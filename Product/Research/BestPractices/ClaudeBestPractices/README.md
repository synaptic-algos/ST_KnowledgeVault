# Claude Code Best Practices

This directory contains best practices, tips, and workflows for using Claude Code effectively with this project.

## Contents

### [Git Worktrees for Parallel Claude Sessions](./GIT_WORKTREES_FOR_PARALLEL_CLAUDE_SESSIONS.md)

**Comprehensive guide on using Git worktrees to run multiple Claude Code sessions in parallel.**

**Perfect for:**
- Working on multiple issues simultaneously
- Running parallel Claude sessions without conflicts
- Managing work across multiple computers
- Quickly switching contexts without stashing

**Key Features:**
- ✅ Complete tutorial from beginner to advanced
- ✅ Multi-computer workflow examples
- ✅ Automation scripts included
- ✅ Troubleshooting guide
- ✅ Project-specific configurations

### [Local Merge Workflow](./LOCAL_MERGE_WORKFLOW.md)

**Step-by-step guide for merging branches locally without GitHub PRs.**

**Learn how to:**
- Merge feature branches into main locally
- Handle merge conflicts effectively
- Test changes before and after merge
- Understand fast-forward vs three-way merges
- Clean up after successful merges

**Perfect for:**
- Solo development
- Quick iterations
- Local experimentation
- Testing multiple approaches

### [Quick Reference Guide](./QUICK_REFERENCE.md)

**One-page cheat sheet for common worktree operations.**

---

## Quick Start

```bash
# Create worktree for new issue
./scripts/worktree/create_worktree.sh 123 "RSI fix"

# List all worktrees
./scripts/worktree/list_worktrees.sh

# Work in worktree, then merge locally
cd ../worktrees/issue-123-rsi-fix
# ... make changes ...
git add . && git commit -m "fix: Something"
cd /Users/nitindhawan/Downloads/CodeRepository/pilot-synaptictrading
git checkout main && git merge issue-123-rsi-fix && git push origin main

# Cleanup merged worktrees
./scripts/worktree/cleanup_merged_worktrees.sh
```

---

## Helper Scripts

All helper scripts are located in `/scripts/worktree/` directory:

### 1. `create_worktree.sh`
Creates a new worktree with proper structure and symlinks.

```bash
./scripts/worktree/create_worktree.sh <issue-number> <description>

# Example:
./scripts/worktree/create_worktree.sh 123 "RSI fix"
```

**What it does:**
- Creates worktree in `/worktrees/` directory
- Creates symlinks to data catalogs
- Sets up proper branch naming
- Shows next steps

### 2. `list_worktrees.sh`
Lists all active worktrees with detailed status.

```bash
./scripts/worktree/list_worktrees.sh
```

**Shows:**
- Worktree path and branch
- Last commit time and message
- Changed files count
- Staged/unstaged/untracked files

### 3. `cleanup_merged_worktrees.sh`
Cleans up worktrees for branches merged to main.

```bash
./scripts/worktree/cleanup_merged_worktrees.sh
```

**What it does:**
- Finds all merged branches
- Removes their worktrees
- Deletes merged branches
- Prunes stale references

---

## Contributing

When adding new best practices documents:

1. **Create descriptive filename:** Use `UPPERCASE_WITH_UNDERSCORES.md`
2. **Add to this README:** Update the Contents section
3. **Include examples:** Practical, project-specific examples
4. **Test instructions:** Verify all commands work
5. **Add scripts if needed:** Place in `/scripts/worktree/` directory

---

## Document Standards

All documents in this directory should:

- ✅ Have clear table of contents
- ✅ Include quick start section
- ✅ Provide practical examples
- ✅ Address troubleshooting
- ✅ Link to related documentation
- ✅ Be specific to this project

---

## Related Documentation

- **Project Setup:** `/documentation/guides/`
- **Nautilus Best Practices:** `/documentation/nautilusbestpractices/`
- **Deployment:** `/documentation/deployment/`
- **Main README:** `/CLAUDE.md`

---

## Feedback

Found an issue with these practices or have a suggestion?

1. Create an issue in `/issues/identified/`
2. Use tag: `[DOCUMENTATION]`
3. Reference the specific document

---

Last Updated: 2025-10-26
