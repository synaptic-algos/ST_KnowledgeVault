---
? SynapticTrading provides powerful backtesting capabilities to validate trading strategies
  before deploying them with real capital. Our platform supports **two backtesting
  engines**
: null
artifact_type: story
created_at: '2025-11-25T16:23:21.791699Z'
id: AUTO-backtesting
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for backtesting
updated_at: '2025-11-25T16:23:21.791703Z'
---

## Quick Start

### Running a Backtest

```python
from datetime import datetime, timezone
from adapters.frameworks.backtest import BacktestConfig
from adapters.frameworks.backtest.data_providers import ParquetDataProvider

# 1. Configure backtest
config = BacktestConfig(
    start_date=datetime(2024, 1, 1, tzinfo=timezone.utc),
    end_date=datetime(2024, 12, 31, tzinfo=timezone.utc),
    initial_capital=100_000.0,
    commission_bps=10,  # 0.10% per trade
    slippage_bps=5      # 0.05% slippage
)

# 2. Set up data source
data_provider = ParquetDataProvider(catalog_path="data/")

# 3. Choose engine (Custom or Backtrader)
from adapters.frameworks.backtest import BacktestEngine
# OR
from adapters.frameworks.backtrader import BacktraderBacktestAdapter

# 4. Create adapter
adapter = BacktraderBacktestAdapter(
    config=config,
    data_provider=data_provider,
    instrument_id="AAPL"
)

# 5. Run backtest
results = adapter.run(your_strategy)

# 6. View results
print(f"Return: {results.statistics['return_pct']:.2f}%")
print(f"Sharpe Ratio: {results.statistics['sharpe_ratio']:.2f}")
print(f"Max Drawdown: {results.statistics['max_drawdown']:.2f}%")
```

---

## Choosing an Engine

### Custom Engine

**Use When:**
- You need multi-asset portfolio strategies
- You need custom slippage models
- You need tick-level precision
- You need advanced order types (limit, stop, trailing stop)
- You need millisecond-level timing accuracy

**Advantages:**
- Full control over execution simulation
- Multi-asset support
- Custom commission and slippage models
- Advanced order types
- Optimized for our domain model

### Backtrader Engine

**Use When:**
- You want to validate results against a proven framework
- You need access to Backtrader's indicator library
- You want to leverage Backtrader's community resources
- You need standard backtesting with proven reliability
- You want cross-engine validation

**Advantages:**
- Battle-tested framework with large community
- Rich ecosystem of indicators and analyzers
- Industry-standard results
- Excellent for validation and benchmarking
- Faster execution for single-asset strategies

### Cross-Engine Validation

For maximum confidence, run your strategy on **both engines**:

```python
# Run on Custom Engine
from adapters.frameworks.backtest import BacktestEngine
custom_adapter = BacktestEngine(config, data_provider)
custom_results = custom_adapter.run(strategy)

# Run on Backtrader Engine
from adapters.frameworks.backtrader import BacktraderBacktestAdapter
bt_adapter = BacktraderBacktestAdapter(config, data_provider, "AAPL")
bt_results = bt_adapter.run(strategy)

# Compare results
print(f"Custom Engine Return: {custom_results.statistics['return_pct']:.2f}%")
print(f"Backtrader Return:    {bt_results.statistics['return_pct']:.2f}%")

divergence = abs(custom_results.statistics['return_pct'] - bt_results.statistics['return_pct'])
print(f"Divergence: {divergence:.4f}%")
```

**Expected Divergence**: < 0.01% (Results should match within 0.01%)

---

## Understanding Results

### Results Structure

Every backtest returns a `BacktestResults` object with:

```python
results.config          # BacktestConfig used
results.portfolio       # Portfolio state
results.statistics      # Performance metrics dictionary
```

### Key Performance Metrics

#### Returns
- **`final_portfolio_value`**: Portfolio value at end of backtest
- **`total_pnl`**: Total profit/loss in dollars
- **`return_pct`**: Return percentage over backtest period

#### Risk Metrics
- **`sharpe_ratio`**: Risk-adjusted return (higher is better)
- **`max_drawdown`**: Maximum peak-to-trough decline (%)
- **`max_drawdown_duration`**: Length of maximum drawdown (bars)

#### Trading Activity
- **`total_trades`**: Total number of completed trades
- **`winning_trades`**: Number of profitable trades
- **`losing_trades`**: Number of losing trades
- **`win_rate`**: Percentage of winning trades
- **`profit_factor`**: Ratio of gross profit to gross loss

### Interpreting Metrics

**Good Performance Indicators**:
- Return % > 0 (positive returns)
- Sharpe Ratio > 1.0 (good risk-adjusted returns)
- Sharpe Ratio > 2.0 (excellent risk-adjusted returns)
- Max Drawdown < 20% (manageable risk)
- Win Rate > 50% (more winners than losers)
- Profit Factor > 1.5 (profits exceed losses)

**Warning Signs**:
- Sharpe Ratio < 0.5 (poor risk-adjusted returns)
- Max Drawdown > 30% (high risk)
- Win Rate < 40% (many losing trades)
- Profit Factor < 1.0 (losses exceed profits)

---

## Configuration Options

### BacktestConfig Parameters

```python
BacktestConfig(
    # Time Range (Required)
    start_date=datetime(2024, 1, 1, tzinfo=timezone.utc),
    end_date=datetime(2024, 12, 31, tzinfo=timezone.utc),

    # Capital (Required)
    initial_capital=100_000.0,

    # Currency (Optional, default: "USD")
    base_currency="USD",

    # Trading Costs (Optional)
    commission_bps=10,    # Basis points (10 = 0.10%)
    slippage_bps=5,       # Basis points (5 = 0.05%)
    min_commission=1.0    # Minimum commission per trade ($1)
)
```

### Commission Calculation

Commission is calculated as a percentage of trade value:

**Formula**: `commission = trade_value × (commission_bps / 10,000)`

**Examples**:
- Trade value: $10,000, Commission: 10 BPS → $10 commission
- Trade value: $1,000, Commission: 10 BPS → $1 commission
- Trade value: $100, Commission: 10 BPS, Min: $1 → $1 commission (minimum applied)

### Slippage Calculation

Slippage simulates the difference between expected and actual fill prices:

**Formula**: `slippage = order_size × price × (slippage_bps / 10,000)`

**Note**: Backtrader engine does not natively support slippage (config accepted but not applied).

---

## Common Use Cases

### Single Instrument Backtest

```python
config = BacktestConfig(
    start_date=datetime(2024, 1, 1, tzinfo=timezone.utc),
    end_date=datetime(2024, 12, 31, tzinfo=timezone.utc),
    initial_capital=100_000.0
)

data_provider = ParquetDataProvider(catalog_path="data/")

adapter = BacktraderBacktestAdapter(
    config=config,
    data_provider=data_provider,
    instrument_id="AAPL"
)

results = adapter.run(strategy)
```

### Multiple Instruments (Sequential)

```python
instruments = ["AAPL", "GOOGL", "MSFT", "TSLA"]
results_dict = {}

for instrument in instruments:
    adapter = BacktraderBacktestAdapter(
        config=config,
        data_provider=data_provider,
        instrument_id=instrument
    )

    results = adapter.run(strategy)
    results_dict[instrument] = results

    print(f"{instrument}: {results.statistics['return_pct']:.2f}%")
```

### Parameter Optimization

```python
# Test different strategy parameters
position_sizes = [100, 500, 1000, 5000]
best_sharpe = -float('inf')
best_params = None

for size in position_sizes:
    strategy = MyStrategy(position_size=size)
    results = adapter.run(strategy)

    if results.statistics['sharpe_ratio'] > best_sharpe:
        best_sharpe = results.statistics['sharpe_ratio']
        best_params = {'position_size': size}

print(f"Best parameters: {best_params}")
print(f"Best Sharpe: {best_sharpe:.2f}")
```

---

## Best Practices

### Data Quality

✅ **Do**:
- Use clean, validated historical data
- Ensure no gaps in data feed
- Verify data timezone (must be UTC)
- Check for survivorship bias
- Validate data against multiple sources

❌ **Don't**:
- Use forward-looking data (lookahead bias)
- Use uncleaned data with errors
- Mix data from different sources without validation
- Ignore corporate actions (splits, dividends)

### Strategy Development

✅ **Do**:
- Start simple, add complexity gradually
- Test on out-of-sample data
- Use walk-forward analysis
- Cross-validate with multiple engines
- Document strategy logic and assumptions

❌ **Don't**:
- Overfit to historical data
- Use only in-sample testing
- Ignore transaction costs
- Assume backtest results guarantee future performance
- Deploy without paper trading validation

### Performance Analysis

✅ **Do**:
- Analyze multiple time periods
- Compare to benchmarks (S&P 500, etc.)
- Consider risk-adjusted returns
- Evaluate worst-case scenarios
- Test during different market conditions

❌ **Don't**:
- Focus only on total return
- Ignore drawdown and volatility
- Cherry-pick best time periods
- Overlook trading costs
- Ignore practical constraints (liquidity, slippage)

---

## Troubleshooting

### Common Issues

#### Issue 1: "ModuleNotFoundError: backtrader"

**Solution**:
```bash
pip install backtrader
```

#### Issue 2: "Datetime must be UTC-aware"

**Solution**: Ensure all datetimes use `timezone.utc`:
```python
from datetime import timezone
start_date = datetime(2024, 1, 1, tzinfo=timezone.utc)  # ✅ Correct
start_date = datetime(2024, 1, 1)  # ❌ Wrong (naive datetime)
```

#### Issue 3: No trades executed

**Possible Causes**:
- Strategy logic never triggers buy/sell
- Insufficient capital for trades
- Data feed empty or corrupted

**Debugging**:
```python
# Add logging to strategy
def on_tick(self, tick):
    print(f"Tick received: {tick.timestamp} - ${tick.price}")
    # Strategy logic...
```

#### Issue 4: Results differ between engines

**Expected**: Results should match within 0.01%

**If divergence > 0.01%**:
- Check data alignment (same date range, same bars)
- Verify commission/slippage settings match
- Ensure timezone handling consistent
- Review order execution timing differences

---

## Additional Resources

### Documentation
- **Full User Guide**: `documentation/guides/BACKTRADER-INTEGRATION-USER-GUIDE.md`
- **Admin Guide**: `documentation/guides/BACKTRADER-ADMIN-GUIDE.md`
- **API Reference**: Generated from code docstrings

### Examples
- **Hello World Example**: `examples/backtrader_hello_world.py`
- **Strategy Catalog**: `strategies/` directory
- **Integration Tests**: `tests/frameworks/backtrader/integration/`

### External Resources
- **Backtrader Documentation**: https://www.backtrader.com/
- **Backtrader Community**: https://community.backtrader.com/

---

## Getting Help

For questions or issues:
1. Check [Troubleshooting](#troubleshooting) section
2. Review documentation guides
3. Check integration tests for examples
4. Consult Admin Guide for advanced debugging

---

**Last Updated**: 2025-11-20
**Version**: 1.0
**Status**: Production Ready
