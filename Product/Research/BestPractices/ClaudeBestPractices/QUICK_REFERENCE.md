---
artifact_type: story
created_at: '2025-11-25T16:23:21.882029Z'
id: AUTO-QUICK_REFERENCE
manual_update: 'true'
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: '001'
status: pending
title: Auto-generated title for QUICK_REFERENCE
updated_at: '2025-11-25T16:23:21.882032Z'
---

## Multi-Computer Workflow

### On Computer A (Create branch)
```bash
./scripts/create_worktree.sh 123 "RSI fix"
cd ../worktrees/issue-123-rsi-fix
# ... work ...
git push -u origin issue-123-rsi-fix
```

### On Computer B (Access same branch)
```bash
git fetch origin
./scripts/create_worktree.sh 123 "RSI fix"  # Will use existing branch
cd ../worktrees/issue-123-rsi-fix
git pull origin issue-123-rsi-fix
# ... continue work ...
```

---

## Parallel Sessions

```bash
# Create multiple worktrees
./scripts/create_worktree.sh 123 "RSI fix"
./scripts/create_worktree.sh 456 "Stop loss"
./scripts/create_worktree.sh 789 "Portfolio SL"

# Terminal 1
cd ../worktrees/issue-123-rsi-fix && claude

# Terminal 2
cd ../worktrees/issue-456-stop-loss && claude

# Terminal 3
cd ../worktrees/issue-789-portfolio-sl && claude

# All three Claude sessions run independently!
```

---

## Project-Specific Setup

### Virtual Environment
```bash
# Use main repo's venv (recommended)
cd /path/to/worktree
source /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading/venv/bin/activate
```

### Data Catalogs
```bash
# Automatically created by create_worktree.sh script
# Symlinks point to main repo:
# data/catalogs -> ../pilot-synaptictrading/data/catalogs
# data/.cache -> ../pilot-synaptictrading/data/.cache
```

### Run Backtest
```bash
cd /path/to/worktree
source /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading/venv/bin/activate

./venv/bin/python src/nautilus/backtest/run_dual_mode_backtest.py \
  --config config/strategy_config.json \
  --catalog data/catalogs/v13_real_enhanced_hourly_consolidated_TIMEZONE_FIXED \
  --precompute
```

---

## Troubleshooting

### Branch Already Checked Out
```bash
# Problem: Branch already in another worktree
git worktree list  # Find where it's checked out
git worktree prune  # Clean stale references
```

### Stale Worktree References
```bash
# Deleted worktree directory manually
git worktree prune  # Remove stale tracking
```

### Cannot Remove Worktree
```bash
# Has uncommitted changes
cd /path/to/worktree
git status  # Check changes
git add . && git commit -m "WIP: Save work"  # Commit first
cd -
git worktree remove /path/to/worktree  # Now can remove

# Or force remove (CAUTION: loses uncommitted work!)
git worktree remove --force /path/to/worktree
```

### Missing Virtual Environment
```bash
# Create symlink to main venv
cd /path/to/worktree
ln -s /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading/venv venv
```

---

## Git Aliases (Optional)

Add to `~/.gitconfig`:

```ini
[alias]
    wt = worktree
    wtls = worktree list
    wtadd = worktree add
    wtrm = worktree remove
    wtprune = worktree prune
```

Usage:
```bash
git wtls          # List worktrees
git wtadd -b feature-x ../worktrees/feature-x main
git wtrm ../worktrees/feature-x
git wtprune       # Cleanup
```

---

## Directory Structure

```
/Users/nitindhawan/Downloads/CodeRepository/
├── pilot-synaptictrading/           # Main repo (on main branch)
│   ├── .git/                        # Shared Git database
│   ├── data/catalogs/               # Shared catalogs
│   ├── data/.cache/                 # Shared cache
│   └── venv/                        # Shared virtual environment
│
└── worktrees/                       # All worktrees here
    ├── issue-123-rsi-fix/           # Issue 123
    │   ├── data/catalogs -> ../../pilot-synaptictrading/data/catalogs
    │   ├── data/.cache -> ../../pilot-synaptictrading/data/.cache
    │   └── ...
    ├── issue-456-stop-loss/         # Issue 456
    └── feature-capital-manager/     # New feature
```

---

## Best Practices

✅ **DO:**
- Use helper scripts for consistency
- Keep worktrees in `/worktrees/` directory
- Commit and push frequently (multi-computer)
- Clean up merged worktrees regularly
- Use descriptive branch names

❌ **DON'T:**
- Delete worktree directories manually (use `git worktree remove`)
- Checkout same branch in multiple worktrees
- Leave stale worktrees around
- Forget to activate virtual environment
- Mix changes from different issues in one commit

---

## Quick Status Check

```bash
# Show all worktrees with detailed status
./scripts/list_worktrees.sh

# Check for cleanup opportunities
./scripts/cleanup_merged_worktrees.sh

# Verify Git is tracking correctly
git worktree list
```

---

## Emergency Recovery

### Accidentally Deleted Worktree Directory
```bash
# 1. Prune the stale reference
git worktree prune

# 2. Recreate worktree (if work was committed and pushed)
git fetch origin
git worktree add ../worktrees/issue-123 issue-123
```

### Lost Uncommitted Work
```bash
# If work was not committed before deletion, it's LOST
# Prevention: Commit frequently!

# Check reflog for any commits (might help)
git reflog

# If found commit hash
git worktree add ../worktrees/recovery <commit-hash>
```

---

## Resources

- **Full Guide:** [GIT_WORKTREES_FOR_PARALLEL_CLAUDE_SESSIONS.md](./GIT_WORKTREES_FOR_PARALLEL_CLAUDE_SESSIONS.md)
- **Helper Scripts:** `/scripts/create_worktree.sh`, `/scripts/list_worktrees.sh`, `/scripts/cleanup_merged_worktrees.sh`
- **Git Docs:** https://git-scm.com/docs/git-worktree

---

Last Updated: 2025-10-26
