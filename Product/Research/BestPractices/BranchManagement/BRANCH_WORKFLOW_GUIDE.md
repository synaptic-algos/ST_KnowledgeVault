# Branch-Based Parallel Development Workflow

## Executive Summary

This guide explains how to set up and manage branch-based parallel development for the nikhilwm-opt-v2 project, enabling multiple developers to work simultaneously without conflicts.

## Table of Contents

1. [Understanding the Repository Structure](#understanding-the-repository-structure)
2. [Current State](#current-state)
3. [Setting Up Your Branch](#setting-up-your-branch)
4. [Pushing Your Branch to GitHub](#pushing-your-branch-to-github)
5. [Creating Feature Branches](#creating-feature-branches)
6. [Parallel Development Workflows](#parallel-development-workflows)
7. [Branch Management](#branch-management)
8. [Testing and Integration](#testing-and-integration)
9. [Best Practices](#best-practices)

---

## Understanding the Repository Structure

### Main Repository
**URL:** `https://github.com/gtalknitin/synpatictrading`

The main repository has two types of code organization:

#### Type 1: Subdirectory-Based (Existing)
```
synpatictrading/                  (main repository)
├── src/
│   └── pilot/
│       └── nikhilwm-opt-v2/     ← V2 code lives here in main branch
│           ├── application/
│           ├── domain/
│           ├── infrastructure/
│           ├── src/
│           ├── run_backtest.py
│           └── v2_config.py
└── (other projects...)
```

**Commits on main branch:**
- `68cc1a4` docs: Add Docker deployment and nginx reverse proxy learnings
- `76851de` fix: Critical trade logic bugs - D0 prevention, orphan hedges
- Recent work by the team

#### Type 2: Root-Level Branch (Standalone)
```
pilot-synaptictrading-nitin       ← Your standalone branch
├── application/                   ← V2 code at root level
├── domain/
├── infrastructure/
├── src/
├── run_backtest.py
├── v2_config.py
└── documentation/
```

**Commits on your branch:**
- `197132b` feat: Add manual test server deployment scripts
- `7161338` chore: Add overnight risk mitigation validation results
- Your recent standalone development

### Key Difference

**Main Branch (`main`):**
- Full trading platform with multiple projects
- V2 code in `src/pilot/nikhilwm-opt-v2/`
- Shared by entire team

**Standalone Branch (`pilot-synaptictrading-nitin`):**
- V2 code at root level
- Self-contained development
- Your independent work stream

---

## Current State

### Your Local Repository
**Location:** `/Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading`

**Status:**
- Currently on branch: `Nitin`
- Has commits: 10+ commits with features
- Remote configured: `https://github.com/gtalknitin/synpatictrading.git`
- Not yet pushed to remote

**Recent commits:**
```
197132b feat: Add manual test server deployment scripts
7161338 chore: Add overnight risk mitigation validation results
1e7c881 chore: Add 3-month catastrophic override validation results
b0b43d0 chore: Add 21-month backtest validation results
```

### Remote Repository
**Branches available:**
- `main` - Production code with V2 in subdirectory
- (Your branch will be added after push)

---

## Setting Up Your Branch

### Step 1: Verify Your Local Setup

```bash
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading

# Check current status
git status
git branch -a
git log --oneline -5

# Verify remote
git remote -v
# Should show: origin  https://github.com/gtalknitin/synpatictrading.git
```

### Step 2: Prepare for Push

Before pushing, ensure:

```bash
# 1. All changes committed
git status
# Should show: "nothing to commit, working tree clean"

# 2. No large files
du -sh .git
# Should be reasonable size (< 500MB)

# 3. Check .gitignore is working
git status | grep -E "backtest_results|\.cache|__pycache__"
# Should show these as ignored
```

### Step 3: Choose Branch Strategy

**Option A: Keep as Standalone Branch (Recommended)**
```bash
# Rename your local branch to match remote naming
git branch -m Nitin pilot-synaptictrading-nitin

# Verify
git branch
# Should show: * pilot-synaptictrading-nitin
#              main
```

**Option B: Merge into Main Branch Structure**
```bash
# This is more complex - would require restructuring files
# Not recommended unless specifically needed
```

---

## Pushing Your Branch to GitHub

### Method 1: Direct Push (If You Have Write Access)

```bash
# Ensure you're on the right branch
git checkout pilot-synaptictrading-nitin

# Push to remote
git push -u origin pilot-synaptictrading-nitin

# If this succeeds, you'll see:
# Branch 'pilot-synaptictrading-nitin' set up to track remote branch
```

### Method 2: Handle Large Repository Issues

If the push fails due to size:

```bash
# Check repository size
du -sh .git

# Clean up unnecessary files
git gc --aggressive --prune=now

# Try incremental push
git push -u origin pilot-synaptictrading-nitin --verbose

# If still failing, check for large files
git rev-list --objects --all | \
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
  awk '/^blob/ {print substr($0,6)}' | sort --numeric-sort --key=2 | \
  tail -20
```

### Method 3: Using SSH (If HTTPS Fails)

```bash
# Change to SSH URL
git remote set-url origin git@github.com:gtalknitin/synpatictrading.git

# Ensure SSH key is set up
ssh -T git@github.com
# Should show: "Hi <username>! You've successfully authenticated..."

# Push with SSH
git push -u origin pilot-synaptictrading-nitin
```

### Verification After Push

```bash
# Check remote branches
git fetch origin
git branch -r

# Should now show:
#   origin/main
#   origin/pilot-synaptictrading-nitin

# Verify on GitHub
# Visit: https://github.com/gtalknitin/synpatictrading/branches
# Your branch should be listed
```

---

## Creating Feature Branches

### Branch Naming Convention

```
feature/<ticket-id>-<description>    # New features
bugfix/<ticket-id>-<description>     # Bug fixes
hotfix/<description>                 # Urgent fixes
experimental/<description>           # POC/experimental work
```

### Creating a Feature Branch

**From Your Standalone Branch:**

```bash
# Update your base branch
git checkout pilot-synaptictrading-nitin
git pull origin pilot-synaptictrading-nitin

# Create feature branch
git checkout -b feature/FEAT-100-enhance-vix-exits

# Make changes
# ... edit files ...

# Commit
git add .
git commit -m "feat: Enhance VIX exit logic with dynamic thresholds

- Add dynamic VIX threshold calculation
- Implement volatility regime detection
- Add comprehensive tests

Related: FEAT-100"

# Push feature branch
git push -u origin feature/FEAT-100-enhance-vix-exits
```

**From Main Branch:**

```bash
# Update main
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/FEAT-101-improve-entry-timing

# Navigate to V2 directory
cd src/pilot/nikhilwm-opt-v2

# Make changes
# ... edit files ...

# Commit (from repository root)
cd ../../..
git add src/pilot/nikhilwm-opt-v2/
git commit -m "feat: Improve entry timing logic

- Adjust entry window for hourly data
- Add entry timing validation
- Update tests

Related: FEAT-101"

# Push
git push -u origin feature/FEAT-101-improve-entry-timing
```

---

## Parallel Development Workflows

### Scenario 1: Multiple Developers on Standalone Branch

**Setup:**
```
pilot-synaptictrading-nitin (base branch)
├── feature/dev1-vix-exits        (Developer 1)
├── feature/dev2-entry-logic      (Developer 2)
└── feature/dev3-risk-management  (Developer 3)
```

**Developer 1 Workflow:**
```bash
# Clone and setup
git clone https://github.com/gtalknitin/synpatictrading.git
cd synpatictrading
git checkout pilot-synaptictrading-nitin

# Create feature branch
git checkout -b feature/dev1-vix-exits

# Work on feature
# ... make changes ...
git add .
git commit -m "feat: Add VIX exit enhancements"
git push origin feature/dev1-vix-exits

# Create pull request targeting pilot-synaptictrading-nitin
```

**Developer 2 & 3 follow same pattern**

### Scenario 2: Mixed Development (Some on Main, Some on Standalone)

**Team A: Working on main branch:**
```bash
git clone https://github.com/gtalknitin/synpatictrading.git
cd synpatictrading
git checkout -b feature/teamA-new-feature
# Work in src/pilot/nikhilwm-opt-v2/
git push origin feature/teamA-new-feature
# PR targets: main
```

**Team B: Working on standalone branch:**
```bash
git clone https://github.com/gtalknitin/synpatictrading.git
cd synpatictrading
git checkout pilot-synaptictrading-nitin
git checkout -b feature/teamB-new-feature
# Work in root directory
git push origin feature/teamB-new-feature
# PR targets: pilot-synaptictrading-nitin
```

### Scenario 3: Synchronizing Changes Between Branches

**Port changes from standalone to main:**
```bash
# Checkout main
git checkout main
git pull origin main

# Cherry-pick specific commits from standalone
git cherry-pick <commit-hash-from-standalone>

# Or merge specific files
git checkout pilot-synaptictrading-nitin -- src/strategy/entry_manager.py
git commit -m "integrate: Port entry_manager improvements from standalone"

# Push to main
git push origin main
```

**Port changes from main to standalone:**
```bash
# Checkout standalone
git checkout pilot-synaptictrading-nitin
git pull origin pilot-synaptictrading-nitin

# Cherry-pick from main
git cherry-pick <commit-hash-from-main>

# Or merge specific files
git checkout main -- src/pilot/nikhilwm-opt-v2/src/strategy/exit_manager.py
git mv src/pilot/nikhilwm-opt-v2/src/strategy/exit_manager.py src/strategy/
git commit -m "integrate: Port exit_manager improvements from main"

# Push
git push origin pilot-synaptictrading-nitin
```

---

## Branch Management

### Keeping Your Branch Up-to-Date

**Update standalone branch from origin:**
```bash
git checkout pilot-synaptictrading-nitin
git fetch origin
git merge origin/pilot-synaptictrading-nitin
# Or: git pull origin pilot-synaptictrading-nitin
```

**Update feature branch from base:**
```bash
git checkout feature/your-feature
git merge pilot-synaptictrading-nitin
# Resolve conflicts if any
git push origin feature/your-feature
```

### Resolving Merge Conflicts

```bash
# When merge creates conflicts
git status
# Shows conflicted files

# Edit each conflicted file
# Look for <<<<<<< HEAD markers
# Choose which changes to keep

# After resolving
git add <resolved-files>
git commit -m "merge: Resolve conflicts with base branch"
git push origin feature/your-feature
```

### Cleaning Up Merged Branches

```bash
# After feature is merged, delete local branch
git checkout pilot-synaptictrading-nitin
git branch -d feature/your-feature

# Delete remote branch
git push origin --delete feature/your-feature
```

### Listing All Branches

```bash
# Local branches
git branch

# Remote branches
git branch -r

# All branches
git branch -a

# Branches with last commit
git branch -v

# Branches merged into current
git branch --merged

# Branches not yet merged
git branch --no-merged
```

---

## Testing and Integration

### Pre-Merge Testing

**Before creating PR:**
```bash
# 1. Ensure branch is up-to-date
git checkout pilot-synaptictrading-nitin
git pull origin pilot-synaptictrading-nitin
git checkout feature/your-feature
git merge pilot-synaptictrading-nitin

# 2. Run all tests
pytest tests/ -v

# 3. Run backtest
python run_backtest.py

# 4. Check code quality
black . --check
flake8 .

# 5. Verify results
ls -la backtest_results/
```

### Integration Testing

**Test multiple features together:**
```bash
# Create integration branch
git checkout pilot-synaptictrading-nitin
git checkout -b integration/sprint-10

# Merge all features
git merge feature/feat1 --no-ff
git merge feature/feat2 --no-ff
git merge feature/feat3 --no-ff

# Run comprehensive tests
pytest tests/ -v --cov=src
python run_backtest.py

# If all good, merge features to base branch individually
```

### Deployment Testing

**Deploy feature to test server:**
```bash
# Use deployment script (see MULTI_DEVELOPER_WORKFLOW.md)
./scripts/deploy_to_test.sh dev1 feature/your-feature

# Or manual deployment
ssh test-server
cd /opt/deployments/dev1
git fetch origin
git checkout feature/your-feature
git pull origin feature/your-feature
systemctl restart nikhilwm-dev1
```

---

## Best Practices

### Commit Best Practices

```bash
# Atomic commits - one logical change per commit
git add src/strategy/entry_manager.py
git commit -m "feat: Add VIX threshold validation"

git add tests/test_entry_manager.py
git commit -m "test: Add tests for VIX threshold validation"

# Not this:
git add .
git commit -m "Fixed stuff and added things"
```

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Adding tests
- `refactor`: Code restructuring
- `chore`: Maintenance tasks

**Example:**
```
feat(exit-manager): Add dynamic VIX exit thresholds

- Calculate VIX threshold based on recent volatility
- Add regime detection (low/medium/high volatility)
- Update exit logic to use dynamic threshold
- Add comprehensive unit tests

Related: FEAT-100
Closes: #45
```

### Branch Lifecycle

```
1. Create from base
   git checkout -b feature/my-feature

2. Develop & commit regularly
   git commit -m "..."

3. Push to remote regularly
   git push origin feature/my-feature

4. Keep up-to-date with base
   git merge pilot-synaptictrading-nitin

5. Create PR when ready
   (via GitHub UI)

6. Address review comments
   git commit -m "review: Address feedback"
   git push origin feature/my-feature

7. Merge after approval
   (via GitHub UI)

8. Delete branch after merge
   git branch -d feature/my-feature
   git push origin --delete feature/my-feature
```

### Code Review Guidelines

**Before requesting review:**
- [ ] All tests pass
- [ ] Code is formatted (black)
- [ ] No linting errors (flake8)
- [ ] Backtest runs successfully
- [ ] Documentation updated
- [ ] Commit messages clear
- [ ] Branch up-to-date with base

**When reviewing:**
- [ ] Code quality acceptable
- [ ] Tests comprehensive
- [ ] No breaking changes (or documented)
- [ ] Performance acceptable
- [ ] Security considerations addressed

### Parallel Development Etiquette

**Do:**
- Communicate with team about what you're working on
- Keep branches small and focused
- Merge base branch frequently
- Test before creating PRs
- Respond to review comments promptly
- Update documentation

**Don't:**
- Work on same files as another developer without coordination
- Let branches get stale (> 1 week without merging base)
- Create massive PRs (> 500 lines without justification)
- Force push to shared branches
- Ignore test failures
- Skip code review

---

## Quick Reference Commands

### Setup
```bash
# Clone repository
git clone https://github.com/gtalknitin/synpatictrading.git
cd synpatictrading

# Checkout standalone branch
git checkout pilot-synaptictrading-nitin

# Create feature branch
git checkout -b feature/my-feature
```

### Daily Workflow
```bash
# Start of day - update base
git checkout pilot-synaptictrading-nitin
git pull origin pilot-synaptictrading-nitin
git checkout feature/my-feature
git merge pilot-synaptictrading-nitin

# Work & commit
git add .
git commit -m "feat: Description"

# Push regularly
git push origin feature/my-feature

# End of day - ensure pushed
git push origin feature/my-feature
```

### Testing
```bash
# Run tests
pytest tests/ -v

# Run backtest
python run_backtest.py

# Check code quality
black . --check
flake8 .
```

### Branch Management
```bash
# List branches
git branch -a

# Switch branch
git checkout branch-name

# Delete branch
git branch -d branch-name

# Force delete
git branch -D branch-name
```

---

## Troubleshooting

### Push Rejected

```bash
# If push is rejected due to non-fast-forward
git pull origin feature/my-feature --rebase
git push origin feature/my-feature
```

### Conflicts During Merge

```bash
# See conflicted files
git status

# Abort merge if needed
git merge --abort

# Or resolve conflicts
# Edit files, then:
git add <resolved-files>
git commit
```

### Accidentally Committed to Wrong Branch

```bash
# Save the commit
git log  # Note commit hash

# Reset current branch
git reset --hard HEAD~1

# Switch to correct branch
git checkout correct-branch
git cherry-pick <commit-hash>
```

### Branch Diverged from Remote

```bash
# See divergence
git status

# Merge remote changes
git pull origin feature/my-feature

# Or rebase (if no one else is using branch)
git pull origin feature/my-feature --rebase
```

---

## Summary

**Key Points:**

1. **Two Development Modes:**
   - Main branch: Work in `src/pilot/nikhilwm-opt-v2/`
   - Standalone branch: Work at root level

2. **Branch Strategy:**
   - Base branches: `main` and `pilot-synaptictrading-nitin`
   - Feature branches: Created from base, merged back after PR approval

3. **Parallel Development:**
   - Multiple developers can work simultaneously
   - Each on their own feature branch
   - Regular syncing with base branch prevents conflicts

4. **Best Practices:**
   - Small, focused branches
   - Regular commits and pushes
   - Comprehensive testing before PRs
   - Clear communication with team

**Next Steps:**

1. Push your `pilot-synaptictrading-nitin` branch to remote
2. Verify on GitHub
3. Create feature branches as needed
4. Follow parallel development workflows
5. Refer to MULTI_DEVELOPER_WORKFLOW.md for team collaboration details

---

**Document Version:** 1.0
**Last Updated:** 2025-10-07
**Maintained By:** Synapse Trading Development Team
