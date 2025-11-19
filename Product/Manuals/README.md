# Manuals

This directory contains the User Manual and Administrator Manual for the SynapticTrading platform.

## Contents

- **[user_manual](./user_manual/)** - User-facing documentation
- **[administrator_manual](./administrator_manual/)** - Administrator and developer documentation

## Purpose

The manuals are maintained in the knowledge vault and symlinked to the code repository for:
1. **Single Source of Truth**: Manuals live in vault alongside product documentation
2. **Version Control**: Code repo symlinks enable Git versioning and PR workflows
3. **CI/CD Integration**: Accessible in automated pipelines via symlinks
4. **Unified Documentation**: All product artifacts in one location

## Architecture

**Source Location** (this directory):
```
/Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault/Product/Manuals/
├── user_manual/
└── administrator_manual/
```

**Symlinked In Code Repository**:
```
/Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/documentation/
├── user_manual → [vault]/Product/Manuals/user_manual
└── administrator_manual → [vault]/Product/Manuals/administrator_manual
```

This setup enables:
- Sprint planning (referencing manual update requirements)
- Compliance verification (checking manual updates during sprint close)
- Documentation reviews
- Cross-referencing from EPIC/Feature/Story artifacts
- Git-based PR workflows for manual updates

## Manual Update Process

See [manual_update_checklist.md](./administrator_manual/manual_update_checklist.md) for the sprint-based manual update workflow.

## Structure

### User Manual
- `getting_started.md` - Getting started guide
- `navigation.md` - UI navigation guide
- `dashboards.md` - Dashboard documentation
- `partner_workspace.md` - Partner workspace features
- `release_notes.md` - User-facing release notes

### Administrator Manual
- `environment_setup.md` - Development environment setup
- `automation.md` - Sprint automation workflows
- `vault_governance.md` - Knowledge vault governance
- `manual_update_checklist.md` - Manual update process

---

**Last Updated**: 2025-11-14
**Maintained By**: Documentation Team
