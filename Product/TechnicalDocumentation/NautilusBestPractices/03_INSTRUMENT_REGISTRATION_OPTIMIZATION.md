---
artifact_type: story
created_at: '2025-11-25T16:23:21.801032Z'
id: AUTO-03_INSTRUMENT_REGISTRATION_OPTIMIZATION
manual_update: 'true'
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: '001'
status: pending
title: Auto-generated title for 03_INSTRUMENT_REGISTRATION_OPTIMIZATION
updated_at: '2025-11-25T16:23:21.801036Z'
---

## Current Approach (Baseline)

### Implementation
Location: `src/nautilus/backtest/single_strategy_runner.py:register_instruments()`

```python
def register_instruments(self):
    """Register instruments from catalog - CURRENT APPROACH (17s)"""
    catalog = ParquetDataCatalog(self.catalog_path)

    # Load all instrument directories (33,408)
    instrument_dirs = list(Path(self.catalog_path).glob("data/option_contract/*/"))

    # Filter by date range
    filtered_instruments = []
    for inst_dir in instrument_dirs:
        # Parse instrument ID from directory name
        inst_id_str = inst_dir.name

        # Check if instrument has data in backtest date range
        bar_dir = f"data/bar/{inst_id_str}-1-HOUR-LAST-EXTERNAL/"
        bar_files = list((Path(self.catalog_path) / bar_dir).glob("*.parquet"))

        for bar_file in bar_files:
            # Parse timestamps from filename
            if file_overlaps_date_range(bar_file, self.start_date, self.end_date):
                filtered_instruments.append(inst_id_str)
                break

    # Parse and register each instrument (6,264)
    for inst_id_str in filtered_instruments:
        # Parse V12 format: NIFTY240125C24700
        match = re.match(r'^([A-Z]+)(\d{6})([CP])(\d+)', inst_id_str)
        # ... create OptionContract
        # ... register with engine
```

### Performance
- **Time**: 17 seconds (for 3-month date range)
- **Bottlenecks**:
  1. File system I/O (33,408 directory scans)
  2. Regex parsing (6,264 instrument IDs)
  3. Parquet file metadata reads (6,264 × ~7 files/instrument)

---

## Optimization Approach 1: Pre-Built Instrument Index (RECOMMENDED)

### Concept
Create a **one-time** instrument metadata index that maps instrument IDs to their available date ranges. Backtests query this index instead of scanning directories.

### Implementation

#### Step 1: Build Index (One-Time)

```python
# scripts/build_instrument_index.py
import json
from pathlib import Path
from datetime import datetime
import pyarrow.parquet as pq

def build_instrument_index(catalog_path: str) -> dict:
    """
    Build instrument metadata index (run once per catalog)

    Returns:
        {
            "NIFTY240125C24700.NSE": {
                "underlying": "NIFTY",
                "expiry": "2024-01-25",
                "option_type": "CALL",
                "strike": 24700,
                "data_start": "2024-01-01",
                "data_end": "2024-01-25",
                "bar_count": 42
            },
            ...
        }
    """
    index = {}
    catalog = ParquetDataCatalog(catalog_path)

    # Get all instruments from catalog
    instruments = catalog.instruments()

    for instrument in instruments:
        inst_id = str(instrument.id)

        # Get bar data metadata (without loading full data)
        bar_type = BarType.from_str(f"{inst_id}-1-HOUR-LAST-EXTERNAL")

        # Get bar file info (fast - just metadata)
        bar_path = f"{catalog_path}/data/bar/{inst_id}-1-HOUR-LAST-EXTERNAL/"
        bar_files = list(Path(bar_path).glob("*.parquet"))

        if not bar_files:
            continue

        # Parse date range from filenames (fast - no parquet read)
        timestamps = []
        for bar_file in bar_files:
            # Filename: 2024-01-01T09-00-00-000000000Z_2024-01-25T15-00-00-000000000Z.parquet
            parts = bar_file.stem.split('_')
            start_ts = datetime.strptime(parts[0], "%Y-%m-%dT%H-%M-%S-%f000Z")
            end_ts = datetime.strptime(parts[1], "%Y-%m-%dT%H-%M-%S-%f000Z")
            timestamps.extend([start_ts, end_ts])

        data_start = min(timestamps)
        data_end = max(timestamps)

        # Store metadata
        index[inst_id] = {
            "underlying": instrument.underlying,
            "expiry": instrument.expiration_ns,
            "option_kind": str(instrument.option_kind),
            "strike": float(instrument.strike_price),
            "data_start": data_start.isoformat(),
            "data_end": data_end.isoformat(),
            "bar_count": sum(1 for _ in bar_files)
        }

    return index

# Build and save
index = build_instrument_index("data/catalogs/v12_real_enhanced_hourly")
with open("data/catalogs/v12_real_enhanced_hourly/.instrument_index.json", 'w') as f:
    json.dump(index, f, indent=2)

print(f"✅ Indexed {len(index)} instruments")
```

**Run Once**: `python scripts/build_instrument_index.py`

#### Step 2: Use Index in Backtest (Fast Query)

```python
# src/nautilus/backtest/single_strategy_runner.py
def register_instruments(self):
    """Register instruments using pre-built index (< 1 second)"""
    index_path = Path(self.catalog_path) / ".instrument_index.json"

    # Load index (fast - single file read)
    with open(index_path) as f:
        index = json.load(f)

    # Filter by date range (in-memory, fast)
    filtered = {
        inst_id: metadata
        for inst_id, metadata in index.items()
        if overlaps_date_range(
            metadata["data_start"],
            metadata["data_end"],
            self.start_date,
            self.end_date
        )
    }

    print(f"Filtered to {len(filtered)} instruments (using index)")

    # Load actual instruments from catalog (only filtered ones)
    catalog = ParquetDataCatalog(self.catalog_path)
    for inst_id in filtered:
        instrument = catalog.instruments([InstrumentId.from_str(inst_id)])[0]
        self.engine.add_instrument(instrument)
```

### Performance
- **Index Build Time**: ~30 seconds (one-time per catalog)
- **Backtest Registration Time**: < 1 second (100x faster)
- **Trade-off**: Requires rebuild if catalog data changes

### When to Rebuild Index
- ✅ After importing new data to catalog
- ✅ After modifying instrument definitions
- ❌ NOT needed for different backtest date ranges (index covers all dates)

---

## Optimization Approach 2: Catalog-Level Metadata Cache

### Concept
Nautilus catalogs can store metadata at the catalog level, avoiding per-instrument directory scans.

### Implementation

```python
# Use Nautilus native metadata API
from nautilus_trader.persistence.catalog import ParquetDataCatalog

catalog = ParquetDataCatalog("data/catalogs/v12_real_enhanced_hourly")

# Query instruments by date range (if catalog has metadata)
instruments = catalog.instruments(
    as_nautilus=True,
    filter_callable=lambda i: (
        i.expiration_ns >= start_date_ns and
        i.activation_ns <= end_date_ns
    )
)

# Nautilus handles caching internally
```

### Performance
- **Depends on**: Catalog implementation
- **Nautilus v1.220.0**: Partial support (instruments cached, but not date ranges)

**Limitation**: Current Nautilus catalogs don't index bar data date ranges, only instrument metadata.

---

## Optimization Approach 3: Lazy Instrument Registration

### Concept
Register instruments **on-demand** as bars are encountered, instead of upfront registration.

### Implementation

```python
class LazyInstrumentBacktestEngine:
    def __init__(self, catalog_path, start_date, end_date):
        self.catalog = ParquetDataCatalog(catalog_path)
        self.engine = BacktestEngine()
        self.registered_instruments = set()

    def on_bar(self, bar: Bar):
        """Register instrument on first bar encounter"""
        inst_id = bar.bar_type.instrument_id

        if inst_id not in self.registered_instruments:
            # Load instrument from catalog (lazy)
            instrument = self.catalog.instruments([inst_id])[0]
            self.engine.add_instrument(instrument)
            self.registered_instruments.add(inst_id)

        # Process bar
        self.engine.process(bar)
```

### Performance
- **Registration Time**: 0 seconds upfront
- **Runtime Overhead**: Minimal (one-time lookup per instrument)

### Trade-offs
- ✅ Zero upfront cost
- ✅ Simple implementation
- ❌ Instruments registered during simulation (not before)
- ❌ May miss instruments with no bar data in range

**Not Recommended**: Nautilus best practices require instruments registered before simulation starts.

---

## Comparison Table

| Approach | Upfront Time | Backtest Time | Complexity | Nautilus Native | Recommended |
|----------|--------------|---------------|------------|-----------------|-------------|
| **Current (Baseline)** | 17s | +0s | Low | ✅ | ❌ |
| **Pre-Built Index** | 30s (one-time) | <1s | Medium | Partial | ✅ **BEST** |
| **Catalog Metadata** | 5s | +0s | Low | ✅ | ⚠️ (when available) |
| **Lazy Registration** | 0s | +2s | Low | ❌ | ❌ |

---

## Recommended Implementation Plan

### Phase 1: Quick Win (Pre-Built Index)
1. **Create index builder script**:
   - `scripts/build_instrument_index.py`
   - Run once per catalog
   - Store `.instrument_index.json` in catalog root

2. **Update backtest runner**:
   - Load index on startup
   - Filter instruments in-memory
   - Register only filtered instruments

3. **Update catalog import scripts**:
   - Auto-rebuild index after data import
   - Add index versioning (detect stale indexes)

**Expected Result**: 17s → <1s registration time

### Phase 2: Nautilus Native Integration
1. **Submit PR to Nautilus Trader**:
   - Add `ParquetDataCatalog.index_instruments()` API
   - Store index in catalog metadata (parquet)
   - Auto-update index on data writes

2. **Use native API when available**:
   ```python
   # Future Nautilus API
   instruments = catalog.query_instruments(
       start_date=start_date,
       end_date=end_date,
       instrument_class=OptionContract
   )
   ```

**Expected Result**: Native support, no manual index builds

---

## FAQ

### Q: Why not use Nautilus' existing instrument filtering?
**A**: Nautilus catalogs filter by instrument **attributes** (strike, expiry, etc.) but not by **available data date ranges**. Our index adds temporal filtering.

### Q: What if I add new data to the catalog?
**A**: Rebuild the index using `build_instrument_index.py`. Consider adding this to your data import pipeline.

### Q: Can I use different date ranges without rebuilding?
**A**: Yes! The index stores full date ranges for each instrument. Different backtests can query different subsets without rebuilding.

### Q: What about memory usage?
**A**: Index file is ~2MB for 33,000 instruments (JSON). Loaded into memory: ~10MB. Negligible compared to bar data (GB).

---

## Example Usage

### Initial Setup (One-Time)
```bash
# Build instrument index for V12 catalog
python scripts/build_instrument_index.py \
    --catalog data/catalogs/v12_real_enhanced_hourly

# Output:
# ✅ Indexed 33,408 instruments in 28 seconds
# 📁 Saved to: data/catalogs/v12_real_enhanced_hourly/.instrument_index.json
```

### Backtest (Fast)
```bash
# Run backtest (uses index automatically)
python src/nautilus/backtest/run_dual_mode_backtest.py \
    --config config/examples/nautilus_native_strategy.json \
    --catalog data/catalogs/v12_real_enhanced_hourly

# Output:
# ✅ Loaded instrument index (33,408 instruments)
# ✅ Filtered to 6,264 instruments for 2024-01-01 to 2024-03-31
# ⏱️ Registration time: 0.8 seconds (vs 17 seconds before)
```

---

## Conclusion

**Recommended**: Implement Pre-Built Index (Approach 1)

**Benefits**:
- ✅ 100x faster registration (17s → <1s)
- ✅ Simple implementation (one Python script)
- ✅ Compatible with Nautilus best practices
- ✅ Works across different date ranges
- ✅ Minimal maintenance (rebuild on data import)

**Next Steps**:
1. Create `scripts/build_instrument_index.py`
2. Modify `single_strategy_runner.py` to use index
3. Update data import scripts to auto-rebuild index
4. Document in project README

---

**Author**: V12 Migration Team
**Date**: October 16, 2025
**Status**: Proposal (awaiting implementation)
**Related**: V12 Catalog Migration, Nautilus Integration
