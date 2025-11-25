---
artifact_type: story
created_at: '2025-11-25T16:23:21.867271Z'
id: AUTO-13_INSTRUMENT_SUBSCRIPTION_TIMING_ORDER_FILLS
manual_update: 'true'
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: '001'
status: pending
title: Auto-generated title for 13_INSTRUMENT_SUBSCRIPTION_TIMING_ORDER_FILLS
updated_at: '2025-11-25T16:23:21.867273Z'
---

## Nautilus Best Practices

### Official Recommendation

From Nautilus documentation and examples:

**✅ All subscriptions should happen in `on_start()`**

```python
def on_start(self):
    """
    Use on_start to initialize strategy:
    - Fetch instruments
    - Subscribe to data
    - Register indicators
    """
    # Subscribe to spot for RSI
    self.subscribe_bars(self.spot_bar_type)

    # Subscribe to ALL instruments you'll trade
    for instrument_id in self.trading_instruments:
        bar_type = BarType.from_str(f"{instrument_id}-1-HOUR-LAST-EXTERNAL")
        self.subscribe_bars(bar_type)
```

**❌ Do NOT subscribe dynamically in `on_bar()`**

Dynamic subscription during bar processing:
- Not documented in Nautilus examples
- Creates timing ambiguity
- May behave differently in backtest vs live
- Risk of race conditions

### Why Upfront Subscription Matters

**Nautilus BacktestEngine Behavior**:
1. Processes all bars in chronological order
2. When order submitted, FillModel needs current market data
3. If instrument has no recent updates → uses stale cached price
4. Subscription ensures current bar data is available

---

## Solution: Pre-Subscribe with Precomputation

### Implementation Pattern

**Leverage existing precomputation system**:

```python
class OptionsMonthlyWeeklyHedgeStrategy(Strategy):

    def on_start(self):
        """
        Subscribe to ALL precomputed instruments upfront.

        This ensures Nautilus has current market data for all instruments
        before any orders are submitted, preventing stale price fills.
        """
        # 1. Subscribe to spot index for RSI
        spot_bar_type = BarType.from_str("NIFTY.NSE-1-HOUR-LAST-EXTERNAL")
        self.subscribe_bars(spot_bar_type)

        # 2. Get precomputed instruments list
        precomputed_file = Path("src/runners/backtest/cache/precomputed/instruments.json")

        if precomputed_file.exists():
            with open(precomputed_file) as f:
                instruments = json.load(f)

            self.logger.info(f"Pre-subscribing to {len(instruments)} instruments...")

            # 3. Subscribe to all option instruments
            for instrument_id in instruments:
                if instrument_id != "NIFTY.NSE":  # Skip spot (already subscribed)
                    bar_type = BarType.from_str(f"{instrument_id}-1-HOUR-LAST-EXTERNAL")
                    self.subscribe_bars(bar_type)

            self.logger.info(f"✓ Pre-subscribed to {len(instruments)} instruments")
        else:
            self.logger.warning("Precomputed instruments not found - may have fill timing issues")

    def _create_spread(self, leg1_symbol, leg2_symbol):
        """
        Create spread and submit orders.

        No subscription needed here - all instruments already subscribed in on_start.
        Nautilus will have current bar data available for accurate fills.
        """
        # Submit orders - FillModel will have current prices
        self.submit_order(leg1_order)
        self.submit_order(leg2_order)
```

### Integration with Existing Precomputation

**File**: `src/runners/backtest/cache/precomputed/instruments.json`

Already contains ~5,894 instruments:
```json
[
  "NIFTY.NSE",
  "NIFTY240104C17000.NSE",
  "NIFTY240104C17800.NSE",
  ...
]
```

**Benefits**:
- Reuses existing precomputation work
- All instruments needed for strategy are known upfront
- Clean separation: precompute determines "what to load", strategy subscribes to "what to monitor"

---

## Performance Considerations

### Memory Usage

**Before** (dynamic subscription):
- Only subscribed instruments in memory
- ~10-50 instruments at a time

**After** (pre-subscription):
- All 5,894 instruments subscribed
- Nautilus caches bar data for each

**Impact Analysis**:
- Bar data: ~5,894 instruments × ~300 bars × 64 bytes ≈ 113 MB
- Acceptable for 2-month backtest on modern hardware
- Trade-off: Slightly more memory for correct fills

**Mitigation** (if needed):
```python
def on_start(self):
    # Subscribe only to instruments for next N days
    active_expiries = self._get_expiries_for_next_n_days(days=7)
    instruments = self._filter_by_expiries(active_expiries)
    # Reduces to ~500-1000 instruments
```

### Startup Time

**Impact**: +2-3 seconds for subscription processing

**Acceptable** because:
- One-time cost at strategy start
- Backtest runs for hours/minutes afterward
- Ensures accurate fills throughout

---

## Validation

### Test Case: SPREAD_0001 (2024-01-08)

**After Fix** (expected results):

```
Order Time | Instrument  | Fill Price | Source Bar | Status
-----------|-------------|------------|------------|--------
04:30      | 21650 PUT   | 238.31     | 04:30      | ✓ Correct
04:30      | 21450 PUT   | 150.09     | 04:30      | ✓ Correct
05:30      | 21650 PUT   | 270.63     | 05:30      | ✓ Correct
05:30      | 21450 PUT   | 175.37     | 05:30      | ✓ Correct
```

**P&L Impact**:
- Before: -23.82% loss in 1 hour (false stop loss trigger)
- After: Realistic P&L, no false triggers

### Verification Steps

1. **Check fill prices match catalog timestamps**:
   ```python
   # Compare backtest fills vs catalog at exact timestamp
   assert fill_price == catalog_close_at_timestamp
   ```

2. **Verify subscription logs**:
   ```
   2024-01-08T02:41:05 [INFO] Strategy: Pre-subscribing to 5894 instruments...
   2024-01-08T02:41:07 [INFO] Strategy: ✓ Pre-subscribed to 5894 instruments
   ```

3. **Confirm no stale fills**:
   ```
   # All fills should use current bar timestamp
   assert fill_timestamp == order_submission_timestamp
   ```

---

## Related Research

### Nautilus GitHub Issues

**Issue #1476**: "Backtest Equity with EOD bar data seems to be broken"
- Similar timing issue with order fills
- Orders filling at wrong prices due to missing market data
- Resolution involved proper instrument configuration and market data availability

**Issue #1515**: "Streaming Backtest time synchronization issue"
- Timestamps not received chronologically
- Related to market data timing and order execution

### Nautilus Documentation References

**Bar Timestamp Convention**:
> "Bar timestamps (ts_event) are expected to represent the **close time** of the bar"
> "When `on_bar` is called, the bar is fully formed with OHLC prices"

**Strategy Lifecycle**:
> "Use `on_start` to initialize your strategy (e.g., fetch instruments, **subscribe to data**)"
> "Do not call components such as clock and logger in `__init__`"

---

## Key Takeaways

### ✅ DO

1. **Subscribe to all instruments in `on_start()`**
   - Ensures current market data available
   - Follows Nautilus best practices
   - Consistent backtest/live behavior

2. **Leverage precomputation**
   - Reuse existing instrument list
   - Clean architecture separation

3. **Monitor memory if needed**
   - Can filter by expiry dates
   - Trade-off: accuracy vs resources

### ❌ DON'T

1. **Subscribe dynamically in `on_bar()`**
   - Not documented pattern
   - Creates timing ambiguity
   - Risk of stale fills

2. **Subscribe after submitting orders**
   - Too late to affect fill prices
   - Market data must exist BEFORE fill

3. **Assume "last price" is current**
   - Nautilus uses "last available" update
   - Without subscription, "last" = stale

---

## Code Location

**Implementation File**: `src/strategy/options_monthly_weekly_hedge_strategy.py`

**Key Methods**:
- `on_start()` - Add pre-subscription logic
- `_create_monthly_spread()` - Remove post-order subscription
- `_create_weekly_hedge()` - Remove post-order subscription

**Precomputed Data**: `src/runners/backtest/cache/precomputed/instruments.json`

---

## Deep Research Findings (2025-11-07)

### Test Results: Pre-Subscription Did NOT Fix the Problem

After implementing pre-subscription in `on_start()`:
- ✅ 3,869 instruments pre-subscribed successfully
- ❌ SPREAD_0001 fills STILL WRONG:
  - 21450 PUT @ 04:30: filled at 134.62 (should be 150.09)
  - 21650 PUT @ 04:30: filled at 217.24 (should be 238.31)

### Root Cause: Nautilus Bar Processing Architecture

**From Nautilus Official Documentation:**

> "In the main backtesting loop, new market data is first processed for the execution of existing orders before being processed by the data engine that will then send data to strategies."

**What This Means:**

When a bar arrives at timestamp T (e.g., 04:30):
1. Nautilus processes the bar for ORDER EXECUTION first (OHLC sequence)
2. THEN sends the bar to strategy via `on_bar()`
3. By the time `on_bar()` is called, that bar's data is already consumed
4. Orders submitted in `on_bar(T)` are queued
5. These orders use "last available price" = previous bar (T-1)

**Bar-to-Market-Update Conversion:**

> "Each bar is converted into a sequence of four price points: Opening price, High price, Low price, Closing price."

All four updates happen at the SAME timestamp, processed for execution before strategy sees the bar.

### Why Pre-Subscription Doesn't Help

Pre-subscription only tells Nautilus to deliver bars to your strategy. It does NOT affect:
- The order execution timing
- Which bar's prices are available when orders fill
- The "last available price" used by FillModel

Orders submitted in `on_bar(T)` fundamentally cannot use bar T's prices because Nautilus has already consumed that bar for execution.

## Correct Solution: Enricher-Based Price Correction

### Approach

Accept that Nautilus fills happen at architectural timing, but correct the prices in post-processing:

1. **During Backtest:**
   - Let Nautilus fill orders at whatever prices its architecture determines
   - These fills will be at stale prices (T-1) due to bar processing order

2. **In Enricher:**
   - Lookup correct prices from catalog at order submission timestamp
   - Use order's `ts_event` to determine intended bar
   - Query V13 catalog for close price at that exact timestamp
   - Override position entry/exit prices with catalog prices

3. **Result:**
   - Enriched trade log shows correct prices
   - P&L calculations use correct entry/exit prices
   - Risk management decisions based on accurate data
   - Can compare "execution prices" vs "correct prices" for transparency

### Implementation

**File**: `src/enrichment/trade_enricher.py`

```python
def _get_bar_price_from_catalog(self, instrument_id: str, timestamp_ns: int) -> Optional[float]:
    """
    Get bar close price from V13 catalog at exact timestamp.

    Args:
        instrument_id: Instrument ID string (e.g., "NIFTY240125P21650.NSE")
        timestamp_ns: UNIX timestamp in nanoseconds

    Returns:
        Close price at timestamp, or None if not found
    """
    # Query V13 catalog parquet for close price at timestamp
    # (Implementation depends on catalog structure)
    pass

def _extract_positions(self, ...):
    # ...

    # Get entry price from catalog instead of position
    entry_price = self._get_bar_price_from_catalog(
        instrument_id_str,
        pos.ts_opened
    )
    if entry_price is None:
        entry_price = float(pos.avg_px_open)  # Fallback to Nautilus fill

    # Get exit price from catalog
    if pos.is_closed:
        exit_price = self._get_bar_price_from_catalog(
            instrument_id_str,
            pos.ts_closed
        )
        if exit_price is None:
            exit_price = float(pos.avg_px_close)  # Fallback
```

### Benefits

- **Accurate Reporting**: Trade logs show correct market prices
- **Valid P&L**: Risk calculations use actual entry/exit prices
- **Clean Architecture**: Doesn't fight Nautilus design
- **Transparency**: Can log both "Nautilus fill" and "catalog price"
- **Maintainable**: No custom FillModel needed

## Conclusion

**Initial Hypothesis**: Pre-subscription would ensure current bar data for fills
**Test Result**: Pre-subscription did NOT fix the problem
**Root Cause**: Nautilus architecture design - bars processed for execution before strategy notification
**Correct Solution**: Accept Nautilus timing, fix prices in enricher using catalog lookup

**Best Practice**: When using Nautilus with bar data:
1. Understand that `on_bar(T)` is called AFTER bar T is processed for execution
2. Orders submitted in `on_bar(T)` cannot use bar T's prices
3. Use enricher to correct prices from catalog at order timestamps
4. Document the discrepancy between "execution prices" and "catalog prices"

**Pre-Subscription Value**: Still useful for ensuring strategy receives all bar data, but does NOT fix fill timing issue.

---

## References

- **Issue Identified**: 2025-11-07 (SPREAD_0001 analysis)
- **Root Cause Analysis**: `/tmp/nautilus_fill_timing_proposal.md`
- **Nautilus Docs**: https://nautilustrader.io/docs/latest/concepts/strategies/
- **GitHub Issue #1476**: https://github.com/nautechsystems/nautilus_trader/issues/1476
- **Related Best Practice**: `07_INSTRUMENT_PRE_COMPUTATION_PATTERN.md`
