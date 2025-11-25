# Test Specifications: Nautilus Integration

**Sprint**: SPRINT-20251120-epic005-feat01-nautilus
**Feature**: FEAT-005-01 (Nautilus Integration Core)
**Created**: 2025-11-20
**Approach**: Test-Driven Development (TDD)

---

## Overview

This document defines **test specifications before implementation** following TDD principles. All tests must be written BEFORE the corresponding implementation code.

### TDD Process

For each component:
1. **RED**: Write failing test (specification)
2. **GREEN**: Write minimal code to pass test
3. **REFACTOR**: Improve code quality
4. **REPEAT**: Next test

### Test Coverage Goals

- **Unit Tests**: 90%+ coverage
- **Integration Tests**: All critical paths
- **Acceptance Tests**: All user stories
- **Edge Cases**: All boundary conditions

---

## 1. NautilusStrategyWrapper Tests

**File**: `tests/adapters/frameworks/nautilus/core/test_strategy_wrapper.py`

### 1.1 Wrapper Construction Tests

#### TEST-SW-001: Constructor wraps domain strategy
```python
def test_wrapper_constructor_stores_domain_strategy():
    """
    GIVEN: A domain strategy instance
    WHEN: NautilusStrategyWrapper is constructed with the strategy
    THEN: The wrapper stores reference to domain strategy
    AND: Wrapper inherits from nautilus_trader.trading.strategy.Strategy
    """
```

#### TEST-SW-002: Constructor accepts StrategyConfig
```python
def test_wrapper_constructor_accepts_config():
    """
    GIVEN: A valid Nautilus StrategyConfig
    WHEN: NautilusStrategyWrapper is constructed with config
    THEN: Wrapper initializes with config
    AND: Config is accessible via wrapper.config
    """
```

#### TEST-SW-003: Constructor validates domain strategy has required methods
```python
def test_wrapper_constructor_validates_strategy_methods():
    """
    GIVEN: A strategy missing required methods (e.g., no start() method)
    WHEN: NautilusStrategyWrapper is constructed
    THEN: Constructor raises ValueError with clear message
    """
```

### 1.2 Lifecycle Mapping Tests

#### TEST-SW-004: on_start() maps to domain strategy.start()
```python
def test_on_start_calls_domain_strategy_start():
    """
    GIVEN: A wrapped domain strategy with start() method
    WHEN: Wrapper.on_start() is called
    THEN: Domain strategy.start() is called exactly once
    AND: No exceptions are raised
    """
```

#### TEST-SW-005: on_stop() maps to domain strategy.stop()
```python
def test_on_stop_calls_domain_strategy_stop():
    """
    GIVEN: A wrapped domain strategy with stop() method
    WHEN: Wrapper.on_stop() is called
    THEN: Domain strategy.stop() is called exactly once
    AND: Strategy state is cleaned up
    """
```

#### TEST-SW-006: on_reset() maps to domain strategy.reset()
```python
def test_on_reset_calls_domain_strategy_reset():
    """
    GIVEN: A wrapped domain strategy with reset() method
    WHEN: Wrapper.on_reset() is called
    THEN: Domain strategy.reset() is called
    AND: Strategy returns to initial state
    """
```

#### TEST-SW-007: Handles missing optional lifecycle methods gracefully
```python
def test_missing_optional_methods_do_not_raise():
    """
    GIVEN: A domain strategy without optional methods (reset, stop)
    WHEN: Wrapper lifecycle methods are called
    THEN: No exceptions are raised
    AND: Wrapper continues functioning
    """
```

### 1.3 Event Handler Mapping Tests

#### TEST-SW-008: on_trade_tick() converts and calls domain on_tick()
```python
def test_on_trade_tick_converts_and_calls_on_tick():
    """
    GIVEN: A wrapped domain strategy with on_tick() method
    AND: A Nautilus TradeTick event
    WHEN: Wrapper.on_trade_tick(tick) is called
    THEN: EventTranslator.nautilus_tick_to_domain() is called
    AND: Domain strategy.on_tick(domain_tick) is called
    AND: Tick data matches (price, volume, timestamp)
    """
```

#### TEST-SW-009: on_bar() converts and calls domain on_bar()
```python
def test_on_bar_converts_and_calls_domain_on_bar():
    """
    GIVEN: A wrapped domain strategy with on_bar() method
    AND: A Nautilus Bar event
    WHEN: Wrapper.on_bar(bar) is called
    THEN: EventTranslator.nautilus_bar_to_domain() is called
    AND: Domain strategy.on_bar(domain_bar) is called
    AND: Bar OHLCV data matches
    """
```

#### TEST-SW-010: on_order_event() converts and calls domain handler
```python
def test_on_order_event_converts_and_propagates():
    """
    GIVEN: A wrapped domain strategy with on_order_filled() method
    AND: A Nautilus OrderFilled event
    WHEN: Wrapper.on_order_event(event) is called
    THEN: EventTranslator.nautilus_order_to_domain() is called
    AND: Domain strategy.on_order_filled(domain_fill) is called
    AND: Fill details match (price, quantity, fees)
    """
```

#### TEST-SW-011: Handles events for strategies without handlers
```python
def test_unhandled_events_do_not_raise():
    """
    GIVEN: A domain strategy without on_bar() method
    AND: A Nautilus Bar event
    WHEN: Wrapper.on_bar(bar) is called
    THEN: No exception is raised
    AND: Event is silently ignored
    """
```

### 1.4 Error Handling Tests

#### TEST-SW-012: Domain strategy exception propagates clearly
```python
def test_domain_strategy_exception_propagates_with_context():
    """
    GIVEN: A domain strategy.on_tick() that raises ValueError
    WHEN: Wrapper.on_trade_tick() is called
    THEN: ValueError propagates to Nautilus
    AND: Exception message includes "Domain strategy error"
    AND: Original traceback is preserved
    """
```

#### TEST-SW-013: EventTranslator exception is caught and logged
```python
def test_event_translation_failure_is_logged():
    """
    GIVEN: EventTranslator that raises TranslationError
    WHEN: Wrapper.on_trade_tick() is called
    THEN: Exception is caught
    AND: Error is logged with context
    AND: Strategy continues running (doesn't crash)
    """
```

---

## 2. Port Adapter Tests

**File**: `tests/adapters/frameworks/nautilus/core/test_port_adapters.py`

### 2.1 NautilusClockPort Tests

#### TEST-CP-001: ClockPort implements ClockPort interface
```python
def test_clock_port_implements_interface():
    """
    GIVEN: NautilusClockPort instance
    WHEN: Interface compliance is checked
    THEN: Implements ClockPort protocol
    AND: Has now() method
    """
```

#### TEST-CP-002: now() returns Nautilus clock time
```python
def test_now_returns_nautilus_clock_time():
    """
    GIVEN: Nautilus Clock set to specific timestamp
    AND: NautilusClockPort wrapping the clock
    WHEN: clock_port.now() is called
    THEN: Returns datetime matching Nautilus clock.utc_now()
    AND: Timezone is UTC
    """
```

#### TEST-CP-003: Time advances correctly in backtest mode
```python
def test_clock_advances_in_backtest_mode():
    """
    GIVEN: Nautilus TestClock (backtest mode)
    AND: NautilusClockPort wrapping test clock
    WHEN: Backtest advances time by 1 hour
    THEN: clock_port.now() reflects the new time
    AND: Time delta is exactly 1 hour
    """
```

#### TEST-CP-004: now() returns timezone-aware datetime
```python
def test_now_returns_timezone_aware():
    """
    GIVEN: NautilusClockPort instance
    WHEN: clock_port.now() is called
    THEN: Returned datetime has tzinfo set
    AND: Timezone is UTC
    """
```

### 2.2 NautilusMarketDataPort Tests

#### TEST-MDP-001: MarketDataPort implements MarketDataPort interface
```python
def test_market_data_port_implements_interface():
    """
    GIVEN: NautilusMarketDataPort instance
    WHEN: Interface compliance is checked
    THEN: Implements MarketDataPort protocol
    AND: Has get_latest_tick(), get_bars() methods
    """
```

#### TEST-MDP-002: get_latest_tick() returns converted tick
```python
def test_get_latest_tick_returns_domain_tick():
    """
    GIVEN: Nautilus cache with TradeTick for AAPL
    AND: NautilusMarketDataPort wrapping data engine
    WHEN: get_latest_tick(InstrumentId("AAPL")) is called
    THEN: Returns MarketTick instance (domain type)
    AND: Tick data matches Nautilus tick (price, volume, timestamp)
    """
```

#### TEST-MDP-003: get_latest_tick() returns None if no data
```python
def test_get_latest_tick_returns_none_when_no_data():
    """
    GIVEN: Nautilus cache with no data for TSLA
    WHEN: get_latest_tick(InstrumentId("TSLA")) is called
    THEN: Returns None
    AND: No exception is raised
    """
```

#### TEST-MDP-004: get_bars() queries Nautilus data and converts
```python
def test_get_bars_queries_nautilus_data():
    """
    GIVEN: Nautilus data engine with 100 bars for AAPL
    AND: NautilusMarketDataPort wrapping data engine
    WHEN: get_bars(InstrumentId("AAPL"), start, end) is called
    THEN: Returns List[MarketBar] (domain type)
    AND: Bar count matches Nautilus query result
    AND: Each bar OHLCV matches Nautilus bar
    """
```

#### TEST-MDP-005: get_bars() handles empty result gracefully
```python
def test_get_bars_returns_empty_list_when_no_data():
    """
    GIVEN: Nautilus data engine with no bars for date range
    WHEN: get_bars(InstrumentId("AAPL"), start, end) is called
    THEN: Returns empty list []
    AND: No exception is raised
    """
```

#### TEST-MDP-006: Invalid instrument ID raises clear error
```python
def test_invalid_instrument_id_raises_value_error():
    """
    GIVEN: NautilusMarketDataPort instance
    WHEN: get_latest_tick(InstrumentId("INVALID")) is called
    THEN: Raises ValueError with message "Unknown instrument"
    """
```

### 2.3 NautilusExecutionPort Tests

#### TEST-EP-001: ExecutionPort implements ExecutionPort interface
```python
def test_execution_port_implements_interface():
    """
    GIVEN: NautilusExecutionPort instance
    WHEN: Interface compliance is checked
    THEN: Implements ExecutionPort protocol
    AND: Has submit_order(), cancel_order() methods
    """
```

#### TEST-EP-002: submit_order() creates Nautilus market order
```python
def test_submit_order_creates_nautilus_market_order():
    """
    GIVEN: NautilusExecutionPort wrapping strategy
    WHEN: submit_order(InstrumentId("AAPL"), Side.BUY, 100, OrderType.MARKET)
    THEN: Nautilus strategy.order_factory.market() is called
    AND: Order submitted via strategy.submit_order()
    AND: Returns order ID as string
    """
```

#### TEST-EP-003: submit_order() creates Nautilus limit order
```python
def test_submit_order_creates_nautilus_limit_order():
    """
    GIVEN: NautilusExecutionPort wrapping strategy
    WHEN: submit_order(instrument, Side.BUY, 100, OrderType.LIMIT, limit_price=150.0)
    THEN: Nautilus strategy.order_factory.limit() is called
    AND: Limit price matches 150.0
    AND: Order submitted successfully
    """
```

#### TEST-EP-004: submit_order() creates Nautilus stop order
```python
def test_submit_order_creates_nautilus_stop_order():
    """
    GIVEN: NautilusExecutionPort wrapping strategy
    WHEN: submit_order(instrument, Side.SELL, 50, OrderType.STOP, stop_price=140.0)
    THEN: Nautilus strategy.order_factory.stop_market() is called
    AND: Stop price matches 140.0
    AND: Order submitted successfully
    """
```

#### TEST-EP-005: cancel_order() cancels Nautilus order by ID
```python
def test_cancel_order_cancels_by_id():
    """
    GIVEN: Submitted Nautilus order with client_order_id
    AND: NautilusExecutionPort wrapping strategy
    WHEN: cancel_order(order_id) is called
    THEN: Nautilus strategy.cancel_order() is called with correct order
    AND: Order status changes to CANCELED
    """
```

#### TEST-EP-006: Order fill propagates to domain strategy
```python
def test_order_fill_propagates_to_domain():
    """
    GIVEN: Domain strategy with on_order_filled() handler
    AND: Submitted market order
    WHEN: Nautilus fills the order
    THEN: Domain strategy.on_order_filled() is called
    AND: Fill details match (price, quantity, commission)
    """
```

#### TEST-EP-007: Invalid order type raises ValueError
```python
def test_invalid_order_type_raises_error():
    """
    GIVEN: NautilusExecutionPort instance
    WHEN: submit_order() called with unsupported order type
    THEN: Raises ValueError with message "Unsupported order type"
    """
```

---

## 3. EventTranslator Tests

**File**: `tests/adapters/frameworks/nautilus/core/test_event_translator.py`

### 3.1 Tick Translation Tests

#### TEST-ET-001: Nautilus TradeTick converts to domain MarketTick
```python
def test_nautilus_tick_to_domain():
    """
    GIVEN: Nautilus TradeTick with known values
        - instrument_id: AAPL.NASDAQ
        - price: 150.50
        - size: 100
        - ts_event: 2025-11-20T10:30:00Z
    WHEN: EventTranslator.nautilus_tick_to_domain(tick) is called
    THEN: Returns MarketTick instance
    AND: instrument_id == "AAPL"
    AND: price == 150.50
    AND: volume == 100
    AND: timestamp == 2025-11-20T10:30:00Z
    """
```

#### TEST-ET-002: Domain MarketTick converts to Nautilus TradeTick
```python
def test_domain_tick_to_nautilus():
    """
    GIVEN: Domain MarketTick with known values
    WHEN: EventTranslator.domain_tick_to_nautilus(tick) is called
    THEN: Returns Nautilus TradeTick instance
    AND: All fields match original domain tick
    """
```

#### TEST-ET-003: Tick translation is bidirectional
```python
def test_tick_translation_bidirectional():
    """
    GIVEN: Original Nautilus TradeTick
    WHEN: Convert to domain and back to Nautilus
    THEN: Resulting tick matches original (within precision)
    """
```

#### TEST-ET-004: Handles missing bid/ask in Nautilus tick
```python
def test_missing_bid_ask_uses_price():
    """
    GIVEN: Nautilus TradeTick without bid/ask quotes
    WHEN: EventTranslator.nautilus_tick_to_domain() is called
    THEN: Domain tick uses price for both bid and ask
    AND: No exception is raised
    """
```

### 3.2 Bar Translation Tests

#### TEST-ET-005: Nautilus Bar converts to domain MarketBar
```python
def test_nautilus_bar_to_domain():
    """
    GIVEN: Nautilus Bar with known OHLCV values
        - open: 150.0
        - high: 152.0
        - low: 149.5
        - close: 151.0
        - volume: 10000
    WHEN: EventTranslator.nautilus_bar_to_domain(bar) is called
    THEN: Returns MarketBar instance
    AND: All OHLCV values match
    AND: Timestamp matches bar.ts_event
    """
```

#### TEST-ET-006: Domain MarketBar converts to Nautilus Bar
```python
def test_domain_bar_to_nautilus():
    """
    GIVEN: Domain MarketBar with known values
    WHEN: EventTranslator.domain_bar_to_nautilus(bar) is called
    THEN: Returns Nautilus Bar instance
    AND: All fields match original domain bar
    """
```

#### TEST-ET-007: Bar translation is bidirectional
```python
def test_bar_translation_bidirectional():
    """
    GIVEN: Original Nautilus Bar
    WHEN: Convert to domain and back to Nautilus
    THEN: Resulting bar matches original (within precision)
    """
```

### 3.3 Order/Fill Translation Tests

#### TEST-ET-008: Nautilus OrderFilled converts to domain Fill
```python
def test_nautilus_order_filled_to_domain():
    """
    GIVEN: Nautilus OrderFilled event with known values
        - order_id: "O-123"
        - fill_price: 150.25
        - fill_qty: 100
        - commission: 1.50
    WHEN: EventTranslator.nautilus_order_to_domain(event) is called
    THEN: Returns Fill instance
    AND: All fields match
    AND: Commission is properly converted
    """
```

#### TEST-ET-009: Domain Fill converts to Nautilus OrderFilled
```python
def test_domain_fill_to_nautilus():
    """
    GIVEN: Domain Fill with known values
    WHEN: EventTranslator.domain_fill_to_nautilus(fill) is called
    THEN: Returns Nautilus OrderFilled event
    AND: All fields match original fill
    """
```

#### TEST-ET-010: Handles partial fills correctly
```python
def test_partial_fill_translation():
    """
    GIVEN: Nautilus OrderFilled with partial fill (50 of 100)
    WHEN: EventTranslator.nautilus_order_to_domain() is called
    THEN: Domain Fill correctly reflects partial quantity
    AND: Remaining quantity is tracked
    """
```

### 3.4 Edge Cases and Error Handling

#### TEST-ET-011: Handles None/null values gracefully
```python
def test_translation_handles_none_values():
    """
    GIVEN: Nautilus event with optional fields set to None
    WHEN: EventTranslator methods are called
    THEN: Translation completes successfully
    AND: None values are handled appropriately
    """
```

#### TEST-ET-012: Invalid event type raises TranslationError
```python
def test_invalid_event_raises_translation_error():
    """
    GIVEN: Unknown event type (not TradeTick, Bar, OrderFilled)
    WHEN: EventTranslator.translate() is called
    THEN: Raises TranslationError with clear message
    """
```

#### TEST-ET-013: Preserves precision in numeric conversions
```python
def test_numeric_precision_preserved():
    """
    GIVEN: Nautilus Price with high precision (150.123456789)
    WHEN: Convert to domain and back
    THEN: Precision is preserved (within float64 limits)
    """
```

---

## 4. ConfigMapper Tests

**File**: `tests/adapters/frameworks/nautilus/core/test_config_mapper.py`

### 4.1 Basic Configuration Mapping

#### TEST-CM-001: BacktestConfig maps to BacktestEngineConfig
```python
def test_backtest_config_to_nautilus():
    """
    GIVEN: Domain BacktestConfig with known values
        - start_date: 2023-01-01
        - end_date: 2023-12-31
        - initial_capital: 100000
    WHEN: ConfigMapper.to_nautilus_config(config) is called
    THEN: Returns BacktestEngineConfig
    AND: Date range matches
    AND: Initial capital matches
    """
```

#### TEST-CM-002: Handles default values correctly
```python
def test_config_mapping_uses_defaults():
    """
    GIVEN: BacktestConfig with minimal fields set
    WHEN: ConfigMapper.to_nautilus_config() is called
    THEN: Nautilus config has sensible defaults
    AND: No required fields are missing
    """
```

### 4.2 Slippage Model Mapping

#### TEST-CM-003: Fixed slippage model maps correctly
```python
def test_fixed_slippage_model_mapping():
    """
    GIVEN: BacktestConfig with fixed slippage (0.05%)
    WHEN: ConfigMapper.to_nautilus_config() is called
    THEN: Nautilus config uses FixedSlippageModel
    AND: Slippage percentage matches 0.05%
    """
```

#### TEST-CM-004: Volume-based slippage model maps correctly
```python
def test_volume_based_slippage_mapping():
    """
    GIVEN: BacktestConfig with volume-based slippage
    WHEN: ConfigMapper.to_nautilus_config() is called
    THEN: Nautilus config uses appropriate slippage model
    AND: Volume impact parameters are correct
    """
```

#### TEST-CM-005: Zero slippage disables slippage model
```python
def test_zero_slippage_disables_model():
    """
    GIVEN: BacktestConfig with slippage = 0
    WHEN: ConfigMapper.to_nautilus_config() is called
    THEN: Nautilus config has no slippage model
    """
```

### 4.3 Commission Model Mapping

#### TEST-CM-006: Fixed commission model maps correctly
```python
def test_fixed_commission_mapping():
    """
    GIVEN: BacktestConfig with fixed commission (1.0 per trade)
    WHEN: ConfigMapper.to_nautilus_config() is called
    THEN: Nautilus config uses FixedCommissionModel
    AND: Commission amount matches 1.0
    """
```

#### TEST-CM-007: Percentage commission model maps correctly
```python
def test_percentage_commission_mapping():
    """
    GIVEN: BacktestConfig with percentage commission (0.1%)
    WHEN: ConfigMapper.to_nautilus_config() is called
    THEN: Nautilus config uses PercentageCommissionModel
    AND: Percentage matches 0.1%
    """
```

#### TEST-CM-008: Zero commission disables commission model
```python
def test_zero_commission_disables_model():
    """
    GIVEN: BacktestConfig with commission = 0
    WHEN: ConfigMapper.to_nautilus_config() is called
    THEN: Nautilus config has no commission model
    """
```

### 4.4 Advanced Configuration

#### TEST-CM-009: Risk settings map correctly
```python
def test_risk_settings_mapping():
    """
    GIVEN: BacktestConfig with risk parameters
        - max_position_size: 1000
        - max_portfolio_exposure: 0.5
    WHEN: ConfigMapper.to_nautilus_config() is called
    THEN: Nautilus config reflects risk parameters
    """
```

#### TEST-CM-010: Data resolution maps to Nautilus BarAggregation
```python
def test_data_resolution_mapping():
    """
    GIVEN: BacktestConfig with bar_resolution = "1-MINUTE"
    WHEN: ConfigMapper.to_nautilus_config() is called
    THEN: Nautilus config uses BAR_AGGREGATION_1_MINUTE
    """
```

---

## 5. NautilusBacktestAdapter Tests

**File**: `tests/adapters/frameworks/nautilus/backtest/test_nautilus_backtest_adapter.py`

### 5.1 Adapter Initialization

#### TEST-NBA-001: Adapter initializes with BacktestConfig
```python
def test_adapter_initialization():
    """
    GIVEN: Valid BacktestConfig and HistoricalDataProvider
    WHEN: NautilusBacktestAdapter is constructed
    THEN: Adapter stores config and data provider
    AND: BacktestNode is not yet created
    """
```

#### TEST-NBA-002: Adapter validates config on initialization
```python
def test_adapter_validates_config():
    """
    GIVEN: Invalid BacktestConfig (end_date before start_date)
    WHEN: NautilusBacktestAdapter is constructed
    THEN: Raises ValueError with clear message
    """
```

### 5.2 Backtest Execution

#### TEST-NBA-003: run() initializes Nautilus BacktestNode
```python
def test_run_initializes_backtest_node():
    """
    GIVEN: NautilusBacktestAdapter with valid config
    WHEN: adapter.run(strategy) is called
    THEN: BacktestNode is created
    AND: Node is configured with engine config
    """
```

#### TEST-NBA-004: run() wraps domain strategy
```python
def test_run_wraps_domain_strategy():
    """
    GIVEN: Domain strategy (SimpleBuyAndHoldStrategy)
    WHEN: adapter.run(strategy) is called
    THEN: Strategy is wrapped in NautilusStrategyWrapper
    AND: Wrapped strategy is added to BacktestNode
    """
```

#### TEST-NBA-005: run() injects port adapters
```python
def test_run_injects_port_adapters():
    """
    GIVEN: Domain strategy with port dependencies
    WHEN: adapter.run(strategy) is called
    THEN: strategy.clock is NautilusClockPort
    AND: strategy.market_data is NautilusMarketDataPort
    AND: strategy.execution is NautilusExecutionPort
    """
```

#### TEST-NBA-006: run() executes backtest to completion
```python
def test_run_executes_backtest():
    """
    GIVEN: Configured adapter with SimpleBuyAndHoldStrategy
    WHEN: adapter.run(strategy) is called
    THEN: BacktestNode.run() completes successfully
    AND: Strategy received events (ticks/bars)
    AND: No exceptions raised
    """
```

#### TEST-NBA-007: run() returns BacktestResults
```python
def test_run_returns_backtest_results():
    """
    GIVEN: Completed backtest run
    WHEN: results = adapter.run(strategy)
    THEN: Returns BacktestResults instance
    AND: Contains equity_curve
    AND: Contains performance_metrics
    AND: Contains trade_history
    """
```

### 5.3 Results Extraction

#### TEST-NBA-008: Results contain correct equity curve
```python
def test_results_equity_curve():
    """
    GIVEN: Completed backtest with trades
    WHEN: results = adapter.run(strategy)
    THEN: results.equity_curve is List[EquityPoint]
    AND: Curve starts at initial_capital
    AND: Curve ends at final portfolio value
    AND: Each point has timestamp and equity
    """
```

#### TEST-NBA-009: Results contain trade history
```python
def test_results_trade_history():
    """
    GIVEN: Strategy that executed 10 trades
    WHEN: results = adapter.run(strategy)
    THEN: results.trade_history contains 10 trades
    AND: Each trade has entry/exit prices
    AND: Each trade has PnL
    """
```

#### TEST-NBA-010: Results contain performance metrics
```python
def test_results_performance_metrics():
    """
    GIVEN: Completed backtest
    WHEN: results = adapter.run(strategy)
    THEN: results.performance_metrics is dict
    AND: Contains total_return
    AND: Contains sharpe_ratio
    AND: Contains max_drawdown
    AND: Contains win_rate
    """
```

### 5.4 Data Provider Integration

#### TEST-NBA-011: Adapter loads data from provider
```python
def test_adapter_loads_data_from_provider():
    """
    GIVEN: HistoricalDataProvider with 1 year of AAPL data
    WHEN: adapter.run(strategy) is called
    THEN: Provider.get_historical_data() is called
    AND: Data is loaded into Nautilus catalog
    AND: Strategy receives ticks/bars
    """
```

#### TEST-NBA-012: Handles missing data gracefully
```python
def test_adapter_handles_missing_data():
    """
    GIVEN: DataProvider with no data for requested instrument
    WHEN: adapter.run(strategy) is called
    THEN: Raises DataError with message "No data available"
    """
```

### 5.5 Edge Cases

#### TEST-NBA-013: Strategy without trades completes successfully
```python
def test_strategy_with_no_trades():
    """
    GIVEN: Strategy that never submits orders
    WHEN: adapter.run(strategy) is called
    THEN: Backtest completes successfully
    AND: Results show zero trades
    AND: Equity curve is flat (no changes)
    """
```

#### TEST-NBA-014: Strategy with exception is caught and reported
```python
def test_strategy_exception_is_caught():
    """
    GIVEN: Strategy that raises exception in on_tick()
    WHEN: adapter.run(strategy) is called
    THEN: Exception is caught
    AND: Wrapped in BacktestError with context
    AND: Backtest stops gracefully
    """
```

---

## 6. Integration Tests

**File**: `tests/adapters/frameworks/nautilus/integration/test_nautilus_integration.py`

### 6.1 End-to-End Integration

#### TEST-INT-001: SimpleBuyAndHoldStrategy runs on Nautilus
```python
def test_simple_buy_and_hold_on_nautilus():
    """
    GIVEN: SimpleBuyAndHoldStrategy (domain strategy)
    AND: 1 year of AAPL historical data
    AND: NautilusBacktestAdapter with config
    WHEN: adapter.run(strategy) is called
    THEN: Backtest completes successfully
    AND: Strategy buys on first tick
    AND: Strategy holds until end
    AND: Final equity > initial capital (AAPL went up)
    AND: Trade history shows 1 entry, 1 exit
    """
```

#### TEST-INT-002: Strategy receives ticks correctly
```python
def test_strategy_receives_all_ticks():
    """
    GIVEN: Historical data with 10,000 ticks
    AND: Domain strategy counting ticks
    WHEN: Backtest runs
    THEN: Strategy.on_tick() called 10,000 times
    AND: All ticks have valid prices and volumes
    """
```

#### TEST-INT-003: Orders are submitted and filled
```python
def test_orders_submitted_and_filled():
    """
    GIVEN: Strategy that submits market order
    WHEN: Backtest runs
    THEN: Order is submitted to Nautilus execution engine
    AND: Order is filled with realistic price
    AND: Fill event propagates back to strategy
    AND: Portfolio position is updated
    """
```

#### TEST-INT-004: Portfolio updates correctly
```python
def test_portfolio_updates():
    """
    GIVEN: Strategy executing multiple trades
    WHEN: Backtest runs
    THEN: Portfolio.equity reflects P&L
    AND: Portfolio.positions shows current holdings
    AND: Cash balance decreases/increases correctly
    """
```

### 6.2 Cross-Engine Validation

#### TEST-INT-005: Results match expected format
```python
def test_results_match_backtest_results_interface():
    """
    GIVEN: Completed Nautilus backtest
    WHEN: results = adapter.run(strategy)
    THEN: Results conform to BacktestResults interface
    AND: Can be compared with Custom engine results
    """
```

#### TEST-INT-006: Performance metrics calculation
```python
def test_performance_metrics_calculated():
    """
    GIVEN: Completed backtest with known trades
    WHEN: Performance metrics are calculated
    THEN: Total return matches manual calculation
    AND: Sharpe ratio is reasonable
    AND: Max drawdown is correctly identified
    """
```

### 6.3 Multi-Instrument Tests

#### TEST-INT-007: Portfolio with multiple instruments
```python
def test_multi_instrument_strategy():
    """
    GIVEN: Strategy trading AAPL and MSFT
    AND: Historical data for both instruments
    WHEN: Backtest runs
    THEN: Strategy receives ticks for both instruments
    AND: Can hold positions in both simultaneously
    AND: Portfolio correctly tracks both positions
    """
```

### 6.4 Performance Tests

#### TEST-INT-008: Backtest completes in reasonable time
```python
def test_backtest_performance():
    """
    GIVEN: 1 year of daily data (252 bars)
    WHEN: Backtest runs
    THEN: Completes in <5 seconds
    AND: Memory usage <500MB
    """
```

---

## 7. Acceptance Tests

**File**: `tests/adapters/frameworks/nautilus/acceptance/test_acceptance.py`

### 7.1 User Story Acceptance

#### TEST-ACC-001: As a user, I can run my strategy on Nautilus
```python
def test_user_can_run_strategy_on_nautilus():
    """
    USER STORY: As a strategy developer, I want to run my domain
    strategy on Nautilus Trader without modifying strategy code,
    so that I can leverage Nautilus's backtesting engine.

    GIVEN: Domain strategy (SimpleBuyAndHoldStrategy)
    AND: Historical data for backtesting
    WHEN: User creates NautilusBacktestAdapter and calls run()
    THEN: Strategy runs without modification
    AND: User receives BacktestResults
    AND: Results match expectations

    ACCEPTANCE CRITERIA:
    - Strategy code unchanged
    - Backtest completes successfully
    - Results returned in familiar format
    - Performance metrics included
    """
```

#### TEST-ACC-002: As a user, results are consistent with custom engine
```python
def test_results_consistent_with_custom_engine():
    """
    USER STORY: As a strategy developer, I want Nautilus backtest
    results to be comparable with custom engine results, so that
    I can validate Nautilus integration.

    GIVEN: Same strategy, same data, same config
    WHEN: Run on both Custom and Nautilus engines
    THEN: Total return divergence < 1%
    AND: Trade count matches (±1 trade)
    AND: Final equity within 0.5%

    ACCEPTANCE CRITERIA:
    - PnL divergence < 1%
    - Trade count similar
    - Metrics comparable
    """
```

#### TEST-ACC-003: As a user, I can choose engine at runtime
```python
def test_user_can_choose_engine():
    """
    USER STORY: As a strategy developer, I want to choose the
    backtesting engine (Custom or Nautilus) at runtime, so that
    I can compare results or leverage different engine features.

    GIVEN: Domain strategy
    WHEN: User creates adapter with engine="nautilus"
    THEN: Strategy runs on Nautilus
    WHEN: User creates adapter with engine="custom"
    THEN: Strategy runs on Custom engine
    AND: Both return BacktestResults

    ACCEPTANCE CRITERIA:
    - Engine selection via parameter
    - Same strategy code works on both
    - Results format identical
    """
```

### 7.2 Admin Acceptance

#### TEST-ACC-004: As an admin, I can debug Nautilus integration
```python
def test_admin_can_debug_integration():
    """
    ADMIN STORY: As a system admin, I want detailed logging
    and error messages from Nautilus integration, so that I
    can troubleshoot issues.

    GIVEN: Backtest with verbose logging enabled
    WHEN: Backtest runs
    THEN: Logs show:
        - Strategy lifecycle events
        - Order submissions
        - Fill events
        - Event translations
    AND: Errors include context and traceback

    ACCEPTANCE CRITERIA:
    - Comprehensive logging
    - Clear error messages
    - Debugging information available
    """
```

---

## 8. Test Execution Plan

### Phase 1: Unit Tests (Days 3-8)

**Order of Implementation**:
1. EventTranslator tests (simplest, no dependencies)
2. Port Adapter tests (depends on EventTranslator)
3. StrategyWrapper tests (depends on EventTranslator, Ports)
4. ConfigMapper tests (independent)
5. NautilusBacktestAdapter tests (depends on all above)

### Phase 2: Integration Tests (Day 9)

**Order of Implementation**:
1. SimpleBuyAndHoldStrategy end-to-end
2. Multi-instrument portfolio tests
3. Cross-engine validation tests
4. Performance tests

### Phase 3: Acceptance Tests (Day 9)

**Order of Implementation**:
1. User story acceptance tests
2. Admin story acceptance tests

---

## 9. Coverage Requirements

### Unit Test Coverage
- **Target**: 90%+ line coverage
- **Required**: All public methods tested
- **Required**: All edge cases covered

### Integration Test Coverage
- **Target**: All critical paths tested
- **Required**: End-to-end flow validated
- **Required**: Cross-engine comparison

### Acceptance Test Coverage
- **Target**: All user stories validated
- **Required**: All acceptance criteria met

---

## 10. Test Data Fixtures

### 10.1 Mock Domain Strategy
```python
@pytest.fixture
def mock_domain_strategy():
    """Simple mock strategy for testing wrapper."""
    class MockStrategy:
        def __init__(self):
            self.started = False
            self.tick_count = 0

        def start(self):
            self.started = True

        def on_tick(self, tick):
            self.tick_count += 1

    return MockStrategy()
```

### 10.2 Sample Historical Data
```python
@pytest.fixture
def sample_historical_data():
    """1 year of AAPL daily data."""
    return generate_sample_bars(
        instrument="AAPL",
        start="2023-01-01",
        end="2023-12-31",
        frequency="1D"
    )
```

### 10.3 Sample BacktestConfig
```python
@pytest.fixture
def sample_backtest_config():
    """Standard backtest configuration."""
    return BacktestConfig(
        start_date=datetime(2023, 1, 1),
        end_date=datetime(2023, 12, 31),
        initial_capital=100000,
        slippage=0.0005,
        commission=1.0
    )
```

---

## 11. Continuous Integration

### Test Automation
- All tests run on every commit
- TDD: Tests written BEFORE implementation
- Coverage reports generated automatically
- Failed tests block PR merge

### Test Execution Commands
```bash
# Run all Nautilus tests
pytest tests/adapters/frameworks/nautilus/

# Run with coverage
pytest tests/adapters/frameworks/nautilus/ --cov=src/adapters/frameworks/nautilus --cov-report=html

# Run specific test category
pytest tests/adapters/frameworks/nautilus/core/  # Unit tests
pytest tests/adapters/frameworks/nautilus/integration/  # Integration tests
pytest tests/adapters/frameworks/nautilus/acceptance/  # Acceptance tests
```

---

## 12. Definition of Done (Testing)

### Component-Level DoD
- [ ] All unit tests passing
- [ ] Coverage ≥90%
- [ ] No skipped tests
- [ ] All edge cases tested
- [ ] Integration tests passing

### Feature-Level DoD
- [ ] All acceptance tests passing
- [ ] End-to-end flow validated
- [ ] Cross-engine validation complete
- [ ] Performance benchmarks met
- [ ] Documentation updated with test results

---

**Test Specifications Status**: ✅ Complete
**Next Step**: Begin TDD implementation (Day 3)
**First Test to Write**: TEST-ET-001 (EventTranslator)

---

**Appendix: Test Naming Convention**

Format: `TEST-<Component>-<Number>: <Description>`

Components:
- **SW**: StrategyWrapper
- **CP**: ClockPort
- **MDP**: MarketDataPort
- **EP**: ExecutionPort
- **ET**: EventTranslator
- **CM**: ConfigMapper
- **NBA**: NautilusBacktestAdapter
- **INT**: Integration
- **ACC**: Acceptance
