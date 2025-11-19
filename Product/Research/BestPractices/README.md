# SynapticTrading Best Practices Library

**Created**: 2025-11-19
**Purpose**: Centralized repository of best practices from Nautilus, Backtrader, Claude Code, and UPMS methodology
**Maintainer**: SynapticTrading Development Team

---

## Table of Contents

1. [Overview](#overview)
2. [Nautilus Best Practices](#nautilus-best-practices)
3. [Backtrader Best Practices](#backtrader-best-practices)
4. [Claude Code Best Practices](#claude-code-best-practices)
5. [Branch Management](#branch-management)
6. [UPMS Integration](#upms-integration)
7. [Tags and Categories](#tags-and-categories)
8. [Quick Reference](#quick-reference)

---

## Overview

This library contains battle-tested best practices for:
- **Backtesting frameworks** (Nautilus, Backtrader)
- **Development workflows** (Claude Code, Git worktrees, branch management)
- **Product methodology** (UPMS integration)

**Source**: Migrated from `pilot-synaptictrading` project and enhanced with additional research.

### Directory Structure

```
BestPractices/
├── NautilusBestPractices/     # 17 comprehensive guides
├── BacktraderBestPractices/   # To be added
├── ClaudeBestPractices/       # Git worktrees, merge workflows
├── BranchManagement/          # Multi-developer workflows
├── UPMS_Integration/          # Methodology improvements
└── README.md                  # This file
```

---

## Nautilus Best Practices

### Key Documents

**Backtesting**:
- [`04_BACKTESTING_BEST_PRACTICES.md`](./NautilusBestPractices/04_BACKTESTING_BEST_PRACTICES.md) ⭐ **CRITICAL**
- [`09_BACKTEST_OPTIMIZATION_NAUTILUS_ALIGNMENT.md`](./NautilusBestPractices/09_BACKTEST_OPTIMIZATION_NAUTILUS_ALIGNMENT.md)
- [`10_NAUTILUS_PARQUET_CATALOG_PERFORMANCE_DEEP_DIVE.md`](./NautilusBestPractices/10_NAUTILUS_PARQUET_CATALOG_PERFORMANCE_DEEP_DIVE.md)

**Live/Paper Trading**:
- [`01_PAPER_TRADING_BEST_PRACTICES.md`](./NautilusBestPractices/01_PAPER_TRADING_BEST_PRACTICES.md)
- [`02_LIVE_TRADING_BEST_PRACTICES.md`](./NautilusBestPractices/02_LIVE_TRADING_BEST_PRACTICES.md)

**Options-Specific**:
- [`05_OPTIONS_BACKTESTING_BEST_PRACTICES.md`](./NautilusBestPractices/05_OPTIONS_BACKTESTING_BEST_PRACTICES.md)
- [`12_OPTIONS_SPREAD_POSITION_TRACKING.md`](./NautilusBestPractices/12_OPTIONS_SPREAD_POSITION_TRACKING.md)

**Performance & Optimization**:
- [`03_INSTRUMENT_REGISTRATION_OPTIMIZATION.md`](./NautilusBestPractices/03_INSTRUMENT_REGISTRATION_OPTIMIZATION.md)
- [`07_INSTRUMENT_PRE_COMPUTATION_PATTERN.md`](./NautilusBestPractices/07_INSTRUMENT_PRE_COMPUTATION_PATTERN.md)

### Critical Patterns for SynapticTrading

#### 1. Event-Driven Architecture

```python
# ✅ Nautilus Pattern (Event-Driven)
class OptionsSpreadStrategy(Strategy):
    def on_bar(self, bar: Bar):
        # Framework calls this automatically
        self._check_exits(bar)
        self._check_entries(bar)

    def on_order_filled(self, event: OrderFilled):
        # Automatic event handling
        self.log.info(f"Order filled: {event.order_id}")
```

**Why This Matters**: Our BacktestAdapter should follow event-driven patterns from BACKTEST_ENGINE.md.

#### 2. Actor Pattern for Components

```python
# ✅ Nautilus Pattern (Actor)
class CapitalManager(Actor):
    def on_start(self):
        self.subscribe(PositionClosed)
        self.subscribe(PositionOpened)

    def on_event(self, event):
        # React to events automatically
        if isinstance(event, PositionClosed):
            self.update_capital(event.realized_pnl)
```

**Why This Matters**: Modular components (risk manager, capital manager) should be actors, not tightly coupled.

#### 3. Native Data Catalog Usage

```python
# ✅ Use Nautilus Native Catalog
from nautilus_trader.persistence.catalog import ParquetDataCatalog

catalog = ParquetDataCatalog('data/catalogs/v12_real_enhanced_hourly')
instruments = catalog.instruments()  # Native metadata
bars = catalog.bars(instrument_ids=[...], start=..., end=...)

# ❌ DON'T: Create custom index files (.instrument_metadata.json)
```

**Why This Matters**: Our ParquetDataProvider (STORY-006) should use Nautilus catalog natively.

#### 4. Same Code, All Environments

```python
# ✅ Write once, run everywhere
class MyStrategy(Strategy):
    # Works in backtest, paper, live - NO CODE CHANGES
    pass

# Different configs only
backtest_config = BacktestEngineConfig(...)
paper_config = TradingNodeConfig(...)
live_config = TradingNodeConfig(...)
```

**Why This Matters**: Our framework-agnostic design aligns with this principle.

#### 5. Port and Adapter Pattern

```python
# ✅ Port (Interface)
class MarketDataPort(ABC):
    @abstractmethod
    def get_latest_tick(self, instrument_id) -> Optional[MarketTick]:
        pass

# ✅ Adapter (Implementation)
class BacktestMarketDataPort(MarketDataPort):
    # Backtest-specific implementation
    pass

class LiveMarketDataPort(MarketDataPort):
    # Live-specific implementation
    pass
```

**Why This Matters**: We're already implementing this correctly in EPIC-002.

---

## Backtrader Best Practices

### To Be Added

**Research Needed**:
- Backtrader event-driven vs manual iteration patterns
- Data feed architecture
- Strategy lifecycle management
- Order execution simulation
- Analyzer ecosystem

**Action**: Schedule web research for Backtrader patterns to compare with Nautilus approach.

---

## Claude Code Best Practices

### Key Documents

- [`GIT_WORKTREES_FOR_PARALLEL_CLAUDE_SESSIONS.md`](./ClaudeBestPractices/GIT_WORKTREES_FOR_PARALLEL_CLAUDE_SESSIONS.md) ⭐ **CRITICAL**
- [`LOCAL_MERGE_WORKFLOW.md`](./ClaudeBestPractices/LOCAL_MERGE_WORKFLOW.md)
- [`QUICK_REFERENCE.md`](./ClaudeBestPractices/QUICK_REFERENCE.md)

### Critical Patterns for SynapticTrading

#### 1. Git Worktrees for Parallel EPICs

```bash
# ✅ Create worktree for parallel EPIC development
git worktree add ../SynapticTrading-epic-002 epic-002-backtesting

# Multiple Claude sessions can work on different EPICs simultaneously
# - Session 1: epic-002 (backtesting)
# - Session 2: epic-003 (live trading)
# - Session 3: epic-004 (risk management)
```

**Why This Matters**: We're already using this pattern for EPIC-002 development.

#### 2. Local Merge Workflow

```bash
# ✅ Merge epic branch to main locally (not on GitHub)
git checkout main
git merge epic-002-backtesting --no-ff
git push origin main

# ❌ DON'T: Create PRs on GitHub for epic merges (slow, bureaucratic)
```

**Why This Matters**: Faster iteration cycles for solo development.

#### 3. Branch Naming Conventions

```bash
epic-XXX-<description>        # Epic branches
feature-XXX-<description>     # Feature branches within epic
story-XXX-<description>       # Story branches (rare, for complex stories)
```

**Why This Matters**: Clear traceability to vault artifacts.

---

## Branch Management

### Key Documents

- [`BRANCH_WORKFLOW_GUIDE.md`](./BranchManagement/BRANCH_WORKFLOW_GUIDE.md)
- [`MULTI_DEVELOPER_WORKFLOW.md`](./BranchManagement/MULTI_DEVELOPER_WORKFLOW.md)
- [`TEAM_ONBOARDING.md`](./BranchManagement/TEAM_ONBOARDING.md)

### Critical Patterns for UPMS Integration

#### 1. Branch-per-EPIC Strategy

**Pattern**: Each EPIC gets its own long-lived branch
- Enables parallel EPIC development
- Clear separation of concerns
- Easy to pause/resume EPIC work

**UPMS Recommendation**: Document this in UPMS Methodology as "EPIC Branch Pattern"

#### 2. Feature Flags vs Feature Branches

**Pattern**: Use feature flags for experimental features, branches for EPICs
- Feature flags: Runtime toggle (code deployed but disabled)
- Feature branches: Compile-time separation (code not deployed)

**UPMS Recommendation**: Add "Feature Management Strategy" section to UPMS

#### 3. Critical Path Management

**Pattern**: Identify and protect critical paths (data directories, config files)
- Results directories should be configurable (not hardcoded)
- Cache directories should be project-relative (not absolute)

**UPMS Recommendation**: Add "Critical Path Checklist" to UPMS templates

---

## UPMS Integration

### Improvements to UPMS Methodology

Based on learnings from pilot project and best practices:

#### 1. EPIC Branching Strategy

**Add to UPMS Methodology**:
```markdown
## EPIC Development Workflow

### Branch Strategy
- One branch per EPIC (long-lived)
- Use git worktrees for parallel EPIC development
- Merge EPICs to main locally (no GitHub PRs)

### Naming Convention
epic-XXX-<short-description>

Examples:
- epic-002-backtesting
- epic-003-live-trading
- epic-004-risk-management
```

#### 2. Parallel Development Pattern

**Add to UPMS Methodology**:
```markdown
## Parallel Development

### Multiple Claude Sessions
Use git worktrees to enable multiple AI agents working on different EPICs:

Session 1: EPIC-002 (Backtesting)
  - Worktree: ../SynapticTrading-epic-002
  - Branch: epic-002-backtesting

Session 2: EPIC-003 (Live Trading)
  - Worktree: ../SynapticTrading-epic-003
  - Branch: epic-003-live-trading

### Benefits
- True parallel EPIC development
- No context switching
- Independent test runs
- Isolated dependencies
```

#### 3. Test-Driven Development Workflow

**Add to UPMS Methodology**:
```markdown
## TDD Workflow for Stories

### Red-Green-Refactor Cycle

1. RED - Write Failing Tests First
   - Read Story acceptance criteria
   - Write comprehensive tests
   - Verify tests fail (expected)

2. GREEN - Implement Minimal Code
   - Write simplest code to pass tests
   - No over-engineering
   - Just enough to make tests pass

3. REFACTOR - Clean Up
   - Improve design
   - Add documentation
   - Extract reusable components

### Commit Pattern
[STORY-XXX] RED: Add failing tests for feature X
[STORY-XXX] GREEN: Implement feature X to pass tests
[STORY-XXX] REFACTOR: Extract helper methods
```

#### 4. Design-First Documentation

**Add to UPMS Templates**:
```markdown
## Design Document Template

### Required Before Implementation
- Architecture diagrams
- Component interfaces
- Data flow diagrams
- Sequence diagrams (for complex interactions)

### Referenced During Sprints
- Link design docs in Story descriptions
- Claude Code references design during TDD
- Tests validate design contracts
```

---

## Tags and Categories

### Tag System

**Framework Tags**:
- `#nautilus` - Nautilus Trader patterns
- `#backtrader` - Backtrader patterns
- `#framework-agnostic` - Portable patterns

**Domain Tags**:
- `#backtesting` - Backtesting specific
- `#live-trading` - Live trading specific
- `#paper-trading` - Paper trading specific
- `#options` - Options-specific patterns

**Architecture Tags**:
- `#event-driven` - Event-driven patterns
- `#actor-pattern` - Actor/component patterns
- `#ports-adapters` - Hexagonal architecture
- `#data-pipeline` - Data loading/processing

**Development Tags**:
- `#tdd` - Test-driven development
- `#design-first` - Design-first approach
- `#git-workflow` - Git/branch management
- `#claude-code` - Claude Code workflows

---

## Quick Reference

### For Backtesting (EPIC-002)

**Must Read**:
1. `NautilusBestPractices/04_BACKTESTING_BEST_PRACTICES.md` ⭐
2. `NautilusBestPractices/10_NAUTILUS_PARQUET_CATALOG_PERFORMANCE_DEEP_DIVE.md`

**Key Patterns**:
- Event-driven architecture (not manual iteration)
- Actor pattern for components (CapitalManager, RiskMonitor)
- Native catalog usage (ParquetDataCatalog)
- Port/Adapter pattern for framework independence

**Design Alignment**:
- ✅ Our BACKTEST_ENGINE.md aligns with Nautilus event-driven pattern
- ✅ Our port interfaces match MarketDataPort, ClockPort patterns
- ✅ Our EventReplayer is equivalent to Nautilus data replay engine

### For Development Workflow

**Must Read**:
1. `ClaudeBestPractices/GIT_WORKTREES_FOR_PARALLEL_CLAUDE_SESSIONS.md` ⭐
2. `BranchManagement/BRANCH_WORKFLOW_GUIDE.md`

**Key Patterns**:
- Git worktrees for parallel EPICs
- Local merge workflow (no GitHub PRs)
- EPIC-based branch naming

**Current Usage**:
- ✅ Using worktree for EPIC-002: `../SynapticTrading-epic-002`
- ✅ Branch: `epic-002-backtesting`
- ✅ Following TDD approach

### For UPMS Methodology

**Improvements to Capture**:
1. EPIC branching strategy
2. Parallel development with worktrees
3. TDD workflow documentation
4. Design-first templates

**Action**: Update `/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/` with these patterns.

---

## Maintenance

### Keeping Best Practices Current

**Review Cycle**:
- Sprint Retrospectives: Capture new patterns
- EPIC Completions: Document lessons learned
- Cross-Framework Learnings: Compare Nautilus, Backtrader, custom approaches

**Version Control**:
- Best practices library is in SynapticTrading Vault (git-controlled)
- Changes tracked via git commits
- Link improvements back to UPMS Vault

---

## References

**Nautilus Trader**:
- Docs: https://nautilustrader.io/docs/latest/
- GitHub: https://github.com/nautilustrader/nautilus_trader

**Backtrader**:
- Docs: https://www.backtrader.com/docu/
- GitHub: https://github.com/mementum/backtrader

**UPMS Vault**:
- Location: `/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/`

**SynapticTrading Vault**:
- Location: `/Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault/`

---

**Last Updated**: 2025-11-19
**Maintained By**: SynapticTrading Development Team
