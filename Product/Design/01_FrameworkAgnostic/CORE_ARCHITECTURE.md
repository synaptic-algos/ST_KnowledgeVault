---
artifact_type: story
created_at: '2025-11-25T16:23:21.841389Z'
id: AUTO-CORE_ARCHITECTURE
manual_update: 'true'
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: '001'
status: pending
title: Auto-generated title for CORE_ARCHITECTURE
updated_at: '2025-11-25T16:23:21.841392Z'
---

## 2. Strategy Port Specifications

### 2.1 MarketDataPort

```python
from abc import ABC, abstractmethod
from datetime import datetime
from typing import Iterator, List, Optional
from decimal import Decimal

class MarketDataPort(ABC):
    """
    Provides read-only access to market data in canonical format.
    Adapters normalize tick/bar data from underlying engines.
    """

    @abstractmethod
    def get_latest_tick(
        self,
        instrument_id: InstrumentId
    ) -> Optional[MarketTick]:
        """
        Retrieve most recent tick for instrument.

        Returns:
            MarketTick with bid/ask/last, or None if no data available

        Guarantees:
            - Immutable snapshot (defensive copy)
            - UTC timezone-aware timestamp
            - Canonical instrument identifier
        """
        pass

    @abstractmethod
    def get_latest_bar(
        self,
        instrument_id: InstrumentId,
        granularity: BarGranularity
    ) -> Optional[Bar]:
        """
        Retrieve most recent completed bar.

        Args:
            granularity: MINUTE_1, MINUTE_5, HOUR_1, DAY_1, etc.

        Returns:
            Bar with OHLCV, or None if unavailable

        Guarantees:
            - Bar represents COMPLETED period (close time in past)
            - Normalized volume units
        """
        pass

    @abstractmethod
    def lookup_history(
        self,
        instrument_id: InstrumentId,
        window: HistoryWindow
    ) -> List[Bar]:
        """
        Fetch historical bars for lookback calculations.

        Args:
            window: Defines count, granularity, end_time

        Returns:
            List of bars in chronological order (oldest first)

        Guarantees:
            - Gaps in data handled per adapter policy (forward-fill, raise, null)
            - Maximum window enforced by adapter capabilities
        """
        pass

    @abstractmethod
    def stream_ticks(
        self,
        instrument_id: InstrumentId
    ) -> Iterator[MarketTick]:
        """
        Stream real-time ticks (live/paper trading only).

        Yields:
            MarketTick objects as they arrive

        Note:
            Backtest adapters yield historical ticks from recorded data.
            Bar-based engines synthesize ticks from bar close prices.
        """
        pass

    @abstractmethod
    def get_instrument_info(
        self,
        instrument_id: InstrumentId
    ) -> InstrumentInfo:
        """
        Fetch instrument metadata (tick size, lot size, multiplier).

        Returns:
            InstrumentInfo with contract specifications

        Raises:
            InstrumentNotFoundError if instrument unknown to adapter
        """
        pass
```

**Adapter Translation Rules**:
- **Tick → Bar**: Adapters synthesize bar from sequence of ticks
- **Bar → Tick**: Adapters synthesize tick from bar close (with warning)
- **Timezone**: All timestamps normalized to UTC; adapters handle conversions
- **Gaps**: Adapters document gap-handling policy (forward-fill, null, raise)

---

### 2.2 ClockPort

```python
from abc import ABC, abstractmethod
from datetime import datetime, timedelta
from typing import Callable, Optional
from enum import Enum

class ClockMode(Enum):
    REALTIME = "realtime"       # System clock (live/paper)
    SIMULATED = "simulated"     # Controlled clock (backtest)
    REPLAY = "replay"           # Historical timestamp replay

class ClockPort(ABC):
    """
    Provides time and scheduling in framework-agnostic manner.
    Adapters normalize event-driven vs. bar-driven timing models.
    """

    @abstractmethod
    def now(self) -> datetime:
        """
        Current timestamp in UTC.

        Returns:
            datetime with tzinfo=UTC

        Behavior:
            - REALTIME: Returns system time
            - SIMULATED: Returns engine simulation time
            - REPLAY: Returns current event timestamp
        """
        pass

    @abstractmethod
    def mode(self) -> ClockMode:
        """Returns current clock mode (realtime, simulated, replay)."""
        pass

    @abstractmethod
    def schedule_once(
        self,
        callback: Callable[[], None],
        delay: timedelta
    ) -> ScheduleHandle:
        """
        Schedule callback after delay.

        Args:
            callback: Zero-argument function
            delay: Time delta from now()

        Returns:
            Handle for cancellation

        Guarantees:
            - Callback invoked exactly once
            - Clock time advances before callback runs
        """
        pass

    @abstractmethod
    def schedule_interval(
        self,
        callback: Callable[[], None],
        interval: timedelta,
        initial_delay: Optional[timedelta] = None
    ) -> ScheduleHandle:
        """
        Schedule recurring callback.

        Args:
            callback: Zero-argument function
            interval: Time between invocations
            initial_delay: Delay before first run (default: interval)

        Returns:
            Handle for cancellation
        """
        pass

    @abstractmethod
    def schedule_at(
        self,
        callback: Callable[[], None],
        timestamp: datetime
    ) -> ScheduleHandle:
        """
        Schedule callback at specific time.

        Args:
            timestamp: UTC datetime

        Raises:
            ValueError if timestamp is in the past
        """
        pass

    @abstractmethod
    def cancel_schedule(self, handle: ScheduleHandle) -> bool:
        """
        Cancel pending scheduled callback.

        Returns:
            True if canceled, False if already executed/invalid
        """
        pass

    @abstractmethod
    def next_market_open(
        self,
        calendar: str = "NYSE"
    ) -> datetime:
        """
        Timestamp of next market open.

        Args:
            calendar: Exchange calendar identifier

        Returns:
            UTC datetime of next trading session open

        Note:
            Adapters integrate with pandas_market_calendars or equivalent
        """
        pass
```

**Adapter Implementation Notes**:
- **Nautilus**: Wraps engine clock; schedule → event callbacks
- **Backtrader**: Schedules trigger on `next()` calls; clock = bar timestamp
- **Zipline**: Maps to `schedule_function`; clock from pipeline context
- **Custom**: Configurable clock backend (real/sim/replay)

---

### 2.3 OrderExecutionPort

```python
from abc import ABC, abstractmethod
from typing import List, Optional
from enum import Enum
from uuid import UUID

class OrderStatus(Enum):
    PENDING = "pending"           # Intent received, not submitted
    SUBMITTED = "submitted"       # Submitted to broker/exchange
    ACCEPTED = "accepted"         # Acknowledged by broker
    PARTIAL_FILL = "partial_fill" # Partially filled
    FILLED = "filled"             # Completely filled
    CANCELED = "canceled"         # Canceled by user/broker
    REJECTED = "rejected"         # Rejected by broker/exchange
    EXPIRED = "expired"           # Time-in-force expired

class OrderExecutionPort(ABC):
    """
    Submits trade intents and manages order lifecycle.
    Adapters translate canonical TradeIntent to engine-specific orders.
    """

    @abstractmethod
    def submit_order(
        self,
        intent: TradeIntent
    ) -> OrderTicket:
        """
        Submit trading intent for execution.

        Args:
            intent: Canonical trade intent (may be multi-leg)

        Returns:
            OrderTicket with unique ticket_id

        Raises:
            UnsupportedOrderTypeError if intent type not supported
            RiskCheckFailedError if pre-trade risk rejects

        Guarantees:
            - Ticket ID is globally unique
            - Status initially PENDING
            - Async updates delivered via register_callback()
        """
        pass

    @abstractmethod
    def cancel_order(
        self,
        ticket_id: UUID
    ) -> bool:
        """
        Request order cancellation.

        Returns:
            True if cancel request submitted, False if already terminal

        Note:
            Actual cancellation confirmed via order update callback
        """
        pass

    @abstractmethod
    def modify_order(
        self,
        ticket_id: UUID,
        modifications: OrderModification
    ) -> bool:
        """
        Modify pending order (price, quantity).

        Returns:
            True if modification submitted, False if unsupported/terminal

        Note:
            Not all adapters support modification; may cancel/replace
        """
        pass

    @abstractmethod
    def get_order_status(
        self,
        ticket_id: UUID
    ) -> Optional[OrderTicket]:
        """
        Query current order status.

        Returns:
            Latest OrderTicket snapshot, or None if ticket unknown
        """
        pass

    @abstractmethod
    def register_callback(
        self,
        callback: Callable[[OrderUpdate], None]
    ) -> None:
        """
        Register callback for order lifecycle events.

        Args:
            callback: Function receiving OrderUpdate on state changes

        Guarantees:
            - Callbacks invoked in order lifecycle sequence
            - Thread-safe if adapter supports concurrent execution
        """
        pass

    @abstractmethod
    def get_capabilities(self) -> ExecutionCapabilities:
        """
        Query adapter execution capabilities.

        Returns:
            ExecutionCapabilities with supported order types, TIF, etc.

        Example:
            caps = port.get_capabilities()
            if OrderType.SPREAD in caps.order_types:
                # Submit spread order
            else:
                # Decompose into legs
        """
        pass
```

**Capability Negotiation Example**:
```python
class ExecutionCapabilities:
    order_types: List[OrderType]           # MARKET, LIMIT, STOP, SPREAD, etc.
    time_in_force: List[TimeInForce]       # DAY, GTC, IOC, FOK
    supports_multi_leg: bool               # Native spread support
    supports_modification: bool            # In-flight order updates
    supports_bracket_orders: bool          # OCO/OTO orders
    max_legs_per_order: int                # Multi-leg limit
    latency_estimate_ms: float             # Expected fill latency
```

---

### 2.4 PortfolioStatePort

```python
from abc import ABC, abstractmethod
from typing import Dict, List, Optional
from decimal import Decimal

class PortfolioStatePort(ABC):
    """
    Provides read-only access to current portfolio state.
    Adapters normalize position/holdings representations.
    """

    @abstractmethod
    def get_positions(
        self,
        instrument_filter: Optional[InstrumentFilter] = None
    ) -> List[PositionSnapshot]:
        """
        Retrieve current positions.

        Args:
            instrument_filter: Optional filter by instrument/venue/asset_class

        Returns:
            List of PositionSnapshot (open positions only)

        Guarantees:
            - Net positions (long/short)
            - Unrealized P&L marked to latest market price
            - Includes all fees/commissions
        """
        pass

    @abstractmethod
    def get_position(
        self,
        instrument_id: InstrumentId
    ) -> Optional[PositionSnapshot]:
        """
        Retrieve position for specific instrument.

        Returns:
            PositionSnapshot or None if no position
        """
        pass

    @abstractmethod
    def get_cash_balances(
        self
    ) -> Dict[str, Decimal]:
        """
        Retrieve cash balances by currency.

        Returns:
            Dict mapping currency code → balance
            Example: {"USD": Decimal("100000.00"), "EUR": Decimal("50000.00")}
        """
        pass

    @abstractmethod
    def get_portfolio_value(
        self
    ) -> Decimal:
        """
        Total portfolio value (cash + positions MTM).

        Returns:
            Portfolio value in base currency

        Note:
            Adapters handle multi-currency conversion
        """
        pass

    @abstractmethod
    def get_buying_power(
        self
    ) -> Decimal:
        """
        Available buying power for new positions.

        Returns:
            Maximum capital available for trades

        Note:
            Accounts for margin requirements, risk limits
        """
        pass

    @abstractmethod
    def portfolio_snapshot(
        self
    ) -> PortfolioSnapshot:
        """
        Complete portfolio snapshot.

        Returns:
            PortfolioSnapshot with positions, cash, metrics, risk

        Guarantees:
            - Consistent point-in-time snapshot
            - All values marked to same timestamp
        """
        pass

    @abstractmethod
    def register_callback(
        self,
        callback: Callable[[PortfolioUpdate], None]
    ) -> None:
        """
        Register callback for portfolio state changes.

        Args:
            callback: Function receiving PortfolioUpdate on changes

        Guarantees:
            - Invoked on position changes, P&L updates
            - Throttled to avoid excessive callbacks
        """
        pass
```

**Position Normalization Rules**:
- **Net Positions**: Adapters convert holdings to net long/short
- **Average Cost**: Weighted average across fills
- **Unrealized P&L**: `(current_price - avg_cost) * quantity`
- **Realized P&L**: Cumulative from closed positions
- **Fees**: Explicit field, never hidden in P&L

---

### 2.5 TelemetryPort

```python
from abc import ABC, abstractmethod
from typing import Any, Dict, Optional
from enum import Enum

class LogLevel(Enum):
    DEBUG = "debug"
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"

class TelemetryPort(ABC):
    """
    Unified logging, metrics, and event emission.
    Adapters bridge to engine-native telemetry sinks.
    """

    @abstractmethod
    def log(
        self,
        level: LogLevel,
        message: str,
        context: Optional[Dict[str, Any]] = None
    ) -> None:
        """
        Structured logging.

        Args:
            level: Log severity
            message: Human-readable message
            context: Structured data (strategy_id, instrument_id, etc.)
        """
        pass

    @abstractmethod
    def metric(
        self,
        name: str,
        value: float,
        tags: Optional[Dict[str, str]] = None,
        timestamp: Optional[datetime] = None
    ) -> None:
        """
        Emit numeric metric.

        Args:
            name: Metric name (e.g., "strategy.signal_count")
            value: Metric value
            tags: Dimensions (strategy_id, instrument_id, signal_type)
            timestamp: Optional override (default: clock.now())

        Example:
            telemetry.metric(
                "strategy.sharpe_ratio",
                1.85,
                tags={"strategy_id": "mean_reversion_v1"}
            )
        """
        pass

    @abstractmethod
    def emit_event(
        self,
        event_type: str,
        payload: Dict[str, Any],
        timestamp: Optional[datetime] = None
    ) -> None:
        """
        Emit domain event for audit trail.

        Args:
            event_type: Event category (e.g., "order_filled", "risk_breach")
            payload: Event data
            timestamp: Optional override

        Guarantees:
            - Events persisted to canonical audit log
            - Enables deterministic replay
        """
        pass

    @abstractmethod
    def start_span(
        self,
        operation: str
    ) -> SpanContext:
        """
        Begin distributed tracing span.

        Args:
            operation: Operation name (e.g., "submit_order")

        Returns:
            SpanContext for duration tracking

        Usage:
            with telemetry.start_span("calculate_signal"):
                signal = strategy.generate_signal(tick)
        """
        pass
```

---

## 3. Canonical Domain Model

### 3.1 Core Value Objects

```python
# src/domain/shared/value_objects.py

from dataclasses import dataclass
from decimal import Decimal
from datetime import datetime
from typing import Optional
from enum import Enum

@dataclass(frozen=True)
class InstrumentId:
    """
    Canonical instrument identifier.
    Format: {venue}:{symbol}:{contract_spec}
    Example: NASDAQ:AAPL:STOCK, CME:ES:FUT:202503
    """
    venue: str
    symbol: str
    contract_spec: str

    def __str__(self) -> str:
        return f"{self.venue}:{self.symbol}:{self.contract_spec}"

    @classmethod
    def parse(cls, id_string: str) -> "InstrumentId":
        parts = id_string.split(":")
        return cls(venue=parts[0], symbol=parts[1], contract_spec=parts[2])


@dataclass(frozen=True)
class Price:
    """Immutable price with currency."""
    value: Decimal
    currency: str = "USD"

    def __add__(self, other: "Price") -> "Price":
        if self.currency != other.currency:
            raise ValueError("Cannot add prices in different currencies")
        return Price(self.value + other.value, self.currency)


@dataclass(frozen=True)
class Quantity:
    """Instrument quantity with direction."""
    value: Decimal

    def is_long(self) -> bool:
        return self.value > 0

    def is_short(self) -> bool:
        return self.value < 0

    def is_flat(self) -> bool:
        return self.value == 0


class Side(Enum):
    BUY = "buy"
    SELL = "sell"


class OrderType(Enum):
    MARKET = "market"
    LIMIT = "limit"
    STOP = "stop"
    STOP_LIMIT = "stop_limit"
    SPREAD = "spread"
    ICEBERG = "iceberg"


class TimeInForce(Enum):
    DAY = "day"           # Good for day
    GTC = "gtc"           # Good till canceled
    IOC = "ioc"           # Immediate or cancel
    FOK = "fok"           # Fill or kill
    GTD = "gtd"           # Good till date


@dataclass(frozen=True)
class MarketTick:
    """Canonical market tick."""
    instrument_id: InstrumentId
    timestamp: datetime
    bid: Optional[Price]
    ask: Optional[Price]
    last: Optional[Price]
    volume: Optional[Quantity]
    bid_size: Optional[Quantity] = None
    ask_size: Optional[Quantity] = None


@dataclass(frozen=True)
class Bar:
    """Canonical OHLCV bar."""
    instrument_id: InstrumentId
    timestamp: datetime              # Bar close time
    granularity: "BarGranularity"
    open: Price
    high: Price
    low: Price
    close: Price
    volume: Quantity
```

### 3.2 Trade Intent & Order Model

```python
@dataclass
class OrderLeg:
    """Single leg of potentially multi-leg order."""
    instrument_id: InstrumentId
    side: Side
    quantity: Quantity
    ratio: Decimal = Decimal("1.0")  # For spread orders


@dataclass
class TradeIntent:
    """
    Framework-agnostic trade intent.
    Adapters translate to engine-specific orders.
    """
    strategy_id: str
    legs: List[OrderLeg]
    order_type: OrderType
    price_instruction: Optional[Price] = None     # Limit price
    stop_price: Optional[Price] = None           # Stop trigger
    time_in_force: TimeInForce = TimeInForce.DAY
    metadata: Dict[str, Any] = field(default_factory=dict)

    def is_multi_leg(self) -> bool:
        return len(self.legs) > 1

    def total_quantity(self) -> Quantity:
        """Total notional quantity (sum of leg quantities)."""
        return Quantity(sum(leg.quantity.value for leg in self.legs))


@dataclass
class Fill:
    """Execution fill record."""
    timestamp: datetime
    instrument_id: InstrumentId
    quantity: Quantity
    price: Price
    fee: Price
    liquidity_flag: str  # "maker" or "taker"


@dataclass
class OrderTicket:
    """Order lifecycle tracking."""
    ticket_id: UUID
    intent: TradeIntent
    status: OrderStatus
    fills: List[Fill]
    last_update: datetime
    adapter_metadata: Dict[str, Any]  # Engine-specific fields

    def filled_quantity(self) -> Quantity:
        return Quantity(sum(f.quantity.value for f in self.fills))

    def avg_fill_price(self) -> Optional[Price]:
        if not self.fills:
            return None
        total_value = sum(f.price.value * f.quantity.value for f in self.fills)
        total_qty = sum(f.quantity.value for f in self.fills)
        return Price(total_value / total_qty, self.fills[0].price.currency)
```

### 3.3 Position & Portfolio Model

```python
@dataclass
class PositionSnapshot:
    """Point-in-time position state."""
    instrument_id: InstrumentId
    net_quantity: Quantity
    avg_cost: Price
    realized_pnl: Price
    unrealized_pnl: Price
    total_fees: Price
    exposure: Price              # net_quantity * current_price
    first_opened: datetime
    last_updated: datetime


@dataclass
class PortfolioSnapshot:
    """Complete portfolio state."""
    timestamp: datetime
    cash_balances: Dict[str, Decimal]
    positions: List[PositionSnapshot]
    total_value: Decimal
    total_pnl: Decimal
    buying_power: Decimal
    risk_metrics: Dict[str, float]  # VaR, Sharpe, etc.
```

---

## 4. Application Orchestration Layer

### 4.1 RuntimeBootstrapper

```python
class RuntimeBootstrapper:
    """
    Dependency injection container.
    Wires ports to adapters based on engine configuration.
    """

    def __init__(self, config: RuntimeConfig):
        self.config = config
        self._adapter_registry: Dict[str, Type[FrameworkAdapter]] = {}

    def register_adapter(
        self,
        engine_name: str,
        adapter_class: Type[FrameworkAdapter]
    ) -> None:
        """Register adapter for engine selection."""
        self._adapter_registry[engine_name] = adapter_class

    def bootstrap(self) -> StrategyRuntime:
        """
        Initialize runtime with selected adapter.

        Returns:
            StrategyRuntime with wired ports

        Raises:
            AdapterNotFoundError if engine unknown
            AdapterInitializationError if setup fails
        """
        adapter_class = self._adapter_registry[self.config.engine_name]
        adapter = adapter_class(self.config.engine_config)

        # Wire ports
        market_data_port = adapter.create_market_data_port()
        clock_port = adapter.create_clock_port()
        execution_port = adapter.create_execution_port()
        portfolio_port = adapter.create_portfolio_port()
        telemetry_port = adapter.create_telemetry_port()

        # Create application services
        tick_dispatcher = TickDispatcher(clock_port, telemetry_port)
        command_bus = CommandBus(execution_port, telemetry_port)
        risk_orchestrator = RiskOrchestrator(
            portfolio_port,
            self.config.risk_limits
        )

        return StrategyRuntime(
            market_data=market_data_port,
            clock=clock_port,
            execution=execution_port,
            portfolio=portfolio_port,
            telemetry=telemetry_port,
            tick_dispatcher=tick_dispatcher,
            command_bus=command_bus,
            risk_orchestrator=risk_orchestrator
        )
```

### 4.2 TickDispatcher

```python
class TickDispatcher:
    """
    Normalizes engine events to canonical clock events.
    Dispatches to registered strategies.
    """

    def __init__(
        self,
        clock: ClockPort,
        telemetry: TelemetryPort
    ):
        self.clock = clock
        self.telemetry = telemetry
        self._strategies: List[Strategy] = []

    def register_strategy(self, strategy: Strategy) -> None:
        """Add strategy to dispatch list."""
        self._strategies.append(strategy)

    def on_tick(self, tick: MarketTick) -> None:
        """
        Dispatch market tick to all strategies.
        Called by adapter on new market data.
        """
        with self.telemetry.start_span("dispatch_tick"):
            for strategy in self._strategies:
                try:
                    strategy.on_market_data(tick)
                except Exception as e:
                    self.telemetry.log(
                        LogLevel.ERROR,
                        f"Strategy {strategy.id} tick error: {e}",
                        context={"instrument": str(tick.instrument_id)}
                    )

    def on_bar(self, bar: Bar) -> None:
        """Dispatch bar-based events."""
        for strategy in self._strategies:
            try:
                strategy.on_bar(bar)
            except Exception as e:
                self.telemetry.log(
                    LogLevel.ERROR,
                    f"Strategy {strategy.id} bar error: {e}"
                )
```

### 4.3 CommandBus

```python
class CommandBus:
    """
    Routes trade intents through risk checks to execution.
    """

    def __init__(
        self,
        execution: OrderExecutionPort,
        telemetry: TelemetryPort
    ):
        self.execution = execution
        self.telemetry = telemetry

    def submit_intent(
        self,
        intent: TradeIntent,
        risk_orchestrator: RiskOrchestrator
    ) -> Result[OrderTicket, RiskCheckError]:
        """
        Submit trade intent with risk validation.

        Returns:
            Result[OrderTicket] on success, Result[Error] on failure
        """
        # Pre-trade risk check
        risk_result = risk_orchestrator.validate_intent(intent)
        if not risk_result.is_ok():
            self.telemetry.log(
                LogLevel.WARNING,
                f"Risk check failed: {risk_result.error}",
                context={"strategy_id": intent.strategy_id}
            )
            return Result.error(risk_result.error)

        # Submit to execution port
        try:
            ticket = self.execution.submit_order(intent)
            self.telemetry.emit_event(
                "order_submitted",
                {
                    "ticket_id": str(ticket.ticket_id),
                    "strategy_id": intent.strategy_id,
                    "order_type": intent.order_type.value
                }
            )
            return Result.ok(ticket)
        except Exception as e:
            self.telemetry.log(
                LogLevel.ERROR,
                f"Order submission failed: {e}"
            )
            return Result.error(ExecutionError(str(e)))
```

---

## 5. Dependency Management

### 5.1 Module Structure

```
src/
├── domain/
│   ├── __init__.py
│   ├── shared/
│   │   ├── value_objects.py       # InstrumentId, Price, Quantity
│   │   └── events.py              # Domain events
│   └── strategy/
│       ├── aggregates/
│       │   ├── strategy.py        # Strategy aggregate root
│       │   └── position.py        # Position aggregate
│       ├── services/
│       │   ├── signal_generator.py
│       │   └── position_sizer.py
│       └── value_objects/
│           └── signal.py
│
├── application/
│   ├── __init__.py
│   ├── ports/                     # Port interface definitions
│   │   ├── __init__.py
│   │   ├── market_data_port.py
│   │   ├── clock_port.py
│   │   ├── execution_port.py
│   │   ├── portfolio_port.py
│   │   └── telemetry_port.py
│   └── orchestration/
│       ├── runtime_bootstrapper.py
│       ├── tick_dispatcher.py
│       ├── command_bus.py
│       └── risk_orchestrator.py
│
├── adapters/
│   ├── __init__.py
│   └── frameworks/
│       ├── nautilus/
│       │   ├── __init__.py
│       │   ├── adapter.py
│       │   ├── market_data.py
│       │   ├── execution.py
│       │   └── translators.py
│       ├── backtrader/
│       │   └── ...
│       ├── zipline/
│       │   └── ...
│       └── custom/
│           └── ...
│
└── interfaces/
    └── strategy_runtime.py        # Public API for strategy execution
```

### 5.2 Dependency Rules (Enforced via import-linter)

```yaml
# .importlinter.ini
[contracts]
name = Layered Architecture
type = layers
layers =
    domain
    application
    adapters

[domain_independence]
type = forbidden
source_modules =
    domain
forbidden_modules =
    adapters
    application

[adapter_isolation]
type = forbidden
source_modules =
    adapters.frameworks.nautilus
forbidden_modules =
    adapters.frameworks.backtrader
    adapters.frameworks.zipline
```

---

## 6. Error Handling & Resilience

### 6.1 Error Hierarchy

```python
class StrategyRuntimeError(Exception):
    """Base for all runtime errors."""
    pass

class AdapterError(StrategyRuntimeError):
    """Adapter-specific failures."""
    pass

class RiskCheckError(StrategyRuntimeError):
    """Pre-trade risk validation failures."""
    pass

class ExecutionError(StrategyRuntimeError):
    """Order submission/management failures."""
    pass

class DataUnavailableError(StrategyRuntimeError):
    """Market data not available."""
    pass
```

### 6.2 Resilience Patterns

**Circuit Breaker**: Adapter execution port tracks failure rate; opens circuit if threshold exceeded
**Retry with Backoff**: Transient errors (network) retried with exponential backoff
**Graceful Degradation**: Missing capabilities handled via adapter negotiation
**Audit Logging**: All errors logged to canonical audit trail

---

## Summary

This core architecture provides:
- ✅ **5 port interfaces** for complete framework abstraction
- ✅ **Canonical domain model** for normalized data exchange
- ✅ **Application orchestration** for event dispatch and risk management
- ✅ **Strict dependency rules** enforced via tooling
- ✅ **Comprehensive error handling** with resilience patterns

Next: See `STRATEGY_LIFECYCLE.md` for strategy implementation patterns.
