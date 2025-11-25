---
artifact_type: story
created_at: '2025-11-25T16:23:21.799518Z'
id: AUTO-vault_governance
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for vault_governance
updated_at: '2025-11-25T16:23:21.799522Z'
---

# Vault & Documentation Governance

## Sprint Close Requirements
1. Update sprint README + `execution_summary.yaml`.
2. Update user/admin manuals for any user-facing or operational changes.
3. Run `make sprint-close SPRINT=<id>` and `scripts/automation/update_test_metadata.py`.

## Manual Ownership
- **User Manual**: Product management + UX writer; reviewed each sprint.
- **Administrator Manual**: Engineering lead + DevOps.

## Audit Checklist
- `REQUIREMENTS_MATRIX.md` includes both functional + UI test references.
- EPIC/Feature/Story front matter contains `last_test_run`.
- Manuals include latest screenshots/notes where applicable (store screenshots under `documentation/assets/`—no external URLs).
