---
artifact_type: story
created_at: '2025-11-25T16:23:21.881439Z'
id: AUTO-LOCAL_MERGE_WORKFLOW
manual_update: 'true'
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: '001'
status: pending
title: Auto-generated title for LOCAL_MERGE_WORKFLOW
updated_at: '2025-11-25T16:23:21.881442Z'
---

## Basic Local Merge

### The Core Process

```bash
# 1. Commit your work in worktree
cd /path/to/worktree
git add .
git commit -m "Your changes"

# 2. Switch to main branch in main repo
cd /path/to/main-repo
git checkout main
git pull origin main  # Sync with remote first (IMPORTANT!)

# 3. Merge feature branch INTO main
git merge <feature-branch-name>

# 4. Push merged main to remote
git push origin main

# 5. Cleanup
git worktree remove /path/to/worktree
git branch -d <feature-branch-name>
```

---

## Step-by-Step Guide

### Complete Workflow for This Project

```bash
# ===== STEP 1: Work in Worktree =====
cd /Users/nitindhawan/Downloads/CodeRepository/worktrees/issue-123-rsi-fix

# Make your changes with Claude...
# Then commit
git status  # Check what changed
git add .
git commit -m "fix: RSI > 70 classification corrected

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Verify commit
git log -1

# ===== STEP 2: Navigate to Main Repo =====
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading

# ===== STEP 3: Update Main Branch First =====
git checkout main
git pull origin main  # Get latest changes from remote

# ===== STEP 4: Merge Your Feature Branch =====
git merge issue-123-rsi-fix

# Success output:
# Updating abc1234..def5678
# Fast-forward
#  src/strategy/components/entry_manager.py | 10 +++++-----
#  1 file changed, 5 insertions(+), 5 deletions(-)

# ===== STEP 5: Push Merged Main to Remote =====
git push origin main

# ===== STEP 6: Cleanup Worktree =====
git worktree remove ../worktrees/issue-123-rsi-fix
git branch -d issue-123-rsi-fix  # Delete the merged branch

# ===== STEP 7: Verify =====
git log --oneline -5  # Check recent commits
./scripts/worktree/list_worktrees.sh  # Check remaining worktrees
```

### Using Helper Scripts

```bash
# Create worktree
./scripts/worktree/create_worktree.sh 123 "RSI fix"

# Work in worktree
cd ../worktrees/issue-123-rsi-fix
# ... make changes ...
git add . && git commit -m "fix: Something"

# Merge locally
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
git checkout main
git pull origin main
git merge issue-123-rsi-fix
git push origin main

# Cleanup
./scripts/worktree/cleanup_merged_worktrees.sh
```

---

## Understanding Merge Types

### Fast-Forward Merge (Most Common)

**When:** Main branch hasn't changed since you branched.

**Diagram:**
```
Before merge:
main:    A---B
              \
feature:       C---D

After fast-forward merge:
main:    A---B---C---D
```

**Command:**
```bash
git checkout main
git merge issue-123-rsi-fix
# Output: "Fast-forward"
```

**Characteristics:**
- ✅ Linear history
- ✅ No merge commit created
- ✅ Clean, simple
- ✅ Easy to understand

### Three-Way Merge (Divergent Branches)

**When:** Both main and feature branch have new commits.

**Diagram:**
```
Before merge:
main:    A---B---E---F
              \
feature:       C---D

After three-way merge (creates merge commit):
main:    A---B---E---F---M
              \         /
feature:       C-------D
```

**Command:**
```bash
git checkout main
git merge issue-123-rsi-fix
# Creates merge commit M
# Editor opens for merge commit message
```

**Characteristics:**
- ✅ Preserves branch history
- ✅ Shows when branches diverged
- ⚠️  Creates extra merge commit
- ⚠️  More complex history

### Forcing Fast-Forward Only

```bash
# Fail if fast-forward not possible
git merge --ff-only issue-123-rsi-fix

# If it fails, rebase first:
git checkout issue-123-rsi-fix
git rebase main
git checkout main
git merge --ff-only issue-123-rsi-fix
```

---

## Handling Merge Conflicts

### When Conflicts Occur

Conflicts happen when the same lines in the same files were changed in both branches.

### Step-by-Step Conflict Resolution

```bash
# ===== STEP 1: Attempt Merge =====
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
git checkout main
git merge issue-123-rsi-fix

# Output shows conflict:
# Auto-merging src/strategy/components/entry_manager.py
# CONFLICT (content): Merge conflict in src/strategy/components/entry_manager.py
# Automatic merge failed; fix conflicts and then commit the result.

# ===== STEP 2: Check Which Files Have Conflicts =====
git status

# Output:
# On branch main
# You have unmerged paths.
#   (fix conflicts and run "git commit")
#
# Unmerged paths:
#   (use "git add <file>..." to mark resolution)
#         both modified:   src/strategy/components/entry_manager.py

# ===== STEP 3: View Conflict Details =====
git diff

# Or open the file
cat src/strategy/components/entry_manager.py
```

### Conflict Markers Explained

The conflicted file will look like this:

```python
# Normal code above conflict
def calculate_entry(self, timestamp):
    """Calculate entry conditions."""

<<<<<<< HEAD
    # This is the code from main branch
    if rsi > 70:
        return "OVERBOUGHT"
=======
    # This is the code from your feature branch (issue-123-rsi-fix)
    if rsi >= 70:
        return "RSI_OVERBOUGHT"
>>>>>>> issue-123-rsi-fix

    # Normal code below conflict
    return "NEUTRAL"
```

**Markers:**
- `<<<<<<< HEAD` - Start of main branch code
- `=======` - Separator between versions
- `>>>>>>> issue-123-rsi-fix` - End of feature branch code

### Resolving Conflicts

```bash
# ===== STEP 4: Edit File to Resolve =====
# Open in editor
code src/strategy/components/entry_manager.py

# Edit to keep what you want, remove markers:
def calculate_entry(self, timestamp):
    """Calculate entry conditions."""
    # Decided to keep feature branch version
    if rsi >= 70:
        return "RSI_OVERBOUGHT"
    return "NEUTRAL"

# Save the file

# ===== STEP 5: Mark as Resolved =====
git add src/strategy/components/entry_manager.py

# ===== STEP 6: Check Status =====
git status
# On branch main
# All conflicts fixed but you are still merging.
#   (use "git commit" to conclude merge)

# ===== STEP 7: Complete the Merge =====
git commit  # Opens editor with default merge message

# Or provide message directly:
git commit -m "Merge issue-123-rsi-fix into main

Resolved conflicts in entry_manager.py by keeping new RSI threshold logic."

# ===== STEP 8: Push =====
git push origin main
```

### Aborting a Merge

If you want to cancel the merge and start over:

```bash
# Abort merge and return to pre-merge state
git merge --abort

# Your main branch returns to its previous state
# Try again or fix issues first
```

### Viewing Conflicts in Tools

```bash
# Use VS Code merge editor
code --wait src/strategy/components/entry_manager.py

# Or use Git's built-in merge tool
git mergetool

# Configure merge tool (one-time setup)
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait $MERGED'
```

---

## Testing Before Merge

### Best Practice: Validate Before Merging

**For this trading strategy project:**

```bash
# ===== STEP 1: Run Backtest in Worktree =====
cd /Users/nitindhawan/Downloads/CodeRepository/worktrees/issue-123-rsi-fix
source /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading/venv/bin/activate

# Quick test backtest (10 instruments)
./venv/bin/python src/nautilus/backtest/run_dual_mode_backtest.py \
  --config config/strategy_config.json \
  --catalog data/catalogs/v13_real_enhanced_hourly_consolidated_TIMEZONE_FIXED \
  --max-instruments 10 \
  --precompute

# ===== STEP 2: Validate Results =====
# Check: backtest_results/YYYYMMDD/HHMMSS_NativeOptionsStrategy/
ls -la backtest_results/

# Review trade log
head -20 backtest_results/YYYYMMDD/HHMMSS_NativeOptionsStrategy/trade_log.csv

# Check statistics
cat backtest_results/YYYYMMDD/HHMMSS_NativeOptionsStrategy/statistics.json

# ===== STEP 3: If Tests Pass, Merge =====
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
git checkout main
git pull origin main
git merge issue-123-rsi-fix
git push origin main
```

### Pre-Merge Checklist

Before merging, verify:

- ✅ All changes committed
- ✅ Backtest runs successfully
- ✅ Results look reasonable
- ✅ No debug code left in
- ✅ Configuration changes documented
- ✅ Main branch is up-to-date

```bash
# Pre-merge verification script
cd /path/to/worktree

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ Uncommitted changes found!"
    git status
    exit 1
fi

# Check for debug prints
if grep -r "print(" src/ --include="*.py"; then
    echo "⚠️  Debug print statements found"
fi

# Check for TODO/FIXME
if grep -r "TODO\|FIXME" src/ --include="*.py"; then
    echo "⚠️  TODO/FIXME comments found"
fi

echo "✅ Pre-merge checks passed"
```

---

## Complete Examples

### Example 1: Single Worktree Merge

```bash
# Create worktree
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
./scripts/worktree/create_worktree.sh 123 "RSI fix"

# Work in worktree
cd ../worktrees/issue-123-rsi-fix
# ... make changes ...
git add .
git commit -m "fix: RSI classification logic"

# Test changes
source /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading/venv/bin/activate
./venv/bin/python src/nautilus/backtest/run_dual_mode_backtest.py \
  --config config/strategy_config.json \
  --max-instruments 10 \
  --precompute

# If tests pass, merge
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
git checkout main
git pull origin main
git merge issue-123-rsi-fix
git push origin main

# Cleanup
git worktree remove ../worktrees/issue-123-rsi-fix
git branch -d issue-123-rsi-fix
```

### Example 2: Multiple Worktrees, Sequential Merges

```bash
# Create multiple worktrees
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
./scripts/worktree/create_worktree.sh 123 "RSI fix"
./scripts/worktree/create_worktree.sh 456 "Stop loss"
./scripts/worktree/create_worktree.sh 789 "Portfolio SL"

# ===== Work on all three in parallel =====
# Terminal 1 - Issue 123
cd ../worktrees/issue-123-rsi-fix
# ... work ...
git add . && git commit -m "fix: RSI classification"

# Terminal 2 - Issue 456
cd ../worktrees/issue-456-stop-loss
# ... work ...
git add . && git commit -m "fix: Stop loss calculation"

# Terminal 3 - Issue 789
cd ../worktrees/issue-789-portfolio-sl
# ... work ...
git add . && git commit -m "fix: Portfolio stop loss"

# ===== Merge sequentially =====
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
git checkout main
git pull origin main

# Merge issue 123
git merge issue-123-rsi-fix
git push origin main

# Merge issue 456
git merge issue-456-stop-loss
git push origin main

# Merge issue 789
git merge issue-789-portfolio-sl
git push origin main

# Cleanup all
./scripts/worktree/cleanup_merged_worktrees.sh
```

### Example 3: Merge with Conflict Resolution

```bash
# Create worktree
./scripts/worktree/create_worktree.sh 123 "Entry timing change"

# Work in worktree
cd ../worktrees/issue-123-entry-timing-change
# ... edit config/strategy_config.json ...
git add config/strategy_config.json
git commit -m "feat: Change entry time to 10:30"

# Meanwhile, someone else changed main
# (or you made changes in main repo)

# Attempt merge
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
git checkout main
git pull origin main  # Gets new changes
git merge issue-123-entry-timing-change

# CONFLICT in config/strategy_config.json
git status

# Resolve conflict
code config/strategy_config.json
# ... edit file, remove conflict markers, keep desired changes ...
git add config/strategy_config.json
git commit -m "Merge issue-123-entry-timing-change

Resolved conflict in strategy_config.json by keeping both entry time
and new exit time changes."

git push origin main

# Cleanup
./scripts/worktree/cleanup_merged_worktrees.sh
```

### Example 4: Test, Merge, Test Again

```bash
# Create worktree
./scripts/worktree/create_worktree.sh 500 "Major refactor"

# Work in worktree
cd ../worktrees/issue-500-major-refactor
# ... make changes ...
git add .
git commit -m "refactor: Restructure entry manager"

# Test in worktree
source /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading/venv/bin/activate
./venv/bin/python src/nautilus/backtest/run_dual_mode_backtest.py \
  --config config/strategy_config.json \
  --max-instruments 10 \
  --precompute

# Tests pass, merge
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
git checkout main
git merge issue-500-major-refactor
git push origin main

# Test again in main repo (sanity check)
./venv/bin/python src/nautilus/backtest/run_dual_mode_backtest.py \
  --config config/strategy_config.json \
  --max-instruments 10 \
  --precompute

# If all good, cleanup
./scripts/worktree/cleanup_merged_worktrees.sh
```

---

## Troubleshooting

### Issue 1: "Already up to date"

**Problem:**
```bash
git merge issue-123-rsi-fix
# Output: "Already up to date."
```

**Cause:** The branches are already in sync (no new commits to merge).

**Solution:**
```bash
# Check if branch has commits
git log main..issue-123-rsi-fix

# If empty, nothing to merge
# Cleanup the worktree
git worktree remove ../worktrees/issue-123-rsi-fix
git branch -d issue-123-rsi-fix
```

### Issue 2: "Not something we can merge"

**Problem:**
```bash
git merge issue-123
# fatal: issue-123 - not something we can merge
```

**Cause:** Branch doesn't exist or name is wrong.

**Solution:**
```bash
# List all branches
git branch -a

# Find correct branch name
git worktree list

# Use correct name
git merge issue-123-rsi-fix
```

### Issue 3: Merge Commits Not Showing

**Problem:** After merge, commits don't appear in `git log`.

**Cause:** Fast-forward merge doesn't create merge commit.

**Solution:**
```bash
# To see all commits including merged ones
git log --oneline --graph --all

# To force merge commit even with fast-forward
git merge --no-ff issue-123-rsi-fix
```

### Issue 4: Wrong Branch Merged

**Problem:** Merged wrong branch into main.

**Solution (if not pushed yet):**
```bash
# Undo last merge (not pushed)
git reset --hard HEAD~1

# Or undo to specific commit
git log --oneline -10  # Find commit before merge
git reset --hard abc1234

# Try again with correct branch
git merge correct-branch-name
```

**Solution (if already pushed):**
```bash
# Revert the merge (creates new commit)
git revert -m 1 HEAD
git push origin main

# Explanation:
# -m 1 means "revert to first parent" (main branch)
# This creates a new commit that undoes the merge
```

### Issue 5: Can't Switch to Main

**Problem:**
```bash
git checkout main
# error: pathspec 'main' did not match any file(s) known to git
```

**Cause:** In a worktree where main isn't checked out.

**Solution:**
```bash
# Go to main repo first
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading

# Then checkout main
git checkout main
```

### Issue 6: Conflicts Too Complex

**Problem:** Too many conflicts to resolve manually.

**Solution:**
```bash
# Abort the merge
git merge --abort

# Option A: Rebase your branch first (resolve conflicts incrementally)
git checkout issue-123-rsi-fix
git rebase main
# Resolve conflicts one commit at a time
git checkout main
git merge issue-123-rsi-fix  # Now should be clean

# Option B: Use PR for complex merges (GitHub will help)
git push origin issue-123-rsi-fix
gh pr create --title "Issue 123: RSI fix"
# Resolve conflicts on GitHub interface
```

---

## Quick Reference

### Essential Commands

```bash
# MERGE WORKFLOW
git checkout main              # Switch to main
git pull origin main           # Update from remote
git merge <branch>             # Merge branch into main
git push origin main           # Push to remote

# VIEW MERGE STATUS
git status                     # Current state
git log --oneline --graph -10  # Visual history
git diff main <branch>         # Show differences

# CONFLICT RESOLUTION
git status                     # See conflicted files
git add <file>                 # Mark as resolved
git commit                     # Complete merge
git merge --abort              # Cancel merge

# CLEANUP
git worktree remove <path>     # Remove worktree
git branch -d <branch>         # Delete branch
git worktree prune             # Clean stale refs
```

### Merge Checklist

Before merging:
- [ ] All changes committed in worktree
- [ ] Backtest runs successfully
- [ ] Main branch is up-to-date (`git pull origin main`)
- [ ] No uncommitted debug code
- [ ] Configuration changes documented

During merge:
- [ ] Check for conflicts (`git status`)
- [ ] Resolve conflicts if any
- [ ] Test after merge (optional but recommended)
- [ ] Push to remote

After merge:
- [ ] Remove worktree
- [ ] Delete merged branch
- [ ] Prune stale references
- [ ] Verify with `git log`

### Common Scenarios

```bash
# Scenario 1: Simple fast-forward merge
git checkout main && git pull origin main && git merge issue-123 && git push origin main

# Scenario 2: Merge with explicit merge commit
git checkout main && git merge --no-ff issue-123 && git push origin main

# Scenario 3: Merge only if fast-forward possible
git checkout main && git merge --ff-only issue-123 || echo "Rebase needed"

# Scenario 4: Merge and cleanup in one go
git checkout main && git merge issue-123 && git push origin main && git branch -d issue-123

# Scenario 5: Test merge before committing (dry run)
git merge --no-commit --no-ff issue-123
# Review changes
git merge --abort  # If not satisfied
# Or
git commit  # If satisfied
```

### Viewing Merge Information

```bash
# See what would be merged (without merging)
git log main..issue-123-rsi-fix

# See differences between branches
git diff main...issue-123-rsi-fix

# See merge base (common ancestor)
git merge-base main issue-123-rsi-fix

# See if branch is merged
git branch --merged main
```

---

## Summary

### Key Takeaways

1. **Always update main first**: `git pull origin main` before merging
2. **Test before merging**: Run backtest in worktree to validate
3. **Commit everything**: Ensure clean working directory before merge
4. **Resolve conflicts carefully**: Understand what each side changed
5. **Push after merge**: `git push origin main` to sync remote
6. **Cleanup after merge**: Remove worktree and delete branch

### When to Use What

| Scenario | Recommended Approach |
|----------|---------------------|
| Solo development | Local merge |
| Quick iterations | Local merge |
| Team collaboration | GitHub PR |
| Complex changes | GitHub PR |
| Need code review | GitHub PR |
| Experimentation | Local merge |
| Production changes | GitHub PR (with CI/CD) |

### Typical Workflow

```bash
# 1. Create and work
./scripts/worktree/create_worktree.sh 123 "Fix"
cd ../worktrees/issue-123-fix
# ... work ...
git add . && git commit -m "fix: Something"

# 2. Test
./venv/bin/python src/nautilus/backtest/run_dual_mode_backtest.py \
  --config config/strategy_config.json --max-instruments 10 --precompute

# 3. Merge
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
git checkout main && git pull origin main && git merge issue-123-fix && git push origin main

# 4. Cleanup
./scripts/worktree/cleanup_merged_worktrees.sh
```

---

## Related Documentation

- **Worktrees Guide**: [GIT_WORKTREES_FOR_PARALLEL_CLAUDE_SESSIONS.md](./GIT_WORKTREES_FOR_PARALLEL_CLAUDE_SESSIONS.md)
- **Quick Reference**: [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)
- **Helper Scripts**: `/scripts/worktree/`

---

Last Updated: 2025-10-26
