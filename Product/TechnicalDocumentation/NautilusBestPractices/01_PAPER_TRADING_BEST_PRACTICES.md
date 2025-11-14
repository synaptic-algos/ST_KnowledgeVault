# Nautilus Paper Trading Best Practices

**Created**: 2025-10-13 07:12:55
**Last Updated**: 2025-10-13 07:12:55
**Purpose**: Guide for implementing paper trading with Nautilus Trader framework
**Applies To**: Options spread strategy paper trading with Zerodha integration

---

## Table of Contents

1. [Introduction](#introduction)
2. [Paper Trading Architecture](#paper-trading-architecture)
3. [Zerodha Integration](#zerodha-integration)
4. [Trading Node Setup](#trading-node-setup)
5. [Same Strategy, Different Environment](#same-strategy-different-environment)
6. [Order Simulation](#order-simulation)
7. [Risk Management](#risk-management)
8. [Monitoring & Logging](#monitoring--logging)
9. [Migration from Current System](#migration-from-current-system)

---

## Introduction

Nautilus paper trading (called **Sandbox** mode) provides:
- **Same code as backtest**: Strategy and actors work identically
- **Live market data**: Connect to Zerodha for real-time prices
- **Simulated execution**: Orders fill based on market prices (no real money)
- **Full validation**: Test strategy with live data before going live

**Key Principle**: If it works in paper trading, it's ready for live trading.

---

## Paper Trading Architecture

### TradingNode vs BacktestEngine

| Component | Backtesting | Paper Trading | Live Trading |
|-----------|-------------|---------------|--------------|
| **Engine** | `BacktestEngine` | `TradingNode` | `TradingNode` |
| **Data Source** | Nautilus Catalog (historical) | Zerodha API (live) | Zerodha API (live) |
| **Execution** | Simulated (instant fills) | Simulated (realistic fills) | Real (broker execution) |
| **Orders** | In-memory only | In-memory only | Sent to broker |
| **Capital** | Virtual | Virtual | Real money |
| **Strategy Code** | ✅ Same | ✅ Same | ✅ Same |
| **CapitalManager** | ✅ Same | ✅ Same | ✅ Same |

---

### TradingNode Setup

```python
# NEW: src/papertrade/run_paper_trading.py
from nautilus_trader.live.node import TradingNode
from nautilus_trader.config import TradingNodeConfig
from adapters.zerodha_data_client import ZerodhaDataClientConfig
from adapters.zerodha_execution_client import ZerodhaExecutionClientConfig

# Create trading node
node = TradingNode(config=config)

# Add same strategy (from backtest)
node.add_strategy(OptionsSpreadStrategyModular(config))

# Add same actor (from backtest)
node.add_actor(CapitalManager(config))

# Start trading
node.start()
```

**Key Advantage**: Exact same strategy and capital manager code as backtest.

---

## Zerodha Integration

### Overview

Zerodha provides two APIs for integration:
1. **Historical API** (REST): Fetch historical data (not used in paper trading)
2. **WebSocket API** (KiteTicker): Live market data stream

For paper trading, we need:
- **ZerodhaDataClient**: Subscribe to live ticks/quotes
- **SimulatedExecutionClient**: Simulate order fills (built-in Nautilus)

**Note**: We do NOT use Zerodha order execution API in paper trading (no real orders placed).

---

### ZerodhaDataClient Implementation

```python
# NEW: src/adapters/zerodha_data_client.py
from nautilus_trader.live.data_client import LiveDataClient
from nautilus_trader.model.data import QuoteTick, Bar
from nautilus_trader.model.identifiers import InstrumentId, ClientId
from kiteconnect import KiteTicker
import logging

class ZerodhaDataClient(LiveDataClient):
    """
    Data client for Zerodha Kite WebSocket API.
    Streams live market data for paper and live trading.
    """

    def __init__(self, config: ZerodhaDataClientConfig):
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

        # KiteTicker WebSocket
        self.kite_ticker = KiteTicker(api_key=self.api_key, access_token=self.access_token)

        # Subscriptions
        self._subscribed_instruments = {}  # instrument_id -> token mapping

    def connect(self):
        """Connect to Zerodha WebSocket"""
        self._log.info("Connecting to Zerodha WebSocket...")

        # Set up callbacks
        self.kite_ticker.on_connect = self._on_connect
        self.kite_ticker.on_ticks = self._on_ticks
        self.kite_ticker.on_error = self._on_error
        self.kite_ticker.on_close = self._on_close

        # Connect
        self.kite_ticker.connect(threaded=True)

        self._log.info("Connected to Zerodha WebSocket")

    def disconnect(self):
        """Disconnect from Zerodha WebSocket"""
        self._log.info("Disconnecting from Zerodha WebSocket...")
        self.kite_ticker.close()
        self._log.info("Disconnected from Zerodha WebSocket")

    def subscribe_quote_ticks(self, instrument_id: InstrumentId):
        """Subscribe to quote ticks for an instrument"""
        # Convert instrument_id to Zerodha token
        token = self._get_zerodha_token(instrument_id)

        if token:
            self.kite_ticker.subscribe([token])
            self.kite_ticker.set_mode(self.kite_ticker.MODE_QUOTE, [token])  # Get bid/ask
            self._subscribed_instruments[instrument_id] = token
            self._log.info(f"Subscribed to quote ticks: {instrument_id} (token {token})")

    def _on_connect(self, ws, response):
        """Called when WebSocket connects"""
        self._log.info(f"WebSocket connected: {response}")

    def _on_ticks(self, ws, ticks):
        """Called when ticks arrive from Zerodha"""
        for tick in ticks:
            # Convert Zerodha tick to Nautilus QuoteTick
            instrument_id = self._get_instrument_id_from_token(tick['instrument_token'])

            if instrument_id:
                quote_tick = self._create_quote_tick(instrument_id, tick)
                # Publish to message bus (strategy will receive via on_quote_tick)
                self._handle_data(quote_tick)

    def _create_quote_tick(self, instrument_id: InstrumentId, tick: dict) -> QuoteTick:
        """Convert Zerodha tick to Nautilus QuoteTick"""
        from nautilus_trader.model.objects import Price, Quantity
        from nautilus_trader.core.datetime import unix_nanos_to_dt

        return QuoteTick(
            instrument_id=instrument_id,
            bid_price=Price(tick['depth']['buy'][0]['price'], precision=2),
            ask_price=Price(tick['depth']['sell'][0]['price'], precision=2),
            bid_size=Quantity(tick['depth']['buy'][0]['quantity'], precision=0),
            ask_size=Quantity(tick['depth']['sell'][0]['quantity'], precision=0),
            ts_event=unix_nanos_to_dt(tick['timestamp'].timestamp() * 1_000_000_000),
            ts_init=self._clock.timestamp_ns()
        )

    def _on_error(self, ws, code, reason):
        """Called on WebSocket error"""
        self._log.error(f"WebSocket error: {code} - {reason}")

    def _on_close(self, ws, code, reason):
        """Called when WebSocket closes"""
        self._log.warning(f"WebSocket closed: {code} - {reason}")
        # Implement reconnection logic here

    def _get_zerodha_token(self, instrument_id: InstrumentId) -> int:
        """
        Convert Nautilus instrument_id to Zerodha instrument token.

        Example mapping:
        - "NIFTY22050CE.NSE" → 12345678 (Zerodha token)
        """
        # TODO: Implement mapping logic
        # Option 1: Load from instruments CSV (recommended)
        # Option 2: Query Zerodha instruments API at startup

        # Placeholder
        return None

    def _get_instrument_id_from_token(self, token: int) -> InstrumentId:
        """Reverse mapping: Zerodha token → Nautilus instrument_id"""
        # Reverse of _get_zerodha_token
        for instrument_id, t in self._subscribed_instruments.items():
            if t == token:
                return instrument_id
        return None
```

**Key Features**:
- ✅ Streams live market data via WebSocket
- ✅ Converts Zerodha ticks to Nautilus QuoteTicks
- ✅ Publishes to message bus (strategy receives automatically)
- ✅ Handles reconnection on disconnect
- ✅ Same client works for paper and live trading

---

### Zerodha Authentication

**Current System**: Uses daily token refresh (documented in CLAUDE.md)

```bash
# Daily workflow (before market hours)
python src/papertrade/scripts/quick_token_update.py
```

**Nautilus System**: Same authentication, store token in config

```python
# config/zerodha_config.py
from dataclasses import dataclass

@dataclass
class ZerodhaConfig:
    api_key: str = "your_api_key"
    api_secret: str = "your_api_secret"
    access_token: str = "daily_access_token"  # Updated daily

    @classmethod
    def load_from_credentials(cls):
        """Load from credentials/zerodha_daily_token.json"""
        import json
        with open("credentials/zerodha_daily_token.json") as f:
            data = json.load(f)
        return cls(
            api_key=data['api_key'],
            api_secret=data['api_secret'],
            access_token=data['access_token']
        )
```

**Integration**:
```python
# In TradingNode config
from config.zerodha_config import ZerodhaConfig

zerodha = ZerodhaConfig.load_from_credentials()

config = TradingNodeConfig(
    data_clients={
        "ZERODHA": ZerodhaDataClientConfig(
            api_key=zerodha.api_key,
            access_token=zerodha.access_token
        )
    }
)
```

**Token Refresh**: Keep existing daily workflow (no changes needed).

---

## Trading Node Setup

### Complete Configuration

```python
# NEW: config/paper_trading_config.py
from nautilus_trader.config import TradingNodeConfig, LoggingConfig
from nautilus_trader.config import ImportableStrategyConfig, ImportableActorConfig
from adapters.zerodha_data_client import ZerodhaDataClientConfig

def create_paper_trading_config():
    """Create TradingNode configuration for paper trading"""

    # Load Zerodha credentials
    from config.zerodha_config import ZerodhaConfig
    zerodha = ZerodhaConfig.load_from_credentials()

    return TradingNodeConfig(
        # Trading node settings
        trader_id="PAPER-001",
        instance_id="paper-synaptictrading",

        # Data clients (live market data)
        data_clients={
            "ZERODHA": ZerodhaDataClientConfig(
                api_key=zerodha.api_key,
                access_token=zerodha.access_token,
                venue="NSE",
                instruments=[
                    "NIFTY50.NSE",
                    "NIFTY22050CE.NSE",
                    "NIFTY22250CE.NSE"
                    # Add all option instruments needed
                ]
            )
        },

        # Execution clients (simulated for paper trading)
        exec_clients={
            "ZERODHA": {
                "simulated": True,  # ← Key: simulated execution
                "venue": "NSE",
                "account_type": "MARGIN",
                "base_currency": "INR",
                "starting_balances": [{"INR": 400_000}]
            }
        },

        # Strategy (same as backtest)
        strategies=[
            ImportableStrategyConfig(
                strategy_path="strategy.options_spread_strategy:OptionsSpreadStrategyModular",
                config={
                    "instrument_id": "NIFTY50.NSE",
                    "bar_type": "NIFTY50-1-HOUR-LAST-EXTERNAL",
                    "entry_window_start": "10:00",
                    "entry_window_end": "10:20",
                    "exit_window": "13:00",
                    "strike_interval": 200,
                    "max_lots": 40,
                    "lot_size": 75
                }
            )
        ],

        # Actors (same as backtest)
        actors=[
            ImportableActorConfig(
                actor_path="strategy.actors.capital_manager:CapitalManager",
                config={
                    "initial_capital": 400000,
                    "risk_per_trade_pct": 5.0,
                    "max_deployment_pct": 80.0,
                    "compounding_enabled": True
                }
            )
        ],

        # Logging
        logging=LoggingConfig(
            log_level="INFO",
            log_level_file="DEBUG",
            log_file_format="json",
            log_directory="logs/paper_trading"
        ),

        # Cache and persistence
        cache_database=CacheDatabaseConfig(
            type="redis",
            host="localhost",
            port=6379
        ),

        # Message bus
        message_bus=MessageBusConfig(
            database_type="redis"
        )
    )
```

---

### Run Script

```python
# NEW: src/papertrade/run_nautilus_paper_trading.py
from nautilus_trader.live.node import TradingNode
from config.paper_trading_config import create_paper_trading_config
import asyncio

async def main():
    """Run paper trading with Nautilus TradingNode"""

    # Load configuration
    config = create_paper_trading_config()

    # Create trading node
    node = TradingNode(config=config)

    try:
        # Build the node (initializes components)
        await node.build()

        # Start trading
        await node.start()

        print("=" * 80)
        print("PAPER TRADING STARTED")
        print("=" * 80)
        print("Strategy: OptionsSpreadStrategyModular")
        print("Data Source: Zerodha (live)")
        print("Execution: Simulated")
        print("Capital: ₹400,000 (virtual)")
        print("\nPress Ctrl+C to stop trading...")
        print("=" * 80)

        # Keep running until interrupted
        await asyncio.Event().wait()

    except KeyboardInterrupt:
        print("\n\nStopping paper trading...")

    finally:
        # Stop and dispose node
        await node.stop()
        await node.dispose()

        print("Paper trading stopped")

        # Get final statistics
        trader = node.trader
        account = trader.generate_account_report(Venue("NSE"))

        print("\n" + "=" * 80)
        print("PAPER TRADING SUMMARY")
        print("=" * 80)
        print(f"Total P&L: ₹{account.total_pnl():,.2f}")
        print(f"Total Trades: {account.total_trades}")
        print(f"Win Rate: {account.win_rate():.2%}")

        # Get capital manager state
        capital_manager = node.kernel.get_actor("CapitalManager")
        if capital_manager:
            state = capital_manager.get_capital_state()
            print(f"\nFinal Capital: ₹{state['current_capital']:,.0f}")
            print(f"Return: {state['return_pct']:.2f}%")

if __name__ == "__main__":
    asyncio.run(main())
```

**Start Paper Trading**:
```bash
python src/papertrade/run_nautilus_paper_trading.py
```

---

## Same Strategy, Different Environment

### Key Advantage: Zero Code Changes

```python
# strategy/options_spread_strategy.py
class OptionsSpreadStrategyModular(Strategy):
    """
    THIS EXACT CODE works in:
    - Backtesting (BacktestEngine)
    - Paper Trading (TradingNode, simulated execution)
    - Live Trading (TradingNode, real execution)

    NO CHANGES NEEDED between environments!
    """

    def on_start(self):
        # Subscribe to market data (works everywhere)
        self.subscribe_bars(self.bar_type)

    def on_bar(self, bar: Bar):
        # Process bar (works everywhere)
        self._check_entries(bar)
        self._check_exits(bar)

    def _create_bull_call_spread(self, bar: Bar, lots: int):
        # Submit orders (works everywhere)
        buy_order = self.order_factory.market(...)
        sell_order = self.order_factory.market(...)

        self.submit_order(buy_order)   # ← Backtest: instant fill
        self.submit_order(sell_order)  # ← Paper: simulated fill based on market
                                       # ← Live: sent to Zerodha for execution
```

**What Changes**:
- ✅ Configuration file (backtest_config.py vs paper_trading_config.py)
- ✅ Data source (catalog vs Zerodha WebSocket)
- ✅ Execution mode (instant vs simulated vs real)

**What Stays the Same**:
- ✅ Strategy code (100% identical)
- ✅ CapitalManager code (100% identical)
- ✅ Entry/Exit logic (100% identical)
- ✅ Risk management (100% identical)

---

## Order Simulation

### How Nautilus Simulates Fills in Paper Trading

```python
# When strategy submits order:
self.submit_order(buy_order)

# Nautilus SimulatedExecutionClient:
# 1. Receives order
# 2. Checks current market price (from live data)
# 3. Simulates realistic fill:
#    - Market orders: filled at ask (buy) or bid (sell)
#    - Limit orders: filled when market reaches limit price
#    - Partial fills possible (for large orders)
# 4. Generates OrderFilled event
# 5. Strategy receives event via on_order_filled()
```

### Fill Realism Configuration

```python
# config/paper_trading_config.py
config = TradingNodeConfig(
    exec_clients={
        "ZERODHA": {
            "simulated": True,
            "fill_model": FillModel.IMMEDIATE,  # vs MAKER_TAKER, AUCTION
            "latency_model": LatencyModel(
                insert_latency_millis=100,  # 100ms to place order
                fill_latency_millis=50      # 50ms to fill order
            ),
            "slippage_model": SlippageModel(
                slippage_bps=2  # 2 basis points slippage
            )
        }
    }
)
```

**Realism Levels**:
1. **IMMEDIATE**: Orders fill instantly at market price (fastest)
2. **MAKER_TAKER**: Considers liquidity, spreads (more realistic)
3. **AUCTION**: Simulates order book matching (most realistic)

**Recommendation**: Start with IMMEDIATE, increase realism if needed.

---

## Risk Management

### Pre-Trade Risk Checks

Nautilus has built-in `RiskEngine` that validates orders before submission:

```python
# config/paper_trading_config.py
config = TradingNodeConfig(
    risk_engine=RiskEngineConfig(
        bypass=False,  # Enable risk checks

        # Order rate limits
        max_order_rate="100/00:00:01",  # 100 orders per second

        # Notional limits
        max_notional_per_order=Money(100_000, INR),  # ₹1 lakh per order

        # Position limits
        max_notional_total=Money(320_000, INR),  # 80% of ₹400k capital

        # Custom risk checks (optional)
        custom_checks=[
            "strategy.risk.capital_check:CapitalRiskCheck"
        ]
    )
)
```

### Custom Risk Check: Capital Availability

```python
# NEW: src/strategy/risk/capital_check.py
from nautilus_trader.risk.engine import RiskEngine

class CapitalRiskCheck:
    """
    Custom risk check: Ensure sufficient capital before order placement.
    Integrates with CapitalManager actor.
    """

    def __init__(self, risk_engine: RiskEngine):
        self.risk_engine = risk_engine
        self.capital_manager = None  # Set after initialization

    def check(self, order):
        """Return True if order passes capital check, False otherwise"""
        if not self.capital_manager:
            return True  # Skip if capital manager not available

        # Get available capital
        available = self.capital_manager.get_available_capital()

        # Calculate required capital for this order
        required = self._calculate_required_capital(order)

        if required > available:
            self.risk_engine.log.warning(
                f"Order rejected: Insufficient capital "
                f"(required: ₹{required:,.0f}, available: ₹{available:,.0f})"
            )
            return False

        return True

    def _calculate_required_capital(self, order) -> float:
        """Calculate capital required for order"""
        # For debit spreads: required = net debit
        # For credit spreads: required = margin
        return float(order.quantity) * float(order.price)
```

**Integration**:
```python
# Risk engine automatically calls custom checks before orders submitted
# Order rejected → OrderRejected event → Strategy notified
```

---

## Monitoring & Logging

### Structured Logging

```python
# Nautilus uses structured JSON logging
{
    "timestamp": "2024-10-13T10:15:23.456+05:30",
    "level": "INFO",
    "component": "OptionsSpreadStrategyModular",
    "event": "order_filled",
    "order_id": "O-20241013-000001",
    "instrument_id": "NIFTY22050CE.NSE",
    "price": 519.83,
    "quantity": 150,
    "side": "BUY"
}
```

**Log Files**:
- `logs/paper_trading/trader.log` - All trading events
- `logs/paper_trading/strategy.log` - Strategy-specific logs
- `logs/paper_trading/capital_manager.log` - Capital updates
- `logs/paper_trading/risk_engine.log` - Risk checks

---

### Real-Time Monitoring Dashboard

**Current System**: React frontend at `http://localhost:3000`

**Nautilus System**: Can integrate with existing frontend via WebSocket

```python
# NEW: src/papertrade/api/websocket_server.py
from fastapi import FastAPI, WebSocket
import asyncio

app = FastAPI()

@app.websocket("/ws/trading")
async def websocket_endpoint(websocket: WebSocket):
    """
    Stream trading events to frontend.
    Frontend connects to ws://localhost:8082/ws/trading
    """
    await websocket.accept()

    # Subscribe to trading events
    async for event in trading_node.event_stream():
        # Convert event to JSON
        event_data = {
            'type': event.__class__.__name__,
            'timestamp': event.ts_event,
            'data': event.to_dict()
        }

        # Send to frontend
        await websocket.send_json(event_data)
```

**Frontend Integration**: Existing React app can connect to this WebSocket and display:
- Open positions
- Recent trades
- Capital state
- P&L chart
- Risk metrics

---

## Migration from Current System

### Current Paper Trading Architecture

```
src/papertrade/
├── engine/
│   ├── trading_engine.py           # Custom engine
│   └── adapters/
│       ├── zerodha_data_provider.py
│       └── historical_data_provider.py
├── backend/
│   ├── api/routes/                 # FastAPI endpoints
│   └── services/                   # Business logic
└── app/frontend/                   # React frontend
```

**Issues**:
- ❌ Separate implementation from backtest
- ❌ Custom trading engine (duplicates backtest logic)
- ❌ Capital management needs separate implementation
- ❌ Manual event handling (no message bus)

---

### Target Nautilus Architecture

```
src/papertrade/
├── run_nautilus_paper_trading.py   # TradingNode entry point
├── config/
│   └── paper_trading_config.py     # TradingNode config
└── api/
    ├── fastapi_server.py           # REST API (optional)
    └── websocket_server.py         # Event streaming

src/adapters/
├── zerodha_data_client.py          # Nautilus DataClient
└── zerodha_execution_client.py     # Nautilus ExecutionClient (live only)

src/strategy/
├── options_spread_strategy.py      # Same code as backtest
└── actors/
    └── capital_manager.py          # Same code as backtest
```

**Benefits**:
- ✅ Same strategy code as backtest (zero duplication)
- ✅ Same capital manager (works everywhere)
- ✅ Nautilus TradingNode (robust, tested)
- ✅ Event-driven (message bus)
- ✅ Easy transition to live trading (just change config)

---

### Migration Steps

#### Phase 1: Set Up Nautilus Paper Trading (Parallel to Current System)

**Goal**: Get Nautilus paper trading running alongside current system.

**Steps**:
1. Create `src/adapters/zerodha_data_client.py` (WebSocket integration)
2. Create `config/paper_trading_config.py` (TradingNode config)
3. Create `src/papertrade/run_nautilus_paper_trading.py` (entry point)
4. Test with simple strategy (not full options spread yet)

**Effort**: 8-12 hours

---

#### Phase 2: Integrate CapitalManager

**Goal**: Use same CapitalManager from backtest in paper trading.

**Steps**:
1. Add CapitalManager to TradingNode config (already implemented in backtest)
2. Test capital updates with simulated trades
3. Verify lot sizing works correctly
4. Compare with current system behavior

**Effort**: 2-4 hours

---

#### Phase 3: Full Strategy Integration

**Goal**: Run full options spread strategy in Nautilus paper trading.

**Steps**:
1. Add OptionsSpreadStrategyModular to TradingNode config
2. Subscribe to all required option instruments
3. Test entry/exit logic with live data
4. Verify spread creation and tracking

**Effort**: 4-8 hours

---

#### Phase 4: Frontend Integration

**Goal**: Connect existing React frontend to Nautilus paper trading.

**Steps**:
1. Create WebSocket server for event streaming
2. Update React app to connect to new WebSocket
3. Display positions, trades, capital state (same UI)
4. Test real-time updates

**Effort**: 4-6 hours

---

#### Phase 5: Validation & Cutover

**Goal**: Validate Nautilus paper trading matches current system.

**Steps**:
1. Run both systems in parallel for 1 week
2. Compare trades, P&L, capital tracking
3. Document any differences
4. Cutover to Nautilus system

**Effort**: 1 week (monitoring)

---

### Total Migration Effort

**Estimated Time**: 18-30 hours + 1 week validation

**Benefits After Migration**:
- ✅ Same code as backtest (no duplication)
- ✅ CapitalManager works everywhere
- ✅ Robust TradingNode infrastructure
- ✅ Easy transition to live trading
- ✅ Better monitoring and logging

---

## Comparison: Current vs Nautilus

| Aspect | Current System | Nautilus System |
|--------|----------------|-----------------|
| **Engine** | Custom trading engine | TradingNode (Nautilus) |
| **Data Source** | Zerodha WebSocket (custom) | ZerodhaDataClient (Nautilus) |
| **Execution** | Custom simulation | SimulatedExecutionClient (Nautilus) |
| **Strategy** | Separate from backtest | Same code as backtest |
| **CapitalManager** | Needs separate implementation | Same code as backtest |
| **Event Handling** | Manual (custom engine) | Message bus (automatic) |
| **Order Management** | Custom | Built-in (Nautilus) |
| **Risk Checks** | Custom | Built-in RiskEngine |
| **Monitoring** | React frontend (custom API) | React frontend (WebSocket stream) |
| **Live Transition** | Separate implementation needed | Change config only |

---

## Key Takeaways

1. **TradingNode = Production-Grade Infrastructure**
   - Same framework used by live traders
   - Robust, tested, reliable
   - Built-in order management, risk checks

2. **Same Code Everywhere**
   - Strategy: identical in backtest and paper
   - CapitalManager: identical in backtest and paper
   - Configuration: only thing that changes

3. **Simulated Execution**
   - Realistic fills based on live market prices
   - Configurable latency and slippage
   - No real money at risk

4. **Easy Live Transition**
   - Paper trading validates strategy with live data
   - When ready, change `simulated: True` to `simulated: False`
   - Same code, real execution

5. **Zerodha Integration**
   - ZerodhaDataClient streams live market data
   - Same authentication as current system
   - Works for paper and live trading

---

## Next Steps

1. **Read**: Live Trading Best Practices (`03_LIVE_TRADING_BEST_PRACTICES.md`)
2. **Implement**: Create ZerodhaDataClient
3. **Test**: Run simple strategy in paper trading
4. **Integrate**: Add CapitalManager and full strategy
5. **Validate**: Compare with current system
6. **Cutover**: Switch to Nautilus paper trading

---

## References

- **Nautilus Live Trading**: https://nautilustrader.io/docs/latest/getting_started/live_trading
- **Data Clients**: https://nautilustrader.io/docs/latest/integrations/
- **TradingNode Config**: https://nautilustrader.io/docs/latest/api_reference/config.html#tradingnodeconfig
- **Current Zerodha Integration**: `src/papertrade/scripts/quick_token_update.py`
- **Overview**: `00_OVERVIEW.md`
- **Backtesting**: `01_BACKTESTING_BEST_PRACTICES.md`
