---
artifact_type: story
created_at: '2025-11-25T16:23:21.820782Z'
id: AUTO-NAUTILUS-USER-GUIDE
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for NAUTILUS-USER-GUIDE
updated_at: '2025-11-25T16:23:21.820786Z'
---

## Introduction

### What is Nautilus Integration?

The Nautilus integration allows you to run your **domain strategies** on the **Nautilus Trader** backtesting engine without modifying your strategy code. Your strategies remain framework-agnostic and can run on multiple backtest engines.

### Key Benefits

✅ **No Strategy Changes**: Your existing strategies work without modification
✅ **High Performance**: Nautilus is optimized for speed (Rust/Cython core)
✅ **Consistent Interface**: Same API as custom backtest engine
✅ **Production Ready**: Nautilus is battle-tested in production
✅ **Rich Ecosystem**: Access to Nautilus data adapters and tools

### When to Use Nautilus

**Use Nautilus when:**
- You need faster backtests (>100K ticks/second)
- You want to validate custom engine results
- You need live trading capabilities later
- You want access to Nautilus data adapters

**Use Custom Engine when:**
- You need complete control over execution simulation
- You're prototyping new backtest features
- You need custom order matching logic

---

## Quick Start

### Installation

1. **Install Nautilus Trader**:
```bash
pip install nautilus-trader>=1.221.0
```

2. **Verify Installation**:
```bash
python -c "import nautilus_trader; print(nautilus_trader.__version__)"
```

### 5-Minute Example

```python
from datetime import datetime, timezone
from adapters.frameworks.nautilus.backtest_adapter import NautilusBacktestAdapter
from domain.strategy.aggregates.strategy import YourStrategy

# 1. Create your domain strategy (no changes needed!)
strategy = YourStrategy()

# 2. Configure backtest
config = BacktestConfig(
    start_date=datetime(2024, 1, 1, tzinfo=timezone.utc),
    end_date=datetime(2024, 12, 31, tzinfo=timezone.utc),
    initial_capital=100000.0,
    commission_bps=10,  # 0.10% commission
    min_commission=1.0
)

# 3. Create data provider
data_provider = YourDataProvider()  # Your historical data source

# 4. Create Nautilus adapter
adapter = NautilusBacktestAdapter(
    config=config,
    data_provider=data_provider
)

# 5. Run backtest
results = adapter.run(strategy)

# 6. Analyze results
print(f"Total PnL: ${results.statistics['total_pnl']:,.2f}")
print(f"Total Trades: {results.statistics['total_trades']}")
print(f"Final Value: ${results.statistics['final_portfolio_value']:,.2f}")
```

That's it! Your strategy now runs on Nautilus Trader.

---

## How It Works

### Architecture Overview

```
Your Domain Strategy
    ↓ (unchanged)
Port Interfaces (ClockPort, MarketDataPort, ExecutionPort)
    ↓ (adapter layer)
NautilusBacktestAdapter
    ↓ (orchestrates)
├── StrategyWrapper ─────► Wraps your strategy for Nautilus
├── ConfigMapper ────────► Converts your config to Nautilus format
├── Port Adapters ───────► Connect ports to Nautilus engines
└── EventTranslator ─────► Converts events between formats
    ↓
Nautilus Trader Framework
```

### What Happens During a Backtest

1. **Configuration Mapping**:
   - Your `BacktestConfig` → Nautilus `BacktestEngineConfig`
   - Commission BPS → Nautilus fee model
   - Initial capital → Nautilus venue balance

2. **Strategy Wrapping**:
   - Your strategy wrapped in `NautilusStrategyWrapper`
   - Wrapper inherits from Nautilus `Strategy`
   - Your methods (`on_tick`, `on_bar`) called automatically

3. **Port Injection**:
   - Nautilus clock injected as `ClockPort`
   - Nautilus data engine injected as `MarketDataPort`
   - Nautilus execution engine injected as `ExecutionPort`

4. **Event Translation**:
   - Nautilus events → Domain events (automatic)
   - Your strategy sees only domain types
   - Results converted back to domain format

### Framework Agnosticism

Your strategy code remains **100% framework-agnostic**:

```python
# ✅ Your strategy code (framework-agnostic)
class MyStrategy:
    def on_tick(self, tick: MarketTick):
        # Works on ANY backtest engine
        if tick.price > self.threshold:
            self.execution.submit_order(...)
```

No references to Nautilus anywhere in your strategy!

---

## Basic Usage

### Step 1: Write Your Strategy (Framework-Agnostic)

```python
from domain.shared.value_objects import MarketTick, InstrumentId
from application.ports.execution_port import OrderSide, OrderType

class SimpleMovingAverageStrategy:
    """
    Example strategy that works on ANY backtest engine.
    No Nautilus dependencies!
    """

    def __init__(self):
        self.prices = []
        self.sma_period = 20
        self.position = 0

        # Port interfaces (injected by adapter)
        self.clock = None
        self.market_data = None
        self.execution = None

    def start(self):
        """Called when strategy starts."""
        print("Strategy started")

    def on_tick(self, tick: MarketTick):
        """Process market tick."""
        # Update price history
        self.prices.append(tick.price)
        if len(self.prices) > self.sma_period:
            self.prices.pop(0)

        # Calculate SMA
        if len(self.prices) == self.sma_period:
            sma = sum(self.prices) / self.sma_period

            # Trading logic
            if tick.price > sma and self.position <= 0:
                # Buy signal
                self.execution.submit_order(
                    instrument_id=tick.instrument_id,
                    side=OrderSide.BUY,
                    quantity=100,
                    order_type=OrderType.MARKET
                )
                self.position = 100

            elif tick.price < sma and self.position >= 0:
                # Sell signal
                self.execution.submit_order(
                    instrument_id=tick.instrument_id,
                    side=OrderSide.SELL,
                    quantity=100,
                    order_type=OrderType.MARKET
                )
                self.position = -100

    def stop(self):
        """Called when strategy stops."""
        print(f"Strategy stopped. Final position: {self.position}")
```

### Step 2: Configure Backtest

```python
from datetime import datetime, timezone

# Create backtest configuration
config = BacktestConfig(
    # Time range
    start_date=datetime(2024, 1, 1, tzinfo=timezone.utc),
    end_date=datetime(2024, 12, 31, tzinfo=timezone.utc),

    # Capital
    initial_capital=100000.0,

    # Costs
    commission_bps=10,      # 0.10% commission per trade
    min_commission=1.0,     # Minimum $1 commission
    slippage_bps=5,         # 0.05% slippage
)
```

### Step 3: Setup Data Provider

```python
# Use your existing data provider
data_provider = ParquetDataProvider(
    data_path="/path/to/market/data",
    instruments=["AAPL", "MSFT", "GOOGL"]
)

# Or mock provider for testing
data_provider = MockDataProvider(
    instruments=["AAPL"],
    start_date=config.start_date,
    end_date=config.end_date
)
```

### Step 4: Run Backtest

```python
from adapters.frameworks.nautilus.backtest_adapter import NautilusBacktestAdapter

# Create adapter
adapter = NautilusBacktestAdapter(
    config=config,
    data_provider=data_provider
)

# Create strategy
strategy = SimpleMovingAverageStrategy()

# Run backtest
results = adapter.run(strategy)
```

---

## Configuration Options

### BacktestConfig Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `start_date` | `datetime` | Backtest start time (UTC) | `datetime(2024, 1, 1, tzinfo=timezone.utc)` |
| `end_date` | `datetime` | Backtest end time (UTC) | `datetime(2024, 12, 31, tzinfo=timezone.utc)` |
| `initial_capital` | `float` | Starting capital ($) | `100000.0` |
| `commission_bps` | `int` | Commission in basis points | `10` (= 0.10%) |
| `min_commission` | `float` | Minimum commission ($) | `1.0` |
| `slippage_bps` | `int` | Slippage in basis points | `5` (= 0.05%) |

### Commission Examples

```python
# Low commission (discount broker)
config.commission_bps = 5       # 0.05%
config.min_commission = 0.5     # $0.50 minimum

# Standard commission
config.commission_bps = 10      # 0.10%
config.min_commission = 1.0     # $1.00 minimum

# High commission (full-service broker)
config.commission_bps = 30      # 0.30%
config.min_commission = 5.0     # $5.00 minimum

# Zero commission (free trading)
config.commission_bps = 0       # 0%
config.min_commission = 0.0     # $0 minimum
```

### Time Range Best Practices

```python
# ✅ GOOD: Specific time range
start_date = datetime(2024, 1, 1, tzinfo=timezone.utc)
end_date = datetime(2024, 12, 31, tzinfo=timezone.utc)

# ✅ GOOD: Recent period
from datetime import timedelta
end_date = datetime.now(timezone.utc)
start_date = end_date - timedelta(days=365)

# ❌ BAD: Naive datetime (no timezone)
start_date = datetime(2024, 1, 1)  # Missing timezone!
```

---

## Running Backtests

### Running a Single Backtest

```python
# Standard backtest run
results = adapter.run(strategy)

# Print summary
print(f"Backtest completed:")
print(f"  Total PnL: ${results.statistics['total_pnl']:,.2f}")
print(f"  Return: {results.statistics['return_pct']:.2f}%")
print(f"  Total Trades: {results.statistics['total_trades']}")
```

### Running Multiple Strategies

```python
strategies = [
    SimpleMovingAverageStrategy(),
    BollingerBandStrategy(),
    RSIStrategy()
]

results_list = []
for strategy in strategies:
    # Create fresh adapter for each run
    adapter = NautilusBacktestAdapter(config, data_provider)
    results = adapter.run(strategy)
    results_list.append(results)

# Compare results
for i, results in enumerate(results_list):
    print(f"Strategy {i+1}: PnL = ${results.statistics['total_pnl']:,.2f}")
```

### Running Parameter Sweeps

```python
# Test different SMA periods
sma_periods = [10, 20, 30, 50, 100]
best_pnl = -float('inf')
best_period = None

for period in sma_periods:
    strategy = SimpleMovingAverageStrategy()
    strategy.sma_period = period

    adapter = NautilusBacktestAdapter(config, data_provider)
    results = adapter.run(strategy)

    pnl = results.statistics['total_pnl']
    if pnl > best_pnl:
        best_pnl = pnl
        best_period = period

    print(f"Period {period}: PnL = ${pnl:,.2f}")

print(f"\nBest period: {best_period} (PnL: ${best_pnl:,.2f})")
```

---

## Interpreting Results

### Results Structure

```python
results = adapter.run(strategy)

# Available attributes
results.config           # BacktestConfig used
results.statistics       # Dictionary of statistics
```

### Standard Statistics

```python
statistics = results.statistics

# Performance metrics
total_pnl = statistics['total_pnl']              # Total profit/loss ($)
return_pct = statistics['return_pct']            # Return percentage
final_value = statistics['final_portfolio_value'] # Final portfolio value

# Trading metrics
total_trades = statistics['total_trades']        # Number of trades
realized_pnl = statistics['realized_pnl']        # Closed position P&L
unrealized_pnl = statistics['unrealized_pnl']    # Open position P&L

# Capital
initial_capital = statistics['initial_capital']  # Starting capital
```

### Example Analysis

```python
# Calculate key metrics
initial = results.statistics['initial_capital']
final = results.statistics['final_portfolio_value']
pnl = results.statistics['total_pnl']
trades = results.statistics['total_trades']

# Print report
print("=" * 50)
print("BACKTEST RESULTS")
print("=" * 50)
print(f"Initial Capital:    ${initial:>15,.2f}")
print(f"Final Value:        ${final:>15,.2f}")
print(f"Total PnL:          ${pnl:>15,.2f}")
print(f"Return:             {(pnl/initial)*100:>14.2f}%")
print(f"Total Trades:       {trades:>16}")
if trades > 0:
    print(f"Avg PnL per Trade:  ${pnl/trades:>15,.2f}")
print("=" * 50)
```

### Comparing with Custom Engine

```python
# Run on both engines
nautilus_results = nautilus_adapter.run(strategy1)
custom_results = custom_adapter.run(strategy2)

# Compare results
nautilus_pnl = nautilus_results.statistics['total_pnl']
custom_pnl = custom_results.statistics['total_pnl']

diff = abs(nautilus_pnl - custom_pnl)
diff_pct = (diff / abs(custom_pnl)) * 100

print(f"Nautilus PnL: ${nautilus_pnl:,.2f}")
print(f"Custom PnL:   ${custom_pnl:,.2f}")
print(f"Difference:   ${diff:,.2f} ({diff_pct:.2f}%)")

# Should be very close (< 0.01% difference)
assert diff_pct < 0.01, "Results diverge too much!"
```

---

## Best Practices

### 1. Keep Strategies Framework-Agnostic

```python
# ✅ GOOD: Framework-agnostic
class MyStrategy:
    def on_tick(self, tick: MarketTick):
        # Uses port interfaces only
        self.execution.submit_order(...)

# ❌ BAD: Nautilus-specific
class MyStrategy:
    def on_tick(self, nautilus_tick):
        # Direct Nautilus dependency
        self.submit_order(...)  # Nautilus method
```

### 2. Always Use UTC Timestamps

```python
# ✅ GOOD: UTC timezone
from datetime import timezone
start = datetime(2024, 1, 1, tzinfo=timezone.utc)

# ❌ BAD: Naive datetime
start = datetime(2024, 1, 1)  # No timezone!
```

### 3. Validate Data Quality

```python
# Check data provider has data
data_count = data_provider.get_data_count(
    start=config.start_date,
    end=config.end_date
)

if data_count == 0:
    raise ValueError("No data available for date range!")

print(f"Found {data_count:,} data points")
```

### 4. Handle Missing Data Gracefully

```python
def on_tick(self, tick: MarketTick):
    # Check if we have data
    if tick is None:
        return

    # Check for valid prices
    if tick.price <= 0:
        return

    # Your trading logic
    ...
```

### 5. Test with Small Date Ranges First

```python
# Start with 1 day
config.start_date = datetime(2024, 1, 1, tzinfo=timezone.utc)
config.end_date = datetime(2024, 1, 2, tzinfo=timezone.utc)

# Run quick test
results = adapter.run(strategy)

# Then expand to full range
config.end_date = datetime(2024, 12, 31, tzinfo=timezone.utc)
results = adapter.run(strategy)
```

### 6. Log Important Events

```python
class MyStrategy:
    def on_tick(self, tick: MarketTick):
        if self.should_buy(tick):
            print(f"[{self.clock.now()}] BUY signal at ${tick.price}")
            order_id = self.execution.submit_order(...)
            print(f"  Order submitted: {order_id}")
```

---

## Troubleshooting

### Issue: "No module named 'nautilus_trader'"

**Problem**: Nautilus not installed

**Solution**:
```bash
pip install nautilus-trader>=1.221.0
```

### Issue: "Strategy has no attribute 'clock'"

**Problem**: Ports not injected properly

**Solution**: Ensure adapter injects ports before running
```python
# Ports are injected automatically by adapter
results = adapter.run(strategy)  # Ports injected here
```

### Issue: "Backtest runs but no trades"

**Problem**: Strategy not receiving events

**Solution**: Check data provider
```python
# Verify data provider has data
data = data_provider.get_data(
    instrument="AAPL",
    start=config.start_date,
    end=config.end_date
)
print(f"Data points: {len(data)}")
```

### Issue: "Results differ from custom engine"

**Problem**: Different execution simulation

**Solution**: Check commission and slippage settings
```python
# Ensure same settings on both engines
config.commission_bps = 10
config.slippage_bps = 5
config.min_commission = 1.0
```

### Issue: "Backtest is very slow"

**Problem**: Large dataset or inefficient strategy

**Solution**:
1. Reduce date range for testing
2. Optimize strategy logic
3. Enable Nautilus performance mode (already enabled by default)

---

## FAQ

### Q: Do I need to change my existing strategies?

**A**: No! Your strategies remain 100% framework-agnostic. They work on both custom and Nautilus engines without any modifications.

### Q: Can I use Nautilus data adapters?

**A**: Yes! You can use Nautilus data adapters directly. See Admin Guide for details.

### Q: How fast is Nautilus compared to custom engine?

**A**: Nautilus is typically 2-3x faster for large datasets due to Rust/Cython optimization. For small tests, startup overhead may make it slightly slower.

### Q: Can I run live trading with this integration?

**A**: Not yet. Current integration supports backtesting only. Live trading support is planned for a future sprint.

### Q: What Nautilus version is required?

**A**: Nautilus Trader >= 1.221.0

### Q: How do I report bugs?

**A**: File an issue in the repository with:
- Strategy code (minimal reproducible example)
- Configuration used
- Expected vs actual behavior
- Error messages/stack traces

### Q: Can I use custom order types?

**A**: Currently supports: MARKET, LIMIT, STOP, STOP_LIMIT. Other order types coming in future releases.

### Q: Does this work with options strategies?

**A**: Basic options support exists. Full options support (Greeks, spreads) coming in future releases.

---

## Next Steps

1. **Try the Quick Start example** above
2. **Run your existing strategies** on Nautilus
3. **Compare results** with custom engine
4. **Report any issues** you encounter
5. **Share feedback** on what works well

For advanced configuration and troubleshooting, see the [Admin Guide](./NAUTILUS-ADMIN-GUIDE.md).

---

**Questions?** Contact the platform team or file an issue in the repository.
