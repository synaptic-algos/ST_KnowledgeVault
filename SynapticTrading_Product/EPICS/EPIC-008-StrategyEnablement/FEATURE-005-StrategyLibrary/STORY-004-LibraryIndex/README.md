# STORY-008-05-04: Build Strategy Library Index & Search

## Story Overview

**Story ID**: STORY-008-05-04  
**Title**: Build Strategy Library Index & Search  
**Feature**: [FEATURE-005: Strategy Template & Library System](../README.md)  
**Epic**: [EPIC-008: Strategy Enablement & Operations](../../README.md)  
**Status**: 📋 Planned  
**Priority**: P0  
**Assignee**: Knowledge Management Lead  
**Estimated Effort**: 1.5 days (12 hours)

## User Story

**As a** team member  
**I want** a searchable index of strategies and templates  
**So that** I can quickly find existing work, examples, or templates to reuse

## Acceptance Criteria

- [ ] Strategy index note includes filters (asset class, status, owner, version, KPIs)
- [ ] Search links to strategy notes, templates, decisions, dashboards
- [ ] Index auto-updated by script when strategies are added/updated
- [ ] Documentation explains how to use search and contribute metadata

## Tasks

| Task ID | Task Description | Est. | Status |
|---------|------------------|------|--------|
| [TASK-008-05-04-01](#task-008-05-04-01) | Design index schema & metadata fields | 4h | 📋 |
| [TASK-008-05-04-02](#task-008-05-04-02) | Implement index note + search queries | 4h | 📋 |
| [TASK-008-05-04-03](#task-008-05-04-03) | Automate updates via script | 2h | 📋 |
| [TASK-008-05-04-04](#task-008-05-04-04) | Document contribution workflow | 2h | 📋 |

## Task Details

### TASK-008-05-04-01
Define metadata fields (strategy ID, name, asset class, owner, lifecycle state, version, KPIs, latest review date).

### TASK-008-05-04-02
Create index note `Strategies/INDEX.md` with table and search instructions; consider Dataview for Obsidian.

### TASK-008-05-04-03
Enhance scaffold/release scripts to update index automatically.

### TASK-008-05-04-04
Document how to add strategies manually and maintain metadata.
