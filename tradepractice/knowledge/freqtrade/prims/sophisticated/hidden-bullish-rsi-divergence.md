---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T13:10:03+10:00
cycle: 19
---

---

## Prim: hidden-bullish-rsi-divergence
**Level:** sophisticated (refined from intermediate)
**Project:** freqtrade
**Parent:** intermediate/hidden-bullish-rsi-divergence

### Rule
**EMA ribbon ≥ 3 aligned** + ADX 20–45 rising + price > 1h EMA200 + **true 5-bar pivot pair** (8–40 candle separation) with price HL + RSI(14) LL (≥ 3pt gap, **RSI LL ≥ 30** — below 30 = regular-div exhaustion territory) + **Fibonacci pullback ≤ 50% of prior impulse** + **MACD hist ≥ 0 at pivot-2** + **volume at pivot-2 < 50% of pivot-1 impulse candle volume** (Wyckoff "test on low volume") + **next-candle confirmation** (close > pivot-2 close) + **hard mutual exclusivity** (reject if regular-div active same pair same candle) + 4h primary (1h secondary, never sub-1h) + **fee+slippage-adjusted edge > 2× friction** + **parameter plateau verified** (PF variance < 25% across 28-cell grid) + **CPCV + Deflated Sharpe correction applied** (28 cells crosses PBO threshold) + **R:R ≥ 1:2** → long to prior swing high.

### What Elevated This from Intermediate

13 sources (up from 8), with the **first mechanistic cross-reference from PMC9920669, quantified friction model, OOS degradation ceiling, parameter-sensitivity bounds, Wyckoff volume threshold, and multiple-testing correction requirement specific to trend-continuation divergence**. Elevation does not come from direct crypto WR data — it comes from (a) establishing mechanistic alignment with the WINNING side of the only peer-reviewed crypto study, (b) quantifying every filter's information contribution, and (c) bounding realistic live performance identically to sister sophisticated prims.

| New Finding | Source | Impact |
|---|---|---|
| **PMC9920669 cross-reference**: momentum RSI>50 returned 773.6% vs B&H 275.2% (+498pp); reversal RSI<30 returned 177.7% (−97.5pp). Hidden div aligns with **momentum side**, not reversal side. | PMC9920669 (same study as sister prim negative anchor) | Mechanistic alignment; hidden div enters sophisticated with **no published negative evidence AND mechanistic support from only peer-reviewed crypto study** |
| **Friction Sharpe erosion ~47%** at typical crypto fees+slippage | BSIC, FMZQuant, PANews | Friction model from sister prims applies in full; sub-1h lethal |
| **OOS degradation 26–58%** ceiling (McLean-Pontiff factor zoo) | QuantPedia, arxiv 2602.10785 | Bounds live Sharpe at 50–70% IS for trend-following divergence |
| **Real overfit example +28.4% IS → −79.3% live** | QuantVPS / CPCV | Anchors tail-risk magnitude of uncorrected IS optimisation |
| **PBO + Deflated Sharpe REQUIRED** — 7 lookbacks × 4 gap values = 28 cells | Bailey-Borwein-Lopez de Prado SSRN 2326253 | 28 > 20 cell threshold; DSR replaces raw Sharpe in all reporting |
| **HFT variant sign-flip +84k gross → −99k net** (similar oscillator rule class) | FMZQuant / PANews | Confirms sub-1h ban mandatory, not advisory |
| **Fibonacci 50% ceiling**: corrections holding above 50% confirm higher-low structure (~60–70% of corrections in genuine uptrends; ~30–40% fall deeper = reversal candidate) | Murphy, TAOFM | Rejects 30–40% of pullbacks that are reversal-phase entries, not continuation |
| **MACD hist ≥ 0** gate: MACD histogram is positive 55–65% of time in trending markets; gate passes the higher-quality subset and rejects 35–45% of trend-phase candles where momentum is temporarily negative | Elder, Trading for a Living | Improves signal WR without destroying frequency in trending regime |
| **Volume ≤ 50% of prior impulse at pivot-2** ("test on low volume"): canonical Wyckoff continuation — absent sellers; volume rising on correction = distribution / reversal | Wyckoff, SMC practitioner corpus | Tightens volume filter from "declining" (intermediate) to quantified ≤ 50% threshold |
| **Pivot-detection bias ~30%** false-pivot drop with left/right bar confirmation vs rolling-min | LuxAlgo, TradingView pivot lib | Quantifies upgrade impact from naive pivot detection |
| **Trend-continuation WR premium over reversals**: momentum > mean-reversion across crypto asset classes; hidden div mechanism aligned to stronger side | PMC9920669 cross-reference + SSRN 5775962 (Efe Arda 2026) | Justifies WR target ceiling above sister prim (reversal): 55–62% vs 52–58% |
| **WR ladder analogical application**: bare reversal signal 33% → confluence 65% → double-confirmation 73% (equity n=235). Trend-continuation baseline higher; ~25% crypto discount applied. | Kraken + Concord p2c + LuxAlgo + QuantifiedStrategies | Realistic crypto hidden-div WR target: **55–62%** (vs sister reversal prim 52–58%) |
| **R:R upgrade to ≥1:2**: at 55% WR and 1:2 R:R, EV = 0.55×2 − 0.45×1 = 0.65 (positive, friction-tolerant). At 1:1.5, EV = 0.55×1.5 − 0.45×1 = 0.375 (positive but friction-kills at 47% Sharpe erosion). | EV analysis + BSIC friction model | Mandatory upgrade from intermediate's 1:1.5 gate |

### Key Numbers

| Metric | Value |
|---|---|
| PMC9920669 momentum side (RSI>50) | **+498pp vs B&H** (773.6% vs 275.2%) — mechanism alignment benchmark |
| PMC9920669 reversal side (RSI<30) | **−97.5pp vs B&H** (177.7% vs 275.2%) — sister prim's mechanism |
| Expected live WR (trend-continuation premium over reversal) | **55–62%** (vs sister prim 52–58%) |
| Post-OOS lower bound | **50–55%** (25–50% Sharpe degradation; vs sister 48–52%) |
| Signal frequency | **< 0.5% of candles** (rarer than regular div ~0.8%; uptrend precondition narrows universe) |
| Friction Sharpe erosion | **~47%** at typical crypto fees+slippage |
| OOS degradation ceiling | **> 30% Sharpe loss = reject** |
| Parameter plateau criterion | **PF variance < 25%** across 28-cell grid (7 lookback × 4 gap-min) |
| PBO threshold cells | **28** (exceeds 20 → CPCV + DSR correction mandatory) |
| Fibonacci filter pass rate in genuine uptrends | **60–70%** of pullbacks hold above 50% Fib |
| Volume gate (≤ 50% impulse): Wyckoff "test" pass rate | Estimated 40–60% of pullbacks qualify |
| RSI LL floor ≥ 30 | Required (< 30 = exhaustion territory, regime conflict) |
| R:R gate (upgraded from intermediate) | **≥ 1:2** after fee round-trip |
| Expected EV at 55% WR / 1:2 R:R | 0.55×2 − 0.45×1 = **+0.65 per unit risk** |
| Corrors RSI2 equity benchmark (analogical ceiling) | PF 2.08 (n=288) |

### Mechanism Cross-Reference — Why This Is the Stronger Divergence

| Dimension | Hidden div (this prim) | Regular div (sister prim) |
|---|---|---|
| Mechanism | Trapped counter-trend shorts (fading pullback in uptrend) | Trapped late sellers (shorting exhaustion low) |
| Regime | Confirmed uptrend (momentum side) | Late-bear / exhaustion (reversal side) |
| PMC9920669 alignment | **Momentum (773.6%, +498pp)** | Mean reversion (177.7%, −97.5pp) |
| Published negative evidence | **None** | PMC9920669 LEAST EFFECTIVE rating |
| Positive peer-reviewed anchor | None (practitioner consensus only) | None (published as failure) |
| Falsification burden | Higher WR required in trend regime | Must survive explicit negative evidence |

**Critical caveat**: absence of negative evidence ≠ positive evidence. The superiority claim rests on mechanistic alignment (momentum vs reversal), not on a direct backtest of hidden divergence in crypto. The head-to-head comparison IS the test.

### 12 Quantified Failure Modes

1. **Nascent reversal misclassified as uptrend** (#1) — hidden div without genuine trend becomes a bull trap; Fibonacci > 50% is the early warning; EMA ribbon degradation is the kill condition
2. **ADX < 20** — insufficient trend strength; signal fires in ranging regime where trend-continuation thesis is void; 57–76% false signal rate without ADX gate (Coinmonks 8,765-pattern study)
3. **ADX > 45** — parabolic phase; no clean pullback structure; corrections are violent and V-shaped, not orderly HL formations
4. **RSI LL < 30** at pivot-2 — regime conflict with regular div (exhaustion territory); hidden div mechanism requires sellers who are WRONG, not sellers who are RIGHT about exhaustion
5. **Fibonacci pullback > 50%** — trend structure compromised; deep corrections (61.8%+) are reversal candidates, not continuation; entering on these produces directional exposure in ambiguous regime
6. **MACD hist < 0 at pivot-2** — bearish momentum dominant at the very pivot the signal fires; contradicts "sellers are thin" thesis; 35–45% of trend-phase candles fail this filter
7. **Volume rising at pivot-2** (> pivot-1 impulse volume) — distribution/reversal signal; sellers strengthening not weakening; contradicts Wyckoff "test on low volume" premise
8. **Same-candle entry** (no next-candle confirmation) — drops 5–10pp WR (applied from sister prim's LuxAlgo + Concord p2c data)
9. **Mutual exclusivity violated** — if regular div fires simultaneously, regime partition is broken (cannot be simultaneously "in confirmed uptrend" and "in exhaustion/late-bear"); neither signal is trustworthy; discard both
10. **Sub-1h timeframe** — friction Sharpe erosion ~47% at 4h; sign-flip at HFT scale (+84k gross → −99k net); sub-1h ban mandatory
11. **Parameter curve-fit without plateau verification** — 28 parameter cells; if PF only profitable at one specific (lookback, gap-min) combination, it is overfit; tail-risk: +28.4% IS → −79.3% live (QuantVPS)
12. **OOS Sharpe loss > 30%** — signal is not robust; reject rather than re-refine; mark as anti-prim candidate if plateau also fails

### Anti-Prim Escape Hatch

Two conditions trigger anti-prim marking (not re-refinement):

**(A) Plateau test failure**: If own-data backtest shows no profitable region across `hidden_divergence_lookback ∈ [8,12,15,20,25,30,40]` × `rsi_hidden_min_gap ∈ [2,3,5,7]` (28 cells) with PF variance > 25%, the mechanism does not produce stable edge on crypto. Mark as anti-prim; do NOT re-refine.

**(B) Head-to-head failure vs sister prim**: If own-data walk-forward shows hidden div WR ≤ regular div WR in trend regimes (where regular div fires on its excluded pairs), the FXOpen/ACY/Babypips "more reliable in trends" practitioner consensus is REFUTED for crypto. Mark as anti-prim with label: "practitioner hierarchy inverted for crypto." This is a high-value negative result — retain as anti-prim with full documentation.

### 12 Implementation Gaps (YujiDivergenceStrategy.py)

1. Mirror pivot detection: `argrelextrema(close, np.greater, order=5)` for price HL; `argrelextrema(rsi, np.less, order=5)` for RSI LL on same candle window; match nearest indices
2. New IntParameters: `hidden_divergence_lookback` (default 15, range 8–40, step for plateau test: [8,12,15,20,25,30,40]); `rsi_hidden_min_gap` (default 3, range 2–7, step: [2,3,5,7])
3. RSI floor: reject if `rsi_at_pivot_2 < 30`
4. EMA ribbon gate: ≥ 3 of {EMA10>EMA21, EMA21>EMA50, EMA50>EMA200} true
5. Fibonacci depth: `(prior_impulse_high - pivot_2_low) / (prior_impulse_high - prior_impulse_low) ≤ 0.50`
6. MACD gate: `macd_hist >= 0` at pivot-2 candle index
7. Volume Wyckoff gate: `volume_at_pivot_2 <= 0.50 * volume_at_prior_impulse_peak` (tighter than intermediate's "declining")
8. Next-candle: `hidden_div_signal.shift(1) & (close > close.shift(1))`
9. Hard mutual exclusivity: `& ~buy_rsi_div & ~buy_macd_div & ~buy_double_div` — also log conflict events for regime partition audit
10. 4h primary TF; 1h secondary; NEVER sub-1h — add explicit TF guard
11. **(BLOCKING) Parameter plateau test**: run 28-cell grid; require PF variance < 25%; compute Deflated Sharpe Ratio (DSR) per Bailey-Borwein; report DSR not raw Sharpe; reject if no plateau
12. **(BLOCKING) CPCV + Deflated Sharpe correction**: 28 tested cells mandate walk-forward CPCV cross-validation and DSR correction; OOS Sharpe must be ≥ 70% of IS Sharpe

### Regime Partition — Complete at Sophisticated (5 prims)

| Regime | Prim | Level | ADX |
|---|---|---|---|
| Ranging (ADX < 20, BBW pctl < 40) | rsi-oversold-mean-reversion | sophisticated | < 20 |
| Ranging-to-mild-trend | liquidity-sweep-reversal | sophisticated | < 30 |
| Trending structural (first pullback) | ema-pullback-dynamic-support | sophisticated | 25–35 rising |
| Exhaustion / late-bear | bullish-rsi-divergence (regular) | sophisticated | any, NOT persistent uptrend |
| **Trending momentum (uptrend pullback HL)** | **hidden-bullish-rsi-divergence** | **sophisticated** | **20–45 rising** |

The two divergence prims partition by regime AND by RSI territory (RSI LL ≥ 30 = hidden; RSI LL < 30 = regular/exhaustion). Mutual exclusivity is a structural guarantee, not a runtime check.

### Bank State After Cycle 19

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | 0 |
| Intermediate | 0 active (hidden-div SUPERSEDED) | 3 |
| Sophisticated | **5** (rsi-oversold, ema-pullback, liq-sweep, bullish-rsi-div, **hidden-div NEW**) | 1 (fractional-kelly) |

All freqtrade prims at sophisticated. 5-axis regime partition complete. Hidden-div is the only sophisticated prim with NO published negative evidence at its parent root — it also has NO direct positive crypto backtest anchor. This parity makes the head-to-head vs sister prim the highest-value single test in the bank.

### Critical Limitation
No own-data backtest. The Wyckoff ≤ 50% volume threshold and Fibonacci 50% ceiling are theoretically motivated and analogically supported, but untested as a unit for hidden divergence in crypto specifically. Deployment blocked pending: (a) own-data walk-forward across bull→bear→accumulation on BTC/ETH 4h, (b) 28-cell parameter plateau test with DSR correction, (c) friction-adjusted OOS Sharpe within 30% of IS, (d) **head-to-head vs bullish-rsi-divergence sophisticated** on same data window — any of the four outcomes (both survive / hidden survives / both fail / regular survives) is load-bearing. If (b) fails → mark anti-prim. If (d) shows hidden WR ≤ regular WR in trend regime → mark anti-prim with "practitioner consensus refuted for crypto."

### Sources (13)
- [PMC9920669 — Effectiveness of RSI Signals in Timing Cryptocurrency Market](https://pmc.ncbi.nlm.nih.gov/articles/PMC9920669/) (momentum RSI>50: +498pp vs B&H; cross-reference for mechanism alignment; regular div NOT hidden div tested)
- [SSRN 5775962 — Bollinger Bands under Varying Market Regimes: BTC/USDT (Efe Arda, 2026)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5775962) (trend-following > mean-reversion across crypto market phases)
- [FXOpen — Hidden vs Regular Divergence](https://fxopen.com/blog/en/what-is-the-difference-between-regular-and-hidden-divergence/)
- [ACY — RSI Hidden Divergence](https://acy.com/en/market-news/education/how-to-spot-rsi-hidden-divergence-j-o-121814/)
- [Babypips — Hidden Divergence](https://www.babypips.com/learn/forex/hidden-divergence)
- [Alchemy Markets — Hidden Divergence](https://alchemymarkets.com/education/hidden-divergence/)
- [LuxAlgo — RSI at S/R: 60–65% WR with confluence confirmation](https://www.luxalgo.com/blog/5-rsi-entry-strategies-using-support-and-resistance/)
- [Concord p2c — Structure-break confirmation adds 15–25pp WR](https://www.concordp2c.com/is-bullish-divergence-reliable-backtested-insights-and-common-mistakes-to-avoid/)
- [Bailey/Borwein/Lopez de Prado — Probability of Backtest Overfitting (SSRN 2326253)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2326253)
- [Bailey — Deflated Sharpe Ratio](https://www.davidhbailey.com/dhbpapers/deflated-sharpe.pdf)
- [BSIC — Transaction Cost Modelling: Sharpe erosion ~47%](https://bsic.it/backtesting-series-episode-5-transaction-cost-modelling/)
- [FMZQuant — HFT oscillator variant sign-flip](https://medium.com/@FMZQuant/dynamic-atr-contrarian-trading-strategy-market-liquidity-sweep-and-reversal-breakthrough-e2a09908e598)
- [QuantPedia — In-Sample vs Out-of-Sample (McLean-Pontiff)](https://quantpedia.com/in-sample-vs-out-of-sample-analysis-of-trading-strategies/) + [arxiv 2602.10785 walk-forward](https://arxiv.org/html/2602.10785) + [QuantVPS overfit case +28.4% IS → −79.3% live](https://www.quantvps.com/blog/swing-failure-pattern-strategy)
