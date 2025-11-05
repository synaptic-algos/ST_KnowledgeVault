---
id: STRAT-001-OptionsWeeklyMonthlyHedge
version: 0.1.0
owner: strategy_ops_team
asset_class: options
status: research
last_review: 2025-11-04
change_log:
  - 2025-11-04 – strategy_ops_team – Imported strategy PRD and metadata
---

# Options Weekly Monthly Hedge

## 1. Metadata
- **Strategy ID**: STRAT-001
- **Owner / PM**: TBD
- **Engineering Lead**: TBD
- **Risk Officer**: TBD
- **Lifecycle State**: Research
- **Target Deployment**: Paper → Live

## 2. Hypothesis & Objectives
- Hedge portfolio drawdowns using weekly and monthly options while generating carry income.
- Primary KPIs: Net PnL, IV edge, delta/gamma exposure, maximum drawdown, hedge effectiveness.

## 3. Strategy Structure
- Mix of protective puts and covered call spreads on core equity holdings.
- Weekly adjustments roll short legs; monthly core hedge maintained.

## 4. Data & Models
- Option chains from NSE/US brokers, IV surfaces, underlying equity bars.
- Greeks computed via Black-Scholes; evaluate alternative models for skew.

## 5. Signals & Execution
- Entries triggered by volatility bands and exposure gaps.
- Exits based on theta decay targets, loss thresholds, and event windows.
- Orders routed via Nautilus adapter with smart execution for multi-leg orders.

## 6. Greeks & Hedging
- Target delta neutrality within ±0.1 per portfolio; gamma limits 0.5.
- Hedge with underlying futures when delta drift exceeds thresholds.

## 7. Risk Controls
- Margin utilisation cap 60% of available capital.
- Stop loss on net premium loss of 3% of capital per week.
- Regulatory compliance: track short option positions and margin requirements.

## 8. Capital & Operations
- Capital bucket TBD; initial assumption 10% of book with scalable tiers.
- Weekly rebalance with monthly review.

## 9. Backtest & Validation Plan
- Reconstruct 3+ years of options chain data; simulate weekly adjustments.
- Stress scenarios: volatility spikes, gap moves, holiday weeks.

## 10. Deployment & Monitoring
- Telemetry: PnL, delta/gamma/theta, margin usage, fill stats.
- Alerts for delta drift, margin >70%, IV spike > 2 standard deviations.
- Runbook to unwind positions on major market events.

## 11. Dependencies
- Vol surface service, futures data, margin calculators, risk engine.

## 12. Checklist
- [ ] Template fully populated
- [ ] Risk review scheduled
- [ ] Strategy catalogue entry updated
- [ ] Implementation stories linked in EPIC-008

## 13. Version History
| Version | Date | Notes |
|---------|------|-------|
| 0.1.0 | 2025-11-04 | Template scaffolded for research handoff |

## 14. References
- [PRD](./PRD.md)
- Lifecyle Epic: [[EPICS/EPIC-007-StrategyLifecycle/README|EPIC-007]]
- Enablement Epic: [[EPICS/EPIC-008-StrategyEnablement/README|EPIC-008]]
