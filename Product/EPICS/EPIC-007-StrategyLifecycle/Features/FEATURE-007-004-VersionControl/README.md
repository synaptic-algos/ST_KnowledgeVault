---
artifact_type: feature_overview
change_log: null
created_at: '2025-11-25T16:23:21.682951Z'
id: FEATURE-008-VersionControl
last_review: 2025-11-04
linked_sprints: []
manual_update: true
owner: strategy_ops_team
progress_pct: 0
related_epic: null
related_feature: null
related_story: null
requirement_coverage: 0
seq: 4
status: planned
title: Strategy Versioning & Change Management
updated_at: '2025-11-25T16:23:21.682955Z'
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
