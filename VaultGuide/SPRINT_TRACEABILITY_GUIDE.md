---
artifact_type: story
created_at: '2025-11-25T16:23:21.556205Z'
id: AUTO-SPRINT_TRACEABILITY_GUIDE
manual_update: 'true'
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: '001'
status: pending
title: Auto-generated title for SPRINT_TRACEABILITY_GUIDE
updated_at: '2025-11-25T16:23:21.556208Z'
---

## Purpose

This guide explains how to implement UPMS Sprint Traceability within **this specific vault** (SynapticTrading Knowledge Vault). It translates the UPMS methodology into concrete steps using this vault's directory structure and conventions.

---

## Quick Reference

### Vault Locations
```
Product/
├── EPICS/
│   └── EPIC-XXX/
│       ├── README.md                    # ← UPDATE after sprint
│       └── FEATURE-YYY/
│           ├── README.md                # ← UPDATE after sprint
│           └── STORY-ZZZ/
│               └── README.md            # ← UPDATE after sprint
└── Sprints/
    └── SPRINT-YYYYMMDD-epic-name/
        ├── SUMMARY.md                   # ← CREATE during retrospective
        └── RETROSPECTIVE.md             # ← OPTIONAL detailed retro
```

### UPMS Templates to Use
- **Sprint Retrospective**: [[../../UPMS_Vault/Templates/SPRINT_RETROSPECTIVE_Template.md|SPRINT_RETROSPECTIVE_Template.md]]
- **Full Methodology**: [[../../UPMS_Vault/Methodology/Ceremonies/Sprint_Traceability_Process.md|Sprint Traceability Process]]

### Research Documentation Standard (Pre-req)
- Any research note referenced in sprint summaries or EPIC updates must live in `UPMS_Vault/Research/` (or Product `Research/`) with a zero-padded numeric filename (`<seq>-Title.md`).
- Ensure each research file begins with YAML front matter that records `sequence_number` and ISO 8601 `created_at`.
- When citing research during sprint closure, use the numbered link format (e.g., `[[../../UPMS_Vault/Research/001-Topic.md|Topic]]`) so audits can trace evidence quickly.
- New research artefacts should increment the highest existing sequence to keep ordering consistent across vaults.

### Execution Summary Export
- Each sprint directory must contain an `execution_summary.yaml` capturing `sprint_id`, `status`, `ended_at`, `completed_items[]`, `kpi_updates`, and `epic_updates[]`.
- This file is the single source of truth for the sync scripts under `VaultGuide/scripts/sync/`.
- After filling the summary, run:
  ```bash
  python VaultGuide/scripts/sync/update_epic_status.py --vault <ProductRoot> --summary <path-to-summary>
  python VaultGuide/scripts/sync/roadmap_sync.py --vault <ProductRoot> --roadmap ROADMAP.md
  # or just call the wrapper:
  VaultGuide/scripts/sync/run_sprint_close.sh <ProductRoot> <SPRINT_ID> ROADMAP.md
  ```
- CI should block sprint closure if the summary or sync step is missing.

---

## The Process (5 Steps)

### Step 1: Complete Sprint Retrospective Document

**Location**: `Product/Sprints/SPRINT-YYYYMMDD-[epic]-[name]/SUMMARY.md` or `RETROSPECTIVE.md`

**Template**: Use [[../../UPMS_Vault/Templates/SPRINT_RETROSPECTIVE_Template.md|Sprint Retrospective Template]]

**Critical Section**: Stories/Tasks Completed

**Example**:
```markdown
## Stories/Tasks Completed

### Completed Stories
- ✅ **[[../../EPICS/EPIC-007-StrategyLifecycle/FEATURE-006-DataPipeline/STORY-001-NSEDataImport/README|STORY-006-01: NSE Data Import & Black-Scholes Greeks Calculation]]**
  - **Status**: pending → completed
  - **Progress**: 0% → 100%
  - **Estimated**: 10 days
  - **Actual**: 1 day
  - **Acceptance Criteria**: All met (CSV parsing, Greeks calculation, DB storage, Nautilus catalogs, S3 upload)
```

**MANDATORY**: List ALL Story IDs with status transitions.

---

### Step 2: Update Story Status

**For EACH completed story:**

**File**: `Product/EPICS/EPIC-XXX/FEATURE-YYY/STORY-ZZZ/README.md`

**Required Changes**:

1. **Update YAML frontmatter**:
```yaml
---
id: STORY-XXX-YY
status: completed  # ← CHANGE from pending/in-progress
progress_pct: 100  # ← UPDATE to 100
completed_at: 2025-11-12T12:00:00Z  # ← ADD completion timestamp
updated_at: 2025-11-12T12:00:00Z  # ← UPDATE to current time
---
```

2. **Add change log entry**:
```yaml
change_log:
  - 2025-11-12 – Sprint [N] completed – Story done
```

3. **Update Implementation Status section**:
   - Mark all phases/tasks as ✅ Complete
   - Update any "Current Status" or "Next Steps" sections

**Real Example**: See `Product/EPICS/EPIC-007-StrategyLifecycle/FEATURE-006-DataPipeline/README.md`

---

### Step 3: Update Feature Status

**For EACH feature with completed stories:**

**File**: `Product/EPICS/EPIC-XXX/FEATURE-YYY/README.md`

**Required Changes**:

1. **Update YAML frontmatter**:
```yaml
---
id: FEATURE-YYY
status: completed  # ← UPDATE based on story completion (in-progress if partial)
progress_pct: 100  # ← RECALCULATE: (Completed Stories / Total Stories) * 100
updated_at: 2025-11-12T12:00:00Z  # ← UPDATE timestamp
completed_at: 2025-11-12T12:00:00Z  # ← ADD if 100% complete
linked_sprints:  # ← ADD sprint ID
  - SPRINT-20251112-epic007-feature006
change_log:  # ← ADD entry
  - 2025-11-12 – Sprint [N] completed – Feature [status]
---
```

2. **Update User Stories table** in README:
```markdown
| Story ID | Story Title | Est. | Actual | Status |
|----------|-------------|------|--------|--------|
| STORY-006-01 | NSE Data Import | 10d | 1d | ✅ Complete |
```

3. **Add Sprint reference**:
```markdown
**Sprint**: [[../../Sprints/SPRINT-20251112-epic007-feature006/SUMMARY|Sprint [N]: [Name]]]
```

4. **Update Implementation Status section** with completion details

**Progress Formula**:
```
Feature Progress = (Completed Stories / Total Stories) * 100
```

---

### Step 4: Update EPIC Status

**For the EPIC containing completed features:**

**File**: `Product/EPICS/EPIC-XXX/README.md`

**Required Changes**:

1. **Update YAML frontmatter**:
```yaml
---
id: EPIC-XXX
status: in-progress  # ← UPDATE (completed only if ALL features done)
progress_pct: 17  # ← RECALCULATE: (Completed Features / Total Features) * 100
updated_at: 2025-11-12T12:00:00Z  # ← UPDATE timestamp
linked_sprints:  # ← ADD sprint ID
  - SPRINT-20251112-epic007-feature006
change_log:  # ← ADD entry
  - 2025-11-12 – Sprint [N] completed ([X]/[Y] Features complete)
---
```

2. **Update Features table** in README:
```markdown
| Feature ID | Feature Name | Stories | Est. | Actual | Status |
|------------|--------------|---------|------|--------|--------|
| FEATURE-006 | Data Pipeline | 1 | 10d | 1d | ✅ Complete |
```

3. **Update Progress summary**:
```markdown
**Progress**: 1/6 Features complete (17%)
```

4. **Add to Sprint History section**:
```markdown
## Sprint History
- **[[../../Sprints/SPRINT-20251112-epic007-feature006/SUMMARY|Sprint [N]: [Name]]]** (2025-11-12) - ✅ COMPLETE
```

**Progress Formula**:
```
EPIC Progress = (Completed Features / Total Features) * 100
```

**Real Example**: See `Product/EPICS/EPIC-007-StrategyLifecycle/README.md`

---

### Step 5: Verify Bidirectional Links

**Check that navigation works in BOTH directions:**

#### Forward Links (Sprint → EPIC)
From Sprint SUMMARY, you should be able to navigate to:
- ✅ EPIC README
- ✅ Feature README
- ✅ Story README
- ✅ Design documents

#### Backward Links (EPIC → Sprint)
From EPIC/Feature/Story READMEs, you should be able to navigate to:
- ✅ Sprint SUMMARY (via Sprint History section)
- ✅ Sprint SUMMARY (via linked_sprints in YAML)

**Test in Obsidian**: Click links to verify full graph navigation

---

## Progress Calculation Examples

### Example 1: Simple Feature (1 Story)
```
Feature has 1 Story
Story completed = 1
Progress = (1 / 1) * 100 = 100%
Status = completed
```

### Example 2: Complex Feature (5 Stories)
```
Feature has 5 Stories
2 Stories completed
Progress = (2 / 5) * 100 = 40%
Status = in-progress
```

### Example 3: EPIC with 6 Features
```
EPIC has 6 Features
1 Feature completed (FEATURE-006)
5 Features pending
Progress = (1 / 6) * 100 = 17%
Status = in-progress
```

---

## Checklist for Sprint Completion

Before marking sprint as "Complete", verify:

- [ ] Sprint SUMMARY/RETROSPECTIVE document created with Stories/Tasks Completed section
- [ ] All worked-on Stories have status updated (pending/in-progress → completed)
- [ ] All worked-on Stories have progress_pct updated to 100
- [ ] All worked-on Stories have completed_at timestamp added
- [ ] All affected Features have status updated based on story completion
- [ ] All affected Features have progress_pct recalculated
- [ ] All affected Features have linked_sprints updated
- [ ] All affected Features have User Stories table updated
- [ ] Affected EPIC has status updated (planned → in-progress or completed)
- [ ] Affected EPIC has progress_pct recalculated
- [ ] Affected EPIC has linked_sprints updated
- [ ] Affected EPIC has Features table updated
- [ ] Affected EPIC has Sprint History entry added
- [ ] Forward links tested (Sprint → EPIC/Feature/Story)
- [ ] Backward links tested (EPIC/Feature/Story → Sprint)
- [ ] All change_log entries added

**Quality Gate**: ALL checkboxes must be checked before sprint is considered complete.

---

## Real-World Example: Sprint 0 (Data Pipeline)

### What Happened
**Sprint**: SPRINT-20251104-epic007-data-pipeline
**Story Completed**: STORY-006-01 (NSE Data Import & Greeks Calculation)
**Feature Affected**: FEATURE-006-DataPipeline
**EPIC Affected**: EPIC-007-StrategyLifecycle

### Updates Made

1. **Sprint SUMMARY** created with Story reference:
   - Location: `Product/Sprints/SPRINT-20251104-epic007-data-pipeline/SUMMARY.md`
   - Listed STORY-006-01 with status transition

2. **STORY-006-01** updated:
   - status: pending → completed
   - progress_pct: 0 → 100
   - completed_at: 2025-11-04T12:00:00Z

3. **FEATURE-006** updated:
   - status: in-progress → completed
   - progress_pct: 30 → 100
   - linked_sprints: added SPRINT-20251104-epic007-data-pipeline
   - User Stories table: marked STORY-006-01 as ✅ Complete

4. **EPIC-007** updated:
   - status: planned → in-progress
   - progress_pct: 0 → 17
   - linked_sprints: added SPRINT-20251104-epic007-data-pipeline
   - Features table: marked FEATURE-006 as ✅ Complete
   - Sprint History: added Sprint 0 reference

### Result
- ✅ Full bidirectional navigation working
- ✅ Progress percentages accurate
- ✅ Stakeholders can see real-time progress
- ✅ Planning aligned with reality

**Files to Reference**:
- `Product/Sprints/SPRINT-20251104-epic007-data-pipeline/SUMMARY.md`
- `Product/EPICS/EPIC-007-StrategyLifecycle/FEATURE-006-DataPipeline/README.md`
- `Product/EPICS/EPIC-007-StrategyLifecycle/README.md`

---

## Common Mistakes (Anti-Patterns)

### ❌ Anti-Pattern 1: Sprint Complete, But No Story IDs
**Problem**: Sprint SUMMARY says "✅ Complete" but doesn't list Story IDs
**Impact**: Cannot trace work back to requirements
**Fix**: Always list Story IDs with full status transitions

### ❌ Anti-Pattern 2: Story Updated, But Feature Not Recalculated
**Problem**: Story shows 100% but Feature still shows 30%
**Impact**: Progress metrics are incorrect and misleading
**Fix**: Recalculate Feature progress based on ALL stories

### ❌ Anti-Pattern 3: Forward Links Only
**Problem**: Sprint links to EPIC, but EPIC doesn't link back to Sprint
**Impact**: Cannot navigate backward in Obsidian graph
**Fix**: Add Sprint to EPIC Sprint History section

### ❌ Anti-Pattern 4: Partial Updates
**Problem**: Updated Story and Feature, but forgot EPIC
**Impact**: EPIC shows 0% despite work being done
**Fix**: Follow all 5 steps completely - no shortcuts

### ❌ Anti-Pattern 5: Wrong Progress Formula
**Problem**: Using estimated effort instead of completed count
**Impact**: Progress doesn't reflect actual completion
**Fix**: Use formulas from UPMS: (Completed / Total) * 100

---

## When to Use This Process

### ALWAYS (Mandatory)
- ✅ After every sprint completion
- ✅ Before marking sprint retrospective as "done"
- ✅ Before starting next sprint
- ✅ During gate reviews (G3 Delivery)

### ALSO RECOMMENDED
- ⚡ During sprint (progressive updates to Story progress_pct)
- ⚡ After completing individual tasks (update Story progress)
- ⚡ Weekly during sprint review (update Feature progress estimates)

**Note**: While progressive updates are recommended, the MANDATORY update is at sprint completion.

---

## Responsibilities (RACI)

| Activity | Product Owner | Scrum Master | Dev Team | Claude/AI |
|----------|---------------|--------------|----------|-----------|
| Draft Sprint SUMMARY | C | A | R | I |
| Update Story Status | C | C | R | R |
| Update Feature Status | A | C | R | R |
| Update EPIC Status | A | C | C | R |
| Verify Traceability | A | R | C | - |
| Quality Gate Check | A | R | I | - |

**Legend**:
- **R** = Responsible (does the work)
- **A** = Accountable (final approval)
- **C** = Consulted (provides input)
- **I** = Informed (kept in the loop)

---

## Tools and Resources

### UPMS Templates (Use These!)
- **[[../../UPMS_Vault/Templates/SPRINT_RETROSPECTIVE_Template.md|Sprint Retrospective Template]]** - Complete retrospective structure
- **[[../../UPMS_Vault/Templates/EPIC_Template.md|EPIC Template]]** - EPIC structure with Sprint History
- **[[../../UPMS_Vault/Templates/FEATURE_Template.md|Feature Template]]** - Feature structure with linked_sprints
- **[[../../UPMS_Vault/Templates/STORY_Template.md|Story Template]]** - Story structure with completion tracking

### UPMS Methodology
- **[[../../UPMS_Vault/Methodology/Ceremonies/Sprint_Traceability_Process.md|Sprint Traceability Process]]** - Full methodology documentation
- **[[../../UPMS_Vault/Methodology/UPMS_Methodology_Blueprint.md|UPMS Methodology Blueprint]]** - Overall framework

### Vault Examples
- **Sprint 0**: `Product/Sprints/SPRINT-20251104-epic007-data-pipeline/`
- **EPIC-007**: `Product/EPICS/EPIC-007-StrategyLifecycle/`
- **FEATURE-006**: `Product/EPICS/EPIC-007-StrategyLifecycle/FEATURE-006-DataPipeline/`

---

## Enforcement

### Code Review Gates
Before merging any sprint work:
1. Reviewer verifies Sprint SUMMARY lists Story IDs
2. Reviewer checks Story/Feature/EPIC status updated
3. Reviewer validates progress calculations
4. Reviewer tests bidirectional links

### Sprint Retrospective Meeting
During retrospective:
1. Team reviews completed Stories together
2. Team updates Feature/EPIC status as group
3. Product Owner verifies traceability
4. Scrum Master checks quality gates

### Automated Checks (Future)
Potential automation:
- Pre-commit hook to validate Story IDs in Sprint SUMMARY
- Script to check progress calculations match story completion
- Obsidian plugin to validate bidirectional links
- CI/CD gate to block merge if traceability incomplete

---

## Getting Help

### Questions About This Guide
**Where**: VaultGuide/README.md or team Slack channel
**Who**: Product Operations Team, Scrum Master

### Questions About UPMS Methodology
**Where**: [[../../UPMS_Vault/Methodology/Ceremonies/Sprint_Traceability_Process.md|Sprint Traceability Process]]
**Who**: Method Lead, Product Owner

### Technical Issues with Vault
**Where**: VaultGuide/ directory documentation
**Who**: Vault Steward, Technical Lead

### Examples and Walkthroughs
**Where**: Look at Sprint 0 (SPRINT-20251104-epic007-data-pipeline) as canonical example
**Who**: Any team member who completed Sprint 0

---

## Process Improvements

This guide will evolve based on learnings from this vault's usage.

### How to Suggest Improvements
1. Document the issue/improvement in `Product/Issues/`
2. Reference this guide in the issue
3. Bring to Weekly UPMS Council meeting
4. If approved, update this guide AND UPMS methodology

### Continuous Improvement Philosophy
This guide follows UPMS "Living Methodology" approach:
- Learn from each sprint
- Adapt processes based on reality
- Update documentation immediately
- Share learnings across vaults

See [[../../UPMS_Vault/README.md|UPMS Living Methodology]] for contribution process.

---

## Compliance Statement

**This guide is MANDATORY for all work in this vault.**

Non-compliance with Sprint Traceability:
- ❌ Breaks planning system
- ❌ Invalidates progress metrics
- ❌ Prevents stakeholder visibility
- ❌ Blocks gate approvals
- ❌ Violates vault governance

**Quality Gate**: Sprints cannot be marked "Complete" without following this process.

---

**Created**: 2025-11-12
**Status**: Active - Mandatory Compliance Required
**Vault**: SynapticTrading Knowledge Vault
**UPMS Version**: 1.0.0
**Last Updated**: 2025-11-12
**Next Review**: After 3 sprints or 2025-12-15 (whichever comes first)
**Owner**: Product Operations Team
