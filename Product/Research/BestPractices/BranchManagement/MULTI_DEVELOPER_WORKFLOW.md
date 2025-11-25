---
artifact_type: story
created_at: '2025-11-25T16:23:21.876088Z'
id: AUTO-MULTI_DEVELOPER_WORKFLOW
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for MULTI_DEVELOPER_WORKFLOW
updated_at: '2025-11-25T16:23:21.876092Z'
---

## Initial Setup for Developers

### Prerequisites

- Git installed
- Python 3.10+
- Access to shared PostgreSQL database
- Access to project repository (GitHub/GitLab)

### Step 1: Clone Repository

```bash
# Clone the standalone repository
git clone <repository-url> nikhilwm-opt-v2
cd nikhilwm-opt-v2

# Verify remote
git remote -v
```

### Step 2: Setup Python Environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Upgrade pip
pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt
```

### Step 3: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your settings
nano .env
```

**Edit `.env` for your environment:**

```bash
# Developer-specific configuration
DEVELOPER_NAME=john_doe  # Your name/ID

# Shared Database (same for all developers)
DB_HOST=dev-postgres.company.local
DB_PORT=5432
DB_NAME=synpatictrading_dev
DB_USER=dev_user
DB_PASSWORD=<shared-dev-password>

# Local Ports (unique per developer on shared servers)
BACKEND_PORT=8000   # Developer 1: 8000, Developer 2: 8001, etc.
FRONTEND_PORT=3000  # Developer 1: 3000, Developer 2: 3001, etc.

# Cache (local to each developer)
CACHE_DIR=./data/.cache

# Results (local to each developer)
RESULTS_BASE_PATH=./backtest_results
```

### Step 4: Setup Cache Data

**Option A: Download Pre-generated Cache**

```bash
# Create cache directory
mkdir -p data/.cache

# Download cache files from shared location
scp dev-server:/shared/cache/nautilus_v10_* data/.cache/

# Or use rsync
rsync -av dev-server:/shared/cache/nautilus_v10_* data/.cache/
```

**Option B: Generate from Shared Database**

```bash
# Generate cache locally (one-time, ~10-30 minutes)
python infrastructure/data/create_nautilus_meta_index_optimized.py \
    --catalog-id v10_real_enhanced_clean \
    --output-dir data/.cache \
    --format hdf5
```

### Step 5: Verify Setup

```bash
# Run verification tests
python -c "
from v2_config import Config
from src.backtest.nautilus_adapter import NautilusMetaIndexedDataAdapter

config = Config()
print('✅ Config loaded')

adapter = NautilusMetaIndexedDataAdapter(catalog_id='v10_real_enhanced_clean')
print('✅ Data adapter initialized')
print(f'   Cache: {adapter.cache_dir}')
print(f'   Results: {config.results_base_path}')
"

# Run quick backtest test
python run_backtest.py
```

---

## Git Workflow & Branching Strategy

### Branch Structure

```
main                    # Production-ready code
├── develop             # Integration branch
├── feature/*          # Feature branches
├── bugfix/*           # Bug fix branches
├── hotfix/*           # Critical fixes
└── test/*             # Test/experimental branches
```

### Branching Rules

1. **main**: Protected, requires PR approval, auto-deploys to production
2. **develop**: Integration branch, requires PR approval
3. **feature/**: Individual features, merged to develop via PR
4. **bugfix/**: Bug fixes, merged to develop via PR
5. **hotfix/**: Critical fixes, merged to main and develop

### Creating a Feature Branch

```bash
# Update develop
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/FEAT-123-vix-exit-logic

# Work on feature
# ... make changes ...

# Commit regularly
git add .
git commit -m "feat: Add VIX-based exit logic

- Implement VIX threshold checking in exit manager
- Add VIX exit reason enum
- Update tests for VIX exits

Related: FEAT-123"

# Push to remote
git push origin feature/FEAT-123-vix-exit-logic
```

### Commit Message Convention

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

**Example:**
```
feat(exit-manager): Add VIX-based exit logic

- Implement VIX threshold checking (default: 18.0)
- Exit all positions when VIX exceeds threshold
- Add comprehensive tests for VIX exit scenarios

Related: FEAT-123
Closes: #45
```

---

## Pull Request Process

### Step 1: Pre-PR Checklist

Before creating a PR, ensure:

```bash
# 1. Code is formatted
black .

# 2. Linting passes
flake8 .

# 3. All tests pass
pytest tests/ -v

# 4. Type checking (if used)
mypy src/

# 5. Branch is up to date with develop
git checkout develop
git pull origin develop
git checkout feature/FEAT-123-vix-exit-logic
git merge develop

# 6. Resolve any conflicts
# ... fix conflicts ...
git add .
git commit -m "merge: Resolve conflicts with develop"

# 7. Push latest changes
git push origin feature/FEAT-123-vix-exit-logic
```

### Step 2: Create Pull Request

**On GitHub/GitLab:**

1. Navigate to repository
2. Click "New Pull Request"
3. Select:
   - **Base**: `develop`
   - **Compare**: `feature/FEAT-123-vix-exit-logic`

**PR Template:**

```markdown
## Description
Brief description of what this PR does.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Related Issues
Closes #45
Related: FEAT-123

## Changes Made
- Implemented VIX-based exit logic in exit manager
- Added `vix_exit_threshold` parameter to config
- Updated exit manager to check VIX on every exit evaluation
- Added comprehensive unit tests

## Testing
- [ ] Unit tests pass (`pytest tests/test_exit_manager.py`)
- [ ] Integration tests pass (`pytest tests/`)
- [ ] Manual testing completed
- [ ] Backtest runs successfully with new logic

## Backtest Results
Attached backtest results showing VIX exits working:
- 3 VIX-triggered exits during high volatility period
- Performance metrics: [attach screenshot or summary]

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated (README, docstrings)
- [ ] Tests added/updated
- [ ] No breaking changes (or clearly documented)
- [ ] Branch is up to date with develop

## Screenshots/Logs
[Attach relevant screenshots, logs, or backtest outputs]

## Deployment Notes
No special deployment steps required. VIX threshold configurable via `strategy_config.json`.

## Reviewers
@reviewer1 @reviewer2
```

### Step 3: Code Review Process

**For Author:**
1. Wait for CI/CD checks to pass
2. Address reviewer comments
3. Push updates to same branch (PR auto-updates)
4. Request re-review when ready

**For Reviewers:**
1. Review code changes
2. Check tests and documentation
3. Run locally if needed:
   ```bash
   git fetch origin
   git checkout feature/FEAT-123-vix-exit-logic
   source venv/bin/activate
   pytest tests/
   python run_backtest.py
   ```
4. Leave comments or approve
5. Approve only if:
   - Code quality is good
   - Tests pass
   - Documentation is clear
   - No breaking changes (or clearly documented)

### Step 4: Merge Pull Request

**After approval:**

```bash
# Option 1: Squash and merge (recommended for feature branches)
# - Keeps history clean
# - One commit per feature

# Option 2: Merge commit
# - Preserves all commits
# - Use for complex features with logical commit history

# Option 3: Rebase and merge
# - Linear history
# - Use for small changes
```

**Post-merge:**

```bash
# Delete feature branch (both local and remote)
git checkout develop
git pull origin develop
git branch -d feature/FEAT-123-vix-exit-logic
git push origin --delete feature/FEAT-123-vix-exit-logic
```

---

## Local Development Environment

### Port Allocation Strategy

**For developers working on SAME machine:**

| Developer | Backend Port | Frontend Port | Notes |
|-----------|--------------|---------------|-------|
| Dev 1 (John) | 8000 | 3000 | Default ports |
| Dev 2 (Jane) | 8001 | 3001 | Increment by 1 |
| Dev 3 (Bob) | 8002 | 3002 | Increment by 1 |

**Update `.env` for each developer:**

```bash
# Developer 1
BACKEND_PORT=8000
FRONTEND_PORT=3000

# Developer 2
BACKEND_PORT=8001
FRONTEND_PORT=3001

# Developer 3
BACKEND_PORT=8002
FRONTEND_PORT=3002
```

### Running Local Development

```bash
# Activate environment
source venv/bin/activate

# Run backtest (no server needed)
python run_backtest.py

# If paper trading is implemented:
# Terminal 1: Backend
cd papertrade
uvicorn app.main:app --port $BACKEND_PORT --reload

# Terminal 2: Frontend (if applicable)
cd papertrade/frontend
npm run dev -- --port $FRONTEND_PORT
```

### Local Testing

```bash
# Run all tests
pytest tests/ -v

# Run specific test file
pytest tests/test_exit_manager.py -v

# Run with coverage
pytest tests/ --cov=src --cov-report=html

# View coverage report
open htmlcov/index.html
```

---

## Test Server Deployments

### Shared Test Server Architecture

```
┌─────────────────────────────────────────────────────┐
│          Shared PostgreSQL Server                    │
│  Host: test-db.company.local:5432                   │
│  Database: synpatictrading_test                     │
└─────────────────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
┌───────▼─────┐  ┌──────▼──────┐  ┌────▼────────┐
│  Dev 1 Test │  │  Dev 2 Test │  │  Dev 3 Test │
│  Backend    │  │  Backend    │  │  Backend    │
│  Port: 9000 │  │  Port: 9001 │  │  Port: 9002 │
└─────────────┘  └─────────────┘  └─────────────┘
```

### Test Server Port Allocation

| Environment | Backend Port | Frontend Port | Description |
|-------------|--------------|---------------|-------------|
| **Dev 1 (John)** | 9000 | 4000 | John's test deployment |
| **Dev 2 (Jane)** | 9001 | 4001 | Jane's test deployment |
| **Dev 3 (Bob)** | 9002 | 4002 | Bob's test deployment |
| **Integration** | 9100 | 4100 | Shared integration environment |
| **Staging** | 9200 | 4200 | Pre-production staging |

### Deployment Configuration

**Create environment-specific config:**

`config/test.dev1.env`:
```bash
# Developer 1 Test Environment
ENVIRONMENT=test
DEVELOPER=dev1

# Shared Database
DB_HOST=test-db.company.local
DB_PORT=5432
DB_NAME=synpatictrading_test
DB_USER=test_user
DB_PASSWORD=<test-password>

# Dev 1 Specific Ports
BACKEND_PORT=9000
FRONTEND_PORT=4000

# Cache (on test server)
CACHE_DIR=/opt/nikhilwm/shared/cache

# Results
RESULTS_BASE_PATH=/opt/nikhilwm/dev1/results

# Logging
LOG_LEVEL=DEBUG
LOG_FILE=/var/log/nikhilwm/dev1.log
```

**Similar files for dev2, dev3, integration, staging**

### Deploying to Test Server

**Option 1: Manual Deployment**

```bash
# 1. SSH to test server
ssh test-server.company.local

# 2. Navigate to deployment directory
cd /opt/nikhilwm/deployments/dev1

# 3. Pull latest changes
git fetch origin
git checkout feature/FEAT-123-vix-exit-logic
git pull origin feature/FEAT-123-vix-exit-logic

# 4. Activate environment
source venv/bin/activate

# 5. Install/update dependencies
pip install -r requirements.txt

# 6. Load environment config
export $(cat config/test.dev1.env | xargs)

# 7. Run migrations (if any)
# python scripts/migrate.py

# 8. Restart service
sudo systemctl restart nikhilwm-dev1

# 9. Check status
sudo systemctl status nikhilwm-dev1

# 10. View logs
tail -f /var/log/nikhilwm/dev1.log
```

**Option 2: Deployment Script**

Create `scripts/deploy_to_test.sh`:

```bash
#!/bin/bash
set -e

# Usage: ./scripts/deploy_to_test.sh dev1 feature/FEAT-123-vix-exit-logic

DEVELOPER=$1
BRANCH=$2

if [ -z "$DEVELOPER" ] || [ -z "$BRANCH" ]; then
    echo "Usage: $0 <developer> <branch>"
    echo "Example: $0 dev1 feature/FEAT-123-vix-exit-logic"
    exit 1
fi

echo "🚀 Deploying $BRANCH to $DEVELOPER test environment..."

# Configuration
TEST_SERVER="test-server.company.local"
DEPLOY_PATH="/opt/nikhilwm/deployments/$DEVELOPER"
SERVICE_NAME="nikhilwm-$DEVELOPER"

# Deploy via SSH
ssh $TEST_SERVER << EOF
    set -e

    echo "📁 Navigating to deployment directory..."
    cd $DEPLOY_PATH

    echo "🔄 Fetching latest changes..."
    git fetch origin
    git checkout $BRANCH
    git pull origin $BRANCH

    echo "🐍 Updating Python environment..."
    source venv/bin/activate
    pip install -q -r requirements.txt

    echo "⚙️  Loading configuration..."
    export \$(cat config/test.$DEVELOPER.env | xargs)

    echo "🔄 Restarting service..."
    sudo systemctl restart $SERVICE_NAME

    echo "✅ Checking service status..."
    sleep 2
    sudo systemctl status $SERVICE_NAME --no-pager

    echo "📋 Recent logs:"
    sudo journalctl -u $SERVICE_NAME -n 20 --no-pager
EOF

echo "✅ Deployment complete!"
echo "   URL: http://test-server.company.local:\$(grep BACKEND_PORT config/test.$DEVELOPER.env | cut -d= -f2)"
echo "   Logs: ssh $TEST_SERVER 'tail -f /var/log/nikhilwm/$DEVELOPER.log'"
```

**Deploy from local machine:**

```bash
# Make executable
chmod +x scripts/deploy_to_test.sh

# Deploy your branch to your test environment
./scripts/deploy_to_test.sh dev1 feature/FEAT-123-vix-exit-logic

# Test the deployment
curl http://test-server.company.local:9000/health
```

### Testing on Test Server

```bash
# SSH to test server
ssh test-server.company.local

# Run backtest on specific deployment
cd /opt/nikhilwm/deployments/dev1
source venv/bin/activate
export $(cat config/test.dev1.env | xargs)
python run_backtest.py

# Check results
ls -la results/

# Run tests
pytest tests/ -v

# View logs
tail -f /var/log/nikhilwm/dev1.log
```

---

## Integration Testing

### Integration Environment

**Purpose:** Test multiple features together before merging to main

**Setup:**

```bash
# On test server
cd /opt/nikhilwm/deployments/integration

# Merge all feature branches to integration branch
git checkout integration
git pull origin develop
git merge feature/FEAT-123-vix-exit-logic --no-ff
git merge feature/FEAT-124-delta-hedging --no-ff
git merge feature/FEAT-125-gamma-scalping --no-ff

# Push integration branch
git push origin integration

# Deploy
./scripts/deploy_to_test.sh integration integration
```

**Integration Test Checklist:**

- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] No conflicts between features
- [ ] Performance acceptable (backtest < 60s for 3 months)
- [ ] Memory usage acceptable (< 2GB)
- [ ] Logs are clean (no errors/warnings)
- [ ] Results are accurate and consistent

### Running Integration Tests

```bash
# On test server integration environment
cd /opt/nikhilwm/deployments/integration
source venv/bin/activate
export $(cat config/test.integration.env | xargs)

# Run full test suite
pytest tests/ -v --cov=src

# Run integration-specific tests
pytest tests/integration/ -v

# Run performance test
python tests/performance/test_backtest_performance.py

# Run full backtest (3 months)
python run_backtest.py

# Generate test report
pytest tests/ --html=test_report.html --self-contained-html
```

---

## Final Testing & Release

### Pre-Release Testing

**1. Create Release Candidate**

```bash
# Merge develop to release candidate branch
git checkout main
git pull origin main
git checkout -b release/v2.1.0
git merge develop --no-ff

# Update version
echo "2.1.0" > VERSION

# Tag release candidate
git tag -a v2.1.0-rc1 -m "Release candidate 1 for version 2.1.0"
git push origin release/v2.1.0
git push origin v2.1.0-rc1
```

**2. Deploy to Staging**

```bash
# Deploy RC to staging environment
./scripts/deploy_to_test.sh staging release/v2.1.0

# Run on staging
ssh test-server.company.local
cd /opt/nikhilwm/deployments/staging
source venv/bin/activate
export $(cat config/test.staging.env | xargs)

# Full regression test
pytest tests/ -v --cov=src --cov-report=html

# Performance test
python tests/performance/benchmark_suite.py

# Full backtest (6 months)
python run_backtest.py  # With 6-month config
```

**3. Final Testing Checklist**

- [ ] All tests pass on staging
- [ ] Performance benchmarks meet SLA
  - Data loading: < 5 seconds
  - Backtest (3 months): < 60 seconds
  - Memory usage: < 2GB peak
- [ ] Manual testing completed
  - All entry scenarios work
  - All exit scenarios work
  - VIX exit triggers correctly
  - Stop loss works
  - Profit targets work
- [ ] Documentation updated
  - README.md
  - CHANGELOG.md
  - API documentation (if applicable)
- [ ] No known critical bugs
- [ ] Security review completed
- [ ] Stakeholder approval received

**4. Release Process**

```bash
# If all tests pass, merge to main
git checkout main
git merge release/v2.1.0 --no-ff -m "Release version 2.1.0

Features:
- VIX-based exit logic
- Delta hedging improvements
- Gamma scalping strategy

See CHANGELOG.md for details."

# Tag release
git tag -a v2.1.0 -m "Release version 2.1.0"

# Push to remote
git push origin main
git push origin v2.1.0

# Merge back to develop
git checkout develop
git merge main --no-ff
git push origin develop

# Delete release branch
git branch -d release/v2.1.0
git push origin --delete release/v2.1.0
```

**5. Post-Release**

```bash
# Deploy to production (in main repository)
cd /Users/nitindhawan/Downloads/CodeRepository/synpatictrading

# Create integration branch
git checkout -b integrate/nikhilwm-v2.1.0

# Sync changes from standalone
rsync -av --exclude='venv' \
          --exclude='.git' \
          ~/Downloads/CodeRepository/nikhilwm-opt-v2-standalone/ \
          src/pilot/nikhilwm-opt-v2/

# Test in main repository
cd src/pilot/nikhilwm-opt-v2
python run_backtest.py

# If good, commit and create PR
git add .
git commit -m "integrate: Merge v2.1.0 from standalone development"
git push origin integrate/nikhilwm-v2.1.0

# Create PR in main repository for final review
```

---

## Troubleshooting

### Common Issues

#### Issue 1: Port Already in Use

```bash
# Check what's using the port
lsof -i :9000

# Kill process if needed
kill -9 <PID>

# Or use different port
export BACKEND_PORT=9010
```

#### Issue 2: Database Connection Failed

```bash
# Test connection
psql -h test-db.company.local -U test_user -d synpatictrading_test -c "SELECT 1;"

# Check credentials in .env
cat .env | grep DB_

# Check firewall
telnet test-db.company.local 5432
```

#### Issue 3: Cache Not Found

```bash
# Verify cache location
ls -la data/.cache/

# Check environment variable
echo $CACHE_DIR

# Regenerate cache if missing
python infrastructure/data/create_nautilus_meta_index_optimized.py \
    --catalog-id v10_real_enhanced_clean \
    --output-dir data/.cache \
    --format hdf5
```

#### Issue 4: Merge Conflicts

```bash
# Update your branch with develop
git checkout develop
git pull origin develop
git checkout feature/your-feature
git merge develop

# If conflicts, resolve manually
# Open conflicted files in editor
nano <conflicted-file>

# After resolving
git add <resolved-files>
git commit -m "merge: Resolve conflicts with develop"
git push origin feature/your-feature
```

#### Issue 5: Test Failures After Merge

```bash
# Check what changed in develop
git log develop --oneline --since="2 days ago"

# Run tests to identify failures
pytest tests/ -v

# Check if dependencies changed
git diff develop..HEAD requirements.txt

# Update dependencies if needed
pip install -r requirements.txt

# Fix tests
# ... make changes ...
git commit -am "test: Fix tests after merge"
```

---

## Developer Quick Reference

### Daily Workflow

```bash
# Start of day
cd ~/nikhilwm-opt-v2
source venv/bin/activate
git checkout develop
git pull origin develop
git checkout feature/your-feature

# Work on feature
# ... make changes ...
pytest tests/ -v  # Test frequently

# End of day
git add .
git commit -m "feat: Progress on feature X"
git push origin feature/your-feature
```

### Common Commands

```bash
# Run backtest
python run_backtest.py

# Run tests
pytest tests/ -v

# Format code
black .

# Lint code
flake8 .

# Check logs
tail -f backtest_output.log

# Deploy to test
./scripts/deploy_to_test.sh dev1 feature/your-feature

# Check test deployment
curl http://test-server.company.local:9000/health
```

### Port Reference

| Environment | Backend | Frontend |
|-------------|---------|----------|
| Local Dev 1 | 8000 | 3000 |
| Local Dev 2 | 8001 | 3001 |
| Local Dev 3 | 8002 | 3002 |
| Test Dev 1 | 9000 | 4000 |
| Test Dev 2 | 9001 | 4001 |
| Test Dev 3 | 9002 | 4002 |
| Integration | 9100 | 4100 |
| Staging | 9200 | 4200 |

### Team Contacts

| Role | Name | Contact | Responsibilities |
|------|------|---------|------------------|
| Tech Lead | [Name] | [Email] | Code review, architecture |
| Dev 1 | [Name] | [Email] | Entry manager features |
| Dev 2 | [Name] | [Email] | Exit manager features |
| Dev 3 | [Name] | [Email] | Risk manager features |
| QA | [Name] | [Email] | Testing, quality assurance |
| DevOps | [Name] | [Email] | Deployment, infrastructure |

---

## Appendix

### A. Systemd Service Template

`/etc/systemd/system/nikhilwm-dev1.service`:

```ini
[Unit]
Description=NikhilWM-OPT V2 - Developer 1 Test Environment
After=network.target postgresql.service

[Service]
Type=simple
User=nikhilwm
WorkingDirectory=/opt/nikhilwm/deployments/dev1
EnvironmentFile=/opt/nikhilwm/deployments/dev1/config/test.dev1.env
ExecStart=/opt/nikhilwm/deployments/dev1/venv/bin/python run_backtest.py
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/nikhilwm/dev1.log
StandardError=append:/var/log/nikhilwm/dev1.error.log

[Install]
WantedBy=multi-user.target
```

### B. CI/CD Pipeline Example

`.github/workflows/test.yml`:

```yaml
name: Test Suite

on:
  pull_request:
    branches: [develop, main]
  push:
    branches: [develop]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: synpatictrading_test
          POSTGRES_USER: test_user
          POSTGRES_PASSWORD: test_pass
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
    - uses: actions/checkout@v3

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install pytest pytest-cov black flake8

    - name: Lint with flake8
      run: flake8 .

    - name: Format check with black
      run: black . --check

    - name: Run tests
      env:
        DB_HOST: localhost
        DB_PORT: 5432
        DB_NAME: synpatictrading_test
        DB_USER: test_user
        DB_PASSWORD: test_pass
      run: |
        pytest tests/ -v --cov=src --cov-report=xml

    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml
```

### C. Performance Benchmarks

Expected performance metrics:

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Data load time (3 months) | < 5s | ~2s | ✅ |
| Backtest time (3 months) | < 60s | ~45s | ✅ |
| Memory peak | < 2GB | ~1.5GB | ✅ |
| CPU avg during backtest | < 80% | ~60% | ✅ |
| Test suite execution | < 30s | ~25s | ✅ |

---

**Document Version:** 1.0
**Last Updated:** 2025-10-06
**Maintained By:** Synapse Trading Development Team
