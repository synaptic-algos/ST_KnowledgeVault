---
id: DESIGN-DataPipeline-Greeks
title: "Black-Scholes Greeks Calculation & Storage Design"
status: draft
artifact_type: design
created_at: 2025-11-04T00:00:00Z
updated_at: 2025-11-04T00:00:00Z
related_story:
  - STORY-006-01
related_feature:
  - FEATURE-006
tags:
  - greeks
  - black-scholes
  - options-pricing
  - timescaledb
  - nautilus
---

# DESIGN: Black-Scholes Greeks Calculation & Storage

**Story**: [STORY-006-01: NSE Data Import & Greeks Calculation](../EPICS/EPIC-007-StrategyLifecycle/FEATURE-006-DataPipeline/STORY-001-NSEDataImport/README.md)

**Feature**: [FEATURE-006: Data Pipeline](../EPICS/EPIC-007-StrategyLifecycle/FEATURE-006-DataPipeline/README.md)

## Overview

This design document specifies the architecture for calculating Black-Scholes Greeks (delta, gamma, theta, vega, rho) for historical options data and storing them in both TimescaleDB and Nautilus Parquet catalogs.

### Scope

**In Scope**:
- Black-Scholes mathematical model implementation
- Greeks calculation for all five Greeks
- Database update pipeline (UPDATE existing records with Greeks)
- Nautilus Parquet schema extension
- Greeks validation and testing
- Performance optimization (multiprocessing)

**Out of Scope**:
- Alternative pricing models (Binomial, Monte Carlo)
- Exotic options Greeks
- Real-time Greeks calculation
- Implied volatility calculation (assumes IV is provided in data)
- Greeks risk management system

## Mathematical Foundation

### Black-Scholes Model

The Black-Scholes model is used to price European-style options and calculate Greeks. NSE NIFTY options are European-style, making this model appropriate.

#### Model Assumptions

1. **European Exercise**: Options can only be exercised at expiry
2. **No Dividends**: NIFTY index options (dividend impact minimal for short-dated)
3. **Constant Volatility**: Implied volatility from market data
4. **Log-normal Distribution**: Underlying price follows geometric Brownian motion
5. **No Transaction Costs**: Frictionless market
6. **Constant Risk-free Rate**: Use Indian government bond rate (~5%)

#### Model Inputs

| Parameter | Symbol | Source | Example |
|-----------|--------|--------|---------|
| Spot Price | S | NIFTY spot price | 21750.00 |
| Strike Price | K | Contract specification | 22000.00 |
| Time to Expiry | T | Days until expiry / 365 | 0.0822 (30 days) |
| Volatility | σ | Implied volatility from market | 0.15 (15%) |
| Risk-free Rate | r | Indian govt bond rate | 0.05 (5%) |
| Option Type | - | CE or PE | CE |

### Core Formulas

#### d1 and d2

These are intermediate calculations used in all Greeks formulas:

```
d1 = [ln(S/K) + (r + σ²/2) × T] / (σ × √T)

d2 = d1 - σ × √T
```

Where:
- ln() = natural logarithm
- S/K = moneyness ratio
- σ² = variance
- √T = square root of time

#### Cumulative Distribution Functions

**N(x)**: Cumulative standard normal distribution
- Probability that a standard normal variable ≤ x
- Implementation: `scipy.stats.norm.cdf(x)`

**φ(x)**: Standard normal probability density function
- PDF of standard normal distribution
- Implementation: `scipy.stats.norm.pdf(x)`
- Formula: φ(x) = (1/√(2π)) × e^(-x²/2)

### Greeks Formulas

#### 1. Delta (Δ)

**Definition**: Rate of change of option price with respect to underlying price

**Call Option**:
```
Δ_call = N(d1)
```

**Put Option**:
```
Δ_put = N(d1) - 1
```

**Expected Ranges**:
- Call Delta: [0, 1]
  - Deep OTM: ≈ 0
  - ATM: ≈ 0.5
  - Deep ITM: ≈ 1
- Put Delta: [-1, 0]
  - Deep OTM: ≈ 0
  - ATM: ≈ -0.5
  - Deep ITM: ≈ -1

**Interpretation**: A delta of 0.3 means option price changes by ₹0.30 for every ₹1 change in underlying

**Critical for STRAT-001**: Weekly hedge uses ±0.1 delta strikes

#### 2. Gamma (Γ)

**Definition**: Rate of change of delta with respect to underlying price

**Formula (same for call and put)**:
```
Γ = φ(d1) / (S × σ × √T)
```

**Expected Range**:
- Gamma > 0 (always positive for long options)
- Maximum at ATM
- Approaches 0 for deep ITM/OTM

**Interpretation**: Measures delta acceleration; high gamma = delta changes rapidly

#### 3. Theta (Θ)

**Definition**: Rate of change of option price with respect to time (time decay)

**Call Option**:
```
Θ_call = - (S × φ(d1) × σ) / (2 × √T) - r × K × e^(-r×T) × N(d2)
```

**Put Option**:
```
Θ_put = - (S × φ(d1) × σ) / (2 × √T) + r × K × e^(-r×T) × N(-d2)
```

**Expected Range**:
- Typically negative for long options (time decay)
- Measured per day: divide by 365 for daily theta

**Interpretation**: Theta of -5 means option loses ₹5 in value per day (all else equal)

#### 4. Vega (ν)

**Definition**: Rate of change of option price with respect to volatility

**Formula (same for call and put)**:
```
ν = S × φ(d1) × √T
```

**Expected Range**:
- Vega > 0 (always positive for long options)
- Maximum at ATM
- Typically scaled to 1% volatility change (divide by 100)

**Interpretation**: Vega of 12 means option price increases by ₹12 for 1% increase in IV

#### 5. Rho (ρ)

**Definition**: Rate of change of option price with respect to interest rate

**Call Option**:
```
ρ_call = K × T × e^(-r×T) × N(d2)
```

**Put Option**:
```
ρ_put = -K × T × e^(-r×T) × N(-d2)
```

**Expected Range**:
- Call: Rho > 0
- Put: Rho < 0
- Typically scaled to 1% rate change (divide by 100)

**Interpretation**: Less important for short-dated options; more relevant for LEAPS

## Python Implementation

### 1. Black-Scholes Core Model

```python
"""
Black-Scholes option pricing model and Greeks calculation.

This module implements the Black-Scholes model for European options,
providing accurate Greeks calculation for NSE NIFTY options.
"""

import numpy as np
from scipy.stats import norm
from typing import NamedTuple
from datetime import datetime, date


class GreeksResult(NamedTuple):
    """Container for calculated Greeks."""
    delta: float
    gamma: float
    theta: float
    vega: float
    rho: float


class BlackScholesModel:
    """
    Black-Scholes option pricing model.

    Calculates option prices and Greeks for European-style options
    using the Black-Scholes formula.

    Attributes:
        risk_free_rate: Annual risk-free rate (default: 0.05 for India)
    """

    def __init__(self, risk_free_rate: float = 0.05):
        """
        Initialize Black-Scholes model.

        Args:
            risk_free_rate: Annual risk-free rate (e.g., 0.05 for 5%)
        """
        self.risk_free_rate = risk_free_rate

    def _calculate_d1_d2(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        volatility: float
    ) -> tuple[float, float]:
        """
        Calculate d1 and d2 parameters.

        Args:
            spot: Current underlying price
            strike: Option strike price
            time_to_expiry: Time to expiry in years
            volatility: Annualized volatility (e.g., 0.15 for 15%)

        Returns:
            Tuple of (d1, d2)
        """
        # Handle edge cases
        if time_to_expiry <= 0:
            time_to_expiry = 1 / 365  # Minimum 1 day
        if volatility <= 0:
            volatility = 0.01  # Minimum 1% volatility
        if spot <= 0:
            raise ValueError(f"Spot price must be positive: {spot}")
        if strike <= 0:
            raise ValueError(f"Strike price must be positive: {strike}")

        # Calculate d1
        d1 = (
            np.log(spot / strike)
            + (self.risk_free_rate + 0.5 * volatility ** 2) * time_to_expiry
        ) / (volatility * np.sqrt(time_to_expiry))

        # Calculate d2
        d2 = d1 - volatility * np.sqrt(time_to_expiry)

        return d1, d2

    def calculate_greeks(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        volatility: float,
        option_type: str
    ) -> GreeksResult:
        """
        Calculate all Greeks for an option.

        Args:
            spot: Current underlying price
            strike: Option strike price
            time_to_expiry: Time to expiry in years
            volatility: Annualized implied volatility
            option_type: 'CE' for call, 'PE' for put

        Returns:
            GreeksResult with all five Greeks

        Raises:
            ValueError: If option_type is not 'CE' or 'PE'
        """
        if option_type not in ('CE', 'PE'):
            raise ValueError(f"Invalid option type: {option_type}. Must be 'CE' or 'PE'")

        # Calculate d1 and d2
        d1, d2 = self._calculate_d1_d2(spot, strike, time_to_expiry, volatility)

        # Calculate Greeks
        delta = self._calculate_delta(d1, option_type)
        gamma = self._calculate_gamma(spot, d1, volatility, time_to_expiry)
        theta = self._calculate_theta(
            spot, strike, d1, d2, volatility, time_to_expiry, option_type
        )
        vega = self._calculate_vega(spot, d1, time_to_expiry)
        rho = self._calculate_rho(strike, d2, time_to_expiry, option_type)

        return GreeksResult(
            delta=delta,
            gamma=gamma,
            theta=theta,
            vega=vega,
            rho=rho
        )

    def _calculate_delta(self, d1: float, option_type: str) -> float:
        """Calculate delta."""
        if option_type == 'CE':
            return norm.cdf(d1)
        else:  # PE
            return norm.cdf(d1) - 1

    def _calculate_gamma(
        self,
        spot: float,
        d1: float,
        volatility: float,
        time_to_expiry: float
    ) -> float:
        """Calculate gamma (same for call and put)."""
        return norm.pdf(d1) / (spot * volatility * np.sqrt(time_to_expiry))

    def _calculate_theta(
        self,
        spot: float,
        strike: float,
        d1: float,
        d2: float,
        volatility: float,
        time_to_expiry: float,
        option_type: str
    ) -> float:
        """Calculate theta (per year, divide by 365 for daily)."""
        # Common term for both call and put
        term1 = -(spot * norm.pdf(d1) * volatility) / (2 * np.sqrt(time_to_expiry))

        # Option-specific term
        if option_type == 'CE':
            term2 = -self.risk_free_rate * strike * np.exp(
                -self.risk_free_rate * time_to_expiry
            ) * norm.cdf(d2)
        else:  # PE
            term2 = self.risk_free_rate * strike * np.exp(
                -self.risk_free_rate * time_to_expiry
            ) * norm.cdf(-d2)

        # Return daily theta (divide by 365)
        theta_annual = term1 + term2
        return theta_annual / 365

    def _calculate_vega(
        self,
        spot: float,
        d1: float,
        time_to_expiry: float
    ) -> float:
        """Calculate vega (per 1% change in volatility)."""
        vega_per_unit = spot * norm.pdf(d1) * np.sqrt(time_to_expiry)
        # Scale to 1% volatility change
        return vega_per_unit / 100

    def _calculate_rho(
        self,
        strike: float,
        d2: float,
        time_to_expiry: float,
        option_type: str
    ) -> float:
        """Calculate rho (per 1% change in interest rate)."""
        if option_type == 'CE':
            rho_per_unit = strike * time_to_expiry * np.exp(
                -self.risk_free_rate * time_to_expiry
            ) * norm.cdf(d2)
        else:  # PE
            rho_per_unit = -strike * time_to_expiry * np.exp(
                -self.risk_free_rate * time_to_expiry
            ) * norm.cdf(-d2)

        # Scale to 1% rate change
        return rho_per_unit / 100

    @staticmethod
    def calculate_time_to_expiry(
        current_date: date,
        expiry_date: date
    ) -> float:
        """
        Calculate time to expiry in years.

        Args:
            current_date: Current date (or timestamp date)
            expiry_date: Option expiry date

        Returns:
            Time to expiry in years (365-day convention)
        """
        if isinstance(current_date, datetime):
            current_date = current_date.date()
        if isinstance(expiry_date, datetime):
            expiry_date = expiry_date.date()

        days_to_expiry = (expiry_date - current_date).days

        # Minimum 1 day
        if days_to_expiry <= 0:
            days_to_expiry = 1

        return days_to_expiry / 365.0
```

### 2. Greeks Calculator Service

```python
"""
Service for calculating Greeks for options data from database.
"""

import pandas as pd
from sqlalchemy import create_engine
from concurrent.futures import ProcessPoolExecutor
import os
from typing import Optional
from .black_scholes_model import BlackScholesModel


class GreeksCalculatorService:
    """
    Service for calculating Greeks for historical options data.

    Handles batch processing, validation, and database integration.
    """

    def __init__(
        self,
        db_url: Optional[str] = None,
        risk_free_rate: float = 0.05,
        num_workers: Optional[int] = None
    ):
        """
        Initialize Greeks calculator service.

        Args:
            db_url: Database connection URL (auto-detected from env if None)
            risk_free_rate: Annual risk-free rate (default: 5%)
            num_workers: Number of parallel workers (default: CPU count)
        """
        if db_url is None:
            db_url = self._build_db_url()

        self.engine = create_engine(db_url)
        self.bs_model = BlackScholesModel(risk_free_rate=risk_free_rate)
        self.num_workers = num_workers or os.cpu_count()

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

    def calculate_greeks_for_records(
        self,
        df: pd.DataFrame
    ) -> pd.DataFrame:
        """
        Calculate Greeks for a DataFrame of options records.

        Args:
            df: DataFrame with columns: timestamp, spot_price, strike, expiry,
                implied_volatility, option_type

        Returns:
            DataFrame with added Greeks columns: delta, gamma, theta, vega, rho
        """
        # Validate required columns
        required = {'timestamp', 'spot_price', 'strike', 'expiry',
                   'implied_volatility', 'option_type'}
        missing = required - set(df.columns)
        if missing:
            raise ValueError(f"Missing required columns: {missing}")

        # Calculate time to expiry for each record
        df['time_to_expiry'] = df.apply(
            lambda row: self.bs_model.calculate_time_to_expiry(
                row['timestamp'].date(),
                row['expiry']
            ),
            axis=1
        )

        # Calculate Greeks for each row
        greeks_list = []
        for _, row in df.iterrows():
            try:
                greeks = self.bs_model.calculate_greeks(
                    spot=row['spot_price'],
                    strike=row['strike'],
                    time_to_expiry=row['time_to_expiry'],
                    volatility=row['implied_volatility'],
                    option_type=row['option_type']
                )
                greeks_list.append(greeks._asdict())
            except Exception as e:
                # Log error and append NaN values
                print(f"Error calculating Greeks for row: {e}")
                greeks_list.append({
                    'delta': None,
                    'gamma': None,
                    'theta': None,
                    'vega': None,
                    'rho': None
                })

        # Add Greeks columns to DataFrame
        greeks_df = pd.DataFrame(greeks_list)
        df = pd.concat([df, greeks_df], axis=1)

        # Drop temporary column
        df.drop(columns=['time_to_expiry'], inplace=True)

        return df

    def update_greeks_in_database(
        self,
        underlying: str = 'NIFTY',
        batch_size: int = 1000,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None
    ) -> int:
        """
        Calculate Greeks and update database records.

        Args:
            underlying: Underlying symbol (default: NIFTY)
            batch_size: Number of records per batch
            start_date: Start date filter (YYYY-MM-DD)
            end_date: End date filter (YYYY-MM-DD)

        Returns:
            Total number of records updated
        """
        print(f"=== Calculating Greeks for {underlying} ===")

        # Step 1: Query records that need Greeks calculation
        query = self._build_query(underlying, start_date, end_date)

        print("Querying database...")
        df = pd.read_sql(query, self.engine)
        total_records = len(df)

        if total_records == 0:
            print("No records found to process")
            return 0

        print(f"Found {total_records:,} records to process")

        # Step 2: Check for required data
        missing_iv = df['implied_volatility'].isna().sum()
        missing_spot = df['spot_price'].isna().sum()

        if missing_iv > 0:
            print(f"⚠️  Warning: {missing_iv} records missing implied volatility")
        if missing_spot > 0:
            print(f"⚠️  Warning: {missing_spot} records missing spot price")

        # Filter out records with missing data
        df_valid = df.dropna(subset=['implied_volatility', 'spot_price'])
        valid_records = len(df_valid)

        if valid_records < total_records:
            print(f"Processing {valid_records:,} valid records (skipping {total_records - valid_records:,})")

        # Step 3: Calculate Greeks in batches
        total_updated = 0

        for i in range(0, valid_records, batch_size):
            batch = df_valid.iloc[i:i+batch_size].copy()

            # Calculate Greeks for batch
            batch_with_greeks = self.calculate_greeks_for_records(batch)

            # Update database
            updated = self._update_batch(batch_with_greeks)
            total_updated += updated

            print(f"Processed {total_updated:,} / {valid_records:,} records...")

        print(f"✅ Updated {total_updated:,} records with Greeks")
        return total_updated

    def _build_query(
        self,
        underlying: str,
        start_date: Optional[str],
        end_date: Optional[str]
    ) -> str:
        """Build SQL query to fetch records needing Greeks."""
        query = f"""
        SELECT
            timestamp,
            underlying,
            strike,
            expiry,
            option_type,
            spot_price,
            implied_volatility,
            delta,
            gamma,
            theta,
            vega,
            rho
        FROM options_ticks
        WHERE underlying = '{underlying}'
        """

        if start_date:
            query += f" AND timestamp >= '{start_date}'"
        if end_date:
            query += f" AND timestamp <= '{end_date}'"

        # Optional: only update records where Greeks are NULL
        # query += " AND delta IS NULL"

        query += " ORDER BY timestamp"

        return query

    def _update_batch(self, df: pd.DataFrame) -> int:
        """Update a batch of records in database."""
        # Build UPDATE statements
        updates = []

        for _, row in df.iterrows():
            update_stmt = f"""
            UPDATE options_ticks
            SET
                delta = {row['delta']},
                gamma = {row['gamma']},
                theta = {row['theta']},
                vega = {row['vega']},
                rho = {row['rho']}
            WHERE timestamp = '{row['timestamp']}'
              AND underlying = '{row['underlying']}'
              AND strike = {row['strike']}
              AND expiry = '{row['expiry']}'
              AND option_type = '{row['option_type']}'
            """
            updates.append(update_stmt)

        # Execute batch update
        with self.engine.begin() as conn:
            for stmt in updates:
                conn.execute(stmt)

        return len(updates)
```

### 3. Greeks Validation

```python
"""
Validation module for Greeks calculation results.
"""

from typing import List, Dict
import pandas as pd


class GreeksValidator:
    """Validator for Greeks calculation results."""

    @staticmethod
    def validate_greeks(df: pd.DataFrame) -> Dict[str, List[str]]:
        """
        Validate Greeks values against expected ranges.

        Args:
            df: DataFrame with Greeks columns

        Returns:
            Dictionary with validation results:
            {
                'errors': List of critical errors,
                'warnings': List of warnings
            }
        """
        errors = []
        warnings = []

        # 1. Delta validation
        ce_delta_invalid = (
            (df['option_type'] == 'CE') &
            ((df['delta'] < 0) | (df['delta'] > 1))
        )
        if ce_delta_invalid.any():
            count = ce_delta_invalid.sum()
            errors.append(f"Call delta out of range [0,1]: {count} records")

        pe_delta_invalid = (
            (df['option_type'] == 'PE') &
            ((df['delta'] < -1) | (df['delta'] > 0))
        )
        if pe_delta_invalid.any():
            count = pe_delta_invalid.sum()
            errors.append(f"Put delta out of range [-1,0]: {count} records")

        # 2. Gamma validation
        gamma_invalid = df['gamma'] <= 0
        if gamma_invalid.any():
            count = gamma_invalid.sum()
            errors.append(f"Gamma not positive: {count} records")

        # 3. Vega validation
        vega_invalid = df['vega'] <= 0
        if vega_invalid.any():
            count = vega_invalid.sum()
            errors.append(f"Vega not positive: {count} records")

        # 4. Theta validation (warning only, as theta can be positive for deep ITM puts)
        ce_theta_positive = (
            (df['option_type'] == 'CE') &
            (df['theta'] > 0)
        )
        if ce_theta_positive.any():
            count = ce_theta_positive.sum()
            warnings.append(f"Call theta positive (unusual): {count} records")

        # 5. Rho validation
        ce_rho_invalid = (
            (df['option_type'] == 'CE') &
            (df['rho'] < 0)
        )
        if ce_rho_invalid.any():
            count = ce_rho_invalid.sum()
            warnings.append(f"Call rho negative (unusual): {count} records")

        pe_rho_invalid = (
            (df['option_type'] == 'PE') &
            (df['rho'] > 0)
        )
        if pe_rho_invalid.any():
            count = pe_rho_invalid.sum()
            warnings.append(f"Put rho positive (unusual): {count} records")

        # 6. ATM delta check (warning)
        atm_mask = (df['strike'] / df['spot_price']).between(0.98, 1.02)
        ce_atm = (df['option_type'] == 'CE') & atm_mask
        if ce_atm.any():
            avg_delta = df[ce_atm]['delta'].mean()
            if not (0.45 <= avg_delta <= 0.55):
                warnings.append(
                    f"ATM call delta average {avg_delta:.3f} (expected ~0.5)"
                )

        return {
            'errors': errors,
            'warnings': warnings
        }
```

## Nautilus Catalog Integration

### Extended Parquet Schema

```python
"""
Extension to NautilusCatalogGenerator to include Greeks in Parquet files.
"""

class NautilusCatalogWithGreeks(NautilusCatalogGenerator):
    """Extended catalog generator that includes Greeks."""

    def _generate_instrument_bars_with_greeks(
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
        """Generate bars for a single instrument WITH Greeks columns."""

        # Query data WITH Greeks
        query = """
        SELECT
            timestamp,
            open, high, low, close, volume, open_interest,
            delta, gamma, theta, vega, rho,
            implied_volatility AS iv,
            spot_price
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

        # Aggregate OHLCV and Greeks
        resampled = df.resample(timeframe).agg({
            'open': 'first',
            'high': 'max',
            'low': 'min',
            'close': 'last',
            'volume': 'sum',
            'open_interest': 'last',
            # Greeks at bar close
            'delta': 'last',
            'gamma': 'last',
            'theta': 'last',
            'vega': 'last',
            'rho': 'last',
            'iv': 'last',
            'spot_price': 'last',
        }).dropna()

        resampled = resampled.reset_index()

        # Create instrument directory
        inst_dir = bars_dir / instrument_id
        inst_dir.mkdir(exist_ok=True)

        # Write Parquet file with extended schema
        bars_path = inst_dir / f"{timeframe}.parquet"
        resampled.to_parquet(
            bars_path,
            engine='pyarrow',
            compression='snappy',
            index=False
        )
```

### Parquet Schema Specification

```
bars/{instrument_id}/{timeframe}.parquet

Columns:
  - timestamp: datetime64[ns]           # Bar timestamp
  - open: float64                       # Opening price
  - high: float64                       # High price
  - low: float64                        # Low price
  - close: float64                      # Closing price
  - volume: int64                       # Volume
  - open_interest: int64                # Open interest at bar close
  - delta: float64                      # Delta at bar close
  - gamma: float64                      # Gamma at bar close
  - theta: float64                      # Theta at bar close (daily)
  - vega: float64                       # Vega at bar close (per 1%)
  - rho: float64                        # Rho at bar close (per 1%)
  - iv: float64                         # Implied volatility at bar close
  - spot_price: float64                 # Underlying spot price at bar close

Compression: snappy
Encoding: optimal (auto-selected by PyArrow)
```

## Performance Optimization

### 1. Multiprocessing Strategy

```python
from multiprocessing import Pool
from functools import partial

def calculate_greeks_parallel(
    df: pd.DataFrame,
    bs_model: BlackScholesModel,
    num_workers: int = 4
) -> pd.DataFrame:
    """
    Calculate Greeks using multiprocessing.

    Args:
        df: DataFrame with options data
        bs_model: Black-Scholes model instance
        num_workers: Number of parallel workers

    Returns:
        DataFrame with Greeks
    """
    # Split DataFrame into chunks
    chunk_size = len(df) // num_workers
    chunks = [df.iloc[i:i+chunk_size] for i in range(0, len(df), chunk_size)]

    # Create partial function with model
    calc_func = partial(_calculate_greeks_chunk, bs_model=bs_model)

    # Process in parallel
    with Pool(num_workers) as pool:
        results = pool.map(calc_func, chunks)

    # Combine results
    return pd.concat(results, ignore_index=True)


def _calculate_greeks_chunk(
    chunk: pd.DataFrame,
    bs_model: BlackScholesModel
) -> pd.DataFrame:
    """Worker function for parallel Greeks calculation."""
    # Use GreeksCalculatorService logic
    service = GreeksCalculatorService()
    service.bs_model = bs_model
    return service.calculate_greeks_for_records(chunk)
```

### 2. Vectorization

```python
# Vectorized Greeks calculation (NumPy arrays)
def calculate_greeks_vectorized(
    spots: np.ndarray,
    strikes: np.ndarray,
    times_to_expiry: np.ndarray,
    volatilities: np.ndarray,
    option_types: np.ndarray,
    risk_free_rate: float = 0.05
) -> Dict[str, np.ndarray]:
    """
    Vectorized Greeks calculation for performance.

    Args:
        spots: Array of spot prices
        strikes: Array of strikes
        times_to_expiry: Array of times to expiry (years)
        volatilities: Array of implied volatilities
        option_types: Array of 'CE' or 'PE'
        risk_free_rate: Risk-free rate

    Returns:
        Dictionary with Greeks arrays
    """
    # Calculate d1 and d2 (vectorized)
    d1 = (
        np.log(spots / strikes)
        + (risk_free_rate + 0.5 * volatilities ** 2) * times_to_expiry
    ) / (volatilities * np.sqrt(times_to_expiry))

    d2 = d1 - volatilities * np.sqrt(times_to_expiry)

    # Calculate Greeks (vectorized)
    deltas = np.where(
        option_types == 'CE',
        norm.cdf(d1),
        norm.cdf(d1) - 1
    )

    gammas = norm.pdf(d1) / (spots * volatilities * np.sqrt(times_to_expiry))

    # ... (continue for other Greeks)

    return {
        'delta': deltas,
        'gamma': gammas,
        # ... other Greeks
    }
```

### 3. Performance Targets

| Operation | Target | Notes |
|-----------|--------|-------|
| Greeks calculation | > 1000/sec | Single-threaded |
| Parallel Greeks calc | > 10,000/sec | With 8 cores |
| Database UPDATE | > 500/sec | Batch size 1000 |
| Total pipeline | 100K records in < 2 min | Full workflow |

## Testing Strategy

### 1. Unit Tests

```python
def test_call_delta_atm():
    """Test call delta at-the-money."""
    bs = BlackScholesModel(risk_free_rate=0.05)
    greeks = bs.calculate_greeks(
        spot=100.0,
        strike=100.0,  # ATM
        time_to_expiry=0.25,  # 3 months
        volatility=0.20,
        option_type='CE'
    )
    # ATM call delta should be close to 0.5
    assert 0.48 <= greeks.delta <= 0.52


def test_put_delta_atm():
    """Test put delta at-the-money."""
    bs = BlackScholesModel(risk_free_rate=0.05)
    greeks = bs.calculate_greeks(
        spot=100.0,
        strike=100.0,
        time_to_expiry=0.25,
        volatility=0.20,
        option_type='PE'
    )
    # ATM put delta should be close to -0.5
    assert -0.52 <= greeks.delta <= -0.48


def test_gamma_positive():
    """Test gamma is always positive."""
    bs = BlackScholesModel()
    for strike in [80, 100, 120]:  # OTM, ATM, ITM
        greeks = bs.calculate_greeks(
            spot=100.0,
            strike=float(strike),
            time_to_expiry=0.25,
            volatility=0.20,
            option_type='CE'
        )
        assert greeks.gamma > 0


def test_edge_case_expiry_day():
    """Test Greeks on expiry day."""
    bs = BlackScholesModel()
    greeks = bs.calculate_greeks(
        spot=100.0,
        strike=100.0,
        time_to_expiry=1/365,  # 1 day
        volatility=0.20,
        option_type='CE'
    )
    # Should not crash and should return valid values
    assert 0 <= greeks.delta <= 1
    assert greeks.gamma > 0
```

### 2. Integration Tests

```python
def test_end_to_end_greeks_calculation():
    """Test full Greeks calculation pipeline."""
    # Setup test database with sample data
    # ... create test records ...

    service = GreeksCalculatorService(db_url='postgresql://test_db')

    # Run Greeks calculation
    updated_count = service.update_greeks_in_database(
        underlying='NIFTY',
        start_date='2024-01-01',
        end_date='2024-01-31'
    )

    # Verify Greeks were calculated
    assert updated_count > 0

    # Query and validate
    df = pd.read_sql(
        "SELECT * FROM options_ticks WHERE delta IS NOT NULL",
        service.engine
    )

    # Run validation
    validator = GreeksValidator()
    results = validator.validate_greeks(df)

    # Should have no errors
    assert len(results['errors']) == 0
```

### 3. Validation Against Broker Data

```python
def test_compare_with_zerodha():
    """Compare calculated Greeks with Zerodha Kite Greeks."""
    # Load Zerodha Greeks export
    zerodha_df = pd.read_csv('tests/data/zerodha_greeks_sample.csv')

    # Calculate our Greeks
    bs = BlackScholesModel(risk_free_rate=0.05)

    for _, row in zerodha_df.iterrows():
        our_greeks = bs.calculate_greeks(
            spot=row['spot'],
            strike=row['strike'],
            time_to_expiry=row['tte'],
            volatility=row['iv'],
            option_type=row['type']
        )

        # Compare delta (5% tolerance)
        delta_diff = abs(our_greeks.delta - row['zerodha_delta'])
        assert delta_diff / abs(row['zerodha_delta']) < 0.05

        # Compare gamma (10% tolerance - more volatile)
        gamma_diff = abs(our_greeks.gamma - row['zerodha_gamma'])
        assert gamma_diff / abs(row['zerodha_gamma']) < 0.10
```

## Error Handling

### 1. Invalid Input Handling

```python
# Handle missing implied volatility
if pd.isna(implied_volatility) or implied_volatility <= 0:
    logger.warning(f"Invalid IV for {instrument_id}: {implied_volatility}")
    # Use historical average or skip
    continue

# Handle missing spot price
if pd.isna(spot_price) or spot_price <= 0:
    logger.error(f"Missing spot price for {timestamp}")
    # Try to interpolate from nearby timestamps
    spot_price = interpolate_spot_price(timestamp)
```

### 2. Numerical Stability

```python
# Clamp extreme values
if abs(d1) > 10:
    logger.warning(f"Extreme d1 value: {d1} (clamping)")
    d1 = np.sign(d1) * 10

# Handle division by zero
if volatility * np.sqrt(time_to_expiry) < 1e-10:
    logger.warning("Near-zero volatility-time product")
    return default_greeks()
```

## Usage Example

```python
#!/usr/bin/env python3
"""
Complete workflow: Import data and calculate Greeks.
"""

from pathlib import Path
from src.data_pipeline.parsers.nse_parser import NSEOptionsCSVParser
from src.data_pipeline.importers.database_importer import DatabaseImporter
from src.data_pipeline.greeks.calculator_service import GreeksCalculatorService
from src.data_pipeline.catalog.nautilus_generator import NautilusCatalogWithGreeks


def main():
    # Step 1: Import data (see DESIGN-DataPipeline-NSEImport.md)
    print("=== Step 1: Importing NSE Data ===")
    parser = NSEOptionsCSVParser()
    df = parser.parse_directory(Path("data/sample/options"))

    importer = DatabaseImporter()
    importer.import_options_data(df)

    # Step 2: Calculate and update Greeks
    print("\n=== Step 2: Calculating Greeks ===")
    greeks_service = GreeksCalculatorService(
        risk_free_rate=0.05,  # 5% for India
        num_workers=8  # Parallel processing
    )

    updated_count = greeks_service.update_greeks_in_database(
        underlying='NIFTY',
        batch_size=1000
    )

    print(f"✅ Updated {updated_count:,} records with Greeks")

    # Step 3: Generate Nautilus catalog WITH Greeks
    print("\n=== Step 3: Generating Nautilus Catalog with Greeks ===")
    catalog_gen = NautilusCatalogWithGreeks(
        db_url=importer.engine.url,
        output_dir=Path("/tmp/nautilus-catalogs")
    )

    catalog_dir = catalog_gen.generate_catalog(underlying='NIFTY')
    print(f"✅ Catalog generated at: {catalog_dir}")

    # Step 4: Upload to S3
    print("\n=== Step 4: Uploading to S3 ===")
    from src.data_pipeline.catalog.s3_uploader import S3CatalogUploader

    uploader = S3CatalogUploader(
        bucket_name='synaptic-trading-data',
        prefix='nautilus-catalogs'
    )
    s3_url = uploader.upload_catalog(catalog_dir, 'nifty-options')
    print(f"✅ Uploaded to: {s3_url}")

    print("\n=== Pipeline Complete ===")


if __name__ == '__main__':
    main()
```

## Change Log

- 2025-11-04: Initial design document created with complete Black-Scholes implementation
