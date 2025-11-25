---
artifact_type: story
created_at: '2025-11-25T16:23:21.629909Z'
id: AUTO-PROC-2025-001-Status-Sync-Frontmatter
manual_update: 'true'
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: '001'
status: pending
title: Auto-generated title for PROC-2025-001-Status-Sync-Frontmatter
updated_at: '2025-11-25T16:23:21.629912Z'
---

## Impact

- ❌ Vault status frozen at initial values
- ❌ Status drift between cursor (correct) and vault (stale)
- ❌ Broken trust in automated tracking
- ❌ Manual status updates required (defeating automation)

**Scope**: All EPICs in SynapticTrading (EPIC-001, EPIC-002, EPIC-007), likely same issue in PDS

---

## Fixes Implemented

### 1. ✅ Documented in UPMS

**Created**: `/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/Knowledge/Watchouts/Status_Sync_Frontmatter_Gap.md`

Comprehensive documentation of:
- The gap (documentation vs. implementation)
- Why it happened (missing templates, no validation, manual creation)
- Impact analysis
- Prevention strategies

### 2. ✅ Created Missing Templates

**Created in** `/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/Templates/`:
- `EPIC_Template.md` - Complete with frontmatter schema and usage instructions
- `FEATURE_Template.md` - Complete with frontmatter schema
- `STORY_Template.md` - Complete with frontmatter schema

**Frontmatter Schema** (required fields):
```yaml
---
id: EPIC-XXX
status: planned
progress_pct: 0
created_at: YYYY-MM-DDTHH:MM:SSZ
updated_at: YYYY-MM-DDTHH:MM:SSZ
manual_update: false
---
```

### 3. ✅ Added Validation to status_sync.py

**Updated**: `scripts/automation/status_sync.py`

Added `validate_frontmatter()` function that:
- Detects missing frontmatter (no longer silent)
- Checks for required fields (`status`, `progress_pct`)
- Provides clear, actionable error messages
- Guides user to templates or fix commands

**Before**:
```python
if not text.startswith("---"):
    return {}, text  # Silent failure!
```

**After**:
```python
if not validate_frontmatter(path, fm, errors, "epic"):
    errors.append(
        f"❌ MISSING FRONTMATTER: {path}\n"
        f"   Fix: Add frontmatter or copy from UPMS template\n"
    )
    return 0.0, False  # Fail loudly!
```

---

## Fixes Remaining

### 4. ⏳ Migration Script (TODO)

**Need to create**: `scripts/automation/migrate_to_frontmatter.py`

**Function**:
1. Scan all EPIC/Feature/Story README.md files
2. Extract status from body text (`**Status**: ✅ Completed`)
3. Insert YAML frontmatter at top of file
4. Preserve existing body content
5. Validate result

**Run once** per product to migrate existing files.

### 5. ⏳ Update Documentation (TODO)

**Files to update**:
- `CLAUDE.md` - Add "Creating EPICs/Features/Stories" section with template usage
- `Development_Roadmap_Process.md` - Document template requirement
- `documentation/guides/` - Add migration guide

### 6. ⏳ Enhanced Pre-commit Hook (TODO)

Add frontmatter validation to `.githooks/pre-commit`:
```bash
# Check new/modified EPIC/Feature/Story files for frontmatter
./scripts/automation/validate_frontmatter.sh || exit 1
```

---

## Testing Plan

### Manual Testing

1. **Run sync on current files** (should show errors):
   ```bash
   make check-status
   ```
   Expected: Clear error messages for all files without frontmatter

2. **Add frontmatter to one EPIC** (manual):
   ```bash
   # Edit EPIC-002/README.md - add frontmatter
   make check-status
   ```
   Expected: No errors for that EPIC

3. **Run migration script** (after creating it):
   ```bash
   python scripts/automation/migrate_to_frontmatter.py --product synaptic
   make check-status
   ```
   Expected: All files have frontmatter, no errors

### Validation

```bash
# After migration, verify automation works
make sync-status    # Should calculate progress from cursor
git diff            # Should show updated progress_pct in frontmatter
```

---

## Action Items

### Immediate (This Week)

- [x] Document gap in UPMS
- [x] Create missing templates
- [x] Add validation to status_sync.py
- [ ] Create migration script
- [ ] Run migration on SynapticTrading vault
- [ ] Test status_sync with migrated files
- [ ] Update CLAUDE.md

### Short-term (Next Sprint)

- [ ] Run migration on ProductDevelopmentSupport vault
- [ ] Add pre-commit frontmatter validation
- [ ] Create "vault health check" tool
- [ ] Update UPMS methodology docs

### Long-term (Quarterly)

- [ ] Add template validation to UPMS CI
- [ ] Train team on template usage
- [ ] Document in knowledge base
- [ ] Apply to all future products

---

## Benefits

**Once Complete**:
- ✅ Automated status tracking works correctly
- ✅ Vault always reflects actual progress
- ✅ No manual status updates needed
- ✅ Trust restored in automation
- ✅ Process enforced via validation
- ✅ Templates prevent future issues

---

## Lessons Learned

1. **Templates are critical** - Without them, developers improvise
2. **Silent failures are dangerous** - Scripts should fail loudly
3. **Documentation ≠ Implementation** - Must validate both align
4. **Prevention > Detection** - Templates + validation prevent issues
5. **Process gaps compound** - Missing templates → wrong format → broken automation

---

## Related Documents

- **UPMS Watchout**: `/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/Knowledge/Watchouts/Status_Sync_Frontmatter_Gap.md`
- **UPMS Templates**: `/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/Templates/`
- **status_sync.py**: `scripts/automation/status_sync.py`
- **Sprint Cursor**: `documentation/vault_sprints/SPRINT-20251118-epic002-adapter-replay/`

---

**Created By**: Claude Code + User
**Priority**: HIGH - Blocks accurate status tracking
**Timeline**: Week of 2025-11-19
