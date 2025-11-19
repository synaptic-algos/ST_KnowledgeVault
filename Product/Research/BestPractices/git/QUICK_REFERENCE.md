# Git Workflow Quick Reference

**One-page cheat sheet for daily git operations**

---

## Before Every Commit ✅

```bash
# ALWAYS verify location and branch
pwd && git branch --show-current
```

---

## Feature Branch Workflow

### Start New Feature
```bash
git checkout main
git pull origin main
git checkout -b feature/my-feature
```

### Work on Feature
```bash
# Make changes...
git add <files>
git commit -m "[TYPE] Clear message"
git push -u origin feature/my-feature  # First push
git push                                # Subsequent pushes
```

### Create Pull Request
```bash
gh pr create --title "Feature description" --body "Details..."
```

### After PR Merged
```bash
git checkout main
git pull origin main
git branch -d feature/my-feature
```

---

## Git Worktrees

### Create Worktree
```bash
# For existing branch
git worktree add ../project-feature feature/branch-name

# Create new branch + worktree
git worktree add -b feature/new ../project-feature
```

### List Worktrees
```bash
git worktree list
```

### Remove Worktree
```bash
git worktree remove ../project-feature
git worktree prune  # Clean up stale references
```

### Common Pattern: PR Review
```bash
# Create worktree for review
git worktree add ../project-review feature-to-review
cd ../project-review

# Review code, run tests...

# Clean up
cd ../project
git worktree remove ../project-review
```

---

## Pull Request Workflow

### Create PR
```bash
gh pr create \
  --title "Short description" \
  --body "## Summary
- What changed
- Why it changed
- How to test"
```

### View PRs
```bash
gh pr list                    # List all PRs
gh pr view 123                # View specific PR
gh pr checkout 123            # Check out PR locally
```

### Merge PR
```bash
# On GitHub: Click "Merge pull request"
# Locally after merge:
git checkout main
git pull origin main
```

---

## Common Commands

### Status & Info
```bash
git status                    # Current state
git log --oneline -10         # Recent commits
git diff                      # Unstaged changes
git diff --staged             # Staged changes
git branch -v                 # Local branches
git remote -v                 # Remote repositories
```

### Update from Remote
```bash
git fetch origin              # Fetch changes
git pull origin main          # Pull main branch
git merge origin/main         # Merge main into current
git rebase origin/main        # Rebase on main
```

### Undo/Fix
```bash
git reset --soft HEAD~1       # Undo last commit, keep changes
git reset --hard HEAD~1       # Undo last commit, discard changes
git restore <file>            # Discard changes to file
git restore --staged <file>   # Unstage file
```

### Cleanup
```bash
git branch -d branch-name     # Delete local branch
git push origin --delete br   # Delete remote branch
git fetch --prune             # Clean stale references
git worktree prune            # Clean stale worktrees
```

---

## Branch Naming

```bash
feature/user-authentication   # New features
fix/payment-timeout           # Bug fixes
hotfix/critical-bug           # Urgent fixes
refactor/database-schema      # Code improvements
docs/api-documentation        # Documentation
test/unit-tests               # Testing
```

---

## Commit Message Format

```
[TYPE] Short summary (50 chars)

Optional longer description:
- What changed
- Why it changed
- Any breaking changes

Refs: #123
Closes #456
```

**Types**: FEATURE, FIX, REFACTOR, DOCS, TEST, CHORE

---

## Pre-Commit Checklist

- [ ] `pwd && git branch` - Verify location
- [ ] `git status` - Review changes
- [ ] `git diff --staged` - Review staged
- [ ] `make test` - Run tests
- [ ] Write clear message
- [ ] `git push` - Push!

---

## Pre-PR Checklist

- [ ] Branch updated with main
- [ ] Tests passing
- [ ] Code formatted
- [ ] Docs updated
- [ ] Clear commit messages
- [ ] Ready for review

---

## Emergency Fixes

### Wrong Branch
```bash
# If not pushed yet
git reset --soft HEAD~1
git checkout -b correct-branch
git commit -m "Message"
```

### Merge Conflicts
```bash
git status              # See conflicts
# Edit files, resolve <<<< ==== >>>>
git add <file>
git commit
```

### Lost Worktree
```bash
git worktree prune
```

---

## Don'ts ❌

- ❌ Never `git push --force` to main
- ❌ Never commit directly to main
- ❌ Never commit secrets (.env)
- ❌ Never create 20+ worktrees
- ❌ Never `rm -rf` a worktree (use git)
- ❌ Never forget to push after commit

---

## Help

```bash
git help <command>        # Detailed help
git <command> --help      # Same as above
gh --help                 # GitHub CLI help
```

**Team Resources**:
- Full Guide: `documentation/vault_research/BestPractices/git/GIT_WORKFLOW_GUIDE.md`
- CLAUDE.md: Repository-specific guidelines
- Slack: #engineering

---

**Remember**: When in doubt, `pwd && git branch` before any git operation!
