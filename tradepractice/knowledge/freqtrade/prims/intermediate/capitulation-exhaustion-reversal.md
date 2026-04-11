---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T15:16:47+10:00
cycle: 25
---

Commit `3b444f4`.

---

## Prim: capitulation-exhaustion-reversal
**Level:** intermediate (refined from naive)
**Project:** freqtrade
**Parent:** naive/capitulation-exhaustion-reversal

### Rule
**Prior trend gate** (price > EMA200_1h within last 20 bars AND 4h EMA200 slope ≥ 0 in last 30 bars) + **speed gate** (decline ≥ 15% from 20-bar high in ≤ 5 bars) + ADX_4h < 40 + N ≥ 5 consecutive reds + volume > 3× SMA(20) + RSI < 20 + MFI < 12 + Stoch < 10 + BB 2.5σ + **next-candle confirmation** (close > reversal candle high) + **fixed stop** below wick low → long to BB middle / RSI > 55. **Single-tier (extinction_burst_full). Panic capitulation regime only.**

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Regime gate | none (#1 failure mode) | **Prior trend: price > EMA200_1h.shift(20) AND 4h EMA200 slope ≥ 0 within 30 bars** |
| Decline character | implied | **Speed gate: ≥ 15% from 20-bar high in ≤ 5 bars** (crash not drift) |
| ADX context | none | **ADX_4h < 40** (entrenched downtrend exclusion) |
| Entry timing | same-candle | **Next-candle**: close > reversal candle high |
| Stop type | trailing_stop=True (1.2% offset) | **Fixed stop below capitulation wick low** |
| Entry tiers | 3 tiers | **Single-tier: extinction_burst_full only** |
| Certainty | guess | **hypothesis** |

### Why the Regime Gate is the Mechanism Gate (Not a Refinement)

Wyckoff (1931): Selling Climax requires a preceding markup phase. Without it, there are no trapped buyers — the seller cohort is not exhausting, it is correct. Every naive-prim condition (N reds, RSI < 20, volume spike) can be satisfied inside a structural downtrend, and every trade loses because the fundamental agent model is absent. PMC9920669 shows the identical structural failure on the analogous RSI < 30 signal (−97.5pp vs B&H ungated). The gate activates the mechanism; it does not narrow a working signal.

### Evidence — 8 Sources

| Source | Finding |
|---|---|
| **Wyckoff (1931)** | SC requires prior markup — foundational mechanism requirement |
| **Murphy, TAOFM (1999)** | "Selling Climax follows a period of declining prices after a peak" — prior trend textbook definition |
| **Elder, Trading for a Living (1993)** | Reliable reversals at high-volume climaxes "at the end of extended moves, not partway through trends" |
| **Glassnode (2023)** | 7 BTC capitulation events 2017–2023: **all 7 had prior uptrend**, avg 30d return **+31%** (n=7 — directional, not statistical) |
| **PMC9920669** (analogy) | RSI < 30 ungated = −97.5pp vs B&H; regime gate is the activation condition |
| **Sister prim: EMA-pullback** | Trailing stop → PF 2.0→0.603, WR 28%; **fixed stop required** |
| **Sister prim: divergence** | Next-candle confirmation: **+5–10pp WR** |
| **Sornette & Johansen (2001)** | Genuine crashes = accelerating decline (super-exponential); trends = linear; speed gate is the practical proxy |

### Key Numbers

| Metric | Value |
|---|---|
| Glassnode BTC cap events with prior uptrend | 7/7 (100%) — mechanism required |
| Avg 30d forward return post-cap (n=7) | **+31%** |
| Regime-ungated RSI < 30 on crypto | −97.5pp vs B&H (PMC9920669) |
| Next-candle confirmation WR boost | +5–10pp (sister prim meta) |
| Trailing vs fixed stop (EMA-pullback) | PF crash 2.0→0.603 avoided |
| Estimated signal frequency (all gates, BTC 1h) | **< 5/year** — needs 3+ years for statistical validation |

### 6 Documented Limitations (Intermediate)
1. Glassnode n=7 too small for statistical inference; regime gate is Wyckoff-theoretical + analogy, not crypto-derived
2. Speed gate threshold (15% / 5 bars) untuned — may be too tight (misses slow crashes) or too loose (admits strong downtrends)
3. Signal frequency < 5/year post-gates — backtest validation requires 3+ years minimum; 6-month paper-trade uninformative
4. MFI < 12 may further reduce frequency below viable threshold even with years of data
5. Prior-trend proxy may fire during relief rallies inside persistent bear markets — 4h slope gate is second check but imperfect
6. partial_burst and macro_capitulation tiers excluded without evidence — conservative, not researched

### Implementation Gaps (YujiExtinctionBurstStrategy.py)
1. Regime gate: `(close.shift(20) > ema_200_1h.shift(20)) & (ema_200_4h > ema_200_4h.shift(30))`
2. Speed gate: `(close.shift(5) - close) / close.shift(5) >= 0.15`
3. ADX_4h < 40 guard (4h informative)
4. Next-candle: `extinction_burst_signal.shift(1) & (close > close.shift(1))`
5. Fixed stop: `stoploss = -(wick_low - entry_price) / entry_price` — remove `trailing_stop=True`
6. Drop `extinction_burst_partial` and `macro_capitulation` blocks until separately validated

### Bank State After Cycle 25

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | **0** | 1 (obi-informed-directional) |
| Intermediate | **1** (capitulation-exhaustion-reversal) | 0 |
| Sophisticated | 5 | 4 |

### Next Cycle Recommendation
**IMPLEMENT** — implement the 6-gap list above in `YujiExtinctionBurstStrategy.py`; regime gate + speed gate + next-candle confirmation + fixed stop are the minimum viable intermediate implementation. After implementation: count raw regime-gated signals on BTC/ETH 1h 2020–2025 historical data — if n < 20 signals in 5 years, frequency anti-prim (mark and move on); if n ≥ 20, proceed to parameter plateau test (`consecutive_red_min`, `volume_spike_mult`, `rsi_extreme`, `speed_gate_pct`).
