---
artifact_type: story
created_at: '2025-11-25T16:23:21.610684Z'
id: AUTO-README
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for README
updated_at: '2025-11-25T16:23:21.610688Z'
---

# Strategy Catalogue & Lifecycle Tracker

This directory captures every trading strategy, its lifecycle state, and links to implementation artefacts. Use the asset-class templates in `Templates/` when proposing new strategies.

## How to Use
1. Fill the appropriate template (equities/options/futures/custom) in `Templates/`.
2. Create a strategy folder `STRAT-XXX-Name` with README and PRD.
3. Update the table below with status, owner, and version.
4. Link to EPIC-007 lifecycle notes and EPIC-008 implementation tasks.

## Strategy Index
| Strategy ID | Name | Asset Class | Owner | Lifecycle | Version | Last Review | Links |
|-------------|------|-------------|-------|-----------|---------|-------------|-------|
| STRAT-001 | Options Weekly Monthly Hedge | options | strategy_ops_team | Research | 0.1.0 | 2025-11-04 | [Folder](./STRAT-001-OptionsWeeklyMonthlyHedge) |

## Templates
- [Equities Template](./Templates/Equities_Strategy_Template.md)
- [Options Template](./Templates/Options_Strategy_Template.md)
- [Futures Template](./Templates/Futures_Strategy_Template.md)
- [Custom Template](./Templates/Custom_Strategy_Template.md)

## Notes
- Keep business logic in templates; implementation tasks move to EPIC-008 features.
- Update version and changelog when releases are tagged.
