---
artifact_type: story
created_at: '2025-11-25T16:23:21.759538Z'
id: AUTO-STORY-001-LifecycleStateMachine
manual_update: true
owner: Auto-assigned
progress_pct: 0.0
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: planned
title: Auto-generated title for STORY-001-LifecycleStateMachine
updated_at: '2025-11-25T16:23:21.759541Z'
---

# STORY-001-03-01: Implement Strategy Lifecycle State Machine

## Story Overview

**Story ID**: STORY-001-03-01  
**Title**: Implement Strategy Lifecycle State Machine  
**Feature**: [FEATURE-003: Base Strategy Class](../README.md)  
**Epic**: [EPIC-001: Foundation & Core Architecture](../../README.md)  
**Status**: 📋 Planned  
**Priority**: P0  
**Assignee**: Lead Architect  
**Estimated Effort**: 1 day (8 hours)

## User Story

**As a** strategy author  
**I want** a robust lifecycle state machine in the base class  
**So that** my strategies transition cleanly between initialising, running, pausing, and stopping without race conditions

## Acceptance Criteria

- [ ] State machine implemented with explicit states (`CREATED`, `INITIALISED`, `RUNNING`, `PAUSED`, `STOPPED`, `FAILED`)
- [ ] Guard methods enforce valid transitions and raise descriptive errors for illegal moves
- [ ] Start/stop/pause/resume methods idempotent and thread-safe
- [ ] Hooks invoked during state changes for custom instrumentation
- [ ] Lifecycle metrics emitted via telemetry port
- [ ] Unit tests cover all transition paths and illegal sequences

## Technical Notes

- Implement state machine in `src/domain/strategy/state_machine.py`
- Use `enum.Enum` or `enum.StrEnum` for readability and logging
- Synchronise transitions with `anyio.Lock` (or asyncio) for concurrency safety

## Tasks

| Task ID | Task Description | Est. | Status |
|---------|------------------|------|--------|
| [TASK-001-03-01-01](#task-001-03-01-01) | Draft state enum and transition map | 1h | 📋 |
| [TASK-001-03-01-02](#task-001-03-01-02) | Implement transition validation helpers | 1h | 📋 |
| [TASK-001-03-01-03](#task-001-03-01-03) | Add lifecycle methods to `BaseStrategy` | 2h | 📋 |
| [TASK-001-03-01-04](#task-001-03-01-04) | Wire telemetry callbacks + logging | 1h | 📋 |
| [TASK-001-03-01-05](#task-001-03-01-05) | Implement concurrency guard (lock) | 1h | 📋 |
| [TASK-001-03-01-06](#task-001-03-01-06) | Write unit tests for valid transitions | 1h | 📋 |
| [TASK-001-03-01-07](#task-001-03-01-07) | Write unit tests for illegal transitions | 0.5h | 📋 |
| [TASK-001-03-01-08](#task-001-03-01-08) | Update developer documentation | 0.5h | 📋 |

## Task Details

### TASK-001-03-01-01
Define `StrategyState` enum and a dictionary describing allowed transitions.

### TASK-001-03-01-02
Implement helper function `validate_transition(current, next)` raising `InvalidStrategyStateTransition`.

### TASK-001-03-01-03
Add lifecycle methods `initialize()`, `start()`, `stop()`, `pause()`, `resume()` to `BaseStrategy` leveraging the validation helpers.

### TASK-001-03-01-04
Emit telemetry events (state name, timestamp, metadata) on each transition and hook into logging.

### TASK-001-03-01-05
Guard transitions with re-entrant lock to prevent concurrent state mutations.

### TASK-001-03-01-06
Unit tests verifying happy path transitions and idempotent stop.

### TASK-001-03-01-07
Tests ensuring illegal transitions (e.g., resume from CREATED) raise exceptions.

### TASK-001-03-01-08
Document lifecycle semantics and state diagram in developer guide.
