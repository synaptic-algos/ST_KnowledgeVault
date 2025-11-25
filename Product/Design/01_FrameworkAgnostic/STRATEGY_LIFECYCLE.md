---
artifact_type: story
created_at: '2025-11-25T16:23:21.846278Z'
id: AUTO-STRATEGY_LIFECYCLE
manual_update: 'true'
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: '001'
status: pending
title: Auto-generated title for STRATEGY_LIFECYCLE
updated_at: '2025-11-25T16:23:21.846281Z'
---

## 2. Lifecycle States & Transitions

### 2.1 State Machine

```
┌─────────────┐
│ INITIALIZED │ (Constructor called)
└──────┬──────┘
       │ start()
       ▼
┌─────────────┐
│  STARTING   │ (on_start() executing)
└──────┬──────┘
       │ success
       ▼
┌─────────────┐◄─────────────┐
│   RUNNING   │              │ resume()
└──────┬──────┘              │
       │                     │
       ├─ pause() ─►┌────────┴───┐
       │            │   PAUSED   │
       │            └────────────┘
       │ stop()
       ▼
┌─────────────┐
│  STOPPING   │ (on_stop() executing)
└──────┬──────┘
       │ success
       ▼
┌─────────────┐
│   STOPPED   │ (Terminal state)
└─────────────┘

       │ Exception in any handler
       ▼
┌─────────────┐
│    FAULT    │ (Error state, requires intervention)
└─────────────┘
```

### 2.2 State Transition Rules

| From State | To State | Trigger | Validation |
|------------|----------|---------|------------|
| INITIALIZED | STARTING | `start()` | Must have valid config |
| STARTING | RUNNING | `on_start()` success | All ports responsive |
| STARTING | FAULT | `on_start()` exception | Log error, notify |
| RUNNING | PAUSED | `pause()` | No pending orders (configurable) |
| RUNNING | STOPPING | `stop()` | Begin shutdown sequence |
| RUNNING | FAULT | Event handler exception | Log error, transition immediately |
| PAUSED | RUNNING | `resume()` | All ports still responsive |
| STOPPING | STOPPED | `on_stop()` success | All resources released |
| ANY | FAULT | Critical error | Requires manual recovery |

---

## 3. State Management

### 3.1 Strategy State Persistence

```python
class StatefulStrategy(Strategy):
    """
    Strategy with state persistence support.
    Saves/restores state across runs.
    """

    def __init__(self, *args, state_store: Optional[StateStore] = None, **kwargs):
        super().__init__(*args, **kwargs)
        self.state_store = state_store
        self._indicators: Dict[str, Any] = {}
        self._internal_state: Dict[str, Any] = {}

    def on_start(self) -> None:
        """Restore state on startup."""
        if self.state_store:
            saved_state = self.state_store.load(self.id)
            if saved_state:
                self._restore_state(saved_state)
                self.telemetry.log(
                    LogLevel.INFO,
                    f"Restored state for {self.id}"
                )

    def on_stop(self) -> None:
        """Persist state on shutdown."""
        if self.state_store:
            state = self._capture_state()
            self.state_store.save(self.id, state)
            self.telemetry.log(
                LogLevel.INFO,
                f"Persisted state for {self.id}"
            )

    def _capture_state(self) -> Dict[str, Any]:
        """Serialize strategy state."""
        return {
            "indicators": self._indicators,
            "internal_state": self._internal_state,
            "last_update": self._last_update.isoformat() if self._last_update else None,
            "timestamp": self.clock.now().isoformat()
        }

    def _restore_state(self, state: Dict[str, Any]) -> None:
        """Deserialize strategy state."""
        self._indicators = state.get("indicators", {})
        self._internal_state = state.get("internal_state", {})
        if state.get("last_update"):
            self._last_update = datetime.fromisoformat(state["last_update"])
```

### 3.2 Indicator Management

```python
class IndicatorMixin:
    """
    Mixin for indicator lifecycle management.
    Handles warmup, updates, state tracking.
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._indicators: Dict[str, Indicator] = {}

    def register_indicator(
        self,
        name: str,
        indicator: Indicator,
        warmup_bars: int = 0
    ) -> None:
        """
        Register indicator for automatic updates.

        Args:
            name: Unique identifier
            indicator: Indicator instance
            warmup_bars: Bars needed before valid
        """
        self._indicators[name] = indicator

        if warmup_bars > 0:
            self._warmup_indicator(name, warmup_bars)

    def _warmup_indicator(self, name: str, warmup_bars: int) -> None:
        """Load historical data for indicator warmup."""
        # Example for moving average
        indicator = self._indicators[name]
        if hasattr(indicator, 'instrument_id'):
            history = self.market_data.lookup_history(
                indicator.instrument_id,
                HistoryWindow(count=warmup_bars, granularity=indicator.granularity)
            )
            for bar in history:
                indicator.update(bar)

    def get_indicator(self, name: str) -> Indicator:
        """Retrieve indicator by name."""
        return self._indicators[name]

    def handle_bar(self, bar: Bar) -> None:
        """Automatically update all indicators on new bar."""
        for indicator in self._indicators.values():
            if hasattr(indicator, 'instrument_id'):
                if indicator.instrument_id == bar.instrument_id:
                    indicator.update(bar)
```

---

## 4. Event Handling

### 4.1 Event Priority & Ordering

Adapters guarantee event delivery order within instrument:
1. Market data events (ticks/bars) in chronological order
2. Order updates follow submission order
3. Portfolio updates reflect completed fills

Cross-instrument event ordering depends on adapter capabilities.

### 4.2 Event Filtering

```python
class SelectiveStrategy(Strategy):
    """
    Strategy that filters events by instrument.
    Reduces processing overhead for multi-instrument environments.
    """

    def __init__(self, *args, watched_instruments: List[InstrumentId], **kwargs):
        super().__init__(*args, **kwargs)
        self.watched_instruments = set(watched_instruments)

    def on_market_data(self, tick: MarketTick) -> None:
        """Only process ticks for watched instruments."""
        if tick.instrument_id in self.watched_instruments:
            super().on_market_data(tick)

    def on_bar(self, bar: Bar) -> None:
        """Only process bars for watched instruments."""
        if bar.instrument_id in self.watched_instruments:
            super().on_bar(bar)
```

---

## 5. Configuration & Parameters

### 5.1 Strategy Configuration Schema

```python
from dataclasses import dataclass, field
from typing import List, Dict, Any

@dataclass
class StrategyConfig:
    """
    Framework-agnostic strategy configuration.
    Serializable to JSON/YAML.
    """
    strategy_id: str
    strategy_class: str                    # Fully-qualified class name
    instruments: List[str]                  # InstrumentId strings
    parameters: Dict[str, Any]              # Strategy-specific params

    # Risk limits
    max_position_size: Decimal
    max_daily_loss: Decimal
    max_drawdown_pct: float

    # Execution preferences
    order_type_preference: OrderType = OrderType.LIMIT
    time_in_force: TimeInForce = TimeInForce.DAY
    slippage_tolerance_bps: int = 5

    # State management
    persist_state: bool = True
    state_snapshot_interval_minutes: int = 5

    # Telemetry
    log_level: str = "INFO"
    emit_metrics: bool = True
    metrics_interval_seconds: int = 60


@dataclass
class BacktestConfig(StrategyConfig):
    """Extended config for backtesting."""
    start_date: datetime
    end_date: datetime
    initial_capital: Decimal
    commission_bps: int = 5
    slippage_model: str = "fixed"          # "fixed", "volume", "spread"


@dataclass
class LiveConfig(StrategyConfig):
    """Extended config for live trading."""
    broker: str                             # Broker/exchange identifier
    account_id: str
    dry_run: bool = False                   # Paper trading mode
    failsafe_enabled: bool = True
    heartbeat_interval_seconds: int = 30
```

### 5.2 Configuration Loading

```python
class ConfigLoader:
    """Loads and validates strategy configurations."""

    @staticmethod
    def load_from_file(path: str) -> StrategyConfig:
        """Load config from YAML/JSON file."""
        with open(path, 'r') as f:
            data = yaml.safe_load(f)

        # Determine config type from mode
        if data.get("mode") == "backtest":
            return BacktestConfig(**data)
        elif data.get("mode") == "live":
            return LiveConfig(**data)
        else:
            return StrategyConfig(**data)

    @staticmethod
    def validate(config: StrategyConfig) -> List[str]:
        """
        Validate configuration.
        Returns list of validation errors (empty if valid).
        """
        errors = []

        if config.max_position_size <= 0:
            errors.append("max_position_size must be positive")

        if config.max_daily_loss <= 0:
            errors.append("max_daily_loss must be positive")

        if not (0 < config.max_drawdown_pct < 100):
            errors.append("max_drawdown_pct must be between 0 and 100")

        # Validate instruments are parseable
        for inst_str in config.instruments:
            try:
                InstrumentId.parse(inst_str)
            except Exception:
                errors.append(f"Invalid instrument ID: {inst_str}")

        return errors
```

---

## 6. Example Strategy Implementation

### 6.1 Simple Moving Average Crossover

```python
class MovingAverageCrossover(Strategy):
    """
    Classic MA crossover strategy.
    BUY when fast MA crosses above slow MA.
    SELL when fast MA crosses below slow MA.
    """

    def __init__(
        self,
        strategy_id: str,
        market_data: MarketDataPort,
        clock: ClockPort,
        execution: OrderExecutionPort,
        portfolio: PortfolioStatePort,
        telemetry: TelemetryPort,
        config: Dict[str, Any]
    ):
        super().__init__(
            strategy_id, market_data, clock, execution,
            portfolio, telemetry, config
        )

        # Extract strategy parameters
        self.instrument_id = InstrumentId.parse(config["instrument"])
        self.fast_period = config["fast_period"]
        self.slow_period = config["slow_period"]
        self.position_size = Quantity(Decimal(config["position_size"]))

        # Initialize indicators
        self.fast_ma = SimpleMovingAverage(self.fast_period)
        self.slow_ma = SimpleMovingAverage(self.slow_period)

        # Track crossover state
        self._last_signal: Optional[Side] = None

    def on_start(self) -> None:
        """Warmup indicators with historical data."""
        self.telemetry.log(
            LogLevel.INFO,
            f"Warming up indicators: fast={self.fast_period}, slow={self.slow_period}"
        )

        # Load historical bars for warmup
        history = self.market_data.lookup_history(
            self.instrument_id,
            HistoryWindow(
                count=self.slow_period,  # Need enough for slow MA
                granularity=BarGranularity.MINUTE_5
            )
        )

        for bar in history:
            self.fast_ma.update(bar.close.value)
            self.slow_ma.update(bar.close.value)

        self.telemetry.log(
            LogLevel.INFO,
            f"Indicators warmed up with {len(history)} bars"
        )

    def on_stop(self) -> None:
        """Close any open positions on shutdown."""
        position = self.get_position(self.instrument_id)
        if position and not position.net_quantity.is_flat():
            self.telemetry.log(
                LogLevel.INFO,
                "Closing position on strategy stop"
            )
            close_intent = TradeIntent(
                strategy_id=self.id,
                legs=[
                    OrderLeg(
                        instrument_id=self.instrument_id,
                        side=Side.SELL if position.net_quantity.is_long() else Side.BUY,
                        quantity=Quantity(abs(position.net_quantity.value))
                    )
                ],
                order_type=OrderType.MARKET,
                time_in_force=TimeInForce.IOC
            )
            self.submit_order(close_intent)

    def handle_bar(self, bar: Bar) -> None:
        """Update indicators on new bar."""
        if bar.instrument_id != self.instrument_id:
            return

        self.fast_ma.update(bar.close.value)
        self.slow_ma.update(bar.close.value)

    def generate_signals(self) -> List[TradingSignal]:
        """Generate crossover signals."""
        # Wait for indicators to have sufficient data
        if not self.fast_ma.is_ready() or not self.slow_ma.is_ready():
            return []

        signals = []
        fast_value = self.fast_ma.value
        slow_value = self.slow_ma.value

        # Detect crossover
        if fast_value > slow_value and self._last_signal != Side.BUY:
            # Bullish crossover
            if self.is_flat(self.instrument_id):
                signals.append(
                    TradingSignal(
                        instrument_id=self.instrument_id,
                        side=Side.BUY,
                        quantity=self.position_size,
                        order_type=OrderType.MARKET,
                        timestamp=self.clock.now(),
                        metadata={"fast_ma": fast_value, "slow_ma": slow_value}
                    )
                )
                self._last_signal = Side.BUY

        elif fast_value < slow_value and self._last_signal != Side.SELL:
            # Bearish crossover
            position = self.get_position(self.instrument_id)
            if position and position.net_quantity.is_long():
                signals.append(
                    TradingSignal(
                        instrument_id=self.instrument_id,
                        side=Side.SELL,
                        quantity=Quantity(abs(position.net_quantity.value)),
                        order_type=OrderType.MARKET,
                        timestamp=self.clock.now(),
                        metadata={"fast_ma": fast_value, "slow_ma": slow_value}
                    )
                )
                self._last_signal = Side.SELL

        return signals


class SimpleMovingAverage:
    """Simple moving average indicator."""

    def __init__(self, period: int):
        self.period = period
        self._values: Deque[Decimal] = deque(maxlen=period)

    def update(self, value: Decimal) -> None:
        """Add new value to MA calculation."""
        self._values.append(value)

    def is_ready(self) -> bool:
        """Check if MA has sufficient data."""
        return len(self._values) == self.period

    @property
    def value(self) -> Decimal:
        """Current MA value."""
        if not self.is_ready():
            raise ValueError("MA not ready")
        return sum(self._values) / self.period
```

---

## Summary

This lifecycle design provides:

- ✅ **Clear state machine** with explicit transitions
- ✅ **Dependency injection** for all external services
- ✅ **Event-driven hooks** normalized across frameworks
- ✅ **State persistence** for restarts
- ✅ **Indicator management** with automatic warmup
- ✅ **Configuration schema** for deployment flexibility
- ✅ **Example implementation** demonstrating patterns

**Next**: See `BACKTEST_ENGINE.md` for historical simulation design.