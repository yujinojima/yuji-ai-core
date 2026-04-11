---
name: capitulation-exhaustion-reversal
level: naive
project: freqtrade
parent_prim: none
created: 2026-04-11
last_validated: never
source_strategy: YujiExtinctionBurstStrategy.py
---

## Prim: capitulation-exhaustion-reversal
**Level:** naive
**Project:** freqtrade
**Parent:** none
**ABA Framework:** Extinction Burst — when reinforcement (upward price action) is suddenly removed, the organism (seller cohort) increases response rate and intensity before exhausting and stopping.

### Rule
N ≥ 5 consecutive red candles + volume > 3× SMA(20) + RSI(14) < 20 + MFI(14) < 12 + reversal candle (bullish close after red run) + price below 2.5σ BB → long to BB middle or RSI > 55. Secondary: N ≥ 3 reds + RSI < 22 + volume > 2.5× + lower wick > 50% of range + Stoch < 10 + below BB.

### Mechanism
Wyckoff Selling Climax / ABA Extinction Burst. Seller cohort exhausts through accelerating volume-intensity (more sellers, larger candles) during consecutive reds. The volume spike at the extreme reveals large-buyer absorption of forced sellers. When sellers are absorbed, the cohort collapses and trapped shorts must cover. The reversal candle is the first evidence of this cohort collapse.

**Mechanistically distinct from all 5 existing freqtrade prims:**
| Prim | Mechanism | Trigger |
|---|---|---|
| rsi-oversold-mean-reversion | Oscillator exhaustion in ranging | RSI 25–35, no volume requirement |
| ema-pullback-dynamic-support | Trend-follower re-entry at level | EMA touch, no extreme RSI |
| liquidity-sweep-reversal | Stop cluster sweep at structural level | VP POC, CVD divergence |
| bullish-rsi-divergence | Two-pivot oscillator divergence | Price LL + RSI HL pair |
| hidden-bullish-rsi-divergence | Counter-trend short trap in uptrend | Price HL + RSI LL pair |
| **capitulation-exhaustion-reversal** | **Panic seller cohort exhaustion** | **Volume climax + consecutive reds + extreme RSI** |

### Conditions
- **Works when:** Genuine panic/crash event; large-format red candles with acceleration; seller cohort visible in volume (not mechanical drift); oversold across multiple oscillators simultaneously
- **Fails when:** Strong structured downtrend (consecutive reds = trend, not panic; each "reversal candle" is relief then continuation); news-driven gap-down without volume climax on close; no genuine buyer absorption at the low
- **Best pairs:** untested
- **Best timeframe:** 1h (code default); 4h context via informative

### Evidence
- **Source:** anecdote (code extraction only)
- **Certainty:** guess
- **Scope:** untested
- **Falsifiable:** untested
- **Data:** pending backtest

**Academic proxies (not crypto-specific):**
- Wyckoff Selling Climax (1931): high-volume reversal at extreme low = classic capitulation signal; established for equities/futures
- ABA Extinction Burst: behavioral psychology framework; applied to market agent modelling here — original mapping, not established literature
- PMC9920669 (crypto RSI): tested RSI < 30 reversals (underperform B&H). RSI < 20 is a MORE EXTREME threshold — not tested in the paper; cannot extend result

**No peer-reviewed crypto study on consecutive-red-streak reversal probability is known.**

### Limitations
1. **No regime gate** — code fires in any market; structural downtrends produce consecutive reds constantly, making the signal noise
2. **RSI < 20 threshold is untuned** — code default, no plateau test; may be too strict (low frequency) or too loose (catches trend) depending on pair/TF
3. **PMC9920669 cannot be extended**: it tested RSI < 30 (wider threshold, different context) — cannot import negative or positive result for RSI < 20 + volume climax
4. **Same-candle entry** on reversal_candle — no next-candle confirmation; sister prim research shows this costs 5–10pp WR
5. **Trailing stop (code default)** — sister prim (ema-pullback) showed ATR trailing kills edge (PF 2.0 → 0.603); this prim uses trailing with 1.2% positive offset, unvalidated
6. **Consecutive-red detection** uses cumcount logic — can mis-classify if a doji interrupts the streak
7. **Volume SMA(20) baseline**: in a crash, the first few panic candles inflate the SMA, making subsequent spikes harder to detect (denominator pollution)
8. **No minimum gap between signals** — can fire repeatedly during extended crash without throttle
9. **MFI < 12 is very strict** — unknown frequency; MFI requires OHLCV, sensitive to illiquid hours
10. **Signal frequency on BTC/ETH/target pairs**: unknown; genuine capitulation events may be monthly or quarterly — too infrequent for statistical validation

### Implementation
- **File:** `user_data/strategies/YujiExtinctionBurstStrategy.py`
- **Primary entry:** `extinction_burst` block (lines 194–206): consecutive_red.shift(1) ≥ 5 + volume_ratio > 3.0 + RSI < 18 + MFI < 12 + reversal_candle == 1 + close < bb_lower_wide
- **Secondary entry:** `partial_burst` block (lines 209–220): consecutive_red.shift(1) ≥ 3 + RSI < 22 + volume_ratio > 2.5 + lower_wick_ratio > 0.5 + stoch_k < 10 + close < bb_lower_wide
- **Tertiary entry:** `macro_capitulation` block (lines 222–231): 4h RSI < 25 + 1h RSI < 25 + volume_ratio > 2.0 + reversal_candle == 1
- **Parameters (untuned defaults):** `rsi_extreme` default=18 (range 12–25); `volume_spike_mult` default=3.0 (range 2.0–5.0); `mfi_extreme` default=12 (range 8–20); `consecutive_red_min` default=5 (range 3–8)
- **Exit:** BB middle + RSI > 55 | schedule_thinning + RSI > 60 | ratio_strain + RSI > 50
- **ABA companion signals:** `schedule_thinning` (successive highs with declining RSI = reinforcement thinning); `ratio_strain` (7+ of 10 candles up but net change < 2% = effort without reward)

### Conditions Log Entry
- **Works when:** Genuine panic event; consecutive reds with volume spike; multi-oscillator extreme (RSI + MFI + Stoch)
- **Fails when:** Structured downtrend (consecutive reds = trend continuation); no buyer absorption volume; news-driven gaps without climax candle
- **Last validated:** never

### 6th Regime Axis
Adds a distinct mechanism class to the 5-axis freqtrade partition:

| Regime | Prim | Level |
|---|---|---|
| Ranging (ADX < 20) | rsi-oversold-mean-reversion | sophisticated |
| Ranging-to-mild-trend (ADX < 30) | liquidity-sweep-reversal | sophisticated |
| Trending structural (ADX 25–35 rising) | ema-pullback-dynamic-support | sophisticated |
| Exhaustion / late-bear | bullish-rsi-divergence (regular) | sophisticated |
| Trending momentum (uptrend pullback) | hidden-bullish-rsi-divergence | sophisticated |
| **Panic capitulation (crash event)** | **capitulation-exhaustion-reversal** | **naive** |

### Recommended Research Path
**(A) RESEARCH — Wyckoff Selling Climax on crypto**: Find quantitative evidence for volume spike + consecutive down candle reversal on BTC/ETH. Search: "selling climax cryptocurrency", "capitulation volume reversal crypto backtest", arxiv/SSRN.
**(B) RESEARCH — Consecutive red candle streak reversal stats**: n-streak reversal base rates on BTC/ETH 1h data. Practitioner sources (QuantifiedStrategies, Coinmonks) or own OHLCV calculation.
**(C) BACKTEST-ANALYSIS** — own-data: count capitulation events on BTC/ETH 1h 2020–2025 to get signal frequency, then run primary vs secondary vs tertiary entry WR comparison.

### Sources
- `user_data/strategies/YujiExtinctionBurstStrategy.py` (lines 1–276, full strategy extraction)
- Wyckoff, R.D. (1931) *Studies in Tape Reading* — Selling Climax concept (equity/futures, pre-crypto; founding reference)
- Skinner, B.F. (1938) ABA extinction burst framework — behavioural psychology basis for strategy's agent model
