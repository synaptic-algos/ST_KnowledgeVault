# STORY-001-03-02: Implement Event Handler Dispatch

## Story Overview

**Story ID**: STORY-001-03-02  
**Title**: Implement Event Handler Dispatch  
**Feature**: [FEATURE-003: Base Strategy Class](../README.md)  
**Epic**: [EPIC-001: Foundation & Core Architecture](../../README.md)  
**Status**: 📋 Planned  
**Priority**: P0  
**Assignee**: Senior Engineer 1  
**Estimated Effort**: 1 day (8 hours)

## User Story

**As a** strategy author  
**I want** ergonomic event handler hooks  
**So that** my strategy can respond to market data, bars, orders, and timers without boilerplate

## Acceptance Criteria

- [ ] Base class defines overridable hooks (`on_initialize`, `on_market_data`, `on_bar`, `on_timer`, `on_order_update`)
- [ ] Event dispatcher routes events to hooks with structured context objects
- [ ] Hook execution errors captured and transitioned to `FAILED` state
- [ ] Support sync and async handlers (await if coroutine)
- [ ] Provide scheduler helper to register periodic callbacks
- [ ] Unit tests cover event dispatch ordering and error propagation

## Technical Notes

- Create `StrategyEvent` hierarchy for typed dispatch
- Event loop integration should be agnostic (works in sync + async contexts)
- Provide instrumentation around handler duration (using telemetry port)

## Tasks

| Task ID | Task Description | Est. | Status |
|---------|------------------|------|--------|
| [TASK-001-03-02-01](#task-001-03-02-01) | Define event classes in `events.py` | 1h | 📋 |
| [TASK-001-03-02-02](#task-001-03-02-02) | Implement dispatcher in `BaseStrategy` | 2h | 📋 |
| [TASK-001-03-02-03](#task-001-03-02-03) | Add coroutine detection + awaiting | 1h | 📋 |
| [TASK-001-03-02-04](#task-001-03-02-04) | Implement periodic scheduler helper | 1h | 📋 |
| [TASK-001-03-02-05](#task-001-03-02-05) | Add error handling + failover state change | 1h | 📋 |
| [TASK-001-03-02-06](#task-001-03-02-06) | Instrument handler duration via telemetry | 1h | 📋 |
| [TASK-001-03-02-07](#task-001-03-02-07) | Write unit tests for dispatch + scheduler | 1h | 📋 |
| [TASK-001-03-02-08](#task-001-03-02-08) | Update docs with handler usage examples | 0.5h | 📋 |

## Task Details

### TASK-001-03-02-01
Create `StrategyEvent` base class plus `MarketDataEvent`, `BarEvent`, `TimerEvent`, `OrderUpdateEvent` with relevant payloads.

### TASK-001-03-02-02
Implement dispatcher that maps event types to handler methods, supports fallback `on_event` handler for custom events.

### TASK-001-03-02-03
Detect coroutine handlers via `inspect.iscoroutinefunction` and `await` results when necessary.

### TASK-001-03-02-04
Provide scheduler helper leveraging clock port for periodic callbacks and strategy-level job registry.

### TASK-001-03-02-05
Ensure exceptions in handlers transition strategy to `FAILED`, log stacktrace, and notify telemetry.

### TASK-001-03-02-06
Instrument handlers with start/stop timestamps and emit telemetry metrics for latency monitoring.

### TASK-001-03-02-07
Write tests for dispatch ordering, scheduler execution, coroutine support, and failure propagation.

### TASK-001-03-02-08
Document handler patterns, including streaming vs batch processing and telemetry best practices.
