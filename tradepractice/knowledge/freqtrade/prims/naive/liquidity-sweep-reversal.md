---
name: liquidity-sweep-reversal
level: naive
project: freqtrade
parent_prim: none
created: 2026-04-10
last_validated: never
reaction_validated: assumed
---

## Situation

### Setup
Price has formed a visible swing low on the 15m chart. Resting stop-loss orders accumulate below the swing low (retail long stops, breakout short triggers). A higher-timeframe volume profile level (POC or VAL) sits near the swing low, concentrating institutional interest at that price zone.

### Trigger
Current candle's low wicks BELOW the prior swing low (sweeping the liquidity pool) but the candle closes BACK ABOVE the swing low with a bullish body (close > open).

### Reaction
- **Accepted:** CVD delta turns positive (net buying volume increasing), price holds above the swept level on the next 1–2 candles, no new low printed. Buyers absorbed the sweep supply.
- **Rejected:** Price closes below the swing low on subsequent candles, CVD stays negative — the sweep was a genuine breakdown, not a hunt. Sellers are in control.
- **Unclear:** Price oscillates around the swept level with low volume and flat CVD. No directional conviction.

### Agent Behaviour
- **Who is acting:** Institutional/algorithmic players who swept the liquidity (triggered stops) and are now accumulating at discount prices. Mean-reversion algos activating near VP levels.
- **Who is trapped:** Breakout short-sellers who entered on the wick below the swing low — they expected continuation lower. Retail longs whose stops were triggered (forced sellers providing cheap supply to institutions).
- **Who is wrong:** The breakout shorts. When price reclaims the swing low, their short positions are underwater and must be covered, providing upside fuel.

### Outcome
- **If accepted:** Upside continuation toward BB middle band or anchored VWAP from swing high. Trapped shorts covering adds fuel. Target: next volume profile level (POC or VAH).
- **If rejected:** Trend continuation lower. The sweep was real selling, not a stop hunt. Do not hold.
- **If unclear:** No action. Wait for CVD confirmation or next candle close.

## Rule
If price wicks below a prior swing low AND closes back above it with a bullish candle AND CVD delta is positive and rising → long bias toward next VP level (POC/VAH), conditional on acceptance (price holds above swept level).

## Mechanism
Stop-loss clusters below swing lows create liquidity pools. Institutional order flow sweeps these stops to fill large buy orders at lower prices (getting better fills from forced sellers). The wick-and-reclaim pattern reveals the sweep is complete — the market absorbed the sell liquidity and reversed. Trapped breakout shorts must cover, providing the mechanical fuel for the bounce. CVD confirms real buying pressure vs. a dead-cat bounce.

## Conditions
- **Works when:** Price near a significant VP level (POC or VAL); clear prior swing low with clustered stops; CVD turning positive; adequate volume (> 0.8x 20-SMA)
- **Fails when:** Strong macro downtrend (4h bearish); sweep at VP level with no CVD confirmation; low volume sweep (likely noise, not institutional); multiple consecutive sweeps (level is genuinely breaking)
- **Best pairs:** untested — hypothetically better on liquid pairs where institutional order flow is present
- **Best timeframe:** 15m (implemented in YujiSmartMoneyStrategy); likely too noisy on 5m, too slow on 1h
- **Best regime:** ranging to mildly trending; VP levels are most meaningful when price is rotating within a range

## Evidence

### Source Quality
- **Source:** anecdote (code extraction)
- **Certainty:** guess
- **Scope:** untested
- **Falsifiable:** untested
- **Reaction observed:** no — code fires on sweep candle without waiting for next-candle confirmation

### Data
- Period: pending backtest
- Trades: unknown
- Win rate: unknown
- Profit: unknown
- Max drawdown: unknown
- Sharpe: unknown
- Acceptance rate: unknown
- Rejection rate: unknown
- Unclear rate: unknown

## Limitations
- Swing high/low detection uses a simple 5-bar pivot — may miss significant levels or flag insignificant ones.
- CVD is approximated from candle close position within the bar (buy_ratio = (close - low) / range). This is a rough proxy for real order flow — actual CVD requires tick data or trade-level data not available in freqtrade.
- Volume Profile computation is a rolling O(n*m) loop recomputed every candle — computationally expensive and may not be stable on short lookbacks.
- The strategy fires on the sweep candle itself, not on confirmation of acceptance. Reaction validation is same-candle only (bullish close). An intermediate refinement would require next-candle hold.
- Anchored VWAP re-anchors on every new swing detection — if swings are frequent, AVWAP becomes unstable and less meaningful.
- No regime guard beyond RSI < 45 on the secondary signal. Primary signal has no RSI or trend filter.
- Sweep detection counts any wick below prior swing low — no minimum wick depth threshold, so noise wicks may trigger false signals.

## Implementation
- **File:** `user_data/strategies/YujiSmartMoneyStrategy.py`
- **Parameter:** `sweep_proximity_pct` (DecimalParameter, default=0.005); `cvd_period` (IntParameter, default=10); `vp_lookback` (IntParameter, default=100)
- **Code:** Primary entry at lines 179–187; sweep detection in `_detect_bullish_sweep()` (lines 270–282); CVD calculation lines 114–124; VP calculation in `_compute_volume_profile_series()` (lines 340–411)
- **Reaction detection:** not implemented — entry fires on sweep candle (bullish close above swing low). No next-candle confirmation. CVD is a proxy for reaction acceptance but is checked same-candle, not after the fact.

## Situation Log

| Date | Pair | TF | Setup | Trigger | Reaction | Outcome | Notes |
|------|------|----|-------|---------|----------|---------|-------|
| — | — | — | — | — | — | — | No observations yet |

## Refinement History
- 2026-04-10: Created as naive prim from YujiSmartMoneyStrategy.py code extraction
