---
artifact_type: story
created_at: '2025-11-25T16:23:21.845084Z'
id: AUTO-BACKTEST_ENGINE
manual_update: 'true'
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: '001'
status: pending
title: Auto-generated title for BACKTEST_ENGINE
updated_at: '2025-11-25T16:23:21.845087Z'
---

## 2. Architecture Components

### 2.1 BacktestAdapter

```python
class BacktestAdapter(FrameworkAdapter):
    """
    Adapter implementing all strategy ports for backtesting.
    Provides historical data replay and simulated execution.
    """

    def __init__(
        self,
        config: BacktestConfig,
        data_provider: HistoricalDataProvider,
        execution_simulator: ExecutionSimulator
    ):
        self.config = config
        self.data_provider = data_provider
        self.execution_simulator = execution_simulator

        # Simulated clock
        self.clock = SimulatedClock(config.start_date)

        # Portfolio accounting
        self.portfolio = BacktestPortfolio(
            initial_capital=config.initial_capital,
            base_currency=config.base_currency
        )

        # Event replay engine
        self.event_replayer = EventReplayer(
            data_provider=data_provider,
            clock=self.clock,
            start_date=config.start_date,
            end_date=config.end_date
        )

        # Audit log
        self.audit_log = AuditLog()

    def create_market_data_port(self) -> MarketDataPort:
        """Create market data port backed by historical data."""
        return BacktestMarketDataPort(
            data_provider=self.data_provider,
            clock=self.clock
        )

    def create_clock_port(self) -> ClockPort:
        """Create simulated clock port."""
        return BacktestClockPort(self.clock)

    def create_execution_port(self) -> OrderExecutionPort:
        """Create simulated execution port."""
        return BacktestExecutionPort(
            simulator=self.execution_simulator,
            clock=self.clock,
            portfolio=self.portfolio,
            audit_log=self.audit_log
        )

    def create_portfolio_port(self) -> PortfolioStatePort:
        """Create portfolio port with simulated accounting."""
        return BacktestPortfolioPort(self.portfolio)

    def create_telemetry_port(self) -> TelemetryPort:
        """Create telemetry port for logging/metrics."""
        return BacktestTelemetryPort(
            audit_log=self.audit_log,
            clock=self.clock
        )

    def run(self, strategy: Strategy) -> BacktestResults:
        """
        Execute backtest.

        Args:
            strategy: Strategy instance to test

        Returns:
            BacktestResults with performance metrics, trades, equity curve

        Flow:
            1. Initialize strategy (warmup period)
            2. Replay historical events chronologically
            3. Dispatch events to strategy
            4. Simulate order fills
            5. Update portfolio accounting
            6. Collect performance metrics
            7. Generate backtest report
        """
        # Initialize
        strategy.start()

        # Replay events
        for event in self.event_replayer:
            # Advance clock
            self.clock.set_time(event.timestamp)

            # Dispatch to strategy
            if isinstance(event, MarketDataEvent):
                strategy.on_market_data(event.tick)
            elif isinstance(event, BarEvent):
                strategy.on_bar(event.bar)

            # Process pending orders
            fills = self.execution_simulator.process_pending_orders(
                market_state=event,
                current_time=self.clock.now()
            )

            # Update portfolio
            for fill in fills:
                self.portfolio.apply_fill(fill)
                strategy.on_order_update(
                    OrderUpdate.from_fill(fill)
                )

            # Snapshot for equity curve
            if self._should_snapshot():
                self.portfolio.snapshot(self.clock.now())

        # Finalize
        strategy.stop()

        # Generate results
        return BacktestResults(
            config=self.config,
            portfolio=self.portfolio,
            audit_log=self.audit_log,
            strategy_metrics=self._calculate_metrics()
        )

    def _should_snapshot(self) -> bool:
        """Determine if portfolio snapshot needed (e.g., daily)."""
        return True  # Simplified; implement sampling logic
```

---

## 3. Historical Data Replay

### 3.1 Event Replayer

```python
from typing import Iterator, List
from datetime import datetime, timedelta
from enum import Enum

class EventType(Enum):
    TICK = "tick"
    BAR = "bar"
    CORPORATE_ACTION = "corporate_action"

class HistoricalEvent:
    """Base class for replayed events."""
    timestamp: datetime
    event_type: EventType


class MarketDataEvent(HistoricalEvent):
    """Market tick/quote event."""
    tick: MarketTick


class BarEvent(HistoricalEvent):
    """Bar close event."""
    bar: Bar


class EventReplayer:
    """
    Chronologically replays historical events.
    Merges multiple data sources (ticks, bars, corporate actions).
    """

    def __init__(
        self,
        data_provider: HistoricalDataProvider,
        clock: SimulatedClock,
        start_date: datetime,
        end_date: datetime
    ):
        self.data_provider = data_provider
        self.clock = clock
        self.start_date = start_date
        self.end_date = end_date

    def __iter__(self) -> Iterator[HistoricalEvent]:
        """
        Yield events in chronological order.

        Strategy:
        - Load data in chunks (e.g., daily) to manage memory
        - Merge sort across instruments
        - Respect market hours (optional filtering)
        """
        current_date = self.start_date

        while current_date <= self.end_date:
            # Load day's data
            day_events = self._load_day(current_date)

            # Sort by timestamp (merge multiple instruments)
            day_events.sort(key=lambda e: e.timestamp)

            # Yield events
            for event in day_events:
                yield event

            current_date += timedelta(days=1)

    def _load_day(self, date: datetime) -> List[HistoricalEvent]:
        """Load all events for a single day."""
        events = []

        # Load tick data
        for instrument in self.data_provider.instruments:
            ticks = self.data_provider.get_ticks(instrument, date)
            events.extend(
                MarketDataEvent(timestamp=t.timestamp, tick=t)
                for t in ticks
            )

            # Or load bar data if tick not available
            if not ticks:
                bars = self.data_provider.get_bars(
                    instrument, date, BarGranularity.MINUTE_1
                )
                events.extend(
                    BarEvent(timestamp=b.timestamp, bar=b)
                    for b in bars
                )

        return events
```

### 3.2 Historical Data Provider Interface

```python
from abc import ABC, abstractmethod

class HistoricalDataProvider(ABC):
    """
    Abstract interface for historical data sources.
    Implementations: Parquet files, database, vendor API, etc.
    """

    @abstractmethod
    def get_ticks(
        self,
        instrument_id: InstrumentId,
        date: datetime
    ) -> List[MarketTick]:
        """Fetch tick data for instrument on date."""
        pass

    @abstractmethod
    def get_bars(
        self,
        instrument_id: InstrumentId,
        start: datetime,
        end: datetime,
        granularity: BarGranularity
    ) -> List[Bar]:
        """Fetch bar data for date range."""
        pass

    @abstractmethod
    def get_instrument_universe(
        self,
        date: datetime
    ) -> List[InstrumentId]:
        """Get tradeable instruments on date (survivorship bias handling)."""
        pass


class ParquetDataProvider(HistoricalDataProvider):
    """
    Data provider backed by Parquet files.
    Assumes structure: {base_path}/{instrument}/{year}/{month}/data.parquet
    """

    def __init__(self, base_path: str):
        self.base_path = base_path

    def get_bars(
        self,
        instrument_id: InstrumentId,
        start: datetime,
        end: datetime,
        granularity: BarGranularity
    ) -> List[Bar]:
        """Load bars from Parquet."""
        import pandas as pd

        # Construct file path
        file_path = (
            f"{self.base_path}/{instrument_id.symbol}/"
            f"{start.year}/{start.month:02d}/bars_{granularity.value}.parquet"
        )

        # Read Parquet
        df = pd.read_parquet(file_path)

        # Filter date range
        df = df[(df['timestamp'] >= start) & (df['timestamp'] <= end)]

        # Convert to Bar objects
        return [
            Bar(
                instrument_id=instrument_id,
                timestamp=row['timestamp'],
                granularity=granularity,
                open=Price(Decimal(str(row['open']))),
                high=Price(Decimal(str(row['high']))),
                low=Price(Decimal(str(row['low']))),
                close=Price(Decimal(str(row['close']))),
                volume=Quantity(Decimal(str(row['volume'])))
            )
            for _, row in df.iterrows()
        ]
```

---

## 4. Simulated Execution

### 4.1 Execution Simulator

```python
from typing import List, Dict
from uuid import UUID, uuid4
from collections import defaultdict

class ExecutionSimulator:
    """
    Simulates order fills based on market data.
    Models slippage, commissions, market impact, latency.
    """

    def __init__(
        self,
        slippage_model: SlippageModel,
        commission_model: CommissionModel,
        latency_model: LatencyModel
    ):
        self.slippage_model = slippage_model
        self.commission_model = commission_model
        self.latency_model = latency_model

        # Pending orders
        self._pending_orders: Dict[UUID, PendingOrder] = {}

    def submit_order(
        self,
        intent: TradeIntent,
        submit_time: datetime
    ) -> OrderTicket:
        """
        Accept order for simulation.

        Args:
            intent: Trade intent
            submit_time: Current simulation time

        Returns:
            OrderTicket with PENDING status
        """
        ticket_id = uuid4()

        # Calculate effective submission time (latency)
        effective_time = submit_time + self.latency_model.get_delay()

        pending_order = PendingOrder(
            ticket_id=ticket_id,
            intent=intent,
            submit_time=submit_time,
            effective_time=effective_time,
            status=OrderStatus.PENDING
        )

        self._pending_orders[ticket_id] = pending_order

        return OrderTicket(
            ticket_id=ticket_id,
            intent=intent,
            status=OrderStatus.PENDING,
            fills=[],
            last_update=submit_time,
            adapter_metadata={"sim_latency_ms": self.latency_model.get_delay().total_seconds() * 1000}
        )

    def process_pending_orders(
        self,
        market_state: HistoricalEvent,
        current_time: datetime
    ) -> List[Fill]:
        """
        Evaluate pending orders against current market state.
        Simulate fills based on order type and market conditions.

        Args:
            market_state: Current market tick/bar
            current_time: Simulation time

        Returns:
            List of Fill objects for executed orders
        """
        fills = []

        for ticket_id, order in list(self._pending_orders.items()):
            # Skip if not yet effective (latency)
            if current_time < order.effective_time:
                continue

            # Attempt fill
            fill = self._try_fill(order, market_state, current_time)

            if fill:
                fills.append(fill)
                del self._pending_orders[ticket_id]

        return fills

    def _try_fill(
        self,
        order: PendingOrder,
        market_state: HistoricalEvent,
        current_time: datetime
    ) -> Optional[Fill]:
        """
        Determine if order should fill given market state.

        Logic:
        - MARKET orders: Fill immediately at current price + slippage
        - LIMIT orders: Fill if market price crosses limit
        - STOP orders: Trigger if stop price reached
        """
        if order.intent.order_type == OrderType.MARKET:
            return self._fill_market_order(order, market_state, current_time)
        elif order.intent.order_type == OrderType.LIMIT:
            return self._fill_limit_order(order, market_state, current_time)
        elif order.intent.order_type == OrderType.STOP:
            return self._fill_stop_order(order, market_state, current_time)
        else:
            raise NotImplementedError(f"Order type {order.intent.order_type} not supported")

    def _fill_market_order(
        self,
        order: PendingOrder,
        market_state: HistoricalEvent,
        current_time: datetime
    ) -> Fill:
        """Fill market order at current price + slippage."""
        # Extract current price from market state
        if isinstance(market_state, MarketDataEvent):
            # Use mid-price
            current_price = (market_state.tick.bid.value + market_state.tick.ask.value) / 2
            # Apply spread cost
            if order.intent.legs[0].side == Side.BUY:
                current_price = market_state.tick.ask.value  # Pay ask
            else:
                current_price = market_state.tick.bid.value  # Receive bid
        elif isinstance(market_state, BarEvent):
            current_price = market_state.bar.close.value
        else:
            raise ValueError("Unexpected market state type")

        # Apply slippage
        slippage = self.slippage_model.calculate_slippage(
            price=Price(current_price),
            quantity=order.intent.total_quantity(),
            side=order.intent.legs[0].side,
            market_state=market_state
        )

        fill_price = Price(current_price + slippage.value)

        # Calculate commission
        commission = self.commission_model.calculate_commission(
            price=fill_price,
            quantity=order.intent.total_quantity(),
            instrument_id=order.intent.legs[0].instrument_id
        )

        return Fill(
            timestamp=current_time,
            instrument_id=order.intent.legs[0].instrument_id,
            quantity=order.intent.total_quantity(),
            price=fill_price,
            fee=commission,
            liquidity_flag="taker"
        )

    def _fill_limit_order(
        self,
        order: PendingOrder,
        market_state: HistoricalEvent,
        current_time: datetime
    ) -> Optional[Fill]:
        """Fill limit order if price crosses limit."""
        limit_price = order.intent.price_instruction

        if isinstance(market_state, BarEvent):
            bar = market_state.bar

            # Check if limit was reached during bar
            if order.intent.legs[0].side == Side.BUY:
                # Buy limit: Fill if low <= limit
                if bar.low.value <= limit_price.value:
                    return self._create_fill(
                        order, limit_price, current_time, "maker"
                    )
            else:
                # Sell limit: Fill if high >= limit
                if bar.high.value >= limit_price.value:
                    return self._create_fill(
                        order, limit_price, current_time, "maker"
                    )

        elif isinstance(market_state, MarketDataEvent):
            tick = market_state.tick

            if order.intent.legs[0].side == Side.BUY:
                # Buy limit: Fill if ask <= limit
                if tick.ask and tick.ask.value <= limit_price.value:
                    return self._create_fill(
                        order, limit_price, current_time, "maker"
                    )
            else:
                # Sell limit: Fill if bid >= limit
                if tick.bid and tick.bid.value >= limit_price.value:
                    return self._create_fill(
                        order, limit_price, current_time, "maker"
                    )

        return None

    def _create_fill(
        self,
        order: PendingOrder,
        fill_price: Price,
        timestamp: datetime,
        liquidity_flag: str
    ) -> Fill:
        """Helper to create fill with commission."""
        commission = self.commission_model.calculate_commission(
            price=fill_price,
            quantity=order.intent.total_quantity(),
            instrument_id=order.intent.legs[0].instrument_id
        )

        return Fill(
            timestamp=timestamp,
            instrument_id=order.intent.legs[0].instrument_id,
            quantity=order.intent.total_quantity(),
            price=fill_price,
            fee=commission,
            liquidity_flag=liquidity_flag
        )
```

### 4.2 Slippage Models

```python
from abc import ABC, abstractmethod

class SlippageModel(ABC):
    """Abstract slippage model."""

    @abstractmethod
    def calculate_slippage(
        self,
        price: Price,
        quantity: Quantity,
        side: Side,
        market_state: HistoricalEvent
    ) -> Price:
        """Calculate price slippage."""
        pass


class FixedSlippageModel(SlippageModel):
    """Fixed BPS slippage."""

    def __init__(self, slippage_bps: int):
        self.slippage_bps = slippage_bps

    def calculate_slippage(
        self,
        price: Price,
        quantity: Quantity,
        side: Side,
        market_state: HistoricalEvent
    ) -> Price:
        """Apply fixed slippage."""
        slippage_amount = price.value * Decimal(self.slippage_bps) / Decimal(10000)

        # Adverse price movement
        if side == Side.BUY:
            return Price(slippage_amount, price.currency)
        else:
            return Price(-slippage_amount, price.currency)


class VolumeSlippageModel(SlippageModel):
    """
    Slippage proportional to order size relative to volume.
    Models market impact.
    """

    def __init__(self, impact_coefficient: float = 0.1):
        self.impact_coefficient = impact_coefficient

    def calculate_slippage(
        self,
        price: Price,
        quantity: Quantity,
        side: Side,
        market_state: HistoricalEvent
    ) -> Price:
        """Calculate volume-based slippage."""
        if isinstance(market_state, MarketDataEvent):
            tick = market_state.tick
            available_volume = tick.volume.value if tick.volume else Decimal(10000)
        elif isinstance(market_state, BarEvent):
            bar = market_state.bar
            available_volume = bar.volume.value
        else:
            available_volume = Decimal(10000)

        # Impact = (order_size / available_volume) * coefficient * price
        size_ratio = abs(quantity.value) / available_volume
        impact = price.value * Decimal(str(size_ratio * self.impact_coefficient))

        if side == Side.BUY:
            return Price(impact, price.currency)
        else:
            return Price(-impact, price.currency)
```

### 4.3 Commission Models

```python
class CommissionModel(ABC):
    """Abstract commission model."""

    @abstractmethod
    def calculate_commission(
        self,
        price: Price,
        quantity: Quantity,
        instrument_id: InstrumentId
    ) -> Price:
        """Calculate trading commission."""
        pass


class FixedBPSCommission(CommissionModel):
    """Fixed basis points commission."""

    def __init__(self, commission_bps: int, min_commission: Decimal = Decimal("1.0")):
        self.commission_bps = commission_bps
        self.min_commission = min_commission

    def calculate_commission(
        self,
        price: Price,
        quantity: Quantity,
        instrument_id: InstrumentId
    ) -> Price:
        """Calculate commission as BPS of notional."""
        notional = price.value * abs(quantity.value)
        commission = notional * Decimal(self.commission_bps) / Decimal(10000)

        # Apply minimum
        commission = max(commission, self.min_commission)

        return Price(commission, price.currency)


class TieredCommission(CommissionModel):
    """Tiered commission based on volume."""

    def __init__(self, tiers: List[Tuple[Decimal, int]]):
        """
        Args:
            tiers: List of (volume_threshold, commission_bps)
                   Example: [(1000000, 5), (5000000, 3), (inf, 2)]
        """
        self.tiers = sorted(tiers, key=lambda x: x[0])

    def calculate_commission(
        self,
        price: Price,
        quantity: Quantity,
        instrument_id: InstrumentId
    ) -> Price:
        """Calculate tiered commission."""
        notional = price.value * abs(quantity.value)

        # Find applicable tier
        for threshold, bps in self.tiers:
            if notional <= threshold:
                commission = notional * Decimal(bps) / Decimal(10000)
                return Price(commission, price.currency)

        # Fallback to last tier
        last_bps = self.tiers[-1][1]
        commission = notional * Decimal(last_bps) / Decimal(10000)
        return Price(commission, price.currency)
```

---

## 5. Performance Analysis

### 5.1 BacktestResults

```python
@dataclass
class BacktestResults:
    """Complete backtest results."""
    config: BacktestConfig
    portfolio: BacktestPortfolio
    audit_log: AuditLog

    # Performance metrics
    total_return: float
    sharpe_ratio: float
    sortino_ratio: float
    max_drawdown: float
    max_drawdown_duration: timedelta
    win_rate: float
    profit_factor: float
    avg_win: Decimal
    avg_loss: Decimal

    # Trade statistics
    total_trades: int
    winning_trades: int
    losing_trades: int
    avg_trade_duration: timedelta

    # Time series
    equity_curve: pd.DataFrame        # timestamp, equity, drawdown
    trade_log: pd.DataFrame           # Trade-by-trade results

    def summary(self) -> str:
        """Generate human-readable summary."""
        return f"""
Backtest Summary
================
Period: {self.config.start_date.date()} to {self.config.end_date.date()}
Initial Capital: ${self.config.initial_capital:,.2f}
Final Equity: ${self.portfolio.total_value:,.2f}

Performance Metrics
-------------------
Total Return: {self.total_return:.2%}
Sharpe Ratio: {self.sharpe_ratio:.2f}
Sortino Ratio: {self.sortino_ratio:.2f}
Max Drawdown: {self.max_drawdown:.2%}

Trade Statistics
----------------
Total Trades: {self.total_trades}
Win Rate: {self.win_rate:.2%}
Profit Factor: {self.profit_factor:.2f}
Avg Win: ${self.avg_win:,.2f}
Avg Loss: ${self.avg_loss:,.2f}
        """

    def plot_equity_curve(self) -> None:
        """Generate equity curve visualization."""
        import matplotlib.pyplot as plt

        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8), sharex=True)

        # Equity curve
        ax1.plot(self.equity_curve.index, self.equity_curve['equity'])
        ax1.set_ylabel('Equity ($)')
        ax1.set_title('Equity Curve')
        ax1.grid(True)

        # Drawdown
        ax2.fill_between(
            self.equity_curve.index,
            self.equity_curve['drawdown'],
            0,
            color='red',
            alpha=0.3
        )
        ax2.set_ylabel('Drawdown (%)')
        ax2.set_xlabel('Date')
        ax2.set_title('Drawdown')
        ax2.grid(True)

        plt.tight_layout()
        plt.show()
```

### 5.2 Performance Calculator

```python
class PerformanceCalculator:
    """Calculate performance metrics from backtest data."""

    @staticmethod
    def calculate_sharpe_ratio(
        returns: pd.Series,
        risk_free_rate: float = 0.0
    ) -> float:
        """
        Calculate annualized Sharpe ratio.

        Args:
            returns: Series of period returns
            risk_free_rate: Annual risk-free rate

        Returns:
            Annualized Sharpe ratio
        """
        excess_returns = returns - (risk_free_rate / 252)  # Daily adjustment
        return np.sqrt(252) * excess_returns.mean() / excess_returns.std()

    @staticmethod
    def calculate_sortino_ratio(
        returns: pd.Series,
        risk_free_rate: float = 0.0
    ) -> float:
        """Calculate Sortino ratio (downside deviation)."""
        excess_returns = returns - (risk_free_rate / 252)
        downside_returns = excess_returns[excess_returns < 0]
        downside_std = downside_returns.std()

        if downside_std == 0:
            return 0.0

        return np.sqrt(252) * excess_returns.mean() / downside_std

    @staticmethod
    def calculate_max_drawdown(equity_curve: pd.Series) -> Tuple[float, timedelta]:
        """
        Calculate maximum drawdown and duration.

        Returns:
            (max_drawdown_pct, duration)
        """
        cummax = equity_curve.cummax()
        drawdown = (equity_curve - cummax) / cummax

        max_dd = drawdown.min()

        # Find longest drawdown duration
        underwater = drawdown < 0
        groups = (underwater != underwater.shift()).cumsum()
        underwater_periods = underwater.groupby(groups).apply(
            lambda x: x.index[-1] - x.index[0] if x.any() else timedelta(0)
        )

        max_duration = underwater_periods.max()

        return max_dd, max_duration

    @staticmethod
    def calculate_win_rate(trades: pd.DataFrame) -> float:
        """Calculate percentage of winning trades."""
        if len(trades) == 0:
            return 0.0
        return (trades['pnl'] > 0).sum() / len(trades)

    @staticmethod
    def calculate_profit_factor(trades: pd.DataFrame) -> float:
        """Calculate profit factor (gross profit / gross loss)."""
        gross_profit = trades[trades['pnl'] > 0]['pnl'].sum()
        gross_loss = abs(trades[trades['pnl'] < 0]['pnl'].sum())

        if gross_loss == 0:
            return float('inf') if gross_profit > 0 else 0.0

        return gross_profit / gross_loss
```

---

## 6. Adapter Implementation

### 6.1 BacktestMarketDataPort

```python
class BacktestMarketDataPort(MarketDataPort):
    """Market data port for backtesting."""

    def __init__(
        self,
        data_provider: HistoricalDataProvider,
        clock: SimulatedClock
    ):
        self.data_provider = data_provider
        self.clock = clock
        self._current_ticks: Dict[InstrumentId, MarketTick] = {}
        self._current_bars: Dict[InstrumentId, Dict[BarGranularity, Bar]] = {}

    def update_state(self, event: HistoricalEvent) -> None:
        """Called by replayer to update current market state."""
        if isinstance(event, MarketDataEvent):
            self._current_ticks[event.tick.instrument_id] = event.tick
        elif isinstance(event, BarEvent):
            if event.bar.instrument_id not in self._current_bars:
                self._current_bars[event.bar.instrument_id] = {}
            self._current_bars[event.bar.instrument_id][event.bar.granularity] = event.bar

    def get_latest_tick(self, instrument_id: InstrumentId) -> Optional[MarketTick]:
        """Return current tick from replay state."""
        return self._current_ticks.get(instrument_id)

    def get_latest_bar(
        self,
        instrument_id: InstrumentId,
        granularity: BarGranularity
    ) -> Optional[Bar]:
        """Return current bar from replay state."""
        return self._current_bars.get(instrument_id, {}).get(granularity)

    def lookup_history(
        self,
        instrument_id: InstrumentId,
        window: HistoryWindow
    ) -> List[Bar]:
        """Fetch historical bars (for indicator warmup)."""
        end_time = self.clock.now()
        start_time = end_time - timedelta(days=window.count)  # Simplified

        return self.data_provider.get_bars(
            instrument_id,
            start_time,
            end_time,
            window.granularity
        )
```

---

## Summary

This backtesting engine design provides:

- ✅ **Deterministic replay** of historical data
- ✅ **High-fidelity execution simulation** with slippage/commissions
- ✅ **Framework-agnostic** strategies run unmodified
- ✅ **Comprehensive performance analytics** with standard metrics
- ✅ **Auditability** through complete event logging
- ✅ **Extensible models** for slippage, commission, latency

**Next**: See `PAPER_TRADING.md` for simulated live trading design.