---
progress_pct: 0.0
status: planned
---

# STORY-008-04-02: Link Versions to Strategy Catalogue

## Story Overview

**Story ID**: STORY-008-04-02  
**Title**: Link Versions to Strategy Catalogue  
**Feature**: [FEATURE-004: Strategy Versioning & Change Management](../README.md)  
**Epic**: [EPIC-008: Strategy Enablement & Operations](../../README.md)  
**Status**: 📋 Planned  
**Priority**: P0  
**Assignee**: Strategy Ops Analyst  
**Estimated Effort**: 1.5 days (12 hours)

## User Story

**As a** strategy ops analyst  
**I want** catalogue entries to display the latest version and history  
**So that** stakeholders know which strategy revision is active

## Acceptance Criteria

- [ ] Strategy catalogue table includes columns: version, status, release date, link to changelog
- [ ] Strategy README front-matter contains `version` field
- [ ] Version history accessible via dedicated note per strategy

## Tasks

| Task ID | Task Description | Est. | Status |
|---------|------------------|------|--------|
| [TASK-008-04-02-01](#task-008-04-02-01) | Update catalogue table schema | 4h | 📋 |
| [TASK-008-04-02-02](#task-008-04-02-02) | Create version history template | 4h | 📋 |
| [TASK-008-04-02-03](#task-008-04-02-03) | Integrate with release script | 4h | 📋 |

## Task Details

### TASK-008-04-02-01
Modify `SynapticTrading_Product/Strategies/README.md` to add version metadata columns.

### TASK-008-04-02-02
Create template `Strategies/Templates/Strategy_Version_History.md` for logging changes.

### TASK-008-04-02-03
Ensure release script updates catalogue and version history automatically.
