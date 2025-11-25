---
artifact_type: story
created_at: '2025-11-25T16:23:21.884488Z'
id: AUTO-GIT_WORKFLOW_GUIDE
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for GIT_WORKFLOW_GUIDE
updated_at: '2025-11-25T16:23:21.884492Z'
---

## Overview

This guide documents our git workflow for feature development using:
- **Feature branches** for isolated development
- **Git worktrees** for parallel work on multiple features
- **Pull requests** for code review and integration

### Core Principles

1. **Main branch is always deployable** - Never commit directly to main
2. **Feature branches for all work** - Isolate changes until ready for review
3. **Code review is mandatory** - All changes go through PR process
4. **Worktrees for parallel work** - Work on multiple features simultaneously
5. **Clean history** - Meaningful commits, clear PR descriptions

---

## Feature Branch Workflow

### What is a Feature Branch?

A feature branch is a dedicated branch for developing a specific feature, bug fix, or experiment. It isolates your work from the main codebase until it's ready for integration.

### Why Use Feature Branches?

✅ **Benefits**:
- Main branch stays stable and deployable
- Multiple developers can work independently
- Easy to review changes in isolation
- Simple to discard failed experiments
- Clear history of what changed and why

### Branch Naming Conventions

Use descriptive, consistent names:

```bash
# Format: <type>/<description>
feature/user-authentication
feature/epic-007-data-pipeline
fix/payment-gateway-timeout
hotfix/critical-security-patch
refactor/database-schema
docs/api-documentation
```

**Types**:
- `feature/` - New functionality
- `fix/` - Bug fixes
- `hotfix/` - Urgent production fixes
- `refactor/` - Code improvements without behavior changes
- `docs/` - Documentation only
- `test/` - Test additions/improvements
- `chore/` - Build, CI, or maintenance tasks

### Standard Feature Branch Workflow

#### 1. Create Feature Branch

```bash
# Update main first
git checkout main
git pull origin main

# Create and switch to feature branch
git checkout -b feature/my-new-feature

# Or in one command
git checkout -b feature/my-new-feature origin/main
```

#### 2. Work on Feature

```bash
# Make changes to files
# ...

# Stage changes
git add <files>

# Commit with descriptive message
git commit -m "[FEATURE] Add user authentication

- Implement JWT token generation
- Add login/logout endpoints
- Create user session management

Refs: #123"
```

#### 3. Keep Branch Updated

```bash
# Fetch latest changes from remote
git fetch origin

# Rebase on main to stay current (if no conflicts expected)
git rebase origin/main

# Or merge main into your branch (safer for shared branches)
git merge origin/main
```

#### 4. Push to Remote

```bash
# First push: create remote branch
git push -u origin feature/my-new-feature

# Subsequent pushes
git push
```

#### 5. Create Pull Request

```bash
# Using GitHub CLI (recommended)
gh pr create --title "Add user authentication" --body "Detailed description..."

# Or via GitHub web interface
# Navigate to repository → "Compare & pull request"
```

#### 6. After PR Merged

```bash
# Switch back to main
git checkout main

# Update local main
git pull origin main

# Delete local feature branch
git branch -d feature/my-new-feature

# Delete remote feature branch (if not auto-deleted)
git push origin --delete feature/my-new-feature
```

---

## Git Worktrees

### What is a Git Worktree?

A worktree allows you to have **multiple working directories** for the same repository, each checking out a different branch. This enables parallel development without switching branches.

### Why Use Worktrees?

✅ **Benefits**:
- Work on multiple features simultaneously
- Review PRs without stashing current work
- Run tests on one branch while developing on another
- Compare implementations side-by-side
- No context switching between branches

⚠️ **When NOT to Use Worktrees**:
- For quick branch switches (just use `git checkout`)
- If you'll have 20+ worktrees (too much clutter)
- For temporary exploratory work (use regular branches)

### Worktree Commands

#### List Worktrees

```bash
git worktree list

# Example output:
# /Users/dev/project           abc1234 [main]
# /Users/dev/project-feature1  def5678 [feature/auth]
# /Users/dev/project-feature2  ghi9012 [feature/payments]
```

#### Add Worktree

```bash
# Create new worktree in ../project-feature directory
git worktree add ../project-feature feature/my-feature

# Create worktree and new branch at once
git worktree add -b feature/new-feature ../project-feature

# Create worktree from specific commit
git worktree add ../project-hotfix abc1234
```

#### Remove Worktree

```bash
# Remove worktree (after committing/pushing work)
git worktree remove ../project-feature

# Force remove (discards uncommitted changes)
git worktree remove --force ../project-feature

# Clean up stale worktree references
git worktree prune
```

### Worktree Best Practices

#### 1. **Consistent Directory Naming**

```bash
# Good: Clear, predictable structure
/CodeRepository/
├── SynapticTrading/              # main branch
├── SynapticTrading-epic-007/     # epic-007-data-pipeline branch
├── SynapticTrading-epic-002/     # epic-002-backtesting branch
└── SynapticTrading-hotfix-123/   # hotfix branch

# Avoid: Random, unclear names
/CodeRepository/
├── myproject/
├── test/
├── temp/
└── stuff/
```

#### 2. **Short-Lived Worktrees**

```bash
# Create worktree
git worktree add ../project-review feature/auth

# Do the work (review PR, test, etc.)
cd ../project-review
# ... work ...

# Clean up when done
cd ../project
git worktree remove ../project-review
```

**Don't** keep 20 worktrees lying around indefinitely!

#### 3. **Worktree Workflow Example**

**Scenario**: You're working on `feature/payments` when a PR needs review.

```bash
# Currently in main worktree, working on payments
cd /CodeRepository/SynapticTrading
git branch --show-current  # feature/payments

# Create worktree for PR review
git worktree add ../SynapticTrading-pr-review feature/auth

# Review the PR in separate worktree
cd ../SynapticTrading-pr-review
# ... review code, run tests, etc. ...

# Return to your work without losing context
cd /CodeRepository/SynapticTrading
# Still on feature/payments, nothing changed

# After review complete, clean up
git worktree remove ../SynapticTrading-pr-review
```

#### 4. **Common Use Cases**

**PR Review**:
```bash
# Create temporary worktree for review
git worktree add ../project-pr-123 pr-branch

# Review, test, comment
cd ../project-pr-123
make test

# Clean up after review
cd ../project
git worktree remove ../project-pr-123
```

**Parallel Feature Development**:
```bash
# Working on feature A in main worktree
cd /CodeRepository/project

# Need to work on feature B simultaneously
git worktree add ../project-feature-b feature/feature-b

# Switch between them as needed
cd /CodeRepository/project          # Feature A
cd /CodeRepository/project-feature-b  # Feature B
```

**Emergency Hotfix**:
```bash
# You're mid-development on feature branch
# Critical bug reported in production

# Create worktree for hotfix
git worktree add ../project-hotfix main
cd ../project-hotfix

# Fix the bug
git checkout -b hotfix/critical-bug
# ... fix bug ...
git commit -m "Fix critical bug"
git push -u origin hotfix/critical-bug

# Create PR for hotfix (fast-track review)
gh pr create --title "HOTFIX: Critical bug" --base main

# Return to feature work
cd /CodeRepository/project
# Continue where you left off
```

### Worktree Anti-Patterns

❌ **Don't: Create Too Many Worktrees**

```bash
# Bad: 20 worktrees, all stale
git worktree list | wc -l  # → 20
```

❌ **Don't: Use Worktrees for Quick Switches**

```bash
# Bad: Creating worktree just to check something
git worktree add ../project-temp main
cd ../project-temp
cat README.md
cd ../project
git worktree remove ../project-temp

# Good: Just switch branches
git checkout main
cat README.md
git checkout feature/my-feature
```

❌ **Don't: Forget to Clean Up**

```bash
# Bad: Worktree directory deleted manually, git still references it
rm -rf ../project-feature
git worktree list  # Still shows the worktree!

# Good: Use git to remove
git worktree remove ../project-feature
# Or clean up stale references
git worktree prune
```

---

## Pull Request Process

### Why Pull Requests?

Pull requests (PRs) are the industry standard for code integration because they:

✅ **Quality Gates**:
- Code review before merge
- Automated testing (CI/CD)
- Security scans
- Code quality checks

✅ **Collaboration**:
- Team awareness of changes
- Discussion and feedback
- Knowledge sharing
- Documentation of decisions

✅ **Safety**:
- Prevents broken code in main
- Easy to revert if needed
- Audit trail of changes

### PR Workflow

#### 1. **Before Creating PR**

```bash
# Ensure branch is up to date
git checkout feature/my-feature
git fetch origin
git rebase origin/main  # or git merge origin/main

# Run tests locally
make test

# Push latest changes
git push
```

#### 2. **Create Pull Request**

**Using GitHub CLI** (Recommended):

```bash
gh pr create \
  --title "Add user authentication" \
  --body "## Summary
- Implements JWT token generation
- Adds login/logout endpoints
- Includes unit and integration tests

## Test Plan
- All tests passing (180/180)
- Manually tested login flow
- Security scan passed

## Related Issues
Closes #123

## Checklist
- [x] Tests added
- [x] Documentation updated
- [x] No breaking changes"
```

**Using GitHub Web Interface**:

1. Navigate to repository
2. Click "Compare & pull request" (appears after pushing)
3. Fill in:
   - Title: Clear, concise description
   - Description: Summary, test plan, related issues
   - Reviewers: Assign team members
   - Labels: Add appropriate labels
   - Milestone: Link to sprint/milestone

#### 3. **PR Title Format**

Use clear, standardized titles:

```bash
# Good PR titles
Add user authentication with JWT
Fix payment gateway timeout issue
Refactor database connection pool
Update API documentation for v2.0

# Bad PR titles
Fixed stuff
Updates
WIP
asdf
```

#### 4. **PR Description Template**

```markdown
## Summary
Brief description of what changed and why.

## Changes
- Bullet point list of key changes
- Makes it easy for reviewers to understand scope

## Test Plan
How was this tested? What scenarios were covered?

## Screenshots (if UI changes)
Before/after screenshots for visual changes

## Related Issues
Closes #123
Refs #456

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Breaking changes noted
- [ ] Security considerations addressed
```

#### 5. **PR Review Process**

**As Author**:
- Respond promptly to feedback
- Address all comments
- Update PR based on review
- Mark conversations as resolved
- Request re-review when ready

**As Reviewer**:
- Review within 24 hours
- Be constructive and specific
- Approve or request changes
- Test changes locally if needed
- Check for:
  - Code quality
  - Test coverage
  - Documentation
  - Security issues
  - Performance impacts

#### 6. **After PR Approved**

**On GitHub**:
1. Click "Merge pull request"
2. Choose merge strategy:
   - **Merge commit** (default): Preserves all commits + merge commit
   - **Squash and merge**: Combines all commits into one
   - **Rebase and merge**: Linear history without merge commit
3. Confirm merge
4. Delete branch (optional, recommended)

**Locally**:
```bash
# Update local main
git checkout main
git pull origin main

# Delete local feature branch
git branch -d feature/my-feature

# Verify merge
git log --oneline -5
```

### PR Best Practices

#### **1. Open PRs Early**

Open PRs as "Draft" early in development for early feedback:

```bash
gh pr create --draft --title "WIP: Add user authentication"
```

**Benefits**:
- Early feedback on approach
- Continuous discussion
- Parallel review as you develop
- Mark as "Ready for review" when done

#### **2. Keep PRs Small**

**Good PR sizes**:
- **Small**: <200 lines (ideal for quick review)
- **Medium**: 200-500 lines (standard feature)
- **Large**: 500-1000 lines (acceptable if unavoidable)
- **Too Large**: >1000 lines (hard to review effectively)

**How to keep PRs small**:
- Break features into smaller stories
- Use feature flags for incremental delivery
- Separate refactoring from new features
- Split infrastructure changes from application changes

#### **3. Write Meaningful Commit Messages**

```bash
# Good commits
git commit -m "[FEATURE] Add JWT token generation

Implements token generation using HS256 algorithm:
- Token expiration configurable via environment
- Refresh token support added
- Tests cover edge cases (expired tokens, invalid signatures)

Refs: #123"

# Bad commits
git commit -m "fix"
git commit -m "updates"
git commit -m "WIP"
```

#### **4. Automate Quality Checks**

Configure GitHub Actions / CI/CD to run:
- Unit tests
- Integration tests
- Linting (ruff, black)
- Type checking (mypy)
- Security scans
- Code coverage reports

**Example `.github/workflows/pr-checks.yml`**:
```yaml
name: PR Checks
on: [pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: |
          make test
          make lint
          make type-check
```

#### **5. Link PRs to Issues**

```markdown
## In PR description:
Closes #123
Fixes #456
Resolves #789
Refs #101
```

**Benefits**:
- Automatic issue closure on merge
- Clear traceability
- Easy to understand context

---

## Best Practices

### General Git Hygiene

#### **1. Commit Frequently**

```bash
# Good: Small, logical commits
git commit -m "Add User model"
git commit -m "Add authentication middleware"
git commit -m "Add login endpoint"

# Bad: One huge commit
git commit -m "Add entire authentication system"
```

#### **2. Write Descriptive Commit Messages**

**Format**:
```
[TYPE] Short summary (50 chars or less)

Longer description explaining:
- What changed and why
- Any important context
- Breaking changes or deprecations

Refs: #issue-number
```

**Example**:
```bash
git commit -m "[FEATURE] Add user authentication with JWT

Implements complete JWT-based authentication system:
- Token generation using HS256 algorithm
- Refresh token support for long-lived sessions
- Password hashing using bcrypt
- Rate limiting on login attempts

Breaking Changes:
- API now requires Authorization header for protected endpoints
- Old session-based auth deprecated (remove in v2.0)

Security:
- Tokens expire after 1 hour (configurable)
- Refresh tokens stored in httpOnly cookies
- CSRF protection enabled

Testing:
- 45 new tests covering auth flows
- Security tests for common attacks (XSS, CSRF, injection)

Refs: #123, #124
Closes #125"
```

#### **3. Pull Before Push**

```bash
# Always pull before pushing
git pull origin feature/my-feature

# Resolve any conflicts
# Then push
git push
```

#### **4. Use .gitignore Properly**

Never commit:
- Environment files (`.env`)
- Build artifacts (`dist/`, `build/`)
- Dependencies (`node_modules/`, `venv/`)
- IDE settings (`.vscode/`, `.idea/`)
- Secrets or credentials
- Large binary files
- OS files (`.DS_Store`, `Thumbs.db`)

#### **5. Review Your Changes Before Committing**

```bash
# See what changed
git diff

# See what's staged
git diff --staged

# Interactive staging (pick specific changes)
git add -p

# Review commit before pushing
git show
```

### Team Collaboration

#### **1. Never Force Push to Shared Branches**

```bash
# ❌ NEVER on main or shared branches
git push --force origin main

# ❌ NEVER on someone else's branch
git push --force origin their-feature

# ✅ OK on your own feature branch (if no one else is using it)
git push --force origin my-feature
```

#### **2. Communicate About Rebases**

If you rebase a shared branch:
```bash
# Notify team before rebasing
# "Hey team, rebasing feature/auth branch in 5 minutes"

git rebase origin/main
git push --force-with-lease origin feature/auth

# Notify team after
# "Rebase complete, please run: git pull --rebase origin feature/auth"
```

#### **3. Use Branch Protection**

Configure on GitHub:
- Require PR reviews before merge
- Require status checks to pass
- Require branches to be up to date
- Require signed commits
- Restrict who can push to main

#### **4. Delete Merged Branches**

```bash
# Delete local branches
git branch -d feature/completed-feature

# Delete remote branches
git push origin --delete feature/completed-feature

# Clean up tracking branches
git fetch --prune
```

---

## Common Pitfalls

### Pitfall 1: Committing to Main by Accident

**Problem**:
```bash
# You're on main, make changes
pwd  # Forgot to check which directory!
git add .
git commit -m "Add feature"
# Oh no, committed to main!
```

**Prevention**:
```bash
# ALWAYS check before committing
pwd && git branch --show-current

# Or add to git prompt (zsh example)
# Shows current branch in terminal prompt
```

**Fix**:
```bash
# If not pushed yet
git reset --soft HEAD~1  # Uncommit, keep changes
git checkout -b feature/my-feature  # Create feature branch
git commit -m "Add feature"  # Recommit on feature branch

# If already pushed (requires force push, be careful!)
git reset --hard HEAD~1
git push --force origin main  # ⚠️ Only if no one else pulled!
```

### Pitfall 2: Working in Wrong Worktree

**Problem**:
```bash
# Think you're in worktree, but in main repo
cd ~/projects
git commit -m "Add feature"
# Oops, committed to wrong branch!
```

**Prevention**:
```bash
# ALWAYS verify location and branch
pwd && git branch --show-current

# Output should match expectations
# /path/to/project-feature && feature/my-feature
```

**Fix**: Same as Pitfall 1

### Pitfall 3: Merge Conflicts

**Problem**:
```bash
git merge origin/main
# CONFLICT (content): Merge conflict in file.py
```

**Resolution**:
```bash
# 1. See which files have conflicts
git status

# 2. Open conflicted files, look for markers:
# <<<<<<< HEAD
# Your changes
# =======
# Their changes
# >>>>>>> origin/main

# 3. Resolve conflicts manually

# 4. Stage resolved files
git add file.py

# 5. Complete merge
git commit
```

**Prevention**:
- Pull/rebase frequently
- Keep PRs small
- Communicate about shared files

### Pitfall 4: Forgetting to Push

**Problem**:
```bash
# You committed locally, but didn't push
git commit -m "Add feature"
# Walk away, think it's on remote
# It's not!
```

**Prevention**:
```bash
# Always check after commit
git status  # Shows "Your branch is ahead of 'origin/...' by 1 commit"

# Push immediately
git push
```

### Pitfall 5: Lost Worktree After Directory Deletion

**Problem**:
```bash
# Manually delete worktree directory
rm -rf ../project-feature

# Git still thinks it exists
git worktree list  # Still shows ../project-feature
```

**Fix**:
```bash
# Clean up stale worktree references
git worktree prune

# Or force remove
git worktree remove --force ../project-feature
```

**Prevention**:
```bash
# ALWAYS use git to remove worktrees
git worktree remove ../project-feature
```

---

## Troubleshooting

### Issue: "fatal: 'origin' does not appear to be a git repository"

**Cause**: Remote origin not configured

**Fix**:
```bash
# Check remotes
git remote -v

# Add origin
git remote add origin https://github.com/user/repo.git

# Or change existing origin
git remote set-url origin https://github.com/user/repo.git
```

### Issue: "error: failed to push some refs"

**Cause**: Remote has changes you don't have locally

**Fix**:
```bash
# Pull first
git pull origin branch-name

# Resolve conflicts if any
# Then push
git push
```

### Issue: "fatal: refusing to merge unrelated histories"

**Cause**: Trying to merge branches with no common ancestor

**Fix**:
```bash
# Allow merging unrelated histories (rare, usually on initial setup)
git pull origin main --allow-unrelated-histories
```

### Issue: Can't delete branch - "error: branch not fully merged"

**Cause**: Branch has commits not in main

**Fix**:
```bash
# If you're sure you want to delete
git branch -D branch-name  # Force delete

# If you want to save the work
git merge branch-name  # Merge it first
# Then delete
git branch -d branch-name
```

### Issue: Worktree still shows after deletion

**Cause**: Directory deleted manually instead of via git

**Fix**:
```bash
# Clean up stale worktree references
git worktree prune
```

---

## Quick Reference

### Essential Commands

```bash
# FEATURE BRANCHES
git checkout -b feature/name       # Create feature branch
git push -u origin feature/name    # Push to remote
git merge origin/main              # Update from main
git push                          # Push changes

# WORKTREES
git worktree list                 # List all worktrees
git worktree add ../path branch   # Create worktree
git worktree remove ../path       # Remove worktree
git worktree prune                # Clean up stale worktrees

# PULL REQUESTS
gh pr create                      # Create PR (GitHub CLI)
gh pr list                        # List PRs
gh pr view 123                    # View PR details
gh pr checkout 123                # Check out PR locally
gh pr merge 123                   # Merge PR

# STATUS & CLEANUP
git status                        # Check current state
git log --oneline -10             # View recent commits
git branch -d branch-name         # Delete local branch
git push origin --delete branch   # Delete remote branch
git fetch --prune                 # Clean up stale remote refs
```

### Workflow Cheat Sheet

**Starting New Feature**:
```bash
git checkout main
git pull origin main
git checkout -b feature/my-feature
# ... work ...
git add .
git commit -m "Descriptive message"
git push -u origin feature/my-feature
gh pr create
```

**PR Review (with Worktree)**:
```bash
git worktree add ../project-review feature-to-review
cd ../project-review
# ... review ...
cd ../project
git worktree remove ../project-review
```

**After PR Merged**:
```bash
git checkout main
git pull origin main
git branch -d feature/my-feature
```

### Pre-Commit Checklist

Before every commit:
- [ ] `pwd && git branch --show-current` - Verify location and branch
- [ ] `git status` - Review what's being committed
- [ ] `git diff --staged` - Review changes
- [ ] `make test` - Run tests locally (if applicable)
- [ ] Write clear commit message
- [ ] `git push` - Don't forget to push!

### Pre-PR Checklist

Before creating PR:
- [ ] Branch is up to date with main
- [ ] All tests passing
- [ ] Code formatted/linted
- [ ] Documentation updated
- [ ] Commit messages are clear
- [ ] Ready for review (not WIP)

---

## Resources

### Official Documentation
- [Git Documentation](https://git-scm.com/doc)
- [GitHub Docs - Pull Requests](https://docs.github.com/en/pull-requests)
- [Git Worktree](https://git-scm.com/docs/git-worktree)
- [GitHub CLI](https://cli.github.com/)

### Best Practices
- [Atlassian Git Tutorials](https://www.atlassian.com/git/tutorials)
- [GitHub Flow](https://docs.github.com/en/get-started/quickstart/github-flow)
- [Conventional Commits](https://www.conventionalcommits.org/)

### Internal Resources
- Project CLAUDE.md - Repository-specific guidelines
- Team Wiki - Process documentation
- Slack #engineering - Ask questions

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-19 | 1.0 | Initial version with feature branch, worktree, and PR workflows | Claude Code |

---

## Feedback

This is a living document. If you find issues or have suggestions:
- Open an issue: [Link to issue tracker]
- Submit a PR to update this doc
- Reach out on Slack: #engineering
