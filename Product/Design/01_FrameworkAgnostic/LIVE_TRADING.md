---
artifact_type: story
created_at: '2025-11-25T16:23:21.842684Z'
id: AUTO-LIVE_TRADING
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for LIVE_TRADING
updated_at: '2025-11-25T16:23:21.842688Z'
---

# Live Trading Design

## Overview

Live trading executes real orders with actual capital. This mode requires additional safeguards, monitoring, and operational controls beyond backtesting and paper trading.

## Critical Requirements

### Safety & Risk Management
- **Pre-trade risk checks**: Position limits, loss limits, exposure limits
- **Kill switch**: Emergency stop all strategies
- **Heartbeat monitoring**: Detect strategy/connection failures
- **Order reconciliation**: Match executed orders with intended orders
- **Audit logging**: Complete trail for compliance and debugging

### Operational Requirements
- **99.9% uptime**: Redundancy and failover
- **Latency monitoring**: Alert on degraded performance
- **Real-time alerting**: SMS/email/PagerDuty integration
- **Position/P&L tracking**: Real-time updates
- **Reconciliation**: Daily EOD position/cash reconciliation

## Architecture

```
┌────────────────────────────────────────────────────┐
│              Live Trading Runtime                  │
├────────────────────────────────────────────────────┤
│                                                    │
│  ┌──────────────┐      ┌──────────────┐          │
│  │  Broker API  │      │  Market Data │          │
│  │  Connector   │      │   Provider   │          │
│  └──────┬───────┘      └──────┬───────┘          │
│         │                     │                   │
│         │                     │                   │
│         ▼                     ▼                   │
│  ┌────────────────────────────────────┐           │
│  │       LiveTradingAdapter           │           │
│  │  - Real execution                  │           │
│  │  - Live portfolio tracking         │           │
│  │  - Connection management           │           │
│  └────────────┬───────────────────────┘           │
│               │                                   │
│               ▼                                   │
│  ┌────────────────────────────┐                  │
│  │    Risk Orchestrator       │                  │
│  │  - Pre-trade checks        │                  │
│  │  - Position limits         │                  │
│  │  - Loss limits             │                  │
│  └────────────┬───────────────┘                  │
│               │                                   │
│               ▼                                   │
│        ┌──────────┐                              │
│        │ Strategy │                              │
│        └──────────┘                              │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │         Monitoring & Alerting              │ │
│  │  - Heartbeat checks                        │ │
│  │  - Latency monitoring                      │ │
│  │  - Error alerts                            │ │
│  └────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────┘
```

## Implementation

### LiveTradingAdapter

```python
class LiveTradingAdapter(FrameworkAdapter):
    """
    Adapter for live trading with real broker connectivity.
    """

    def __init__(
        self,
        config: LiveTradingConfig,
        broker_connector: BrokerConnector,
        market_data_provider: LiveDataProvider,
        risk_config: RiskConfig
    ):
        self.config = config
        self.broker = broker_connector
        self.market_data = market_data_provider
        self.risk_config = risk_config

        # Real-time components
        self.clock = RealTimeClock()
        self.portfolio = LivePortfolio(broker=broker_connector)
        self.risk_orchestrator = RiskOrchestrator(risk_config)

        # Monitoring
        self.heartbeat_monitor = HeartbeatMonitor(
            interval=config.heartbeat_interval
        )
        self.latency_monitor = LatencyMonitor()

        # Kill switch
        self.kill_switch = KillSwitch(adapter=self)

        # Audit log
        self.audit_log = PersistentAuditLog(
            storage_path=config.audit_log_path
        )

    def create_execution_port(self) -> OrderExecutionPort:
        """Live execution port with risk checks."""
        return LiveExecutionPort(
            broker=self.broker,
            portfolio=self.portfolio,
            risk_orchestrator=self.risk_orchestrator,
            audit_log=self.audit_log,
            latency_monitor=self.latency_monitor
        )

    def start(self) -> None:
        """
        Start live trading with safety checks.

        Sequence:
        1. Connect to broker
        2. Sync portfolio state
        3. Start heartbeat monitor
        4. Enable kill switch
        5. Start strategies
        """
        # Connect
        self.broker.connect()
        if not self.broker.is_connected():
            raise ConnectionError("Failed to connect to broker")

        # Sync portfolio
        self.portfolio.sync_from_broker()

        # Start monitoring
        self.heartbeat_monitor.start(self._on_heartbeat_failure)

        # Start strategies
        self.strategy_runtime.start()

    def stop(self) -> None:
        """Graceful shutdown."""
        # Stop strategies
        self.strategy_runtime.stop()

        # Cancel all pending orders
        self.broker.cancel_all_orders()

        # Disconnect
        self.broker.disconnect()

        # Stop monitoring
        self.heartbeat_monitor.stop()

    def _on_heartbeat_failure(self) -> None:
        """Handle heartbeat failure (connection lost)."""
        self.audit_log.log_critical("Heartbeat failure detected")

        # Trigger kill switch
        self.kill_switch.activate("heartbeat_failure")

        # Alert
        self.alert("CRITICAL: Heartbeat failure - trading halted")
```

### LiveExecutionPort

```python
class LiveExecutionPort(OrderExecutionPort):
    """
    Execution port for live trading.
    Submits real orders to broker with comprehensive checks.
    """

    def submit_order(self, intent: TradeIntent) -> OrderTicket:
        """
        Submit order with multi-layer validation.

        Flow:
        1. Pre-trade risk checks
        2. Broker connectivity check
        3. Submit to broker API
        4. Track order state
        5. Audit log
        """
        # Log intent
        self.audit_log.log_order_intent(intent)

        # Measure latency
        submit_start = time.time()

        # Risk checks
        risk_result = self.risk_orchestrator.validate_intent(intent)
        if not risk_result.is_ok():
            self.audit_log.log_risk_rejection(intent, risk_result.error)
            raise RiskCheckFailedError(risk_result.error)

        # Submit to broker
        try:
            broker_order_id = self.broker.submit_order(
                symbol=intent.legs[0].instrument_id.symbol,
                side=intent.legs[0].side,
                quantity=intent.total_quantity().value,
                order_type=intent.order_type,
                limit_price=intent.price_instruction.value if intent.price_instruction else None
            )

            # Measure latency
            submit_latency = (time.time() - submit_start) * 1000  # ms
            self.latency_monitor.record_submission_latency(submit_latency)

            # Create ticket
            ticket = OrderTicket(
                ticket_id=uuid4(),
                intent=intent,
                status=OrderStatus.SUBMITTED,
                fills=[],
                last_update=datetime.now(timezone.utc),
                adapter_metadata={"broker_order_id": broker_order_id}
            )

            # Track order
            self._track_order(ticket, broker_order_id)

            # Audit log
            self.audit_log.log_order_submission(ticket)

            return ticket

        except BrokerAPIError as e:
            self.audit_log.log_submission_error(intent, e)
            raise ExecutionError(f"Broker submission failed: {e}")

    def _track_order(self, ticket: OrderTicket, broker_order_id: str) -> None:
        """
        Subscribe to broker order updates.
        Updates ticket state and notifies strategy.
        """
        def on_broker_update(broker_event):
            """Handle broker order update."""
            # Translate broker event to canonical OrderUpdate
            update = self._translate_broker_event(broker_event)

            # Update ticket
            ticket.status = update.status
            if update.fill:
                ticket.fills.append(update.fill)

                # Update portfolio
                self.portfolio.apply_fill(update.fill)

            ticket.last_update = datetime.now(timezone.utc)

            # Audit log
            self.audit_log.log_order_update(ticket, update)

            # Notify strategy
            self._notify_strategy(update)

        # Subscribe to broker events
        self.broker.subscribe_order_updates(
            broker_order_id,
            callback=on_broker_update
        )
```

### Risk Orchestrator

```python
class RiskOrchestrator:
    """
    Pre-trade risk management.
    Validates all orders against risk limits before submission.
    """

    def __init__(self, config: RiskConfig):
        self.config = config
        self._daily_pnl_tracker = DailyPnLTracker()
        self._position_tracker = PositionTracker()

    def validate_intent(self, intent: TradeIntent) -> Result[None, RiskCheckError]:
        """
        Comprehensive pre-trade risk checks.

        Returns:
            Result[None] if valid, Result[Error] if rejected
        """
        # Check 1: Position size limit
        if not self._check_position_size_limit(intent):
            return Result.error(RiskCheckError("Position size limit exceeded"))

        # Check 2: Daily loss limit
        if not self._check_daily_loss_limit():
            return Result.error(RiskCheckError("Daily loss limit exceeded"))

        # Check 3: Max drawdown
        if not self._check_drawdown_limit():
            return Result.error(RiskCheckError("Drawdown limit exceeded"))

        # Check 4: Concentration risk
        if not self._check_concentration_limit(intent):
            return Result.error(RiskCheckError("Concentration limit exceeded"))

        # Check 5: Buying power
        if not self._check_buying_power(intent):
            return Result.error(RiskCheckError("Insufficient buying power"))

        return Result.ok(None)

    def _check_position_size_limit(self, intent: TradeIntent) -> bool:
        """Validate position size within limits."""
        instrument_id = intent.legs[0].instrument_id
        current_position = self._position_tracker.get_position(instrument_id)
        new_position_size = current_position + intent.total_quantity().value

        return abs(new_position_size) <= self.config.max_position_size

    def _check_daily_loss_limit(self) -> bool:
        """Check if daily loss exceeds limit."""
        daily_pnl = self._daily_pnl_tracker.get_daily_pnl()
        return daily_pnl > -self.config.max_daily_loss

    def _check_drawdown_limit(self) -> bool:
        """Check current drawdown vs. limit."""
        current_drawdown = self._calculate_current_drawdown()
        return current_drawdown < self.config.max_drawdown_pct

    def _check_concentration_limit(self, intent: TradeIntent) -> bool:
        """Check portfolio concentration."""
        # Prevent over-concentration in single instrument
        instrument_id = intent.legs[0].instrument_id
        instrument_exposure = self._position_tracker.get_exposure(instrument_id)
        total_portfolio_value = self._position_tracker.get_total_value()

        concentration_pct = instrument_exposure / total_portfolio_value
        return concentration_pct <= self.config.max_concentration_pct

    def _check_buying_power(self, intent: TradeIntent) -> bool:
        """Validate sufficient buying power."""
        required_capital = self._estimate_required_capital(intent)
        available_buying_power = self._position_tracker.get_buying_power()

        return available_buying_power >= required_capital
```

### Kill Switch

```python
class KillSwitch:
    """
    Emergency stop mechanism.
    Immediately halts all trading activity.
    """

    def __init__(self, adapter: LiveTradingAdapter):
        self.adapter = adapter
        self._is_active = False
        self._activation_reason: Optional[str] = None

    def activate(self, reason: str) -> None:
        """
        Activate kill switch.

        Actions:
        1. Stop all strategies
        2. Cancel all pending orders
        3. Disconnect from broker (optional)
        4. Alert operations team
        5. Log event
        """
        if self._is_active:
            return  # Already active

        self._is_active = True
        self._activation_reason = reason

        # Log critical event
        self.adapter.audit_log.log_critical(
            f"KILL SWITCH ACTIVATED: {reason}"
        )

        # Stop strategies
        self.adapter.strategy_runtime.stop()

        # Cancel all orders
        self.adapter.broker.cancel_all_orders()

        # Optional: Close all positions
        if self.adapter.config.kill_switch_closes_positions:
            self._close_all_positions()

        # Alert
        self.adapter.alert(
            severity="CRITICAL",
            message=f"Kill switch activated: {reason}"
        )

    def deactivate(self, authorized_user: str) -> None:
        """
        Deactivate kill switch (requires authorization).
        """
        if not self._is_active:
            return

        # Log deactivation
        self.adapter.audit_log.log_info(
            f"Kill switch deactivated by {authorized_user}"
        )

        self._is_active = False
        self._activation_reason = None

        # Alert
        self.adapter.alert(
            severity="INFO",
            message=f"Kill switch deactivated by {authorized_user}"
        )

    def _close_all_positions(self) -> None:
        """Emergency close all open positions."""
        positions = self.adapter.portfolio.get_positions()

        for position in positions:
            close_intent = TradeIntent(
                strategy_id="kill_switch",
                legs=[
                    OrderLeg(
                        instrument_id=position.instrument_id,
                        side=Side.SELL if position.net_quantity.is_long() else Side.BUY,
                        quantity=Quantity(abs(position.net_quantity.value))
                    )
                ],
                order_type=OrderType.MARKET,
                time_in_force=TimeInForce.IOC
            )

            self.adapter.broker.submit_order(close_intent)
```

### Heartbeat Monitor

```python
class HeartbeatMonitor:
    """
    Monitors strategy and connection health.
    Triggers kill switch on failure.
    """

    def __init__(self, interval: timedelta):
        self.interval = interval
        self._last_heartbeat: Optional[datetime] = None
        self._is_running = False
        self._failure_callback: Optional[Callable] = None

    def start(self, on_failure: Callable[[], None]) -> None:
        """Start heartbeat monitoring."""
        self._failure_callback = on_failure
        self._is_running = True
        self._last_heartbeat = datetime.now(timezone.utc)

        # Start monitoring loop
        asyncio.create_task(self._monitor_loop())

    def stop(self) -> None:
        """Stop monitoring."""
        self._is_running = False

    def heartbeat(self) -> None:
        """Record heartbeat (called by strategy/adapter)."""
        self._last_heartbeat = datetime.now(timezone.utc)

    async def _monitor_loop(self) -> None:
        """Monitor heartbeat in background."""
        while self._is_running:
            await asyncio.sleep(self.interval.total_seconds())

            # Check last heartbeat
            if self._last_heartbeat:
                time_since_heartbeat = datetime.now(timezone.utc) - self._last_heartbeat

                if time_since_heartbeat > self.interval * 2:
                    # Heartbeat failure
                    if self._failure_callback:
                        self._failure_callback()

                    break  # Stop monitoring after failure
```

## Monitoring & Alerting

### Metrics Collection

```python
class LiveMetricsCollector:
    """
    Collects and exports real-time metrics.
    Integrates with Prometheus, StatsD, CloudWatch, etc.
    """

    def __init__(self, backend: MetricsBackend):
        self.backend = backend

    def record_order_submission(self, latency_ms: float) -> None:
        """Record order submission latency."""
        self.backend.histogram(
            "order_submission_latency_ms",
            latency_ms,
            tags={"environment": "live"}
        )

    def record_fill(self, fill: Fill) -> None:
        """Record trade fill."""
        self.backend.counter(
            "trades_executed",
            1,
            tags={"instrument": str(fill.instrument_id)}
        )

    def record_pnl_update(self, pnl: Decimal) -> None:
        """Record P&L update."""
        self.backend.gauge(
            "current_pnl",
            float(pnl),
            tags={"environment": "live"}
        )

    def record_position_count(self, count: int) -> None:
        """Record open position count."""
        self.backend.gauge(
            "open_positions",
            count,
            tags={"environment": "live"}
        )
```

### Alerting

```python
class AlertManager:
    """
    Sends alerts via multiple channels.
    """

    def __init__(self, config: AlertConfig):
        self.config = config
        self.email_client = EmailClient(config.smtp)
        self.sms_client = SMSClient(config.twilio)
        self.pagerduty_client = PagerDutyClient(config.pagerduty_key)

    def send_alert(
        self,
        severity: str,  # INFO, WARNING, CRITICAL
        message: str,
        metadata: Optional[Dict] = None
    ) -> None:
        """
        Send alert based on severity.

        - INFO: Email only
        - WARNING: Email + Slack
        - CRITICAL: Email + SMS + PagerDuty
        """
        if severity == "INFO":
            self.email_client.send(message)

        elif severity == "WARNING":
            self.email_client.send(message)
            self.slack_client.send(message)

        elif severity == "CRITICAL":
            self.email_client.send(message)
            self.sms_client.send(message)
            self.pagerduty_client.trigger_incident(message, metadata)
```

## Daily Reconciliation

```python
class EODReconciliation:
    """
    End-of-day reconciliation.
    Validates positions and cash match broker records.
    """

    def run_reconciliation(
        self,
        internal_portfolio: PortfolioSnapshot,
        broker_portfolio: BrokerPortfolioSnapshot
    ) -> ReconciliationReport:
        """
        Compare internal vs. broker portfolio.

        Returns:
            Report with discrepancies and required corrections
        """
        report = ReconciliationReport()

        # Compare positions
        for instrument_id in set(
            internal_portfolio.positions.keys() |
            broker_portfolio.positions.keys()
        ):
            internal_qty = internal_portfolio.positions.get(instrument_id, 0)
            broker_qty = broker_portfolio.positions.get(instrument_id, 0)

            if internal_qty != broker_qty:
                report.add_discrepancy(
                    instrument=instrument_id,
                    internal=internal_qty,
                    broker=broker_qty,
                    difference=broker_qty - internal_qty
                )

        # Compare cash
        if internal_portfolio.cash != broker_portfolio.cash:
            report.add_cash_discrepancy(
                internal=internal_portfolio.cash,
                broker=broker_portfolio.cash
            )

        return report
```

## Summary

Live trading design provides:

- ✅ **Multi-layer risk checks** (position, loss, drawdown limits)
- ✅ **Kill switch** for emergency stop
- ✅ **Heartbeat monitoring** for failure detection
- ✅ **Real-time metrics** and alerting
- ✅ **Audit logging** for compliance
- ✅ **EOD reconciliation** for accuracy
- ✅ **99.9% uptime** through monitoring and redundancy

**Critical**: Live trading requires extensive testing, operational runbooks, and on-call support.
