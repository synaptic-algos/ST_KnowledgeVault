---
progress_pct: 0.0
status: planned
---

# STORY-008-02-01: Build Strategy KPI Dashboards

## Story Overview

**Story ID**: STORY-008-02-01  
**Title**: Build Strategy KPI Dashboards  
**Feature**: [FEATURE-002: Strategy Performance Analytics](../README.md)  
**Epic**: [EPIC-008: Strategy Enablement & Operations](../../README.md)  
**Status**: 📋 Planned  
**Priority**: P0  
**Assignee**: Data Analytics Lead  
**Estimated Effort**: 2.5 days (20 hours)

## User Story

**As a** strategy operator  
**I want** dashboards summarising strategy KPIs  
**So that** we can monitor performance, risk, and operational health in near real-time

## Acceptance Criteria

- [ ] Dashboard template published with core metrics (returns, drawdown, win rate, hit rate, capital usage, latency, telemetry heartbeat)
- [ ] Supports drill-down per strategy and aggregate views
- [ ] Data refresh < 15 minutes using telemetry feeds
- [ ] Dashboard links to strategy catalogue and version history

## Tasks

| Task ID | Task Description | Est. | Status |
|---------|------------------|------|--------|
| [TASK-008-02-01-01](#task-008-02-01-01) | Design dashboard layout and KPIs | 6h | 📋 |
| [TASK-008-02-01-02](#task-008-02-01-02) | Connect telemetry warehouse to dashboard | 6h | 📋 |
| [TASK-008-02-01-03](#task-008-02-01-03) | Implement filters & drill-down | 4h | 📋 |
| [TASK-008-02-01-04](#task-008-02-01-04) | Document usage & onboarding | 4h | 📋 |

## Task Details

### TASK-008-02-01-01
Define KPI layout (overview tab, risk tab, operations tab) with metric definitions referencing KPI library.

### TASK-008-02-01-02
Integrate dashboard tool (Grafana/Metabase) with telemetry storage (e.g., Postgres/ClickHouse) using SQL or API connectors.

### TASK-008-02-01-03
Add filters for strategy, timeframe, version; enable drill-down to trade-level data.

### TASK-008-02-01-04
Publish documentation in `TechnicalDocumentation/StrategyDashboards.md` including screenshots, access instructions, and SLA.
