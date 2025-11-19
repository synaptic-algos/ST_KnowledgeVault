---
id: EPIC-007
seq: 7
title: Strategy Lifecycle
owner: strategy_ops_team
status: in_progress
artifact_type: epic_overview
related_epic:
- EPIC-007
related_feature:
- FEATURE-001-ResearchPipeline
- FEATURE-002-PrioritisationGovernance
- FEATURE-003-ImplementationBridge
- FEATURE-004-DeploymentRunbooks
- FEATURE-005-ContinuousOptimization
- FEATURE-006-DataPipeline
related_story:
- STORY-006-01
created_at: 2025-11-03 00:00:00+00:00
updated_at: '2025-11-13T06:08:36Z'
last_review: '2025-11-13'
change_log:
- 2025-02-15 - data_engineering_team - Consolidated Nautilus catalog documentation
  into DESIGN-010 and sprint artifacts.
- 2025-11-04 - SPRINT-20251104-epic007-data-pipeline - Data pipeline delivered with
  Greeks + Nautilus catalogs.
- 2025-11-12 - Updated progress to 17% (1/6 Features complete)
- 2025-11-04 - Sprint 0 completed (FEATURE-006-DataPipeline)
- 2025-11-03 - Scaffolded strategy lifecycle epic structure
progress_pct: 16.67
requirement_coverage: 17
linked_sprints:
- SPRINT-20251104-epic007-data-pipeline
last_test_run:
  date: '2025-11-04T18:00:00Z'
  suite: Unit Tests - Greeks Calculator
  location: tests/data_pipeline/greeks/test_black_scholes_model.py
  result: pass
  pass_count: 31
  fail_count: 0
  total_count: 31
  duration_seconds: 0.8
test_run_history:
- date: '2025-11-04T18:00:00Z'
  suite: Unit Tests - Greeks Calculator
  result: pass
  pass_count: 31
  fail_count: 0
  sprint_id: SPRINT-20251104-epic007-data-pipeline
  notes: Data pipeline Greeks calculator validation - all delta/gamma/theta/vega/rho
    tests passing
- date: '2025-11-04T16:30:00Z'
  suite: Integration Tests - Data Pipeline
  result: pass
  pass_count: 3
  fail_count: 0
  sprint_id: SPRINT-20251104-epic007-data-pipeline
  notes: Parser validation, batch verification, catalog integration
---

# EPIC-007: Strategy Lifecycle

- **PRD**: [EPIC-007 Strategy Lifecycle PRD](./PRD.md)
- **Requirements**: [Requirements Matrix](./REQUIREMENTS_MATRIX.md)
- **Gate Status**: G0 (Ideation) – awaiting prioritisation council alignment
- **Roadmap**: [[../../ROADMAP.md#phase-4-strategy-operations--continuous-improvement-ongoing|Phase 4: Strategy Operations (Ongoing)]] - See [Product Roadmap](../../ROADMAP.md)

## Related Design Documents

- **[[../../Design/DATA-PIPELINE-ARCHITECTURE|Data Pipeline Architecture]]** - NSE options data → Database → Nautilus catalogs
- **[[../../Design/EPIC-007-STRAT-001-IMPLEMENTATION-PROPOSAL|EPIC-007 + STRAT-001 Implementation Proposal]]** - Comprehensive implementation approach bridging EPIC-007 and STRAT-001
- **[[../../Design/DESIGN-009-GreeksNautilusIntegrationPlan|Greeks Integration with Nautilus]]** - Strategy for keeping Greeks separate from OHLCV
- **[[../../Design/DESIGN-010-NautilusCatalogApproach|Nautilus Catalog Integrity & Greeks Sidecar Pattern]]** - Ensures native catalogs with separate Greeks storage

## Sprint History

- **[[../../Sprints/SPRINT-20251104-epic007-data-pipeline/SUMMARY|Sprint 0: Data Pipeline Infrastructure]]** (2025-11-04) - ✅ COMPLETE

## Epic Overview

**Epic ID**: EPIC-007  
**Title**: Strategy Lifecycle  
**Duration**: Continuous, reviewed quarterly  
**Status**: 📋 Planned  
**Priority**: P0 (Drives revenue roadmap)  
**Owner**: Strategy Operations Team + Product Owner

## Description

Define and operate the end-to-end lifecycle that takes a trading strategy from ideation through research, governance, implementation, deployment, and ongoing optimisation. The lifecycle provides backward integration into platform work, ensuring each strategy is production-ready and observable.

## Business Value

- Ensures strategy pipeline is transparent and prioritised against capital allocation goals
- Creates repeatable hand-offs between research, engineering, and operations
- Improves deployment readiness and compliance documentation
- Provides telemetry for post-trade evaluation and continuous improvement

## Success Criteria

- [ ] Strategy intake process documented with scoring model and approval gates
- [ ] Research artefacts standardised with template and storage conventions
- [ ] Implementation hand-off package defined (design brief, acceptance checklist)
- [ ] Deployment runbooks implemented for paper → live transitions
- [ ] Post-deployment reviews scheduled with KPIs + guardrails
- [ ] Strategies catalogued with status tracking (Idea → Research → Prioritised → In Dev → Paper → Live → Retired)

## Features

| Feature ID | Feature Name | Stories | Est. Days | Actual | Status |
|------------|--------------|---------|-----------|--------|--------|
| [FEATURE-001-ResearchPipeline](./FEATURE-001-ResearchPipeline/README.md) | Research Intake & Discovery Workflow | 4 | 6 | - | 📋 Planned |
| [FEATURE-002-PrioritisationGovernance](./FEATURE-002-PrioritisationGovernance/README.md) | Prioritisation Council & Scoring | 3 | 4 | - | 📋 Planned |
| [FEATURE-003-ImplementationBridge](./FEATURE-003-ImplementationBridge/README.md) | Implementation Handoff & Traceability | 3 | 4 | - | 📋 Planned |
| [FEATURE-004-DeploymentRunbooks](./FEATURE-004-DeploymentRunbooks/README.md) | Deployment & Rollout Playbooks | 3 | 5 | - | 📋 Planned |
| [FEATURE-005-ContinuousOptimization](./FEATURE-005-ContinuousOptimization/README.md) | Post-Trade Analytics & Iteration | 4 | 5 | - | 📋 Planned |
| [FEATURE-006-DataPipeline](./FEATURE-006-DataPipeline/README.md) | Historical Data Pipeline & Greeks Calculation | 1 | 10 | 1d | ✅ Complete |

**Total**: 6 Features, 18 Stories
**Progress**: 1/6 Features complete (17%)
**Completed**: [[../../Sprints/SPRINT-20251104-epic007-data-pipeline/SUMMARY|Sprint 0: Data Pipeline]] (2025-11-04)

## Milestones

1. **Lifecycle Framework Approved** – council charter, templates, and tooling in place
2. **First Strategy Through Pipeline** – strategy exits deployment gate using new process
3. **Quarterly Portfolio Review** – continuous optimisation cadence established

## Dependencies

### Prerequisites
- Research tooling (data access, notebooks) configured and documented
- Platform foundation (EPIC-001) and testing (FEATURE-005) to support new strategies
- Governance stakeholders aligned on OKRs and risk thresholds

### Blocks
- Backtesting (EPIC-002) and paper trading (EPIC-003) integration for validation steps
- Live trading controls (EPIC-004) for deployment gating

## Key Deliverables

### Process Deliverables
- Strategy intake form & scoring rubric
- Research artefact template with reproducibility checklist
- Implementation handoff package (architecture brief, test plan, risk assessment)
- Deployment runbook covering paper and live transition steps
- Post-deployment review template with KPI dashboards

### Documentation Deliverables
- Strategy catalogue with lifecycle status board
- Governance council charter and meeting cadence
- Backward integration playbook aligning strategy artefacts to platform components

## Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Fragmented research artefacts | 🔴 High | 🟡 Medium | Enforce templates + storage policies |
| Governance bottlenecks | 🟡 Medium | 🟡 Medium | Define SLA, asynchronous scoring |
| Handoff gaps to engineering | 🔴 High | 🟡 Medium | Checklists, joint review sessions |
| Deployment regressions | 🔴 High | 🟡 Medium | Pre-deployment simulation, rollback runbook |

## Lifecycle Phases

1. **Discover** – capture ideas, run exploratory research, assess viability
2. **Prioritise** – score strategies, align with capital/risk budgets
3. **Produce** – formalise design, hand off to engineering, track build progress
4. **Deploy** – run paper/live trials with runbooks and monitoring
5. **Optimise** – evaluate performance, iterate, or retire

## Acceptance Criteria

### Operational
- [ ] End-to-end process documented and accessible
- [ ] Roles and responsibilities defined across teams
- [ ] RACI chart maintained for each gate
- [ ] Communication cadence set (weekly standup, monthly council)

### Tooling
- [ ] Strategy tracking dashboard live (Notion/Jira integration or equivalent)
- [ ] Templates stored in `SynapticTrading_Product/Strategies/Templates`
- [ ] Automation hooks defined for moving strategies between states

### Metrics
- [ ] Time-to-deploy tracked from intake to live launch
- [ ] Hit rate (research ideas → deployed strategies)
- [ ] Post-deployment alpha decay monitored

Keep this epic updated as the lifecycle framework evolves and ensure cross-links exist into platform epics when strategy requirements intersect engineering deliverables.
