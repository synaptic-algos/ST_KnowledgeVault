---
artifact_type: story
created_at: '2025-11-25T16:23:21.568197Z'
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
updated_at: '2025-11-25T16:23:21.568200Z'
---

# Sync Automation Scripts

These scripts keep sprint execution, epic metadata, and roadmap summaries in sync.

## Files

| Script | Purpose |
|--------|---------|
| `update_epic_status.py` | Applies a sprint’s `execution_summary.yaml` to all impacted Stories/Features/Epics. Updates status, progress %, requirement coverage, change logs, timestamps, and linked sprints. |
| `roadmap_sync.py` | Reads epic metadata and regenerates the auto-summary block in `Product/ROADMAP.md` (between `<!-- AUTO-ROADMAP-SUMMARY:START/END -->`). |
| `run_sprint_close.sh` | Convenience wrapper that runs both scripts for a given sprint; ideal for CI pipelines (`make sprint-close`). |

## Usage

```bash
VAULT_ROOT=/path/to/<Product>_Vault/Product

# 1) After updating sprint execution_summary.yaml manually
python VaultGuide/scripts/sync/update_epic_status.py --vault "$VAULT_ROOT" --summary "$VAULT_ROOT/Sprints/<SPRINT_ID>/execution_summary.yaml"
python VaultGuide/scripts/sync/roadmap_sync.py --vault "$VAULT_ROOT" --roadmap ROADMAP.md

# OR simply run the wrapper (recommended / CI)
VaultGuide/scripts/sync/run_sprint_close.sh "$VAULT_ROOT" "<SPRINT_ID>" ROADMAP.md
```

Both scripts are tool-agnostic: as long as each sprint records an `execution_summary.yaml`, the loop works regardless of whether work was done via TaskMaster, Claude CLI, Codex, or manual effort.
