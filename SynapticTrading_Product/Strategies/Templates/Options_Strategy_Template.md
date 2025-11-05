---
template_id: options-strategy-template
version: 1.0.0
last_review: 2025-11-04
asset_class: options
owner: strategy_ops_team
---

# Options Strategy Template

Use this template for delta/gamma/theta strategies, spreads, or hedges. Capture quantitative detail for greeks management and compliance.

## 1. Metadata
- **Strategy ID / Name**: 
- **Primary Underlyings**: 
- **Strategy Owner / PM**: 
- **Engineering Lead**: 
- **Risk Officer**: 
- **Lifecycle State**: 
- **Deployment Targets**: 
- **Version**: `0.1.0`

## 2. Hypothesis & Objectives
- **Market Thesis**: 
- **Edge Source**: (volatility, skew, term structure)
- **Time Horizon**: (weekly, monthly)
- **Target Greeks**: (delta, gamma, vega, theta)
- **Performance KPIs**: (PnL, IV edge, win rate, drawdown)

## 3. Strategy Structure
- **Option Structures**: (spreads, butterflies, straddles)
- **Contract Selection**: (strike logic, expiry ladder)
- **Adjustment Rules**: (roll, hedge triggers)

## 4. Data & Models
- **Volatility Data**: (surface source, frequency)
- **Pricing Models**: (Black-Scholes, Heston, custom)
- **Market Data Needs**: (underlying bars/ticks, greeks feed)
- **Risk Models**: (scenario analysis, stress testing)

## 5. Signals & Execution
- **Entry Conditions**: (vol triggers, price patterns)
- **Exit Conditions**: (profit target, time decay, stop loss)
- **Order Workflow**: (limit/market, legs execution plan)
- **Execution Constraints**: (slippage tolerance, liquidity thresholds)

## 6. Greeks & Hedging
- **Target Greeks Ranges**: 
- **Hedging Instruments**: (underlying equity/futures, options overlays)
- **Hedging Frequency**: 
- **Hedge Trigger Rules**: 

## 7. Risk Controls
- **Margin Usage**: 
- **Max Exposure**: (per underlying, per expiry bucket)
- **Drawdown Limits**: 
- **Regulatory / Compliance Checks**: (short options policy, reporting)

## 8. Capital Allocation
- **Capital Bucket**: 
- **Leverage / Notional Limits**: 
- **Position Scaling**: (vol-adjusted, capital tiers)

## 9. Backtest & Validation Plan
- **Historical Window**: 
- **Scenarios**: (vol spikes, crash, low liquidity)
- **Assumptions**: (transaction costs, borrow availability)
- **KPIs**: (PnL, IV edge, hedge effectiveness)

## 10. Deployment & Monitoring
- **Telemetry**: (PnL, Greeks exposure, margin usage, alerts)
- **Alert Thresholds**: (delta/gamma drift, margin utilization)
- **Runbooks**: (emergency unwind, risk escalation)
- **Reporting Cadence**: (daily/weekly summaries)

## 11. Dependencies
- **Data Sources**: (vol surfaces, option chain cache)
- **Integrations**: (risk engine, OMS)
- **Secrets**: 

## 12. Checklist
- [ ] Template reviewed by derivatives PM & risk  
- [ ] Hedging playbook attached  
- [ ] Telemetry metrics configured  
- [ ] Added to strategy catalogue

## 13. Version History
| Version | Date | Description | Reviewer |
|---------|------|-------------|----------|
| 1.0.0 | 2025-11-04 | Template created | strategy_ops_team |

## 14. References
- Research: 
- Models: 
- Historical strategies: 
