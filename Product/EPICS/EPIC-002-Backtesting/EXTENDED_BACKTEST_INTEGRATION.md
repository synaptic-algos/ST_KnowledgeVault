---
id: EPIC-002-Backtesting-Extended
title: Extended Backtesting Engine Integration
artifact_type: technical_specification
created_at: '2025-11-20T20:00:00+00:00'
updated_at: '2025-11-20T20:00:00+00:00'
author: system_architect
related_epic: [EPIC-002-Backtesting, EPIC-005-Adapters, EPIC-007-StrategyLifecycle]
---

# EPIC-002: Extended Backtesting Engine Integration

## Overview

This document extends EPIC-002 to provide comprehensive details for running backtests using multiple engines (Nautilus, Backtrader, and Custom Backtester) with unified frontend integration and consistent logging across all platforms.

## Multi-Engine Backtesting Architecture

### Supported Backtesting Engines

1. **Nautilus Trader** - High-performance event-driven backtesting
2. **Backtrader** - Feature-rich Python backtesting framework
3. **Custom Backtester** - Domain-specific backtesting implementation

### Unified Interface

All backtesting engines implement the same interface to ensure consistency:

```python
class BacktestAdapter(ABC):
    """Unified interface for all backtesting engines."""
    
    @abstractmethod
    def run(self, strategy: Strategy, config: BacktestConfig) -> BacktestResults:
        """Run backtest and return unified results."""
        pass
```

## 1. Nautilus Trader Integration

### 1.1 Architecture

```
NautilusBacktestAdapter
├── NautilusStrategyWrapper
│   ├── Domain Strategy (wrapped)
│   └── Event Translation (Domain ↔ Nautilus)
├── NautilusClockPort
├── NautilusMarketDataPort
├── NautilusExecutionPort
├── NautilusPortfolioPort
├── ConfigMapper (BacktestConfig → NautilusConfig)
└── ResultsConverter (Nautilus → BacktestResults)
```

### 1.2 Implementation Details

**Location**: `src/adapters/frameworks/nautilus/`

**Key Components**:
- `nautilus_backtest_adapter.py` - Main adapter implementation
- `core/strategy_wrapper.py` - Wraps domain strategies for Nautilus
- `core/port_adapters.py` - Port interface implementations
- `config_mapper.py` - Configuration translation
- `results_converter.py` - Results standardization

### 1.3 Running a Nautilus Backtest

```python
from src.adapters.frameworks.nautilus import NautilusBacktestAdapter
from src.domain.strategy import Strategy
from src.domain.config import BacktestConfig

# Initialize adapter
adapter = NautilusBacktestAdapter()

# Configure backtest
config = BacktestConfig(
    start_date="2024-01-01",
    end_date="2024-12-31",
    initial_capital=1000000.0,
    data_config={
        "symbols": ["NIFTY", "BANKNIFTY"],
        "data_type": "OHLCV",
        "interval": "1m"
    }
)

# Run backtest with platform-agnostic strategy (from EPIC-007)
strategy = load_strategy("STRAT-001")  # Platform-agnostic strategy
results = adapter.run(strategy, config)
```

### 1.4 Custom Logging Integration

The Nautilus adapter integrates with the custom logging system from `pilot-synaptictrading`:

```python
from src.logging.integration_helper import BacktestLoggingIntegration
from src.logging.core.base_logger import RunnerType

# Initialize logging integration
logger_integration = BacktestLoggingIntegration(
    strategy_name=strategy.name,
    runner_type=RunnerType.BACKTEST
)

# Generate comprehensive logs
log_paths = logger_integration.generate_from_nautilus_engine(
    engine=nautilus_engine,
    initial_capital=config.initial_capital
)

# Log paths include:
# - metadata.json (execution metadata)
# - trades.csv (trade details)
# - daily_pnl.csv (daily P&L)
# - statistics.json (performance metrics)
# - components.log (strategy component logs)
```

## 2. Backtrader Integration

### 2.1 Architecture

```
BacktraderBacktestAdapter
├── BacktraderStrategyWrapper (extends bt.Strategy)
│   ├── Domain Strategy (wrapped)
│   └── Event Translation (Domain ↔ Backtrader)
├── BacktraderClockPort
├── BacktraderMarketDataPort
├── BacktraderExecutionPort
├── ConfigMapper (BacktestConfig → Cerebro)
└── ResultsConverter (Backtrader → BacktestResults)
```

### 2.2 Implementation Details

**Location**: `src/adapters/frameworks/backtrader/`

**Key Components**:
- `backtrader_backtest_adapter.py` - Main adapter implementation
- `core/strategy_wrapper.py` - Wraps domain strategies for Backtrader
- `core/port_adapters.py` - Port interface implementations
- `config_mapper.py` - Configuration translation
- `results_converter.py` - Results standardization

### 2.3 Running a Backtrader Backtest

```python
from src.adapters.frameworks.backtrader import BacktraderBacktestAdapter
from src.domain.strategy import Strategy
from src.domain.config import BacktestConfig

# Initialize adapter
adapter = BacktraderBacktestAdapter()

# Configure backtest
config = BacktestConfig(
    start_date="2024-01-01",
    end_date="2024-12-31",
    initial_capital=1000000.0,
    data_config={
        "symbols": ["NIFTY", "BANKNIFTY"],
        "data_type": "OHLCV",
        "interval": "1D"
    },
    commission=0.001,
    slippage=0.0001
)

# Run backtest with platform-agnostic strategy
strategy = load_strategy("STRAT-001")  # Same strategy as Nautilus!
results = adapter.run(strategy, config)
```

### 2.4 Custom Logging Integration

```python
# Backtrader logging uses the same interface
logger_integration = BacktestLoggingIntegration(
    strategy_name=strategy.name,
    runner_type=RunnerType.BACKTEST
)

# Extract data from Backtrader Cerebro
log_paths = logger_integration.generate_from_backtrader_cerebro(
    cerebro=cerebro,
    initial_capital=config.initial_capital
)
```

## 3. Custom Backtester Integration

### 3.1 Architecture

```
CustomBacktestAdapter
├── Domain Strategy (native support)
├── CustomClockPort
├── CustomMarketDataPort
├── CustomExecutionPort
├── CustomPortfolioPort
└── CustomAnalytics
```

### 3.2 Implementation Details

**Location**: `src/adapters/frameworks/custom/`

**Key Components**:
- `custom_backtest_adapter.py` - Main adapter implementation
- `engine/event_replayer.py` - Historical event replay
- `engine/execution_simulator.py` - Order fill simulation
- `engine/portfolio.py` - Portfolio accounting
- `analytics/performance.py` - Performance calculation

### 3.3 Running a Custom Backtest

```python
from src.adapters.frameworks.custom import CustomBacktestAdapter
from src.domain.strategy import Strategy
from src.domain.config import BacktestConfig

# Initialize adapter
adapter = CustomBacktestAdapter()

# Configure backtest
config = BacktestConfig(
    start_date="2024-01-01",
    end_date="2024-12-31",
    initial_capital=1000000.0,
    data_config={
        "symbols": ["NIFTY", "BANKNIFTY"],
        "data_type": "OHLCV_GREEKS",  # Custom supports Greeks
        "interval": "1m"
    }
)

# Run backtest
strategy = load_strategy("STRAT-001")  # Same strategy again!
results = adapter.run(strategy, config)
```

### 3.4 Custom Logging Integration

```python
# Custom backtester has native support for the logging system
logger_integration = BacktestLoggingIntegration(
    strategy_name=strategy.name,
    runner_type=RunnerType.BACKTEST
)

# Generate logs directly from custom engine
log_paths = logger_integration.generate_from_custom_engine(
    engine=custom_engine,
    initial_capital=config.initial_capital
)
```

## 4. Frontend Integration

### 4.1 Unified Backtesting API

The frontend interacts with all backtesting engines through a unified API:

```python
class BacktestingService:
    """Unified service for frontend to run backtests."""
    
    def __init__(self):
        self.adapters = {
            'nautilus': NautilusBacktestAdapter(),
            'backtrader': BacktraderBacktestAdapter(),
            'custom': CustomBacktestAdapter()
        }
    
    def run_backtest(
        self,
        engine: str,
        strategy_id: str,
        config: Dict[str, Any]
    ) -> BacktestResults:
        """Run backtest on specified engine."""
        adapter = self.adapters[engine]
        strategy = load_strategy(strategy_id)
        backtest_config = BacktestConfig(**config)
        
        # Run backtest with logging
        results = adapter.run(strategy, backtest_config)
        
        # Generate comprehensive logs
        self._generate_logs(engine, strategy, results)
        
        return results
```

### 4.2 Frontend API Endpoints

```python
# FastAPI endpoints for frontend
from fastapi import FastAPI, BackgroundTasks
from typing import Dict, Any

app = FastAPI()

@app.post("/backtest/run")
async def run_backtest(
    engine: str,
    strategy_id: str,
    config: Dict[str, Any],
    background_tasks: BackgroundTasks
):
    """Run backtest asynchronously."""
    task_id = generate_task_id()
    
    # Run in background
    background_tasks.add_task(
        backtesting_service.run_backtest,
        engine, strategy_id, config, task_id
    )
    
    return {"task_id": task_id, "status": "running"}

@app.get("/backtest/status/{task_id}")
async def get_backtest_status(task_id: str):
    """Get backtest status and progress."""
    return backtesting_service.get_status(task_id)

@app.get("/backtest/results/{task_id}")
async def get_backtest_results(task_id: str):
    """Get backtest results when complete."""
    return backtesting_service.get_results(task_id)

@app.get("/backtest/logs/{task_id}")
async def get_backtest_logs(task_id: str):
    """Get comprehensive logs for the backtest."""
    return backtesting_service.get_logs(task_id)
```

### 4.3 Frontend UI Components

```typescript
// React components for backtest UI
interface BacktestConfig {
  engine: 'nautilus' | 'backtrader' | 'custom';
  strategyId: string;
  startDate: string;
  endDate: string;
  initialCapital: number;
  symbols: string[];
  interval: string;
}

const BacktestRunner: React.FC = () => {
  const [config, setConfig] = useState<BacktestConfig>({
    engine: 'nautilus',
    // ... default config
  });
  
  const runBacktest = async () => {
    const response = await api.post('/backtest/run', config);
    const taskId = response.data.task_id;
    
    // Poll for results
    const results = await pollForResults(taskId);
    
    // Display results
    showResults(results);
  };
  
  return (
    <div>
      <EngineSelector 
        value={config.engine}
        onChange={(engine) => setConfig({...config, engine})}
      />
      <StrategySelector
        value={config.strategyId}
        onChange={(strategyId) => setConfig({...config, strategyId})}
      />
      <DateRangePicker
        startDate={config.startDate}
        endDate={config.endDate}
        onChange={({start, end}) => setConfig({...config, startDate: start, endDate: end})}
      />
      <Button onClick={runBacktest}>Run Backtest</Button>
    </div>
  );
};
```

## 5. Unified Logging System

### 5.1 Logging Architecture

All backtesting engines use the same comprehensive logging system based on the pilot-synaptictrading implementation:

```
BacktestLoggingFactory
├── EnhancedBacktestResultsGenerator
│   ├── MetadataLogger (backtest_metadata.json)
│   ├── TradeLogger (trade_log.csv / enriched_trade_log.csv)
│   ├── DailyPnLLogger (daily_pnl.csv)
│   ├── StatisticsLogger (statistics.json)
│   └── ComponentLogger (strategy_components_log.json)
├── RunnerOverrides (backtest/paper/live configurations)
├── ConsolidatedLogger (multi-strategy aggregation)
└── BacktestLoggingIntegration (engine adapters)
```

### 5.2 Log Output Structure

Based on the actual implementation:

```
backtest_results/
├── YYYYMMDD/                                    # Date folder
│   ├── HHMMSS/                                 # Time folder
│   │   ├── {StrategyName}_backtest/           # Strategy-specific folder
│   │   │   ├── backtest_metadata.json         # v2.0.0+ metadata format
│   │   │   ├── trade_log.csv                  # Comprehensive trade details
│   │   │   ├── enriched_trade_log.csv         # With additional columns
│   │   │   ├── daily_pnl.csv                  # Daily P&L tracking
│   │   │   ├── statistics.json                # Performance metrics
│   │   │   ├── backtest.log                   # Execution log
│   │   │   ├── nautilus_engine.log            # Engine-specific log
│   │   │   ├── runner_overrides.json          # Applied overrides
│   │   │   ├── spread_failures.json           # Failed trades (if any)
│   │   │   └── spread_failure_logs.txt        # Detailed failure logs
│   │   ├── consolidated_metadata.json          # Multi-strategy metadata
│   │   ├── consolidated_statistics.json        # Aggregated statistics
│   │   ├── consolidated_daily_pnl.csv         # Combined daily P&L
│   │   └── consolidated_backtest.log          # Combined execution log
```

### 5.3 Log Content Specifications (v2.0.0)

**backtest_metadata.json** (Per PRD Specification):
```json
{
  "metadata_version": "2.0.0",
  "backtest_run": {
    "run_id": "20251022_160335",
    "run_timestamp": "2025-10-22T10:33:35.277680+00:00",
    "run_name": "OptionsWeeklyMonthlyHedgeStrategy",
    "duration_seconds": 135.83,
    "status": "completed",
    "error_message": null,
    "framework": "nautilus_trader"
  },
  "nautilus_info": {
    "framework_version": "1.220.0",
    "catalog_path": "data/catalogs/v13_real_enhanced_hourly_consolidated",
    "catalog_format": "v13_consolidated",
    "strategy_class": "OptionsWeeklyMonthlyHedgeStrategy",
    "mode": "single",
    "instruments": {}
  },
  "data_source": {
    "catalog_id": "v13_real_enhanced_hourly_consolidated",
    "catalog_version": "13.0",
    "adapter_class": "SharedV13DataManager",
    "date_range": {
      "start": "2024-01-01",
      "end": "2024-12-31"
    }
  },
  "configuration": {
    "config_version": "3.15.0",
    "config_file": "config/strategy_config.json",
    "config_hash": "e9a066df8dfa60b3",
    "mode": "single",
    "backtest": {
      "rsi_warmup_days": 14,
      "trading_start_date": "2024-01-15",
      "start_date": "2024-01-01",
      "end_date": "2024-02-29",
      "initial_capital": 400000.0,
      "lot_size": 75,
      "num_lots": 4
    }
  },
  "performance": {
    "execution": {
      "total_duration_seconds": 135.83,
      "strategy_execution_seconds": 135.83
    },
    "memory": {
      "peak_memory_mb": 381.14,
      "avg_memory_mb": 381.14
    }
  },
  "system_environment": {
    "python_version": "3.13.7",
    "platform": "darwin",
    "os_version": "macOS-15.4.1-arm64-arm-64bit-Mach-O",
    "architecture": "arm64",
    "processor": "arm",
    "cpu_count": 10,
    "total_memory_gb": 16.0
  },
  "results_summary": {
    "total_trades": 6,
    "closed_positions": 6,
    "total_pnl": -159546.0,
    "return_pct": -39.89,
    "win_rate": 0.0,
    "execution_time_seconds": 135.83
  }
}
```

**trade_log.csv** (Comprehensive v2.0.0 Format):
```csv
trade_id,spread_id,parent_spread_id,leg_type,leg_number,entry_timestamp,exit_timestamp,days_in_trade,expiry_date,month,strategy_type,position_type,entry_reason,direction,direction_reason,instrument_id,strike,option_type,side,quantity,lot_size,entry_price,exit_price,leg_pnl,strike_width,net_credit,spread_pnl,spread_return_pct,max_profit,max_loss,capital_at_risk,profit_target_pct,profit_target_value,entry_spot,entry_rsi,entry_vix,entry_delta,exit_spot,exit_vix,status,exit_reason,exit_details,cumulative_pnl,portfolio_value,commissions_inr,slippage_inr,net_pnl_after_costs,position_id
NIFTY240118P22000.NSE-OptionsWeeklyMonthlyHedgeStrategy-000,SPREAD_M1,,SHORT,1,2024-01-15T09:00:00,2024-01-15T18:30:00,0,2024-01-18 09:00:00+05:30,2024-01,BULL_CALL_SPREAD,monthly_bull_call,MONTHLY_ENTRY,BULLISH,RSI_NEUTRAL_BULLISH,NIFTY240118P22000.NSE,22000.0,PE,SELL,300,75,206.53,101.93,-31380.0,200,-42279.0,-31380.0,-29.89,0,105000,105000,60.0,63000.0,21982.75,0.0,13.79,-0.5032,22064.0,13.79,closed,stop_loss,,-31380.0,368620.0,0.0,0.0,-31380.0,NIFTY240118P22000.NSE-OptionsWeeklyMonthlyHedgeStrategy-000
```

Key columns include:
- **Spread identification**: `spread_id`, `parent_spread_id` for weekly-monthly linkage
- **Capital management**: `portfolio_value`, `net_credit`, `entry_vix`, `entry_delta`, `exit_vix`
- **Exit tracking**: `exit_reason` with priority codes (portfolio_stop_loss, stop_loss, profit_target, etc.)
- **Performance metrics**: `spread_pnl`, `spread_return_pct`, `cumulative_pnl`

**statistics.json**:
```json
{
  "summary": {
    "total_trades": 6,
    "closed_positions": 6,
    "open_positions": 0,
    "total_pnl": -159546.0,
    "return_pct": -39.89,
    "win_rate": 0.0,
    "avg_profit": 0.0,
    "avg_loss": -26591.0,
    "max_profit": -10233.0,
    "max_loss": -36081.0,
    "profit_factor": 0.0
  },
  "by_direction": {
    "BULLISH": {"count": 3, "pnl": -80000.0},
    "BEARISH": {"count": 3, "pnl": -79546.0}
  },
  "by_exit_reason": {
    "stop_loss": {"count": 4, "pnl": -140000.0},
    "portfolio_stop_loss": {"count": 2, "pnl": -19546.0}
  },
  "execution": {
    "total_trades": 6,
    "winning_trades": 0,
    "losing_trades": 6
  }
}
```

**daily_pnl.csv**:
```csv
date,portfolio_value,daily_pnl,daily_return_pct,cumulative_pnl,cumulative_return_pct,peak_value,drawdown,drawdown_pct,open_positions
2024-01-15,368620.0,-31380.0,-7.845,-31380.0,-7.845,400000.0,-31380.0,-7.845,2
2024-01-16,357148.0,-11472.0,-2.868,-42852.0,-10.713,400000.0,-42852.0,-10.713,4
```

## 6. Cross-Engine Validation

### 6.1 Validation Framework

```python
class CrossEngineValidator:
    """Validate results across different backtesting engines."""
    
    def validate_results(
        self,
        nautilus_results: BacktestResults,
        backtrader_results: BacktestResults,
        custom_results: BacktestResults,
        tolerance: float = 0.0001  # 0.01%
    ) -> ValidationReport:
        """Compare results across engines."""
        
        report = ValidationReport()
        
        # Compare final P&L
        report.pnl_divergence = self._compare_pnl(
            nautilus_results.final_pnl,
            backtrader_results.final_pnl,
            custom_results.final_pnl
        )
        
        # Compare trade counts
        report.trade_count_match = self._compare_trade_counts(
            nautilus_results.total_trades,
            backtrader_results.total_trades,
            custom_results.total_trades
        )
        
        # Compare performance metrics
        report.metrics_divergence = self._compare_metrics(
            nautilus_results.metrics,
            backtrader_results.metrics,
            custom_results.metrics
        )
        
        return report
```

### 6.2 Validation Dashboard

The frontend includes a validation dashboard to compare results across engines:

```typescript
const ValidationDashboard: React.FC = () => {
  const [results, setResults] = useState<CrossEngineResults>();
  
  return (
    <div>
      <h2>Cross-Engine Validation</h2>
      <EngineComparison 
        nautilus={results.nautilus}
        backtrader={results.backtrader}
        custom={results.custom}
      />
      <DivergenceChart data={results.divergence} />
      <ValidationReport report={results.validation} />
    </div>
  );
};
```

## 7. Implementation Timeline

### Phase 1: Core Integration (Weeks 1-2)
- Implement Nautilus adapter with custom logging
- Implement Backtrader adapter with custom logging
- Enhance custom backtester with unified logging

### Phase 2: Frontend Integration (Weeks 3-4)
- Build unified backtesting API
- Implement frontend components
- Create results visualization

### Phase 3: Validation & Testing (Week 5)
- Implement cross-engine validation
- Performance testing
- Documentation

### Phase 4: Production Deployment (Week 6)
- Deploy to staging environment
- User acceptance testing
- Production rollout

## 8. Performance Benchmarks

### Expected Performance

| Engine | 1 Year Daily | 1 Year 1-min | 5 Years Daily |
|--------|--------------|--------------|---------------|
| Nautilus | 2-5s | 30-60s | 10-20s |
| Backtrader | 5-10s | 60-120s | 20-40s |
| Custom | 10-15s | 90-180s | 30-60s |

### Optimization Strategies

1. **Data Caching**: Pre-load and cache market data
2. **Parallel Processing**: Run multiple symbols in parallel
3. **Incremental Updates**: Cache intermediate results
4. **Memory Management**: Stream large datasets

## 9. Monitoring & Observability

### 9.1 Metrics Collection

```python
class BacktestMetricsCollector:
    """Collect metrics for monitoring."""
    
    def collect_metrics(self, engine: str, results: BacktestResults):
        metrics = {
            'engine': engine,
            'runtime_seconds': results.runtime,
            'memory_usage_mb': results.memory_usage,
            'total_trades': results.total_trades,
            'data_points_processed': results.data_points
        }
        
        # Send to monitoring system
        prometheus_client.push_metrics(metrics)
```

### 9.2 Alerting Rules

- Alert if backtest runtime > 5 minutes
- Alert if memory usage > 4GB
- Alert if engine divergence > 0.1%
- Alert if backtest failure rate > 5%

## 10. Security Considerations

### 10.1 Data Access Control
- Strategy code isolation
- Market data access restrictions
- Result data encryption

### 10.2 Resource Limits
- CPU time limits per backtest
- Memory limits per backtest
- Concurrent backtest limits per user

## 11. Multi-Strategy Backtesting

### 11.1 Overview

Multi-strategy backtesting extends the backtesting engine to run multiple trading strategies simultaneously with proper capital allocation, cross-strategy coordination, and consolidated performance analytics. This is implemented as FEATURE-007 under EPIC-002.

### 11.2 Architecture

```
MultiStrategyBacktestAdapter
├── StrategyRegistry (metadata and compatibility rules)
├── CompatibilityChecker (strategy combination analysis)
├── PortfolioCapitalManager (dynamic allocation)
├── MultiStrategyOrchestrator (execution coordination)
└── ConsolidatedResultsGenerator (aggregated reporting)
```

### 11.3 Running Multi-Strategy Backtests

```python
from src.nautilus.backtest.multi_strategy_runner import MultiStrategyRunner

# Create multi-strategy configuration
config = {
    "version": "1.0.0",
    "mode": "multi",
    "portfolio": {
        "total_capital": 1000000.0,
        "allocation_method": "equal_weight"
    },
    "strategies": {
        "OPTIONS_MONTHLY_WEEKLY_HEDGE": {
            "enabled": true,
            "allocation_pct": 40.0
        },
        "MOMENTUM_FUTURES": {
            "enabled": true,
            "allocation_pct": 30.0
        },
        "MEAN_REVERSION_EQUITY": {
            "enabled": true,
            "allocation_pct": 30.0
        }
    }
}

# Run multi-strategy backtest
runner = MultiStrategyRunner("config/multi_strategy.json")
results = runner.run()

# Results include compatibility analysis and portfolio metrics
print(f"Compatibility Score: {results.compatibility_report.overall_score}")
print(f"Portfolio Return: {results.portfolio_summary['return_pct']}%")
print(f"Portfolio Sharpe: {results.portfolio_summary['sharpe_ratio']}")
```

### 11.4 Compatibility Analysis

The system automatically analyzes strategy compatibility:

```python
compatibility_report = compatibility_checker.analyze_combination(
    strategies_metadata=[strat1_meta, strat2_meta, strat3_meta],
    total_capital=1000000.0,
    target_return=0.15,
    max_volatility=0.20,
    max_drawdown=0.10
)

# Report includes:
# - Overall compatibility score (0-100)
# - Diversification score
# - Identified synergies
# - Risk concentration warnings
# - Capital allocation recommendations
```

### 11.5 Consolidated Logging

Multi-strategy runs generate both individual and consolidated logs:

```
backtest_results/
├── YYYYMMDD/
│   ├── HHMMSS/
│   │   ├── StrategyA_backtest/     # Individual results
│   │   ├── StrategyB_backtest/     # Individual results
│   │   ├── StrategyC_backtest/     # Individual results
│   │   ├── consolidated_metadata.json
│   │   ├── consolidated_statistics.json
│   │   ├── consolidated_daily_pnl.csv
│   │   └── consolidated_backtest.log
```

### 11.6 Performance Attribution

The system provides detailed performance attribution:

```json
{
  "strategy_contributions": {
    "OPTIONS_MONTHLY_WEEKLY_HEDGE": {
      "return_contribution_pct": 6.2,
      "risk_contribution_pct": 35.0,
      "sharpe_contribution": 0.65
    },
    "MOMENTUM_FUTURES": {
      "return_contribution_pct": 7.8,
      "risk_contribution_pct": 45.0,
      "sharpe_contribution": 0.89
    }
  }
}
```

## 12. Future Enhancements

### 12.1 Additional Engines
- **VectorBT**: Vectorized backtesting
- **Zipline**: Quantopian-style backtesting
- **PyAlgoTrade**: Event-driven backtesting

### 12.2 Advanced Features
- Multi-asset portfolio backtesting (extended from multi-strategy)
- Options Greeks integration (already in pilot-synaptictrading)
- Real-time backtest progress streaming
- Distributed backtesting across clusters
- Dynamic strategy weighting based on regime

### 12.3 Machine Learning Integration
- Strategy parameter optimization
- Walk-forward analysis
- Monte Carlo simulations
- Regime detection
- Adaptive capital allocation

## References

- [EPIC-002 Original](./README.md)
- [EPIC-002 FEATURE-007 Multi-Strategy](./Features/FEATURE-007-MultiStrategy/README.md)
- [EPIC-005 Adapters](../EPIC-005-Adapters/README.md)
- [EPIC-007 Strategy Lifecycle](../EPIC-007-StrategyLifecycle/README.md)
- [Nautilus Documentation](https://nautilustrader.io/docs/)
- [Backtrader Documentation](https://www.backtrader.com/docu/)
- [pilot-synaptictrading Implementation](https://github.com/synaptic-algos/pilot-synaptictrading)