---
artifact_type: story
created_at: '2025-11-25T16:23:21.598824Z'
id: AUTO-EPIC-007-STRAT-001-IMPLEMENTATION-PROPOSAL
manual_update: 'true'
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: '001'
status: pending
title: Auto-generated title for EPIC-007-STRAT-001-IMPLEMENTATION-PROPOSAL
updated_at: '2025-11-25T16:23:21.598829Z'
---

## 1. Understanding EPIC-007 (Strategy Lifecycle)

### What EPIC-007 Actually Is

**NOT**: "Build Nautilus and Backtrader adapters"
**YES**: "Build governance framework for strategy intake → research → implementation → deployment → optimization"

### EPIC-007 Features (from PRD)

| Feature | Purpose | Our Focus |
|---------|---------|-----------|
| **FEATURE-007-ResearchPipeline** | Idea submission, hypothesis testing, data validation | ✅ HIGH - needed for STRAT-001 validation |
| **FEATURE-007-PrioritisationGovernance** | Scoring rubric, approval gates | ⚠️ MEDIUM - simplified for solo dev |
| **FEATURE-007-ImplementationBridge** | Design dossier, requirements mapping, eng handoff | ✅ HIGH - STRAT-001 → code translation |
| **FEATURE-007-DeploymentRunbooks** | Paper trading, go/no-go checklist, live deploy | ✅ HIGH - backtest → paper → live path |
| **FEATURE-007-ContinuousOptimization** | KPI tracking, variance analysis, iteration | ⚠️ MEDIUM - post-deployment monitoring |

### Corrected Understanding

**EPIC-007 sits ABOVE the framework adapters**:
```
Strategy Lifecycle (EPIC-007)
    │
    ├─> Research (backtest on Nautilus/Backtrader)
    ├─> Implementation (STRAT-001 domain logic)
    ├─> Deployment (paper trading → live)
    └─> Optimization (KPI tracking, iteration)
         │
         └─> Uses: Framework Adapters (EPIC-002 Backtesting, EPIC-003 Paper, EPIC-004 Live)
```

**Framework adapters are NOT part of EPIC-007** - they're infrastructure from earlier epics.

---

## 2. STRAT-001 Strategy Overview

### Strategy Summary
- **Type**: Options spread trading (debit spreads)
- **Instruments**: NIFTY50 monthly + weekly options
- **Position Structure**:
  - Monthly spread (Bull Call OR Bear Put) - 4 lots
  - Weekly hedge (opposite direction) - 4 lots
- **Capital**: ₹400,000
- **Entry**: RSI-based directional bias, 10:15 AM IST
- **Exit**: Multi-layer (portfolio SL 5%, individual SL 50%, profit 60%, time-based)
- **Risk**: Max drawdown <12.6%, target CAGR 18.7%

### Key Complexity Drivers
1. **Options-specific domain objects**: Strike, Expiry, Greeks, OptionContract
2. **Multi-leg position management**: Monthly + Weekly linked exits
3. **Delta-based strike selection**: ±0.1 delta for weekly hedge
4. **RSI calculation**: 14-day lookback for direction
5. **Immediate re-entry logic**: No cooldown after position exits
6. **Catastrophic loss override**: Hold deep ITM positions to expiry

---

## 3. Proposed EPIC-007 Implementation Scope

### 3.1 What We WILL Build

#### Phase 1: Strategy Domain Model (EPIC-007 Foundation)
**Goal**: Implement STRAT-001 as pure domain logic (framework-agnostic)

**Deliverables**:
```
src/domain/strategies/strat_001/
├── __init__.py
├── value_objects.py          # OptionContract, Strike, Greeks, RSISignal
├── aggregates.py             # MonthlySpread, WeeklyHedge, CombinedPosition
├── services/
│   ├── entry_manager.py      # RSI calculation, direction determination
│   ├── exit_manager.py       # Multi-layer exit logic, catastrophic override
│   ├── position_sizer.py     # Lot sizing, capital management
│   └── delta_calculator.py   # ±0.1 delta strike selection
└── strategy.py               # Main strategy orchestrator
```

**Why Domain-First**: STRAT-001 logic must work identically on Nautilus, Backtrader, and live trading.

#### Phase 2: Backtest Infrastructure (Framework Adapters)
**Goal**: Enable STRAT-001 backtest on Nautilus AND Backtrader

**Deliverables**:
```
src/adapters/frameworks/nautilus/
├── market_data_adapter.py    # Options chain data, Greeks feed
├── execution_adapter.py      # Multi-leg spread execution
├── portfolio_adapter.py      # Position tracking, P&L
├── clock_adapter.py          # Hourly candle timing
├── telemetry_adapter.py      # Backtest metrics logging
└── runtime_bootstrap.py      # Nautilus engine setup

src/adapters/frameworks/backtrader/
├── market_data_adapter.py
├── execution_adapter.py
├── portfolio_adapter.py
├── clock_adapter.py
├── telemetry_adapter.py
└── runtime_bootstrap.py      # Backtrader cerebro setup
```

**Why Both Frameworks**: Validates framework-agnostic architecture, provides fallback if one framework fails.

#### Phase 3: Research Pipeline (EPIC-007 Feature)
**Goal**: Backtest automation, parameter optimization, results analysis

**Deliverables**:
```
src/application/research/
├── backtest_runner.py        # Run STRAT-001 on both frameworks
├── parameter_optimizer.py    # Grid search for RSI thresholds, SL levels
├── results_analyzer.py       # P&L, Sharpe, drawdown comparison
└── report_generator.py       # PDF/HTML backtest reports
```

#### Phase 4: Deployment Runbooks (EPIC-007 Feature)
**Goal**: Transition from backtest → paper trading → live

**Deliverables**:
```
documentation/runbooks/
├── STRAT-001-BACKTEST.md     # How to run backtest, interpret results
├── STRAT-001-PAPER.md        # Paper trading checklist, monitoring
├── STRAT-001-LIVE.md         # Live deployment go/no-go criteria
└── STRAT-001-MONITORING.md   # KPI dashboard, alert thresholds
```

### 3.2 What We Will NOT Build (Out of Scope)

- ❌ Full governance dashboard (solo dev, minimal process)
- ❌ Strategy prioritization scoring (only one strategy for now)
- ❌ Automated capital allocation (future epic)
- ❌ Live trading adapters (EPIC-004, future work)
- ❌ Multi-strategy orchestration (future work)

---

## 4. Key Design Decisions

### Decision 1: Options Domain Model Design

**Problem**: Options have complex state (strike, expiry, Greeks, bid/ask spread)

**Proposed Solution**: Layered value objects

```python
# src/domain/strategies/strat_001/value_objects.py

@dataclass(frozen=True)
class Strike:
    """Strike price with NIFTY rounding (50-point intervals)."""
    value: float  # e.g., 25000.0

    def __post_init__(self):
        if self.value % 50 != 0:
            raise ValueError(f"Strike must be 50-point interval: {self.value}")

@dataclass(frozen=True)
class OptionContract:
    """Represents a single option contract."""
    underlying: InstrumentId  # NIFTY50
    strike: Strike
    expiry: datetime
    option_type: OptionType  # CALL or PUT
    lot_size: int = 75  # NIFTY standard

@dataclass(frozen=True)
class Greeks:
    """Option Greeks (for delta-based strike selection)."""
    delta: float
    gamma: float
    theta: float
    vega: float
    rho: float

@dataclass(frozen=True)
class SpreadLeg:
    """One leg of a multi-leg spread."""
    action: OrderAction  # BUY or SELL
    contract: OptionContract
    premium: float
    quantity: int

@dataclass(frozen=True)
class OptionSpread:
    """Complete spread definition (bull call, bear put, etc.)."""
    spread_id: str  # e.g., "M1", "M1_WEEKLY"
    spread_type: SpreadType  # BULL_CALL, BEAR_PUT
    legs: List[SpreadLeg]
    entry_time: datetime
    expiry: datetime

    @property
    def max_profit(self) -> float:
        """Credit spreads: credit received, Debit spreads: spread width - debit"""
        ...

    @property
    def max_loss(self) -> float:
        """Credit spreads: spread width - credit, Debit spreads: debit paid"""
        ...
```

**Rationale**: Immutable value objects ensure spread definitions can't be corrupted mid-trade.

### Decision 2: Delta-Based Strike Selection Service

**Problem**: Weekly hedge needs "±0.1 delta" strike, which varies by volatility

**Proposed Solution**: Delta calculator service

```python
# src/domain/strategies/strat_001/services/delta_calculator.py

class DeltaBasedStrikeSelector:
    """Select strike based on target delta using Black-Scholes."""

    def __init__(self, risk_free_rate: float = 0.05):
        self.risk_free_rate = risk_free_rate

    def find_strike_for_delta(
        self,
        spot: float,
        expiry: datetime,
        target_delta: float,  # e.g., -0.1 for puts, +0.1 for calls
        option_type: OptionType,
        iv_surface: Dict[Strike, float],  # Implied volatility by strike
    ) -> Strike:
        """
        Find strike closest to target delta.

        For -0.1 delta PUT hedge:
        - Typically 1300-1500 points OTM at NIFTY 26k
        - Auto-adjusts based on IV
        """
        # Binary search over strike range
        # Calculate delta using Black-Scholes for each strike
        # Return strike with delta closest to target
        ...
```

**Alternative Approaches**:
1. **Fixed offset** (e.g., always 1400 points OTM) - ❌ Breaks in high/low vol
2. **Percentile-based** (e.g., 10th percentile strike) - ❌ Doesn't capture directional risk
3. **Delta-based** (current proposal) - ✅ Adapts to volatility, consistent risk profile

**Decision**: Use delta-based selection with Black-Scholes approximation.

### Decision 3: Framework Adapter Architecture

**Problem**: Nautilus and Backtrader have completely different APIs

**Proposed Solution**: 3-layer adapter architecture

```
Layer 1: Port Abstraction (already exists from EPIC-001)
    ├── MarketDataPort
    ├── ExecutionPort
    ├── PortfolioPort
    ├── ClockPort
    └── TelemetryPort

Layer 2: Framework Adapter Base (shared logic)
    ├── BaseMarketDataAdapter (options chain caching)
    ├── BaseExecutionAdapter (multi-leg order sequencing)
    └── BasePortfolioAdapter (P&L calculation)

Layer 3: Framework-Specific Implementation
    ├── Nautilus adapters (Arrow tables, async execution)
    └── Backtrader adapters (pandas feeds, cerebro integration)
```

**Key Insight**: Most complexity is in Layer 2 (options-specific logic), not Layer 3 (framework wrapping).

### Decision 4: RSI Calculation Strategy

**Problem**: STRAT-001 needs 14-day RSI, but backtest data may be hourly

**Proposed Solution**: Multi-source RSI calculator

```python
# src/domain/strategies/strat_001/services/entry_manager.py

class RSICalculator:
    """Calculate RSI from multiple data sources."""

    def calculate_rsi(
        self,
        data_source: RSIDataSource,  # DAILY_BARS, HOURLY_BARS, LIVE_FEED
        lookback_days: int = 14,
    ) -> float:
        """
        Calculate 14-day RSI using appropriate data source.

        Priority:
        1. Daily bars (best for 14-day calculation)
        2. Hourly bars (convert to daily closes)
        3. Live feed (maintain rolling window)
        """
        ...
```

**Data Source Strategy**:
- **Backtest**: Use daily bars from historical data (Nautilus/Backtrader feeds)
- **Paper Trading**: Query NSE API for daily closes
- **Live Trading**: Maintain rolling 14-day window in Redis

### Decision 5: Immediate Re-entry Implementation

**Problem**: STRAT-001 requires "immediate re-entry" after exits (Section 3.5)

**Proposed Solution**: Event-driven re-entry scheduler

```python
# src/domain/strategies/strat_001/strategy.py

class STRAT001Strategy:
    def on_position_exit(self, exit_reason: ExitReason):
        """Handle position exit and schedule immediate re-entry."""

        # Exit both monthly and weekly
        self.exit_all_positions()

        # Skip immediate re-entry for portfolio SL or market close
        if exit_reason == ExitReason.PORTFOLIO_STOP_LOSS:
            self.schedule_cooldown(minutes=5)
            return

        if self.is_near_market_close():
            self.schedule_next_day_entry()
            return

        # Immediate re-entry (next candle)
        next_direction = self.re_evaluate_direction(
            previous_direction=self.current_direction,
            exit_reason=exit_reason,
        )

        self.schedule_immediate_reentry(
            direction=next_direction,
            next_candle_timestamp=self.get_next_candle_time(),
        )
```

**Rationale**: Event-driven architecture ensures no missed re-entries, maintains continuous market coverage.

---

## 5. Sprint Plan (5 Sprints, ~8 weeks total)

### Sprint 0: Data Pipeline Infrastructure (2 weeks) **[NEW - PREREQUISITE]**
**Goal**: Import NSE options data, calculate Greeks, store in TimescaleDB, generate Nautilus catalogs on S3

**Critical Dependency**: This MUST be completed before any backtesting can occur.

**Stories**:
1. **STORY-000-001**: Set up TimescaleDB database + schema (hypertables, indexes)
2. **STORY-000-002**: Implement NSE data importer + Black-Scholes Greeks calculator
3. **STORY-000-003**: Data validator (check for missing fields, IV outliers, spot consistency)
4. **STORY-000-004**: Bulk import script for historical data (1+ years NSE options)
5. **STORY-000-005**: Nautilus catalog generator (query DB → Parquet files)
6. **STORY-000-006**: S3 upload automation (boto3 integration)
7. **STORY-000-007**: CLI tool for import/catalog/upload workflow

**Acceptance Criteria**:
- [ ] TimescaleDB database running (local or AWS RDS)
- [ ] 1+ years of NSE options data imported with calculated Greeks
- [ ] Greeks validation: Delta ∈ [-1, 1], IV > 0, spot prices consistent
- [ ] Nautilus catalogs generated for full date range (hourly + daily bars)
- [ ] Catalogs uploaded to S3 bucket (s3://synaptic-trading-data/nautilus-catalogs/)
- [ ] CLI tool works end-to-end: import → calculate → catalog → upload
- [ ] Sample backtest loads data from S3 successfully

**Deliverables**:
- `src/data_pipeline/importers/` (NSE CSV → DB)
- `src/data_pipeline/calculators/` (Black-Scholes Greeks)
- `src/data_pipeline/catalog/` (DB → Nautilus Parquet)
- `src/data_pipeline/cli/` (import CLI tool)
- TimescaleDB schema scripts (`schema.sql`)
- Documented data import workflow (`DATA-PIPELINE-ARCHITECTURE.md`)

**Data Flow**:
```
NSE CSV/Parquet
    ↓
[Importer] → Calculate Greeks (Black-Scholes)
    ↓
TimescaleDB (hypertables: options_ticks, spot_prices)
    ↓
[Catalog Generator] → Hourly/Daily aggregates
    ↓
Parquet files → S3 (s3://synaptic-trading-data/nautilus-catalogs/)
    ↓
Nautilus Backtest Engine
```

**See**: `documentation/DATA-PIPELINE-ARCHITECTURE.md` for full technical specification.

---

### Sprint 1: Options Domain Model (1.5 weeks)
**Goal**: Implement STRAT-001 domain objects and services (framework-agnostic)

**Stories**:
1. **STORY-007-001**: Options value objects (Strike, OptionContract, Greeks, SpreadLeg)
2. **STORY-007-002**: Spread aggregates (OptionSpread, CombinedPosition)
3. **STORY-007-003**: Entry manager service (RSI calculation, direction determination)
4. **STORY-007-004**: Exit manager service (multi-layer exits, catastrophic override)
5. **STORY-007-005**: Delta calculator service (Black-Scholes strike selection)
6. **STORY-007-006**: Position sizer service (lot calculation, capital management)

**Acceptance Criteria**:
- [ ] All domain objects are immutable (frozen dataclasses)
- [ ] Unit tests for all services (>90% coverage)
- [ ] RSI calculator works with daily AND hourly data
- [ ] Delta calculator finds strikes within ±0.01 delta of target
- [ ] Entry/exit logic passes all STRAT-001 PRD scenarios

**Deliverables**:
- `src/domain/strategies/strat_001/` (complete)
- `tests/unit/domain/strategies/strat_001/` (>90% coverage)

---

### Sprint 2: Nautilus Framework Adapter (2 weeks)
**Goal**: Implement all 5 port adapters for NautilusTrader

**Stories**:
1. **STORY-007-007**: Nautilus market data adapter (options chain, Greeks feed)
2. **STORY-007-008**: Nautilus execution adapter (multi-leg spread orders)
3. **STORY-007-009**: Nautilus portfolio adapter (position tracking, P&L)
4. **STORY-007-010**: Nautilus clock adapter (hourly candle timing)
5. **STORY-007-011**: Nautilus telemetry adapter (backtest metrics)
6. **STORY-007-012**: Nautilus runtime bootstrap (engine configuration)

**Acceptance Criteria**:
- [ ] All 5 adapters pass contract tests (from EPIC-001)
- [ ] Options chain data loads from historical CSV/Parquet
- [ ] Multi-leg spread orders execute atomically
- [ ] Greeks calculated using Black-Scholes or market data
- [ ] Hourly candle clock triggers strategy events correctly
- [ ] Integration test: Simple spread trade executes end-to-end

**Deliverables**:
- `src/adapters/frameworks/nautilus/` (complete)
- `tests/contract/adapters/nautilus/` (all port contracts pass)
- `tests/integration/adapters/nautilus/` (end-to-end spread trade)

---

### Sprint 3: Backtrader Framework Adapter (2 weeks)
**Goal**: Implement all 5 port adapters for Backtrader

**Stories**:
1. **STORY-007-013**: Backtrader market data adapter (options chain, Greeks)
2. **STORY-007-014**: Backtrader execution adapter (multi-leg spread orders)
3. **STORY-007-015**: Backtrader portfolio adapter (position tracking, P&L)
4. **STORY-007-016**: Backtrader clock adapter (hourly candle timing)
5. **STORY-007-017**: Backtrader telemetry adapter (backtest metrics)
6. **STORY-007-018**: Backtrader runtime bootstrap (cerebro configuration)

**Acceptance Criteria**:
- [ ] All 5 adapters pass contract tests (same as Nautilus)
- [ ] Backtest results match Nautilus within ±2% (same data, same strategy)
- [ ] Multi-leg orders execute correctly (Backtrader doesn't natively support spreads)
- [ ] Integration test: Same spread trade as Sprint 2, identical results

**Deliverables**:
- `src/adapters/frameworks/backtrader/` (complete)
- `tests/contract/adapters/backtrader/` (all port contracts pass)
- `tests/integration/adapters/backtrader/` (end-to-end spread trade)
- Comparison report: Nautilus vs Backtrader execution

---

### Sprint 4: STRAT-001 Backtest + Research Pipeline (2 weeks)
**Goal**: Run complete STRAT-001 backtest on both frameworks, analyze results

**Stories**:
1. **STORY-007-019**: Backtest runner (orchestrate Nautilus + Backtrader runs)
2. **STORY-007-020**: Historical options data loader (NSE data ingestion)
3. **STORY-007-021**: Results analyzer (P&L, Sharpe, drawdown, trade log)
4. **STORY-007-022**: Parameter optimizer (grid search for RSI thresholds, SL levels)
5. **STORY-007-023**: Deployment runbook (backtest → paper → live checklist)
6. **STORY-007-024**: KPI dashboard (post-deployment monitoring spec)

**Acceptance Criteria**:
- [ ] STRAT-001 backtest runs on Nautilus (1-year historical data)
- [ ] STRAT-001 backtest runs on Backtrader (same data)
- [ ] Results match STRAT-001 target: CAGR 18.7%, max DD <12.6%
- [ ] Framework comparison: Nautilus vs Backtrader results within ±3%
- [ ] Parameter optimization identifies best RSI thresholds
- [ ] Deployment runbook complete (go/no-go criteria defined)

**Deliverables**:
- `src/application/research/` (complete)
- `scripts/run_strat_001_backtest.py` (CLI for backtest execution)
- `documentation/runbooks/STRAT-001-*.md` (backtest, paper, live runbooks)
- Backtest results report (PDF/HTML with charts, metrics)

---

## 6. Technical Dependencies & Risks

### Dependencies

**Required Libraries**:
```toml
[dependencies]
nautilus-trader = "^1.180.0"  # For Nautilus adapter
backtrader = "^1.9.78"        # For Backtrader adapter
py-vollib = "^1.0.1"          # Black-Scholes Greeks calculation
pandas = "^2.0.0"             # Data manipulation
numpy = "^1.24.0"             # Numerical calculations
scipy = "^1.10.0"             # Optimization (parameter search)
```

**Historical Options Data**:
- Source: NSE historical data (CSV/Parquet)
- Required fields: Strike, Expiry, Bid, Ask, IV, Greeks (or calculate)
- Date range: 1+ years for meaningful backtest
- Format: Standardized schema compatible with both frameworks

**Compute Requirements**:
- Backtest runtime: ~5-10 minutes per year (hourly data)
- Parameter optimization: ~2-4 hours (grid search)
- Memory: ~4GB for 1-year options chain data

### Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Options data unavailable** | HIGH | Fallback to simulated data with realistic spreads |
| **Greeks calculation inaccurate** | MEDIUM | Validate against broker platform (Zerodha Kite) |
| **Nautilus/Backtrader incompatibility** | HIGH | Contract tests ensure adapter compliance |
| **Backtest results don't match STRAT-001 targets** | MEDIUM | Parameter optimization, strategy iteration |
| **Framework execution differs significantly** | MEDIUM | Root cause analysis, fix adapter bugs |

---

## 7. Success Criteria

### Sprint Completion Criteria

**Sprint 1 (Domain Model)**:
- [ ] All STRAT-001 domain objects implemented
- [ ] Unit test coverage >90%
- [ ] RSI calculator validated against known data
- [ ] Delta calculator finds strikes within ±0.01 delta

**Sprint 2 (Nautilus)**:
- [ ] All 5 Nautilus adapters pass contract tests
- [ ] Integration test: Simple spread trade executes successfully
- [ ] Backtest runs without errors (even with dummy data)

**Sprint 3 (Backtrader)**:
- [ ] All 5 Backtrader adapters pass contract tests
- [ ] Integration test: Same spread trade as Nautilus
- [ ] Nautilus vs Backtrader results within ±2%

**Sprint 4 (Backtest)**:
- [ ] STRAT-001 full backtest completes on both frameworks
- [ ] Results meet targets: CAGR ~18.7%, max DD <12.6%
- [ ] Deployment runbook approved for paper trading

### EPIC-007 Success Metrics (from PRD)

| Goal ID | Metric | Target | How We'll Measure |
|---------|--------|--------|-------------------|
| **G-007-01** | Time from submission to decision | <10 days | Solo dev: self-approval same day |
| **G-007-02** | % strategies with complete dossier | 100% | STRAT-001 has full PRD ✅ |
| **G-007-03** | Deployment rollback readiness | 100% | Runbook includes rollback steps |
| **G-007-04** | Strategies with KPI dashboards | 100% | STRAT-001 monitoring dashboard defined |

---

## 8. Open Questions Status

### ANSWERED ✅

1. ~~**Historical Options Data Source**~~ ✅
   - ✅ We HAVE NSE historical options data (1+ years)
   - ✅ Includes: IV, OI, OHLC, bid/ask
   - ✅ Missing: Greeks (will calculate using Black-Scholes)
   - ✅ Storage: TimescaleDB → Nautilus catalogs → S3

2. ~~**Greeks Calculation Approach**~~ ✅
   - ✅ Use Black-Scholes model for Greeks calculation
   - ✅ Calculate during data import (not real-time during backtest)
   - ✅ Store in TimescaleDB alongside NSE data
   - Validation: Compare sample against broker platform (Zerodha Kite)

3. ~~**Framework Priority**~~ ✅
   - ✅ Nautilus FIRST (Sprint 2), then Backtrader (Sprint 3)
   - Rationale: Nautilus has better options support, more modern architecture

### REMAINING QUESTIONS ⚠️

4. **Backtest vs Paper Trading Scope**:
   - Focus on backtest first, defer paper trading to EPIC-003?
   - Or implement paper trading in Sprint 4? (adds 1+ weeks)

5. **Parameter Optimization Scope**:
   - Grid search for RSI thresholds (45/55), SL levels (50%), profit targets (60%)?
   - Or use STRAT-001 PRD values as-is for initial backtest?

6. **S3 Bucket Configuration** (NEW):
   - S3 bucket name: `synaptic-trading-data`?
   - AWS region: `ap-south-1` (Mumbai)?
   - IAM permissions: Who has access?

7. **TimescaleDB Hosting** (NEW):
   - Local PostgreSQL + TimescaleDB extension?
   - Or AWS RDS with TimescaleDB?
   - Connection details for import scripts?

---

## 9. Recommendation

**Proposed Approach**:

1. ✅ **Accept EPIC-007 as Strategy Lifecycle** (not just adapters)
2. ✅ **Sprint 0**: Data pipeline (NSE import → TimescaleDB → Nautilus catalogs → S3)
3. ✅ **Sprint 1**: Build STRAT-001 domain model (framework-agnostic)
4. ✅ **Sprint 2**: Nautilus adapters (priority framework)
5. ⚠️ **Sprint 3**: Backtrader adapters (validation framework - OPTIONAL)
6. ✅ **Sprint 4**: Full backtest + research pipeline

**Why This Order**:
- Domain-first ensures STRAT-001 logic is correct before framework integration
- Nautilus first (more modern, better options support)
- Backtrader validates framework-agnostic architecture
- Research pipeline enables parameter optimization and deployment readiness

**Total Timeline**: ~8 weeks (5 sprints: Sprint 0 [2w] + 4 implementation sprints [6w])

---

## 10. Next Steps

**Immediate (Today)**:
1. Review this proposal with stakeholders
2. Answer open questions (Section 8)
3. Confirm sprint priorities and timeline

**Short-term (This Week)**:
1. Create Sprint 0 README in vault
2. Set up TimescaleDB database (local or AWS RDS)
3. Configure S3 bucket for Nautilus catalogs
4. Begin NSE data import pipeline

**Medium-term (Next 8 Weeks)**:
1. Execute 5-sprint plan (Sprint 0-4)
2. Weekly progress updates in vault
3. Backtest results review and strategy iteration

---

**Approval Required**: Please review and approve/reject this proposal before proceeding with Sprint 0.

**Key Decision Points**:
- [ ] EPIC-007 scope (lifecycle framework, not just adapters)
- [ ] Sprint 0 added (data pipeline infrastructure)
- [ ] Sprint priorities (data → domain → Nautilus → Backtrader → backtest)
- [ ] Open questions resolved (see Section 8)
- [ ] Timeline acceptable (~8 weeks total)
