# Critical Paths & Data Architecture - Addendum

## Overview

This document addresses critical path configurations and data storage architecture that are essential for making the nikhilwm-opt-v2 project truly self-contained and portable.

---

## 1. Results Path Configuration

### ❌ Problem: Absolute Path to Parent Repository

**Original Configuration (v2_config.py line 90):**
```python
results_base_path: str = "/Users/nitindhawan/Downloads/CodeRepository/synpatictrading/backtest_results"
```

**Issues:**
- Points outside the v2 project directory
- Breaks self-contained principle
- Not portable across environments
- Mixes results with other projects

### ✅ Solution: Relative Path Within Project

**Fixed Configuration (v2_config.py line 90):**
```python
# Results Path - Relative to project root for portability
results_base_path: str = str(Path(__file__).parent / "backtest_results")
```

**Benefits:**
- ✅ Self-contained within v2 project
- ✅ Portable across environments
- ✅ Works in standalone deployment
- ✅ Clear separation from other projects

### Directory Structure

```
nikhilwm-opt-v2/
├── backtest_results/          # ✅ Results now stored here
│   ├── 20251006/
│   │   ├── 172309_nikhilwm_opt_v2/
│   │   │   ├── trade_log_nikhilwm_opt.csv
│   │   │   ├── performance_metrics.json
│   │   │   └── equity_curve.csv
│   │   └── ...
│   └── .gitkeep
└── ...
```

### Update .gitignore

Add to `.gitignore`:
```gitignore
# Backtest results
backtest_results/*
!backtest_results/.gitkeep
```

### Verification

Test the configuration:
```bash
cd /Users/nitindhawan/Downloads/CodeRepository/synpatictrading/src/pilot/nikhilwm-opt-v2

# Test results path
python -c "
from v2_config import Config
config = Config()
print(f'Results path: {config.results_base_path}')
print(f'Test run dir: {config.get_results_dir()}')
"

# Should output:
# Results path: /Users/nitindhawan/.../nikhilwm-opt-v2/backtest_results
# Test run dir: /Users/nitindhawan/.../nikhilwm-opt-v2/backtest_results/20251006/183045_nikhilwm_opt_v2
```

---

## 2. Meta-Indexed Parquet Data Architecture

### Data Storage Overview

The nikhilwm-opt-v2 project uses a **two-tier data storage system**:

1. **PostgreSQL**: Source of truth (optional in standalone)
2. **Local Cache**: Pre-indexed pickle/HDF5 files for fast access

### Storage Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Data Storage Layers                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  PostgreSQL Database (Optional)                              │
│  ├── Raw parquet data                                        │
│  ├── Catalog metadata                                        │
│  └── Index tables                                            │
│         │                                                     │
│         │ Export/Generate (one-time)                         │
│         ▼                                                     │
│  Local Cache (.cache/)                   ◄─── Used at runtime│
│  ├── nautilus_{catalog_id}_meta.pkl     (200x faster)       │
│  ├── nautilus_{catalog_id}_indexed.pkl  or                  │
│  └── nautilus_{catalog_id}_indexed.h5                       │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Cache Directory Location

**Current Location (HARDCODED - NEEDS FIXING):**
```python
# In src/backtest/nautilus_adapter.py line 37
self.cache_dir = Path("/Users/nitindhawan/Downloads/CodeRepository/synpatictrading/.cache")
```

**❌ Issues:**
- Absolute path to parent repository
- Not portable
- Breaks self-contained principle

**✅ Recommended Fix:**
```python
# Option 1: Relative to project root (RECOMMENDED)
self.cache_dir = Path(__file__).parent.parent.parent / "data" / ".cache"

# Option 2: Configurable via environment variable
self.cache_dir = Path(os.getenv('CACHE_DIR', str(Path(__file__).parent.parent.parent / "data" / ".cache")))

# Option 3: From v2_config
from v2_config import Config
config = Config()
self.cache_dir = Path(config.cache_path).parent
```

### File Structure

```
nikhilwm-opt-v2/
├── data/
│   └── .cache/                          # Local cache directory
│       ├── nautilus_v10_real_enhanced_clean_meta.pkl      # Meta structures
│       ├── nautilus_v10_real_enhanced_clean_indexed.pkl   # Indexed data (pickle)
│       └── nautilus_v10_real_enhanced_clean_indexed.h5    # Indexed data (HDF5)
└── ...
```

### Cache File Contents

**1. Meta File (`*_meta.pkl`):**
```python
{
    'storage_format': 'hdf5',  # or 'pickle'
    'catalog_id': 'v10_real_enhanced_clean',
    'total_rows': 15000000,
    'expiries': [...],         # List of all expiry dates
    'monthly_expiries': [...], # Monthly expiry dates
    'weekly_expiries': [...],  # Weekly expiry dates
    'strikes_by_expiry': {     # Pre-computed strike lists
        '2025-01-30': [19000, 19100, ...],
        '2025-02-06': [19200, 19300, ...],
        ...
    },
    'date_range': ('2024-01-01', '2025-10-03'),
    'instruments': ['NIFTY'],
    'columns': ['timestamp', 'open', 'high', 'low', 'close', 'volume', 'delta', 'gamma', 'theta', 'vega']
}
```

**2. Indexed Data File (`*_indexed.pkl` or `*_indexed.h5`):**
- Multi-level pandas index: (strike, expiry_date, option_type, data_date, timestamp)
- OHLCV data + Greeks (delta, gamma, theta, vega)
- ~5-10GB for 18 months of data
- Pickle: Faster load, more memory
- HDF5: Slower load, less memory, supports partial loading

### Data Generation

**From PostgreSQL (one-time setup):**

```bash
# Generate cache from PostgreSQL
cd /Users/nitindhawan/Downloads/CodeRepository/synpatictrading/src/pilot/nikhilwm-opt-v2

# Option 1: Generate pickle cache
python infrastructure/data/create_nautilus_meta_index.py \
    --catalog-id v10_real_enhanced_clean \
    --output-dir data/.cache

# Option 2: Generate HDF5 cache (recommended for large datasets)
python infrastructure/data/create_nautilus_meta_index_optimized.py \
    --catalog-id v10_real_enhanced_clean \
    --output-dir data/.cache \
    --format hdf5
```

**Verification:**
```bash
# Check cache files
ls -lh data/.cache/nautilus_v10_real_enhanced_clean*

# Expected output:
# nautilus_v10_real_enhanced_clean_meta.pkl      (5-10MB)
# nautilus_v10_real_enhanced_clean_indexed.pkl   (5-10GB) or
# nautilus_v10_real_enhanced_clean_indexed.h5    (3-7GB)
```

### Standalone Deployment Considerations

For standalone deployment, you have **two options**:

#### Option A: Ship with Pre-Generated Cache (Recommended)

```bash
# In standalone repository
# 1. Copy cache files
mkdir -p data/.cache
cp /path/to/parent/.cache/nautilus_v10_real_enhanced_clean* data/.cache/

# 2. Update .gitignore to exclude large cache files
echo "data/.cache/*.pkl" >> .gitignore
echo "data/.cache/*.h5" >> .gitignore
echo "!data/.cache/*_meta.pkl" >> .gitignore  # Include meta (small)

# 3. Document cache in README
cat >> README.md << 'EOF'

## Data Setup

### Pre-generated Cache
This project uses pre-generated cache files for fast data access.

**Required files:**
- `data/.cache/nautilus_v10_real_enhanced_clean_meta.pkl` (included)
- `data/.cache/nautilus_v10_real_enhanced_clean_indexed.h5` (10GB, download separately)

**Download cache:**
```bash
# Contact dev team for cache file download link
wget <cache-url> -O data/.cache/nautilus_v10_real_enhanced_clean_indexed.h5
```
EOF
```

#### Option B: Generate Cache from PostgreSQL (Full setup)

```bash
# In standalone repository
# 1. Setup PostgreSQL connection
cp .env.example .env
# Edit .env with database credentials

# 2. Generate cache
python infrastructure/data/create_nautilus_meta_index_optimized.py \
    --catalog-id v10_real_enhanced_clean \
    --output-dir data/.cache \
    --format hdf5

# Takes: ~10-30 minutes depending on dataset size
```

---

## 3. Required Fixes for Standalone

### Fix 1: Update nautilus_adapter.py Cache Path

**File:** `src/backtest/nautilus_adapter.py`

**Current (line 37):**
```python
self.cache_dir = Path("/Users/nitindhawan/Downloads/CodeRepository/synpatictrading/.cache")
```

**Fix:**
```python
# Use environment variable with fallback to project-relative path
import os
self.cache_dir = Path(os.getenv(
    'CACHE_DIR',
    str(Path(__file__).parent.parent.parent / "data" / ".cache")
))
```

### Fix 2: Update v2_config.py Cache Path

**File:** `v2_config.py`

**Current (line 76):**
```python
cache_path: str = str(Path(__file__).parent / "data" / ".cache" / "nifty_options_indexed.pkl")
```

**Good!** ✅ Already using relative path, but update for consistency:

```python
cache_path: str = str(Path(__file__).parent / "data" / ".cache")
```

### Fix 3: Add Environment Variable Support

**Update `.env.example`:**
```bash
# Data Cache Configuration
CACHE_DIR=./data/.cache
CACHE_FORMAT=hdf5  # or 'pickle'
```

**Update `v2_config.py`:**
```python
from pathlib import Path
import os

@dataclass
class Config:
    # ... existing fields ...

    # Cache Settings
    cache_dir: str = os.getenv('CACHE_DIR', str(Path(__file__).parent / "data" / ".cache"))
    cache_format: str = os.getenv('CACHE_FORMAT', 'hdf5')
```

---

## 4. Verification Checklist

After applying all fixes:

### ✅ Configuration Verification
```bash
# Test all path configurations
python -c "
from v2_config import Config
from pathlib import Path

config = Config()
print('Results path:', config.results_base_path)
print('Cache path:', config.cache_dir)
print('All paths relative?',
      Path(config.results_base_path).is_absolute() and
      str(Path.home()) not in config.results_base_path)
"
```

### ✅ Cache Access Verification
```bash
# Test cache loading
python -c "
from src.backtest.nautilus_adapter import NautilusMetaIndexedDataAdapter

adapter = NautilusMetaIndexedDataAdapter(
    catalog_id='v10_real_enhanced_clean',
    debug_mode=True
)
print('Cache dir:', adapter.cache_dir)
print('Meta file:', adapter.meta_file)
print('Meta exists:', adapter.meta_file.exists())
"
```

### ✅ Backtest End-to-End Verification
```bash
# Run a quick backtest
python run_backtest.py

# Verify results location
ls -la backtest_results/$(date +%Y%m%d)/

# Verify no files created in parent repository
ls -la ../../../../../../backtest_results/ 2>/dev/null || echo "✅ No parent results"
```

---

## 5. Migration Script

For existing users who need to migrate to the new structure:

```bash
#!/bin/bash
# migrate_to_standalone.sh

set -e

PROJECT_ROOT="/Users/nitindhawan/Downloads/CodeRepository/synpatictrading/src/pilot/nikhilwm-opt-v2"
PARENT_CACHE="/Users/nitindhawan/Downloads/CodeRepository/synpatictrading/.cache"
PARENT_RESULTS="/Users/nitindhawan/Downloads/CodeRepository/synpatictrading/backtest_results"

echo "🔄 Migrating nikhilwm-opt-v2 to standalone structure..."

# 1. Create local cache directory
echo "📁 Creating local cache directory..."
mkdir -p "$PROJECT_ROOT/data/.cache"

# 2. Copy cache files (symlink to avoid duplication)
echo "🔗 Linking cache files..."
ln -sf "$PARENT_CACHE/nautilus_v10_real_enhanced_clean_meta.pkl" \
       "$PROJECT_ROOT/data/.cache/"
ln -sf "$PARENT_CACHE/nautilus_v10_real_enhanced_clean_indexed.h5" \
       "$PROJECT_ROOT/data/.cache/"

# 3. Create local results directory
echo "📁 Creating local results directory..."
mkdir -p "$PROJECT_ROOT/backtest_results"

# 4. Copy recent results (optional)
echo "📋 Copying recent results..."
if [ -d "$PARENT_RESULTS/$(date +%Y%m%d)" ]; then
    cp -r "$PARENT_RESULTS/$(date +%Y%m%d)" "$PROJECT_ROOT/backtest_results/"
fi

# 5. Apply configuration fixes
echo "⚙️  Applying configuration fixes..."
cd "$PROJECT_ROOT"

# Update v2_config.py (already done via Edit tool)
echo "✅ v2_config.py already updated"

# Update nautilus_adapter.py
sed -i.bak 's|Path("/Users/nitindhawan/Downloads/CodeRepository/synpatictrading/.cache")|Path(os.getenv("CACHE_DIR", str(Path(__file__).parent.parent.parent / "data" / ".cache")))|' \
    src/backtest/nautilus_adapter.py

# 6. Create .env
echo "📝 Creating .env..."
cat > .env << 'EOF'
# Data Cache Configuration
CACHE_DIR=./data/.cache
CACHE_FORMAT=hdf5

# Database Configuration
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=synpatictrading
DB_USER=nitindhawan
DB_PASSWORD=

# Results Configuration
RESULTS_BASE_PATH=./backtest_results
EOF

# 7. Update .gitignore
echo "📝 Updating .gitignore..."
cat >> .gitignore << 'EOF'

# Local cache
data/.cache/*.pkl
data/.cache/*.h5
!data/.cache/*_meta.pkl

# Local results
backtest_results/*
!backtest_results/.gitkeep
EOF

# 8. Create .gitkeep files
touch data/.cache/.gitkeep
touch backtest_results/.gitkeep

echo "✅ Migration complete!"
echo ""
echo "Next steps:"
echo "1. Test backtest: python run_backtest.py"
echo "2. Verify results: ls -la backtest_results/"
echo "3. Verify cache: ls -la data/.cache/"
```

Make executable and run:
```bash
chmod +x migrate_to_standalone.sh
./migrate_to_standalone.sh
```

---

## 6. Summary of Critical Paths

### Current State (After Fixes)

| Path Type | Location | Status |
|-----------|----------|--------|
| **Results** | `./backtest_results/` | ✅ Relative |
| **Cache** | `./data/.cache/` | ⚠️ Needs fix |
| **Config** | `./strategy_config.json` | ✅ Relative |
| **Logs** | `./backtest_output.log` | ✅ Relative |
| **Data Sources** | `./src/backtest/data_sources.json` | ✅ Relative |

### Required Actions

1. ✅ **DONE**: Fix `v2_config.py` results path
2. ⚠️ **TODO**: Fix `nautilus_adapter.py` cache path
3. ⚠️ **TODO**: Add environment variable support
4. ⚠️ **TODO**: Update documentation with cache setup
5. ⚠️ **TODO**: Create migration script for existing users

---

## 7. Recommended Project Structure (Final)

```
nikhilwm-opt-v2/
├── data/                        # ✅ All data within project
│   ├── .cache/                  # ✅ Pre-indexed cache files
│   │   ├── .gitkeep
│   │   ├── nautilus_v10_*_meta.pkl    (5-10MB, commit)
│   │   └── nautilus_v10_*_indexed.h5  (5-10GB, .gitignore)
│   └── sql/                     # SQL scripts (optional)
├── backtest_results/            # ✅ Results within project
│   ├── .gitkeep
│   └── 20251006/
│       └── 183045_nikhilwm_opt_v2/
├── src/                         # Source code
├── infrastructure/              # Infrastructure
├── domain/                      # Domain models
├── application/                 # Application layer
├── papertrade/                  # Paper trading
├── tests/                       # Tests
├── run_backtest.py              # Main entry
├── v2_config.py                 # ✅ Config with relative paths
├── strategy_config.json         # Strategy params
├── .env                         # ✅ Environment config
├── .env.example                 # Template
├── .gitignore                   # ✅ Exclude cache/results
└── README.md                    # Documentation
```

**Key Principles:**
- ✅ All paths relative to project root
- ✅ No dependencies on parent repository
- ✅ Portable across environments
- ✅ Self-contained data and results
- ✅ Environment-configurable via `.env`

---

**Document Version:** 1.0
**Last Updated:** 2025-10-06
**Status:** CRITICAL - Apply fixes before standalone deployment
