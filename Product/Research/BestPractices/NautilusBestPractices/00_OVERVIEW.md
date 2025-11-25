---
artifact_type: story
created_at: '2025-11-25T16:23:21.872368Z'
id: AUTO-00_OVERVIEW
manual_update: 'true'
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: '001'
status: pending
title: Auto-generated title for 00_OVERVIEW
updated_at: '2025-11-25T16:23:21.872371Z'
---

## What is NautilusTrader?

NautilusTrader is a high-performance algorithmic trading platform built with Python and Rust that provides:

- **Event-driven architecture**: Message-based communication between components
- **Multi-environment support**: Same code works in Backtest, Sandbox (paper), and Live modes
- **High performance**: Rust core with Python bindings for speed
- **Built-in components**: Data management, order execution, risk management
- **Type safety**: Strong typing with msgspec for serialization

**Official Documentation**: https://nautilustrader.io/docs/latest/

---

## Core Nautilus Concepts

### 1. Actor Pattern

**Actors** are the fundamental building blocks in Nautilus - components that:
- React to events via message bus
- Can maintain state
- Work across all environments (backtest/paper/live)
- Examples: Custom indicators, risk managers, capital managers

```python
from nautilus_trader.trading.strategy import Actor

class CapitalManager(Actor):
    """
    Manages capital allocation across environments.
    Works in backtest, paper, and live trading.
    """
    def __init__(self, config):
        super().__init__()
        self.current_capital = config.initial_capital

    def on_start(self):
        """Called when actor starts in any environment"""
        self.register_indicator_for_quote_ticks(...)

    def on_event(self, event):
        """Process events from message bus"""
        if isinstance(event, PositionClosed):
            self.update_capital(event.realized_pnl)
```

**Key Advantage**: Write once, works everywhere (backtest/paper/live).

---

### 2. Strategy vs Actor

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| **Strategy** | Trading logic, order placement | Main trading algorithm |
| **Actor** | Supporting functionality, state management | Capital management, custom indicators, risk monitors |

**Our Use Case**:
- `OptionsSpreadStrategyModular` → Should be a Nautilus **Strategy**
- `CapitalManager` → Should be a Nautilus **Actor**
- `EntryManager`, `ExitManager` → Can be plain Python classes (used by Strategy)
- `PositionManager` → Should integrate with Nautilus `Portfolio` component

---

### 3. Environment Contexts

Nautilus provides three execution environments with **same API**:

```python
# Backtesting
from nautilus_trader.backtest.engine import BacktestEngine
engine = BacktestEngine()
engine.add_strategy(OptionsSpreadStrategyModular)
engine.add_actor(CapitalManager)  # Same actor works here...
engine.run()

# Paper Trading (Sandbox)
from nautilus_trader.live.node import TradingNode
node = TradingNode()
node.add_strategy(OptionsSpreadStrategyModular)
node.add_actor(CapitalManager)  # ...and here...
node.start()

# Live Trading
node = TradingNode(environment=Environment.LIVE)
node.add_strategy(OptionsSpreadStrategyModular)
node.add_actor(CapitalManager)  # ...and here!
node.start()
```

**Key Advantage**: Write code once, test in backtest, validate in paper, deploy to live.

---

### 4. Message Bus & Events

All communication happens via **message bus** with typed events:

```python
# Core events (built-in)
OrderInitialized
OrderFilled
OrderCanceled
PositionOpened
PositionChanged
PositionClosed
AccountState

# Custom events (you define)
class CapitalUpdated(Event):
    """Capital changed after trade"""
    def __init__(self, new_capital: float, trade_pnl: float):
        self.new_capital = new_capital
        self.trade_pnl = trade_pnl
```

**Event Flow**:
1. Strategy places order → `OrderInitialized` event
2. Execution engine fills order → `OrderFilled` event
3. Position manager updates → `PositionChanged` event
4. Capital manager reacts → `CapitalUpdated` event
5. Risk manager validates → checks against new capital

---

### 5. Data Management

Nautilus has built-in data engines for market data:

```python
# Instead of custom data_provider interface:
from nautilus_trader.data.engine import DataEngine

class OptionsSpreadStrategyModular(Strategy):
    def on_start(self):
        # Subscribe to market data
        self.subscribe_quote_ticks(instrument_id)
        self.subscribe_bars(bar_type)

    def on_quote_tick(self, tick: QuoteTick):
        """Called automatically when new tick arrives"""
        self.process_market_data(tick)

    def on_bar(self, bar: Bar):
        """Called automatically when new bar closes"""
        self.check_entry_conditions(bar)
```

**Key Advantage**: No custom polling loop, framework delivers data via events.

---

## Current Architecture Analysis

### What We Have Now

```
src/strategy/
├── options_spread_strategy_modular.py  # Main strategy (custom class)
├── components/
│   ├── entry_manager.py                # Entry logic (plain Python)
│   ├── exit_manager.py                 # Exit logic (plain Python)
│   ├── position_manager.py             # Position tracking (plain Python)
│   └── risk_manager.py                 # Risk checks (plain Python)

src/backtest/
├── nautilus_parquet_v4_adapter.py      # Custom adapter (NOT Nautilus framework)
└── optimized_backtest_data_adapter.py  # Pickle cache loader

src/interfaces/
├── data_interface.py                   # Custom IDataProvider interface
├── execution_interface.py              # Custom IExecutionEngine interface
└── risk_interface.py                   # Custom IRiskManager interface
```

**Issues with Current Approach**:
1. ✅ **Good**: Modular separation of concerns
2. ✅ **Good**: Clear component responsibilities
3. ❌ **Bad**: Not using Nautilus framework (no cross-environment support)
4. ❌ **Bad**: Custom interfaces instead of Nautilus native objects
5. ❌ **Bad**: Manual data polling instead of event-driven
6. ❌ **Bad**: Components can't easily move between backtest/paper/live

---

### What We Should Have

```
src/strategy/
├── options_spread_strategy.py          # Nautilus Strategy subclass
├── actors/
│   ├── capital_manager.py              # Nautilus Actor (works everywhere)
│   └── spread_monitor.py               # Nautilus Actor for P&L tracking
├── components/
│   ├── entry_manager.py                # Helper class (used by Strategy)
│   ├── exit_manager.py                 # Helper class (used by Strategy)
│   └── position_tracker.py             # Helper (wraps Nautilus Portfolio)

src/adapters/
├── zerodha_execution_client.py         # Nautilus ExecutionClient subclass
├── options_data_client.py              # Nautilus DataClient subclass
└── parquet_data_loader.py              # Nautilus Data loading for backtest

config/
├── backtest_config.py                  # BacktestEngineConfig
├── sandbox_config.py                   # TradingNode config (paper)
└── live_config.py                      # TradingNode config (live)
```

**Benefits of Target Architecture**:
1. ✅ Same strategy code works in backtest, paper, live
2. ✅ CapitalManager works everywhere (no duplication)
3. ✅ Nautilus handles order execution, data delivery
4. ✅ Built-in risk management, portfolio tracking
5. ✅ Event-driven (no manual polling loops)
6. ✅ Type-safe with msgspec serialization

---

## Migration Path

### Phase 1: CapitalManager as Nautilus Actor (HIGH PRIORITY)

**Goal**: Create capital management that works in all environments.

**Current Issue**: Proposed `CapitalManager` in `/tmp/capital_management_implementation_plan.md` uses custom pattern, won't work in paper/live trading.

**Solution**: Implement as Nautilus Actor.

```python
# NEW: src/strategy/actors/capital_manager.py
from nautilus_trader.trading.strategy import Actor
from nautilus_trader.model.events import PositionClosed, PositionOpened

class CapitalManager(Actor):
    """
    Manages trading capital with compounding growth.
    Works in backtest, paper trading, and live trading.
    """

    def __init__(self, config):
        super().__init__()
        self.initial_capital = config.initial_capital
        self.current_capital = self.initial_capital
        self.risk_pct = config.risk_per_trade_pct
        self.max_deployment_pct = config.max_deployment_pct
        self._capital_history = []

    def on_start(self):
        """Called when actor starts (any environment)"""
        self.subscribe(PositionClosed, self.on_position_closed)
        self.subscribe(PositionOpened, self.on_position_opened)
        self.log.info(f"CapitalManager started with ₹{self.initial_capital:,.0f}")

    def on_position_closed(self, event: PositionClosed):
        """Update capital after position closes"""
        trade_pnl = event.realized_pnl
        previous_capital = self.current_capital
        self.current_capital += trade_pnl

        self._capital_history.append({
            'timestamp': event.timestamp,
            'position_id': event.position_id,
            'previous_capital': previous_capital,
            'trade_pnl': trade_pnl,
            'new_capital': self.current_capital
        })

        self.log.info(f"Capital updated: ₹{previous_capital:,.0f} + ₹{trade_pnl:,.0f} = ₹{self.current_capital:,.0f}")

    def calculate_max_lots(self, capital_per_lot: float, max_lots_config: int) -> int:
        """Calculate dynamic lot size based on current capital"""
        risk_capital = self.current_capital * (self.risk_pct / 100)
        max_lots_by_risk = int(risk_capital / capital_per_lot)

        deployment_capital = self.current_capital * (self.max_deployment_pct / 100)
        max_lots_by_deployment = int(deployment_capital / capital_per_lot)

        actual_lots = min(max_lots_by_risk, max_lots_by_deployment, max_lots_config)
        return max(1, actual_lots)

    def get_capital_state(self) -> dict:
        """Get current capital state for risk checks"""
        return {
            'current_capital': self.current_capital,
            'initial_capital': self.initial_capital,
            'total_return': self.current_capital - self.initial_capital,
            'return_pct': ((self.current_capital / self.initial_capital) - 1) * 100
        }
```

**Integration with Strategy**:
```python
# In OptionsSpreadStrategyModular
class OptionsSpreadStrategyModular(Strategy):
    def __init__(self, config):
        super().__init__(config)
        # Strategy can access actor via message bus
        self.capital_manager = None  # Set by framework

    def on_start(self):
        # Get capital manager reference from clock
        self.capital_manager = self.clock.get_actor("CapitalManager")

    def calculate_position_size(self, capital_per_lot: float) -> int:
        # Ask capital manager for dynamic lot size
        return self.capital_manager.calculate_max_lots(
            capital_per_lot=capital_per_lot,
            max_lots_config=self.config.max_lots
        )
```

**Location**: `src/strategy/actors/capital_manager.py`

---

### Phase 2: Convert Strategy to Nautilus Strategy Class

**Goal**: Make main strategy a proper Nautilus Strategy.

**Changes Required**:
1. Inherit from `nautilus_trader.trading.strategy.Strategy`
2. Use `on_start()`, `on_stop()`, `on_bar()` lifecycle methods
3. Subscribe to market data via framework APIs
4. Place orders using `self.submit_order()` instead of custom execution engine

See `01_BACKTESTING_BEST_PRACTICES.md` for detailed example.

---

### Phase 3: Create Execution Adapters

**Goal**: Integrate with Zerodha for paper/live trading.

**Components**:
- `ZerodhaExecutionClient` → Handles order placement via Zerodha API
- `ZerodhaDataClient` → Streams live market data
- Authentication, reconnection, error handling

See `02_PAPER_TRADING_BEST_PRACTICES.md` and `03_LIVE_TRADING_BEST_PRACTICES.md`.

---

## Component Placement Guidelines

### Where Should Each Component Live?

| Component | Type | Location | Rationale |
|-----------|------|----------|-----------|
| **CapitalManager** | Nautilus Actor | `src/strategy/actors/capital_manager.py` | Needs to work in backtest/paper/live |
| **OptionsSpreadStrategyModular** | Nautilus Strategy | `src/strategy/options_spread_strategy.py` | Main trading logic |
| **EntryManager** | Helper Class | `src/strategy/components/entry_manager.py` | Used by Strategy, not standalone |
| **ExitManager** | Helper Class | `src/strategy/components/exit_manager.py` | Used by Strategy, not standalone |
| **PositionManager** | Helper Class | `src/strategy/components/position_tracker.py` | Wraps Nautilus Portfolio |
| **ZerodhaExecutionClient** | Nautilus ExecutionClient | `src/adapters/zerodha_execution_client.py` | Paper/live trading only |
| **ZerodhaDataClient** | Nautilus DataClient | `src/adapters/zerodha_data_client.py` | Paper/live trading only |
| **ParquetDataLoader** | Data Loader | `src/adapters/parquet_data_loader.py` | Backtesting only |

---

## Configuration Standards

### Nautilus Config Pattern

```python
# config/backtest_config.py
from nautilus_trader.config import BacktestEngineConfig, ImportableActorConfig, ImportableStrategyConfig

config = BacktestEngineConfig(
    strategies=[
        ImportableStrategyConfig(
            strategy_path="strategy.options_spread_strategy:OptionsSpreadStrategyModular",
            config_path="config.strategy_config:StrategyConfig",
            config={
                "instrument_id": "NIFTY50-NSE.NSE",
                "bar_type": "NIFTY50-1-HOUR-LAST",
                "initial_capital": 400000,
                "risk_per_trade_pct": 5.0,
                "max_deployment_pct": 80.0
            }
        )
    ],
    actors=[
        ImportableActorConfig(
            actor_path="strategy.actors.capital_manager:CapitalManager",
            config_path="config.capital_config:CapitalConfig",
            config={
                "initial_capital": 400000,
                "risk_per_trade_pct": 5.0,
                "max_deployment_pct": 80.0,
                "compounding_enabled": True
            }
        )
    ],
    data=[
        {
            "catalog": "nautilus_v10_real_enhanced_clean",
            "data_type": "QuoteTick",
            "instrument_id": "NIFTY50-NSE.NSE"
        }
    ]
)
```

**Key Features**:
- **Importable paths**: Framework loads components dynamically
- **Type validation**: Config classes validated at runtime
- **Environment-specific**: Separate configs for backtest/paper/live
- **Single source of truth**: One config per environment

---

## Key Differences: Current vs Nautilus

| Aspect | Current Architecture | Nautilus Architecture |
|--------|---------------------|----------------------|
| **Strategy Base** | Custom class | `nautilus_trader.trading.strategy.Strategy` |
| **Data Delivery** | Manual polling (`on_market_data()`) | Event-driven (`on_quote_tick()`, `on_bar()`) |
| **Order Execution** | Custom `IExecutionEngine` interface | `self.submit_order()` via framework |
| **Position Tracking** | Custom `PositionManager` | Built-in `self.portfolio` |
| **Capital Management** | Planned custom class | Nautilus Actor (works everywhere) |
| **Risk Management** | Custom `IRiskManager` | Nautilus `RiskEngine` + custom actors |
| **Configuration** | JSON + dataclass | `BacktestEngineConfig` / `TradingNodeConfig` |
| **Environment Support** | Separate implementations | Same code, different config |

---

## Benefits of Full Nautilus Integration

### 1. Code Reuse Across Environments

**Current Problem**:
- Backtest code in `src/backtest/`
- Paper trading code in `src/papertrade/`
- Live trading code would need separate implementation
- Capital management logic would need duplication

**Nautilus Solution**:
```python
# Write once:
class CapitalManager(Actor):
    def on_position_closed(self, event):
        self.update_capital(event.realized_pnl)

# Use everywhere:
# - Backtesting: BacktestEngine.add_actor(CapitalManager)
# - Paper: TradingNode.add_actor(CapitalManager)
# - Live: TradingNode.add_actor(CapitalManager)
```

---

### 2. Built-in Features (Don't Reinvent)

**What Nautilus Provides**:
- ✅ Order management (fills, cancels, amendments)
- ✅ Position tracking (realized/unrealized P&L)
- ✅ Risk checks (pre-trade validation)
- ✅ Data caching (quote ticks, bars)
- ✅ Event persistence (replay backtests)
- ✅ Performance metrics (Sharpe, drawdown, etc.)

**What We Don't Need to Build**:
- ❌ Custom position manager (use `Portfolio`)
- ❌ Custom execution engine (use framework)
- ❌ Manual P&L calculation (framework tracks)
- ❌ Separate paper trading engine (use `TradingNode`)

---

### 3. Type Safety & Validation

**Nautilus Uses msgspec**:
```python
from nautilus_trader.model.orders import Order
from nautilus_trader.model.events import OrderFilled

# Type-safe, validated at runtime
def on_order_filled(self, event: OrderFilled):
    assert isinstance(event, OrderFilled)  # Always True
    assert event.order_id is not None      # Validated
    # No need for defensive checks
```

---

### 4. Production-Grade Infrastructure

**Built-in Support For**:
- Live order book management
- Reconnection handling (WebSocket drops)
- Rate limiting (API throttling)
- Error recovery (partial fills, rejections)
- Logging & monitoring (structured logs)
- Backtesting accuracy (realistic slippage, latency)

---

## Next Steps

### Immediate Priorities

1. **Phase 1: CapitalManager as Actor** (HIGH PRIORITY)
   - Create `src/strategy/actors/capital_manager.py`
   - Implement as Nautilus Actor
   - Test in backtest environment
   - Verify capital updates after trades

2. **Phase 2: Strategy Conversion**
   - Convert `OptionsSpreadStrategyModular` to Nautilus Strategy
   - Update entry/exit managers to work with Nautilus events
   - Test with existing backtest data

3. **Phase 3: Paper Trading Integration**
   - Create Zerodha execution client
   - Create Zerodha data client
   - Test with paper trading environment

4. **Phase 4: Live Trading (Future)**
   - Full risk management validation
   - Production monitoring
   - Gradual rollout with capital limits

### Documentation References

- **Backtesting**: See `01_BACKTESTING_BEST_PRACTICES.md`
- **Paper Trading**: See `02_PAPER_TRADING_BEST_PRACTICES.md`
- **Live Trading**: See `03_LIVE_TRADING_BEST_PRACTICES.md`

---

## Questions & Answers

### Q: Do we need to rewrite everything?

**A**: No. Gradual migration path:
1. Start with CapitalManager as Actor (works immediately)
2. Keep existing strategy logic, just wrap in Nautilus Strategy class
3. Gradually move to event-driven patterns
4. Existing helper classes (EntryManager, ExitManager) can stay as-is

### Q: What about our custom data adapter?

**A**:
- **Backtesting**: Load parquet data into Nautilus catalog, use `BacktestDataConfig`
- **Paper/Live**: Create `ZerodhaDataClient` (streams live data)
- Current adapter logic can be reused for catalog loading

### Q: How does CapitalManager get accessed from Strategy?

**A**: Via message bus or direct reference:
```python
# Method 1: Message bus (recommended)
self.msgbus.subscribe("events.position.closed", self.on_position_closed)

# Method 2: Direct reference
self.capital_manager = self.clock.get_actor("CapitalManager")
lots = self.capital_manager.calculate_max_lots(...)
```

### Q: What about our existing backtest results?

**A**: Compatible. Nautilus backtest produces similar output:
- Trade log (CSV)
- Daily P&L
- Performance statistics
- Can keep existing analysis scripts

---

## Conclusion

**Current State**: Custom architecture, works for backtesting only.

**Target State**: Full Nautilus integration, same code works everywhere.

**Path Forward**:
1. Convert CapitalManager to Nautilus Actor (immediate)
2. Wrap strategy in Nautilus Strategy class (short-term)
3. Create execution/data adapters for Zerodha (medium-term)
4. Full live trading support (long-term)

**Key Principle**: Write once, test in backtest, validate in paper, deploy to live.

See individual best practices documents for implementation details.
