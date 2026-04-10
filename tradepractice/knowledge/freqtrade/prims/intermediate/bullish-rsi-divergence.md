---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T06:01:59+10:00
cycle: 13
---

---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T05:59:00+10:00
cycle: 13
---

## Prim: bullish-rsi-divergence
**Level:** intermediate (refined from naive)
**Project:** freqtrade
**Parent:** naive/bullish-rsi-divergence

### Rule
**True 5-bar pivot** bullish divergence (pivot lows separated 10–60 candles) + **regime exclusion** (NOT persistent uptrend: EMA200 slope > 0 AND ADX > 35) + **REQUIRED double divergence** (RSI HL ≥5pt AND MACD-hist HL on same pivot pair) + **volume declining across pivots** (cohort thinning) + **next-candle structure break** (close > pivot-2 close AND close > prior 5-bar swing high) + price at defended support (BB lower / VAL / 1h EMA200 from below) + 4h primary TF + **divergence throttle** + fee-adjusted R:R ≥ 1:2 → long to prior swing high. **Excludes persistently-rising BTC/ETH per PMC9920669.**

### Mode: RESEARCH — Highest Falsification Risk Refinement in the Bank

This is the **first intermediate prim in the knowledge bank to carry published negative-evidence baggage**. PMC9920669 rated the naive variant the LEAST EFFECTIVE of all RSI experiments tested. The refinement is constructed to survive the counter-result — but has NOT been own-tested.

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Swing detection | rolling-min (flags continuation lows) | **True 5-bar pivot with left/right confirmation** |
| Pivot separation | implicit lookback | **10–60 candles enforced** (PMC9920669 methodology) |
| Regime | none | **Excludes persistent uptrend (EMA200 slope > 0 AND ADX > 35)** |
| Confluence | OR (RSI \| MACD \| double) | **REQUIRE double divergence** (AND) |
| Confirmation | same-candle | **Next-candle structure break** |
| Volume | > 0.8× SMA loose | **Declining across pivots** (seller thinning) |
| Re-fire | every window candle | **Throttle until invalidation** (close < pivot-2 low) |
| Timeframe | 1h untested | **4h primary, 1h secondary, no sub-1h** |
| Whitelist | all pairs | **Exclude persistently-rising BTC/ETH** |
| Certainty | guess (published negative) | **hypothesis (9-source convergent)** |

### Research Evidence — 9 Sources

| Source | Finding |
|---|---|
| **PMC9920669** (peer-reviewed, 10 cryptos, 1,462 days) | Naive variant LEAST EFFECTIVE of all RSI experiments; ~0.8% frequency; counterproductive on rising BTC/ETH — **negative-result anchor** |
| **QuantifiedStrategies — MACD+RSI (n=235)** | **73% WR**, 0.88% avg gain/trade inc. costs — double-confirmation mechanism benchmark (equity, discount for crypto) |
| **LuxAlgo — RSI at S/R** | Reversal at support with 1:2 R:R: **60–65% WR**; breakout confirmation 55–60% WR with 1:3 R:R |
| **Concord p2c / Sniper Trades** | Structure-break + candlestick confirmation: 50–65% typical WR; 86% selection-biased outlier |
| **FXOpen / ACY / Babypips / Alchemy** (convergent) | Hidden div more reliable on 4h/daily; regular div "not used in sideways market"; **regular divergence "difficult to quantify"** (QuantifiedStrategies verdict) |
| **Kraken Learn** | Naive first-signal: **~2 of 3 losing trades** |
| **SaintQuant — BTC backtest** | Bullish-div 60-day forward ROI **~10x** bearish-div ROI — directional asymmetry |
| **Gate.io 2026 (MACD confluence)** | 77% WR reported, selection bias suspected |
| **TradingView pivot libraries** | Proper pivots need left/right bar confirmation, min 5–10 candle separation |

### Key Numbers

| Metric | Value |
|---|---|
| Naive bare-signal WR | ~33% (2 of 3 losing) |
| Confluence WR (Concord p2c / LuxAlgo) | 60–65% at 1:2 R:R |
| MACD+RSI double confirmation (equity) | 73% WR, n=235 |
| Signal frequency | ~0.8% of candles |
| **Realistic live WR target** (post-OOS) | **55–62%** |
| Bullish-bearish forward ROI asymmetry | ~10× |
| Pivot separation window | 10–60 candles (PMC9920669 3–60) |

### 12 Implementation Gaps in YujiDivergenceStrategy

`user_data/strategies/YujiDivergenceStrategy.py`:
1. Replace `rolling(lookback).min()` (lines 112–116) with true 5-bar pivot (`scipy.signal.argrelextrema` or left/right confirmation)
2. Enforce pivot separation 10–60 candles (new)
3. Convert lines 181–184 OR-gate to AND-gate requiring `buy_double_div` only
4. Add regime exclusion: `~(ema_200_slope > 0 & adx > 35)` (new)
5. Next-candle structure break: `close > close.shift(1) & close > rolling(5).max().shift(1)`
6. Volume-thinning filter: `volume_at_pivot_2 < 0.8 * volume_at_pivot_1`
7. Divergence throttle (state variable, blocks re-fire until `close < pivot_2_low`)
8. Pair whitelist excluding BTC/ETH in persistent uptrend
9. Promote to 4h primary TF (currently 1h)
10. Fee-aware R:R gate ≥ 1:2 after costs
11. Parameter plateau IntParameter test on `divergence_lookback ∈ [10,15,20,25,30]` and `rsi_divergence_min ∈ [3,5,7,10]`; PF variance < 25%
12. Hidden-divergence companion prim for trend-continuation regime (covers the regime this one excludes)

### Regime Partition — 4 Freqtrade Prims, All at Intermediate+

| Regime | Prim | Level |
|---|---|---|
| Ranging | rsi-oversold-mean-reversion | sophisticated |
| Ranging-to-mild-trend | liquidity-sweep-reversal | sophisticated |
| Trending | ema-pullback-dynamic-support | sophisticated |
| **Exhaustion/late-bear** | **bullish-rsi-divergence** | **intermediate** (highest falsification risk) |

All 4 freqtrade naive prims are now refined. Bank state: **3 sophisticated + 1 intermediate** for freqtrade.

### Critical Limitation
No own-data backtest. The specific 12-filter combination has never been tested as a unit against the PMC9920669 counter-result. **If a plateau test shows no profitable region on `divergence_lookback` or `rsi_divergence_min`, this prim should be marked as anti-prim** and replaced by the hidden-divergence trend-continuation companion. Falsification risk is measurably higher than for sister prims.

### Files Updated
- `knowledge/freqtrade/prims/intermediate/bullish-rsi-divergence.md` (created, 121 lines)
- `knowledge/epistemic-index.md` (naive marked superseded; intermediate freqtrade table +1 row → 4/4 refined)
- `knowledge/conditions-log.md` (naive marked historical, intermediate entry appended with 9-source evidence + 12 implementation gaps)
- Commit: `a48436c`

### Next Cycle Recommendations
- **(A) BACKTEST-ANALYSIS** — shared blocker across all 4 freqtrade prims; own-data walk-forward across bull → bear → accumulation needed before any further elevation. Critically, run the bullish-rsi-divergence refinement against the PMC9920669 baseline directly — this is a falsifiable refinement that deserves first-priority testing because the negative evidence is published and specific.
- **(B) RESEARCH — hidden-divergence companion prim** — regime-complement to this one (trend-continuation via price HL + RSI LL during pullback); partitions the divergence problem into regular (exhaustion, this prim) and hidden (trend-continuation, new prim). Would be a first-of-its-kind own-data test of the FXOpen/ACY "hidden more reliable in trends" claim.
- **(C) ASSESS — extract capitulation-exhaustion prim** from YujiExtinctionBurstStrategy — distinct mechanism (climactic selling + vol spike + extreme oscillators) completing the regime coverage.

Recommend **(A)** — the refinement exists specifically to be tested against a published negative result; until we run that test, the prim sits in the bank with the highest uncertainty of any entry. Second-best is **(B)** for regime coverage.

### Sources
- [PMC9920669 — Effectiveness of RSI Signals in Timing Cryptocurrency Market](https://pmc.ncbi.nlm.nih.gov/articles/PMC9920669/)
- [QuantifiedStrategies — MACD and RSI Strategy (73% WR, n=235)](https://www.quantifiedstrategies.com/macd-and-rsi-strategy/)
- [QuantifiedStrategies — Divergence Trading Strategy Backtest](https://www.quantifiedstrategies.com/divergence-trading-strategy/)
- [LuxAlgo — 5 RSI Entry Strategies Using Support and Resistance](https://www.luxalgo.com/blog/5-rsi-entry-strategies-using-support-and-resistance/)
- [FXOpen — Hidden vs Regular Divergence](https://fxopen.com/blog/en/what-is-the-difference-between-regular-and-hidden-divergence/)
- [ACY — RSI Hidden Divergence](https://acy.com/en/market-news/education/how-to-spot-rsi-hidden-divergence-j-o-121814/)
- [Babypips — Hidden Divergence](https://www.babypips.com/learn/forex/hidden-divergence)
- [Kraken Learn — RSI Divergences](https://www.kraken.com/learn/rsi-divergences-what-they-how-they-work)
- [Concord p2c — Is Bullish Divergence Reliable? Backtested](https://www.concordp2c.com/is-bullish-divergence-reliable-backtested-insights-and-common-mistakes-to-avoid/)
- [SaintQuant — Bullish Divergence RSI Crypto](https://saintquant.com/blog/173-bullish-divergence-rsi-how-smart-crypto-traders-spot-early-reversals)
- [Schwab — Chart Divergences for Trading Decisions](https://www.schwab.com/learn/story/using-chart-divergences-to-make-trading-decisions)
