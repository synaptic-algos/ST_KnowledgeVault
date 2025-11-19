---
id: DESIGN-007-StrategyIntakeWorkflow
title: "Strategy Intake Workflow Design"
owner: strategy_ops_team
status: draft
artifact_type: design_document
related_epic:
  - EPIC-007
related_feature:
  - FEATURE-001-ResearchPipeline
related_story:
  - STORY-007-01-01
created_at: 2025-11-19T00:00:00Z
updated_at: 2025-11-19T00:00:00Z
last_review: 2025-11-19
version: 0.1.0
reviewers: []
approval_status: pending
---

# DESIGN-007: Strategy Intake Workflow

## 1. Document Overview

### Purpose
Design a standardized intake workflow for new trading strategy ideas that captures essential information, enforces compliance checks, and feeds into the strategy lifecycle dashboard.

### Scope
- **In Scope**:
  - Intake form schema and validation rules
  - Workflow state machine (submission → compliance → data access → lifecycle dashboard)
  - Integration with lifecycle dashboard
  - Documentation and SLA requirements

- **Out of Scope**:
  - Strategy prioritization logic (covered by FEATURE-002)
  - Research execution templates (covered by STORY-007-01-02)
  - Deployment workflows (covered by FEATURE-004)

### References
- **PRD**: [EPIC-007 PRD](../vault_epics/EPIC-007-StrategyLifecycle/PRD.md)
- **Story**: [STORY-007-01-01](../vault_epics/EPIC-007-StrategyLifecycle/Features/FEATURE-001-ResearchPipeline/Stories/STORY-001-IntakeWorkflow.md)
- **Requirements**: REQ-EPIC007-001, REQ-EPIC007-002

---

## 2. Problem Statement

### Current State
- No standardized process for submitting new strategy ideas
- Inconsistent information captured across submissions
- Manual compliance and data access reviews with no audit trail
- Lack of visibility into intake pipeline and status

### Challenges
1. **Information Gap**: Submissions lack critical data needed for prioritization
2. **Compliance Risk**: No systematic compliance review before research begins
3. **Data Access Delays**: Data access requests not tracked or approved systematically
4. **Status Opacity**: Submitters have no visibility into approval status
5. **Duplicate Effort**: No mechanism to detect duplicate or similar strategies

### Success Criteria
- 100% of submissions include mandatory fields (hypothesis, data sources, risk profile, owner)
- Compliance review completed within 2 business days (SLA)
- Data access approval completed within 3 business days (SLA)
- Zero submissions reaching "Discover" phase without compliance sign-off
- All submissions visible in lifecycle dashboard with current status

---

## 3. Solution Architecture

### 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Strategy Researcher                          │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                 Intake Form (YAML/JSON Schema)                   │
│  Fields: hypothesis, data_sources, alpha_horizon, risk_profile, │
│          owner, expected_returns, constraints, etc.              │
└─────────────────┬───────────────────────────────────────────────┘
                  │ Submit
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│              Intake Validation & Storage                         │
│  - Schema validation (required fields, data types)               │
│  - Duplicate detection (similarity check vs. existing)           │
│  - Generate unique strategy_id                                   │
│  - Store in: documentation/research/strategies/<id>/intake.yaml  │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│              Workflow Orchestration                              │
│  State Machine: submitted → compliance_review →                  │
│                 data_access_review → approved → discover         │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ├──────────────────────┬──────────────────────┐
                  ▼                      ▼                      ▼
┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│ Compliance Review    │  │ Data Access Review   │  │ Lifecycle Dashboard  │
│ - Risk assessment    │  │ - Data availability  │  │ - Status tracking    │
│ - Regulatory check   │  │ - Access approval    │  │ - Owner assignment   │
│ - Audit trail        │  │ - Cost estimation    │  │ - SLA monitoring     │
└──────────────────────┘  └──────────────────────┘  └──────────────────────┘
```

### 3.2 Data Flow

1. **Submission**: Researcher fills intake form (CLI, web UI, or YAML file)
2. **Validation**: Schema validation ensures all required fields present
3. **Storage**: Intake stored as `documentation/research/strategies/<strategy_id>/intake.yaml`
4. **Workflow Trigger**: State machine initialized with status = "submitted"
5. **Compliance Review**: Automated notification to compliance team, awaiting approval
6. **Data Access Review**: Automated notification to data engineering, awaiting approval
7. **Dashboard Update**: Lifecycle dashboard updated with status = "discover"
8. **Notification**: Researcher notified of approval and next steps

---

## 4. Data Model

### 4.1 Intake Form Schema

```yaml
# Schema: intake_form_schema_v1.yaml

strategy_intake:
  metadata:
    schema_version: "1.0.0"
    strategy_id: string  # Auto-generated: STRAT-YYYYMMDD-<seq>
    submission_date: datetime  # ISO-8601 format
    submission_type: enum [new, revision]  # new strategy or revision to existing

  # MANDATORY FIELDS
  required:
    # Strategy Identity
    strategy_name: string  # Human-readable name (max 100 chars)
    strategy_owner: string  # Email or user ID
    strategy_hypothesis: string  # Min 100 chars, max 2000 chars

    # Asset Universe & Data
    asset_universe:
      asset_class: enum [equity, options, futures, forex, fixed_income, multi_asset]
      instruments: list[string]  # Specific tickers or instrument patterns
      markets: list[string]  # e.g., ["NSE", "BSE", "CME"]

    data_sources:
      required_datasets: list[string]  # e.g., ["NSE_OPTIONS_EOD", "SPOT_INTRADAY"]
      external_vendors: list[string]  # e.g., ["Bloomberg", "Reuters"] (empty if none)
      data_frequency: enum [tick, 1min, 5min, 1hour, daily, weekly]
      historical_lookback: string  # e.g., "2 years", "6 months"

    # Alpha & Returns
    alpha_horizon: enum [intraday, daily, weekly, monthly, quarterly]
    expected_return_annual_pct: float  # Expected annualized return (%)
    expected_sharpe_ratio: float  # Target Sharpe ratio

    # Risk Profile
    risk_profile:
      max_drawdown_pct: float  # Maximum acceptable drawdown (%)
      max_leverage: float  # Maximum leverage (1.0 = no leverage)
      position_sizing: string  # Brief description of position sizing approach
      stop_loss_strategy: string  # Description of stop-loss approach

    # Business Context
    business_justification: string  # Why this strategy? (min 50 chars)
    target_capital_usd: float  # Initial capital allocation target

  # OPTIONAL FIELDS
  optional:
    related_strategies: list[string]  # IDs of similar/related strategies
    research_references: list[string]  # Papers, articles, internal docs
    regulatory_constraints: string  # Any known regulatory constraints
    execution_constraints: string  # Liquidity, slippage, latency requirements
    technology_requirements: string  # Special tech needs (GPU, low-latency, etc.)
    target_launch_date: date  # Desired launch date (YYYY-MM-DD)

  # SYSTEM FIELDS (auto-populated)
  system:
    intake_id: string  # Unique intake identifier
    workflow_status: enum [submitted, compliance_review, data_access_review, approved, rejected, discover]
    created_at: datetime
    updated_at: datetime
    compliance_reviewer: string  # User ID who reviewed (null if pending)
    compliance_approval_date: datetime  # null if pending
    data_access_reviewer: string  # User ID who reviewed (null if pending)
    data_access_approval_date: datetime  # null if pending
    rejection_reason: string  # null if approved or pending
    lifecycle_dashboard_id: string  # ID in lifecycle dashboard (null until approved)
```

### 4.2 Validation Rules

```python
# Validation rules enforced by intake processor

class IntakeValidationRules:
    """Validation rules for strategy intake form."""

    REQUIRED_FIELDS = [
        "strategy_name",
        "strategy_owner",
        "strategy_hypothesis",
        "asset_universe",
        "data_sources",
        "alpha_horizon",
        "expected_return_annual_pct",
        "expected_sharpe_ratio",
        "risk_profile",
        "business_justification",
        "target_capital_usd",
    ]

    FIELD_CONSTRAINTS = {
        "strategy_name": {"min_length": 10, "max_length": 100},
        "strategy_hypothesis": {"min_length": 100, "max_length": 2000},
        "business_justification": {"min_length": 50, "max_length": 1000},
        "expected_return_annual_pct": {"min": -100, "max": 1000},  # Sanity bounds
        "expected_sharpe_ratio": {"min": -5, "max": 10},  # Sanity bounds
        "risk_profile.max_drawdown_pct": {"min": 0, "max": 100},
        "risk_profile.max_leverage": {"min": 1.0, "max": 10.0},
        "target_capital_usd": {"min": 1000, "max": 100_000_000},  # $1K to $100M
    }

    ENUM_VALUES = {
        "asset_universe.asset_class": [
            "equity", "options", "futures", "forex", "fixed_income", "multi_asset"
        ],
        "data_sources.data_frequency": [
            "tick", "1min", "5min", "1hour", "daily", "weekly"
        ],
        "alpha_horizon": ["intraday", "daily", "weekly", "monthly", "quarterly"],
        "workflow_status": [
            "submitted", "compliance_review", "data_access_review",
            "approved", "rejected", "discover"
        ],
    }

    # Duplicate detection: Check similarity of hypothesis text
    DUPLICATE_THRESHOLD_COSINE_SIMILARITY = 0.85  # 85% similarity → flag as potential duplicate
```

---

## 5. Workflow State Machine

### 5.1 States & Transitions

```
┌──────────────┐
│  SUBMITTED   │  ← Initial state after validation
└──────┬───────┘
       │ auto-trigger
       ▼
┌──────────────────────┐
│ COMPLIANCE_REVIEW    │  ← Awaiting compliance team review
└──────┬───────┬───────┘
       │       │
       │       └─────── rejected → REJECTED (terminal state)
       │ approved
       ▼
┌──────────────────────┐
│ DATA_ACCESS_REVIEW   │  ← Awaiting data engineering review
└──────┬───────┬───────┘
       │       │
       │       └─────── rejected → REJECTED (terminal state)
       │ approved
       ▼
┌──────────────┐
│   APPROVED   │  ← Both reviews complete
└──────┬───────┘
       │ auto-create dashboard entry
       ▼
┌──────────────┐
│   DISCOVER   │  ← Visible in lifecycle dashboard, ready for research
└──────────────┘
```

### 5.2 State Definitions

| State | Description | SLA | Next States | Owners |
|-------|-------------|-----|-------------|--------|
| `submitted` | Intake form validated and stored | Immediate | `compliance_review` | System |
| `compliance_review` | Awaiting compliance approval | 2 business days | `data_access_review`, `rejected` | Compliance Team |
| `data_access_review` | Awaiting data access approval | 3 business days | `approved`, `rejected` | Data Engineering |
| `approved` | All reviews complete | Immediate | `discover` | System |
| `rejected` | Submission rejected (terminal) | N/A | None | Compliance/Data Eng |
| `discover` | Active in lifecycle dashboard | N/A | (Next phase in lifecycle) | Strategy Ops |

### 5.3 Transition Rules

```python
class WorkflowTransitions:
    """State machine transitions for intake workflow."""

    ALLOWED_TRANSITIONS = {
        "submitted": ["compliance_review"],
        "compliance_review": ["data_access_review", "rejected"],
        "data_access_review": ["approved", "rejected"],
        "approved": ["discover"],
        "rejected": [],  # Terminal state
        "discover": [],  # Handed off to next phase
    }

    AUTO_TRANSITIONS = {
        "submitted": "compliance_review",  # Auto-trigger on submission
        "approved": "discover",  # Auto-create dashboard entry
    }

    APPROVAL_REQUIRED = {
        "compliance_review": {
            "approver_role": "compliance_officer",
            "approval_fields": ["compliance_reviewer", "compliance_approval_date"],
            "rejection_field": "rejection_reason",
        },
        "data_access_review": {
            "approver_role": "data_engineer",
            "approval_fields": ["data_access_reviewer", "data_access_approval_date"],
            "rejection_field": "rejection_reason",
        },
    }
```

---

## 6. Implementation Components

### 6.1 Core Components

#### 6.1.1 Intake Form Processor (`intake_processor.py`)
```python
# Location: src/strategy_lifecycle/intake/intake_processor.py

class IntakeProcessor:
    """Processes strategy intake submissions."""

    def validate_intake(self, intake_data: dict) -> ValidationResult:
        """Validate intake form against schema."""
        pass

    def check_duplicates(self, hypothesis: str) -> List[str]:
        """Check for similar existing strategies."""
        pass

    def generate_strategy_id(self) -> str:
        """Generate unique strategy ID: STRAT-YYYYMMDD-<seq>."""
        pass

    def save_intake(self, intake_data: dict, strategy_id: str) -> Path:
        """Save intake to documentation/research/strategies/<id>/intake.yaml."""
        pass

    def trigger_workflow(self, strategy_id: str) -> WorkflowInstance:
        """Initialize workflow state machine."""
        pass
```

#### 6.1.2 Workflow Engine (`workflow_engine.py`)
```python
# Location: src/strategy_lifecycle/intake/workflow_engine.py

class WorkflowEngine:
    """Manages intake workflow state machine."""

    def transition_state(
        self,
        strategy_id: str,
        from_state: str,
        to_state: str,
        approver: Optional[str] = None,
        reason: Optional[str] = None
    ) -> WorkflowState:
        """Transition workflow to new state."""
        pass

    def get_current_state(self, strategy_id: str) -> WorkflowState:
        """Get current workflow state."""
        pass

    def approve(self, strategy_id: str, approver: str) -> WorkflowState:
        """Approve current review step."""
        pass

    def reject(self, strategy_id: str, approver: str, reason: str) -> WorkflowState:
        """Reject submission."""
        pass

    def check_sla_breach(self, strategy_id: str) -> Optional[SLABreach]:
        """Check if SLA has been breached."""
        pass
```

#### 6.1.3 Dashboard Integration (`dashboard_connector.py`)
```python
# Location: src/strategy_lifecycle/intake/dashboard_connector.py

class DashboardConnector:
    """Integrates with lifecycle dashboard."""

    def create_dashboard_entry(self, strategy_id: str) -> str:
        """Create entry in lifecycle dashboard, return dashboard_id."""
        pass

    def update_status(self, dashboard_id: str, status: str) -> None:
        """Update status in dashboard."""
        pass

    def get_all_submissions(self, status_filter: Optional[str] = None) -> List[dict]:
        """Retrieve all submissions from dashboard."""
        pass
```

#### 6.1.4 CLI Interface (`intake_cli.py`)
```python
# Location: src/strategy_lifecycle/cli/intake_cli.py

class IntakeCLI:
    """Command-line interface for intake workflow."""

    def submit_intake(self, intake_file: Path) -> str:
        """Submit intake from YAML file."""
        pass

    def review_intake(self, strategy_id: str, action: str, reason: Optional[str]) -> None:
        """Review (approve/reject) an intake submission."""
        pass

    def check_status(self, strategy_id: str) -> dict:
        """Check status of intake submission."""
        pass

    def list_pending_reviews(self, review_type: str) -> List[dict]:
        """List all pending reviews (compliance or data_access)."""
        pass
```

### 6.2 Directory Structure

```
documentation/research/strategies/
├── STRAT-20251119-001/
│   ├── intake.yaml              # Intake form data
│   ├── workflow_state.yaml      # Current workflow state
│   ├── compliance_review.yaml   # Compliance review details (if completed)
│   ├── data_access_review.yaml  # Data access review details (if completed)
│   └── README.md                # Auto-generated summary

src/strategy_lifecycle/
├── intake/
│   ├── __init__.py
│   ├── intake_processor.py      # Intake validation and processing
│   ├── workflow_engine.py       # State machine implementation
│   ├── dashboard_connector.py   # Dashboard integration
│   └── schemas/
│       └── intake_schema_v1.yaml
├── cli/
│   └── intake_cli.py            # CLI commands
└── tests/
    ├── unit/
    │   ├── test_intake_processor.py
    │   ├── test_workflow_engine.py
    │   └── test_dashboard_connector.py
    └── integration/
        └── test_intake_workflow_e2e.py
```

---

## 7. Integration Points

### 7.1 Lifecycle Dashboard
- **Type**: External tool (Jira/Notion/Custom)
- **Integration**: REST API or file-based sync
- **Data Flow**: Approved intakes automatically create dashboard tickets
- **Status Updates**: Bidirectional sync of status changes

### 7.2 Compliance System
- **Type**: Manual review process (future: automated risk scoring)
- **Integration**: Email notifications + CLI review commands
- **SLA Monitoring**: Automated alerts if review SLA breached

### 7.3 Data Access Control
- **Type**: Manual approval process
- **Integration**: Email notifications + CLI review commands
- **Access Tracking**: Approved data sources recorded for downstream use

### 7.4 Knowledge Vault
- **Type**: Obsidian vault with strategy documentation
- **Integration**: File system (intakes stored as YAML in vault)
- **Linking**: Backlinks to Epic/Feature/Story artifacts

---

## 8. Testing Strategy

### 8.1 Unit Tests

**Test Coverage Targets**: ≥90% for all components

```python
# tests/unit/test_intake_processor.py

def test_validate_intake_all_required_fields_present():
    """Test validation passes when all required fields present."""

def test_validate_intake_missing_required_field():
    """Test validation fails when required field missing."""

def test_validate_intake_field_constraints():
    """Test field constraint validation (min/max length, ranges)."""

def test_generate_strategy_id_uniqueness():
    """Test strategy ID generation is unique."""

def test_check_duplicates_high_similarity():
    """Test duplicate detection flags similar hypotheses."""

def test_save_intake_creates_correct_directory_structure():
    """Test intake saved to correct file path."""
```

```python
# tests/unit/test_workflow_engine.py

def test_transition_state_allowed():
    """Test state transition succeeds when allowed."""

def test_transition_state_not_allowed():
    """Test state transition fails when not allowed."""

def test_auto_transition_after_submission():
    """Test auto-transition from submitted → compliance_review."""

def test_approve_compliance_review():
    """Test compliance approval transitions to data_access_review."""

def test_reject_compliance_review():
    """Test compliance rejection transitions to rejected."""

def test_sla_breach_detection():
    """Test SLA breach detection for pending reviews."""
```

### 8.2 Integration Tests

```python
# tests/integration/test_intake_workflow_e2e.py

def test_full_intake_workflow_approval():
    """
    End-to-end test: submission → compliance approval →
    data access approval → dashboard entry creation.
    """

def test_full_intake_workflow_rejection_at_compliance():
    """Test rejection during compliance review."""

def test_duplicate_detection_prevents_duplicate_submission():
    """Test duplicate submission is flagged."""

def test_sla_breach_triggers_alert():
    """Test SLA breach triggers notification."""
```

### 8.3 Contract Tests

```python
# tests/contract/test_dashboard_connector.py

def test_dashboard_connector_create_entry_contract():
    """Test dashboard connector creates entry with expected fields."""

def test_dashboard_connector_update_status_contract():
    """Test status update follows expected contract."""
```

---

## 9. Documentation & SLA

### 9.1 Intake Guide

**Location**: `documentation/vault_product_templates/STRATEGY_INTAKE_GUIDE.md`

**Contents**:
- How to submit an intake (CLI, web form, YAML template)
- Required vs. optional fields explanation
- Field value examples and best practices
- Submission checklist
- SLA expectations (response times)
- Contact points for questions

### 9.2 SLA Definitions

| Process Step | SLA | Escalation |
|--------------|-----|------------|
| Intake submission validation | Immediate | N/A |
| Compliance review | 2 business days | Escalate to Compliance Lead after 3 days |
| Data access review | 3 business days | Escalate to Data Eng Lead after 5 days |
| Dashboard entry creation | Immediate (automated) | N/A |
| Overall intake-to-discover | 5 business days | Escalate to Strategy Ops Lead after 7 days |

### 9.3 Audit Trail

All state transitions recorded in `workflow_state.yaml`:

```yaml
history:
  - timestamp: 2025-11-19T10:00:00Z
    from_state: null
    to_state: submitted
    actor: researcher@example.com

  - timestamp: 2025-11-19T14:30:00Z
    from_state: submitted
    to_state: compliance_review
    actor: system

  - timestamp: 2025-11-20T09:15:00Z
    from_state: compliance_review
    to_state: data_access_review
    actor: compliance_officer@example.com
    notes: "Approved - no regulatory concerns"

  - timestamp: 2025-11-21T11:00:00Z
    from_state: data_access_review
    to_state: approved
    actor: data_engineer@example.com
    notes: "All data sources available - approved"

  - timestamp: 2025-11-21T11:01:00Z
    from_state: approved
    to_state: discover
    actor: system
    dashboard_id: LIFECYCLE-12345
```

---

## 10. Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| SLA breaches due to reviewer workload | Medium | Medium | Automated SLA monitoring + escalation alerts |
| Duplicate strategies not detected | Low | Low | Implement NLP-based similarity scoring |
| Compliance requirements change | High | Low | Versioned schema allows migration path |
| Dashboard integration breaks | Medium | Low | Fallback to manual dashboard entry |
| Missing required fields slip through | Low | Low | Comprehensive validation tests (≥90% coverage) |

---

## 11. Future Enhancements

### Phase 2 (Post-MVP)
- [ ] Web UI for intake form submission (currently CLI-only)
- [ ] Automated compliance risk scoring (ML model)
- [ ] Integration with external compliance systems
- [ ] Advanced duplicate detection (semantic similarity)
- [ ] Real-time dashboard updates (WebSocket)

### Phase 3 (Future)
- [ ] Multi-tenant support (team-based intake)
- [ ] Strategy recommendation engine (suggest similar strategies)
- [ ] Integration with capital allocation system
- [ ] Automated data cost estimation

---

## 12. Appendices

### Appendix A: Sample Intake Form

See: `documentation/vault_product_templates/SAMPLE_INTAKE_FORM.yaml`

### Appendix B: CLI Usage Examples

```bash
# Submit intake
python -m src.strategy_lifecycle.cli.intake_cli submit \
  --intake-file documentation/research/strategies/my_strategy_intake.yaml

# Check status
python -m src.strategy_lifecycle.cli.intake_cli status \
  --strategy-id STRAT-20251119-001

# Approve compliance review
python -m src.strategy_lifecycle.cli.intake_cli review \
  --strategy-id STRAT-20251119-001 \
  --action approve \
  --reviewer compliance_officer@example.com

# List pending compliance reviews
python -m src.strategy_lifecycle.cli.intake_cli list-pending \
  --review-type compliance
```

### Appendix C: Dashboard Integration Schema

```json
{
  "dashboard_entry": {
    "id": "LIFECYCLE-12345",
    "strategy_id": "STRAT-20251119-001",
    "strategy_name": "Mean Reversion NSE Options",
    "owner": "researcher@example.com",
    "status": "discover",
    "submission_date": "2025-11-19T10:00:00Z",
    "compliance_approved_date": "2025-11-20T09:15:00Z",
    "data_access_approved_date": "2025-11-21T11:00:00Z",
    "alpha_horizon": "daily",
    "asset_class": "options",
    "target_capital_usd": 100000,
    "expected_sharpe_ratio": 1.8,
    "tags": ["options", "mean_reversion", "nse"]
  }
}
```

---

## 13. Approval & Sign-Off

| Role | Name | Approval Status | Date |
|------|------|-----------------|------|
| Strategy Operations Lead | TBD | Pending | - |
| Compliance Officer | TBD | Pending | - |
| Data Engineering Lead | TBD | Pending | - |
| Engineering Lead | TBD | Pending | - |

---

## Document Control

- **Version**: 0.1.0 (Draft)
- **Created**: 2025-11-19
- **Last Updated**: 2025-11-19
- **Next Review**: 2025-11-22 (3 days after creation)
- **Approval Required**: Yes (G1 Gate)
- **Status**: 📝 Draft (awaiting review)
