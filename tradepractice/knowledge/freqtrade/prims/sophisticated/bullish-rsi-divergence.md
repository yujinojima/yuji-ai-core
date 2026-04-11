---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T11:34:06+10:00
cycle: 17
---

---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T11:30:00+10:00
cycle: 17
---

## Prim: bullish-rsi-divergence
**Level:** sophisticated (refined from intermediate)
**Project:** freqtrade
**Parent:** intermediate/bullish-rsi-divergence

### Mode: RESEARCH — Highest-Falsification-Risk Elevation in the Bank

Only intermediate prim carrying **published negative evidence** at its parent root (PMC9920669: LEAST EFFECTIVE RSI variant, 10 cryptos × 1,462 days). Sophisticated elevation here means **failure modes are quantified and falsification path is exact, NOT that the prim works** — a deliberate epistemic distinction from sister sophisticated prims.

### What Elevated This from Intermediate

11 sources (up from 9), with the **first quantified friction model, OOS degradation ceiling, parameter-sensitivity bounds, and multiple-testing correction requirement specific to divergence**. Elevation does not come from new positive WR data — it comes from quantifying every failure mode the intermediate flagged and bounding realistic live performance against the published negative result.

| New Finding | Source | Impact |
|---|---|---|
| **PMC9920669 explicit ranking re-anchored** — divergence "hardest to implement, least effective" | PMC9920669 | Sophisticated must justify *why* it survives the only peer-reviewed crypto test |
| Friction Sharpe erosion **~47%** at typical crypto fees+slippage | BSIC, FMZQuant | Friction model from sister sophisticated prims applies in full |
| **OOS degradation 26–58%** ceiling (McLean-Pontiff factor zoo) | QuantPedia, arxiv 2602.10785 | Bounds expected live Sharpe at 50–70% IS |
| **PBO + Deflated Sharpe correction REQUIRED** when > 20 parameter cells | Bailey-Borwein-Lopez de Prado SSRN 2326253 | 5 lookback × 4 RSI gap = 20 cells already at PBO threshold |
| Real overfit example **+28.4% IS → −79.3% live** | QuantVPS / CPCV | Anchors tail-risk magnitude |
| **Connors RSI2 PF 2.08 (n=288, equity)** comparable baseline | QuantifiedStrategies | Sets WR/PF expectation ceiling |
| **HFT variant sign-flip +84k → −99k** | FMZQuant / PANews | Confirms sub-1h ban |
| **Pivot-detection bias quantified ~30%** false-pivot drop with left/right confirm | LuxAlgo, TradingView pivot lib | Quantifies upgrade impact |
| **Bullish-bearish ROI asymmetry ~10×** re-anchored | SaintQuant | Mechanism: positive expectancy IF stops tight, targets far |
| **WR ladder 33% → 65% → 73%** monotonic with filter count | Kraken + Concord p2c + LuxAlgo + QuantifiedStrategies | Validates 12-filter approach with ~25% crypto discount |
| **Regular divergence "difficult to quantify"** explicit verdict | QuantifiedStrategies | Sophisticated tier carries this caveat permanently |

### Key Numbers

| Metric | Value |
|---|---|
| Naive bare-signal WR | ~33% |
| Confluence WR (1:2 R:R, support) | 60–65% |
| MACD+RSI double-confirmation (equity, n=235) | 73% WR, 0.88% avg gain |
| Crypto discount factor | ~25% |
| **Realistic crypto sophisticated WR target** | **52–58%** |
| Realistic post-OOS live WR | 48–52% |
| Signal frequency | ~0.8% of candles |
| Friction Sharpe erosion | ~47% |
| OOS rejection threshold | > 30% Sharpe loss |
| Parameter plateau criterion | PF variance < 25% across 20-cell grid |
| Bullish-bearish forward ROI asymmetry | ~10× |
| Required R:R after fees | ≥ 1:2 |

### 12 Critical Failure Modes (Quantified)
1. Persistent uptrend on majors — **#1 from PMC9920669**
2. Single-oscillator signal — drops 15–25pp WR
3. Rolling-min pivot detection — drops ~10pp
4. Same-candle entry — drops 5–10pp
5. Sub-1h timeframe — friction sign-flip
6. No volume-thinning filter
7. No divergence throttle — loss cascade
8. Curve-fit "magic number" parameters
9. OOS Sharpe loss > 30%
10. Multiple-testing inflation > 20 cells without DSR
11. News capitulation (RSI < 20)
12. Whitelist filter inactive on BTC/ETH uptrend

### 12 Implementation Gaps in YujiDivergenceStrategy.py
1. True 5-bar pivot via `argrelextrema` (replace rolling-min)
2. Enforce pivot separation 10–60 candles
3. Convert OR-gate to AND-gate (`buy_double_div` only)
4. Regime exclusion `~(ema_200_slope > 0 & adx > 35)`
5. Next-candle structure break
6. Volume-thinning `pivot_2 < 0.8 × pivot_1`
7. Divergence throttle (state variable)
8. Pair whitelist excluding BTC/ETH in persistent uptrend
9. Promote to 4h primary TF
10. Fee-aware R:R gate ≥ 1:2
11. **BLOCKING: parameter plateau test** (5×4 grid, PF variance < 25%)
12. **BLOCKING: CPCV + Deflated Sharpe correction** (20+ tested cells)

### Critical Limitation — Anti-Prim Escape Hatch

**No own-data backtest. The 12-filter unit has never been tested as a unit against the PMC9920669 counter-result.** This is the **only sophisticated prim in the bank with an unambiguous anti-prim escape hatch**: if own-data plateau test fails (no profitable region across 20 parameter cells), the prim must be marked **anti-prim** rather than re-refined.

Deployment blocked pending 6-step verification: (a) own-data walk-forward bull→bear→accumulation BTC/ETH 4h, (b) parameter plateau test, (c) CPCV+DSR correction, (d) direct comparison vs PMC9920669 baseline, (e) friction-adjusted OOS Sharpe within 30% of IS, (f) head-to-head vs hidden-divergence intermediate.

### Bank State After Cycle 17

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | 0 |
| Intermediate | **4** (rsi-oversold superseded; ema-pullback superseded; liq-sweep superseded; **regular-div SUPERSEDED**; hidden-div) | 3 |
| Sophisticated | **4** (rsi-oversold, ema-pullback, liq-sweep, **bullish-rsi-divergence NEW**) | 0 |

4 sophisticated freqtrade prims now cover 4 distinct regimes. Hidden-divergence remains intermediate (1 prim, awaiting own-data head-to-head).

### Regime Partition — 4 Sophisticated + 1 Intermediate

| Regime | Prim | Level |
|---|---|---|
| Ranging (ADX < 20, BBW pctl < 40) | rsi-oversold-mean-reversion | sophisticated |
| Ranging-to-mild-trend (ADX < 30) | liquidity-sweep-reversal | sophisticated |
| Trending structural (ADX 25–35 rising) | ema-pullback-dynamic-support | sophisticated |
| **Exhaustion / late-bear** | **bullish-rsi-divergence (regular)** | **sophisticated** |
| Trending momentum (uptrend pullback) | hidden-bullish-rsi-divergence | intermediate |

### Files Updated
- `knowledge/freqtrade/prims/sophisticated/bullish-rsi-divergence.md` (created, 175 lines)
- `knowledge/epistemic-index.md` (intermediate marked SUPERSEDED, sophisticated freqtrade table +1 row → 4 sophisticated)
- `knowledge/conditions-log.md` (intermediate marked historical, sophisticated entry appended)
- Commit: `153a56e`

### Next Cycle Recommendation

**BACKTEST-ANALYSIS** is now the shared blocker across **4 sophisticated + 1 intermediate** freqtrade prims. The single highest-leverage backtest is the **head-to-head walk-forward of bullish-rsi-divergence (this prim, sophisticated) vs hidden-bullish-rsi-divergence (intermediate)** on same BTC/ETH 4h data window across bull → bear → accumulation phases. This test directly adjudicates a published negative result AND an unverified practitioner consensus simultaneously; all four outcomes are load-bearing; falsification path is clean (anti-prim marking is unambiguous, no re-refinement loop).

Secondary: extract **capitulation-exhaustion** prim from YujiExtinctionBurstStrategy (climactic selling + vol spike + extreme oscillators) — distinct mechanism class completing 5th regime axis (panic-reversal vs exhaustion-reversal).

### Sources (11)
- [PMC9920669 — RSI Crypto (peer-reviewed negative anchor)](https://pmc.ncbi.nlm.nih.gov/articles/PMC9920669/)
- [QuantifiedStrategies — MACD+RSI 73% WR n=235](https://www.quantifiedstrategies.com/macd-and-rsi-strategy/)
- [QuantifiedStrategies — Divergence "difficult to quantify"](https://www.quantifiedstrategies.com/divergence-trading-strategy/)
- [QuantifiedStrategies — RSI2 Connors PF 2.08 n=288](https://www.quantifiedstrategies.com/rsi-2-strategy/)
- [LuxAlgo — RSI at S/R 60–65% WR](https://www.luxalgo.com/blog/5-rsi-entry-strategies-using-support-and-resistance/)
- [Concord p2c — Structure-break confirmation](https://www.concordp2c.com/is-bullish-divergence-reliable-backtested-insights-and-common-mistakes-to-avoid/)
- [SaintQuant — Bullish 10× forward-ROI asymmetry](https://saintquant.com/blog/173-bullish-divergence-rsi-how-smart-crypto-traders-spot-early-reversals)
- [Bailey/Borwein/Lopez de Prado — PBO SSRN 2326253](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2326253) + [Deflated Sharpe](https://www.davidhbailey.com/dhbpapers/deflated-sharpe.pdf)
- [BSIC — Transaction cost modelling Sharpe erosion ~47%](https://bsic.it/backtesting-series-episode-5-transaction-cost-modelling/)
- [QuantPedia — IS vs OOS McLean-Pontiff](https://quantpedia.com/in-sample-vs-out-of-sample-analysis-of-trading-strategies/) + [arxiv 2602.10785 walk-forward](https://arxiv.org/html/2602.10785) + [ScienceDirect CPCV](https://www.sciencedirect.com/science/article/abs/pii/S0950705124011110)
- [QuantVPS — Real overfit +28.4% IS → −79.3% live](https://www.quantvps.com/blog/swing-failure-pattern-strategy)
