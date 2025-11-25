---
artifact_type: story
created_at: '2025-11-25T16:23:21.878706Z'
id: AUTO-GIT_WORKTREES_FOR_PARALLEL_CLAUDE_SESSIONS
manual_update: 'true'
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: '001'
status: pending
title: Auto-generated title for GIT_WORKTREES_FOR_PARALLEL_CLAUDE_SESSIONS
updated_at: '2025-11-25T16:23:21.878709Z'
---

## Why Use Git Worktrees?

### The Problem Without Worktrees

**Traditional workflow:**
```bash
# Working on issue-123
git checkout issue-123
# Claude session A working here...

# Need to urgently fix issue-456
git stash  # Save incomplete work
git checkout issue-456
# Claude session B working here...

# Want to go back to issue-123
git stash pop  # Restore work
git checkout issue-123

# PROBLEM: Only one Claude session can run at a time!
```

### The Solution With Worktrees

**Worktree workflow:**
```bash
# Main repo at ~/pilot-synaptictrading/
git worktree add ../pilot-issue-123 issue-123
git worktree add ../pilot-issue-456 issue-456

# Now you have:
# ~/pilot-synaptictrading/          (main branch)
# ~/pilot-issue-123/                (issue-123 branch)
# ~/pilot-issue-456/                (issue-456 branch)

# Each directory is independent:
cd ~/pilot-issue-123 && claude  # Session A
cd ~/pilot-issue-456 && claude  # Session B (parallel!)
```

**Key Advantage:** Multiple Claude Code instances can run simultaneously without conflicts!

---

## Quick Start

### 1. Basic Worktree Commands

```bash
# List all worktrees
git worktree list

# Add a new worktree for existing branch
git worktree add <path> <branch-name>

# Add worktree and create new branch
git worktree add -b <new-branch> <path> <base-branch>

# Remove a worktree (after committing/pushing changes)
git worktree remove <path>

# Prune stale worktree references
git worktree prune
```

### 2. Example: Create Two Parallel Worktrees

```bash
# Navigate to your main repo
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading

# Create worktree for issue-123 (existing branch)
git worktree add ../pilot-issue-123 issue-123

# Create worktree for new issue-789
git worktree add -b issue-789 ../pilot-issue-789 main

# Verify
git worktree list
# /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading  (main)
# /Users/nitindhawan/Downloads/CodeRepository/pilot-issue-123        (issue-123)
# /Users/nitindhawan/Downloads/CodeRepository/pilot-issue-789        (issue-789)
```

### 3. Launch Claude Sessions

```bash
# Terminal 1
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-issue-123
claude  # Claude session working on issue-123

# Terminal 2
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-issue-789
claude  # Claude session working on issue-789
```

Both sessions run **completely independently**!

---

## Core Concepts

### 1. Shared Git Directory

All worktrees share the **same `.git` directory**, which means:
- ✅ Commits, branches, and history are shared
- ✅ Efficient storage (objects stored once)
- ✅ `git fetch` in any worktree updates all
- ⚠️ Cannot checkout the same branch in multiple worktrees

### 2. Worktree Directory Structure

```
/Users/nitindhawan/Downloads/CodeRepository/
├── pilot-synaptictrading/           # Main worktree (primary checkout)
│   ├── .git/                        # Shared Git database
│   ├── src/
│   ├── config/
│   └── ...
├── pilot-issue-123/                 # Worktree for issue-123
│   ├── .git                         # Points to main .git
│   ├── src/
│   └── ...
└── pilot-issue-456/                 # Worktree for issue-456
    ├── .git                         # Points to main .git
    ├── src/
    └── ...
```

### 3. Branch Locking

**Important:** A branch can only be checked out in **one worktree at a time**.

```bash
# This will FAIL if issue-123 is already checked out
git worktree add ../pilot-duplicate issue-123
# fatal: 'issue-123' is already checked out at '.../pilot-issue-123'
```

**Solution:** Use different branches for each worktree.

---

## Setup for This Project

### Recommended Directory Structure

```bash
/Users/nitindhawan/Downloads/CodeRepository/
├── pilot-synaptictrading/           # Main repo (keep on main/stable branch)
└── worktrees/                       # Dedicated worktree directory
    ├── issue-123-rsi-fix/
    ├── issue-456-stop-loss/
    ├── feature-capital-manager/
    └── hotfix-data-loader/
```

### Initial Setup

```bash
# 1. Navigate to main repo
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading

# 2. Create worktrees directory (outside main repo)
mkdir -p ../worktrees

# 3. Fetch latest branches
git fetch origin

# 4. Create worktrees for active issues
git worktree add -b issue-123-rsi-fix ../worktrees/issue-123-rsi-fix main
git worktree add -b issue-456-stop-loss ../worktrees/issue-456-stop-loss main
git worktree add -b feature-capital-manager ../worktrees/feature-capital-manager main

# 5. Verify setup
git worktree list
```

### Naming Convention

**Format:** `<type>-<issue-number>-<short-description>`

Examples:
- `issue-123-rsi-fix`
- `issue-456-stop-loss`
- `feature-capital-manager`
- `hotfix-data-loader`
- `refactor-entry-manager`
- `docs-worktree-guide`

**Benefits:**
- Easy to identify purpose
- Self-documenting
- Consistent sorting

---

## Multi-Computer Workflow

### Scenario: Two Computers Accessing Same Repository

**Computer A (Mac 1):**
```
/Users/nitindhawan/Downloads/CodeRepository/
├── pilot-synaptictrading/
└── worktrees/
    ├── issue-123-rsi-fix/
    └── issue-456-stop-loss/
```

**Computer B (Mac 2):**
```
/Users/nitindhawan/workspace/
├── pilot-synaptictrading/
└── worktrees/
    ├── issue-789-portfolio-sl/
    └── feature-spread-optimization/
```

### Synchronization Workflow

#### On Computer A (Creating New Worktree)

```bash
# 1. Create worktree and branch
cd ~/Downloads/CodeRepository/pilot-synaptictrading
git worktree add -b issue-123-rsi-fix ../worktrees/issue-123-rsi-fix main

# 2. Do some work
cd ../worktrees/issue-123-rsi-fix
# ... Claude makes changes ...

# 3. Commit and push to remote
git add .
git commit -m "fix: RSI > 70 misclassified as neutral"
git push -u origin issue-123-rsi-fix
```

#### On Computer B (Accessing Branch from Computer A)

```bash
# 1. Fetch latest branches from remote
cd ~/workspace/pilot-synaptictrading
git fetch origin

# 2. Create worktree from remote branch
git worktree add ../worktrees/issue-123-rsi-fix issue-123-rsi-fix

# 3. Continue work
cd ../worktrees/issue-123-rsi-fix
# ... Claude continues work on same branch ...

# 4. Commit and push
git add .
git commit -m "fix: Add validation tests for RSI classification"
git push origin issue-123-rsi-fix
```

#### Back on Computer A (Pull Changes)

```bash
cd ~/Downloads/CodeRepository/worktrees/issue-123-rsi-fix
git pull origin issue-123-rsi-fix
# Now you have Computer B's changes
```

### Best Practices for Multi-Computer Setup

1. **Always push before switching computers**
   ```bash
   git push origin <branch-name>
   ```

2. **Always fetch/pull when switching to a computer**
   ```bash
   git fetch origin
   git pull origin <branch-name>
   ```

3. **Use descriptive commit messages**
   - Helps identify what was done on which computer
   - Use `Co-Authored-By: Claude <noreply@anthropic.com>` footer

4. **Avoid working on same branch simultaneously**
   - If you must, coordinate carefully
   - Use `git pull --rebase` to avoid merge commits

5. **Clean up completed worktrees on both computers**
   ```bash
   # After merging PR
   git worktree remove ../worktrees/issue-123-rsi-fix
   git branch -d issue-123-rsi-fix  # Delete local branch
   git push origin --delete issue-123-rsi-fix  # Delete remote (optional)
   ```

---

## Common Workflows

### Workflow 1: Start New Issue

```bash
# 1. Fetch latest main
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
git fetch origin
git pull origin main  # If main is checked out here

# 2. Create worktree for new issue
git worktree add -b issue-500-new-feature ../worktrees/issue-500-new-feature main

# 3. Launch Claude in new worktree
cd ../worktrees/issue-500-new-feature
claude

# 4. After work, commit and push
git add .
git commit -m "feat: Implement new feature"
git push -u origin issue-500-new-feature

# 5. Create PR on GitHub
gh pr create --title "Issue 500: New Feature" --body "..."
```

### Workflow 2: Parallel Issue Resolution

```bash
# Multiple issues to solve simultaneously
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading

# Create multiple worktrees
git worktree add -b issue-501-bug-a ../worktrees/issue-501-bug-a main
git worktree add -b issue-502-bug-b ../worktrees/issue-502-bug-b main
git worktree add -b issue-503-refactor ../worktrees/issue-503-refactor main

# Terminal 1
cd ../worktrees/issue-501-bug-a && claude

# Terminal 2
cd ../worktrees/issue-502-bug-b && claude

# Terminal 3
cd ../worktrees/issue-503-refactor && claude

# Each Claude session works independently!
```

### Workflow 3: Review PR While Working

```bash
# You're working on issue-123
cd /Users/nitindhawan/Downloads/CodeRepository/worktrees/issue-123-rsi-fix
# Claude session running here...

# Teammate creates PR on issue-456, you want to review
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
git fetch origin
git worktree add ../worktrees/review-issue-456 issue-456-stop-loss

# Open new terminal for review
cd /Users/nitindhawan/Downloads/CodeRepository/worktrees/review-issue-456
claude  # Launch Claude to help with review

# Both sessions running:
# Session 1: Your work on issue-123
# Session 2: Review of issue-456
```

### Workflow 4: Hotfix on Production

```bash
# You're working on multiple features
# Urgent hotfix needed on production

cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
git fetch origin

# Create hotfix worktree from main (or production branch)
git worktree add -b hotfix-critical-bug ../worktrees/hotfix-critical-bug main

# Launch Claude for hotfix
cd ../worktrees/hotfix-critical-bug
claude

# After fix:
git add .
git commit -m "hotfix: Critical bug in portfolio stop loss"
git push -u origin hotfix-critical-bug

# Create PR with high priority
gh pr create --title "[HOTFIX] Critical bug fix" --body "..."

# Other feature worktrees remain unaffected!
```

### Workflow 5: Cleanup After Merge

```bash
# PR merged for issue-123
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading

# 1. Remove worktree
git worktree remove ../worktrees/issue-123-rsi-fix

# 2. Update main branch
git checkout main
git pull origin main

# 3. Delete local branch
git branch -d issue-123-rsi-fix

# 4. (Optional) Delete remote branch
git push origin --delete issue-123-rsi-fix

# 5. Prune stale references
git worktree prune
```

---

## Best Practices

### 1. Organization

**✅ DO:**
- Keep worktrees in a dedicated `../worktrees/` directory
- Use consistent naming convention
- Limit active worktrees to current tasks (5-10 max)
- Document active worktrees in a tracking file

**❌ DON'T:**
- Scatter worktrees randomly in filesystem
- Create too many worktrees (hard to manage)
- Use vague names like `test1`, `temp`, `new-feature`

### 2. Branching Strategy

**✅ DO:**
- Always branch from up-to-date `main`
- Use descriptive branch names
- One branch per worktree
- Rebase before creating PR: `git rebase origin/main`

**❌ DON'T:**
- Branch from outdated `main`
- Checkout same branch in multiple worktrees
- Create worktree from another worktree's branch

### 3. Commit Hygiene

**✅ DO:**
- Commit frequently in each worktree
- Push to remote regularly (especially multi-computer)
- Use conventional commit messages
- Include `Co-Authored-By: Claude` footer

**❌ DON'T:**
- Leave uncommitted work for days
- Work offline for extended periods (multi-computer)
- Mix changes from different issues in same commit

### 4. Cleanup

**✅ DO:**
- Remove worktrees after PR merge
- Prune regularly: `git worktree prune`
- Delete merged branches
- Keep main repo clean

**❌ DON'T:**
- Leave stale worktrees around
- Delete worktree directory manually (use `git worktree remove`)
- Forget to delete remote branches after merge

### 5. Project-Specific Considerations

For **pilot-synaptictrading** project:

**Virtual Environment:**
```bash
# Each worktree needs its own venv OR use shared venv
# Option A: Shared venv (recommended for this project)
# Use main repo's venv from all worktrees
cd /Users/nitindhawan/Downloads/CodeRepository/worktrees/issue-123-rsi-fix
source /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading/venv/bin/activate

# Option B: Per-worktree venv (if dependencies differ)
cd /Users/nitindhawan/Downloads/CodeRepository/worktrees/issue-123-rsi-fix
python3 -m venv venv
source venv/bin/activate
pip install -e /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
```

**Data Catalogs:**
```bash
# Catalogs are large - share them across worktrees
# Create symlinks instead of duplicating

cd /Users/nitindhawan/Downloads/CodeRepository/worktrees/issue-123-rsi-fix
ln -s /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading/data/catalogs data/catalogs
ln -s /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading/data/.cache data/.cache
```

**Backtest Results:**
```bash
# Each worktree writes to separate results directory
# Results are in worktree, not shared

# After backtest in worktree:
cd /Users/nitindhawan/Downloads/CodeRepository/worktrees/issue-123-rsi-fix
./venv/bin/python src/nautilus/backtest/run_dual_mode_backtest.py --config config/strategy_config.json

# Results saved to:
# /Users/nitindhawan/Downloads/CodeRepository/worktrees/issue-123-rsi-fix/backtest_results/
```

**Configuration Files:**
```bash
# Each worktree has its own config
# Allows testing different configs in parallel!

# Worktree A: Testing RSI threshold change
config/strategy_config.json  # "rsi_overbought_threshold": 75

# Worktree B: Testing stop loss change
config/strategy_config.json  # "individual_stop_loss": 0.60
```

---

## Troubleshooting

### Issue 1: "Branch already checked out"

**Error:**
```bash
git worktree add ../worktrees/issue-123 issue-123
fatal: 'issue-123' is already checked out at '.../worktrees/issue-123'
```

**Solution:**
```bash
# Check where branch is checked out
git worktree list

# If worktree was deleted manually, prune it
git worktree prune

# Or remove properly
git worktree remove ../worktrees/issue-123
```

### Issue 2: Stale Worktree References

**Problem:** Deleted worktree directory manually, Git still tracks it.

**Solution:**
```bash
# List worktrees
git worktree list
# Shows: /path/to/deleted [branch] prunable

# Prune stale references
git worktree prune

# Verify
git worktree list
```

### Issue 3: Cannot Remove Worktree

**Error:**
```bash
git worktree remove ../worktrees/issue-123
fatal: '.../worktrees/issue-123' contains modified or untracked files
```

**Solution:**
```bash
# Option A: Commit changes first
cd ../worktrees/issue-123
git add .
git commit -m "WIP: Save work"
git push origin issue-123
cd -
git worktree remove ../worktrees/issue-123

# Option B: Force remove (CAUTION: loses uncommitted work)
git worktree remove --force ../worktrees/issue-123
```

### Issue 4: Worktree Missing After Computer Restart

**Problem:** Worktree paths break after moving directories or computer restart.

**Solution:**
```bash
# Check status
git worktree list
# Shows: /old/path/to/worktree [branch] (error)

# Repair worktree
git worktree repair /new/path/to/worktree

# Or remove and recreate
git worktree prune
git worktree add /new/path/to/worktree branch-name
```

### Issue 5: Different Git History in Worktrees

**Problem:** Worktrees seem out of sync.

**Explanation:** All worktrees share the same Git database, but working directories are independent.

**Solution:**
```bash
# Fetch updates all worktrees
cd /path/to/any/worktree
git fetch origin

# Each worktree can be on different commits
cd ../worktree-a
git log -1  # Shows commit A

cd ../worktree-b
git log -1  # Shows commit B (different!)

# This is expected! Each worktree is on its own branch.
```

### Issue 6: Disk Space Issues

**Problem:** Too many worktrees consuming disk space.

**Solution:**
```bash
# List worktrees
git worktree list

# Remove inactive worktrees
git worktree remove ../worktrees/completed-issue-123
git worktree remove ../worktrees/completed-issue-456

# Cleanup merged branches
git branch -d issue-123
git branch -d issue-456

# Prune stale references
git worktree prune

# Check disk usage
du -sh ../worktrees/*
```

### Issue 7: Python Virtual Environment Not Found

**Problem:** Running backtest in worktree, venv not found.

**Solution:**
```bash
# Option A: Use main repo's venv (recommended)
cd /path/to/worktree
source /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading/venv/bin/activate

# Option B: Create symlink to main venv
cd /path/to/worktree
ln -s /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading/venv venv

# Option C: Create new venv in worktree
cd /path/to/worktree
python3 -m venv venv
source venv/bin/activate
pip install -e .
```

---

## Advanced Usage

### 1. Automation Script for Worktree Creation

Create a helper script: `scripts/create_worktree.sh`

```bash
#!/bin/bash
# scripts/create_worktree.sh
# Usage: ./scripts/create_worktree.sh issue-123 "RSI fix"

ISSUE_NUM=$1
DESCRIPTION=$2
BRANCH_NAME="issue-${ISSUE_NUM}-${DESCRIPTION// /-}"
BRANCH_NAME=$(echo "$BRANCH_NAME" | tr '[:upper:]' '[:lower:]')

WORKTREE_DIR="/Users/nitindhawan/Downloads/CodeRepository/worktrees/${BRANCH_NAME}"

echo "Creating worktree for ${BRANCH_NAME}..."

cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
git fetch origin
git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" main

# Create symlinks for data
cd "$WORKTREE_DIR"
ln -s /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading/data/catalogs data/catalogs
ln -s /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading/data/.cache data/.cache

echo "✅ Worktree created at: $WORKTREE_DIR"
echo "Launch Claude: cd $WORKTREE_DIR && claude"
```

**Usage:**
```bash
chmod +x scripts/create_worktree.sh
./scripts/create_worktree.sh 123 "RSI fix"
./scripts/create_worktree.sh 456 "Stop loss calculation"
```

### 2. List Active Worktrees with Status

Create helper script: `scripts/list_worktrees.sh`

```bash
#!/bin/bash
# scripts/list_worktrees.sh

echo "Active Worktrees:"
echo "================"

git worktree list | while read line; do
    path=$(echo "$line" | awk '{print $1}')
    branch=$(echo "$line" | grep -oP '\[\K[^\]]+')

    if [ -d "$path" ]; then
        cd "$path"
        status=$(git status --short | wc -l)
        last_commit=$(git log -1 --format="%ar - %s" 2>/dev/null)
        echo ""
        echo "📁 $path"
        echo "   Branch: $branch"
        echo "   Changed files: $status"
        echo "   Last commit: $last_commit"
    fi
done
```

**Usage:**
```bash
chmod +x scripts/list_worktrees.sh
./scripts/list_worktrees.sh
```

### 3. Cleanup All Merged Worktrees

Create helper script: `scripts/cleanup_merged_worktrees.sh`

```bash
#!/bin/bash
# scripts/cleanup_merged_worktrees.sh

cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
git fetch origin
git checkout main
git pull origin main

echo "Finding merged branches..."

git branch --merged main | grep -v "main" | while read branch; do
    # Check if branch has worktree
    worktree_path=$(git worktree list | grep "[$branch]" | awk '{print $1}')

    if [ ! -z "$worktree_path" ]; then
        echo "Removing worktree for merged branch: $branch"
        git worktree remove "$worktree_path"
    fi

    echo "Deleting merged branch: $branch"
    git branch -d "$branch"
done

git worktree prune
echo "✅ Cleanup complete!"
```

**Usage:**
```bash
chmod +x scripts/cleanup_merged_worktrees.sh
./scripts/cleanup_merged_worktrees.sh
```

### 4. Track Active Worktrees in File

Create: `.worktrees-active.md` (gitignored)

```markdown
# Active Worktrees

Last updated: 2025-10-26

## In Progress

- **issue-123-rsi-fix** (`/worktrees/issue-123-rsi-fix`)
  - Computer: Mac 1
  - Started: 2025-10-25
  - Status: Testing RSI classification fix
  - Claude session: Terminal 1

- **issue-456-stop-loss** (`/worktrees/issue-456-stop-loss`)
  - Computer: Mac 2
  - Started: 2025-10-26
  - Status: Implementing portfolio stop loss
  - Claude session: Terminal 2

## Review

- **review-pr-789** (`/worktrees/review-pr-789`)
  - Computer: Mac 1
  - Started: 2025-10-26
  - Status: Reviewing teammate's PR

## Completed (to clean up)

- ~~issue-111-strike-fix~~ - Merged on 2025-10-24
```

Add to `.gitignore`:
```bash
echo ".worktrees-active.md" >> .gitignore
```

### 5. Git Aliases for Worktree Commands

Add to `~/.gitconfig`:

```ini
[alias]
    # Worktree aliases
    wt = worktree
    wtls = worktree list
    wtadd = worktree add
    wtrm = worktree remove
    wtprune = worktree prune

    # Create worktree with branch
    wtnew = "!f() { git worktree add -b \"$1\" \"../worktrees/$1\" main; }; f"

    # List worktrees with status
    wtstatus = "!git worktree list | while read line; do echo \"$line\"; done"
```

**Usage:**
```bash
git wtls                          # List worktrees
git wtnew issue-123-rsi-fix       # Create new worktree
git wtrm ../worktrees/issue-123   # Remove worktree
git wtprune                       # Prune stale worktrees
```

---

## Summary

### Quick Reference Card

```bash
# CREATE WORKTREE
git worktree add -b <branch> ../worktrees/<name> main

# LIST WORKTREES
git worktree list

# REMOVE WORKTREE
git worktree remove ../worktrees/<name>

# CLEANUP
git worktree prune

# TYPICAL WORKFLOW
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
git worktree add -b issue-123-fix ../worktrees/issue-123-fix main
cd ../worktrees/issue-123-fix
claude  # Launch Claude Code
# ... work ...
git add . && git commit -m "fix: ..." && git push -u origin issue-123-fix
gh pr create
# After merge:
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
git worktree remove ../worktrees/issue-123-fix
git branch -d issue-123-fix
```

### Benefits Recap

✅ **Parallel Development:** Multiple Claude sessions simultaneously
✅ **No Context Switching:** Each issue in its own directory
✅ **Efficient Storage:** Shared Git objects
✅ **Multi-Computer Sync:** Easy push/pull workflow
✅ **Clean Organization:** Dedicated worktrees directory
✅ **Hotfix Ready:** Quickly create production fix without affecting feature work

### Next Steps

1. **Try it:** Create your first worktree
2. **Automate:** Add helper scripts to `scripts/` directory
3. **Document:** Track active worktrees in `.worktrees-active.md`
4. **Optimize:** Create symlinks for data catalogs
5. **Share:** Add automation scripts to this repo

---

## References

- [Official Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [Git Worktrees and Claude Code 2025 Guide](https://www.geeky-gadgets.com/how-to-use-git-worktrees-with-claude-code-for-seamless-multitasking/)
- [Parallel AI Development with Git Worktrees](https://medium.com/@ooi_yee_fei/parallel-ai-development-with-git-worktrees-f2524afc3e33)
- [Incident.io: Shipping Faster with Claude Code](https://incident.io/blog/shipping-faster-with-claude-code-and-git-worktrees)
