# Performance Issue: [Short Title]

**Date**: YYYY-MM-DD HH:MM:SS
**Severity**: HIGH | MEDIUM | LOW
**Status**: Identified | In Progress | Resolved
**Component**: [Strategy Execution | Data Processing | Backtest Engine | API Calls]
**Related Story**: [Link to Story if applicable]

---

## Summary

[Brief description of the performance issue]

---

## Performance Metrics

### Current Performance
- **Metric**: [e.g., Backtest time, Order execution latency]
- **Current Value**: [e.g., 45 seconds, 250ms]
- **Baseline/Expected**: [e.g., 10 seconds, 50ms]
- **Degradation**: [e.g., 350% slower, 5x increase]

### System Impact
- **CPU Usage**: [%]
- **Memory Usage**: [MB/GB]
- **Disk I/O**: [MB/s]
- **Network**: [requests/sec or latency]

---

## Evidence

### Profiling Data
```
[Paste profiling output showing bottlenecks]
Example:
- function_name: 25.3% of total time (12.5 seconds)
- data_processing: 45.2% of total time (22.1 seconds)
```

### Logs
```
[Relevant performance logs with timestamps]
```

### Monitoring Data
[Screenshots of performance graphs, metrics dashboards]

---

## Reproduction Steps

1. [Step to reproduce slow performance]
2. [Measurement method]
3. [Expected vs actual timing]

**Environment**:
- Hardware: [CPU, RAM specs]
- Data Size: [Number of records, date range]
- Concurrent Users/Processes: [N]

---

## Root Cause Analysis

### Bottleneck Identification
[Where is the slowdown occurring?]
- File: `path/to/file.py:function_name`
- Operation: [Database query, API call, computation, etc.]

### Why This Is Slow
[Technical explanation of the bottleneck]

Common Performance Issues:
- [ ] N+1 query problem (multiple DB calls in loop)
- [ ] Missing index on database query
- [ ] Inefficient algorithm (O(n²) instead of O(n log n))
- [ ] Unnecessary data loading (loading full dataset when only need subset)
- [ ] No caching (recalculating same values)
- [ ] Synchronous API calls (should be async)
- [ ] Memory leak (unbounded growth)

---

## Impact

1. **User Impact**: [How does slowness affect users/traders?]
2. **Trading Impact**: [Does this affect order execution speed?]
3. **Backtest Impact**: [Does this slow down development cycle?]
4. **Cost Impact**: [Increased server costs, opportunity cost]

### Severity Justification
[Why is this HIGH/MEDIUM/LOW priority?]

---

## Proposed Optimization

### Strategy
[Describe the optimization approach]

### Expected Improvement
- **Target Performance**: [e.g., <10 seconds, <50ms]
- **Expected Speedup**: [e.g., 5x faster, 80% reduction]

### Optimization Techniques
- [ ] Algorithm improvement
- [ ] Caching strategy
- [ ] Database query optimization
- [ ] Async/parallel processing
- [ ] Data structure change
- [ ] Code refactoring
- [ ] Infrastructure scaling

### Files to Modify
1. `path/to/file1.py` - [What to optimize]
2. `path/to/file2.py` - [What to optimize]

### Risks
- [Potential risk 1 - e.g., increased memory usage]
- [Potential risk 2 - e.g., code complexity]

---

## Implementation
[To be filled when work starts]

### Changes Made
1. File: `path/to/file.py`
   - Line X: [Optimization description]

### Benchmark Results

**Before Optimization**:
```
Test: [Description]
Time: [X seconds/ms]
CPU: [%]
Memory: [MB]
```

**After Optimization**:
```
Test: [Description]
Time: [Y seconds/ms]
CPU: [%]
Memory: [MB]
```

**Improvement**:
- Speed: [X% faster]
- CPU Reduction: [X%]
- Memory Reduction: [X MB]

### Testing Performed
- [ ] Benchmark tests show improvement
- [ ] No functional regression
- [ ] Load testing completed
- [ ] Production monitoring plan in place

---

## Resolution
[To be filled when resolved]

**Resolved Date**: YYYY-MM-DD
**Resolution Summary**: [What was optimized]
**Git Commits**: [Commit hashes]

### Verification
- **Performance Target Met**: [Yes/No]
- **Speedup Achieved**: [Xx faster]
- **Monitoring**: [How will we track this going forward?]

### Lessons Learned
[What did we learn about performance optimization?]

---

**Created By**: [Name/System]
**Last Updated**: YYYY-MM-DD
