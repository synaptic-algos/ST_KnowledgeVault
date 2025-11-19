# Automation & CI Jobs

## Sprint Close Workflow
- Trigger: manual via `workflow_dispatch` (`.github/workflows/sprint-close.yml`) or as part of release branch merges.
- Steps:
  1. `make sprint-close SPRINT=<id>`
  2. `python scripts/automation/update_test_metadata.py --report junit.xml --vault $KNOWLEDGE_VAULT_PRODUCT`
  3. Commit/push updated vault content or notify vault owners to pull changes.

## Manual Update Enforcement
- Add a CI job that checks `documentation/user_manual/*.md` and `documentation/administrator_manual/*.md` changed when relevant directories (e.g., `Product/EPICS/EPIC-002`) change. For now, include a checklist item in PR templates.
- Sprint finishing requires checked box: “Manual updated/verified”.

## Screenshot Handling
- Store screenshots under `documentation/assets/<feature>/`.
- Reference them using relative paths (e.g., `![Navigator Tree](../assets/navigator/tree.png)`).
