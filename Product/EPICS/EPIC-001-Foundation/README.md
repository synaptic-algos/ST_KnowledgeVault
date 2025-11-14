---
id: EPIC-001
seq: 1
title: Foundation & Core Architecture
owner: product_ops_team
status: in_progress
artifact_type: epic_overview
related_epic:
- EPIC-001
related_feature:
- FEATURE-001-PortInterfaces
- FEATURE-002-DomainModel
- FEATURE-003-StrategyBase
- FEATURE-004-Orchestration
- FEATURE-005-Testing
related_story: []
created_at: 2025-11-03 00:00:00+00:00
updated_at: '2025-11-13T06:08:09Z'
last_review: '2025-11-13'
change_log:
- "2025-11-06 \u2013 SPRINT-20251104-epic001-foundation-prep \u2013 Repo, tooling,\
  \ and traceability scaffolding complete; EPIC-001 moved to in-progress."
- "2025-11-03 \u2013 product_ops_team \u2013 Added UPMS metadata, PRD and requirements\
  \ references \u2013 n/a"
progress_pct: 15
requirement_coverage: 25
linked_sprints:
- SPRINT-20251104-epic001-foundation-prep
---

# EPIC-001: Foundation & Core Architecture

- **PRD**: [EPIC-001 Foundation PRD](./PRD.md)
- **Requirements**: [Requirements Matrix](./REQUIREMENTS_MATRIX.md)
- **Gate Status**: Preparing for G1 (Discovery) – Research backlog seeding in progress

## Epic Overview

**Epic ID**: EPIC-001
**Title**: Foundation & Core Architecture
**Duration**: 4 weeks (Weeks 1-4)
**Status**: 📋 Planned
**Priority**: P0 (Must Have)
**Owner**: Senior Engineer 1 + Lead Architect

## Description

Establish the foundational architecture for the framework-agnostic platform, including port interfaces, canonical domain model, base Strategy class, and dependency injection infrastructure. This epic creates the core abstractions that enable all subsequent work.

## Business Value

- Enables framework-agnostic strategy development
- Provides testable abstractions for all components
- Establishes architectural patterns for the platform
- Unblocks all downstream epics

## Success Criteria

- [ ] All 5 port interfaces defined and documented
- [ ] Canonical domain model implemented (20+ value objects)
- [ ] Base Strategy class functional with lifecycle management
- [ ] RuntimeBootstrapper working with DI container
- [ ] Mock implementations available for all ports
- [ ] Example strategy runs with mocked dependencies
- [ ] Architectural dependency rules enforced in CI
- [ ] 90%+ test coverage for domain and ports
- [ ] Technical documentation complete

## Features

| Feature ID | Feature Name | Stories | Est. Days | Status |
|------------|--------------|---------|-----------|--------|
| [FEATURE-001-PortInterfaces](./FEATURE-001-PortInterfaces/README.md) | Port Interface Definitions | 5 | 5 | 📋 Planned |
| [FEATURE-002-DomainModel](./FEATURE-002-DomainModel/README.md) | Canonical Domain Model | 4 | 4 | 📋 Planned |
| [FEATURE-003-StrategyBase](./FEATURE-003-StrategyBase/README.md) | Base Strategy Class | 3 | 3 | 📋 Planned |
| [FEATURE-004-Orchestration](./FEATURE-004-Orchestration/README.md) | Application Orchestration | 2 | 4 | 📋 Planned |
| [FEATURE-005-Testing](./FEATURE-005-Testing/README.md) | Testing Infrastructure | 1 | 4 | 📋 Planned |

**Total**: 5 Features, 15 Stories, ~20 days

## Milestone

**Milestone 1: Core Architecture Complete**
- **Target**: End of Week 4
- **Demo**: Example strategy running with mocked ports
- **Validation**: All acceptance tests passing

## Dependencies

### Prerequisites
- Development environment setup
- Project structure created
- CI/CD pipeline configured
- Documentation tooling setup

### Blocks
- EPIC-002 (Backtesting)
- EPIC-003 (Paper Trading)
- EPIC-004 (Live Trading)
- EPIC-005 (Adapters)

## Key Deliverables

### Code Deliverables
- `src/application/ports/` - 5 port interfaces
- `src/domain/shared/` - Canonical value objects and aggregates
- `src/domain/strategy/` - Base Strategy class and mixins
- `src/application/orchestration/` - RuntimeBootstrapper, TickDispatcher, CommandBus
- `tests/unit/` - Comprehensive unit tests
- `tests/mocks/` - Mock port implementations

### Documentation Deliverables
- Port API documentation (auto-generated from docstrings)
- Domain model diagram
- Strategy developer guide
- Architecture decision records (ADRs)

### Testing Deliverables
- Unit test suite (90%+ coverage)
- Contract test framework
- Mock implementations
- Example strategy tests

## Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Port interfaces incomplete | 🔴 High | 🟡 Medium | Review with stakeholders, iterate based on adapter feedback |
| Domain model too complex | 🟡 Medium | 🟡 Medium | Start simple, add complexity as needed |
| Performance overhead | 🟡 Medium | 🟢 Low | Profile early, optimize hot paths |
| Team learning curve | 🟡 Medium | 🟡 Medium | Pair programming, architecture reviews |

## Sprint Breakdown

### Sprint 1 (Week 1-2)
**Goal**: Port interfaces and domain model

**Work Items**:
- FEAT-001-01: Port Interface Definitions (5 stories)
- FEAT-001-02: Canonical Domain Model (partial, 2 stories)

**Demo**: Port interfaces documented, 2 ports have mock implementations

### Sprint 2 (Week 3-4)
**Goal**: Strategy class and orchestration

**Work Items**:
- FEAT-001-02: Canonical Domain Model (complete, 2 stories)
- FEAT-001-03: Base Strategy Class (3 stories)
- FEAT-001-04: Application Orchestration (2 stories)
- FEAT-001-05: Testing Infrastructure (1 story)

**Demo**: Example strategy running end-to-end with mocks

## Acceptance Criteria

### Functional
- [ ] Strategy can be instantiated with port dependencies
- [ ] Strategy lifecycle (start/stop/pause/resume) works correctly
- [ ] Event handlers (on_market_data, on_bar, etc.) can be overridden
- [ ] Signals generated by strategy are processed
- [ ] RuntimeBootstrapper wires all dependencies correctly

### Non-Functional
- [ ] All port methods have <100μs overhead (profiled)
- [ ] Domain objects are immutable and thread-safe
- [ ] Zero circular dependencies (enforced by import-linter)
- [ ] All public APIs have docstrings and type hints
- [ ] Code passes linting (pylint, mypy, black)

### Testing
- [ ] 90%+ line coverage for src/domain/
- [ ] 90%+ line coverage for src/application/ports/
- [ ] All port interfaces have contract tests
- [ ] Example strategy has >95% coverage
- [ ] Property-based tests for domain objects (hypothesis)

## Technical Notes

### Architecture Patterns
- **Hexagonal Architecture**: Ports & Adapters pattern
- **Dependency Inversion**: Domain depends only on abstractions
- **Immutable Domain**: All value objects frozen dataclasses
- **Constructor Injection**: Explicit dependency passing

### Code Standards
- Python 3.10+ type hints on all functions
- Docstrings in Google style
- Immutable domain objects (frozen dataclasses)
- Pure functions for domain logic

### Testing Strategy
- Unit tests with pytest
- Property-based tests with hypothesis
- Contract tests for port compliance
- Mocks using unittest.mock

## Progress Tracking

### Week 1
- [ ] FEAT-001-01-01: Define MarketDataPort
- [ ] FEAT-001-01-02: Define ClockPort
- [ ] FEAT-001-01-03: Define OrderExecutionPort
- [ ] FEAT-001-02-01: Define value objects (InstrumentId, Price, Quantity)
- [ ] FEAT-001-02-02: Define MarketTick and Bar

### Week 2
- [ ] FEAT-001-01-04: Define PortfolioStatePort
- [ ] FEAT-001-01-05: Define TelemetryPort
- [ ] FEAT-001-02-03: Define TradeIntent and OrderTicket
- [ ] FEAT-001-02-04: Define Position and Portfolio snapshots

### Week 3
- [ ] FEAT-001-03-01: Implement Strategy base class
- [ ] FEAT-001-03-02: Implement lifecycle state machine
- [ ] FEAT-001-03-03: Implement event handlers
- [ ] FEAT-001-04-01: Implement RuntimeBootstrapper

### Week 4
- [ ] FEAT-001-04-02: Implement TickDispatcher and CommandBus
- [ ] FEAT-001-05-01: Create testing infrastructure
- [ ] Integration testing
- [ ] Documentation polish
- [ ] Epic demo and review

## Related Documents

- [Epic PRD](./PRD.md)
- [Requirements Matrix](./REQUIREMENTS_MATRIX.md)
- [Design: Core Architecture](../../design/01_FrameworkAgnostic/CORE_ARCHITECTURE.md)
- [Design: Strategy Lifecycle](../../design/01_FrameworkAgnostic/STRATEGY_LIFECYCLE.md)

## Feature Breakdown

### [FEATURE-001: Port Interface Definitions](./FEATURE-001-PortInterfaces/README.md)
Define the 5 core port interfaces that provide abstraction over execution frameworks.

**Stories**: 5 (one per port)
**Effort**: 5 days

### [FEATURE-002: Canonical Domain Model](./FEATURE-002-DomainModel/README.md)
Implement framework-agnostic domain objects and value types.

**Stories**: 4
**Effort**: 4 days

### [FEATURE-003: Base Strategy Class](./FEATURE-003-StrategyBase/README.md)
Create the abstract Strategy class with lifecycle management and event handlers.

**Stories**: 3
**Effort**: 3 days

### [FEATURE-004: Application Orchestration](./FEATURE-004-Orchestration/README.md)
Build the orchestration layer that coordinates ports, strategies, and risk management.

**Stories**: 2
**Effort**: 4 days

### [FEATURE-005: Testing Infrastructure](./FEATURE-005-Testing/README.md)
Establish mock implementations and testing patterns for strategy development.

**Stories**: 1
**Effort**: 4 days

---

**Next Epic**: [EPIC-002: Backtesting Engine](./EPIC-002-Backtesting.md)
