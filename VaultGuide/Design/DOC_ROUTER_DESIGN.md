# DESIGN – Documentation Synchronisation Workflow

**Design ID**: DESIGN-VAULT-001
**Related Epic**: [[../EPICS/EPIC-001-Synchronisation/README.md|EPIC-001: Vault Synchronisation]]
**Related Story**: [[../EPICS/EPIC-001-Synchronisation/Stories/STORY-001-DocRouter/README.md|STORY-001: Doc Router]]
**Status**: Draft
**Owner**: DevOps Team
**Created**: 2025-11-05
**Updated**: 2025-11-12

---

## Context

Claude Code sessions produce implementation artifacts (implementation summaries, design documents, schemas, quickstart guides) inside the code repository workspace. These docs must live in the knowledge vault for long-term curation while remaining accessible to engineers working in the code base via symlinks.

### Problem Statement

**Current Pain**:
- Engineers manually copy Claude-generated docs to vault
- YAML frontmatter often missing or inconsistent
- EPIC/Feature/Story links not established
- Symlinks break when vault structure changes
- Time-consuming and error-prone process

**Desired State**:
- Automated detection and routing of generated documentation
- Consistent metadata on all artifacts
- Bidirectional traceability (doc ↔ EPIC/Feature/Story)
- Healthy symlinks maintained automatically
- < 1 minute from doc generation to vault integration

---

## Goals

1. **Preserve Single Source of Truth**: Knowledge vault remains the authoritative source for all documentation
2. **Engineer Convenience**: Instant access to vault docs through symlinks in code repository
3. **Minimize Manual Steps**: Automate detection, routing, metadata injection, and backlink updates
4. **Ensure Quality**: Validate metadata completeness and symlink health
5. **Support Workflow**: Integrate seamlessly into existing development workflow

---

## Architecture Overview

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Code Repository Workspace                                   │
│ /Users/.../CodeRepository/SynapticTrading/                 │
│                                                             │
│  ┌─────────────────┐                                       │
│  │ Claude Code     │ Generates documentation               │
│  │ Session         │ (DESIGN-*.md, IMPLEMENTATION-*.md)    │
│  └────────┬────────┘                                       │
│           │                                                 │
│           ├─► documentation/ (new .md files)               │
│           ├─► docs/                                        │
│           └─► ./ (root)                                    │
└─────────────────────────────────────────────────────────────┘
           │
           │ 1. Engineer runs: make archive-docs
           ↓
┌─────────────────────────────────────────────────────────────┐
│ Documentation Router                                        │
│ scripts/claude_doc_router.py                               │
│                                                             │
│  ┌──────────────────────────────────────────┐             │
│  │ Step 1: Scan for New Docs                │             │
│  │ - Check scan_paths from config           │             │
│  │ - Find .md files not in vault            │             │
│  └──────────────┬───────────────────────────┘             │
│                 │                                           │
│  ┌──────────────▼───────────────────────────┐             │
│  │ Step 2: Match Routing Rules              │             │
│  │ - Load config/doc_routing.yml            │             │
│  │ - Match filename patterns                │             │
│  │ - Determine destination                   │             │
│  └──────────────┬───────────────────────────┘             │
│                 │                                           │
│  ┌──────────────▼───────────────────────────┐             │
│  │ Step 3: Propose Routing                  │             │
│  │ - Show: source → destination             │             │
│  │ - Show: metadata to inject                │             │
│  │ - Show: backlinks to update               │             │
│  └──────────────┬───────────────────────────┘             │
│                 │                                           │
│  ┌──────────────▼───────────────────────────┐             │
│  │ Step 4: Interactive Confirmation         │             │
│  │ - User input: (y)es, (n)o, (e)dit       │             │
│  │ - If edit: allow destination change       │             │
│  └──────────────┬───────────────────────────┘             │
│                 │                                           │
│  ┌──────────────▼───────────────────────────┐             │
│  │ Step 5: Execute Routing                  │             │
│  │ - Backup original file                    │             │
│  │ - Inject YAML frontmatter                 │             │
│  │ - Move to vault destination               │             │
│  │ - Update EPIC/Feature/Story backlinks     │             │
│  └──────────────┬───────────────────────────┘             │
│                 │                                           │
│  ┌──────────────▼───────────────────────────┐             │
│  │ Step 6: Validate Results                 │             │
│  │ - Verify file in vault                    │             │
│  │ - Check YAML valid                        │             │
│  │ - Confirm backlinks added                 │             │
│  └───────────────────────────────────────────┘             │
└─────────────────────────────────────────────────────────────┘
           │
           │ Files now in vault
           ↓
┌─────────────────────────────────────────────────────────────┐
│ Knowledge Vault                                             │
│ /Users/.../KnowledgeVaults/SynapticTrading_Vault/Product/  │
│                                                             │
│  Product/                                                   │
│  ├── Design/                                               │
│  │   └── DESIGN-*.md ← [moved here]                       │
│  ├── TechnicalDocumentation/                              │
│  │   └── IMPLEMENTATION-*.md ← [moved here]              │
│  ├── Sprints/                                             │
│  │   └── SPRINT-*/SUMMARY.md ← [moved here]              │
│  └── EPICS/                                               │
│      └── EPIC-XXX/                                        │
│          └── README.md ← [backlink added]                 │
└─────────────────────────────────────────────────────────────┘
           │
           │ Symlinks maintained
           ↓
┌─────────────────────────────────────────────────────────────┐
│ Code Repository /documentation/ (Engineer Access)          │
│                                                             │
│  documentation/                                            │
│  ├── vault_design → ../../../Vault/Product/Design/        │
│  ├── vault_technical_docs → ../../../Vault/Product/Tech...│
│  ├── vault_epics → ../../../Vault/Product/EPICS/         │
│  └── vault_sprints → ../../../Vault/Product/Sprints/     │
│                                                             │
│  [Engineers see all vault content via symlinks]            │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Components

### 1. Documentation Router (`scripts/claude_doc_router.py`)

#### Purpose
Orchestrate the detection, classification, and routing of documentation from code repository to knowledge vault.

#### Core Classes

```python
class DocRouter:
    """Main orchestrator for documentation routing"""

    def __init__(self, config_path: str):
        self.config = RoutingConfig.load(config_path)
        self.vault_root = self._resolve_vault_root()
        self.scanner = FileScanner(self.config.scan_paths)
        self.matcher = RuleMatcher(self.config.routing_rules)
        self.mover = FileMover(self.vault_root)
        self.backlinker = BacklinkUpdater(self.vault_root)

    def run(self, interactive: bool = True, dry_run: bool = False):
        """Main execution flow"""
        # 1. Scan for new docs
        new_docs = self.scanner.find_new_docs()

        # 2. Match against routing rules
        proposals = []
        for doc in new_docs:
            rule = self.matcher.match(doc)
            proposal = self._create_proposal(doc, rule)
            proposals.append(proposal)

        # 3. Confirm (if interactive)
        if interactive:
            proposals = self._confirm_proposals(proposals)

        # 4. Execute routing
        if not dry_run:
            for proposal in proposals:
                self._route_document(proposal)

        # 5. Report results
        return RoutingReport(proposals)

    def _route_document(self, proposal: Proposal):
        """Execute a single document routing"""
        # Backup original
        self.mover.backup(proposal.source)

        # Inject YAML frontmatter
        self.mover.inject_frontmatter(proposal.source, proposal.metadata)

        # Move to vault
        self.mover.move(proposal.source, proposal.destination)

        # Update backlinks
        self.backlinker.update(proposal)


class FileScanner:
    """Scan code repository for new markdown files"""

    def __init__(self, scan_paths: List[str]):
        self.scan_paths = scan_paths

    def find_new_docs(self) -> List[Path]:
        """Find .md files not already in vault"""
        candidates = []
        for scan_path in self.scan_paths:
            candidates.extend(Path(scan_path).rglob("*.md"))

        # Filter out files already in vault
        return [f for f in candidates if not self._in_vault(f)]

    def _in_vault(self, filepath: Path) -> bool:
        """Check if file already exists in vault"""
        # Implementation: search vault for matching filename


class RuleMatcher:
    """Match files against routing rules"""

    def __init__(self, rules: List[RoutingRule]):
        self.rules = rules

    def match(self, filepath: Path) -> Optional[RoutingRule]:
        """Find first matching rule for file"""
        for rule in self.rules:
            if fnmatch.fnmatch(filepath.name, rule.pattern):
                return rule
        return None


class FileMover:
    """Handle file movement and metadata injection"""

    def backup(self, filepath: Path):
        """Create backup before moving"""
        backup_path = filepath.with_suffix('.md.backup')
        shutil.copy2(filepath, backup_path)

    def inject_frontmatter(self, filepath: Path, metadata: dict):
        """Add or update YAML frontmatter"""
        content = filepath.read_text()

        # Check if frontmatter exists
        if content.startswith('---'):
            # Update existing frontmatter
            pass
        else:
            # Inject new frontmatter
            frontmatter = self._build_frontmatter(metadata)
            new_content = f"{frontmatter}\n\n{content}"
            filepath.write_text(new_content)

    def move(self, source: Path, destination: Path):
        """Move file to vault destination"""
        # Create destination directory if needed
        destination.parent.mkdir(parents=True, exist_ok=True)

        # Move file
        shutil.move(str(source), str(destination))


class BacklinkUpdater:
    """Update EPIC/Feature/Story backlinks"""

    def update(self, proposal: Proposal):
        """Add backlinks to relevant artifacts"""
        for target in proposal.backlink_targets:
            if target.type == 'epic':
                self._update_epic_readme(target.id, proposal.destination)
            elif target.type == 'feature':
                self._update_feature_traceability(target.id, proposal.destination)
            elif target.type == 'story':
                self._update_story_readme(target.id, proposal.destination)

    def _update_epic_readme(self, epic_id: str, artifact_path: Path):
        """Add artifact link to EPIC README"""
        epic_readme = self.vault_root / f"EPICS/EPIC-{epic_id}/README.md"

        # Find "Related Design Documents" section
        section = "## Related Design Documents"

        # Add link
        link = f"- [[{artifact_path.relative_to(epic_readme.parent)}]]"

        # Append to section
        self._append_to_section(epic_readme, section, link)
```

#### Command-Line Interface

```bash
# Interactive mode (default)
python scripts/claude_doc_router.py --interactive

# Dry run (preview without changes)
python scripts/claude_doc_router.py --dry-run

# Automatic mode (no confirmation)
python scripts/claude_doc_router.py --auto

# Verbose logging
python scripts/claude_doc_router.py --verbose

# Custom config
python scripts/claude_doc_router.py --config config/custom_routing.yml
```

---

### 2. Routing Configuration (`config/doc_routing.yml`)

#### Purpose
Define declarative rules for mapping files to vault destinations and metadata.

#### Structure

```yaml
# Paths to scan for new documentation (relative to code repo root)
scan_paths:
  - "documentation/"
  - "docs/"
  - "./"  # root level

# Exclude patterns (files to ignore)
exclude_patterns:
  - "**/.DS_Store"
  - "**/node_modules/**"
  - "**/__pycache__/**"
  - "**/README.md"  # Don't route repo README

# Vault root (can be relative or absolute)
vault_root: "../../../KnowledgeVaults/SynapticTrading_Vault/Product/"

# Routing rules (evaluated in order, first match wins)
routing_rules:
  # Design documents
  - name: "Design Documents"
    pattern: "DESIGN-*.md"
    destination: "Design/"
    metadata:
      artifact_type: design_document
      approval_status: draft
      owner: eng_team
    backlink_targets:
      - type: epic
        pattern: "EPIC-{epic_id}"
        section: "## Related Design Documents"
      - type: feature
        pattern: "FEATURE-{feature_id}"
        section: "## Design Documents"

  # Implementation summaries
  - name: "Implementation Summaries"
    pattern: "IMPLEMENTATION-*.md"
    destination: "TechnicalDocumentation/"
    metadata:
      artifact_type: implementation_summary
      owner: eng_team
    backlink_targets:
      - type: epic
      - type: feature

  # Sprint summaries
  - name: "Sprint Summaries"
    pattern: "SPRINT-*-SUMMARY.md"
    destination: "Sprints/SPRINT-{sprint_id}/"
    metadata:
      artifact_type: sprint_summary
    backlink_targets:
      - type: epic
      - type: sprint

  # Nautilus integration docs
  - name: "Nautilus Documents"
    pattern: "NAUTILUS-*.md"
    destination: "TechnicalDocumentation/Nautilus/"
    metadata:
      artifact_type: technical_documentation
      subsystem: nautilus

  # Greeks calculation docs
  - name: "Greeks Documents"
    pattern: "GREEKS-*.md"
    destination: "TechnicalDocumentation/Greeks/"
    metadata:
      artifact_type: technical_documentation
      subsystem: greeks

  # Quickstart guides
  - name: "Quickstart Guides"
    pattern: "QUICKSTART-*.md"
    destination: "TechnicalDocumentation/"
    metadata:
      artifact_type: guide
      audience: developers

  # Database setup docs
  - name: "Setup Guides"
    pattern: "SETUP-*.md"
    destination: "TechnicalDocumentation/Setup/"
    metadata:
      artifact_type: setup_guide

  # Data pipeline docs
  - name: "Data Pipeline Docs"
    pattern: "*-DATA-PIPELINE-*.md"
    destination: "Design/"
    metadata:
      artifact_type: architecture_document
      subsystem: data_pipeline

  # Correct approach docs (architectural decisions)
  - name: "Architectural Decisions"
    pattern: "CORRECT-*-APPROACH.md"
    destination: "Design/Decisions/"
    metadata:
      artifact_type: architectural_decision

  # Fallback: prompt user for destination
  - name: "Unknown Documents"
    pattern: "*.md"
    destination: "prompt"  # Special value: ask user
    metadata:
      artifact_type: "prompt"

# Metadata templates (applied to all documents)
default_metadata:
  created_at: "{timestamp}"
  source_repo: "SynapticTrading"
  artifact_type: "{detected_or_configured}"
  related_epic: []
  related_feature: []
  related_story: []
```

#### Template Variables

Available variables for expansion in `destination` and `metadata`:

- `{filename}` - Original filename
- `{basename}` - Filename without extension
- `{timestamp}` - ISO 8601 timestamp
- `{epic_id}` - Extracted from filename (EPIC-XXX)
- `{feature_id}` - Extracted from filename (FEATURE-YYY)
- `{sprint_id}` - Extracted from filename (SPRINT-YYYYMMDD-xxx)
- `{subsystem}` - Detected subsystem name

---

### 3. Symlink Manager (`VaultGuide/setup_vault_symlinks.sh`)

#### Purpose
Validate and maintain symlinks between code repository and knowledge vault.

#### Enhancements (to existing script)

```bash
#!/bin/bash
# VaultGuide/setup_vault_symlinks.sh

# Enhanced functionality
MODE="${1:---setup}"  # --setup, --check, --repair

VAULT_ROOT="/Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault/Product"
CODE_REPO_DOCS="/Users/nitindhawan/Downloads/CodeRepository/SynapticTrading/documentation"

# Symlink definitions
declare -A SYMLINKS=(
    ["vault_epics"]="$VAULT_ROOT/EPICS"
    ["vault_design"]="$VAULT_ROOT/Design"
    ["vault_strategies"]="$VAULT_ROOT/Strategies"
    ["vault_prd"]="$VAULT_ROOT/PRD"
    ["vault_research"]="$VAULT_ROOT/Research"
    ["vault_sprints"]="$VAULT_ROOT/Sprints"
    ["vault_technical_docs"]="$VAULT_ROOT/TechnicalDocumentation"
    ["vault_product_templates"]="$VAULT_ROOT/Templates"
)

case "$MODE" in
    --setup)
        echo "Creating symlinks..."
        for link_name in "${!SYMLINKS[@]}"; do
            create_symlink "$link_name" "${SYMLINKS[$link_name]}"
        done
        ;;

    --check)
        echo "Checking symlink health..."
        BROKEN_COUNT=0
        for link_name in "${!SYMLINKS[@]}"; do
            check_symlink "$link_name" "${SYMLINKS[$link_name]}" || ((BROKEN_COUNT++))
        done
        if [ $BROKEN_COUNT -gt 0 ]; then
            echo "❌ Found $BROKEN_COUNT broken symlink(s)"
            exit 1
        else
            echo "✅ All symlinks healthy"
            exit 0
        fi
        ;;

    --repair)
        echo "Repairing broken symlinks..."
        for link_name in "${!SYMLINKS[@]}"; do
            repair_symlink "$link_name" "${SYMLINKS[$link_name]}"
        done
        ;;
esac
```

---

### 4. Symlink Validator (`scripts/validate_symlinks.py`)

#### Purpose
Continuous validation of symlink integrity (for CI/CD integration).

```python
#!/usr/bin/env python3
"""Validate symlinks between code repository and vault"""

import sys
from pathlib import Path
from typing import List, Tuple

SYMLINK_DEFINITIONS = {
    "vault_epics": "../../../KnowledgeVaults/SynapticTrading_Vault/Product/EPICS",
    "vault_design": "../../../KnowledgeVaults/SynapticTrading_Vault/Product/Design",
    "vault_strategies": "../../../KnowledgeVaults/SynapticTrading_Vault/Product/Strategies",
    "vault_prd": "../../../KnowledgeVaults/SynapticTrading_Vault/Product/PRD",
    "vault_research": "../../../KnowledgeVaults/SynapticTrading_Vault/Product/Research",
    "vault_sprints": "../../../KnowledgeVaults/SynapticTrading_Vault/Product/Sprints",
    "vault_technical_docs": "../../../KnowledgeVaults/SynapticTrading_Vault/Product/TechnicalDocumentation",
}

def check_symlinks() -> Tuple[List[str], List[str]]:
    """Check all symlinks, return (valid, broken)"""
    valid = []
    broken = []

    docs_dir = Path("documentation")
    for link_name, target_rel_path in SYMLINK_DEFINITIONS.items():
        link_path = docs_dir / link_name

        if not link_path.exists():
            broken.append(f"{link_name}: does not exist")
        elif not link_path.is_symlink():
            broken.append(f"{link_name}: not a symlink")
        elif not link_path.resolve().exists():
            broken.append(f"{link_name}: target does not exist")
        else:
            valid.append(link_name)

    return valid, broken

def main():
    valid, broken = check_symlinks()

    print(f"✅ Valid symlinks: {len(valid)}")
    for link in valid:
        print(f"  - {link}")

    if broken:
        print(f"\n❌ Broken symlinks: {len(broken)}")
        for error in broken:
            print(f"  - {error}")
        sys.exit(1)
    else:
        print("\n✅ All symlinks healthy")
        sys.exit(0)

if __name__ == "__main__":
    main()
```

---

## Operational Flow

### End-to-End Workflow

1. **Engineer runs Claude Code**
   - Claude generates documentation (DESIGN-xxx.md, IMPLEMENTATION-xxx.md, etc.)
   - Files appear in code repository working directory

2. **Engineer runs `make archive-docs`**
   - Wrapper executes `claude_doc_router.py --interactive`
   - Router scans configured paths for new .md files

3. **Router proposes routings**
   ```
   Found 3 new documents:

   [1/3] DESIGN-DATA-PIPELINE.md
     → Destination: Product/Design/DATA-PIPELINE.md
     → Metadata: artifact_type=design_document, owner=eng_team
     → Backlinks: EPIC-007 README
     Proceed? (y/n/e)dit: y

   [2/3] IMPLEMENTATION-GREEKS.md
     → Destination: Product/TechnicalDocumentation/GREEKS-IMPLEMENTATION.md
     → Metadata: artifact_type=implementation_summary
     → Backlinks: EPIC-007 README, FEATURE-006 TRACEABILITY
     Proceed? (y/n/e)dit: y

   [3/3] QUICKSTART-BACKTEST.md
     → Destination: Product/TechnicalDocumentation/QUICKSTART-BACKTEST.md
     → Metadata: artifact_type=guide, audience=developers
     → Backlinks: EPIC-002 README
     Proceed? (y/n/e)dit: y
   ```

4. **Router executes routings**
   - Backs up original files
   - Injects YAML frontmatter
   - Moves files to vault destinations (creating directories as needed)
   - Updates EPIC/Feature/Story READMEs with backlinks
   - Prints summary

5. **Engineer verifies and commits**
   ```bash
   # Check vault changes
   cd /Users/nitindhawan/KnowledgeVaults/SynapticTrading_Vault
   git status
   git diff

   # Commit vault changes
   git add .
   git commit -m "Add documentation: DATA-PIPELINE design, GREEKS implementation, BACKTEST quickstart"
   git push

   # Verify symlinks still work
   make check-symlinks
   ```

6. **Symlinks provide immediate access**
   - Engineers see new docs in `documentation/vault_*` directories
   - Obsidian shows new docs in vault with full graph navigation

---

## Integration with Developer Workflow

### Makefile Targets

```makefile
# Code repository Makefile

.PHONY: archive-docs check-symlinks bootstrap

# Route documentation to vault
archive-docs:
	@echo "Routing documentation to vault..."
	python scripts/claude_doc_router.py --interactive

# Validate symlink health
check-symlinks:
	@echo "Checking symlink health..."
	@python scripts/validate_symlinks.py || (echo "Run 'make repair-symlinks' to fix" && exit 1)

# Repair broken symlinks
repair-symlinks:
	@echo "Repairing broken symlinks..."
	@./VaultGuide/setup_vault_symlinks.sh --repair

# First-time setup
bootstrap:
	@echo "Setting up vault symlinks..."
	@./VaultGuide/setup_vault_symlinks.sh --setup
```

### Git Hooks (Optional)

```bash
# .git/hooks/pre-commit
#!/bin/bash
# Validate symlinks before commit
make check-symlinks || {
    echo "❌ Broken symlinks detected. Run 'make repair-symlinks'"
    exit 1
}

# .git/hooks/post-merge
#!/bin/bash
# Repair symlinks after pulling changes
make repair-symlinks
```

---

## Open Questions & Decisions

### 1. Should routing ever happen automatically (no prompt)?
**Status**: Open
**Options**:
- A: Always require confirmation (safest, slowest)
- B: Automatic for trusted patterns, prompt for unknown (recommended)
- C: Fully automatic with rollback capability (fastest, riskiest)

**Recommendation**: Start with B. Define "trusted patterns" after observing routing accuracy for 2-3 weeks.

### 2. How to surface routing failures or skipped files?
**Status**: Open
**Options**:
- A: Log file only
- B: Log file + terminal warning
- C: Log file + Slack notification
- D: All of the above

**Recommendation**: Start with B (log + terminal). Add Slack (C) if failures become common.

### 3. Governance process for evolving `doc_routing.yml`?
**Status**: Open
**Recommendation**: Product Owner approval required for routing rule changes. Document in VaultGuide README.

### 4. How to handle routing conflicts (multiple pattern matches)?
**Status**: Decided
**Decision**: First matching rule wins (rules evaluated in order). If truly ambiguous, use `destination: prompt` pattern.

---

## Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Router moves file to wrong location | Medium | Medium | Interactive confirmation + dry-run mode + backup |
| YAML frontmatter malformed | Low | Medium | Validation before writing + unit tests |
| Broken symlinks after vault restructure | High | High | Automated validation + repair script + pre-commit hook |
| Permission errors (macOS TCC) | Low | Low | Document TCC requirements in README |
| Routing config becomes unmaintainable | Medium | Medium | Clear documentation + periodic review + governance |
| Metadata drift over time | Medium | High | Enforce frontmatter validation + UPMS compliance checks |

---

## Testing Strategy

### Unit Tests
- File scanner finds all new docs
- Pattern matcher correctly matches rules
- YAML injection preserves file content
- Backlink updater adds links to correct sections

### Integration Tests
- End-to-end routing flow (scan → match → confirm → move → backlink)
- Symlink validation detects broken links
- Symlink repair fixes broken links
- Makefile targets execute correctly

### Manual Testing
- Generate doc with Claude Code
- Run `make archive-docs`
- Verify file in correct vault location
- Verify YAML frontmatter complete
- Verify EPIC README updated with backlink
- Verify symlink still works
- Run `make check-symlinks` (should pass)

---

## Success Metrics

### Adoption
- 90% of Claude Code sessions use `make archive-docs` within 2 weeks
- 95% routing accuracy (files go to correct destination)
- 100% symlink health at all times

### Efficiency
- < 1 minute from doc generation to vault integration (vs ~5 minutes manual)
- 80% reduction in missing YAML frontmatter
- 100% of artifacts have proper EPIC/Feature backlinks

### Quality
- Zero data loss incidents
- < 1% routing errors requiring manual fixes
- Zero broken symlink incidents

---

## Future Enhancements

### Phase 2: AI-Powered Routing
- Use Claude API to suggest destinations based on content analysis
- Automatic metadata enrichment (related_epic, related_feature extraction)
- Context-aware routing rules

### Phase 3: Advanced Automation
- Git hooks for automatic routing on commit
- CI/CD pipeline integration
- Automated PR comments with routing summary
- Slack notifications for routing events

### Phase 4: Analytics & Monitoring
- Dashboard showing routing statistics
- Symlink health monitoring over time
- Metadata completeness reports
- Routing accuracy tracking

---

## Related Documentation

- **Epic**: [[../EPICS/EPIC-001-Synchronisation/README.md|EPIC-001 Synchronisation]]
- **Story**: [[../EPICS/EPIC-001-Synchronisation/Stories/STORY-001-DocRouter/README.md|STORY-001 Doc Router]]
- **VaultGuide**: [[../README.md|VaultGuide README]]
- **UPMS**: [[../../../UPMS_Vault/Methodology/UPMS_Methodology_Blueprint.md|UPMS Methodology]]

---

**Status**: Draft
**Approval Status**: Pending Review
**Next Step**: Implementation of STORY-001
**Owner**: DevOps Team
**Last Updated**: 2025-11-12
