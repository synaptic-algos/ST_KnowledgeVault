---
artifact_type: story
created_at: '2025-11-25T16:23:21.861942Z'
id: AUTO-README
manual_update: 'true'
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: '001'
status: pending
title: Auto-generated title for README
updated_at: '2025-11-25T16:23:21.861945Z'
---

## Documentation Files

### 1. [00_OVERVIEW.md](00_OVERVIEW.md) - START HERE

**Read Time**: 20 minutes

**Topics Covered**:
- What is NautilusTrader and why use it
- Core Nautilus concepts (Actor, Strategy, Message Bus)
- Current architecture vs target architecture
- Migration path overview
- Component placement guidelines
- Benefits of full Nautilus integration

**Who Should Read**: Everyone working on the project

**Key Takeaway**: Understand the Nautilus framework and how it solves the "write once, run everywhere" problem.

---

### 2. [01_PAPER_TRADING_BEST_PRACTICES.md](01_PAPER_TRADING_BEST_PRACTICES.md)

**Read Time**: 30 minutes

**Topics Covered**:
- Nautilus TradingNode for paper trading
- Zerodha integration (WebSocket data streaming)
- Simulated execution (realistic order fills)
- Same strategy code as backtest (zero changes)
- Order simulation configuration
- Risk management in paper trading
- Monitoring and logging
- Migration from current paper trading system

**Who Should Read**: Developers working on paper trading

**Key Takeaway**: Same strategy and CapitalManager code works in paper trading with just a config change. Zerodha provides live data, Nautilus simulates execution.

**Code Examples**:
- ✅ ZerodhaDataClient implementation
- ✅ TradingNode configuration
- ✅ Run script
- ✅ WebSocket integration

---

### 3. [02_LIVE_TRADING_BEST_PRACTICES.md](02_LIVE_TRADING_BEST_PRACTICES.md)

**Read Time**: 40 minutes

**Topics Covered**:
- Pre-go-live checklist (validation requirements)
- Zerodha execution client (real order placement)
- Risk management and circuit breakers
- Order management (fills, rejections, cancellations)
- Monitoring and alerts (SMS/email)
- Error handling and recovery
- Gradual rollout strategy (10% → 50% → 100% capital)
- Production checklist (daily, weekly, monthly)

**Who Should Read**: Everyone (mandatory before live trading)

**Key Takeaway**: Live trading requires extensive validation, risk management, and monitoring. Gradual rollout is essential.

**Code Examples**:
- ✅ ZerodhaExecutionClient implementation
- ✅ Circuit breaker actor
- ✅ Position reconciliation
- ✅ Alert system
- ✅ Live trading configuration

---

### 4. [03_INSTRUMENT_REGISTRATION_OPTIMIZATION.md](03_INSTRUMENT_REGISTRATION_OPTIMIZATION.md)

**Read Time**: 25 minutes

**Topics Covered**:
- Current instrument registration bottleneck (17s for 33,408 instruments)
- Pre-built instrument index approach (100x speedup)
- Catalog-level metadata caching
- Lazy registration pattern
- Performance comparisons and trade-offs
- Implementation plan and example code
- When to rebuild indexes

**Who Should Read**: Developers working on backtesting performance

**Key Takeaway**: Pre-build a one-time instrument index to reduce backtest startup from 17 seconds to <1 second. Index maps instruments to date ranges for fast filtering.

**Code Examples**:
- ✅ Index builder script
- ✅ Fast index query in backtest runner
- ✅ Auto-rebuild on data import

---

### 5. [04_BACKTESTING_BEST_PRACTICES.md](04_BACKTESTING_BEST_PRACTICES.md)

**Read Time**: 30 minutes

**Topics Covered**:
- Nautilus BacktestEngine architecture
- Data loading (parquet → Nautilus catalog)
- Strategy implementation (inherit from Strategy class)
- CapitalManager as Nautilus Actor
- Configuration setup
- Running backtests
- Performance optimization
- Migration from current system

**Who Should Read**: Developers working on backtesting

**Key Takeaway**: How to convert current custom backtest system to Nautilus framework for cross-environment compatibility.

**Code Examples**:
- ✅ Complete CapitalManager as Nautilus Actor
- ✅ Strategy implementation example
- ✅ Backtest configuration
- ✅ Run script

---

### 6. [05_OPTIONS_BACKTESTING_BEST_PRACTICES.md](05_OPTIONS_BACKTESTING_BEST_PRACTICES.md)

**Read Time**: 20 minutes

**Topics Covered**:
- Options-specific backtesting challenges
- Instrument registration bottleneck solutions
- Research findings from Nautilus documentation
- Best practices for options strategies
- Recommended approaches
- Known limitations
- Future improvements

**Who Should Read**: Developers working on options backtesting

**Key Takeaway**: Options backtesting requires special handling due to large instrument universes. Use lazy loading and pre-filtering strategies.

---

### 7. [06_DYNAMIC_INSTRUMENT_REGISTRATION_INVESTIGATION.md](06_DYNAMIC_INSTRUMENT_REGISTRATION_INVESTIGATION.md)

**Read Time**: 45 minutes

**Topics Covered**:
- Deep investigation into dynamic instrument registration feasibility
- Why on-demand registration doesn't work in Nautilus
- Technical and architectural barriers (lifecycle states, data loading, matching engines)
- Comprehensive analysis of 6 potential workarounds
- Detailed pros/cons for each approach
- Implementation examples and performance metrics
- Production recommendations

**Who Should Read**: Developers seeking to understand registration bottleneck deeply, architects considering alternatives

**Key Takeaway**: Dynamic registration during backtest execution is NOT supported by Nautilus architecture. Root causes: lifecycle constraints, event-driven replay model, catalog API design, and Rust core optimizations. Best solution: Adaptive pre-filtering with generous buffer (95%+ reduction, 2-7 min registration).

**Code Examples**:
- ✅ Adaptive pre-filtering implementation
- ✅ Two-pass discovery backtest pattern
- ✅ Batch parallel backtesting
- ✅ Performance comparisons for each workaround

---

### 8. [07_INSTRUMENT_PRE_COMPUTATION_PATTERN.md](07_INSTRUMENT_PRE_COMPUTATION_PATTERN.md) ⭐ RECOMMENDED

**Read Time**: 50 minutes

**Topics Covered**:
- Pre-computation pattern for determining exact instruments before backtest
- Industry best practices research (options platforms, universe selection, walk-forward)
- Why this works with Nautilus architecture constraints
- Complete implementation guide with code examples
- Comparison: pre-computation vs generous buffer filtering
- Advanced techniques (direction proxies, delta approximation, intelligent buffering)
- Production gotchas and edge cases (logic divergence, expiry misalignment, regime changes)
- Validation and caching strategies

**Who Should Read**: **Everyone working on options backtesting** - This is the optimal approach for deterministic strategies

**Key Takeaway**: Pre-compute exact instruments by simulating strike selection on lightweight spot data (20-40 instruments, <1 min setup, 99.9% accuracy) vs generous buffer (500-1,500 instruments, 2-7 min). Best production approach: Pre-comp + 20% buffer for safety.

**Code Examples**:
- ✅ Complete `InstrumentPreComputer` service
- ✅ Shared strike/expiry calculation utilities
- ✅ Integration with backtest runner
- ✅ Delta approximation algorithms
- ✅ Intelligent buffering strategies
- ✅ Validation and caching patterns

**Research Sources**:
- Nautilus GitHub discussions on large universes
- Options platforms (AlgoTest, OptionOmega, ORATS)
- Walk-forward optimization methodology
- Universe selection bias mitigation

---

### 9. [08_LONG_RUNNING_BACKTEST_SERVER.md](08_LONG_RUNNING_BACKTEST_SERVER.md) 🚀 PRODUCTION-READY

**Read Time**: 60 minutes

**Topics Covered**:
- Production-grade long-running backtest server architecture
- Hot-reload capabilities (incremental instrument/data loading)
- Complete Flask REST API implementation with health checks
- Thread-safe concurrent request handling
- Production deployment (systemd, Docker, Kubernetes)
- Monitoring with Prometheus/Grafana
- Security (authentication, rate limiting, input validation)
- Memory management and performance optimization
- Graceful shutdown and troubleshooting

**Who Should Read**: **DevOps, backend developers, and teams building backtest infrastructure**

**Key Takeaway**: Long-running server eliminates 5-min registration overhead by keeping engine alive. Hot-reload adds new instruments in 2.5 min (vs 8 min restart). Perfect for parameter sweeps (2.6x faster), multi-user teams, and web UI integration.

**Code Examples**:
- ✅ Complete Flask server implementation (1000+ lines)
- ✅ EngineManager with hot-reload support
- ✅ Health checks (liveness/readiness probes)
- ✅ Prometheus metrics collector
- ✅ systemd/Docker/Kubernetes deployment configs
- ✅ Graceful shutdown handlers
- ✅ Security (API keys, rate limiting)

**Research Sources**:
- Flask vs FastAPI for compute-intensive workloads (2025)
- Python state management best practices
- systemd production deployment patterns
- Kubernetes health check patterns
- Graceful shutdown implementations

**Performance Impact**:
- First backtest: 8 min (same)
- Subsequent: 3 min vs 8 min (2.7x faster)
- 100-run sweep: 5 hrs vs 13.3 hrs (2.6x faster)
- Add new expiry: 2.5 min vs 8 min (3.2x faster)

---

### 10. [09_BACKTEST_OPTIMIZATION_NAUTILUS_ALIGNMENT.md](09_BACKTEST_OPTIMIZATION_NAUTILUS_ALIGNMENT.md) 🎯 SPRINT PLANNING

**Read Time**: 70 minutes

**Topics Covered**:
- Deep investigation of 7 proposed backtest optimizations
- Nautilus architecture alignment analysis for each optimization
- Which optimizations are fully Nautilus-compliant (✅)
- Which require Nautilus-specific implementation patterns (⚠️)
- Which fundamentally conflict with Nautilus architecture (❌)
- Detailed implementation guidance for Nautilus-aligned approaches
- Alternative approaches for non-Nautilus optimizations
- Sprint-by-sprint implementation roadmap

**Who Should Read**: **Everyone involved in sprint planning, optimization work, and architecture decisions**

**Key Takeaway**: 5 out of 7 proposed optimizations are fully Nautilus-aligned. The 2 that conflict (vectorized execution, timeline parallelization) should be implemented as separate tools for parameter optimization, not as replacements for Nautilus backtesting.

**Optimization Analysis**:
1. ✅ **Catalog-Level Filtering** (Fully aligned) - 20-25s gain
2. ✅ **Disable Hot Path Logging** (Fully aligned) - 50-100s gain
3. ✅ **Incremental RSI** (Fully aligned) - 300-500s gain
4. ⚠️ **Entry Caching** (Compatible with caveats) - 200-400s gain
5. ✅ **Consolidated Catalog** (Aligned via custom adapter) - 200-230s gain
6. ❌ **Vectorized Backtest** (Conflicts - separate tool) - 2,000-2,500s gain
7. ❌ **Parallel Execution** (Difficult - parameter-level only) - 4x speedup

**Code Examples**:
- ✅ Nautilus-aligned catalog filtering
- ✅ Custom Indicator implementation (IncrementalRSI)
- ✅ Deterministic caching patterns
- ✅ Custom DataCatalog implementation (ConsolidatedParquetCatalog)
- ⚠️ FastBacktest as separate tool (not integrated with Nautilus)
- ✅ Parameter-level parallelism workflow

**Sprint Roadmap**:
- Sprint 29: Quick wins (catalog filtering, logging, incremental RSI, caching)
- Sprint 30: Consolidated catalog (custom DataCatalog implementation)
- Sprint 31+: Separate optimization tools (FastBacktest, parameter parallelism)

**Key Principles Documented**:
- Event-driven architecture compliance
- Pre-registration of instruments
- Data catalog abstraction
- Actor pattern for cross-environment logic
- Immutable data replay

---

## Quick Start Guide

### For New Developers

**Day 1**: Read `00_OVERVIEW.md` to understand Nautilus architecture and benefits.

**Day 2-3**: Read `04_BACKTESTING_BEST_PRACTICES.md` and implement CapitalManager as Nautilus Actor.

**Week 2**: Read `01_PAPER_TRADING_BEST_PRACTICES.md` and set up ZerodhaDataClient.

**Month 2+**: Read `02_LIVE_TRADING_BEST_PRACTICES.md` after paper trading validation.

---

### For Existing Developers

**Priority 1 (THIS WEEK)**: Implement CapitalManager as Nautilus Actor
- **File**: `src/strategy/actors/capital_manager.py`
- **Reference**: `04_BACKTESTING_BEST_PRACTICES.md` → "CapitalManager as Nautilus Actor"
- **Why**: This fixes the architectural issue identified in `/tmp/capital_management_implementation_plan.md`

**Priority 2 (NEXT WEEK)**: Convert strategy to Nautilus Strategy class
- **File**: `src/strategy/options_spread_strategy.py`
- **Reference**: `04_BACKTESTING_BEST_PRACTICES.md` → "Strategy Implementation"
- **Why**: Enables cross-environment compatibility

**Priority 3 (MONTH 1)**: Load data into Nautilus catalog
- **Script**: `src/backtest/load_catalog.py`
- **Reference**: `04_BACKTESTING_BEST_PRACTICES.md` → "Data Loading"
- **Why**: Framework-managed data delivery

**Priority 4 (MONTH 2)**: Create ZerodhaDataClient for paper trading
- **File**: `src/adapters/zerodha_data_client.py`
- **Reference**: `01_PAPER_TRADING_BEST_PRACTICES.md` → "Zerodha Integration"
- **Why**: Live data streaming for paper trading

---

## Key Architectural Decisions

### Decision 1: CapitalManager Should Be a Nautilus Actor

**Problem**: Proposed CapitalManager in `/tmp/capital_management_implementation_plan.md` uses custom pattern, won't work in paper/live trading.

**Solution**: Implement as Nautilus Actor (see `04_BACKTESTING_BEST_PRACTICES.md`).

**Location**: `src/strategy/actors/capital_manager.py`

**Rationale**: Actors work identically in backtest, paper, and live environments.

---

### Decision 2: Strategy Should Inherit from Nautilus Strategy

**Problem**: Current strategy uses custom class with manual data polling.

**Solution**: Inherit from `nautilus_trader.trading.strategy.Strategy`.

**Location**: `src/strategy/options_spread_strategy.py`

**Rationale**: Event-driven architecture, framework-managed data delivery, cross-environment compatibility.

---

### Decision 3: Keep EntryManager and ExitManager as Helper Classes

**Problem**: Do these need to be Nautilus components?

**Solution**: No, keep as plain Python helper classes (used by Strategy).

**Location**: `src/strategy/components/entry_manager.py`, `exit_manager.py`

**Rationale**: These are strategy-specific logic, not standalone components that need cross-environment support.

---

### Decision 4: Use Nautilus Data Catalog for Backtesting

**Problem**: Current custom parquet adapter reads data manually.

**Solution**: Load data into Nautilus catalog, use `BacktestDataConfig`.

**Location**: `data/nautilus_catalog/` (one-time conversion)

**Rationale**: Framework-managed data loading, faster, consistent with live data delivery.

---

### Decision 5: Gradual Migration Path

**Problem**: Full rewrite too risky, need incremental approach.

**Solution**: Phase-by-phase migration (see each best practices document).

**Phases**:
1. CapitalManager as Actor (immediate value)
2. Strategy conversion (moderate effort)
3. Data catalog loading (one-time setup)
4. Paper trading integration (Zerodha client)
5. Live trading (after extensive validation)

**Rationale**: De-risk migration, validate at each step, maintain current system during transition.

---

## Benefits Summary

### Code Reuse

| Component | Backtest | Paper | Live | Code Duplication |
|-----------|----------|-------|------|------------------|
| **Current System** | Custom | Separate | TBD | 3x code |
| **Nautilus System** | ✅ Same | ✅ Same | ✅ Same | 1x code (zero duplication) |

---

### Feature Coverage

| Feature | Current System | Nautilus System |
|---------|---------------|-----------------|
| **Backtesting** | ✅ Working | ✅ Working (after migration) |
| **Paper Trading** | ✅ Working | ✅ Working (after migration) |
| **Live Trading** | ❌ Not implemented | ✅ Included (same code) |
| **Capital Management** | ❌ Planned (backtest only) | ✅ Works everywhere |
| **Order Management** | Custom (limited) | Built-in (robust) |
| **Risk Management** | Custom | Built-in RiskEngine |
| **Position Tracking** | Custom | Built-in Portfolio |
| **Event Handling** | Manual | Message bus (automatic) |

---

### Performance

| Metric | Current System | Nautilus System |
|--------|----------------|-----------------|
| **Data Load** | 4-6s (pickle cache) | 2-3s (catalog) |
| **Backtest Execution** | ~17s | ~10-15s (Rust core) |
| **Order Execution** | N/A (backtest only) | Realistic (paper/live) |

---

## Implementation Checklist

### Phase 1: CapitalManager as Actor ⚡ HIGH PRIORITY

**Files to Create**:
- [ ] `src/strategy/actors/capital_manager.py` - Nautilus Actor implementation
- [ ] `src/strategy/actors/__init__.py` - Module init

**Files to Modify**:
- [ ] `config/backtest_config.py` - Add CapitalManager to actors list
- [ ] `src/strategy/options_spread_strategy_modular.py` - Access capital manager via framework

**Testing**:
- [ ] Unit test: capital updates after trades
- [ ] Unit test: lot size calculation
- [ ] Integration test: backtest with capital management
- [ ] Validation: compare with current system

**Effort**: 4-8 hours

---

### Phase 2: Strategy Conversion

**Files to Create**:
- [ ] `src/strategy/options_spread_strategy.py` - Nautilus Strategy subclass

**Files to Modify**:
- [ ] `src/strategy/components/entry_manager.py` - Work with Nautilus events
- [ ] `src/strategy/components/exit_manager.py` - Work with Nautilus events
- [ ] `config/backtest_config.py` - Use new strategy

**Testing**:
- [ ] Unit test: on_bar() method
- [ ] Unit test: order submission
- [ ] Integration test: full backtest
- [ ] Validation: results match current system

**Effort**: 8-12 hours

---

### Phase 3: Data Catalog Loading

**Files to Create**:
- [ ] `src/backtest/load_catalog.py` - Conversion script

**One-Time Execution**:
- [ ] Run conversion: parquet → Nautilus catalog
- [ ] Verify data loaded correctly
- [ ] Update backtest config to use catalog

**Testing**:
- [ ] Data load speed (<3s)
- [ ] Data accuracy (spot-check prices)
- [ ] Backtest results match current system

**Effort**: 4-6 hours

---

### Phase 4: Paper Trading Integration

**Files to Create**:
- [ ] `src/adapters/zerodha_data_client.py` - WebSocket integration
- [ ] `config/paper_trading_config.py` - TradingNode config
- [ ] `src/papertrade/run_nautilus_paper_trading.py` - Entry point

**Files to Modify**:
- [ ] `config/zerodha_config.py` - Credentials loading

**Testing**:
- [ ] WebSocket connection
- [ ] Live data streaming
- [ ] Order simulation
- [ ] Compare with current paper trading

**Effort**: 12-20 hours

---

### Phase 5: Live Trading (Future)

**Files to Create**:
- [ ] `src/adapters/zerodha_execution_client.py` - Real order execution
- [ ] `src/strategy/risk/circuit_breakers.py` - Safety mechanisms
- [ ] `src/strategy/risk/position_reconciler.py` - Position validation
- [ ] `config/live_trading_config.py` - Production config

**Testing**:
- [ ] 2+ weeks paper trading validation
- [ ] 1 week live with 10% capital
- [ ] 2 weeks live with 50% capital
- [ ] Full deployment with 100% capital

**Effort**: 20-30 hours + extensive validation

---

## FAQ

### Q: Do we need to rewrite everything?

**A**: No. Gradual migration:
1. Start with CapitalManager as Actor (works immediately)
2. Keep existing strategy logic, just wrap in Nautilus Strategy class
3. Keep EntryManager and ExitManager as-is (helper classes)
4. Gradually move to event-driven patterns

---

### Q: What about our existing backtest results?

**A**: Compatible. Nautilus produces similar output:
- Trade log (CSV)
- Daily P&L
- Performance statistics
- Can keep existing analysis scripts

---

### Q: How does CapitalManager work across environments?

**A**: Via Nautilus Actor pattern:
- Same code in `src/strategy/actors/capital_manager.py`
- BacktestEngine loads it: `engine.add_actor(CapitalManager(config))`
- TradingNode loads it: `node.add_actor(CapitalManager(config))`
- Subscribes to position events (works everywhere)

---

### Q: What if we want to keep the current system running during migration?

**A**: Parallel operation:
- Current system: `src/backtest/run_backtest.py` (unchanged)
- Nautilus system: `src/backtest/run_nautilus_backtest.py` (new)
- Run both, compare results
- Cutover when validated

---

### Q: How long will migration take?

**A**: Estimated timeline:
- Phase 1 (CapitalManager): 1 week
- Phase 2 (Strategy conversion): 1-2 weeks
- Phase 3 (Data catalog): 1 week
- Phase 4 (Paper trading): 2-3 weeks
- Phase 5 (Live trading): 1-2 months (with validation)

**Total**: 2-3 months for full migration with extensive testing.

---

## Next Steps

### Immediate Actions (This Week)

1. **Read** `00_OVERVIEW.md` to understand Nautilus architecture
2. **Read** `01_BACKTESTING_BEST_PRACTICES.md` for CapitalManager implementation
3. **Implement** CapitalManager as Nautilus Actor in `src/strategy/actors/capital_manager.py`
4. **Test** with simple backtest to validate capital tracking

### Short-Term (Next 2 Weeks)

1. Convert strategy to Nautilus Strategy class
2. Test with existing backtest data
3. Compare results with current system
4. Document any differences

### Medium-Term (Next Month)

1. Load data into Nautilus catalog
2. Create ZerodhaDataClient for paper trading
3. Run paper trading in parallel with current system
4. Validate results

### Long-Term (Next 2-3 Months)

1. Extensive paper trading validation (2+ weeks)
2. Create ZerodhaExecutionClient for live trading
3. Gradual live rollout (10% → 50% → 100%)
4. Full production deployment

---

## Support & Questions

### Documentation Issues

If you find errors or need clarification:
1. Open issue in repository
2. Tag with `documentation` label
3. Reference specific document and section

### Implementation Questions

If you have questions during implementation:
1. Refer to official Nautilus documentation: https://nautilustrader.io/docs/latest/
2. Check code examples in best practices documents
3. Review current codebase patterns

### Architecture Decisions

If you're unsure about architectural choices:
1. Refer to `00_OVERVIEW.md` → "Component Placement Guidelines"
2. Follow the "write once, run everywhere" principle
3. When in doubt, prefer Nautilus native objects over custom implementations

---

## References

**Internal Documentation**:
- `/tmp/capital_management_implementation_plan.md` - Original capital management plan
- `/tmp/trade1_calculation_analysis.md` - Trade calculations and bugs identified
- `documentation/prd/strategy/CORE_STRATEGY_PRD.md` - Strategy specification (v3.0.0)

**External Documentation**:
- Nautilus Trader: https://nautilustrader.io/docs/latest/
- Nautilus Backtesting: https://nautilustrader.io/docs/latest/getting_started/backtesting
- Nautilus Live Trading: https://nautilustrader.io/docs/latest/getting_started/live_trading
- Zerodha Kite API: https://kite.trade/docs/connect/v3/

---

## Document History

| Date | Version | Changes |
|------|---------|---------|
| 2025-10-13 | 1.0.0 | Initial documentation created |
| | | - 00_OVERVIEW.md: Architecture overview |
| | | - 01_PAPER_TRADING_BEST_PRACTICES.md: Paper trading guide |
| | | - 02_LIVE_TRADING_BEST_PRACTICES.md: Live trading guide |
| 2025-10-16 | 1.1.0 | Added optimization guides |
| | | - 03_INSTRUMENT_REGISTRATION_OPTIMIZATION.md: Performance optimization |
| | | - 04_BACKTESTING_BEST_PRACTICES.md: Backtest integration guide |
| 2025-10-20 | 1.2.0 | Added options-specific guidance |
| | | - 05_OPTIONS_BACKTESTING_BEST_PRACTICES.md: Options backtesting |
| | | - Renumbered files by creation date |
| | | - Added datetime stamps to all metadata |
| | | - README.md: Documentation index |
| 2024-10-20 | 1.3.0 | Deep investigation into dynamic registration |
| | | - 06_DYNAMIC_INSTRUMENT_REGISTRATION_INVESTIGATION.md: Dynamic registration feasibility |
| | | - 6 workarounds analyzed with pros/cons |
| | | - Production recommendations |
| | | - Updated 05 with streaming section and OptionSpread warnings |
| 2024-10-20 | 1.4.0 | Pre-computation pattern documentation (⭐ RECOMMENDED) |
| | | - 07_INSTRUMENT_PRE_COMPUTATION_PATTERN.md: Optimal pattern for deterministic strategies |
| | | - Deep research: Industry best practices, options platforms, universe selection |
| | | - Complete implementation guide with code examples |
| | | - Advanced techniques: Delta approximation, intelligent buffering |
| | | - Production gotchas: Logic divergence, expiry misalignment, regime changes |
| | | - Performance: 20-40 instruments, <1 min setup, 99.9% accuracy |
| 2024-10-20 | 1.5.0 | Backtest optimization Nautilus alignment analysis (🎯 SPRINT PLANNING) |
| | | - 09_BACKTEST_OPTIMIZATION_NAUTILUS_ALIGNMENT.md: Deep investigation of 7 optimizations |
| | | - Nautilus architecture compliance analysis (✅ ⚠️ ❌) |
| | | - Implementation guidance for Nautilus-aligned optimizations |
| | | - Alternative approaches for non-Nautilus optimizations |
| | | - Sprint-by-sprint roadmap (Sprint 29 → Sprint 31+) |
| | | - 5/7 optimizations fully Nautilus-aligned |

---

**Status**: ✅ Documentation Complete

All Nautilus best practices documented. Ready for implementation.
