---
artifact_type: prd
change_log: null
created_at: '2025-11-25T16:23:21.660203Z'
id: prd-epic-007-strategy-lifecycle
last_approved_by: TBD
last_review: 2025-11-03
lifecycle_phase: G0
manual_update: true
owner: strategy_ops_team
related_epic: null
related_feature: null
related_story: []
requirement_coverage: TBD
scope_level: epic
seq: 7
status: draft
title: EPIC-007 Strategy Lifecycle PRD
updated_at: '2025-11-25T16:23:21.660207Z'
version: 0.1.0
---

## 1. Summary
A unified lifecycle guiding strategies from idea to live deployment and continuous optimisation. The lifecycle codifies research, governance, engineering handoff, deployment, and post-trade review, ensuring every strategy is measurable, auditable, and aligned with business objectives.

## 2. Goals & Non-Goals

### Goals
| Goal ID | Description | Metric | Target |
| --- | --- | --- | --- |
| G-007-01 | Establish governance for strategy intake and prioritisation | Time from submission to decision | < 10 business days |
| G-007-02 | Standardise handoff package for engineering | % strategies with complete dossier | 100% |
| G-007-03 | Provide deployment runbook | Deployment rollback readiness | 100% |
| G-007-04 | Capture post-deployment KPIs | Strategies with KPI dashboards | 100% |

### Non-Goals
- Building strategy alpha models (covered by research teams)
- Implementing automated capital allocation (future epic)
- Managing post-trade compliance obligations already handled by Ops

## 3. Users & Personas
- **Quant Researcher**: ideates and validates strategies; needs clear intake + research template.
- **Strategy Operations**: coordinates lifecycle; needs dashboard + governance framework.
- **Engineering Lead**: receives handoff package; needs explicit requirements + acceptance tests.
- **Risk Officer**: participates in prioritisation; needs risk scoring + gate artefacts.
- **Portfolio Manager**: monitors live performance; needs post-deployment reports.

## 4. Lifecycle Overview
1. **Intake & Research** – idea submission, scope definition, data validation, hypothesis testing.
2. **Governance & Prioritisation** – scoring rubric, council approval, scheduling.
3. **Implementation Handoff** – design dossier, requirements mapping, engineering tasks.
4. **Deployment & Rollout** – paper trading trials, go/no-go checklist, live deployment plan.
5. **Continuous Optimisation** – KPI tracking, variance analysis, iteration or retirement.

## 5. Requirements
See [Requirements Matrix](./REQUIREMENTS_MATRIX.md) for detailed mapping of needs to features and tests.

## 6. Success Metrics
- Lead time from intake to live <= 8 weeks (for target strategies)
- ≥ 80% strategies meeting post-deployment KPI targets after 3 months
- At least one quarterly retrospective with actionable insights per strategy

## 7. Assumptions
- Research teams have data access and computational resources.
- Governance council meets weekly with quorum.
- Platform epics deliver required infrastructure per roadmap (ports, orchestration, monitoring).

## 8. Open Questions
- Which tool will host the lifecycle dashboard (Jira, Notion, bespoke)?
- How to integrate risk capital limits into scoring rubric?
- Who signs off on decommissioning underperforming strategies?

## 9. Appendices
- Strategy intake form (draft)
- Scoring rubric (v0.1)
- Post-deployment review checklist
