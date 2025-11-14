---
id: FEATURE-002-DomainModel
seq: 2
title: Canonical Domain Model
owner: product_ops_team
status: in_progress
artifact_type: feature_overview
related_epic:
- EPIC-001
related_feature:
- FEATURE-002-DomainModel
related_story:
- STORY-001-02-01
- STORY-001-02-02
- STORY-001-02-03
- STORY-001-02-04
created_at: 2025-11-03 00:00:00+00:00
updated_at: '2025-11-13T06:08:09Z'
last_review: '2025-11-13'
change_log:
- "2025-11-06 \u2013 Sprint 0 prep \u2013 Domain model traceability seeded and tooling\
  \ ready."
- "2025-11-03 \u2013 product_ops_team \u2013 Stubbed canonical domain model feature\
  \ structure \u2013 n/a"
progress_pct: 10
requirement_coverage: 0
linked_sprints:
- SPRINT-20251104-epic001-foundation-prep
---

# FEATURE-002: Canonical Domain Model

- **Epic**: [EPIC-001: Foundation & Core Architecture](../README.md)
- **Traceability**: [TRACEABILITY.md](./TRACEABILITY.md)
- **Primary Requirement(s)**: REQ-EPIC001-002, REQ-EPIC001-003

## Feature Overview

**Feature ID**: FEATURE-002  
**Feature Name**: Canonical Domain Model  
**Epic**: [EPIC-001: Foundation & Core Architecture](../README.md)  
**Status**: 📋 Planned  
**Priority**: P0  
**Owner**: Lead Architect + Senior Engineer 1  
**Estimated Effort**: 4 days

## Description

Design and implement the canonical domain model that underpins the framework-agnostic platform. The model includes value objects, market data entities, order artefacts, and portfolio snapshots that are immutable, type-safe, and easily serialisable. These primitives establish a shared language across ports, adapters, and strategies.

## Business Value

- Provides single source of truth for financial concepts
- Enables port adapters to exchange strongly typed data
- Reduces duplication across execution frameworks
- Unlocks deterministic testing and replay scenarios

## Acceptance Criteria

- [ ] Value objects implemented as frozen dataclasses with validation
- [ ] Market data entities support tick and bar representations
- [ ] Order domain objects cover lifecycle from intent to fill
- [ ] Portfolio snapshots model cash, positions, and risk metrics
- [ ] Serialization helpers provided (dict/JSON)
- [ ] Comprehensive docstrings and diagrams published
- [ ] 95%+ unit test coverage across domain objects
- [ ] Mypy passes with strict optional checks enabled

## User Stories

| Story ID | Story Title | Est. | Status |
|----------|-------------|------|--------|
| [STORY-001-ValueObjects](./STORY-001-ValueObjects/README.md) | Implement Core Value Objects | 1d | 📋 |
| [STORY-002-MarketDataObjects](./STORY-002-MarketDataObjects/README.md) | Implement Market Data Entities | 1d | 📋 |
| [STORY-003-OrderObjects](./STORY-003-OrderObjects/README.md) | Implement Order Lifecycle Objects | 1d | 📋 |
| [STORY-004-PortfolioObjects](./STORY-004-PortfolioObjects/README.md) | Implement Portfolio Snapshots | 1d | 📋 |

**Total**: 4 Stories, ~48 Tasks, 4 days

## Technical Design (Draft)

### Module Structure
```
src/domain/models/
├── __init__.py
├── identifiers.py          # InstrumentId, StrategyId, VenueId
├── money.py                # Price, Quantity, Currency, Money
├── market_data.py          # MarketTick, Bar, BarGranularity
├── orders.py               # TradeIntent, OrderTicket, Fill, FillPolicy
└── portfolio.py            # PositionSnapshot, PortfolioSnapshot, RiskMetrics
```

### Patterns
- **Immutability**: Use `@dataclass(frozen=True)` and `Enum` types for categorical fields.
- **Validation**: Implement `__post_init__` to enforce invariants (positive quantities, UTC timestamps).
- **Type Safety**: Prefer explicit types (e.g., `Decimal`, `datetime`) over primitives.
- **Serialization**: Provide `.to_dict()` / `.from_dict()` helpers for persistence and messaging.

## Dependencies

### Requires
- Base type definitions from `src/core` (decimal precision, timezone helpers)
- `pydantic` or custom validation utilities (TBD)

### Blocks
- Backtesting (EPIC-002) adapters and analytics
- Paper/Live trading telemetry and reconciliation

## Testing Strategy

- Property-based tests for arithmetic invariants (Hypothesis)
- Snapshot tests for serialization routines
- Round-trip conversions (dict → object → dict)
- Error handling tests for invalid inputs

## Documentation

- UML class diagram for major aggregates
- Domain glossary entry updates
- Example usage snippets in developer guide

Keep metadata updated as stories progress and reflect completion percentages in the traceability matrix.
