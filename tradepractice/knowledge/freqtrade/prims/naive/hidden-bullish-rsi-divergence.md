---
name: hidden-bullish-rsi-divergence
level: naive
project: freqtrade
parent_prim: none
companion_prim: intermediate/bullish-rsi-divergence
created: 2026-04-11
last_validated: never
reaction_validated: assumed
---

## Prim: hidden-bullish-rsi-divergence
**Level:** naive
**Project:** freqtrade
**Parent:** none
**Companion:** intermediate/bullish-rsi-divergence (regular div — exhaustion/late-bear regime)

### Situation

**Setup:** Price is in a confirmed uptrend. A pullback retraces part of the prior impulse. On the pullback the price print makes a **higher low (HL)** vs the prior pullback low, but RSI(14) makes a **lower low (LL)** on the same pivot pair. Oscillator is "overselling" the pullback relative to where price actually traded. Agent reading: dip-buyers are still positioned at higher prices; late profit-takers (who exited on the prior dip) see momentum weakening and re-short; when price refuses to break the prior HL, the late shorts are trapped and must cover — continuation fuel.

**Trigger:** Price HL confirmed via rolling 5-bar pivot AND RSI(14) LL on the same pivot pair. Second pivot low of divergence pair is the signal candle.

**Reaction:**
- **Accepted:** Close holds above pivot-2 low; next candle breaks above recent minor swing high; volume on continuation candle ≥ volume at pivot. Trend resumes.
- **Rejected:** Close below pivot-2 low OR breakdown through pivot-1 low. Uptrend invalidated — this was not a pullback, it was distribution. Exit immediately.
- **Unclear:** Rangebound consolidation after signal, no structure break, low volume. No action.

**Agent Behaviour:**
- **Who is acting:** Trend-followers adding to longs on pullback; dip-buyer cohort re-entering at defended support.
- **Who is trapped:** Late shorts / profit-takers betting the pullback extends; they faded a holding trend.
- **Who is wrong:** The oscillator. RSI LL says "momentum exhausted" but price HL says "seller cohort too thin to break structure." Price wins; oscillator re-rates.

**Outcome:**
- **If accepted:** Trend continuation to prior swing high or next structural resistance. Target = recent higher-high.
- **If rejected:** Trend invalidation. This is why the signal is dangerous without regime gate — hidden div in a nascent reversal is a bull trap.

### Rule
In a confirmed uptrend (EMA50 > EMA200, ADX ≥ 20, price > 1h EMA200), if a rolling-pivot pullback prints **price HL + RSI LL** (same pivot pair, 5–30 candle separation, RSI LL gap ≥ 3 points) AND close holds above the pivot-2 low, long-bias toward the prior swing high with stop below pivot-2 low.

### Mechanism
Hidden divergence is the **trend-continuation mirror** of regular divergence. Where regular divergence says "momentum is leading price — reversal coming," hidden divergence says "momentum overstated the pullback — the trend-follower cohort is still in control." The edge comes from trapped counter-trend shorts that faded a pullback they misread as a reversal: when price fails to break the prior HL, their stops cluster just below the last pivot, creating a stop-run into trend resumption. The oscillator "lying about" the pullback is the visible footprint of a thin seller cohort that couldn't push price as low as momentum suggested.

### Conditions
- **Works when:** Confirmed uptrend (EMA50 > EMA200, ADX ≥ 20); pullback is corrective (≤ 38.2% Fibonacci of prior impulse typical); seller volume declining on pullback; 4h/daily timeframe preferred per convergent sources; major pairs in established bull phase
- **Fails when:** Nascent reversal (trend not yet confirmed — hidden div becomes bull trap); accelerating downtrend (same rule inverts); sideways/ranging regime (no trend to continue); ADX < 20 (insufficient trend strength); price already extended > 2 ATR from EMA50 (entry too late); single-oscillator detection without volume/structure filters
- **Best pairs:** untested — hypothetically major pairs (BTC/USDT, ETH/USDT) during established uptrends where the sister prim (regular div) is REGIME-EXCLUDED
- **Best timeframe:** untested in own code; convergent practitioner sources (FXOpen, ACY, Babypips, Alchemy Markets) report 4h/daily more reliable than 1h for hidden divergence specifically

### Evidence
- **Source:** anecdote (convergent practitioner sources + no peer-reviewed crypto anchor yet)
- **Certainty:** guess
- **Scope:** untested
- **Falsifiability:** untested-in-own-code
- **Reaction observed:** assumed
- **Data:** pending backtest; no published large-n study found for hidden bullish divergence specifically on crypto (PMC9920669 tested regular div, not hidden)
- **Citation:**
  - [FXOpen — Hidden vs Regular Divergence](https://fxopen.com/blog/en/what-is-the-difference-between-regular-and-hidden-divergence/) — "hidden divergence is used in trending markets"
  - [ACY — RSI Hidden Divergence](https://acy.com/en/market-news/education/how-to-spot-rsi-hidden-divergence-j-o-121814/) — trend-continuation bias
  - [Babypips — Hidden Divergence](https://www.babypips.com/learn/forex/hidden-divergence) — "more reliable in trending markets than regular divergence"
  - [Alchemy Markets — Hidden Divergence](https://alchemymarkets.com/education/hidden-divergence/) — continuation signal distinction

### Limitations
1. **No peer-reviewed crypto anchor** — PMC9920669 tested regular divergence (and rated it LEAST EFFECTIVE of RSI experiments on crypto); hidden divergence has NOT been independently tested on crypto in the same methodology. The convergent practitioner claim is UNVERIFIED for this asset class.
2. **Trend-confirmation dependency is the critical variable** — a nascent reversal misclassified as "uptrend" turns hidden div into a bull trap. False-positive rate is a direct function of trend-regime detection accuracy.
3. **Not currently implemented in YujiDivergenceStrategy** — the strategy detects only regular bullish divergence (price LL + RSI HL) at `populate_indicators`. Hidden divergence requires the mirror pivot detection (price HL + RSI LL).
4. **Pivot-detection risk inherited** — sister prim documented that rolling-min/rolling-max is not true pivot detection; same methodology gap applies here (pivot detection must use left/right 5-bar confirmation).
5. **Parameter dead zone unknown** — RSI LL gap threshold, pullback depth bounds, lookback window for pivot pair — all untuned. Plateau test required before any elevation.
6. **Signal frequency unknown** — if regular div is ~0.8% of candles (PMC9920669), hidden div frequency in uptrends is an open question. May be even rarer (only prints during confirmed-trend pullbacks).
7. **Regime gate is mandatory, not optional** — unlike most naive prims where regime is a nice-to-have refinement, hidden div WITHOUT trend confirmation is actively harmful. Even the naive version should include an EMA50 > EMA200 precondition.
8. **Exit logic underspecified** — target at prior HH is obvious; stop placement less so. Stop below pivot-2 low is one convention; stop below pivot-1 low is more conservative but gives worse R:R.
9. **Same asymmetry caveat as regular div** — SaintQuant reported ~10x forward ROI asymmetry for bullish-vs-bearish regular divergence; no equivalent asymmetry data exists for hidden divergence.
10. **Interaction with sister prim** — the regular-div intermediate explicitly excludes persistent uptrend. Hidden div is designed to fire EXACTLY there. The two prims must be mutually exclusive by regime, not overlapping — otherwise a conflicted signal state is possible.

### Implementation
- **File:** `user_data/strategies/YujiDivergenceStrategy.py` (mirror addition — not a new strategy file)
- **Detection logic (to be added):**
  ```python
  # Mirror of existing regular-div detection (lines 107–190)
  # Pivot detection: left/right 5-bar confirmation
  # Signal: price.pivot_high[p2] > price.pivot_high[p1] (price HL)
  #     AND rsi.at_pivot[p2] < rsi.at_pivot[p1] - rsi_hidden_div_min  (RSI LL)
  #     AND uptrend_confirmed (EMA50 > EMA200, ADX >= 20)
  #     AND close > pivot_2_low (not breaking structure)
  ```
- **New parameters:**
  - `hidden_divergence_lookback` (IntParameter, default=15, range 10–30)
  - `rsi_hidden_divergence_min` (IntParameter, default=3, range 2–7)
  - `uptrend_adx_min` (IntParameter, default=20, range 15–30)
- **Reaction detection:** NOT implemented in naive version — next-candle confirmation is an intermediate refinement
- **Regime gate (MANDATORY even for naive):** `(ema_50 > ema_200) & (adx >= 20)` — unlike sister naive prims where regime is a future refinement, this is a precondition for fire-safety

### Conditions Log Entry
- **Works when:** confirmed uptrend (EMA50 > EMA200, ADX ≥ 20), corrective pullback with price HL + RSI LL, close holding above pivot-2 low
- **Fails when:** nascent reversal misclassified as trend, ADX < 20, ranging market, accelerating downtrend, close breaks pivot-2 low
- **Last validated:** never (NEW prim — hidden-divergence variant never implemented or tested in Yuji codebase)

### Epistemic Framing — Why This Matters

This prim exists specifically to close a **regime coverage gap** in the knowledge bank. After cycle 13, the four freqtrade prims partitioned the market as:

| Regime | Prim | Status |
|---|---|---|
| Ranging | rsi-oversold-mean-reversion | sophisticated |
| Ranging-to-mild-trend | liquidity-sweep-reversal | sophisticated |
| Trending | ema-pullback-dynamic-support | sophisticated |
| Exhaustion/late-bear | bullish-rsi-divergence (regular) | intermediate |

But the trending regime has **two active prims** — ema-pullback (structural, via moving average) and now hidden-div (momentum, via oscillator mirror). These are not redundant: they trigger on different microstructures within the same regime. EMA pullback activates on first-touch of a dynamic support level; hidden div activates on a pivot-pair pullback signature regardless of EMA proximity. Both can fire on the same pullback; agreement strengthens conviction, disagreement flags ambiguity.

More importantly, hidden-bullish-rsi-divergence is the **first-of-its-kind own-data test of the FXOpen/ACY/Babypips/Alchemy claim** that hidden divergence is more reliable in trending markets than regular divergence. No peer-reviewed crypto study tests this claim. A rigorous backtest comparing regular-div (in exhaustion regime) vs hidden-div (in trend regime) on the same pair/period would be novel research leverage — and the sister prim's published negative result (PMC9920669) sets up a clean falsification: if hidden-div ALSO fails on crypto, then RSI divergence as a mechanism is invalidated for this asset class, not just the regular variant.

### Next Cycle Recommendation
Sister prim already carries highest falsification risk. Before elevating this new naive to intermediate, the next BACKTEST-ANALYSIS cycle should test BOTH divergence variants head-to-head:
- Regular div in exhaustion regime (sister intermediate filter set)
- Hidden div in trend regime (this prim)
On the same data window with identical fee/slippage assumptions. If hidden div survives and regular div fails, the partition is validated. If both fail, mark both as anti-prims and redirect divergence-research effort elsewhere. If both survive, we have the first quantitative crypto test of the hidden-vs-regular reliability hierarchy.
