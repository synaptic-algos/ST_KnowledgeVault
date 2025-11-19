# Issues Management - SynapticTrading

**UPMS Reference**: [Issue Management Pattern](/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/Methodology/Issue_Management_Pattern.md)

## Issue Workflow

```
identified/ → wip/ → resolved/
            ↓
    [categorized folders]
```

## Folder Structure

### Core Workflow Folders
- **`identified/`** - Newly identified bugs/issues (not yet started)
- **`wip/`** - Issues currently being worked on
- **`resolved/`** - Successfully resolved and verified issues

### Category Folders (Organized by Type)
- **`enhancements/`** - Feature requests and enhancement proposals
- **`templates/`** - Issue templates for consistency
- **`sprint_summaries/`** - Sprint retrospectives and issue summaries
- **`archive/`** - Deprecated or obsolete issues

## Issue Lifecycle

### Phase 1: Issue Creation (`identified/`)

**When to Create an Issue**:
- Bug found during development or testing
- Performance degradation detected
- Integration failure
- Backtest discrepancy
- Production anomaly
- Enhancement idea

**How to Create**:
1. **Choose Template**: Select from `templates/` based on issue type:
   - `bug_template.md` - Bugs, errors, incorrect behavior
   - `enhancement_template.md` - Feature requests, improvements
   - `performance_template.md` - Performance bottlenecks, optimization
   - `backtest_issue_template.md` - Backtest-specific issues

2. **Create File**: Use naming convention `YYYYMMDD_HHMMSS_short_description.md`
   ```bash
   cp templates/bug_template.md identified/20251116_HHMMSS_description.md
   ```

3. **Fill Template**: Complete all sections:
   - **Title**: Clear, specific description
   - **Status**: Set to "Identified"
   - **Severity**: CRITICAL/HIGH/MEDIUM/LOW based on impact
   - **Related Story/Feature**: Link to EPIC/Feature/Story if applicable
   - **Description**: Detailed explanation of the problem
   - **Evidence**: Logs, backtest results, error messages, screenshots
   - **Root Cause Analysis**: Initial investigation findings

### Phase 2: Active Work (`wip/`)

1. **Move to WIP**:
   ```bash
   mv identified/20251116_HHMMSS_description.md wip/
   ```

2. **Update Status**: Change status to "In Progress"

3. **Document Implementation**:
   - Add "Implementation" section to issue
   - List files being modified
   - Document code changes with line numbers
   - Link to related tasks in stories

### Phase 3: Resolution (`resolved/`)

1. **Move to Resolved**:
   ```bash
   mv wip/20251116_HHMMSS_description.md resolved/
   ```

2. **Update Resolution Details**:
   - Change status to "Resolved"
   - Add "Resolution" section with:
     - Date resolved
     - Summary of fix
     - Files changed
     - Validation/testing performed (backtest results)
   - Link to git commits if applicable

## Connection to UPMS Structure

Issues are connected to the UPMS hierarchy:

```
EPIC → Feature → Story → Tasks
                    ↓
                 Issues (bugs found during implementation)
```

### Integration with Trading System Development

For SynapticTrading, issues often relate to:
- **Strategy Issues**: Logic bugs in trading strategies
- **Backtest Issues**: Discrepancies in historical testing
- **Performance Issues**: Slow execution, memory leaks
- **Integration Issues**: Broker API, data feed problems
- **Risk Management Issues**: Stop loss, position sizing bugs

**Link to Stories**:
- Identified Issues → May create new tasks within existing stories
- Enhancement Issues → May become new features or stories
- Critical Issues → May block story/sprint completion

## Naming Convention

`YYYYMMDD_HHMMSS_short_description.md`

Examples:
- `20251116_180000_stop_loss_not_triggering.md`
- `20251116_181500_backtest_pnl_calculation_error.md`
- `20251116_183000_duplicate_order_execution.md`

## Priority Levels

- **CRITICAL**: Trading logic broken, risk management failure, data corruption - fix immediately
- **HIGH**: Major feature broken, performance degraded >50%, fix within 1 day
- **MEDIUM**: Important but workaround exists, fix within 1 week
- **LOW**: Minor issue, cosmetic, fix when convenient

## Severity Levels (Trading-Specific)

- **P0 - Trading Halt**: System cannot trade, immediate financial risk
- **P1 - Strategy Broken**: Core strategy logic incorrect
- **P2 - Performance**: Degraded performance, still functional
- **P3 - Enhancement**: Improvement, not a bug

## Status Values

- **Identified**: Issue documented, not yet started
- **In Progress**: Actively being worked on
- **Resolved**: Fixed and verified with backtest/testing
- **Archived**: No longer relevant or obsolete

## Testing Requirements

All resolved issues MUST include:
- **Unit Tests**: If applicable
- **Integration Tests**: If applicable
- **Backtest Validation**: For trading logic issues
- **Production Verification**: For deployed fixes

---

**Created**: 2025-11-16
**Purpose**: Track bugs, issues, and enhancements during SynapticTrading development
**Vault Guide**: [SynapticTrading Vault Guide](../VaultGuide/README.md)
