# STORY-001-05-01: Create Mock Implementations & Test Harness

## Story Overview

**Story ID**: STORY-001-05-01  
**Title**: Create Mock Implementations & Test Harness  
**Feature**: [FEATURE-005: Testing Infrastructure](../README.md)  
**Epic**: [EPIC-001: Foundation & Core Architecture](../../README.md)  
**Status**: 📋 Planned  
**Priority**: P0  
**Assignee**: QA Engineer  
**Estimated Effort**: 4 days (32 hours)

## User Story

**As a** QA engineer  
**I want** mock port implementations and a reusable test harness  
**So that** engineers can validate functionality without live infrastructure

## Acceptance Criteria

- [ ] Mock implementations for MarketDataPort, ClockPort, OrderExecutionPort, PortfolioStatePort, TelemetryPort
- [ ] Contract test suite verifying each mock adheres to port specs
- [ ] Pytest fixtures for domain objects, strategies, and mock ports
- [ ] CI workflow running lint, mypy, unit tests, and coverage >= 90%
- [ ] Documentation describing how to extend mocks and run the harness locally

## Technical Notes

- Place mocks under `tests/mocks` with simple deterministic behaviour
- Use Hypothesis for property-based contract tests where valuable
- Integrate `coverage xml` output for CI gating

## Tasks

| Task ID | Task Description | Est. | Status |
|---------|------------------|------|--------|
| [TASK-001-05-01-01](#task-001-05-01-01) | Implement mock MarketDataPort | 4h | 📋 |
| [TASK-001-05-01-02](#task-001-05-01-02) | Implement mock ClockPort | 3h | 📋 |
| [TASK-001-05-01-03](#task-001-05-01-03) | Implement mock OrderExecutionPort | 5h | 📋 |
| [TASK-001-05-01-04](#task-001-05-01-04) | Implement mock PortfolioStatePort | 4h | 📋 |
| [TASK-001-05-01-05](#task-001-05-01-05) | Implement mock TelemetryPort | 3h | 📋 |
| [TASK-001-05-01-06](#task-001-05-01-06) | Write contract tests for all ports | 6h | 📋 |
| [TASK-001-05-01-07](#task-001-05-01-07) | Build pytest fixtures + factory helpers | 3h | 📋 |
| [TASK-001-05-01-08](#task-001-05-01-08) | Configure CI workflow (lint/mypy/tests) | 2h | 📋 |
| [TASK-001-05-01-09](#task-001-05-01-09) | Generate coverage reports + thresholds | 2h | 📋 |
| [TASK-001-05-01-10](#task-001-05-01-10) | Document harness usage + extension | 2h | 📋 |

## Task Details

### TASK-001-05-01-01
Implement deterministic `MockMarketDataPort` returning pre-seeded ticks/bars with configurable latencies.

### TASK-001-05-01-02
Create `MockClockPort` supporting manual time advancement and scheduling helpers for tests.

### TASK-001-05-01-03
Implement `MockOrderExecutionPort` with in-memory order book, fill simulation, and deterministic responses.

### TASK-001-05-01-04
Provide `MockPortfolioStatePort` that tracks positions and generates snapshots based on executed orders.

### TASK-001-05-01-05
Build `MockTelemetryPort` capturing emitted metrics/logs for assertions.

### TASK-001-05-01-06
Author contract tests verifying mocks satisfy port requirements (method signatures, invariants, error handling).

### TASK-001-05-01-07
Create pytest fixtures returning domain objects, mocks, and helper factories for reuse across tests.

### TASK-001-05-01-08
Add CI workflow (GitHub Actions) running `ruff`, `black`, `mypy`, and `pytest --cov`.

### TASK-001-05-01-09
Configure coverage thresholds, generate HTML/XML artifacts, and ensure pipeline fails below 90% coverage for target modules.

### TASK-001-05-01-10
Document how to run the harness locally, extend mocks, and integrate into future test suites.
