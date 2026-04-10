---
name: hidden-bullish-rsi-divergence
level: intermediate
project: freqtrade
parent_prim: naive/hidden-bullish-rsi-divergence
created: 2026-04-11
last_validated: never
---

## Prim: hidden-bullish-rsi-divergence
**Level:** intermediate (refined from naive)
**Project:** freqtrade
**Parent:** naive/hidden-bullish-rsi-divergence
**Companion:** intermediate/bullish-rsi-divergence (regular div, exhaustion regime — mutually exclusive by regime)

### Rule
**EMA ribbon ≥ 3 aligned** + ADX 20–45 rising + price > 1h EMA200 + **true 5-bar pivot pair** (8–40 candle separation) with price HL + RSI(14) LL (≥ 3pt gap, **RSI LL ≥ 30** — below 30 = regular-div territory, regime conflict) + **Fibonacci pullback ≤ 50% of prior impulse** + **MACD hist ≥ 0 at pivot-2** + **volume declining across pivots** + **next-candle confirmation** (close > pivot-2 close) + **hard mutual exclusivity** (reject if regular-div signal active same pair same candle) + 4h primary TF + fee-adjusted R:R ≥ 1:1.5 → long to prior swing high, stop below pivot-2 low.

### Mechanism
In an established uptrend, counter-trend shorts enter on a pullback expecting trend reversal. The oscillator marks a new low (RSI LL) — appearing to confirm their position — but price holds a higher low (HL), revealing the seller cohort is too thin to break structure. Counter-trend shorts are trapped; their forced covers + trend-following re-entries fuel the next impulse leg. Edge disappears when the pullback is too deep (>50% Fibonacci) because the trend structure is genuinely compromised, or when MACD is below zero because bearish momentum is dominant regardless of the oscillator divergence.

### Conditions
- **Works when:** EMA ribbon ≥ 3 aligned and rising; ADX 20–45 and rising (not just threshold); prior impulse leg clearly visible; corrective pullback ≤ 50% of that impulse; RSI LL occurs between 30–55 during pullback; MACD histogram ≥ 0 (trend momentum positive); volume at pivot-2 < volume at pivot-1; 4h primary; BTC/ETH or major alts in established bull phase
- **Fails when:** Nascent reversal misclassified as uptrend (**#1 failure mode** — hidden div without genuine trend becomes a bull trap); ADX < 20 (no trend) or ADX > 45 (parabolic — pullback entries ill-timed); RSI LL < 30 (overlap with regular-div exhaustion regime — regime partition conflict); pullback > 50% of prior impulse (trend structure breaking); MACD hist < 0 at pivot-2 (bearish momentum dominant); volume rising on pullback (distribution, not shallow correction); EMA ribbon degrading even if still aligned; hard mutual exclusivity violated (regular-div signal also active = conflicted regime detection)
- **Best pairs:** BTC/USDT, ETH/USDT in confirmed uptrend — exactly the pairs sister prim intermediate EXCLUDES via persistent-uptrend filter
- **Best timeframe:** 4h primary (convergent: FXOpen, ACY, Babypips, Alchemy Markets all specify 4h/daily for hidden div; 1h secondary; no sub-1h)

### Evidence
- **Source:** anecdote → hypothesis (4 convergent practitioner sources + mechanism derivation from sister-prim evidence chain)
- **Certainty:** hypothesis
- **Scope:** untested on own data; BTC/ETH trending-uptrend regime
- **Falsifiability:** untested — first implementation in Yuji codebase

**Evidence table:**

| Source | Finding |
|---|---|
| **FXOpen** | "Hidden divergence is used in trending markets" — directional opposite of regular div |
| **ACY** | Trend-continuation bias; 4h/daily more reliable than sub-1h for hidden div signals |
| **Babypips** | Hidden divergence "more reliable in trending markets than regular divergence" — explicit comparative claim |
| **Alchemy Markets** | Continuation signal — distinct mechanism from reversal (regular div) |
| **Murphy, TAOFM** | Fibonacci 50% retracement = critical boundary; corrections holding above 50% confirm trend structure intact |
| **Elder, Trading for a Living** | MACD zero-line = trend direction filter; MACD hist ≥ 0 = bullish momentum dominant |
| **Wyckoff accumulation principle** | Declining volume on corrective legs = weak sellers = shallow correction likely to resolve as continuation |
| **Sister prim research (convergent)** | Double-confirmation lifts WR 15–25pp vs single-oscillator; next-candle adds 5–10pp (LuxAlgo, Concord p2c, liquidity-sweep-reversal cycle) |
| **PMC9920669** | Tested ONLY regular divergence (rated LEAST EFFECTIVE RSI variant on crypto). **Hidden div NOT tested** — absence of negative evidence, not positive evidence. |

**Key numbers:**
- No direct crypto-specific WR data for hidden divergence
- Expected live WR (derived): **58–65%** — above sister prim's 55–62% target by the "more reliable in trends" practitioner adjustment, discounted by absence of own-data anchor
- Realistic lower bound after OOS degradation: **53–58%** (applying sister prim 25–50% OOS degradation floor)
- Signal frequency: unknown; estimated < 0.5% of candles (rarer than regular div ~0.8% because uptrend precondition narrows the universe)

### Limitations
1. No peer-reviewed crypto anchor — PMC9920669 did not test hidden divergence; all evidence is practitioner-source
2. Expected WR is derived by analogy from sister prim research — not directly measured
3. Fibonacci 50% filter: computed from swing-low to swing-high of prior impulse — swing detection quality carries through
4. True 5-bar pivot detection still imprecise; argrelextrema with order=5 misses multi-bar tops/bottoms
5. RSI ≥ 30 lower bound: derived constraint, not empirically validated — edge of boundary is untested
6. MACD hist ≥ 0 eliminates entries in deep corrections that still resolve as continuation (conservative but untested)
7. Signal frequency may be too low for statistical validation even after 30-day paper trade window
8. OOS degradation magnitude: expect 25–50% Sharpe loss (from sister prim walk-forward meta-analysis — applied by analogy)
9. ADX upper bound 45: parabolic exclusion is a judgment call; threshold untested for hidden div specifically
10. Mutual exclusivity hard gate: if both signals fire simultaneously it prevents trade — may miss valid entries on boundary regime

### Implementation
**File:** `user_data/strategies/YujiDivergenceStrategy.py` (extension, NOT a new file)

10 implementation gaps:
1. **Mirror pivot detection**: price HL via `scipy.signal.argrelextrema(close, np.greater, order=5)` on price; RSI LL via `argrelextrema(rsi, np.less, order=5)` — match pivot indices; confirm price makes HL (pivot-2 price > pivot-1 price) AND RSI makes LL (pivot-2 rsi < pivot-1 rsi)
2. **New IntParameters**: `hidden_divergence_lookback` (default 15, range 8–40) and `rsi_hidden_min_gap` (default 3, range 2–7)
3. **RSI floor constraint**: `rsi_at_pivot_2 >= 30` — reject if RSI LL < 30 (regular-div territory)
4. **EMA ribbon quality gate**: `ema_10 > ema_21 > ema_50 > ema_200` count ≥ 3 layers (consistent with ema-pullback-dynamic-support sophisticated)
5. **Fibonacci pullback depth**: `correction_depth = (prior_impulse_high - pivot_2_low) / (prior_impulse_high - prior_impulse_low)`; reject if `correction_depth > 0.50`
6. **MACD hist non-negative**: `macd_hist >= 0` at pivot-2 candle
7. **Volume declining**: `volume_at_pivot_2 < volume_at_pivot_1` (candle-volume at each pivot index)
8. **Next-candle confirmation**: `hidden_div_signal.shift(1) & (close > close.shift(1))`
9. **Hard mutual exclusivity**: `& ~buy_rsi_div & ~buy_macd_div & ~buy_double_div` — reject if regular-div detection is active on same pair/candle
10. **4h primary TF**: run on 4h dataframe; 1h as secondary for entry precision; no sub-1h

**Stop placement:** below pivot-2 low (same as sister prim)
**Target:** prior swing high (rolling 20-bar max)
**R:R gate:** `(target - close) / (close - stop) >= 1.5` post fee-adjustment

### Conditions Log Entry
- **Works when:** EMA ribbon ≥ 3 aligned, ADX 20–45 rising; true 5-bar pivot price HL + RSI LL (≥3pt gap, RSI ≥ 30); pullback ≤ 50% Fib; MACD hist ≥ 0; volume declining; next-candle close > pivot-2 close; 4h primary; BTC/ETH in bull phase; no regular-div signal active same pair
- **Fails when:** Trend misclassified (ADX < 20 or EMA ribbon degrading); RSI LL < 30 (exhaustion, not continuation); Fib > 50% (structure compromised); MACD hist < 0; volume rising on pullback; sub-1h TF; ranging/sideways regime; hard exclusivity conflict with regular-div
- **Last validated:** never (intermediate — 10-gap implementation pending; head-to-head backtest vs regular-div required to validate FXOpen/ACY/Babypips "more reliable in trends" claim)

### Sources
- [FXOpen — Hidden vs Regular Divergence](https://fxopen.com/blog/en/what-is-the-difference-between-regular-and-hidden-divergence/)
- [ACY — RSI Hidden Divergence](https://acy.com/en/market-news/education/how-to-spot-rsi-hidden-divergence-j-o-121814/)
- [Babypips — Hidden Divergence](https://www.babypips.com/learn/forex/hidden-divergence)
- [Alchemy Markets — Hidden Divergence](https://alchemymarkets.com/education/hidden-divergence/)
- [PMC9920669 — Effectiveness of RSI Signals in Timing Cryptocurrency Market](https://pmc.ncbi.nlm.nih.gov/articles/PMC9920669/) (regular-div negative result; hidden div NOT tested)
- [LuxAlgo — RSI at S/R: 60–65% WR with confirmation](https://www.luxalgo.com/blog/5-rsi-entry-strategies-using-support-and-resistance/)
- [Concord p2c — Structure-break confirmation adds 15–25pp WR](https://www.concordp2c.com/is-bullish-divergence-reliable-backtested-insights-and-common-mistakes-to-avoid/)
