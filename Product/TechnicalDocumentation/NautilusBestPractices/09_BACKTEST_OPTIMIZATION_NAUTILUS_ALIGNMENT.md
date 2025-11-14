# Backtest Optimization Roadmap: Nautilus Architecture Alignment Analysis

**Created**: 2024-10-20 14:00:00
**Last Updated**: 2024-10-20 14:00:00
**Purpose**: Deep investigation of proposed backtest optimizations for Nautilus architecture compliance
**Audience**: Sprint planning, architecture decisions, performance optimization work
**Related Docs**:
- [04_BACKTESTING_BEST_PRACTICES.md](04_BACKTESTING_BEST_PRACTICES.md)
- [07_INSTRUMENT_PRE_COMPUTATION_PATTERN.md](07_INSTRUMENT_PRE_COMPUTATION_PATTERN.md)
- [SESSION_STATUS_20251020_21MONTH_BACKTEST_TIMING_ANALYSIS.md](../../SESSION_STATUS_20251020_21MONTH_BACKTEST_TIMING_ANALYSIS.md)

---

## Executive Summary

This document analyzes **7 proposed optimizations** from the 21-month backtest timing analysis against **Nautilus Trader architecture principles** to determine:
1. Which optimizations are Nautilus-compliant (✅)
2. Which require Nautilus-specific implementation patterns (⚠️)
3. Which fundamentally conflict with Nautilus architecture (❌)

**Key Finding**: **5 out of 7 optimizations are fully Nautilus-aligned** with proper implementation. The 2 that conflict (vectorized execution, parallel backtesting) should be implemented as **separate tooling** for parameter optimization, not as replacements for Nautilus backtesting.

---

## Nautilus Architecture Principles (Review)

Before analyzing optimizations, let's establish the core Nautilus principles that must be respected:

### Principle 1: Event-Driven Architecture
**What it means**: All components react to events via message bus. No polling, no direct function calls between components.

**Why it matters**: Ensures realistic simulation and multi-environment consistency (backtest = paper = live).

**Example**:
```python
# ✅ CORRECT - Event-driven
class Strategy(Strategy):
    def on_bar(self, bar: Bar):
        # React to bar event
        self.submit_order(...)

# ❌ WRONG - Direct polling
def process_data(self):
    bars = self.get_next_bars()  # Polling
    for bar in bars:
        self.process(bar)
```

---

### Principle 2: Pre-Registration of Instruments
**What it means**: All instruments must be registered with `BacktestEngine` BEFORE `engine.run()` is called.

**Why it matters**: Nautilus creates matching engines per instrument at registration time. Dynamic registration during backtest is not supported.

**Example**:
```python
# ✅ CORRECT - Pre-register instruments
for instrument in instruments:
    engine.add_instrument(instrument)
engine.run()  # Instruments locked

# ❌ WRONG - Dynamic registration
engine.run()
# ... later during backtest ...
engine.add_instrument(new_instrument)  # NOT SUPPORTED
```

**Related Pattern**: [Instrument Pre-Computation Pattern](07_INSTRUMENT_PRE_COMPUTATION_PATTERN.md)

---

### Principle 3: Data Catalog Abstraction
**What it means**: Data access goes through Nautilus `DataCatalog` interface. Direct parquet/file access breaks abstraction.

**Why it matters**: Catalog provides consistent API, handles filtering, supports multiple storage backends.

**Example**:
```python
# ✅ CORRECT - Use catalog
catalog = ParquetDataCatalog(path)
bars = catalog.bars(instrument_ids=[...], start=..., end=...)

# ❌ WRONG - Direct file access
import pandas as pd
df = pd.read_parquet("data/NIFTY240125C22050/bar.parquet")
```

---

### Principle 4: Actor Pattern for Cross-Environment Logic
**What it means**: Components that need to work in backtest + paper + live should be implemented as `Actor` subclasses.

**Why it matters**: Actors have standardized lifecycle methods (`on_start`, `on_stop`, `on_event`) that work identically across environments.

**Example**:
```python
# ✅ CORRECT - Actor for capital management
class CapitalManager(Actor):
    def on_position_opened(self, event: PositionOpened):
        # Works in backtest, paper, live
        self.reserve_capital(event.position)

# ❌ WRONG - Environment-specific code
if environment == "backtest":
    backtest_capital_manager.reserve(...)
elif environment == "live":
    live_capital_manager.reserve(...)
```

---

### Principle 5: Immutable Data Replay
**What it means**: In backtesting, data is pre-loaded and replayed in chronological order. No modifying historical data during backtest.

**Why it matters**: Prevents look-ahead bias and ensures deterministic results.

**Example**:
```python
# ✅ CORRECT - React to data as it comes
def on_bar(self, bar: Bar):
    # Can only see bars up to current timestamp
    self.process(bar)

# ❌ WRONG - Access future data
def on_bar(self, bar: Bar):
    future_bars = self.catalog.bars(start=bar.ts_event)  # Look-ahead!
```

---

## Optimization Analysis

Now let's analyze each proposed optimization against these principles.

---

## Optimization 1: Catalog-Level Instrument Filtering

**Proposed Implementation**:
```python
# Instead of loading all 33K instruments:
all_instruments = catalog.instruments()  # 33,408 objects
filtered_ids = [id for id in all_instruments if id in required_set]

# Load only required instruments:
filtered_instruments = catalog.instruments(instrument_ids=required_instrument_ids)  # 2,833 objects
```

**Expected Gain**: 20-25 seconds
**Effort**: Low (1-2 hours)
**Priority**: Immediate (Sprint 29)

### Nautilus Architecture Analysis

#### ✅ FULLY ALIGNED

**Compliance with Principles**:
- ✅ **Event-Driven**: Doesn't affect event model
- ✅ **Pre-Registration**: Filtering happens BEFORE `engine.add_instrument()`
- ✅ **Data Catalog**: Uses native catalog API (`instrument_ids` parameter)
- ✅ **Actor Pattern**: N/A (data loading, not logic)
- ✅ **Immutable Replay**: N/A (pre-backtest operation)

**Why This Works**:
1. Nautilus `ParquetDataCatalog.instruments()` already supports filtering via `instrument_ids` parameter
2. This is EXACTLY how Nautilus is designed to be used (see [04_BACKTESTING_BEST_PRACTICES.md](04_BACKTESTING_BEST_PRACTICES.md))
3. Pre-computation pattern ([07_INSTRUMENT_PRE_COMPUTATION_PATTERN.md](07_INSTRUMENT_PRE_COMPUTATION_PATTERN.md)) is Nautilus-validated

**Nautilus-Aligned Implementation**:

```python
# src/nautilus/backtest/backtestnode_runner.py

def _load_filtered_instruments(
    self,
    catalog: ParquetDataCatalog,
    required_instrument_ids: List[str]
) -> List[Instrument]:
    """
    Load only required instruments from catalog using native filtering.

    NAUTILUS BEST PRACTICE:
    - Uses catalog.instruments(instrument_ids=...) for efficient filtering
    - Avoids loading all 33K instruments then filtering in Python
    - Respects catalog abstraction layer
    """
    logger.info(f"Loading {len(required_instrument_ids)} filtered instruments from catalog...")

    # ✅ Use Nautilus native filtering
    filtered_instruments = catalog.instruments(instrument_ids=required_instrument_ids)

    logger.info(f"✅ Loaded {len(filtered_instruments)} instruments (filtered at catalog level)")

    return filtered_instruments
```

**Migration Steps**:
1. Verify `ParquetDataCatalog.instruments()` supports `instrument_ids` parameter (Nautilus 1.190+)
2. Update `backtestnode_runner.py` to pass pre-computed IDs to catalog
3. Remove manual filtering loop
4. Test with 2-month and 21-month backtests

**Sprint 29 Recommendation**: ✅ **IMPLEMENT IMMEDIATELY** - This is textbook Nautilus best practice

---

## Optimization 2: Disable Unnecessary Logging in Hot Path

**Proposed Implementation**:
```python
# Remove DEBUG-level logs from on_bar() callback
def on_bar(self, bar: Bar):
    # ❌ REMOVE THIS - called 553K times
    # self.log.debug(f"Processing bar: {bar.instrument_id} at {bar.ts_event}")

    # ✅ KEEP THIS - only logs on date change
    if bar_date != self._current_date:
        self.log.info(f"📅 Processing: {bar_date} | Bars: {self._bar_count:,}")
```

**Expected Gain**: 50-100 seconds
**Effort**: Very Low (30 minutes)
**Priority**: Immediate (Sprint 29)

### Nautilus Architecture Analysis

#### ✅ FULLY ALIGNED

**Compliance with Principles**:
- ✅ **Event-Driven**: Doesn't affect event model
- ✅ **Pre-Registration**: N/A
- ✅ **Data Catalog**: N/A
- ✅ **Actor Pattern**: Applies to both Strategy and Actor `on_bar()` methods
- ✅ **Immutable Replay**: N/A

**Why This Works**:
1. Nautilus supports standard Python logging levels (DEBUG, INFO, WARNING, ERROR)
2. Logging is already conditional based on log level
3. Hot path optimization is a general performance best practice
4. Doesn't change logic, only observability

**Nautilus Logging Best Practices**:

```python
# ✅ CORRECT - Conditional logging in hot path
class NativeOptionsStrategy(Strategy):
    def __init__(self, config):
        super().__init__(config)
        # Use Nautilus logger (automatically configured)
        # self.log is provided by Strategy base class

    def on_bar(self, bar: Bar):
        # ❌ AVOID - Log on every bar (553K times)
        # self.log.debug(f"Bar: {bar}")

        # ✅ PREFER - Log on significant events only
        if self._should_log_progress(bar):
            self.log.info(f"Progress: {bar.ts_event.date()}")

        # ✅ PREFER - Use log.debug only when actually debugging
        if self.log.is_enabled_for(logging.DEBUG):  # Check before formatting
            self.log.debug(f"Detailed bar info: {bar}")
```

**Nautilus-Aligned Implementation**:

```python
# src/nautilus/strategy/nautilus_options_strategy.py

class NativeOptionsStrategy(Strategy):
    def on_bar(self, bar: Bar):
        """
        PERFORMANCE: This method called 553,169 times in 21-month backtest.
        Avoid expensive operations (logging, I/O) unless necessary.
        """
        # Date-based progress logging (Sprint 28) - runs ~440 times
        bar_date = bar.ts_event.date()
        if bar_date != self._current_date:
            # INFO logging - only on date changes (acceptable overhead)
            self.log.info(
                f"📅 Processing: {bar_date} | "
                f"Bars: {self._bar_count:,} | "
                f"Memory: {self._get_memory_mb():.1f} MB"
            )
            self._current_date = bar_date

        self._bar_count += 1

        # DEBUG logging - only when debugging is enabled
        # NOTE: This is checked BEFORE string formatting (important!)
        if self.log.is_enabled_for(logging.DEBUG) and self._bar_count % 1000 == 0:
            self.log.debug(f"Processed {self._bar_count:,} bars, current: {bar.instrument_id}")

        # Main strategy logic (no logging unless errors)
        try:
            self._process_bar_logic(bar)
        except Exception as e:
            # ERROR logging - always appropriate for exceptions
            self.log.error(f"Error processing bar {bar.instrument_id}: {e}", exc_info=True)
```

**Sprint 29 Recommendation**: ✅ **IMPLEMENT IMMEDIATELY** - Standard performance optimization

---

## Optimization 3: Incremental RSI Calculation

**Proposed Implementation**:
```python
# Replace pandas rolling window RSI with incremental Wilder's smoothing
class IncrementalRSI:
    def update(self, price):
        # Update incrementally instead of full recalculation
        gain = max(price - self.prev_price, 0)
        loss = max(self.prev_price - price, 0)

        if not self.initialized:
            self.avg_gain = gain
            self.avg_loss = loss
        else:
            # Wilder's smoothing (exponential moving average)
            alpha = 1.0 / self.period
            self.avg_gain = (1 - alpha) * self.avg_gain + alpha * gain
            self.avg_loss = (1 - alpha) * self.avg_loss + alpha * loss

        rs = self.avg_gain / self.avg_loss if self.avg_loss != 0 else 0
        rsi = 100 - (100 / (1 + rs))

        self.prev_price = price
        return rsi
```

**Expected Gain**: 300-500 seconds
**Effort**: Medium (1 day)
**Priority**: Immediate (Sprint 29)

### Nautilus Architecture Analysis

#### ✅ FULLY ALIGNED

**Compliance with Principles**:
- ✅ **Event-Driven**: Calculation happens in `on_bar()` event handler
- ✅ **Pre-Registration**: N/A (computational optimization)
- ✅ **Data Catalog**: N/A
- ✅ **Actor Pattern**: Could be implemented as custom Indicator (Actor subclass)
- ✅ **Immutable Replay**: Maintains causal ordering (only uses past data)

**Why This Works**:
1. Incremental calculation is **deterministic** - same result as rolling window
2. Only uses historical data (no look-ahead bias)
3. Fits naturally into event-driven model (update on each bar)
4. Nautilus supports custom indicators via `Indicator` base class

**Nautilus Implementation Options**:

#### Option A: Custom Indicator (BEST PRACTICE)

```python
# src/nautilus/indicators/incremental_rsi.py

from nautilus_trader.indicators.base.indicator import Indicator
from nautilus_trader.model.data import Bar

class IncrementalRSI(Indicator):
    """
    Wilder's RSI using incremental calculation (3-5x faster than rolling window).

    NAUTILUS INTEGRATION:
    - Inherits from Indicator base class
    - Supports proper initialization and state management
    - Can be registered with Strategy for automatic updates
    - Works in backtest, paper, and live environments
    """

    def __init__(self, period: int = 14):
        super().__init__(params=[period])
        self.period = period
        self._avg_gain = 0.0
        self._avg_loss = 0.0
        self._prev_close = None
        self._initialized = False

    def handle_bar(self, bar: Bar):
        """Called automatically when bar event occurs."""
        self.update_raw(float(bar.close))

    def update_raw(self, close: float):
        """
        Incremental RSI update (Wilder's smoothing).

        PERFORMANCE: O(1) instead of O(period) for rolling window.
        """
        if self._prev_close is None:
            self._prev_close = close
            return

        # Calculate gain/loss
        change = close - self._prev_close
        gain = max(change, 0.0)
        loss = max(-change, 0.0)

        if not self._initialized:
            # First calculation
            self._avg_gain = gain
            self._avg_loss = loss
            self._initialized = True
        else:
            # Wilder's smoothing (exponential moving average)
            alpha = 1.0 / self.period
            self._avg_gain = (1 - alpha) * self._avg_gain + alpha * gain
            self._avg_loss = (1 - alpha) * self._avg_loss + alpha * loss

        # Calculate RSI
        if self._avg_loss != 0:
            rs = self._avg_gain / self._avg_loss
            self.value = 100.0 - (100.0 / (1.0 + rs))
        else:
            self.value = 100.0 if self._avg_gain > 0 else 50.0

        self._prev_close = close
        self._has_inputs = True

    def _reset(self):
        """Reset indicator state."""
        self._avg_gain = 0.0
        self._avg_loss = 0.0
        self._prev_close = None
        self._initialized = False


# Usage in Strategy
class NativeOptionsStrategy(Strategy):
    def on_start(self):
        # Register indicator for automatic updates
        self.rsi = IncrementalRSI(period=14)
        # Nautilus automatically calls rsi.handle_bar() on each bar

    def on_bar(self, bar: Bar):
        # Update RSI (if not auto-registered)
        self.rsi.handle_bar(bar)

        # Use RSI value
        if self.rsi.value > 70:
            # Overbought logic
            pass
```

**Advantages of Indicator Approach**:
- ✅ Follows Nautilus patterns
- ✅ Reusable across strategies
- ✅ Automatic state management
- ✅ Works in live trading
- ✅ Can be tested independently

#### Option B: In-Strategy Calculation (SIMPLER)

```python
# src/nautilus/strategy/nautilus_options_strategy.py

class NativeOptionsStrategy(Strategy):
    def __init__(self, config):
        super().__init__(config)
        # RSI state
        self._rsi_period = 14
        self._rsi_avg_gain = 0.0
        self._rsi_avg_loss = 0.0
        self._rsi_prev_close = None
        self._rsi_initialized = False

    def _update_rsi(self, close: float) -> float:
        """Incremental RSI calculation (Wilder's smoothing)."""
        if self._rsi_prev_close is None:
            self._rsi_prev_close = close
            return 50.0  # Neutral RSI

        # Calculate gain/loss
        change = close - self._rsi_prev_close
        gain = max(change, 0.0)
        loss = max(-change, 0.0)

        if not self._rsi_initialized:
            self._rsi_avg_gain = gain
            self._rsi_avg_loss = loss
            self._rsi_initialized = True
        else:
            alpha = 1.0 / self._rsi_period
            self._rsi_avg_gain = (1 - alpha) * self._rsi_avg_gain + alpha * gain
            self._rsi_avg_loss = (1 - alpha) * self._rsi_avg_loss + alpha * loss

        if self._rsi_avg_loss != 0:
            rs = self._rsi_avg_gain / self._rsi_avg_loss
            rsi = 100.0 - (100.0 / (1.0 + rs))
        else:
            rsi = 100.0 if self._rsi_avg_gain > 0 else 50.0

        self._rsi_prev_close = close
        return rsi
```

**Advantages of In-Strategy Approach**:
- ✅ Simpler (no separate class)
- ✅ Faster development
- ❌ Less reusable
- ❌ Harder to test independently

**Sprint 29 Recommendation**: ✅ **IMPLEMENT AS CUSTOM INDICATOR** (Option A) for best Nautilus alignment

---

## Optimization 4: Entry Condition Caching

**Proposed Implementation**:
```python
# Cache negative entry check results by (date, hour)
self.entry_check_cache = {}

def should_enter(self, timestamp):
    cache_key = (timestamp.date(), timestamp.hour)
    if cache_key in self.entry_check_cache:
        return self.entry_check_cache[cache_key]

    result = self._evaluate_entry_conditions(timestamp)
    self.entry_check_cache[cache_key] = result
    return result
```

**Expected Gain**: 200-400 seconds
**Effort**: Medium (1 day)
**Priority**: Immediate (Sprint 29)

### Nautilus Architecture Analysis

#### ⚠️ NAUTILUS-COMPATIBLE WITH CAVEATS

**Compliance with Principles**:
- ⚠️ **Event-Driven**: Caching must not violate event causality
- ✅ **Pre-Registration**: N/A
- ✅ **Data Catalog**: N/A
- ✅ **Actor Pattern**: N/A
- ⚠️ **Immutable Replay**: Cache keys must be deterministic

**Why This Needs Care**:
1. Caching is acceptable as long as cache keys are **deterministic** and **causal**
2. Must not cache results that depend on future data
3. Cache must be cleared/invalidated properly when state changes

**Potential Issues**:

```python
# ❌ DANGEROUS - Caching across bar timestamps
def should_enter(self, bar: Bar):
    cache_key = bar.instrument_id
    if cache_key in self.cache:
        return self.cache[cache_key]  # Could return stale result!

# ✅ SAFE - Caching with timestamp
def should_enter(self, bar: Bar):
    cache_key = (bar.ts_event, bar.instrument_id)  # Unique per bar
    if cache_key in self.cache:
        return self.cache[cache_key]  # Safe - tied to specific bar
```

**Nautilus-Aligned Implementation**:

```python
# src/nautilus/strategy/nautilus_options_strategy.py

from typing import Dict, Tuple, Optional
from datetime import date

class NativeOptionsStrategy(Strategy):
    def __init__(self, config):
        super().__init__(config)

        # Entry condition cache
        # Key: (date, hour) - deterministic and causal
        # Value: (should_enter: bool, reason: str)
        self._entry_check_cache: Dict[Tuple[date, int], Tuple[bool, Optional[str]]] = {}

        # Cache statistics (for monitoring)
        self._cache_hits = 0
        self._cache_misses = 0

    def should_check_entry(self, timestamp: pd.Timestamp) -> Tuple[bool, Optional[str]]:
        """
        Check entry conditions with caching.

        CACHING SAFETY:
        - Cache key: (date, hour) - deterministic
        - Only caches entry CHECKS, not entry DECISIONS
        - Entry checks depend only on time (not price/state)
        - Examples: "Is it Mon/Wed?", "Is it 10:00-10:05?", "Is it D-1?"

        PERFORMANCE:
        - Original: 553,169 calls to entry check logic
        - Cached: ~440 unique (date, hour) combinations
        - Speedup: 1,257x reduction in entry check evaluations
        """
        cache_key = (timestamp.date(), timestamp.hour)

        # Check cache
        if cache_key in self._entry_check_cache:
            self._cache_hits += 1
            return self._entry_check_cache[cache_key]

        self._cache_misses += 1

        # Evaluate entry conditions (expensive)
        should_check, reason = self._evaluate_entry_timing(timestamp)

        # Cache result
        self._entry_check_cache[cache_key] = (should_check, reason)

        # Log cache effectiveness periodically
        if self._cache_misses % 100 == 0:
            hit_rate = self._cache_hits / (self._cache_hits + self._cache_misses)
            self.log.debug(
                f"Entry check cache: {self._cache_hits} hits, "
                f"{self._cache_misses} misses, "
                f"{hit_rate*100:.1f}% hit rate"
            )

        return should_check, reason

    def _evaluate_entry_timing(self, timestamp: pd.Timestamp) -> Tuple[bool, Optional[str]]:
        """
        Evaluate if we should check for entry at this timestamp.

        IMPORTANT: This method should ONLY depend on timestamp, not on:
        - Current positions (state-dependent)
        - Prices (data-dependent)
        - Indicators (data-dependent)

        Safe to cache because result is deterministic for given timestamp.
        """
        # Check day of week
        day_name = timestamp.day_name()
        if day_name not in ['Monday', 'Wednesday']:
            return False, f"Not entry day ({day_name})"

        # Check time window
        hour = timestamp.hour
        if hour != 10:  # 10:00-10:05 window (hourly data = 10:15 actual)
            return False, f"Not entry time ({hour}:00)"

        # Check D-1 prohibition
        # ... (deterministic based on timestamp)

        return True, "Entry timing conditions met"

    def on_bar(self, bar: Bar):
        """Process bar with cached entry checks."""
        timestamp = bar.ts_event

        # Use cached entry timing check
        should_check, reason = self.should_check_entry(timestamp)

        if not should_check:
            return  # Skip expensive entry evaluation

        # Now do expensive checks (price-dependent, can't be cached)
        spot_price = self._get_spot_price(timestamp)
        direction = self._determine_direction(spot_price, timestamp)

        # ... proceed with entry logic

    def on_reset(self):
        """Clear cache when backtest resets."""
        super().on_reset()
        self._entry_check_cache.clear()
        self._cache_hits = 0
        self._cache_misses = 0
        self.log.info("Entry check cache cleared")
```

**What Can Be Safely Cached**:
- ✅ Time-based conditions (day of week, hour, D-1 checks)
- ✅ Expiry-based conditions (DTE calculations if expiries are static)
- ❌ Price-based conditions (RSI, direction, ATM calculations)
- ❌ State-based conditions (position count, cooldowns)

**Sprint 29 Recommendation**: ⚠️ **IMPLEMENT WITH CARE** - Cache only time-based conditions

---

## Optimization 5: Consolidated Bar Storage (V13 Catalog)

**Proposed Implementation**:
```
v13_consolidated/
├── bars/
│   ├── 2024-01.parquet  # All instruments for Jan 2024
│   ├── 2024-02.parquet  # All instruments for Feb 2024
│   ...
│   └── 2025-10.parquet  # All instruments for Oct 2025
└── metadata.json  # Instrument index
```

**Expected Gain**: 200-230 seconds (5-10x faster loading)
**Effort**: High (2-3 days)
**Priority**: Medium-term (Sprint 30)

### Nautilus Architecture Analysis

#### ✅ FULLY ALIGNED (WITH CUSTOM DATA ADAPTER)

**Compliance with Principles**:
- ✅ **Event-Driven**: Doesn't affect event model
- ✅ **Pre-Registration**: Still register instruments before `engine.run()`
- ⚠️ **Data Catalog**: Requires custom DataCatalog implementation
- ✅ **Actor Pattern**: N/A (data layer)
- ✅ **Immutable Replay**: Maintains chronological replay

**Why This Works**:
1. Nautilus supports **custom data catalog implementations**
2. Just need to implement `DataCatalog` interface
3. Engine doesn't care about underlying storage format
4. Consolidated storage is actually BETTER for Nautilus (fewer file handles)

**Nautilus Data Catalog Interface**:

```python
# From Nautilus documentation
class DataCatalog:
    """
    Abstract base class for data catalogs.
    Custom implementations must provide these methods.
    """
    def instruments(
        self,
        instrument_ids: Optional[List[str]] = None,
        **kwargs
    ) -> List[Instrument]:
        """Load instruments from catalog."""
        raise NotImplementedError

    def bars(
        self,
        instrument_ids: Optional[List[str]] = None,
        bar_type: Optional[BarType] = None,
        start: Optional[pd.Timestamp] = None,
        end: Optional[pd.Timestamp] = None,
        **kwargs
    ) -> pd.DataFrame:
        """Load bars from catalog."""
        raise NotImplementedError
```

**Nautilus-Aligned Implementation**:

```python
# src/nautilus/data/consolidated_catalog.py

from nautilus_trader.persistence.catalog import DataCatalog
from nautilus_trader.model.instruments import Instrument
from nautilus_trader.model.data import Bar, BarType
import pandas as pd
from pathlib import Path
from typing import List, Optional
import json

class ConsolidatedParquetCatalog(DataCatalog):
    """
    Consolidated monthly-partitioned parquet catalog for Nautilus.

    DESIGN:
    - Monthly partitions: 2024-01.parquet, 2024-02.parquet, etc.
    - All instruments in single file per month
    - Predicate pushdown for efficient filtering

    NAUTILUS COMPLIANCE:
    - Implements DataCatalog interface
    - Returns standard Nautilus objects (Instrument, Bar)
    - Works with BacktestEngine via catalog.bars()
    - Transparent to strategy code

    PERFORMANCE:
    - 21 file reads instead of 8,499 (404x reduction)
    - Predicate pushdown filters at parquet level
    - Sequential reads instead of random seeks
    """

    def __init__(self, catalog_path: str):
        self.catalog_path = Path(catalog_path)
        self.bars_path = self.catalog_path / "bars"
        self.metadata_path = self.catalog_path / "metadata.json"

        # Load metadata
        with open(self.metadata_path) as f:
            self.metadata = json.load(f)

    def instruments(
        self,
        instrument_ids: Optional[List[str]] = None,
        **kwargs
    ) -> List[Instrument]:
        """
        Load instruments from catalog metadata.

        NAUTILUS COMPLIANCE:
        - Supports filtering via instrument_ids parameter
        - Returns List[Instrument] (Nautilus native objects)
        """
        # Load instrument definitions from metadata
        all_instruments = self._load_instrument_objects()

        if instrument_ids is None:
            return all_instruments

        # Filter to requested IDs
        instrument_id_set = set(instrument_ids)
        return [inst for inst in all_instruments if str(inst.id) in instrument_id_set]

    def bars(
        self,
        instrument_ids: Optional[List[str]] = None,
        bar_type: Optional[BarType] = None,
        start: Optional[pd.Timestamp] = None,
        end: Optional[pd.Timestamp] = None,
        **kwargs
    ) -> pd.DataFrame:
        """
        Load bars using predicate pushdown for efficiency.

        NAUTILUS COMPLIANCE:
        - Returns DataFrame with Nautilus bar schema
        - Supports filtering by instrument_ids, start, end
        - Used by BacktestEngine via engine.add_data()

        PERFORMANCE OPTIMIZATION:
        - Determine which monthly files to read (e.g., 2024-01 to 2024-03)
        - Read only those files (3 files instead of 2,833 directories)
        - Use parquet predicate pushdown to filter rows
        """
        # Determine which monthly files to read
        monthly_files = self._get_monthly_files(start, end)

        # Read monthly files with predicate pushdown
        dfs = []
        for monthly_file in monthly_files:
            df = pd.read_parquet(
                monthly_file,
                filters=[
                    ("instrument_id", "in", instrument_ids)  # Predicate pushdown
                ] if instrument_ids else None
            )
            dfs.append(df)

        # Concatenate and filter by date range
        bars_df = pd.concat(dfs, ignore_index=True)

        if start:
            bars_df = bars_df[bars_df['ts_event'] >= start]
        if end:
            bars_df = bars_df[bars_df['ts_event'] <= end]

        return bars_df

    def _get_monthly_files(
        self,
        start: Optional[pd.Timestamp],
        end: Optional[pd.Timestamp]
    ) -> List[Path]:
        """
        Determine which monthly parquet files to read.

        Example: start=2024-01-01, end=2024-03-31
        Returns: [2024-01.parquet, 2024-02.parquet, 2024-03.parquet]
        """
        # Generate list of YYYY-MM partitions
        # ... implementation ...
        pass


# Usage with BacktestNode (transparent replacement)
catalog = ConsolidatedParquetCatalog("data/catalogs/v13_consolidated")

# Everything else works exactly the same
instruments = catalog.instruments(instrument_ids=required_ids)
bars = catalog.bars(instrument_ids=required_ids, start=start_date, end=end_date)

# BacktestEngine uses catalog transparently
engine.add_data(bars, client_id=ClientId("NSE"))
```

**Migration Path**:

1. **Create V13 Catalog Builder** (1 day)
   ```python
   # scripts/build_v13_catalog.py
   # Read V12 fragmented catalog
   # Write V13 consolidated catalog
   ```

2. **Implement ConsolidatedParquetCatalog** (1 day)
   - Implement DataCatalog interface
   - Test with small dataset

3. **Validate Against V12** (0.5 day)
   - Run same backtest on V12 and V13
   - Verify identical results

4. **Deploy** (0.5 day)
   - Update runner to use V13 catalog
   - Keep V12 for fallback

**Sprint 30 Recommendation**: ✅ **IMPLEMENT AS CUSTOM DATA CATALOG** - Fully Nautilus-compliant

---

## Optimization 6: Vectorized FastBacktest Mode

**Proposed Implementation**:
```python
# Load all data into DataFrames
bars_df = load_all_bars()

# Apply strategy logic using vectorized operations
bars_df['rsi'] = calculate_rsi_vectorized(bars_df['close'])
bars_df['should_enter'] = (bars_df['day'].isin(['Mon', 'Wed'])) & (bars_df['hour'] == 10)

# Generate trades in bulk
trades = bars_df[bars_df['should_enter']].apply(execute_entry)
```

**Expected Gain**: 2,000-2,500 seconds (3-4x faster)
**Effort**: Very High (2-3 weeks)
**Priority**: Long-term (Sprint 31+)

### Nautilus Architecture Analysis

#### ❌ FUNDAMENTALLY CONFLICTS WITH NAUTILUS

**Compliance with Principles**:
- ❌ **Event-Driven**: Violates event-driven model (batch processing)
- ❌ **Pre-Registration**: N/A
- ❌ **Data Catalog**: Bypasses catalog (direct DataFrame access)
- ❌ **Actor Pattern**: Cannot use Actors (no event bus)
- ❌ **Immutable Replay**: Violates replay model (sees all data at once)

**Why This Doesn't Work with Nautilus**:
1. Nautilus is fundamentally **event-driven** - all components expect events
2. Strategy.on_bar() is the core abstraction - can't skip it
3. Portfolio state management depends on event ordering
4. Actors depend on event bus - no events = no actors

**Correct Approach**: Separate Tool

```python
# DON'T: Try to make Nautilus do vectorized backtesting
# DO: Create separate FastBacktest tool for parameter optimization

# src/backtest/fast_backtest.py (SEPARATE FROM NAUTILUS)

class FastBacktest:
    """
    Vectorized backtest for parameter optimization.

    IMPORTANT:
    - NOT a replacement for Nautilus backtest
    - NOT used for paper/live trading
    - ONLY for rapid parameter sweeps

    WORKFLOW:
    1. Use FastBacktest for parameter optimization (fast, approximate)
    2. Validate best parameters with Nautilus backtest (slow, realistic)
    3. Use Nautilus for paper/live trading (same code as backtest)
    """

    def run(self, params: dict) -> dict:
        # Load data
        bars = self._load_bars_vectorized()

        # Apply strategy logic (vectorized)
        signals = self._generate_signals_vectorized(bars, params)

        # Calculate P&L (vectorized)
        pnl = self._calculate_pnl_vectorized(signals)

        return {"pnl": pnl, "trades": len(signals)}


# Usage: Parameter optimization
parameters_to_test = [
    {"rsi_period": 10, "profit_target": 0.5},
    {"rsi_period": 14, "profit_target": 0.6},
    {"rsi_period": 20, "profit_target": 0.7},
]

results = []
for params in parameters_to_test:
    # Fast backtest (5 minutes per 21-month test)
    result = FastBacktest().run(params)
    results.append((params, result))

# Find best parameters
best_params = max(results, key=lambda x: x[1]['pnl'])[0]

# Validate with Nautilus (69 minutes, realistic)
nautilus_result = run_backtestnode_backtest(config=best_params)

# If validated, use for paper/live trading (same Nautilus code)
```

**Architecture Diagram**:

```
Parameter Optimization Workflow:

┌─────────────────────┐
│  FastBacktest       │  ← Fast (5 min), approximate
│  (Vectorized)       │  ← 100+ parameter combinations
└──────────┬──────────┘
           │ Find best parameters
           ↓
┌─────────────────────┐
│  Nautilus Backtest  │  ← Slow (69 min), realistic
│  (Event-Driven)     │  ← Validate top 3-5 combinations
└──────────┬──────────┘
           │ Best parameters confirmed
           ↓
┌─────────────────────┐
│  Nautilus Paper     │  ← Same code as backtest
│  Trading            │  ← Real-time validation
└──────────┬──────────┘
           │ Paper validated
           ↓
┌─────────────────────┐
│  Nautilus Live      │  ← Same code as backtest/paper
│  Trading            │  ← Production
└─────────────────────┘
```

**Sprint 31+ Recommendation**: ⚠️ **IMPLEMENT AS SEPARATE TOOL** - Do NOT try to integrate with Nautilus

---

## Optimization 7: Parallel Backtest Execution

**Proposed Implementation**:
```python
# Split timeline into chunks
chunks = [
    ("2024-01-01", "2024-06-30"),  # Core 1
    ("2024-07-01", "2024-12-31"),  # Core 2
    ("2025-01-01", "2025-06-30"),  # Core 3
    ("2025-07-01", "2025-10-15"),  # Core 4
]

# Run in parallel
from joblib import Parallel, delayed
results = Parallel(n_jobs=4)(
    delayed(run_backtest)(start, end) for start, end in chunks
)

# Merge results
final_results = merge_backtest_results(results)
```

**Expected Gain**: 4x with 4 cores (3,610s → 900s)
**Effort**: Very High (3-4 weeks)
**Priority**: Long-term (Sprint 31+)

### Nautilus Architecture Analysis

#### ❌ EXTREMELY DIFFICULT WITH NAUTILUS

**Compliance with Principles**:
- ⚠️ **Event-Driven**: Each parallel backtest is event-driven (OK)
- ⚠️ **Pre-Registration**: Each backtest pre-registers instruments (OK)
- ⚠️ **Data Catalog**: Each backtest uses catalog (OK)
- ⚠️ **Actor Pattern**: Each backtest has actors (OK)
- ❌ **Immutable Replay**: State merging at chunk boundaries is very hard

**Why This Is Very Hard**:
1. **Position state continuity**: Positions opened in chunk 1 must carry to chunk 2
2. **Capital tracking**: Deployed capital affects future entries
3. **Cooldown tracking**: Exit cooldowns span chunk boundaries
4. **Event ordering**: Parallel chunks violate causal ordering

**Challenges**:

```python
# Example: Position opened in chunk 1, closed in chunk 2
# Chunk 1: 2024-01-01 to 2024-06-30
# → Opens monthly position on 2024-01-04
# → Position still open at chunk end (2024-06-30)

# Chunk 2: 2024-07-01 to 2024-12-31
# → Needs initial state: position from chunk 1
# → But chunk 2 runs in parallel (doesn't know chunk 1 state yet!)

# This requires:
# 1. Sequential chunk execution (loses parallelism)
# 2. OR predictive state transfer (extremely complex)
```

**Possible Approaches**:

#### Approach A: Parameter-Level Parallelism (RECOMMENDED)

```python
# Don't parallelize single backtest
# DO parallelize multiple backtests (different parameters)

# ✅ CORRECT - Parallel parameter sweep
from joblib import Parallel, delayed

def run_single_backtest(params):
    """Run one complete backtest (sequential, 69 min)."""
    return run_backtestnode_backtest(config=params)

# Run 4 backtests in parallel (different parameters)
parameter_sets = [
    {"rsi_period": 10, "profit_target": 0.5},
    {"rsi_period": 14, "profit_target": 0.6},
    {"rsi_period": 18, "profit_target": 0.7},
    {"rsi_period": 20, "profit_target": 0.8},
]

results = Parallel(n_jobs=4)(
    delayed(run_single_backtest)(params)
    for params in parameter_sets
)

# Result: 4 backtests complete in 69 minutes instead of 276 minutes
```

**Advantages**:
- ✅ Trivial to implement
- ✅ No state merging complexity
- ✅ Works with Nautilus as-is
- ✅ Perfect for parameter optimization

**Limitations**:
- ❌ Doesn't speed up single backtest
- ✅ But that's OK - use for parameter sweeps

#### Approach B: Timeline Chunking with State Transfer (NOT RECOMMENDED)

```python
# ❌ VERY COMPLEX - Timeline chunking

def run_chunk(start, end, initial_state):
    """
    Run backtest chunk with initial state from previous chunk.

    PROBLEMS:
    - initial_state must include ALL state (positions, capital, cooldowns)
    - State serialization/deserialization is complex
    - Nautilus doesn't support initializing with arbitrary state
    - Very hard to debug
    """
    engine = BacktestEngine()

    # TODO: How to initialize Nautilus with initial_state?
    # Nautilus doesn't provide this API!
    engine.set_initial_state(initial_state)  # ← Doesn't exist!

    engine.run()
    return engine.get_final_state()

# Run chunks sequentially (must wait for previous chunk)
state = {}
for chunk in chunks:
    state = run_chunk(chunk.start, chunk.end, state)
    # Now can start next chunk with this state
    # But this is sequential! Lost parallelism!
```

**Why This Doesn't Work**:
- Nautilus doesn't support arbitrary state initialization
- Would need deep Nautilus internals knowledge
- Very fragile (breaks on Nautilus updates)
- Gains are minimal vs complexity

**Sprint 31+ Recommendation**: ✅ **IMPLEMENT PARAMETER-LEVEL PARALLELISM** - Simple and effective

---

## Summary Matrix

| Optimization | Nautilus Alignment | Effort | Gain | Sprint | Recommendation |
|--------------|-------------------|---------|------|---------|----------------|
| **1. Catalog Filtering** | ✅ Fully Aligned | Low | 20-25s | Sprint 29 | ✅ Implement immediately |
| **2. Disable Logging** | ✅ Fully Aligned | Very Low | 50-100s | Sprint 29 | ✅ Implement immediately |
| **3. Incremental RSI** | ✅ Fully Aligned | Medium | 300-500s | Sprint 29 | ✅ Implement as Indicator |
| **4. Entry Caching** | ⚠️ Compatible with caveats | Medium | 200-400s | Sprint 29 | ⚠️ Cache time-based only |
| **5. Consolidated Catalog** | ✅ Aligned (custom adapter) | High | 200-230s | Sprint 30 | ✅ Implement as DataCatalog |
| **6. Vectorized Backtest** | ❌ Conflicts | Very High | 2,000-2,500s | Sprint 31+ | ⚠️ Separate tool only |
| **7. Parallel Execution** | ❌ Very Difficult | Very High | 4x speedup | Sprint 31+ | ✅ Parameter-level only |

**Legend**:
- ✅ Fully Aligned: Follows Nautilus patterns exactly
- ⚠️ Compatible: Works with Nautilus but needs care
- ❌ Conflicts: Fundamentally incompatible with Nautilus

---

## Sprint Implementation Roadmap

### Sprint 29: Quick Wins (All Nautilus-Aligned)

**Goal**: 69 min → 50-60 min (15-27% faster)

**Tasks**:
1. ✅ Catalog-level filtering (1-2 hours)
   - Update `backtestnode_runner.py` to use `catalog.instruments(instrument_ids=...)`
   - Test with 2-month backtest

2. ✅ Disable hot path logging (30 min)
   - Remove DEBUG logs from `on_bar()`
   - Add log level checks before formatting

3. ✅ Incremental RSI as Indicator (1 day)
   - Create `IncrementalRSI(Indicator)` class
   - Replace pandas rolling window in strategy
   - Unit test for correctness

4. ⚠️ Entry condition caching (1 day)
   - Cache time-based conditions only
   - Add cache invalidation on reset
   - Monitor cache hit rate

**Deliverables**:
- All changes follow Nautilus patterns
- Can be deployed to paper/live trading
- Backward compatible (old code still works)

---

### Sprint 30: Consolidated Catalog (Nautilus Custom Adapter)

**Goal**: 50 min → 20-30 min (40-60% faster)

**Tasks**:
1. ✅ Design V13 catalog schema (0.5 day)
   - Monthly partitions: `2024-01.parquet`, etc.
   - Metadata structure
   - Migration plan

2. ✅ Implement `ConsolidatedParquetCatalog(DataCatalog)` (1 day)
   - Implement required methods
   - Support predicate pushdown
   - Test with small dataset

3. ✅ Build V13 catalog from V12 (0.5 day)
   - Create builder script
   - Run conversion (one-time)

4. ✅ Validation (0.5 day)
   - Run same backtest on V12 and V13
   - Compare results (should be identical)

5. ✅ Deploy (0.5 day)
   - Update runner to use V13
   - Keep V12 for fallback

**Deliverables**:
- Custom DataCatalog implementation
- Fully Nautilus-compliant
- 5-10x faster data loading

---

### Sprint 31+: Separate Optimization Tools

**Goal**: Enable rapid parameter optimization

**Tasks**:
1. ⚠️ FastBacktest tool (2-3 weeks)
   - **SEPARATE from Nautilus**
   - Vectorized implementation
   - Use for parameter sweeps only
   - Validate with Nautilus

2. ✅ Parameter-level parallelism (1 week)
   - Use joblib for parallel backtests
   - Different parameters per core
   - Simple wrapper around Nautilus

**Deliverables**:
- FastBacktest tool (not integrated with Nautilus)
- Parallel parameter optimization
- Clear workflow: FastBacktest → Nautilus validation → Paper → Live

---

## Key Takeaways for Future Sprint Design

### 1. Always Check Nautilus Alignment First

Before proposing any optimization, ask:
- Does it respect event-driven architecture?
- Does it work with pre-registered instruments?
- Does it use catalog abstraction?
- Can it work in paper/live trading?

### 2. Separate Optimization from Trading Logic

**Nautilus-Aligned Optimizations**:
- Data loading (catalog format)
- Computational efficiency (incremental calculations)
- Caching (deterministic, causal)

**Non-Nautilus Optimizations** (separate tools):
- Vectorized backtesting
- Approximate simulations
- Timeline parallelization

### 3. Prioritize Multi-Environment Compatibility

If an optimization only works in backtesting, it's probably:
- Breaking Nautilus patterns
- Creating technical debt
- Limiting future capabilities

Better to:
- Find Nautilus-aligned solution
- OR implement as separate tool

### 4. Use Nautilus Extension Points

Nautilus provides extension points:
- Custom Indicators
- Custom DataCatalogs
- Custom Actors
- Custom ExecutionAlgorithms

Use these instead of monkeypatching or bypassing framework.

### 5. Document Architectural Decisions

For each optimization, document:
- ✅ Why it's Nautilus-aligned (or not)
- ✅ What Nautilus principles it respects
- ✅ How it integrates with framework
- ✅ Migration path for paper/live trading

---

## References

1. [Nautilus Architecture Overview](00_OVERVIEW.md)
2. [Nautilus Backtesting Best Practices](04_BACKTESTING_BEST_PRACTICES.md)
3. [Instrument Pre-Computation Pattern](07_INSTRUMENT_PRE_COMPUTATION_PATTERN.md)
4. [21-Month Backtest Timing Analysis](../../SESSION_STATUS_20251020_21MONTH_BACKTEST_TIMING_ANALYSIS.md)
5. [Nautilus Official Documentation](https://nautilustrader.io/docs/latest/)

---

**Last Updated**: 2025-10-20
**Status**: Complete - Ready for Sprint Planning
**Next Review**: Before Sprint 29 kickoff
