# Strategy Catalogue & Lifecycle Tracker

This workspace captures every trading strategy and its lifecycle status. Use it alongside the [Strategy Lifecycle epic](../EPICS/EPIC-007-StrategyLifecycle/README.md) to keep research, prioritisation, implementation, and operations in sync.

## How to Use

1. **Create a strategy folder** using the template below.
2. **Update lifecycle status** as the strategy progresses (Idea → Research → Prioritised → In Dev → Paper → Live → Retired).
3. **Link artefacts** for research notes, handoff dossier, deployment runbooks, and post-deployment reviews.
4. **Reference dependencies** on platform epics/features and ticket IDs.

## Catalogue

| Strategy ID | Name | Owner | Lifecycle Status | Last Review | Links |
|-------------|------|-------|------------------|-------------|-------|
| STRAT-001 | Options Weekly Monthly Hedge | strategy_ops_team | Research | 2025-11-03 | [Folder](./STRAT-001-OptionsWeeklyMonthlyHedge) |
| *(example)* | Momentum_US_Equities | alice@example.com | Idea | 2025-11-03 | [Folder](./STRAT-000-MomentumUSEquities) |

Add a row for each strategy and keep the table sorted by status, then ID.

## Folder Structure

```
Strategies/
├── README.md                      # This file
├── Templates/
│   └── Strategy_Template.md       # Strategy note template
└── STRAT-XYZ-Name/                # One subfolder per strategy
    └── README.md                  # Strategy-specific dossier
```

## Lifecycle States

| State | Description | Exit Criteria |
|-------|-------------|---------------|
| Idea | Intake form submitted, awaiting validation | Intake checklist complete, compliance green light |
| Research | Active analysis and data work | Research template filled, validation gate approved |
| Prioritised | Approved by governance council | Scheduled handoff with engineering |
| In Dev | Under implementation/testing | Engineering definition-of-ready met |
| Paper | Running in paper trading with monitoring | Paper trial outcomes meet KPI targets |
| Live | Deployed to production | KPI monitoring active, review cadence scheduled |
| Retired | Strategy sunset or paused | Retirement protocol executed |

Update the [Strategy Lifecycle dashboard](../EPICS/EPIC-007-StrategyLifecycle/FEATURE-002-PrioritisationGovernance/STORY-003-LifecycleDashboard/README.md) whenever a strategy changes state.
