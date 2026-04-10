---
name: bullish-rsi-divergence
level: naive
project: freqtrade
parent_prim: none
created: 2026-04-10
last_validated: never
reaction_validated: assumed
---

## Prim: bullish-rsi-divergence
**Level:** naive
**Project:** freqtrade
**Parent:** none

### Situation

**Setup:** Over a 10–30 candle lookback, price prints a lower low while RSI(14) prints a higher low (by at least 5 RSI points). Momentum is failing to confirm new price lows — sellers are pushing price but losing force. Classic "regular bullish divergence" — a signature of trend exhaustion at the bottom.

**Trigger:** On the entry timeframe (1h), the current rolling-min of `low` is below the prior rolling-min, AND the current rolling-min of `rsi` is above the prior rolling-min by >= 5 points. Additional confluence: RSI < 40, close < BB middle, stochastic turning up from < 40, volume > 0.8x SMA(20).

**Reaction:**
- **Accepted:** Next candle is bullish, closes above the divergence swing low, stochastic continues up, RSI crosses 45 within 3–5 candles — sellers absorbed, momentum flipping.
- **Rejected:** Price prints another lower low, RSI also prints a lower low — divergence broken, continuation down. This is the canonical "divergence can persist" failure mode.
- **Unclear:** Sideways chop at the swing low; no directional close; divergence intact but not yet confirmed.

**Agent Behaviour:**
- **Who is acting:** Late shorts entering the extended downtrend; mean-reversion algos triggered by oversold oscillators; distressed longs being stopped out.
- **Who is trapped:** Late shorts who sold into the lower-low that already lacks momentum — their stops sit above the prior swing high. The divergence itself is the tell that their edge is gone.
- **Who is wrong:** The "trend continuation" crowd shorting weakness. Divergence reveals they're late to a move that is running out of fuel.

**Outcome:**
- If accepted: mean-reversion bounce toward BB middle, then potentially to the prior swing high as late shorts cover.
- If rejected: trend continues lower — and divergence can re-print multiple times in a parabolic move, each one a failed signal.
- If unclear: no action until a confirming candle closes.

### Rule
If price rolling-low makes a lower low AND RSI(14) rolling-low makes a higher low (>= 5 pts) within a 10–30 candle window AND RSI < 40 AND close < BB middle AND stochastic turning up → long bias toward BB middle / prior swing high, conditional on reaction acceptance.

### Mechanism
Momentum is the derivative of trapped-position flow. When price falls but RSI doesn't confirm, the mass of sellers driving price down is shrinking — each new low is produced by fewer, weaker hands. Late shorts pile in anyway (the trend is "obvious"), but there is no fuel left to propagate. When mean-reversion algos or opportunistic longs step in, there are no strong sellers left to absorb the bid — price snaps back, late shorts are stopped out, and their covering fuels the reversal. Divergence is not a predictive indicator; it is a record that the seller cohort has thinned below the threshold required to make the next leg.

### Conditions
- **Works when:** Ranging or late-stage downtrend (exhaustion phase, not trend-initiation); price at a defended level (BB lower, prior support, VAL); volume declining on successive lows (sellers leaving); 4h RSI > 20 (not in freefall capitulation); higher-timeframe trend neutral or bottoming
- **Fails when:** Parabolic or strong trending move — divergence can persist for weeks, each new signal worse than the last; news-driven capitulation (fundamentals override momentum); rising cryptocurrencies in bull markets (PMC9920669: "counterproductive" on rising BTC/ETH); single-divergence setups without confirmation candle; signals fired same-candle without waiting for structure break
- **Best pairs:** untested — hypothetically better on ranging or late-bear assets; actively counterproductive on strong-uptrend majors per academic study
- **Best timeframe:** untested — implemented 1h (YujiDivergenceStrategy); higher timeframes (daily) reported more reliable but have fewer signals

### Evidence
- **Source:** anecdote (code extraction) + academic counter-evidence (PMC9920669, peer-reviewed) + convergent practitioner backtests
- **Certainty:** guess (code) → hypothesis (research)
- **Scope:** cryptocurrency mid/higher timeframes; Bitcoin-specific counterproductive signal documented
- **Falsifiable:** partially tested — PMC9920669 rates RSI divergence the LEAST EFFECTIVE of all RSI experiments
- **Reaction observed:** assumed — no forward-test or backtest results for the specific filter set
- **Data:** 
  - **PMC9920669 (peer-reviewed, 10 cryptos, 1,462 days):** Divergences occurred in only **0.8% of candles** on average per divergence type. Rated "hardest to implement, least effective" of all RSI signals tested. Authors explicitly advise against using RSI divergence on rising BTC/ETH (signal works counterproductively).
  - **Naive standalone** (traded on first signal, no filters): "two out of three losing trades" base rate (multiple practitioner sources).
  - **With MACD confluence** (double divergence, per Gate.io 2026 analysis): 77% backtest win rate — but selection bias suspected.
  - **With structure-break confirmation + candlestick pattern** (practitioner backtest n=16 setups): 50–65% WR typical; one outlier 86% on small n.
  - **Bitcoin asymmetry** (practitioner, 2023): Bullish divergence 60-day forward ROI ~10x bearish divergence's — suggests bullish signal has some directional bias even if WR is low.
- **Citation:** YujiDivergenceStrategy.py populate_indicators (lines 107–142) + populate_entry_trend (lines 149–190)

### Limitations
1. **Divergence can persist indefinitely** in parabolic moves — the #1 failure mode. Every new signal during a continuing trend is a fresh losing trade. Code has no "second-strike" throttle.
2. **Rolling-min swing detection** approximates pivots but misclassifies: the "lower low" may not be at an actual structural level; the "higher low" in RSI may be on a noise bar. True pivot detection (e.g. `ta.MIN` + lookahead) is not implemented.
3. **Signal is rare** (0.8% of candles per PMC9920669) — limited trade frequency means even a high-win-rate version contributes little absolute return and is hard to validate statistically.
4. **No regime gate** — current YujiDivergenceStrategy fires in any regime; academic study confirms this is exactly where divergence fails on BTC/ETH.
5. **No next-candle confirmation** — entry fires on the same candle the divergence condition is met, before the reaction reveals itself.
6. **The naive rule has been formally tested and rated worst of the RSI family** — PMC9920669 is a published negative result, not an absence of evidence.
7. **Distance-between-pivots not enforced** — the study specified 3–60 candle distance; the code uses a single lookback window (10–30 default) which conflates signal bandwidth with pivot separation.
8. **Hidden divergence (trend-continuation variant) is not implemented** — and hidden divergence is reportedly more reliable in trending markets than regular divergence.
9. **Frequency on Yuji's whitelist pairs is unknown** — the 0.8% rate is an average across 10 cryptos in the study; individual pairs may print divergences far less often.
10. **RSI lookback parameter (divergence_lookback default 20)** is untuned; no plateau test has been performed to verify edge is not curve-fit to a single lookback value.

### Implementation
- **File:** `user_data/strategies/YujiDivergenceStrategy.py`
- **Parameters:** 
  - `divergence_lookback` (IntParameter, default=20, range 10–30, space="buy")
  - `rsi_divergence_min` (IntParameter, default=5, range 3–10, space="buy")
- **Code:** 
  - Divergence detection: lines 107–142 (rolling-min comparison)
  - Buy 1 (RSI divergence + stoch turn): lines 151–159
  - Buy 2 (MACD divergence): lines 162–168
  - Buy 3 (double divergence): lines 171–176
  - 4h HTF guard: `rsi_4h > 20` (line 179)
- **Reaction detection:** partial — stochastic turn is a same-candle proxy; no next-candle confirmation; no structure break verification
- **Exit:** bearish divergence symmetric (lines 197–215) + BB upper + MACD bearish cross

### Conditions Log Entry
- **Works when:** ranging or late-bear market, price at defended level, volume declining on successive lows, 4h RSI > 20, not in parabolic trend
- **Fails when:** strong/parabolic trends (divergence persists); rising BTC/ETH bull market (PMC9920669 counterproductive); news capitulation; no confirmation candle; signal fired on first detection
- **Frequency:** ~0.8% of candles (rare)
- **Last validated:** never

### Sources
- [PMC9920669 — Effectiveness of RSI Signals in Timing Cryptocurrency Market](https://pmc.ncbi.nlm.nih.gov/articles/PMC9920669/) — peer-reviewed: divergences 0.8% of candles, "least effective" RSI signal, counterproductive on rising BTC/ETH
- [QuantifiedStrategies — Divergence Trading Strategy Backtest](https://www.quantifiedstrategies.com/divergence-trading-strategy/) — naive divergence rules underperform filtered versions
- [Kraken Learn — RSI Divergences](https://www.kraken.com/learn/rsi-divergences-what-they-how-they-work) — "2 out of 3 losing trades" on naive first-signal entry
- [SaintQuant — Bullish Divergence RSI Crypto](https://saintquant.com/blog/173-bullish-divergence-rsi-how-smart-crypto-traders-spot-early-reversals) — Bitcoin 60-day forward ROI asymmetry (bullish ~10x bearish)
- [Concord p2c — Is Bullish Divergence Reliable? Backtested](https://www.concordp2c.com/is-bullish-divergence-reliable-backtested-insights-and-common-mistakes-to-avoid/) — "divergence alone did not create profit; structure and confirmation did"
- [FXOpen — Hidden vs Regular Divergence](https://fxopen.com/blog/en/what-is-the-difference-between-regular-and-hidden-divergence/) — regular divergence ranging, hidden divergence trending
- [arxiv 2410.06935 — Predicting Bitcoin Market Trends with Enhanced Technical Indicators](https://arxiv.org/html/2410.06935v1) — ML feature engineering for crypto TA

---

**Gap assessment update** — remaining uncaptured freqtrade naive prims:

| Priority | Strategy | Signal | Status |
|---|---|---|---|
| ~~1~~ | ~~YujiDivergenceStrategy~~ | ~~bullish RSI divergence~~ | **CAPTURED (this cycle)** |
| 1 | YujiExtinctionBurstStrategy | Capitulation (consecutive red + vol spike + extreme oscillators) | **uncaptured** |
| 2 | YujiScalperStrategy | BB %B oversold + StochRSI | **uncaptured** (overlaps RSI mean reversion) |
| 3 | YujiFluidStrategy | unread | **unread** |
| 4 | YujiStrategy/V2/V3 | unread | **unread** |
| 5 | YujiInverseScalperStrategy | unread | **unread** |

Next-cycle recommendation: **YujiExtinctionBurstStrategy → capitulation-exhaustion prim**. Distinct mechanism (climactic selling vs divergent momentum), complements the regime partition (adds "panic/capitulation" as a fourth regime beyond ranging/transitional/trending).
