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
