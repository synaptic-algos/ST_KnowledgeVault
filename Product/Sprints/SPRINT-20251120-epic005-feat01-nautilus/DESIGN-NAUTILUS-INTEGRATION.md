---
1. **Preserve Port Abstraction**: Domain strategies remain framework-agnostic
2. **Zero Strategy Changes**: Existing strategies run on Nautilus without modification
3. **Consistent Interface**: NautilusBacktestAdapter returns same BacktestResults
  as custom engine
4. **Performance**: Nautilus performance should match or exceed custom engine
5. **Maintainability**: Clean separation between domain and Nautilus-specific code
artifact_type: story
created_at: '2025-11-25T16:23:21.826813Z'
id: AUTO-DESIGN-NAUTILUS-INTEGRATION
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for DESIGN-NAUTILUS-INTEGRATION
updated_at: '2025-11-25T16:23:21.826821Z'
---

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Domain Layer (Framework-Agnostic)         │
│  ┌────────────────┐      ┌──────────────────────────┐      │
│  │  Your Strategy │─────▶│ Port Interfaces          │      │
│  │                │      │ - ClockPort              │      │
│  │  on_tick()     │      │ - MarketDataPort         │      │
│  │  on_bar()      │      │ - ExecutionPort          │      │
│  └────────────────┘      └──────────────────────────┘      │
└────────────────────────────────┬────────────────────────────┘
                                 │
                                 │ Adapter Layer
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                        │                        │
        ▼                        ▼                        ▼
┌───────────────┐      ┌──────────────────┐    ┌──────────────────┐
│ Custom Engine │      │ Nautilus Trader  │    │ Backtrader       │
│               │      │                  │    │                  │
│ BacktestAda...│      │ NautilusBackt... │    │ BacktraderBac... │
└───────────────┘      └──────────────────┘    └──────────────────┘
     (DONE)                 (THIS SPRINT)           (NEXT SPRINT)
```

### Component Architecture

```
NautilusBacktestAdapter
├── NautilusStrategyWrapper ──────▶ Wraps domain strategy
│   ├── Domain Strategy
│   └── Nautilus Strategy (generated)
│
├── Port Adapters ────────────────▶ Implement port interfaces
│   ├── NautilusClockPort
│   ├── NautilusMarketDataPort
│   └── NautilusExecutionPort
│
├── EventTranslator ──────────────▶ Translate events
│   ├── Domain Events → Nautilus Events
│   └── Nautilus Events → Domain Events
│
├── ConfigMapper ─────────────────▶ Map configuration
│   └── BacktestConfig → BacktestEngineConfig
│
└── ResultsExtractor ─────────────▶ Extract results
    └── Nautilus Results → BacktestResults
```

---

## Component Specifications

### 1. NautilusStrategyWrapper

**Purpose**: Wrap domain strategy to work as Nautilus Strategy

**Interface**:
```python
class NautilusStrategyWrapper(nautilus_trader.trading.strategy.Strategy):
    """
    Wraps a domain strategy to work with Nautilus Trader.

    This class acts as an adapter between our domain strategy interface
    and Nautilus Strategy base class.
    """

    def __init__(self, domain_strategy: Any, config: StrategyConfig):
        """
        Args:
            domain_strategy: Domain strategy instance (has on_tick, on_bar methods)
            config: Nautilus strategy configuration
        """
        super().__init__(config=config)
        self._domain_strategy = domain_strategy
        self._port_adapters = None  # Injected later

    def on_start(self) -> None:
        """Called when strategy starts - maps to domain strategy.start()"""
        if hasattr(self._domain_strategy, 'start'):
            self._domain_strategy.start()

    def on_stop(self) -> None:
        """Called when strategy stops - maps to domain strategy.stop()"""
        if hasattr(self._domain_strategy, 'stop'):
            self._domain_strategy.stop()

    def on_trade_tick(self, tick: TradeTick) -> None:
        """
        Called for each trade tick - converts to domain MarketTick
        and calls domain strategy.on_tick()
        """
        domain_tick = EventTranslator.nautilus_tick_to_domain(tick)
        if hasattr(self._domain_strategy, 'on_tick'):
            self._domain_strategy.on_tick(domain_tick)

    def on_bar(self, bar: Bar) -> None:
        """
        Called for each bar - converts to domain MarketBar
        and calls domain strategy.on_bar()
        """
        domain_bar = EventTranslator.nautilus_bar_to_domain(bar)
        if hasattr(self._domain_strategy, 'on_bar'):
            self._domain_strategy.on_bar(domain_bar)
```

**Key Design Decisions**:
- Inheritance from Nautilus Strategy (required by Nautilus)
- Delegation pattern for event handling
- Port adapters injected after construction
- Lifecycle methods map directly

---

### 2. Port Adapters

#### 2.1 NautilusClockPort

**Purpose**: Implement ClockPort using Nautilus clock

**Interface**:
```python
class NautilusClockPort:
    """
    Implements ClockPort interface using Nautilus clock.

    Provides access to current backtest time from Nautilus engine.
    """

    def __init__(self, clock: nautilus_trader.common.Clock):
        self._clock = clock

    def now(self) -> datetime:
        """Return current backtest time from Nautilus clock"""
        # Convert Nautilus timestamp to Python datetime
        return self._clock.utc_now()

    def schedule(self, callback: Callable, when: datetime) -> str:
        """Schedule callback at specific time"""
        # Use Nautilus timer system
        timer_name = f"timer_{uuid.uuid4()}"
        self._clock.set_timer(
            name=timer_name,
            interval=timedelta(0),  # One-shot
            start_time=when,
            callback=callback
        )
        return timer_name
```

#### 2.2 NautilusMarketDataPort

**Purpose**: Implement MarketDataPort using Nautilus data access

**Interface**:
```python
class NautilusMarketDataPort:
    """
    Implements MarketDataPort interface using Nautilus data engine.

    Provides access to market data through Nautilus APIs.
    """

    def __init__(self, data_engine: nautilus_trader.data.DataEngine):
        self._data_engine = data_engine
        self._cache = {}  # Cache for latest ticks/bars

    def get_latest_tick(self, instrument_id: InstrumentId) -> Optional[MarketTick]:
        """Get latest tick for instrument"""
        nautilus_instrument_id = self._convert_instrument_id(instrument_id)
        nautilus_tick = self._data_engine.cache.quote_tick(nautilus_instrument_id)

        if nautilus_tick:
            return EventTranslator.nautilus_tick_to_domain(nautilus_tick)
        return None

    def get_bars(
        self,
        instrument_id: InstrumentId,
        start: datetime,
        end: datetime,
        interval: BarInterval
    ) -> List[MarketBar]:
        """Query historical bars"""
        # Use Nautilus data catalog to query bars
        nautilus_instrument_id = self._convert_instrument_id(instrument_id)
        nautilus_bars = self._data_engine.get_bars(
            instrument_id=nautilus_instrument_id,
            bar_type=self._convert_bar_interval(interval),
            start=start,
            end=end
        )

        return [EventTranslator.nautilus_bar_to_domain(b) for b in nautilus_bars]

    def subscribe_ticks(self, instrument_id: InstrumentId):
        """Subscribe to tick updates"""
        # Nautilus automatically delivers subscribed data
        nautilus_instrument_id = self._convert_instrument_id(instrument_id)
        self._data_engine.subscribe_quote_ticks(nautilus_instrument_id)
```

#### 2.3 NautilusExecutionPort

**Purpose**: Implement ExecutionPort using Nautilus execution engine

**Interface**:
```python
class NautilusExecutionPort:
    """
    Implements ExecutionPort interface using Nautilus execution engine.

    Handles order submission and fill notifications.
    """

    def __init__(
        self,
        exec_engine: nautilus_trader.execution.ExecutionEngine,
        strategy: Strategy
    ):
        self._exec_engine = exec_engine
        self._strategy = strategy  # Needed for order submission context

    def submit_order(
        self,
        instrument_id: InstrumentId,
        side: OrderSide,
        quantity: float,
        order_type: OrderType,
        limit_price: Optional[float] = None
    ) -> str:
        """Submit order to Nautilus execution engine"""

        # Convert to Nautilus order
        nautilus_instrument_id = self._convert_instrument_id(instrument_id)

        if order_type == OrderType.MARKET:
            order = self._strategy.order_factory.market(
                instrument_id=nautilus_instrument_id,
                order_side=self._convert_side(side),
                quantity=Quantity(quantity, precision=2)
            )
        elif order_type == OrderType.LIMIT:
            order = self._strategy.order_factory.limit(
                instrument_id=nautilus_instrument_id,
                order_side=self._convert_side(side),
                quantity=Quantity(quantity, precision=2),
                price=Price(limit_price, precision=2)
            )

        # Submit order through strategy (Nautilus requirement)
        self._strategy.submit_order(order)

        return str(order.client_order_id)

    def cancel_order(self, order_id: str):
        """Cancel pending order"""
        nautilus_order_id = ClientOrderId(order_id)
        self._strategy.cancel_order(order=self._exec_engine.cache.order(nautilus_order_id))
```

---

### 3. EventTranslator

**Purpose**: Translate events between domain and Nautilus formats

**Interface**:
```python
class EventTranslator:
    """
    Translates events between domain and Nautilus formats.

    Handles bidirectional conversion:
    - Domain → Nautilus (for sending data to Nautilus)
    - Nautilus → Domain (for delivering data to domain strategy)
    """

    @staticmethod
    def nautilus_tick_to_domain(nautilus_tick: TradeTick) -> MarketTick:
        """Convert Nautilus TradeTick to domain MarketTick"""
        return MarketTick(
            instrument_id=InstrumentId(str(nautilus_tick.instrument_id.symbol)),
            timestamp=nautilus_tick.ts_event.as_utc_datetime(),
            price=float(nautilus_tick.price),
            volume=float(nautilus_tick.size),
            bid=float(nautilus_tick.price),  # Approximation
            ask=float(nautilus_tick.price)   # Approximation
        )

    @staticmethod
    def nautilus_bar_to_domain(nautilus_bar: Bar) -> MarketBar:
        """Convert Nautilus Bar to domain MarketBar"""
        return MarketBar(
            instrument_id=InstrumentId(str(nautilus_bar.bar_type.instrument_id.symbol)),
            timestamp=nautilus_bar.ts_event.as_utc_datetime(),
            open=float(nautilus_bar.open),
            high=float(nautilus_bar.high),
            low=float(nautilus_bar.low),
            close=float(nautilus_bar.close),
            volume=float(nautilus_bar.volume)
        )

    @staticmethod
    def nautilus_fill_to_domain(nautilus_fill: OrderFilled) -> Fill:
        """Convert Nautilus OrderFilled event to domain Fill"""
        return Fill(
            order_id=str(nautilus_fill.client_order_id),
            instrument_id=InstrumentId(str(nautilus_fill.instrument_id.symbol)),
            side="BUY" if nautilus_fill.order_side == OrderSide.BUY else "SELL",
            quantity=Quantity(float(nautilus_fill.last_qty)),
            fill_price=Price(float(nautilus_fill.last_px)),
            timestamp=nautilus_fill.ts_event.as_utc_datetime(),
            commission=Money(float(nautilus_fill.commission.as_decimal()))
        )
```

---

### 4. ConfigMapper

**Purpose**: Map our BacktestConfig to Nautilus BacktestEngineConfig

**Interface**:
```python
class ConfigMapper:
    """
    Maps BacktestConfig to Nautilus BacktestEngineConfig.

    Handles configuration translation and defaults.
    """

    @staticmethod
    def map_backtest_config(config: BacktestConfig) -> BacktestEngineConfig:
        """Convert BacktestConfig to Nautilus configuration"""

        return BacktestEngineConfig(
            # Time range
            start=config.start_date,
            end=config.end_date,

            # Risk/execution
            bypass_logging=True,  # Performance optimization
            use_batch_fills=True,  # Realistic fill simulation

            # Slippage (convert BPS to decimal)
            fill_model=FixedFeeModel(
                commission=Decimal(config.commission_bps) / Decimal(10000),
                commission_min=Decimal(config.min_commission)
            )
        )

    @staticmethod
    def map_venue_config(config: BacktestConfig) -> BacktestVenueConfig:
        """Create venue configuration for backtest"""
        return BacktestVenueConfig(
            name="SIM",
            venue_type=VenueType.EXCHANGE,
            base_currency="USD",
            starting_balances=[Money(config.initial_capital, Currency.from_str("USD"))]
        )
```

---

### 5. NautilusBacktestAdapter

**Purpose**: Main adapter class implementing BacktestAdapter interface

**Interface**:
```python
class NautilusBacktestAdapter:
    """
    Implements BacktestAdapter interface using Nautilus Trader.

    This is the main entry point for running backtests on Nautilus.
    """

    def __init__(self, config: BacktestConfig, data_provider: Any):
        self.config = config
        self.data_provider = data_provider
        self._node = None  # BacktestNode (created in run())

    def run(self, strategy: Any) -> BacktestResults:
        """
        Execute backtest using Nautilus Trader.

        Args:
            strategy: Domain strategy instance

        Returns:
            BacktestResults matching our interface
        """
        # Step 1: Create Nautilus backtest node
        engine_config = ConfigMapper.map_backtest_config(self.config)
        venue_config = ConfigMapper.map_venue_config(self.config)

        self._node = BacktestNode(configs=[engine_config, venue_config])

        # Step 2: Load data into Nautilus
        self._load_data()

        # Step 3: Wrap domain strategy
        nautilus_config = StrategyConfig(strategy_id=StrategyId("STRATEGY-001"))
        wrapped_strategy = NautilusStrategyWrapper(
            domain_strategy=strategy,
            config=nautilus_config
        )

        # Step 4: Inject port adapters into domain strategy
        port_adapters = self._create_port_adapters(wrapped_strategy)
        strategy.clock = port_adapters['clock']
        strategy.market_data = port_adapters['market_data']
        strategy.execution = port_adapters['execution']

        # Step 5: Add strategy to node and run
        self._node.add_strategy(wrapped_strategy)
        self._node.run()

        # Step 6: Extract results and convert to BacktestResults
        return self._extract_results(strategy)

    def _load_data(self):
        """Load historical data from data_provider into Nautilus"""
        # Use Nautilus data catalog or direct loading
        # Implementation depends on data_provider interface
        pass

    def _create_port_adapters(self, wrapped_strategy) -> dict:
        """Create port adapter instances"""
        return {
            'clock': NautilusClockPort(self._node.clock),
            'market_data': NautilusMarketDataPort(self._node.data_engine),
            'execution': NautilusExecutionPort(self._node.exec_engine, wrapped_strategy)
        }

    def _extract_results(self, strategy) -> BacktestResults:
        """Extract results from Nautilus and convert to BacktestResults"""
        # Get final portfolio state from Nautilus
        nautilus_account = self._node.portfolio.account(VenueAccountId("SIM-001"))

        # Create our BacktestPortfolio representation
        final_value = float(nautilus_account.balance_total(Currency.from_str("USD")))

        # Calculate statistics
        statistics = {
            'total_trades': len(nautilus_account.trades()),
            'final_portfolio_value': final_value,
            'total_pnl': final_value - self.config.initial_capital,
            'realized_pnl': float(nautilus_account.realized_pnl),
            'unrealized_pnl': float(nautilus_account.unrealized_pnl),
            'initial_capital': self.config.initial_capital,
            'return_pct': ((final_value - self.config.initial_capital) / self.config.initial_capital) * 100
        }

        # Create BacktestResults matching our interface
        return BacktestResults(
            config=self.config,
            portfolio=self._convert_portfolio(nautilus_account),
            statistics=statistics
        )
```

---

## Data Flow Diagrams

### Backtest Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User calls: adapter.run(strategy)                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. NautilusBacktestAdapter                                  │
│    - Creates BacktestNode                                   │
│    - Loads data                                             │
│    - Wraps strategy                                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Nautilus runs backtest                                   │
│    - Replays historical data                                │
│    - Calls wrapped_strategy.on_trade_tick()                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. NautilusStrategyWrapper                                  │
│    - Converts Nautilus tick → domain tick                   │
│    - Calls domain_strategy.on_tick()                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Domain Strategy                                          │
│    - Processes tick                                         │
│    - Calls execution.submit_order()                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. NautilusExecutionPort                                    │
│    - Converts domain order → Nautilus order                 │
│    - Submits to Nautilus execution engine                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. Nautilus fills order                                     │
│    - Calls wrapped_strategy.on_order_filled()               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. Extract results                                          │
│    - Convert Nautilus results → BacktestResults             │
│    - Return to user                                         │
└─────────────────────────────────────────────────────────────┘
```

### Event Translation Flow

```
Nautilus Event         EventTranslator         Domain Event
─────────────────      ───────────────────     ────────────────
TradeTick       ─────▶ nautilus_tick_to    ─▶  MarketTick
                       _domain()                 - instrument_id
                                                 - timestamp
                                                 - price
                                                 - volume

Bar             ─────▶ nautilus_bar_to     ─▶  MarketBar
                       _domain()                 - open/high/low/close
                                                 - volume

OrderFilled     ─────▶ nautilus_fill_to    ─▶  Fill
                       _domain()                 - order_id
                                                 - fill_price
                                                 - commission
```

---

## Design Decisions & Rationale

### Decision 1: Wrapper vs Native Implementation

**Options Considered**:
A. Write domain strategies as Nautilus strategies from start
B. **Wrap domain strategies in Nautilus Strategy class** ✅

**Decision**: Option B (Wrapper)

**Rationale**:
- Preserves framework-agnostic design
- Existing strategies work without modification
- Clear separation of concerns
- Enables multi-framework support

### Decision 2: Port Adapter Injection

**Options Considered**:
A. Pass port adapters in strategy constructor
B. **Inject port adapters after wrapper creation** ✅

**Decision**: Option B (Post-creation injection)

**Rationale**:
- Wrapper needs to be fully constructed before ports exist
- Nautilus requires Strategy construction before engine creation
- Cleaner initialization order

### Decision 3: Event Translation Layer

**Options Considered**:
A. Direct conversion in each port adapter
B. **Centralized EventTranslator class** ✅

**Decision**: Option B (Centralized)

**Rationale**:
- Single source of truth for conversion logic
- Easier to test
- Reusable across components
- Consistent conversion behavior

### Decision 4: Results Extraction

**Options Considered**:
A. Return Nautilus results directly
B. **Convert to BacktestResults interface** ✅

**Decision**: Option B (Convert)

**Rationale**:
- Consistent interface across all engines
- User code doesn't need to know about Nautilus
- Easier to compare results across engines
- Enables engine swapping without code changes

---

## Performance Considerations

### Expected Performance

| Metric | Custom Engine | Nautilus | Notes |
|--------|--------------|----------|-------|
| Throughput | 100K ticks/sec | 80-120K ticks/sec | Nautilus optimized in Rust/Cython |
| Memory | 200MB | 300-400MB | Nautilus has more overhead |
| Startup | <1s | 2-3s | Nautilus initialization cost |

### Optimization Strategies

1. **Batch Data Loading**: Load all data upfront vs streaming
2. **Bypass Logging**: Disable Nautilus logging in backtest
3. **Use Batch Fills**: Enable batch fill processing
4. **Cache Conversions**: Cache translated objects where possible

---

## Error Handling

### Error Categories

1. **Configuration Errors**
   - Invalid date range
   - Missing data
   - Invalid instruments

2. **Runtime Errors**
   - Strategy exceptions
   - Order submission failures
   - Data quality issues

3. **Integration Errors**
   - Translation failures
   - Type mismatches
   - Missing Nautilus features

### Error Handling Strategy

```python
try:
    results = nautilus_adapter.run(strategy)
except NautilusConfigurationError as e:
    # Handle configuration issues
    logger.error(f"Invalid configuration: {e}")
    raise

except NautilusRuntimeError as e:
    # Handle runtime issues
    logger.error(f"Backtest failed: {e}")
    raise

except EventTranslationError as e:
    # Handle translation issues
    logger.error(f"Event translation failed: {e}")
    raise
```

---

## Testing Strategy

### Test Levels

1. **Unit Tests** (90%+ coverage)
   - EventTranslator conversions
   - ConfigMapper mapping
   - Port adapter methods

2. **Integration Tests**
   - StrategyWrapper with real strategy
   - Port adapters with Nautilus engine
   - End-to-end backtest flow

3. **Acceptance Tests**
   - SimpleBuyAndHoldStrategy runs
   - Results match custom engine (±0.01%)
   - Performance acceptable

### Test Data

- Mock Nautilus objects for unit tests
- Minimal real data for integration tests
- Full historical dataset for acceptance tests

---

## Deployment & Rollout

### Phase 1: Internal Testing (Week 1)
- Unit tests complete
- Integration tests passing
- Internal team validation

### Phase 2: Beta Testing (Week 2)
- SimpleBuyAndHoldStrategy validated
- Documentation complete
- External beta testers

### Phase 3: Production Release (Week 3)
- All tests passing
- Performance benchmarks met
- User/Admin manuals complete

---

## Open Questions

1. **Data Provider Interface**: How does data_provider work with Nautilus?
   - **Answer**: TBD - May need adapter for data provider

2. **Live Trading**: Will this design extend to live trading?
   - **Answer**: Yes - same pattern for paper and live

3. **Advanced Nautilus Features**: Do we support Nautilus-specific features?
   - **Answer**: No initially - start with common subset

---

## Appendix

### Nautilus API Reference

**Key Classes Used**:
- `BacktestNode`: Main backtest orchestrator
- `BacktestEngineConfig`: Backtest configuration
- `Strategy`: Base class for strategies
- `TradeTick`, `Bar`: Market data events
- `OrderFilled`: Fill events

**Documentation**: https://nautilustrader.io/docs/latest/

### Related Documents

- Sprint Plan: SPRINT_PLAN.md
- Test Specifications: TEST_SPECIFICATIONS.md (TBD)
- User Guide: NAUTILUS-USER-GUIDE.md (TBD)
- Admin Guide: NAUTILUS-ADMIN-GUIDE.md (TBD)

---

**Design Status**: 🟡 Draft
**Next Step**: Design review and approval
**After Approval**: Begin TDD implementation
