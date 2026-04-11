---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T15:02:15+10:00
cycle: 23
---

---

## Prim: capitulation-exhaustion-reversal
**Level:** naive
**Project:** freqtrade
**Parent:** none
**Commit:** `7bda0f7`

### Rule
N ≥ 5 consecutive red candles + volume > 3× SMA(20) + RSI(14) < 20 + MFI(14) < 12 + reversal candle (bullish close after red run) + price below 2.5σ BB → long to BB middle / RSI > 55.

Secondary: N ≥ 3 reds + RSI < 22 + volume > 2.5× + lower wick > 50% of range + Stoch < 10 + below BB.

### Mechanism
Wyckoff Selling Climax / ABA Extinction Burst. The seller cohort escalates rate (consecutive reds) and intensity (volume spike) before exhausting. The volume spike at the extreme reveals large-buyer absorption. Reversal candle = first evidence of cohort collapse. Trapped counter-trend shorts must cover → mechanical upside fuel.

**Mechanistically distinct from all 5 existing sophisticated prims:**

| Prim | Mechanism | Key trigger |
|---|---|---|
| rsi-oversold-mean-reversion | Oscillator exhaustion in ranging | RSI 25–35, no volume req |
| liquidity-sweep-reversal | Stop cluster sweep | VP POC, CVD divergence |
| ema-pullback-dynamic-support | Trend re-entry | EMA touch, no extreme RSI |
| bullish-rsi-divergence | Two-pivot oscillator divergence | Price LL + RSI HL pair |
| hidden-bullish-rsi-divergence | Counter-trend short trap | Price HL + RSI LL in uptrend |
| **capitulation-exhaustion-reversal** | **Panic seller cohort exhaustion** | **Volume climax + N reds + RSI < 20** |

**6th regime axis:**

| Regime | Prim | Level |
|---|---|---|
| Ranging (ADX < 20) | rsi-oversold-mean-reversion | sophisticated |
| Ranging-to-mild-trend (ADX < 30) | liquidity-sweep-reversal | sophisticated |
| Trending structural (ADX 25–35) | ema-pullback-dynamic-support | sophisticated |
| Exhaustion / late-bear | bullish-rsi-divergence | sophisticated |
| Trending momentum (uptrend pullback) | hidden-bullish-rsi-divergence | sophisticated |
| **Panic capitulation (crash event)** | **capitulation-exhaustion-reversal** | **naive** |

### Evidence
- **Source:** anecdote (code extraction)
- **Certainty:** guess
- **Data:** pending — signal frequency, WR, and failure rate on BTC/ETH 1h all unknown
- **PMC9920669 CANNOT be applied:** tests RSI < 30 (different threshold, different multi-factor context)

### 10 Documented Limitations
1. No regime gate — fires in structural downtrend where consecutive reds = trend, not panic (#1 failure mode)
2. Same-candle entry on reversal_candle — no next-candle confirmation (−5–10pp WR per sister prim data)
3. Trailing stop (code default) likely kills edge — sister prim (ema-pullback) showed PF 2.0 → 0.603 with ATR trail
4. Three-tier entry conflates quality — extinction_burst vs partial_burst vs macro_capitulation need per-tier WR separation
5. MFI < 12 frequency unknown — may fire < 5×/year on BTC/ETH 1h
6. Volume SMA(20) denominates with early-crash candles — baseline inflates, suppressing later spike detection
7. No minimum gap between signals — can fire repeatedly during extended crash
8. Parameters (RSI < 18, MFI < 12, 5 reds, 3× volume) are code defaults, not plateau-verified
9. Consecutive-red cumcount mislabels if a doji interrupts the streak
10. No peer-reviewed crypto anchor for RSI < 20 + volume climax reversal

### Recommended Research Path (Intermediate)
- **(A) Wyckoff Selling Climax crypto quantification** — find backtest data for volume spike at N-consecutive-down-day extremes on BTC/ETH; arxiv/SSRN search "selling climax cryptocurrency", "panic reversal volume crypto"
- **(B) Consecutive red streak reversal base rates** — own OHLCV calculation on BTC/ETH 1h 2020–2025: given N ≥ 5 consecutive reds + RSI < 20, what is the unconditional reversal rate at 1, 3, 5 candles forward?
- **(C) Regime gate research** — quantify the trend vs capitulation disambiguation: does 4h EMA200 slope + ADX filter separate genuine crashes (viable) from trending breakdown (false signal)?

### Implementation
- **File:** `user_data/strategies/YujiExtinctionBurstStrategy.py`
- **Primary:** `extinction_burst` (lines 194–206)
- **Parameters (untuned):** `rsi_extreme`=18 (12–25); `volume_spike_mult`=3.0 (2.0–5.0); `mfi_extreme`=12 (8–20); `consecutive_red_min`=5 (3–8)
- **ABA companion indicators:** `schedule_thinning` (successive highs with declining RSI = reinforcement thinning); `ratio_strain` (7+ of 10 up candles, < 2% net change = effort without reward)

### Bank State After Cycle 23

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | **1** (capitulation-exhaustion) | 0 |
| Intermediate | 0 | 0 |
| Sophisticated | 5 | 4 |

### Next Cycle Recommendation
**(A) RESEARCH** — find quantitative evidence for the Wyckoff Selling Climax mechanism on crypto. Primary search target: consecutive-red-streak reversal base rates on BTC/ETH + volume spike at extreme + RSI < 20 reversal probability. This is the minimum evidence needed to refine to intermediate. A single practitioner backtest with WR numbers would be sufficient to advance.
**(B) RESEARCH** — regime gate: is there a quantitative way to separate genuine crash/capitulation events (viable) from structured downtrend continuation (false signal)? Candidates: prior ADX trend direction, 4h context, time-since-ATH, drawdown magnitude threshold.

### Sources
- `user_data/strategies/YujiExtinctionBurstStrategy.py` (full extraction, 276 lines)
- Wyckoff, R.D. (1931) *Studies in Tape Reading* — Selling Climax (equity/futures foundational concept)
- Skinner, B.F. (1938) — ABA extinction burst (behavioural psychology basis for agent model)
