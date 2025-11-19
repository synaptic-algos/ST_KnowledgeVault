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
