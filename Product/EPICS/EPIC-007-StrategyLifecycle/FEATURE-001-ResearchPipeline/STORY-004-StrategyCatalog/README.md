# STORY-007-01-04: Create Strategy Catalogue Index

## Story Overview

**Story ID**: STORY-007-01-04  
**Title**: Create Strategy Catalogue Index  
**Feature**: [FEATURE-001: Research Intake & Discovery Workflow](../README.md)  
**Epic**: [EPIC-007: Strategy Lifecycle](../../README.md)  
**Status**: 📋 Planned  
**Priority**: P0  
**Assignee**: Strategy Librarian  
**Estimated Effort**: 1 day (8 hours)

## User Story

**As a** product stakeholder  
**I want** a catalogue listing of all strategies and their lifecycle status  
**So that** we can monitor pipeline health and spot bottlenecks quickly

## Acceptance Criteria

- [ ] Catalogue lists strategy ID, owner, status, latest review, associated epic/feature, KPIs
- [ ] Filterable by lifecycle state (Idea, Research, Prioritised, In Dev, Paper, Live, Retired)
- [ ] Synchronises with ticketing data (read-only) or is updated via automation script
- [ ] Accessible from knowledge vault with clear update instructions

## Tasks

| Task ID | Task Description | Est. | Status |
|---------|------------------|------|--------|
| [TASK-007-01-04-01](#task-007-01-04-01) | Define catalogue schema & metadata | 2h | 📋 |
| [TASK-007-01-04-02](#task-007-01-04-02) | Implement catalogue note + table | 3h | 📋 |
| [TASK-007-01-04-03](#task-007-01-04-03) | Integrate with lifecycle dashboard or script | 2h | 📋 |
| [TASK-007-01-04-04](#task-007-01-04-04) | Document update cadence & owners | 1h | 📋 |

## Task Details

### TASK-007-01-04-01
Consult stakeholders to agree on required metadata and sort order.

### TASK-007-01-04-02
Build catalogue table within `SynapticTrading_Product/Strategies/README.md` linking to strategy folders.

### TASK-007-01-04-03
Create automation or SOP to sync statuses from tracking tool (optional script or manual routine).

### TASK-007-01-04-04
Publish update cadence, responsible owners, and definition of done for catalogue entries.
