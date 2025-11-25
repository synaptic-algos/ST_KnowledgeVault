---
artifact_type: story
created_at: '2025-11-25T16:23:21.869811Z'
id: AUTO-14_LOT_SIZE_AND_PARTIAL_FILL_HANDLING
manual_update: 'true'
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: '001'
status: pending
title: Auto-generated title for 14_LOT_SIZE_AND_PARTIAL_FILL_HANDLING
updated_at: '2025-11-25T16:23:21.869814Z'
---

## Nautilus Quantity Model

### Instrument Registration
- When we register NSE option instruments, we explicitly pass `lot_size=Quantity.from_int(75)` and `min_quantity=Quantity.from_int(75)` so Nautilus enforces 1-lot granularity (`src/runners/backtest/execution/single_executor.py:533-567`).  
- `lot_size` controls tick-value/P&L scaling inside Nautilus’ matching engine; `min_quantity` ensures the venue rejects orders smaller than one lot, while `max_quantity` caps exposures for sanity.

### Strategy Conversion
- Strategy code keeps everything in **lots** until it has to submit an order. For exits we read the live `position.quantity` (already in units) and pass it straight into `Quantity.from_int(actual_quantity)` so the order closes exactly what the engine thinks is open (`src/strategy/options_monthly_weekly_hedge_strategy.py:1304-1345`).  
- On entry, spread builders multiply desired lot count by the stored `lot_size` pulled from `self.cache.instrument()` so risk limits/gross exposure stay aligned with exchange constraints (`src/strategy/options_monthly_weekly_hedge_strategy.py:359-410`).

### Risk & P&L
- Risk metrics convert back to lots by dividing filled quantity by `lot_size`, e.g., `Spread.max_loss` assumes NIFTY’s 75-share lot when computing spread width × contracts (`src/models/spread.py:99-126`).  
- For live unrealized P&L, the strategy multiplies `(current_price - entry_price) * quantity * lot_size`, so storing the exact lot size in each `position_info` entry is mandatory for accurate per-leg stop-loss math (`src/strategy/options_monthly_weekly_hedge_strategy.py:2017-2070`).

---

## Partial Fill Lifecycle

### Fill States
- Every submitted leg is tracked through `LegExecutionState` (`PENDING → SUBMITTED → PARTIALLY_FILLED → FILLED/CANCELLED/...`) so we know exactly which legs need repair if something stalls (`src/execution/atomic_spread_executor.py:55-118`).  
- Even when `allow_partial_fills` is set to `False` in config, Nautilus can emit a `PARTIALLY_FILLED` update before we cancel. The executor therefore watches for these transitions and can either continue filling or roll everything back depending on `rollback_on_partial` (`src/config/strategy_config.py:173-211`, `src/execution/atomic_spread_executor.py:120-214`).

### Rollback Strategy
- `RollbackHandler` inspects each `LegExecution` and issues compensating orders for any filled or partially filled legs to avoid orphaned exposure. It supports market-close, limit-close, hedge-first, and wait-and-close strategies, selected automatically by priority (`src/execution/rollback_handler.py:1-170`).  
- Atomic execution mode (`ExecutionMode.ATOMIC`) submits all legs simultaneously and cancels on the first failure; other modes (sequential, best-effort) loosen the guarantee but still report partials through the same state machine (`src/execution/atomic_spread_executor.py:101-214`).

### Reporting & Enrichment
- The Nautilus `Position` object exposes `peak_qty` (maximum filled quantity). For partially filled orders, that does **not** equal the requested quantity, so the enricher fetches `order.quantity` via `opening_order_id` to compute the real `number_of_lots` and store an audit trail (`src/enrichment/trade_enricher.py:378-414`).  
- Spread metadata copies `spread_max_loss`, `spread_max_profit`, and `lot_size` into each leg as soon as all legs are open, so later stop-loss checks don’t divide by 1 (the bug documented in `issues/identified/20251107_091500_incorrect_stop_loss_pnl_calculation.md` is addressed in `src/strategy/options_monthly_weekly_hedge_strategy.py:359-418`).

---

## Best Practices Checklist

1. **Register instruments with the real lot contract**  
   - Set `lot_size`, `min_quantity`, and `price_increment` when calling `engine.add_instrument()` so Nautilus refuses illegal lot counts (`src/runners/backtest/execution/single_executor.py:533-567`).

2. **Store lot metadata per position**  
   - Capture `lot_size`, `spread_id`, and risk metrics inside `position_info` as soon as `PositionOpened` fires. This powers correct P&L and later exit sizing (`src/strategy/options_monthly_weekly_hedge_strategy.py:359-418`).

3. **Guard against partial fills even if you “disallow” them**  
   - Keep `allow_partial_fills`, `rollback_on_partial`, and `fill_or_kill` in sync and instrument `LegExecutionState` so partial fills are either completed or rolled back deterministically (`src/config/strategy_config.py:173-211`, `src/execution/atomic_spread_executor.py:101-214`, `src/execution/rollback_handler.py:1-170`).

4. **Use original order quantity for analytics**  
   - For reports and stop-loss math, read `order.quantity` via `opening_order_id` instead of `position.peak_qty`; otherwise partial fills masquerade as smaller trades (`src/enrichment/trade_enricher.py:378-414`).

5. **Convert lots at the last hop**  
   - Keep internal calculations in “lots,” only multiply by `lot_size` when creating a Nautilus `Quantity`. This avoids rounding drift and matches how exchanges see the order book.

Following this pattern keeps lot-size math, P&L, and rollback logic aligned with how Nautilus’ matching engine processes spreads, eliminating phantom exposure when partial fills or odd quantities sneak through.
