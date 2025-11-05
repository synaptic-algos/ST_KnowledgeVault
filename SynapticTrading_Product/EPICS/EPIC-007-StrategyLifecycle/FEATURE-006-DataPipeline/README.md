---
id: FEATURE-007-DataPipeline
seq: 6
title: "Historical Data Pipeline & Greeks Calculation"
owner: data_engineering_team
status: in_progress
artifact_type: feature_overview
related_epic:
  - EPIC-007
related_story:
  - STORY-007-06-01
created_at: 2025-11-04T00:00:00Z
updated_at: 2025-11-04T00:00:00Z
last_review: 2025-11-04
change_log:
  - 2025-11-04 – Claude – Created data pipeline feature for STRAT-001 backtest infrastructure
progress_pct: 30
requirement_coverage: 0
linked_sprints: []
---

# FEATURE-006: Historical Data Pipeline & Greeks Calculation

- **Epic**: [EPIC-007: Strategy Lifecycle](../README.md)
- **Traceability**: [TRACEABILITY.md](./TRACEABILITY.md)
- **Primary Requirement(s)**: Infrastructure for STRAT-001 backtesting

## Feature Overview

**Feature ID**: FEATURE-006
**Feature Name**: Historical Data Pipeline & Greeks Calculation
**Status**: 🔄 In Progress
**Priority**: P0 (Blocker for STRAT-001)
**Owner**: Data Engineering Team
**Estimated Effort**: 10 days

## Description

Build complete data pipeline to import NSE historical options data, calculate Black-Scholes Greeks (delta, gamma, theta, vega, rho), store in TimescaleDB, generate Nautilus Parquet catalogs, and upload to S3 for backtest consumption.

**Critical Dependency**: This is a prerequisite for all strategy backtesting. No strategies can be tested without historical options data with calculated Greeks.

## Business Value

- Enables backtesting of options strategies (STRAT-001 and future strategies)
- Provides delta-based strike selection capability (±0.1 delta hedge requirement)
- Centralized historical data storage for consistent backtest results
- S3-based catalog enables cloud-native backtesting infrastructure

## Acceptance Criteria

- [ ] NSE historical options data imported into TimescaleDB (1+ years)
- [ ] Black-Scholes Greeks calculated and stored for all option contracts
- [ ] Greeks validation: Delta ∈ [-1, 1], Gamma > 0, IV > 0
- [ ] Nautilus Parquet catalogs generated with instruments, bars, and Greeks
- [ ] Catalogs uploaded to S3 bucket (s3://synaptic-trading-data/nautilus-catalogs/)
- [ ] Greeks available in both database queries AND Nautilus catalog format
- [ ] Sample backtest successfully loads data and Greeks from S3

## User Stories

| Story ID | Story Title | Est. | Status |
|----------|-------------|------|--------|
| [STORY-001-GreeksCalculation](./STORY-001-GreeksCalculation/README.md) | NSE Data Import & Black-Scholes Greeks Calculation | 10d | 🔄 In Progress |

**Total**: 1 Story (may expand), ~10 days

## Technical Architecture

### Data Flow
```
NSE CSV/Parquet Files
    ↓
[NSE Importer] → Parse contracts (strike, expiry, IV, spot)
    ↓
[Greeks Calculator] → Black-Scholes calculation
    ↓
TimescaleDB
    ├── options_ticks (OHLCV + IV + OI + Greeks)
    └── spot_prices (underlying spot prices)
    ↓
[Nautilus Catalog Generator]
    ├── Query aggregated bars (hourly, daily)
    ├── Embed Greeks in catalog metadata
    ↓
Parquet Files (local)
    ↓
[S3 Uploader] → boto3
    ↓
S3: s3://synaptic-trading-data/nautilus-catalogs/
    ↓
NautilusTrader Backtest Engine
    └── Reads instruments, bars, Greeks for strategy execution
```

### Greeks Storage Requirements

**Database Schema** (TimescaleDB):
```sql
CREATE TABLE options_ticks (
    timestamp TIMESTAMPTZ NOT NULL,
    underlying VARCHAR(20) NOT NULL,
    strike NUMERIC(10,2) NOT NULL,
    expiry DATE NOT NULL,
    option_type VARCHAR(2) NOT NULL,  -- CE or PE

    -- Market data
    open NUMERIC(10,2),
    high NUMERIC(10,2),
    low NUMERIC(10,2),
    close NUMERIC(10,2),
    volume BIGINT,
    open_interest BIGINT,
    bid NUMERIC(10,2),
    ask NUMERIC(10,2),
    implied_volatility NUMERIC(8,6),
    spot_price NUMERIC(10,2),

    -- Calculated Greeks
    delta NUMERIC(8,6),      -- Must be stored!
    gamma NUMERIC(8,6),
    theta NUMERIC(8,6),
    vega NUMERIC(8,6),
    rho NUMERIC(8,6),

    data_source VARCHAR(50)
);
```

**Nautilus Catalog Format**:
- Store Greeks in custom Parquet columns alongside OHLCV data
- Enable strategy code to query delta for strike selection

## Dependencies

**Technical**:
- TimescaleDB database (✅ Running in Docker)
- AWS S3 bucket (✅ Created: synaptic-trading-data)
- Python libraries: scipy (Black-Scholes), pandas, pyarrow, boto3 (✅ Installed)

**Data**:
- NSE historical options data (✅ Available in `data/sample/`)
- NIFTY spot prices (✅ Available in `data/sample/niftyspot/`)

## Testing / Validation

- [ ] Greeks validation against broker platform (Zerodha Kite)
- [ ] Delta values match expected ranges (CE: +0.0 to +1.0, PE: -1.0 to -0.0)
- [ ] ±0.1 delta strike selection works correctly
- [ ] Catalog loads in NautilusTrader without errors
- [ ] Backtest can access Greeks for delta-based logic

## Design Documents

- [Greeks Calculation & Storage Design](../../../Design/DESIGN-DataPipeline-Greeks.md) ← **TO BE CREATED**

## Implementation Status

**Completed** (30%):
- ✅ TimescaleDB setup with Docker
- ✅ S3 bucket created and tested
- ✅ Database schema migrated
- ✅ Demo catalog uploaded to S3

**In Progress** (0%):
- ⏳ Greeks calculation implementation
- ⏳ Real NSE data import
- ⏳ Greeks storage in database
- ⏳ Greeks export to Nautilus catalog

**Not Started** (70%):
- ❌ Greeks validation tests
- ❌ Full historical data import
- ❌ Production catalog generation

## Notes

This feature is **Sprint 0** from the EPIC-007 implementation proposal. It was originally scoped as a 2-week sprint but broken into a single comprehensive story for focused execution.

**Key Requirement**: STRAT-001 requires delta-based strike selection (±0.1 delta for weekly hedge). Greeks MUST be calculated and accessible during backtest.
