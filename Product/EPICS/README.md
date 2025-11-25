---
artifact_type: epic_index
change_log: null
created_at: '2025-11-25T16:23:21.632436Z'
id: synaptic-trading-epic-index
last_review: 2025-11-03
manual_update: true
owner: product_ops_team
related_epic: null
related_feature: []
related_story: []
requirement_coverage: TBD
seq: 1
status: active
title: Synaptic Trading Epics
updated_at: '2025-11-25T16:23:21.632440Z'
---

# Synaptic Trading Epics

| Epic | Scope | Gate | Status | Progress |
| --- | --- | --- | --- | --- |
| [[SynapticTrading_Product/EPICS/EPIC-001-Foundation/README|EPIC-001 Foundation]] | Core architecture + ports | G1 prep | 📋 Planned | 0% |
| [[SynapticTrading_Product/EPICS/EPIC-002-Backtesting/README|EPIC-002 Backtesting]] | Backtest engine + analytics | G0 draft | 📋 Planned | 0% |
| [[SynapticTrading_Product/EPICS/EPIC-003-PaperTrading/README|EPIC-003 Paper Trading]] | Paper execution | G0 draft | 📋 Planned | 0% |
| [[SynapticTrading_Product/EPICS/EPIC-004-LiveTrading/README|EPIC-004 Live Trading]] | Live controls & monitoring | G0 draft | 📋 Planned | 0% |
| [[SynapticTrading_Product/EPICS/EPIC-005-Adapters/README|EPIC-005 Adapters]] | Engine adapter suite | G0 draft | 📋 Planned | 0% |
| [[SynapticTrading_Product/EPICS/EPIC-006-PartnerAccess/README|EPIC-006 Partner Access]] | Multi-tenant auth & credential security | Pre-G0 | 📋 Planned | 0% |
| [[SynapticTrading_Product/EPICS/EPIC-007-StrategyLifecycle/README|EPIC-007 Strategy Lifecycle]] | Strategy intake → deployment (incl. enablement) | G0 draft | 📋 Planned | 0% |
| [[SynapticTrading_Product/EPICS/EPIC-008-Administration/README|EPIC-008 Administration]] | Portal administration (ops/config/audit) | Pre-G0 | 📋 Planned | 0% |
| [[SynapticTrading_Product/EPICS/EPIC-009-PartnerCommunity/README|EPIC-009 Partner Community]] | Partner collaboration & sharing | Pre-G0 | 📋 Planned | 0% |

Hardening/reliability is now tracked as part of the Definition of Done for each epic (no standalone hardening epic).

Each epic directory also contains a `TEST_PLAN.md` (see UPMS template) that maps requirements to the test suites that live under `tests/epics/<epic_slug>/`.

## How to use
- Open an epic to access its PRD, requirements matrix, features, and sprint links.
- Update the table after each gate review or major progress change.
- Add new epics here as they are created.
