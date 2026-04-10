---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T06:56:23+10:00
cycle: 14
---

---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T06:55:00+10:00
cycle: 14
---

## Prim: hidden-bullish-rsi-divergence
**Level:** naive
**Project:** freqtrade
**Parent:** none
**Companion:** intermediate/bullish-rsi-divergence (regular div, exhaustion regime)

### Rule
Confirmed uptrend (EMA50 > EMA200, ADX ≥ 20, price > 1h EMA200) + rolling 5-bar pivot pair with price HL + RSI(14) LL (≥ 3pt gap, 5–30 candle separation) + close holds above pivot-2 low → long to prior swing high, stop below pivot-2 low.

### Mode: RESEARCH — New Angle (regime coverage gap close)

Three of four freqtrade prims already sophisticated; bullish-rsi-divergence (regular) sits at intermediate with highest falsification risk and published negative evidence — further elevation premature without own-data backtest. Higher-leverage move: extract **implementation gap #12 from cycle 13** as a new naive prim covering the regime the sister prim explicitly excludes.

### What This Closes

| Regime | Prim | Level |
|---|---|---|
| Ranging | rsi-oversold-mean-reversion | sophisticated |
| Ranging-to-mild-trend | liquidity-sweep-reversal | sophisticated |
| Trending (structural) | ema-pullback-dynamic-support | sophisticated |
| Exhaustion/late-bear | bullish-rsi-divergence (regular) | intermediate |
| **Trending (momentum)** | **hidden-bullish-rsi-divergence** | **naive (NEW)** |

Sister intermediate excludes persistent uptrend (`EMA200 slope > 0 AND ADX > 35`). This prim is designed to fire exactly there. Mutual exclusivity by regime, not overlap.

### Mechanism Inversion

| Variant | Trapped cohort | Fuel direction |
|---|---|---|
| Regular div | Late shorts at exhaustion low | Reversal |
| **Hidden div** | **Counter-trend shorts fading a pullback** | **Continuation** |

Same agent model; opposite direction. Oscillator "lies about" the pullback — seller cohort too thin to break structure.

### Evidence — 4 Convergent Practitioner Sources, ZERO Peer-Reviewed Crypto Anchors

| Source | Claim |
|---|---|
| FXOpen | "Hidden divergence is used in trending markets" |
| ACY | Trend-continuation bias (vs reversal bias of regular) |
| Babypips | "More reliable in trending markets than regular divergence" |
| Alchemy Markets | Continuation-signal pattern distinction |
| **PMC9920669** | **Tested ONLY regular div; rated LEAST EFFECTIVE RSI variant on crypto** |

**The practitioner consensus is unverified for crypto.** This prim is constructed specifically to be the first own-code test of that claim.

### Why Regime Gate is a Naive-Level Precondition, Not a Refinement

Unlike sister naive prims where regime filtering is a future intermediate refinement, hidden div without trend confirmation is **actively harmful** — a nascent reversal misclassified as uptrend turns the signal into a bull trap. The gate `EMA50 > EMA200 AND ADX ≥ 20` must be present even in the naive version.

### 10 Documented Limitations
1. No peer-reviewed crypto anchor — practitioner consensus unverified
2. Trend-confirmation accuracy is THE critical variable (bull-trap risk)
3. Not currently implemented in YujiDivergenceStrategy (mirror addition required)
4. Pivot-detection risk inherited from sister prim (rolling-min ≠ true pivot)
5. Parameter dead zone unknown (lookback, gap, ADX all untuned)
6. Signal frequency unknown — may be even rarer than regular div (~0.8%)
7. Regime gate MANDATORY not optional
8. Exit logic underspecified (stop below pivot-2 vs pivot-1 tradeoff)
9. No asymmetry data (SaintQuant ~10x forward-ROI finding is regular-div only)
10. Mutual exclusivity with sister prim must be asserted — simultaneous fire = regime-partition failure

### Falsification Design

The head-to-head opportunity this creates is epistemically clean:

| Outcome | Interpretation |
|---|---|
| Both survive | Hidden-vs-regular reliability hierarchy validated on crypto (novel result) |
| Hidden survives, regular fails | FXOpen/ACY/Babypips consensus validated; refine hidden to intermediate |
| Both fail | **RSI divergence as mechanism invalidated for crypto entirely — mark both as anti-prims** |
| Regular survives, hidden fails | Inverts practitioner consensus — requires reinterpretation |

Any of the four outcomes is load-bearing research output. The current bank has no prim with this structural clarity in its falsification path.

### Files Updated
- `knowledge/freqtrade/prims/naive/hidden-bullish-rsi-divergence.md` (created, 120 lines)
- `knowledge/epistemic-index.md` (naive freqtrade table: +1 row → 5 naive prims, 4 active + 1 superseded)
- `knowledge/conditions-log.md` (new naive entry appended with implementation gaps and falsification design)
- Commit: `522b902`

### Bank State After Cycle 14

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 1 (hidden-div) | 1 (binary-arb-completeness) |
| Intermediate | 4 (rsi-oversold, ema-pullback, liq-sweep, regular-div) | 3 (spread-capture, ensemble-forecast, kelly-sizing) |
| Sophisticated | 3 | 0 |

5 freqtrade prims (1 naive + 4 intermediate + 3 sophisticated); regime partition now 5-axis.

### Next Cycle Recommendation

**BACKTEST-ANALYSIS** — shared blocker across all 4 intermediate prims + this new naive. The highest-leverage backtest is the **head-to-head regular-div vs hidden-div** on same data window (bull → bear → accumulation across BTC/ETH), because it is the only test in the bank with a clean falsification design and directly tests a published negative result (PMC9920669). Second priority is RESEARCH on capitulation-exhaustion from YujiExtinctionBurstStrategy for a distinct mechanism class.

### Sources
- [FXOpen — Hidden vs Regular Divergence](https://fxopen.com/blog/en/what-is-the-difference-between-regular-and-hidden-divergence/)
- [ACY — RSI Hidden Divergence](https://acy.com/en/market-news/education/how-to-spot-rsi-hidden-divergence-j-o-121814/)
- [Babypips — Hidden Divergence](https://www.babypips.com/learn/forex/hidden-divergence)
- [Alchemy Markets — Hidden Divergence](https://alchemymarkets.com/education/hidden-divergence/)
- [PMC9920669 — Effectiveness of RSI Signals in Timing Cryptocurrency Market](https://pmc.ncbi.nlm.nih.gov/articles/PMC9920669/) (regular-div anchor; no hidden-div coverage)
