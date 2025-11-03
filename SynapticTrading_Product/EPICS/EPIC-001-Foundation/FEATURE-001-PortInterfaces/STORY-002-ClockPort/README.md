# STORY-001-01-02: Define ClockPort Interface

## Story Overview

**Story ID**: STORY-001-01-02  
**Title**: Define ClockPort Interface  
**Feature**: [FEATURE-001: Port Interface Definitions](../README.md)  
**Epic**: [EPIC-001: Foundation & Core Architecture](../../README.md)  
**Status**: 📋 Planned  
**Priority**: P0  
**Assignee**: Senior Engineer 1  
**Estimated Effort**: 1 day (8 hours)

## User Story

**As a** strategy runtime engineer  
**I want** a ClockPort interface abstraction  
**So that** strategies can coordinate scheduling, timers, and time travel across backtest, paper, and live modes

## Acceptance Criteria

- [ ] ClockPort abstract base class defined in `src/application/ports/clock_port.py`
- [ ] Methods cover current time retrieval, sleep/schedule primitives, and time travel controls for backtests
- [ ] Docstrings document behaviour across realtime vs simulated environments
- [ ] MockClockPort implementation provided with deterministic controls
- [ ] Contract tests ensure adapters maintain monotonic time and cancellation semantics
- [ ] Code passes linting, mypy, and unit tests

## Tasks

| Task ID | Task Description | Est. | Status |
|---------|------------------|------|--------|
| [TASK-001-01-02-01](#task-001-01-02-01) | Create clock port module skeleton | 0.5h | 📋 |
| [TASK-001-01-02-02](#task-001-01-02-02) | Define base interface + docstrings | 1h | 📋 |
| [TASK-001-01-02-03](#task-001-01-02-03) | Add scheduling APIs (sleep_until, schedule_job) | 1h | 📋 |
| [TASK-001-01-02-04](#task-001-01-02-04) | Model cancellable handles + context managers | 1h | 📋 |
| [TASK-001-01-02-05](#task-001-01-02-05) | Implement MockClockPort | 1.5h | 📋 |
| [TASK-001-01-02-06](#task-001-01-02-06) | Write contract tests for ClockPort | 1.5h | 📋 |
| [TASK-001-01-02-07](#task-001-01-02-07) | Run mypy + lint + update docs | 1.5h | 📋 |

## Task Details

### TASK-001-01-02-01
Create `src/application/ports/clock_port.py` with imports and module docstring describing real-time vs simulated clock requirements.

### TASK-001-01-02-02
Define `ClockPort` class inheriting from `ABC` with docstring covering thread-safety and monotonic guarantees.

### TASK-001-01-02-03
Add methods `now()`, `sleep(duration)`, `sleep_until(when)`, and `schedule(callback, when)` with precise typing.

### TASK-001-01-02-04
Introduce `ScheduledJobHandle` for cancellation, with context manager support.

### TASK-001-01-02-05
Implement `MockClockPort` enabling manual time advancement and scheduled callback execution for tests.

### TASK-001-01-02-06
Write contract tests verifying monotonicity, cancellation, and scheduler behaviour.

### TASK-001-01-02-07
Run tooling (ruff, mypy), document usage examples, and capture learnings in developer guide.
