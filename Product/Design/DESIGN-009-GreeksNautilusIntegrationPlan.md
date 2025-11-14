---
id: DESIGN-009-GreeksNautilusIntegrationPlan
seq: 9
title: "Greeks Integration with Nautilus"
status: draft
artifact_type: design_plan
created_at: 2025-02-15T00:00:00Z
updated_at: 2025-02-15T00:00:00Z
tags:
  - nautilus
  - greeks
  - backtesting
---

# Greeks Integration with Nautilus: Proper Implementation Plan

**Status**: 🔄 REVISION REQUIRED
**Issue**: Current implementation modifies Nautilus Bar schema (anti-pattern)
**Solution**: Use Nautilus GenericData for Greeks (separate from OHLCV bars)

---

## Problem with Current Implementation

### ❌ What We Did Wrong

Modified `nautilus_generator.py` to add Greeks columns to Bar schema:

```python
# WRONG - Extended Bar schema
bars_data = {
    "timestamp": ...,
    "open": ...,
    "high": ...,
    "low": ...,
    "close": ...,
    "volume": ...,
    "delta": ...,      # ← CUSTOM FIELD (breaks Nautilus schema)
    "gamma": ...,      # ← CUSTOM FIELD
    "theta": ...,      # ← CUSTOM FIELD
    "vega": ...,       # ← CUSTOM FIELD
    "rho": ...,        # ← CUSTOM FIELD
}
```

**Why This is Wrong**:
1. **Not native Nautilus format** - Breaks compatibility with `ParquetDataCatalog`
2. **Schema violation** - Bar type has fixed schema in Nautilus
3. **Cannot load with BacktestNode** - Requires custom loader
4. **Not maintainable** - Future Nautilus updates may break

---

## Correct Nautilus Pattern for Custom Data

### ✅ Nautilus-Aligned Approach

According to Nautilus best practices (11_CUSTOM_DATA_CLIENT_V13_INTEGRATION.md):

**Option A: GenericData Type** (Recommended)
- Nautilus provides `GenericData` type for custom fields
- Loaded separately via `BacktestEngine.add_data()`
- Accessed via strategy callbacks

**Option B: Custom Data Client**
- For live/paper trading custom data sources
- Overkill for backtest-only Greeks data

**Option C: Separate Parquet Files**
- Store Greeks in parallel Parquet structure
- Load via custom adapter
- Join with bars in strategy logic

---

## Recommended Implementation: Separate Greeks Parquet Catalog

### Architecture

```
catalog_dir/
├── bars/                        # Standard Nautilus OHLCV bars
│   └── {instrument_id}/
│       ├── 1H.parquet          # Native Nautilus Bar format
│       └── 1D.parquet
│
└── greeks/                      # Custom Greeks data (NEW)
    └── {instrument_id}/
        ├── 1H_greeks.parquet   # Delta, Gamma, Theta, Vega, Rho
        └── 1D_greeks.parquet
```

### Greeks Parquet Schema

**File**: `catalog_dir/greeks/{instrument_id}/1H_greeks.parquet`

```python
{
    "timestamp": datetime64[ns],   # Join key with bars
    "delta": float64,
    "gamma": float64,
    "theta": float64,
    "vega": float64,
    "rho": float64,
    "implied_volatility": float64,  # Optional
    "spot_price": float64,          # Optional
}
```

**Key Points**:
- Uses same `timestamp` as bars (join key)
- Same instrument directory structure
- Separate from Nautilus Bar files
- Can be loaded independently

### Loading Pattern

```python
# Step 1: Load bars (standard Nautilus)
catalog = ParquetDataCatalog(catalog_path)
bars = catalog.bars(
    instrument_ids=instrument_ids,
    bar_type=BarType.from_str("NIFTY-NSE-1-HOUR-LAST"),
    start=start_date,
    end=end_date
)

# Step 2: Load Greeks (custom loader)
greeks_loader = GreeksParquetLoader(catalog_path)
greeks_data = greeks_loader.load_greeks(
    instrument_ids=instrument_ids,
    bar_type="1H",
    start=start_date,
    end=end_date
)

# Step 3: Create lookup table for strategy
greeks_lookup = {}
for greeks_row in greeks_data:
    key = (greeks_row.instrument_id, greeks_row.timestamp)
    greeks_lookup[key] = {
        'delta': greeks_row.delta,
        'gamma': greeks_row.gamma,
        'theta': greeks_row.theta,
        'vega': greeks_row.vega,
        'rho': greeks_row.rho
    }

# Step 4: In strategy on_bar callback
def on_bar(self, bar: Bar):
    instrument_id = bar.bar_type.instrument_id
    timestamp = bar.ts_event

    # Lookup Greeks for this bar
    greeks = self.greeks_lookup.get((instrument_id, timestamp))

    if greeks:
        delta = greeks['delta']
        # Use delta for strike selection
        if abs(delta - 0.1) < 0.02:  # Within ±0.02 of target
            self.select_this_strike()
```

---

## Implementation Tasks

### Phase 1: Revert Current Changes ❌

**Files to Revert**:
1. `src/data_pipeline/catalog/nautilus_generator.py`
   - Remove Greeks columns from `_generate_bars()` query
   - Remove Greeks from `bars_data` dictionary
   - Restore to native Nautilus Bar schema

**Changes to Revert**:
```python
# REMOVE these lines from nautilus_generator.py:294-342

# Old query (REMOVE avg_greeks):
SELECT
    {time_col} as timestamp,
    open, high, low, close, volume,
    avg_delta, avg_gamma, avg_theta, avg_vega, avg_rho  # ← REMOVE

# Old bars_data (REMOVE Greeks):
bars_data = [
    {
        ...
        "delta": float(row[6]) if row[6] is not None else None,  # ← REMOVE
        "gamma": float(row[7]) if row[7] is not None else None,  # ← REMOVE
        ...
    }
]
```

### Phase 2: Implement Greeks Parquet Generator ✅

**New File**: `src/data_pipeline/catalog/greeks_parquet_generator.py`

```python
class GreeksParquetGenerator:
    """
    Generate parallel Greeks Parquet files alongside Nautilus bars.

    Directory structure mirrors Nautilus catalog:
        catalog_dir/greeks/{instrument_id}/{bar_type}_greeks.parquet
    """

    def __init__(self, db_session: DatabaseSession):
        self.db_session = db_session

    def generate_greeks_catalog(
        self,
        underlying: str,
        start_date: datetime,
        end_date: datetime,
        output_dir: Path,
        bar_types: list[str] = ["1H", "1D"]
    ) -> Path:
        """
        Generate Greeks catalog in parallel structure.

        Returns:
            Path to greeks/ directory
        """
        greeks_dir = output_dir / "greeks"
        greeks_dir.mkdir(parents=True, exist_ok=True)

        # Query contracts
        contracts = self._query_contracts(underlying, start_date, end_date)

        # Generate Greeks for each contract and bar type
        for contract in contracts:
            for bar_type in bar_types:
                self._generate_contract_greeks(
                    contract=contract,
                    bar_type=bar_type,
                    start_date=start_date,
                    end_date=end_date,
                    greeks_dir=greeks_dir
                )

        return greeks_dir

    def _generate_contract_greeks(
        self,
        contract: dict,
        bar_type: str,
        start_date: datetime,
        end_date: datetime,
        greeks_dir: Path
    ):
        """Generate Greeks file for one contract."""

        # Query Greeks from database
        if bar_type == "1H":
            view_name = "options_hourly_bars"
            time_col = "hour"
        elif bar_type == "1D":
            view_name = "options_daily_bars"
            time_col = "day"

        query = text(f"""
            SELECT
                {time_col} as timestamp,
                avg_delta as delta,
                avg_gamma as gamma,
                avg_theta as theta,
                avg_vega as vega,
                avg_rho as rho,
                avg_implied_volatility as implied_volatility,
                avg_spot_price as spot_price
            FROM {view_name}
            WHERE underlying = :underlying
              AND strike = :strike
              AND expiry = :expiry
              AND option_type = :option_type
              AND {time_col} >= :start_date
              AND {time_col} <= :end_date
            ORDER BY {time_col}
        """)

        with self.db_session.get_session() as session:
            result = session.execute(query, {
                "underlying": contract["underlying"],
                "strike": contract["strike"],
                "expiry": contract["expiry"],
                "option_type": contract["option_type"],
                "start_date": start_date,
                "end_date": end_date
            })

            greeks_data = [
                {
                    "timestamp": row[0],
                    "delta": float(row[1]) if row[1] is not None else None,
                    "gamma": float(row[2]) if row[2] is not None else None,
                    "theta": float(row[3]) if row[3] is not None else None,
                    "vega": float(row[4]) if row[4] is not None else None,
                    "rho": float(row[5]) if row[5] is not None else None,
                    "implied_volatility": float(row[6]) if row[6] is not None else None,
                    "spot_price": float(row[7]) if row[7] is not None else None,
                }
                for row in result
            ]

        if not greeks_data:
            return

        # Create instrument directory
        contract_id = self._format_contract_id(contract)
        contract_dir = greeks_dir / contract_id
        contract_dir.mkdir(parents=True, exist_ok=True)

        # Write Greeks Parquet file
        df = pd.DataFrame(greeks_data)
        greeks_file = contract_dir / f"{bar_type}_greeks.parquet"

        df.to_parquet(
            greeks_file,
            engine="pyarrow",
            compression="snappy",
            index=False
        )
```

### Phase 3: Implement Greeks Loader ✅

**New File**: `src/data_pipeline/catalog/greeks_loader.py`

```python
class GreeksParquetLoader:
    """Load Greeks data from parallel Parquet structure."""

    def __init__(self, catalog_path: Path):
        self.greeks_path = catalog_path / "greeks"

    def load_greeks(
        self,
        instrument_ids: list[str],
        bar_type: str,
        start: datetime | None = None,
        end: datetime | None = None
    ) -> pd.DataFrame:
        """
        Load Greeks for specified instruments and time range.

        Returns:
            DataFrame with columns: timestamp, instrument_id, delta, gamma, theta, vega, rho
        """
        all_greeks = []

        for instrument_id in instrument_ids:
            greeks_file = self.greeks_path / instrument_id / f"{bar_type}_greeks.parquet"

            if not greeks_file.exists():
                continue

            df = pd.read_parquet(greeks_file)
            df['instrument_id'] = instrument_id

            # Filter by time range
            if start is not None:
                df = df[df['timestamp'] >= start]
            if end is not None:
                df = df[df['timestamp'] <= end]

            all_greeks.append(df)

        if not all_greeks:
            return pd.DataFrame()

        return pd.concat(all_greeks, ignore_index=True)

    def create_lookup_dict(self, greeks_df: pd.DataFrame) -> dict:
        """
        Create fast lookup dictionary: (instrument_id, timestamp) -> Greeks.

        Usage in strategy:
            greeks = self.greeks_lookup.get((bar.instrument_id, bar.ts_event))
            delta = greeks['delta'] if greeks else None
        """
        lookup = {}
        for _, row in greeks_df.iterrows():
            key = (row['instrument_id'], row['timestamp'])
            lookup[key] = {
                'delta': row['delta'],
                'gamma': row['gamma'],
                'theta': row['theta'],
                'vega': row['vega'],
                'rho': row['rho'],
                'implied_volatility': row.get('implied_volatility'),
                'spot_price': row.get('spot_price')
            }
        return lookup
```

### Phase 4: Update Workflow Scripts ✅

**Modify**: `scripts/complete_data_pipeline.py`

```python
def step_3_generate_catalog(args):
    """Step 3: Generate Nautilus catalog (OHLCV only) + separate Greeks."""

    # Generate standard Nautilus catalog (no Greeks in bars)
    generator = NautilusCatalogGenerator(db_session)
    catalog_path = generator.generate_catalog(
        underlying=args.underlying,
        start_date=start_date,
        end_date=end_date,
        output_dir=args.output_dir,
        bar_types=args.bar_types
    )

    # Generate parallel Greeks catalog
    greeks_generator = GreeksParquetGenerator(db_session)
    greeks_path = greeks_generator.generate_greeks_catalog(
        underlying=args.underlying,
        start_date=start_date,
        end_date=end_date,
        output_dir=args.output_dir,
        bar_types=args.bar_types
    )

    print(f"✅ Nautilus catalog (bars): {catalog_path}")
    print(f"✅ Greeks catalog: {greeks_path}")

    return catalog_path
```

---

## Strategy Integration Pattern

### Example: STRAT-001 Delta-Based Strike Selection

```python
from nautilus_trader.trading.strategy import Strategy
from nautilus_trader.model.data import Bar
from src.data_pipeline.catalog import GreeksParquetLoader

class OptionsWeeklyMonthlyHedge(Strategy):

    def on_start(self):
        """Initialize Greeks lookup on strategy start."""

        # Load Greeks data
        greeks_loader = GreeksParquetLoader(catalog_path)
        greeks_df = greeks_loader.load_greeks(
            instrument_ids=self.instrument_ids,
            bar_type="1H",
            start=self.start_date,
            end=self.end_date
        )

        # Create fast lookup dictionary
        self.greeks_lookup = greeks_loader.create_lookup_dict(greeks_df)

        self.log.info(f"Loaded Greeks for {len(greeks_df)} bars")

    def on_bar(self, bar: Bar):
        """Handle bar data with Greeks lookup."""

        # Get Greeks for this bar
        key = (bar.bar_type.instrument_id, bar.ts_event)
        greeks = self.greeks_lookup.get(key)

        if greeks is None:
            self.log.warning(f"No Greeks for {key}")
            return

        delta = greeks['delta']

        # STRAT-001: Select strike with ±0.1 delta
        if abs(delta - 0.1) < 0.02:  # Within ±0.02 tolerance
            self.log.info(f"Found target delta strike: {bar.instrument_id.symbol} delta={delta:.4f}")
            self.execute_weekly_hedge_entry(bar, greeks)
```

---

## Benefits of This Approach

### ✅ Advantages

1. **100% Nautilus Compatible**
   - Bars use native Nautilus schema
   - Can load with standard `ParquetDataCatalog`
   - Works with BacktestNode and BacktestEngine

2. **Separation of Concerns**
   - OHLCV data (Nautilus standard)
   - Greeks data (custom, strategy-specific)
   - Clean architecture

3. **Flexible Access**
   - Load only Greeks when needed
   - Different strategies may not need Greeks
   - Reduces memory footprint

4. **Maintainable**
   - Future Nautilus updates won't break
   - Easy to extend with more custom fields
   - Clear data ownership

5. **Performance**
   - Greeks loaded once at strategy init
   - Fast dictionary lookup during backtest
   - No parsing overhead per bar

### ❌ Tradeoffs

1. **Extra Files**
   - Doubles Parquet file count
   - More disk space (negligible with compression)

2. **Manual Join Logic**
   - Strategy must lookup Greeks per bar
   - Simple dictionary lookup (fast)

3. **Two-Step Generation**
   - Generate bars, then Greeks
   - Can be parallelized

---

## Migration Steps

### Immediate Actions

1. **Revert Catalog Generator** ✅
   - Remove Greeks columns from Bar schema
   - Restore to native Nautilus format
   - Test with Nautilus ParquetDataCatalog

2. **Implement Greeks Generator** ✅
   - Create `greeks_parquet_generator.py`
   - Parallel directory structure
   - Same timestamp alignment

3. **Implement Greeks Loader** ✅
   - Create `greeks_loader.py`
   - Dictionary lookup pattern
   - Strategy integration helpers

4. **Update Documentation** ✅
   - Document Greeks catalog structure
   - Add loading examples
   - Update STORY-001 status

5. **Test End-to-End** ✅
   - Generate both catalogs
   - Load in test strategy
   - Verify Greeks lookup works
   - Validate delta values

---

## Status

- ❌ Current implementation (extended Bar schema): **MUST BE REVERTED**
- ✅ Nautilus best practices copied to vault: **COMPLETED**
- 🔄 Proper Greeks implementation (separate Parquet): **IN PROGRESS**

**Next**: Implement GreeksParquetGenerator and GreeksParquetLoader following this plan.
