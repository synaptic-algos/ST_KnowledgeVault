---
artifact_type: story
created_at: '2025-11-25T16:23:21.541286Z'
id: AUTO-README
manual_update: 'true'
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: '001'
status: pending
title: Auto-generated title for README
updated_at: '2025-11-25T16:23:21.541290Z'
---

## Vault Structure

This vault follows the standard product vault pattern:

```
SynapticTrading_Vault/
├── KnowledgeVault/       # Meta-documentation about THIS vault
└── Product/              # Trading platform execution artifacts
```

### KnowledgeVault/ - Vault System Design

**Purpose**: Documents how THIS vault operates and integrates with the code repository

**Contents**:
- README.md - Comprehensive vault usage guide
- Design/ - Vault architecture and symlink documentation
- EPICS/ - Vault-specific automation initiatives (EPIC-001 Synchronisation)

**Key Topics**:
- How this vault integrates with code repository via symlinks
- Symlink setup instructions
- Usage guidelines for engineers and PMs
- Vault maintenance and best practices

See: [KnowledgeVault/README.md](./KnowledgeVault/README.md)

### Product/ - Trading Platform Artifacts

**Purpose**: All execution artifacts for the Synaptic Trading Platform

**Contents**:
```
Product/
├── README.md                          # Product overview
├── QUICK_START.md                     # Getting started guide
├── IMPLEMENTATION_HIERARCHY.md        # Complete work breakdown
├── EPICS/                             # 7 platform epics
│   ├── EPIC-001-Foundation/
│   ├── EPIC-002-Backtesting/
│   ├── EPIC-003-PaperTrading/
│   ├── EPIC-004-LiveTrading/
│   ├── EPIC-005-Adapters/
│   ├── EPIC-006-Compliance/
│   ├── EPIC-007-StrategyLifecycle/
│   └── EPIC-008-StrategyEnablement/
├── PRD/                               # Product requirements
├── Strategies/                        # Strategy catalog and templates
├── Design/                            # Design documents
├── Research/                          # Research findings
├── Sprints/                           # Sprint execution records
└── TechnicalDocumentation/           # Technical specs
```

**Scope**:
- 7 Epics
- 35 Features
- 107 Stories
- ~420 Tasks

See: [Product/README.md](./Product/README.md)

## Methodology

This vault follows the **UPMS (Universal Product Management Meta-System)** methodology:

**UPMS Location**: `/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/`

**Key UPMS Concepts**:
- 6-phase lifecycle: Inception → Discovery → Definition → Delivery → Validation → Operate & Learn
- Gate-driven approvals (G0-G5)
- Variable-length sprints
- Epic → Feature → Story → Task hierarchy

**Templates**: Reference UPMS templates and adapt for trading platform needs

## Integration with Code Repository

### Symlinks

Engineers access vault content through symlinks in the code repository:

**Symlink Location**: `/Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/documentation/`

**Symlinks Point To**: This vault's Product/ directory

### Setup

See [KnowledgeVault/README.md](./KnowledgeVault/README.md) for detailed symlink setup instructions, or run:

```bash
/Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault/VaultGuide/setup_vault_symlinks.sh
```

### Access Pattern

```
Engineer in code repo
    ↓
Reads documentation/vault_epics/EPIC-001/
    ↓
Symlink resolves to vault Product/EPICS/EPIC-001/
    ↓
Single source of truth maintained
```

## Setup Instructions

### For New Collaborators

1. **Clone this repository**:
   ```bash
   cd /Users/nitindhawan/KnowledgeVaults/
   git clone <repository-url> SynapticTrading_Vault
   ```

2. **Open in Obsidian**:
   - Open Obsidian
   - Click "Open folder as vault"
   - Select the `SynapticTrading_Vault` folder

3. **Set up symlinks** (if you work in code repository):
   ```bash
   /Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault/VaultGuide/setup_vault_symlinks.sh
   ```

4. **Start collaborating**:
   - Create and edit notes as needed
   - Commit your changes regularly
   - Pull before you start working to get latest updates
   - Push your changes to share with the team

### Git Workflow for Collaboration

```bash
# Before starting work - get latest changes
git pull origin main

# After making changes
git add .
git commit -m "Description of your changes"
git push origin main
```

### Handling Merge Conflicts

If you encounter conflicts:
1. Open the conflicted file in Obsidian or a text editor
2. Look for conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
3. Choose which version to keep or merge them manually
4. Remove conflict markers
5. Commit the resolved changes

## Quick Navigation

### For Engineers
- **Current sprint work**: [Product/EPICS/](./Product/EPICS/)
- **Strategy templates**: [Product/Strategies/Templates/](./Product/Strategies/Templates/)
- **Technical docs**: [Product/TechnicalDocumentation/](./Product/TechnicalDocumentation/)
- **UPMS templates**: `/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/Templates/`

### For Product Managers
- **Roadmap**: [Product/README.md](./Product/README.md)
- **Work breakdown**: [Product/IMPLEMENTATION_HIERARCHY.md](./Product/IMPLEMENTATION_HIERARCHY.md)
- **Quick start**: [Product/QUICK_START.md](./Product/QUICK_START.md)
- **Sprint planning**: [Product/Sprints/](./Product/Sprints/)

### For Stakeholders
- **Product overview**: [Product/README.md](./Product/README.md)
- **Strategy catalog**: [Product/Strategies/README.md](./Product/Strategies/README.md)
- **Research findings**: [Product/Research/](./Product/Research/)

## Best Practices

1. **Single Source of Truth**: Vault is authoritative, code repo accesses via symlinks
2. **Commit Often**: Make small, focused commits with clear messages
3. **Pull Regularly**: Always pull before starting new work
4. **Resolve Conflicts Promptly**: Address merge conflicts as soon as they occur
5. **Use Meaningful Names**: Name notes clearly and consistently
6. **Link Notes**: Use Obsidian's `[[wiki-links]]` to connect related notes
7. **Follow UPMS**: Reference UPMS templates and adapt for platform needs

## Configuration

The `.obsidian` folder contains shared settings including:
- Core plugins configuration
- Appearance settings
- App settings

Note: Workspace layouts are NOT synced (they're in `.gitignore`) so each user can have their own window arrangement.

## Product Information

- **Product**: Synaptic Trading Platform
- **Type**: Framework-Agnostic Algorithmic Trading System
- **Status**: Active Development
- **Team**: 2-3 engineers, 1 PM
- **Methodology**: UPMS

## Related Resources

- **UPMS Vault**: `/Users/nitindhawan/KnowledgeVaults/UPMS_Vault/` - Universal methodology
- **Code Repository**: `/Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/`
- **Product Tracker**: `/Users/nitindhawan/KnowledgeVaults/ProductDevelopmentSupport_Vault/` - Monitors this product

## Version

- **Created**: 2025-11-01
- **Restructured**: 2025-11-12 (moved to standard vault pattern)
- **Obsidian Version**: Compatible with latest release
- **Git**: Enabled for collaboration

---

**This vault follows UPMS standards. For methodology questions, see the UPMS Vault.**
