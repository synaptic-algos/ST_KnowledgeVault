---
id: doc-upms-methodology-research-20251103
title: "UPMS Methodology & Knowledge Vault Study"
owner: "product_ops_team"
status: "in_research"
last_review: "2025-11-03"
links:
  - documentation/productmanagement/README.md
  - /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading/issues/README.md
  - /Users/nitindhawan/SynapseTrading_Knowledge/Synapse_Dev_Vault/03_MARKET_DOMAIN/72_Product_Management_Alt/README.md
---

## How to use this doc
- Working research log focused on methodology design and the supporting knowledge vault structure.
- Updated iteratively as we map existing practices, identify gaps, and propose alignment steps.
- Each section ends with open questions to confirm before moving into recommendations.

## 1. Current product-management hierarchy (repo view)
- `documentation/productmanagement/README.md` implements a strict **Epic → Feature → Story → Task** folder hierarchy with embedded status tracking.
- Every epic/feature/story README carries planning data (timeline, status emoji, checklists). Tasks remain inline inside story READMEs.
- PRD references currently live in `../prd/01_FrameworkAgnosticPlatform/`, separate from the execution hierarchy.
- No explicit traceability matrices exist yet; cross-links rely on manual references.
- **Task representation options**
  - *Inline checklists (current behaviour)*  
    - **Pros:** Lightweight; easy for authors to update; keeps story context in one file; minimal structural churn.  
    - **Cons:** Harder to reference tasks individually (no unique IDs); difficult to track completion programmatically; limited metadata (owners, estimates, sprint links).  
  - *Dedicated `TASK-###` nodes (one Markdown file per task)*  
    - **Pros:** Enables unique IDs, richer metadata (front-matter for owner, estimate, sprint, related tests); simplifies linking from sprints/issues/tests; supports automated reporting.  
    - **Cons:** Introduces folder/file proliferation; higher maintenance overhead; may feel heavy for very small tasks.
  - *Hybrid approach*  
    - Keep simple tasks as checklists but create `TASK-` files for high-impact work requiring traceability (e.g., external dependencies, compliance steps). Could add a front-matter field in stories (`tasks_inline: true/false`) to signal when dedicated nodes exist.
    - **Decision:** Adopt the hybrid model; inline checklists remain the default, but a `TASK-` directory is used whenever traceability, approvals, or automation hooks are needed.

**Questions**
1. Do you want the PRD folder to be retired once Epic-level PRDs are embedded alongside the epics, or should we keep both in parallel for a transition period? **(Decision: retire legacy PRD folder after Epic-level PRDs land; also allow higher-level product/portfolio PRDs and pre-epic PRDs for future initiatives.)**

## 2. Proposed Epic/Feature structure with PRDs & traceability
- Proposal: each epic gets `README.md`, `PRD.md`, `REQUIREMENTS_MATRIX.md`. Features inherit README with a requirements section + `TRACEABILITY.md` for stories/tasks/tests.
- Benefits align with your outline: single authoritative PRD per epic, lightweight feature docs, Markdown traceability tables.
- Need to decide how stories map into the matrix. Options:
  - Row per requirement referencing story IDs (`STORY-###`), tasks, test cases.
  - Use YAML front-matter in stories to declare `requirement_ids` for bi-directional linking.
- **Schema baseline:** adopt a standard requirements matrix column set (`Requirement ID | Description | Origin/Research Link | Stories | Tasks | Tests | Status | Notes`). Standardise PRD front-matter with `version`, `last_updated`, and maintain a changelog section per document.

**Questions**
1. Any epic-specific customisations needed beyond the baseline columns (if so, specify)?  
2. Should changelog entries follow a fixed template (e.g., date, author, summary, impacted requirements)? **(Decision: yes—lock the template `- YYYY-MM-DD – owner – summary – affected_requirements`.)**

## 3. Issue lifecycle alignment
- Separate repository (`pilot-synaptictrading/issues`) maintains a rich issue workflow: identified → wip → resolved, plus category folders (enhancements, performance, etc.).
- Templates enforce evidence, root-cause analysis, code references.
- Opportunities for integration:
  - Link issues to epic/feature via front-matter fields (`epic_id`, `feature_id`) and embed backlinks in the requirements matrices.
  - Establish lifecycle mapping: Issues in `identified/` correspond to Discovery/Definition phases; `wip/` ties to Delivery; `resolved/` feed Validation/Postmortem.
  - Consider a `ISSUE_INDEX.md` in each epic folder summarising active issues with status pointers to the issues repo.
- Plan (Nov 03): consolidate issues into a central folder within the new vault (e.g., `UPMS/Issues/`) and maintain cross-links to epics/features/stories. Legacy issue repo remains reference-only.

**Questions**
1. Should enhancements and performance analyses be treated as features/stories once approved, or remain ancillary documents linked to epics? **(Decision: once approved they graduate into formal features and/or stories for execution; ancillary notes remain only for context until that point.)**

## 4. Knowledge assets (watchouts, suggestions, guides, optimization)
- Multiple knowledge categories exist under `pilot-synaptictrading/documentation/` (watchouts, suggestions, guides, optimization) plus best practices.
- These capture learnings and recurring patterns that should feed the EKL loop and inform requirements/templates.
- Need a structured ingestion path into the Synapse vault: e.g., nightly/weekly review to convert relevant items into vault notes under specific knowledge packs.
- Direction: design new knowledge taxonomy within the vault rather than mirroring existing folder names. Define slots for watchouts, suggestions, guides, optimisation attempts, best practices, with consistent front-matter (classification, related_epic/feature/story, decision_status).
  - Minimum front-matter baseline: `id`, `seq`, `title`, `owner`, `status`, `artifact_type`, `related_epic`, `related_feature`, `related_story`, `last_review`, `created_at`, `updated_at`.
  - Change log requirements: maintain a datetime-stamped history list (`change_log:` array following the same format as requirements changelog). Provide tailored templates per artefact type.

**Questions**
1. How formalised should the learning artefacts be? (E.g., do we require YAML front-matter with `learning_type`, `related_epic`, `last_review`?)

## 5. Existing vault organisation insights
- Vault currently organised by major domains (Vault Management, Core Product, Market Domain, etc.) with navigation indexes and template libraries.
- Product management material sits under `03_MARKET_DOMAIN/72_Product_Management_Alt`, focusing on dashboard design and legacy docs.
- Opportunity: establish a dedicated `UPMS/` or `Product_Management/` pack with folders for methodology, hierarchy specs, templates, metrics, adoption kit—mirroring the deliverables backlog.
- Decision: create a new top-level `UPMS/` area in the Synaptic Trading Knowledge Vault (current vault is largely blank).

**Questions**
1. What retention policy should we apply for legacy material—archive in place or migrate into a `Legacy/` subfolder with deprecation notes?

## 6. Integration touchpoints for automation
- MCP servers (filesystem + Obsidian) can enforce linting, synchronize front-matter (`owner`, `status`, `last_review`), and maintain traceability tables.
- Potential automations:
  - Generate/update `REQUIREMENTS_MATRIX.md` from structured metadata in stories/issues.
  - Run lint job to ensure every doc has required fields and valid links.
  - Build dashboards for issue status vs UPMS phases.
- Automation constraints: none—new MCP scripts/tools can be added as needed.

**Questions**
1. Any constraints on using external packages for linting/report generation (given network access is allowed)?

## Next research steps (pending your answers)
1. Deep-dive into story templates to assess feasibility of metadata-based traceability.
2. Map watchouts/suggestions/best practices to EKL pipeline and propose vault ingestion workflow.
3. Draft methodology updates (gates, ceremonies, artefacts) aligned with the desired structure.

Please review the open questions; your guidance will shape the next research iteration and eventual recommendations.

## 7. Product development cadence & tracking thoughts
- Current docs emphasise hierarchy but not explicit sprint/iteration planning.
- Opportunity: introduce a cadence layer (e.g., 2-week sprints) that references work items via metadata.
- Possible structures:
  - Maintain `Sprints/SPRINT-YYYYWW/README.md` containing goals, committed stories, exit criteria, metrics. Each story/feature README lists `sprint_ids` in front-matter.
  - Alternatively, embed sprint sections inside epic/feature READMEs, but this risks bloat and harder cross-epic reporting.
- Tracking dimension should capture planned vs actual completion, dependencies, and links to issues/resolutions.
- Need to ensure sprint docs align with stage gates (G0–G5). For example, Discovery sprints capture research artefacts, Delivery sprints map to Agentic Loop cycles.
- Product development tracking should surface cumulative progress dashboards (burn-up/down, velocity trends) inside the vault or via linked dashboards.

**Questions**
1. Preferred sprint container: centralised `Sprints/` directory or embedded per epic? (Centralised aids cross-epic visibility; embedded tightens local context.)
2. Sprint cadence: do you want fixed-length (e.g., 14-day) sprints, or variable-length “iterations” tied to gate deliverables?
3. How strict should sprint commitments be? (Hard commitment tracked for velocity vs flexible buckets.)
4. Should we reuse existing documents (e.g., sprint summaries in issues repo) or create new vault-native sprint logs that reference those artefacts?

**Direction confirmed (Nov 03)**  
- Create a central `Sprints/` directory in the new vault (`/Users/nitindhawan/SynapseTrading_Knowledge/Synaptic_Trading_KnowledgeVault`) and link each sprint to epics/features/stories via front-matter (e.g., `related_items`, `epic_id`, `feature_id`, `story_id`).  
- Sprints run with variable lengths aligned to gate objectives; no fixed cadence requirement.  
- Sprint scope is a flexible planning bucket, but every epic/feature/story must expose accurate completion tracking (percentage complete, requirements covered, linked tests).  
- Build a fresh sprint documentation system from scratch; legacy sprint summaries in the issues repo remain as historical references only.  
- All repository documentation under `documentation/` will migrate into the new vault and be referenced from there.

## 8. Research stage emphasis
- Introduce an explicit **Research Stage** that precedes or runs parallel to Discovery. This stage curates market analysis, technical investigations, watchouts, optimisation attempts, and best-practice guides.  
- Proposed vault structure (within Synaptic_Trading_KnowledgeVault): `Research/` with subfolders for `Market`, `Technical`, `Risk`, `Optimization`, `Lessons & Watchouts`, each note carrying standard front-matter (`id`, `title`, `owner`, `status`, `related_epic`, `last_review`, `links`).  
- Research outputs must connect to requirements (e.g., PRD sections, requirement IDs) and inform sprint planning. Discovery gate (G1) checklists will require referenced research artefacts.  
- Consider Research Sprints or research backlog grooming ceremonies to maintain cadence and reporting (pending your preference).

**Open questions**
1. Should we formalise dedicated “Research Sprints” with their own logs, or embed research items into the Discovery backlog with ad-hoc reviews? **(Decision: maintain a continuous Discovery/Research backlog for now; add sprint wrappers later if cadence control becomes necessary.)**  
2. Research notes remain flexible: they may stand alone (futuristic explorations, design research) or link to requirements/epics/features when relevant. Front-matter should support optional fields (`related_requirement_ids`, `related_design_ids`, etc.) but must not enforce a linkage. Traceability views can be generated per epic as needed rather than requiring a mandatory `Research_Traceability.md`.  
3. Migration approach confirmed: no bulk migration from legacy systems; import documents selectively as needed and wrap them in the new schemas. (Documented here for traceability.)

## Requested confirmation / next questions for you
- Remaining confirmations needed in sections 1–6 plus the research-stage questions above.  
- Once we lock in those details, I’ll move on to drafting the methodology recommendation (lifecycle, gates, ceremonies, traceability model) and propose the vault reorganisation plan with sprint and research integration.
