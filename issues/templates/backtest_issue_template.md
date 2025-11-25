---
artifact_type: story
created_at: '2025-11-25T16:23:21.560696Z'
id: AUTO-backtest_issue_template
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for backtest_issue_template
updated_at: '2025-11-25T16:23:21.560699Z'
---

## Backtest Configuration

**Strategy**: [Strategy name]
**Instrument**: [Symbol/Contract]
**Timeframe**: [1min, 5min, 1day, etc.]
**Date Range**: [Start date - End date]
**Capital**: ₹[amount]
**Position Size**: [Shares/Contracts]

---

## Evidence

### Backtest Output
```
[Paste backtest summary]
- Total Trades:
- Win Rate:
- P&L:
- Max Drawdown:
```

### Suspicious Patterns
[Describe what looks wrong in the backtest results]

### Logs
```
[Relevant backtest log excerpts showing the issue]
```

### Charts/Screenshots
[Attach charts showing entry/exit points, P&L curves, etc.]

---

## Reproduction Steps

1. Run backtest with configuration: [paste config]
2. Observe: [what happens]
3. Expected: [what should happen]

**Reproduction Rate**: [Always | Sometimes | Specific dates only]

---

## Root Cause Analysis

### The Problem
[Detailed explanation of what's wrong in the backtest]

### Why This Happens
[Technical root cause - data issue, fill model, calculation error, etc.]

### Common Backtest Issues to Check
- [ ] Look-ahead bias (using future data)
- [ ] Incorrect fill prices (using close instead of next bar open)
- [ ] Missing slippage/commission
- [ ] Incorrect position sizing
- [ ] P&L calculation error
- [ ] Stop loss/take profit logic
- [ ] Data quality (gaps, splits, dividends)

### Affected Components
- File: `path/to/file.py:line_number`
- Data Source: [Where does the data come from?]
- Fill Model: [What fill model is used?]

---

## Impact

1. **Backtest Reliability**: [Can we trust backtest results?]
2. **Strategy Viability**: [Does this affect go-live decision?]
3. **Historical Comparison**: [Are previous backtests also affected?]

---

## Proposed Solution

### Approach
[Describe the fix]

### Validation Plan
1. Re-run backtest with fix applied
2. Compare with manual trade-by-trade analysis
3. Verify against live trading data (if available)

### Files to Modify
1. `path/to/file1.py` - [What to change]
2. `path/to/file2.py` - [What to change]

---

## Implementation
[To be filled when work starts]

### Changes Made
1. File: `path/to/file.py`
   - Line X: [Change description]

### Backtest Comparison

**Before Fix**:
```
Backtest Period: [dates]
Total Trades: [N]
Win Rate: [X%]
Total P&L: ₹[amount]
Max Drawdown: [X%]
Sharpe Ratio: [value]
```

**After Fix**:
```
Backtest Period: [dates]
Total Trades: [N]
Win Rate: [X%]
Total P&L: ₹[amount]
Max Drawdown: [X%]
Sharpe Ratio: [value]
```

**Difference Analysis**:
- P&L Change: ₹[amount] ([reason])
- Trade Count Change: [N trades] ([reason])
- Win Rate Change: [X%] ([reason])

---

## Resolution
[To be filled when resolved]

**Resolved Date**: YYYY-MM-DD
**Resolution Summary**: [How was it fixed]
**Git Commits**: [Commit hashes]

### Validation Results
- [ ] Backtest results now match manual calculation
- [ ] No look-ahead bias detected
- [ ] Fill prices validated
- [ ] P&L calculation verified
- [ ] Comparison with live trading data (if available)

---

**Created By**: [Name/System]
**Last Updated**: YYYY-MM-DD
