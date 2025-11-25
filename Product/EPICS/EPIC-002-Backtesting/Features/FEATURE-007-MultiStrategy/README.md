---
id: FEATURE-007-UnifiedBacktestAdapter
title: Unified Strategy Support for Backtesting
artifact_type: feature_specification
status: proposed
created_at: '2025-11-20T21:00:00+00:00'
updated_at: '2025-11-21T00:15:00+00:00'
owner: system_architect
related_epic: [EPIC-002-Backtesting]
related_feature: [EPIC-001-FEATURE-006-MultiStrategyOrchestration]
progress_pct: 0
---

# FEATURE-007: Unified Strategy Support for Backtesting

## Feature Overview

**Feature ID**: FEATURE-007
**Title**: Unified Strategy Support for Backtesting
**Epic**: EPIC-002 (Backtesting Engine)
**Status**: 📋 Proposed
**Priority**: P1 (High)
**Owner**: Backtesting Team
**Duration**: 1 week (5 days)

## Description

Enhance the existing backtesting adapters to support the unified strategy orchestrator (from EPIC-001 FEATURE-006). This enables BOTH single-strategy mode (library selection) and multi-strategy mode (concurrent execution) in backtesting with the same adapter infrastructure.

## Relationship to Core Domain

This feature enhances the **existing backtesting infrastructure** to support unified strategy execution:
- Uses the unified orchestrator from EPIC-001 FEATURE-006
- Enhances existing adapters instead of creating new ones
- Supports BOTH single-strategy (N=1) and multi-strategy (N>1) modes
- Handles backtest-specific concerns (historical data, simulation time, etc.)
- Maintains separation between domain logic and infrastructure

## Business Value

- **Unified Approach**: Single adapter handles all strategy configurations
- **Strategy Library Testing**: Easy A/B testing of individual strategies
- **Portfolio Optimization**: Test strategy combinations for optimal allocation
- **Risk Diversification**: Evaluate portfolio-level risk across strategies
- **Synergy Discovery**: Identify complementary strategy combinations
- **Realistic Testing**: Simulate both single and portfolio scenarios
- **Performance Attribution**: Understand strategy contributions

## Success Criteria

- [ ] Existing adapters enhanced with unified orchestrator
- [ ] Single-strategy mode works with library selection
- [ ] Multi-strategy mode handles concurrent execution
- [ ] Mode auto-detection from configuration works
- [ ] Handles historical data for both modes efficiently
- [ ] Produces appropriate results for each mode
- [ ] Works with all three engines (Nautilus, Backtrader, Custom)
- [ ] Performance acceptable for multi-year backtests

## Architecture

### Enhanced Adapter Design

```
UnifiedBacktestAdapter (Enhanced existing adapter)
├── Integrates UnifiedStrategyOrchestrator (from domain)
├── Auto-detects single vs multi mode from config
├── Uses existing BacktestEngine
├── Manages BacktestDataProvider
└── Produces mode-appropriate results

Dependencies:
- domain.orchestration.UnifiedStrategyOrchestrator
- domain.ports.OrchestrationPort
- adapters.frameworks.backtest.BacktestEngine (existing)
```

### Implementation Pattern

```python
from domain.orchestration import UnifiedStrategyOrchestrator, OrchestratorMode
from domain.ports import OrchestrationPort
from adapters.frameworks.backtest import BacktestEngine

class UnifiedBacktestAdapter(OrchestrationPort):
    """Enhanced backtest adapter supporting both single and multi-strategy modes."""
    
    def __init__(
        self,
        orchestrator: UnifiedStrategyOrchestrator,
        engine: BacktestEngine,
        data_provider: BacktestDataProvider
    ):
        self.orchestrator = orchestrator  # Unified domain logic
        self.engine = engine              # Existing backtest infrastructure
        self.data_provider = data_provider
        
    def run_backtest(self, config: BacktestConfig) -> BacktestResults:
        """Run backtest in appropriate mode based on config."""
        # Auto-detect mode
        mode = self.orchestrator.detect_mode(config)
        
        if mode == OrchestratorMode.SINGLE:
            return self._run_single_strategy_backtest(config)
        else:
            return self._run_multi_strategy_backtest(config)
            
    def _run_single_strategy_backtest(self, config: BacktestConfig) -> BacktestResults:
        """Run single strategy from library."""
        # Load single strategy from library
        strategy_name = config["strategy"]
        strategy = self.strategy_library.get_strategy(strategy_name)
        
        # Add with 100% allocation
        self.orchestrator.add_strategy(
            strategy=strategy,
            metadata=StrategyMetadata(id=strategy_name),
            allocation=AllocationConfig(target_pct=100.0)
        )
        
        # Run with simple pass-through logic
        return self._execute_backtest()
        
    def _run_multi_strategy_backtest(self, config: BacktestConfig) -> BacktestResults:
        """Run multiple strategies concurrently."""
        # Load and add multiple strategies
        for name, strategy_config in config["strategies"].items():
            if strategy_config["enabled"]:
                strategy = self.strategy_library.get_strategy(name)
                self.orchestrator.add_strategy(
                    strategy=strategy,
                    metadata=StrategyMetadata(id=name),
                    allocation=AllocationConfig(
                        target_pct=strategy_config["allocation_pct"]
                    )
                )
        
        # Validate compatibility
        report = self.orchestrator.validate_compatibility()
        if not report.is_compatible:
            raise ValueError(f"Incompatible strategies: {report.warnings}")
            
        # Run with full orchestration
        return self._execute_backtest()
```

## Stories

### STORY-001: Enhance Backtest Adapter for Unified Support

**Description**: Enhance existing backtest adapter to support unified orchestrator

**Tasks**:
1. Integrate `UnifiedStrategyOrchestrator` into existing adapter
2. Implement mode detection logic
3. Add single-strategy mode support (library pattern)
4. Enhance multi-strategy mode support
5. Handle mode-specific data loading
6. Add unit tests for both modes

**Acceptance Criteria**:
- [ ] Adapter detects mode from configuration
- [ ] Single-strategy mode works correctly
- [ ] Multi-strategy mode works correctly
- [ ] Existing functionality preserved
- [ ] Tests pass for both modes

### STORY-002: Historical Data Management

**Description**: Handle data loading for multiple strategies

**Tasks**:
1. Extend data provider for multi-strategy
2. Implement shared data caching
3. Handle different data requirements per strategy
4. Optimize memory usage for large datasets
5. Add performance benchmarks

**Acceptance Criteria**:
- [ ] Data loaded efficiently for all strategies
- [ ] Shared data cached appropriately
- [ ] Memory usage acceptable
- [ ] Performance within targets

### STORY-003: Results Consolidation

**Description**: Produce consolidated backtest results

**Tasks**:
1. Create `MultiStrategyBacktestResults` class
2. Aggregate individual strategy results
3. Calculate portfolio-level metrics
4. Generate performance attribution
5. Ensure backward compatibility

**Acceptance Criteria**:
- [ ] Results include all strategy data
- [ ] Portfolio metrics calculated correctly
- [ ] Attribution analysis available
- [ ] Compatible with existing results format

### STORY-004: Engine-Specific Integration

**Description**: Integrate with Nautilus, Backtrader, and Custom engines

**Tasks**:
1. Create Nautilus multi-strategy runner
2. Create Backtrader multi-strategy runner
3. Create Custom engine multi-strategy runner
4. Ensure consistent behavior
5. Add cross-engine validation tests

**Acceptance Criteria**:
- [ ] Works with all three engines
- [ ] Behavior consistent across engines
- [ ] Performance acceptable
- [ ] Validation tests pass

### STORY-005: Logging Integration

**Description**: Integrate with existing logging system

**Tasks**:
1. Extend logging factory for multi-strategy
2. Create consolidated log format
3. Maintain individual strategy logs
4. Add portfolio-level logging
5. Update log specifications

**Acceptance Criteria**:
- [ ] Logs follow v2.0.0 specification
- [ ] Individual and consolidated logs created
- [ ] Portfolio metrics logged
- [ ] Backward compatible

## Configuration Schema

### Single-Strategy Configuration (Library Pattern)

```json
{
  "version": "1.0.0",
  "strategy": "OPTIONS_MONTHLY_WEEKLY_HEDGE",
  "config": {
    "num_lots": 4,
    "max_positions": 3,
    "stop_loss_pct": 2.0,
    "target_profit_pct": 5.0
  },
  "portfolio": {
    "total_capital": 1000000.0,
    "currency": "INR"
  },
  "risk_management": {
    "max_drawdown_pct": 10.0,
    "position_size_limit": 100000.0
  }
}
```

### Multi-Strategy Configuration (Concurrent Execution)

```json
{
  "version": "1.0.0",
  "strategies": {
    "OPTIONS_MONTHLY_WEEKLY_HEDGE": {
      "enabled": true,
      "allocation_pct": 40.0,
      "max_positions": 3,
      "config": {
        "num_lots": 4
      }
    },
    "MOMENTUM_FUTURES": {
      "enabled": true,
      "allocation_pct": 30.0,
      "max_positions": 5,
      "config": {
        "leverage": 2.0
      }
    },
    "MEAN_REVERSION_EQUITY": {
      "enabled": true,
      "allocation_pct": 30.0,
      "max_positions": 10,
      "config": {
        "position_size_pct": 3.0
      }
    }
  },
  "portfolio": {
    "total_capital": 1000000.0,
    "currency": "INR",
    "allocation_method": "manual",
    "rebalance_frequency": "monthly",
    "performance_targets": {
      "target_annual_return_pct": 15.0,
      "max_acceptable_volatility_pct": 20.0,
      "target_sharpe_ratio": 1.5,
      "target_max_drawdown_pct": 10.0
    }
  },
  "risk_management": {
    "portfolio_var_limit": 50000.0,
    "concentration_limit_pct": 40.0,
    "correlation_threshold": 0.7
  }
}
```

## Logging Extensions

### Multi-Strategy Metadata

```json
{
  "metadata_version": "4.1.0",
  "mode": "multi",
  "total_strategy_runs": 3,
  "portfolio_summary": {
    "total_capital": 1000000.0,
    "allocated_capital": 1000000.0,
    "final_portfolio_value": 1156234.50,
    "total_return_pct": 15.62,
    "sharpe_ratio": 1.82,
    "max_drawdown_pct": -8.34
  },
  "compatibility_analysis": {
    "overall_score": 85.5,
    "compatibility_level": "HIGH",
    "diversification_score": 78.2,
    "warnings": [],
    "synergies": [
      "OPTIONS_MONTHLY_WEEKLY_HEDGE provides hedging for MOMENTUM_FUTURES",
      "MEAN_REVERSION_EQUITY has low correlation with options strategies"
    ]
  },
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
    },
    "MEAN_REVERSION_EQUITY": {
      "return_contribution_pct": 1.62,
      "risk_contribution_pct": 20.0,
      "sharpe_contribution": 0.28
    }
  }
}
```

### Consolidated Trade Log

Additional columns for multi-strategy:
- `strategy_id`: Which strategy generated the trade
- `portfolio_weight`: Strategy's weight in portfolio
- `cross_strategy_impact`: Impact on other strategies
- `portfolio_var_contribution`: Contribution to portfolio VaR

## Performance Considerations

### Optimization Strategies

1. **Parallel Strategy Execution**
   - Run independent strategies in parallel
   - Synchronize only at capital allocation points
   - Use shared data cache

2. **Memory Management**
   - Stream large datasets
   - Share common market data
   - Lazy load strategy-specific data

3. **Computation Efficiency**
   - Pre-calculate compatibility scores
   - Cache portfolio metrics
   - Batch correlation calculations

### Expected Performance

| Strategies | Data Period | Expected Runtime |
|------------|-------------|------------------|
| 2 | 1 year daily | 10-20s |
| 3 | 1 year daily | 15-30s |
| 5 | 1 year daily | 25-50s |
| 10 | 1 year daily | 50-100s |

## Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Strategy interference | 🔴 High | 🟡 Medium | Isolation via separate instances |
| Capital allocation errors | 🔴 High | 🟡 Medium | Extensive validation and tests |
| Performance degradation | 🟡 Medium | 🟡 Medium | Optimization and caching |
| Complex debugging | 🟡 Medium | 🔴 High | Comprehensive logging |

## Dependencies

### Prerequisites
- **EPIC-001 FEATURE-006**: Multi-Strategy Orchestration Domain Model (MUST be complete)
- EPIC-002 Features 1-6 complete
- Logging system v2.0.0 deployed

### Enables
- Multi-strategy backtesting capability
- Foundation for paper/live multi-strategy adapters

### Blocks
- None - other adapters (paper/live) can be developed in parallel

## Testing Strategy

### Unit Tests
- Compatibility checker logic
- Capital allocation algorithms
- Portfolio metrics calculation

### Integration Tests
- Multi-strategy with each engine
- Cross-strategy capital flows
- Consolidated logging

### Performance Tests
- Scalability with strategy count
- Memory usage profiling
- Execution time benchmarks

## References

- [Multi-Strategy Runner Implementation](https://github.com/synaptic-algos/pilot-synaptictrading/blob/main/src/nautilus/backtest/multi_strategy_runner.py)
- [Strategy Compatibility Checker](https://github.com/synaptic-algos/pilot-synaptictrading/blob/main/src/strategy/compatibility/strategy_compatibility_checker.py)
- [Portfolio Capital Manager](https://github.com/synaptic-algos/pilot-synaptictrading/blob/main/src/strategy/actors/portfolio_capital_manager.py)
- [Consolidated Logger](https://github.com/synaptic-algos/pilot-synaptictrading/blob/main/src/logging/consolidated/consolidated_logger.py)