# Backtrader Operations - Administrator Guide

**Product**: SynapticTrading Platform
**Feature**: Backtrader Integration
**Audience**: System Administrators, DevOps Engineers
**Last Updated**: 2025-11-20
**Status**: Active

---

## Overview

This guide provides operational procedures for managing the Backtrader backtesting engine integration within the SynapticTrading platform. Administrators should use this guide for deployment, monitoring, troubleshooting, and maintenance of the Backtrader adapter.

---

## System Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│  ┌────────────────────────────────────────────────────┐     │
│  │         Domain Strategy (Framework-Agnostic)       │     │
│  └────────────────────────────────────────────────────┘     │
│                          ▲                                   │
│                          │ Port Interfaces                   │
└──────────────────────────┼───────────────────────────────────┘
                           │
┌──────────────────────────┼───────────────────────────────────┐
│                   Adapter Layer                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │      BacktraderBacktestAdapter (Orchestrator)      │     │
│  └────────────────────────────────────────────────────┘     │
│           │                │                  │               │
│           ▼                ▼                  ▼               │
│  ┌──────────────┐ ┌─────────────┐ ┌──────────────────┐     │
│  │StrategyWrapper│ │ Port Adapters│ │ Data Feed Creator│    │
│  └──────────────┘ └─────────────┘ └──────────────────┘     │
└──────────────────────────┼───────────────────────────────────┘
                           │
┌──────────────────────────┼───────────────────────────────────┐
│                 Backtrader Framework                         │
│  ┌────────────────────────────────────────────────────┐     │
│  │               bt.Cerebro (Engine)                   │     │
│  └────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### File Locations

**Production Code**:
- `/src/adapters/frameworks/backtrader/` - Main adapter code
  - `backtrader_adapter.py` - Main orchestrator (382 lines)
  - `core/strategy_wrapper.py` - Strategy bridge (323 lines)
  - `core/port_adapters.py` - Port implementations (440 lines)

**Documentation**:
- `/documentation/guides/BACKTRADER-INTEGRATION-USER-GUIDE.md` - User guide
- `/documentation/guides/BACKTRADER-ADMIN-GUIDE.md` - Admin guide (detailed)
- `/docs/BACKTRADER_ADAPTER_DESIGN.md` - Architecture design
- `/docs/BACKTRADER_RESEARCH.md` - Research notes

**Tests**:
- `/tests/frameworks/backtrader/unit/` - Unit tests
- `/tests/frameworks/backtrader/integration/` - Integration tests

---

## Installation and Deployment

### Prerequisites

**System Requirements**:
- Python 3.10 or higher
- Virtual environment configured
- Git repository access
- Write access to `/src/adapters/frameworks/backtrader/`

**Dependencies**:
```bash
backtrader>=1.9.78.123
pandas>=1.5.0
numpy>=1.24.0
```

### Installation Steps

#### 1. Update Repository

```bash
cd /path/to/SynapticTrading
git pull origin main
```

#### 2. Install Dependencies

```bash
source venv/bin/activate  # or: source .venv/bin/activate
pip install backtrader pandas numpy
```

#### 3. Verify Installation

```bash
python3 -c "import backtrader as bt; print(f'Backtrader: {bt.__version__}')"
```

Expected output:
```
Backtrader: 1.9.78.123
```

#### 4. Run Integration Tests

```bash
PYTHONPATH=src pytest tests/frameworks/backtrader/integration/ -v
```

Expected: All tests passing

#### 5. Verify Module Imports

```bash
python3 -c "from adapters.frameworks.backtrader import BacktraderBacktestAdapter; print('Import successful')"
```

### Deployment Checklist

- [ ] Git repository up to date
- [ ] Dependencies installed
- [ ] Integration tests passing
- [ ] Module imports working
- [ ] Documentation accessible
- [ ] Logging configured
- [ ] Monitoring enabled

---

## Configuration Management

### Environment Variables

Store configuration in environment or `.env` file:

```bash
# .env
BACKTEST_INITIAL_CAPITAL=100000
BACKTEST_COMMISSION_BPS=10
BACKTEST_SLIPPAGE_BPS=5
BACKTEST_DATA_PATH=/data/parquet_catalog/
BACKTEST_LOG_LEVEL=INFO
```

Load in application:

```python
import os
from dotenv import load_dotenv

load_dotenv()

config = BacktestConfig(
    initial_capital=float(os.getenv('BACKTEST_INITIAL_CAPITAL', 100000)),
    commission_bps=float(os.getenv('BACKTEST_COMMISSION_BPS', 10)),
    slippage_bps=float(os.getenv('BACKTEST_SLIPPAGE_BPS', 5))
)
```

### Configuration Files

**Development** (`config/development.yaml`):
```yaml
backtest:
  default_capital: 100000
  default_commission_bps: 10
  default_slippage_bps: 5
  data_path: "data/parquet_catalog"
  log_level: "DEBUG"
```

**Production** (`config/production.yaml`):
```yaml
backtest:
  default_capital: 1000000
  default_commission_bps: 5
  default_slippage_bps: 3
  data_path: "/prod/data/parquet_catalog"
  log_level: "INFO"
```

---

## Monitoring and Logging

### Enable Logging

Add logging configuration to adapter:

```python
# In src/adapters/frameworks/backtrader/backtrader_adapter.py

import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/synaptic/backtrader.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

class BacktraderBacktestAdapter:
    def run(self, strategy):
        logger.info(f"Starting backtest for {self.instrument_id}")
        logger.info(f"Period: {self.config.start_date} to {self.config.end_date}")

        # ... implementation
```

### Log Locations

**Development**:
- Console output (stdout)
- `logs/backtrader_dev.log`

**Production**:
- `/var/log/synaptic/backtrader.log`
- Rotated daily, kept for 30 days

### Key Metrics to Monitor

**Performance Metrics**:
- Backtest execution time
- Memory usage
- CPU utilization
- Data loading time

**Business Metrics**:
- Number of backtests per day
- Average backtest duration
- Success/failure rate
- Cross-engine divergence rates

### Monitoring Dashboard

Create Grafana dashboard tracking:

1. **Execution Metrics**:
   - Backtest count (per hour)
   - Average duration (seconds)
   - 95th percentile duration

2. **Resource Usage**:
   - Memory consumption
   - CPU usage
   - Disk I/O

3. **Error Rates**:
   - Failed backtests
   - Import errors
   - Data loading failures

---

## Troubleshooting

### Common Production Issues

#### Issue 1: Memory Leak

**Symptoms**:
- Memory usage grows over time
- Python process consumes increasing RAM
- System becomes unresponsive

**Diagnosis**:
```bash
# Monitor memory usage
ps aux | grep python | grep backtest

# Use memory profiler
pip install memory_profiler
python -m memory_profiler backtest_script.py
```

**Solution**:
```python
# Explicitly clean up after backtest
cerebro = bt.Cerebro()
# ... run backtest
results = cerebro.run()

# Clean up
del cerebro
del results
import gc
gc.collect()
```

#### Issue 2: Slow Data Loading

**Symptoms**:
- Backtests take > 30 seconds to start
- High disk I/O during data loading

**Diagnosis**:
```bash
# Profile data loading
import time
start = time.time()
bars = data_provider.get_bars(...)
print(f"Data loading: {time.time() - start:.2f}s")
```

**Solutions**:
1. Implement data caching
2. Use faster storage (SSD vs HDD)
3. Compress historical data
4. Pre-load frequently used datasets

#### Issue 3: Import Errors in Production

**Symptoms**:
```
ModuleNotFoundError: No module named 'adapters.frameworks.backtrader'
```

**Solutions**:
```bash
# Verify PYTHONPATH
echo $PYTHONPATH

# Set PYTHONPATH
export PYTHONPATH=/path/to/SynapticTrading/src:$PYTHONPATH

# Or add to service file
# /etc/systemd/system/backtest.service:
Environment="PYTHONPATH=/opt/synaptic/src"
```

#### Issue 4: High Divergence Between Engines

**Symptoms**:
- Custom vs Backtrader results differ by > 0.01%

**Diagnosis**:
1. Compare trade-by-trade execution
2. Check data alignment (timestamps, bars)
3. Verify commission/slippage settings
4. Review timezone handling

**Investigation**:
```python
# Log all fills in both engines
def on_fill(self, fill):
    logger.info(f"Fill: {fill.timestamp} {fill.side} {fill.quantity} @ {fill.fill_price}")
```

---

## Maintenance Procedures

### Weekly Tasks

**Every Monday**:
1. Review logs for errors
2. Check backtest success rate
3. Monitor resource usage trends
4. Verify data feeds up to date

```bash
# Weekly maintenance script
./scripts/maintenance/weekly_backtest_check.sh
```

### Monthly Tasks

**First of Month**:
1. Run cross-engine validation tests
2. Update Backtrader dependency
3. Review performance benchmarks
4. Archive old logs

```bash
# Monthly maintenance
./scripts/maintenance/monthly_backtest_maintenance.sh
```

### Quarterly Tasks

**Every Quarter**:
1. Full code review
2. Performance optimization review
3. Update documentation
4. Security audit
5. Dependency updates

### Upgrading Backtrader

```bash
# Check current version
pip show backtrader

# Backup current installation
pip freeze > requirements_backup.txt

# Upgrade
pip install --upgrade backtrader

# Run regression tests
PYTHONPATH=src pytest tests/frameworks/backtrader/ -v

# Run cross-engine validation
python scripts/validate_backtrader_engine.py

# If tests fail, rollback
pip install backtrader==1.9.78.123  # previous version
```

---

## Performance Tuning

### Optimization Strategies

#### 1. Data Loading Optimization

```python
# Bad: Load entire dataset
all_data = data_provider.get_bars(instrument, start, end)

# Good: Load only needed range
data = data_provider.get_bars(
    instrument,
    config.start_date,
    config.end_date
)
```

#### 2. Analyzer Optimization

```python
# Bad: Add all analyzers
cerebro.addanalyzer(bt.analyzers.SharpeRatio)
cerebro.addanalyzer(bt.analyzers.DrawDown)
cerebro.addanalyzer(bt.analyzers.TradeAnalyzer)
cerebro.addanalyzer(bt.analyzers.Returns)
cerebro.addanalyzer(bt.analyzers.TimeReturn)
cerebro.addanalyzer(bt.analyzers.AnnualReturn)
# ... many more

# Good: Add only needed analyzers
cerebro.addanalyzer(bt.analyzers.SharpeRatio, _name='sharpe')
cerebro.addanalyzer(bt.analyzers.DrawDown, _name='drawdown')
```

#### 3. Memory Optimization

```python
# Reduce historical tick cache
class BacktraderMarketDataPort:
    def __init__(self, wrapper, instrument_id):
        self._max_history = 500  # Reduce from 1000
```

#### 4. Parallel Processing

```python
from multiprocessing import Pool

def run_backtest(params):
    instrument, config, data_provider = params
    adapter = BacktraderBacktestAdapter(config, data_provider, instrument)
    return adapter.run(strategy)

# Parallel execution
with Pool(4) as pool:
    results = pool.map(run_backtest, params_list)
```

### Performance Benchmarks

**Target Performance** (M1 MacBook Pro):

| Data Size          | Bars   | Time (sec) | Memory (MB) |
|--------------------|--------|------------|-------------|
| 1 month daily      | 20     | < 1        | < 10        |
| 3 months daily     | 60     | < 2        | < 15        |
| 1 year daily       | 252    | < 5        | < 25        |
| 5 years daily      | 1,260  | < 15       | < 75        |

**Alert if**:
- 1 year backtest > 10 seconds
- Memory usage > 100 MB for daily data
- CPU usage > 80% for extended periods

---

## Security Considerations

### Access Control

**Production**:
- Limit write access to `/src/adapters/frameworks/backtrader/`
- Read-only access for most users
- Audit log for code changes

**Data Access**:
- Restrict access to historical data
- Encrypt sensitive data at rest
- Use secure data transfer protocols

### Input Validation

**Always validate**:
- Date ranges (start < end)
- Capital amounts (> 0)
- Commission/slippage (0-10000 BPS)
- Instrument IDs (alphanumeric only)

```python
def validate_config(config):
    if config.start_date >= config.end_date:
        raise ValueError("Start date must be before end date")
    if config.initial_capital <= 0:
        raise ValueError("Initial capital must be positive")
    if not 0 <= config.commission_bps <= 10000:
        raise ValueError("Commission must be 0-10000 BPS")
```

---

## Disaster Recovery

### Backup Strategy

**Code**:
- Git repository (remote backup)
- Daily snapshots of `/src/` directory
- Tagged releases for rollback

**Data**:
- Historical data backed up daily
- Backup retention: 90 days
- Offsite backup for critical data

**Configuration**:
- Configuration files version controlled
- Environment variables documented
- Deployment scripts backed up

### Recovery Procedures

#### Service Outage

```bash
# 1. Check service status
systemctl status backtest

# 2. Review logs
tail -100 /var/log/synaptic/backtrader.log

# 3. Restart service
systemctl restart backtest

# 4. Verify service health
curl http://localhost:8000/health
```

#### Corrupted Installation

```bash
# 1. Stop service
systemctl stop backtest

# 2. Backup current installation
cp -r /opt/synaptic /opt/synaptic.backup

# 3. Restore from git
cd /opt/synaptic
git fetch origin
git reset --hard origin/main

# 4. Reinstall dependencies
pip install -r requirements.txt

# 5. Run tests
pytest tests/frameworks/backtrader/ -v

# 6. Restart service
systemctl start backtest
```

---

## Contact and Escalation

### Support Contacts

**Level 1: User Support**
- Email: support@synaptictrading.com
- Response time: 24 hours

**Level 2: Technical Support**
- Email: tech-support@synaptictrading.com
- Response time: 4 hours

**Level 3: Engineering Escalation**
- Email: engineering@synaptictrading.com
- Response time: 1 hour (critical issues)

### Escalation Criteria

**Level 1 → Level 2**:
- User cannot resolve with documentation
- Service degradation affecting multiple users

**Level 2 → Level 3**:
- System-wide outage
- Data integrity issues
- Security incidents
- Critical bug affecting results accuracy

---

## Appendix

### Useful Commands

```bash
# Check Backtrader installation
python3 -c "import backtrader; print(backtrader.__version__)"

# Run integration tests
PYTHONPATH=src pytest tests/frameworks/backtrader/integration/ -v

# Profile memory usage
python -m memory_profiler backtest_script.py

# Monitor running backtests
watch -n 1 'ps aux | grep backtest'

# Check disk usage
du -sh /data/parquet_catalog/*

# Rotate logs
logrotate /etc/logrotate.d/backtrader
```

### Configuration Examples

**Systemd Service** (`/etc/systemd/system/backtest.service`):
```ini
[Unit]
Description=SynapticTrading Backtest Service
After=network.target

[Service]
Type=simple
User=synaptic
WorkingDirectory=/opt/synaptic
Environment="PYTHONPATH=/opt/synaptic/src"
ExecStart=/opt/synaptic/venv/bin/python -m backtest.server
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

**Nginx Reverse Proxy** (`/etc/nginx/sites-available/backtest`):
```nginx
server {
    listen 80;
    server_name backtest.synaptictrading.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-20 | 1.0 | Initial release - Backtrader integration complete |

---

**Last Updated**: 2025-11-20
**Version**: 1.0
**Status**: Active
**Maintained By**: SynapticTrading Engineering Team
