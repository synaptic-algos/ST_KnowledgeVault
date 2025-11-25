---
artifact_type: story
asset_class: equities
created_at: '2025-11-25T16:23:21.837015Z'
id: AUTO-Equities_Strategy_Template
last_review: 2025-11-04
manual_update: true
owner: strategy_ops_team
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
template_id: equities-strategy-template
title: Auto-generated title for Equities_Strategy_Template
updated_at: '2025-11-25T16:23:21.837018Z'
version: 1.0.0
---

# Equities Strategy Template

Complete every section to capture the business logic required to implement and operate an equities strategy. Use `N/A` where not applicable. Link supporting documents inline.

## 1. Metadata
- **Strategy ID**: 
- **Strategy Name**: 
- **Owner / PM**: 
- **Engineering Lead**: 
- **Risk Officer**: 
- **Lifecycle State**: `Idea | Research | Prioritised | In Dev | Paper | Live | Retired`
- **Target Deployment**: `Backtest | Paper | Live`
- **Expected Go-Live**: 
- **Version**: `0.1.0`

## 2. Hypothesis & Objectives
- **Market Thesis**: 
- **Alpha Drivers**: 
- **Time Horizon**: (intraday, swing, positional)
- **KPIs & Success Criteria**: (Sharpe, Sortino, hit rate, drawdown, capacity)

## 3. Universe & Data
- **Instrument Universe**: (indices, sectors, watchlist criteria)
- **Liquidity Filters**: (min ADV, price constraints)
- **Data Feeds**: (vendors, bar intervals, corporate action handling)
- **Alternative/Fundamental Inputs**: 
- **Data Pre-processing**: (feature engineering, normalisation)

## 4. Signals & Indicators
- **Entry Rules**: (indicator thresholds, pattern recognition)
- **Exit Rules**: (profit targets, stop loss, time stops)
- **Indicators / Features Used**: (moving averages, RSI, factor models)
- **Signal Frequency**: (event-driven, periodic)

## 5. Strategy Workflow
- **Pseudocode / Flow**: Outline decision sequence from data ingest to order placement.
- **State Management**: (position tracking, indicator caching)
- **Execution Timing**: (market open, close, intraday)

## 6. Risk Management
- **Position Sizing**: (fixed %, volatility targeting, Kelly)
- **Exposure Limits**: (per symbol, sector, beta)
- **Drawdown / Stop Policies**: (hard stops, trailing stops)
- **Hedging Plan**: (instruments, triggers)
- **Compliance Notes**: (restricted lists, ESG constraints)

## 7. Capital & Operations
- **Capital Allocation**: 
- **Leverage / Margin**: 
- **Rebalancing Frequency**: 
- **Broker / Execution Adapter**: 

## 8. Backtest & Validation
- **Historical Period**: 
- **Benchmark(s)**: 
- **Key Metrics to Validate**: (PnL, turnover, slippage)
- **Scenario Tests**: (crash, volatility spike)
- **Assumptions & Limitations**: 

## 9. Deployment & Monitoring
- **Telemetry Metrics**: (latency, fill rate, P&L, risk metrics)
- **Alert Thresholds**: 
- **Runbooks / On-call Procedures**: 
- **Post-Trade Review Cadence**: 

## 10. Dependencies
- **External Systems**: (data APIs, risk engines)
- **Internal Modules**: (shared libraries, adapters)
- **Secrets/Credentials**: (vault references)

## 11. Implementation Checklist
- [ ] Template reviewed with engineering  
- [ ] Risk approval obtained  
- [ ] Added to strategy catalogue  
- [ ] Linked to EPIC-008 stories  

## 12. Version History
| Version | Date | Description | Reviewer |
|---------|------|-------------|----------|
| 1.0.0 | 2025-11-04 | Template created | strategy_ops_team |

## 13. References
- Research links: 
- Relevant design docs: 
- Comparable strategies: 
