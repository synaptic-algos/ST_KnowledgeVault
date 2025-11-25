---
artifact_type: story
created_at: '2025-11-25T16:23:21.763425Z'
id: AUTO-STORY-002-MarketDataObjects
manual_update: true
owner: Auto-assigned
progress_pct: 0.0
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: planned
title: Auto-generated title for STORY-002-MarketDataObjects
updated_at: '2025-11-25T16:23:21.763429Z'
---

# STORY-001-02-02: Implement Market Data Entities

## Story Overview

**Story ID**: STORY-001-02-02  
**Title**: Implement Market Data Entities  
**Feature**: [FEATURE-002: Canonical Domain Model](../README.md)  
**Epic**: [EPIC-001: Foundation & Core Architecture](../../README.md)  
**Status**: 📋 Planned  
**Priority**: P0  
**Assignee**: Senior Engineer 1  
**Estimated Effort**: 1 day (8 hours)

## User Story

**As a** strategy developer  
**I want** canonical market data objects for ticks, bars, and historical windows  
**So that** strategies and adapters exchange a uniform data shape

## Acceptance Criteria

- [ ] `MarketTick` captures bid/ask/last with millisecond precision timestamps
- [ ] `Bar` object stores OHLCV + volume and normalises timezone to UTC
- [ ] `BarGranularity` enum provides canonical granularities with metadata helpers
- [ ] `HistoryWindow` abstraction encapsulates rolling lookbacks and pagination
- [ ] All data objects are immutable and comparable for equality
- [ ] Contract tests ensure adapters conform to serialization and immutability rules

## Technical Notes

- Prefer `datetime` with `tzinfo=timezone.utc`
- Provide `from_dict` constructors for ingestion pipelines
- Include instrument metadata snapshot within tick for quick lookups
- Add helper on `Bar` to compute midpoint, typical price, and returns

## Tasks

| Task ID | Task Description | Est. | Status |
|---------|------------------|------|--------|
| [TASK-001-02-02-01](#task-001-02-02-01) | Define `market_data.py` module layout | 0.5h | 📋 |
| [TASK-001-02-02-02](#task-001-02-02-02) | Implement `MarketTick` dataclass | 1h | 📋 |
| [TASK-001-02-02-03](#task-001-02-02-03) | Implement `Bar` dataclass with helpers | 1.5h | 📋 |
| [TASK-001-02-02-04](#task-001-02-02-04) | Create `BarGranularity` enum + metadata | 0.5h | 📋 |
| [TASK-001-02-02-05](#task-001-02-02-05) | Implement `HistoryWindow` abstraction | 1h | 📋 |
| [TASK-001-02-02-06](#task-001-02-02-06) | Add serialization + validation utilities | 1h | 📋 |
| [TASK-001-02-02-07](#task-001-02-02-07) | Write unit + property tests for bars/ticks | 1.5h | 📋 |
| [TASK-001-02-02-08](#task-001-02-02-08) | Document usage and integration patterns | 1h | 📋 |

## Task Details

### TASK-001-02-02-01
Create `src/domain/models/market_data.py`, import shared value objects, and define `__all__` exports.

### TASK-001-02-02-02
Implement `MarketTick` with bid, ask, last, size, timestamp, and instrument metadata. Include `spread` property.

### TASK-001-02-02-03
Implement `Bar` dataclass storing open, high, low, close, volume, open interest, and timestamp. Add methods for `midpoint()`, `true_range()`, and `rate_of_return()`.

### TASK-001-02-02-04
Create `BarGranularity` enum with minute/hour/day constants plus helper `duration()` returning `timedelta`.

### TASK-001-02-02-05
Add `HistoryWindow` type encapsulating `start`, `end`, `granularity`, and `limit` with iteration helpers.

### TASK-001-02-02-06
Provide `.to_dict()` / `.from_dict()` conversions, rounding/normalising functions, and adhesives for `pandas` interoperability.

### TASK-001-02-02-07
Write tests covering rounding, timezone enforcement, equality semantics, and property-based checks for monotonic bar sequences.

### TASK-001-02-02-08
Update developer guide with usage examples for retrieving bars from MarketDataPort and computing indicators.
