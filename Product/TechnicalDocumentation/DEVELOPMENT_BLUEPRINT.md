# Development Blueprint: Hybrid UPMS Implementation

**Document ID**: `dev-blueprint-20251104-hybrid-upms`
**Created**: 2025-11-04
**Owner**: Engineering Team
**Status**: Active
**Version**: 1.0.0

---

## Purpose

This blueprint defines how to develop code in the **SynapticTrading code repository** while maintaining traceability and development status in the **Obsidian Knowledge Vault**. It implements a pragmatic hybrid of UPMS methodology (Option C) that balances rigor with velocity.

---

## Core Principles

1. **Code lives in repository** (`/Users/nitindhawan/Downloads/CodeRepository/SynapticTrading`)
2. **Planning lives in vault** (`/Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault`)
3. **Traceability is bidirectional** (code → vault, vault → code)
4. **Sprints drive development** (time-boxed iterations with clear objectives)
5. **Quality gates are lightweight** (essential checkpoints only)

---

## Repository Structure

### Code Repository Layout

```
SynapticTrading/
├── src/
│   ├── domain/                    # Pure business logic
│   │   ├── shared/
│   │   │   ├── __init__.py
│   │   │   ├── value_objects.py
│   │   │   └── events.py
│   │   └── strategy/
│   │       ├── aggregates/
│   │       ├── services/
│   │       └── value_objects/
│   ├── application/               # Orchestration & ports
│   │   ├── ports/
│   │   │   ├── __init__.py
│   │   │   ├── market_data_port.py
│   │   │   ├── clock_port.py
│   │   │   ├── execution_port.py
│   │   │   ├── portfolio_port.py
│   │   │   └── telemetry_port.py
│   │   └── orchestration/
│   │       ├── runtime_bootstrapper.py
│   │       ├── tick_dispatcher.py
│   │       ├── command_bus.py
│   │       └── risk_orchestrator.py
│   ├── adapters/                  # Framework-specific implementations
│   │   └── frameworks/
│   │       ├── backtest/
│   │       ├── paper/
│   │       ├── live/
│   │       └── custom/
│   └── interfaces/
│       └── strategy_runtime.py
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── contract/                  # Port contract tests
│   └── mocks/
├── docs/                          # Auto-generated API docs
├── documentation/                 # Development guides & blueprints
│   ├── DEVELOPMENT_BLUEPRINT.md   # This file
│   ├── diagrams/
│   ├── logs/
│   └── notes/
├── pyproject.toml
├── setup.py
├── .importlinter.ini              # Dependency rules enforcement
├── pytest.ini
├── .github/
│   └── workflows/
│       ├── test.yml
│       └── lint.yml
└── README.md
```

### Knowledge Vault Layout (Corrected Structure)

```
Synaptic_Trading_KnowledgeVault/
├── SynapticTrading_Product/       # Product-specific content & operations
│   ├── EPICS/
│   │   └── EPIC-001-Foundation/
│   │       ├── README.md
│   │       ├── PRD.md
│   │       ├── REQUIREMENTS_MATRIX.md
│   │       └── FEATURE-*/
│   │           ├── README.md
│   │           ├── TRACEABILITY.md
│   │           └── STORY-*/
│   │               └── README.md
│   ├── Design/                    # Architecture & design docs
│   ├── Research/                  # Research findings
│   ├── Templates/                 # Product templates
│   ├── Sprints/                   # ⭐ Sprint tracking (operational)
│   │   └── SPRINT-YYYYMMDD-slug/
│   │       └── README.md
│   ├── Issues/                    # ⭐ Issue tracking (operational)
│   │   └── ISSUE-timestamp-slug.md
│   └── Designs/                   # ⭐ Design approvals (operational)
│       └── DESIGN-ID/
│           └── README.md
└── UPMS/                          # Methodology only (non-operational)
    └── Methodology/
        ├── UPMS_Methodology_Blueprint.md
        └── Research/
```

---

## Development Workflow

### Phase 1: Pre-Development (Sprint Planning)

**Location**: Knowledge Vault

1. **Review Epic/Feature/Story** in vault
   - Read `EPIC-001-Foundation/README.md`
   - Review feature objectives
   - Identify stories for sprint

2. **Create Sprint README**
   - Location: `SynapticTrading_Product/Sprints/SPRINT-YYYYMMDD-slug/README.md`
   - Link to stories/features
   - Define objectives and acceptance criteria
   - Set duration (1-2 weeks typical)

3. **Check Design Approval** (if needed)
   - For new components, create `SynapticTrading_Product/Designs/DESIGN-ID/README.md`
   - Reference architecture docs from `SynapticTrading_Product/Design/`
   - Get approval (can be self-approval for solo dev, document decision)

4. **Update Traceability Matrix**
   - Open `FEATURE-*/TRACEABILITY.md`
   - Ensure stories linked to requirements
   - Pre-define test identifiers

### Phase 2: Development (TDD)

**Location**: Code Repository

**For Each Story:**

1. **Create Test Contract First**
   ```python
   # tests/contract/test_market_data_port_contract.py
   def test_get_latest_tick_returns_immutable_snapshot():
       """Contract: MarketDataPort.get_latest_tick returns defensive copy"""
       pass  # Write failing test
   ```

2. **Implement Code**
   ```python
   # src/application/ports/market_data_port.py
   from abc import ABC, abstractmethod

   class MarketDataPort(ABC):
       @abstractmethod
       def get_latest_tick(self, instrument_id: InstrumentId) -> Optional[MarketTick]:
           """Implementation that passes contract test"""
           pass
   ```

3. **Write Unit Tests**
   ```python
   # tests/unit/application/ports/test_market_data_port.py
   def test_market_data_port_interface():
       """Test port interface definition"""
       pass
   ```

4. **Update Documentation**
   - Add docstrings (Google style)
   - Update README if needed
   - Auto-generate API docs

5. **Commit with Traceability**
   ```bash
   git add .
   git commit -m "[STORY-001-01-01][TASK-003] Implement get_latest_tick method

   - Added MarketTick return type with immutability guarantee
   - Implemented defensive copy pattern
   - Added UTC timezone validation
   - Contract and unit tests passing (coverage: 95%)

   Refs: REQ-EPIC001-001, DESIGN-PORT-001
   Files: src/application/ports/market_data_port.py
   Tests: tests/contract/test_market_data_port_contract.py
   Progress: 25% → 45%"
   ```

### Phase 3: Progress Tracking (Continuous)

**Location**: Knowledge Vault

**Daily Updates:**

1. **Update Story Progress**
   - Edit `STORY-*/README.md` front-matter
   ```yaml
   progress_pct: 45
   last_review: 2025-11-04
   change_log:
     - 2025-11-04 – eng_team – Implemented get_latest_tick, tests passing – REQ-EPIC001-001
   ```

2. **Check Off Tasks**
   - Update task checkboxes in Story README
   ```markdown
   - [x] TASK-001-01-01-01: Create port module file and imports (0.5h)
   - [x] TASK-001-01-01-02: Define MarketDataPort ABC skeleton (0.5h)
   - [x] TASK-001-01-01-03: Implement get_latest_tick method signature (0.5h)
   - [ ] TASK-001-01-01-04: Implement get_latest_bar method signature (0.5h)
   ```

3. **Log Issues** (if blockers arise)
   - Create `SynapticTrading_Product/Issues/ISSUE-20251104-type-inference-mypy.md`
   - Link to story/task
   - Track resolution

**Weekly Updates (Sprint Checkpoint):**

1. **Update Sprint README**
   - Log completed stories
   - Update burn-down metrics
   - Note any blockers/risks

2. **Update Requirements Matrix**
   - Add test references to `REQUIREMENTS_MATRIX.md`
   ```markdown
   | REQ-EPIC001-001 | Define stable market data interface | res-technical-20251015-01 | STORY-001-MarketDataPort | TASK-001-003 | TEST-PORT-CONTRACT-001, TEST-UNIT-001 | validated | Tests passing 95% coverage |
   ```

3. **Update Feature Traceability**
   - Sync `FEATURE-*/TRACEABILITY.md` with sprint progress
   ```markdown
   | STORY-001 | Market Data Port | REQ-EPIC001-001 | TASK-001-003 | TEST-PORT-CONTRACT-001 | SPRINT-20251104-foundation | in_progress | 45% complete |
   ```

### Phase 4: Story Completion

**Location**: Both (Code & Vault)

**Code Repository:**
- [ ] All tests passing (>90% coverage)
- [ ] Code reviewed (can be self-review, document in commit)
- [ ] Linting passed (mypy, pylint, black)
- [ ] Documentation updated
- [ ] Merged to main branch

**Knowledge Vault:**
- [ ] Story progress set to 100%
- [ ] All tasks checked off
- [ ] Change log entry added
- [ ] Tests linked in REQUIREMENTS_MATRIX.md
- [ ] TRACEABILITY.md updated with completion date

**Story README Update:**
```yaml
id: STORY-001-MarketDataPort
status: completed
progress_pct: 100
completed_date: 2025-11-10
sprint_ids: ["SPRINT-20251104-foundation"]
change_log:
  - 2025-11-10 – eng_team – Story completed, all tests passing – REQ-EPIC001-001
```

### Phase 5: Sprint Close

**Location**: Knowledge Vault

1. **Sprint Retrospective**
   - Update `UPMS/Sprints/SPRINT-*/README.md`
   - Document what went well, what didn't
   - Capture learnings

2. **Update Epic Metrics**
   - Update `EPIC-001-Foundation/README.md`
   ```yaml
   progress_pct: 35
   requirement_coverage: 40
   linked_sprints: ["SPRINT-20251104-foundation"]
   ```

3. **Plan Next Sprint**
   - Create next sprint README
   - Link remaining stories
   - Adjust based on velocity

---

## Traceability Reference Map

### From Code to Vault

**Git Commit** → **Story/Task** → **Feature** → **Epic** → **Requirement**

Example:
```
Commit a1b2c3d
  → [STORY-001-01-01][TASK-003]
    → FEATURE-001-PortInterfaces
      → EPIC-001-Foundation
        → REQ-EPIC001-001
```

### From Vault to Code

**Requirement** → **Story** → **Task** → **Test** → **Code**

Example:
```
REQ-EPIC001-001
  → STORY-001-MarketDataPort
    → TASK-001-01-01-03
      → TEST-PORT-CONTRACT-001
        → src/application/ports/market_data_port.py:25
```

---

## Git Commit Standards

### Format

```
[STORY-ID][TASK-ID] Short description (50 chars max)

- Detailed bullet points of changes
- What was added/modified/removed
- Test results and coverage

Refs: REQ-ID, DESIGN-ID
Files: src/path/to/file.py
Tests: tests/path/to/test.py
Progress: X% → Y%
```

### Examples

**Good Commit:**
```
[STORY-001-01-01][TASK-003] Implement get_latest_tick method

- Added MarketTick return type with Optional handling
- Implemented defensive copy for immutability
- Added UTC timezone validation in docstring
- Contract tests passing, unit tests at 95% coverage

Refs: REQ-EPIC001-001, DESIGN-PORT-001
Files: src/application/ports/market_data_port.py
Tests: tests/contract/test_market_data_port_contract.py
Progress: 25% → 45%
```

**Bad Commit:**
```
fix stuff
```

### Branch Naming

- Feature branches: `feature/STORY-001-market-data-port`
- Bugfix branches: `fix/ISSUE-001-type-inference`
- Sprint branches (optional): `sprint/20251104-foundation`

---

## Testing Strategy

### Test Pyramid

```
           E2E Tests (Few)
         /               \
    Integration Tests (Some)
   /                         \
Unit Tests (Many) + Contract Tests (All Ports)
```

### Test Categories

1. **Contract Tests** (`tests/contract/`)
   - Verify port interface compliance
   - Run against all adapter implementations
   - Required for every port method

2. **Unit Tests** (`tests/unit/`)
   - Test individual components in isolation
   - Mock all dependencies
   - Target: >90% coverage

3. **Integration Tests** (`tests/integration/`)
   - Test component interactions
   - Use mocks for external systems
   - Focus on critical paths

4. **End-to-End Tests** (`tests/e2e/`)
   - Full strategy execution scenarios
   - Use mock adapters
   - Validate orchestration flow

### Coverage Requirements

| Component | Minimum Coverage | Target |
|-----------|-----------------|--------|
| `src/domain/` | 90% | 95% |
| `src/application/ports/` | 90% | 95% |
| `src/application/orchestration/` | 85% | 90% |
| `src/adapters/` | 80% | 85% |
| **Overall** | **85%** | **90%** |

---

## Quality Gates (Lightweight)

### G0: Inception (Epic Start)
- [ ] Epic README created in vault
- [ ] PRD documented
- [ ] REQUIREMENTS_MATRIX.md created
- [ ] High-level architecture reviewed

### G1: Discovery (Feature Start)
- [ ] Feature README created
- [ ] TRACEABILITY.md template populated
- [ ] Design documents reviewed (reference existing if applicable)
- [ ] Stories defined with task lists

### G2: Definition (Before Coding)
- [ ] Sprint README created
- [ ] Stories prioritized and estimated
- [ ] Test strategy defined
- [ ] Repository structure ready

### G3: Delivery (During Development)
- [ ] Code committed with traceability
- [ ] Tests passing
- [ ] Progress tracked in vault
- [ ] Issues documented and resolved

### G4: Validation (Feature Complete)
- [ ] All stories completed (100%)
- [ ] Coverage targets met
- [ ] Integration tests passing
- [ ] TRACEABILITY.md fully populated

### G5: Operate (Epic Complete)
- [ ] Sprint retrospectives documented
- [ ] Epic metrics updated
- [ ] Learnings captured
- [ ] Ready for next epic

---

## Tools & Automation

### Required Tools

```bash
# Python environment
python >= 3.10
pytest
pytest-cov
mypy
pylint
black
import-linter

# Git hooks
pre-commit
```

### Setup

```bash
# Install dependencies
cd /Users/nitindhawan/Downloads/CodeRepository/SynapticTrading
pip install -e ".[dev]"

# Configure pre-commit hooks
pre-commit install

# Run tests
pytest tests/ --cov=src --cov-report=html

# Run linting
mypy src/
pylint src/
black src/ tests/

# Check dependency rules
lint-imports
```

### Recommended Aliases

```bash
# Add to ~/.zshrc or ~/.bashrc
alias st-test='pytest tests/ --cov=src --cov-report=term-missing'
alias st-lint='mypy src/ && pylint src/ && black --check src/ tests/'
alias st-deps='lint-imports'
alias st-all='st-test && st-lint && st-deps'
```

---

## Practical Examples

### Example 1: Starting STORY-001 (MarketDataPort)

**Step 1: Review in Vault**
```bash
# Read story details
open "/Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault/SynapticTrading_Product/EPICS/EPIC-001-Foundation/FEATURE-001-PortInterfaces/STORY-001-MarketDataPort/README.md"
```

**Step 2: Create Sprint**
```bash
# Create sprint folder
mkdir -p "/Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault/SynapticTrading_Product/Sprints/SPRINT-20251104-foundation"

# Create sprint README (use template)
```

**Step 3: Write Tests First**
```bash
cd /Users/nitindhawan/Downloads/CodeRepository/SynapticTrading

# Create contract test
touch tests/contract/test_market_data_port_contract.py
```

**Step 4: Implement Port**
```bash
# Create port file
touch src/application/ports/market_data_port.py

# Implement interface
```

**Step 5: Commit with Traceability**
```bash
git add .
git commit -m "[STORY-001-01-01][TASK-003] Implement get_latest_tick method

- Added MarketDataPort ABC with get_latest_tick signature
- Created contract test for immutability guarantee
- Added comprehensive docstrings

Refs: REQ-EPIC001-001, DESIGN-PORT-001
Files: src/application/ports/market_data_port.py
Tests: tests/contract/test_market_data_port_contract.py
Progress: 0% → 15%"
```

**Step 6: Update Vault**
- Update Story README progress_pct to 15
- Check off completed tasks
- Add change log entry

### Example 2: Handling a Blocker

**Issue Arises:**
```
MyPy type inference failing for Optional[MarketTick]
```

**Step 1: Create Issue in Vault**
```bash
# Create issue file
touch "/Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault/SynapticTrading_Product/Issues/ISSUE-20251104-mypy-optional-inference.md"
```

**Step 2: Document Issue**
```yaml
---
id: ISSUE-20251104-mypy-optional-inference
title: "MyPy Type Inference Failing for Optional[MarketTick]"
status: analysis
severity: medium
related_story: STORY-001-01-01
created_at: 2025-11-04T10:30:00Z
---

## Description
MyPy unable to infer Optional[MarketTick] return type...

## Resolution
Added explicit type annotation...
```

**Step 3: Fix and Link**
```bash
git commit -m "[STORY-001-01-01][ISSUE-001] Fix MyPy type inference

- Added explicit Optional[MarketTick] annotation
- MyPy now passes cleanly

Refs: ISSUE-20251104-mypy-optional-inference
Closes: ISSUE-001"
```

**Step 4: Update Issue Status**
- Set status to `resolved`
- Add resolution notes

---

## Sprint Template

### Location
`SynapticTrading_Product/Sprints/SPRINT-YYYYMMDD-slug/README.md`

### Template
```yaml
---
id: SPRINT-20251104-foundation
seq: 1
title: "Foundation Sprint 1: Port Interfaces & Domain Foundation"
owner: eng_team
status: in_progress
type: delivery
duration_days: 10
start_date: 2025-11-04
end_date: 2025-11-15
related_items:
  - EPIC-001-Foundation
  - FEATURE-001-PortInterfaces
  - STORY-001-MarketDataPort
  - STORY-002-ClockPort
  - STORY-003-ExecutionPort
objectives:
  - Complete all 5 port interface definitions
  - Implement core value objects
  - Achieve 90%+ test coverage
metrics_baseline:
  code_coverage: 0
  stories_completed: 0
metrics_target:
  code_coverage: 90
  stories_completed: 7
change_log:
  - 2025-11-04 – eng_team – Sprint initiated – n/a
---

## Sprint Goals

### Primary Objective
Complete FEATURE-001 (Port Interfaces) and begin FEATURE-002 (Domain Model)

### Success Criteria
- [ ] 5 port interfaces defined and documented
- [ ] Contract tests written for all ports
- [ ] Mock implementations available
- [ ] Core value objects implemented (InstrumentId, Price, Quantity)
- [ ] 90%+ test coverage achieved

## Planned Scope

| Story ID | Title | Est. Days | Priority | Status |
|----------|-------|-----------|----------|--------|
| STORY-001 | MarketDataPort | 1 | P0 | in_progress |
| STORY-002 | ClockPort | 1 | P0 | planned |
| STORY-003 | ExecutionPort | 1 | P0 | planned |
| STORY-004 | PortfolioPort | 1 | P0 | planned |
| STORY-005 | TelemetryPort | 1 | P0 | planned |
| STORY-006 | Value Objects | 1.5 | P0 | planned |
| STORY-007 | Market Data Objects | 1.5 | P1 | planned |

**Total**: 8 days planned work, 10 days sprint duration (buffer: 2 days)

## Daily Progress Log

### 2025-11-04
- Started STORY-001: MarketDataPort
- Created contract test framework
- Progress: 15%

### 2025-11-05
- ...

## Risks & Dependencies

| Risk | Impact | Mitigation |
|------|--------|------------|
| Type system complexity with generics | Medium | Consult Python typing docs, simplify if needed |
| Test coverage tracking setup | Low | Configure pytest-cov early |

## Completion Report

*(Fill at sprint end)*

### Metrics Achieved
- Code coverage: ___%
- Stories completed: ___
- Tests written: ___

### What Went Well
- ...

### What Didn't Go Well
- ...

### Action Items for Next Sprint
- ...
```

---

## Issue Template

### Location
`SynapticTrading_Product/Issues/ISSUE-timestamp-slug.md`

### Template
```yaml
---
id: ISSUE-20251104-slug
title: "Issue Title"
status: identified
severity: low|medium|high|critical
related_story: STORY-ID
related_task: TASK-ID
created_at: 2025-11-04T10:00:00Z
updated_at: 2025-11-04T10:00:00Z
resolved_at: null
change_log:
  - 2025-11-04 – eng_team – Issue identified – STORY-ID
---

## Description
Clear description of the issue...

## Impact
How this blocks/affects development...

## Root Cause
*(Fill during analysis)*

## Resolution
*(Fill when resolved)*

## Related Commits
- Commit hash: commit message
```

---

## Design Document Template

### Location
`SynapticTrading_Product/Designs/DESIGN-ID/README.md`

### Template
```yaml
---
id: DESIGN-PORT-001
title: "Port Interface Design"
owner: lead_architect
status: approved
approval_status: approved
approver: lead_architect
approval_date: 2025-11-03
related_epic: EPIC-001
related_feature: FEATURE-001
related_requirements:
  - REQ-EPIC001-001
change_log:
  - 2025-11-03 – lead_architect – Initial design – REQ-EPIC001-001
---

## Design Overview
Brief summary of what's being designed...

## Architecture Diagrams
Link to diagrams or embed...

## Interface Specifications
Detailed API specifications...

## Test Strategy
How this will be tested...

## Risk Assessment
Potential risks and mitigations...

## Rollback Plan
How to revert if needed...

## References
- Link to architecture docs
- Link to requirements
```

---

## Metrics & Dashboards (Future)

### Key Metrics to Track

**Development Velocity:**
- Stories completed per sprint
- Average story completion time
- Velocity trend

**Quality Metrics:**
- Test coverage percentage
- Defect density (issues per story)
- Code review cycle time

**Traceability Metrics:**
- Requirements with linked tests
- Stories with design approval
- Commits with traceability tags

**Sprint Health:**
- Planned vs. actual scope
- Sprint goal achievement rate
- Blocker resolution time

---

## FAQs

### Q: Do I need to create a design doc for every story?
**A:** No. Create design docs for:
- New architectural components (ports, orchestration)
- Complex algorithms
- Major changes to existing components

Simple implementations can reference existing design docs.

### Q: How often should I update the vault?
**A:**
- **Daily**: Update story progress, check off tasks
- **After each commit**: If significant progress (optional but recommended)
- **Weekly**: Update sprint README, requirements matrix, traceability
- **Sprint end**: Complete retrospective, update epic metrics

### Q: What if I forget to add traceability to a commit?
**A:** Use `git commit --amend` before pushing, or create a follow-up commit with proper references.

### Q: Can I work on multiple stories in parallel?
**A:** Yes, but:
- Keep them in separate branches
- Update vault for each story independently
- Don't let too many stories linger "in progress"

### Q: What if a story takes longer than estimated?
**A:**
- Update the sprint README with revised estimate
- Log the reason in sprint retrospective
- Adjust future estimates based on learnings

---

## Quick Reference Commands

### Daily Workflow
```bash
# 1. Read story from vault
open "<vault-path>/STORY-*/README.md"

# 2. Write tests first
cd /Users/nitindhawan/Downloads/CodeRepository/SynapticTrading
pytest tests/ -v

# 3. Implement code
# ... code ...

# 4. Run quality checks
pytest tests/ --cov=src
mypy src/
black src/ tests/

# 5. Commit with traceability
git add .
git commit -m "[STORY-ID][TASK-ID] Description

Refs: REQ-ID
Progress: X% → Y%"

# 6. Update vault progress
# Edit story README front-matter, check off tasks
```

### Weekly Workflow
```bash
# 1. Update sprint README with progress
open "<vault-path>/SynapticTrading_Product/Sprints/SPRINT-*/README.md"

# 2. Update requirements matrix
open "<vault-path>/SynapticTrading_Product/EPICS/EPIC-*/REQUIREMENTS_MATRIX.md"

# 3. Update feature traceability
open "<vault-path>/SynapticTrading_Product/EPICS/EPIC-*/FEATURE-*/TRACEABILITY.md"

# 4. Review and triage issues
ls "<vault-path>/SynapticTrading_Product/Issues/"
```

---

## Next Steps

### Immediate (Today)
1. ✅ Read this blueprint
2. Create essential UPMS folders in vault
3. Create Sprint-0 for foundation prep
4. Initialize code repository structure
5. Set up development tools (pytest, mypy, etc.)

### Short-term (This Week)
1. Create Sprint-1 README
2. Start STORY-001: MarketDataPort
3. Write first contract test
4. Implement first port interface
5. Update vault with progress

### Medium-term (This Month)
1. Complete EPIC-001 (all 5 features)
2. Establish sprint rhythm
3. Refine traceability process
4. Build automation for progress tracking

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-11-04 | eng_team | Initial blueprint created |

---

**Blueprint Location**: `/Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/documentation/DEVELOPMENT_BLUEPRINT.md`

**Obsidian Vault Location**: `/Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault/`

**Code Repository**: `/Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/`

---

*This is a living document. Update as the process evolves.*
