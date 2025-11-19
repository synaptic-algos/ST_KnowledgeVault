# Team Onboarding Quick Start

## 🚀 New Developer Setup (15 minutes)

### Step 1: Clone & Setup (5 min)

```bash
# Clone repository
git clone <repository-url> nikhilwm-opt-v2
cd nikhilwm-opt-v2

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Step 2: Configure Environment (5 min)

```bash
# Copy template
cp .env.example .env

# Edit with your settings
nano .env
```

**Critical settings to update:**

```bash
DEVELOPER_NAME=your_name          # Your identifier

# Your assigned ports (ask team lead)
BACKEND_PORT=8001                 # Unique per developer
FRONTEND_PORT=3001                # Unique per developer

# Shared database (provided by team)
DB_HOST=dev-postgres.company.local
DB_PORT=5432
DB_NAME=synpatictrading_dev
DB_USER=dev_user
DB_PASSWORD=<ask-team-lead>
```

### Step 3: Setup Cache Data (5 min)

**Option A: Download (Recommended)**
```bash
mkdir -p data/.cache
scp dev-server:/shared/cache/nautilus_v10_* data/.cache/
```

**Option B: Generate (30 min)**
```bash
python infrastructure/data/create_nautilus_meta_index_optimized.py \
    --catalog-id v10_real_enhanced_clean \
    --output-dir data/.cache
```

### Step 4: Verify Setup

```bash
# Test configuration
python -c "from v2_config import Config; print('✅ Config OK')"

# Run quick backtest
python run_backtest.py
```

---

## 📋 Your Assigned Resources

Contact your team lead to get:

- [ ] **Git repository access** (GitHub/GitLab credentials)
- [ ] **Database credentials** (PostgreSQL access)
- [ ] **Port assignments** (Backend/Frontend ports)
- [ ] **Test server access** (SSH key and hostname)
- [ ] **Cache files location** (Download link or path)
- [ ] **Team communication** (Slack/Teams channel invite)

---

## 🌳 Git Workflow (Daily)

### Starting a New Feature

```bash
# 1. Update develop
git checkout develop
git pull origin develop

# 2. Create feature branch
git checkout -b feature/FEAT-XXX-description

# 3. Work and commit regularly
# ... make changes ...
git add .
git commit -m "feat: Add feature X"

# 4. Push to remote
git push origin feature/FEAT-XXX-description
```

### Creating a Pull Request

```bash
# 1. Ensure tests pass
pytest tests/ -v

# 2. Format code
black .

# 3. Push latest
git push origin feature/FEAT-XXX-description

# 4. Create PR on GitHub/GitLab
# Base: develop
# Compare: feature/FEAT-XXX-description
```

---

## 🎯 Port Assignments

### Local Development (Your Machine)

| Developer | Backend | Frontend |
|-----------|---------|----------|
| Dev 1     | 8000    | 3000     |
| Dev 2     | 8001    | 3001     |
| Dev 3     | 8002    | 3002     |
| **You**   | **????**| **????** |

**Ask team lead for your ports!**

### Test Server

| Developer | Backend | Frontend |
|-----------|---------|----------|
| Dev 1     | 9000    | 4000     |
| Dev 2     | 9001    | 4001     |
| Dev 3     | 9002    | 4002     |
| **You**   | **????**| **????** |

---

## 🧪 Common Commands

```bash
# Activate environment
source venv/bin/activate

# Run backtest
python run_backtest.py

# Run tests
pytest tests/ -v

# Run specific test
pytest tests/test_exit_manager.py -v

# Format code
black .

# Check code quality
flake8 .

# View results
ls -la backtest_results/
```

---

## 📚 Documentation

### Essential Reading (Priority Order)

1. ✅ **[TEAM_ONBOARDING.md](./TEAM_ONBOARDING.md)** - This file (you're here!)
2. 📖 **[MULTI_DEVELOPER_WORKFLOW.md](./MULTI_DEVELOPER_WORKFLOW.md)** - Complete workflow guide
3. 📖 **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Quick commands reference
4. 📖 **[SUBPROJECT_SPINOFF_GUIDE.md](./SUBPROJECT_SPINOFF_GUIDE.md)** - Full technical guide

### When You Need Help

- **Git issues**: Check MULTI_DEVELOPER_WORKFLOW.md § Git Workflow
- **Testing issues**: Check MULTI_DEVELOPER_WORKFLOW.md § Testing
- **Deployment issues**: Check MULTI_DEVELOPER_WORKFLOW.md § Deployment
- **Configuration issues**: Check CRITICAL_PATHS_ADDENDUM.md

---

## 👥 Team Contacts

| Role | Name | Contact | Ask About |
|------|------|---------|-----------|
| **Team Lead** | [Name] | [Email/Slack] | Architecture, port assignments, approvals |
| **DevOps** | [Name] | [Email/Slack] | Test server access, deployment issues |
| **QA** | [Name] | [Email/Slack] | Testing requirements, bug reports |
| **Developer 1** | [Name] | [Email/Slack] | Entry manager questions |
| **Developer 2** | [Name] | [Email/Slack] | Exit manager questions |
| **Developer 3** | [Name] | [Email/Slack] | Risk manager questions |

---

## ⚡ Quick Troubleshooting

### Issue: "Port already in use"

```bash
# Find what's using it
lsof -i :8001

# Kill it
kill -9 <PID>

# Or use different port in .env
```

### Issue: "Database connection failed"

```bash
# Test connection
psql -h dev-postgres.company.local -U dev_user -d synpatictrading_dev

# If fails, check:
# 1. Credentials in .env
# 2. VPN connection (if required)
# 3. Ask DevOps team
```

### Issue: "Cache not found"

```bash
# Download cache files
scp dev-server:/shared/cache/nautilus_v10_* data/.cache/

# Or ask team lead for download link
```

### Issue: "Tests failing"

```bash
# Update dependencies
pip install -r requirements.txt

# Update from develop
git checkout develop
git pull origin develop
git checkout your-branch
git merge develop

# Run tests again
pytest tests/ -v
```

---

## ✅ Onboarding Checklist

### Day 1
- [ ] Repository cloned
- [ ] Virtual environment created
- [ ] Dependencies installed
- [ ] .env configured with assigned ports
- [ ] Database access verified
- [ ] Cache data downloaded
- [ ] First backtest run successfully
- [ ] Test server SSH access verified
- [ ] Team communication channels joined
- [ ] Met with team lead

### Week 1
- [ ] Read MULTI_DEVELOPER_WORKFLOW.md
- [ ] Created first feature branch
- [ ] Made first commit
- [ ] Ran tests successfully
- [ ] Deployed to test server
- [ ] Created first pull request
- [ ] Participated in code review
- [ ] Understand git workflow

### Month 1
- [ ] Merged first feature to develop
- [ ] Contributed to integration testing
- [ ] Understand architecture
- [ ] Can debug issues independently
- [ ] Familiar with all testing procedures
- [ ] Can help onboard new developers

---

## 🎓 Learning Resources

### Project Architecture

```
nikhilwm-opt-v2/
├── src/                    # Core strategy
│   ├── strategy/          # Entry/Exit/Position/Risk managers
│   ├── models/            # Data models
│   └── backtest/          # Backtest engine
├── domain/                # Domain models & enums
├── infrastructure/        # Data, execution, risk infrastructure
├── application/           # Application interfaces
└── tests/                 # Test suite
```

### Key Concepts

1. **Entry Manager**: Handles trade entries, timing, DTE requirements
2. **Exit Manager**: Handles exits (profit target, stop loss, VIX exits)
3. **Position Manager**: Tracks open positions and spreads
4. **Risk Manager**: Validates trades against risk limits
5. **Data Adapter**: Loads market data (200x faster with meta-indexing)

### Example: Adding a New Exit Condition

1. Update `src/strategy/components/exit_manager.py`
2. Add exit reason to `domain/enums/strategy_enums.py`
3. Add tests to `tests/test_exit_manager.py`
4. Update `v2_config.py` if new parameter needed
5. Update `strategy_config.json` with defaults
6. Create PR with description and test results

---

## 🚦 Next Steps

1. **Complete onboarding checklist** (Day 1 items)
2. **Read MULTI_DEVELOPER_WORKFLOW.md** (full guide)
3. **Pick first task** (ask team lead for good starter task)
4. **Create feature branch** and start coding
5. **Ask questions** (team is here to help!)

---

## 💡 Pro Tips

1. **Commit often**: Small, focused commits are better than large ones
2. **Test before pushing**: Run `pytest tests/ -v` before every push
3. **Format your code**: Run `black .` before committing
4. **Update from develop**: Merge develop into your branch regularly to avoid conflicts
5. **Clear commit messages**: Use conventional commits (feat, fix, docs, test, etc.)
6. **Document complex logic**: Add comments for tricky code
7. **Ask for help**: Better to ask early than struggle for hours
8. **Review others' PRs**: Great way to learn the codebase

---

## 📞 Getting Help

### Slack Channels (Example)
- `#nikhilwm-dev` - General development questions
- `#nikhilwm-alerts` - Build failures, deployment notifications
- `#nikhilwm-releases` - Release announcements

### Office Hours
- **Team Lead**: Mondays 2-3 PM, Thursdays 10-11 AM
- **DevOps**: Daily 9-9:30 AM standup

### Emergency Contacts
- Production issues: [Emergency Phone]
- After hours: [On-call rotation]

---

**Welcome to the team! 🎉**

If you have any questions about this guide or need help getting started, reach out to your team lead or post in the team channel.

Happy coding! 💻

---

**Document Version:** 1.0
**Last Updated:** 2025-10-06
**Maintained By:** Synapse Trading Development Team
