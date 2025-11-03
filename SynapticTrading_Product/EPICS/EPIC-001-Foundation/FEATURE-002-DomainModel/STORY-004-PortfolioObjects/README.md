# STORY-001-02-04: Implement Portfolio Snapshots

## Story Overview

**Story ID**: STORY-001-02-04  
**Title**: Implement Portfolio Snapshots  
**Feature**: [FEATURE-002: Canonical Domain Model](../README.md)  
**Epic**: [EPIC-001: Foundation & Core Architecture](../../README.md)  
**Status**: 📋 Planned  
**Priority**: P0  
**Assignee**: Senior Engineer 2  
**Estimated Effort**: 1 day (8 hours)

## User Story

**As a** portfolio risk analyst  
**I want** canonical portfolio snapshot objects  
**So that** strategies, risk engines, and monitoring tools observe consistent positions, cash, and risk metrics

## Acceptance Criteria

- [ ] `PositionSnapshot` captures instrument exposure, avg price, unrealized P&L, and greeks (optional)
- [ ] `PortfolioSnapshot` aggregates positions, cash balances, risk metrics, and NAV
- [ ] Provide helper to derive risk metrics (exposure, beta, VaR placeholder)
- [ ] Support diffing snapshots to highlight position changes
- [ ] Ensure serialization for telemetry + storage (dict/json)
- [ ] Unit tests cover aggregation math and rounding rules

## Technical Notes

- Introduce `CashBalance` dataclass grouped by currency
- Provide `PortfolioDelta` for change tracking between snapshots
- Align rounding to 2 decimal places for cash, 4 for quantities

## Tasks

| Task ID | Task Description | Est. | Status |
|---------|------------------|------|--------|
| [TASK-001-02-04-01](#task-001-02-04-01) | Create `portfolio.py` module skeleton | 0.5h | 📋 |
| [TASK-001-02-04-02](#task-001-02-04-02) | Implement `PositionSnapshot` dataclass | 1.5h | 📋 |
| [TASK-001-02-04-03](#task-001-02-04-03) | Implement `CashBalance` + helpers | 0.5h | 📋 |
| [TASK-001-02-04-04](#task-001-02-04-04) | Implement `PortfolioSnapshot` aggregate | 1.5h | 📋 |
| [TASK-001-02-04-05](#task-001-02-04-05) | Add derived metric helpers (exposure, NAV) | 1h | 📋 |
| [TASK-001-02-04-06](#task-001-02-04-06) | Implement snapshot diff utilities | 1h | 📋 |
| [TASK-001-02-04-07](#task-001-02-04-07) | Write unit tests for aggregation math | 1.5h | 📋 |
| [TASK-001-02-04-08](#task-001-02-04-08) | Document usage in monitoring + telemetry | 1h | 📋 |

## Task Details

### TASK-001-02-04-01
Create `src/domain/models/portfolio.py` with imports and module docstring describing responsibilities.

### TASK-001-02-04-02
Implement `PositionSnapshot` capturing instrument, quantity, cost basis, current price, unrealized P&L, and metadata (strategy, tags).

### TASK-001-02-04-03
Add `CashBalance` dataclass keyed by currency with helper to compute total converted to base currency.

### TASK-001-02-04-04
Implement `PortfolioSnapshot` containing positions, cash balances, exposure metrics, realized/unrealized P&L, and timestamp.

### TASK-001-02-04-05
Provide helper methods for gross/net exposure, leverage, and equity curve contribution.

### TASK-001-02-04-06
Implement diff utilities that compare two snapshots and produce list of position/cash deltas for reconciliation.

### TASK-001-02-04-07
Write tests verifying arithmetic, rounding, immutability, and diff outputs.

### TASK-001-02-04-08
Update documentation with examples for telemetry, reconciliation, and portfolio risk dashboards.
