# Hierarchical Folder Structure - Visual Guide

## Complete Folder Tree

```
SynapticTrading_Product/
│
├── README.md                                    # Main overview and navigation
├── QUICK_START.md                               # Getting started guide
├── IMPLEMENTATION_HIERARCHY.md                  # Complete breakdown
├── STRUCTURE_VISUAL.md                          # This file
│
├── Strategies/                               # Strategy catalogue + lifecycle docs
│   ├── README.md                             # Catalogue & status table
│   ├── Templates/
│   │   └── Strategy_Template.md
│   ├── STRAT-000-MomentumUSEquities/
│   │   └── README.md                         # Example strategy record
│   └── STRAT-001-OptionsWeeklyMonthlyHedge/
│       ├── README.md                         # Lifecycle tracker for options hedge
│       └── PRD.md                            # Imported PRD
│
├── Design/                                   # System design references
│   ├── README.md                             # Design index
│   └── 01_FrameworkAgnostic/
│       ├── OVERVIEW.md
│       ├── CORE_ARCHITECTURE.md
│       ├── BACKTEST_ENGINE.md
│       ├── PAPER_TRADING.md
│       ├── LIVE_TRADING.md
│       └── STRATEGY_LIFECYCLE.md
│
├── PRD/                                      # Product requirements archive
│   ├── README.md                             # PRD index
│   └── 01_FrameworkAgnosticPlatform/
│       ├── EXECUTIVE_SUMMARY.md
│       └── PRD.md
│
├── Research/                                 # Research studies and validation
│   ├── README.md                             # Research index
│   └── 02_FrameworkAgnosticArchitecture/
│       ├── ARCHITECTURE_BRIEF.md
│       ├── FRAMEWORK_COMPARISON.md
│       ├── DEPENDENCY_RULES.md
│       ├── RISK_TRADEOFF_LOG.md
│       └── VALIDATION_PLAN.md
│
├── EPIC-001-Foundation/                         # ━━━ WEEKS 1-4 ━━━
│   ├── README.md                                # Epic overview, 5 features, 15 stories
│   │
│   ├── FEATURE-001-PortInterfaces/              # 5 days, 5 stories
│   │   ├── README.md                            # Feature overview
│   │   ├── STORY-001-MarketDataPort/
│   │   │   └── README.md                        # Story + 12 tasks ✅ Complete example
│   │   ├── STORY-002-ClockPort/
│   │   │   └── README.md                        # Story README + task list ✅
│   │   ├── STORY-003-ExecutionPort/
│   │   │   └── README.md                        # Story README + task list ✅
│   │   ├── STORY-004-PortfolioPort/
│   │   │   └── README.md                        # Story README + task list ✅
│   │   └── STORY-005-TelemetryPort/
│   │       └── README.md                        # Story README + task list ✅
│   │
│   ├── FEATURE-002-DomainModel/                 # 4 days, 4 stories
│   │   ├── README.md                            # Feature overview ✅
│   │   ├── STORY-001-ValueObjects/
│   │   │   └── README.md                        # Story README + tasks ✅
│   │   ├── STORY-002-MarketDataObjects/
│   │   │   └── README.md                        # Story README + tasks ✅
│   │   ├── STORY-003-OrderObjects/
│   │   │   └── README.md                        # Story README + tasks ✅
│   │   └── STORY-004-PortfolioObjects/
│   │       └── README.md                        # Story README + tasks ✅
│   │
│   ├── FEATURE-003-StrategyBase/                # 3 days, 3 stories
│   │   ├── README.md                            # Feature overview ✅
│   │   ├── STORY-001-LifecycleStateMachine/
│   │   │   └── README.md                        # Story README + tasks ✅
│   │   ├── STORY-002-EventHandlers/
│   │   │   └── README.md                        # Story README + tasks ✅
│   │   └── STORY-003-HelperMethods/
│   │       └── README.md                        # Story README + tasks ✅
│   │
│   ├── FEATURE-004-Orchestration/               # 4 days, 2 stories
│   │   ├── README.md                            # Feature overview ✅
│   │   ├── STORY-001-RuntimeBootstrapper/
│   │   │   └── README.md                        # Story README + tasks ✅
│   │   └── STORY-002-TickDispatcherCommandBus/
│   │       └── README.md                        # Story README + tasks ✅
│   │
│   └── FEATURE-005-Testing/                     # 4 days, 1 story
│       ├── README.md                            # Feature overview ✅
│       └── STORY-001-MockImplementations/
│           └── README.md                        # Story README + tasks ✅
│
├── EPIC-002-Backtesting/                        # ━━━ WEEKS 5-8 ━━━
│   ├── README.md                                # Epic overview, 6 features, 18 stories
│   │
│   ├── FEATURE-001-BacktestAdapter/             # 3 days, 3 stories
│   │   ├── README.md
│   │   ├── STORY-001-AdapterClass/
│   │   ├── STORY-002-MarketDataPort/
│   │   └── STORY-003-ClockPort/
│   │
│   ├── FEATURE-002-EventReplay/                 # 4 days, 3 stories
│   │   ├── README.md
│   │   ├── STORY-001-EventReplayer/
│   │   ├── STORY-002-DataProviderInterface/
│   │   └── STORY-003-ParquetProvider/
│   │
│   ├── FEATURE-003-ExecutionSimulator/          # 5 days, 4 stories
│   │   ├── README.md
│   │   ├── STORY-001-SimulatorCore/
│   │   ├── STORY-002-OrderFillLogic/
│   │   ├── STORY-003-SlippageModels/
│   │   └── STORY-004-CommissionModels/
│   │
│   ├── FEATURE-004-Portfolio/                   # 3 days, 3 stories
│   │   ├── README.md
│   │   ├── STORY-001-PositionTracking/
│   │   ├── STORY-002-PnLCalculations/
│   │   └── STORY-003-EquityCurve/
│   │
│   ├── FEATURE-005-Analytics/                   # 4 days, 3 stories
│   │   ├── README.md
│   │   ├── STORY-001-PerformanceCalculator/
│   │   ├── STORY-002-TradeAnalysis/
│   │   └── STORY-003-BacktestResults/
│   │
│   └── FEATURE-006-Validation/                  # 3 days, 2 stories
│       ├── README.md
│       ├── STORY-001-ValidationSuite/
│       └── STORY-002-FirstBacktest/
│
├── EPIC-003-PaperTrading/                       # ━━━ WEEKS 9-10 ━━━
│   ├── README.md                                # Epic overview, 4 features, 12 stories
│   │
│   ├── FEATURE-001-PaperAdapter/                # 3 days, 3 stories
│   │   ├── README.md
│   │   ├── STORY-001-AdapterClass/
│   │   ├── STORY-002-LiveDataIntegration/
│   │   └── STORY-003-PaperExecutionPort/
│   │
│   ├── FEATURE-002-SimulatedExecution/          # 3 days, 3 stories
│   │   ├── README.md
│   │   ├── STORY-001-FillSimulation/
│   │   ├── STORY-002-LiveSlippage/
│   │   └── STORY-003-SimulatedPortfolio/
│   │
│   ├── FEATURE-003-ShadowMode/                  # 2 days, 3 stories
│   │   ├── README.md
│   │   ├── STORY-001-ShadowModeRunner/
│   │   ├── STORY-002-SignalComparator/
│   │   └── STORY-003-DivergenceDetection/
│   │
│   └── FEATURE-004-Validation/                  # 2 days, 3 stories
│       ├── README.md
│       ├── STORY-001-DeployStrategies/
│       ├── STORY-002-MonitorSevenDays/
│       └── STORY-003-ValidateBehavior/
│
├── EPIC-004-LiveTrading/                        # ━━━ WEEKS 11-14 ━━━
│   ├── README.md                                # Epic overview, 7 features, 21 stories
│   │
│   ├── FEATURE-001-LiveAdapter/                 # 4 days, 3 stories
│   │   ├── README.md
│   │   ├── STORY-001-AdapterClass/
│   │   ├── STORY-002-BrokerIntegration/
│   │   └── STORY-003-LiveExecutionPort/
│   │
│   ├── FEATURE-002-RiskManagement/              # 5 days, 4 stories
│   │   ├── README.md
│   │   ├── STORY-001-RiskOrchestratorCore/
│   │   ├── STORY-002-PositionLossLimits/
│   │   ├── STORY-003-ConcentrationLimits/
│   │   └── STORY-004-PenetrationTesting/
│   │
│   ├── FEATURE-003-KillSwitch/                  # 3 days, 3 stories
│   │   ├── README.md
│   │   ├── STORY-001-KillSwitchClass/
│   │   ├── STORY-002-EmergencyPositionClose/
│   │   └── STORY-003-ActivationTesting/
│   │
│   ├── FEATURE-004-Monitoring/                  # 4 days, 4 stories
│   │   ├── README.md
│   │   ├── STORY-001-HeartbeatMonitor/
│   │   ├── STORY-002-MetricsCollector/
│   │   ├── STORY-003-AlertManager/
│   │   └── STORY-004-MonitoringDashboards/
│   │
│   ├── FEATURE-005-AuditLogging/                # 2 days, 2 stories
│   │   ├── README.md
│   │   ├── STORY-001-PersistentAuditLog/
│   │   └── STORY-002-ComplianceEvents/
│   │
│   ├── FEATURE-006-Reconciliation/              # 2 days, 3 stories
│   │   ├── README.md
│   │   ├── STORY-001-EODReconciliation/
│   │   ├── STORY-002-PositionComparison/
│   │   └── STORY-003-ReportGeneration/
│   │
│   └── FEATURE-007-ProductionValidation/        # 4 days, 2 stories
│       ├── README.md
│       ├── STORY-001-StagingDeployment/
│       └── STORY-002-SevenDayUptimeTest/
│
├── EPIC-005-Adapters/                           # ━━━ WEEKS 15-16 ━━━
│   ├── README.md                                # Epic overview, 3 features, 9 stories
│   │
│   ├── FEATURE-001-NautilusAdapter/             # 4 days, 3 stories
│   │   ├── README.md
│   │   ├── STORY-001-AdapterClass/
│   │   ├── STORY-002-PortImplementations/
│   │   └── STORY-003-StrategyMigration/
│   │
│   ├── FEATURE-002-BacktraderAdapter/           # 3 days, 3 stories
│   │   ├── README.md
│   │   ├── STORY-001-AdapterClass/
│   │   ├── STORY-002-PortImplementations/
│   │   └── STORY-003-ValidationRun/
│   │
│   └── FEATURE-003-CrossEngineValidation/       # 3 days, 3 stories
│       ├── README.md
│       ├── STORY-001-RunOnAllAdapters/
│       ├── STORY-002-CompareSignalsAndPnL/
│       └── STORY-003-ValidateTolerance/
│
└── EPIC-006-Hardening/                          # ━━━ WEEKS 17-18 ━━━
    ├── README.md                                # Epic overview, 5 features, 15 stories
    │
    ├── FEATURE-001-Documentation/               # 3 days, 3 stories
    │   ├── README.md
    │   ├── STORY-001-APIDocumentation/
    │   ├── STORY-002-DeveloperGuide/
    │   └── STORY-003-OperationalRunbooks/
    │
    ├── FEATURE-002-Performance/                 # 3 days, 3 stories
    │   ├── README.md
    │   ├── STORY-001-ProfilingOptimization/
    │   ├── STORY-002-CachingImplementation/
    │   └── STORY-003-BenchmarkValidation/
    │
    ├── FEATURE-003-Security/                    # 2 days, 3 stories
    │   ├── README.md
    │   ├── STORY-001-SecurityAudit/
    │   ├── STORY-002-EncryptionImplementation/
    │   └── STORY-003-VulnerabilityFixes/
    │
    ├── FEATURE-004-LoadTesting/                 # 2 days, 3 stories
    │   ├── README.md
    │   ├── STORY-001-LoadTestScenarios/
    │   ├── STORY-002-RunLoadTests/
    │   └── STORY-003-ScalabilityValidation/
    │
    └── FEATURE-005-ProductionRollout/           # 2 days, 3 stories
        ├── README.md
        ├── STORY-001-DeployToProduction/
        ├── STORY-002-MonitorSevenDays/
        └── STORY-003-RetrospectiveDocumentation/

├── EPIC-007-StrategyLifecycle/                # ━━━ CONTINUOUS ━━━
│   ├── README.md                              # Epic overview, 5 features, 17 stories
│   │
│   ├── FEATURE-001-ResearchPipeline/          # Intake & discovery workflow ✅ scaffolded
│   │   ├── README.md                          # Feature overview ✅
│   │   ├── TRACEABILITY.md                    # Traceability matrix ✅
│   │   ├── STORY-001-IntakeWorkflow/
│   │   │   └── README.md                      # Intake workflow story ✅
│   │   ├── STORY-002-ResearchTemplate/
│   │   │   └── README.md                      # Research template story ✅
│   │   ├── STORY-003-ValidationGate/
│   │   │   └── README.md                      # Validation gate story ✅
│   │   └── STORY-004-StrategyCatalog/
│   │       └── README.md                      # Strategy catalogue story ✅
│   │
│   ├── FEATURE-002-PrioritisationGovernance/  # Scoring & council ✅ scaffolded
│   │   ├── README.md                          # Feature overview ✅
│   │   ├── TRACEABILITY.md                    # Traceability matrix ✅
│   │   ├── STORY-001-ScoringModel/
│   │   │   └── README.md                      # Scoring model story ✅
│   │   ├── STORY-002-GovernanceCouncil/
│   │   │   └── README.md                      # Council operations story ✅
│   │   └── STORY-003-LifecycleDashboard/
│   │       └── README.md                      # Dashboard story ✅
│   │
│   ├── FEATURE-003-ImplementationBridge/      # Engineering handoff ✅ scaffolded
│   │   ├── README.md                          # Feature overview ✅
│   │   ├── TRACEABILITY.md                    # Traceability matrix ✅
│   │   ├── STORY-001-HandoffDossier/
│   │   │   └── README.md                      # Handoff dossier story ✅
│   │   ├── STORY-002-TraceabilityMapping/
│   │   │   └── README.md                      # Traceability mapping story ✅
│   │   └── STORY-003-EngineeringSync/
│   │       └── README.md                      # Sync process story ✅
│   │
│   ├── FEATURE-004-DeploymentRunbooks/        # Deployment playbooks ✅ scaffolded
│   │   ├── README.md                          # Feature overview ✅
│   │   ├── TRACEABILITY.md                    # Traceability matrix ✅
│   │   ├── STORY-001-PaperTrialPlaybook/
│   │   │   └── README.md                      # Paper trial story ✅
│   │   ├── STORY-002-GoNoGoChecklist/
│   │   │   └── README.md                      # Go/No-Go story ✅
│   │   └── STORY-003-LiveRolloutRunbook/
│   │       └── README.md                      # Live rollout story ✅
│   │
│   └── FEATURE-005-ContinuousOptimization/    # Post-trade analytics ✅ scaffolded
│       ├── README.md                          # Feature overview ✅
│       ├── TRACEABILITY.md                    # Traceability matrix ✅
│       ├── STORY-001-KPIFramework/
│       │   └── README.md                      # KPI framework story ✅
│       ├── STORY-002-PostDeploymentReview/
│       │   └── README.md                      # Review cadence story ✅
│       ├── STORY-003-IterationBacklog/
│       │   └── README.md                      # Iteration backlog story ✅
│       └── STORY-004-RetirementProtocol/
│           └── README.md                      # Retirement protocol story ✅
```

## Hierarchy Summary

### Level 1: Epics (7 total)
```
EPIC-001-Foundation      (4 weeks)  →  5 features,  15 stories
EPIC-002-Backtesting     (4 weeks)  →  6 features,  18 stories
EPIC-003-PaperTrading    (2 weeks)  →  4 features,  12 stories
EPIC-004-LiveTrading     (4 weeks)  →  7 features,  21 stories
EPIC-005-Adapters        (2 weeks)  →  3 features,   9 stories
EPIC-006-Hardening       (2 weeks)  →  5 features,  15 stories
EPIC-007-StrategyLifecycle (continuous) → 5 features, 17 stories
─────────────────────────────────────────────────────────────
TOTAL                    18 weeks + lifecycle     35 features,  107 stories
```

### Level 2: Features (35 total)
Each feature folder contains:
- `README.md` with feature overview
- Multiple STORY-###-Name/ subfolders

### Level 3: Stories (107 total)
Each story folder contains:
- `README.md` with story details and tasks

### Level 4: Tasks (~420 total)
Tasks embedded in story README.md files as markdown checklists

## File Count

```
7 Epics         × 1 README.md  =   7 files
35 Features     × 1 README.md  =  35 files
107 Stories     × 1 README.md  = 107 files
────────────────────────────────────────
Total README.md files          = 149 files
```

Plus:
- 1 main README.md
- 1 QUICK_START.md
- 1 IMPLEMENTATION_HIERARCHY.md
- 1 STRUCTURE_VISUAL.md

**Grand Total**: 153 markdown files

## Current Status

### ✅ Created
- All 7 epic folders with README files (EPIC-007 newly scaffolded)
- Feature/story documentation complete for EPIC-001 and EPIC-007
- Strategy lifecycle catalogue seeded with template + example strategy

### 📋 To Be Created
- Feature/story documentation for EPIC-002 → EPIC-006
- Additional strategy folders as research moves forward

## Example Paths

### Navigate to Epic
```bash
cd EPIC-001-Foundation/
open README.md
```

### Navigate to Feature
```bash
cd EPIC-001-Foundation/FEATURE-001-PortInterfaces/
open README.md
```

### Navigate to Story
```bash
cd EPIC-001-Foundation/FEATURE-001-PortInterfaces/STORY-001-MarketDataPort/
open README.md  # Contains 12 tasks
```

## Naming Rules

### Folders
- **Epic**: `EPIC-###-Name/` (e.g., `EPIC-001-Foundation/`)
- **Feature**: `FEATURE-###-Name/` (e.g., `FEATURE-001-PortInterfaces/`)
- **Story**: `STORY-###-Name/` (e.g., `STORY-001-MarketDataPort/`)

### Files
- Every folder has `README.md`
- Tasks embedded in story README.md

### Numbers
- Epic: 001-006 (6 epics)
- Feature: 001-007 (varies by epic)
- Story: 001-005 (varies by feature)
- Task: Listed as checklist items in story

## Benefits of This Structure

### ✅ Clear Hierarchy
- Visual folder structure mirrors work breakdown
- Easy to navigate with standard file managers

### ✅ Self-Documenting
- Folder names describe scope
- README.md provides details at each level

### ✅ Git-Friendly
- Small files, easy to review
- Merge conflicts minimized
- Clear file ownership

### ✅ Tool-Agnostic
- Works in GitHub, GitLab, Bitbucket
- Compatible with any markdown viewer
- No special tooling required

### ✅ Scalable
- Easy to add new features/stories
- Template pattern clear from examples
- Consistent structure throughout

---

**Created**: 2025-11-03
**Purpose**: Visual guide to hierarchical folder structure
**Status**: Foundation folders created, content in progress
