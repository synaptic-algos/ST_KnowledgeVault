# STORY-001: Doc Router and Symlink Automation

**Story ID**: STORY-001-DocRouter
**Epic**: [[../../README.md|EPIC-001: Vault Synchronisation Automation]]
**Status**: 📋 Planned
**Owner**: DevOps Team
**Estimated Effort**: 5 days
**Created**: 2025-11-05
**Updated**: 2025-11-12

---

## Goal

Ship a repeatable workflow that identifies newly generated documentation in the code repository, routes it into the knowledge vault with proper metadata, and keeps the code repository linked to vault content through validated symlinks.

---

## User Story

**As an** engineer using Claude Code to generate documentation

**I want** documentation to automatically move to the vault with proper metadata

**So that** I don't have to manually copy files, add YAML frontmatter, or update EPIC/Feature links

---

## Scope

### In Scope
1. **Documentation Router** (`scripts/claude_doc_router.py`)
   - Detect new documentation files in code repository
   - Propose vault destinations based on routing rules
   - Request user confirmation before moving
   - Move files to vault with directory creation
   - Inject YAML frontmatter if missing
   - Update EPIC/Feature/Story indexes with backlinks

2. **Routing Configuration** (`config/doc_routing.yml`)
   - Define filename patterns → vault destinations
   - Specify metadata templates per file type
   - Configure backlink target specifications
   - Support for custom routing rules

3. **Symlink Bootstrap** (`VaultGuide/setup_vault_symlinks.sh`)
   - Already exists ✅
   - Ensure it validates and repairs symlinks
   - Add health check capability

4. **Documentation Updates**
   - Update `CLAUDE.md` with workflow instructions
   - Update code repo `README.md` with make targets
   - Update VaultGuide with automation details

5. **Design Documentation**
   - Detailed design at [[../../../Design/DOC_ROUTER_DESIGN.md|DOC_ROUTER_DESIGN.md]]

### Out of Scope (Future Work)
- AI-powered destination suggestions (using Claude API)
- Automated routing without confirmation
- Git hooks integration
- CI/CD pipeline integration
- Slack notifications
- Web UI dashboard

---

## Deliverables

### 1. Router Script (`scripts/claude_doc_router.py`)

**Functionality**:
```python
# Usage
python scripts/claude_doc_router.py --interactive

# What it does:
# 1. Scans configured paths for new .md files
# 2. Applies routing rules from config/doc_routing.yml
# 3. Presents proposed destination + metadata
# 4. Waits for user confirmation (y/n/edit)
# 5. Moves file to vault destination
# 6. Injects YAML frontmatter
# 7. Updates EPIC/Feature/Story backlinks
# 8. Prints summary of actions taken
```

**Key Features**:
- Interactive confirmation with preview
- Dry-run mode for testing (`--dry-run`)
- Verbose logging (`--verbose`)
- Skip already-routed files
- Rollback capability on error

### 2. Routing Configuration (`config/doc_routing.yml`)

**Example Structure**:
```yaml
# Scan paths (relative to code repo root)
scan_paths:
  - "documentation/"
  - "docs/"
  - "./"

# Vault root (relative to code repo or absolute)
vault_root: "../../../KnowledgeVaults/SynapticTrading_Vault/Product/"

# Routing rules (first match wins)
routing_rules:
  # Implementation summaries
  - pattern: "IMPLEMENTATION-*.md"
    destination: "TechnicalDocumentation/"
    metadata:
      artifact_type: implementation_summary
      owner: eng_team
    backlink_targets:
      - type: epic
        pattern: "EPIC-{epic_id}"
      - type: feature
        pattern: "FEATURE-{feature_id}"

  # Design documents
  - pattern: "DESIGN-*.md"
    destination: "Design/"
    metadata:
      artifact_type: design_document
      approval_status: draft
    backlink_targets:
      - type: epic
      - type: feature

  # Sprint summaries
  - pattern: "SPRINT-*-SUMMARY.md"
    destination: "Sprints/SPRINT-{sprint_id}/"
    metadata:
      artifact_type: sprint_summary
    backlink_targets:
      - type: epic
      - type: sprint

  # Quickstart guides
  - pattern: "QUICKSTART-*.md"
    destination: "TechnicalDocumentation/"
    metadata:
      artifact_type: guide
    backlink_targets:
      - type: epic

  # Fallback (requires manual destination)
  - pattern: "*.md"
    destination: prompt  # Ask user
    metadata:
      artifact_type: prompt
```

### 3. Enhanced Symlink Script

**Additions to existing** `VaultGuide/setup_vault_symlinks.sh`:
- Add `--check` flag to validate symlinks without changes
- Add `--repair` flag to fix broken symlinks
- Return exit code 1 if any symlinks broken (for CI/CD)

### 4. Documentation Updates

**Update `CLAUDE.md`**:
```markdown
## Documentation Workflow

After generating documentation with Claude Code:

1. Review generated files in working directory
2. Run documentation router:
   ```bash
   make archive-docs
   # or
   python scripts/claude_doc_router.py --interactive
   ```
3. Confirm proposed destinations
4. Router moves files to vault with metadata
5. Commit vault changes

**Symlink Validation**:
```bash
# Check symlink health
make check-symlinks

# Repair broken symlinks
./VaultGuide/setup_vault_symlinks.sh --repair
```
```

**Update code repo `README.md`**:
```markdown
## Make Targets

- `make archive-docs` - Route Claude-generated docs to vault
- `make check-symlinks` - Validate vault symlinks
- `make bootstrap` - Setup symlinks (first time only)
```

**Update `VaultGuide/README.md`**:
- Add section on documentation routing workflow
- Link to EPIC-001 and STORY-001
- Document routing configuration options

### 5. Design Document

Complete design at: `VaultGuide/Design/DOC_ROUTER_DESIGN.md`

---

## Acceptance Criteria

### Functional Requirements
- [ ] **Router Detection**: Scanning code repo paths finds all new .md files not already in vault
- [ ] **Pattern Matching**: Routing rules correctly match filenames and propose destinations
- [ ] **Interactive Confirmation**: User can confirm, reject, or edit each proposed routing
- [ ] **File Movement**: Files move to correct vault directories (creating dirs if needed)
- [ ] **YAML Injection**: Missing frontmatter added with all required fields (id, artifact_type, created_at, etc.)
- [ ] **Backlink Updates**: EPIC/Feature/Story READMEs updated with links to new artifacts
- [ ] **Symlink Validation**: `setup_vault_symlinks.sh --check` detects broken symlinks
- [ ] **Symlink Repair**: `setup_vault_symlinks.sh --repair` fixes broken symlinks

### Quality Requirements
- [ ] **No Data Loss**: Original files backed up before move (safety net)
- [ ] **Idempotency**: Running router twice doesn't create duplicates
- [ ] **Error Handling**: Clear error messages for all failure scenarios
- [ ] **Logging**: Verbose mode logs all actions taken
- [ ] **Dry Run**: `--dry-run` shows what would happen without making changes

### Performance Requirements
- [ ] **Speed**: Router completes scan + routing in < 30 seconds
- [ ] **Responsiveness**: Interactive prompts appear immediately
- [ ] **Validation**: Symlink check completes in < 5 seconds

### Documentation Requirements
- [ ] **CLAUDE.md**: Workflow instructions complete and accurate
- [ ] **README.md**: Make targets documented
- [ ] **VaultGuide**: Automation details documented
- [ ] **Design Doc**: Complete technical design available

---

## Tasks

### Phase 1: Core Router (3 days)
- [ ] Implement file scanner (`scan_new_docs()`)
- [ ] Implement pattern matcher (`match_routing_rules()`)
- [ ] Implement interactive confirmation (`prompt_user()`)
- [ ] Implement file mover (`move_to_vault()`)
- [ ] Implement YAML injector (`add_frontmatter()`)
- [ ] Write unit tests for core functions
- [ ] Create example routing configuration

### Phase 2: Backlink Automation (1 day)
- [ ] Implement EPIC README updater
- [ ] Implement Feature TRACEABILITY updater
- [ ] Implement Story README updater
- [ ] Implement Sprint SUMMARY updater
- [ ] Write integration tests for backlinks

### Phase 3: Symlink Enhancements (0.5 days)
- [ ] Add `--check` flag to symlink script
- [ ] Add `--repair` flag to symlink script
- [ ] Add exit codes for CI/CD integration
- [ ] Test on fresh repo clone

### Phase 4: Documentation & Integration (0.5 days)
- [ ] Update CLAUDE.md with workflow
- [ ] Update README.md with make targets
- [ ] Create Makefile entries
- [ ] Update VaultGuide README
- [ ] Write end-to-end test

---

## Testing Strategy

### Unit Tests
```python
# tests/tools/test_claude_doc_router.py
def test_scan_new_docs():
    """Test file scanner finds new markdown files"""

def test_match_routing_rules():
    """Test pattern matching against routing config"""

def test_inject_frontmatter():
    """Test YAML frontmatter injection"""

def test_move_to_vault():
    """Test file movement with backup"""
```

### Integration Tests
```python
# tests/integration/test_doc_routing_flow.py
def test_end_to_end_routing():
    """Test complete routing flow from detection to vault"""

def test_backlink_updates():
    """Test EPIC/Feature/Story updates"""

def test_symlink_validation():
    """Test symlink check and repair"""
```

### Manual Testing Checklist
- [ ] Generate new doc with Claude Code
- [ ] Run `make archive-docs`
- [ ] Confirm proposed destination
- [ ] Verify file moved to vault
- [ ] Verify YAML frontmatter complete
- [ ] Verify EPIC README updated with backlink
- [ ] Verify symlink still works
- [ ] Run `make check-symlinks` (should pass)

---

## Dependencies

### Technical Dependencies
- Python 3.9+
- PyYAML library
- pathlib (stdlib)
- Existing vault structure
- Existing symlink script

### Process Dependencies
- VaultGuide documentation complete
- UPMS templates defined
- Vault directory structure finalized

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Router moves file to wrong location | 🟡 Medium | Interactive confirmation + dry-run mode |
| YAML frontmatter malformed | 🟡 Medium | Validation before writing + unit tests |
| Broken symlinks after vault changes | 🔴 High | Automated validation + repair script |
| Permission errors on macOS | 🟢 Low | Document TCC requirements in README |
| Routing config gets complex | 🟡 Medium | Clear documentation + examples |

---

## Implementation Notes

### Router Architecture
```python
# Proposed structure
class DocRouter:
    def __init__(self, config_path):
        self.config = load_yaml(config_path)
        self.vault_root = resolve_vault_path()

    def scan(self):
        """Scan code repo for new docs"""
        return find_new_markdown_files()

    def match_rules(self, filepath):
        """Match file against routing rules"""
        for rule in self.config['routing_rules']:
            if matches(filepath, rule['pattern']):
                return rule
        return None

    def propose_routing(self, filepath, rule):
        """Generate proposed destination + metadata"""
        destination = expand_template(rule['destination'], filepath)
        metadata = build_metadata(rule['metadata'], filepath)
        return Proposal(destination, metadata)

    def confirm(self, proposal):
        """Interactive confirmation"""
        print_preview(proposal)
        return prompt_user("Proceed? (y/n/edit): ")

    def route(self, filepath, proposal):
        """Move file to vault with metadata"""
        backup_file(filepath)
        inject_frontmatter(filepath, proposal.metadata)
        move_file(filepath, proposal.destination)
        update_backlinks(proposal)
```

### Backlink Update Logic
```python
def update_epic_readme(artifact_path, epic_id):
    """Add artifact link to EPIC README"""
    epic_readme = vault_root / f"EPICS/EPIC-{epic_id}/README.md"
    section = "## Related Design Documents"
    link = f"- [[{artifact_path}]]"
    append_to_section(epic_readme, section, link)
```

---

## Success Metrics

### Adoption Metrics
- **Usage Rate**: % of Claude Code sessions that use `make archive-docs`
- **Routing Accuracy**: % of files routed to correct destination (manual spot checks)
- **Symlink Health**: % of symlinks valid at any time

### Efficiency Metrics
- **Time Savings**: Time saved vs manual documentation routing
- **Error Reduction**: % reduction in missing YAML frontmatter
- **Backlink Completeness**: % of artifacts with proper EPIC/Feature links

### Target Values
- 90% usage rate within 2 weeks
- 95% routing accuracy
- 100% symlink health
- 80% time savings (from ~5 min to ~1 min per doc)

---

## Related Documentation

- **Epic**: [[../../README.md|EPIC-001 Synchronisation]]
- **Design**: [[../../../Design/DOC_ROUTER_DESIGN.md|Doc Router Design]]
- **VaultGuide**: [[../../../README.md|VaultGuide README]]
- **UPMS Templates**: [[../../../../../UPMS_Vault/Templates/|UPMS Templates]]

---

**Status**: 📋 Planned
**Next Step**: Begin Phase 1 implementation (Core Router)
**Owner**: DevOps Team
**Last Updated**: 2025-11-12
