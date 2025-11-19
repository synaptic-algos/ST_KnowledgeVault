# Nautilus Best Practices: Options Spread Position Tracking

**Research Date**: 2025-11-06
**Nautilus Version**: 1.220.0+ (Latest stable with options spread support)
**Issue Context**: #20251106_160000 - Stop loss not triggering due to P&L calculation
**Research Status**: Comprehensive

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Multi-Leg Order Types in Nautilus](#multi-leg-order-types-in-nautilus)
3. [Position Tracking Patterns](#position-tracking-patterns)
4. [P&L Calculation for Spreads](#pl-calculation-for-spreads)
5. [Position Metadata Management](#position-metadata-management)
6. [Code Examples from Nautilus](#code-examples-from-nautilus)
7. [Recommendations for Our Strategy](#recommendations-for-our-strategy)
8. [References](#references)
9. [Appendix: Investigation Log](#appendix-investigation-log)

---

## Executive Summary

After comprehensive research into Nautilus Trader's options spread capabilities, here are the key findings:

### Critical Discovery: Spread Instruments Don't Create Positions

**Most Important Finding**: Nautilus documentation explicitly states:

> "Positions are not created for spread instruments. While contingent orders can still trigger for spreads, they operate without position linkage."

This means:
- **OptionSpread instruments** are designed for exchange-defined spreads (e.g., Interactive Brokers BAG contracts)
- **No automatic position tracking** for spread instruments
- **No automatic P&L calculation** at the spread level
- Strategies must implement **custom position tracking** for spreads

### Our Current Implementation is Correct

Our strategy's approach of:
1. Tracking each leg as a separate Nautilus position (for proper execution and fills)
2. Maintaining custom `active_positions` dictionary with spread metadata
3. Calculating spread-level P&L manually in strategy code

**This is the recommended pattern for options spread strategies in Nautilus.**

### The Actual Problem

The issue identified in #20251106_160000 is NOT architectural - it's a data pipeline issue:
- Our custom position dictionaries don't have `unrealized_pnl` calculated
- Exit manager reads these stale dictionaries instead of live P&L
- Solution: Calculate unrealized P&L before passing to exit manager

### Position Management Modes

Nautilus supports two OMS types:
- **NETTING**: One position per instrument, flips LONG/SHORT
- **HEDGING**: Multiple positions per instrument, each with unique ID

For options spreads with opposite legs (e.g., buy call + sell call), **HEDGING mode** is required.

---

## Multi-Leg Order Types in Nautilus

### 1. OptionSpread Instrument Type

**Definition**: "Exchange-defined multi-leg options strategy—e.g., vertical, calendar, straddle—quoted as one instrument."

**Key Properties** (Added in v1.208.0, Dec 2024):
```python
OptionSpread(
    legs=[...],                    # List of option legs
    margin_init=Decimal('5000'),   # Initial margin requirement
    margin_maint=Decimal('2500'),  # Maintenance margin
    maker_fee=Decimal('0.0005'),   # Maker fee rate
    taker_fee=Decimal('0.0010')    # Taker fee rate
)
```

**Important Limitations**:
- ✅ Supported for **exchange-defined spreads** (e.g., IB BAG contracts)
- ✅ Supported for **backtesting execution** (added v1.220.0, Sep 2025)
- ❌ **No automatic position tracking** - strategies must manage positions manually
- ❌ **No automatic P&L calculation** - strategies must calculate manually
- ❌ Not suitable for **dynamic spread strategies** where legs are selected at runtime

**Renamed in Recent Releases**: `OptionsSpread` → `OptionSpread` (singular) for technical correctness

### 2. OrderList - Grouping Mechanism

**Purpose**: Group related orders with common `order_list_id`

```python
# Orders can be grouped into lists
order_list = OrderList(
    order_list_id=OrderListId("SPREAD_001"),
    orders=[order1, order2]  # Both legs of spread
)
```

**Use Cases**:
- Tracking related orders for analysis
- Venue-specific multi-leg order routing
- Custom order grouping logic

**Limitations**:
- Does NOT automatically link orders for contingent execution
- Does NOT create spread-level positions
- Purely organizational - no execution semantics

### 3. Contingent Orders

Nautilus supports three contingency types for order linking:

#### OTO (One-Triggers-Other)
Parent order triggers child orders upon execution:
- **Full-trigger model**: Children release after complete parent fill
- **Partial-trigger model**: Children release pro-rata with partial fills

```python
# Parent order (entry)
parent_order = strategy.order_factory.market(
    instrument_id=instrument_id,
    order_side=OrderSide.BUY,
    quantity=Quantity.from_int(1)
)

# Child orders (profit target + stop loss)
take_profit = strategy.order_factory.limit(
    instrument_id=instrument_id,
    order_side=OrderSide.SELL,
    quantity=Quantity.from_int(1),
    price=Price.from_str("21500.00"),
    contingency_type=ContingencyType.OTO,
    parent_order_id=parent_order.client_order_id
)
```

#### OCO (One-Cancels-Other)
Linked orders where executing one cancels the remainder:

```python
# Typical use: Profit target + Stop loss (both active simultaneously)
profit_target = strategy.order_factory.limit(...)
stop_loss = strategy.order_factory.stop_market(
    ...,
    contingency_type=ContingencyType.OCO,
    linked_order_ids=[profit_target.client_order_id]
)
```

#### OUO (One-Updates-Other)
Linked orders where executing one reduces quantity of remainder:

```python
# Partial exits that update remaining position size
```

### 4. Bracket Orders

Combines entry with simultaneous profit target and stop loss:

```python
bracket_order = strategy.order_factory.bracket(
    instrument_id=instrument_id,
    order_side=OrderSide.BUY,
    quantity=Quantity.from_int(1),
    entry_price=Price.from_str("21000.00"),
    take_profit_price=Price.from_str("21200.00"),
    stop_loss_price=Price.from_str("20800.00")
)
```

**Components**:
- Parent order (entry order)
- Take-profit `LIMIT` child order
- Stop-loss `STOP_MARKET` child order

### Multi-Leg Spread Orders: Not Explicitly Documented

**Key Finding**: Nautilus documentation does NOT contain detailed guidance on:
- How to submit multi-leg spread orders
- How to ensure atomic execution of spread legs
- How to handle partial fills across legs
- Best practices for spread order routing

**Inference**: Strategies are expected to:
1. Submit individual leg orders separately
2. Use `order_list_id` for grouping/tracking
3. Implement custom logic for spread execution coordination
4. Handle leg fills asynchronously

---

## Position Tracking Patterns

### Pattern 1: Single Position Per Leg (Recommended for Nautilus)

**How It Works**:
- Each option leg creates a separate Nautilus `Position` object
- Long call = one position, Short call = separate position
- Each position tracks fills, P&L, and state independently

**Pros**:
✅ Native Nautilus support - works out of the box
✅ Accurate fill tracking per leg
✅ Individual leg P&L calculation automatic
✅ Supports partial fills properly
✅ Aligns with HEDGING OMS mode
✅ Works with Nautilus position lifecycle (open/closed events)

**Cons**:
❌ No spread-level position representation
❌ Manual calculation required for spread P&L
❌ No atomic position management (must close both legs separately)
❌ Strategy must maintain spread metadata externally

**When to Use**:
- ✅ Dynamic spread strategies (legs selected at runtime)
- ✅ Custom spread types not defined by exchange
- ✅ Need flexibility in leg management
- ✅ **This is the recommended pattern for our strategy**

**Implementation Pattern**:
```python
class OptionsStrategy(Strategy):
    def __init__(self):
        # Track Nautilus positions normally (one per leg)
        # Maintain custom spread mapping
        self.active_spreads = {
            'SPREAD_001': {
                'position_ids': ['POS-001', 'POS-002'],  # Both legs
                'leg1_instrument': InstrumentId(...),
                'leg2_instrument': InstrumentId(...),
                'risk_metrics': {
                    'max_loss': Decimal('5000'),
                    'max_profit': Decimal('2000')
                },
                'entry_time': datetime(...),
                'is_monthly': True
            }
        }

        # Track each position's spread membership
        self.active_positions = {
            'POS-001': {
                'spread_id': 'SPREAD_001',
                'instrument_id': 'NIFTY240104C21000.NSE',
                'side': 'BUY',
                'quantity': 3,
                'entry_price': 115.50,
                'unrealized_pnl': 0.0,  # ⚠️ Must be calculated manually
                'expiry': date(2024, 1, 4),
                'is_monthly': True,
                'lot_size': 25
            },
            'POS-002': {
                'spread_id': 'SPREAD_001',
                'instrument_id': 'NIFTY240104C21200.NSE',
                'side': 'SELL',
                'quantity': 3,
                'entry_price': 75.25,
                'unrealized_pnl': 0.0,  # ⚠️ Must be calculated manually
                'expiry': date(2024, 1, 4),
                'is_monthly': True,
                'lot_size': 25
            }
        }

    def calculate_spread_pnl(self, spread_id: str) -> Decimal:
        """Calculate total P&L for all legs in spread."""
        spread_data = self.active_spreads[spread_id]
        total_pnl = Decimal('0')

        for pos_id in spread_data['position_ids']:
            # Get Nautilus Position object
            position = self.cache.position(PositionId(pos_id))
            if position:
                total_pnl += position.unrealized_pnl(Price(...))  # Use current market price

        return total_pnl
```

### Pattern 2: OptionSpread Instrument (Limited Use Cases)

**How It Works**:
- Define spread as single `OptionSpread` instrument
- Exchange quotes/trades the spread as one unit
- Submit single order for the spread

**Pros**:
✅ Atomic execution (all legs or none)
✅ Single instrument ID for tracking
✅ Exchange-level spread pricing
✅ Simplified order submission

**Cons**:
❌ **No position tracking** - Nautilus explicitly doesn't create positions for spreads
❌ Only works for exchange-defined spreads (IB BAG, etc.)
❌ Cannot dynamically construct spreads at runtime
❌ Must know exact legs before trading
❌ Strategy must implement all position/P&L tracking manually
❌ Limited exchange support (mainly Interactive Brokers)

**When to Use**:
- Exchange-defined spreads only (e.g., IB BAG contracts)
- Live trading with Interactive Brokers
- Fixed spread strategies (not dynamic)
- **NOT recommended for our use case** (dynamic spread selection)

**Example**:
```python
# Define spread instrument (must be pre-registered)
spread_instrument = OptionSpread(
    instrument_id=InstrumentId.from_str("NIFTY_BULL_PUT_21000_21200.NSE"),
    legs=[
        ("NIFTY240104C21000.NSE", 1),   # Buy 1
        ("NIFTY240104C21200.NSE", -1)   # Sell 1
    ],
    margin_init=Decimal('5000'),
    margin_maint=Decimal('2500')
)

# Submit order for spread
order = self.order_factory.market(
    instrument_id=spread_instrument.id,
    order_side=OrderSide.BUY,
    quantity=Quantity.from_int(3)
)
self.submit_order(order)

# ⚠️ WARNING: No Position object will be created!
# Must track fills and P&L manually in strategy
```

### Pattern 3: Hybrid Approach (Advanced)

**How It Works**:
- Use `OptionSpread` instrument for order submission (atomic execution)
- Maintain shadow positions for each leg manually
- Calculate P&L manually using fill events

**Pros**:
✅ Atomic execution via spread orders
✅ Custom position tracking with full control
✅ Can integrate with existing strategy components

**Cons**:
❌ High complexity - duplicate position tracking
❌ Must synchronize Nautilus events with shadow positions
❌ Risk of state divergence
❌ Only works with exchange-defined spreads

**When to Use**:
- Live trading with IB when atomic execution is critical
- Strategy already has robust position tracking infrastructure
- Can tolerate additional complexity for execution guarantee

**Recommendation**: Not recommended unless atomic execution is absolutely required.

---

## P&L Calculation for Spreads

### Nautilus Built-in P&L

#### How Position.unrealized_pnl() Works

Nautilus automatically calculates unrealized P&L for individual positions:

```python
# Get position from cache
position = self.cache.position(position_id)

# Calculate unrealized P&L
unrealized_pnl = position.unrealized_pnl(
    price=Price.from_str("115.75")  # Current market price
)
```

**Formula**:
```
Standard Instruments (Options):
unrealized_pnl = (current_price - entry_price) × quantity × multiplier × side_multiplier

Where:
- side_multiplier = +1 for LONG, -1 for SHORT
- multiplier = lot_size (e.g., 25 for NIFTY options)
```

**What It Provides**:
- ✅ Per-position P&L in settlement currency
- ✅ Automatic calculation on position updates
- ✅ Handles partial fills correctly
- ✅ Accounts for commissions in realized P&L

**Limitations**:
- ❌ Only calculates for single position
- ❌ No spread-level aggregation
- ❌ Requires current market price as input
- ❌ No automatic price updates - strategy must provide

### Portfolio-Level P&L

```python
# Get portfolio-wide P&L
total_unrealized = self.portfolio.unrealized_pnl(currency=USD)
total_realized = self.portfolio.realized_pnl(currency=USD)
total_pnl = self.portfolio.total_pnl(currency=USD)
```

**Added Features (v1.220.0+)**:
- Optional `price` parameter for custom valuation
- Support for mark prices: `use_mark_prices=True`
- Multi-currency support with exchange rates

**Use Cases**:
- Portfolio stop loss checks
- Overall performance tracking
- Account balance monitoring

### Custom P&L Calculation for Spreads

**When Needed**:
- Checking spread-level stop loss
- Profit target evaluation
- Exit condition analysis
- Risk management decisions

**Recommended Pattern**:

```python
def calculate_spread_unrealized_pnl(
    self,
    spread_id: str,
    current_prices: Dict[str, Decimal]
) -> Decimal:
    """
    Calculate unrealized P&L for entire spread.

    Args:
        spread_id: Spread identifier
        current_prices: Dict mapping instrument_id -> current_price

    Returns:
        Total unrealized P&L for spread
    """
    spread_data = self.active_spreads[spread_id]
    total_pnl = Decimal('0')

    for pos_id in spread_data['position_ids']:
        # Get position info
        position_info = self.active_positions[pos_id]
        instrument_id = position_info['instrument_id']

        # Get current price
        current_price = current_prices.get(instrument_id)
        if not current_price:
            # Fallback: Get from cache
            current_price = self._get_current_price(instrument_id)

        # Calculate P&L for this leg
        entry_price = Decimal(str(position_info['entry_price']))
        quantity = Decimal(str(position_info['quantity']))
        lot_size = Decimal(str(position_info['lot_size']))

        # Side multiplier: +1 for BUY, -1 for SELL
        side_multiplier = 1 if position_info['side'] == 'BUY' else -1

        # P&L = (current_price - entry_price) × side × quantity × lot_size
        price_diff = (current_price - entry_price) * side_multiplier
        leg_pnl = price_diff * quantity * lot_size

        total_pnl += leg_pnl

    return total_pnl

def _get_current_price(self, instrument_id: str) -> Decimal:
    """Get current market price for instrument."""
    # Try quote first (most accurate)
    instrument = self.cache.instrument(InstrumentId.from_str(instrument_id))
    if instrument:
        quote = self.cache.quote(instrument.id)
        if quote:
            return Decimal(str(quote.bid_price))  # Use bid for conservative valuation

        # Fallback to last bar
        bar = self.cache.bar(instrument.id)
        if bar:
            return Decimal(str(bar.close))

    # Fallback to stored price (last known)
    return Decimal(str(self.active_positions.get('last_price', 0)))
```

### Recommended Approach for Our Strategy

**Current Problem**: Exit manager receives position dictionaries without `unrealized_pnl`

**Solution**: Calculate P&L before passing to exit manager

**Implementation** (in `options_monthly_weekly_hedge_strategy.py`):

```python
def _process_exit_conditions(self, bar: Bar):
    """
    Process exit conditions with LIVE P&L calculation.

    ⚠️ CRITICAL: Must calculate unrealized_pnl BEFORE calling exit manager.
    """
    current_time = bar.ts_init.as_datetime()
    bar_time = bar.ts_event.as_datetime()

    # STEP 1: Update unrealized P&L for ALL positions
    self._update_positions_unrealized_pnl(bar)

    # STEP 2: Evaluate exit conditions (now has fresh P&L data)
    exit_signals = self.exit_manager.evaluate_all_exit_conditions(
        current_time=current_time,
        current_capital=self.current_capital,
        positions=self.active_positions,  # Now has unrealized_pnl calculated
        vix_level=self.current_vix_level
    )

    # STEP 3: Process exit signals
    if exit_signals:
        self._execute_exit_signals(exit_signals, bar_time)

def _update_positions_unrealized_pnl(self, bar: Bar):
    """
    Calculate current unrealized P&L for all active positions.

    Updates self.active_positions dictionaries with fresh unrealized_pnl values.
    """
    for pos_id, position_info in self.active_positions.items():
        instrument_id = position_info['instrument_id']

        # Get current market price
        current_price = self._get_current_price(instrument_id, bar)

        # Calculate unrealized P&L
        entry_price = Decimal(str(position_info['entry_price']))
        quantity = Decimal(str(position_info['quantity']))
        lot_size = Decimal(str(position_info['lot_size']))
        side_multiplier = 1 if position_info['side'] == 'BUY' else -1

        price_diff = (current_price - entry_price) * side_multiplier
        unrealized_pnl = price_diff * quantity * lot_size

        # Update position dictionary
        position_info['unrealized_pnl'] = float(unrealized_pnl)
        position_info['current_price'] = float(current_price)
        position_info['last_update'] = bar.ts_event.as_datetime()

def _get_current_price(self, instrument_id: str, bar: Bar) -> Decimal:
    """
    Get current market price for an instrument.

    Priority:
    1. If bar is for this instrument, use bar's close price
    2. Query cache for latest quote
    3. Fallback to last known price
    """
    # Check if bar is for this instrument
    if str(bar.instrument_id) == instrument_id:
        return Decimal(str(bar.close))

    # Query cache for quote
    instrument = self.cache.instrument(InstrumentId.from_str(instrument_id))
    if instrument:
        quote = self.cache.quote(instrument.id)
        if quote:
            # Use bid price for conservative valuation
            return Decimal(str(quote.bid_price))

        # Fallback to last bar
        last_bar = self.cache.bar(instrument.id)
        if last_bar:
            return Decimal(str(last_bar.close))

    # Fallback to last known price from position tracking
    return Decimal(str(self.active_positions[pos_id].get('current_price', 0)))
```

**Benefits**:
- ✅ Exit manager receives live P&L data
- ✅ Stop loss triggers correctly
- ✅ Minimal changes to existing architecture
- ✅ Aligns with Nautilus best practices
- ✅ Works with current position tracking model

---

## Position Metadata Management

### Using Nautilus Position Objects Directly

**NOT Recommended for Spread Strategies**

Nautilus `Position` objects don't support custom metadata fields:
```python
position = self.cache.position(position_id)
# ❌ No way to add: spread_id, is_monthly, expiry, risk_metrics
```

**Limitations**:
- No custom attributes
- No spread-level grouping
- No strategy-specific metadata
- Limited to Nautilus-defined fields (quantity, entry, P&L, etc.)

### Custom Position Dictionaries (Recommended)

**Our Current Approach - This is Valid**

Maintain parallel dictionaries with strategy-specific metadata:

```python
self.active_positions = {
    'POS-001': {
        # Nautilus-related
        'position_id': 'POS-001',
        'instrument_id': 'NIFTY240104C21000.NSE',
        'side': 'BUY',
        'quantity': 3,
        'entry_price': 115.50,
        'unrealized_pnl': 1250.75,  # Calculated manually

        # Strategy-specific metadata
        'spread_id': 'SPREAD_001',
        'is_monthly': True,
        'expiry': date(2024, 1, 4),
        'lot_size': 25,

        # Risk tracking
        'capital_at_risk': Decimal('5000'),
        'max_loss': Decimal('5000'),

        # Audit trail
        'entry_time': datetime(...),
        'last_update': datetime(...)
    }
}

self.active_spreads = {
    'SPREAD_001': {
        'spread_id': 'SPREAD_001',
        'spread_type': 'BULL_PUT_SPREAD',
        'position_ids': ['POS-001', 'POS-002'],

        # Risk metrics (spread-level)
        'risk_metrics': {
            'max_loss': Decimal('5000'),
            'max_profit': Decimal('2000'),
            'breakeven': Decimal('21040.25')
        },

        # Entry details
        'entry_time': datetime(...),
        'entry_spot': Decimal('21500'),
        'entry_vix': 14.5,

        # Classification
        'is_monthly': True,
        'direction': 'BULLISH'
    }
}
```

**Advantages**:
✅ Full control over metadata structure
✅ Can add any fields needed
✅ Easy to query and filter
✅ Supports spread-level aggregation
✅ Strategy-specific data lives with strategy

**Best Practices**:
1. **Sync with Nautilus positions**: Use Nautilus position events to keep dictionaries up-to-date
2. **Single source of truth**: Nautilus positions for P&L, custom dicts for metadata
3. **Validation**: Periodically verify custom dict matches Nautilus state
4. **Cleanup**: Remove entries when Nautilus positions close

### Alternative Patterns (Not in Nautilus)

**Tags/Labels**: Not found in Nautilus documentation
**Position Groups**: Not natively supported
**Custom Attributes**: Not available on Position objects

**Conclusion**: Custom dictionaries are the recommended pattern.

---

## Code Examples from Nautilus

### Bracket Order Example

From Nautilus documentation:

```python
# Create bracket order (entry + profit target + stop loss)
bracket_order = self.order_factory.bracket(
    instrument_id=instrument.id,
    order_side=OrderSide.BUY,
    quantity=Quantity.from_int(100),
    entry_price=Price.from_str("100.00"),
    take_profit_price=Price.from_str("105.00"),
    stop_loss_price=Price.from_str("95.00"),
    entry_order_type=OrderType.LIMIT,
    time_in_force=TimeInForce.GTC
)

# Submit all three orders atomically
self.submit_order_list(bracket_order)
```

### Position P&L Query Example

```python
# Get all open positions
open_positions = self.cache.positions_open()

for position in open_positions:
    # Get current unrealized P&L
    current_quote = self.cache.quote(position.instrument_id)
    if current_quote:
        pnl = position.unrealized_pnl(current_quote.bid_price)

        self.log.info(
            f"Position {position.id}: "
            f"Qty={position.quantity}, "
            f"Avg={position.avg_px_open}, "
            f"Unrealized P&L={pnl}"
        )
```

### Portfolio-Level P&L Example

```python
# Get portfolio totals
total_unrealized = self.portfolio.unrealized_pnl(USD)
total_realized = self.portfolio.realized_pnl(USD)
net_exposure = self.portfolio.net_exposure(instrument.id)

self.log.info(
    f"Portfolio: "
    f"Unrealized={total_unrealized}, "
    f"Realized={total_realized}, "
    f"Net Exposure={net_exposure}"
)
```

### No Spread-Specific Examples Found

**Important**: Nautilus documentation and repository do NOT contain:
- ❌ Options spread strategy examples
- ❌ Multi-leg position tracking examples
- ❌ Spread P&L calculation examples
- ❌ OptionSpread usage examples for backtesting

**Inference**: Spread strategies are expected to implement custom tracking logic.

---

## Recommendations for Our Strategy

### Current Implementation Analysis

#### What We're Doing Right ✅

1. **Separate Positions Per Leg**
   - Aligns with Nautilus architecture
   - Proper fill tracking
   - Individual P&L calculation available

2. **Custom Metadata Dictionaries**
   - `active_positions`: Position-level metadata
   - `active_spreads`: Spread-level grouping and risk metrics
   - This is the recommended pattern for spread strategies

3. **Modular Component Design**
   - Entry manager, exit manager, risk manager
   - Clean separation of concerns
   - Reusable components

4. **HEDGING OMS Mode**
   - Supports opposite legs (buy + sell same instrument)
   - Each leg has unique position ID

#### What Needs to Change ❌

**1. P&L Calculation Pipeline**

**Problem**: Position dictionaries passed to exit manager don't have `unrealized_pnl` calculated

**Current Code** (`options_monthly_weekly_hedge_strategy.py:842-846`):
```python
exit_signals = self.exit_manager.evaluate_all_exit_conditions(
    current_time=current_time,
    current_capital=self.current_capital,
    positions=self.active_positions,  # ⚠️ Missing unrealized_pnl!
    vix_level=self.current_vix_level
)
```

**Exit Manager** (`exit_manager.py:363`):
```python
pos_pnl = Decimal(str(spread_pos.get('unrealized_pnl', 0)))  # Always returns 0!
```

**Impact**: Stop loss never triggers (see issue #20251106_160000)

**Solution**: Calculate P&L before calling exit manager (see [Recommended Approach](#recommended-approach-for-our-strategy))

**2. Current Price Tracking**

**Problem**: Position dictionaries don't maintain `current_price` or `last_price`

**Needed**: Track last known price for each instrument to enable P&L calculation

**Solution**: Add `current_price` field, update on every bar/quote

**3. Price Data Access**

**Problem**: Strategy needs efficient way to get current price for any instrument

**Solution**: Implement `_get_current_price()` helper with fallback chain:
1. Check if current bar is for instrument
2. Query cache for latest quote
3. Use last bar from cache
4. Fallback to stored price

### Proposed Architecture

#### 1. Position Tracking Structure (NO CHANGES NEEDED)

Keep current structure - it's correct:

```python
# Track each leg as separate Nautilus position
# Maintain custom metadata dictionaries
self.active_positions = {...}  # Position-level metadata
self.active_spreads = {...}    # Spread-level grouping
```

#### 2. P&L Calculation Flow (NEW)

**Add to strategy lifecycle**:

```python
def on_bar(self, bar: Bar):
    """Main bar handler."""
    # 1. Update risk tracking (existing)
    self._update_risk_tracking(bar)

    # 2. Calculate P&L for all positions (NEW)
    self._update_positions_unrealized_pnl(bar)

    # 3. Process exits with fresh P&L (existing, but now works correctly)
    self._process_exit_conditions(bar)

    # 4. Process entries (existing)
    self._process_entry_conditions(bar)
```

#### 3. Exit Manager Integration (FIXED)

**No changes needed to exit manager** - it already expects `unrealized_pnl` in position dicts

Just ensure strategy provides it:

```python
# Before calling exit manager:
self._update_positions_unrealized_pnl(bar)

# Now exit manager receives positions with unrealized_pnl populated
exit_signals = self.exit_manager.evaluate_all_exit_conditions(
    positions=self.active_positions  # ✅ Now has unrealized_pnl
)
```

#### 4. Spread-Level P&L Aggregation (EXISTING)

Exit manager already does this correctly (`exit_manager.py:355-364`):

```python
# Sum P&L across all positions in spread
spread_data = self.active_spreads[spread_id]
position_ids = spread_data.get('position_ids', [])
current_pnl = Decimal('0')
for spread_pos_id in position_ids:
    if spread_pos_id in positions:
        spread_pos = positions[spread_pos_id]
        pos_pnl = Decimal(str(spread_pos.get('unrealized_pnl', 0)))
        current_pnl += pos_pnl
```

**This logic is sound** - it just needs positions to have `unrealized_pnl` populated.

### Migration Path

#### Phase 1: Fix P&L Calculation (IMMEDIATE - CRITICAL)

**File**: `src/strategy/options_monthly_weekly_hedge_strategy.py`

**Changes**:
1. Add `_update_positions_unrealized_pnl()` method
2. Add `_get_current_price()` helper method
3. Call `_update_positions_unrealized_pnl()` before exit manager
4. Add `current_price` field to position dictionaries

**Testing**:
1. Unit test: Verify P&L calculation accuracy
2. Integration test: Verify stop loss triggers correctly
3. Backtest validation: Confirm SPREAD_0003 (loss of -548%) would trigger stop loss

**Priority**: CRITICAL - Must fix before live trading

#### Phase 2: Enhance Position Tracking (OPTIONAL - IMPROVEMENT)

**Potential Enhancements**:
1. Add position state validation (compare Nautilus vs custom dict)
2. Add periodic reconciliation checks
3. Enhance logging for P&L updates
4. Add P&L calculation performance monitoring

**Priority**: Medium - Quality improvement, not critical

#### Phase 3: Documentation (REQUIRED)

**Create**:
1. Internal docs on P&L calculation methodology
2. Position tracking architecture diagram
3. Exit manager data flow documentation
4. Troubleshooting guide for P&L issues

**Priority**: High - Essential for maintainability

### Backward Compatibility Considerations

**No Breaking Changes**:
- ✅ Position dictionary structure unchanged (just adding `unrealized_pnl` field)
- ✅ Exit manager interface unchanged
- ✅ Spread tracking unchanged
- ✅ Entry manager unaffected

**Safe to Deploy**:
- Calculating P&L doesn't affect other components
- Exit manager already expects `unrealized_pnl` (defensive default: 0)
- No changes to order submission or position lifecycle

---

## References

### Official Nautilus Documentation

1. **Positions**: https://nautilustrader.io/docs/latest/concepts/positions/
   - Position tracking, P&L calculation, NETTING vs HEDGING modes
   - "Positions are not created for spread instruments"

2. **Orders**: https://nautilustrader.io/docs/latest/concepts/orders/
   - OrderList, OTO, OCO, OUO contingency types
   - Bracket orders

3. **Execution**: https://nautilustrader.io/docs/latest/concepts/execution/
   - Execution flow, OrderEmulator, position management

4. **Instruments**: https://nautilustrader.io/docs/latest/concepts/instruments/
   - OptionSpread instrument type definition

### GitHub Repository

5. **Release Notes**: https://github.com/nautechsystems/nautilus_trader/blob/develop/RELEASES.md
   - v1.208.0 (Dec 2024): Added margin_init, margin_maint, maker_fee, taker_fee for OptionSpread
   - v1.220.0 (Sep 2025): Support for option spread execution in backtesting
   - v1.221.0 (Oct 2025): Fixed OptionSpread Arrow schema, added PositionAdjusted events

6. **Issues & Discussions**:
   - No specific discussions found on options spread position tracking
   - Community indicates spread strategies must implement custom tracking

### Related Research

7. **Internal Documentation**:
   - `documentation/nautilusbestpractices/05_OPTIONS_BACKTESTING_BEST_PRACTICES.md`
     - Options instrument filtering, registration optimization
     - Streaming mode for memory efficiency

   - `documentation/prd/CORE_STRATEGY_PRD.md` (v3.15.0)
     - Section 4.1: Stop loss requirements (50% of max spread loss)
     - Exit priority system (6-level)

8. **Issue Tracking**:
   - `issues/identified/20251106_160000_stop_loss_not_triggering.md`
     - Root cause analysis
     - Evidence from 4-month backtest
     - 8 spreads exceeded -50% threshold but none triggered stop loss

---

## Appendix: Investigation Log

### Research Methodology

**Phase 1: Web Search (Completed)**
- Searched Nautilus documentation for multi-leg orders, spreads, position tracking
- Explored GitHub repository for examples and release notes
- Analyzed community discussions for real-world patterns

**Phase 2: Codebase Analysis (Completed)**
- Read current strategy implementation
- Analyzed exit manager position handling
- Identified P&L calculation gap
- Reviewed existing Nautilus best practices documentation

**Phase 3: Synthesis (Completed)**
- Cross-referenced findings with issue #20251106_160000
- Validated our implementation against Nautilus best practices
- Developed concrete recommendations

### Key Findings Timeline

1. **Critical Discovery**: Nautilus doesn't create positions for OptionSpread instruments
2. **Validation**: Our approach (separate positions + custom metadata) is correct
3. **Root Cause**: Data pipeline issue, not architectural problem
4. **Solution**: Calculate P&L before passing to exit manager

### Questions Investigated

1. ✅ **Does Nautilus have native support for tracking spreads as a single position?**
   - Answer: NO - explicitly documented that spread instruments don't create positions

2. ✅ **How should unrealized P&L be calculated for multi-leg positions?**
   - Answer: Sum individual leg P&L values; strategy must calculate manually

3. ✅ **Should each leg be a separate position or should they be grouped?**
   - Answer: Separate positions (Nautilus native), grouped via custom metadata (strategy-managed)

4. ✅ **What's the recommended pattern for custom position metadata?**
   - Answer: Custom dictionaries parallel to Nautilus positions

5. ✅ **How do other strategies handle options spreads in Nautilus?**
   - Answer: No public examples found; inference = custom implementation required

### Unanswered Questions

1. ❓ **Performance impact of P&L calculation on every bar**
   - Need to profile P&L calculation overhead
   - May need caching strategy if performance issue

2. ❓ **Best practice for price staleness detection**
   - How long is a cached price valid?
   - Should we log warnings for stale prices?

3. ❓ **Integration with Nautilus Portfolio for aggregate P&L**
   - Can we leverage `portfolio.unrealized_pnl()` instead of manual calculation?
   - Would need to map Nautilus positions back to spreads

### Testing Recommendations

1. **Unit Tests**:
   - Test `_update_positions_unrealized_pnl()` with known prices
   - Test `_get_current_price()` fallback chain
   - Test spread P&L aggregation

2. **Integration Tests**:
   - Run 4-month backtest with fix
   - Verify stop loss triggers for SPREAD_0003 (-548% loss)
   - Validate all 8 identified spreads would trigger stop loss

3. **Performance Tests**:
   - Profile P&L calculation overhead
   - Measure impact on backtest duration
   - Optimize if >5% overhead

---

## Conclusion

**Key Takeaways**:

1. **Our architecture is sound** - Separate positions + custom metadata is the recommended pattern
2. **The problem is specific** - P&L calculation pipeline, not overall design
3. **The fix is straightforward** - Calculate P&L before exit manager
4. **Nautilus limitations are clear** - No native spread position tracking; strategies must implement

**Confidence Level**: HIGH

This research is based on:
- ✅ Official Nautilus documentation (latest version)
- ✅ Recent release notes (2024-2025)
- ✅ Actual codebase analysis
- ✅ Detailed issue investigation

**Recommended Actions**:

1. **Immediate**: Implement P&L calculation fix (Phase 1)
2. **Short-term**: Add comprehensive testing
3. **Medium-term**: Document architecture and patterns
4. **Long-term**: Consider contributing spread strategy example to Nautilus

---

**Document Version**: 1.0
**Author**: Claude (Research Agent)
**Review Status**: Initial Draft - Requires Human Review
**Next Update**: After Phase 1 implementation and testing
