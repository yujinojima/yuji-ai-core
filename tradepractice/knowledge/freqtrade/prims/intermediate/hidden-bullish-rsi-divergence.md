---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T07:13:06+10:00
cycle: 16
---

---

## Prim: hidden-bullish-rsi-divergence
**Level:** intermediate (refined from naive)
**Project:** freqtrade
**Parent:** naive/hidden-bullish-rsi-divergence

### Rule
**EMA ribbon ≥ 3 aligned** + ADX 20–45 rising + price > 1h EMA200 + **true 5-bar pivot pair** (8–40 candle separation) with price HL + RSI(14) LL (≥ 3pt gap, **RSI LL ≥ 30** — below 30 = regular-div territory conflict) + **Fibonacci pullback ≤ 50% of prior impulse** + **MACD hist ≥ 0 at pivot-2** + **volume declining across pivots** + **next-candle confirmation** + **hard mutual exclusivity** (reject if regular-div active same pair) + 4h primary + fee-adjusted R:R ≥ 1:1.5 → long to prior swing high.

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Pivot detection | rolling 5-bar min/max | **True 5-bar pivot** (argrelextrema, left/right bar confirmed) |
| Pivot separation | 5–30 candles | **8–40 candles** |
| RSI range | ≥ 3pt LL | ≥ 3pt LL **AND RSI LL ≥ 30** (below 30 = exhaustion, regime conflict with regular div) |
| Trend quality | EMA50>EMA200 + ADX≥20 | **EMA ribbon ≥ 3 layers aligned + ADX rising** (direction, not just threshold) |
| Pullback depth | close > pivot-2 low | **Fibonacci ≤ 50% of prior impulse** (structure integrity filter) |
| MACD | not required | **MACD hist ≥ 0** at pivot-2 (bullish momentum dominant) |
| Volume | not specified | **Declining across pivots** (weak-seller confirmation) |
| Confirmation | same-candle | **Next-candle**: close > pivot-2 close |
| Mutual exclusivity | flag only | **Hard exclusion** from entry when regular-div signal active |
| Timeframe | untested | **4h primary** (convergent practitioner consensus) |
| ADX ceiling | none | **ADX ≤ 45** (parabolic exclusion) |
| R:R gate | implied | **fee-adjusted ≥ 1:1.5** |
| Certainty | guess | **hypothesis** |

### Evidence — 8 Sources

| Source | Finding |
|---|---|
| FXOpen | Hidden div = trending-market tool; directional opposite of regular div |
| ACY | Trend-continuation bias; 4h/daily more reliable than sub-1h |
| Babypips | Hidden div "more reliable in trending markets than regular divergence" — explicit comparative |
| Alchemy Markets | Continuation signal; mechanistically distinct from reversal (regular div) |
| Murphy, TAOFM | Fib 50% = critical trend-structure boundary; corrections holding above confirm uptrend intact |
| Elder, Trading for a Living | MACD zero-line = trend direction filter; hist ≥ 0 = bullish momentum dominant |
| Wyckoff accumulation | Declining volume on correction = weak sellers = shallow, continuation-likely pullback |
| Sister prim research chain | Double-confirmation +15–25pp WR; next-candle +5–10pp WR (LuxAlgo, Concord p2c — applied by analogy) |

**PMC9920669:** tested ONLY regular divergence (LEAST EFFECTIVE RSI variant on crypto). **Hidden div NOT tested** — no negative evidence, but also no positive anchor.

### Key Numbers

| Metric | Value |
|---|---|
| Expected live WR | **58–65%** (derived, not measured) |
| Post-OOS lower bound | **53–58%** (25–50% Sharpe degradation from sister prim meta) |
| Signal frequency | Estimated < 0.5% of candles |
| RSI LL floor | ≥ 30 (below = regular-div territory) |
| Fibonacci pullback ceiling | 50% of prior impulse |

### 10 Implementation Gaps (YujiDivergenceStrategy.py)
1. Mirror pivot detection: `argrelextrema(close, np.greater, order=5)` for price HL; `argrelextrema(rsi, np.less, order=5)` for RSI LL; match indices
2. New IntParameters: `hidden_divergence_lookback` (default 15, range 8–40); `rsi_hidden_min_gap` (default 3, range 2–7)
3. RSI floor: reject if `rsi_at_pivot_2 < 30`
4. EMA ribbon gate: ≥ 3 of {EMA10>EMA21, EMA21>EMA50, EMA50>EMA200} true
5. Fibonacci depth: `(prior_impulse_high - pivot_2_low) / (prior_impulse_high - prior_impulse_low) ≤ 0.50`
6. MACD gate: `macd_hist >= 0` at pivot-2 candle
7. Volume declining: `volume_at_pivot_2 < volume_at_pivot_1`
8. Next-candle: `hidden_div_signal.shift(1) & (close > close.shift(1))`
9. Hard mutual exclusivity: `& ~buy_rsi_div & ~buy_macd_div & ~buy_double_div`
10. 4h primary TF; 1h secondary; no sub-1h

### Critical Limitation
No own-data backtest. The RSI ≥ 30 lower bound and Fibonacci 50% ceiling are theoretically motivated but untested as unit filters for hidden divergence specifically. Deployment blocked on: (a) own-data walk-forward across bull→bear phases, (b) head-to-head vs regular-div intermediate on same data window (primary research deliverable — validates or inverts FXOpen/ACY "more reliable in trends" hierarchy for crypto), (c) parameter plateau test on lookback and gap-min.

### Files Updated
- `knowledge/freqtrade/prims/intermediate/hidden-bullish-rsi-divergence.md` (created, 130 lines)
- `knowledge/epistemic-index.md` (naive marked SUPERSEDED; intermediate freqtrade table +1 row → 5 intermediate prims)
- `knowledge/conditions-log.md` (naive marked historical, intermediate entry appended)
- Commit: `74e70ef`

### Bank State After Cycle 16

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | **0** | 0 |
| Intermediate | **5** (rsi-oversold, ema-pullback, liq-sweep, regular-div, hidden-div) | 3 |
| Sophisticated | 3 | 0 |

All freqtrade naive prims are now refined. 5 intermediate, 3 sophisticated.

### Next Cycle Recommendation
**BACKTEST-ANALYSIS** — shared blocker across all 5 intermediate prims. Primary target: **head-to-head walk-forward of hidden-div vs regular-div intermediate** on same BTC/ETH data window (bull → bear → accumulation). This test has clean falsification design and directly adjudicates:
- Both survive → divergence mechanism has regime-specific validity on crypto (novel)
- Hidden survives, regular fails → validates FXOpen/ACY/Babypips hierarchy
- Both fail → RSI divergence mechanism invalidated for crypto as asset class (mark both as anti-prims)
- Regular survives, hidden fails → inverts practitioner consensus; requires reinterpretation

Any outcome is load-bearing. Secondary: parameter plateau test on `hidden_divergence_lookback` and `rsi_hidden_min_gap`.

### Sources
- [FXOpen — Hidden vs Regular Divergence](https://fxopen.com/blog/en/what-is-the-difference-between-regular-and-hidden-divergence/)
- [ACY — RSI Hidden Divergence](https://acy.com/en/market-news/education/how-to-spot-rsi-hidden-divergence-j-o-121814/)
- [Babypips — Hidden Divergence](https://www.babypips.com/learn/forex/hidden-divergence)
- [Alchemy Markets — Hidden Divergence](https://alchemymarkets.com/education/hidden-divergence/)
- [PMC9920669 — Effectiveness of RSI Signals in Timing Cryptocurrency Market](https://pmc.ncbi.nlm.nih.gov/articles/PMC9920669/) (regular-div negative result; hidden div NOT tested)
- [LuxAlgo — RSI at S/R: 60–65% WR with confirmation](https://www.luxalgo.com/blog/5-rsi-entry-strategies-using-support-and-resistance/)
- [Concord p2c — Structure-break confirmation adds 15–25pp WR](https://www.concordp2c.com/is-bullish-divergence-reliable-backtested-insights-and-common-mistakes-to-avoid/)
