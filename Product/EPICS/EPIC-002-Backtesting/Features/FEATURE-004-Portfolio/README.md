---
id: FEATURE-004-Portfolio
parent_epic: EPIC-002
title: Portfolio Accounting
owner: eng_team
status: completed
artifact_type: feature_overview
created_at: '2025-11-20T09:30:00+00:00'
updated_at: '2025-11-20T10:00:00+00:00'
progress_pct: 100
manual_update: true
seq: 4
related_epic: [EPIC-007]
related_feature: []
related_story: []
last_review: '2025-11-20'
change_log:
  - '2025-11-20 – eng_team – Marked complete: implementation from EPIC-007 satisfies requirements – RECONCILIATION'
  - '2025-11-20 – system – Feature placeholder created – EPIC-002'
requirement_coverage: 95
linked_sprints: []
---

# FEATURE-004: Portfolio Accounting

## Overview

Implement portfolio accounting that tracks positions, P&L, and equity curves during backtesting.

## Status

✅ **Completed** - Implementation reused from EPIC-007 (95% requirement coverage)

## Reconciliation Note

**Decision Date**: 2025-11-20

EPIC-007 (Strategy Lifecycle Management) independently implemented `portfolio.py` that satisfies EPIC-002 Feature 4 requirements. After code audit, determined that reusing this implementation avoids duplicate work while exceeding core requirements.

## Implementation Summary

**Source**: EPIC-007 (merged in PR #2)

**Components Delivered**:
- BacktestPortfolio class (599 lines)
- Position tracking with weighted average price
- Cash balance management (debit/credit on trades)
- Realized PnL calculation (on position close)
- Unrealized PnL calculation (mark-to-market)
- Equity curve snapshots
- PortfolioPort interface implementation
- Fill processing logic

**Test Coverage**:
- 20 passing tests
- Buy/sell order processing
- Position creation/update/close
- PnL calculations (realized + unrealized)
- Multiple positions
- Equity curve snapshots
- Edge cases (insufficient cash, zero quantities)

**Files**:
- `src/adapters/frameworks/backtest/portfolio.py`
- `tests/backtesting/portfolio/test_backtest_portfolio.py`

## Requirement Coverage: 95%

**Satisfied Requirements** ✅:
- Position tracking (create, update, close)
- Weighted average price calculation
- Cash balance management
- Realized PnL (locked in from closed positions)
- Unrealized PnL (mark-to-market with price updates)
- Equity curve snapshots (timestamp, equity, cash, unrealized)
- PortfolioPort interface compliance
- Multiple instrument support
- Fill processing with commission handling

**Known Gaps** ⚠️:
- Trade log detail (marked as TODO - line 350)
- Entry/exit timestamps for round-trip trades not fully captured

**Gap Resolution**:
- Trade log detail not critical for MVP backtesting
- Current realized PnL tracking sufficient for performance analysis
- Can be enhanced in Feature 5 (Analytics) if needed

## Acceptance Criteria

- [x] Position tracking working
- [x] Cash accounting correct
- [x] Realized PnL calculated on close
- [x] Unrealized PnL updated with market prices
- [x] Equity curve generated
- [x] PortfolioPort interface satisfied
- [x] Tests passing (20 tests)
- [ ] Detailed trade log (deferred to Feature 5)

## Dependencies

- FEATURE-003 (ExecutionSimulator) - completed ✅ (via EPIC-007)
