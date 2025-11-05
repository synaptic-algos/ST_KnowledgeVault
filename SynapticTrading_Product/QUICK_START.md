# Quick Start Guide: Product Management Structure

## Overview

This directory contains the complete implementation plan for the Framework-Agnostic Trading Platform using the **Epic → Feature → Story → Task** hierarchy.

## What's Included

✅ **7 Epics** – Platform and strategy lifecycle initiatives  
✅ **35 Features** – Shippable capabilities (3-7 days each)  
✅ **107 Stories** – User-facing functionality (1-3 days each)  
✅ **~420 Tasks** – Technical + operational work items (2-8 hours)

## Vault Layout

```
SynapticTrading_Product/
├── README.md                     # Main navigation and overview
├── QUICK_START.md                # This file
├── IMPLEMENTATION_HIERARCHY.md   # Complete breakdown of all work
├── STRUCTURE_VISUAL.md           # Folder tree snapshot
├── Strategies/                   # Strategy catalogue and templates
├── EPICS/                        # Epic folders (001–008)
└── Templates/                    # Documentation templates
```

## Strategy Library Overview
- Templates live under `Strategies/Templates/` for equities, options, futures, and custom strategies.
- EPIC-008 adds a scaffold CLI (`make new-strategy TYPE=<asset_class> NAME=<id>`) and CI pipeline—use it once implemented.
- Track per-strategy status, version, and artefacts in `Strategies/README.md`.
- Link strategies to EPIC-007 lifecycle pathways and EPIC-008 enablement work.

## How to Use

### For Product Managers
1. **Start with**: [README.md](./README.md) for project overview.  
2. **Track progress**: Use the epic roadmap table.  
3. **Sprint planning**: Select stories from the active epics.  
4. **Reporting**: Update epic status weekly.

### For Engineers
1. **Pick a story**: Using the sprint board (EPIC-001…008).  
2. **Review**: Story acceptance criteria and traceability.  
3. **Break down**: Create tasks following template conventions.  
4. **Execute**: Implement, test, update status.  
5. **Demo**: Present completed work during sprint review.

### For Stakeholders
1. **Progress**: Review [IMPLEMENTATION_HIERARCHY.md](./IMPLEMENTATION_HIERARCHY.md).  
2. **Milestones**: Check the roadmap table.  
3. **Scope**: Understand epics/features/stories counts.  
4. **Risks**: Use epic-level risk tables.

## Example Walkthrough

### Epic Level (Weeks 1-4)
📁 [EPIC-001: Foundation & Core Architecture](./EPICS/EPIC-001-Foundation/README.md)

**Contains**:
- 5 Features
- 15 Stories
- ~180 Tasks
- Sprint breakdown
- Success criteria

### Feature Level (5 days)
📁 [FEATURE-001: Port Interface Definitions](./EPICS/EPIC-001-Foundation/FEATURE-001-PortInterfaces/README.md)

**Contains**:
- 5 Stories (one per port)
- ~60 Tasks
- Technical design
- Dependencies

### Story Level (1 day)
📁 [STORY-001: MarketDataPort Interface](./EPICS/EPIC-001-Foundation/FEATURE-001-PortInterfaces/STORY-001-MarketDataPort/README.md)

**Contains**:
- User story format
- 12 Tasks (detailed)
- Acceptance criteria
- Code examples

### Task Level (0.5-2 hours)
Embedded in story files.

**Example Tasks**:
- TASK-001-01-01-01: Create port module file (0.5h)
- TASK-001-01-01-02: Define ABC skeleton (0.5h)
- TASK-001-01-01-03: Implement get_latest_tick signature (0.5h)

## Detailed Examples Provided

- **Epic**: [EPIC-001: Foundation & Core Architecture](./EPICS/EPIC-001-Foundation/README.md) – full 4-week breakdown, sprint planning, risks.  
- **Feature**: [FEATURE-001: Port Interface Definitions](./EPICS/EPIC-001-Foundation/FEATURE-001-PortInterfaces/README.md) – technical design, testing plan.  
- **Story**: [STORY-001: Define MarketDataPort Interface](./EPICS/EPIC-001-Foundation/FEATURE-001-PortInterfaces/STORY-001-MarketDataPort/README.md) – tasks, acceptance criteria.

## Estimation Summary

### Time Breakdown
- **Epic**: 2-4 weeks (platform) + ongoing strategy cycles
- **Feature**: 3-7 days
- **Story**: 1-3 days
- **Task**: 2-8 hours

### Scope Breakdown
- **7 Epics** = 18 weeks + continuous lifecycle work
- **35 Features** = ~120 days
- **107 Stories** = ~214 person-days
- **~420 Tasks** = ~1680 person-hours

### Team Velocity
- 2 Senior Engineers (full-time)  
- 1 Lead Architect (50% time)  
- 1 DevOps Engineer (25% time)  
- 1 QA Engineer (50% time)

## Creating Additional Documents

### To Create a Feature
1. Copy an existing feature (e.g., `EPIC-001-Foundation/FEATURE-001-PortInterfaces/README.md`).  
2. Rename and update metadata, description, stories.  
3. Add `TRACEABILITY.md` (reuse template).  
4. Link stories and requirements.

### To Create a Story
1. Copy a story (e.g., `FEATURE-001-PortInterfaces/STORY-001-MarketDataPort/README.md`).  
2. Update metadata, user story, acceptance criteria, and tasks.  
3. Adjust task IDs to match numbering.  
4. Ensure tasks align with epic traceability.

### ID Format
- **Epic**: `EPIC-XXX`
- **Feature**: `FEATURE-XXX-Name`
- **Story**: `STORY-XXX-Name`
- **Task**: `TASK-XXX-YY`

## Integration with Tools

### GitHub Issues
```
Epic → GitHub Project
Feature → GitHub Milestone
Story → GitHub Issue ("story" label)
Task → Checklist within issue
```

### Jira
```
Epic → Jira Epic
Feature → Jira Component/Sub-epic
Story → Jira Story
Task → Jira Subtask
```

### Labels
`epic-001`, `epic-002`, … `epic-008`; `priority-p0/p1/p2`; `status-planned/in-progress/complete`

## Key Milestones

1. **Milestone 1: Core Architecture (Week 4)** – ports, domain model, base strategy.  
2. **Milestone 2: Backtesting (Week 8)** – backtest adapter + analytics.  
3. **Milestone 3: Paper Trading (Week 10)** – paper mode validated.  
4. **Milestone 4: Production Ready (Week 14)** – live trading & safety controls.  
5. **Milestone 5: Multi-Framework (Week 16)** – adapters operational.  
6. **Milestone 6: Strategy Enablement (Ongoing)** – templates, dashboards, collaboration in place.

## Next Steps
1. ✅ Stakeholder review of epics.  
2. ✅ Team assignment for EPIC-001 → EPIC-004.  
3. ✅ Sprint 0 tooling setup.  
4. 📋 Sprint 1: Execute EPIC-001.  
5. 📋 Strategy lifecycle (EPIC-007) + enablement (EPIC-008) review sessions.

## Questions?
- **Architecture**: See `Design/` notes.  
- **Requirements**: See `PRD/`.  
- **Strategy Lifecycle**: See [EPIC-007](./EPICS/EPIC-007-StrategyLifecycle/README.md).  
- **Strategy Enablement**: See [EPIC-008](./EPICS/EPIC-008-StrategyEnablement/README.md).

---
**Created**: 2025-11-03  
**Status**: Ready for Implementation  
**Next Action**: Keep epics and strategy library in sync with execution.
