---
artifact_type: story
created_at: '2025-11-25T16:23:21.880801Z'
git add . && git commit -m "fix: Something"
id: AUTO-README
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for README
updated_at: '2025-11-25T16:23:21.880805Z'
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
