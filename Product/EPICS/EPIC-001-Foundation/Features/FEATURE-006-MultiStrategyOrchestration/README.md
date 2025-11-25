---
id: FEATURE-006-MultiStrategyOrchestration
title: Unified Strategy Orchestration Domain Model
artifact_type: feature_specification
status: proposed
created_at: '2025-11-20T22:00:00+00:00'
updated_at: '2025-11-21T00:00:00+00:00'
owner: system_architect
related_epic: [EPIC-001-Foundation]
related_feature: []
progress_pct: 0
---

# FEATURE-006: Unified Strategy Orchestration Domain Model

## Feature Overview

**Feature ID**: FEATURE-006
**Title**: Unified Strategy Orchestration Domain Model
**Epic**: EPIC-001 (Foundation & Core Architecture)
**Status**: 📋 Proposed
**Priority**: P0 (Critical - Blocks both single and multi-strategy modes)
**Owner**: Core Architecture Team
**Duration**: 2 weeks (10 days)

## Description

Implement the platform-agnostic domain model for unified strategy orchestration that supports BOTH modes:
1. **Single-Strategy Mode**: Strategy library with ONE active strategy (100% capital allocation)
2. **Multi-Strategy Mode**: 2-3 strategies running simultaneously (capital split based on allocation)

This provides the core logic for strategy execution with proper capital allocation, coordination, and risk management - independent of execution environment (backtest, paper, or live). The same orchestrator handles both N=1 (single) and N>1 (multi) cases seamlessly.

## Business Value

- **Unified Approach**: Single orchestrator handles both single-strategy and multi-strategy modes
- **Foundation for All Trading**: Supports strategy library pattern AND portfolio trading
- **Reusable Core Logic**: Write once, use in backtest/paper/live
- **Risk Management**: Works for single strategy or portfolio-level controls
- **Clean Architecture**: Maintains separation between domain and infrastructure
- **Configuration-Driven**: Mode selection via configuration, no code changes

## Success Criteria

- [ ] Platform-agnostic orchestrator implemented for both modes
- [ ] Single-strategy mode: Strategy library with configuration-based selection
- [ ] Multi-strategy mode: Concurrent execution with capital allocation
- [ ] Mode auto-detection from configuration structure
- [ ] Capital management logic independent of execution mode
- [ ] Strategy coordination without environment coupling
- [ ] Clear port interfaces for adapters
- [ ] Domain events for cross-strategy communication
- [ ] Unit tests with 95%+ coverage (no infrastructure dependencies)

## Architecture

### Domain Model Structure

```
src/domain/
├── orchestration/
│   ├── __init__.py
│   ├── multi_strategy_orchestrator.py      # Core orchestration logic
│   ├── portfolio_capital_manager.py        # Capital allocation domain logic
│   ├── strategy_coordinator.py             # Cross-strategy coordination
│   ├── compatibility_analyzer.py           # Strategy compatibility rules
│   └── events.py                          # Domain events for orchestration
├── models/
│   ├── portfolio.py                       # Portfolio domain model
│   ├── allocation.py                      # Capital allocation model
│   └── strategy_metadata.py               # Strategy metadata model
└── ports/
    ├── orchestration_port.py              # Port for execution adapters
    ├── capital_management_port.py         # Port for capital operations
    └── coordination_port.py               # Port for strategy coordination
```

### Core Classes

```python
# domain/orchestration/unified_strategy_orchestrator.py
class UnifiedStrategyOrchestrator:
    """
    Platform-agnostic orchestrator for both single and multi-strategy modes.
    Handles N=1 (single-strategy) and N>1 (multi-strategy) cases.
    Pure domain logic - no infrastructure dependencies.
    """
    
    def __init__(
        self,
        capital_manager: PortfolioCapitalManager,
        coordinator: StrategyCoordinator,
        compatibility_analyzer: CompatibilityAnalyzer
    ):
        self.strategies: Dict[str, StrategyEntry] = {}
        self.capital_manager = capital_manager
        self.coordinator = coordinator
        self.compatibility_analyzer = compatibility_analyzer
        self._mode: OrchestratorMode = None
        
    def detect_mode(self, config: Dict[str, Any]) -> OrchestratorMode:
        """Auto-detect mode from configuration structure."""
        # Single-strategy: {"strategy": "name", "config": {...}}
        # Multi-strategy: {"strategies": {"S1": {...}, "S2": {...}}}
        
    def add_strategy(
        self, 
        strategy: Strategy,
        metadata: StrategyMetadata,
        allocation: AllocationConfig
    ) -> None:
        """Add a strategy with allocation config (100% for single, custom for multi)."""
        
    def validate_compatibility(self) -> CompatibilityReport:
        """Validate strategy compatibility (always passes for single mode)."""
        
    def allocate_capital(self) -> Dict[str, Decimal]:
        """Calculate capital allocation (100% for single, split for multi)."""
        
    def coordinate_execution(self, event: MarketEvent) -> List[StrategyCommand]:
        """Coordinate execution (simple for single, complex for multi)."""
        
    @property
    def is_single_strategy_mode(self) -> bool:
        """Check if running in single-strategy mode."""
        return len(self.strategies) == 1
```

### Mode-Aware Components

```python
# domain/orchestration/portfolio_capital_manager.py
class PortfolioCapitalManager:
    """
    Capital manager that handles both modes intelligently.
    Single mode: 100% to one strategy
    Multi mode: Split based on allocations
    """
    
    def calculate_allocations(self) -> Dict[str, Decimal]:
        if self.orchestrator.is_single_strategy_mode:
            # Simple: 100% to the single strategy
            return {strategy_id: self.total_capital}
        else:
            # Complex: Based on allocation configs
            return self._calculate_multi_allocations()
```

## Stories

### STORY-001: Unified Orchestration Model

**Description**: Implement the unified orchestrator that handles both single and multi-strategy modes

**Tasks**:
1. Create `UnifiedStrategyOrchestrator` class
2. Implement mode detection from configuration
3. Define `StrategyEntry` and `StrategyMetadata` models
4. Implement strategy lifecycle management (add/remove/pause)
5. Create domain events for orchestration
6. Handle strategy library pattern for single mode
7. Add comprehensive unit tests for both modes

**Acceptance Criteria**:
- [ ] Orchestrator detects mode from config
- [ ] Single-strategy mode works with library selection
- [ ] Multi-strategy mode handles concurrent strategies
- [ ] No infrastructure dependencies
- [ ] Domain events published correctly
- [ ] 95%+ test coverage

### STORY-002: Portfolio Capital Management

**Description**: Implement capital allocation domain logic

**Tasks**:
1. Create `PortfolioCapitalManager` class
2. Implement allocation algorithms (equal weight, risk parity, custom)
3. Add position sizing logic
4. Create capital rebalancing rules
5. Handle margin and leverage calculations

**Acceptance Criteria**:
- [ ] Multiple allocation methods supported
- [ ] Position limits enforced
- [ ] Rebalancing logic works correctly
- [ ] Pure domain logic (no I/O)

### STORY-003: Strategy Coordination

**Description**: Implement cross-strategy coordination logic

**Tasks**:
1. Create `StrategyCoordinator` class
2. Implement execution ordering rules
3. Handle cross-strategy dependencies
4. Create conflict resolution logic
5. Add event propagation between strategies

**Acceptance Criteria**:
- [ ] Strategies can share information via events
- [ ] Execution order deterministic
- [ ] Conflicts detected and resolved
- [ ] No race conditions

### STORY-004: Compatibility Analysis

**Description**: Implement strategy compatibility analyzer

**Tasks**:
1. Create `CompatibilityAnalyzer` class
2. Define compatibility rules engine
3. Implement scoring algorithms
4. Add portfolio risk analysis
5. Create recommendation engine

**Acceptance Criteria**:
- [ ] Compatibility scores calculated
- [ ] Risk concentration detected
- [ ] Synergies identified
- [ ] Recommendations generated

### STORY-005: Port Interfaces

**Description**: Define port interfaces for adapters

**Tasks**:
1. Create `OrchestrationPort` interface
2. Define `CapitalManagementPort` interface
3. Create `CoordinationPort` interface
4. Document adapter requirements
5. Create example adapter implementations

**Acceptance Criteria**:
- [ ] Clear port interfaces defined
- [ ] Adapter responsibilities documented
- [ ] Example implementations provided
- [ ] No leaky abstractions

## Integration Points

### With Execution Environments

Each execution environment will implement adapters:

```python
# Port interface (domain layer)
class OrchestrationPort(Protocol):
    """Port for execution environment integration."""
    
    def execute_commands(self, commands: List[StrategyCommand]) -> None:
        """Execute strategy commands in the environment."""
        
    def get_portfolio_state(self) -> PortfolioState:
        """Get current portfolio state from environment."""

# Adapter implementations (infrastructure layer)
class BacktestOrchestrationAdapter(OrchestrationPort):
    """Backtest-specific implementation."""
    
class PaperOrchestrationAdapter(OrchestrationPort):
    """Paper trading-specific implementation."""
    
class LiveOrchestrationAdapter(OrchestrationPort):
    """Live trading-specific implementation."""
```

### Domain Events

Events for cross-cutting concerns:

```python
@dataclass
class StrategyAddedEvent(DomainEvent):
    strategy_id: str
    allocation_pct: float
    
@dataclass
class CapitalRebalancedEvent(DomainEvent):
    allocations: Dict[str, Decimal]
    
@dataclass
class StrategyConflictDetectedEvent(DomainEvent):
    strategy_ids: List[str]
    conflict_type: str
```

## Dependencies

### Prerequisites
- Core domain model (Strategy base class) - Already complete in EPIC-001
- Port interfaces pattern established - Already complete in EPIC-001

### Enables
- EPIC-002: Enhanced backtesting adapters with unified strategy support
- EPIC-003: Enhanced paper trading adapters with unified strategy support
- EPIC-004: Enhanced live trading adapters with unified strategy support

## Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Over-engineering | 🟡 Medium | 🟡 Medium | Start simple, iterate based on needs |
| Leaky abstractions | 🔴 High | 🟡 Medium | Strict port interfaces, no infrastructure in domain |
| Performance overhead | 🟡 Medium | 🟢 Low | Profile early, optimize hot paths |
| Complex testing | 🟡 Medium | 🟡 Medium | Use in-memory test doubles |

## Testing Strategy

### Unit Tests
- Pure domain logic tests (no I/O)
- Use in-memory test doubles
- Property-based testing for allocations
- Scenario-based testing for coordination

### Integration Tests
- Test with mock adapters
- Verify event propagation
- Test error scenarios

## Implementation Notes

### Key Principles
1. **No Infrastructure Dependencies**: Pure domain logic only
2. **Immutable Models**: Use value objects where possible
3. **Event-Driven**: Communicate via domain events
4. **Testable**: Design for testing without infrastructure
5. **Extensible**: Easy to add new allocation methods

### Example Usage

```python
# Domain layer usage (same for all environments)
orchestrator = UnifiedStrategyOrchestrator(
    capital_manager=PortfolioCapitalManager(),
    coordinator=StrategyCoordinator(),
    compatibility_analyzer=CompatibilityAnalyzer()
)

# Example 1: Single-Strategy Mode (Library Pattern)
config = {
    "strategy": "OPTIONS_MONTHLY_WEEKLY_HEDGE",
    "config": {
        "num_lots": 4,
        "max_positions": 3
    }
}
orchestrator.detect_mode(config)  # Returns OrchestratorMode.SINGLE

# Load strategy from library
strategy = strategy_library.get_strategy("OPTIONS_MONTHLY_WEEKLY_HEDGE")
orchestrator.add_strategy(
    strategy=strategy,
    metadata=StrategyMetadata(id="OPTIONS_01"),
    allocation=AllocationConfig(target_pct=100.0)  # Always 100% for single
)

# Example 2: Multi-Strategy Mode (Concurrent Execution)
config = {
    "strategies": {
        "OPTIONS_MONTHLY_WEEKLY_HEDGE": {
            "enabled": true,
            "allocation_pct": 60.0,
            "config": {"num_lots": 4}
        },
        "MOMENTUM_FUTURES": {
            "enabled": true,
            "allocation_pct": 30.0,
            "config": {"leverage": 2.0}
        },
        "MEAN_REVERSION_EQUITY": {
            "enabled": true,
            "allocation_pct": 10.0,
            "config": {"position_size_pct": 3.0}
        }
    }
}
orchestrator.detect_mode(config)  # Returns OrchestratorMode.MULTI

# Add multiple strategies
for strategy_name, strategy_config in config["strategies"].items():
    if strategy_config["enabled"]:
        strategy = strategy_library.get_strategy(strategy_name)
        orchestrator.add_strategy(
            strategy=strategy,
            metadata=StrategyMetadata(id=strategy_name),
            allocation=AllocationConfig(target_pct=strategy_config["allocation_pct"])
        )

# Validate compatibility (only relevant for multi mode)
if not orchestrator.is_single_strategy_mode:
    report = orchestrator.validate_compatibility()
    if not report.is_compatible:
        raise ValueError(f"Incompatible strategies: {report.warnings}")

# Get allocation (100% for single, split for multi)
allocations = orchestrator.allocate_capital()
```

## Dual-Mode Architecture

### Mode Detection Logic

The orchestrator automatically detects the mode based on configuration:

```python
def detect_mode(self, config: Dict[str, Any]) -> OrchestratorMode:
    """
    Auto-detect mode from configuration structure.
    
    Single-strategy indicators:
    - Has 'strategy' key (string)
    - Has 'config' key (dict)
    
    Multi-strategy indicators:
    - Has 'strategies' key (dict)
    - Each sub-key is a strategy with config
    """
    if "strategy" in config and isinstance(config["strategy"], str):
        return OrchestratorMode.SINGLE
    elif "strategies" in config and isinstance(config["strategies"], dict):
        return OrchestratorMode.MULTI
    else:
        raise ValueError("Invalid configuration format")
```

### Behavioral Differences by Mode

| Aspect | Single-Strategy Mode | Multi-Strategy Mode |
|--------|---------------------|-------------------|
| Strategy Count | Exactly 1 | 2+ strategies |
| Capital Allocation | 100% to single strategy | Split by configuration |
| Compatibility Check | Not needed | Required |
| Coordination | Simple pass-through | Complex orchestration |
| Performance | Minimal overhead | Coordination overhead |
| Configuration | Library selection | Individual allocations |

### Strategy Library Pattern (Single Mode)

```python
class StrategyLibrary:
    """Pre-defined strategies available for selection."""
    
    STRATEGIES = {
        "OPTIONS_MONTHLY_WEEKLY_HEDGE": OptionsMonthlyWeeklyHedgeStrategy,
        "IRON_CONDOR": IronCondorStrategy,
        "BULL_CALL_SPREAD": BullCallSpreadStrategy,
        "BEAR_PUT_SPREAD": BearPutSpreadStrategy,
        "STRANGLE": StrangleStrategy,
        "MOMENTUM_FUTURES": MomentumFuturesStrategy,
        "MEAN_REVERSION_EQUITY": MeanReversionEquityStrategy,
    }
    
    @classmethod
    def get_strategy(cls, name: str) -> Strategy:
        """Get strategy instance from library."""
        if name not in cls.STRATEGIES:
            raise ValueError(f"Unknown strategy: {name}")
        return cls.STRATEGIES[name]()
```

## References

- [Domain-Driven Design](https://martinfowler.com/tags/domain%20driven%20design.html)
- [Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/)
- [EPIC-001 Foundation](../../README.md)
- [Multi-Strategy Implementation Overview](pilot-synaptictrading/documentation/nautilusrefactoring/MULTI_STRATEGY_IMPLEMENTATION_OVERVIEW.md)