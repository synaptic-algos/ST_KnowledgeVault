---
artifact_type: prd
change_log: null
created_at: '2025-11-25T16:23:21.650951Z'
id: prd-epic-001-foundation
last_approved_by: TBD
last_review: 2025-11-03
lifecycle_phase: G1
manual_update: true
owner: product_ops_team
related_epic: null
related_feature: null
related_story: []
requirement_coverage: TBD
scope_level: epic
seq: 1
status: draft
title: EPIC-001 Foundation & Core Architecture PRD
updated_at: '2025-11-25T16:23:21.650954Z'
version: 0.1.0
---

## How to use this document
- Authoritative requirements reference for EPIC-001.
- Update together with `REQUIREMENTS_MATRIX.md`; every requirement change must be reflected in both files and logged in the changelog.
- Link supporting research and design artefacts inline.

## 1. Summary
Establish the foundational architecture for the framework-agnostic trading platform, covering standardised port interfaces, canonical domain model, core strategy abstractions, orchestration layer, and testing infrastructure. This epic unlocks downstream capabilities (backtesting, paper, live trading) by providing stable, testable building blocks.

## 2. Goals & Non-Goals

### Goals
| Goal ID | Description | Metric | Target |
| --- | --- | --- | --- |
| GOAL-1 | Enable framework-agnostic strategy execution | Example strategy executes via mock ports | Demo complete by Week 4 |
| GOAL-2 | Provide canonical domain model | Domain objects available and documented | 100% coverage of core objects |
| GOAL-3 | Establish testing infrastructure | Automated tests covering domain and ports | ≥90% coverage |

### Non-Goals
| Non-Goal | Rationale |
| --- | --- |
| Deliver production adapters | Deferred to EPIC-005 |
| Implement live trading controls | Covered by EPIC-004 |
| Optimise for exotic asset classes | Scoped for later strategy epics |

## 3. Stakeholders & RACI
| Role | Name | Responsibilities | R/A/C/I |
| --- | --- | --- | --- |
| Method Lead | TBD | Gate reviews, methodology alignment | A |
| Product Lead | TBD | Business outcomes, backlog | R |
| Lead Architect | TBD | Technical architecture | R |
| Compliance | TBD | Trading controls review | C |
| Engineering Team | TBD | Delivery | R |

## 4. Requirements Overview
Detailed requirements tracked in `REQUIREMENTS_MATRIX.md`. Highlights:
- Standardise five core port interfaces for market data, time, execution, portfolio, telemetry.
- Define canonical domain value objects supporting option strategies.
- Provide lifecycle-managed base strategy class with dependency injection.
- Implement orchestration bootstrapper and dispatchers.
- Establish mocks and testing frameworks with ≥90% coverage.

## 5. Assumptions & Constraints
- Initial scope focuses on equity/ETF options; other asset classes deferred.
- Python 3.11 runtime; adhere to 100-character line limits.
- Should integrate with future backtesting engine via stable port contracts.
- Compliance requires documented sign-off before moving to paper trading.

## 6. Research & Evidence
- `res-technical-20251015-01` – Port abstraction lessons from legacy pilot.
- `res-market-20251020-02` – Strategy requirements for options hedging.
- `res-lesson-20251028-03` – Testing pitfalls identified in pilot issues.

## 7. Design Alignment
- `DESIGN-PORTS-001` – Port interface specifications.
- `DESIGN-STRAT-001` – Strategy lifecycle state machine.
- `DESIGN-ORCH-001` – Orchestration topology and DI configuration.

## 8. Testing Strategy
- Unit tests across domain and ports using pytest + hypothesis.
- Contract tests ensuring adapter compliance via shared fixtures.
- Scenario tests running mock strategy flows.
- Code coverage thresholds: domain/ports ≥90%, orchestration ≥85%.

## 9. Rollout & Adoption
- Sequence: backtest environment → paper → restricted live (post EPIC-003/004).
- Deliver developer guides and port API docs for downstream teams.
- Schedule enablement sessions with strategy engineers during G3.

## 10. Risks & Mitigations
| Risk ID | Description | Impact | Mitigation | Owner |
| --- | --- | --- | --- | --- |
| RISK-EP1 | Port abstraction misalignment with future adapters | High | Conduct design reviews with adapter team; iterate prototypes | Lead Architect |
| RISK-EP2 | Domain model complexity creep | Medium | Start minimal, review weekly, document decisions in ADRs | Product Lead |
| RISK-EP3 | Testing infrastructure underutilised | Medium | Enforce test requirements in Definition of Done; integrate with CI | Engineering Lead |

## 11. Changelog
- 2025-11-03 – product_ops_team – Initial PRD draft captured from legacy epic README – REQ-EPIC001-001
