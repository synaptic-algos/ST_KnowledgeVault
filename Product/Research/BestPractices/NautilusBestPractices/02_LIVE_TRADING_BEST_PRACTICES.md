---
artifact_type: story
created_at: '2025-11-25T16:23:21.871068Z'
id: AUTO-02_LIVE_TRADING_BEST_PRACTICES
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for 02_LIVE_TRADING_BEST_PRACTICES
updated_at: '2025-11-25T16:23:21.871072Z'
---

## Introduction

Live trading with Nautilus means:
- **Real orders** sent to Zerodha
- **Real money** at risk
- **Same code** as backtest and paper trading
- **Production infrastructure** required

**Critical Principle**: If it works in paper trading for 2+ weeks with zero issues, it's ready for live trading with reduced capital.

---

## Pre-Go-Live Checklist

### Must-Have Before Live Trading

#### 1. Backtesting Validation ✅
- [ ] Strategy backtested on 6+ months of data
- [ ] Positive expectancy (avg win > avg loss × (1 - win rate))
- [ ] Maximum drawdown acceptable (<20%)
- [ ] Sharpe ratio > 1.0
- [ ] Capital management tested (compounding works)

#### 2. Paper Trading Validation ✅
- [ ] Paper trading running for 2+ weeks minimum
- [ ] Zero code errors or exceptions
- [ ] Capital tracking accurate (matches manual calculation)
- [ ] Order fills realistic (no instant fills on illiquid options)
- [ ] Re-entry logic working (no duplicate spreads)
- [ ] Exit logic working (D-1, profit target, stop loss)

#### 3. Risk Management ✅
- [ ] Portfolio stop-loss implemented and tested
- [ ] Per-trade stop-loss implemented and tested
- [ ] Position size limits enforced (max lots per trade)
- [ ] Capital deployment limits enforced (max 80% deployed)
- [ ] Circuit breakers in place (daily loss limit)
- [ ] Manual kill switch available (emergency stop)

#### 4. Infrastructure ✅
- [ ] Server monitoring (CPU, memory, disk)
- [ ] Database backups (trades, positions, logs)
- [ ] Redundant internet connection (failover)
- [ ] SMS/email alerts configured
- [ ] Phone number for urgent alerts
- [ ] On-call person available during market hours

#### 5. Operational Readiness ✅
- [ ] Daily checklist created (token refresh, health checks)
- [ ] Incident response plan documented
- [ ] Rollback procedure tested
- [ ] Manual trading knowledge (know how to manually close positions)
- [ ] Zerodha support contact saved
- [ ] Broker account verified (margin requirements, limits)

---

## Live Trading Architecture

### Difference from Paper Trading: One Config Change

```python
# PAPER TRADING CONFIG
config = TradingNodeConfig(
    exec_clients={
        "ZERODHA": {
            "simulated": True,  # ← Simulated execution
            # ...
        }
    }
)

# LIVE TRADING CONFIG (only change: simulated → False)
config = TradingNodeConfig(
    exec_clients={
        "ZERODHA": {
            "simulated": False,  # ← REAL execution to broker
            # ...
        }
    }
)
```

**That's it.** Same strategy code, same capital manager, same everything.

---

## Zerodha Execution Client

### Implementation

```python
# NEW: src/adapters/zerodha_execution_client.py
from nautilus_trader.live.execution_client import LiveExecutionClient
from nautilus_trader.model.orders import Order, OrderStatus
from nautilus_trader.model.events import OrderFilled, OrderCanceled, OrderRejected
from kiteconnect import KiteConnect
import logging

class ZerodhaExecutionClient(LiveExecutionClient):
    """
    Execution client for Zerodha Kite API.
    Handles REAL order placement, modification, and cancellation.
    """

    def __init__(self, config: ZerodhaExecutionClientConfig):
        super().__init__(
            client_id=ClientId("ZERODHA"),
            venue=config.venue,
            msgbus=config.msgbus,
            cache=config.cache,
            clock=config.clock,
            logger=config.logger
        )

        # Zerodha configuration
        self.api_key = config.api_key
        self.access_token = config.access_token

        # KiteConnect REST API
        self.kite = KiteConnect(api_key=self.api_key)
        self.kite.set_access_token(self.access_token)

        # Order tracking
        self._order_id_map = {}  # Nautilus order_id → Zerodha order_id

    def connect(self):
        """Connect to Zerodha (verify credentials)"""
        self._log.info("Connecting to Zerodha execution API...")

        try:
            # Verify access token
            profile = self.kite.profile()
            self._log.info(f"Connected as: {profile['user_name']} ({profile['email']})")

            # Check funds
            margins = self.kite.margins()
            available = margins['equity']['available']['live_balance']
            self._log.info(f"Available margin: ₹{available:,.2f}")

        except Exception as e:
            self._log.error(f"Failed to connect to Zerodha: {e}")
            raise

    def disconnect(self):
        """Disconnect from Zerodha"""
        self._log.info("Disconnecting from Zerodha execution API...")
        # No explicit disconnect for REST API
        self._log.info("Disconnected from Zerodha")

    def submit_order(self, order: Order):
        """
        Submit order to Zerodha.
        CRITICAL: This places REAL orders with REAL money.
        """
        try:
            self._log.info(f"Submitting order to Zerodha: {order}")

            # Convert Nautilus order to Zerodha order
            zerodha_order = self._convert_order(order)

            # PLACE REAL ORDER
            zerodha_order_id = self.kite.place_order(**zerodha_order)

            # Track order
            self._order_id_map[order.client_order_id] = zerodha_order_id

            self._log.info(f"Order submitted: Nautilus {order.client_order_id} → Zerodha {zerodha_order_id}")

            # Start polling for order status (Zerodha doesn't push updates)
            self._poll_order_status(order.client_order_id)

        except Exception as e:
            self._log.error(f"Failed to submit order: {e}")
            # Generate OrderRejected event
            self._generate_order_rejected(order, reason=str(e))

    def cancel_order(self, order: Order):
        """Cancel order on Zerodha"""
        try:
            zerodha_order_id = self._order_id_map.get(order.client_order_id)

            if not zerodha_order_id:
                self._log.error(f"Cannot cancel order: Zerodha order ID not found for {order.client_order_id}")
                return

            # Cancel on Zerodha
            self.kite.cancel_order(
                variety=self.kite.VARIETY_REGULAR,
                order_id=zerodha_order_id
            )

            self._log.info(f"Order canceled: {order.client_order_id} (Zerodha {zerodha_order_id})")

        except Exception as e:
            self._log.error(f"Failed to cancel order: {e}")

    def _convert_order(self, order: Order) -> dict:
        """Convert Nautilus order to Zerodha order parameters"""
        return {
            'variety': self.kite.VARIETY_REGULAR,
            'exchange': self.kite.EXCHANGE_NSE,
            'tradingsymbol': self._get_zerodha_symbol(order.instrument_id),
            'transaction_type': self.kite.TRANSACTION_TYPE_BUY if order.side == OrderSide.BUY else self.kite.TRANSACTION_TYPE_SELL,
            'quantity': int(order.quantity),
            'order_type': self._get_zerodha_order_type(order),
            'price': float(order.price) if hasattr(order, 'price') else 0,
            'product': self.kite.PRODUCT_MIS,  # Intraday
            'validity': self.kite.VALIDITY_DAY
        }

    def _get_zerodha_symbol(self, instrument_id: InstrumentId) -> str:
        """
        Convert Nautilus instrument_id to Zerodha trading symbol.

        Example:
        - "NIFTY22050CE.NSE" → "NIFTY25JAN22050CE"
        """
        # TODO: Implement mapping logic
        # Option 1: Parse instrument_id and construct Zerodha symbol
        # Option 2: Load from instrument master CSV

        # Placeholder
        return str(instrument_id.symbol)

    def _poll_order_status(self, client_order_id: str):
        """
        Poll Zerodha for order status updates.
        Zerodha doesn't push updates, so we need to poll.
        """
        async def poll():
            zerodha_order_id = self._order_id_map.get(client_order_id)

            while True:
                try:
                    # Get order status from Zerodha
                    order_history = self.kite.order_history(zerodha_order_id)

                    # Get latest status
                    latest = order_history[-1]
                    status = latest['status']

                    if status == 'COMPLETE':
                        # Order filled
                        self._generate_order_filled(client_order_id, latest)
                        break

                    elif status in ['CANCELLED', 'REJECTED']:
                        # Order canceled or rejected
                        self._generate_order_canceled(client_order_id, latest)
                        break

                    # Wait 1 second before polling again
                    await asyncio.sleep(1)

                except Exception as e:
                    self._log.error(f"Error polling order status: {e}")
                    await asyncio.sleep(1)

        # Run polling in background
        asyncio.create_task(poll())

    def _generate_order_filled(self, client_order_id: str, zerodha_order: dict):
        """Generate OrderFilled event from Zerodha order"""
        event = OrderFilled(
            account_id=self.account_id,
            client_order_id=client_order_id,
            venue_order_id=VenueOrderId(zerodha_order['order_id']),
            execution_id=ExecutionId(zerodha_order['exchange_order_id']),
            position_id=PositionId(client_order_id),  # Simplified
            instrument_id=self._get_instrument_id(zerodha_order['tradingsymbol']),
            order_side=OrderSide.BUY if zerodha_order['transaction_type'] == 'BUY' else OrderSide.SELL,
            last_qty=Quantity(zerodha_order['filled_quantity'], precision=0),
            last_px=Price(zerodha_order['average_price'], precision=2),
            cum_qty=Quantity(zerodha_order['filled_quantity'], precision=0),
            leaves_qty=Quantity(0, precision=0),
            commission=Money(0, INR),  # Calculate from brokerage
            ts_event=self._clock.timestamp_ns(),
            ts_init=self._clock.timestamp_ns()
        )

        # Publish event to message bus
        self._handle_event(event)

    def _generate_order_rejected(self, order: Order, reason: str):
        """Generate OrderRejected event"""
        event = OrderRejected(
            account_id=self.account_id,
            client_order_id=order.client_order_id,
            reason=reason,
            ts_event=self._clock.timestamp_ns(),
            ts_init=self._clock.timestamp_ns()
        )

        self._handle_event(event)

    def _generate_order_canceled(self, client_order_id: str, zerodha_order: dict):
        """Generate OrderCanceled event"""
        event = OrderCanceled(
            account_id=self.account_id,
            client_order_id=client_order_id,
            venue_order_id=VenueOrderId(zerodha_order['order_id']),
            ts_event=self._clock.timestamp_ns(),
            ts_init=self._clock.timestamp_ns()
        )

        self._handle_event(event)
```

---

## Risk Management & Circuit Breakers

### Built-in Risk Engine

```python
# config/live_trading_config.py
config = TradingNodeConfig(
    risk_engine=RiskEngineConfig(
        bypass=False,  # NEVER bypass in live trading

        # Portfolio limits
        max_notional_total=Money(320_000, INR),  # 80% of ₹400k

        # Per-order limits
        max_order_rate="10/00:00:01",  # Max 10 orders per second
        max_notional_per_order=Money(100_000, INR),  # ₹1 lakh per order

        # Trading hours (IST)
        trading_start="09:15:00",
        trading_stop="15:30:00",

        # Reject orders outside trading hours
        check_trading_hours=True
    )
)
```

---

### Custom Circuit Breakers

```python
# NEW: src/strategy/risk/circuit_breakers.py
from nautilus_trader.trading.strategy import Actor
from nautilus_trader.model.events import AccountState, PositionChanged

class CircuitBreakerActor(Actor):
    """
    Monitors for circuit breaker conditions and stops trading if triggered.

    Triggers:
    1. Daily loss exceeds limit (e.g., 10% of capital)
    2. Too many consecutive losses (e.g., 5 in a row)
    3. Rapid capital depletion (e.g., 5% loss in 1 hour)
    4. System errors (e.g., order rejections, connectivity issues)
    """

    def __init__(self, config):
        super().__init__()

        self.max_daily_loss_pct = config.max_daily_loss_pct  # 10%
        self.max_consecutive_losses = config.max_consecutive_losses  # 5
        self.max_hourly_loss_pct = config.max_hourly_loss_pct  # 5%

        # Tracking
        self._daily_pnl = 0.0
        self._consecutive_losses = 0
        self._hourly_pnl = 0.0
        self._last_hour_reset = None

        # Circuit breaker state
        self._circuit_breaker_triggered = False
        self._trigger_reason = None

    def on_start(self):
        """Subscribe to events"""
        self.subscribe(AccountState, self.on_account_state)
        self.subscribe(PositionClosed, self.on_position_closed)

    def on_account_state(self, event: AccountState):
        """Check portfolio-level circuit breakers"""
        # Get current unrealized P&L
        unrealized_pnl = float(event.unrealized_pnl)

        # Check daily loss limit
        if (self._daily_pnl + unrealized_pnl) < -self.max_daily_loss_pct * self.capital:
            self._trigger_circuit_breaker(
                reason=f"Daily loss limit exceeded: {self._daily_pnl + unrealized_pnl:,.0f}"
            )

        # Check hourly loss limit
        current_hour = self._clock.timestamp().hour
        if self._last_hour_reset != current_hour:
            self._hourly_pnl = 0
            self._last_hour_reset = current_hour

        if (self._hourly_pnl + unrealized_pnl) < -self.max_hourly_loss_pct * self.capital:
            self._trigger_circuit_breaker(
                reason=f"Hourly loss limit exceeded: {self._hourly_pnl + unrealized_pnl:,.0f}"
            )

    def on_position_closed(self, event: PositionClosed):
        """Track position-level metrics"""
        trade_pnl = float(event.realized_pnl)
        self._daily_pnl += trade_pnl
        self._hourly_pnl += trade_pnl

        # Check consecutive losses
        if trade_pnl < 0:
            self._consecutive_losses += 1

            if self._consecutive_losses >= self.max_consecutive_losses:
                self._trigger_circuit_breaker(
                    reason=f"Too many consecutive losses: {self._consecutive_losses}"
                )
        else:
            self._consecutive_losses = 0  # Reset on win

    def _trigger_circuit_breaker(self, reason: str):
        """EMERGENCY STOP - Halt all trading"""
        if self._circuit_breaker_triggered:
            return  # Already triggered

        self._circuit_breaker_triggered = True
        self._trigger_reason = reason

        self.log.critical("=" * 80)
        self.log.critical("⚠️  CIRCUIT BREAKER TRIGGERED ⚠️")
        self.log.critical(f"Reason: {reason}")
        self.log.critical("=" * 80)

        # Stop all strategies
        for strategy in self.msgbus.get_strategies():
            strategy.stop()

        # Close all positions
        for strategy in self.msgbus.get_strategies():
            strategy.close_all_positions()

        # Send SMS/email alert
        self._send_emergency_alert(reason)

        self.log.critical("All strategies stopped. Positions closing.")

    def _send_emergency_alert(self, reason: str):
        """Send SMS/email alert (implement with Twilio/SendGrid)"""
        # TODO: Implement emergency alerts
        pass

    def is_trading_allowed(self) -> bool:
        """Check if trading is allowed (called by strategies)"""
        return not self._circuit_breaker_triggered
```

**Integration**:
```python
# config/live_trading_config.py
config = TradingNodeConfig(
    actors=[
        ImportableActorConfig(
            actor_path="strategy.risk.circuit_breakers:CircuitBreakerActor",
            config={
                "max_daily_loss_pct": 10.0,
                "max_consecutive_losses": 5,
                "max_hourly_loss_pct": 5.0
            }
        )
    ]
)
```

---

## Order Management

### Order Lifecycle in Live Trading

```
1. Strategy.submit_order() called
   ↓
2. RiskEngine validates (pre-trade checks)
   ↓
3. If approved → ZerodhaExecutionClient.submit_order()
   ↓
4. Order sent to Zerodha API
   ↓
5. Zerodha places order on exchange
   ↓
6. ZerodhaExecutionClient polls for status
   ↓
7. Order fills → OrderFilled event generated
   ↓
8. Portfolio updates position
   ↓
9. Strategy.on_order_filled() called
   ↓
10. CapitalManager.on_position_opened() called
```

---

### Handling Partial Fills

```python
# In strategy
def on_order_filled(self, event: OrderFilled):
    """Handle order fills (may be partial)"""
    if event.leaves_qty > 0:
        # Partial fill
        self.log.warning(f"Partial fill: {event.cum_qty} of {event.order_qty} filled")
        # Wait for remaining quantity to fill
        # OR cancel order and adjust position size
    else:
        # Complete fill
        self.log.info(f"Order fully filled: {event.client_order_id}")
```

---

### Handling Order Rejections

```python
def on_order_rejected(self, event: OrderRejected):
    """Handle order rejections"""
    self.log.error(f"Order rejected: {event.client_order_id}")
    self.log.error(f"Reason: {event.reason}")

    # Common rejection reasons:
    # - Insufficient margin
    # - Invalid strike/expiry
    # - Market closed
    # - Rate limit exceeded

    # Decide on action:
    # - Retry with smaller quantity?
    # - Skip this trade?
    # - Alert operator?

    # For now: log and skip
    self._send_alert(f"Order rejected: {event.reason}")
```

---

## Monitoring & Alerts

### Real-Time Monitoring Dashboard

**Must-Have Metrics**:
1. **System Health**
   - Uptime
   - CPU/memory usage
   - Network connectivity
   - Last successful order fill

2. **Position Metrics**
   - Open positions (count, notional)
   - Unrealized P&L
   - Deployed capital (%)
   - Available capital

3. **Daily Metrics**
   - Total trades today
   - Win rate today
   - Daily P&L
   - Largest win/loss

4. **Risk Metrics**
   - Portfolio stop-loss distance
   - Per-position stop-loss distance
   - Consecutive losses
   - Circuit breaker status

---

### Alert Configuration

```python
# config/alerts_config.py
from dataclasses import dataclass

@dataclass
class AlertsConfig:
    # SMS alerts (via Twilio)
    sms_enabled: bool = True
    sms_phone_number: str = "+91XXXXXXXXXX"
    twilio_account_sid: str = "..."
    twilio_auth_token: str = "..."

    # Email alerts (via SendGrid)
    email_enabled: bool = True
    email_address: str = "trading@example.com"
    sendgrid_api_key: str = "..."

    # Alert triggers
    alert_on_circuit_breaker: bool = True
    alert_on_order_rejection: bool = True
    alert_on_connectivity_loss: bool = True
    alert_on_position_stop_loss: bool = True
    alert_on_daily_loss_threshold: float = 0.05  # 5%
```

---

### Alert Implementation

```python
# NEW: src/utils/alerts.py
import requests
from twilio.rest import Client

class AlertManager:
    """Send SMS and email alerts"""

    def __init__(self, config: AlertsConfig):
        self.config = config

        # Twilio client
        if config.sms_enabled:
            self.twilio = Client(config.twilio_account_sid, config.twilio_auth_token)

    def send_sms(self, message: str):
        """Send SMS alert"""
        if not self.config.sms_enabled:
            return

        try:
            self.twilio.messages.create(
                to=self.config.sms_phone_number,
                from_="+1XXXXXXXXXX",  # Twilio number
                body=message
            )
        except Exception as e:
            print(f"Failed to send SMS: {e}")

    def send_email(self, subject: str, body: str):
        """Send email alert"""
        if not self.config.email_enabled:
            return

        try:
            # SendGrid API
            response = requests.post(
                "https://api.sendgrid.com/v3/mail/send",
                headers={
                    "Authorization": f"Bearer {self.config.sendgrid_api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "personalizations": [{"to": [{"email": self.config.email_address}]}],
                    "from": {"email": "alerts@synaptictrading.com"},
                    "subject": subject,
                    "content": [{"type": "text/plain", "value": body}]
                }
            )
            response.raise_for_status()
        except Exception as e:
            print(f"Failed to send email: {e}")

    def alert_circuit_breaker(self, reason: str):
        """Critical alert: Circuit breaker triggered"""
        self.send_sms(f"🚨 CIRCUIT BREAKER TRIGGERED: {reason}")
        self.send_email(
            subject="🚨 CIRCUIT BREAKER TRIGGERED",
            body=f"Trading has been stopped due to:\n\n{reason}\n\nImmediate action required."
        )

    def alert_order_rejected(self, order_id: str, reason: str):
        """Warning alert: Order rejected"""
        self.send_sms(f"⚠️  Order rejected: {order_id} - {reason}")
```

---

## Error Handling & Recovery

### Common Errors & Responses

| Error | Cause | Response |
|-------|-------|----------|
| **ConnectionError** | Network issue | Retry with exponential backoff, alert if > 5 min |
| **OrderRejected (Insufficient Margin)** | Not enough capital | Skip trade, log warning |
| **OrderRejected (Invalid Instrument)** | Wrong strike/expiry | Fix instrument mapping, alert |
| **PartialFill** | Illiquid options | Wait for full fill (max 30s), then cancel |
| **MarketClosed** | Order outside market hours | Queue order for next day |
| **RateLimitExceeded** | Too many API calls | Throttle requests, retry after 1s |
| **AccessTokenExpired** | Token not refreshed | CRITICAL: Stop trading, refresh token, restart |
| **PositionMismatch** | Strategy vs broker mismatch | Reconcile positions, alert operator |

---

### Position Reconciliation

```python
# NEW: src/strategy/risk/position_reconciler.py
from nautilus_trader.trading.strategy import Actor

class PositionReconcilerActor(Actor):
    """
    Reconciles Nautilus positions with broker positions.
    Runs every 5 minutes to detect discrepancies.
    """

    def __init__(self, config):
        super().__init__()
        self.reconciliation_interval = 300  # 5 minutes

    def on_start(self):
        """Schedule position reconciliation"""
        self.clock.set_timer(
            name="position_reconciliation",
            interval=timedelta(seconds=self.reconciliation_interval),
            callback=self.reconcile_positions
        )

    def reconcile_positions(self):
        """Compare Nautilus positions with Zerodha positions"""
        # Get Nautilus positions
        nautilus_positions = self.portfolio.positions()

        # Get Zerodha positions
        zerodha_positions = self._get_zerodha_positions()

        # Compare
        discrepancies = self._find_discrepancies(nautilus_positions, zerodha_positions)

        if discrepancies:
            self.log.error(f"Position discrepancies detected: {discrepancies}")
            self._send_alert(f"Position mismatch: {discrepancies}")

            # Auto-reconcile or require manual intervention?
            # For safety: STOP trading and alert operator
            self._trigger_emergency_stop("Position mismatch detected")

    def _get_zerodha_positions(self):
        """Fetch positions from Zerodha API"""
        # Use ZerodhaExecutionClient to query positions
        return self.execution_client.get_positions()

    def _find_discrepancies(self, nautilus, zerodha):
        """Find positions that don't match"""
        discrepancies = []

        # Check each Nautilus position exists in Zerodha
        for np in nautilus:
            zp = self._find_matching_zerodha_position(np, zerodha)

            if not zp:
                discrepancies.append(f"Nautilus position {np.id} not in Zerodha")
            elif np.quantity != zp.quantity:
                discrepancies.append(f"Quantity mismatch: {np.id} (Nautilus: {np.quantity}, Zerodha: {zp.quantity})")

        return discrepancies
```

---

## Gradual Rollout Strategy

### Phase 1: Paper Trading (2+ weeks)

**Goal**: Validate strategy with live data, zero risk.

**Checklist**:
- [ ] Run paper trading for minimum 2 weeks
- [ ] Monitor daily for errors, exceptions, unexpected behavior
- [ ] Validate capital management (lot sizing correct)
- [ ] Validate entry/exit logic (timing, strikes correct)
- [ ] Compare with backtest results (similar P&L profile)

---

### Phase 2: Live Trading with 10% Capital (1 week)

**Goal**: Validate execution with real money, minimal risk.

**Configuration**:
```python
# Use 10% of capital
config = CapitalManagerConfig(
    initial_capital=40_000,  # ₹40k instead of ₹400k
    risk_per_trade_pct=5.0,
    max_deployment_pct=80.0
)
```

**Checklist**:
- [ ] Execute 5+ trades successfully
- [ ] No order rejections (except for valid reasons)
- [ ] Capital tracking accurate (manual verification)
- [ ] Circuit breakers NOT triggered (unless legitimately)
- [ ] Alerts working (test with small intentional trigger)

---

### Phase 3: Live Trading with 50% Capital (2 weeks)

**Goal**: Increase capital, monitor for issues.

**Configuration**:
```python
config = CapitalManagerConfig(
    initial_capital=200_000,  # ₹200k (50%)
    # ...
)
```

**Checklist**:
- [ ] Execute 20+ trades successfully
- [ ] Win rate matches backtest expectations (±10%)
- [ ] Average P&L matches expectations (±20%)
- [ ] No significant slippage (trades fill near market price)
- [ ] System stable (no crashes, hangs, or memory leaks)

---

### Phase 4: Live Trading with Full Capital

**Goal**: Full production deployment.

**Configuration**:
```python
config = CapitalManagerConfig(
    initial_capital=400_000,  # Full ₹400k
    # ...
)
```

**Ongoing Monitoring**:
- [ ] Daily review of trades (entry/exit correct)
- [ ] Weekly review of P&L (on track with expectations)
- [ ] Monthly strategy review (adjust parameters if needed)
- [ ] Quarterly backtest refresh (test on recent data)

---

## Production Checklist

### Daily Pre-Market Checklist

**Before 9:00 AM IST**:
- [ ] Refresh Zerodha access token (run `quick_token_update.py`)
- [ ] Verify system health (CPU, memory, disk space)
- [ ] Check network connectivity (ping test)
- [ ] Review pending orders (should be none)
- [ ] Verify capital state (matches expectations from yesterday)
- [ ] Check for any alerts from overnight

---

### During Market Hours

**Monitoring** (every hour):
- [ ] Check for new positions (expected timing)
- [ ] Verify no order rejections
- [ ] Monitor daily P&L (within expectations)
- [ ] Check circuit breaker status (not triggered)
- [ ] Review alerts (address any warnings)

**End of Day** (after 3:30 PM):
- [ ] Review all trades executed today
- [ ] Verify positions closed as expected (D-1 exits, profit targets)
- [ ] Update capital tracking spreadsheet (manual verification)
- [ ] Check logs for any errors or warnings
- [ ] Backup trade log, position log to cloud storage

---

### Weekly Review

**Every Monday**:
- [ ] Review last week's trades (win rate, avg P&L)
- [ ] Compare with backtest expectations
- [ ] Check for any recurring issues (e.g., consistent slippage)
- [ ] Review capital growth (compounding working correctly)
- [ ] Test alert system (send test SMS/email)

---

### Monthly Review

**First weekend of month**:
- [ ] Full performance review (Sharpe, drawdown, return)
- [ ] Backtest on last 3 months of data (compare with live)
- [ ] Review strategy parameters (need adjustments?)
- [ ] Check system infrastructure (disk space, logs, backups)
- [ ] Review brokerage statements (match internal records)

---

## Configuration for Live Trading

### Complete Live Trading Config

```python
# config/live_trading_config.py
from nautilus_trader.config import TradingNodeConfig
from config.zerodha_config import ZerodhaConfig

def create_live_trading_config():
    """Create TradingNode configuration for LIVE trading"""

    # Load credentials
    zerodha = ZerodhaConfig.load_from_credentials()

    return TradingNodeConfig(
        trader_id="LIVE-001",
        instance_id="live-synaptictrading",

        # Data clients (live market data)
        data_clients={
            "ZERODHA": ZerodhaDataClientConfig(
                api_key=zerodha.api_key,
                access_token=zerodha.access_token,
                venue="NSE"
            )
        },

        # Execution clients (REAL execution)
        exec_clients={
            "ZERODHA": ZerodhaExecutionClientConfig(
                api_key=zerodha.api_key,
                access_token=zerodha.access_token,
                venue="NSE",
                simulated=False,  # ← LIVE EXECUTION
                # NO fill_model, latency_model (real fills from broker)
            )
        },

        # Strategy (same as backtest/paper)
        strategies=[
            ImportableStrategyConfig(
                strategy_path="strategy.options_spread_strategy:OptionsSpreadStrategyModular",
                config={...}  # Same config
            )
        ],

        # Actors
        actors=[
            ImportableActorConfig(
                actor_path="strategy.actors.capital_manager:CapitalManager",
                config={...}
            ),
            ImportableActorConfig(
                actor_path="strategy.risk.circuit_breakers:CircuitBreakerActor",
                config={
                    "max_daily_loss_pct": 10.0,
                    "max_consecutive_losses": 5,
                    "max_hourly_loss_pct": 5.0
                }
            ),
            ImportableActorConfig(
                actor_path="strategy.risk.position_reconciler:PositionReconcilerActor",
                config={"reconciliation_interval": 300}
            )
        ],

        # Risk engine (STRICT)
        risk_engine=RiskEngineConfig(
            bypass=False,  # NEVER bypass
            max_notional_total=Money(320_000, INR),
            max_order_rate="10/00:00:01",
            trading_start="09:15:00",
            trading_stop="15:30:00",
            check_trading_hours=True
        ),

        # Logging (DEBUG level)
        logging=LoggingConfig(
            log_level="INFO",
            log_level_file="DEBUG",
            log_directory="logs/live_trading"
        ),

        # Database (production)
        cache_database=CacheDatabaseConfig(
            type="redis",
            host="localhost",
            port=6379
        ),

        # Alerts
        alerts=AlertsConfig(
            sms_enabled=True,
            sms_phone_number="+91XXXXXXXXXX",
            email_enabled=True,
            email_address="trading@example.com"
        )
    )
```

---

## Key Takeaways

1. **Same Code, Different Config**
   - Strategy: 100% identical to backtest/paper
   - CapitalManager: 100% identical
   - Only execution client changes (simulated → real)

2. **Risk Management is Critical**
   - Portfolio stop-loss (10% daily loss)
   - Per-trade stop-loss (50% of max loss)
   - Circuit breakers (consecutive losses, rapid depletion)
   - Position reconciliation (every 5 minutes)

3. **Gradual Rollout**
   - Paper trading: 2+ weeks (validate strategy)
   - Live 10%: 1 week (validate execution)
   - Live 50%: 2 weeks (validate scaling)
   - Live 100%: Full deployment

4. **Monitoring & Alerts**
   - Real-time dashboard (positions, P&L, risk)
   - SMS/email alerts (circuit breaker, rejections)
   - Daily review (trades, P&L, logs)
   - Weekly/monthly review (performance, parameters)

5. **Error Handling**
   - Order rejections: log and skip
   - Partial fills: wait or cancel
   - Position mismatch: stop and alert
   - Connection loss: retry with backoff

6. **Operational Discipline**
   - Daily pre-market checklist
   - Hourly monitoring during market hours
   - End-of-day review
   - Weekly/monthly performance review

---

## Final Warning

**Live trading involves REAL MONEY and REAL RISK.**

- Only deploy to live after 2+ weeks of successful paper trading
- Start with 10% capital, increase gradually
- Monitor continuously during initial weeks
- Have emergency procedures ready (kill switch, manual trading)
- Never bypass risk checks
- Always have alerts configured (SMS + email)

**If in doubt, stay in paper trading longer.**

---

## References

- **Nautilus Live Trading**: https://nautilustrader.io/docs/latest/getting_started/live_trading
- **Zerodha Kite API**: https://kite.trade/docs/connect/v3/
- **Overview**: `00_OVERVIEW.md`
- **Backtesting**: `01_BACKTESTING_BEST_PRACTICES.md`
- **Paper Trading**: `02_PAPER_TRADING_BEST_PRACTICES.md`
- **Current System**: `CLAUDE.md` (Zerodha authentication)
