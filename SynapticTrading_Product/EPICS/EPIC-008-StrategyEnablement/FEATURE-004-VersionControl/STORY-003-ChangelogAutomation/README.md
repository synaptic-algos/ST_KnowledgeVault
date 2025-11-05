# STORY-008-04-03: Automate Strategy Changelogs

## Story Overview

**Story ID**: STORY-008-04-03  
**Title**: Automate Strategy Changelogs  
**Feature**: [FEATURE-004: Strategy Versioning & Change Management](../README.md)  
**Epic**: [EPIC-008: Strategy Enablement & Operations](../../README.md)  
**Status**: 📋 Planned  
**Priority**: P0  
**Assignee**: DevOps Engineer  
**Estimated Effort**: 1.5 days (12 hours)

## User Story

**As a** DevOps engineer  
**I want** changelog automation tied to strategy releases  
**So that** stakeholders can see what changed without manual work

## Acceptance Criteria

- [ ] Changelog generator parses commits / PR metadata for each strategy
- [ ] Output stored in `Strategies/<ID>/Changelog.md` and referenced in release notes
- [ ] Supports categories (features, fixes, experiments, risk updates)
- [ ] Changelog automation triggered by release command or CI pipeline

## Tasks

| Task ID | Task Description | Est. | Status |
|---------|------------------|------|--------|
| [TASK-008-04-03-01](#task-008-04-03-01) | Design changelog format and categories | 3h | 📋 |
| [TASK-008-04-03-02](#task-008-04-03-02) | Implement changelog script | 5h | 📋 |
| [TASK-008-04-03-03](#task-008-04-03-03) | Integrate script with release workflow | 3h | 📋 |
| [TASK-008-04-03-04](#task-008-04-03-04) | Document usage and rollback procedure | 1h | 📋 |

## Task Details

### TASK-008-04-03-01
Define markdown format including headers for release version, date, summary, and categories.

### TASK-008-04-03-02
Implement script that reads git log between tags, categorises commits using labels, and writes to changelog note.

### TASK-008-04-03-03
Hook script into release pipeline so changelog updates automatically when a new version is tagged.

### TASK-008-04-03-04
Document instructions in `TechnicalDocumentation/StrategyReleaseProcess.md`.
