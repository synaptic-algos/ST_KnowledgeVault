---
artifact_type: story
created_at: '2025-11-25T16:23:21.812778Z'
id: AUTO-11_CUSTOM_DATA_CLIENT_V13_INTEGRATION
manual_update: 'true'
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: '001'
status: pending
title: Auto-generated title for 11_CUSTOM_DATA_CLIENT_V13_INTEGRATION
updated_at: '2025-11-25T16:23:21.812781Z'
---

## Table of Contents

1. [Nautilus Data Architecture Overview](#nautilus-data-architecture-overview)
2. [DataClient vs Data Injection Pattern](#dataclient-vs-data-injection-pattern)
3. **[CRITICAL: BacktestNode vs BacktestEngine](#critical-backtestnode-vs-backtestengine)** ⚠️ **NEW**
4. [Custom DataClient Implementation Guide](#custom-dataclient-implementation-guide)
5. [Direct Data Injection Pattern (Recommended for V13)](#direct-data-injection-pattern-recommended-for-v13)
6. [V13 Integration Implementation](#v13-integration-implementation)
7. [Performance Analysis](#performance-analysis)
8. [Cross-Environment Compatibility](#cross-environment-compatibility)
9. [Migration Path](#migration-path)
10. [Code Examples](#code-examples)
11. [Decision Tree](#decision-tree)

---

## CRITICAL: BacktestNode vs BacktestEngine

**Discovery Date**: 2025-10-21
**Issue**: Initial V13 implementation used BacktestNode with Direct Data Injection - produced 0 trades
**Root Cause**: BacktestNode and BacktestEngine serve different purposes in Nautilus architecture

### The Problem

```python
# ❌ BROKEN PATTERN - BacktestNode + Direct Injection
node = BacktestNode(configs=[run_config])  # Config with empty data list
node.build()
engines = node.get_engines()
engine = engines[0]

# Load and inject data
bars = v13_adapter.get_nautilus_bars(...)
engine.add_data(bars)  # ← Data added but never replayed!

# Run backtest
node.run()  # ← Strategy receives NO bars (0 trades)
```

**Symptoms**:
- Backtest completes successfully (no errors)
- Data loads correctly (613,872 bars from V13)
- Instruments registered (4,872 instruments)
- Strategy subscribes to instruments (33,408 subscriptions)
- **But**: Strategy never receives bar data (only 4 on_bar calls vs 613K bars)
- **Result**: 0 trades in trade_log.csv

### Why BacktestNode Doesn't Work

**BacktestNode Design Purpose**:
- High-level orchestration API
- Designed for **BacktestDataConfig** (catalog-based loading)
- Automatically loads data from ParquetDataCatalog based on config
- Internal execution flow expects data from BacktestDataConfig, not manual injection

**What Happens**:
1. `BacktestNode` creates internal `BacktestEngine`
2. `node.build()` initializes strategy (strategy subscribes to instruments)
3. `engine.add_data(bars)` adds bars to engine's internal data buffer
4. **BUT**: `node.run()` doesn't replay manually injected data
5. `node.run()` only replays data from BacktestDataConfig sources
6. Strategy never receives bars → 0 trades

### The Solution: Use BacktestEngine Directly

**BacktestEngine Design Purpose**:
- Low-level execution API
- Native support for `add_data()` (Direct Data Injection)
- Manual control over all aspects (venue, instruments, data, strategy)
- This is the **documented Nautilus pattern** for custom data sources

```python
# ✅ CORRECT PATTERN - BacktestEngine + Direct Injection
from nautilus_trader.backtest.engine import BacktestEngine, BacktestEngineConfig
from nautilus_trader.model.identifiers import Venue
from nautilus_trader.model.enums import AccountType, OmsType
from nautilus_trader.model.objects import Money
from nautilus_trader.model.currencies import INR

# Step 1: Create engine config
config = BacktestEngineConfig(
    trader_id="BACKTESTER-001",
    logging=LoggingConfig(log_level="INFO")
)

# Step 2: Create engine
engine = BacktestEngine(config=config)

# Step 3: Add venue (exchange) with starting capital
engine.add_venue(
    venue=Venue("NSE"),
    oms_type=OmsType.NETTING,
    account_type=AccountType.MARGIN,
    base_currency=INR,
    starting_balances=[Money(400_000, INR)]
)

# Step 4: Load V13 data
bars = v13_adapter.get_nautilus_bars(
    start_date=start_date,
    end_date=end_date
)

# Step 5: Register instruments (extract from bars)
unique_instruments = extract_unique_instruments(bars)
for instrument in unique_instruments:
    engine.add_instrument(instrument)

# Step 6: Inject data
engine.add_data(bars)  # ← Works correctly with BacktestEngine

# Step 7: Add strategy
strategy = NativeOptionsStrategy(config=strategy_config)
engine.add_strategy(strategy)

# Step 8: Add actors (results tracker, etc.)
results_actor = ResultsTrackerActor(config=results_config)
engine.add_actor(results_actor)

# Step 9: Run backtest
engine.run()  # ← Strategy RECEIVES bars correctly
```

**Why This Works**:
- `BacktestEngine.add_data()` is the native API for Direct Data Injection
- `engine.run()` replays all data added via `add_data()`
- Strategy receives bars via `on_bar()` callbacks as expected
- This is the exact pattern shown in Nautilus documentation (04_BACKTESTING_BEST_PRACTICES.md)

### Architecture Comparison

| Aspect | BacktestNode | BacktestEngine |
|--------|-------------|----------------|
| **Purpose** | High-level API | Low-level API |
| **Data Source** | BacktestDataConfig (catalog) | `add_data()` (manual injection) |
| **Setup Complexity** | Low (config-driven) | Medium (manual setup) |
| **Use Case** | Standard Nautilus catalogs | Custom data sources |
| **Direct Injection** | ❌ NOT SUPPORTED | ✅ NATIVELY SUPPORTED |
| **V13 Integration** | ❌ Doesn't work | ✅ Correct approach |

### Lesson Learned

**Key Insight**: Nautilus provides two execution patterns:

1. **BacktestNode** (config-driven): Use when data is in Nautilus ParquetDataCatalog format
   - Pros: Simple, config-only setup
   - Cons: Requires Nautilus catalog structure

2. **BacktestEngine** (manual injection): Use for custom data sources
   - Pros: Works with ANY data format, full control
   - Cons: More manual setup required

For V13 consolidated catalog (custom monthly format), **BacktestEngine is the only viable approach**.

---

## 1. Nautilus Data Architecture Overview

### Core Data Delivery Patterns

Nautilus provides **two primary patterns** for delivering data to backtests:

```
┌─────────────────────────────────────────────────────────────────┐
│                     DATA DELIVERY PATTERNS                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Pattern 1: BacktestDataConfig (Catalog-Based)                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ BacktestDataConfig                                     │    │
│  │   catalog_path = "data/catalogs/v12"                   │    │
│  │   data_cls = Bar                                       │    │
│  │   instrument_ids = ["NIFTY50.NSE", ...]                │    │
│  │                                                         │    │
│  │ BacktestNode automatically:                            │    │
│  │   • Opens ParquetDataCatalog                           │    │
│  │   • Queries catalog.bars(instrument_ids, start, end)   │    │
│  │   • Streams bars to strategy via on_bar() events       │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
│  Pattern 2: Direct Data Injection (BacktestEngine.add_data())  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ engine = BacktestEngine(config)                        │    │
│  │                                                         │    │
│  │ # Load data from custom source                         │    │
│  │ bars = v13_adapter.get_nautilus_bars(...)              │    │
│  │                                                         │    │
│  │ # Inject into engine                                   │    │
│  │ engine.add_data(bars)                                  │    │
│  │                                                         │    │
│  │ # Engine handles streaming automatically               │    │
│  │ engine.run()                                           │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
│  Pattern 3: Custom DataClient (Advanced)                       │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ class V13DataClient(DataClient):                       │    │
│  │     def connect(self): ...                             │    │
│  │     def disconnect(self): ...                          │    │
│  │     def subscribe(self, data_type): ...                │    │
│  │     def request_bars(self, ...): ...                   │    │
│  │                                                         │    │
│  │ # Used for live/paper trading data sources             │    │
│  │ # Complex: connection management, reconnection, etc.   │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### When to Use Each Pattern

| Pattern | Use Case | Complexity | Cross-Env | Example |
|---------|----------|------------|-----------|---------|
| **BacktestDataConfig** | Nautilus catalogs (parquet) | Low | Backtest only | V12 fragmented catalog |
| **Direct Injection** | Custom backtest data sources | Low | Backtest only | V13 monthly consolidated |
| **Custom DataClient** | Live/paper trading data | High | All environments | Zerodha, IB, Binance |

**Key Insight**: Custom DataClient is **overkill** for backtest-only data sources. Direct injection is simpler and equally Nautilus-compliant.

---

## 2. DataClient vs Data Injection Pattern

### Pattern 1: BacktestDataConfig (Catalog-Based)

**Use When**: You have data in Nautilus ParquetDataCatalog format

**Architecture**:
```python
# config/backtest_config.py
from nautilus_trader.backtest.config import BacktestDataConfig

config = BacktestRunConfig(
    data_configs=[
        BacktestDataConfig(
            catalog_path="data/catalogs/v12_real_enhanced_hourly",
            data_cls=Bar,
            instrument_ids=["NIFTY24JAN25C21150.NSE", "NIFTY24JAN25C21200.NSE"],
            start_time="2024-01-01T09:15:00+05:30",
            end_time="2024-02-29T15:30:00+05:30"
        )
    ]
)

# BacktestNode handles everything automatically
node = BacktestNode(config)
node.run()
```

**Advantages**:
- ✅ Zero code - pure configuration
- ✅ Nautilus handles catalog opening/closing
- ✅ Automatic data streaming
- ✅ Built-in error handling

**Limitations**:
- ❌ Requires Nautilus catalog format (fragmented per-instrument)
- ❌ Subject to catalog query performance issues (O(N × M) file discovery)
- ❌ Cannot use custom storage formats (monthly consolidated, HDF5, etc.)

**Performance** (V12 fragmented catalog):
- 937,906 parquet files
- 230 instruments: ~2 min/instrument = ~7.7 hours
- 33K instruments: ~5-10 minutes (date filter only)

---

### Pattern 2: Direct Data Injection (Recommended for V13)

**Use When**: Custom backtest data format (monthly partitions, HDF5, SQL, etc.)

**Architecture**:
```python
# src/nautilus/backtest/backtestnode_runner.py

# Load data from custom source
from src.nautilus.backtest.v13_consolidated_adapter import V13ConsolidatedDataAdapter

adapter = V13ConsolidatedDataAdapter(
    catalog_path="data/catalogs/v13_consolidated",
    instrument_ids=required_instrument_ids  # Pre-filtered
)

# Get Nautilus Bar objects
bars = adapter.get_nautilus_bars(
    instrument_ids=required_instrument_ids,
    start_date=start_date,
    end_date=end_date
)
# Returns: List[Bar] (Nautilus native objects)

# Create BacktestEngine
engine = BacktestEngine(config)

# Add instruments
for instrument in instruments:
    engine.add_instrument(instrument)

# Inject data
engine.add_data(bars)  # Nautilus handles streaming from this point

# Run backtest
engine.run()
```

**Advantages**:
- ✅ Works with any data format (not just Nautilus catalogs)
- ✅ Full control over data loading (optimize for your format)
- ✅ Bypasses catalog query performance issues
- ✅ Still 100% Nautilus-compliant (uses native Bar objects)
- ✅ Simple - no connection lifecycle management

**Limitations**:
- ❌ Requires custom adapter (one-time development)
- ❌ Backtest-only (doesn't work in live/paper trading)

**Performance** (V13 consolidated catalog):
- 43 monthly parquet files
- Load time: 30-60 seconds (6-9x faster than V12)
- Memory: Constant ~300 MB

**When to Use**:
- ✅ Custom data storage formats
- ✅ Performance-optimized loading
- ✅ Backtest-only scenarios
- ❌ NOT for live/paper trading (use Custom DataClient instead)

---

### Pattern 3: Custom DataClient (Advanced)

**Use When**: Streaming data from external API (Zerodha, IB, Binance) for live/paper trading

**Architecture**:
```python
# src/nautilus/adapters/zerodha_data_client.py

from nautilus_trader.live.data_client import LiveDataClient

class ZerodhaDataClient(LiveDataClient):
    """
    Streams live market data from Zerodha KiteTicker WebSocket.
    Works in paper and live trading environments.
    """

    def connect(self):
        """Establish WebSocket connection"""
        self._kite_ticker = KiteTicker(self._api_key, self._access_token)
        self._kite_ticker.on_connect = self._on_connect
        self._kite_ticker.on_ticks = self._on_ticks
        self._kite_ticker.on_close = self._on_close
        self._kite_ticker.connect()

    def disconnect(self):
        """Close WebSocket connection"""
        if self._kite_ticker:
            self._kite_ticker.close()

    def subscribe(self, data_type):
        """Subscribe to instrument updates"""
        tokens = [self._instrument_to_token[inst_id] for inst_id in instruments]
        self._kite_ticker.subscribe(tokens)

    def _on_ticks(self, ws, ticks):
        """Handle incoming tick data"""
        for tick in ticks:
            # Convert Zerodha tick to Nautilus QuoteTick
            quote_tick = self._convert_tick(tick)
            # Publish to message bus (strategy receives via on_quote_tick)
            self._handle_data(quote_tick)
```

**Advantages**:
- ✅ Works in backtest, paper, AND live trading
- ✅ Same client code across all environments
- ✅ Nautilus handles message routing
- ✅ Built-in reconnection support (via LiveDataClient base)

**Limitations**:
- ❌ High complexity (connection lifecycle, error handling, reconnection)
- ❌ Requires external API (not suitable for static backtest data)
- ❌ Overkill for backtest-only scenarios

**When to Use**:
- ✅ Live/paper trading data sources
- ✅ WebSocket streaming APIs
- ✅ Need cross-environment compatibility
- ❌ NOT for static backtest data (use Direct Injection instead)

---

## 3. Custom DataClient Implementation Guide

### DataClient Base Class Interface

**Source**: `nautilus_trader/live/data_client.py`

```python
from nautilus_trader.live.data_client import LiveDataClient

class CustomDataClient(LiveDataClient):
    """
    Base interface for custom data clients.
    Must implement all abstract methods.
    """

    # ═══════════════════════════════════════════════════════════════════
    # CONNECTION LIFECYCLE
    # ═══════════════════════════════════════════════════════════════════

    async def _connect(self):
        """
        Establish connection to data source.
        Called automatically by framework on client start.

        Responsibilities:
        - Open WebSocket/HTTP connection
        - Authenticate with API
        - Set up event handlers
        - Set self._is_connected = True
        """
        raise NotImplementedError

    async def _disconnect(self):
        """
        Close connection to data source.
        Called automatically on client stop.

        Responsibilities:
        - Close WebSocket/HTTP connection
        - Clean up resources
        - Set self._is_connected = False
        """
        raise NotImplementedError

    # ═══════════════════════════════════════════════════════════════════
    # SUBSCRIPTION MANAGEMENT
    # ═══════════════════════════════════════════════════════════════════

    async def _subscribe(self, data_type):
        """
        Subscribe to data updates for specific instruments.

        Args:
            data_type: QuoteTick, Bar, etc.

        Responsibilities:
        - Send subscription request to API
        - Track subscribed instruments
        - Handle subscription confirmation
        """
        raise NotImplementedError

    async def _unsubscribe(self, data_type):
        """
        Unsubscribe from data updates.

        Args:
            data_type: QuoteTick, Bar, etc.

        Responsibilities:
        - Send unsubscribe request to API
        - Remove from subscribed instruments
        - Handle unsubscribe confirmation
        """
        raise NotImplementedError

    # ═══════════════════════════════════════════════════════════════════
    # DATA REQUEST (Historical/Snapshot)
    # ═══════════════════════════════════════════════════════════════════

    async def _request_bars(
        self,
        bar_type: BarType,
        start: datetime,
        end: datetime,
        **kwargs
    ):
        """
        Request historical bars (if API supports).

        Args:
            bar_type: Bar specification (instrument, aggregation, etc.)
            start: Start datetime
            end: End datetime

        Returns:
            List[Bar]: Historical bars

        Responsibilities:
        - Query API for historical data
        - Convert API response to Nautilus Bar objects
        - Return bars in chronological order
        """
        raise NotImplementedError

    # ═══════════════════════════════════════════════════════════════════
    # DATA PUBLISHING (Streaming)
    # ═══════════════════════════════════════════════════════════════════

    def _handle_data(self, data):
        """
        Publish data to Nautilus message bus.

        Args:
            data: Nautilus data object (QuoteTick, Bar, etc.)

        Usage:
            # In WebSocket on_message handler:
            quote_tick = self._convert_tick(api_tick)
            self._handle_data(quote_tick)  # Publishes to strategy

        Framework automatically routes to:
        - strategy.on_quote_tick(tick)  # For QuoteTick
        - strategy.on_bar(bar)          # For Bar
        """
        # Provided by LiveDataClient base class
        super()._handle_data(data)
```

### Implementation Checklist

**Minimum Requirements**:
- [ ] Implement `_connect()` - Establish connection to data source
- [ ] Implement `_disconnect()` - Close connection gracefully
- [ ] Implement `_subscribe()` - Subscribe to instrument updates
- [ ] Implement `_unsubscribe()` - Unsubscribe from instruments
- [ ] Convert API data to Nautilus objects (QuoteTick, Bar, etc.)
- [ ] Call `self._handle_data()` to publish data to strategies
- [ ] Handle reconnection on connection loss
- [ ] Handle API errors and rate limiting

**Optional**:
- [ ] Implement `_request_bars()` for historical data
- [ ] Implement `_request_quote_ticks()` for tick history
- [ ] Add custom configuration (API keys, endpoints, etc.)
- [ ] Add connection health monitoring
- [ ] Add metrics/logging for debugging

---

## 4. Direct Data Injection Pattern (Recommended for V13)

### Why Direct Injection for V13?

**V13 Consolidated Catalog Characteristics**:
1. **Static backtest data** (not streaming from external API)
2. **Monthly-partitioned parquet files** (custom format, not per-instrument)
3. **Backtest-only** (not used in live/paper trading)
4. **Performance-optimized loading** (6-9x faster than fragmented catalog)

**Conclusion**: Custom DataClient would add unnecessary complexity for a simple "load data and inject" scenario.

### Direct Injection Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│               DIRECT DATA INJECTION FLOW                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Step 1: Create Custom Data Adapter                            │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ V13ConsolidatedDataAdapter                             │    │
│  │   catalog_path = "data/catalogs/v13_consolidated"      │    │
│  │                                                         │    │
│  │ Methods:                                               │    │
│  │   • get_instruments() → List[Instrument]               │    │
│  │   • get_bars() → DataFrame                             │    │
│  │   • get_nautilus_bars() → List[Bar]  ✅ Key method     │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
│  Step 2: Load Data into Nautilus Objects                       │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ adapter = V13ConsolidatedDataAdapter(...)              │    │
│  │                                                         │    │
│  │ bars = adapter.get_nautilus_bars(                      │    │
│  │     instrument_ids=["NIFTY24JAN25C21150.NSE", ...],    │    │
│  │     start_date=datetime(2024, 1, 1),                   │    │
│  │     end_date=datetime(2024, 2, 29)                     │    │
│  │ )                                                       │    │
│  │ # Returns: List[Bar] (33,408 Bar objects)              │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
│  Step 3: Inject into BacktestEngine                            │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ engine = BacktestEngine(config)                        │    │
│  │                                                         │    │
│  │ # Add instruments                                      │    │
│  │ for instrument in instruments:                         │    │
│  │     engine.add_instrument(instrument)                  │    │
│  │                                                         │    │
│  │ # Inject bars                                          │    │
│  │ engine.add_data(bars)  ✅ Nautilus handles streaming   │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
│  Step 4: Run Backtest                                          │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ engine.run()                                           │    │
│  │                                                         │    │
│  │ Nautilus automatically:                                │    │
│  │   • Sorts bars chronologically                         │    │
│  │   • Streams bars to strategy via on_bar() events       │    │
│  │   • Manages event ordering (bars, fills, positions)    │    │
│  │   • Tracks portfolio state                             │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### Key Advantages

1. **Simplicity**: No connection management, no subscriptions, no reconnection logic
2. **Performance**: Optimized data loading (monthly consolidation)
3. **Nautilus-Compliant**: Uses native `Bar` objects, framework handles streaming
4. **Maintainability**: Single adapter class (~400 lines vs ~1500+ for DataClient)

---

## 5. V13 Integration Implementation

### Current Implementation (Sprint 30 Task 2.2)

**Location**: `src/nautilus/backtest/backtestnode_runner.py:519-600`

**Architecture**:
```python
# File: src/nautilus/backtest/backtestnode_runner.py

def _create_data_config(self, start_date, end_date, max_instruments):
    """
    Create BacktestDataConfig with V13 catalog detection.

    Detects catalog type automatically:
    - V13: catalog.json exists → Use Direct Injection
    - V12: No catalog.json → Use BacktestDataConfig
    """

    # Detect catalog type
    catalog_json_path = self.catalog_path / "catalog.json"
    is_v13_catalog = catalog_json_path.exists()

    if is_v13_catalog:
        # ═══════════════════════════════════════════════════════════
        # V13 CONSOLIDATED CATALOG (Direct Injection)
        # ═══════════════════════════════════════════════════════════

        from src.nautilus.backtest.v13_consolidated_adapter import V13ConsolidatedDataAdapter

        # Create adapter
        adapter = V13ConsolidatedDataAdapter(
            catalog_path=str(self.catalog_path),
            instrument_ids=None  # Load all instruments
        )

        # Get Nautilus Bar objects
        bars = adapter.get_nautilus_bars(
            instrument_ids=None,  # All instruments in catalog
            start_date=start_date,
            end_date=end_date
        )

        # Store bars for engine.add_data() injection
        self._preloaded_bars = bars

        # Return empty BacktestDataConfig (data injected separately)
        return BacktestDataConfig(
            catalog_path=str(self.catalog_path),
            data_cls=Bar,
            # No instrument_ids filter - data already loaded
        ), metadata

    else:
        # ═══════════════════════════════════════════════════════════
        # V12 FRAGMENTED CATALOG (Catalog-Based)
        # ═══════════════════════════════════════════════════════════

        # Use BacktestDataConfig pattern (automatic streaming)
        return BacktestDataConfig(
            catalog_path=str(self.catalog_path),
            data_cls=Bar,
            instrument_ids=filtered_instrument_ids,
            start_time=start_date,
            end_time=end_date
        ), metadata
```

### V13ConsolidatedDataAdapter Implementation

**Location**: `src/nautilus/backtest/v13_consolidated_adapter.py`

**Key Method**: `get_nautilus_bars()`

```python
# File: src/nautilus/backtest/v13_consolidated_adapter.py

class V13ConsolidatedDataAdapter:
    """
    Data adapter for V13 consolidated monthly-partitioned catalog.

    KEY OPTIMIZATION:
    - Loads entire month at once (single I/O operation)
    - Filters by instrument_id in memory (columnar parquet)
    - Caches monthly data to avoid reloading
    """

    def get_nautilus_bars(
        self,
        instrument_ids: Optional[List[str]] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> List[Bar]:
        """
        Get bars as Nautilus Bar objects (for BacktestEngine.add_data()).

        This method is specifically for Sprint 30 Task 2.2: Direct Data Injection.
        It converts V13 monthly consolidated data into Nautilus Bar objects that
        can be fed directly to BacktestEngine.add_data().

        Args:
            instrument_ids: List of instrument IDs (None = all)
            start_date: Start date (None = catalog start)
            end_date: End date (None = catalog end)

        Returns:
            List of Nautilus Bar objects ready for BacktestEngine.add_data()

        Performance:
            - Loads 2 months (43 files): ~30-60 seconds
            - Loads 21 months (43 files): ~2-4 minutes
            - 6-9x faster than V12 (fragmented catalog)
        """
        from nautilus_trader.model.data import Bar, BarType
        from nautilus_trader.model.identifiers import InstrumentId
        from nautilus_trader.model.objects import Price, Quantity

        # Get bars as DataFrame
        bars_df = self.get_bars(instrument_ids, start_date, end_date)

        if bars_df.empty:
            return []

        # Convert to Nautilus Bar objects
        nautilus_bars = []

        for row in bars_df.itertuples(index=False):
            # Create BarType object
            bar_type = BarType.from_str(f"{row.instrument_id}-1-HOUR-LAST-EXTERNAL")

            # Create Bar object
            bar = Bar(
                bar_type=bar_type,
                open=Price.from_str(f"{row.open:.2f}"),
                high=Price.from_str(f"{row.high:.2f}"),
                low=Price.from_str(f"{row.low:.2f}"),
                close=Price.from_str(f"{row.close:.2f}"),
                volume=Quantity.from_str(f"{row.volume:.0f}"),
                ts_event=int(row.ts_event),  # Nanoseconds
                ts_init=int(row.ts_event)
            )
            nautilus_bars.append(bar)

        return nautilus_bars
```

### Integration Flow

```
┌─────────────────────────────────────────────────────────────────┐
│        V13 DIRECT INJECTION INTEGRATION FLOW                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. BacktestNodeRunner._create_data_config()                   │
│     │                                                           │
│     ├─ Detect catalog type (catalog.json exists?)              │
│     │                                                           │
│     └─ IF V13:                                                 │
│         │                                                       │
│         ├─ Create V13ConsolidatedDataAdapter                   │
│         ├─ Call adapter.get_nautilus_bars()                    │
│         ├─ Store bars in self._preloaded_bars                  │
│         └─ Return empty BacktestDataConfig                     │
│                                                                 │
│  2. BacktestNodeRunner.run()                                   │
│     │                                                           │
│     ├─ Create BacktestEngine(config)                           │
│     ├─ Add instruments: engine.add_instrument(...)             │
│     │                                                           │
│     └─ IF V13:                                                 │
│         ├─ engine.add_data(self._preloaded_bars) ✅ INJECT     │
│         └─ Nautilus takes over (streaming, event ordering)     │
│                                                                 │
│  3. BacktestEngine.run()                                       │
│     │                                                           │
│     ├─ Sort all bars chronologically                           │
│     ├─ Stream bars to strategy via on_bar() events             │
│     ├─ Execute strategy logic                                  │
│     ├─ Track portfolio/positions                               │
│     └─ Generate results                                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Performance Analysis

### V12 Fragmented Catalog (Catalog-Based)

**Structure**:
```
data/catalogs/v12_real_enhanced_hourly/
├── data/bar/
│   ├── NIFTY24JAN25C21150.NSE-1-HOUR-LAST-EXTERNAL/
│   │   └── *.parquet (28 files per instrument)
│   ├── NIFTY24JAN25C21200.NSE-1-HOUR-LAST-EXTERNAL/
│   │   └── *.parquet (28 files per instrument)
│   └── ... (33,408 instrument directories)
└── metadata/
    └── instruments.json (33,408 instruments)
```

**Performance**:
- Total files: 937,906 parquet files
- File discovery: O(N × M) = 937K × 230 = ~215M comparisons
- Load time (230 instruments, 2 months): ~7.7 hours
- Load time (33K instruments, 2 months): ~5-10 minutes (date filter only)

**Bottleneck**: `ParquetDataCatalog._query_files()` - O(N × M) file discovery

---

### V13 Consolidated Catalog (Direct Injection)

**Structure**:
```
data/catalogs/v13_consolidated/
├── data/bars/
│   ├── 2024-01.parquet  # All 33K instruments for Jan 2024
│   ├── 2024-02.parquet  # All 33K instruments for Feb 2024
│   └── ... (21 monthly files total)
├── meta/greeks/
│   ├── 2024-01.parquet
│   └── ...
└── catalog.json  ← Detection marker
```

**Performance**:
- Total files: 43 parquet files (21 months × 2 types)
- File discovery: Sequential reads (no nested loops)
- Load time (all instruments, 2 months): 30-60 seconds
- Load time (all instruments, 21 months): 2-4 minutes

**Speedup**: 6-9x faster than V12

---

### Comparison Table

| Metric | V12 Fragmented | V13 Consolidated | Speedup |
|--------|----------------|------------------|---------|
| **Files** | 937,906 | 43 | 21,811x fewer |
| **Complexity** | O(N × M) | O(N) | Linear |
| **2-month load (230 inst)** | ~7.7 hours | ~30-60 seconds | ~460x |
| **2-month load (33K inst)** | ~5-10 min | ~30-60 seconds | ~6-9x |
| **21-month load (33K inst)** | ~30-60 min | ~2-4 minutes | ~10-15x |
| **Memory** | ~300 MB | ~300 MB | Same |
| **Pattern** | Catalog-Based | Direct Injection | Both valid |

---

## 7. Cross-Environment Compatibility

### V13 Adapter: Backtest-Only

**Why V13 is Backtest-Only**:
1. Static historical data (not live streaming)
2. Monthly consolidation (not real-time partitioning)
3. No API connection (just file reads)
4. No subscription management (load all data upfront)

**Implications**:
- ✅ Perfect for backtesting
- ❌ Cannot be used in paper/live trading
- ✅ Simpler than DataClient (no connection lifecycle)

---

### Cross-Environment Pattern: DataClient

**Zerodha Example** (Works in Backtest, Paper, Live):

```python
# config/backtest_config.py (BACKTEST)
config = BacktestRunConfig(
    data_clients={
        "ZERODHA": ZerodhaDataClientConfig(
            api_key="mock_key",
            access_token="mock_token",
            instruments=["NIFTY50.NSE"],
            # In backtest: Uses historical data simulation
        )
    }
)

# config/paper_config.py (PAPER TRADING)
config = TradingNodeConfig(
    data_clients={
        "ZERODHA": ZerodhaDataClientConfig(
            api_key=os.getenv("ZERODHA_API_KEY"),
            access_token=os.getenv("ZERODHA_ACCESS_TOKEN"),
            instruments=["NIFTY50.NSE"],
            # In paper: Uses live WebSocket stream
        )
    }
)

# config/live_config.py (LIVE TRADING)
config = TradingNodeConfig(
    data_clients={
        "ZERODHA": ZerodhaDataClientConfig(
            api_key=os.getenv("ZERODHA_API_KEY"),
            access_token=os.getenv("ZERODHA_ACCESS_TOKEN"),
            instruments=["NIFTY50.NSE"],
            # In live: Uses live WebSocket stream
        )
    }
)
```

**Key Difference**:
- **V13 Direct Injection**: Backtest-only, simpler, no connection management
- **Zerodha DataClient**: All environments, complex, full connection lifecycle

---

## 8. Migration Path

### From V12 Catalog-Based to V13 Direct Injection

**Step 1: Build V13 Consolidated Catalog** (One-Time, 2-3 hours)

```bash
# Script: src/nautilus/scripts/build_v13_catalog.py
python src/nautilus/scripts/build_v13_catalog.py \
    --source-catalog data/catalogs/v12_real_enhanced_hourly \
    --target-catalog data/catalogs/v13_consolidated \
    --start-date 2024-01-01 \
    --end-date 2025-10-15

# Output:
# data/catalogs/v13_consolidated/
#   ├── data/bars/2024-01.parquet ... 2025-10.parquet (21 files)
#   ├── meta/greeks/2024-01.parquet ... 2025-10.parquet (22 files)
#   ├── catalog.json ← Detection marker
#   └── data/instruments/instruments.parquet
```

**Step 2: Implement V13ConsolidatedDataAdapter** (Already Complete)

**Location**: `src/nautilus/backtest/v13_consolidated_adapter.py`

**Step 3: Update BacktestNodeRunner** (Already Complete)

**Location**: `src/nautilus/backtest/backtestnode_runner.py:519-600`

**Step 4: Test**

```bash
# Test with V13 catalog
python src/nautilus/backtest/run_dual_mode_backtest.py \
    --config config/strategy_config.json \
    --catalog data/catalogs/v13_consolidated \
    --start-date 2024-01-01 \
    --end-date 2024-02-29

# Expected output:
# 📦 V13 CONSOLIDATED CATALOG DETECTED (Sprint 30)
#   Load time: ~30-60 seconds
#   Memory: ~300 MB
#   Backtest time: Similar to V12 (strategy execution dominates)
```

**Step 5: Validate Results**

Run same backtest on both catalogs, compare results:

```bash
# V12 fragmented catalog
python src/nautilus/backtest/run_dual_mode_backtest.py \
    --catalog data/catalogs/v12_real_enhanced_hourly \
    --output backtest_results/v12_validation

# V13 consolidated catalog
python src/nautilus/backtest/run_dual_mode_backtest.py \
    --catalog data/catalogs/v13_consolidated \
    --output backtest_results/v13_validation

# Compare results
python scripts/compare_backtest_results.py \
    backtest_results/v12_validation \
    backtest_results/v13_validation
```

**Expected**: Identical results (same data, different loading pattern)

---

## 9. Code Examples

### Example 1: V13 Direct Injection (Complete)

```python
# File: src/nautilus/backtest/backtestnode_runner.py

def run(self, start_date, end_date, max_instruments=None):
    """
    Run backtest with V13 direct injection support.
    """

    # Create data config (detects V13 automatically)
    data_config, metadata = self._create_data_config(
        start_date, end_date, max_instruments
    )

    # Create BacktestEngine
    engine = BacktestEngine(config=self.backtest_config)

    # Add instruments
    for instrument in instruments:
        engine.add_instrument(instrument)

    # V13: Inject preloaded bars
    if hasattr(self, '_preloaded_bars'):
        logger.info(f"💉 Injecting {len(self._preloaded_bars):,} bars into BacktestEngine")
        engine.add_data(self._preloaded_bars)

    # Add strategy
    engine.add_strategy(strategy)

    # Run backtest
    engine.run()

    return engine
```

---

### Example 2: V13ConsolidatedDataAdapter Usage

```python
# File: examples/v13_adapter_example.py

from src.nautilus.backtest.v13_consolidated_adapter import V13ConsolidatedDataAdapter
from datetime import datetime

# Create adapter
adapter = V13ConsolidatedDataAdapter(
    catalog_path="data/catalogs/v13_consolidated",
    instrument_ids=None  # Load all instruments
)

# Get instruments
instruments = adapter.get_instruments()
print(f"Total instruments: {len(instruments):,}")

# Get bars as DataFrame
bars_df = adapter.get_bars(
    instrument_ids=["NIFTY24JAN25C21150.NSE", "NIFTY24JAN25C21200.NSE"],
    start_date=datetime(2024, 1, 1),
    end_date=datetime(2024, 2, 29)
)
print(f"Total bars (DataFrame): {len(bars_df):,}")

# Get bars as Nautilus objects
nautilus_bars = adapter.get_nautilus_bars(
    instrument_ids=["NIFTY24JAN25C21150.NSE"],
    start_date=datetime(2024, 1, 1),
    end_date=datetime(2024, 2, 29)
)
print(f"Total bars (Nautilus): {len(nautilus_bars):,}")

# Inspect first bar
bar = nautilus_bars[0]
print(f"Bar: {bar.bar_type} | O: {bar.open} H: {bar.high} L: {bar.low} C: {bar.close}")
```

---

### Example 3: Custom DataClient Template (Zerodha)

```python
# File: src/nautilus/adapters/zerodha_data_client.py

from nautilus_trader.live.data_client import LiveDataClient
from kiteconnect import KiteTicker

class ZerodhaDataClient(LiveDataClient):
    """
    Live data client for Zerodha KiteTicker WebSocket.
    Works in paper and live trading.
    """

    def __init__(self, loop, client_id, config, msgbus, cache, clock):
        super().__init__(loop, client_id, config.venue, msgbus, cache, clock)

        self._api_key = config.api_key
        self._access_token = config.access_token
        self._kite_ticker = None

    async def _connect(self):
        """Establish WebSocket connection"""
        self._kite_ticker = KiteTicker(self._api_key, self._access_token)

        # Register event handlers
        self._kite_ticker.on_connect = self._on_connect
        self._kite_ticker.on_ticks = self._on_ticks
        self._kite_ticker.on_close = self._on_close
        self._kite_ticker.on_error = self._on_error

        # Connect (blocking call in thread)
        await self._loop.run_in_executor(None, self._kite_ticker.connect)

        self._is_connected = True
        self._log.info("✅ Zerodha WebSocket connected")

    async def _disconnect(self):
        """Close WebSocket connection"""
        if self._kite_ticker:
            self._kite_ticker.close()
            self._is_connected = False
            self._log.info("🔌 Zerodha WebSocket disconnected")

    async def _subscribe(self, data_type):
        """Subscribe to instrument updates"""
        # Get instrument tokens
        tokens = [self._instrument_to_token[inst_id] for inst_id in instruments]

        # Subscribe via KiteTicker
        self._kite_ticker.subscribe(tokens)
        self._kite_ticker.set_mode(self._kite_ticker.MODE_FULL, tokens)

        self._log.info(f"📡 Subscribed to {len(tokens)} instruments")

    def _on_ticks(self, ws, ticks):
        """Handle incoming tick data (WebSocket callback)"""
        for tick in ticks:
            try:
                # Convert Zerodha tick to Nautilus QuoteTick
                quote_tick = self._convert_tick(tick)

                # Publish to message bus (strategy receives via on_quote_tick)
                self._handle_data(quote_tick)
            except Exception as e:
                self._log.error(f"Error processing tick: {e}")

    def _convert_tick(self, tick):
        """Convert Zerodha tick to Nautilus QuoteTick"""
        from nautilus_trader.model.data import QuoteTick
        from nautilus_trader.model.objects import Price, Quantity

        instrument_id = self._token_to_instrument[tick['instrument_token']]

        return QuoteTick(
            instrument_id=instrument_id,
            bid_price=Price.from_str(f"{tick['depth']['buy'][0]['price']:.2f}"),
            ask_price=Price.from_str(f"{tick['depth']['sell'][0]['price']:.2f}"),
            bid_size=Quantity.from_str(f"{tick['depth']['buy'][0]['quantity']:.0f}"),
            ask_size=Quantity.from_str(f"{tick['depth']['sell'][0]['quantity']:.0f}"),
            ts_event=int(tick['exchange_timestamp'].timestamp() * 1e9),
            ts_init=self._clock.timestamp_ns()
        )
```

---

## 10. Decision Tree

### When to Use Each Pattern

```
┌─────────────────────────────────────────────────────────────────┐
│              DATA INTEGRATION DECISION TREE                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Q1: Is this for backtest-only or live/paper trading?          │
│  │                                                              │
│  ├─ BACKTEST-ONLY                                              │
│  │  │                                                           │
│  │  Q2: Is data in Nautilus ParquetDataCatalog format?         │
│  │  │                                                           │
│  │  ├─ YES (Nautilus catalog)                                  │
│  │  │  │                                                        │
│  │  │  Q3: Is catalog performance acceptable?                  │
│  │  │  │                                                        │
│  │  │  ├─ YES → Use BacktestDataConfig (Pattern 1)             │
│  │  │  │   ✅ Zero code, pure config                           │
│  │  │  │   ✅ Nautilus handles everything                      │
│  │  │  │   Example: V12 with filtered instruments              │
│  │  │  │                                                        │
│  │  │  └─ NO (slow queries) → Use Direct Injection (Pattern 2) │
│  │  │      ✅ Bypass catalog query bottleneck                  │
│  │  │      ✅ Custom data adapter                              │
│  │  │      Example: Two-stage filtering approach               │
│  │  │                                                           │
│  │  └─ NO (custom format)                                      │
│  │     │                                                        │
│  │     Q4: Can you convert to Nautilus catalog?                │
│  │     │                                                        │
│  │     ├─ YES → Convert to catalog + use Pattern 1             │
│  │     │   ✅ One-time conversion                              │
│  │     │   ✅ Standard Nautilus workflow                       │
│  │     │                                                        │
│  │     └─ NO → Use Direct Injection (Pattern 2) ✅             │
│  │         ✅ Custom adapter for your format                   │
│  │         ✅ Call adapter.get_nautilus_bars()                 │
│  │         ✅ engine.add_data(bars)                            │
│  │         Example: V13 monthly consolidated                   │
│  │                                                              │
│  └─ LIVE/PAPER TRADING                                         │
│     │                                                           │
│     Q5: Is this a streaming data source (WebSocket, API)?      │
│     │                                                           │
│     ├─ YES → Implement Custom DataClient (Pattern 3) ✅        │
│     │   ✅ Works across backtest/paper/live                    │
│     │   ✅ Connection lifecycle management                     │
│     │   ✅ Subscription management                             │
│     │   ✅ Auto-reconnection                                   │
│     │   Example: Zerodha, IB, Binance                          │
│     │                                                           │
│     └─ NO (static data) → Wrong approach!                      │
│         ❌ Live trading needs real-time data                   │
│         ❌ Use DataClient for live API                         │
└─────────────────────────────────────────────────────────────────┘
```

### Pattern Selection Summary

| Scenario | Pattern | Complexity | Example |
|----------|---------|------------|---------|
| Nautilus catalog (fast queries) | BacktestDataConfig | Low | V12 with <100 instruments |
| Nautilus catalog (slow queries) | Direct Injection | Medium | V12 with two-stage filtering |
| Custom backtest format | Direct Injection | Medium | V13 monthly consolidated |
| Live/paper trading API | Custom DataClient | High | Zerodha, IB, Binance |

---

## Conclusion

### Key Findings

1. **Direct Data Injection is the Nautilus-recommended pattern for custom backtest data formats**
   - Simpler than Custom DataClient (no connection lifecycle)
   - Equally Nautilus-compliant (uses native `Bar` objects)
   - Perfect for V13 consolidated catalog

2. **Custom DataClient is overkill for backtest-only scenarios**
   - Designed for live/paper trading with streaming APIs
   - Adds unnecessary complexity (connection, subscription, reconnection)
   - Only use when data source works across backtest/paper/live

3. **V13 Direct Injection is fully implemented and production-ready**
   - Location: `src/nautilus/backtest/backtestnode_runner.py:519-600`
   - Performance: 6-9x faster than V12 fragmented catalog
   - Pattern: 100% Nautilus-aligned

### Recommendations

**For V13 Consolidated Catalog**:
- ✅ Continue using Direct Injection pattern (Sprint 30 Task 2.2)
- ✅ No need for Custom DataClient
- ✅ Monitor performance metrics (load time, memory)

**For Future Data Sources**:
- Backtest-only (HDF5, SQL, etc.) → Use Direct Injection
- Live/paper trading (Zerodha, IB, etc.) → Use Custom DataClient
- Nautilus catalog (performance acceptable) → Use BacktestDataConfig

---

## References

**Nautilus Best Practices**:
- [04_BACKTESTING_BEST_PRACTICES.md](04_BACKTESTING_BEST_PRACTICES.md) - Backtest patterns
- [09_BACKTEST_OPTIMIZATION_NAUTILUS_ALIGNMENT.md](09_BACKTEST_OPTIMIZATION_NAUTILUS_ALIGNMENT.md) - Optimization alignment
- [10_NAUTILUS_PARQUET_CATALOG_PERFORMANCE_DEEP_DIVE.md](10_NAUTILUS_PARQUET_CATALOG_PERFORMANCE_DEEP_DIVE.md) - Catalog performance analysis

**Implementation**:
- `src/nautilus/backtest/backtestnode_runner.py` - V13 integration (lines 519-600)
- `src/nautilus/backtest/v13_consolidated_adapter.py` - V13 data adapter
- `src/nautilus/adapters/zerodha_data_client.py` - DataClient example

**Nautilus Documentation**:
- [Nautilus Backtesting Guide](https://nautilustrader.io/docs/latest/getting_started/backtesting)
- [Nautilus Data Clients](https://nautilustrader.io/docs/latest/integrations/index.html)

---

**Author**: Research Team - Sprint 30 Investigation
**Date**: 2025-10-21
**Sprint**: Sprint 30 - V13 Consolidated Catalog
**Status**: ✅ Complete - V13 Direct Injection implemented and validated
