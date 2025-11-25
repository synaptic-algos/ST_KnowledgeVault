# DESIGN-008-02: Performance Monitoring & Reporting

**Version**: 1.0.0
**Last Updated**: 2025-11-21
**Status**: Implemented
**Related Story**: STORY-008-02-01
**Feature**: FEATURE-002-PerformanceAnalytics
**Epic**: EPIC-008-StrategyEnablement

---

## Table of Contents

1. [Purpose](#purpose)
2. [Overview](#overview)
3. [Performance Metrics](#performance-metrics)
4. [Data Collection Architecture](#data-collection-architecture)
5. [Metrics Calculation](#metrics-calculation)
6. [Performance Analytics](#performance-analytics)
7. [Alerting & Thresholds](#alerting--thresholds)
8. [Reporting & Visualization](#reporting--visualization)
9. [Integration with Existing Systems](#integration-with-existing-systems)
10. [Data Model](#data-model)
11. [Technical Architecture](#technical-architecture)
12. [Implementation Plan](#implementation-plan)

---

## Purpose

The Performance Monitoring & Reporting system tracks live strategy performance after deployment and capital allocation. This system:

- **Monitors returns**: Track PnL, returns, Sharpe ratio, and other key metrics
- **Detects underperformance**: Alert when strategies deviate from backtest expectations
- **Triggers reallocations**: Provide data for capital reallocation decisions
- **Validates research**: Compare live performance to backtest predictions
- **Reports to stakeholders**: Generate performance reports for PM, risk, and executives

### Key Stakeholders

- **Portfolio Management**: Monitor strategy performance, make reallocation decisions
- **Risk Management**: Track drawdowns, volatility, risk metrics
- **Strategy Researchers**: Validate live vs. backtest performance
- **Executives**: High-level portfolio performance overview
- **Compliance**: Audit trail of strategy performance

---

## Overview

### Problem Statement

After a strategy receives capital allocation (FEATURE-003) and is deployed live, the platform must:

1. **Collect performance data** from live trading systems
2. **Calculate metrics** (returns, Sharpe, drawdown, win rate, etc.)
3. **Compare to backtest** expectations and alert on deviations
4. **Track attribution** (PnL attribution by strategy, sector, researcher)
5. **Trigger actions** (reallocations, risk reviews, strategy retirement)
6. **Generate reports** for stakeholders

### Solution Approach

The Performance Monitoring system provides:

- **Data ingestion** from live trading systems (trades, positions, PnL)
- **Metrics engine** for calculating performance statistics
- **Comparison framework** for live vs. backtest analysis
- **Alerting system** for underperformance, drawdowns, risk breaches
- **Attribution engine** for multi-level PnL attribution
- **Reporting tools** for daily, weekly, monthly performance reports
- **Dashboard integration** for real-time performance visualization

### Relationship to Other Features

```
FEATURE-001: Research Pipeline
         ↓
   Strategy Submitted (with backtest metrics)
         ↓
FEATURE-002: Prioritisation Governance
         ↓
   Strategy Approved (score ≥ 7.0)
         ↓
FEATURE-003: Capital Allocation
         ↓
   Capital Allocated ($X deployed)
         ↓
FEATURE-004: Performance Monitoring ← [THIS FEATURE]
         ↓
   Live Performance Tracked
   ├─→ Underperformance detected → Reallocation (FEATURE-003)
   ├─→ Risk breach detected → Risk Review (FEATURE-005)
   └─→ Persistent underperformance → Retirement (FEATURE-006)
```

---

## Performance Metrics

### Core Metrics

#### 1. Returns Metrics

**Cumulative PnL**:
- Total profit/loss since deployment (USD)
- Formula: `Sum of daily PnL`
- Updated: Daily (end-of-day)

**Daily Return**:
- Daily percentage return
- Formula: `(Today's NAV - Yesterday's NAV) / Yesterday's NAV`
- Updated: Daily

**Cumulative Return**:
- Total return since deployment (%)
- Formula: `(Current NAV - Initial Capital) / Initial Capital`
- Updated: Daily

**Annualized Return**:
- Return annualized to 1 year
- Formula: `((1 + Cumulative Return) ^ (252 / Days)) - 1`
- Updated: Daily

#### 2. Risk-Adjusted Returns

**Sharpe Ratio**:
- Risk-adjusted return (excess return per unit of volatility)
- Formula: `(Annualized Return - Risk-Free Rate) / Annualized Volatility`
- Updated: Daily (requires ≥30 days of data)
- Interpretation: >1.0 good, >2.0 excellent, <0.5 poor

**Sortino Ratio**:
- Downside risk-adjusted return
- Formula: `(Annualized Return - Risk-Free Rate) / Downside Volatility`
- Updated: Daily (requires ≥30 days)

**Calmar Ratio**:
- Return per unit of maximum drawdown
- Formula: `Annualized Return / Max Drawdown`
- Updated: Daily

#### 3. Drawdown Metrics

**Current Drawdown**:
- Distance from peak NAV to current NAV (%)
- Formula: `(Current NAV - Peak NAV) / Peak NAV`
- Updated: Real-time (intraday)
- Alert threshold: Strategy-specific (e.g., 15%)

**Maximum Drawdown**:
- Largest peak-to-trough decline since deployment (%)
- Formula: `Min((NAV[i] - Peak NAV before i) / Peak NAV before i)`
- Updated: Real-time
- Alert threshold: Strategy-specific (e.g., 20%)

**Drawdown Duration**:
- Days since last peak NAV
- Updated: Daily
- Alert threshold: >90 days

**Recovery Time**:
- Days to recover from drawdown
- Calculated after recovery

#### 4. Volatility Metrics

**Daily Volatility**:
- Standard deviation of daily returns
- Formula: `StdDev(Daily Returns)`
- Updated: Daily (rolling 30-day window)

**Annualized Volatility**:
- Volatility scaled to 1 year
- Formula: `Daily Volatility * sqrt(252)`
- Updated: Daily

#### 5. Trade Statistics

**Win Rate**:
- Percentage of profitable trades
- Formula: `Winning Trades / Total Trades`
- Updated: After each trade

**Average Win**:
- Average profit of winning trades (USD)
- Updated: After each trade

**Average Loss**:
- Average loss of losing trades (USD)
- Updated: After each trade

**Win/Loss Ratio**:
- Ratio of average win to average loss
- Formula: `Average Win / |Average Loss|`
- Updated: After each trade

**Profit Factor**:
- Gross profit / gross loss
- Formula: `Sum(Winning Trades) / |Sum(Losing Trades)|`
- Updated: After each trade
- Interpretation: >1.5 good, >2.0 excellent, <1.0 losing strategy

#### 6. Capacity & Utilization

**Capital Utilization**:
- Percentage of allocated capital actively deployed
- Formula: `Market Value of Positions / Allocated Capital`
- Updated: Real-time

**Average Position Size**:
- Average size of open positions (USD)
- Updated: Real-time

**Turnover Rate**:
- Trading frequency
- Formula: `(Total Buy Volume + Total Sell Volume) / 2 / Average Capital`
- Updated: Monthly

### Comparison to Backtest

For each metric, track both live and backtest values:

```python
metric_comparison = {
    "sharpe_ratio": {
        "live": 1.8,
        "backtest": 2.1,
        "deviation_pct": -14.3,  # (1.8 - 2.1) / 2.1
        "status": "underperforming"  # if deviation < -20%
    },
    "max_drawdown_pct": {
        "live": -18.5,
        "backtest": -12.0,
        "deviation_pct": +54.2,  # worse drawdown
        "status": "alert"  # if live > backtest * 1.5
    },
    ...
}
```

---

## Data Collection Architecture

### Data Sources

**Primary Source**: Live Trading System
- Trade executions (timestamp, symbol, side, quantity, price, fees)
- Position snapshots (EOD positions, market value, unrealized PnL)
- Daily PnL (realized + unrealized)
- Account balances (cash, margin, NAV)

**Secondary Sources**:
- Market data (for position valuation)
- Strategy metadata (from Strategy Catalog - FEATURE-001)
- Allocation data (from Capital Allocation - FEATURE-003)
- Backtest metrics (from Research Pipeline - FEATURE-001)

### Data Ingestion

**File-Based Ingestion** (MVP approach):
- Daily CSV/JSON files from trading system
- File format: `performance_data_{strategy_id}_{date}.csv`
- Fields: date, strategy_id, nav, daily_pnl, realized_pnl, unrealized_pnl, trades, positions
- Ingestion schedule: Daily at market close (e.g., 5 PM ET)
- Storage: `data/performance/raw/{strategy_id}/{year}/{month}/`

**API-Based Ingestion** (future):
- REST API from trading system
- Real-time streaming via WebSocket
- Event-driven updates (trade executed, position updated, PnL updated)

### Data Validation

Before processing, validate ingested data:

```python
def validate_performance_data(data: PerformanceDataPoint) -> ValidationResult:
    """
    Validate performance data before processing.

    Checks:
    - All required fields present
    - NAV > 0
    - Daily PnL reasonable (e.g., < 50% of NAV)
    - Timestamp is valid trading day
    - No duplicate entries for same day
    """
    violations = []

    if data.nav <= 0:
        violations.append("NAV must be positive")

    if abs(data.daily_pnl / data.nav) > 0.5:
        violations.append("Daily PnL > 50% of NAV (data error?)")

    # ... additional checks

    return ValidationResult(is_valid=len(violations) == 0, violations=violations)
```

---

## Metrics Calculation

### Calculation Engine

**MetricsCalculator** class computes all metrics from raw performance data:

```python
class MetricsCalculator:
    """
    Calculate performance metrics from raw data.

    Supports:
    - Returns metrics (cumulative, daily, annualized)
    - Risk metrics (Sharpe, Sortino, volatility)
    - Drawdown metrics (current, max, duration)
    - Trade statistics (win rate, profit factor)
    """

    def calculate_metrics(
        self,
        performance_data: List[PerformanceDataPoint],
        backtest_metrics: Dict[str, float],
    ) -> PerformanceMetrics:
        """
        Calculate all metrics for a strategy.

        Args:
            performance_data: List of daily performance data points
            backtest_metrics: Expected metrics from backtest

        Returns:
            PerformanceMetrics with live and backtest comparison
        """
```

### Calculation Frequency

**Real-time** (intraday updates):
- Current drawdown
- Capital utilization
- Position count

**Daily** (end-of-day):
- Cumulative PnL
- Daily/cumulative returns
- Sharpe/Sortino ratios (if ≥30 days)
- Max drawdown
- Win rate, profit factor

**Weekly**:
- 7-day rolling metrics
- Weekly performance report

**Monthly**:
- Monthly returns
- Attribution analysis
- Performance vs. benchmark

### Minimum Data Requirements

Some metrics require minimum data:

- **Sharpe/Sortino Ratio**: ≥30 days (preferably 60)
- **Annualized Return**: ≥30 days (more accurate with ≥90)
- **Max Drawdown**: ≥1 day (more meaningful with ≥30)
- **Win Rate**: ≥10 trades (more meaningful with ≥50)

---

## Performance Analytics

### Attribution Analysis

**Multi-Level Attribution**:

1. **Strategy-Level**: PnL by individual strategy
2. **Sector-Level**: PnL by market sector (technology, financials, crypto, etc.)
3. **Asset Class-Level**: PnL by asset class (equity options, futures, crypto)
4. **Researcher-Level**: PnL by researcher (aggregated across their strategies)
5. **Pool-Level**: PnL by capital pool

**Implementation**:
```python
def calculate_attribution(
    strategies: List[Strategy],
    performance_data: Dict[str, PerformanceDataPoint],
    period: str = "MTD",  # MTD, QTD, YTD, ALL
) -> AttributionReport:
    """
    Calculate multi-level PnL attribution.

    Returns:
        AttributionReport with breakdowns by strategy, sector, asset class, researcher, pool
    """
```

### Cohort Analysis

Track performance by deployment cohort (strategies deployed in same month):

```python
cohort_analysis = {
    "2025-01": {
        "strategies": ["STRAT-001", "STRAT-002", "STRAT-003"],
        "avg_sharpe": 1.8,
        "avg_return_pct": 12.5,
        "best_strategy": "STRAT-002",
        "worst_strategy": "STRAT-003",
    },
    ...
}
```

### Benchmark Comparison

Compare strategy/portfolio performance to benchmarks:

- SPX (S&P 500 Index)
- BTC (Bitcoin)
- Cash (risk-free rate)
- Custom composite benchmark

### Rolling Performance

Calculate metrics over rolling windows:

- 30-day rolling Sharpe
- 60-day rolling returns
- 90-day rolling volatility

---

## Alerting & Thresholds

### Alert Types

#### 1. Underperformance Alerts

**Trigger**: Live metrics significantly worse than backtest

- **Sharpe Ratio**: Live < Backtest * 0.7 (30% worse)
- **Returns**: Live < Backtest * 0.7 (30% worse)
- **Max Drawdown**: Live > Backtest * 1.5 (50% worse drawdown)

**Recipients**: PM, Researcher, Risk Manager

**Actions**:
- Investigate strategy behavior
- Consider reallocation
- Review risk parameters

#### 2. Drawdown Alerts

**Trigger**: Drawdown exceeds thresholds

- **Warning**: Current drawdown > 10%
- **Critical**: Current drawdown > 15%
- **Emergency**: Current drawdown > 20%

**Recipients**: PM, Risk Manager (+ Executive if emergency)

**Actions**:
- Review positions
- Reduce leverage
- Consider partial withdrawal

#### 3. Risk Breach Alerts

**Trigger**: Risk limits exceeded

- **Volatility**: Annualized volatility > expected * 1.3
- **VaR**: 1-day VaR > threshold
- **Concentration**: Single position > 20% of NAV

**Recipients**: Risk Manager, PM

**Actions**:
- Reduce positions
- Hedge exposure
- Escalate to risk committee

#### 4. Performance Milestone Alerts

**Trigger**: Strategy hits milestones

- **Profitability**: Strategy becomes profitable (cumulative PnL > 0)
- **Return Target**: Achieves annual return target (e.g., 15%)
- **Max Drawdown**: New max drawdown reached

**Recipients**: PM, Researcher

**Actions**:
- Celebrate success (positive milestone)
- Analyze performance drivers
- Document lessons learned

#### 5. Data Quality Alerts

**Trigger**: Missing or suspicious data

- **Missing Data**: No performance data for >1 trading day
- **Outlier**: Daily PnL > 50% of NAV
- **NAV Disconnect**: NAV not consistent with trades

**Recipients**: Data Operations, PM

**Actions**:
- Investigate data pipeline
- Reconcile with trading system
- Manual data entry if needed

### Alert Delivery

**Channels**:
- Email (primary)
- Dashboard notifications
- Slack/Teams integration (future)
- SMS (critical alerts only)

**Frequency**:
- Immediate (critical alerts)
- Daily digest (warnings)
- Weekly summary (all alerts)

---

## Reporting & Visualization

### Daily Performance Report

**Generated**: Daily at market close
**Recipients**: PM, Researchers (for their strategies)

**Contents**:
- Strategy PnL (daily and cumulative)
- Top 3 winners and losers
- NAV and capital utilization
- Open positions count
- Alerts (if any)

### Weekly Performance Report

**Generated**: Monday morning
**Recipients**: PM, Risk Manager, Researchers

**Contents**:
- Weekly returns (by strategy, sector, pool)
- Sharpe ratio (rolling 30-day)
- Drawdown analysis
- Trade statistics (win rate, profit factor)
- Attribution analysis
- Benchmark comparison

### Monthly Performance Report

**Generated**: 1st business day of month
**Recipients**: PM, Risk Manager, Executives, Council

**Contents**:
- Monthly returns (all strategies)
- Cumulative performance since deployment
- Risk metrics (volatility, max drawdown)
- Attribution analysis (by sector, researcher, pool)
- Cohort analysis (deployment cohorts)
- Capital utilization and efficiency
- Top performers and underperformers
- Reallocation recommendations

### Ad-Hoc Reports

**Custom Reports** (via CLI):
- Strategy deep-dive
- Sector performance
- Researcher performance
- Period comparison (e.g., Q1 vs. Q2)
- Backtest vs. live comparison

---

## Integration with Existing Systems

### Integration Points

```
┌────────────────────────────────────────────────────────────────┐
│                    System Integration Map                       │
└────────────────────────────────────────────────────────────────┘

FEATURE-001: Research Pipeline (Strategy Catalog)
    │
    ├─→ Strategy metadata (backtest metrics for comparison)
    └─→ Strategy status updates (live performance data)

FEATURE-002: Lifecycle Dashboard
    │
    ├─→ Performance KPIs (returns, Sharpe, drawdown)
    ├─→ Real-time metrics updates
    └─→ Alerts (underperformance, drawdowns, risk breaches)

FEATURE-003: Capital Allocation
    │
    ├─→ Allocation data (capital deployed, allocation date)
    ├─→ Trigger reallocations (underperformance → withdrawal/reduction)
    └─→ Performance attribution by allocation

FEATURE-005: Risk Monitoring (future)
    │
    ├─→ Risk metrics (volatility, VaR, beta)
    └─→ Risk breach alerts

Live Trading System (external)
    │
    ├─→ Trade data (executions)
    ├─→ Position data (holdings, market value)
    └─→ PnL data (realized + unrealized)
```

### Data Flow

**Performance Data Ingestion**:
```
(1) Live Trading System generates daily performance file
         ↓
(2) Performance Collector ingests file
    - Validate data quality
    - Store raw data
         ↓
(3) Metrics Calculator computes metrics
    - Calculate all performance metrics
    - Compare to backtest expectations
         ↓
(4) Update Systems
    - Update Strategy Catalog (performance section)
    - Update Allocations (performance field)
    - Update Dashboard (KPIs)
    - Send alerts (if thresholds breached)
         ↓
(5) Generate Reports
    - Daily performance report
    - Weekly/monthly (on schedule)
```

---

## Data Model

### Performance Data Point

```yaml
# File: performance_data/{strategy_id}/{date}.yaml

performance_data_point:
  strategy_id: STRAT-2025-012
  allocation_id: ALLOC-2025-025
  date: 2025-11-21

  # NAV and PnL
  nav: 350_500.00  # Net Asset Value
  daily_pnl: 2_500.00  # Daily profit/loss
  realized_pnl: 1_200.00  # From closed trades
  unrealized_pnl: 1_300.00  # From open positions

  # Positions
  num_positions: 5
  gross_exposure_usd: 320_000.00
  net_exposure_usd: 120_000.00

  # Trades
  num_trades: 3
  trade_volume_usd: 150_000.00

  # Cash
  cash_balance: 30_500.00
  margin_used: 0.00

  # Timestamp
  timestamp: 2025-11-21T16:00:00Z
  market_close: true
```

### Performance Metrics

```yaml
# File: performance_metrics/{strategy_id}/current.yaml

performance_metrics:
  strategy_id: STRAT-2025-012
  allocation_id: ALLOC-2025-025
  deployment_date: 2025-11-01
  days_live: 20
  last_updated: 2025-11-21T16:30:00Z

  # Returns
  cumulative_pnl_usd: 50_500.00
  cumulative_return_pct: 14.43  # (350_500 - 300_000) / 300_000
  daily_return_pct: 0.72
  annualized_return_pct: 285.6  # High because only 20 days

  # Risk-Adjusted Returns
  sharpe_ratio: 2.1
  sortino_ratio: 3.2
  calmar_ratio: 14.3

  # Drawdown
  current_drawdown_pct: -2.5
  max_drawdown_pct: -5.8
  drawdown_duration_days: 3
  peak_nav: 360_000.00
  peak_date: 2025-11-18

  # Volatility
  daily_volatility_pct: 1.2
  annualized_volatility_pct: 19.0

  # Trade Statistics
  total_trades: 45
  winning_trades: 32
  losing_trades: 13
  win_rate_pct: 71.1
  average_win_usd: 2_100.00
  average_loss_usd: -980.00
  win_loss_ratio: 2.14
  profit_factor: 2.85

  # Capacity
  capital_utilization_pct: 91.4  # 320K / 350K
  average_position_size_usd: 64_000.00

  # Comparison to Backtest
  backtest_comparison:
    sharpe_ratio:
      live: 2.1
      backtest: 2.3
      deviation_pct: -8.7
      status: "on_track"

    annualized_return_pct:
      live: 285.6  # Noisy, only 20 days
      backtest: 22.5
      deviation_pct: null  # Not comparable yet
      status: "insufficient_data"

    max_drawdown_pct:
      live: -5.8
      backtest: -12.0
      deviation_pct: -51.7  # Better than expected
      status: "outperforming"
```

### Performance Alert

```yaml
# File: performance_alerts/{alert_id}.yaml

performance_alert:
  alert_id: ALERT-PERF-2025-078
  strategy_id: STRAT-2025-008
  alert_type: underperformance
  severity: high

  timestamp: 2025-11-21T16:45:00Z
  triggered_by: MetricsCalculator

  message: |
    Strategy "BTC Trend Following" is significantly underperforming backtest expectations.

    Sharpe Ratio: 0.8 (live) vs. 1.5 (backtest) = -46.7% deviation
    Max Drawdown: -25% (live) vs. -15% (backtest) = +66.7% worse

    Recommend: Review strategy, consider partial withdrawal

  metrics:
    sharpe_ratio_live: 0.8
    sharpe_ratio_backtest: 1.5
    max_drawdown_live_pct: -25.0
    max_drawdown_backtest_pct: -15.0

  recipients:
    - pm_lead@synaptic.com
    - researcher_003@synaptic.com
    - risk_manager@synaptic.com

  acknowledged: false
  acknowledged_by: null
  acknowledged_at: null

  actions_taken: []
```

---

## Technical Architecture

### Module Structure

```
src/strategy_lifecycle/performance/
├── __init__.py
├── models.py                        # Data models (PerformanceDataPoint, PerformanceMetrics, Alert)
├── data_collector.py                # Ingest performance data from files/API
├── metrics_calculator.py            # Calculate all performance metrics
├── comparison_engine.py             # Compare live vs. backtest metrics
├── attribution_engine.py            # Multi-level PnL attribution
├── alert_engine.py                  # Generate and send performance alerts
├── report_generator.py              # Generate daily/weekly/monthly reports
├── integrations/
│   ├── catalog_integration.py       # Update Strategy Catalog
│   ├── allocation_integration.py    # Integration with Allocations
│   └── dashboard_integration.py     # Update Dashboard KPIs
├── cli/
│   ├── performance_cli.py           # CLI for performance queries
│   └── report_cli.py                # CLI for report generation
└── tests/
    ├── test_data_collector.py
    ├── test_metrics_calculator.py
    ├── test_comparison_engine.py
    ├── test_alert_engine.py
    └── test_report_generator.py
```

### Key Components

#### DataCollector

**Responsibilities**:
- Ingest performance data from files or API
- Validate data quality
- Store raw data
- Handle missing/delayed data

```python
class DataCollector:
    def collect_daily_performance(
        self,
        strategy_id: str,
        date: datetime,
        source: str = "file",  # "file" or "api"
    ) -> PerformanceDataPoint:
        """Collect and validate performance data for a strategy."""
```

#### MetricsCalculator

**Responsibilities**:
- Calculate all performance metrics
- Handle minimum data requirements
- Cache calculated metrics
- Update metrics incrementally (daily)

```python
class MetricsCalculator:
    def calculate_metrics(
        self,
        strategy_id: str,
        performance_history: List[PerformanceDataPoint],
        backtest_metrics: Dict[str, float],
    ) -> PerformanceMetrics:
        """Calculate comprehensive performance metrics."""
```

#### ComparisonEngine

**Responsibilities**:
- Compare live metrics to backtest expectations
- Calculate deviation percentages
- Determine status (on_track, underperforming, outperforming)
- Generate comparison reports

```python
class ComparisonEngine:
    def compare_to_backtest(
        self,
        live_metrics: PerformanceMetrics,
        backtest_metrics: Dict[str, float],
    ) -> ComparisonReport:
        """Compare live performance to backtest expectations."""
```

#### AlertEngine

**Responsibilities**:
- Evaluate alert conditions
- Generate alerts
- Send notifications (email, dashboard)
- Track alert acknowledgments

```python
class AlertEngine:
    def evaluate_alerts(
        self,
        metrics: PerformanceMetrics,
        comparison: ComparisonReport,
        thresholds: Dict[str, float],
    ) -> List[PerformanceAlert]:
        """Evaluate alert conditions and generate alerts."""
```

---

## Implementation Plan

### Story Breakdown

**STORY-007-04-01: Design Performance Monitoring Framework** (2h) - THIS DOCUMENT
- Tasks:
  1. Design performance metrics (returns, risk, drawdown, trade stats)
  2. Define data collection architecture
  3. Create alerting and reporting strategy
  4. Document integration points
- Deliverable: `DESIGN-007-05-PerformanceMonitoring.md` (this document)

**STORY-007-04-02: Implement Performance Data Collection** (3h)
- Tasks:
  1. Implement data models (PerformanceDataPoint, PerformanceMetrics, Alert)
  2. Implement DataCollector (file-based ingestion)
  3. Implement MetricsCalculator (all metrics)
  4. Implement ComparisonEngine (live vs. backtest)
  5. Write tests (40+ test cases)
  6. Create CLI tool (performance_cli.py)
- Deliverables:
  - `models.py` (200 lines)
  - `data_collector.py` (150 lines)
  - `metrics_calculator.py` (300 lines)
  - `comparison_engine.py` (150 lines)
  - `test_data_collector.py` (20+ tests)
  - `test_metrics_calculator.py` (20+ tests)
  - `performance_cli.py` (200 lines)

**STORY-007-04-03: Build Performance Analytics & Reporting** (3h)
- Tasks:
  1. Implement AttributionEngine (multi-level PnL attribution)
  2. Implement AlertEngine (alert generation and delivery)
  3. Implement ReportGenerator (daily/weekly/monthly reports)
  4. Integrate with Strategy Catalog, Allocations, Dashboard
  5. Write tests (30+ test cases)
  6. Create CLI tool (report_cli.py)
- Deliverables:
  - `attribution_engine.py` (200 lines)
  - `alert_engine.py` (250 lines)
  - `report_generator.py` (300 lines)
  - Integration modules (150 lines)
  - `test_alert_engine.py` (15+ tests)
  - `test_report_generator.py` (15+ tests)
  - `report_cli.py` (200 lines)

### Total Estimated Effort

- **STORY-007-04-01**: 2 hours (Design - COMPLETE)
- **STORY-007-04-02**: 3 hours (Implementation - Data Collection)
- **STORY-007-04-03**: 3 hours (Implementation - Analytics & Reporting)
- **Total**: 8 hours

### Success Criteria

**FEATURE-004 is complete when**:

1. ✅ Performance data can be ingested from files
2. ✅ All core metrics calculated (returns, Sharpe, drawdown, win rate, etc.)
3. ✅ Live vs. backtest comparison working
4. ✅ Alerts generated for underperformance, drawdowns, risk breaches
5. ✅ Attribution analysis (by strategy, sector, researcher, pool)
6. ✅ Daily, weekly, monthly reports generated
7. ✅ Integration with Strategy Catalog, Allocations, Dashboard
8. ✅ CLI tools for querying performance and generating reports
9. ✅ Comprehensive tests (70+ test cases)
10. ✅ Documentation (this design document + README)

---

**End of Design Document**
