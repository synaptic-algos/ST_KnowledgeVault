# Data Pipeline Architecture - Ports and Adapters Pattern

**Status**: 🟢 Approved Architecture
**Date**: 2025-11-05
**Related**: [[EPIC-007 Nautilus Greeks Integration]], [[STRAT-001 Catalog Generation]]
**Next**: [[DATA-001 Pluggable Data Sources PRD]]

---

## Executive Summary

This document defines the **Ports & Adapters** architecture for our data pipeline, enabling:
- ✅ Import from multiple data sources (NSE CSV, Interactive Brokers, Zerodha, etc.)
- ✅ Single source of truth in PostgreSQL/TimescaleDB
- ✅ Export to multiple backtest formats (Nautilus Parquet, Backtrader CSV)
- ✅ S3 storage for production backtesting

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                      DATA SOURCES (External)                         │
│  • NSE CSV files                                                     │
│  • Interactive Brokers API                                           │
│  • Yahoo Finance API                                                 │
│  • Zerodha Kite API                                                  │
│  • Manual CSV uploads                                                │
└────────────┬────────────────────────────────────────────────────────┘
             │
             │ INPUT ADAPTERS (normalize & validate)
             │
             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    POSTGRESQL (TimescaleDB)                          │
│                    🎯 Single Source of Truth                         │
│  ┌──────────────────┐  ┌──────────────────┐                        │
│  │ options_ticks    │  │ spot_prices      │                        │
│  │ options_hourly   │  │ futures_ticks    │                        │
│  │ options_daily    │  │ equity_daily     │                        │
│  └──────────────────┘  └──────────────────┘                        │
└────────────┬────────────────────────────────────────────────────────┘
             │
             │ EXPORT ADAPTERS (transform & package)
             │
             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  EXPORT FORMATS (S3 Storage)                         │
│  ┌───────────────────────┐  ┌───────────────────────┐              │
│  │ Nautilus Parquet      │  │ Backtrader CSV        │              │
│  │ s3://bucket/catalog/  │  │ s3://bucket/csv/      │              │
│  └───────────────────────┘  └───────────────────────┘              │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Core Concepts

### Port vs Adapter

| Concept | Definition | Analogy | In Our System |
|---------|-----------|---------|---------------|
| **Port** | Abstract interface defining operations | USB-C port specification | `DataImportPort`, `DataExportPort` |
| **Adapter** | Concrete implementation for specific system | USB-C charger, HDMI cable | `NSECSVAdapter`, `NautilusExporter` |

**Key Principle**:
- **Port** = "I need data that looks like THIS" (stable contract)
- **Adapter** = "Here's how to get it from THAT source" (swappable implementation)

---

## Port Definitions

### 1. DataImportPort (Input)

```python
# src/data_pipeline/adapters/input/base.py
from abc import ABC, abstractmethod
from datetime import datetime
import pandas as pd

class DataImportPort(ABC):
    """
    Abstract interface for importing options data into PostgreSQL.
    Each data source implements this port.
    """

    @abstractmethod
    def import_options_data(
        self,
        symbol: str,
        start_date: datetime,
        end_date: datetime,
        **kwargs
    ) -> int:
        """
        Import options data from source into PostgreSQL.

        Args:
            symbol: Underlying symbol (e.g., 'NIFTY')
            start_date: Start date for data import
            end_date: End date for data import
            **kwargs: Source-specific parameters

        Returns:
            Number of records imported
        """
        pass

    @abstractmethod
    def validate_data(self, df: pd.DataFrame) -> bool:
        """
        Validate data before import.

        Args:
            df: DataFrame to validate

        Returns:
            True if valid, raises ValueError if invalid
        """
        pass

    @abstractmethod
    def normalize_schema(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Normalize source-specific schema to standard schema.

        Args:
            df: Source-specific DataFrame

        Returns:
            DataFrame with normalized schema matching PostgreSQL
        """
        pass
```

### 2. DataExportPort (Output)

```python
# src/data_pipeline/adapters/output/base.py
from abc import ABC, abstractmethod
from pathlib import Path

class DataExportPort(ABC):
    """
    Abstract interface for exporting PostgreSQL data to backtest formats.
    Each framework implements this port.
    """

    @abstractmethod
    def export_catalog(
        self,
        underlying: str,
        start_date: datetime,
        end_date: datetime,
        output_path: Path,
        **kwargs
    ) -> Path:
        """
        Export data from PostgreSQL to framework-specific format.

        Args:
            underlying: Underlying symbol
            start_date: Start date for export
            end_date: End date for export
            output_path: Local or S3 path for output
            **kwargs: Framework-specific parameters

        Returns:
            Path to exported catalog
        """
        pass

    @abstractmethod
    def validate_export(self, output_path: Path) -> bool:
        """
        Validate exported catalog can be loaded by framework.

        Args:
            output_path: Path to exported catalog

        Returns:
            True if valid, raises ValueError if invalid
        """
        pass
```

---

## Adapter Implementations

### Input Adapters

#### NSECSVAdapter (Already Implemented ✅)

```python
# src/data_pipeline/adapters/input/nse_csv_adapter.py
class NSECSVAdapter(DataImportPort):
    """Import data from NSE CSV files (tick data)"""

    def import_options_data(self, symbol: str, start_date: datetime,
                           end_date: datetime, csv_dir: Path) -> int:
        # Read CSV files
        # Parse NSE ticker format: NIFTY25AUG24500CE
        # Normalize to standard schema
        # Insert into options_ticks table
        pass

    def normalize_schema(self, df: pd.DataFrame) -> pd.DataFrame:
        # NSE-specific: Rename columns, parse ticker, handle timezone
        df['timestamp'] = pd.to_datetime(df['Date'] + ' ' + df['Time'])
        df['underlying'], df['strike'], df['expiry'], df['option_type'] = \
            parse_nse_ticker(df['Ticker'])
        return df
```

#### InteractiveBrokersAdapter (Planned)

```python
# src/data_pipeline/adapters/input/ib_adapter.py
class IBAdapter(DataImportPort):
    """Import data from Interactive Brokers TWS API"""

    def import_options_data(self, symbol: str, start_date: datetime,
                           end_date: datetime) -> int:
        # Connect to IB TWS
        # Request historical data: reqHistoricalData()
        # Handle IB contract format
        # Normalize to standard schema
        # Insert into options_ticks
        pass

    def normalize_schema(self, df: pd.DataFrame) -> pd.DataFrame:
        # IB-specific: Convert IB timestamps, parse IB contracts
        df['timestamp'] = pd.to_datetime(df['date'], unit='s')
        df['underlying'] = df['localSymbol'].str[:5]  # e.g., 'NIFTY'
        return df
```

#### ZerodhaAdapter (Planned)

```python
# src/data_pipeline/adapters/input/zerodha_adapter.py
class ZerodhaAdapter(DataImportPort):
    """Import data from Zerodha Kite API"""

    def import_options_data(self, symbol: str, start_date: datetime,
                           end_date: datetime, instruments: List[str]) -> int:
        # Connect to Kite API
        # Request historical data
        # Handle Kite instrument tokens
        # Normalize to standard schema
        # Insert into options_ticks
        pass
```

### Output Adapters

#### NautilusExporter (Implemented ✅)

```python
# src/data_pipeline/adapters/output/nautilus_exporter.py
class NautilusExporter(DataExportPort):
    """Export PostgreSQL data to Nautilus Parquet catalog"""

    def export_catalog(self, underlying: str, start_date: datetime,
                      end_date: datetime, output_path: Path) -> Path:
        # Query PostgreSQL for instruments and bars
        # Convert to Nautilus OptionContract and Bar objects
        # Write using ParquetDataCatalog.write_data()
        # Upload to S3 if output_path is s3://
        pass

    def validate_export(self, output_path: Path) -> bool:
        # Try loading with ParquetDataCatalog
        catalog = ParquetDataCatalog(str(output_path))
        instruments = catalog.instruments()
        return len(instruments) > 0
```

#### BacktraderExporter (Planned)

```python
# src/data_pipeline/adapters/output/backtrader_exporter.py
class BacktraderExporter(DataExportPort):
    """Export PostgreSQL data to Backtrader CSV format"""

    def export_catalog(self, underlying: str, start_date: datetime,
                      end_date: datetime, output_path: Path) -> Path:
        # Query PostgreSQL for daily bars
        # Format as Backtrader expects: date,open,high,low,close,volume
        # Write CSV files
        # Upload to S3
        pass
```

---

## Data Flow

### Import Flow (Source → PostgreSQL)

```
1. User runs: python scripts/import_data.py --source nse-csv --path data/08-2025/

2. CLI loads appropriate adapter:
   adapter = NSECSVAdapter()

3. Adapter reads source data:
   df = adapter.read_source(path)

4. Adapter normalizes schema:
   df = adapter.normalize_schema(df)

5. Adapter validates data:
   adapter.validate_data(df)

6. Adapter writes to PostgreSQL:
   df.to_sql('options_ticks', engine, if_exists='append')

7. TimescaleDB continuous aggregates auto-update:
   - options_hourly_bars (materialized)
   - options_daily_bars (materialized)
```

### Export Flow (PostgreSQL → Backtest Format)

```
1. User runs: python scripts/export_catalog.py --format nautilus --underlying NIFTY

2. CLI loads appropriate exporter:
   exporter = NautilusExporter(db_session)

3. Exporter queries PostgreSQL:
   instruments = exporter.query_instruments(underlying, start, end)
   bars = exporter.query_bars(instruments, start, end)

4. Exporter transforms to Nautilus format:
   nautilus_instruments = [OptionContract(...) for inst in instruments]
   nautilus_bars = [Bar(...) for bar in bars]

5. Exporter writes Parquet:
   catalog.write_data(nautilus_instruments)
   catalog.write_data(nautilus_bars)

6. Exporter uploads to S3:
   s3.upload_file(catalog_path, s3_bucket, s3_key)
```

---

## File Structure

```
src/data_pipeline/
├── adapters/
│   ├── input/
│   │   ├── __init__.py
│   │   ├── base.py                    # DataImportPort (abstract)
│   │   ├── nse_csv_adapter.py         # ✅ Implemented
│   │   ├── ib_adapter.py              # 📋 Planned
│   │   └── zerodha_adapter.py         # 📋 Planned
│   │
│   └── output/
│       ├── __init__.py
│       ├── base.py                    # DataExportPort (abstract)
│       ├── nautilus_exporter.py       # ✅ Implemented
│       └── backtrader_exporter.py     # 📋 Planned
│
├── database/
│   ├── schema/
│   │   ├── 001_create_options_schema.sql
│   │   ├── 002_create_continuous_aggregates.sql
│   │   └── 003_create_indexes.sql
│   ├── session.py
│   └── migrations.py
│
└── scripts/
    ├── import_data.py                 # CLI: Import from any source
    └── export_catalog.py              # CLI: Export to any format
```

---

## Benefits

| Benefit | Explanation |
|---------|-------------|
| **Separation of Concerns** | Import logic ≠ Storage ≠ Export logic |
| **Single Source of Truth** | PostgreSQL is authoritative, formats are derived |
| **Extensibility** | Add new sources/formats without changing core code |
| **Testability** | Mock PostgreSQL, test adapters in isolation |
| **Performance** | TimescaleDB optimizations (compression, aggregates) |
| **Debuggability** | SQL queries to inspect data at any stage |
| **Incremental Updates** | Import new data without regenerating catalogs |
| **Multi-Framework** | One database → Multiple backtest frameworks |
| **Type Safety** | Strong contracts via abstract base classes |

---

## S3 Integration

### Storage Structure

```
s3://synaptic-trading-data/
├── catalogs/
│   ├── nautilus/
│   │   ├── NIFTY/
│   │   │   ├── 2025-05/
│   │   │   ├── 2025-06/
│   │   │   └── 2025-08/
│   │   │       ├── data/
│   │   │       │   └── bar.parquet
│   │   │       └── instruments/
│   │   │           └── option_contract.parquet
│   │   └── BANKNIFTY/
│   │
│   └── backtrader/
│       └── NIFTY/
│           └── 2025-08/
│               └── NIFTY_250814_24500_CE.csv
│
└── raw/
    └── nse/
        └── 08-2025/
            └── *.csv
```

### Upload/Download

```python
import boto3

class S3Handler:
    def upload_catalog(self, local_path: Path, s3_uri: str):
        s3 = boto3.client('s3')
        bucket, prefix = parse_s3_uri(s3_uri)

        for file in local_path.rglob('*'):
            if file.is_file():
                s3_key = f"{prefix}/{file.relative_to(local_path)}"
                s3.upload_file(str(file), bucket, s3_key)

    def download_catalog(self, s3_uri: str, local_path: Path):
        s3 = boto3.client('s3')
        bucket, prefix = parse_s3_uri(s3_uri)

        # List all objects with prefix
        objects = s3.list_objects_v2(Bucket=bucket, Prefix=prefix)

        for obj in objects['Contents']:
            local_file = local_path / obj['Key'].replace(prefix, '')
            local_file.parent.mkdir(parents=True, exist_ok=True)
            s3.download_file(bucket, obj['Key'], str(local_file))
```

---

## Example Usage

### Import from NSE CSV

```bash
python scripts/import_data.py \
    --source nse-csv \
    --path data/sample/options/08-2025/ \
    --underlying NIFTY \
    --start-date 2025-08-01 \
    --end-date 2025-08-31
```

### Import from Interactive Brokers

```bash
python scripts/import_data.py \
    --source interactive-brokers \
    --symbol NIFTY \
    --start-date 2025-08-01 \
    --end-date 2025-08-31 \
    --ib-host localhost \
    --ib-port 7497
```

### Export to Nautilus (S3)

```bash
python scripts/export_catalog.py \
    --format nautilus \
    --underlying NIFTY \
    --start-date 2025-08-01 \
    --end-date 2025-08-31 \
    --output s3://synaptic-trading-data/catalogs/nautilus/NIFTY/2025-08/
```

### Export to Backtrader (Local)

```bash
python scripts/export_catalog.py \
    --format backtrader \
    --underlying NIFTY \
    --start-date 2025-08-01 \
    --end-date 2025-08-31 \
    --output /tmp/backtrader-data/
```

---

## Migration Plan

### Phase 1: Refactor Existing Code ✅ (CURRENT)
- [x] Extract NSE CSV logic into `NSECSVAdapter`
- [x] Extract Nautilus catalog generation into `NautilusExporter`
- [x] Define `DataImportPort` and `DataExportPort` interfaces
- [x] Update scripts to use adapter pattern

### Phase 2: Add New Input Adapters 📋 (NEXT)
- [ ] Implement `InteractiveBrokersAdapter`
- [ ] Implement `ZerodhaAdapter`
- [ ] Implement `YahooFinanceAdapter`
- [ ] Add adapter registry/factory

### Phase 3: Add New Export Adapters 📋
- [ ] Implement `BacktraderExporter`
- [ ] Implement `QuantConnectExporter`
- [ ] Implement generic CSV exporter

### Phase 4: S3 Integration 📋
- [ ] Add S3 upload/download to exporters
- [ ] Implement S3 caching for catalog reads
- [ ] Add S3 lifecycle policies for cost optimization

---

## Related Documents

- [[EPIC-007 Nautilus Greeks Integration]] - Parent epic
- [[STRAT-001 Catalog Generation]] - Current story (completed)
- [[DATA-001 Pluggable Data Sources PRD]] - Next story (to be created)
- [[Database Schema Design]] - PostgreSQL schema reference
- [[Nautilus Catalog Format]] - Nautilus-specific requirements

---

## Questions & Decisions

### Q: Why PostgreSQL instead of direct CSV → Parquet?
**A**: PostgreSQL provides:
- ✅ Data validation and constraints
- ✅ Efficient querying for date ranges
- ✅ TimescaleDB continuous aggregates (auto-update hourly/daily bars)
- ✅ Single source of truth (one import, multiple exports)
- ✅ SQL for debugging and analytics

### Q: Why separate import and export adapters?
**A**: Different responsibilities:
- **Import**: Validate, normalize, deduplicate source data
- **Export**: Transform, package, optimize for backtest framework
- Allows mixing: Import from NSE + IB, export to Nautilus + Backtrader

### Q: How to handle duplicate data imports?
**A**: PostgreSQL `ON CONFLICT DO UPDATE` in adapters:
```python
INSERT INTO options_ticks (...) VALUES (...)
ON CONFLICT (timestamp, underlying, strike, expiry, option_type)
DO UPDATE SET close = EXCLUDED.close, volume = EXCLUDED.volume
```

### Q: How to add a new data source?
**A**: Three steps:
1. Create adapter: `class NewSourceAdapter(DataImportPort)`
2. Implement: `import_options_data()`, `normalize_schema()`, `validate_data()`
3. Register in CLI: `ADAPTERS = {'new-source': NewSourceAdapter}`

---

**Last Updated**: 2025-11-05
**Author**: Claude Code
**Status**: ✅ Approved Architecture
