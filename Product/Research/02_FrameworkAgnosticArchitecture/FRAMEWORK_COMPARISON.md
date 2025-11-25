---
artifact_type: story
created_at: '2025-11-25T16:23:21.852683Z'
id: AUTO-FRAMEWORK_COMPARISON
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for FRAMEWORK_COMPARISON
updated_at: '2025-11-25T16:23:21.852687Z'
---

# Framework Comparison

| Framework | Language | Strengths | Gaps vs Requirements | Notes |
|-----------|----------|-----------|----------------------|-------|
| Nautilus Trader | Python/C++ | Institutional-grade event engine, deterministic backtesting, robust risk controls | Limited community adapters, deployment tooling still evolving | Preferred primary target for live trading |
| Backtrader | Python | Mature ecosystem, simple strategy API | Single-threaded core, limited order types, weaker risk hooks | Suitable for quick prototyping and education |
| Zipline | Python | Historical backtesting heritage, rich analytics | Project unmaintained, lacks live trading support | Archive only; do not invest further |
| Hummingbot | Python | Market-making focus, exchange connectors | Strategy model differs from discretionary flow, heavier devops | Consider for market-making adapters only |
| Custom Engine | Python/Rust | Tailored to latency and compliance needs | Requires significant investment to match existing features | Evaluate after foundation and adapter work complete |

## Evaluation Criteria
1. **Adapter Feasibility**: Ability to wrap engine APIs with port interfaces.
2. **Deterministic Replay**: Replay accuracy in backtests and paper trading.
3. **Risk Control Hooks**: Pre/post trade checks, kill-switch compatibility.
4. **Operational Tooling**: Deployment automation, observability, alerting.

## Recommendations
- Start with **Nautilus Trader** for production-grade adapters.
- Maintain **Backtrader** adapter for education and validation.
- Park investments in Zipline/Hummingbot unless strategy mandates.
- Keep the custom engine exploration as a separate R&D track after EPIC-004.
