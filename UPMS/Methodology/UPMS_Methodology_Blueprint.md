---
id: doc-upms-methodology-blueprint-20251103
title: "UPMS Methodology Blueprint"
owner: "product_ops_team"
status: "in_progress"
last_review: "2025-11-03"
links:
  - documentation/productmanagement/README.md
  - documentation/research/01_Product_Managamement_System/UPMS_Research_Brief.md
  - documentation/research/01_Product_Managamement_System/Methodology_and_Vault_Study.md
---

## How to use this doc
- Reference guide for running the Universal Product Management Meta-System (UPMS) with agentic development teams.
- Read alongside the research brief for context and the upcoming templates pack for implementation details.
- Use the checklists and workflows herein to configure the vault, stage gates, sprints, and research cadence.

## 1. Methodology overview
- Lifecycle phases: **Inception → Discovery → Definition → Delivery → Validation → Operate & Learn**. Each phase is gated (G0–G5) with required artefacts and human approvals.
- Delivery teams operate in variable-length sprints linked to epic/feature/story nodes via metadata; sprints live in a central `UPMS/Sprints` directory.
- Research workfeeds the Discovery backlog continuously, with a dedicated vault area capturing market, technical, risk, optimisation, and lessons-learned artefacts.
- Hybrid task model: inline checklists for lightweight tasks, dedicated `TASK-###` notes whenever traceability, approvals, or automation hooks are necessary.

### Phase summary & gate criteria
| Phase | Gate | Core Activities | Required Artefacts (inline = must be updated) | Approval Roles |
| --- | --- | --- | --- | --- |
| Inception | G0 | Charter, scope, success criteria, initial OKRs, stakeholder alignment | `Charter.md`, `RiskLog.md`, sprint 0 plan (if applicable) | Method Lead (A), Product Lead (R), Compliance (C) |
| Discovery | G1 | Research backlog triage, experiments, stakeholder interviews, context mapping | `ContextMap.md`, Discovery research notes (market/technical), initial ADRs, Research backlog board | Method Lead (A), Product Lead (R), Vault Steward (C) |
| Definition | G2 | Hierarchy fit, ER model, governance rules, metrics design, template selection | `UPMS-Hierarchy.md`, `ER-Model.md`, `MetaTemplates.md`, `MetricsMap.md`, updated ADRs | Method Lead (A), Product Lead (R), Compliance (C), Agent Wrangler (C) |
| Delivery | G3 | Agentic loop execution, sprint management, design approvals, traceability updates | Sprint docs, `REQUIREMENTS_MATRIX.md`, feature `TRACEABILITY.md`, design records, updated issues | Product Lead (A), Engineering Lead (R), Compliance (C), Method Lead (C) |
| Validation | G4 | Fit-for-purpose testing, compliance sign-off, pilot plan readiness | `PilotPlan.md`, validation checklist, risk controls evidence, test coverage report | Compliance/Risk (A), Product Lead (R), Method Lead (C) |
| Operate & Learn | G5 | Postmortems, EKL pipeline, metrics review, template evolution | `Postmortem.md`, learning digest, updated templates, change logs | Method Lead (A), Vault Steward (R), Stakeholders (C/I) |

### Ceremonies & cadence
- **Weekly UPMS Council**: review risks, decisions, research deltas, sprint status; log outcomes in `UPMS/Ceremonies/Weekly_Council.md` with change log entry.
- **Bi-weekly Program Review**: cross-epic dependencies, capacity balancing, metrics roll-up.
- **Monthly Learning Review**: curate EKL pipeline outputs, retire stale knowledge artefacts, adjust templates.
- **Quarterly Meta-Retrospective**: revalidate hierarchy, ER relationships, and governance policies.
- **Continuous Agent Watch**: monitor automation exception logs, lint results, change drift dashboards.

## 2. Sprint operating model
- Central directory: `UPMS/Sprints/SPRINT-<YYYYMMDD>-<slug>/README.md`.
- Front-matter fields: `id`, `title`, `owner`, `status`, `type`, `duration_days`, `start_date`, `end_date`, `related_items` (list of epic/feature/story IDs), `objectives`, `metrics_baseline`, `metrics_target`, `change_log`.
- Body sections: Goals, Planned Scope (tables referencing stories/tasks), Research Inputs, Risks/Dependencies, Completion Report, Metrics Summary, Retrospective Notes.
- Variable sprint lengths allowed; align each sprint to gate objectives and specify whether it is Discovery, Definition, Delivery, Validation, or Operate-focused.
- Completion tracking: each epic/feature/story front-matter maintains `progress_pct`, `requirement_coverage`, and `linked_sprints`. Update these fields at sprint close via the sprint retro checklist.

### Sprint workflow
1. **Plan**: define objectives, relate items (epics/features/stories/tasks/issues), capture entry criteria and expected gate impact.
2. **Execute**: run agentic loop cycles (Spec → Dry Run → Human Review → Execute → Structured Update → Measure → Exception routing), recording approvals in design docs and sprint notes.
3. **Review**: update requirement matrices, issues, metrics dashboards; log outcomes in sprint README and gate checklist.
4. **Retrospective**: capture insights under EKL pipeline; flag new watchouts/optimisations for the Research backlog.

## 3. Research pipeline
- Vault location: `UPMS/Research/` with subdirectories `Market/`, `Technical/`, `Risk/`, `Optimization/`, `Lessons/`.
- Front-matter template (baseline):
  ```yaml
  id: res-<domain>-<date>-<seq>
  seq: <integer>
  title: "..."
  owner: "..."
  status: proposed|active|accepted|archived
  artifact_type: research|watchout|suggestion|guide|optimization
  related_epic: []
  related_feature: []
  related_story: []
  related_requirement_ids: []
  related_design_ids: []
  created_at: <ISO8601>
  updated_at: <ISO8601>
  last_review: <ISO8601>
  change_log:
    - 2025-11-03 – owner – Initial draft – n/a
  ```
- Body standard: Summary, Evidence & Data, Insights, Recommendations, Next Actions (including promotion candidates), References.
- Research backlog management:
  - Continuous triage during Weekly Council.
  - Discovery sprints pull from backlog; promotion recorded in change log and, when applicable, in PRD requirements via `Origin` column and YAML `related_requirement_ids`.
  - Flexible linkage: research may stand alone (futures work), attach to designs, or feed requirements. Traceability views generated per epic/feature when needed.

## 4. Design & test governance
- **Design approval** is mandatory before development or major bug fixes commence.
  - Design docs stored under `UPMS/Designs/DESIGN-<id>/README.md` with front-matter mirroring requirements metadata plus `approval_status`, `approver`, `approval_date`.
  - Checklist: stakeholders consulted, interfaces defined, risk assessment, test strategy, rollback plan.
  - Approved design IDs referenced in story/task front-matter (`design_ids: []`).
- **Test-driven approach**:
  - Each requirement in the matrix maps to explicit tests (unit/integration/backtest) with identifiers logged in the matrix `Tests` column.
  - Validation gate requires test evidence attachments/links (logs, coverage reports).
  - Issues closing major gaps must include updated design/test documentation before resolution is marked complete.

## 5. Traceability model
- **Epic-level** `REQUIREMENTS_MATRIX.md` columns: `Requirement ID | Description | Origin (Research/Design/Issue) | Linked Stories | Linked Tasks | Linked Tests | Status | Notes`.
- **Feature-level** `TRACEABILITY.md`: table of stories/tasks/tests with status and sprint linkage.
- **Story front-matter** sample:
  ```yaml
  id: STORY-001-PortInterfaces
  title: "Implement Market Data Port"
  owner: "eng_team"
  status: in_progress
  sprint_ids: ["SPRINT-20251108-foundation"]
  requirement_ids: ["REQ-EPIC001-001"]
  design_ids: ["DESIGN-PORT-001"]
  tasks_inline: false
  progress_pct: 45
  last_review: 2025-11-03
  change_log:
    - 2025-11-03 – eng_team – Updated progress to 45% – REQ-EPIC001-001
  ```
- **Task nodes** (`TASK-###`) carry owner, estimate, sprint, status, related_story, related_tests, change log. Inline tasks tracked via checklist but must still update story progress fields.
- **Issues**: maintained in `UPMS/Issues/ISSUE-<timestamp>-<slug>.md` with lifecycle metadata (`status: identified|analysis|wip|validation|resolved`) and references to epics/features/stories/tasks.

## 6. Vault architecture (Synaptic Trading Knowledge Vault)
```
UPMS/
├── Methodology/
│   ├── Blueprint.md (this doc)
│   ├── Gate_Checklists/
│   └── Ceremonies/
├── Hierarchy/
│   ├── UPMS-Hierarchy.md
│   ├── ER-Model.md
│   └── Governance/
├── Templates/
│   ├── PRD_Template.md
│   ├── Requirements_Matrix_Template.md
│   ├── Sprint_Template.md
│   ├── Research_Note_Template.md
│   ├── Design_Doc_Template.md
│   └── Issue_Template.md
├── Sprints/
│   └── SPRINT-YYYYMMDD-slug/
├── Research/
│   ├── Market/
│   ├── Technical/
│   ├── Risk/
│   ├── Optimization/
│   └── Lessons/
├── Issues/
│   ├── README.md (workflow)
│   └── ISSUE-<timestamp>-*.md
├── Designs/
│   └── DESIGN-*/
├── Metrics/
│   ├── Dashboard_Specs.md
│   └── Measurement_Plan.md
├── Knowledge/
│   ├── Watchouts/
│   ├── Guides/
│   ├── Best_Practices/
│   └── Optimisation/
└── Adoption/
    ├── UPMS-QuickStart.md
    ├── Training-Plan.md
    └── Glossary-&-Vocab-Packs.md
```
- All documents share the standard front-matter baseline plus type-specific fields.
- Legacy repo `documentation/` becomes reference-only; new content authored directly in the vault and pulled into code workflows via MCP.

## 7. Automation opportunities
- **Linting & metadata**: MCP job validates front-matter fields, change logs, and required sections per template.
- **Traceability upkeep**: script to sync `REQUIREMENTS_MATRIX.md` and feature `TRACEABILITY.md` from front-matter metadata (stories/tasks/issues/tests).
- **Sprint dashboards**: generate burn-up/down charts by aggregating progress fields; publish under `UPMS/Metrics/`.
- **Issue workflow**: automation to move issues between states based on status field, update sprint docs, and notify Weekly Council backlog.
- **Research promotion**: tool to flag research notes that lack follow-up, ensuring continuous flow into Discovery.

## 8. Immediate next steps
1. Create the `UPMS/` root in Synaptic Trading Knowledge Vault and scaffold directories listed above.
2. Port existing `documentation/` assets into new structures as needed (manual import per decision).
3. Author template files with locked front-matter schemas and changelog sections.
4. Define MCP lint rules for metadata validation and change-log enforcement.
5. Pilot the sprint template on the first variable-length sprint, linking to EPIC-001 nodes.
6. Stand up continuous Research backlog reviews during Weekly Council; capture outputs in the new research notes structure.

---

*Prepared 2025-11-03. Update this blueprint after initial vault scaffolding and sprint pilot are complete.*
