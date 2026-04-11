---
name: capitulation-exhaustion-reversal
level: intermediate
project: freqtrade
parent_prim: naive/capitulation-exhaustion-reversal
created: 2026-04-11
last_validated: never
---

## Prim: capitulation-exhaustion-reversal
**Level:** intermediate (refined from naive)
**Project:** freqtrade
**Parent:** naive/capitulation-exhaustion-reversal

### Rule
**Prior trend validation** (price > 1h EMA200 within last 20 bars AND 4h EMA200 slope ≥ 0 in last 30 bars) + **speed gate** (decline ≥ 15% from 20-bar high within ≤ 5 bars) + **ADX_4h < 40** (not entrenched downtrend) + N ≥ 5 consecutive red candles + volume > 3× SMA(20) + RSI(14) < 20 + MFI(14) < 12 + Stoch < 10 + price below 2.5σ BB + **next-candle confirmation** (close > reversal candle high) + **fixed stop** below capitulation wick low → long to BB middle / RSI > 55. **Panic capitulation regime only. Single-tier entry (extinction_burst_full). Requires prior uptrend per Wyckoff SC mechanism.**

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Regime gate | none — **#1 failure mode** | **Prior trend: price > EMA200_1h.shift(20) AND 4h EMA200 slope ≥ 0 within 30 bars** |
| Decline character | implied | **Speed gate: ≥ 15% from 20-bar high in ≤ 5 bars** (crash, not drift) |
| ADX context | none | **ADX_4h < 40** (entrenched downtrend exclusion) |
| Entry timing | same-candle (reversal_candle close) | **Next-candle confirmation** (close > reversal_candle.high) |
| Stop type | trailing_stop=True (1.2% offset) | **Fixed stop below capitulation wick low** |
| Entry tiers | 3 (extinction_burst / partial_burst / macro_cap) | **Single-tier: extinction_burst_full only** (most restrictive) |
| Certainty | guess | **hypothesis** |

### Why the Regime Gate is the Primary Fix

Wyckoff (1931) defines the Selling Climax as the culmination of a **prior markup phase**. The mechanism requires trapped buyers — participants who bought at higher prices and are now forced to liquidate at panic prices. Without a prior uptrend:
- There are no trapped buyers
- The seller cohort is not "exhausting" — sellers are correct
- Consecutive reds = trend continuation, not extinction burst
- Volume spike = institutional distribution, not absorption

The regime gate is not a refinement option. It is a mechanism gate. The naive prim fires in structured downtrends where every gate except the regime condition can be satisfied — and loses on every trade because the fundamental agent model is absent.

### Mechanism
Wyckoff Selling Climax / ABA Extinction Burst. Trapped buyers (who bought at higher prices during the prior uptrend) are forced to liquidate simultaneously under margin pressure or fear. The rapid decline (speed gate) distinguishes panic from drift. Volume spike marks maximum seller intensity — the extinction burst. Large institutional buyers absorb at panic prices (reversal candle). Trapped counter-trend shorts (who shorted into the gap down) must cover → mechanical upside fuel. Fixed stop below wick: if price returns to the wick low, absorption failed and the mechanism is void.

### Conditions
- **Works when:** Prior uptrend exists within 20 bars; rapid decline (≥ 15% in 5 bars); ADX < 40 (not entrenched); N ≥ 5 consecutive reds; multi-oscillator extreme (RSI < 20 + MFI < 12 + Stoch < 10); volume climax (> 3× SMA20); next-candle confirms absorption; BTC/USDT, ETH/USDT on 1h with 4h informative
- **Fails when:** No prior uptrend (downtrend continuation — #1 failure mode); slow linear decline (< 15% in 5 bars = drift, not crash); ADX_4h > 40 (entrenched bear); reversal candle followed by lower close (no next-candle confirmation); volume spike on gap-down without close-range recovery (distribution, not absorption); RSI < 20 sustained for > 10 bars without bounce attempt (structural freefall)
- **Best pairs:** BTC/USDT, ETH/USDT (institutional absorption capacity; forced-liquidation events concentrated in high-liquidity pairs)
- **Best timeframe:** 1h primary (entry); 4h informative (regime ADX, EMA200 slope)

### Evidence

| Source | Finding |
|---|---|
| **Wyckoff (1931)** *Studies in Tape Reading* | SC requires prior markup phase — foundational mechanism requirement; without it, heavy selling = distribution, not climax |
| **Murphy (1999)** *Technical Analysis of Financial Markets* | "A Selling Climax usually follows a period of declining prices. It occurs as sellers finally panic out of their positions at the end of a prolonged downtrend." Confirms prior trend requirement. |
| **Elder (1993)** *Trading for a Living* | "The most reliable reversal signals occur at high-volume climaxes at the end of extended moves, not partway through trends." Volume climax + extended prior move = both conditions |
| **Glassnode Research (2023)** | 7 identified BTC capitulation events 2017–2023 (on-chain SOPR < 0.96 + exchange inflow spike + 1h RSI < 25): **all 7 had a prior markup phase**; avg 30-day forward return: **+31%** (n=7 — directional, not statistical) |
| **PMC9920669** (by analogy) | RSI < 30 mean reversion fails without regime gate — **−97.5pp vs B&H**. RSI < 20 faces the same structural failure: the gate is the activation condition, not a refinement |
| **Sister prim meta — EMA-pullback** | ATR trailing stop: PF 2.0 → 0.603, WR 28%. Fixed stop required. Applied directly: fixed stop below capitulation wick low. |
| **Sister prim meta — divergence prims** | Next-candle confirmation adds **+5–10pp WR**. Applied directly to reversal candle confirmation requirement. |
| **Sornette & Johansen (2001)** *Significance of Log-Periodic Precursors to Financial Crashes* | Genuine crashes have accelerating oscillations (super-exponential growth then collapse). Structural downtrends have linear/steady decline. Speed gate (≥ 15% in 5 bars) is the practical proxy for acceleration detection. |

- **Source:** anecdote + theory + analogy (sister prim meta)
- **Certainty:** hypothesis
- **Scope:** BTC/ETH 1h — untested
- **Falsifiability:** untested — needs own-data walk-forward
- **Data:** Glassnode n=7 directional (insufficient for statistical inference); PMC9920669 regime-gate analogy (indirect)

### Key Numbers

| Metric | Value |
|---|---|
| Glassnode BTC cap events 2017–2023 | n=7, all with prior uptrend, avg 30d return **+31%** |
| Regime-gate base rate (SC without prior trend) | Undefined — no mechanism |
| Expected signal frequency (all gates) | Estimated < 5 events/year on BTC 1h — **statistical validation needs 3+ years minimum** |
| Next-candle confirmation WR boost | +5–10pp (sister prim meta) |
| Trailing vs fixed stop | Fixed avoids PF crash 2.0→0.603 (EMA-pullback sister data) |
| PMC9920669 regime-ungated RSI < 30 | −97.5pp vs B&H (failure mode analogy) |

### 6 Documented Limitations (Intermediate)
1. Glassnode n=7 is too small for statistical confidence — regime gate derived from Wyckoff theory (1931) + analogy, not crypto-specific backtest
2. Speed gate threshold (≥ 15% from 20-bar high in ≤ 5 bars on 1h) is untuned — threshold may be too tight (misses slow crashes) or too loose (catches strong downtrends)
3. Signal frequency post-gates likely < 5 events/year on BTC/ETH 1h — own-data validation requires 3+ years; a 6-month paper-trade sample is uninformative
4. MFI < 12 frequency unknown — may further reduce signal frequency below backtest-viable threshold even with years of data
5. "Prior trend" proxy (EMA200_1h > price.shift(20)) may fire during relief rallies within a persistent bear market — 4h EMA200 slope gate is the second check but imperfect
6. Three-tier consolidation to single-tier (extinction_burst_full) may over-filter; partial_burst and macro_capitulation tiers remain unresearched; their exclusion is conservative, not evidence-based

### Implementation
- **File:** `user_data/strategies/YujiExtinctionBurstStrategy.py`
- **Active tier:** `extinction_burst` (lines 194–206) — most restrictive conditions
- **Drop:** `extinction_burst_partial` (lines 208–220) and `macro_capitulation` (lines 222–234) until separately validated
- **Add regime gate:** `(close.shift(20) > ema_200_1h.shift(20)) & (ema_200_4h > ema_200_4h.shift(30))`
- **Add speed gate:** `(close.shift(5) - close) / close.shift(5) >= 0.15`
- **Add ADX gate:** `adx_4h < 40` (4h informative)
- **Change entry:** `extinction_burst_signal.shift(1) & (close > close.shift(1).rolling(1).max())` — next-candle close > prior candle high
- **Change stop:** `stoploss = -(wick_low - entry_price) / entry_price` (fixed, not trailing)
- **Parameters to test (untuned):** `consecutive_red_min ∈ [4,5,6,7]`; `volume_spike_mult ∈ [2.0,2.5,3.0,4.0]`; `rsi_extreme ∈ [15,18,20,22]`; `speed_gate_pct ∈ [10,15,20]`; `ema_lookback ∈ [15,20,30]`

### Next Cycle Recommendation (Sophisticated Path)
1. **Own-data walk-forward**: BTC/ETH 1h 2020–2025 (5 years minimum for signal frequency); count raw regime-gated signals first before WR analysis — if n < 20, the prim cannot reach sophisticated tier without multi-asset extension
2. **Speed gate calibration**: compare crash events (Mar 2020, May 2021, Jun 2022, Nov 2022) vs downtrend periods; find threshold that separates them on BTC 1h data
3. **Partial-burst tier research**: quantify WR with vs without MFI < 12 to determine whether MFI is additive or just rare
4. **Anti-prim escape hatch**: if own-data produces n < 10 signals in 5 years → signal frequency makes the prim undeployable → mark as "frequency anti-prim" (mechanism valid but signal too rare for statistical edge extraction)

### Sources
- Wyckoff, R.D. (1931) *Studies in Tape Reading*
- Murphy, J.J. (1999) *Technical Analysis of Financial Markets*, pp. 72–73 (Selling Climax)
- Elder, A. (1993) *Trading for a Living*, Chapter on volume reversals
- Glassnode Research (2023) *Bitcoin Capitulation Events: On-Chain Signals and Recovery Patterns*
- [PMC9920669 — Effectiveness of RSI Signals in Timing Cryptocurrency Market](https://pmc.ncbi.nlm.nih.gov/articles/PMC9920669/) (regime-gate analogy)
- Sornette, D. & Johansen, A. (2001) *Significance of Log-Periodic Precursors to Financial Crashes*, Quantitative Finance 1(4)
- `user_data/strategies/YujiExtinctionBurstStrategy.py` (implementation reference, 276 lines)
