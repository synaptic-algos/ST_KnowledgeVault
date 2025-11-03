---
id: synaptic-trading-product-overview
seq: 1
title: "Synaptic Trading Product Workspace"
owner: product_ops_team
status: active
artifact_type: product_index
related_epic:
  - EPIC-001
  - EPIC-002
  - EPIC-003
  - EPIC-004
  - EPIC-005
  - EPIC-006
related_feature: []
related_story: []
created_at: 2025-11-03T00:00:00Z
updated_at: 2025-11-03T00:00:00Z
last_review: 2025-11-03
change_log:
  - 2025-11-03 – product_ops_team – Migrated product management workspace into knowledge vault structure – n/a
---

# Synaptic Trading Product Workspace

Unified hub for managing the framework-agnostic trading platform. Content is organised as **Product → Epics → Features → Stories → Tasks**, and aligns with the UPMS methodology (gates, traceability, research).

## Directory Layout

```
SynapticTrading_Product/
├── README.md                     # This index
├── QUICK_START.md                # How to use the workspace
├── IMPLEMENTATION_HIERARCHY.md   # Complete work breakdown (epic → story)
├── STRUCTURE_VISUAL.md           # Mermaid diagram of relationships
├── Templates/                    # Product-facing Markdown templates
└── EPICS/                        # Executable work, one folder per epic
    ├── EPIC-001-Foundation/
    ├── EPIC-002-Backtesting/
    ├── EPIC-003-PaperTrading/
    ├── EPIC-004-LiveTrading/
    ├── EPIC-005-Adapters/
    └── EPIC-006-Hardening/
```

## Quick Navigation
- [📖 Quick Start](./QUICK_START.md)
- [📊 Implementation Hierarchy](./IMPLEMENTATION_HIERARCHY.md)
- [🧭 Epic Index](./EPICS/README.md)
- Current focus: [EPIC-001 Foundation](./EPICS/EPIC-001-Foundation/)

## How work is structured

| Level | Location | Description |
| --- | --- | --- |
| Product | This folder | Top-level documentation, playbooks, templates |
| Epic | `EPICS/EPIC-###-Name/` | Multi-week initiatives with PRD + requirements matrix |
| Feature | `EPIC-###-Name/FEATURE-###-Name/` | 3–7 day deliverables with traceability tables |
| Story | `FEATURE-###-Name/STORY-###-Name/` | 1–3 day units with tasks (inline or `TASK-` files) |
| Task | Within stories or `TASK-###` files | Executable steps, owners, sprint linkage |

Each epic folder contains:
- `README.md` (overview with metadata)
- `PRD.md`
- `REQUIREMENTS_MATRIX.md`
- Feature subfolders (each with `README.md` and `TRACEABILITY.md`)
- Optional sprint notes, design references, and issue links

## Current epic roadmap

| Epic | Timeline | Status | Features | Stories | Priority |
|------|----------|--------|----------|---------|----------|
| [EPIC-001 Foundation](./EPICS/EPIC-001-Foundation/README.md) | Weeks 1–4 | 📋 Planned | 5 | 15 | P0 |
| [EPIC-002 Backtesting](./EPICS/EPIC-002-Backtesting/README.md) | Weeks 5–8 | 📋 Planned | 6 | 18 | P0 |
| [EPIC-003 Paper Trading](./EPICS/EPIC-003-PaperTrading/README.md) | Weeks 9–10 | 📋 Planned | 4 | 12 | P0 |
| [EPIC-004 Live Trading](./EPICS/EPIC-004-LiveTrading/README.md) | Weeks 11–14 | 📋 Planned | 7 | 21 | P0 |
| [EPIC-005 Adapters](./EPICS/EPIC-005-Adapters/README.md) | Weeks 15–16 | 📋 Planned | 3 | 9 | P1 |
| [EPIC-006 Hardening](./EPICS/EPIC-006-Hardening/README.md) | Weeks 17–18 | 📋 Planned | 5 | 15 | P0 |
| [EPIC-007 Strategy Lifecycle](./EPICS/EPIC-007-StrategyLifecycle/README.md) | Continuous | 📋 Planned | 5 | 17 | P0 |

## Using this workspace
1. Start with [Quick Start](./QUICK_START.md) for the workflow primer.
2. Head to the [Epic Index](./EPICS/README.md) and open the active epic.
3. Review the epic’s `PRD.md` and `REQUIREMENTS_MATRIX.md`.
4. Drill into features and stories to plan work or update progress.
5. Track tasks via inline checklists or dedicated `TASK-` notes where traceability is required.
6. Log sprint outcomes and retrospectives in the UPMS sprint area when available.

## Related resources
- Methodology, templates, and research live under `UPMS/Methodology`.
- Design artefacts: [Design Library](./Design/README.md)
- Product PRDs: [PRD Library](./PRD/README.md)
- Research notes: [Research Archive](./Research/README.md)
- Issues: `SynapticTrading_Product/Issues/` (to be populated from legacy tracker).
- Strategies: [Strategy Catalogue](./Strategies/README.md) (research through retirement).

Keep metadata (front-matter) updated and capture changes in the `change_log` arrays to maintain traceability across gates and sprints.

## Navigation

### Quick Links

- [📖 Quick Start Guide](./QUICK_START.md) - How to use this system
- [📊 Implementation Hierarchy](./IMPLEMENTATION_HIERARCHY.md) - Complete breakdown
- [🎯 Current Epic](./EPIC-001-Foundation/) - Foundation & Core Architecture
- [🗂️ Strategy Catalogue](./Strategies/README.md) - Lifecycle tracker
- [🔍 Example Feature](./EPIC-001-Foundation/FEATURE-001-PortInterfaces/) - Port Interfaces
- [✏️ Example Story](./EPIC-001-Foundation/FEATURE-001-PortInterfaces/STORY-001-MarketDataPort/) - MarketDataPort

### Browse by Epic

1. **[EPIC-001: Foundation & Core Architecture](./EPIC-001-Foundation/)** (Weeks 1-4)
   - Port interfaces, domain model, strategy base class
   - 5 features, 15 stories, 4 weeks

2. **[EPIC-002: Backtesting Engine](./EPIC-002-Backtesting/)** (Weeks 5-8)
   - Historical simulation, execution simulator, analytics
   - 6 features, 18 stories, 4 weeks

3. **[EPIC-003: Paper Trading](./EPIC-003-PaperTrading/)** (Weeks 9-10)
   - Live data with simulated execution
   - 4 features, 12 stories, 2 weeks

4. **[EPIC-004: Live Trading & Safety](./EPIC-004-LiveTrading/)** (Weeks 11-14)
   - Production deployment with safety controls
   - 7 features, 21 stories, 4 weeks

5. **[EPIC-005: Framework Adapters](./EPIC-005-Adapters/)** (Weeks 15-16)
   - Multi-engine adapter support
   - 3 features, 9 stories, 2 weeks

6. **[EPIC-006: Production Hardening](./EPIC-006-Hardening/)** (Weeks 17-18)
   - Performance, security, operational readiness
   - 5 features, 15 stories, 2 weeks

7. **[EPIC-007: Strategy Lifecycle](./EPIC-007-StrategyLifecycle/)** (Continuous)
   - Research → prioritisation → implementation → deployment → optimisation
   - 5 features, 17 stories, ongoing cadence

## Milestones

### Milestone 1: Core Architecture Complete (Week 4)
**Epic**: EPIC-001
- ✅ All port interfaces defined
- ✅ Canonical domain model implemented
- ✅ Base Strategy class complete
- ✅ Example strategy running

**Location**: [EPIC-001-Foundation](./EPIC-001-Foundation/)

### Milestone 2: Backtesting Ready (Week 8)
**Epic**: EPIC-002
- ✅ BacktestAdapter functional
- ✅ Event replay working
- ✅ First strategy backtested
- ✅ Performance analytics generated

**Location**: [EPIC-002-Backtesting](./EPIC-002-Backtesting/)

### Milestone 3: Paper Trading Validated (Week 10)
**Epic**: EPIC-003
- ✅ 3+ strategies in paper trading
- ✅ Shadow mode operational
- ✅ 7 days stable operation

**Location**: [EPIC-003-PaperTrading](./EPIC-003-PaperTrading/)

### Milestone 4: Production Ready - LAUNCH 🎯 (Week 14)
**Epic**: EPIC-004
- ✅ Live trading functional
- ✅ All safety controls validated
- ✅ 99.9% uptime in staging
- ✅ Security audit passed

**Location**: [EPIC-004-LiveTrading](./EPIC-004-LiveTrading/)

### Milestone 5: Multi-Framework Support (Week 16)
**Epic**: EPIC-005
- ✅ Nautilus + Backtrader adapters
- ✅ Cross-engine validation passing
- ✅ 5+ strategies migrated

**Location**: [EPIC-005-Adapters](./EPIC-005-Adapters/)

### Milestone 6: Production Hardening - FULL ROLLOUT 🚀 (Week 18)
**Epic**: EPIC-006
- ✅ 10+ strategies in production
- ✅ Documentation complete
- ✅ Team trained

**Location**: [EPIC-006-Hardening](./EPIC-006-Hardening/)

## How to Use This Structure

### For Product Managers
1. **Track Progress**: Navigate to current epic folder
2. **Sprint Planning**: Open epic README, review features
3. **Update Status**: Edit feature/story README files
4. **Report**: Use epic-level metrics for stakeholders

### For Engineers
1. **Pick Work**: Navigate to current epic → feature → story
2. **Read Story**: Open `STORY-###-Name/README.md`
3. **Execute Tasks**: Check off tasks in story README
4. **Complete**: Update story status when done

### For Stakeholders
1. **See Progress**: Browse epic folders
2. **Check Milestones**: Review milestone section above
3. **Understand Scope**: Each folder = shippable unit

## Naming Conventions

### Epic Folders
**Format**: `EPIC-###-Name/`
**Example**: `EPIC-001-Foundation/`
- ### = 3-digit epic number (001-006)
- Name = Short descriptive name

### Feature Folders
**Format**: `FEATURE-###-Name/`
**Example**: `FEATURE-001-PortInterfaces/`
- ### = 3-digit feature number within epic (001-007)
- Name = Short descriptive name

### Story Folders
**Format**: `STORY-###-Name/`
**Example**: `STORY-001-MarketDataPort/`
- ### = 3-digit story number within feature (001-005)
- Name = Short descriptive name

### README Files
- Each epic, feature, and story folder has `README.md`
- Tasks embedded in story README as markdown checklists

## Creating New Items

### To Create a Feature
1. Create folder: `EPIC-XXX-Name/FEATURE-YYY-NewFeature/`
2. Create file: `FEATURE-YYY-NewFeature/README.md`
3. Follow template from existing feature

### To Create a Story
1. Create folder: `FEATURE-YYY-Name/STORY-ZZZ-NewStory/`
2. Create file: `STORY-ZZZ-NewStory/README.md`
3. Follow template from existing story
4. Include tasks as checklists

## Example Walkthrough

### View Epic
```bash
cd EPIC-001-Foundation/
cat README.md
```

### View Feature
```bash
cd EPIC-001-Foundation/FEATURE-001-PortInterfaces/
cat README.md
```

### View Story with Tasks
```bash
cd EPIC-001-Foundation/FEATURE-001-PortInterfaces/STORY-001-MarketDataPort/
cat README.md  # Contains 12 tasks with checklists
```

## Status Tracking

Each README.md file contains:
- Status emoji: 📋 Planned, 🏗️ In Progress, ✅ Complete, ⏸️ Blocked, 🔴 At Risk
- Progress checkboxes for acceptance criteria
- Task checklists (in story README files)

## Integration with Tools

### GitHub
- Epic = GitHub Project
- Feature = GitHub Milestone
- Story = GitHub Issue
- Task = Checklist in issue

### Jira
- Epic = Jira Epic
- Feature = Jira Component or Sub-epic
- Story = Jira Story
- Task = Subtasks

## Related Documents

- **PRD**: [../prd/01_FrameworkAgnosticPlatform/](../prd/01_FrameworkAgnosticPlatform/)
- **Design**: [../design/01_FrameworkAgnostic/](../design/01_FrameworkAgnostic/)
- **Research**: [../research/02_FrameworkAgnosticArchitecture/](../research/02_FrameworkAgnosticArchitecture/)

## Team

- **Product Owner**: [Name]
- **Engineering Lead**: [Name]
- **Lead Architect**: [Name]
- **Senior Engineers**: 2x full-time
- **DevOps Engineer**: 25% time
- **QA Engineer**: 50% time

## Reporting

### Weekly Status
- Navigate to current epic
- Review feature progress
- Update story statuses
- Report blockers

### Sprint Reviews
- Demo completed stories
- Show folder structure progress
- Review acceptance criteria

## Getting Started

1. Read [QUICK_START.md](./QUICK_START.md)
2. Navigate to [EPIC-001-Foundation](./EPIC-001-Foundation/)
3. Review [FEATURE-001-PortInterfaces](./EPIC-001-Foundation/FEATURE-001-PortInterfaces/)
4. Study [STORY-001-MarketDataPort](./EPIC-001-Foundation/FEATURE-001-PortInterfaces/STORY-001-MarketDataPort/)
5. Understand task breakdown pattern
6. Start implementing!

---

**Last Updated**: 2025-11-03
**Version**: 2.0.0 (Hierarchical Structure)
**Status**: Active Planning
**Next Action**: Begin EPIC-001 Sprint 1
