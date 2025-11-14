# Paper Trading Design

## Overview

Paper trading provides simulated live trading with real-time market data but simulated execution. It validates strategies in market conditions without capital risk, serving as the final step before live deployment.

## Architecture

```
Real-Time Market Data → PaperTradingAdapter → Strategy
                              ↓
                    Simulated Execution
                              ↓
                    Simulated Portfolio
```

### Key Differences from Backtesting

| Aspect | Backtesting | Paper Trading |
|--------|-------------|---------------|
| Clock | Simulated (historical) | Real-time system clock |
| Data | Historical replay | Live market data streams |
| Execution | Instant simulation | Realistic delay simulation |
| Purpose | Historical validation | Real-time validation |

## Implementation

### PaperTradingAdapter

```python
class PaperTradingAdapter(FrameworkAdapter):
    """
    Adapter for paper trading with live data but simulated execution.
    """

    def __init__(
        self,
        config: PaperTradingConfig,
        market_data_provider: LiveDataProvider,
        execution_simulator: ExecutionSimulator
    ):
        self.config = config
        self.market_data_provider = market_data_provider
        self.execution_simulator = execution_simulator

        # Real-time clock
        self.clock = RealTimeClock()

        # Simulated portfolio
        self.portfolio = SimulatedPortfolio(
            initial_capital=config.initial_capital
        )

        # Track simulated orders
        self._pending_orders: Dict[UUID, PendingOrder] = {}

    def create_market_data_port(self) -> MarketDataPort:
        """Live market data."""
        return LiveMarketDataPort(self.market_data_provider)

    def create_execution_port(self) -> OrderExecutionPort:
        """Simulated execution with live data."""
        return PaperExecutionPort(
            simulator=self.execution_simulator,
            portfolio=self.portfolio,
            market_data=self.market_data_provider
        )
```

### PaperExecutionPort

```python
class PaperExecutionPort(OrderExecutionPort):
    """
    Simulates order execution using live market prices.
    """

    def submit_order(self, intent: TradeIntent) -> OrderTicket:
        """
        Simulate order submission.
        - Validates order against paper portfolio
        - Simulates fill with current market price + slippage
        - Updates simulated portfolio
        """
        # Risk checks against simulated portfolio
        if not self._can_afford(intent):
            raise InsufficientCapitalError()

        # Create ticket
        ticket_id = uuid4()

        # Simulate fill delay (e.g., 100ms)
        fill_delay = timedelta(milliseconds=100)

        # Schedule simulated fill
        self._schedule_fill(ticket_id, intent, fill_delay)

        return OrderTicket(
            ticket_id=ticket_id,
            intent=intent,
            status=OrderStatus.SUBMITTED,
            fills=[],
            last_update=datetime.now(timezone.utc),
            adapter_metadata={"mode": "paper"}
        )

    def _schedule_fill(
        self,
        ticket_id: UUID,
        intent: TradeIntent,
        delay: timedelta
    ) -> None:
        """
        Schedule simulated fill after delay.
        Uses asyncio for non-blocking execution.
        """
        async def delayed_fill():
            await asyncio.sleep(delay.total_seconds())

            # Get current market price
            current_price = self.market_data.get_latest_tick(
                intent.legs[0].instrument_id
            )

            # Simulate fill
            fill = self.simulator.simulate_fill(
                intent=intent,
                market_price=current_price,
                timestamp=datetime.now(timezone.utc)
            )

            # Update portfolio
            self.portfolio.apply_fill(fill)

            # Notify strategy
            self._notify_fill(ticket_id, fill)

        asyncio.create_task(delayed_fill())
```

## Shadow Mode

Shadow mode runs paper trading parallel to live trading for validation:

```python
class ShadowModeRunner:
    """
    Runs strategy in parallel:
    - Live adapter executes real orders
    - Paper adapter simulates same strategy
    - Compares signals and performance
    """

    def __init__(
        self,
        live_adapter: LiveAdapter,
        paper_adapter: PaperTradingAdapter,
        strategy_class: Type[Strategy]
    ):
        self.live_strategy = strategy_class(..., adapter=live_adapter)
        self.paper_strategy = strategy_class(..., adapter=paper_adapter)
        self.comparator = SignalComparator()

    def on_market_data(self, tick: MarketTick) -> None:
        """Dispatch to both strategies."""
        live_signals = self.live_strategy.on_market_data(tick)
        paper_signals = self.paper_strategy.on_market_data(tick)

        # Compare
        divergence = self.comparator.compare(live_signals, paper_signals)
        if divergence:
            self._alert_divergence(divergence)
```

## Summary

- ✅ Real-time market data
- ✅ Simulated execution with realistic delays
- ✅ Risk-free validation before live deployment
- ✅ Shadow mode for live comparison

**Next**: `LIVE_TRADING.md`
