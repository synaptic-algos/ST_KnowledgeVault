---
template_id: futures-strategy-template
version: 1.0.0
last_review: 2025-11-04
asset_class: futures
owner: strategy_ops_team
---

# Futures Strategy Template

## 1. Metadata
- **Strategy ID / Name**: 
- **Universe / Exchanges**: 
- **Owner / PM**: 
- **Engineering Lead**: 
- **Risk Officer**: 
- **Lifecycle State**: 
- **Target Deployment**: 
- **Version**: `0.1.0`

## 2. Thesis & Objectives
- **Market Thesis**: 
- **Alpha Drivers**: (trend, carry, mean reversion, spread)
- **Time Horizon**: 
- **KPIs**: (return, drawdown, roll cost, Sharpe)

## 3. Contract & Roll Policy
- **Eligible Contracts**: 
- **Roll Methodology**: (calendar, volume, open interest)
- **Spread/Calendar Structures**: 
- **Trading Hours / Holiday Calendar**: 

## 4. Data Requirements
- **Price & Volume Feeds**: 
- **Funding / Carry Data**: 
- **Economic Indicators**: 
- **Data Pre-processing**: 

## 5. Signal Logic
- **Entry Conditions**: 
- **Exit Conditions**: 
- **Indicators / Models**: (momentum, seasonality, machine learning)
- **Execution Timing**: (session boundaries, event-driven)

## 6. Risk & Leverage
- **Position Sizing**: (volatility scaling, fixed risk)
- **Leverage / Margin Policy**: 
- **Risk Limits**: (contract caps, VAR thresholds)
- **Hedging**: (cross hedges, options overlays)

## 7. Capital & Operations
- **Capital Allocation**: 
- **Collateral Management**: 
- **Funding & Carry Considerations**: 

## 8. Backtest & Validation
- **Historical Window**: 
- **Scenario Tests**: (roll stress, contango/backwardation)
- **Slippage/Cost Assumptions**: 
- **Validation Metrics**: (PnL, roll yield, turnover)

## 9. Deployment & Monitoring
- **Execution Adapter**: 
- **Telemetry Metrics**: (PnL, margin usage, VAR, roll cost)
- **Alert Thresholds**: 
- **Runbooks**: (roll failure, margin call procedures)

## 10. Dependencies
- **External Systems**: (clearing broker, data APIs)
- **Internal Integrations**: (risk engine, data pipeline)

## 11. Checklist
- [ ] Roll policy validated  
- [ ] Margin impact reviewed by risk  
- [ ] Telemetry configuration defined  
- [ ] Strategy catalogue updated

## 12. Version History
| Version | Date | Description | Reviewer |
|---------|------|-------------|----------|
| 1.0.0 | 2025-11-04 | Template created | strategy_ops_team |
