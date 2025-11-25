---
artifact_type: story
created_at: '2025-11-25T16:23:21.860333Z'
id: AUTO-04_BACKTESTING_BEST_PRACTICES
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for 04_BACKTESTING_BEST_PRACTICES
updated_at: '2025-11-25T16:23:21.860337Z'
---

## Introduction

Nautilus backtesting provides a **fully event-driven simulation** of live trading with:
- Realistic order execution (fills, slippage, latency)
- Built-in position tracking and P&L calculation
- Actor/Strategy pattern (same code works in paper/live)
- High performance (Rust core)
- Type safety (msgspec serialization)

**Key Principle**: If it works in backtest, it will work the same way in paper trading and live trading.

---

## Backtest Engine Architecture

### Core Components

```python
from nautilus_trader.backtest.engine import BacktestEngine, BacktestEngineConfig
from nautilus_trader.model.identifiers import Venue

# 1. Create backtest engine
engine = BacktestEngine(config=config)

# 2. Add venue (exchange)
engine.add_venue(
    venue=Venue("NSE"),
    oms_type=OmsType.NETTING,
    account_type=AccountType.MARGIN,
    base_currency=INR,
    starting_balances=[Money(400_000, INR)]
)

# 3. Add instruments (NIFTY options)
for instrument in instruments:
    engine.add_instrument(instrument)

# 4. Add data (quote ticks, bars)
engine.add_data(quote_ticks, client_id=ClientId("NSE"))

# 5. Add strategy
engine.add_strategy(OptionsSpreadStrategyModular(config))

# 6. Add actors (capital manager, risk monitor)
engine.add_actor(CapitalManager(config))

# 7. Run backtest
engine.run()

# 8. Get results
stats = engine.trader.generate_account_report(Venue("NSE"))
```

### Event Flow in Backtest

```
1. Data Event (Bar closes at 10:15 AM)
   ↓
2. Strategy.on_bar() called
   ↓
3. Strategy evaluates entry conditions
   ↓
4. Strategy.submit_order(BUY 22050 CE)
   ↓
5. ExecutionEngine processes order
   ↓
6. OrderFilled event generated
   ↓
7. Portfolio updates position
   ↓
8. CapitalManager.on_position_opened() called
   ↓
9. Position tracked, capital reserved
```

**Key Insight**: All components react to events, no manual polling required.

---

## Data Loading

### Nautilus Native Catalog Usage (BEST PRACTICE)

**Use Nautilus native catalog methods instead of custom indexing:**

```python
# ✅ CORRECT - Nautilus Native Way
from nautilus_trader.persistence.catalog import ParquetDataCatalog

catalog = ParquetDataCatalog('data/catalogs/v12_real_enhanced_hourly')

# Get all instruments from catalog metadata
instruments = catalog.instruments()  # Returns all 33,408 instruments
print(f"Catalog has {len(instruments)} instruments")

# Filter instruments by date range using native expiration_ns
from datetime import datetime
start_date = datetime(2024, 1, 1)
end_date = datetime(2024, 3, 31)

filtered_instruments = [
    inst for inst in instruments
    if start_date <= datetime.fromtimestamp(inst.expiration_ns / 1e9) <= end_date
]

# Load bars for specific instruments (filtered at catalog level)
instrument_ids = [str(inst.id) for inst in filtered_instruments[:10]]
bars = catalog.bars(
    instrument_ids=instrument_ids,  # Filter at source for performance
    start=pd.Timestamp(start_date, tz='UTC'),
    end=pd.Timestamp(end_date, tz='UTC')
)
```

**Why This Is Best Practice:**
1. **Native Metadata** - Nautilus catalog already has `metadata/instruments.json` with all instruments
2. **No Custom Index Needed** - Don't create `.instrument_metadata.json` files (duplicates functionality)
3. **Filtered Data Loading** - Use `instrument_ids` parameter to only load needed bars
4. **Consistent API** - Standard Nautilus interface works across all catalogs

**Performance:**
- `catalog.instruments()` loads from native metadata (~100ms for 33K instruments)
- `catalog.bars(instrument_ids=[...])` filters at source (60-80% faster than loading all then filtering)

**Catalog Structure:**
```
data/catalogs/v12_real_enhanced_hourly/
├── metadata/
│   ├── catalog.json          # Catalog metadata (version, date range, row count)
│   └── instruments.json       # All instruments (33,408 instruments) ✅ USE THIS
├── data/
│   └── bar/
│       ├── NIFTY240104C17000.NSE-1-HOUR-LAST-EXTERNAL/
│       │   └── *.parquet
│       └── ...
└── .instrument_metadata.json  # ❌ Custom index (not needed)
```

---

### Current System (Custom Adapter)

```python
# Current: Custom adapter reading parquet files
adapter = NautilusParquetV4DataAdapter(catalog_id="v10_real_enhanced_clean")
adapter.load_data()
data = adapter.nautilus_data  # Pandas DataFrame

# Manual iteration
for timestamp in timestamps:
    market_data = adapter.get_market_data(timestamp)
    strategy.on_market_data(timestamp, market_data)
```

**Issues**:
- Manual timestamp iteration
- No realistic order execution
- Custom data structures (not Nautilus native)

---

### Nautilus System (Framework-Managed)

#### Step 1: Load Data into Nautilus Catalog

```python
# NEW: src/backtest/load_catalog.py
from nautilus_trader.persistence.catalog import ParquetDataCatalog
from nautilus_trader.model.data import QuoteTick, Bar
import pandas as pd

def load_options_data_to_catalog(catalog_path: str, source_parquet_path: str):
    """
    Load options data from custom parquet format into Nautilus catalog.
    This is a ONE-TIME conversion step.
    """
    catalog = ParquetDataCatalog(catalog_path)

    # Read your existing parquet data
    df = pd.read_parquet(source_parquet_path)

    # Convert to Nautilus native objects
    quote_ticks = []
    for _, row in df.iterrows():
        tick = QuoteTick(
            instrument_id=InstrumentId.from_str(f"NIFTY{row['strike']}{row['option_type']}.NSE"),
            bid_price=Price(row['bid'], precision=2),
            ask_price=Price(row['ask'], precision=2),
            bid_size=Quantity(row['bid_size'], precision=0),
            ask_size=Quantity(row['ask_size'], precision=0),
            ts_event=pd.Timestamp(row['timestamp']).value,
            ts_init=pd.Timestamp(row['timestamp']).value
        )
        quote_ticks.append(tick)

    # Write to Nautilus catalog
    catalog.write_data(quote_ticks)
    catalog.write_data(bars)  # If you have bar data

    print(f"✅ Loaded {len(quote_ticks)} ticks into catalog")
```

**Run Once**:
```bash
python src/backtest/load_catalog.py \
    --catalog-path data/nautilus_catalog \
    --source-parquet data/v10_real_enhanced_clean.parquet
```

---

#### Step 2: Configure Data Loading in Backtest

```python
# config/backtest_config.py
from nautilus_trader.config import BacktestDataConfig, BacktestEngineConfig

config = BacktestEngineConfig(
    data_configs=[
        BacktestDataConfig(
            catalog_path="data/nautilus_catalog",
            data_cls=QuoteTick,
            instrument_id="NIFTY22050CE.NSE",
            start_time="2024-01-01",
            end_time="2024-12-31"
        ),
        BacktestDataConfig(
            catalog_path="data/nautilus_catalog",
            data_cls=Bar,
            instrument_id="NIFTY50.NSE",
            bar_spec="1-HOUR-LAST",
            start_time="2024-01-01",
            end_time="2024-12-31"
        )
    ]
)
```

**Key Advantages**:
- Framework loads data automatically
- Data delivered via events (no manual iteration)
- Realistic timestamp progression
- Built-in data caching

---

### Handling Multi-Leg Options Data

Our strategy uses **spreads** (2-leg positions). Nautilus doesn't have native spread instruments, so we:

**Option 1: Track Legs Separately**
```python
class OptionsSpreadStrategyModular(Strategy):
    def on_start(self):
        # Subscribe to both legs
        self.subscribe_quote_ticks(InstrumentId.from_str("NIFTY22050CE.NSE"))
        self.subscribe_quote_ticks(InstrumentId.from_str("NIFTY22250CE.NSE"))

    def on_quote_tick(self, tick: QuoteTick):
        # React to leg price updates
        if self._both_legs_have_prices():
            self.evaluate_spread_entry()
```

**Option 2: Create Synthetic Spread Instrument**
```python
# Define custom spread instrument (advanced)
class OptionSpreadInstrument(Instrument):
    def __init__(self, long_leg, short_leg):
        self.long_leg = long_leg
        self.short_leg = short_leg
        # Custom pricing logic for spread
```

**Recommendation**: Start with Option 1 (track legs separately), simpler for backtesting.

---

## Strategy Implementation

### Current Strategy (Custom Class)

```python
# Current: src/strategy/options_spread_strategy_modular.py
class OptionsSpreadStrategyModular:
    def __init__(self, data_provider, execution_engine, risk_manager, config):
        self.data_provider = data_provider
        self.execution_engine = execution_engine
        # ...

    def on_market_data(self, timestamp, market_data):
        # Manual data processing
        self.check_exits(timestamp, market_data)
        self.check_entries(timestamp, market_data)
```

---

### Nautilus Strategy (Framework-Integrated)

```python
# NEW: src/strategy/options_spread_strategy.py
from nautilus_trader.trading.strategy import Strategy
from nautilus_trader.model.data import Bar, QuoteTick
from nautilus_trader.model.orders import MarketOrder
from nautilus_trader.model.identifiers import InstrumentId

class OptionsSpreadStrategyModular(Strategy):
    """
    Options spread strategy using Nautilus framework.
    Works in backtest, paper, and live environments.
    """

    def __init__(self, config):
        super().__init__(config)

        # Configuration
        self.instrument_id = InstrumentId.from_str(config.instrument_id)
        self.bar_type = BarType.from_str(config.bar_type)

        # Components (same as current)
        self.entry_manager = EntryManager(config)
        self.exit_manager = ExitManager(config)
        self.position_tracker = PositionTracker()  # Wraps self.portfolio

        # Capital manager reference (set by framework)
        self.capital_manager = None

    def on_start(self):
        """Called when strategy starts (any environment)"""
        # Subscribe to market data
        self.subscribe_bars(self.bar_type)
        self.subscribe_quote_ticks(self.instrument_id)

        # Get capital manager reference
        self.capital_manager = self.clock.get_actor("CapitalManager")

        self.log.info(f"Strategy started, subscribed to {self.bar_type}")

    def on_stop(self):
        """Called when strategy stops"""
        self.log.info("Strategy stopped, closing all positions")
        self.close_all_positions(self.instrument_id)

    def on_bar(self, bar: Bar):
        """
        Called when new bar closes (e.g., hourly bar at 10:15 AM).
        Replaces current on_market_data() method.
        """
        self.log.info(f"Bar received: {bar.close} at {bar.ts_event}")

        # 1. Check exits first (highest priority)
        self._check_exits(bar)

        # 2. Check entries (during entry window)
        if TimezoneHandler.is_entry_window(bar.ts_event):
            self._check_entries(bar)

        # 3. Update risk metrics
        self._update_risk_metrics(bar)

    def on_quote_tick(self, tick: QuoteTick):
        """Called when new quote tick arrives (for option legs)"""
        # Update option prices for spread valuation
        self.position_tracker.update_option_price(tick.instrument_id, tick.ask_price)

    def _check_entries(self, bar: Bar):
        """Check entry conditions using EntryManager"""
        # Ask capital manager for dynamic lot size
        capital_per_lot = self.entry_manager.calculate_capital_per_lot(bar.close)
        max_lots = self.capital_manager.calculate_max_lots(
            capital_per_lot=capital_per_lot,
            max_lots_config=self.config.max_lots
        )

        if max_lots == 0:
            self.log.warning("Insufficient capital for entry")
            return

        # Check if entry conditions met
        if self.entry_manager.should_enter(bar, self.portfolio):
            # Create spread (buy long leg, sell short leg)
            self._create_bull_call_spread(bar, lots=max_lots)

    def _create_bull_call_spread(self, bar: Bar, lots: int):
        """Create bull call spread (2-leg position)"""
        # Long leg: BUY ATM call
        long_leg_instrument = InstrumentId.from_str(f"NIFTY22050CE.NSE")
        buy_order = self.order_factory.market(
            instrument_id=long_leg_instrument,
            order_side=OrderSide.BUY,
            quantity=Quantity(lots * 75, precision=0)  # 75 shares per lot
        )

        # Short leg: SELL OTM call (ATM + 200)
        short_leg_instrument = InstrumentId.from_str(f"NIFTY22250CE.NSE")
        sell_order = self.order_factory.market(
            instrument_id=short_leg_instrument,
            order_side=OrderSide.SELL,
            quantity=Quantity(lots * 75, precision=0)
        )

        # Submit both orders
        self.submit_order(buy_order)
        self.submit_order(sell_order)

        self.log.info(f"Bull call spread created: BUY {long_leg_instrument}, SELL {short_leg_instrument}, lots={lots}")

    def _check_exits(self, bar: Bar):
        """Check exit conditions using ExitManager"""
        for position in self.portfolio.positions_open():
            should_exit, reason = self.exit_manager.should_exit(position, bar)

            if should_exit:
                self.log.info(f"Exiting position {position.id}: {reason}")
                self.close_position(position)

    def on_order_filled(self, event: OrderFilled):
        """Called when order fills (automatic by framework)"""
        self.log.info(f"Order filled: {event.order_id} @ {event.last_price}")

    def on_position_opened(self, event: PositionOpened):
        """Called when position opens"""
        self.log.info(f"Position opened: {event.position_id}")

    def on_position_closed(self, event: PositionClosed):
        """Called when position closes"""
        self.log.info(f"Position closed: {event.position_id}, P&L: ₹{event.realized_pnl}")
        # Capital manager automatically updates via its own subscription
```

**Key Differences**:
1. ✅ Inherits from `Strategy` (not custom class)
2. ✅ Uses `on_bar()` instead of `on_market_data()`
3. ✅ Framework calls methods automatically (event-driven)
4. ✅ Built-in order submission (`self.submit_order()`)
5. ✅ Built-in position tracking (`self.portfolio`)
6. ✅ Actor integration (capital manager)

---

## Actor Integration

### CapitalManager as Nautilus Actor

```python
# NEW: src/strategy/actors/capital_manager.py
from nautilus_trader.trading.strategy import Actor
from nautilus_trader.model.events import PositionClosed, PositionOpened
from nautilus_trader.model.enums import OrderSide

class CapitalManager(Actor):
    """
    Manages trading capital with dynamic lot sizing and compounding.
    Works in backtest, paper trading, and live trading.
    """

    def __init__(self, config):
        super().__init__()

        # Configuration
        self.initial_capital = config.initial_capital
        self.current_capital = self.initial_capital
        self.risk_pct = config.risk_per_trade_pct
        self.max_deployment_pct = config.max_deployment_pct
        self.compounding_enabled = config.compounding_enabled

        # Tracking
        self._capital_history = []
        self._deployed_capital = 0.0

    def on_start(self):
        """Called when actor starts (any environment)"""
        # Subscribe to position events
        self.subscribe_event_type(PositionClosed)
        self.subscribe_event_type(PositionOpened)

        self.log.info(f"CapitalManager started")
        self.log.info(f"  Initial capital: ₹{self.initial_capital:,.0f}")
        self.log.info(f"  Risk per trade: {self.risk_pct}%")
        self.log.info(f"  Max deployment: {self.max_deployment_pct}%")
        self.log.info(f"  Compounding: {self.compounding_enabled}")

    def on_event(self, event):
        """Process events from message bus"""
        if isinstance(event, PositionOpened):
            self.on_position_opened(event)
        elif isinstance(event, PositionClosed):
            self.on_position_closed(event)

    def on_position_opened(self, event: PositionOpened):
        """Track capital deployment when position opens"""
        # For debit spreads: capital = net debit paid
        # For credit spreads: capital = margin required
        deployed = self._calculate_deployed_capital(event)
        self._deployed_capital += deployed

        self.log.info(f"Position opened: {event.position_id}")
        self.log.info(f"  Capital deployed: ₹{deployed:,.0f}")
        self.log.info(f"  Total deployed: ₹{self._deployed_capital:,.0f}")
        self.log.info(f"  Available: ₹{self.get_available_capital():,.0f}")

    def on_position_closed(self, event: PositionClosed):
        """Update capital when position closes"""
        # Calculate P&L
        trade_pnl = float(event.realized_pnl)

        # Release deployed capital
        released = self._calculate_deployed_capital(event)
        self._deployed_capital -= released

        # Update capital (if compounding enabled)
        previous_capital = self.current_capital
        if self.compounding_enabled:
            self.current_capital += trade_pnl

        # Track history
        self._capital_history.append({
            'timestamp': event.ts_event,
            'position_id': str(event.position_id),
            'previous_capital': previous_capital,
            'trade_pnl': trade_pnl,
            'new_capital': self.current_capital,
            'deployed_capital': self._deployed_capital
        })

        self.log.info(f"Position closed: {event.position_id}")
        self.log.info(f"  P&L: ₹{trade_pnl:,.0f}")
        self.log.info(f"  Capital: ₹{previous_capital:,.0f} → ₹{self.current_capital:,.0f}")
        self.log.info(f"  Available: ₹{self.get_available_capital():,.0f}")

    def calculate_max_lots(self, capital_per_lot: float, max_lots_config: int) -> int:
        """
        Calculate maximum lots based on current capital and risk limits.

        This is called by the strategy before entering a position.
        """
        available = self.get_available_capital()

        # Risk-based limit (5% of capital per trade)
        risk_capital = self.current_capital * (self.risk_pct / 100)
        max_lots_by_risk = int(risk_capital / capital_per_lot)

        # Deployment-based limit (80% total deployment)
        deployment_capital = self.current_capital * (self.max_deployment_pct / 100)
        max_lots_by_deployment = int((deployment_capital - self._deployed_capital) / capital_per_lot)

        # Take minimum of all limits
        actual_lots = min(
            max_lots_by_risk,
            max_lots_by_deployment,
            max_lots_config  # Config maximum
        )

        # At least 1 lot if any capital available
        actual_lots = max(0, actual_lots)

        self.log.debug(f"Lot calculation:")
        self.log.debug(f"  Available capital: ₹{available:,.0f}")
        self.log.debug(f"  Capital per lot: ₹{capital_per_lot:,.0f}")
        self.log.debug(f"  Max by risk: {max_lots_by_risk} lots")
        self.log.debug(f"  Max by deployment: {max_lots_by_deployment} lots")
        self.log.debug(f"  Max by config: {max_lots_config} lots")
        self.log.debug(f"  ACTUAL: {actual_lots} lots")

        return actual_lots

    def get_available_capital(self) -> float:
        """Get capital available for new positions"""
        return self.current_capital - self._deployed_capital

    def get_capital_state(self) -> dict:
        """Get current capital state for monitoring"""
        return {
            'current_capital': self.current_capital,
            'initial_capital': self.initial_capital,
            'deployed_capital': self._deployed_capital,
            'available_capital': self.get_available_capital(),
            'total_return': self.current_capital - self.initial_capital,
            'return_pct': ((self.current_capital / self.initial_capital) - 1) * 100,
            'deployment_pct': (self._deployed_capital / self.current_capital) * 100 if self.current_capital > 0 else 0
        }

    def _calculate_deployed_capital(self, event) -> float:
        """Calculate capital deployed/released for a position"""
        # For options spreads:
        # - Debit spreads: deployed = net debit paid upfront
        # - Credit spreads: deployed = margin required

        # Access position to get entry/exit details
        position = event.position

        # For debit spreads (bull call, bear put):
        # deployed = abs(entry_price) * quantity
        # For credit spreads (bull put, bear call):
        # deployed = margin (strike width * margin_pct)

        # Simplified: use position value
        return abs(float(position.quantity) * float(position.avg_px_open))
```

**Integration in Backtest**:
```python
# config/backtest_config.py
config = BacktestEngineConfig(
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
    ]
)
```

---

### ResultsTrackerActor (Sprint 13)

**Purpose**: Automatic results tracking and export across all environments (backtest, paper, live).

**Problem Solved**: Eliminates manual results tracking code. In Sprint 12, we used a wrapper pattern that required manual calls to `start_backtest()`, `update_pnl()`, and `finalize_and_export()`. Sprint 13 converts this to Nautilus Actor pattern for automatic, event-driven tracking.

```python
# src/nautilus/actors/results_tracker_actor.py
from nautilus_trader.common.actor import Actor
from nautilus_trader.model.events import PositionClosed, AccountState
from pathlib import Path

class ResultsTrackerActor(Actor):
    """
    Nautilus Actor for automatic results tracking.

    Subscribes to trading events and tracks:
    - Trade lifecycle (via PositionClosed events)
    - Daily P&L (via AccountState events)
    - System metadata (git, config, performance)

    Works identically in backtest, paper, and live trading.
    """

    def __init__(self, config, catalog_path=None, catalog_format="v12"):
        super().__init__()

        self.config = config
        self.catalog_path = catalog_path
        self.catalog_format = catalog_format

        # Initialize tracking components (from Sprint 12)
        # - MetadataTracker: System, git, config info
        # - DailyPnLTracker: Daily portfolio values
        # - ResultsExporter: CSV/JSON export
        self.trades = []

    def on_start(self):
        """Called when actor starts (backtest/paper/live)"""
        # Subscribe to events
        self.subscribe(PositionClosed)
        # AccountState events are published automatically by Nautilus

        # Capture metadata
        self.metadata_tracker.capture_system_info()
        self.metadata_tracker.capture_git_info()
        self.metadata_tracker.start_execution()

        self._log.info(f"ResultsTrackerActor started - results will be saved to: {self.results_dir}")

    def on_stop(self):
        """Called when actor stops - export results automatically"""
        # Finalize and export all results (4 files)
        self.finalize_and_export()

        self._log.info(f"✅ Results exported to: {self.results_dir}")

    def on_event(self, event):
        """Handle all subscribed events"""
        if isinstance(event, PositionClosed):
            self.on_position_closed(event)
        elif isinstance(event, AccountState):
            self.on_account_state(event)

    def on_position_closed(self, event: PositionClosed):
        """Handle position closed event - track trade"""
        # Get position from cache
        position = self.cache.position(event.position_id)

        # Extract trade data
        trade_data = {
            'spread_id': str(position.id),
            'entry_timestamp': datetime.fromtimestamp(position.ts_opened / 1e9),
            'exit_timestamp': datetime.fromtimestamp(position.ts_closed / 1e9),
            'realized_pnl': float(position.realized_pnl.as_double()),
            'status': 'closed'
        }

        self.trades.append(trade_data)
        self._log.info(f"Trade tracked: {trade_data['spread_id']} | P&L: ₹{trade_data['realized_pnl']:.2f}")

    def on_account_state(self, event: AccountState):
        """Handle account state update - track P&L"""
        timestamp = datetime.fromtimestamp(event.ts_event / 1e9)
        balance_total = float(event.balance_total())
        cumulative_pnl = balance_total - self.initial_capital

        # Update daily P&L tracker
        self.pnl_tracker.update(
            timestamp=timestamp,
            cumulative_pnl=cumulative_pnl,
            portfolio_value=balance_total
        )

    def finalize_and_export(self):
        """Finalize tracking and export all results"""
        # Calculate statistics
        statistics = calculate_statistics_from_trades(self.trades, self.initial_capital)

        # Export 4 files:
        # - backtest_metadata.json
        # - trade_log.csv
        # - daily_pnl.csv
        # - statistics.json
        exported_files = self.exporter.export_all_results(
            trades=self.trades,
            statistics=statistics,
            metadata_tracker=self.metadata_tracker,
            pnl_tracker=self.pnl_tracker
        )

        return exported_files
```

**Key Benefits**:

1. **Automatic Tracking** (no manual integration)
   ```python
   # Sprint 12 (wrapper pattern - manual calls)
   results_mgr.start_backtest()           # Manual
   results_mgr.update_pnl(...)            # Manual (every timestamp)
   results_mgr.finalize_and_export(...)   # Manual

   # Sprint 13 (actor pattern - automatic)
   engine.add_actor(ResultsTrackerActor(config))  # Automatic tracking via events
   ```

2. **Event-Driven** (subscribes to PositionClosed, AccountState events)

3. **Cross-Environment** (works in backtest, paper, live without code changes)

4. **Output Files** (generated on `on_stop()` automatically):
   - `backtest_metadata.json` - System, git, config metadata
   - `trade_log.csv` - Individual trade records
   - `daily_pnl.csv` - Daily portfolio values and drawdown
   - `statistics.json` - Performance metrics

**Integration in Backtest**:
```python
# Add ResultsTrackerActor to engine
results_actor = ResultsTrackerActor(
    config=config,
    catalog_path=catalog_path,
    catalog_format='v12'
)
engine.add_actor(results_actor)

# Run backtest
engine.run()

# Results automatically exported during on_stop()
# Access results directory
print(f"Results saved to: {results_actor.get_results_directory()}")
```

**Example**: See `examples/nautilus/backtest_with_results_actor.py`

**Documentation**: See `src/nautilus/actors/README.md` for full Actor documentation.

---

## Configuration

### Backtest Configuration File

```python
# config/backtest_config.py
from nautilus_trader.config import BacktestEngineConfig, BacktestVenueConfig, BacktestDataConfig
from nautilus_trader.config import ImportableStrategyConfig, ImportableActorConfig
from nautilus_trader.model.enums import AccountType, OmsType
from nautilus_trader.model.currencies import INR
from nautilus_trader.model.objects import Money

config = BacktestEngineConfig(
    # Trading venue (NSE)
    venues=[
        BacktestVenueConfig(
            name="NSE",
            venue_type="EXCHANGE",
            account_type=AccountType.MARGIN,
            base_currency=INR,
            starting_balances=[Money(400_000, INR)],  # Initial capital
            oms_type=OmsType.NETTING,
            book_type=BookType.L1_MBP
        )
    ],

    # Data configuration
    data=[
        BacktestDataConfig(
            catalog_path="data/nautilus_catalog",
            data_cls=QuoteTick,
            instrument_id="NIFTY22050CE.NSE",
            start_time="2024-01-01T09:15:00+05:30",
            end_time="2024-12-31T15:30:00+05:30"
        ),
        BacktestDataConfig(
            catalog_path="data/nautilus_catalog",
            data_cls=Bar,
            instrument_id="NIFTY50.NSE",
            bar_spec="1-HOUR-LAST",
            start_time="2024-01-01T09:15:00+05:30",
            end_time="2024-12-31T15:30:00+05:30"
        )
    ],

    # Strategy configuration
    strategies=[
        ImportableStrategyConfig(
            strategy_path="strategy.options_spread_strategy:OptionsSpreadStrategyModular",
            config_path="config.strategy_config:StrategyConfig",
            config={
                "instrument_id": "NIFTY50.NSE",
                "bar_type": "NIFTY50-1-HOUR-LAST-EXTERNAL",
                "entry_window_start": "10:00",
                "entry_window_end": "10:20",
                "exit_window": "13:00",
                "strike_interval": 200,
                "max_lots": 40,
                "lot_size": 75,
                "target_profit_pct": 60,
                "stop_loss_pct": 50,
                "portfolio_stop_loss_pct": 5
            }
        )
    ],

    # Actors (capital manager, risk monitor)
    actors=[
        ImportableActorConfig(
            actor_path="strategy.actors.capital_manager:CapitalManager",
            config={
                "initial_capital": 400000,
                "risk_per_trade_pct": 5.0,
                "max_deployment_pct": 80.0,
                "compounding_enabled": True,
                "min_capital_threshold_pct": 50.0,
                "max_capital_multiplier": 2.0
            }
        )
    ],

    # Execution settings
    logging=LoggingConfig(
        log_level="INFO",
        log_level_file="DEBUG",
        log_file_format="json"
    ),

    # Risk engine settings
    risk_engine=RiskEngineConfig(
        bypass=False,  # Enable pre-trade risk checks
        max_order_rate="100/00:00:01",  # 100 orders per second
        max_notional_per_order=Money(100_000, INR)
    )
)
```

---

## Running Backtests

### Run Script

```python
# src/backtest/run_nautilus_backtest.py
from nautilus_trader.backtest.engine import BacktestEngine
from pathlib import Path
import json

def run_backtest():
    """Run Nautilus backtest with options spread strategy"""

    # Load configuration
    from config.backtest_config import config

    # Create backtest engine
    engine = BacktestEngine(config=config)

    # Run backtest
    print("Starting Nautilus backtest...")
    engine.run()
    print("Backtest complete!")

    # Get results
    trader = engine.trader
    account = trader.generate_account_report(Venue("NSE"))
    stats = trader.generate_order_fills_report()

    # Print summary
    print("\n" + "=" * 80)
    print("BACKTEST RESULTS")
    print("=" * 80)
    print(f"Total P&L: ₹{account.total_pnl():,.2f}")
    print(f"Total Trades: {len(stats)}")
    print(f"Win Rate: {account.win_rate():.2%}")
    print(f"Sharpe Ratio: {account.sharpe_ratio():.2f}")
    print(f"Max Drawdown: {account.max_drawdown():.2%}")

    # Get capital manager state
    capital_manager = engine.kernel.get_actor("CapitalManager")
    capital_state = capital_manager.get_capital_state()

    print("\nCAPITAL MANAGEMENT")
    print("=" * 80)
    print(f"Initial Capital: ₹{capital_state['initial_capital']:,.0f}")
    print(f"Final Capital: ₹{capital_state['current_capital']:,.0f}")
    print(f"Return: ₹{capital_state['total_return']:,.0f} ({capital_state['return_pct']:.2f}%)")
    print(f"Deployed: ₹{capital_state['deployed_capital']:,.0f} ({capital_state['deployment_pct']:.2f}%)")

    # Save results
    results_dir = Path("backtest_results") / datetime.now().strftime("%Y%m%d_%H%M%S")
    results_dir.mkdir(parents=True, exist_ok=True)

    # Save trade log
    trade_log = trader.generate_order_fills_report()
    trade_log.to_csv(results_dir / "trade_log.csv")

    # Save statistics
    with open(results_dir / "statistics.json", "w") as f:
        json.dump({
            'account': account.to_dict(),
            'capital': capital_state
        }, f, indent=2)

    print(f"\n✅ Results saved to {results_dir}")

    return engine

if __name__ == "__main__":
    engine = run_backtest()
```

**Run Backtest**:
```bash
python src/backtest/run_nautilus_backtest.py
```

---

## Performance Optimization

### Current System Performance

From existing cleanup docs:
- **Data Load**: 4-6s (pickle cache) or 9s (parquet)
- **Backtest Execution**: ~17s for 3 months
- **Total**: ~23s

### Nautilus Performance Optimizations

1. **Pre-compiled Data Catalog**
```bash
# ONE-TIME: Load data into Nautilus catalog (parquet format)
python src/backtest/load_catalog.py

# Subsequent backtests load from catalog (2-3s vs 9s)
```

2. **Rust Core**
- Order matching: Rust implementation (100x faster than Python)
- Event processing: Zero-copy msgspec serialization
- Data streaming: Memory-mapped parquet files

3. **Incremental Backtesting**
```python
# Run backtest for specific date range
config.start_time = "2024-01-01"
config.end_time = "2024-01-31"  # Just January

# Or run multiple periods in parallel
from concurrent.futures import ProcessPoolExecutor

periods = [
    ("2024-01-01", "2024-03-31"),
    ("2024-04-01", "2024-06-30"),
    ("2024-07-01", "2024-09-30"),
    ("2024-10-01", "2024-12-31")
]

with ProcessPoolExecutor(max_workers=4) as executor:
    results = executor.map(run_backtest_period, periods)
```

**Expected Performance**:
- Data load: 2-3s (from Nautilus catalog)
- Backtest execution: 10-15s (Rust core)
- **Total**: 12-18s (similar to current system)

---

## Migration from Current System

### Step-by-Step Migration Plan

#### Phase 1: CapitalManager as Actor (IMMEDIATE)

**Goal**: Get capital management working in Nautilus backtest.

**Steps**:
1. Create `src/strategy/actors/capital_manager.py` (see code above)
2. Create minimal Nautilus backtest config
3. Test capital tracking with simple strategy
4. Verify capital updates after trades

**Effort**: 2-4 hours

---

#### Phase 2: Convert Strategy to Nautilus Strategy

**Goal**: Wrap existing strategy logic in Nautilus Strategy class.

**Steps**:
1. Create `src/strategy/options_spread_strategy.py`
2. Inherit from `nautilus_trader.trading.strategy.Strategy`
3. Move `on_market_data()` logic to `on_bar()`
4. Replace custom order submission with `self.submit_order()`
5. Keep EntryManager and ExitManager as-is (helper classes)

**Effort**: 4-8 hours

---

#### Phase 3: Load Data into Nautilus Catalog

**Goal**: Convert parquet data to Nautilus format.

**Steps**:
1. Write `src/backtest/load_catalog.py` (conversion script)
2. Run one-time conversion: parquet → Nautilus catalog
3. Update backtest config to use catalog
4. Test data loading and strategy execution

**Effort**: 4-6 hours

---

#### Phase 4: Full Backtest with Nautilus

**Goal**: Run complete backtest using Nautilus engine.

**Steps**:
1. Create `src/backtest/run_nautilus_backtest.py`
2. Run backtest on historical data (2024-01-01 to 2024-10-03)
3. Compare results with current system
4. Validate capital management, P&L tracking

**Effort**: 2-4 hours

---

#### Phase 5: Results Validation

**Goal**: Ensure Nautilus backtest matches current system.

**Steps**:
1. Run same backtest in both systems
2. Compare trade logs (entry/exit times, prices, P&L)
3. Verify capital management (lot sizing, compounding)
4. Document any differences

**Effort**: 2-4 hours

---

### Total Migration Effort

**Estimated Time**: 14-26 hours (2-4 days)

**Benefits After Migration**:
- ✅ Capital manager works in backtest, paper, live
- ✅ Same strategy code for all environments
- ✅ Built-in order management and position tracking
- ✅ Realistic backtesting (fills, slippage, latency)
- ✅ Foundation for paper trading (next phase)

---

## Comparison: Current vs Nautilus

| Aspect | Current System | Nautilus System |
|--------|----------------|-----------------|
| **Data Loading** | Custom parquet adapter | Nautilus catalog (parquet) |
| **Strategy Class** | Custom class | `nautilus_trader.trading.strategy.Strategy` |
| **Order Execution** | Custom execution engine | Built-in execution engine |
| **Position Tracking** | Custom position manager | Built-in portfolio |
| **Capital Management** | Planned custom class | Nautilus Actor (cross-environment) |
| **Event Processing** | Manual iteration | Event-driven message bus |
| **Backtest Runtime** | ~17s | ~10-15s (Rust core) |
| **Paper Trading** | Separate implementation | Same code, different config |
| **Live Trading** | Not implemented | Same code, different config |
| **Code Reuse** | Low (separate codebases) | High (same code everywhere) |

---

## Key Takeaways

1. **CapitalManager Should Be an Actor**
   - Works in backtest, paper, and live (same code)
   - Subscribes to position events
   - Updates capital automatically

2. **Strategy Should Inherit from Nautilus Strategy**
   - Event-driven (no manual polling)
   - Built-in order submission and position tracking
   - Works across all environments

3. **Data Should Be in Nautilus Catalog**
   - One-time conversion from parquet
   - Fast loading (2-3s)
   - Framework-managed data delivery

4. **Migration Is Incremental**
   - Start with CapitalManager (immediate value)
   - Convert strategy (moderate effort)
   - Full migration over 2-4 days

5. **Same Code, All Environments**
   - Write once, test in backtest
   - Validate in paper trading
   - Deploy to live trading
   - No code duplication

---

## Next Steps

1. **Read**: Paper Trading Best Practices (`02_PAPER_TRADING_BEST_PRACTICES.md`)
2. **Read**: Live Trading Best Practices (`03_LIVE_TRADING_BEST_PRACTICES.md`)
3. **Implement**: Create CapitalManager as Nautilus Actor
4. **Test**: Run simple backtest with capital management
5. **Validate**: Compare with current system results

---

## References

- **Nautilus Docs**: https://nautilustrader.io/docs/latest/
- **Backtest Guide**: https://nautilustrader.io/docs/latest/getting_started/backtesting
- **Strategy API**: https://nautilustrader.io/docs/latest/api_reference/trading.html#strategy
- **Actor API**: https://nautilustrader.io/docs/latest/api_reference/trading.html#actor
- **Current Implementation**: `/tmp/capital_management_implementation_plan.md`
- **Overview**: `00_OVERVIEW.md`
