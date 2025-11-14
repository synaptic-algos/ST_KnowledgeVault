# Knowledge Vault System Architecture

**Document Type**: System Design
**Owner**: Product Operations
**Status**: Active
**Last Updated**: 2025-11-05

## Executive Summary

The Synaptic Trading Knowledge Vault is a three-layer knowledge management system that integrates Obsidian-based documentation with the code repository through symbolic links. This architecture ensures a single source of truth while providing convenient access for engineers and product managers.

## Design Principles

### 1. Single Source of Truth
- Vault contains authoritative product knowledge
- No duplication of content across systems
- Symlinks provide access, not copies

### 2. Separation of Concerns
- **Methodology** (UPMS): Reusable across any product
- **Product Execution** (SynapticTrading_Product): Specific to this platform
- **Meta-Documentation** (SynapticTrading_KnowledgeVault): System design and usage

### 3. Bidirectional Flow
- Engineers access vault content via symlinks
- Claude generates docs that flow into vault
- PMs curate and maintain vault content
- Changes propagate immediately via symlinks

### 4. Tool-Agnostic Access
- Obsidian for visual knowledge management
- File system access for programmatic use
- Git for version control and collaboration
- MCP for AI-powered automation

## System Layers

### Layer 1: UPMS (Universal Product Methodology System)

**Purpose**: Product-agnostic methodology framework

**Location**: `/Users/nitindhawan/SynapseTrading_Knowledge/Synaptic_Trading_KnowledgeVault/UPMS/`

**Contents**:
```
UPMS/
├── Methodology/
│   ├── Blueprint.md                    # Core methodology documentation
│   ├── Gate_Checklists/               # Phase gate approval checklists
│   └── Ceremonies/                    # Sprint rituals and meetings
├── Templates/
│   ├── PRD_Template.md
│   ├── Requirements_Matrix_Template.md
│   ├── Sprint_Template.md
│   ├── Research_Note_Template.md
│   ├── Design_Doc_Template.md
│   └── Issue_Template.md
├── Sprints/                           # Sprint execution records
├── Research/                          # Research pipeline
│   ├── Market/
│   ├── Technical/
│   ├── Risk/
│   ├── Optimization/
│   └── Lessons/
└── Issues/                            # Issue tracking
```

**Lifecycle Phases**:
1. Inception (G0)
2. Discovery (G1)
3. Definition (G2)
4. Delivery (G3)
5. Validation (G4)
6. Operate & Learn (G5)

**Key Features**:
- Reusable templates for any product
- Gate-driven approval workflows
- Variable-length sprint support
- Continuous research pipeline

### Layer 2: SynapticTrading_Product (Execution Artifacts)

**Purpose**: Product-specific execution content

**Location**: `/Users/nitindhawan/SynapseTrading_Knowledge/Synaptic_Trading_KnowledgeVault/SynapticTrading_Product/`

**Contents**:
```
SynapticTrading_Product/
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
├── Strategies/                        # Strategy catalog
│   ├── README.md
│   └── Templates/
├── Design/                            # Design documents
├── Research/                          # Product research
├── Sprints/                           # Sprint execution
└── TechnicalDocumentation/
```

**Scope**:
- 7 Epics
- 35 Features
- 107 Stories
- ~420 Tasks

**Key Features**:
- Hierarchical work breakdown (Epic → Feature → Story → Task)
- Strategy lifecycle management
- Traceability matrices
- Sprint planning and execution records

### Layer 3: Code Repository Integration

**Purpose**: Engineer access to vault content

**Location**: `/Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/documentation/`

**Integration Method**: Symbolic links from code repo to vault

**Symlink Structure**:
```
documentation/
├── vault_epics -> .../SynapticTrading_Product/EPICS
├── vault_strategies -> .../SynapticTrading_Product/Strategies
├── vault_prd -> .../SynapticTrading_Product/PRD
├── vault_templates -> .../UPMS/Templates
├── vault_research -> .../SynapticTrading_Product/Research
└── [existing code repo docs]
```

**Access Pattern**:
```
Engineer in code repo
    ↓
Reads documentation/vault_epics/EPIC-001/
    ↓
Symlink resolves to vault location
    ↓
Content served from vault (single source of truth)
```

### Layer 4: SynapticTrading_KnowledgeVault (Meta-Documentation)

**Purpose**: System design and usage documentation

**Location**: `/Users/nitindhawan/SynapseTrading_Knowledge/Synaptic_Trading_KnowledgeVault/SynapticTrading_KnowledgeVault/`

**Contents**:
```
SynapticTrading_KnowledgeVault/
├── README.md                          # Comprehensive usage guide
├── Design/
│   └── VAULT_ARCHITECTURE.md         # This document
└── EPICS/
    └── EPIC-001-Synchronisation/     # Automation initiatives
```

**Responsibilities**:
- Document vault architecture
- Provide symlink setup instructions
- Define usage patterns and best practices
- Track automation initiatives

## Information Flow

### Read Flow (Engineer → Vault)

```
1. Engineer working in code repository
   └─ /Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/

2. References product documentation
   └─ cd documentation/vault_epics/EPIC-001-Foundation/

3. Symlink resolves to vault
   └─ → /Users/.../Synaptic_Trading_KnowledgeVault/SynapticTrading_Product/EPICS/EPIC-001-Foundation/

4. Content accessed from vault (authoritative source)
   └─ Reads README.md, feature specs, etc.
```

### Write Flow (Claude → Vault → Engineer)

```
1. Engineer works with Claude in code repository
   └─ Claude generates documentation

2. Documentation committed to vault
   └─ git commit in vault repository

3. Changes immediately visible in code repo
   └─ via symlinks (no sync delay)

4. PM reviews and refines in Obsidian
   └─ Direct editing of vault content

5. Refined docs available to all engineers
   └─ Single source of truth updated
```

### Bidirectional Synchronization

```
Vault (Source of Truth)
    ↕
Symlinks (Access Layer)
    ↕
Code Repository (Engineer Workspace)
    ↕
Claude/AI Tools (Generation)
    ↕
Back to Vault (Curation)
```

## Symlink Management

### Creation Strategy

**Naming Convention**: `vault_<category>`

**Rationale**:
- Clear distinction from native code repo docs
- Searchable prefix for all vault content
- Prevents naming conflicts

**Target Directories**:
- Product execution artifacts (EPICS, Strategies, PRD)
- Methodology templates (UPMS/Templates)
- Research and design docs

### Maintenance

**Health Checks**:
```bash
# Check for broken symlinks
cd /Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/documentation/
find . -type l ! -exec test -e {} \; -print
```

**Updates**:
- Add symlinks when new vault sections created
- Remove symlinks if vault structure changes
- Document all symlink changes in code repo README

### Version Control

**Vault Repository**:
- Location: `/Users/nitindhawan/SynapseTrading_Knowledge/Synaptic_Trading_KnowledgeVault/`
- Contains: All vault content
- Tracks: Content changes, not symlinks

**Code Repository**:
- Location: `/Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/`
- Contains: Symlink definitions (not content)
- Tracks: Symlink structure changes

## Access Patterns

### For Engineers

**Reading Vault Content**:
```bash
# From code repository
cd /Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/
cat documentation/vault_epics/EPIC-001-Foundation/README.md
```

**Referencing in Code**:
```python
# Relative path from code repo
# docs: See ../documentation/vault_strategies/Templates/
```

**Searching Vault Content**:
```bash
# Search across symlinked content
grep -r "pattern" documentation/vault_*
```

### For Product Managers

**Editing Vault Content**:
1. Open Obsidian
2. Navigate to SynapticTrading_Product
3. Edit files directly
4. Changes visible immediately to engineers

**Creating New Content**:
1. Use UPMS templates
2. Create in appropriate vault location
3. Link to related epics/features/stories
4. Engineers see via symlinks automatically

### For AI Assistants (Claude)

**Accessing Vault**:
```python
# MCP tools provide read access
vault_path = "/Users/nitindhawan/SynapseTrading_Knowledge/Synaptic_Trading_KnowledgeVault/"
```

**Generating Documentation**:
1. Read vault structure and content
2. Generate docs following templates
3. Commit to appropriate vault location
4. Update traceability matrices

## Automation Initiatives

### EPIC-001: Vault Synchronisation

**Objectives**:
1. Automate documentation flow from code → vault
2. Maintain symlink health
3. Ensure consistency between vault and code artifacts
4. Monitor and alert on sync issues

**Components**:
- Symlink health checker (cron job)
- Documentation analyzer (identifies docs to sync)
- Vault importer (routes docs to correct location)
- Consistency validator (checks for conflicts)

**Status**: Planning phase

## Design Decisions

### Why Symlinks?

**Alternatives Considered**:
1. **File copying**: Rejected due to sync issues and duplication
2. **Git submodules**: Rejected due to complexity and update friction
3. **API/service layer**: Rejected due to overhead and latency
4. **Symlinks**: ✅ Chosen for simplicity and real-time access

**Benefits**:
- Zero sync delay
- Single source of truth guaranteed
- Simple to understand and maintain
- Works with all file-based tools

**Trade-offs**:
- Platform-specific (works on Unix/Linux/macOS)
- Requires absolute paths (not portable)
- Can break if vault moves

### Why Obsidian?

**Benefits**:
- Visual knowledge graph
- Powerful linking and tagging
- Git-friendly (plain markdown)
- Extensible with plugins
- No vendor lock-in

**Trade-offs**:
- Requires manual installation
- Config not fully portable
- Some plugins needed for full workflow

### Why Three Layers?

**Rationale**:
1. **UPMS**: Methodology reusable across products → efficiency
2. **Product**: Product-specific execution → focus
3. **Meta**: System documentation → maintainability

**Benefits**:
- Clear separation of concerns
- Reusability of methodology
- Scalability to multiple products

## Migration Guide

### From Legacy Documentation

**Steps**:
1. Audit existing code repo documentation
2. Identify docs that should be in vault (product knowledge)
3. Identify docs that should stay in code repo (build artifacts)
4. Move product docs to appropriate vault location
5. Create symlinks to vault content
6. Update code repo README
7. Archive legacy docs

**Criteria for Vault vs Code Repo**:

**Move to Vault**:
- Product requirements (PRDs)
- Epic/feature/story specs
- Design documents
- Research findings
- Strategy definitions
- Process templates

**Keep in Code Repo**:
- Build logs
- Generated diagrams (artifacts)
- Environment-specific configs
- Temporary notes
- Implementation notes (developer scratch)

## Future Enhancements

### Short Term (1-3 months)
- [ ] Automated symlink creation script
- [ ] Symlink health monitoring dashboard
- [ ] Documentation analyzer for sync candidates

### Medium Term (3-6 months)
- [ ] Bidirectional sync automation (EPIC-001)
- [ ] Vault content linter (template compliance)
- [ ] Traceability matrix auto-generator

### Long Term (6-12 months)
- [ ] Multi-product vault support
- [ ] Advanced search across vault + code
- [ ] Integration with CI/CD pipelines
- [ ] Usage analytics and recommendations

## Troubleshooting

### Symlink Broken

**Symptom**: `ls: cannot access 'vault_epics': No such file or directory`

**Solution**:
```bash
# Check if symlink exists
ls -la documentation/vault_epics

# Recreate if needed
cd documentation/
rm vault_epics  # Remove broken link
ln -s /Users/nitindhawan/SynapseTrading_Knowledge/Synaptic_Trading_KnowledgeVault/SynapticTrading_Product/EPICS vault_epics
```

### Vault Moved

**Symptom**: All vault symlinks broken

**Solution**:
```bash
# Update all symlinks to new vault location
cd /Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/documentation/

# Remove old symlinks
rm vault_*

# Recreate with new paths
ln -s <new_vault_path>/SynapticTrading_Product/EPICS vault_epics
# ... repeat for all symlinks
```

### Permission Issues

**Symptom**: Cannot read vault content via symlinks

**Solution**:
```bash
# Check vault permissions
ls -la /Users/nitindhawan/SynapseTrading_Knowledge/Synaptic_Trading_KnowledgeVault/

# Fix if needed
chmod -R u+rw /Users/nitindhawan/SynapseTrading_Knowledge/Synaptic_Trading_KnowledgeVault/
```

## References

- [Main Vault README](../README.md)
- [SynapticTrading_KnowledgeVault README](../SynapticTrading_KnowledgeVault/README.md)
- [UPMS Methodology Blueprint](../../UPMS/Methodology/UPMS_Methodology_Blueprint.md)
- [Product Quick Start](../../SynapticTrading_Product/QUICK_START.md)

---

**Document History**:
- 2025-11-05: Initial version
- Owner: Product Operations Team
- Review Cycle: Quarterly
