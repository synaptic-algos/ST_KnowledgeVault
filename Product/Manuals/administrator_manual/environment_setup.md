---
artifact_type: story
created_at: '2025-11-25T16:23:21.794747Z'
id: AUTO-environment_setup
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for environment_setup
updated_at: '2025-11-25T16:23:21.794751Z'
---

# Environment Setup

## Vault Paths
- SynapticTrading vault: `/Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault`
- ProductDevelopmentSupport vault: `/Users/nitindhawan/KnowledgeVaults/ProductDevelopmentSupport_Vault`

## Required Secrets (CI/CD)
- `KNOWLEDGE_VAULT_BASE`
- `KNOWLEDGE_VAULT_PRODUCT`
- `KNOWLEDGE_VAULT_RUNNER`

## Commands
```bash
# Run sprint-close automation
make sprint-close SPRINT=<SPRINT_ID>

# Sync test metadata
python scripts/automation/update_test_metadata.py --report junit.xml --vault $KNOWLEDGE_VAULT_PRODUCT
```
