---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T17:16:15+10:00
cycle: 11
---

---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T17:12:00+10:00
cycle: 11
---

## Prim: bullish-rsi-divergence
**Level:** naive
**Project:** freqtrade
**Parent:** none

### Rule
Price rolling-low LL + RSI(14) rolling-low HL (>= 5 pts, 10–30 candle window) + RSI < 40 + close < BB middle + stochastic turning up → long to BB middle / prior swing high.

### Mode: RESEARCH — New Angle (all 3 prior prims already sophisticated)

Extracted 4th freqtrade naive prim from **YujiDivergenceStrategy** (lines 107–190). Distinct mechanism from existing 3 prims: **momentum failure revealing seller-cohort thinning**, not oscillator exhaustion, trend pullback, or stop-cluster sweeping.

### Research Finding — Published Negative Result

| Source | Key Finding |
|---|---|
| **PMC9920669** (peer-reviewed, 10 cryptos, 1,462 days) | Divergences occur only **~0.8% of candles**; rated **LEAST EFFECTIVE** of all RSI experiments; "hardest to implement"; **explicitly counterproductive on rising BTC/ETH** |
| Kraken / multi-source practitioner | Naive first-signal entry: **~2 of 3 losing trades** |
| Gate.io 2026 (MACD confluence) | 77% WR reported (selection bias suspected) |
| Concord p2c / Sniper Trades | With structure-break + candlestick confirmation: **50–65% WR** typical; 86% outlier on small-n |
| SaintQuant / practitioner Bitcoin backtest | Bullish-div 60-day forward ROI **~10x** bearish-div's — asymmetric directional bias |
| FXOpen | Regular divergence → ranging; hidden divergence → trending (not implemented in Yuji code) |

### Critical Honest Framing

This prim enters the knowledge bank with **published negative evidence**. PMC9920669 is the same peer-reviewed paper that anchors the RSI mean reversion sophisticated prim — and it explicitly warns against the divergence variant on majors. The Yuji code trades BTC/ETH as priority pairs. The naive rule is active on exactly the pairs the study says it fails on.

### 10 Documented Limitations
1. Divergence can **persist indefinitely** in parabolic trends — every new print is a fresh loss; no throttle in code
2. Rolling-min swing detection is not true pivot detection — misclassifies non-structural lows
3. Signal is **extremely rare** (0.8% of candles) — limited frequency, hard to validate statistically
4. No regime gate — fires in any regime, including academically-documented failure regime
5. No next-candle confirmation — same-candle entry before reaction reveals itself
6. Formally tested and rated worst of the RSI family (negative evidence, not absent evidence)
7. Pivot-distance constraint (3–60 candles) from paper not enforced
8. Hidden divergence (more reliable in trends) not implemented
9. Per-pair frequency on Yuji's whitelist unknown
10. divergence_lookback parameter untuned, no plateau test

### Regime Partition Update

| Regime | Prim | Level |
|---|---|---|
| Ranging | rsi-oversold-mean-reversion | sophisticated |
| Ranging-to-mild-trend | liquidity-sweep-reversal | sophisticated |
| Trending | ema-pullback-dynamic-support | sophisticated |
| **Exhaustion/reversal** | **bullish-rsi-divergence** | **naive (negative evidence)** |

Adds a 4th regime axis — momentum exhaustion — distinct from the ADX partition. Partition is now regime × mechanism rather than ADX-only.

### Files Updated
- `knowledge/freqtrade/prims/naive/bullish-rsi-divergence.md` (created, 113 lines)
- `knowledge/epistemic-index.md` (naive freqtrade table: +1 row → 4 naive prims)
- `knowledge/conditions-log.md` (naive entry appended with PMC9920669 warning and 9 implementation gaps)
- Commit: `979fab1`

### Next Cycle Recommendation
Two paths, analyst should pick:
- **(A) Refine bullish-rsi-divergence to intermediate** — add regime gate (exhaustion/late-bear filter), next-candle confirmation, pivot-based swing detection, pivot-distance enforcement, structure-break filter, divergence throttle. Test whether the regime-gated + confluence version survives the PMC9920669 counter-result.
- **(B) Extract capitulation-exhaustion prim from YujiExtinctionBurstStrategy** — distinct mechanism (climactic selling + vol spike), completes the 4-prim regime partition with a separate trigger class.

Path (A) has higher research leverage (a documented negative result refined into a conditional positive); path (B) has higher coverage gain. Recommend (A) — the failure modes are already mapped, the refinement path is concrete, and a regime-gated divergence + hidden-divergence companion would be a first-of-its-kind own-data test of the PMC9920669 claim.

### Sources
- [PMC9920669 — Effectiveness of RSI Signals in Timing Cryptocurrency Market](https://pmc.ncbi.nlm.nih.gov/articles/PMC9920669/)
- [QuantifiedStrategies — Divergence Trading Strategy Backtest](https://www.quantifiedstrategies.com/divergence-trading-strategy/)
- [Kraken Learn — RSI Divergences](https://www.kraken.com/learn/rsi-divergences-what-they-how-they-work)
- [SaintQuant — Bullish Divergence RSI Crypto](https://saintquant.com/blog/173-bullish-divergence-rsi-how-smart-crypto-traders-spot-early-reversals)
- [Concord p2c — Is Bullish Divergence Reliable? Backtested](https://www.concordp2c.com/is-bullish-divergence-reliable-backtested-insights-and-common-mistakes-to-avoid/)
- [FXOpen — Hidden vs Regular Divergence](https://fxopen.com/blog/en/what-is-the-difference-between-regular-and-hidden-divergence/)
- [arxiv 2410.06935 — Predicting Bitcoin Market Trends with Enhanced Technical Indicators](https://arxiv.org/html/2410.06935v1)
