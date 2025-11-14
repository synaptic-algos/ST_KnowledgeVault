# STORY-001-02-03: Implement Order Lifecycle Objects

## Story Overview

**Story ID**: STORY-001-02-03  
**Title**: Implement Order Lifecycle Objects  
**Feature**: [FEATURE-002: Canonical Domain Model](../README.md)  
**Epic**: [EPIC-001: Foundation & Core Architecture](../../README.md)  
**Status**: 📋 Planned  
**Priority**: P0  
**Assignee**: Senior Engineer 2  
**Estimated Effort**: 1 day (8 hours)

## User Story

**As a** strategy developer  
**I want** strongly typed order lifecycle objects  
**So that** order intent, submission, fills, and cancellations are tracked consistently across adapters

## Acceptance Criteria

- [ ] `TradeIntent` captures signal metadata and risk context
- [ ] `OrderTicket` stores routing parameters, time in force, and client order id
- [ ] `OrderStatus` enum covers pending → filled → cancelled states
- [ ] `Fill` captures partial fills with commission, slippage, and timestamp
- [ ] Support conversion between intents, tickets, and broker payloads
- [ ] Add helper to compute realized P&L from fills + execution price
- [ ] Unit tests exercise edge cases (partial fills, cancel-replace, rejects)

## Technical Notes

- Introduce identifier `OrderId` and `ExecutionId`
- Provide `OrderAmendment` object for modify flow
- Use `uuid.UUID` for client id default but allow injection

## Tasks

| Task ID | Task Description | Est. | Status |
|---------|------------------|------|--------|
| [TASK-001-02-03-01](#task-001-02-03-01) | Create `orders.py` module skeleton | 0.5h | 📋 |
| [TASK-001-02-03-02](#task-001-02-03-02) | Implement `TradeIntent` dataclass | 1h | 📋 |
| [TASK-001-02-03-03](#task-001-02-03-03) | Implement `OrderTicket` with route params | 1.5h | 📋 |
| [TASK-001-02-03-04](#task-001-02-03-04) | Implement `OrderStatus` + transition helpers | 0.5h | 📋 |
| [TASK-001-02-03-05](#task-001-02-03-05) | Implement `Fill` and partial fill aggregation | 1.5h | 📋 |
| [TASK-001-02-03-06](#task-001-02-03-06) | Add conversion helpers (intent → ticket) | 1h | 📋 |
| [TASK-001-02-03-07](#task-001-02-03-07) | Create broker payload mapper stub | 1h | 📋 |
| [TASK-001-02-03-08](#task-001-02-03-08) | Write unit tests incl. cancel-replace flow | 1h | 📋 |

## Task Details

### TASK-001-02-03-01
Create `src/domain/models/orders.py` with imports, module docstring, enumerations, and exports.

### TASK-001-02-03-02
Design `TradeIntent` capturing instrument, side, size, price targets, risk tags, and strategy metadata.

### TASK-001-02-03-03
Implement `OrderTicket` with route destination, limit/stop prices, order type, TIF, and slippage budget.

### TASK-001-02-03-04
Add `OrderStatus` enum and helper functions (`is_open`, `is_terminal`) plus validation for allowed transitions.

### TASK-001-02-03-05
Implement `Fill` dataclass with partial fill merge helper computing weighted average price, fees, and slippage.

### TASK-001-02-03-06
Provide conversions between `TradeIntent` and `OrderTicket`, ensuring invariants hold (e.g., limit price required for limit orders).

### TASK-001-02-03-07
Create placeholder for broker payload mappers that transform `OrderTicket` into adapter-specific request dictionaries.

### TASK-001-02-03-08
Write tests covering full lifecycle, partial fills, cancellations, and serialization of order history events.
