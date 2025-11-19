# Branch Management & Parallel Development

## 📚 Documentation Index

This directory contains comprehensive guides for managing branches and enabling parallel development on the nikhilwm-opt-v2 project.

### Documents

1. **[BRANCH_WORKFLOW_GUIDE.md](./BRANCH_WORKFLOW_GUIDE.md)** - Branch Management Guide
   - Understanding the repository structure
   - Creating and managing feature branches
   - Pushing branches to the main repository
   - Parallel development workflows
   - Branch naming conventions

2. **[MULTI_DEVELOPER_WORKFLOW.md](./MULTI_DEVELOPER_WORKFLOW.md)** - Multi-Developer Workflow
   - Team setup and onboarding
   - Git branching strategy
   - Pull request process
   - Local and test server deployment
   - Port allocation for multiple developers
   - Integration and final testing
   - Release process

3. **[TEAM_ONBOARDING.md](./TEAM_ONBOARDING.md)** - Team Onboarding Quick Start
   - 15-minute new developer setup
   - Port assignment reference
   - Daily git workflow
   - Common commands
   - Troubleshooting guide
   - Onboarding checklist

4. **[CRITICAL_PATHS_ADDENDUM.md](./CRITICAL_PATHS_ADDENDUM.md)** - Critical Paths & Data Architecture
   - Results path configuration
   - Meta-indexed parquet data architecture
   - Cache directory management
   - Migration scripts
   - Verification checklists

## 🎯 Repository Structure

### Main Repository
**URL:** `https://github.com/gtalknitin/synpatictrading`

**Structure:**
```
synpatictrading/                          (main repository)
├── src/
│   └── pilot/
│       └── nikhilwm-opt-v2/             (existing v2 code - on main branch)
│           ├── application/
│           ├── domain/
│           ├── infrastructure/
│           └── ...
└── ...
```

### Feature Branches
Each developer/feature gets its own branch:
```
branches:
├── main                                  (production code)
├── pilot-synaptictrading-nitin          (Nitin's standalone work)
├── feature/vix-exit-logic               (VIX feature branch)
├── feature/delta-hedging                (Delta hedging branch)
└── feature/gamma-scalping               (Gamma scalping branch)
```

## 🚀 Quick Start for New Developers

### Option 1: Work on Existing Main Branch Code
```bash
# Clone main repository
git clone https://github.com/gtalknitin/synpatictrading.git
cd synpatictrading/src/pilot/nikhilwm-opt-v2

# Create feature branch
git checkout -b feature/your-feature-name

# Make changes and push
git add .
git commit -m "feat: Your feature description"
git push origin feature/your-feature-name
```

### Option 2: Work on Standalone Branch (Like Nitin's)
```bash
# Clone the main repository
git clone https://github.com/gtalknitin/synpatictrading.git
cd synpatictrading

# Checkout standalone branch
git checkout pilot-synaptictrading-nitin

# The entire directory is now the v2 project
# Create your feature branch from here
git checkout -b feature/your-feature-name

# Make changes and push
git add .
git commit -m "feat: Your feature description"
git push origin feature/your-feature-name
```

## 📋 Current Branch Status

### Active Branches

| Branch | Type | Owner | Description | Status |
|--------|------|-------|-------------|--------|
| `main` | Production | Team | Production code with v2 in `src/pilot/nikhilwm-opt-v2` | Active |
| `pilot-synaptictrading-nitin` | Standalone | Nitin | Standalone v2 development with recent features | Active |
| (more to come) | Feature | Various | Individual feature branches | Pending |

## 🔧 Branch Naming Conventions

```
feature/<ticket-id>-<short-description>   # New features
bugfix/<ticket-id>-<short-description>    # Bug fixes
hotfix/<short-description>                # Critical production fixes
experimental/<description>                # Experimental/POC work
```

**Examples:**
- `feature/FEAT-123-vix-exit-logic`
- `bugfix/BUG-456-rsi-calculation`
- `hotfix/critical-trade-bug`
- `experimental/ml-based-entries`

## 🎯 Parallel Development Strategy

### Scenario 1: Multiple Features on Main Branch Code
Developers work on `src/pilot/nikhilwm-opt-v2/` in the main repository:

```bash
# Developer 1
git checkout main
git pull origin main
git checkout -b feature/vix-exits
# Work in src/pilot/nikhilwm-opt-v2/

# Developer 2
git checkout main
git pull origin main
git checkout -b feature/delta-hedging
# Work in src/pilot/nikhilwm-opt-v2/

# Both push to origin and create PRs
```

### Scenario 2: Work on Standalone Branch
Developers work from the standalone branch:

```bash
# Developer 1
git checkout pilot-synaptictrading-nitin
git pull origin pilot-synaptictrading-nitin
git checkout -b feature/improve-entries
# Work on root-level files

# Developer 2
git checkout pilot-synaptictrading-nitin
git pull origin pilot-synaptictrading-nitin
git checkout -b feature/enhance-exits
# Work on root-level files

# Both push and create PRs against pilot-synaptictrading-nitin
```

## 📊 Integration Strategy

### Merging Feature Branches

**To Main Branch:**
```bash
# After feature is complete and tested
git checkout main
git pull origin main
git merge feature/your-feature --no-ff
git push origin main
```

**To Standalone Branch:**
```bash
# After feature is complete and tested
git checkout pilot-synaptictrading-nitin
git pull origin pilot-synaptictrading-nitin
git merge feature/your-feature --no-ff
git push origin pilot-synaptictrading-nitin
```

### Cross-Branch Integration (Advanced)
If you need to merge work from standalone branch to main:

```bash
# Extract specific files/changes
git checkout main
git checkout pilot-synaptictrading-nitin -- path/to/specific/file.py
git commit -m "integrate: Merge specific changes from standalone branch"
```

## 🔄 Keeping Branches in Sync

### Update Feature Branch from Base
```bash
# If working from main
git checkout feature/your-feature
git merge main

# If working from standalone
git checkout feature/your-feature
git merge pilot-synaptictrading-nitin
```

### Resolve Conflicts
```bash
# If conflicts occur during merge
git status  # See conflicted files
# Edit files to resolve conflicts
git add <resolved-files>
git commit -m "merge: Resolve conflicts"
```

## 📞 Support

For questions or issues:

1. Review [BRANCH_WORKFLOW_GUIDE.md](./BRANCH_WORKFLOW_GUIDE.md) for detailed workflows
2. Check [MULTI_DEVELOPER_WORKFLOW.md](./MULTI_DEVELOPER_WORKFLOW.md) for team collaboration
3. See [TEAM_ONBOARDING.md](./TEAM_ONBOARDING.md) for quick setup
4. Contact the development team

## 📝 Document Status

| Document | Status | Last Updated |
|----------|--------|--------------|
| README.md | ✅ Complete | 2025-10-07 |
| BRANCH_WORKFLOW_GUIDE.md | 📝 In Progress | 2025-10-07 |
| MULTI_DEVELOPER_WORKFLOW.md | ✅ Complete | 2025-10-06 |
| TEAM_ONBOARDING.md | ✅ Complete | 2025-10-06 |
| CRITICAL_PATHS_ADDENDUM.md | ✅ Complete | 2025-10-06 |

---

**Maintained By:** Synapse Trading Development Team
**Version:** 2.0 (Updated for branch-based workflow)
