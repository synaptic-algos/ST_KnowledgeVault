# Data Pipeline Architecture: NSE Options → Database → Nautilus Catalogs → S3

**Version**: 1.0.0
**Created**: 2025-11-04
**Status**: Architecture Proposal
**Dependencies**: EPIC-007, STRAT-001

---

## Overview

This document defines the data infrastructure required to import NSE historical options data, calculate Greeks, store in a database, and generate Nautilus-compatible catalogs for backtesting.

**Data Flow**:
```
NSE Historical Data (CSV/Parquet)
    ↓
[Data Importer] → Calculate Greeks (Black-Scholes)
    ↓
[Database] (PostgreSQL/TimescaleDB)
    ↓
[Nautilus Catalog Generator]
    ↓
[Parquet Files] → AWS S3 Buckets
    ↓
[Nautilus Backtest Engine]
```

---

## 1. Data Sources

### 1.1 NSE Historical Options Data (Given)

**Available Fields**:
- Instrument: NIFTY
- Strike Price
- Expiry Date
- Option Type (CE/PE)
- Date/Time
- Open, High, Low, Close
- Volume
- **Implied Volatility (IV)** ✅
- **Open Interest (OI)** ✅
- Bid Price
- Ask Price

**Missing Fields** (need to calculate):
- ❌ Delta
- ❌ Gamma
- ❌ Theta
- ❌ Vega
- ❌ Rho

**Format**: CSV or Parquet (assumed)

### 1.2 Underlying Spot Data (NIFTY50)

**Required for Greeks Calculation**:
- Spot price at each timestamp
- Source: NSE historical index data OR extract from ATM strike

---

## 2. Database Schema

### 2.1 Technology Choice: **TimescaleDB** (PostgreSQL extension)

**Why TimescaleDB**:
- ✅ Time-series optimized (options data is inherently time-series)
- ✅ PostgreSQL compatibility (mature ecosystem, SQL support)
- ✅ Hypertables for automatic partitioning by time
- ✅ Continuous aggregates for pre-computed metrics
- ✅ Compression for historical data storage efficiency
- ✅ Easy integration with Pandas/Parquet

### 2.2 Schema Design

#### Table 1: `options_ticks` (Hypertable)

```sql
CREATE TABLE options_ticks (
    -- Time dimension (primary partitioning key)
    timestamp TIMESTAMPTZ NOT NULL,

    -- Instrument identification
    underlying VARCHAR(20) NOT NULL,        -- 'NIFTY'
    strike NUMERIC(10,2) NOT NULL,          -- 25000.00
    expiry DATE NOT NULL,                   -- 2025-11-28
    option_type VARCHAR(2) NOT NULL,        -- 'CE' or 'PE'

    -- OHLCV data (from NSE)
    open NUMERIC(10,2),
    high NUMERIC(10,2),
    low NUMERIC(10,2),
    close NUMERIC(10,2),
    volume BIGINT,

    -- Bid/Ask spread (from NSE)
    bid NUMERIC(10,2),
    ask NUMERIC(10,2),

    -- Market data (from NSE)
    implied_volatility NUMERIC(8,6),        -- IV from NSE
    open_interest BIGINT,                   -- OI from NSE

    -- Greeks (calculated)
    delta NUMERIC(8,6),                     -- Calculated
    gamma NUMERIC(8,6),                     -- Calculated
    theta NUMERIC(8,6),                     -- Calculated
    vega NUMERIC(8,6),                      -- Calculated
    rho NUMERIC(8,6),                       -- Calculated

    -- Metadata
    data_source VARCHAR(50),                -- 'NSE', 'Calculated'
    inserted_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (timestamp, underlying, strike, expiry, option_type)
);

-- Convert to hypertable (time-series optimization)
SELECT create_hypertable('options_ticks', 'timestamp');

-- Indexes for common queries
CREATE INDEX idx_options_underlying_expiry
    ON options_ticks (underlying, expiry, timestamp DESC);

CREATE INDEX idx_options_strike_type
    ON options_ticks (strike, option_type, timestamp DESC);

-- Enable compression for old data (>30 days)
ALTER TABLE options_ticks SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'underlying, strike, expiry, option_type'
);

SELECT add_compression_policy('options_ticks', INTERVAL '30 days');
```

#### Table 2: `spot_prices` (Hypertable)

```sql
CREATE TABLE spot_prices (
    timestamp TIMESTAMPTZ NOT NULL,
    underlying VARCHAR(20) NOT NULL,        -- 'NIFTY'
    spot_price NUMERIC(10,2) NOT NULL,

    -- OHLCV for spot
    open NUMERIC(10,2),
    high NUMERIC(10,2),
    low NUMERIC(10,2),
    close NUMERIC(10,2),
    volume BIGINT,

    PRIMARY KEY (timestamp, underlying)
);

SELECT create_hypertable('spot_prices', 'timestamp');
```

#### Table 3: `options_metadata`

```sql
CREATE TABLE options_metadata (
    underlying VARCHAR(20) NOT NULL,
    expiry DATE NOT NULL,
    lot_size INT NOT NULL,                  -- 75 for NIFTY
    contract_multiplier INT NOT NULL,       -- 1 for index options
    tick_size NUMERIC(4,2) NOT NULL,        -- 0.05 for NIFTY

    PRIMARY KEY (underlying, expiry)
);
```

### 2.3 Continuous Aggregates (Pre-computed Views)

#### Aggregate 1: Hourly Options Bars

```sql
CREATE MATERIALIZED VIEW options_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', timestamp) AS hour,
    underlying,
    strike,
    expiry,
    option_type,
    FIRST(open, timestamp) AS open,
    MAX(high) AS high,
    MIN(low) AS low,
    LAST(close, timestamp) AS close,
    SUM(volume) AS volume,
    LAST(bid, timestamp) AS bid,
    LAST(ask, timestamp) AS ask,
    LAST(implied_volatility, timestamp) AS implied_volatility,
    LAST(open_interest, timestamp) AS open_interest,
    LAST(delta, timestamp) AS delta,
    LAST(gamma, timestamp) AS gamma,
    LAST(theta, timestamp) AS theta,
    LAST(vega, timestamp) AS vega,
    LAST(rho, timestamp) AS rho
FROM options_ticks
GROUP BY hour, underlying, strike, expiry, option_type;

-- Refresh policy (update every hour)
SELECT add_continuous_aggregate_policy('options_hourly',
    start_offset => INTERVAL '3 hours',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');
```

#### Aggregate 2: Daily Options Bars

```sql
CREATE MATERIALIZED VIEW options_daily
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', timestamp) AS day,
    underlying,
    strike,
    expiry,
    option_type,
    FIRST(open, timestamp) AS open,
    MAX(high) AS high,
    MIN(low) AS low,
    LAST(close, timestamp) AS close,
    SUM(volume) AS volume,
    LAST(implied_volatility, timestamp) AS implied_volatility,
    LAST(open_interest, timestamp) AS open_interest,
    LAST(delta, timestamp) AS delta
FROM options_ticks
GROUP BY day, underlying, strike, expiry, option_type;
```

---

## 3. Data Importer Architecture

### 3.1 Component Structure

```
src/data_pipeline/
├── __init__.py
├── importers/
│   ├── __init__.py
│   ├── nse_importer.py           # Read NSE CSV/Parquet files
│   ├── spot_importer.py          # Import underlying spot data
│   └── base_importer.py          # Abstract importer base class
├── calculators/
│   ├── __init__.py
│   ├── greeks_calculator.py      # Black-Scholes Greeks
│   └── black_scholes.py          # Core BS model
├── database/
│   ├── __init__.py
│   ├── connection.py             # DB connection pool
│   ├── models.py                 # SQLAlchemy models
│   └── bulk_insert.py            # Efficient bulk inserts
├── validators/
│   ├── __init__.py
│   └── data_validator.py         # Data quality checks
└── cli/
    ├── __init__.py
    └── import_cli.py              # CLI for import operations
```

### 3.2 NSE Data Importer

```python
# src/data_pipeline/importers/nse_importer.py

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Iterator

import pandas as pd
from sqlalchemy.orm import Session

from ..calculators.greeks_calculator import GreeksCalculator
from ..database.models import OptionsTick, SpotPrice
from ..validators.data_validator import NSEDataValidator


@dataclass
class NSEOptionsRecord:
    """Single NSE options tick record."""
    timestamp: datetime
    underlying: str
    strike: float
    expiry: datetime
    option_type: str  # 'CE' or 'PE'
    open: float
    high: float
    low: float
    close: float
    volume: int
    bid: float
    ask: float
    implied_volatility: float
    open_interest: int


class NSEOptionsImporter:
    """Import NSE options data and calculate Greeks."""

    def __init__(
        self,
        db_session: Session,
        greeks_calculator: GreeksCalculator,
        validator: NSEDataValidator,
    ):
        self.db = db_session
        self.greeks_calc = greeks_calculator
        self.validator = validator

    def import_from_csv(
        self,
        file_path: Path,
        spot_data: pd.DataFrame,  # NIFTY spot prices
        batch_size: int = 10000,
    ) -> int:
        """
        Import NSE options data from CSV.

        Args:
            file_path: Path to NSE CSV file
            spot_data: DataFrame with spot prices (for Greeks calculation)
            batch_size: Records per batch insert

        Returns:
            Number of records imported
        """
        records_imported = 0

        # Read NSE data
        df = pd.read_csv(file_path, parse_dates=['timestamp', 'expiry'])

        # Validate data quality
        validation_errors = self.validator.validate(df)
        if validation_errors:
            raise ValueError(f"Data validation failed: {validation_errors}")

        # Process in batches
        for batch in self._batch_records(df, batch_size):
            # Calculate Greeks for batch
            batch_with_greeks = self._calculate_greeks_batch(batch, spot_data)

            # Bulk insert to database
            self.db.bulk_insert_mappings(OptionsTick, batch_with_greeks)
            self.db.commit()

            records_imported += len(batch_with_greeks)
            print(f"Imported {records_imported} records...")

        return records_imported

    def _calculate_greeks_batch(
        self,
        batch: pd.DataFrame,
        spot_data: pd.DataFrame,
    ) -> list[dict]:
        """Calculate Greeks for batch of options records."""
        records_with_greeks = []

        for _, row in batch.iterrows():
            # Get spot price at this timestamp
            spot_price = self._get_spot_price(
                timestamp=row['timestamp'],
                spot_data=spot_data,
            )

            # Calculate Greeks using Black-Scholes
            greeks = self.greeks_calc.calculate(
                spot=spot_price,
                strike=row['strike'],
                time_to_expiry=self._days_to_expiry(row['timestamp'], row['expiry']),
                implied_volatility=row['implied_volatility'],
                option_type=row['option_type'],
                risk_free_rate=0.065,  # RBI repo rate (configurable)
            )

            # Combine NSE data + calculated Greeks
            record = {
                'timestamp': row['timestamp'],
                'underlying': row['underlying'],
                'strike': row['strike'],
                'expiry': row['expiry'],
                'option_type': row['option_type'],
                'open': row['open'],
                'high': row['high'],
                'low': row['low'],
                'close': row['close'],
                'volume': row['volume'],
                'bid': row['bid'],
                'ask': row['ask'],
                'implied_volatility': row['implied_volatility'],
                'open_interest': row['open_interest'],
                'delta': greeks.delta,
                'gamma': greeks.gamma,
                'theta': greeks.theta,
                'vega': greeks.vega,
                'rho': greeks.rho,
                'data_source': 'NSE',
            }

            records_with_greeks.append(record)

        return records_with_greeks

    def _get_spot_price(self, timestamp: datetime, spot_data: pd.DataFrame) -> float:
        """Get NIFTY spot price at given timestamp."""
        # Find closest timestamp in spot data
        spot_row = spot_data[spot_data['timestamp'] == timestamp]
        if spot_row.empty:
            # Fallback: nearest timestamp (forward fill)
            spot_row = spot_data[spot_data['timestamp'] <= timestamp].tail(1)

        return float(spot_row['spot_price'].iloc[0])

    def _days_to_expiry(self, current_date: datetime, expiry: datetime) -> float:
        """Calculate days to expiry (in years for BS model)."""
        days = (expiry - current_date).days
        return days / 365.0

    def _batch_records(self, df: pd.DataFrame, batch_size: int) -> Iterator[pd.DataFrame]:
        """Yield dataframe in batches."""
        for i in range(0, len(df), batch_size):
            yield df.iloc[i:i+batch_size]
```

### 3.3 Greeks Calculator (Black-Scholes)

```python
# src/data_pipeline/calculators/greeks_calculator.py

from dataclasses import dataclass
from math import exp, log, sqrt

from scipy.stats import norm


@dataclass
class Greeks:
    """Calculated option Greeks."""
    delta: float
    gamma: float
    theta: float
    vega: float
    rho: float


class GreeksCalculator:
    """Calculate option Greeks using Black-Scholes model."""

    def calculate(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,  # in years
        implied_volatility: float,  # annualized
        option_type: str,  # 'CE' or 'PE'
        risk_free_rate: float = 0.065,  # RBI repo rate
    ) -> Greeks:
        """
        Calculate all Greeks using Black-Scholes formula.

        Args:
            spot: Current underlying price
            strike: Strike price
            time_to_expiry: Time to expiry in years
            implied_volatility: Annualized IV (e.g., 0.15 for 15%)
            option_type: 'CE' for call, 'PE' for put
            risk_free_rate: Risk-free rate (annual)

        Returns:
            Greeks object with delta, gamma, theta, vega, rho
        """
        # Handle edge case: expiry today or past
        if time_to_expiry <= 0:
            return self._intrinsic_greeks(spot, strike, option_type)

        # Black-Scholes d1 and d2
        d1 = (
            log(spot / strike) + (risk_free_rate + 0.5 * implied_volatility ** 2) * time_to_expiry
        ) / (implied_volatility * sqrt(time_to_expiry))

        d2 = d1 - implied_volatility * sqrt(time_to_expiry)

        # Standard normal CDF and PDF
        N_d1 = norm.cdf(d1)
        N_d2 = norm.cdf(d2)
        n_d1 = norm.pdf(d1)  # PDF for gamma, vega, theta

        # Calculate Greeks
        if option_type == 'CE':  # Call option
            delta = N_d1
            theta = (
                -(spot * n_d1 * implied_volatility) / (2 * sqrt(time_to_expiry))
                - risk_free_rate * strike * exp(-risk_free_rate * time_to_expiry) * N_d2
            ) / 365  # Daily theta
            rho = (
                strike * time_to_expiry * exp(-risk_free_rate * time_to_expiry) * N_d2
            ) / 100  # Per 1% change
        else:  # Put option
            delta = N_d1 - 1
            theta = (
                -(spot * n_d1 * implied_volatility) / (2 * sqrt(time_to_expiry))
                + risk_free_rate * strike * exp(-risk_free_rate * time_to_expiry) * (1 - N_d2)
            ) / 365  # Daily theta
            rho = (
                -strike * time_to_expiry * exp(-risk_free_rate * time_to_expiry) * (1 - N_d2)
            ) / 100  # Per 1% change

        # Gamma and Vega are same for calls and puts
        gamma = n_d1 / (spot * implied_volatility * sqrt(time_to_expiry))
        vega = spot * n_d1 * sqrt(time_to_expiry) / 100  # Per 1% change in IV

        return Greeks(
            delta=round(delta, 6),
            gamma=round(gamma, 6),
            theta=round(theta, 6),
            vega=round(vega, 6),
            rho=round(rho, 6),
        )

    def _intrinsic_greeks(self, spot: float, strike: float, option_type: str) -> Greeks:
        """Greeks at expiry (intrinsic value only)."""
        if option_type == 'CE':
            delta = 1.0 if spot > strike else 0.0
        else:
            delta = -1.0 if spot < strike else 0.0

        return Greeks(delta=delta, gamma=0.0, theta=0.0, vega=0.0, rho=0.0)
```

---

## 4. Nautilus Catalog Generation

### 4.1 Nautilus Catalog Structure

Nautilus uses **Parquet files** organized by instrument and bar type:

```
s3://synaptic-trading-data/
└── nautilus-catalogs/
    └── nifty-options/
        ├── NIFTY-25000-CE-2025-11-28/
        │   ├── 1H.parquet       # Hourly bars
        │   ├── 1D.parquet       # Daily bars
        │   └── tick.parquet     # Tick data (optional)
        ├── NIFTY-25000-PE-2025-11-28/
        │   ├── 1H.parquet
        │   └── 1D.parquet
        └── catalog.json         # Catalog metadata
```

### 4.2 Catalog Generator

```python
# src/data_pipeline/catalog/nautilus_catalog_generator.py

from pathlib import Path
from typing import List

import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
from sqlalchemy.orm import Session

from ..database.models import OptionsHourly, OptionsDaily


class NautilusCatalogGenerator:
    """Generate Nautilus-compatible Parquet catalogs from database."""

    def __init__(self, db_session: Session, output_dir: Path):
        self.db = db_session
        self.output_dir = output_dir

    def generate_catalog(
        self,
        underlying: str,
        start_date: datetime,
        end_date: datetime,
        bar_types: List[str] = ['1H', '1D'],
    ) -> Path:
        """
        Generate Nautilus catalog from database.

        Args:
            underlying: 'NIFTY'
            start_date: Start of data range
            end_date: End of data range
            bar_types: ['1H', '1D', 'tick']

        Returns:
            Path to generated catalog directory
        """
        catalog_dir = self.output_dir / f"{underlying.lower()}-options"
        catalog_dir.mkdir(parents=True, exist_ok=True)

        # Get all unique options contracts in date range
        contracts = self._get_contracts(underlying, start_date, end_date)

        for contract in contracts:
            instrument_dir = catalog_dir / self._instrument_id(contract)
            instrument_dir.mkdir(exist_ok=True)

            # Generate each bar type
            for bar_type in bar_types:
                self._generate_bar_file(
                    contract=contract,
                    bar_type=bar_type,
                    output_path=instrument_dir / f"{bar_type}.parquet",
                )

        # Generate catalog metadata
        self._generate_catalog_metadata(catalog_dir, contracts)

        return catalog_dir

    def _generate_bar_file(
        self,
        contract: dict,
        bar_type: str,
        output_path: Path,
    ) -> None:
        """Generate single Parquet file for instrument + bar type."""
        if bar_type == '1H':
            # Query hourly aggregate
            query = self.db.query(OptionsHourly).filter(
                OptionsHourly.underlying == contract['underlying'],
                OptionsHourly.strike == contract['strike'],
                OptionsHourly.expiry == contract['expiry'],
                OptionsHourly.option_type == contract['option_type'],
            )
        elif bar_type == '1D':
            # Query daily aggregate
            query = self.db.query(OptionsDaily).filter(
                OptionsDaily.underlying == contract['underlying'],
                OptionsDaily.strike == contract['strike'],
                OptionsDaily.expiry == contract['expiry'],
                OptionsDaily.option_type == contract['option_type'],
            )
        else:
            raise ValueError(f"Unsupported bar type: {bar_type}")

        # Convert to DataFrame
        df = pd.read_sql(query.statement, self.db.bind)

        # Transform to Nautilus schema
        nautilus_df = self._transform_to_nautilus_schema(df, bar_type)

        # Write Parquet
        table = pa.Table.from_pandas(nautilus_df)
        pq.write_table(table, output_path, compression='snappy')

    def _transform_to_nautilus_schema(self, df: pd.DataFrame, bar_type: str) -> pd.DataFrame:
        """Transform database schema to Nautilus bar schema."""
        # Nautilus bar schema
        nautilus_df = pd.DataFrame({
            'ts_event': pd.to_datetime(df['hour'] if bar_type == '1H' else df['day']),
            'ts_init': pd.to_datetime(df['hour'] if bar_type == '1H' else df['day']),
            'open': df['open'],
            'high': df['high'],
            'low': df['low'],
            'close': df['close'],
            'volume': df['volume'],
            'bid': df.get('bid', df['close']),  # Use close as fallback
            'ask': df.get('ask', df['close']),
        })

        # Add custom fields (Greeks)
        nautilus_df['delta'] = df['delta']
        nautilus_df['gamma'] = df.get('gamma', 0.0)
        nautilus_df['theta'] = df.get('theta', 0.0)
        nautilus_df['vega'] = df.get('vega', 0.0)
        nautilus_df['iv'] = df['implied_volatility']
        nautilus_df['oi'] = df['open_interest']

        return nautilus_df

    def _instrument_id(self, contract: dict) -> str:
        """Generate Nautilus instrument ID."""
        # Format: NIFTY-25000-CE-2025-11-28
        return (
            f"{contract['underlying']}-"
            f"{int(contract['strike'])}-"
            f"{contract['option_type']}-"
            f"{contract['expiry'].strftime('%Y-%m-%d')}"
        )

    def _get_contracts(
        self,
        underlying: str,
        start_date: datetime,
        end_date: datetime,
    ) -> List[dict]:
        """Get all unique options contracts in date range."""
        query = f"""
        SELECT DISTINCT
            underlying,
            strike,
            expiry,
            option_type
        FROM options_ticks
        WHERE underlying = '{underlying}'
          AND timestamp >= '{start_date}'
          AND timestamp <= '{end_date}'
        ORDER BY expiry, strike, option_type
        """

        df = pd.read_sql(query, self.db.bind)
        return df.to_dict('records')

    def _generate_catalog_metadata(self, catalog_dir: Path, contracts: List[dict]) -> None:
        """Generate catalog.json metadata file."""
        import json

        metadata = {
            'catalog_version': '1.0',
            'underlying': contracts[0]['underlying'],
            'total_instruments': len(contracts),
            'date_range': {
                'start': min(c['expiry'] for c in contracts).isoformat(),
                'end': max(c['expiry'] for c in contracts).isoformat(),
            },
            'instruments': [self._instrument_id(c) for c in contracts],
        }

        with open(catalog_dir / 'catalog.json', 'w') as f:
            json.dump(metadata, f, indent=2)
```

### 4.3 S3 Upload

```python
# src/data_pipeline/catalog/s3_uploader.py

import boto3
from pathlib import Path


class S3CatalogUploader:
    """Upload Nautilus catalogs to S3."""

    def __init__(self, bucket_name: str, aws_region: str = 'ap-south-1'):
        self.s3 = boto3.client('s3', region_name=aws_region)
        self.bucket = bucket_name

    def upload_catalog(self, local_catalog_dir: Path, s3_prefix: str = 'nautilus-catalogs'):
        """
        Upload entire catalog directory to S3.

        Args:
            local_catalog_dir: Local catalog directory (e.g., /tmp/nifty-options)
            s3_prefix: S3 prefix (e.g., 'nautilus-catalogs')
        """
        for file_path in local_catalog_dir.rglob('*'):
            if file_path.is_file():
                # Calculate S3 key
                relative_path = file_path.relative_to(local_catalog_dir.parent)
                s3_key = f"{s3_prefix}/{relative_path}"

                # Upload
                self.s3.upload_file(
                    Filename=str(file_path),
                    Bucket=self.bucket,
                    Key=s3_key,
                )

                print(f"Uploaded: s3://{self.bucket}/{s3_key}")
```

---

## 5. CLI Tool

```python
# src/data_pipeline/cli/import_cli.py

import click
from datetime import datetime
from pathlib import Path

from ..importers.nse_importer import NSEOptionsImporter
from ..calculators.greeks_calculator import GreeksCalculator
from ..validators.data_validator import NSEDataValidator
from ..catalog.nautilus_catalog_generator import NautilusCatalogGenerator
from ..catalog.s3_uploader import S3CatalogUploader
from ..database.connection import get_db_session


@click.group()
def cli():
    """SynapticTrading Data Pipeline CLI."""
    pass


@cli.command()
@click.argument('csv_file', type=click.Path(exists=True))
@click.argument('spot_csv', type=click.Path(exists=True))
@click.option('--batch-size', default=10000, help='Records per batch')
def import_nse(csv_file, spot_csv, batch_size):
    """Import NSE options data from CSV."""
    db = get_db_session()
    greeks_calc = GreeksCalculator()
    validator = NSEDataValidator()

    importer = NSEOptionsImporter(db, greeks_calc, validator)

    # Load spot data
    import pandas as pd
    spot_data = pd.read_csv(spot_csv, parse_dates=['timestamp'])

    # Import
    count = importer.import_from_csv(
        file_path=Path(csv_file),
        spot_data=spot_data,
        batch_size=batch_size,
    )

    click.echo(f"✅ Imported {count} records")


@cli.command()
@click.option('--start-date', required=True, help='YYYY-MM-DD')
@click.option('--end-date', required=True, help='YYYY-MM-DD')
@click.option('--output-dir', default='/tmp/catalogs', help='Output directory')
@click.option('--bar-types', default='1H,1D', help='Comma-separated bar types')
def generate_catalog(start_date, end_date, output_dir, bar_types):
    """Generate Nautilus catalog from database."""
    db = get_db_session()
    generator = NautilusCatalogGenerator(db, Path(output_dir))

    catalog_dir = generator.generate_catalog(
        underlying='NIFTY',
        start_date=datetime.fromisoformat(start_date),
        end_date=datetime.fromisoformat(end_date),
        bar_types=bar_types.split(','),
    )

    click.echo(f"✅ Generated catalog: {catalog_dir}")


@cli.command()
@click.argument('catalog_dir', type=click.Path(exists=True))
@click.option('--bucket', required=True, help='S3 bucket name')
@click.option('--prefix', default='nautilus-catalogs', help='S3 prefix')
def upload_s3(catalog_dir, bucket, prefix):
    """Upload catalog to S3."""
    uploader = S3CatalogUploader(bucket_name=bucket)
    uploader.upload_catalog(Path(catalog_dir), s3_prefix=prefix)

    click.echo(f"✅ Uploaded to s3://{bucket}/{prefix}")


if __name__ == '__main__':
    cli()
```

---

## 6. Usage Workflow

### Step 1: Import NSE Data

```bash
# Import options data + calculate Greeks
python -m src.data_pipeline.cli.import_cli import-nse \
    data/nse_options_2024.csv \
    data/nifty_spot_2024.csv \
    --batch-size 10000

# Output: ✅ Imported 5,234,891 records
```

### Step 2: Generate Nautilus Catalog

```bash
# Generate catalog for backtest date range
python -m src.data_pipeline.cli.import_cli generate-catalog \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --output-dir /tmp/catalogs \
    --bar-types 1H,1D

# Output: ✅ Generated catalog: /tmp/catalogs/nifty-options
```

### Step 3: Upload to S3

```bash
# Upload to AWS S3
python -m src.data_pipeline.cli.import_cli upload-s3 \
    /tmp/catalogs/nifty-options \
    --bucket synaptic-trading-data \
    --prefix nautilus-catalogs

# Output: ✅ Uploaded to s3://synaptic-trading-data/nautilus-catalogs
```

### Step 4: Use in Nautilus Backtest

```python
# In backtest script
from nautilus_trader.persistence.catalog import ParquetDataCatalog

catalog = ParquetDataCatalog('s3://synaptic-trading-data/nautilus-catalogs/nifty-options')

# Load data for specific instrument
bars = catalog.bars(
    instrument_id='NIFTY-25000-CE-2025-11-28',
    bar_type='1H',
)
```

---

## 7. Sprint 0: Data Pipeline Implementation

### Sprint 0 Timeline: **2 weeks**

**Goal**: Import NSE data, calculate Greeks, store in TimescaleDB, generate Nautilus catalogs

**Stories**:
1. **STORY-000-001**: Set up TimescaleDB database + schema
2. **STORY-000-002**: Implement NSE data importer + Greeks calculator
3. **STORY-000-003**: Data validator (check for missing fields, outliers)
4. **STORY-000-004**: Bulk import script for historical data (1+ years)
5. **STORY-000-005**: Nautilus catalog generator (Parquet files)
6. **STORY-000-006**: S3 upload automation
7. **STORY-000-007**: CLI tool for import/catalog/upload workflow

**Acceptance Criteria**:
- [ ] TimescaleDB database running (local or cloud)
- [ ] 1+ years of NSE options data imported
- [ ] Greeks calculated for all records (delta, gamma, theta, vega, rho)
- [ ] Nautilus catalogs generated for 2024 data
- [ ] Catalogs uploaded to S3 bucket
- [ ] CLI tool works end-to-end

**Deliverables**:
- `src/data_pipeline/` (complete)
- TimescaleDB schema scripts
- Sample data import (1 month) for testing
- Full data import (1+ years)
- Nautilus catalog on S3

---

## 8. Dependencies

```toml
[dependencies]
# Database
sqlalchemy = "^2.0.0"
psycopg2-binary = "^2.9.0"     # PostgreSQL driver
asyncpg = "^0.29.0"            # Async PostgreSQL (optional)

# TimescaleDB
# (No special Python library needed - uses PostgreSQL driver)

# Data processing
pandas = "^2.0.0"
pyarrow = "^14.0.0"            # Parquet support
numpy = "^1.24.0"

# Greeks calculation
scipy = "^1.10.0"              # For norm.cdf, norm.pdf

# AWS
boto3 = "^1.28.0"              # S3 upload

# CLI
click = "^8.1.0"

# Validation
pydantic = "^2.0.0"            # Data validation
```

---

## 9. Next Steps

**Immediate**:
1. Set up TimescaleDB (local or AWS RDS)
2. Get NSE historical data files (CSV/Parquet format)
3. Create S3 bucket for Nautilus catalogs

**Sprint 0 (Week 1-2)**:
1. Implement database schema
2. Build NSE importer + Greeks calculator
3. Import historical data (1+ years)
4. Generate Nautilus catalogs
5. Upload to S3

**After Sprint 0**:
- Proceed with EPIC-007 Sprint 1 (domain model)
- Use S3 catalogs for Nautilus backtests

---

**Ready to proceed with Sprint 0?**
