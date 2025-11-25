---
artifact_type: story
created_at: '2025-11-25T16:23:21.542782Z'
id: AUTO-CLAUDE
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for CLAUDE
updated_at: '2025-11-25T16:23:21.542786Z'
---
# CLAUDE.md - SynapticTrading Vault Guide

This file provides guidance to Claude Code (claude.ai/code) when working with the SynapticTrading vault and its associated code repositories.

## Vault-Code Synchronization Standards

### CRITICAL REQUIREMENT: Real-Time Vault Updates

**The vault is the single source of truth.** Any work completed in code MUST be immediately reflected in the vault status.

### Mandatory Process After Completing Work

1. **After EACH Task**:
   ```bash
   # Update task status in vault
   # Edit: vault_epics/EPIC-XXX/Features/FEATURE-XXX/Stories/STORY-XXX/Tasks/TASK-XXX.md
   # Set: status: completed
   ```

2. **After EACH Story**:
   ```bash
   # Update story status and run sync
   make sync-status
   git add documentation/vault_*
   git commit -m "[STORY-XXX] Update vault status to completed"
   ```

3. **After EACH Feature**:
   ```bash
   # Update feature and verify all sync
   make sync-status
   make check-status  # MUST pass before proceeding
   ```

### Pre-Commit Enforcement

**EVERY commit must pass vault-code sync checks**:
- The pre-commit hook runs `make check-status`
- If it fails, you MUST run `make sync-status` first
- Never use `--no-verify` to skip this check

### Common Sync Commands

```bash
# Check if vault matches code
make check-status

# Update vault based on sprint/code progress  
make sync-status

# Force sync with verbose output
make sync-status --verbose --force

# Check specific feature
make check-status --feature FEATURE-XXX
```

### Manual Update Protection

For completed work, add to frontmatter:
```yaml
manual_update: true
completed_at: 2025-11-21T10:00:00Z
```

This prevents automated sync from reverting completed status.

## Current Known Issues

### EPIC-007 Progress Discrepancy (as of 2025-11-21)

**Issue**: Vault shows 17% complete but actual progress is 50%
- **Completed**: FEATURE-006, FEATURE-001, FEATURE-002  
- **Action Required**: Run `make sync-status` in main repository

### Performance Monitoring Relocation

**Issue**: Performance monitoring was implemented under EPIC-007/FEATURE-004
- **Correct Location**: EPIC-008/FEATURE-002-PerformanceAnalytics
- **Status**: Already relocated and marked complete

## Definition of Done Includes Vault Update

No work is considered "done" until:
1. ✅ Code is implemented and tested
2. ✅ Vault status is updated to reflect completion
3. ✅ `make check-status` passes
4. ✅ Changes are committed (including vault updates)

## Troubleshooting Sync Issues

### "Vault shows different progress than code"
```bash
# 1. Check sprint records (often more accurate)
cd documentation/vault_sprints/
grep -r "progress_pct" .

# 2. Force sync
make sync-status --force

# 3. Check for manual_update flags blocking sync
grep -r "manual_update" documentation/vault_epics/
```

### "Pre-commit hook keeps failing"
```bash
# 1. See what's out of sync
make check-status --verbose

# 2. Update vault 
make sync-status

# 3. Try again
git commit
```

## Best Practices

1. **Update Immediately**: Don't wait until end of sprint
2. **Include in PRs**: Vault updates must be part of the PR
3. **Document Exceptions**: If skipping sync, explain why in commit message
4. **Review Sprint Records**: They often have more accurate progress

## References

- [UPMS Vault-Code Sync Standards](/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/Methodology/Vault_Code_Sync_Standards.md)
- [Status Sync Tool](scripts/tools/status_sync.py)
- [Sprint Records](documentation/vault_sprints/)

---

**Remember**: If it's not in the vault, it didn't happen. If it happened but isn't in the vault, fix it NOW.