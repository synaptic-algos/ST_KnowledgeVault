---
id: TESTPLAN-EPIC-004
epic_id: EPIC-004
status: draft
owner: qa_architecture_team
last_review: 2025-02-15
related_features:
  - FEATURE-001-LiveAdapter
  - FEATURE-002-RiskManagement
  - FEATURE-003-KillSwitch
  - FEATURE-004-Monitoring
  - FEATURE-005-AuditLogging
  - FEATURE-006-Reconciliation
  - FEATURE-007-ProductionValidation
---

# EPIC-004: Live Trading – Test Plan

## Scope & Objectives
- Live adapter handshake + auth flows validated against sandbox.
- Risk controls (exposure, max-loss) trip within SLA.
- Kill switch + monitoring alerts propagate to partners.
- Audit + reconciliation prove trade-level accuracy.

## Test Buckets
| Bucket | Purpose | Primary Test Paths | Owner | Automation |
| --- | --- | --- | --- | --- |
| Adapter Smoke | Live adapter sandbox handshake tests | `tests/live_trading/adapter/` | execution_team | planned |
| Risk Controls | Unit + integration tests for guardrails | `tests/live_trading/risk/` | risk_team | backlog |
| Kill Switch & Monitoring | End-to-end kill switch drills | `tests/live_trading/monitoring/` | sre_team | backlog |
| Production Simulation | Replay + dry-run on staging | `tests/epics/epic_004_live_trading/` | sre_team | backlog |

## Execution Cadence
- CI target: `make test-epic_004_live_trading` → runs the buckets marked *planned*.
- Nightly regression: `pytest tests/epics/epic_004_live_trading/` plus module buckets as they come online.
- Manual gate: rerun all buckets before advancing this epic’s gate review.

## Reporting & Traceability
- Update `REQUIREMENTS_MATRIX.md` “Linked Tests” with `tests/<path>::TestClass::test_case` identifiers when new tests ship.
- Sprint summaries must record pass/fail + coverage deltas referencing this plan.
- Store logs/artifacts next to sprint execution summaries for audit (e.g., `Sprints/.../artifacts/epic_epic-004_tests/`).

## Open Items
- [ ] Promote bucket owners and scheduling in Sprint 1 backlog.
- [ ] Automate the `make test-epic_004_live_trading` target once first suite lands.

## Change Log
- 2025-02-15 – qa_architecture_team – Initial scaffold.
