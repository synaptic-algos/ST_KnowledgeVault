# Synaptic Trading Platform - Release Plan v2.0

**Document Version**: 2.0
**Created**: 2025-11-20
**Last Updated**: 2025-11-20
**Owner**: Product Operations Team
**Status**: 🟢 Active

---

## Executive Summary

**Key Change**: Multi-framework support for backtesting, paper trading, and live trading. Users can choose between Custom, Nautilus, or Backtrader engines for all trading modes.

**Rationale**:
- Framework-agnostic architecture enables user choice and ecosystem leverage
- EPIC-005 (Framework Adapters) establishes integration patterns used across all EPICs
- Nautilus and Backtrader provide mature market data and execution ecosystems

**Impact**: EPIC-002 is **NOT complete** - only custom engine delivered. Nautilus and Backtrader backtesting pending EPIC-005.

---

## Revised EPIC Sequencing

### Previous Plan (v1.0)
```
EPIC-001 → EPIC-002 ✅ → EPIC-003 → EPIC-004 → EPIC-005
```

### New Plan (v2.0)
```
EPIC-001 → EPIC-002 (Phase 1: Custom) ✅ → EPIC-005 → EPIC-002 (Phase 2: Nautilus/Backtrader) → EPIC-003 → EPIC-004
```

### Why This Order?

1. **EPIC-002 Phase 1** (DONE ✅): Custom backtesting validates architecture
2. **EPIC-005**: Establishes Nautilus and Backtrader integration patterns
3. **EPIC-002 Phase 2**: Completes backtesting with all 3 engine options
4. **EPIC-003**: Paper trading inherits all 3 engine options from start
5. **EPIC-004**: Live trading inherits all 3 engine options from start

**Key Insight**: EPIC-005 is foundational work that **feeds into** EPIC-002, EPIC-003, and EPIC-004.

---

## Phase Breakdown

### Phase 1: Foundation & Custom Backtesting ✅ COMPLETE
**Duration**: Nov 2025 - Jan 2026
**Status**: ✅ Complete

| EPIC | Status | Progress | Deliverable |
|------|--------|----------|-------------|
| EPIC-001 | ✅ Complete | 100% | Port interfaces, domain layer |
| EPIC-002 (Phase 1) | ✅ Complete | 50% | Custom backtesting engine |

**Delivered**:
- ✅ Custom BacktestAdapter with full functionality
- ✅ 12/12 integration tests passing
- ✅ Advanced analytics (Sharpe, Sortino, max drawdown, win rate, profit factor)
- ✅ Comprehensive documentation (2,200+ lines)

**What's Missing**:
- ❌ Nautilus backtesting option
- ❌ Backtrader backtesting option

---

### Phase 2: Framework Integration (NEXT)
**Duration**: 4 weeks
**Status**: 📋 Planned
**Priority**: P0 (Blocks EPIC-002 completion)

| EPIC | Feature | Duration | Dependencies |
|------|---------|----------|--------------|
| EPIC-005 | Framework Adapters | 4w | EPIC-001, EPIC-002 Phase 1 |

#### EPIC-005: Framework Adapters

**Goal**: Establish integration patterns for Nautilus and Backtrader frameworks.

**Features**:

| Feature | Description | Est. Days | Priority |
|---------|-------------|-----------|----------|
| FEAT-005-01 | Nautilus Integration Core | 5 | P0 |
| FEAT-005-02 | Backtrader Integration Core | 4 | P0 |
| FEAT-005-03 | Framework Selection Interface | 2 | P0 |
| FEAT-005-04 | Cross-Framework Validation | 3 | P0 |

**Total**: 4 Features, ~14 days

**Deliverables**:
1. **Nautilus Integration Library** (`adapters/frameworks/nautilus/`)
   - Strategy wrapper (domain Strategy → Nautilus Strategy)
   - Port adapters (ClockPort, MarketDataPort, ExecutionPort)
   - Event translation layer
   - Configuration mapping

2. **Backtrader Integration Library** (`adapters/frameworks/backtrader/`)
   - Strategy wrapper (domain Strategy → Backtrader Strategy)
   - Port adapters
   - Event translation layer
   - Configuration mapping

3. **Framework Selection API**
   ```python
   from adapters.frameworks import create_backtest_adapter

   adapter = create_backtest_adapter(
       engine="nautilus",  # or "custom", "backtrader"
       config=config,
       data_provider=provider
   )
   ```

4. **Cross-Framework Tests**
   - Same strategy on all 3 engines
   - PnL divergence < 0.01%
   - Performance comparison

**Success Criteria**:
- [ ] SimpleBuyAndHoldStrategy runs on Nautilus
- [ ] SimpleBuyAndHoldStrategy runs on Backtrader
- [ ] Results match custom engine (±0.01% PnL)
- [ ] Documentation for framework integration
- [ ] Framework selection interface works

---

### Phase 3: Complete Backtesting (EPIC-002 Phase 2)
**Duration**: 2 weeks
**Status**: 📋 Planned
**Priority**: P0

| EPIC | Feature | Duration | Dependencies |
|------|---------|----------|--------------|
| EPIC-002 (Phase 2) | Nautilus & Backtrader Backtesting | 2w | EPIC-005 |

#### EPIC-002 Phase 2: Multi-Framework Backtesting

**Goal**: Complete EPIC-002 by adding Nautilus and Backtrader backtesting options.

**New Features** (to be added):

| Feature | Description | Est. Days | Status |
|---------|-------------|-----------|--------|
| FEATURE-007 | Nautilus Backtest Adapter | 3 | 📋 Planned |
| FEATURE-008 | Backtrader Backtest Adapter | 3 | 📋 Planned |
| FEATURE-009 | Multi-Engine Documentation | 2 | 📋 Planned |

**Feature 007: Nautilus Backtest Adapter**

Leverage EPIC-005 Nautilus integration to create NautilusBacktestAdapter:
- Wraps Nautilus backtesting engine
- Implements BacktestAdapter interface
- Returns BacktestResults (same format as custom)
- Supports all EPIC-002 features (slippage, commission, analytics)

**Feature 008: Backtrader Backtest Adapter**

Leverage EPIC-005 Backtrader integration to create BacktraderBacktestAdapter:
- Wraps Backtrader backtesting engine
- Implements BacktestAdapter interface
- Returns BacktestResults (same format as custom)
- Supports all EPIC-002 features

**Feature 009: Multi-Engine Documentation**

Update documentation to show all 3 engines:
- How to choose engine
- Engine comparison (features, performance)
- Migration guide (custom → Nautilus → Backtrader)
- Troubleshooting per engine

**Updated EPIC-002 Success Criteria**:
- [x] Backtest 1 year of daily data in <2 minutes (custom ✅)
- [x] P&L calculations accurate within 0.01% (custom ✅)
- [x] Deterministic replay (custom ✅)
- [x] Fill simulation realistic (custom ✅)
- [x] Performance metrics generated (custom ✅)
- [ ] **Nautilus backtesting option available** (Phase 2)
- [ ] **Backtrader backtesting option available** (Phase 2)
- [ ] **User can choose engine at runtime** (Phase 2)
- [ ] **Cross-engine validation passing** (Phase 2)

**EPIC-002 Completion**: When Phase 2 features delivered.

---

### Phase 4: Paper Trading (EPIC-003)
**Duration**: 3 weeks
**Status**: 📋 Planned
**Priority**: P0

**Dependencies**: EPIC-002 Phase 2 (all 3 backtest engines working)

**Approach**: Build on EPIC-005 integration work.

**Features**:

| Feature | Description | Engines Supported |
|---------|-------------|-------------------|
| FEAT-003-01 | Custom Paper Trading | Custom |
| FEAT-003-02 | Nautilus Paper Trading | Nautilus (reuse EPIC-005) |
| FEAT-003-03 | Backtrader Paper Trading | Backtrader (reuse EPIC-005) |
| FEAT-003-04 | Paper Trading Validation | All 3 |

**User Experience**:
```python
from adapters.frameworks import create_paper_trading_adapter

adapter = create_paper_trading_adapter(
    engine="nautilus",  # or "custom", "backtrader"
    config=config,
    live_data_feed=feed
)
```

---

### Phase 5: Live Trading (EPIC-004)
**Duration**: 4 weeks
**Status**: 📋 Planned
**Priority**: P0

**Dependencies**: EPIC-003 (paper trading validated)

**Approach**: Same multi-framework pattern as backtest and paper trading.

**Features**:

| Feature | Description | Engines Supported |
|---------|-------------|-------------------|
| FEAT-004-01 | Custom Live Trading | Custom |
| FEAT-004-02 | Nautilus Live Trading | Nautilus (reuse EPIC-005) |
| FEAT-004-03 | Backtrader Live Trading | Backtrader (reuse EPIC-005) |
| FEAT-004-04 | Risk Management (all engines) | All 3 |
| FEAT-004-05 | Kill Switch (all engines) | All 3 |
| FEAT-004-06 | Monitoring & Alerting | All 3 |
| FEAT-004-07 | Production Validation | All 3 |

---

## Architecture: Multi-Framework Support

### File Structure

```
src/adapters/frameworks/
├── __init__.py                    # Framework selection API
├── base/                          # Base adapter interfaces
│   ├── backtest_adapter.py
│   ├── paper_trading_adapter.py
│   └── live_trading_adapter.py
│
├── custom/                        # Custom implementations (EPIC-002 Phase 1)
│   ├── backtest/                  # ✅ DONE
│   ├── paper/                     # EPIC-003
│   └── live/                      # EPIC-004
│
├── nautilus/                      # EPIC-005 + EPIC-002 Phase 2
│   ├── core/                      # EPIC-005 integration core
│   ├── backtest/                  # EPIC-002 Phase 2
│   ├── paper/                     # EPIC-003
│   └── live/                      # EPIC-004
│
└── backtrader/                    # EPIC-005 + EPIC-002 Phase 2
    ├── core/                      # EPIC-005 integration core
    ├── backtest/                  # EPIC-002 Phase 2
    ├── paper/                     # EPIC-003
    └── live/                      # EPIC-004
```

### Integration Pattern (EPIC-005)

**EPIC-005 Core Deliverables** (reused across backtest/paper/live):

```python
# adapters/frameworks/nautilus/core/
├── strategy_wrapper.py       # Domain Strategy → Nautilus Strategy
├── port_adapters.py          # ClockPort, MarketDataPort, ExecutionPort
├── event_translator.py       # Domain events ↔ Nautilus events
└── config_mapper.py          # BacktestConfig → Nautilus config

# adapters/frameworks/backtrader/core/
├── strategy_wrapper.py       # Domain Strategy → Backtrader Strategy
├── port_adapters.py          # ClockPort, MarketDataPort, ExecutionPort
├── event_translator.py       # Domain events ↔ Backtrader events
└── config_mapper.py          # BacktestConfig → Backtrader config
```

**Then Each Mode Reuses Core** (EPIC-002 Phase 2, EPIC-003, EPIC-004):

```python
# adapters/frameworks/nautilus/backtest/
from ..core import StrategyWrapper, PortAdapters, EventTranslator

class NautilusBacktestAdapter(BacktestAdapter):
    """Wraps Nautilus backtesting using core integration."""
    def __init__(self, config, data_provider):
        self.wrapper = StrategyWrapper()
        self.ports = PortAdapters()
        # Use Nautilus BacktestEngine...
```

---

## Timeline & Milestones

### Updated Timeline

| Phase | EPIC | Duration | Start | End | Status |
|-------|------|----------|-------|-----|--------|
| 1 | EPIC-001 | 4w | Nov 2025 | Dec 2025 | ✅ Complete |
| 1 | EPIC-002 Phase 1 (Custom) | 6w | Dec 2025 | Jan 2026 | ✅ Complete |
| 2 | **EPIC-005 (Framework Adapters)** | 4w | **Jan 2026** | **Feb 2026** | 📋 Next |
| 3 | **EPIC-002 Phase 2 (Nautilus/Backtrader)** | 2w | Feb 2026 | Feb 2026 | 📋 Planned |
| 4 | EPIC-003 (Paper Trading) | 3w | Feb 2026 | Mar 2026 | 📋 Planned |
| 5 | EPIC-004 (Live Trading) | 4w | Mar 2026 | Apr 2026 | 📋 Planned |
| 6 | EPIC-006 (Hardening) | 2w | Apr 2026 | May 2026 | 📋 Planned |

**Total**: ~21 weeks to production-ready platform

### Key Milestones

| Milestone | Target Date | Deliverable |
|-----------|-------------|-------------|
| M1: Foundation Complete | Jan 2026 | ✅ Port interfaces + custom backtest |
| M2: Framework Integration | Feb 2026 | 📋 Nautilus + Backtrader core working |
| M3: Backtesting Complete | Feb 2026 | 📋 All 3 engines available for backtest |
| M4: Paper Trading Ready | Mar 2026 | 📋 All 3 engines in paper mode |
| M5: Production Launch | May 2026 | 📋 All 3 engines in live mode |

---

## User Experience: Engine Selection

### Backtesting (After EPIC-002 Phase 2)

```python
from adapters.frameworks import create_backtest_adapter

# Option 1: Custom engine (lightweight, fast)
adapter = create_backtest_adapter(
    engine="custom",
    config=config,
    data_provider=provider
)

# Option 2: Nautilus engine (mature ecosystem)
adapter = create_backtest_adapter(
    engine="nautilus",
    config=config,
    data_provider=provider
)

# Option 3: Backtrader engine (simple, well-documented)
adapter = create_backtest_adapter(
    engine="backtrader",
    config=config,
    data_provider=provider
)

# All return same BacktestResults interface
results = adapter.run(strategy)
print(f"Return: {results.statistics['return_pct']:.2f}%")
```

### Paper Trading (EPIC-003)

```python
from adapters.frameworks import create_paper_trading_adapter

adapter = create_paper_trading_adapter(
    engine="nautilus",  # or "custom", "backtrader"
    config=config,
    live_data_feed=feed
)
```

### Live Trading (EPIC-004)

```python
from adapters.frameworks import create_live_trading_adapter

adapter = create_live_trading_adapter(
    engine="nautilus",  # or "custom", "backtrader"
    config=config,
    broker=broker
)
```

---

## Migration Path

### For Existing Code

**Before** (EPIC-002 Phase 1 only):
```python
from adapters.frameworks.backtest import BacktestAdapter

adapter = BacktestAdapter(config, data_provider)
results = adapter.run(strategy)
```

**After** (EPIC-002 Phase 2 + EPIC-005):
```python
# Option A: Keep using custom (no change needed)
from adapters.frameworks.backtest import BacktestAdapter
adapter = BacktestAdapter(config, data_provider)

# Option B: Use framework selection API
from adapters.frameworks import create_backtest_adapter
adapter = create_backtest_adapter(engine="custom", config=config, data_provider=provider)

# Option C: Switch to Nautilus
adapter = create_backtest_adapter(engine="nautilus", config=config, data_provider=provider)
```

**Backward Compatibility**: Existing code using `BacktestAdapter` directly continues to work.

---

## Risk Assessment

### Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Nautilus integration complexity | 🔴 High | 🟡 Medium | Start simple, iterate, leverage docs |
| Cross-engine PnL divergence | 🔴 High | 🟡 Medium | Comprehensive validation suite, tolerance tests |
| EPIC-005 timeline slippage | 🟡 Medium | 🟡 Medium | Timebox to 4 weeks, cut Backtrader if needed |
| Nautilus breaking changes | 🟡 Medium | 🟢 Low | Pin Nautilus version, monitor releases |
| User confusion (3 engines) | 🟡 Medium | 🟢 Low | Clear documentation, sensible defaults |

### Contingency Plans

**If EPIC-005 takes too long** (> 5 weeks):
- Ship Nautilus integration only (defer Backtrader to post-launch)
- Custom + Nautilus = 2 engines still provides choice

**If cross-engine validation fails** (PnL divergence > 1%):
- Document differences clearly
- Provide engine comparison guide
- Let users choose based on their priorities

**If Nautilus proves unstable**:
- Custom engine becomes primary recommendation
- Nautilus marked as "experimental"
- Backtrader becomes secondary option

---

## Success Criteria (Updated)

### EPIC-002 Success (Phase 1 + Phase 2)
- [x] Custom backtesting functional (Phase 1 ✅)
- [ ] Nautilus backtesting functional (Phase 2)
- [ ] Backtrader backtesting functional (Phase 2)
- [ ] User can choose engine at runtime (Phase 2)
- [ ] Cross-engine PnL validation passing (Phase 2)
- [ ] Multi-engine documentation complete (Phase 2)

### EPIC-005 Success
- [ ] Nautilus integration core complete
- [ ] Backtrader integration core complete
- [ ] Framework selection API implemented
- [ ] SimpleBuyAndHoldStrategy runs on all 3 engines
- [ ] Results match custom engine (±0.01% PnL)

### Overall Platform Success
- [ ] Backtesting: 3 engines available
- [ ] Paper Trading: 3 engines available
- [ ] Live Trading: 3 engines available
- [ ] Documentation covers all engines
- [ ] Users can switch engines without code changes

---

## Next Actions

### Immediate (This Week)

1. **Reopen EPIC-002** status: `in_progress` (50% complete)
2. **Define EPIC-005** features in detail
3. **Create EPIC-002 Phase 2** feature definitions
4. **Update roadmap** to reflect new sequencing
5. **Communication**: Share release plan with stakeholders

### Week 1 (EPIC-005 Sprint Planning)

1. **FEAT-005-01**: Nautilus Integration Core
   - Research Nautilus Strategy API
   - Design StrategyWrapper interface
   - Implement port adapters
   - Create event translator

2. **Set up Nautilus environment**
   - Install Nautilus dependencies
   - Create sample Nautilus backtest
   - Understand Nautilus configuration

### Week 2-4 (EPIC-005 Execution)

Execute EPIC-005 features sequentially:
- Week 2: Nautilus core complete
- Week 3: Backtrader core complete
- Week 4: Framework selection API + validation

### Week 5-6 (EPIC-002 Phase 2)

Complete EPIC-002 with Nautilus and Backtrader backtesting:
- Leverage EPIC-005 integration work
- Add backtest-specific wrappers
- Comprehensive testing
- Documentation updates

---

## Appendix: EPIC-002 Feature Breakdown

### Phase 1 Features (✅ Complete)

| Feature | Status | Description |
|---------|--------|-------------|
| FEATURE-001 | ✅ Complete | BacktestAdapter (custom) |
| FEATURE-002 | ✅ Complete | Event Replay Engine |
| FEATURE-003 | ✅ Complete | Execution Simulator |
| FEATURE-004 | ✅ Complete | Portfolio Accounting |
| FEATURE-005 | ✅ Complete | Performance Analytics |
| FEATURE-006 | ✅ Complete | Validation & Testing |

### Phase 2 Features (📋 Planned - After EPIC-005)

| Feature | Status | Description | Dependencies |
|---------|--------|-------------|--------------|
| FEATURE-007 | 📋 Planned | Nautilus Backtest Adapter | EPIC-005 FEAT-005-01 |
| FEATURE-008 | 📋 Planned | Backtrader Backtest Adapter | EPIC-005 FEAT-005-02 |
| FEATURE-009 | 📋 Planned | Multi-Engine Documentation | FEATURE-007, FEATURE-008 |

---

**Document Status**: 🟢 Active - Ready for execution
**Next Review**: After EPIC-005 completion
**Owner**: Product Operations Team
