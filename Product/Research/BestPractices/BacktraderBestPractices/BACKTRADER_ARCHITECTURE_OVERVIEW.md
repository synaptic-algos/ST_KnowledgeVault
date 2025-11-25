---
artifact_type: story
created_at: '2025-11-25T16:23:21.883225Z'
id: AUTO-BACKTRADER_ARCHITECTURE_OVERVIEW
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for BACKTRADER_ARCHITECTURE_OVERVIEW
updated_at: '2025-11-25T16:23:21.883229Z'
---

## Architecture Overview

Backtrader uses an **event-driven architecture** for realistic backtesting simulation.

### Core Architecture

```
Cerebro Engine (Orchestrator)
    ├── Data Feeds (Multiple timeframes, multiple instruments)
    ├── Strategy (Trading logic)
    ├── Broker (Order execution simulation)
    ├── Indicators (Technical analysis)
    └── Analyzers (Performance metrics)
```

---

## Core Components

### 1. Cerebro Engine

**Purpose**: Main orchestrator that runs the backtest

```python
import backtrader as bt

cerebro = bt.Cerebro()
cerebro.addstrategy(MyStrategy)
cerebro.adddata(data_feed)
cerebro.broker.setcash(100000.0)
cerebro.run()
```

**Comparison**:
- Nautilus: `BacktestEngine`
- SynapticTrading: `BacktestAdapter`

### 2. Data Feeds

**Purpose**: Historical data sources with multiple timeframe support

```python
# CSV data feed
data = bt.feeds.GenericCSVData(
    dataname='data.csv',
    datetime=0,
    open=1,
    high=2,
    low=3,
    close=4,
    volume=5,
    openinterest=-1
)

cerebro.adddata(data)
```

**Features**:
- Multiple data formats (CSV, Pandas, real-time feeds)
- Multiple timeframes simultaneously (1min, 5min, daily)
- Multiple instruments in single backtest

**Comparison**:
- Nautilus: `ParquetDataCatalog`
- SynapticTrading: `ParquetDataProvider` (STORY-006)

### 3. Strategy

**Purpose**: Trading logic with lifecycle hooks

```python
class MyStrategy(bt.Strategy):
    def __init__(self):
        # Initialize indicators
        self.sma = bt.indicators.SMA(self.data.close, period=20)

    def start(self):
        # Called once at start
        print("Strategy started")

    def next(self):
        # Called for each bar
        if self.data.close[0] > self.sma[0]:
            self.buy()

    def notify_order(self, order):
        # Called when order status changes
        if order.status == order.Completed:
            print(f"Order completed: {order}")

    def stop(self):
        # Called once at end
        print("Strategy stopped")
```

**Lifecycle Hooks**:
- `__init__()` - Setup indicators
- `start()` - Initialization
- `prenext()` - Called before indicator warmup complete
- `next()` - Called for each bar (main logic)
- `notify_order()` - Order status updates
- `notify_trade()` - Trade completion
- `stop()` - Cleanup

**Comparison**:
- Nautilus: `Strategy` base class with `on_start()`, `on_bar()`, `on_stop()`
- SynapticTrading: Framework-agnostic strategy via port injection

### 4. Broker

**Purpose**: Simulated broker with realistic order execution

```python
# Configure broker
cerebro.broker.setcash(100000.0)
cerebro.broker.setcommission(commission=0.001)  # 0.1%

# Slippage
cerebro.broker.set_slippage_fixed(0.01)  # Fixed slippage
```

**Features**:
- Order types (Market, Limit, Stop, StopLimit)
- Commission simulation
- Slippage simulation
- Position tracking

**Comparison**:
- Nautilus: Built-in `ExecutionEngine` with order matching
- SynapticTrading: `ExecutionSimulator` (future STORY)

### 5. Indicators

**Purpose**: Technical indicators with automatic warmup

```python
class MyStrategy(bt.Strategy):
    def __init__(self):
        # Built-in indicators
        self.sma = bt.indicators.SMA(self.data.close, period=20)
        self.rsi = bt.indicators.RSI(self.data.close, period=14)

        # Custom indicator
        self.spread = self.data1.close - self.data0.close
```

**Features**:
- 100+ built-in indicators
- Automatic warmup period handling
- Indicator on indicator (composability)

**Comparison**:
- Nautilus: Limited built-in indicators, strategy-computed metrics
- SynapticTrading: Custom indicators via historical lookback

### 6. Analyzers

**Purpose**: Performance metrics and statistics

```python
cerebro.addanalyzer(bt.analyzers.SharpeRatio, _name='sharpe')
cerebro.addanalyzer(bt.analyzers.DrawDown, _name='drawdown')

results = cerebro.run()
sharpe = results[0].analyzers.sharpe.get_analysis()
drawdown = results[0].analyzers.drawdown.get_analysis()
```

**Built-in Analyzers**:
- SharpeRatio
- DrawDown
- TradeAnalyzer
- AnnualReturn

**Comparison**:
- Nautilus: `generate_account_report()`, `generate_order_fills_report()`
- SynapticTrading: `ResultsTrackerActor` pattern (future)

---

## Event-Driven Pattern

### Backtrader Event Flow

```
1. Data Bar Available
   ↓
2. Indicators Updated (automatic)
   ↓
3. Strategy.next() Called
   ↓
4. Strategy Submits Orders
   ↓
5. Broker Executes Orders
   ↓
6. Strategy.notify_order() Called
   ↓
7. Position Updated
   ↓
8. Strategy.notify_trade() Called (on trade close)
   ↓
9. Next Bar...
```

**Key Insight**: Events are synchronous and sequential (simpler than Nautilus async event bus)

---

## Data Feed Architecture

### Multiple Timeframes

```python
# 1-minute data
data_1min = bt.feeds.GenericCSVData(dataname='1min.csv')
cerebro.adddata(data_1min)

# 5-minute data
data_5min = bt.feeds.GenericCSVData(dataname='5min.csv')
cerebro.resampledata(data_1min, timeframe=bt.TimeFrame.Minutes, compression=5)

# Daily data
data_daily = bt.feeds.GenericCSVData(dataname='daily.csv')
cerebro.adddata(data_daily)
```

### Multiple Instruments

```python
# AAPL data
aapl_data = bt.feeds.GenericCSVData(dataname='aapl.csv', name='AAPL')
cerebro.adddata(aapl_data)

# GOOGL data
googl_data = bt.feeds.GenericCSVData(dataname='googl.csv', name='GOOGL')
cerebro.adddata(googl_data)

class MultiAssetStrategy(bt.Strategy):
    def __init__(self):
        # Access by index
        self.aapl = self.datas[0]
        self.googl = self.datas[1]
```

**Comparison**:
- Nautilus: Multiple data configs in `BacktestEngineConfig`
- SynapticTrading: Multi-instrument via `EventReplayer` (STORY-004)

---

## Strategy Lifecycle

### Initialization Phase

```python
def __init__(self):
    # Setup indicators (called once)
    self.sma = bt.indicators.SMA(self.data.close, period=20)
```

### Warmup Phase

```python
def prenext(self):
    # Called while indicators warm up (before min_period bars)
    # Usually do nothing, wait for indicators to be ready
    pass
```

### Main Loop Phase

```python
def next(self):
    # Called for each bar after warmup
    # Main trading logic here
    if self.data.close[0] > self.sma[0]:
        self.buy()
```

### Cleanup Phase

```python
def stop(self):
    # Called once at end
    # Print final results, export data, etc.
    print(f"Final portfolio value: {self.broker.getvalue()}")
```

**Comparison with SynapticTrading**:
```python
# Our design (similar lifecycle)
class MyStrategy:
    def start(self):
        # Initialization (like Backtrader start())
        pass

    def on_tick(self, tick):
        # Main logic (like Backtrader next())
        pass

    def stop(self):
        # Cleanup (like Backtrader stop())
        pass
```

---

## Order Execution Simulation

### Order Types

```python
# Market order
self.buy()                              # Buy 1 unit
self.buy(size=10)                       # Buy 10 units

# Limit order
self.buy(price=100.0, exectype=bt.Order.Limit)

# Stop order
self.buy(price=100.0, exectype=bt.Order.Stop)

# Bracket order (entry + stop + target)
self.buy_bracket(price=100.0, stopprice=95.0, limitprice=110.0)
```

### Order Notification

```python
def notify_order(self, order):
    if order.status in [order.Submitted, order.Accepted]:
        # Order submitted/accepted
        return

    if order.status == order.Completed:
        if order.isbuy():
            print(f"BUY executed: Price={order.executed.price}, Size={order.executed.size}")
        elif order.issell():
            print(f"SELL executed: Price={order.executed.price}, Size={order.executed.size}")

    elif order.status in [order.Canceled, order.Margin, order.Rejected]:
        print(f"Order canceled/margin/rejected")
```

**Comparison**:
- Nautilus: `on_order_filled()`, `on_order_rejected()` events
- SynapticTrading: `ExecutionSimulator` (future STORY)

---

## Comparison with Nautilus

| Feature | Backtrader | Nautilus |
|---------|-----------|----------|
| **Language** | Python | Python + Rust |
| **Architecture** | Synchronous event-driven | Async event-driven (message bus) |
| **Performance** | Moderate (pure Python) | High (Rust core) |
| **Data Feeds** | CSV, Pandas, real-time | Parquet catalog (native) |
| **Indicators** | 100+ built-in | Limited built-in |
| **Order Types** | Market, Limit, Stop, Bracket | Market, Limit, Stop, trailing |
| **Live Trading** | Broker integrations | Built-in paper/live support |
| **Learning Curve** | Moderate | Steep |
| **Community** | Large, mature | Growing |
| **Best For** | Quick backtesting, beginners | Production systems, advanced users |

---

## Comparison with SynapticTrading Design

### Architectural Alignment

**SynapticTrading follows patterns similar to both Nautilus and Backtrader**:

| Component | SynapticTrading | Backtrader | Nautilus |
|-----------|----------------|-----------|----------|
| **Orchestrator** | `BacktestAdapter` | `Cerebro` | `BacktestEngine` |
| **Data Provider** | `ParquetDataProvider` | `GenericCSVData` | `ParquetDataCatalog` |
| **Event Replay** | `EventReplayer` | Built-in loop | Built-in loop |
| **Strategy** | Port-based (framework-agnostic) | `bt.Strategy` base class | `Strategy` base class |
| **Clock** | `BacktestClockPort` | Internal timestamp | `Clock` component |
| **Market Data** | `BacktestMarketDataPort` | `self.data` access | `MarketDataEngine` |

### Key Differences

**1. Framework Independence** (SynapticTrading advantage):
```python
# SynapticTrading: Framework-agnostic via ports
class MyStrategy:
    def __init__(self, clock: ClockPort, market_data: MarketDataPort):
        self.clock = clock
        self.market_data = market_data

    # Works with ANY adapter (backtest, paper, live)
```

**2. Event-Driven Granularity**:
- **Backtrader**: Synchronous, bar-by-bar (simple)
- **Nautilus**: Async, tick-by-tick (complex)
- **SynapticTrading**: Flexible (tick or bar, via EventReplayer)

**3. Indicator Approach**:
- **Backtrader**: Built-in indicators (100+)
- **Nautilus**: Strategy-computed
- **SynapticTrading**: Strategy-computed via historical lookback

---

## Best Practices

### 1. Avoid Overfitting

**Problem**: Optimizing strategy parameters too closely to historical data

**Solution**:
- Use walk-forward optimization
- Test on out-of-sample data
- Limit optimization parameters (< 5 parameters)

### 2. Indicator Warmup

**Problem**: Indicators need historical data before producing valid signals

**Backtrader Solution**:
```python
def prenext(self):
    # Wait for indicators to warm up
    pass

def next(self):
    # Indicators are ready here
    if self.sma[0] > self.ema[0]:
        self.buy()
```

**SynapticTrading Solution**:
```python
# Use historical lookback via MarketDataPort
bars = self.market_data.get_historical_bars(
    instrument_id,
    start_time - warmup_period,
    start_time,
    interval
)
# Warmup indicators manually
```

### 3. Risk Management

**Position Sizing**:
```python
# Fixed size (not recommended)
self.buy(size=10)

# Percentage-based
cash = self.broker.getcash()
risk_pct = 0.02  # 2% per trade
size = (cash * risk_pct) / self.data.close[0]
self.buy(size=size)
```

### 4. Commission and Slippage

**Always Include**:
```python
cerebro.broker.setcommission(commission=0.001)  # 0.1%
cerebro.broker.set_slippage_fixed(0.01)         # 1 cent slippage
```

### 5. Multiple Timeframes

**Example**:
```python
class MultiTimeframeStrategy(bt.Strategy):
    def __init__(self):
        # 1-hour trend
        self.trend = bt.indicators.SMA(self.data1.close, period=20)

        # 15-minute entry signal
        self.signal = bt.indicators.CrossOver(
            self.data0.close,
            bt.indicators.SMA(self.data0.close, period=10)
        )

    def next(self):
        # Only trade if 1-hour trend is up
        if self.trend[0] > self.trend[-1]:
            if self.signal[0] == 1:  # Crossover happened
                self.buy()
```

---

## Key Takeaways for SynapticTrading

1. **Lifecycle Hooks Are Essential**
   - Our strategy needs `start()`, `stop()`, `on_tick()`/`on_bar()`
   - Indicator warmup must be handled explicitly

2. **Event-Driven Architecture Works**
   - Both Backtrader and Nautilus use event-driven patterns
   - Our EventReplayer aligns with this approach

3. **Multiple Timeframes/Instruments Are Standard**
   - ParquetDataProvider should support multi-instrument replay
   - EventReplayer should handle multiple timeframes

4. **Order Execution Simulation Is Complex**
   - Need realistic fill simulation (not instant fills)
   - Commission and slippage are critical for realistic results

5. **Framework-Agnostic Design Is Unique**
   - Backtrader and Nautilus lock you into their frameworks
   - Our port-based design offers flexibility

---

## References

**Backtrader**:
- Website: https://www.backtrader.com/
- GitHub: https://github.com/mementum/backtrader
- Documentation: https://www.backtrader.com/docu/

**Community Resources**:
- AlgoTrading101: Backtrader guides
- PyQuantNews: Backtrader tutorials

---

**Last Updated**: 2025-11-19
**Maintained By**: SynapticTrading Development Team
