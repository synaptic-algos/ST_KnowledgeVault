---
artifact_type: story
created_at: '2025-11-25T16:23:21.761625Z'
id: AUTO-STORY-001-ValueObjects
manual_update: true
owner: Auto-assigned
progress_pct: 0.0
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: planned
title: Auto-generated title for STORY-001-ValueObjects
updated_at: '2025-11-25T16:23:21.761628Z'
---

# STORY-001-02-01: Implement Core Value Objects

## Story Overview

**Story ID**: STORY-001-02-01  
**Title**: Implement Core Value Objects  
**Feature**: [FEATURE-002: Canonical Domain Model](../README.md)  
**Epic**: [EPIC-001: Foundation & Core Architecture](../../README.md)  
**Status**: 📋 Planned  
**Priority**: P0  
**Assignee**: Senior Engineer 1  
**Estimated Effort**: 1 day (8 hours)

## User Story

**As a** platform engineer  
**I want** canonical value objects for instruments, money, quantities, and enums  
**So that** all upstream components share immutable, validated primitives

## Acceptance Criteria

- [ ] `InstrumentId`, `StrategyId`, and `VenueId` implemented as frozen dataclasses
- [ ] Monetary primitives (`Currency`, `Price`, `Quantity`, `Money`) support arithmetic with validation
- [ ] Side, OrderType, TimeInForce enums created with helper methods
- [ ] All value objects enforce invariants (positive quantities, valid currency codes)
- [ ] Rich docstrings and examples added to developer guide
- [ ] Unit tests cover arithmetic, equality, hashing, and serialization

## Technical Notes

- Use `decimal.Decimal` with configured context for all monetary amounts
- Provide `Money.__add__`, `__sub__`, and allocation helpers with currency checks
- Ensure `InstrumentId` normalises symbol + venue casing
- Mark dataclasses as `frozen=True` and set `slots=True` for memory efficiency

## Tasks

| Task ID | Task Description | Est. | Status |
|---------|------------------|------|--------|
| [TASK-001-02-01-01](#task-001-02-01-01) | Scaffold `identifiers.py` module | 0.5h | 📋 |
| [TASK-001-02-01-02](#task-001-02-01-02) | Implement identifier dataclasses with validation | 1h | 📋 |
| [TASK-001-02-01-03](#task-001-02-01-03) | Define order side / type enums | 0.5h | 📋 |
| [TASK-001-02-01-04](#task-001-02-01-04) | Implement `Currency` and currency registry | 0.5h | 📋 |
| [TASK-001-02-01-05](#task-001-02-01-05) | Implement `Price`, `Quantity`, `Money` with arithmetic | 2h | 📋 |
| [TASK-001-02-01-06](#task-001-02-01-06) | Add JSON / dict serialization helpers | 1h | 📋 |
| [TASK-001-02-01-07](#task-001-02-01-07) | Write unit + property tests for value objects | 1.5h | 📋 |
| [TASK-001-02-01-08](#task-001-02-01-08) | Document usage patterns in developer guide | 1h | 📋 |

## Task Details

### TASK-001-02-01-01
Create skeleton file `src/domain/models/identifiers.py` with imports, module docstring, and `__all__` exports.

### TASK-001-02-01-02
Implement `InstrumentId`, `StrategyId`, and `VenueId` as frozen dataclasses with `__post_init__` validation and convenience constructors (`from_symbol`).

### TASK-001-02-01-03
Define enums for `OrderSide`, `OrderType`, and `TimeInForce` plus helper methods (`is_buy`, `requires_price`).

### TASK-001-02-01-04
Create `Currency` enum plus registry for supported ISO codes, raising `UnsupportedCurrencyError` when invalid.

### TASK-001-02-01-05
Implement `Price`, `Quantity`, and `Money`. Ensure arithmetic preserves currency and scale, adds rounding helpers, and blocks cross-currency maths without conversion.

### TASK-001-02-01-06
Provide `.to_dict()` / `.from_dict()` on value objects and register with `orjson` default serializer.

### TASK-001-02-01-07
Add unit tests verifying equality, hashing, arithmetic behaviour, and Hypothesis-based fuzzing for arithmetic invariants.

### TASK-001-02-01-08
Update developer documentation with examples and guidelines for using the value objects in ports, adapters, and strategies.
