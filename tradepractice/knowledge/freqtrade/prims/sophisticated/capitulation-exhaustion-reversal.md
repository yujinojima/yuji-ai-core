---
name: capitulation-exhaustion-reversal
level: sophisticated
project: freqtrade
parent_prim: intermediate/capitulation-exhaustion-reversal
created: 2026-04-11
last_validated: never
---

## Prim: capitulation-exhaustion-reversal
**Level:** sophisticated (refined from intermediate)
**Project:** freqtrade
**Parent:** intermediate/capitulation-exhaustion-reversal

### Rule
**Prior trend gate** (price > EMA200_1h within last 20 bars AND 4h EMA200 slope ≥ 0 in last 30 bars) + **maturation-adjusted dual speed gate** (≥ 10% decline from 20-bar high in ≤ 5 bars OR ≥ 15% in ≤ 10 bars — plateau-test both windows) + ADX_4h < 40 + N ≥ 5 consecutive reds + volume > 3× SMA(20) + RSI < 20 + MFI < 12 + Stoch < 10 + BB 2.5σ + next-candle confirmation (close > reversal candle high) + **dynamic stop sizing** (position size = 2% bankroll / |entry − wick_low|; fixed stop at wick low) + **minimum 5-pair deployment** (BTC, ETH + 3 major correlated liquid pairs during panic events) + fee-adjusted R:R ≥ 1:3 → long to BB middle / RSI > 55.

### What Changed from Intermediate

| Dimension | Intermediate | Sophisticated |
|---|---|---|
| Speed gate | 15%/≤5 bars (single, untuned) | **Dual window: 10%/≤5 bars (mature-market) OR 15%/≤10 bars (legacy crash); plateau test required** |
| Signal frequency | "< 5/year estimated" | **Quantified: 1-2/year BTC alone; 5-10/year on 5-pair pool (N_eff ≈ 1.3 independent events per panic)** |
| Deployment | BTC + ETH implied | **Formal 5-pair minimum: BTC, ETH + 3 correlated liquid majors** |
| Statistical framework | "3+ years minimum" | **Power analysis: n_eff ≥ 50 required; 5-year multi-asset deployment minimum for statistical floor** |
| Position sizing | implied fixed stop | **Dynamic: 2% bankroll / |entry − wick_low|; wick stops are 20-30% wide — position must scale** |
| R:R | unspecified | **≥ 1:3 mandatory** (wide wick stops require wider R:R to maintain positive expectancy at 55–65% WR) |
| Friction model | not quantified | **~47% Sharpe erosion (BSIC); slippage at wick low dominates per-trade cost; low-frequency = fewer total fees** |
| OOS degradation | not quantified | **25-40% Sharpe ceiling; structural/forced-liquidation mechanism more OOS-stable than statistical factor** |
| Parameter grid | 4 untuned | **27-cell plateau test (3×3×3: speed-pct × RSI-threshold × volume-mult); PBO at ~20 cells → DSR required** |
| Market maturation | not addressed | **Anti-prim escape hatch C: crash amplitude declining cycle-over-cycle; structural risk quantified** |
| Anti-prim escapes | implied | **3 formal escape hatches** |
| Certainty | hypothesis | **hypothesis (structured, bounded, ZERO peer-reviewed crypto anchor at any tier)** |

### Evidence (8 Sources)

| Source | Finding |
|---|---|
| **arxiv 2304.09939** (Bitcoin: A life in crises, Tarassov & Houlié 2023) | **≥10 Bitcoin crisis events 2010-2021 (11 years) ≈ 0.9 cycle-level crashes/year** — each contains 1-3 capitulation wick events; similar duration of ~50-100 days |
| **CoinDesk, April 1, 2026** ("Bitcoin's crashes are shrinking") | **Crash amplitude declining per cycle**: 2013: −87%, 2017: −84%, 2022: −77%, 2026: −50%; deeper liquidity + institutional participation (ETFs, pensions) compresses drawdowns → **structural anti-prim risk as BTC matures** |
| **Glassnode BTC capitulation study** (intermediate anchor, n=7) | 7 events 2017-2023 all had prior uptrend; avg +31% 30d return — regime gate validated as mechanism activation condition |
| **backtestbase.com + statistical power literature** | Minimum 30 trades CLT floor; 200-300 for meaningful metrics; 500+ for real statistical power; low-frequency strategies require multi-asset pooling or long deployment windows; for n=50 at 95% CI: margin of error ±14% on WR |
| **PMC6599809** (LPPLS Bitcoin bubbles, Cauwels & Sornette et al.) | 24 LPPLS bubble events across 8 cryptos over 4.5 years; super-exponential acceleration in crash final legs validates speed gate as crash-vs-trend discriminator; LPPLS hourly data provides "outstanding performance" in detecting rapid price change regimes |
| **MDPI 2021 Bitcoin Bubbles and Crashes Detection** | Log-periodic power law identifies crash onset from acceleration pattern; conceptual underpinning for 10%/5-bar vs 15%/10-bar dual speed gate as proxy for accelerating-vs-linear decline |
| **BSIC transaction cost modelling** (sister prim anchor) | ~47% Sharpe erosion at typical crypto fees+slippage; but rare-event strategy has few trades → lower total fee drag; slippage at extreme wick lows dominates per-trade cost (wide bid-ask at capitulation extreme) |
| **PMC9920669 regime-gate analogy** | RSI < 30 ungated = −97.5pp vs B&H on 10 cryptos 1,462 days; regime gate is mechanism activation = applies structurally to all multi-oscillator-extreme entry signals |

### Key Numbers

| Metric | Value |
|---|---|
| BTC cycle-level crash frequency | ~0.9/year (arxiv 2304.09939) |
| Capitulation wick events per crash | 1-3 (estimated) |
| BTC 1h qualifying signal frequency | **1-2/year** |
| 5-pair pool signal frequency | **5-10 events/year** |
| N_eff per panic event (ρ≈0.90) | **N/(1+(N−1)×ρ) = 5/(1+4×0.90) ≈ 1.3 independent** |
| Signals needed for n_eff = 50 | ~38 panic events = 4-8 years multi-asset deployment |
| WR margin at n=50 | ±14% (95% CI) |
| WR margin at n=100 | ±10% (95% CI) |
| Glassnode 30d forward return (n=7) | +31% average |
| Crash amplitude trend | 87% → 84% → 77% → 50% (−9-10pp per cycle) |
| Friction Sharpe erosion | ~47% (BSIC; slippage-dominant for rare-event holds) |
| OOS degradation ceiling | 25-40% Sharpe loss |
| Required R:R (wick stop = 20-30% wide) | ≥ 1:3 |
| Parameter plateau grid | 27 cells (3×3×3) |
| PBO threshold | ~20 cells → DSR required at 27 cells |

### 3 Anti-Prim Escape Hatches

**(A) Frequency collapse**: rolling 5-year count of qualifying signals across 5-pair pool < 15 total → BTC market maturation has compressed crash amplitude below speed gate threshold → mechanism theoretically sound but empirically unreachable → **mark as "maturation anti-prim" with full documentation of structural reason**

**(B) Speed gate plateau fails**: across 27-cell grid (3 speed-pct thresholds × 3 RSI thresholds × 3 volume multipliers), no stable profitable region (PF variance > 50% OR no cell with WR > 55%) → capitulation mechanism does not produce repeatable quantitative edge at 1h granularity → **mark anti-prim**

**(C) Live WR anti-prim**: own-data live WR < 48% over first 30 qualifying events (multi-asset pool, any deployment length) → mechanism not exploitable at current market efficiency → **mark as "efficiency anti-prim": structural mechanism valid, market pricing already compensates**

### 8 Documented Limitations (Sophisticated)

1. **ZERO peer-reviewed crypto anchor at any tier**: no academic paper directly tests RSI < 20 + volume spike + consecutive reds + prior uptrend + next-candle as combined signal on crypto. Glassnode n=7 is directional only. This is the only sophisticated freqtrade prim with no positive quantitative anchor of any kind.

2. **Statistical power constraint (binding)**: n_eff = 1.3 per panic event. Need 38 panic events for n_eff = 50. At current frequency (1-2/year), that requires 20-38 years of BTC history — impossible. Multi-asset pool reduces to 4-8 years but requires pooling assumption (correlated panics are structurally the same event). Any WR estimate below 72% cannot be distinguished from 58% at n=50.

3. **Market maturation structural risk (irreversible)**: BTC crash amplitude declining per cycle (87% → 84% → 77% → 50%). If ETF flows and institutional participation continue creating buy-the-dip floors, the 10%/5-bar speed gate may not trigger in post-2030 BTC. Not a parameter problem — a structural change in the asset class that makes the mechanism historically isolated rather than forward-applicable.

4. **Speed gate calibration is epoch-dependent**: 15%/5h was derived from 2017-2022 crash behaviour. The 10%/5-bar softening is a conjecture, not a calibrated threshold. The dual-window design is conservative (either qualifies), but neither threshold is empirically derived from post-2022 crash data.

5. **Correlated signals are NOT independent**: during a BTC panic, ETH and altcoins fire simultaneously with ρ ≈ 0.90+. N_eff ≈ 1.3 per panic event regardless of pool size. Adding more pairs increases signal count but NOT statistical independence. This is a fundamental ceiling, not a solvable engineering problem.

6. **Wick stop creates position sizing problem**: capitulation wicks are 20-30% below the prior price. A fixed stop at the wick low requires 1.5-3% position size to maintain 2% bankroll risk per trade. This is appropriate but means portfolio exposure per signal is LOW — maximum benefit extraction requires deploying across multi-asset simultaneously.

7. **MFI < 12 frequency unknown**: MFI < 12 may further reduce signal count below even the 1-2/year estimate. No historical frequency data for RSI < 20 + MFI < 12 simultaneously on BTC/ETH 1h.

8. **27-cell plateau test is infeasible without multi-asset pooling**: 27 cells × 5 signals/year (BTC alone) = 135 cell-years of data needed. With 5-pair pool × 10 signals/year = 2.7 years per cell — more feasible but still requires ~5-year deployment. This is the minimum deployment window, not a quick validation.

### Implementation Gaps (YujiExtinctionBurstStrategy.py) — 9 Gaps

*(From intermediate: 6 gaps — regime gate, speed gate, ADX guard, next-candle, fixed stop, drop partial tiers)*

**From intermediate (must implement first):**
1. Regime gate: `(close.shift(20) > ema_200_1h.shift(20)) & (ema_200_4h > ema_200_4h.shift(30))`
2. Speed gate (dual window): `((close.shift(5) - close) / close.shift(5) >= 0.10) | ((close.shift(10) - close) / close.shift(10) >= 0.15)`
3. ADX_4h < 40 guard (4h informative)
4. Next-candle: `extinction_burst_signal.shift(1) & (close > close.shift(1))`
5. Fixed stop: remove `trailing_stop=True`; set stop at capitulation wick low
6. Drop `extinction_burst_partial` and `macro_capitulation` blocks until separately validated

**New sophisticated gaps:**
7. **Dynamic position sizing**: compute `position_size = 0.02 × bankroll / abs(entry_price − wick_low)` per trade (replaces default fixed position size)
8. **Multi-asset whitelist**: add BTC, ETH, BNB, SOL, XRP to strategy whitelist with identical parameter set (all fire simultaneously during panic events)
9. **Speed gate dual-window plateau test**: implement as two separate Boolean columns `speed_gate_fast` (10%/5) and `speed_gate_slow` (15%/10); test both in hyperopt; report which produces better PF across validation window

### Bank State After Cycle 27

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | 0 |
| Intermediate | **0** | 1 (obi-informed-directional) |
| Sophisticated | **6** (rsi-oversold, ema-pullback, liq-sweep, bullish-rsi-div, hidden-div, **capitulation-exhaustion NEW**) | 4 |

6 freqtrade sophisticated prims cover 6 distinct regime axes:

| Regime | Prim |
|---|---|
| Ranging (ADX < 20, BBW pctl < 40) | rsi-oversold-mean-reversion |
| Ranging-to-mild-trend (ADX < 30) | liquidity-sweep-reversal |
| Trending structural (ADX 25–35 rising) | ema-pullback-dynamic-support |
| Exhaustion / late-bear | bullish-rsi-divergence |
| Trending momentum (uptrend pullback) | hidden-bullish-rsi-divergence |
| **Panic capitulation (crash event)** | **capitulation-exhaustion-reversal** |

### Next Cycle Recommendation

**IMPLEMENT** — implement the 9-gap list above in `YujiExtinctionBurstStrategy.py`; the 6 intermediate gaps are the minimum viable implementation; the 3 sophisticated gaps (dynamic sizing, multi-asset whitelist, dual speed gate) are the minimum viable sophisticated implementation. After implementation: count raw regime-gated signals on BTC/ETH 1h 2020–2025 historical data first. If n < 15 total across both pairs in 5 years, the frequency anti-prim escape hatch (A) has already been triggered before the plateau test can run.

**OR RESEARCH** — if frequency anti-prim is confirmed (n < 15 in 5 years), pivot to: extract new naive prim OR elevate obi-informed-directional from intermediate to sophisticated (4 sources at intermediate, clear research path to 8+).

### Sources (8)
- [arxiv 2304.09939 — Bitcoin: A life in crises (Tarassov & Houlié)](https://arxiv.org/abs/2304.09939)
- [CoinDesk Apr 2026 — Bitcoin's crashes are shrinking, Wall Street notices](https://www.coindesk.com/markets/2026/04/01/bitcoin-s-crashes-are-shrinking-and-wall-street-is-starting-to-notice)
- [PMC6599809 — Are Bitcoin bubbles predictable? LPPLS model (Cauwels/Sornette)](https://pmc.ncbi.nlm.nih.gov/articles/PMC6599809/)
- [MDPI Stats 2021 — The 2021 Bitcoin Bubbles and Crashes: Detection and Classification](https://www.mdpi.com/2571-905X/4/4/56)
- [backtestbase.com — Minimum trades for a valid backtest](https://www.backtestbase.com/education/how-many-trades-for-backtest)
- [PMC9920669 — Effectiveness of RSI Signals in Timing Cryptocurrency Market (regime-gate analogy)](https://pmc.ncbi.nlm.nih.gov/articles/PMC9920669/)
- [BSIC — Backtesting Series: Transaction Cost Modelling (Sharpe erosion ~47%)](https://bsic.it/backtesting-series-episode-5-transaction-cost-modelling/)
- [Wyckoff, R.D. (1931) / Murphy TAOFM (1999) — Selling Climax foundational mechanism]
