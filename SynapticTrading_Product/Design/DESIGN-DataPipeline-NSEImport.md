---
id: DESIGN-DataPipeline-NSEImport
title: "NSE Historical Data Import Pipeline Design"
status: draft
artifact_type: design
created_at: 2025-11-04T00:00:00Z
updated_at: 2025-11-04T00:00:00Z
related_story:
  - STORY-006-01
related_feature:
  - FEATURE-006
tags:
  - data-pipeline
  - nse
  - csv-import
  - timescaledb
  - nautilus
---

# DESIGN: NSE Historical Data Import Pipeline

**Story**: [STORY-006-01: NSE Data Import & Greeks Calculation](../EPICS/EPIC-007-StrategyLifecycle/FEATURE-006-DataPipeline/STORY-001-NSEDataImport/README.md)

**Feature**: [FEATURE-006: Data Pipeline](../EPICS/EPIC-007-StrategyLifecycle/FEATURE-006-DataPipeline/README.md)

## Overview

This design document specifies the architecture for importing NSE historical options and spot data from CSV files into TimescaleDB and generating Nautilus Parquet catalogs for S3 storage.

### Scope

**In Scope**:
- NSE CSV format parsing (options + spot)
- Contract identifier parsing (ticker format)
- Bulk database import pipeline
- Nautilus catalog generation
- S3 upload workflow
- Error handling and data validation

**Out of Scope**:
- Greeks calculation (covered in DESIGN-DataPipeline-Greeks.md)
- Real-time data streaming
- Data quality monitoring dashboards
- Automated data updates from NSE

## Data Sources

### 1. NSE Options Data

**Location**: `data/sample/options/{month-year}/*.csv`

**File Naming Convention**:
```
NIFTY{strike}{expiry}{option_type}.csv

Examples:
- NIFTY2675028AUG25CE.csv  → Strike: 26750, Expiry: 28-AUG-2025, Type: CE
- NIFTY2600025NOV25PE.csv  → Strike: 26000, Expiry: 25-NOV-2025, Type: PE
```

**CSV Format**:
```csv
Ticker,Date,Time,Close,Volume,OI
NIFTY2675028AUG25CE,20250801,09:25:58,6.5,0,33225
NIFTY2675028AUG25CE,20250801,09:25:58,6.5,75,33225
NIFTY2675028AUG25CE,20250801,10:24:36,6.45,75,33150
```

**Columns**:
- `Ticker`: Contract identifier (needs parsing)
- `Date`: YYYYMMDD format
- `Time`: HH:MM:SS format
- `Close`: Last traded price (will be used for OHLC aggregation)
- `Volume`: Trade volume
- `OI`: Open Interest

**Data Characteristics**:
- Tick-level data (multiple records per minute)
- No explicit OHLC (only Close price)
- No implied volatility in CSV (needs separate source or calculation)
- No bid/ask spreads

### 2. NIFTY Spot Data

**Location**: `data/sample/niftyspot/nifty_data_min.csv`

**CSV Format**:
```csv
date,open,high,low,close,volume
2024-01-01 09:15:00+05:30,21727.75,21737.35,21701.8,21712,0
2024-01-01 09:16:00+05:30,21711.5,21720,21695.35,21695.65,0
```

**Columns**:
- `date`: Timestamp with timezone (ISO format)
- `open`, `high`, `low`, `close`: Minute-level OHLC
- `volume`: Trading volume

**Data Characteristics**:
- Minute-level aggregated bars
- Timezone: IST (+05:30)
- Complete OHLC data
- Continuous time series

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    NSE Data Import Pipeline                      │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│  CSV Files       │
│  - Options       │
│  - Spot          │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  CSV Parsers                                                  │
│  ┌────────────────────┐   ┌─────────────────────────┐       │
│  │ NSEOptionsCSV      │   │ NSESpotCSVParser        │       │
│  │ Parser             │   │                         │       │
│  │                    │   │                         │       │
│  │ - Parse ticker     │   │ - Parse timestamp       │       │
│  │ - Extract contract │   │ - Extract OHLCV         │       │
│  │ - Build OHLC bars  │   │ - Validate data         │       │
│  └────────┬───────────┘   └────────┬────────────────┘       │
└───────────┼────────────────────────┼─────────────────────────┘
            │                        │
            ▼                        ▼
┌──────────────────────────────────────────────────────────────┐
│  Data Validator                                               │
│  - Check price ranges                                         │
│  - Validate timestamps                                        │
│  - Check for duplicates                                       │
└───────────┬──────────────────────────────────────────────────┘
            │
            ▼
┌──────────────────────────────────────────────────────────────┐
│  Database Importer                                            │
│  - Batch processing                                           │
│  - Transaction management                                     │
│  - Upsert on conflict                                         │
└───────────┬──────────────────────────────────────────────────┘
            │
            ▼
┌──────────────────────────────────────────────────────────────┐
│  TimescaleDB                                                  │
│  ┌─────────────────────┐   ┌────────────────────────┐       │
│  │ options_ticks       │   │ spot_prices            │       │
│  │ (hypertable)        │   │ (hypertable)           │       │
│  └─────────────────────┘   └────────────────────────┘       │
└───────────┬──────────────────────────────────────────────────┘
            │
            ▼
┌──────────────────────────────────────────────────────────────┐
│  Nautilus Catalog Generator                                   │
│  - Query aggregated bars                                      │
│  - Generate instruments.parquet                               │
│  - Generate bars/{instrument_id}/1H.parquet                   │
│  - Generate bars/{instrument_id}/1D.parquet                   │
└───────────┬──────────────────────────────────────────────────┘
            │
            ▼
┌──────────────────────────────────────────────────────────────┐
│  S3 Catalog Uploader                                          │
│  - Upload Parquet files to S3                                 │
│  - Verify upload success                                      │
└───────────┬──────────────────────────────────────────────────┘
            │
            ▼
┌──────────────────────────────────────────────────────────────┐
│  S3 Storage                                                   │
│  s3://synaptic-trading-data/nautilus-catalogs/nifty-options  │
└──────────────────────────────────────────────────────────────┘
```

## Detailed Design

### 1. Ticker Parser

**Purpose**: Parse NSE option contract identifiers to extract strike, expiry, and option type.

**Input Format**: `NIFTY{strike}{expiry}{option_type}`

**Examples**:
- `NIFTY2675028AUG25CE` → Strike: 26750, Expiry: 2025-08-28, Type: CE
- `NIFTY2600025NOV25PE` → Strike: 26000, Expiry: 2025-11-25, Type: PE

**Algorithm**:

```python
import re
from datetime import datetime
from typing import NamedTuple

class OptionContract(NamedTuple):
    underlying: str
    strike: float
    expiry: datetime
    option_type: str  # 'CE' or 'PE'

def parse_nse_ticker(ticker: str) -> OptionContract:
    """
    Parse NSE option ticker format.

    Format: NIFTY{strike}{expiry_day}{expiry_month}{expiry_year}{option_type}
    Example: NIFTY2675028AUG25CE

    Args:
        ticker: NSE option ticker string

    Returns:
        OptionContract with parsed values

    Raises:
        ValueError: If ticker format is invalid
    """
    # Pattern: NIFTY + digits (strike) + 2 digits (day) + 3 letters (month) + 2 digits (year) + CE/PE
    pattern = r'^(NIFTY|BANKNIFTY)(\d+)(\d{2})([A-Z]{3})(\d{2})(CE|PE)$'

    match = re.match(pattern, ticker)
    if not match:
        raise ValueError(f"Invalid ticker format: {ticker}")

    underlying, strike_str, day, month_abbr, year, option_type = match.groups()

    # Parse strike (divide by 100 if needed for NIFTY format)
    # NSE format: 26750 is stored as "26750" not "267.50"
    strike = float(strike_str)

    # Parse expiry date
    month_map = {
        'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4,
        'MAY': 5, 'JUN': 6, 'JUL': 7, 'AUG': 8,
        'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12
    }

    month_num = month_map.get(month_abbr)
    if not month_num:
        raise ValueError(f"Invalid month abbreviation: {month_abbr}")

    # Year: 25 → 2025
    full_year = 2000 + int(year)

    # Construct date
    expiry = datetime(full_year, month_num, int(day))

    return OptionContract(
        underlying=underlying,
        strike=strike,
        expiry=expiry,
        option_type=option_type
    )
```

**Unit Tests Required**:
```python
def test_parse_nifty_call():
    contract = parse_nse_ticker("NIFTY2675028AUG25CE")
    assert contract.underlying == "NIFTY"
    assert contract.strike == 26750.0
    assert contract.expiry == datetime(2025, 8, 28)
    assert contract.option_type == "CE"

def test_parse_nifty_put():
    contract = parse_nse_ticker("NIFTY2600025NOV25PE")
    assert contract.underlying == "NIFTY"
    assert contract.strike == 26000.0
    assert contract.expiry == datetime(2025, 11, 25)
    assert contract.option_type == "PE"

def test_parse_banknifty():
    contract = parse_nse_ticker("BANKNIFTY5200015JAN25CE")
    assert contract.underlying == "BANKNIFTY"
    assert contract.strike == 52000.0
```

### 2. Options CSV Parser

**Purpose**: Read NSE options CSV files and convert to database-ready records.

**Implementation**:

```python
import pandas as pd
from pathlib import Path
from typing import Iterator
from datetime import datetime

class NSEOptionsCSVParser:
    """Parser for NSE options tick data CSV files."""

    def __init__(self):
        self.required_columns = {'Ticker', 'Date', 'Time', 'Close', 'Volume', 'OI'}

    def parse_file(self, csv_path: Path) -> pd.DataFrame:
        """
        Parse a single NSE options CSV file.

        Args:
            csv_path: Path to CSV file

        Returns:
            DataFrame with parsed and enriched data
        """
        # Read CSV
        df = pd.read_csv(csv_path)

        # Validate columns
        if not self.required_columns.issubset(df.columns):
            missing = self.required_columns - set(df.columns)
            raise ValueError(f"Missing columns: {missing}")

        # Parse ticker to extract contract details
        first_ticker = df['Ticker'].iloc[0]
        contract = parse_nse_ticker(first_ticker)

        # Add contract details as columns
        df['underlying'] = contract.underlying
        df['strike'] = contract.strike
        df['expiry'] = contract.expiry
        df['option_type'] = contract.option_type

        # Parse timestamp
        df['timestamp'] = pd.to_datetime(
            df['Date'].astype(str) + ' ' + df['Time'],
            format='%Y%m%d %H:%M:%S'
        )

        # Rename columns to match database schema
        df.rename(columns={
            'Close': 'close',
            'Volume': 'volume',
            'OI': 'open_interest'
        }, inplace=True)

        # For tick data, we only have close prices
        # OHLC will be aggregated later
        df['open'] = df['close']
        df['high'] = df['close']
        df['low'] = df['close']

        # Set data source
        df['data_source'] = 'NSE_CSV'

        # Select final columns
        columns = [
            'timestamp', 'underlying', 'strike', 'expiry', 'option_type',
            'open', 'high', 'low', 'close', 'volume', 'open_interest',
            'data_source'
        ]

        return df[columns]

    def parse_directory(self, directory: Path) -> pd.DataFrame:
        """
        Parse all CSV files in a directory and subdirectories.

        Args:
            directory: Root directory containing CSV files

        Returns:
            Combined DataFrame from all files
        """
        all_dfs = []

        # Find all CSV files recursively
        csv_files = list(directory.rglob("*.csv"))

        print(f"Found {len(csv_files)} CSV files in {directory}")

        for csv_path in csv_files:
            try:
                df = self.parse_file(csv_path)
                all_dfs.append(df)
                print(f"✅ Parsed {csv_path.name}: {len(df)} records")
            except Exception as e:
                print(f"❌ Failed to parse {csv_path.name}: {e}")

        # Combine all DataFrames
        if not all_dfs:
            raise ValueError(f"No valid CSV files found in {directory}")

        combined_df = pd.concat(all_dfs, ignore_index=True)

        # Sort by timestamp
        combined_df.sort_values('timestamp', inplace=True)

        return combined_df
```

### 3. Spot CSV Parser

**Purpose**: Read NIFTY spot price CSV files.

**Implementation**:

```python
class NSESpotCSVParser:
    """Parser for NIFTY spot price CSV files."""

    def parse_file(self, csv_path: Path) -> pd.DataFrame:
        """
        Parse NIFTY spot price CSV.

        Args:
            csv_path: Path to CSV file

        Returns:
            DataFrame with parsed data
        """
        # Read CSV
        df = pd.read_csv(csv_path)

        # Validate columns
        required = {'date', 'open', 'high', 'low', 'close', 'volume'}
        if not required.issubset(df.columns):
            missing = required - set(df.columns)
            raise ValueError(f"Missing columns: {missing}")

        # Parse timestamp (handles timezone if present)
        df['timestamp'] = pd.to_datetime(df['date'])

        # Remove timezone for consistency with database
        if df['timestamp'].dt.tz is not None:
            df['timestamp'] = df['timestamp'].dt.tz_localize(None)

        # Add underlying symbol
        df['underlying'] = 'NIFTY'

        # Set data source
        df['data_source'] = 'NSE_SPOT_CSV'

        # Select final columns
        columns = [
            'timestamp', 'underlying', 'open', 'high', 'low', 'close',
            'volume', 'data_source'
        ]

        return df[columns]
```

### 4. OHLC Aggregation (for Options Tick Data)

**Purpose**: Convert tick-level options data to OHLC bars.

**Implementation**:

```python
class OHLCAggregator:
    """Aggregate tick data into OHLC bars."""

    def aggregate_to_bars(
        self,
        df: pd.DataFrame,
        timeframe: str = '1H'
    ) -> pd.DataFrame:
        """
        Aggregate tick data to OHLC bars.

        Args:
            df: DataFrame with tick data
            timeframe: Pandas resample frequency ('1H', '1D', etc.)

        Returns:
            DataFrame with OHLC bars
        """
        # Set timestamp as index
        df = df.set_index('timestamp')

        # Group by contract and resample
        grouper = df.groupby(['underlying', 'strike', 'expiry', 'option_type'])

        bars = grouper.resample(timeframe).agg({
            'close': ['first', 'max', 'min', 'last'],  # OHLC
            'volume': 'sum',
            'open_interest': 'last',  # OI at end of period
        })

        # Flatten multi-level columns
        bars.columns = ['open', 'high', 'low', 'close', 'volume', 'open_interest']

        # Reset index
        bars = bars.reset_index()

        # Drop rows with NaN (no data for that period)
        bars = bars.dropna(subset=['close'])

        return bars
```

### 5. Database Import Pipeline

**Purpose**: Bulk insert data into TimescaleDB with transaction management.

**Implementation**:

```python
from sqlalchemy import create_engine
from sqlalchemy.dialects.postgresql import insert
import os

class DatabaseImporter:
    """Import parsed data into TimescaleDB."""

    def __init__(self, db_url: str = None):
        if db_url is None:
            db_url = self._build_db_url()
        self.engine = create_engine(db_url)

    def _build_db_url(self) -> str:
        """Build database URL from environment variables."""
        host = os.getenv('DB_HOST', 'localhost')
        port = os.getenv('DB_PORT', '5432')
        user = os.getenv('DB_USER', 'postgres')
        password = os.getenv('DB_PASSWORD')
        db_name = os.getenv('DB_NAME', 'synaptic_trading')

        if not password:
            raise ValueError("DB_PASSWORD environment variable must be set")

        return f"postgresql://{user}:{password}@{host}:{port}/{db_name}"

    def import_options_data(
        self,
        df: pd.DataFrame,
        batch_size: int = 1000
    ) -> int:
        """
        Import options data with upsert on conflict.

        Args:
            df: DataFrame with options data
            batch_size: Number of records per batch

        Returns:
            Number of records imported
        """
        total_records = 0

        # Process in batches
        for i in range(0, len(df), batch_size):
            batch = df.iloc[i:i+batch_size]

            # Convert to dict records
            records = batch.to_dict('records')

            # Upsert (ON CONFLICT DO UPDATE)
            stmt = insert(table='options_ticks').values(records)
            stmt = stmt.on_conflict_do_update(
                index_elements=['timestamp', 'underlying', 'strike', 'expiry', 'option_type'],
                set_={
                    'open': stmt.excluded.open,
                    'high': stmt.excluded.high,
                    'low': stmt.excluded.low,
                    'close': stmt.excluded.close,
                    'volume': stmt.excluded.volume,
                    'open_interest': stmt.excluded.open_interest,
                }
            )

            with self.engine.begin() as conn:
                conn.execute(stmt)

            total_records += len(batch)
            print(f"Imported {total_records:,} / {len(df):,} records...")

        return total_records

    def import_spot_data(
        self,
        df: pd.DataFrame,
        batch_size: int = 1000
    ) -> int:
        """
        Import spot data with upsert on conflict.

        Args:
            df: DataFrame with spot data
            batch_size: Number of records per batch

        Returns:
            Number of records imported
        """
        total_records = 0

        for i in range(0, len(df), batch_size):
            batch = df.iloc[i:i+batch_size]
            records = batch.to_dict('records')

            stmt = insert(table='spot_prices').values(records)
            stmt = stmt.on_conflict_do_update(
                index_elements=['timestamp', 'underlying'],
                set_={
                    'open': stmt.excluded.open,
                    'high': stmt.excluded.high,
                    'low': stmt.excluded.low,
                    'close': stmt.excluded.close,
                    'volume': stmt.excluded.volume,
                }
            )

            with self.engine.begin() as conn:
                conn.execute(stmt)

            total_records += len(batch)
            print(f"Imported {total_records:,} / {len(df):,} records...")

        return total_records
```

### 6. Data Validation

**Purpose**: Validate data quality before database import.

**Implementation**:

```python
class DataValidator:
    """Validate data quality and consistency."""

    def validate_options_data(self, df: pd.DataFrame) -> list[str]:
        """
        Validate options data quality.

        Returns:
            List of validation errors (empty if all valid)
        """
        errors = []

        # Check for negative prices
        if (df['close'] < 0).any():
            errors.append("Negative close prices found")

        # Check for zero or negative strikes
        if (df['strike'] <= 0).any():
            errors.append("Zero or negative strikes found")

        # Check for invalid option types
        valid_types = {'CE', 'PE'}
        if not df['option_type'].isin(valid_types).all():
            errors.append(f"Invalid option types (must be {valid_types})")

        # Check for missing values
        required_cols = ['timestamp', 'strike', 'expiry', 'close']
        for col in required_cols:
            if df[col].isna().any():
                errors.append(f"Missing values in column: {col}")

        # Check timestamp ordering
        if not df['timestamp'].is_monotonic_increasing:
            errors.append("Timestamps are not in chronological order")

        return errors

    def validate_spot_data(self, df: pd.DataFrame) -> list[str]:
        """Validate spot price data."""
        errors = []

        # Check for negative prices
        price_cols = ['open', 'high', 'low', 'close']
        for col in price_cols:
            if (df[col] < 0).any():
                errors.append(f"Negative prices in {col}")

        # Check OHLC consistency
        if ((df['high'] < df['low']) |
            (df['high'] < df['open']) |
            (df['high'] < df['close']) |
            (df['low'] > df['open']) |
            (df['low'] > df['close'])).any():
            errors.append("OHLC inconsistencies found (high < low or invalid ranges)")

        return errors
```

## Database Schema

### options_ticks Table

```sql
CREATE TABLE options_ticks (
    timestamp TIMESTAMPTZ NOT NULL,
    underlying VARCHAR(20) NOT NULL,
    strike NUMERIC(10,2) NOT NULL,
    expiry DATE NOT NULL,
    option_type VARCHAR(2) NOT NULL,  -- CE or PE

    -- Market data
    open NUMERIC(10,2),
    high NUMERIC(10,2),
    low NUMERIC(10,2),
    close NUMERIC(10,2),
    volume BIGINT,
    open_interest BIGINT,
    bid NUMERIC(10,2),
    ask NUMERIC(10,2),
    implied_volatility NUMERIC(8,6),
    spot_price NUMERIC(10,2),

    -- Greeks (populated by separate pipeline)
    delta NUMERIC(8,6),
    gamma NUMERIC(8,6),
    theta NUMERIC(8,6),
    vega NUMERIC(8,6),
    rho NUMERIC(8,6),

    data_source VARCHAR(50),

    -- Primary key for upsert
    PRIMARY KEY (timestamp, underlying, strike, expiry, option_type)
);

-- Convert to hypertable
SELECT create_hypertable('options_ticks', 'timestamp');

-- Indexes for common queries
CREATE INDEX idx_options_underlying_expiry ON options_ticks (underlying, expiry);
CREATE INDEX idx_options_strike ON options_ticks (strike);
```

### spot_prices Table

```sql
CREATE TABLE spot_prices (
    timestamp TIMESTAMPTZ NOT NULL,
    underlying VARCHAR(20) NOT NULL,
    open NUMERIC(10,2),
    high NUMERIC(10,2),
    low NUMERIC(10,2),
    close NUMERIC(10,2),
    volume BIGINT,
    data_source VARCHAR(50),

    PRIMARY KEY (timestamp, underlying)
);

-- Convert to hypertable
SELECT create_hypertable('spot_prices', 'timestamp');

-- Index for joins with options data
CREATE INDEX idx_spot_underlying ON spot_prices (underlying, timestamp);
```

## Nautilus Catalog Generation

### Architecture

```python
class NautilusCatalogGenerator:
    """Generate Nautilus-compatible Parquet catalogs from database."""

    def __init__(self, db_url: str, output_dir: Path):
        self.engine = create_engine(db_url)
        self.output_dir = Path(output_dir)

    def generate_catalog(
        self,
        underlying: str = 'NIFTY',
        start_date: str = None,
        end_date: str = None
    ) -> Path:
        """
        Generate complete Nautilus catalog.

        Args:
            underlying: Underlying symbol (default: NIFTY)
            start_date: Start date (YYYY-MM-DD)
            end_date: End date (YYYY-MM-DD)

        Returns:
            Path to generated catalog directory
        """
        # Create catalog directory
        catalog_dir = self.output_dir / f"{underlying.lower()}-options"
        catalog_dir.mkdir(parents=True, exist_ok=True)

        # Step 1: Generate instruments file
        print("Generating instruments...")
        self._generate_instruments(catalog_dir, underlying, start_date, end_date)

        # Step 2: Generate bars
        print("Generating bars...")
        self._generate_bars(catalog_dir, underlying, start_date, end_date)

        print(f"✅ Catalog generated at: {catalog_dir}")
        return catalog_dir

    def _generate_instruments(
        self,
        catalog_dir: Path,
        underlying: str,
        start_date: str,
        end_date: str
    ):
        """Generate instruments.parquet file."""
        query = """
        SELECT DISTINCT
            CONCAT(underlying, '-',
                   TO_CHAR(expiry, 'YYMMDD'), '-',
                   strike::INTEGER, '-',
                   option_type) AS instrument_id,
            'OPTION' AS instrument_type,
            underlying,
            strike,
            expiry,
            CASE
                WHEN option_type = 'CE' THEN 'CALL'
                WHEN option_type = 'PE' THEN 'PUT'
            END AS option_type,
            75.0 AS multiplier,  -- NIFTY lot size
            'INR' AS currency
        FROM options_ticks
        WHERE underlying = %s
        """

        params = [underlying]

        if start_date:
            query += " AND timestamp >= %s"
            params.append(start_date)
        if end_date:
            query += " AND timestamp <= %s"
            params.append(end_date)

        query += " ORDER BY expiry, strike, option_type"

        df = pd.read_sql(query, self.engine, params=params)

        # Write to Parquet
        instruments_path = catalog_dir / "instruments.parquet"
        df.to_parquet(
            instruments_path,
            engine='pyarrow',
            compression='snappy',
            index=False
        )

        print(f"✅ Generated {len(df)} instruments")

    def _generate_bars(
        self,
        catalog_dir: Path,
        underlying: str,
        start_date: str,
        end_date: str
    ):
        """Generate bars for each instrument."""
        # Get list of instruments
        query = """
        SELECT DISTINCT
            underlying, strike, expiry, option_type
        FROM options_ticks
        WHERE underlying = %s
        """

        params = [underlying]
        if start_date:
            query += " AND timestamp >= %s"
            params.append(start_date)
        if end_date:
            query += " AND timestamp <= %s"
            params.append(end_date)

        instruments = pd.read_sql(query, self.engine, params=params)

        # Create bars directory
        bars_dir = catalog_dir / "bars"
        bars_dir.mkdir(exist_ok=True)

        total_instruments = len(instruments)

        for idx, row in instruments.iterrows():
            instrument_id = self._format_instrument_id(
                row['underlying'],
                row['expiry'],
                row['strike'],
                row['option_type']
            )

            # Generate 1H bars
            self._generate_instrument_bars(
                bars_dir,
                instrument_id,
                row['underlying'],
                row['strike'],
                row['expiry'],
                row['option_type'],
                '1H',
                start_date,
                end_date
            )

            # Generate 1D bars
            self._generate_instrument_bars(
                bars_dir,
                instrument_id,
                row['underlying'],
                row['strike'],
                row['expiry'],
                row['option_type'],
                '1D',
                start_date,
                end_date
            )

            if (idx + 1) % 10 == 0:
                print(f"Generated bars for {idx + 1}/{total_instruments} instruments...")

    def _generate_instrument_bars(
        self,
        bars_dir: Path,
        instrument_id: str,
        underlying: str,
        strike: float,
        expiry: datetime,
        option_type: str,
        timeframe: str,
        start_date: str,
        end_date: str
    ):
        """Generate bars for a single instrument."""
        # Query data
        query = """
        SELECT
            timestamp,
            open, high, low, close, volume, open_interest
        FROM options_ticks
        WHERE underlying = %s
          AND strike = %s
          AND expiry = %s
          AND option_type = %s
        """

        params = [underlying, strike, expiry, option_type]

        if start_date:
            query += " AND timestamp >= %s"
            params.append(start_date)
        if end_date:
            query += " AND timestamp <= %s"
            params.append(end_date)

        query += " ORDER BY timestamp"

        df = pd.read_sql(query, self.engine, params=params)

        if df.empty:
            return

        # Resample to target timeframe
        df = df.set_index('timestamp')
        resampled = df.resample(timeframe).agg({
            'open': 'first',
            'high': 'max',
            'low': 'min',
            'close': 'last',
            'volume': 'sum',
            'open_interest': 'last',
        }).dropna()

        resampled = resampled.reset_index()

        # Create instrument directory
        inst_dir = bars_dir / instrument_id
        inst_dir.mkdir(exist_ok=True)

        # Write Parquet file
        bars_path = inst_dir / f"{timeframe}.parquet"
        resampled.to_parquet(
            bars_path,
            engine='pyarrow',
            compression='snappy',
            index=False
        )

    def _format_instrument_id(
        self,
        underlying: str,
        expiry: datetime,
        strike: float,
        option_type: str
    ) -> str:
        """Format instrument ID for Nautilus."""
        expiry_str = expiry.strftime('%y%m%d')
        strike_int = int(strike)
        return f"{underlying}-{expiry_str}-{strike_int}-{option_type}"
```

## Performance Considerations

### 1. Bulk Import Optimization
- **Batch Size**: 1000 records per transaction
- **Connection Pooling**: Use SQLAlchemy connection pool
- **Upsert Strategy**: ON CONFLICT DO UPDATE for idempotency
- **Target**: > 1000 records/second

### 2. Memory Management
- **Streaming**: Process large CSV files in chunks
- **DataFrame Cleanup**: Delete DataFrames after use
- **Generator Pattern**: Use generators for file iteration

### 3. Parallel Processing
- **Multiprocessing**: Parse multiple CSV files in parallel
- **CPU Cores**: Use `multiprocessing.Pool` with `cpu_count()`

## Error Handling

### 1. CSV Parsing Errors
- **Invalid Ticker**: Log warning, skip file
- **Missing Columns**: Raise error, halt import
- **Malformed Data**: Log warning, skip record

### 2. Database Errors
- **Connection Failure**: Retry with exponential backoff
- **Constraint Violation**: Log warning, continue (upsert handles duplicates)
- **Transaction Failure**: Rollback, retry batch

### 3. Validation Errors
- **Price Validation**: Warn but don't halt (may be legitimate edge case)
- **Missing Data**: Warn, interpolate if possible
- **Timestamp Gaps**: Log warning, continue

## Testing Strategy

### 1. Unit Tests
- Ticker parser with various formats
- CSV parser with sample files
- Data validator with edge cases
- OHLC aggregator accuracy

### 2. Integration Tests
- End-to-end import with sample data
- Database round-trip (insert → query → verify)
- Catalog generation and verification

### 3. Performance Tests
- Measure import throughput (records/second)
- Monitor memory usage during large imports
- Test with 1M+ records

## Usage Example

```python
#!/usr/bin/env python3
"""Example usage of NSE import pipeline."""

from pathlib import Path
from src.data_pipeline.parsers.nse_parser import NSEOptionsCSVParser, NSESpotCSVParser
from src.data_pipeline.importers.database_importer import DatabaseImporter
from src.data_pipeline.catalog.nautilus_generator import NautilusCatalogGenerator
from src.data_pipeline.catalog.s3_uploader import S3CatalogUploader

def main():
    # Step 1: Parse options data
    print("=== Parsing Options Data ===")
    options_parser = NSEOptionsCSVParser()
    options_df = options_parser.parse_directory(Path("data/sample/options"))
    print(f"Parsed {len(options_df):,} options records")

    # Step 2: Parse spot data
    print("\n=== Parsing Spot Data ===")
    spot_parser = NSESpotCSVParser()
    spot_df = spot_parser.parse_file(Path("data/sample/niftyspot/nifty_data_min.csv"))
    print(f"Parsed {len(spot_df):,} spot records")

    # Step 3: Import to database
    print("\n=== Importing to Database ===")
    importer = DatabaseImporter()

    options_count = importer.import_options_data(options_df)
    print(f"✅ Imported {options_count:,} options records")

    spot_count = importer.import_spot_data(spot_df)
    print(f"✅ Imported {spot_count:,} spot records")

    # Step 4: Generate Nautilus catalog
    print("\n=== Generating Nautilus Catalog ===")
    catalog_gen = NautilusCatalogGenerator(
        db_url=importer.engine.url,
        output_dir=Path("/tmp/nautilus-catalogs")
    )
    catalog_dir = catalog_gen.generate_catalog(underlying='NIFTY')

    # Step 5: Upload to S3
    print("\n=== Uploading to S3 ===")
    uploader = S3CatalogUploader(
        bucket_name='synaptic-trading-data',
        prefix='nautilus-catalogs'
    )
    s3_url = uploader.upload_catalog(catalog_dir, catalog_name='nifty-options')
    print(f"✅ Uploaded to: {s3_url}")

if __name__ == '__main__':
    main()
```

## Change Log

- 2025-11-04: Initial design document created based on actual NSE CSV format
