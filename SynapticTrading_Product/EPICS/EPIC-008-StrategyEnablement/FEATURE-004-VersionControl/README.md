---
id: FEATURE-008-VersionControl
seq: 4
title: "Strategy Versioning & Change Management"
owner: strategy_ops_team
status: planned
artifact_type: feature_overview
related_epic:
  - EPIC-008
related_feature:
  - FEATURE-008-VersionControl
related_story:
  - STORY-008-04-01
  - STORY-008-04-02
  - STORY-008-04-03
created_at: 2025-11-04T00:00:00Z
updated_at: 2025-11-04T00:00:00Z
last_review: 2025-11-04
change_log:
  - 2025-11-04 – strategy_ops_team – Created version control feature – n/a
progress_pct: 0
requirement_coverage: 0
linked_sprints: []
---

# FEATURE-004: Strategy Versioning & Change Management

- **Epic**: [EPIC-008: Strategy Enablement & Operations](../README.md)  
- **Traceability**: [TRACEABILITY.md](./TRACEABILITY.md)  
- **Primary Requirements**: REQ-EPIC008-011 → REQ-EPIC008-013

## Overview

Manage how strategy code and artefacts evolve: semantic versioning, catalogue updates, changelog automation, and release approvals.

## Acceptance Criteria

- [ ] Semantic versioning convention documented and enforced
- [ ] Strategy catalogue records version, release date, link to changelog
- [ ] Changelog automation tool generates release notes per strategy

## Stories

| Story ID | Title | Est. | Status |
|----------|-------|------|--------|
| [STORY-008-04-01](./STORY-001-SemanticVersioning/README.md) | Implement Strategy Semantic Versioning | 2d | 📋 |
| [STORY-008-04-02](./STORY-002-CatalogueLink/README.md) | Link Versions to Strategy Catalogue | 1.5d | 📋 |
| [STORY-008-04-03](./STORY-003-ChangelogAutomation/README.md) | Automate Strategy Changelogs | 1.5d | 📋 |

**Total**: 3 stories, ~5 days.

## Notes
- Align with Git tagging and release workflow (GitHub Actions).  
- Ensure compatibility with Options Weekly Monthly Hedge example.  
- Provide migration guide for existing strategies.
