---
guide_id: VAULT-GUIDE-003
title: "Issue Management Guide"
version: "1.0"
status: "active"
created_at: "2025-11-16"
category: "workflow"
tags: ["issues", "bugs", "workflow"]
---

# Issue Management Guide - SynapticTrading Vault

**UPMS Reference**: [Issue Management Pattern](/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/Methodology/Issue_Management_Pattern.md)

---

## Quick Start

### When to Create an Issue

Create an issue when you encounter:
- **Bug**: Code doesn't work as expected
- **Backtest Anomaly**: Suspicious backtest results
- **Performance Problem**: System is slow
- **Data Quality Issue**: Missing or incorrect data
- **Enhancement Idea**: Feature improvement suggestion

### How to Create an Issue

1. **Navigate to templates**:
   ```bash
   cd /Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault/issues/templates
   ```

2. **Choose template**:
   - `bug_template.md` - For bugs and errors
   - `backtest_issue_template.md` - For backtest-specific issues
   - `performance_template.md` - For performance problems
   - `enhancement_template.md` - For feature requests

3. **Copy template**:
   ```bash
   cp templates/bug_template.md identified/20251116_143000_my_issue_description.md
   ```

4. **Fill out the template**:
   - Use your text editor
   - Complete all sections
   - Be specific and provide evidence

5. **Update STATUS.md** (optional but recommended):
   - Add issue to tracking list
   - Update metrics

---

## Issue Directory Structure

```
/issues/
├── README.md                          # Issue workflow guide
├── STATUS.md                          # Current status summary
│
├── identified/                        # New issues (not yet started)
│   └── 20251116_HHMMSS_description.md
│
├── wip/                               # In progress
│   └── 20251116_HHMMSS_description.md
│
├── resolved/                          # Fixed and verified
│   └── 20251116_HHMMSS_description.md
│
├── enhancements/                      # Feature requests
│   └── 20251116_HHMMSS_enhancement.md
│
├── templates/                         # Issue templates
│   ├── bug_template.md
│   ├── backtest_issue_template.md
│   ├── performance_template.md
│   └── enhancement_template.md
│
├── sprint_summaries/                  # Sprint retrospectives
│   └── SPRINT_NN_SUMMARY.md
│
└── archive/                           # Obsolete issues
    └── 20251116_HHMMSS_obsolete.md
```

---

## Issue Lifecycle Workflow

### 1. Identification Phase

**Location**: `identified/`

When you discover a bug or have an enhancement idea:

```bash
# 1. Copy appropriate template
cp templates/bug_template.md identified/$(date +%Y%m%d_%H%M%S)_stop_loss_not_triggering.md

# 2. Edit the file
vim identified/20251116_143000_stop_loss_not_triggering.md

# 3. Fill all sections:
#    - Summary
#    - Evidence (logs, backtest results)
#    - Reproduction steps
#    - Root cause analysis
#    - Impact assessment
```

**Required Information**:
- Clear title
- Severity (CRITICAL/HIGH/MEDIUM/LOW)
- Component affected
- Evidence (error messages, logs, screenshots)
- Steps to reproduce
- Expected vs actual behavior

### 2. Work-in-Progress Phase

**Location**: `wip/`

When you start working on an issue:

```bash
# Move from identified to wip
mv identified/20251116_143000_stop_loss_not_triggering.md wip/

# Update status in the file to "In Progress"
```

**During Work**:
1. Update the "Implementation" section
2. List files being modified
3. Document approach
4. Run tests
5. Update progress

### 3. Resolution Phase

**Location**: `resolved/`

When issue is fixed and verified:

```bash
# Move from wip to resolved
mv wip/20251116_143000_stop_loss_not_triggering.md resolved/

# Update status in the file to "Resolved"
# Fill the "Resolution" section
```

**Resolution Requirements**:
- [ ] Fix implemented
- [ ] Tests pass (unit, integration, backtest)
- [ ] Code reviewed (if applicable)
- [ ] Deployed/merged
- [ ] Verification completed
- [ ] Documentation updated

**Resolution Section Must Include**:
- Resolved date
- Summary of fix
- Files changed
- Testing performed (backtest before/after)
- Git commits
- Verification method

---

## Trading-Specific Issue Types

### 1. Strategy Logic Issues

**Example**: Stop loss not triggering correctly

**Template**: `bug_template.md`

**Critical Information**:
- Which strategy? (STRAT-001, STRAT-002, etc.)
- Which instruments?
- What timeframe?
- Market conditions when it failed
- P&L impact

**Testing Required**:
- Unit tests for logic
- Backtest validation
- Paper trading verification

### 2. Backtest Issues

**Example**: Unrealistic P&L in backtest

**Template**: `backtest_issue_template.md`

**Critical Information**:
- Backtest configuration (dates, capital, position size)
- Expected vs actual results
- Suspicious patterns
- Data quality checks

**Common Backtest Issues**:
- Look-ahead bias
- Incorrect fill prices
- Missing slippage/commission
- P&L calculation errors
- Stop loss/take profit logic

**Validation**:
- Re-run with fix
- Compare with manual calculation
- Verify against live trading data (if available)

### 3. Performance Issues

**Example**: Backtest takes 45 seconds instead of 10 seconds

**Template**: `performance_template.md`

**Critical Information**:
- Performance metrics (current vs baseline)
- Profiling data showing bottleneck
- System resources (CPU, memory, disk)

**Common Performance Bottlenecks**:
- N+1 query problems
- Missing database indexes
- Inefficient algorithms
- Unnecessary data loading
- No caching

**Validation**:
- Benchmark before/after
- Profiling comparison
- Load testing

### 4. Data Quality Issues

**Example**: Missing bars in data feed

**Template**: `bug_template.md`

**Critical Information**:
- Data source
- Symbol/instrument affected
- Date range affected
- Impact on strategies

**Validation**:
- Data integrity checks
- Comparison with alternate source
- Backtest re-run with corrected data

---

## Severity Guidelines for Trading

### CRITICAL (P0)
**Definition**: Trading cannot proceed, financial risk
**Examples**:
- Live trading system down
- Risk management not working (stop losses not firing)
- Data corruption affecting positions
- Order execution failures
**Action**: Drop everything, fix immediately
**Timeline**: <1 hour

### HIGH (P1)
**Definition**: Core strategy logic broken
**Examples**:
- Entry/exit signals incorrect
- Position sizing wrong
- P&L calculation error
- Backtest producing wrong results
**Action**: Fix within 24 hours
**Timeline**: Same day

### MEDIUM (P2)
**Definition**: Feature degraded but system functional
**Examples**:
- Performance degradation (2x slower)
- UI display issue
- Reporting error
- Non-critical metric calculation
**Action**: Fix within 1 week
**Timeline**: Next sprint

### LOW (P3)
**Definition**: Enhancement or minor issue
**Examples**:
- UI cosmetic issue
- Code cleanup
- Documentation improvement
- Nice-to-have feature
**Action**: Fix when convenient
**Timeline**: Backlog

---

## Integration with UPMS Stories

### Issues vs Stories

**Stories**: Planned work (known requirements)
- "As a trader, I want to see real-time P&L..."
- Estimated in advance
- Part of sprint planning

**Issues**: Unplanned work (discovered problems)
- "Stop loss not triggering in backtest"
- Discovered during development/testing
- May create additional tasks

### Linking Issues to Stories

When an issue is discovered during story implementation:

**In Issue File**:
```markdown
**Related Story**: STORY-005-02 (Risk Management Implementation)
```

**In Story File** (`Stories/STORY-005-02.md`):
```markdown
## Issues Discovered
- [ISSUE-20251116-143000](../../../issues/identified/20251116_143000_stop_loss_not_triggering.md) - Stop loss logic bug
```

### When Issues Block Stories

If an issue prevents story completion:

1. Mark story as "Blocked" in story metadata
2. Link issue in story's blockers section
3. Update sprint plan
4. Consider story carryover to next sprint

**Example** in Story file:
```markdown
---
status: "blocked"
blockers:
  - type: "bug"
    issue: "issues/identified/20251116_143000_stop_loss_not_triggering.md"
    blocked_since: "2025-11-16"
---
```

---

## Best Practices

### For Bug Reports

1. **Be Specific**:
   - ❌ "Backtest not working"
   - ✅ "Backtest shows -₹50,000 P&L when manual calculation shows +₹10,000"

2. **Provide Evidence**:
   - Include error messages (full stack trace)
   - Attach backtest output
   - Include screenshots of charts/positions
   - Provide logs with timestamps

3. **Include Reproduction Steps**:
   - List exact steps to reproduce
   - Include configuration used
   - Note if it happens always or sometimes

4. **Analyze Root Cause**:
   - Don't just describe symptoms
   - Investigate why it happens
   - Identify affected code/components

### For Performance Issues

1. **Benchmark First**:
   - Measure current performance
   - Compare to baseline or expected
   - Use profiler to identify bottleneck

2. **Quantify Impact**:
   - How much slower?
   - Which operations affected?
   - User/system impact

3. **Propose Solution**:
   - What optimization technique?
   - Expected improvement
   - Risks/tradeoffs

### For Backtest Issues

1. **Validate Assumptions**:
   - Check data quality first
   - Verify configuration settings
   - Compare with manual calculation

2. **Look for Common Issues**:
   - Look-ahead bias
   - Fill price assumptions
   - Slippage/commission
   - Stop loss logic

3. **Document Comparison**:
   - Before fix backtest results
   - After fix backtest results
   - Explanation of difference

---

## Common Workflows

### Workflow 1: Found Bug During Development

```bash
# 1. Immediately create issue
cp templates/bug_template.md identified/$(date +%Y%m%d_%H%M%S)_description.md

# 2. Fill out template with evidence
vim identified/20251116_143000_description.md

# 3. If blocking your work, move to WIP immediately
mv identified/20251116_143000_description.md wip/

# 4. Fix the bug
# ... make code changes ...

# 5. Test thoroughly
pytest tests/
python backtest_script.py --validate

# 6. Move to resolved with verification
mv wip/20251116_143000_description.md resolved/

# 7. Update resolution section in file
```

### Workflow 2: Suspicious Backtest Results

```bash
# 1. Create backtest issue
cp templates/backtest_issue_template.md identified/$(date +%Y%m%d_%H%M%S)_backtest_anomaly.md

# 2. Fill with backtest data
#    - Configuration
#    - Results (total P&L, trades, win rate)
#    - What looks suspicious

# 3. Investigate
#    - Check data quality
#    - Verify strategy logic
#    - Compare with manual calculation

# 4. If confirmed bug, move to WIP
mv identified/20251116_145000_backtest_anomaly.md wip/

# 5. Fix and re-run backtest

# 6. Document before/after comparison
#    - Before: -₹50,000
#    - After: +₹10,000
#    - Reason: Incorrect fill price calculation

# 7. Move to resolved
mv wip/20251116_145000_backtest_anomaly.md resolved/
```

### Workflow 3: Performance Optimization

```bash
# 1. Create performance issue
cp templates/performance_template.md identified/$(date +%Y%m%d_%H%M%S)_slow_backtest.md

# 2. Benchmark current performance
python -m cProfile -o backtest.prof backtest.py
python -m pstats backtest.prof  # Analyze

# 3. Document bottleneck
#    - Function taking 80% of time
#    - Inefficient algorithm (O(n²))

# 4. Move to WIP and optimize
mv identified/20251116_150000_slow_backtest.md wip/

# 5. Implement optimization
#    - Change algorithm
#    - Add caching
#    - Use vectorization

# 6. Benchmark after optimization
#    - Before: 45 seconds
#    - After: 8 seconds
#    - Speedup: 5.6x

# 7. Move to resolved with benchmarks
mv wip/20251116_150000_slow_backtest.md resolved/
```

---

## Integration with Git

### Commit Messages Referencing Issues

```bash
# Good commit message
git commit -m "Fix: Stop loss not triggering in short positions

Resolves: issues/20251116_143000_stop_loss_not_triggering.md

- Fixed logic in RiskManager.check_stop_loss()
- Added check for both long and short positions
- Added unit tests for short position stop loss

Tested:
- Unit tests pass
- Backtest shows correct stop loss triggers
- Verified with STRAT-001 on historical data
"
```

### Branch Naming

For issue fixes:
```bash
git checkout -b issue/20251116-143000-stop-loss-bug
```

For enhancements:
```bash
git checkout -b enhancement/20251116-150000-add-trailing-stop
```

---

## Tools and Automation

### Quick Issue Creation Script

Create `scripts/new_issue.sh`:

```bash
#!/bin/bash
# Quick issue creation

ISSUE_TYPE=$1  # bug, backtest, performance, enhancement
DESCRIPTION=$2

if [ -z "$ISSUE_TYPE" ] || [ -z "$DESCRIPTION" ]; then
    echo "Usage: ./new_issue.sh <type> <description>"
    echo "Types: bug, backtest, performance, enhancement"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="${TIMESTAMP}_${DESCRIPTION}.md"
TEMPLATE="templates/${ISSUE_TYPE}_template.md"

cp "$TEMPLATE" "identified/$FILENAME"
echo "Created: identified/$FILENAME"
echo "Edit with: vim identified/$FILENAME"
```

Usage:
```bash
./scripts/new_issue.sh bug stop_loss_not_triggering
./scripts/new_issue.sh backtest unrealistic_pnl
./scripts/new_issue.sh performance slow_backtest
```

### Issue Status Dashboard

Create `scripts/issue_status.sh`:

```bash
#!/bin/bash
# Display issue counts

echo "Issue Status Summary"
echo "===================="
echo "Identified: $(ls -1 identified/ | wc -l)"
echo "In Progress: $(ls -1 wip/ | wc -l)"
echo "Resolved: $(ls -1 resolved/ | wc -l)"
echo "Enhancements: $(ls -1 enhancements/ | wc -l)"
echo ""
echo "Critical Issues:"
grep -l "CRITICAL" identified/*.md wip/*.md 2>/dev/null | wc -l
```

---

## Sprint Integration

### During Sprint Planning

1. **Review identified issues**:
   - Prioritize critical/high issues
   - Estimate effort (story points or hours)
   - Assign to sprint if capacity allows

2. **Reserve capacity for issues**:
   - Allocate 20% of sprint capacity for bug fixes
   - Track separately from planned stories

3. **Link to stories**:
   - If issue discovered during story work, link them
   - If issue blocks story, mark story as blocked

### During Sprint

1. **Daily triage**:
   - Review new identified issues
   - Escalate critical issues immediately

2. **Update STATUS.md**:
   - Track resolution progress
   - Monitor issue creation rate

### Sprint Retrospective

Create sprint summary in `sprint_summaries/`:

```markdown
# Sprint N Issue Summary

**Sprint Dates**: YYYY-MM-DD to YYYY-MM-DD

## Issues Created This Sprint
- Total: N
- Critical: N
- High: N
- Medium: N
- Low: N

## Issues Resolved This Sprint
- Total: N
- By Component:
  - Strategy Logic: N
  - Backtest Engine: N
  - Performance: N

## Average Resolution Time
- Critical: X hours
- High: X days
- Medium: X days

## Patterns Observed
- [Pattern 1: e.g., Many backtest issues due to data quality]
- [Pattern 2: e.g., Performance degradation from feature additions]

## Action Items
- [ ] Improve data validation
- [ ] Add performance benchmarks
- [ ] Review backtest fill model
```

---

## References

- **UPMS Methodology**: [Issue Management Pattern](/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/Methodology/Issue_Management_Pattern.md)
- **Issue Directory**: `/issues/`
- **Templates**: `/issues/templates/`
- **Current Status**: `/issues/STATUS.md`

---

**Version**: 1.0
**Last Updated**: 2025-11-16
**Maintained By**: SynapticTrading Development Team
