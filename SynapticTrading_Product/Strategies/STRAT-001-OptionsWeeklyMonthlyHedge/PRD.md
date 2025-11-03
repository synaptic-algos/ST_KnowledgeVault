# Nikhil's Monthly-Weekly Options Options Weekly Monthly Hedge PRD

**Version:** 3.0.0
**Document Created:** October 6, 2025 17:10 IST
**Last Updated:** October 13, 2025 06:45 IST
**Status:** Active
**Document Type:** Options Weekly Monthly Hedge Specification
**Feature ID:** FEAT-2025-0100-TRADE
**Extracted From:** nikhils_MonthlyWeekly_OptionsStrategy_prd.md v3.15.0

---

## Executive Summary

This document specifies the **core trading strategy logic** for Nikhil's Monthly-Weekly Options Strategy. This PRD is **environment-agnostic** and focuses purely on the strategy rules, entry/exit logic, position management, and risk controls. It serves as the foundation for both backtesting and live/paper trading implementations.

**Key Principle**: This PRD defines WHAT the strategy does, not HOW it's executed (deployment-specific details are in separate PRDs).

---

## 1. Strategy Overview

### 1.1 Core Concept
- **Primary Position**: Monthly option spread (Bull Call Spread for bullish OR Bear Put Spread for bearish)
- **Hedge Position**: Weekly option spread (opposite direction to monthly)
- **Capital Allocation**: ₹400,000 total allocated capital
- **Position Sizing**: 4 lots per spread (NIFTY lot size = 75 shares/lot → 300 shares total)
- **Lot Matching**: Weekly hedge MUST use same lot count as monthly (4 lots each)
- **Target Performance**: 18.7% CAGR with maximum drawdown < 12.6%
- **Market**: NIFTY50 index options
- **Broker/Execution**: Zerodha (when live)

### 1.2 Position Structure

#### Monthly Spread Configuration
**Type**: Bull Call Spread (bullish) OR Bear Put Spread (bearish)

| Parameter | Specification |
|-----------|--------------|
| **Underlying** | NIFTY50 |
| **Expiry** | Monthly expiry (last Thursday or Tuesday) |
| **Lot Size** | 75 shares per lot (NIFTY standard) |
| **Number of Lots** | 4 lots (optimized for ₹400k capital) |
| **Total Quantity** | 300 shares (4 lots × 75 shares/lot) |
| **Strike Structure** | DEBIT spread: BUY ATM, SELL ATM±200 |
| **Entry Strike** | ATM (At-The-Money, rounded to nearest 50-point strike) |
| **Protection Strike** | ATM±200 points (200 points away from entry) |
| **Entry Day** | Wednesday (Thu expiry) or Monday (Tue expiry) |
| **Entry Time** | 10:00 AM IST (10:15 AM with hourly data) |
| **Exit Rules** | D-1 by 1:00 PM (13:00) OR profit/stop triggers |

**Strike Selection Details**:
- **Bull Call Spread (DEBIT)** - Used for BULLISH view:
  - BUY ATM Call (long position)
  - SELL ATM+200 Call (capped profit, 200 points above ATM)
  - Example: Spot 25,350 → BUY 25,350 CE @ ₹380, SELL 25,550 CE @ ₹300 → NET DEBIT ₹80
  - Profit if market moves UP

- **Bear Put Spread (DEBIT)** - Used for BEARISH view:
  - BUY ATM Put (long position)
  - SELL ATM-200 Put (capped profit, 200 points below ATM)
  - Example: Spot 25,350 → BUY 25,350 PE @ ₹380, SELL 25,150 PE @ ₹300 → NET DEBIT ₹80
  - Profit if market moves DOWN

**ATM Strike Determination**:
- NIFTY50 strikes available in **50-point intervals** (26100, 26150, 26200...)
- ATM selection: Round spot price to **nearest 50-point strike**
- Examples:
  - Spot 26150.01 → ATM strike = 26150
  - Spot 26175.00 → ATM strike = 26200
  - Spot 24983.37 → ATM strike = 25000
- Validation: ATM strike must be within ±25 points of spot price

#### Weekly Hedge Configuration
**Type**: Opposite to monthly (Bear Put if monthly is Bull Call, Bull Call if monthly is Bear Put)

| Parameter | Specification |
|-----------|--------------|
| **Underlying** | NIFTY50 |
| **Expiry** | Next week's expiry (7-8 days out) |
| **Lot Size** | 75 shares per lot (NIFTY standard) |
| **Number of Lots** | 4 lots (MUST match monthly lot count) |
| **Total Quantity** | 300 shares (4 lots × 75 shares/lot) |
| **Strike Structure** | Delta-based targeting (±0.1 delta) |
| **Entry Strike** | ±0.1 delta strike (Bear Put Hedge: -0.1 delta PE, Bull Call Hedge: +0.1 delta CE) |
| **Protection Strike** | 50-66% of debit paid |
| **Entry Timing** | NEXT candle after monthly spread creation (11:15 AM for hourly data) |
| **Exit Rules** | D-1 mandatory, linked to monthly |

**Delta-Based Strike Selection Rationale**:
- **±0.1 Delta Target**: Ensures ~10% probability of ITM across all volatility regimes
- **Adaptive Distance**: Auto-adjusts OTM distance based on volatility (typically 1300-1500 points at NIFTY 26k)
- **Bear Put Hedge**: -0.1 delta PE (protects Bull Call monthly against sharp downward moves)
- **Bull Call Hedge**: +0.1 delta CE (protects Bear Put monthly against sharp upward moves)

---

## 2. Entry Rules

### 2.1 Entry Timing

#### 2.1.1 Scheduled Entry Windows
- **Ideal Entry Time**: 10:00 AM IST
- **Actual Entry Time**: 10:15 AM IST (when using hourly candle data)
- **Entry Window**: 10:00-10:20 AM
- **Monthly Spread Entry**: 10:15 AM (first candle in entry window)
- **Weekly Hedge Entry**: NEXT candle after monthly creation (11:15 AM for hourly data)
- **Rationale**:
  - Avoid abnormal open volatility + allow RSI calculation from 09:15 candle
  - Weekly hedge enters in separate candle to ensure monthly is fully established first
  - Prevents simultaneous entry timing issues and ensures proper trade sequencing

#### 2.1.2 Engine Start Immediate Entry (First Trade Priority)
**Behavior**: When the trading engine starts with **no active positions**, it MUST attempt immediate entry regardless of time of day (within market hours), unless prohibited by D-1 restriction.

**Critical Requirements**:
1. **RSI Calculation Required**: Engine MUST calculate RSI(14) before entry using one of these data sources:
   - **Primary**: Live captured data stored in TimescaleDB (requires 15 days of trading history)
   - **Fallback**: Nautilus historical data configured in backtest data sources (`data_sources.json`)
   - **Minimum**: 15 daily closing prices required for valid RSI calculation

2. **Market Direction Determination**: Use calculated RSI to determine spread type:
   - RSI < 45 → BEARISH (Bear Call Spread)
   - RSI > 55 → BULLISH (Bull Put Spread)
   - 45 ≤ RSI ≤ 55 → Apply neutral zone tie-breaker (Section 2.4)

3. **Entry Prohibition Override**: Only skip immediate entry if:
   - Current time is after 12:30 PM on D-1 of ANY expiry (weekly or monthly)
   - RSI calculation fails (insufficient data)
   - VIX > 18 (extreme volatility)
   - Market is closed

**Rationale**: Ensures continuous market coverage by entering immediately when engine starts, rather than waiting for next scheduled entry window (which could be hours or days away). This is critical for paper trading where engine may start mid-day after deployments or restarts.

**Implementation**: First check on engine start bypasses scheduled entry windows (10:00-10:20 AM) and entry day restrictions (Monday/Wednesday). This is a ONE-TIME check; subsequent entries follow normal scheduling rules.

### 2.2 Entry Day Selection

| Scenario | Rule |
|----------|------|
| **Regular Entry** | Wednesday (Thu expiry) or Monday (Tue expiry) |
| **Initial Entry** | Any day except expiry days (if no positions exist) |
| **Prohibited Days** | Never on expiry day or day before weekly expiry |
| **D-1 Time Restriction** | No new trades after 12:30 PM on D-1 of ANY expiry |
| **Re-entry** | Daily re-entry allowed after 5-minute cooldown |

**D-1 Entry Prohibition Rationale**: Weekly hedges created on D-1 after 12:30 PM provide minimal protection (< 24 hours) before exit, making them ineffective and costly.

### 2.3 Monthly Expiry Selection Logic

| Days to Current Month Expiry | Expiry to Use | Rationale |
|-------------------------------|---------------|-----------|
| **> 14 days** | Current month expiry | Sufficient time for theta decay |
| **≤ 14 days** | Next month expiry | Avoid gamma risk near expiry |
| **< 5 days (any expiry)** | Skip entry | Too close to expiry for safe entry |

### 2.4 Directional Bias Determination (RSI-Based with Neutral Zone Tie-Breaker)

**Primary Signal**: RSI (Relative Strength Index)
**Evaluation Period**: Last 14 days of hourly data (for paper trading execution)

**Decision Logic**:

#### Clear Directional Signals
- **RSI < 45**: BEARISH → Enter Bear Put Spread + Bull Call Hedge
- **RSI > 55**: BULLISH → Enter Bull Call Spread + Bear Put Hedge

#### Neutral Zone (45 ≤ RSI ≤ 55) - Adaptive Tie-Breaker

When RSI is in the **neutral zone (45-55)**, apply adaptive tie-breaker logic:

**First Trade (No Previous Position)**:
- RSI ≥ 50 → BULLISH (Bull Call Spread)
- RSI < 50 → BEARISH (Bear Put Spread)

**Subsequent Trades**:
- **If Previous Monthly Position Hit STOP-LOSS**:
  - Take **OPPOSITE** direction of previous trade
  - Example: Previous was BULLISH → SL exit → Current (RSI=52) → BEARISH
  - Rationale: Previous direction was wrong, try opposite approach

- **If Previous Monthly Position Hit ANY OTHER EXIT** (Profit, Time, VIX, Portfolio SL):
  - Use RSI as tie-breaker:
    - RSI ≥ 50 → BULLISH (Bull Call Spread)
    - RSI < 50 → BEARISH (Bear Put Spread)
  - Rationale: Previous trade was not directionally wrong, use current market signal

**Flip Logic Applies To**:
- New monthly positions (M1 → M2 → M3)
- Re-entries after cooldown (M1 → M1_R1 → M1_R2)
- Only triggered by **individual monthly spread stop-loss** (50% max loss threshold)

**Does NOT Apply To**:
- Weekly hedge direction (always opposite to monthly by design)
- VIX exits, time-based exits, profit exits (use RSI tie-breaker instead)

**Configuration** (`strategy_config.json`):
```json
{
  "entry_manager": {
    "neutral_rsi_tiebreaker": {
      "enabled": true,
      "neutral_zone_lower": 45,
      "neutral_zone_upper": 55,
      "flip_on_stop_loss": true
    }
  }
}
```

---

## 3. Exit Rules

### 3.1 Exit Triggers (Priority Order)

| Priority | Trigger | Action | Condition |
|----------|---------|--------|-----------|
| **1** | Portfolio Stop-Loss | EXIT ALL | Portfolio loss ≥ 5% of deployed capital |
| **2** | Individual Stop-Loss (with Catastrophic Override) | EXIT SPREAD or HOLD | Spread loss ≥ 50% of max loss (see 3.2.1 for override) |
| **3** | Combined Profit Target | EXIT BOTH | Combined P&L ≥ 60% of combined credit |
| **4** | Time-based D0 Monthly | EXIT MONTHLY | **≥1:00 PM (13:00)** on expiry day |
| **5** | Time-based D-1 Weekly | EXIT WEEKLY | **≥1:00 PM (13:00)** on D-1 |
| **6** | Daily Overnight Risk Exit | EXIT ALL | 3:00 PM daily (15:15 hourly) |

**Time-Based Exit Clarification (v2.7.0)**:
- **Flexible Timing**: Priorities 4 & 5 trigger at **1:00 PM or later** (hour ≥ 13), not hardcoded to exactly 13:00
- **Hourly Data**: With hourly candles, exits can occur at 13:15, 14:15, or 15:15 (any candle ≥ 1:00 PM)
- **Rationale**: Allows positions maximum time until at least 1:00 PM, accommodates delayed data availability
- **Implementation**: `if hour >= 13` instead of `if hour == 13 and minute == 0`

### 3.2 Individual Stop-Loss Rules

#### 3.2.1 Catastrophic Loss Override (OPTIONAL - v1.2.0) - "Ride It Out"

**Status**: ⚠️ **OPTIONAL FEATURE** - Not required for core strategy functionality
**Purpose**: Prevent time value penalty on catastrophic losses by holding to expiry.
**Default**: **DISABLED** (standard 50% stop-loss only)

**Rule**:
```
IF current_loss >= 90% of max_loss:
    → DO NOT EXIT (hold until expiry)
    → Loss will cap at 100% of max_loss at expiry
    → Avoids time value differential penalty (can be 100%+ of max loss)

ELSE:
    → Normal stop loss applies (exit at 50% of max_loss)
```

**Rationale**:
- **Problem**: Early exit on deep ITM positions incurs massive time value penalty
- **Example (M2)**: Exit at 226% of max loss (₹20,548) vs hold to expiry 100% (₹9,075)
- **Savings**: ₹11,473 by holding to expiry instead of exiting early
- **Logic**: If you're already at 90%+ loss, you're better off holding to expiry where loss is capped

**Thresholds**:
```
Normal Stop Loss:      50% of max_loss (exit immediately)
Catastrophic Zone:     90% of max_loss (hold, don't exit)
Max Loss at Expiry:    100% of max_loss (spread width - credit)
```

**Implementation**:
```python
def should_exit_on_stop_loss(current_loss, max_loss):
    loss_pct = (current_loss / max_loss) * 100

    if loss_pct >= 90:
        # Catastrophic zone - hold until expiry
        return False  # DO NOT exit
    elif loss_pct >= 50:
        # Normal stop loss zone - exit
        return True
    else:
        # Below threshold - no exit
        return False
```

**Backtest Impact** (M2 example):
- **Without override**: Loss = ₹20,548 (226% of max, exited with time value)
- **With override**: Loss = ₹9,075 (100% of max, held to expiry)
- **Savings**: ₹11,473 (52% reduction in catastrophic loss)

**Configuration** (`strategy_config.json`):
```json
{
  "exit_manager": {
    "catastrophic_override": {
      "enabled": true,
      "threshold_pct": 90,
      "comment": "Hold positions with loss >= 90% of max until expiry to avoid time value penalty"
    }
  }
}
```

### 3.3 Combined Profit Target Rules
- **Calculation**: Combined P&L = (Monthly P&L + Weekly P&L) / (Monthly Credit + Weekly Credit)
- **Target**: When combined profit reaches **60%**, exit BOTH spreads together
- **No Individual Exits**: Weekly spread CANNOT exit independently on profit target
- **Linked Positions**: Both spreads managed as ONE combined position

### 3.4 Linked Exit Behavior
- When monthly exits → weekly must exit
- When profit target hit → BOTH positions exit together
- **IMMEDIATE RE-ENTRY (v1.2.0)**: No cooldown for position-specific exits (see 3.5, 3.6)
- Portfolio stop-loss exits require 5-minute cooldown before re-entry

### 3.5 Immediate Re-entry After Exits (v1.2.0) - **CRITICAL CHANGE**

#### 3.5.1 Weekly Hedge Immediate Renewal (D-1 Exit)

**Rule**: When weekly hedge exits on D-1 at 1:00 PM (13:15 hourly), **immediately enter next week's hedge in the NEXT candle**.

**OLD Behavior (v1.1.0)**:
- Weekly exits at D-1 13:15
- Wait until D1 10:15 next day to renew (gap period)
- Monthly position unhedged overnight

**NEW Behavior (v1.2.0)**:
- **Weekly exits at D-1 13:15** → EXIT current weekly hedge
- **Same candle (13:15)**: Evaluate next weekly expiry
- **NEXT candle (14:15)**: Enter new weekly hedge for next week
- **No Gap Period**: Ensures ZERO time with unhedged monthly position

**Implementation Details**:
```python
# At 13:15 on D-1
if weekly_dte == 1 and hour == 13:
    exit_weekly_hedge()  # Close current weekly

    # IMMEDIATE re-entry evaluation
    next_weekly_expiry = get_next_weekly_expiry()  # 7+ days out
    if next_weekly_expiry:
        schedule_immediate_reentry(
            position_type="weekly",
            expiry=next_weekly_expiry,
            next_candle_timestamp=current_timestamp + timedelta(hours=1)  # 14:15
        )

# At 14:15 (NEXT candle after exit)
if has_pending_weekly_reentry():
    enter_new_weekly_hedge(next_weekly_expiry)  # ±0.1 delta strike
```

**Critical Requirements**:
- **No Cooldown**: Weekly hedge immediate re-entry bypasses 5-minute cooldown
- **Same-Day Re-entry**: Happens in NEXT candle (1 hour later), not next trading day
- **Direction**: ALWAYS opposite to monthly (doesn't change with monthly direction)
- **Delta Targeting**: Fresh ±0.1 delta strike selection for new weekly expiry
- **Retry Logic**: If entry fails at 14:15, retry at 15:15 (last candle before market close)
- **Monthly Protection**: Monthly position MUST NOT be left unhedged overnight

#### 3.5.2 Monthly Position Immediate Re-entry (All Exit Reasons)

**Rule**: When monthly position exits (for ANY reason), **immediately re-evaluate direction and enter next month's spread in the NEXT candle**.

**OLD Behavior (v1.1.0)**:
- Monthly exits → 5-minute cooldown
- Wait until next day 10:15 for re-entry
- Position remains idle for hours/days

**NEW Behavior (v1.2.0)**:
- **Monthly exits** → EXIT monthly spread + weekly hedge
- **Same candle**: Re-evaluate market direction (RSI-based, Section 2.4)
- **NEXT candle**: Enter new monthly spread + new weekly hedge
- **Direction Re-evaluation**: ALWAYS check RSI and apply tie-breaker logic

**Implementation Details**:
```python
# When monthly exits (any reason: stop-loss, profit, time, VIX)
def on_monthly_exit(exit_reason, previous_direction):
    # Exit both monthly and weekly together
    exit_monthly_position()
    exit_weekly_hedge()

    # IMMEDIATE direction re-evaluation
    current_rsi = calculate_rsi(last_14_days_data)
    next_direction = determine_direction(
        rsi=current_rsi,
        previous_exit_reason=exit_reason,
        previous_direction=previous_direction,
        use_flip_logic=(exit_reason == "individual_stop_loss")  # Section 2.4
    )

    # Schedule immediate re-entry for NEXT candle
    schedule_immediate_reentry(
        position_type="monthly",
        direction=next_direction,
        next_candle_timestamp=current_timestamp + timedelta(hours=1)
    )

# At NEXT candle (e.g., 14:15 if exit was at 13:15)
if has_pending_monthly_reentry():
    enter_monthly_spread(direction=next_direction, expiry=next_monthly_expiry)
    enter_weekly_hedge(direction=opposite(next_direction), expiry=next_weekly_expiry)
```

**Direction Re-evaluation Rules** (from Section 2.4):
- **RSI < 45**: BEARISH → Bear Put Spread + Bull Call Hedge
- **RSI > 55**: BULLISH → Bull Call Spread + Bear Put Hedge
- **45 ≤ RSI ≤ 55** (Neutral Zone):
  - If previous exit was **stop-loss** → FLIP direction (opposite of previous)
  - If previous exit was **profit/time/VIX** → Use RSI tie-breaker (RSI ≥ 50 → Bullish, RSI < 50 → Bearish)

**Critical Requirements**:
- **No Cooldown**: Monthly immediate re-entry bypasses 5-minute cooldown
- **Same-Day Re-entry**: Happens in NEXT candle (1 hour later)
- **Direction Re-evaluation**: MANDATORY RSI check before each re-entry
- **Weekly Hedge**: MUST create weekly hedge immediately with monthly
- **Retry Logic**: If entry fails, retry next candle until successful or market close
- **Exception**: Portfolio stop-loss exits → 5-minute cooldown + wait until next day 10:15

#### 3.5.3 Exceptions to Immediate Re-entry

**Portfolio Stop-Loss Exit**:
- Exit all positions immediately
- **5-minute cooldown** enforced
- **No same-day re-entry**: Wait until next trading day 10:15
- Rationale: Prevent rapid re-entry during portfolio-level crisis

**Market Close Proximity**:
- If exit happens at 15:15 (last candle), no immediate re-entry
- Wait until next trading day 10:15
- Rationale: Insufficient time to establish new positions safely

**D-1 Time Restriction**:
- No immediate re-entry after 12:30 PM on D-1 of ANY expiry
- Wait until next trading day 10:15
- Rationale: New positions need minimum time before next expiry

#### 3.5.4 Benefits of Immediate Re-entry

**Continuous Market Coverage**:
- No idle time between exits and re-entries
- Maximizes theta decay collection opportunities
- Ensures continuous monthly+weekly hedge coverage

**Faster Capital Deployment**:
- Capital returns to work in 1 hour (next candle) vs 1+ days
- Reduces opportunity cost of idle capital

**Risk Management**:
- Monthly ALWAYS has weekly hedge protection
- No overnight gaps without positions
- Direction re-evaluation ensures adaptive strategy

### 3.6 Overnight Risk Mitigation (v1.1.0) - CONFIGURABLE

**Purpose**: Prevent overnight gap risk exposure during 18-hour market closure (3:30 PM - 9:15 AM next day).

**Configuration** (`strategy_config.json`):
```json
"overnight_risk_mitigation": {
  "enabled": false,              // Set to true to activate feature
  "exit_hour": 15,               // Exit time (24-hour format)
  "exit_minute": 0,              // Exit minute
  "reentry_hour": 10,            // Re-entry time (24-hour format)
  "reentry_minute": 0,           // Re-entry minute
  "apply_to_monthly": true,      // Apply to monthly positions
  "apply_to_weekly": true        // Apply to weekly hedges
}
```

**Strategy** (when `enabled=true`):
- **Daily Exit**: Exit **ALL positions** (monthly + weekly) at configured exit time (default: 3:00 PM / 15:15 hourly execution)
- **Daily Re-entry**: Re-enter **ALL positions** at configured re-entry time (default: 10:00 AM / 10:15 hourly) next trading day
- **Applies to**: **BOTH monthly and weekly positions** (configurable via flags)
- **Exception**: D-1 weekly exit and D0 monthly exit take precedence (Priority 4, 5 > Priority 6)

**Rationale**:
- **Critical Issue**: M2 monthly position lost **226% of max loss** (₹20,548 vs ₹4,538 threshold) due to 18-hour overnight gap
- Hourly data checks cannot prevent losses occurring between market close (3:30 PM) and next open (9:15 AM)
- **Both monthly and weekly positions** exposed to overnight gap risk - must exit BOTH at 3 PM
- Live trading with broker stop-loss orders will mitigate this, but for hourly backtests, daily exits eliminate risk

**Implementation Details**:
- **Exit Time**: 3:00 PM (15:00) - executed at 15:15 hourly candle
- **Re-entry Time**: 10:00 AM (10:00) - executed at 10:15 hourly candle
- **Re-entry Direction**: Same spread type as exited position (Bull Put or Bear Call)
- **Re-entry Strike**: Fresh delta-based selection (±0.1 delta for weekly, ATM-200 for monthly)
- **No Cooldown**: Daily exits bypass 5-minute cooldown for re-entry next day
- **Skip Days**:
  - No re-entry on D0 of monthly expiry (normal D0 exit at 1 PM applies)
  - No re-entry on D-1 or D0 of weekly expiry (normal D-1 exit at 1 PM applies)

**Interaction with Other Rules**:
- **Priority 5 (D-1 Weekly)**: If today is D-1 for weekly, Priority 5 triggers at 1:00 PM, Priority 6 skipped for weekly
- **Priority 4 (D0 Monthly)**: If today is D0 for monthly, Priority 4 triggers at 1:00 PM, Priority 6 skipped for monthly
- **Priority 3 (Combined Profit)**: Combined profit target checked before daily exit
- **Priority 2 (Individual Stop)**: Individual stop-loss checked before daily exit
- **Priority 1 (Portfolio Stop)**: Portfolio stop-loss checked before daily exit

**Trade-off Analysis**:
- **Pros**: Eliminates overnight gap risk for ALL positions, prevents catastrophic losses like M2 (226%)
- **Cons**: Daily transaction costs for exit/re-entry of both positions, potential slippage
- **Net Benefit**: **Prevents catastrophic overnight losses** - M2 example shows this is CRITICAL
- **Note**: This feature is **DISABLED by default** (`enabled=false`) to allow baseline backtesting. Enable for overnight risk mitigation in hourly backtests or when broker stop-loss is unavailable.

---

## 4. Risk Management

### 4.1 Dual-Layer Stop-Loss System

#### Portfolio-Level Stop-Loss
| Parameter | Value | Description |
|-----------|-------|-------------|
| **Threshold** | 5% of deployed capital | Overall portfolio loss limit |
| **Action** | EXIT_ALL_POSITIONS | Close all spreads immediately |
| **Capital Deployed** | Sum of all active position margins | Dynamic calculation |
| **Check Frequency** | Every minute | Real-time monitoring |

**Example**: If ₹200,000 deployed, stop-loss triggers at ₹10,000 loss (5% of ₹200,000)

#### Individual Spread Stop-Loss
| Parameter | Value | Description |
|-----------|-------|-------------|
| **Threshold** | 50% of max spread loss | Per-spread loss limit |
| **Action** | EXIT_SPREAD | Close specific spread |
| **Check Frequency** | Every minute | Real-time monitoring |

**Max Spread Loss Calculation**:
- Max Loss = (Spread Width × Lot Size × Quantity) - Premium Collected
- For 200-point spread: (200 × 25 × 3) - Premium = 15,000 - Premium
- Stop-loss triggers at 50% of this calculated max loss

### 4.2 Risk Metrics & Limits

| Metric | Limit | Action if Breached |
|--------|-------|-------------------|
| **Max Concurrent Positions** | 2 (1 monthly + 1 weekly max) | Prevent new trades |
| **Total Positions per Month** | Unlimited | Track for reporting |
| **Margin Usage** | 80% of allocated | Block new positions |
| **Daily Loss** | 2% of capital | Stop new entries for day |
| **Portfolio Drawdown** | 10% | Halt all trading |
| **VIX Level** | > 18 | Exit all trades, resume when VIX < 18 |

**Position Limit Clarification**:
- **Concurrent Positions**: Maximum 1 monthly + 1 weekly hedge active at any time
- **Total Monthly Positions**: Unlimited - as positions close, new ones can open
- **Spread Identification**:
  - Monthly: `SPREAD_X` (e.g., SPREAD_1, SPREAD_2)
  - Weekly: `SPREAD_X_WEEKLY` (e.g., SPREAD_1_WEEKLY, SPREAD_2_WEEKLY)

### 4.3 Capital Management & Dynamic Lot Sizing (v3.0.0)

**Purpose**: Implement dynamic position sizing based on available capital with compound growth tracking.

#### 4.3.1 Capital Tracking

| Parameter | Value | Description |
|-----------|-------|-------------|
| **Initial Capital** | ₹400,000 | Starting portfolio capital |
| **Current Capital** | Dynamic | Updated after each trade (capital + P&L) |
| **Risk Per Trade** | 5% | Maximum risk per new position |
| **Max Deployment** | 80% | Maximum capital deployed at any time |
| **Compounding** | Enabled | Capital grows/shrinks with P&L |

**Capital Update Formula**:
```python
# After each trade exit
new_capital = current_capital + trade_pnl

# Example:
# Initial: ₹400,000
# Trade 1 P&L: -₹32,643
# New Capital: ₹400,000 - ₹32,643 = ₹367,357
```

#### 4.3.2 Dynamic Lot Sizing

**For Debit Spreads** (Bull Call, Bear Put):
```python
# Capital required per lot
capital_per_lot = max_loss_per_lot
                = net_debit_per_lot
                = abs(premium_received - premium_paid) per lot

# Maximum lots by risk limit
max_lots_by_risk = (current_capital × risk_pct) / capital_per_lot
                 = (current_capital × 0.05) / capital_per_lot

# Maximum lots by deployment limit
max_lots_by_deployment = (current_capital × max_deployment_pct) / capital_per_lot
                       = (current_capital × 0.80) / capital_per_lot

# Actual lots to trade
actual_lots = min(
    max_lots_by_risk,
    max_lots_by_deployment,
    max_lots_from_config  # Configured maximum (e.g., 3000 lots)
)

# Total quantity
total_quantity = actual_lots × lot_size (75 shares/lot)
```

**Example Calculation**:
```
Initial Capital: ₹400,000
Risk Per Trade: 5% = ₹20,000
Max Deployment: 80% = ₹320,000

For Bull Call Spread:
  Entry: BUY 22050 CE @ ₹519.83, SELL 22250 CE @ ₹413.02
  Net Debit per 75-share lot: (₹519.83 - ₹413.02) × 75 = ₹8,010.75
  Capital Required per Lot: ₹8,010.75

Max Lots by Risk:
  = ₹20,000 / ₹8,010.75 = 2.49 lots → 2 lots (round down)

Max Lots by Deployment:
  = ₹320,000 / ₹8,010.75 = 39.95 lots → 39 lots (round down)

Max Lots from Config: 40 lots (max_lots = 3000 shares / 75 = 40 lots)

Actual Lots = min(2, 39, 40) = 2 lots

Total Quantity = 2 × 75 = 150 shares
Capital Deployed = 2 × ₹8,010.75 = ₹16,021.50
```

**For Credit Spreads** (if used):
```python
# Capital required per lot (margin-based)
margin_per_lot = strike_width × lot_size × margin_pct
               = 200 × 75 × 0.25  # 25% margin typical
               = ₹3,750 per lot

# Maximum lots calculation (same formula as debit spreads)
max_lots_by_risk = (current_capital × risk_pct) / margin_per_lot
max_lots_by_deployment = (current_capital × max_deployment_pct) / margin_per_lot
actual_lots = min(max_lots_by_risk, max_lots_by_deployment, max_lots_from_config)
```

#### 4.3.3 Compounding Growth

**Post-Trade Capital Update**:
```python
# After every trade exit
current_capital = previous_capital + trade_pnl

# Track capital history
capital_history = []
capital_history.append({
    'timestamp': exit_timestamp,
    'previous_capital': previous_capital,
    'trade_pnl': trade_pnl,
    'new_capital': current_capital,
    'trade_id': trade_id
})
```

**Example Compounding Sequence**:
```
Trade 1 (M1):
  Starting Capital: ₹400,000
  Max Lots: 2 lots (150 shares)
  P&L: -₹32,643
  Ending Capital: ₹367,357

Trade 2 (M2):
  Starting Capital: ₹367,357
  Risk: ₹18,368 (5% of ₹367,357)
  Max Lots: 2 lots (lower due to reduced capital)
  P&L: +₹15,000
  Ending Capital: ₹382,357

Trade 3 (M3):
  Starting Capital: ₹382,357
  Risk: ₹19,118 (5% of ₹382,357)
  Max Lots: 2 lots
  P&L: +₹25,000
  Ending Capital: ₹407,357 (above initial capital!)
```

#### 4.3.4 Capital Management Rules

**Minimum Capital Threshold**:
```python
# If capital drops below threshold, reduce position sizing
min_capital_threshold = initial_capital × 0.50  # 50% of initial

if current_capital < min_capital_threshold:
    # Emergency mode: reduce risk per trade
    risk_pct = 2.5%  # Half the normal risk
    max_deployment_pct = 60%  # Reduce deployment
```

**Maximum Capital Threshold**:
```python
# If capital grows significantly, cap position sizing
max_capital_for_sizing = initial_capital × 2.0  # 2x initial

if current_capital > max_capital_for_sizing:
    # Use capped capital for lot sizing (prevent excessive concentration)
    sizing_capital = max_capital_for_sizing
else:
    sizing_capital = current_capital
```

#### 4.3.5 Portfolio Value Tracking

**Components**:
```python
portfolio_value = current_capital + unrealized_pnl

where:
  current_capital = cash + closed position P&L
  unrealized_pnl = sum of all open position P&L
```

**Tracking Fields** (in trade log):
```python
{
    'open_premium': capital_deployed,  # Debit paid or credit received
    'target_profit_value': max_profit × target_profit_pct,
    'max_profit': calculated_max_profit,
    'max_loss': calculated_max_loss,
    'portfolio_value': current_capital + unrealized_pnl,
    'capital_deployed': sum of all active position margins,
    'available_capital': current_capital - capital_deployed
}
```

#### 4.3.6 Configuration Parameters

**`strategy_config.json`**:
```json
{
  "capital_management": {
    "enabled": true,
    "initial_capital": 400000,
    "risk_per_trade_pct": 5.0,
    "max_deployment_pct": 80.0,
    "compounding_enabled": true,
    "min_capital_threshold_pct": 50.0,
    "max_capital_multiplier": 2.0,
    "margin_pct_credit_spreads": 25.0
  },
  "position_sizing": {
    "lot_size": 75,
    "max_lots": 40,
    "max_shares": 3000,
    "dynamic_sizing": true
  }
}
```

**Backward Compatibility**:
```json
{
  "capital_management": {
    "enabled": false  // Disable for fixed lot sizing (legacy mode)
  },
  "backtest": {
    "num_lots": 4,  // Fixed lot count when dynamic sizing disabled
    "total_quantity": 300
  }
}
```

#### 4.3.7 Implementation Requirements

**Risk Manager Responsibilities**:
1. Track current capital (updated after each trade)
2. Calculate max lots based on capital and risk limits
3. Validate position size before entry
4. Update capital after each exit
5. Maintain capital history log

**Position Manager Responsibilities**:
1. Pass calculated lot size to entry manager
2. Track open premium (capital deployed)
3. Calculate target profit value on entry
4. Update portfolio value on each tick
5. Log capital state with each trade

**Trade Log Fields** (new/corrected):
```python
# New fields to add
'open_premium': float  # Capital deployed (net debit or credit)
'target_profit_value': float  # Target profit in rupees
'portfolio_value': float  # Total portfolio value at trade time
'capital_deployed': float  # Sum of all active margins
'available_capital': float  # Free capital for new trades
'lot_size_reason': str  # Why this lot size (risk/deployment/config limit)
```

### 4.5 Trade Log Ordering Requirements

**Critical Requirement**: Trade log entries MUST maintain chronological order and reflect actual entry sequencing.

#### 4.5.1 Chronological Ordering
- **Rule**: All trade log entries MUST be sorted by `entry_timestamp` in ascending order
- **Purpose**: Enables accurate analysis of trade sequence, capital deployment timeline, and strategy behavior
- **Validation**: Trade log should be sortable by entry_timestamp without any out-of-order entries

#### 4.5.2 Position Entry Sequencing
**Initial Entry (New Monthly Spread)**:
1. **First**: Monthly spread legs appear in trade log (entry_timestamp = T)
2. **Second**: Weekly hedge legs appear in trade log (entry_timestamp = T+1 hour)

**Re-entry After Exit**:
- **Monthly exit with re-entry**: Monthly legs entered at T+1, weekly legs entered at T+2
- **Weekly exit with re-entry**: Only weekly legs entered at T+1 (monthly unchanged)

**Example Trade Log Order**:
```
Row  | Spread ID    | Entry Timestamp      | Position Type
-----|--------------|----------------------|---------------
1    | SPREAD_M1    | 2024-01-15 10:15 IST | Monthly (leg 1)
2    | SPREAD_M1    | 2024-01-15 10:15 IST | Monthly (leg 2)
3    | SPREAD_W1_M1 | 2024-01-15 11:15 IST | Weekly (leg 1)
4    | SPREAD_W1_M1 | 2024-01-15 11:15 IST | Weekly (leg 2)
```

**Invalid Trade Log Order** (DO NOT allow):
```
Row  | Spread ID    | Entry Timestamp      | Position Type
-----|--------------|----------------------|---------------
1    | SPREAD_W1_M1 | 2024-01-15 10:15 IST | ❌ Weekly before Monthly!
2    | SPREAD_M1    | 2024-01-15 10:15 IST | ❌ Same timestamp!
```

#### 4.5.3 Implementation Requirements
1. **Entry Timing**: Monthly spread MUST complete before weekly hedge starts
2. **Timestamp Separation**: Weekly hedge entry_timestamp MUST be > monthly entry_timestamp
3. **Trade Log Export**: Sort by entry_timestamp ASC before writing to CSV
4. **Validation**: Add assertion to ensure monthly appears before weekly for each spread set

**Rationale**:
- Prevents race conditions in trade execution
- Ensures proper capital allocation sequence (monthly deployed first, then weekly)
- Enables accurate performance analysis by maintaining true temporal order
- Facilitates debugging by showing actual execution sequence

---

## 5. Re-entry Logic (v1.2.0 - Immediate Re-entry)

### 5.1 Re-entry Execution Flow

#### 5.1.1 Immediate Re-entry Flow (Position-Specific Exits)

**When Monthly or Weekly Exits** (stop-loss, profit, time-based D-1/D0):
1. **Exit triggered** → Close position(s) immediately
2. **Same candle**: Evaluate next entry
   - Monthly: Re-evaluate direction (RSI + tie-breaker logic)
   - Weekly: Use opposite direction of monthly
   - Select next expiry (≥ 7 days DTE)
3. **NEXT candle** (1 hour later): Enter new position(s)
   - Monthly: Enter spread + weekly hedge together
   - Weekly: Enter new weekly hedge only
4. **No cooldown**: Skip 5-minute cooldown for immediate re-entry

**When Portfolio Stop-Loss Exits**:
1. Exit ALL positions immediately
2. Enter 5-minute cooldown state
3. Wait until next trading day 10:15 AM
4. Evaluate market conditions and re-enter

#### 5.1.2 Scheduled Re-entry Flow (Next Day)

**For Portfolio Stop-Loss or Last Candle Exits**:
1. Enter cooldown state (5 minutes for portfolio SL, wait for next day)
2. Evaluate market conditions at 10:15 AM next trading day
3. Check days to expiry (≥ 5 days required)
4. Re-enter monthly position first
5. Immediately enter weekly hedge (same timestamp)

### 5.2 Re-entry Conditions

#### 5.2.1 Immediate Re-entry Conditions (v1.2.0)
- **No Cooldown**: Bypasses 5-minute cooldown
- **Market Open**: Within trading hours (09:15 - 15:30 IST)
- **Next Candle**: Re-enters 1 hour after exit (next hourly candle)
- **Days to Expiry**: ≥ 5 days for selected expiry
- **Not Last Candle**: Exit not at 15:15 (market close)
- **Not After 12:30 PM D-1**: Not in D-1 restricted time window
- **Risk Limits**: All risk limits below thresholds
- **Direction Re-evaluation**: MANDATORY for monthly re-entries

#### 5.2.2 Delayed Re-entry Conditions (Portfolio SL)
- **Cooldown Complete**: 5 minutes passed since portfolio SL exit
- **Market Open**: Within trading hours (09:15 - 15:30 IST)
- **Entry Time Window**: 10:00-10:20 AM next trading day
- **Days to Expiry**: ≥ 5 days for selected expiry
- **Risk Limits**: All risk limits below thresholds

### 5.3 Re-entry Frequency
- **Immediate Re-entries**: No limit, happens in next candle after each exit
- **Daily Re-entries**: Unlimited after portfolio SL cooldown
- **Not Restricted to Wednesday**: Re-entry allowed on any valid trading day
- **Cooldown Exceptions**: No cooldown for position-specific exits (v1.2.0 change)
- **Direction Changes**: Re-evaluated on EVERY monthly re-entry

### 5.4 Re-entry Prioritization

**Priority 1: Immediate Re-entry** (v1.2.0)
- Monthly exits (stop-loss, profit, time D0) → Immediate monthly + weekly re-entry
- Weekly exits (time D-1) → Immediate weekly re-entry only
- Happens in NEXT candle (1 hour later)

**Priority 2: Scheduled Re-entry**
- Portfolio stop-loss exits → Wait until next day 10:15 AM
- Last candle exits (15:15) → Wait until next day 10:15 AM
- D-1 restricted exits → Wait until next valid trading day

---

## 6. Position Lifecycle States

### 6.1 State Transitions
```
IDLE → EVALUATING → ENTERING → ACTIVE → EXITING → COOLDOWN → IDLE
```

| State | Description | Duration |
|-------|-------------|----------|
| **IDLE** | No positions, ready for entry | Until entry conditions met |
| **EVALUATING** | Checking entry conditions | Real-time evaluation |
| **ENTERING** | Placing orders | Order execution time |
| **ACTIVE** | Positions open, monitoring | Until exit triggered |
| **EXITING** | Closing positions | Order execution time |
| **COOLDOWN** | Waiting before re-entry | 5 minutes |

### 6.2 Position Identifiers
- **Monthly Spreads**: `M1`, `M2`, `M3`, `M3_R1`, `M3_R2`...
  - `M3` = 3rd monthly position
  - `M3_R1` = 1st re-entry after M3 exit

- **Weekly Hedges**: `W1_M3`, `W2_M3`, `W3_M3_R1`...
  - `W1_M3` = 1st weekly hedge for monthly M3
  - `W2_M3` = 2nd weekly hedge for monthly M3 (renewal)
  - `W3_M3_R1` = 3rd weekly hedge for monthly M3_R1 (re-entry)

---

## 7. Data Requirements (Timing Constraints)

### 7.1 Hourly Candle Data Specification
**Data Frequency**: 1-hour candles
**Timestamp Format**: HH:15:00 (data available at :15 minutes past each hour)
**Available Hours**: 09:15, 10:15, 11:15, 12:15, 13:15, 14:15, 15:15

### 7.2 Timing Implications
**IMPORTANT**: All PRD times must be adjusted by +15 minutes for hourly data execution.

**Entry Times**:
- **PRD Specification**: 10:00 AM (strategy intent)
- **Actual Execution**: 10:15 AM (hourly candle available)

**Exit Times**:
- **PRD Specification**: 1:00 PM / 13:00 (strategy intent)
- **Actual Execution**: 1:15 PM / 13:15 (hourly candle available)

### 7.3 Required Market Data
- **NIFTY50 Spot Price**: Real-time LTP (Last Traded Price)
- **NIFTY50 Options Chain**: All strikes, all expiries, bid/ask/LTP/Greeks
- **India VIX**: Real-time VIX value
- **Historical Candles**: 1-hour OHLCV data (last 14 days for trend evaluation)
- **Options Greeks**: Delta, Gamma, Theta, Vega for all option legs

---

## 8. Performance Metrics

### 8.1 Target Metrics
| Metric | Target | Measurement Period |
|--------|--------|-------------------|
| **CAGR** | 18.7% | Annual |
| **Max Drawdown** | < 12.6% | Rolling |
| **Win Rate** | > 60% | Per trade |
| **Profit Factor** | > 1.5 | Cumulative |
| **Sharpe Ratio** | > 1.0 | Annual |

### 8.2 Trade Metrics (Per Position)
- Entry price (premium collected)
- Exit price (premium paid)
- P&L (absolute and percentage)
- Days held
- Exit reason
- Max favorable/adverse excursion

### 8.3 Portfolio Metrics
- Total capital deployed
- Available margin
- Current portfolio P&L
- Portfolio P&L percentage
- Max portfolio drawdown

---

## 9. Edge Cases & Special Handling

### 9.1 Expiry Collision Scenarios
- **Same-Day Weekly & Monthly Expiry**: Exit both at D-1, renew weekly on D1 of next week
- **Holiday Before Expiry**: Exit on last trading day before holiday
- **Market Closure**: Positions auto-exit at 3:25 PM on expiry day if not already closed

### 9.2 Order Execution Failures
- **Monthly Entry Fails**: Retry once, if fails again, skip entry for the day
- **Weekly Hedge Entry Fails**: Retry up to 7 times with next available weekly expiry
- **Exit Order Fails**: Keep retrying every minute until filled
- **Partial Fills**: Treat as failed, square off partial and retry full order

### 9.3 Market Disruptions
- **Circuit Breaker Hit**: Hold all positions, resume normal operation when market reopens
- **VIX Spike > 30**: Exit all positions immediately, resume when VIX < 30
- **Liquidity Issues**: Skip entry if bid-ask spread > 10% of option price

---

## 10. Configuration Parameters

### 10.1 Options Weekly Monthly Hedge Parameters
```json
{
  "capital": 400000,
  "lot_size": 75,
  "num_lots": 4,
  "total_quantity": 300,
  "strike_interval": 200,
  "weekly_delta_target": 0.1,
  "profit_target_pct": 60,
  "portfolio_stoploss_pct": 5,
  "individual_stoploss_pct": 50,
  "cooldown_minutes": 5,
  "entry_time": "10:00",
  "exit_time": "13:00",
  "vix_exit_threshold": 18
}
```

**Position Sizing Explanation**:
- `lot_size`: NIFTY standard lot size (75 shares per lot)
- `num_lots`: Number of lots to trade (4 lots - optimized for ₹400k capital)
- `total_quantity`: Calculated as `lot_size × num_lots` (75 × 4 = 300 shares)
- **Configuration**: Set in `strategy_config.json` under `"backtest"` section
- **Critical Rule**: Weekly hedges MUST use SAME lot count as monthly (no mismatches allowed)
- **Applies to**: Both monthly spreads AND weekly hedges use identical quantity

### 10.2 Timing Parameters (Hourly Data)
```json
{
  "entry_time_actual": "10:15",
  "exit_time_actual": "13:15",
  "market_open": "09:15",
  "market_close": "15:15",
  "candle_frequency": "1H"
}
```

---

## 11. Validation & Testing Requirements

### 11.1 Core Logic Validation
- [ ] ATM strike rounding logic (nearest 50-point strike)
- [ ] Credit spread structure (SELL ATM, BUY ATM±200)
- [ ] Delta-based weekly strike selection (±0.1 delta)
- [ ] Combined profit target calculation (60% threshold)
- [ ] Portfolio stop-loss trigger (5% of deployed)
- [ ] Individual stop-loss trigger (50% of max loss)
- [ ] Weekly hedge renewal on D1 after D-1 exit
- [ ] 5-minute cooldown enforcement
- [ ] D-1 entry prohibition after 12:30 PM

### 11.2 Edge Case Testing
- [ ] Tie 2-2 indicator scenario (continuity tiebreaker)
- [ ] Same-day weekly expiry handling (retry with next day)
- [ ] Weekly hedge creation failure (7 retries)
- [ ] VIX spike > 30 (exit all immediately)
- [ ] Partial order fills (treat as failed, retry)

---

## 12. Success Criteria

### 12.1 Strategy Performance
- ✅ CAGR ≥ 18.7% over backtesting period (Jan 2024 - Sep 2025)
- ✅ Max drawdown ≤ 12.6%
- ✅ Win rate ≥ 60%
- ✅ No monthly position without weekly hedge (100% hedge coverage)
- ✅ All exits execute within 5 minutes of trigger

### 12.2 Risk Management
- ✅ No portfolio loss exceeds 5% threshold
- ✅ No individual spread loss exceeds 50% threshold
- ✅ All D-1 exits execute by 1:00 PM (13:15 hourly)
- ✅ All VIX > 30 exits execute within 1 minute

---

## Glossary

- **ATM (At-The-Money)**: Strike price nearest to current spot price
- **OTM (Out-Of-The-Money)**: Strike price away from spot (calls above, puts below)
- **CREDIT Spread**: Option spread where you collect net premium upfront
- **Delta**: Rate of change of option price with respect to underlying price
- **Theta Decay**: Time decay of option premium
- **D-1**: Day before expiry
- **D0**: Expiry day
- **D1**: Day after expiry (for hedge renewal)
- **LTP**: Last Traded Price
- **CE**: Call Option (European style)
- **PE**: Put Option (European style)

---

## Changelog

### v3.0.0 (October 13, 2025) - **CAPITAL MANAGEMENT & DYNAMIC LOT SIZING**
- **MAJOR FEATURE**: Implemented comprehensive capital management system
- **Section 4.3**: Added complete capital management & dynamic lot sizing framework
  - Capital tracking with compounding growth
  - Dynamic lot sizing based on risk and deployment limits
  - Portfolio value tracking (capital + unrealized P&L)
  - Minimum/maximum capital thresholds for position sizing
  - Risk per trade: 5% of current capital
  - Max deployment: 80% of current capital
- **Trade Log Fields**: Added new fields for capital management
  - `open_premium`: Capital deployed (net debit or credit) - **FIX for bug where it was 0**
  - `target_profit_value`: Target profit in rupees - **FIX for bug where it was 0**
  - `portfolio_value`: Total portfolio value at trade time
  - `capital_deployed`: Sum of all active position margins
  - `available_capital`: Free capital for new trades
  - `lot_size_reason`: Explanation of why lot size was chosen
- **Configuration**: New `capital_management` and `position_sizing` sections in config
- **Backward Compatibility**: Can disable for fixed lot sizing (legacy mode)
- **Rationale**:
  - Maximize capital usage through dynamic position sizing
  - Implement compound growth (capital increases/decreases with P&L)
  - Risk management through percentage-based limits
  - Example: With ₹400k capital and 5% risk, Trade 1 uses 2 lots (150 shares) instead of fixed 4 lots (300 shares)
- **Impact**:
  - Position sizes adapt to available capital
  - Losses reduce future position sizes (risk control)
  - Profits increase future position sizes (compound growth)
  - More efficient capital allocation
  - Better risk management

### v2.7.0 (October 11, 2025) - **FLEXIBLE D-1 EXIT TIMING**
- **Section 3.1**: Updated time-based exit conditions (Priorities 4 & 5)
  - Changed from hardcoded "1:00 PM (13:00)" to "**≥1:00 PM (13:00)**"
  - Implementation: `if hour >= 13` instead of `if hour == 13 and minute == 0`
- **Rationale**: Allows flexibility for delayed data or later exit candles
- **Impact**: Positions can exit at any hour ≥ 13 (13:15, 14:15, or 15:15 with hourly data)
- **Timing Clarification**: Added explicit note about flexible timing for D-1 and D0 exits

### v1.3.0 (October 11, 2025) - **SPREAD TYPE CORRECTION**
- **CRITICAL CHANGE**: Corrected monthly spread types to align with directional intent
- **Section 1.1, 1.2**: Changed from credit spreads to debit spreads
  - **BULLISH**: Bull Put Spread → **Bull Call Spread** (BUY ATM Call, SELL ATM+200 Call)
  - **BEARISH**: Bear Call Spread → **Bear Put Spread** (BUY ATM Put, SELL ATM-200 Put)
- **Section 1.2 (Weekly Hedge)**: Updated hedge types to match
  - Monthly Bull Call → Weekly Bear Put Hedge
  - Monthly Bear Put → Weekly Bull Call Hedge
- **Section 2.4**: Updated all RSI-based directional rules to reflect correct spread types
- **Section 3.5.2**: Updated direction re-evaluation rules
- **Rationale**:
  - Bull Call Spread profits when market moves UP (bullish directional bet)
  - Bear Put Spread profits when market moves DOWN (bearish directional bet)
  - Previous Bull Put/Bear Call spreads were credit spreads (seller's position)
  - New Bull Call/Bear Put spreads are debit spreads (buyer's position with directional conviction)
- **Impact**: Strategy now correctly aligns with directional market view
- **Note**: Code implementation to follow in separate commit

### v1.2.0 (October 9, 2025) - **IMMEDIATE RE-ENTRY**
- **CRITICAL CHANGE**: Implemented immediate re-entry after position exits
- **Section 3.5**: Completely rewritten - Weekly hedge renewal happens in NEXT candle (not next day)
- **Section 3.5.2**: Monthly re-entry happens in NEXT candle after any exit (not next day)
- **Section 5**: Updated re-entry logic to support immediate re-entry flow
- **Key Changes**:
  - Weekly D-1 exit at 13:15 → New weekly entry at 14:15 (same day, next candle)
  - Monthly exit (any reason) → New monthly + weekly at next candle (1 hour later)
  - Direction re-evaluated on EVERY monthly re-entry (RSI + tie-breaker logic)
  - No cooldown for position-specific exits (only for portfolio stop-loss)
  - Ensures ZERO time with unhedged monthly positions
  - Maximizes capital deployment and theta decay collection
- **Rationale**: Eliminate idle time, ensure continuous market coverage, faster capital deployment
- **Impact**: Higher position turnover, continuous hedging, adaptive direction re-evaluation

### v1.1.0 (October 7, 2025)
- **Added**: Priority 6 - Daily hedge exit at 3:00 PM for overnight risk mitigation
- **Added**: Section 3.6 - Overnight Risk Mitigation strategy
- **Rationale**: Prevent overnight gap risk (18-hour market closure exposure)
- **Impact**: Weekly hedges exit at 3:00 PM daily, re-enter at 10:00 AM next day

### v1.0.0 (October 6, 2025)
- Initial core strategy specification

---

_This PRD is environment-agnostic and serves as the foundation for both backtesting and live/paper trading implementations._
