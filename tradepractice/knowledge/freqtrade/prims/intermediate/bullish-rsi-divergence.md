---
name: bullish-rsi-divergence
level: intermediate
project: freqtrade
parent_prim: naive/bullish-rsi-divergence
created: 2026-04-11
last_validated: never
reaction_validated: no
---

## Prim: bullish-rsi-divergence
**Level:** intermediate (refined from naive)
**Project:** freqtrade
**Parent:** naive/bullish-rsi-divergence

### Rule
**Pivot-based** bullish divergence (true 5-bar pivot lows separated by 10–60 candles) + **regime exclusion** (NOT in persistent uptrend: EMA200 slope > 0 AND ADX > 35) + **REQUIRED double divergence** (RSI HL AND MACD-hist HL on the same pivot pair) + **volume declining** (pivot-2 volume < 0.8 × pivot-1 volume, seller-cohort thinning) + **next-candle confirmation** (close > pivot-2 close AND close above prior 5-bar swing high = structure break) + price at support (BB lower / VAL / 1h EMA200 from below) + 4h timeframe primary (1h secondary, no sub-1h) + **divergence throttle** (new signal blocked until prior divergence invalidated by close below pivot-2 low) + fee-adjusted R:R ≥ 1:2 targeting prior swing high → long. **Excludes persistently-rising BTC/ETH per PMC9920669.**

### Mechanism
Bullish divergence is a **momentum-failure signal**: price extends to a new low while RSI (and MACD) print a shallower oscillator low, revealing that the selling cohort is thinning. The edge is **not** the divergence itself — PMC9920669 rated the naive signal the least effective of all RSI variants tested. The edge emerges only from (a) **structure-break confirmation** that the reversal is realised, (b) **double-oscillator agreement** that filters spurious pivots, and (c) **regime exclusion** removing the parabolic-uptrend failure mode where divergence persists indefinitely. The mechanism collapses when the seller cohort is NOT trapped — in persistent uptrends the "divergence" is simply a pullback on declining sell pressure inside a trend, and the next wave continues down relative to the rally cohort.

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| **Swing detection** | rolling-min (window) | **True 5-bar pivot (left/right confirmation)** |
| **Pivot distance** | none (implicit via lookback) | **10–60 candle separation enforced** (matches PMC9920669 methodology) |
| **Regime** | none — fires any regime | **Excludes persistent uptrend (EMA200 slope > 0 AND ADX > 35); prefers late-bear / ranging exhaustion** |
| **Confluence** | OR (buy_rsi_div \| buy_macd_div \| buy_double_div) | **REQUIRE double divergence** (RSI HL AND MACD-hist HL) |
| **Confirmation** | same-candle | **Next-candle: close > pivot-2 close AND close above prior 5-bar swing high (structure break)** |
| **Volume** | volume > 0.8 × SMA (any) | **Volume declining across pivots** (pivot-2 < 0.8 × pivot-1) — seller thinning |
| **Signal throttle** | none (re-fires every candle the rolling window still shows divergence) | **Blocked until prior divergence invalidated** (close < pivot-2 low) |
| **Timeframe** | 1h (untested) | **4h primary, 1h secondary, NO sub-1h** (noise destroys divergence) |
| **Target** | BB middle (loose) | **Prior swing high, R:R ≥ 1:2 after fees** |
| **Pair whitelist** | all | **Excludes persistently-rising BTC/ETH per PMC9920669** |
| **Certainty** | guess (negative evidence published) | **hypothesis** (confluence + regime gate reframes the failure mode) |

### Research Evidence

| Source | Finding |
|---|---|
| **PMC9920669** (peer-reviewed, 10 cryptos, 1,462 days) | Naive bullish RSI divergence **LEAST EFFECTIVE** of all RSI experiments; frequency ~**0.8% of candles**; explicitly counterproductive on rising BTC/ETH; this is the **negative-result anchor** the refinement must survive |
| **QuantifiedStrategies — MACD+RSI combined** | n=235, **73% WR**, 0.88% avg gain/trade (including costs) — equity benchmark; discount to crypto but validates double-confirmation mechanism |
| **LuxAlgo — RSI at S/R with 1:2 R:R** | Reversal entries at support with 1:2 R:R: **60–65% WR**; breakout confirmation strategies 55–60% WR with 1:3 R:R |
| **Concord p2c / Sniper Trades** (multi-source) | Structure-break + candlestick confirmation lifts WR from ~50% to **50–65%** typical, 86% outlier on small-n (n≈16) — selection bias flagged |
| **FXOpen / ACY / Babypips / Alchemy Markets** (convergent) | Divergence "only applicable during a trend — not used in sideways market" (contradicts early-bear exhaustion framing); **hidden divergence more reliable on 4h/daily** due to noise reduction; regular divergence "difficult to quantify" (QuantifiedStrategies) |
| **Kraken Learn / practitioner consensus** | Naive first-signal entry: **~2 of 3 losing trades** without confirmation layers |
| **SaintQuant — BTC backtest** | Bullish-div 60-day forward ROI **~10x** bearish-div ROI — directional asymmetry suggests the signal has a weak but real long bias even when WR is marginal |
| **Gate.io 2026** | MACD double-divergence confluence: 77% WR reported (selection bias suspected on cherry-picked window) |
| **TradingView pivot detection libraries** | Proper pivot detection uses left/right bar confirmation with minimum 5–10 candle separation — rolling-min (current code) misclassifies continuation lows as pivots |

### Key Numbers

| Metric | Value | Source |
|---|---|---|
| Naive signal frequency | ~0.8% of candles | PMC9920669, n=10 cryptos, 1,462 days |
| Naive bare-signal WR | ~33% (2 of 3 losing) | Kraken + practitioner consensus |
| MACD+RSI double confirmation WR | **73%** (n=235, equity) | QuantifiedStrategies |
| Structure-break + candlestick confirmation WR | **50–65%** typical | Concord p2c / Sniper Trades |
| Support + 1:2 R:R reversal WR | **60–65%** | LuxAlgo |
| Bullish-bearish forward ROI asymmetry | **~10x** (bullish > bearish) | SaintQuant BTC |
| Realistic live WR target (post-OOS) | **55–62%** | McLean-Pontiff OOS degradation applied to 60–65% IS |
| Minimum pivot separation | 10 candles (soft floor) | TradingView + PMC9920669 3–60 window |
| Maximum pivot separation | 60 candles (PMC) / 30 candles (practical) | PMC9920669 |
| Minimum R:R for fee survival | 1:2 (binance spot 0.1% round-trip ≈ 0.2% drag) | standard crypto fee model |

### Conditions
- **Works when:** Late-bear/exhaustion phase OR ranging market with deep oversold selloff; price at defended support (BB lower, VAL, 1h EMA200 from below); 5-bar pivot lows confirmed with ≥10 candle separation; RSI HL ≥ 5 pts AND MACD-hist HL on same pivot pair; volume declining across successive lows (cohort thinning); next candle closes above prior 5-bar swing high (structure break); 4h timeframe on BTC/ETH/major alt; 4h RSI > 20 (not freefall capitulation); fee-adjusted R:R ≥ 1:2 to prior swing high
- **Fails when:** Persistent uptrend (EMA200 slope > 0 AND ADX > 35) — **divergence persists indefinitely, each print a fresh loss** (PMC9920669 #1 failure mode); parabolic capitulation (news-driven freefall, 4h RSI < 20); single-oscillator divergence (RSI only or MACD only — drops 15–25pp WR vs double); same-candle entry (drops 5–10pp); no structure break (pure divergence without reversal confirmation); rolling-min pivot detection (misclassifies continuation lows); pivot separation < 10 or > 60 candles; sub-1h timeframe (noise overwhelms signal); volume rising on successive lows (selling still strong); lone divergence without volume/structure confluence; whitelisted BTC/ETH in persistent uptrend phase; divergence not yet invalidated (repeat-fire on persistent signal)
- **Best pair(s):** Major alts in ranging/late-bear; EXCLUDE BTC/ETH when `close > EMA200 AND EMA200.slope > 0 AND ADX > 30`
- **Best timeframe:** 4h primary (noise-reduced, hidden-div literature consensus) > 1h secondary > **never sub-1h**
- **Best regime:** Ranging-oscillation or late-bear exhaustion (seller cohort measurably thinning); explicitly NOT trend-continuation (that is the hidden-divergence variant, not implemented here)

### Evidence
- **Source:** paper + community backtests + practitioner consensus (9 independent sources)
- **Certainty:** hypothesis (convergent multi-source, but refinement has NOT been own-tested against the PMC9920669 negative result)
- **Scope:** major-pair crypto; ranging and late-bear regimes only
- **Falsifiability:** tested-fail (naive variant in PMC9920669) + tested-pass (confluence variant 60–65% WR multi-source) — but the **specific combination** of pivot + double-div + structure-break + regime-exclude + volume-thinning has never been tested as a unit
- **Reaction observed:** NO — no forward-test or own-data backtest yet

### Critical Limitation
This intermediate prim is the **first refinement in the knowledge bank to carry negative-evidence baggage**. Its parent (naive) was explicitly rated worst in a peer-reviewed study. The intermediate rule is constructed to survive the PMC9920669 counter-result by (a) excluding the failure regime, (b) requiring double confirmation and structure break, (c) using proper pivot detection, (d) adding volume-thinning confluence. **Whether this survives own-data testing is unknown.** The refinement path is plausible but carries higher falsification risk than the sister sophisticated prims. If a plateau test on divergence_lookback and rsi_divergence_min shows no profitable region, this prim should be marked as **anti-prim** and either (a) replaced by the hidden-divergence trend-continuation variant, or (b) demoted to a filter/tiebreaker rather than a primary trigger.

### Implementation Gaps in YujiDivergenceStrategy

`user_data/strategies/YujiDivergenceStrategy.py`:

1. **Replace rolling-min with true pivot detection** (lines 112–116): use `scipy.signal.argrelextrema(data, np.less, order=5)` or implement 5-bar-left + 5-bar-right pivot confirmation — current `rolling(lookback).min()` flags every continuation low as a pivot.
2. **Enforce pivot separation** (new): reject divergence unless `pivot_distance in [10, 60]` candles — matches PMC9920669 methodology.
3. **Require double divergence** (lines 181–184): change the OR gate (`buy_rsi_div | buy_macd_div | buy_double_div`) to require `buy_double_div` only — kills the 15–25pp WR gap of single-oscillator signals.
4. **Add regime exclusion** (new): `~(ema_200_slope > 0 & adx > 35)` — PMC9920669 failure-mode filter; currently absent.
5. **Next-candle confirmation** (lines 151–159): enforce `close > close.shift(1) & close > rolling(5).max().shift(1)` — structure break confirmation, not same-candle.
6. **Volume thinning filter** (new): `volume_at_pivot_2 < 0.8 * volume_at_pivot_1` — seller cohort thinning; replaces loose `volume > 0.8 × SMA` check.
7. **Divergence throttle** (new): state variable blocking re-fire until prior divergence invalidated by `close < pivot_2_low`; prevents loss cascade in persistent trends.
8. **Pair whitelist** (new): exclude BTC/ETH when 1h `close > EMA200 AND EMA200_slope > 0 AND ADX > 30`.
9. **Timeframe change**: promote to 4h primary (currently 1h) or make 4h HTF confirmation mandatory.
10. **Fee-aware R:R gate**: require target-to-swing-high distance ≥ 2 × (stop-loss distance + 2 × fee) before entry.
11. **Parameter plateau test**: IntParameter `divergence_lookback ∈ [10, 15, 20, 25, 30]`, `rsi_divergence_min ∈ [3, 5, 7, 10]`; verify PF variance < 25% across combinations before deployment.
12. **Hidden-divergence companion**: add `buy_hidden_div` for trend-continuation regime (price HL + RSI LL during pullback in confirmed uptrend); complements this prim rather than replaces it.

### Conditions Log Entry
- **Works when:** Late-bear/ranging exhaustion; pivot-confirmed bullish RSI+MACD double divergence; structure break next candle; volume declining across lows; price at defended support; 4h BTC/ETH (when not persistently trending) or major alts; R:R ≥ 1:2 after fees
- **Fails when:** Persistent uptrend (PMC9920669 #1 failure); single-oscillator divergence; same-candle entry; no structure break; rolling-min pivots; volume rising into lows; sub-1h TF; unthrottled re-fire on persistent signals
- **Key numbers:** Naive WR ~33% → confluence WR 60–65% (pre-OOS); realistic live target 55–62%; MACD+RSI double-confirmation 73% WR (equity benchmark); signal frequency ~0.8% of candles; expected OOS degradation 25–50% per sister-prim meta-analysis
- **Last validated:** never (naive has negative published result; intermediate refinement never own-tested)

### Refinement Path to Sophisticated
To elevate further: (1) own-data walk-forward backtest across bull → bear → accumulation regimes; (2) parameter plateau verification on lookback and rsi_min; (3) CPCV + Deflated Sharpe for multiple-testing correction; (4) implement and compare hidden-divergence companion (trend-continuation variant) — ideally partition regime space: regular divergence for exhaustion, hidden divergence for trending pullbacks; (5) measure actual bullish-vs-bearish forward ROI asymmetry on own data to validate/reject SaintQuant claim; (6) test whether volume-thinning filter adds measurable edge or is spurious.

### Sources
- [PMC9920669 — Effectiveness of RSI Signals in Timing Cryptocurrency Market](https://pmc.ncbi.nlm.nih.gov/articles/PMC9920669/)
- [QuantifiedStrategies — MACD and RSI Strategy (73% WR, n=235)](https://www.quantifiedstrategies.com/macd-and-rsi-strategy/)
- [QuantifiedStrategies — Divergence Trading Strategy Backtest](https://www.quantifiedstrategies.com/divergence-trading-strategy/)
- [LuxAlgo — 5 RSI Entry Strategies Using Support and Resistance](https://www.luxalgo.com/blog/5-rsi-entry-strategies-using-support-and-resistance/)
- [FXOpen — Hidden vs Regular Divergence](https://fxopen.com/blog/en/what-is-the-difference-between-regular-and-hidden-divergence/)
- [ACY — RSI Hidden Divergence Trend Continuations](https://acy.com/en/market-news/education/how-to-spot-rsi-hidden-divergence-j-o-121814/)
- [Babypips — Hidden Divergence](https://www.babypips.com/learn/forex/hidden-divergence)
- [Kraken Learn — RSI Divergences](https://www.kraken.com/learn/rsi-divergences-what-they-how-they-work)
- [Concord p2c — Is Bullish Divergence Reliable? Backtested](https://www.concordp2c.com/is-bullish-divergence-reliable-backtested-insights-and-common-mistakes-to-avoid/)
- [SaintQuant — Bullish Divergence RSI Crypto](https://saintquant.com/blog/173-bullish-divergence-rsi-how-smart-crypto-traders-spot-early-reversals)
- [Schwab — Chart Divergences for Trading Decisions](https://www.schwab.com/learn/story/using-chart-divergences-to-make-trading-decisions)
