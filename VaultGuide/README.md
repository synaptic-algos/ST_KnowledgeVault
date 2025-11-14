# SynapticTrading Knowledge Vault System Design

**Meta-Documentation Layer**: This directory contains documentation about how the knowledge vault system itself is designed, operates, and integrates with the code repository.

## Purpose

This is the **architectural documentation for the knowledge management system**. It explains:
- How the Obsidian vault is structured as a product
- The integration between the vault and code repository
- Guidelines for setting up and maintaining the system
- Usage patterns and best practices

Think of this as: **"Documentation about how to build and maintain the documentation system"**

## Knowledge Vault Architecture

### Standard Product Vault Pattern

This vault follows the standard two-layer pattern, with reference to independent UPMS:

```
┌─────────────────────────────────────────────────────────┐
│ UPMS Vault (Independent Methodology)                    │
│ Location: /Users/nitindhawan/UPMS_Vault/               │
│    • Reusable PM processes & templates                  │
│    • Gate checklists, ceremonies, governance            │
│    • The "how to run product management" layer          │
└─────────────────────────────────────────────────────────┘
                            ↓ Referenced by
┌─────────────────────────────────────────────────────────┐
│ SynapticTrading_Vault (This Vault)                      │
│ Location: .../SynapticTrading_Vault/                    │
│ ├── KnowledgeVault/ (this directory)                    │
│ │   └── How THIS vault works                           │
│ └── Product/                                            │
│     └── Epics, Features, Stories, PRDs, etc.           │
│     └── SOURCE OF TRUTH for product knowledge           │
└─────────────────────────────────────────────────────────┘
                            ↑
                    Accessed via symlinks
                            ↓
┌─────────────────────────────────────────────────────────┐
│ Code Repository /documentation/ (Engineer Access)       │
│    • Symlinks to vault Product/ content                 │
│    • Engineers work here                                │
│    • Single source of truth via links                   │
└─────────────────────────────────────────────────────────┘
```

### This Directory's Role

**KnowledgeVault/** (this directory) is the **meta layer** that documents:
- How THIS vault works and is structured
- Integration with code repository via symlinks
- Setup and configuration instructions
- Usage guidelines and best practices

## Symlink Integration Strategy

### Philosophy

**Vault as Source of Truth**: The Obsidian vault contains authoritative product knowledge. The code repository accesses this knowledge through symlinks, ensuring engineers always reference the latest, single source of truth.

### Symlink Location

**Symlinks live in**: `/Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/documentation/`

**Symlinks point to**: Vault content in `/Users/nitindhawan/SynapseTrading_Knowledge/SynapticTrading_Vault/Product/`

### Setting Up Symlinks

Navigate to the code repository documentation folder:

```bash
cd /Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/documentation/
```

Create symlinks to vault content:

```bash
# Link to ALL product vault content
ln -s /Users/nitindhawan/SynapseTrading_Knowledge/SynapticTrading_Vault/Product/EPICS vault_epics
ln -s /Users/nitindhawan/SynapseTrading_Knowledge/SynapticTrading_Vault/Product/Strategies vault_strategies
ln -s /Users/nitindhawan/SynapseTrading_Knowledge/SynapticTrading_Vault/Product/PRD vault_prd
ln -s /Users/nitindhawan/SynapseTrading_Knowledge/SynapticTrading_Vault/Product/Research vault_research
ln -s /Users/nitindhawan/SynapseTrading_Knowledge/SynapticTrading_Vault/Product/Design vault_design
ln -s /Users/nitindhawan/SynapseTrading_Knowledge/SynapticTrading_Vault/Product/Issues vault_issues
ln -s /Users/nitindhawan/SynapseTrading_Knowledge/SynapticTrading_Vault/Product/Sprints vault_sprints
ln -s /Users/nitindhawan/SynapseTrading_Knowledge/SynapticTrading_Vault/Product/TechnicalDocumentation vault_technical_docs
ln -s /Users/nitindhawan/SynapseTrading_Knowledge/SynapticTrading_Vault/Product/Templates vault_product_templates

# Link to UPMS methodology templates (from independent UPMS vault)
ln -s /Users/nitindhawan/UPMS_Vault/Templates vault_upms_templates
```

### Verifying Symlinks

Check that symlinks are created correctly:

```bash
ls -la /Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/documentation/
```

You should see entries like:
```
vault_epics -> /Users/nitindhawan/SynapseTrading_Knowledge/...
vault_strategies -> /Users/nitindhawan/SynapseTrading_Knowledge/...
```

## Usage Guidelines

### For Engineers

**When working in the code repository:**

1. **Reading product docs**: Access via symlinks in `documentation/vault_*`
2. **Referencing epics/stories**: Use the symlinked paths
3. **Understanding methodology**: Check `documentation/vault_templates`
4. **Strategy implementation**: Reference `documentation/vault_strategies`

**When updating product knowledge:**

1. Open the Obsidian vault directly
2. Make changes in the appropriate vault directory (UPMS or SynapticTrading_Product)
3. Commit changes to the vault's git repository
4. Changes immediately available in code repo via symlinks

### For Product Managers

**Managing product artifacts:**

1. Work directly in the Obsidian vault
2. Update epics, features, stories in `SynapticTrading_Product/EPICS/`
3. Maintain PRDs in `SynapticTrading_Product/PRD/`
4. Track strategies in `SynapticTrading_Product/Strategies/`
5. Engineers automatically see updates via symlinks

**Process governance:**

1. Maintain methodology templates in `UPMS/Templates/`
2. Update gate checklists in `UPMS/Methodology/Gate_Checklists/`
3. Document ceremonies in `UPMS/Ceremonies/`

### Research Documentation Standard
- Research notes in either UPMS or Product vaults must use a zero-padded numeric prefix (`<seq>-Title.md`) that matches the authoritative catalog in `UPMS_Vault/Research/`.
- Begin every research file with YAML front matter including `sequence_number` (same as prefix) and UTC `created_at` timestamp.
- Reference research from stories, PRDs, or roadmap docs using the numbered filenames so backlinks remain stable.
- Before adding a new research note, inspect the highest sequence number and increment it to avoid collisions across vaults.

### Sprint Close Checklist (MANDATORY)
1. **Document** – Complete the sprint README/SUMMARY and write `execution_summary.yaml` (see template in UPMS research note 004).
2. **Sync** – Run either:
   ```bash
   make sprint-close SPRINT=<SPRINT_ID>
   # or, from the vault root:
   VaultGuide/scripts/sync/run_sprint_close.sh Product <SPRINT_ID> ROADMAP.md
   ```
3. **Verify** – Ensure EPIC/Feature/Story front matter shows the sprint in `linked_sprints`, and the auto-summary block in `Product/ROADMAP.md` has the new timestamp.
4. **CI Gate** – Pipelines should fail if `execution_summary.yaml` is missing or the sync command wasn’t run.

All sync helpers live in `VaultGuide/scripts/sync/` so they version with vault governance.

### Epic-Aligned Testing
- Every epic directory under `Product/EPICS/` must include a `TEST_PLAN.md` generated from the UPMS template. The plan lists the acceptance criteria, mapped test suites, and the make/pytest targets that enforce them.
- Tests referenced in those plans live in the code repository under `tests/epics/<epic_slug>/` plus any module-specific folders (e.g., `tests/application/ports/`). Keep the folder naming consistent so CI can run `make test-epicXXX`.
- When a test is added, update both the epic `TEST_PLAN.md` and the epic’s `REQUIREMENTS_MATRIX.md` “Linked Tests” column with **all** suites (`tests/<path>::TestClass::test_case`, `tests/ui/...`, `playwright/tests/...`) so traceability stays intact.
- Sprint retros must record the latest test results (pass/fail, coverage) and link back to the epic test plan; gate reviews will block if an epic lacks an up-to-date plan or automated suite reference.
- Sprint planning documents must explicitly schedule the test bucket work (design + execution) aligned to that sprint’s scope. Do not mark a sprint “Complete” until the planned `make test-<epic_slug>` targets ran and their results were logged in the sprint README.
- After each test run, update the affected EPIC/Feature/Story front matter with `last_test_run` metadata capturing date, suite, location, result, and aggregate pass/fail counts. This keeps Obsidian views and downstream tools aware of the most recent evidence.
- Use `scripts/automation/update_test_metadata.py --report <junit.xml> --vault Product` (or run it via CI) to automate the front-matter update from JUnit reports. Each testcase must include `upms_artifact_path` and `upms_suite` properties.

### Documentation Flow

```
Engineer generates code
        ↓
Claude creates documentation artifacts
        ↓
Artifacts committed to vault (SynapticTrading_Product)
        ↓
Changes visible in code repo immediately (via symlinks)
        ↓
PM reviews and refines in Obsidian
        ↓
Updates available to all engineers
```

## Directory Structure

This meta-documentation directory contains:

```
VaultGuide/
├── README.md                          # This file - overall vault guide
├── VAULT_ARCHITECTURE.md              # Vault structure and integration
├── SPRINT_TRACEABILITY_GUIDE.md       # MANDATORY sprint process
├── setup_vault_symlinks.sh            # Symlink setup script
├── EPICS/                             # Vault automation initiatives
│   └── EPIC-001-Synchronisation/      # Documentation routing automation
│       ├── README.md                  # Epic overview
│       └── Stories/
│           └── STORY-001-DocRouter/   # Doc router implementation
│               └── README.md          # Story details
└── Design/                            # Vault system design documents
    └── DOC_ROUTER_DESIGN.md           # Documentation routing design
```

## Active Initiatives

### EPIC-001: Vault Synchronisation Automation
**See**: [EPICS/EPIC-001-Synchronisation/README.md](./EPICS/EPIC-001-Synchronisation/README.md)

**Goal**: Build automation to:
- Detect and route Claude-generated documentation to vault automatically
- Inject proper YAML frontmatter and metadata
- Update EPIC/Feature/Story backlinks automatically
- Maintain symlink health and integrity
- Ensure consistency between vault and code artifacts

**Status**: 📋 Planned

**Components**:
- Documentation Router (`scripts/claude_doc_router.py`) - Automated doc routing
- Routing Configuration (`config/doc_routing.yml`) - Declarative routing rules
- Symlink Manager (`setup_vault_symlinks.sh`) - Symlink validation and repair
- Symlink Validator (`scripts/validate_symlinks.py`) - Continuous symlink health checks

**Next Step**: Implement [STORY-001: Doc Router](./EPICS/EPIC-001-Synchronisation/Stories/STORY-001-DocRouter/README.md)

## Best Practices

### 1. Single Source of Truth
- **Vault** = authoritative product knowledge
- **Code repo** = symlink access for convenience
- Never duplicate; always link

### 2. Separation of Concerns
- **UPMS** = reusable methodology (any product can use)
- **SynapticTrading_Product** = specific execution (this product only)
- **SynapticTrading_KnowledgeVault** = system design (how it all works)

### 3. Git Workflow
- Vault has its own git repository
- Code repository has its own git repository
- Symlinks are committed to code repo (not the content)
- Changes to vault content tracked in vault repo

### 4. Access Patterns
- Engineers: code repo → symlinks → vault content
- PMs: direct access to Obsidian vault
- Everyone: single source of truth in vault

## Maintenance

### Symlink Health Checks

Periodically verify symlinks are valid:

```bash
cd /Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/documentation/
find . -type l ! -exec test -e {} \; -print
```

Empty output = all symlinks valid

### Adding New Symlinks

When new vault directories are created:

1. Assess if engineers need access from code repo
2. If yes, create symlink following naming pattern: `vault_<name>`
3. Document the new symlink in code repo documentation README
4. Notify team of new available resources

## Future Enhancements

- Automated symlink creation scripts
- Symlink health monitoring
- Bidirectional sync automation (EPIC-001)
- Usage analytics and patterns
- Integration with CI/CD pipelines

## Questions & Support

**Architecture questions**: See `Design/` directory
**Setup issues**: Review symlink commands above
**Methodology questions**: See `UPMS/` in main vault
**Product questions**: See `SynapticTrading_Product/` in main vault

---

**Created**: 2025-11-05
**Status**: Active
**Last Updated**: 2025-11-05
**Owner**: Product Operations Team
