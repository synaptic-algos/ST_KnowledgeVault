---
id: DESIGN-010-NautilusCatalogApproach
seq: 10
title: "Nautilus Catalog Integrity & Greeks Sidecar Pattern"
status: draft
artifact_type: design_note
created_at: 2025-02-15T00:00:00Z
updated_at: 2025-02-15T00:00:00Z
tags:
  - nautilus
  - catalog
  - data-pipeline
  - greeks
sources:
  - CORRECT-NAUTILUS-CATALOG-APPROACH.md
  - NAUTILUS-GREEKS-IMPLEMENTATION-SUMMARY.md
---

# Design Intent
Ensure every Nautilus catalog we generate remains 100% native while still exposing calculated Greeks to strategies. This captures the official pattern teams must follow going forward.

## Problem Recap
- Previous pipelines mutated the Nautilus `Bar` schema by embedding Greeks columns. This broke compatibility with `ParquetDataCatalog`, `BacktestNode`, and future Nautilus upgrades.
- GREeks data is mandatory for STRAT-001 (±0.1 delta hedging) and future partner strategies, so we need a maintainable alternative.

## Target Architecture
```
NSE Data  →  Parsers/Importers  →  TimescaleDB (with Greeks)  →  Writers
                                                    │
                                                    ├─ NautilusCatalogWriter (OHLCV-only, native)
                                                    └─ GreeksParquetWriter (sidecar catalog)
```

### 1. Native Catalog Writer (OHLCV Only)
- Use `ParquetDataCatalog.write_data()` to persist `Bar` objects (no schema extension).
- Steps:
  ```python
  catalog = ParquetDataCatalog(path="/path/to/catalog")
  catalog.write_data(instruments_list)
  catalog.write_data(bars_list)
  ```
- Benefits: schema enforcement, future-proofing, full tool compatibility.

### 2. Greeks Sidecar Catalog
- Separate directory: `<catalog_root>/greeks/{instrument_id}/{bar_type}.parquet`.
- Stored using `GreeksParquetWriter` with schema `{delta, gamma, theta, vega, rho, iv, spot_price}`.
- Uses same timestamps as the native bars for join keys.

### 3. Backtest Consumption Pattern
```python
class Strategy(BaseStrategy):
    async def on_start(self):
        self.greeks_lookup = await self.greeks_adapter.build_lookup()

    def on_bar(self, bar: Bar):
        greeks = self.greeks_lookup.get((bar.instrument_id, bar.ts_event))
        if not greeks:
            return
        delta = greeks["delta"]
        self.hedge_engine.rebalance(delta)
```
- Bars remain native.
- Greeks loaded once into an in-memory lookup keyed by `(instrument_id, ts_event)`.

### 4. Pipeline Implementation Guidance
1. **Writers**  
   - `NautilusCatalogWriter`: converts DB rows → `Bar` objects → `catalog.write_data`.  
   - `GreeksParquetWriter`: converts DB rows → pandas DataFrame → parquet (snappy).
2. **Scripts**  
   - `scripts/complete_data_pipeline.py` orchestrates full flow.  
   - Flags `--bar-types 1H 1D`, `--output-dir /tmp/catalogs`, etc.
3. **Validation**  
   - Load catalog via `ParquetDataCatalog` to confirm `catalog.bars(...)` works without custom schema.  
   - Cross-check Greeks sidecar by sampling `delta` values vs. expected ranges.

### 5. Operational Notes
- If catalog verification fails, roll back to previous version (retain S3 object versions).
- Keep Greeks sidecar optional—strategies that do not need Greeks skip the adapter.
- Document location of both outputs in sprint summaries and runbooks.

## Open Items / Follow Ups
1. Create automated test that loads both catalogs into Nautilus and validates a sample strategy.
2. Wire Playwright/CLI smoke test to verify catalog accessibility before publishing to S3.
3. Update STRAT-001 reference implementation to rely on the lookup pattern instead of mutated bars.
