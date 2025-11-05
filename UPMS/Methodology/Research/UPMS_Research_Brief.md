---
id: doc-upms-research-20251103
title: "Universal Product Management Meta-System Research Brief"
owner: "product_ops_team"
status: "draft"
last_review: "2025-11-03"
---

## How to use this doc
- Start here to understand the framing, scope, and constraints for the UPMS+M initiative.
- Follow the cross-references to seed companion artifacts (Methodology, Architecture, Meta-Templates, Knowledge Architecture, Metrics, Agentic Operating Model, Pilot Plan, Adoption Kit).
- Treat the deliverables list as the authoritative backlog for documentation work inside the vault.

## Executive overview
The Universal Product Management Meta-System and Methodology (UPMS+M) aims to provide a high-level, domain-agnostic operating model for product management teams working alongside agentic AI. The system must balance rigor (traceability, compliance, safety) with modularity (composable primitives, domain extension packs). The pilot deployment targets an algorithmic trading platform, but all structures must generalise to non-software and regulated domains.

### Objectives
- Deliver a reusable meta-system that encodes universal structures (hierarchy, ER model, governance) while allowing extension packs per domain.
- Provide a lightweight yet enforceable methodology that orchestrates human-in-the-loop (HITL) agentic development cycles.
- Ensure vault-native knowledge hygiene so agents can navigate, enrich, and reuse artifacts safely.

### Guardrails
- Remain at the architectural and operating-model altitude; avoid low-level schemas or vendor-specific tooling.
- Output Markdown/YAML artefacts that keep Obsidian as the source of truth.
- Preserve adoptability: the full method should be deployable in under two weeks for a new team.

## Research inputs (baseline)
- Obsidian vault: `/Users/nitindhawan/SynapseTrading_Knowledge/Synapse_Dev_Vault` (Markdown + YAML + mermaid).
- MCP servers provide safe tool-mediated access for file ops, linting, Obsidian REST API, and automation bridges.
- Dual-track methodology brief supplied by stakeholders (Discovery vs Delivery, Agentic Loop, EKL pipeline, risk posture).

## Methodology backbone
The operating model is a six-phase lifecycle with gated transitions and explicit HITL checkpoints.

| Phase | Gate | Focus | Key Artifacts |
| --- | --- | --- | --- |
| Inception | G0 | Charter, scope, risks, success criteria | `Charter.md`, initial `RiskLog.md` |
| Discovery | G1 | Context map, stakeholder map, constraints, experiments | `ContextMap.md`, ADR log |
| Definition | G2 | Universal hierarchy fit, ER model, governance, metrics design | `UPMS-Hierarchy.md`, `ER-Model.md`, `MetaTemplates.md`, `MetricsMap.md` |
| Delivery | G3 | Agentic build loop, execution controls, observability | `PilotPlan.md`, updated ADRs, structured progress reports |
| Validation | G4 | Fit-for-purpose tests, compliance sign-off, pilot readiness | Validation checklist, approvals register |
| Operate & Learn | G5 | Retrospectives, EKL loop, template evolution | `Postmortem.md`, learning digests, change logs |

### Stage-gate principles
- Each gate requires linked evidence artefacts plus human approval (Method Lead + domain owners + Compliance where applicable).
- Gate reviews pull from metrics dashboards, risk logs, and ADR status; no undocumented exceptions.
- Gate exit checklists must include knowledge hygiene checks (front-matter completeness, last_review < 30d for active docs).

## Dual-track delivery model
- **Discovery track** explores uncertainty via research spikes, experiments, and stakeholder interviews. Outputs accumulate as ADRs, risk updates, and context maps.
- **Delivery track** executes approved ADRs through the Agentic Loop.
- Tracks sync in Weekly UPMS Council to harmonise discovery learnings with delivery commitments.

## Agentic development loop (HITL)
```
Spec → Dry Run (simulation / offline validation) → Human Review (checklist) → Execute (agentic automation) → Structured Update (docs + links) → Measure (dashboards) → Exception escalation (Council)
```
- **Spec:** manifests as Markdown briefs or meta-templates; includes acceptance criteria, guardrails, and observability plan.
- **Dry Run:** agents perform non-destructive rehearsal (sandbox runs, mocked APIs) with captured evidence.
- **Human Review:** Method Lead or delegate validates against checklists; approvals recorded in `ChangeLog.md` or ADR updates.
- **Execute:** automation runs with logging & telemetry; outputs versioned artefacts and metrics.
- **Structured Update:** agents append results to relevant docs via MCP with deterministic formatting.
- **Measure:** dashboards capture outcome/process/risk metrics; anomalies trigger exception handling.

## Universal hierarchy & ER model themes
- Hierarchy spine (Portfolio → Program → Product → Epic → Capability → Story → Subtask) remains consistent across domains; domain packs add specialised nodes (e.g., for trading: Strategy, Signal, Model).
- ER model must accommodate core artefacts: Goals/OKRs, Roadmaps, ADRs, Risks, Experiments, Specs, Tests, Releases, Runbooks, Metrics.
- Link types (e.g., `influences`, `implements`, `mitigates`, `blocked_by`) define navigable relationships. YAML `links` arrays standardise machine consumption.

## Meta-template framework
- Templates describe required front-matter, structural sections, and knowledge hygiene rules.
- `MetaTemplates.md` should encode: template purpose, field definitions, required links, quality bars, and HITL checkpoints.
- Templates compose along the hierarchy: Charter references Program template; Capability template inherits from Story template with additive fields.

## Knowledge architecture (EKL)
- **Event → Knowledge → Learning** pipeline ensures every significant event (experiment, deployment, incident) produces archival knowledge and surfaced insights.
- Weekly, bi-weekly, monthly, and quarterly ceremonies map to specific EKL outputs:
  - Weekly Council: decision digest, risk updates, metric deltas.
  - Bi-weekly Program Review: dependency map, cross-product impacts.
  - Monthly Learning Review: EKL insights, template adjustments.
  - Quarterly Meta-Retrospective: hierarchy/ER validation, governance tune-up.
- Vault hygiene rules: stable IDs, controlled tags, backlinks usage, last_review freshness, lint automation to enforce schema.

## Metrics & evidence model
- **Outcome:** OKR attainment, customer/business value realisation.
- **Process:** cycle time, lead time to decision, WIP, blocked time.
- **Risk/Quality:** escaped defects, compliance exceptions, audit pass rate, control evidence age.
- **Knowledge:** note density, orphan rate, backlink depth, time-to-insight post-event.
- **AI:** agent precision/recall on summaries, false-action rate, human rework percentage.
- Dashboards should support roll-ups at any hierarchy level and provide visualisations (burn up/down, risk heatmaps, cadence charts).

## Automation & intelligence scope
- Automate deterministic tasks (linting, link graph exports, ADR scaffolding, change logs) via MCP servers.
- Keep humans in approval loops for non-reversible actions and gating decisions.
- Maintain a prompt registry with versioning, guardrails, and QA bars; align prompts with template schemas.
- Exception handling: define criteria for escalation (metric thresholds, missing artefacts, lint failures) and route through Council.

## Risk & compliance considerations (trading emphasis)
- Segregate responsibilities: research vs execution vs risk approval, with explicit RACI mapping.
- Enforce progression: backtest → paper → restricted live; each transition requires documented evidence and approvals.
- Model risk governance: versioned configs, reproducibility metadata, monitoring hooks, incident postmortems.
- Auditability: immutable ADRs, gated release notes, change logs tied to metrics and sign-offs.

## Adoption roadmap (30/60/90)
- **0–30 days:** Vault audit, publish v0 methodology + hierarchy/ER, align lint rules, run discovery sprint, start Weekly Council.
- **31–60 days:** Build Meta-Templates v1, MetricsMap v1, dashboards; formalise Agentic Loop checklists; execute paper pilot with G3→G4 gating.
- **61–90 days:** Extend to second domain via extension packs; codify governance pack; hold quarterly meta-retro; assemble adoption kit.

## Deliverables backlog (vault targets)
1. `UPMS-Methodology.md`
2. `UPMS-Architecture.md`
3. `UPMS-MetaTemplates.md`
4. `UPMS-Knowledge-Architecture.md`
5. `UPMS-Metrics-and-Dashboards.md`
6. `UPMS-Agentic-Operating-Model.md`
7. `UPMS-Pilot-Plan-Algotrading.md`
8. Adoption kit: `UPMS-QuickStart.md`, `Training-Plan.md`, `Glossary-&-Vocab-Packs.md`

Each document requires YAML front-matter (id, title, owner, status, last_review) and a "How to use this doc" section. Decision artefacts must capture measurable impact, linked metrics, and rollback paths.

## Open questions & next steps
- Confirm Obsidian Local REST API plugin availability to enable automated linting and knowledge hygiene jobs.
- Finalise owner assignments for each deliverable (Method Lead, Vault Steward, Agent Wrangler).
- Schedule first Weekly UPMS Council and Monthly Learning Review.
- Determine metric instrumentation stack (data sources, refresh cadence, dashboard tooling) without locking into a vendor.
- Draft initial ADRs for hierarchy choices and EKL governance.
