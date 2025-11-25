# ACTION PLAN: Fix Vault-Code Sync and EPIC-007 Progress

**Created**: 2025-11-21  
**Priority**: URGENT  
**Owner**: Development Team

## Current Issues

1. **EPIC-007 shows 17% complete in vault but actually 50% complete**
   - FEATURE-001, FEATURE-002, FEATURE-006 are all complete
   - Sprint records show completion but vault not updated

2. **Code exists in SynapticTrading repo but not in theplatform repo**
   - Implementation in `/Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/src/strategy_lifecycle/`
   - But theplatform-epic-007 branch was empty

3. **Process gap allowed vault to drift from reality**
   - No enforcement of vault updates after work completion
   - Pre-commit hooks not catching sync issues

## Required Actions

### 1. Immediate Fix for EPIC-007 Progress

```bash
# In SynapticTrading main repository
cd /Users/nitindhawan/Downloads/CodeRepository/SynapticTrading

# Update vault to reflect actual progress
make sync-status

# Verify all features show correct status
make check-status

# Commit the vault updates
git add documentation/vault_*
git commit -m "[EPIC-007] Sync vault status to match completed work (50% complete)

- FEATURE-001: Research Pipeline (100% complete)
- FEATURE-002: Prioritisation Governance (100% complete) 
- FEATURE-006: Data Pipeline (100% complete)

This fixes the discrepancy where vault showed 17% but actual progress is 50%."

git push origin main
```

### 2. Install Strong Enforcement

```bash
# In SynapticTrading repository
cd /Users/nitindhawan/Downloads/CodeRepository/SynapticTrading

# Copy enforcement files from vault
cp /Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault/Product/.githooks/pre-commit .githooks/
cp /Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault/Product/scripts/tools/install-hooks.sh scripts/tools/
cp /Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault/Product/.github/workflows/vault-sync-check.yml .github/workflows/

# Make executable and install
chmod +x .githooks/pre-commit
chmod +x scripts/tools/install-hooks.sh
./scripts/tools/install-hooks.sh

# Test the hook
git add .
git commit -m "Test vault sync hook"
# Should run check-status automatically
```

### 3. Add Manual Update Flags

For all completed features/stories, add to frontmatter:
```yaml
manual_update: true
completed_at: 2025-11-21T10:00:00Z
```

This prevents sync tool from reverting completed status.

### 4. Update Repository CLAUDE.md

Add vault sync requirements section to `/CLAUDE.md` in code repository:
```markdown
### Status/Progress Enforcement
- Vault path: `/Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault`
- Install hook once: `./scripts/tools/install-hooks.sh`
- Commands:
  - `make sync-status` (updates vault based on progress)
  - `make check-status` (verifies sync, fails on drift)
- CI: PR checks fail if vault-code sync fails
- Hook runs `check-status` on every commit

### CRITICAL: After Completing Work
1. Update vault status immediately
2. Run `make sync-status`
3. Include vault updates in same commit/PR
4. Never skip with --no-verify
```

### 5. Create Fresh EPIC-007 Branch

```bash
# From main repository
cd /Users/nitindhawan/Downloads/CodeRepository/SynapticTrading

# Ensure we have latest with fixes
git pull origin main

# Create new worktree for continuing EPIC-007
git worktree add ../theplatform-epic-007-continue -b epic-007-continue

# Navigate to new worktree
cd ../theplatform-epic-007-continue

# Verify we have the completed code
ls -la src/strategy_lifecycle/
# Should show intake/, governance/, allocation/ directories

# Continue with FEATURE-003 (next pending feature)
```

## Process Improvements Now Active

### From UPMS Vault
- Created `/Methodology/Vault_Code_Sync_Standards.md`
- Updated UPMS Blueprint to reference sync requirements
- Standards now part of core methodology

### From SynapticTrading Vault  
- Created `/CLAUDE.md` with specific sync instructions
- Added `.githooks/pre-commit` with enforcement
- Added `.github/workflows/vault-sync-check.yml` for CI
- Added `scripts/tools/install-hooks.sh` for setup

### Key Process Changes
1. **Real-time updates required** - no batching
2. **Pre-commit enforcement** - commits fail if out of sync
3. **CI enforcement** - PRs fail if out of sync
4. **Manual update protection** - preserves completed status
5. **Clear troubleshooting** - documented in CLAUDE.md

## Verification Checklist

- [ ] Run `make sync-status` in SynapticTrading repo
- [ ] Verify EPIC-007 shows 50% complete in vault
- [ ] Install git hooks with `./scripts/tools/install-hooks.sh`
- [ ] Test hook by making a commit
- [ ] Add vault-sync-check.yml to GitHub Actions
- [ ] Update team on new requirements

## Going Forward

**Every sprint retrospective must include**:
- Vault sync verification
- Update any drift immediately
- Set manual_update flags on completed items

**Every commit must**:
- Pass `make check-status`
- Include vault updates for completed work
- Reference artifact IDs in commit message

**Remember**: The vault is the single source of truth. If it's not in the vault, it didn't happen.