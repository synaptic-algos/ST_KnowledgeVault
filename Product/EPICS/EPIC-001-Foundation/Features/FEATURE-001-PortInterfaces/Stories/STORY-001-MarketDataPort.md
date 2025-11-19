---
progress_pct: 0.0
status: planned
---

# STORY-001-01-01: Define MarketDataPort Interface

## Story Overview

**Story ID**: STORY-001-01-01
**Title**: Define MarketDataPort Interface
**Feature**: [FEATURE-001: Port Interface Definitions](../README.md)
**Epic**: [EPIC-001: Foundation & Core Architecture](../../README.md)
**Status**: 📋 Planned
**Priority**: P0
**Assignee**: Senior Engineer 1
**Estimated Effort**: 1 day (8 hours)

## User Story

**As a** strategy developer
**I want** a MarketDataPort interface that abstracts market data access
**So that** my strategy can access ticks, bars, and historical data from any execution framework

## Acceptance Criteria

- [ ] MarketDataPort abstract base class created in `src/application/ports/market_data_port.py`
- [ ] All methods defined with `@abstractmethod` decorator
- [ ] Comprehensive docstrings for class and all methods (Google style)
- [ ] Type hints on all parameters and return values
- [ ] Contract test suite validates interface compliance
- [ ] MockMarketDataPort implementation for testing
- [ ] Code passes mypy type checking
- [ ] Code review approved
- [ ] Documentation generated and reviewed

## Description

The MarketDataPort is the primary interface for accessing market data in a framework-agnostic way. It must support:
- Real-time tick/quote access
- OHLCV bar data (multiple granularities)
- Historical data lookup for indicator warmup
- Instrument metadata queries
- Optional streaming for live data

The interface must guarantee:
- **Immutability**: All returned data are defensive copies
- **Thread-safety**: Concurrent access from multiple strategies
- **Timezone awareness**: All timestamps in UTC
- **Canonical IDs**: Instrument identifiers normalized

## Technical Details

### Methods to Implement

1. `get_latest_tick(instrument_id: InstrumentId) -> Optional[MarketTick]`
   - Returns most recent tick for instrument
   - Returns None if no data available

2. `get_latest_bar(instrument_id: InstrumentId, granularity: BarGranularity) -> Optional[Bar]`
   - Returns most recent completed bar
   - Granularity: MINUTE_1, MINUTE_5, HOUR_1, DAY_1, etc.

3. `lookup_history(instrument_id: InstrumentId, window: HistoryWindow) -> List[Bar]`
   - Fetches historical bars for lookback calculations
   - Returns chronological list (oldest first)

4. `stream_ticks(instrument_id: InstrumentId) -> Iterator[MarketTick]`
   - Streams real-time ticks (live/paper only)
   - Backtest adapters yield historical ticks

5. `get_instrument_info(instrument_id: InstrumentId) -> InstrumentInfo`
   - Returns contract specifications
   - Tick size, lot size, multiplier, etc.

### Error Handling

```python
class InstrumentNotFoundError(Exception):
    """Raised when instrument unknown to adapter."""
    pass

class DataUnavailableError(Exception):
    """Raised when data temporarily unavailable."""
    pass
```

## Tasks

### Task List

| Task ID | Task Description | Est. | Status |
|---------|------------------|------|--------|
| [TASK-001-01-01-01](#task-001-01-01-01) | Create port module file and imports | 0.5h | 📋 |
| [TASK-001-01-01-02](#task-001-01-01-02) | Define MarketDataPort ABC skeleton | 0.5h | 📋 |
| [TASK-001-01-01-03](#task-001-01-01-03) | Implement get_latest_tick method signature | 0.5h | 📋 |
| [TASK-001-01-01-04](#task-001-01-01-04) | Implement get_latest_bar method signature | 0.5h | 📋 |
| [TASK-001-01-01-05](#task-001-01-01-05) | Implement lookup_history method signature | 0.5h | 📋 |
| [TASK-001-01-01-06](#task-001-01-01-06) | Implement stream_ticks method signature | 0.5h | 📋 |
| [TASK-001-01-01-07](#task-001-01-01-07) | Implement get_instrument_info method signature | 0.5h | 📋 |
| [TASK-001-01-01-08](#task-001-01-01-08) | Write comprehensive docstrings | 1h | 📋 |
| [TASK-001-01-01-09](#task-001-01-01-09) | Create contract test suite | 1.5h | 📋 |
| [TASK-001-01-01-10](#task-001-01-01-10) | Implement MockMarketDataPort | 1.5h | 📋 |
| [TASK-001-01-01-11](#task-001-01-01-11) | Run mypy and fix type issues | 0.5h | 📋 |
| [TASK-001-01-01-12](#task-001-01-01-12) | Code review and polish | 0.5h | 📋 |

**Total**: 12 tasks, 8 hours

---

## Task Details

### TASK-001-01-01-01
**Title**: Create port module file and imports
**Effort**: 0.5 hours
**Description**: Create `src/application/ports/market_data_port.py` with necessary imports

**Checklist**:
- [ ] Create file `src/application/ports/market_data_port.py`
- [ ] Add module docstring
- [ ] Import ABC, abstractmethod from abc
- [ ] Import typing utilities (Optional, List, Iterator)
- [ ] Import domain types (InstrumentId, MarketTick, Bar, etc.)
- [ ] Add `__all__` export list

**Code**:
```python
"""
Market data port interface.

Provides framework-agnostic access to market data including ticks,
bars, historical data, and instrument metadata.
"""

from abc import ABC, abstractmethod
from datetime import datetime
from typing import Iterator, List, Optional

from src.domain.shared.value_objects import (
    InstrumentId,
    MarketTick,
    Bar,
    BarGranularity,
)

__all__ = ["MarketDataPort", "HistoryWindow", "InstrumentInfo"]
```

---

### TASK-001-01-01-02
**Title**: Define MarketDataPort ABC skeleton
**Effort**: 0.5 hours
**Description**: Create the abstract base class with class-level documentation

**Checklist**:
- [ ] Define MarketDataPort class inheriting from ABC
- [ ] Write comprehensive class docstring
- [ ] Document guarantees (immutability, thread-safety, timezone)
- [ ] Document adapter responsibilities

**Code**:
```python
class MarketDataPort(ABC):
    """
    Abstract interface for market data access.

    Adapters implement this interface to provide framework-agnostic
    access to market data. All methods must be thread-safe and return
    immutable data structures.

    Guarantees:
        - All timestamps are UTC timezone-aware
        - Returned data structures are immutable (defensive copies)
        - Thread-safe for concurrent access
        - Canonical instrument identifiers used throughout

    Adapter Responsibilities:
        - Normalize engine-specific data to canonical format
        - Handle timezone conversions to UTC
        - Provide defensive copies to prevent mutation
        - Implement efficient caching if applicable
        - Document data latency characteristics
    """
    pass
```

---

### TASK-001-01-01-03
**Title**: Implement get_latest_tick method signature
**Effort**: 0.5 hours
**Description**: Define get_latest_tick abstract method with full documentation

**Checklist**:
- [ ] Add @abstractmethod decorator
- [ ] Define method signature with type hints
- [ ] Write detailed docstring (Args, Returns, Raises)
- [ ] Document edge cases (None return, exceptions)

**Code**:
```python
@abstractmethod
def get_latest_tick(
    self,
    instrument_id: InstrumentId
) -> Optional[MarketTick]:
    """
    Retrieve most recent tick for instrument.

    Args:
        instrument_id: Canonical instrument identifier

    Returns:
        MarketTick with bid/ask/last prices and sizes, or None if
        no data is currently available (e.g., pre-market, halted).

    Raises:
        InstrumentNotFoundError: If instrument is unknown to adapter.
            This typically means the instrument is not in the configured
            universe or has not been subscribed to.

    Thread-safe: Yes

    Example:
        >>> port = get_market_data_port()
        >>> tick = port.get_latest_tick(
        ...     InstrumentId.parse("NASDAQ:AAPL:STOCK")
        ... )
        >>> if tick:
        ...     print(f"Bid: {tick.bid}, Ask: {tick.ask}")
    """
    pass
```

---

### TASK-001-01-01-04
**Title**: Implement get_latest_bar method signature
**Effort**: 0.5 hours
**Description**: Define get_latest_bar abstract method

**Checklist**:
- [ ] Add @abstractmethod decorator
- [ ] Define method signature with type hints
- [ ] Write detailed docstring
- [ ] Document bar completion semantics

**Code**:
```python
@abstractmethod
def get_latest_bar(
    self,
    instrument_id: InstrumentId,
    granularity: BarGranularity
) -> Optional[Bar]:
    """
    Retrieve most recent completed bar.

    Args:
        instrument_id: Canonical instrument identifier
        granularity: Bar timeframe (MINUTE_1, MINUTE_5, HOUR_1, DAY_1, etc.)

    Returns:
        Bar with OHLCV data, or None if unavailable.

    Raises:
        InstrumentNotFoundError: If instrument unknown
        UnsupportedGranularityError: If granularity not available

    Guarantees:
        - Bar represents COMPLETED period (close time in past)
        - Timestamp is bar close time (end of period)
        - Volume is normalized to instrument units

    Note:
        For live data, this returns the last completed bar, NOT the
        current forming bar. Strategies should use get_latest_tick()
        for intra-bar price action.

    Thread-safe: Yes
    """
    pass
```

---

### TASK-001-01-01-05
**Title**: Implement lookup_history method signature
**Effort**: 0.5 hours
**Description**: Define lookup_history abstract method for historical data

**Checklist**:
- [ ] Add @abstractmethod decorator
- [ ] Define method signature with type hints
- [ ] Write detailed docstring
- [ ] Document data ordering and gap handling

**Code**:
```python
@abstractmethod
def lookup_history(
    self,
    instrument_id: InstrumentId,
    window: HistoryWindow
) -> List[Bar]:
    """
    Fetch historical bars for lookback calculations.

    Used primarily for indicator warmup (e.g., loading 200 bars for
    a 200-period moving average).

    Args:
        instrument_id: Canonical instrument identifier
        window: Specifies count, granularity, and optional end_time

    Returns:
        List of bars in chronological order (oldest first).
        May be shorter than requested if insufficient history.

    Raises:
        InstrumentNotFoundError: If instrument unknown
        DataUnavailableError: If historical data not available

    Guarantees:
        - Bars returned in chronological order (oldest → newest)
        - No duplicate bars
        - Gap handling per adapter policy (forward-fill, raise, None)

    Example:
        >>> window = HistoryWindow(
        ...     count=200,
        ...     granularity=BarGranularity.DAY_1
        ... )
        >>> bars = port.lookup_history(instrument_id, window)
        >>> assert len(bars) <= 200
        >>> assert bars[0].timestamp < bars[-1].timestamp

    Thread-safe: Yes
    """
    pass
```

---

### TASK-001-01-01-06
**Title**: Implement stream_ticks method signature
**Effort**: 0.5 hours
**Description**: Define stream_ticks abstract method for real-time streaming

**Checklist**:
- [ ] Add @abstractmethod decorator
- [ ] Define method signature returning Iterator
- [ ] Write detailed docstring
- [ ] Document backtest vs. live behavior

**Code**:
```python
@abstractmethod
def stream_ticks(
    self,
    instrument_id: InstrumentId
) -> Iterator[MarketTick]:
    """
    Stream real-time ticks (live/paper trading only).

    Yields ticks as they arrive. For backtesting, this yields
    historical ticks from recorded data.

    Args:
        instrument_id: Canonical instrument identifier

    Yields:
        MarketTick objects as they arrive/replay

    Raises:
        InstrumentNotFoundError: If instrument unknown

    Behavior by Mode:
        - Live/Paper: Yields ticks as received from exchange/provider
        - Backtest: Yields historical ticks in chronological order

    Note:
        This is a generator/iterator. Adapters may:
        - Buffer ticks for batching
        - Throttle tick rate
        - Synthesize ticks from bars if tick data unavailable

    Example:
        >>> for tick in port.stream_ticks(instrument_id):
        ...     strategy.on_market_data(tick)
        ...     if should_stop:
        ...         break

    Thread-safe: Depends on adapter implementation
    """
    pass
```

---

### TASK-001-01-01-07
**Title**: Implement get_instrument_info method signature
**Effort**: 0.5 hours
**Description**: Define get_instrument_info abstract method for metadata

**Checklist**:
- [ ] Add @abstractmethod decorator
- [ ] Define method signature with type hints
- [ ] Write detailed docstring
- [ ] Document InstrumentInfo structure

**Code**:
```python
@abstractmethod
def get_instrument_info(
    self,
    instrument_id: InstrumentId
) -> InstrumentInfo:
    """
    Fetch instrument metadata and contract specifications.

    Returns static information about the trading instrument including
    tick size, lot size, multiplier, etc.

    Args:
        instrument_id: Canonical instrument identifier

    Returns:
        InstrumentInfo with contract specifications

    Raises:
        InstrumentNotFoundError: If instrument unknown

    InstrumentInfo Fields:
        - tick_size: Minimum price increment
        - lot_size: Minimum quantity increment
        - multiplier: Contract multiplier (for futures/options)
        - currency: Quote currency
        - exchange: Primary exchange/venue
        - asset_class: EQUITY, FUTURE, OPTION, FOREX, CRYPTO
        - trading_hours: Regular trading hours

    Thread-safe: Yes (instrument info is immutable)

    Example:
        >>> info = port.get_instrument_info(instrument_id)
        >>> print(f"Tick size: {info.tick_size}")
        >>> print(f"Multiplier: {info.multiplier}")
    """
    pass
```

---

### TASK-001-01-01-08
**Title**: Write comprehensive docstrings
**Effort**: 1 hour
**Description**: Review and polish all docstrings for clarity and completeness

**Checklist**:
- [ ] Class docstring covers purpose and guarantees
- [ ] All methods have complete docstrings
- [ ] Examples provided where helpful
- [ ] Edge cases documented
- [ ] Thread-safety documented
- [ ] Related methods cross-referenced
- [ ] Run docstring linter (pydocstyle)

---

### TASK-001-01-01-09
**Title**: Create contract test suite
**Effort**: 1.5 hours
**Description**: Write contract tests that all MarketDataPort implementations must pass

**Checklist**:
- [ ] Create `tests/contracts/test_market_data_port_contract.py`
- [ ] Test immutability of returned data
- [ ] Test exception handling (unknown instrument)
- [ ] Test thread-safety (concurrent access)
- [ ] Test timezone (all timestamps UTC)
- [ ] Test data ordering (history chronological)
- [ ] Document how adapters run contract tests

**Code**:
```python
# tests/contracts/test_market_data_port_contract.py
"""
Contract tests for MarketDataPort.

All adapters implementing MarketDataPort must pass these tests.
"""

import pytest
from datetime import timezone

def test_get_latest_tick_returns_immutable(market_data_port, test_instrument):
    """Returned ticks must be immutable."""
    tick = market_data_port.get_latest_tick(test_instrument)
    if tick is not None:
        with pytest.raises((AttributeError, TypeError)):
            tick.bid = Price(Decimal("999.99"))

def test_get_latest_tick_unknown_instrument(market_data_port):
    """Must raise InstrumentNotFoundError for unknown instruments."""
    unknown = InstrumentId.parse("UNKNOWN:XXX:STOCK")
    with pytest.raises(InstrumentNotFoundError):
        market_data_port.get_latest_tick(unknown)

def test_lookup_history_chronological_order(market_data_port, test_instrument):
    """Historical bars must be in chronological order (oldest first)."""
    window = HistoryWindow(count=10, granularity=BarGranularity.DAY_1)
    bars = market_data_port.lookup_history(test_instrument, window)

    for i in range(1, len(bars)):
        assert bars[i-1].timestamp < bars[i].timestamp

def test_timestamps_are_utc(market_data_port, test_instrument):
    """All timestamps must be UTC timezone-aware."""
    tick = market_data_port.get_latest_tick(test_instrument)
    if tick is not None:
        assert tick.timestamp.tzinfo == timezone.utc
```

---

### TASK-001-01-01-10
**Title**: Implement MockMarketDataPort
**Effort**: 1.5 hours
**Description**: Create mock implementation for strategy testing

**Checklist**:
- [ ] Create `tests/mocks/mock_market_data_port.py`
- [ ] Implement all abstract methods
- [ ] Support configurable behaviors (delays, errors)
- [ ] Provide helper methods to inject test data
- [ ] Document usage in docstring
- [ ] Validate mock passes contract tests

**Code**:
```python
# tests/mocks/mock_market_data_port.py
"""Mock implementation of MarketDataPort for testing."""

from collections import defaultdict
from typing import Dict, List, Optional
from src.application.ports.market_data_port import MarketDataPort

class MockMarketDataPort(MarketDataPort):
    """
    Mock market data port for strategy testing.

    Allows strategies to be tested with predictable, deterministic data
    without requiring a real execution framework.

    Usage:
        >>> mock_port = MockMarketDataPort()
        >>> mock_port.set_tick(instrument_id, tick)
        >>> strategy = MyStrategy(market_data=mock_port, ...)
        >>> strategy.start()
    """

    def __init__(self):
        self._ticks: Dict[InstrumentId, MarketTick] = {}
        self._bars: Dict[InstrumentId, Dict[BarGranularity, Bar]] = defaultdict(dict)
        self._history: Dict[InstrumentId, List[Bar]] = {}
        self._instrument_info: Dict[InstrumentId, InstrumentInfo] = {}

    def set_tick(self, instrument_id: InstrumentId, tick: MarketTick) -> None:
        """Inject tick for testing."""
        self._ticks[instrument_id] = tick

    def set_bar(self, instrument_id: InstrumentId, granularity: BarGranularity, bar: Bar) -> None:
        """Inject bar for testing."""
        self._bars[instrument_id][granularity] = bar

    def set_history(self, instrument_id: InstrumentId, bars: List[Bar]) -> None:
        """Inject historical bars for testing."""
        self._history[instrument_id] = bars

    def get_latest_tick(self, instrument_id: InstrumentId) -> Optional[MarketTick]:
        """Return injected tick or None."""
        return self._ticks.get(instrument_id)

    # ... implement remaining methods ...
```

---

### TASK-001-01-01-11
**Title**: Run mypy and fix type issues
**Effort**: 0.5 hours
**Description**: Validate type hints with mypy static type checker

**Checklist**:
- [ ] Run `mypy src/application/ports/market_data_port.py`
- [ ] Fix any type errors
- [ ] Ensure all methods have return type annotations
- [ ] Ensure all parameters have type annotations
- [ ] Run in strict mode (`mypy --strict`)

**Commands**:
```bash
mypy --strict src/application/ports/market_data_port.py
mypy tests/contracts/test_market_data_port_contract.py
mypy tests/mocks/mock_market_data_port.py
```

---

### TASK-001-01-01-12
**Title**: Code review and polish
**Effort**: 0.5 hours
**Description**: Final review and cleanup before PR

**Checklist**:
- [ ] Run black formatter
- [ ] Run pylint and fix issues
- [ ] Review all docstrings for clarity
- [ ] Verify imports are organized
- [ ] Create PR with description
- [ ] Request review from Lead Architect
- [ ] Address review comments
- [ ] Merge to main

---

## Dependencies

### Requires
- Domain model types (InstrumentId, MarketTick, Bar) - from FEAT-001-02
- pytest for testing
- mypy for type checking

### Blocks
- STORY-001-01-02 (ClockPort) - same pattern applies
- MockMarketDataPort needed for strategy testing

## Testing Checklist

- [ ] All contract tests pass
- [ ] MockMarketDataPort passes contract tests
- [ ] mypy passes with --strict
- [ ] pydocstyle passes (docstring linting)
- [ ] No pylint errors
- [ ] Code coverage >95% for mock implementation

## Definition of Done

- [ ] All 12 tasks completed
- [ ] Code reviewed and approved
- [ ] All tests passing
- [ ] Type checking passing
- [ ] Documentation generated
- [ ] Merged to main branch

---

**Next Story**: [STORY-001-01-02: Define ClockPort Interface](./STORY-001-01-02-ClockPort.md)
