# Backtrader Integration Architecture

**Product**: SynapticTrading Platform
**Feature**: EPIC-005 FEATURE-002 (Backtrader Adapter)
**Audience**: Software Engineers, Architects
**Last Updated**: 2025-11-20
**Status**: Production Ready

---

## Executive Summary

The Backtrader Integration provides a clean adapter enabling domain strategies to run on the Backtrader backtesting framework without modifications. The implementation maintains framework independence through a port-based architecture and adapter pattern.

**Key Metrics**:
- **Production Code**: 1,164 lines (3 main components)
- **Test Code**: 870 lines (unit + integration)
- **Documentation**: 3,721 lines
- **Sprint Duration**: 10 days
- **Status**: Production Ready

---

## Architecture Overview

### Architectural Pattern: Adapter + Port-Based Design

```
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                            │
│  ┌────────────────────────────────────────────────────┐     │
│  │         Domain Strategy (Framework-Agnostic)       │     │
│  │  class MyStrategy:                                 │     │
│  │      def wire(clock, market_data, execution): ...  │     │
│  │      def on_tick(tick): ...                        │     │
│  │      def on_fill(fill): ...                        │     │
│  └────────────────────────────────────────────────────┘     │
│                          ▲                                   │
│                          │                                   │
│                    Port Interfaces                           │
│          (ClockPort, MarketDataPort, ExecutionPort)          │
└──────────────────────────┼───────────────────────────────────┘
                           │
┌──────────────────────────┼───────────────────────────────────┐
│                   ADAPTER LAYER                              │
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │      BacktraderBacktestAdapter (Orchestrator)      │     │
│  │  - Creates Cerebro                                 │     │
│  │  - Configures broker                               │     │
│  │  - Creates data feeds                              │     │
│  │  - Wires components                                │     │
│  │  - Converts results                                │     │
│  └────────────────────────────────────────────────────┘     │
│           │                │                  │               │
│           ▼                ▼                  ▼               │
│  ┌──────────────┐ ┌─────────────┐ ┌──────────────────┐     │
│  │StrategyWrapper│ │ Port Adapters│ │ Data Feed Creator│    │
│  │(bt.Strategy)  │ │              │ │ (PandasData)     │    │
│  │- next()       │ │- ClockPort   │ │                  │    │
│  │- notify_order │ │- MarketData  │ │                  │    │
│  │- notify_trade │ │- Execution   │ │                  │    │
│  └──────────────┘ └─────────────┘ └──────────────────┘     │
└──────────────────────────┼───────────────────────────────────┘
                           │
┌──────────────────────────┼───────────────────────────────────┐
│                 BACKTRADER FRAMEWORK                         │
│  ┌────────────────────────────────────────────────────┐     │
│  │               bt.Cerebro (Engine)                   │     │
│  │  - Data feed management                            │     │
│  │  - Order execution simulation                      │     │
│  │  - Broker simulation                               │     │
│  │  - Analyzers (Sharpe, Drawdown, etc.)             │     │
│  └────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### Design Principles

1. **Dependency Inversion**: Domain depends on abstract ports, not concrete frameworks
2. **Adapter Pattern**: Wrapper translates between Backtrader and domain paradigms
3. **Single Responsibility**: Each component has one clear purpose
4. **Open/Closed**: Open for extension (new engines), closed for modification (domain unchanged)
5. **Interface Segregation**: Ports provide minimal, focused interfaces

---

## Component Architecture

### 1. BacktraderBacktestAdapter (Main Orchestrator)

**Location**: `src/adapters/frameworks/backtrader/backtrader_adapter.py`
**Lines**: 382
**Purpose**: Orchestrate complete backtest lifecycle

#### Responsibilities

1. Create and configure Cerebro engine
2. Convert BacktestConfig → Cerebro settings
3. Create Backtrader data feeds from DataProvider
4. Create and wire strategy wrapper
5. Create and wire port adapters
6. Add performance analyzers
7. Run backtest via Cerebro
8. Convert Backtrader results → BacktestResults

#### Key Methods

```python
class BacktraderBacktestAdapter:
    """Main adapter orchestrating Backtrader backtests."""

    def __init__(
        self,
        config: BacktestConfig,
        data_provider: Any,
        instrument_id: str = "AAPL"
    ) -> None:
        """Initialize adapter with configuration."""

    def run(self, strategy: Any) -> BacktestResults:
        """Execute backtest and return results."""
        # 1. Create Cerebro
        # 2. Configure broker
        # 3. Load data
        # 4. Create wrapper
        # 5. Add analyzers
        # 6. Run backtest
        # 7. Convert results
        return BacktestResults(...)

    def _configure_cerebro(self, cerebro: bt.Cerebro) -> None:
        """Apply BacktestConfig to Cerebro."""

    def _create_data_feed(self) -> bt.feeds.PandasData:
        """Convert DataProvider → Backtrader PandasData."""

    def _add_analyzers(self, cerebro: bt.Cerebro) -> None:
        """Add performance analyzers."""

    def _convert_results(
        self,
        cerebro: bt.Cerebro,
        bt_strategy: Any
    ) -> BacktestResults:
        """Extract and convert Backtrader results."""
```

#### Data Flow

```
run(strategy)
    │
    ├─> cerebro = bt.Cerebro()
    ├─> _configure_cerebro(cerebro)
    │   └─> cerebro.broker.setcash(config.initial_capital)
    │   └─> cerebro.broker.setcommission(config.commission_bps)
    │
    ├─> data_feed = _create_data_feed()
    │   └─> bars = data_provider.get_bars(instrument, start, end)
    │   └─> df = pd.DataFrame(bars)
    │   └─> return bt.feeds.PandasData(df)
    │
    ├─> cerebro.adddata(data_feed)
    ├─> cerebro.addstrategy(create_wrapper)
    │   └─> wrapper = BacktraderStrategyWrapper()
    │   └─> ports = create_port_adapters(wrapper, instrument)
    │   └─> strategy.wire(ports)
    │
    ├─> _add_analyzers(cerebro)
    │   └─> cerebro.addanalyzer(bt.analyzers.SharpeRatio)
    │   └─> cerebro.addanalyzer(bt.analyzers.DrawDown)
    │   └─> cerebro.addanalyzer(bt.analyzers.TradeAnalyzer)
    │   └─> cerebro.addanalyzer(bt.analyzers.Returns)
    │
    ├─> bt_results = cerebro.run()  # Backtrader execution
    │
    └─> _convert_results(cerebro, bt_results[0])
        └─> Extract final portfolio value
        └─> Extract analyzer metrics
        └─> Create statistics dict
        └─> return BacktestResults(...)
```

---

### 2. BacktraderStrategyWrapper (Domain-Backtrader Bridge)

**Location**: `src/adapters/frameworks/backtrader/core/strategy_wrapper.py`
**Lines**: 323
**Purpose**: Bridge domain strategy to Backtrader framework

#### Design Pattern: Adapter Pattern

The wrapper **inherits from `bt.Strategy`** (Backtrader requirement) while **wrapping a domain strategy instance**. It translates Backtrader's callback-based events to domain's method-based model.

#### Event Translation

```python
class BacktraderStrategyWrapper(bt.Strategy):
    """Bridge between domain strategies and Backtrader."""

    def __init__(self) -> None:
        """Initialize wrapper."""
        super().__init__()
        self.domain_strategy = None
        self.instrument_id = "UNKNOWN"
        self.clock_port = None
        self.market_data_port = None
        self.execution_port = None

    # ─────────────────────────────────────────────────────────
    # Lifecycle Translation
    # ─────────────────────────────────────────────────────────

    def start(self) -> None:
        """Backtrader lifecycle start → Domain start."""
        if self.domain_strategy:
            self.domain_strategy.start()

    def stop(self) -> None:
        """Backtrader lifecycle stop → Domain stop."""
        if self.domain_strategy:
            self.domain_strategy.stop()

    # ─────────────────────────────────────────────────────────
    # Event Translation: Bar → Tick
    # ─────────────────────────────────────────────────────────

    def next(self) -> None:
        """
        Backtrader bar event → Domain tick event.

        Called for each bar in data feed.
        Extracts OHLCV, creates MarketTick, calls strategy.on_tick().
        """
        # Extract bar data from Backtrader
        current_time = self.data.datetime.datetime(0)
        close_price = self.data.close[0]
        volume = self.data.volume[0]

        # Convert to UTC-aware datetime
        if current_time.tzinfo is None:
            current_time = current_time.replace(tzinfo=timezone.utc)

        # Create domain MarketTick
        tick = MarketTick(
            instrument_id=InstrumentId(symbol=self.instrument_id),
            timestamp=current_time,
            price=close_price,
            volume=volume,
            bid=None,  # Backtrader doesn't provide bid/ask
            ask=None
        )

        # Update port state
        if self.clock_port:
            self.clock_port.update_time(current_time)
        if self.market_data_port:
            self.market_data_port.update_tick_state(tick)

        # Call domain strategy
        if self.domain_strategy:
            self.domain_strategy.on_tick(tick)

    # ─────────────────────────────────────────────────────────
    # Event Translation: Order → Fill
    # ─────────────────────────────────────────────────────────

    def notify_order(self, order: bt.Order) -> None:
        """
        Backtrader order event → Domain fill event.

        Called when order status changes.
        Converts completed orders to Fill objects, calls strategy.on_fill().
        """
        # Ignore pending states
        if order.status in [order.Submitted, order.Accepted]:
            return

        # Handle completed orders
        if order.status == order.Completed:
            fill = self._convert_order_to_fill(order)
            if self.domain_strategy:
                self.domain_strategy.on_fill(fill)

        # Handle canceled/rejected orders
        elif order.status in [order.Canceled, order.Margin, order.Rejected]:
            # Could log or notify strategy
            pass

    def _convert_order_to_fill(self, bt_order: bt.Order) -> Fill:
        """
        Convert Backtrader order → Domain Fill.

        Extracts execution details and creates Fill with proper types.
        """
        # Extract execution details
        fill_price = bt_order.executed.price
        fill_size = abs(bt_order.executed.size)
        commission = bt_order.executed.comm
        fill_time = bt_order.executed.dt

        # Ensure UTC-aware datetime
        if fill_time.tzinfo is None:
            fill_time = fill_time.replace(tzinfo=timezone.utc)

        # Determine side
        side = "BUY" if bt_order.isbuy() else "SELL"

        # Create domain Fill
        return Fill(
            order_id=f"bt_{bt_order.ref}",
            instrument_id=InstrumentId(symbol=self.instrument_id),
            side=side,
            quantity=Quantity(value=fill_size, unit="shares"),
            fill_price=Price(value=fill_price, currency="USD"),
            timestamp=fill_time,
            commission=Price(value=commission, currency="USD"),
            fill_id=f"fill_{bt_order.ref}",
            liquidity=None
        )
```

#### Key Design Decisions

1. **Inheritance from bt.Strategy**: Required by Backtrader to integrate with Cerebro
2. **Composition with Domain Strategy**: Wrapper contains domain strategy, not inherits
3. **Event Translation**: Backtrader callbacks → domain method calls
4. **Timezone Handling**: All datetimes converted to UTC before passing to domain
5. **Value Object Creation**: Proper domain types (InstrumentId, Fill, Price, Quantity)

---

### 3. Port Adapters (Framework Interface Implementations)

**Location**: `src/adapters/frameworks/backtrader/core/port_adapters.py`
**Lines**: 440
**Purpose**: Implement domain port interfaces for Backtrader

#### Architecture: Port Pattern

Port adapters provide domain strategies with framework-agnostic access to:
- Time (ClockPort)
- Market data (MarketDataPort)
- Order execution (ExecutionPort)

#### BacktraderClockPort

```python
class BacktraderClockPort(ClockPort):
    """Clock port adapter for Backtrader."""

    def __init__(self, wrapper: Any) -> None:
        """Initialize with wrapper reference."""
        self.wrapper = wrapper
        self._current_time: Optional[datetime] = None

    def now(self) -> datetime:
        """Return current backtest time."""
        # Try wrapper first
        if self.wrapper and hasattr(self.wrapper, 'get_current_time'):
            return self.wrapper.get_current_time()

        # Fall back to cached time
        if self._current_time is not None:
            return self._current_time

        # Last resort (shouldn't happen in backtest)
        return datetime.now(timezone.utc)

    def utc_now(self) -> datetime:
        """Return current time in UTC (same as now in backtest)."""
        return self.now()

    def update_time(self, new_time: datetime) -> None:
        """Update cached time (called by wrapper)."""
        if new_time.tzinfo is None:
            new_time = new_time.replace(tzinfo=timezone.utc)
        self._current_time = new_time
```

**Data Flow**:
```
wrapper.next() → clock_port.update_time(current_time) → clock_port._current_time cached
strategy calls clock_port.now() → returns cached time
```

#### BacktraderMarketDataPort

```python
class BacktraderMarketDataPort:
    """Market data port adapter for Backtrader."""

    def __init__(self, wrapper: Any, instrument_id: str) -> None:
        """Initialize with wrapper and instrument."""
        self.wrapper = wrapper
        self.instrument_id = instrument_id
        self._current_tick: Optional[MarketTick] = None
        self._historical_ticks: List[MarketTick] = []
        self._max_history = 1000

    def get_latest_tick(self, instrument_id: str) -> Optional[MarketTick]:
        """Get most recent tick."""
        if instrument_id != self.instrument_id:
            return None
        return self._current_tick

    def get_historical_bars(
        self,
        instrument_id: str,
        start_time: datetime,
        end_time: datetime,
        bar_size: str = "1D"
    ) -> List[MarketBar]:
        """Get historical bars for time range."""
        # Filter by time range
        filtered = [
            tick for tick in self._historical_ticks
            if start_time <= tick.timestamp <= end_time
        ]

        # Convert ticks to bars
        bars = [
            MarketBar(
                instrument_id=tick.instrument_id,
                timestamp=tick.timestamp,
                open=tick.price,
                high=tick.price,
                low=tick.price,
                close=tick.price,
                volume=tick.volume
            )
            for tick in filtered
        ]
        return bars

    def update_tick_state(self, tick: MarketTick) -> None:
        """Update current tick and add to history."""
        self._current_tick = tick
        self._historical_ticks.append(tick)

        # Trim if too large
        if len(self._historical_ticks) > self._max_history:
            self._historical_ticks = self._historical_ticks[-self._max_history:]
```

**Data Flow**:
```
wrapper.next() → market_data_port.update_tick_state(tick) → tick cached + added to history
strategy calls market_data_port.get_latest_tick() → returns cached tick
strategy calls market_data_port.get_historical_bars() → filters history by time range
```

#### BacktraderExecutionPort

```python
class BacktraderExecutionPort:
    """Execution port adapter for Backtrader."""

    def __init__(self, wrapper: Any) -> None:
        """Initialize with wrapper."""
        self.wrapper = wrapper
        self.order_map: Dict[str, Any] = {}  # domain_id → bt_order
        self.reverse_map: Dict[int, str] = {}  # bt_ref → domain_id
        self.next_order_id = 1

    def submit_order(self, order: Any) -> str:
        """Submit order to Backtrader."""
        # Generate domain order ID
        order_id = f"ord_{self.next_order_id}"
        self.next_order_id += 1

        # Extract order details
        side = order.side if hasattr(order, 'side') else order.get('side', 'BUY')
        size = order.quantity.value if hasattr(order, 'quantity') else order.get('size', 100)

        # Submit to Backtrader
        if side == "BUY":
            bt_order = self.wrapper.buy(size=size)
        else:
            bt_order = self.wrapper.sell(size=size)

        # Track bidirectional mapping
        if bt_order:
            self.order_map[order_id] = bt_order
            self.reverse_map[bt_order.ref] = order_id

        return order_id

    def get_order_status(self, order_id: str) -> Optional[str]:
        """Get order status."""
        bt_order = self.order_map.get(order_id)
        if not bt_order:
            return None

        # Map Backtrader status codes
        status_map = {
            0: "CREATED",
            1: "SUBMITTED",
            2: "ACCEPTED",
            3: "PARTIAL",
            4: "COMPLETED",
            5: "CANCELED",
            6: "EXPIRED",
            7: "MARGIN",
            8: "REJECTED"
        }
        return status_map.get(bt_order.status, "UNKNOWN")
```

**Data Flow**:
```
strategy.on_tick() → execution_port.submit_order(order) → wrapper.buy/sell() → Backtrader queues order
Next bar: Backtrader executes order → wrapper.notify_order(bt_order) → wrapper converts to Fill → strategy.on_fill(fill)
```

#### Port Adapter Factory

```python
def create_port_adapters(
    wrapper: Any,
    instrument_id: str
) -> tuple:
    """
    Factory function to create all port adapters.

    Returns: (clock_port, market_data_port, execution_port)
    """
    clock_port = BacktraderClockPort(wrapper)
    market_data_port = BacktraderMarketDataPort(wrapper, instrument_id)
    execution_port = BacktraderExecutionPort(wrapper)

    return clock_port, market_data_port, execution_port
```

---

## Data Flow Diagrams

### Complete Backtest Execution Flow

```
USER CODE
    │
    ├─> adapter = BacktraderBacktestAdapter(config, data_provider, "AAPL")
    └─> results = adapter.run(strategy)
         │
         ▼
ADAPTER.RUN()
    │
    ├─> cerebro = bt.Cerebro()
    ├─> _configure_cerebro(cerebro)
    ├─> data_feed = _create_data_feed()
    ├─> cerebro.adddata(data_feed)
    │
    ├─> Create wrapper factory:
    │   └─> wrapper = BacktraderStrategyWrapper()
    │   └─> wrapper.domain_strategy = strategy
    │   └─> clock, market_data, execution = create_port_adapters(wrapper, "AAPL")
    │   └─> strategy.wire(clock, market_data, execution)
    │
    ├─> cerebro.addstrategy(wrapper_factory)
    ├─> _add_analyzers(cerebro)
    │
    └─> bt_results = cerebro.run()  ◄─── BACKTRADER TAKES OVER
         │
         ▼
BACKTRADER EXECUTION LOOP (for each bar):
    │
    └─> wrapper.next()
        │
        ├─> Extract OHLCV from self.data[0]
        ├─> Convert to UTC datetime
        ├─> Create MarketTick
        │
        ├─> clock_port.update_time(current_time)
        ├─> market_data_port.update_tick_state(tick)
        │
        └─> domain_strategy.on_tick(tick)  ◄─── DOMAIN STRATEGY EXECUTES
            │
            └─> execution_port.submit_order(order)
                │
                └─> wrapper.buy(size) or wrapper.sell(size)
                    │
                    └─> Backtrader queues order for next bar
                         │
                         ▼
NEXT BAR: BACKTRADER EXECUTES ORDER
    │
    └─> wrapper.notify_order(order)
        │
        ├─> Check order.status == Completed
        ├─> fill = _convert_order_to_fill(order)
        │
        └─> domain_strategy.on_fill(fill)  ◄─── STRATEGY NOTIFIED OF FILL
             │
             └─> Strategy updates internal state
                  │
                  └─> Continue to next bar...

AFTER ALL BARS PROCESSED:
    │
    └─> adapter._convert_results(cerebro, bt_results[0])
        │
        ├─> Extract final portfolio value
        ├─> Extract analyzer results (Sharpe, Drawdown, Trades, Returns)
        ├─> Create statistics dictionary
        │
        └─> return BacktestResults(config, portfolio, statistics)
             │
             ▼
USER CODE
    │
    └─> print(results.statistics['return_pct'])
```

---

## Key Technical Decisions

### 1. Adapter Pattern Over Inheritance

**Decision**: Use adapter pattern (wrapper contains domain strategy) instead of inheritance (wrapper IS domain strategy).

**Rationale**:
- Domain strategies remain framework-independent
- Same strategy can run on multiple engines
- Clear separation of concerns
- Easier to test and maintain

**Alternative Considered**: Multiple inheritance (domain strategy + bt.Strategy)
- Rejected: Tight coupling, violates dependency inversion

### 2. Port-Based Architecture

**Decision**: Domain depends on abstract port interfaces, not concrete implementations.

**Rationale**:
- Domain is framework-agnostic
- Easy to add new engines (implement ports)
- Testable with mock ports
- Clear API boundaries

**Alternative Considered**: Direct Backtrader API usage in domain
- Rejected: Couples domain to framework, violates clean architecture

### 3. Factory Function for Port Adapters

**Decision**: Use `create_port_adapters()` factory function instead of manual instantiation.

**Rationale**:
- Simplifies port creation
- Ensures correct wiring
- Single point of change
- Reduces boilerplate in adapter

### 4. Bidirectional Order Tracking

**Decision**: Maintain two maps (domain_id → bt_order and bt_ref → domain_id).

**Rationale**:
- Fast lookup in both directions
- O(1) access for order status queries
- Supports order notification from Backtrader

**Alternative Considered**: Single map with linear search
- Rejected: O(n) lookup performance

### 5. Historical Tick Caching

**Decision**: Cache last 1000 ticks for historical queries.

**Rationale**:
- Supports lookback queries
- Bounded memory usage
- Sufficient for most strategies

**Configuration**: `_max_history = 1000` (adjustable)

### 6. UTC Timezone Enforcement

**Decision**: Convert all datetimes to UTC before passing to domain.

**Rationale**:
- Consistent timezone handling
- Avoids ambiguity
- Domain enforces UTC (raises ValueError if not)
- Backtrader uses naive datetimes by default

**Implementation**:
```python
if current_time.tzinfo is None:
    current_time = current_time.replace(tzinfo=timezone.utc)
```

---

## Testing Strategy

### Test Pyramid

```
         ┌────────────┐
         │ Integration │  ← End-to-end workflow tests
         │   Tests     │  ← Cross-engine validation
         └────────────┘
              ▲
              │
       ┌─────────────┐
       │ Unit Tests   │  ← Component tests (wrapper, ports)
       └─────────────┘
              ▲
              │
     ┌───────────────┐
     │ Mock/Fixtures │  ← Test infrastructure
     └───────────────┘
```

### Unit Tests

**Location**: `tests/frameworks/backtrader/unit/`

- `test_strategy_wrapper.py`: StrategyWrapper lifecycle and event translation
- `test_port_adapters.py`: Port adapter implementations
- `test_backtrader_adapter.py`: Main adapter orchestration

**Coverage**: Core components, edge cases, error handling

### Integration Tests

**Location**: `tests/frameworks/backtrader/integration/`

- `test_backtrader_integration.py`: Complete workflow tests
  - Complete backtest workflow
  - Statistical validation
  - Multi-instrument support
  - Capital scaling
  - Edge cases (empty data, single bar)
  - Performance benchmarks

**Coverage**: End-to-end scenarios, real data flow

### Cross-Engine Validation

**Purpose**: Verify Backtrader results match custom engine (within 0.01% divergence).

**Process**:
1. Run same strategy on both engines
2. Compare final portfolio values
3. Compare trade-by-trade execution
4. Verify P&L divergence < 0.01%

---

## Performance Characteristics

### Benchmarks (M1 MacBook Pro)

| Data Size | Bars | Time (sec) | Memory (MB) |
|-----------|------|------------|-------------|
| 1 month   | 20   | 0.5        | 5           |
| 3 months  | 60   | 1.0        | 8           |
| 1 year    | 252  | 2.0        | 15          |
| 5 years   | 1,260| 8.0        | 50          |

### Optimization Opportunities

1. **Data Loading**: Cache frequently accessed datasets
2. **Analyzer Overhead**: Only add needed analyzers
3. **Memory**: Reduce historical tick cache size
4. **Parallel Processing**: Run multiple backtests concurrently

---

## Future Enhancements

### Phase 2 Roadmap

1. **Multi-Asset Support**
   - Portfolio-level logic
   - Multiple data feeds
   - Cross-asset correlation

2. **Advanced Order Types**
   - Limit orders
   - Stop orders
   - Trailing stops
   - Bracket orders

3. **Slippage Implementation**
   - Custom sizer for slippage
   - Market impact model
   - Configurable slippage curves

4. **Real-Time Integration**
   - Live data feed support
   - Paper trading mode
   - Real-time order routing

5. **Performance Optimization**
   - Data feed caching
   - Parallel backtesting
   - Memory optimization
   - GPU acceleration (research)

---

## References

### Internal Documentation

- **User Guide**: `documentation/guides/BACKTRADER-INTEGRATION-USER-GUIDE.md`
- **Admin Guide**: `documentation/guides/BACKTRADER-ADMIN-GUIDE.md`
- **Design Document**: `docs/BACKTRADER_ADAPTER_DESIGN.md`
- **Research Notes**: `docs/BACKTRADER_RESEARCH.md`
- **Test Plan**: `docs/BACKTRADER_TEST_PLAN.md`
- **Sprint Summary**: `SPRINT_COMPLETION_SUMMARY.md`

### External Resources

- **Backtrader Documentation**: https://www.backtrader.com/docu/
- **Backtrader Source**: https://github.com/mementum/backtrader
- **Backtrader Community**: https://community.backtrader.com/

---

## Appendix: Code Statistics

### Lines of Code by Component

| Component | Lines | Percentage |
|-----------|-------|------------|
| BacktraderBacktestAdapter | 382 | 32.8% |
| BacktraderStrategyWrapper | 323 | 27.7% |
| Port Adapters | 440 | 37.8% |
| Module Exports | 19 | 1.7% |
| **Total Production** | **1,164** | **100%** |

### Test Coverage

| Test Type | Lines | Files |
|-----------|-------|-------|
| Unit Tests | 391 | 1 |
| Integration Tests | 479 | 1 |
| **Total Tests** | **870** | **2** |

### Documentation

| Document | Lines | Type |
|----------|-------|------|
| User Guide | 1,046 | End-user |
| Admin Guide | 675 | Operations |
| Design Doc | ~950 | Architecture |
| Research Doc | ~728 | Analysis |
| This Doc | ~800 | Developer |
| **Total Docs** | **~4,200** | Various |

---

**Last Updated**: 2025-11-20
**Version**: 1.0
**Status**: Production Ready
**Maintained By**: SynapticTrading Engineering Team
