---
name: bullish-rsi-divergence
level: sophisticated
project: freqtrade
parent_prim: intermediate/bullish-rsi-divergence
created: 2026-04-11
last_validated: never
reaction_validated: assumed
companion: sophisticated/hidden-bullish-rsi-divergence (pending)
---

## Prim: bullish-rsi-divergence
**Level:** sophisticated (refined from intermediate)
**Project:** freqtrade
**Parent:** intermediate/bullish-rsi-divergence

### Rule

True 5-bar pivot bullish divergence (pivot lows separated **10–60 candles** per PMC9920669) **AND** RSI HL ≥ 5pt **AND** MACD-hist HL on same pivot pair (REQUIRED double divergence — single-oscillator signal rejected) **AND** regime exclusion (NOT persistent uptrend: `~(ema_200_slope > 0 & adx > 35)`) **AND** volume declining across pivots (pivot-2 volume < 0.8× pivot-1 volume) **AND** next-candle structure break (`close > pivot_2_close & close > rolling(5).max().shift(1)`) **AND** price within 1% of defended support (BB lower / VAL / 1h EMA200 from below) **AND** divergence throttle active (no re-fire until `close < pivot_2_low` invalidation) **AND** 4h primary timeframe (1h secondary, **never sub-1h**) **AND** **fee+slippage-adjusted edge ≥ 2× friction** **AND** parameter plateau verified (PF variance < 25% across `divergence_lookback ∈ [10,15,20,25,30]` and `rsi_divergence_min ∈ [3,5,7,10]`) **AND** BTC/ETH whitelist excludes pairs in persistent uptrend → long to prior swing high, fixed stop below pivot-2 low, **fee-adjusted R:R ≥ 1:2**.

**Counter-result anchor:** PMC9920669 rated naive variant LEAST EFFECTIVE of all RSI experiments tested on crypto. Sophisticated rule is constructed specifically to invert this finding via 12-filter unit; the falsification path is exact and the prim should be marked **anti-prim** if own-data plateau test fails.

### What Elevated This from Intermediate

11 convergent sources (up from 9), with the **first quantified friction analysis, OOS degradation ceiling, and parameter-sensitivity data specific to divergence** that the intermediate lacked. The elevation does NOT come from new positive WR data — it comes from quantifying every failure mode the intermediate flagged and bounding the realistic live performance against published negative evidence.

| New Finding | Source | Impact |
|---|---|---|
| **PMC9920669 explicit ranking**: divergence "**hardest to implement, least effective**" of all RSI variants tested across 10 cryptos × 1,462 days | PMC9920669 (re-anchored) | Sophisticated must justify *why* it survives the only peer-reviewed crypto test |
| **Transaction cost destroys frequent oscillator strategies**: Sharpe erosion ~47% (1.5 → 0.8) on typical crypto fees+slippage | BSIC, FMZQuant | Friction model applies to all rule-based prims; divergence at ~0.8% candle frequency is friction-resilient at WR ≥ 60% but lethal at ≤ 50% |
| **OOS / IS degradation 26–58%** across published strategies (McLean-Pontiff factor zoo) | QuantPedia, arxiv 2602.10785 | Bounds expected live Sharpe at 50–70% of in-sample for any backtest result |
| **PBO + Deflated Sharpe correction needed** when > 20 parameter combinations tested | Bailey-Borwein-Lopez de Prado SSRN 2326253 | 5 lookback × 4 RSI gap = 20 cells already at PBO threshold; must use CPCV |
| **Real-world overfit example**: RSI mean reversion +28.4% IS → −79.3% live (QQQ) | QuantVPS / CPCV meta | Anchors tail-risk magnitude for over-tuned oscillator rules |
| **Connors RSI2 PF 2.08 (n=288, equity)** is the comparable baseline benchmark for any short-RSI mean-reversion-class rule | QuantifiedStrategies | Sets WR/PF expectation ceiling — divergence variants typically subordinate |
| **HFT variant of similar oscillator rules: +84k gross → −99k net** (sign flip from costs) | FMZQuant / PANews | Confirms sub-1h timeframe ban for any rule with RSI/divergence at its core |
| **Pivot-detection bias**: rolling-min misclassifies non-structural lows; left/right confirmation drops false-pivot rate by ~30% (TradingView pivot library consensus) | LuxAlgo, TradingView pivot lib | Quantifies pivot-detection upgrade impact |
| **Bullish-bearish forward-ROI asymmetry ~10×** (BTC, SaintQuant) confirms directional bias even at marginal WR | SaintQuant (re-anchored) | Mechanism: even at WR ~50%, asymmetric payoff creates positive expectancy IF stops are tight and targets are far |
| **Naive bare-signal WR ~33%** (Kraken practitioner) → confluence WR 60–65% (Concord p2c, LuxAlgo at 1:2 R:R) → **double-confirmation 73% WR n=235 equity** (QuantifiedStrategies MACD+RSI) | 3-source convergent ladder | WR ladder is monotonic with filter count — validates the 12-filter approach in principle, with ~25% crypto discount |
| **Regular divergence is "difficult to quantify"** (QuantifiedStrategies explicit verdict) | QuantifiedStrategies divergence-strategy article | Honest disclosure — sophisticated tier carries this caveat permanently |

### Key Numbers

| Metric | Value | Source |
|---|---|---|
| Naive bare-signal WR (no filters) | **~33%** (2 of 3 losing) | Kraken practitioner data |
| Confluence WR at support + 1:2 R:R | **60–65%** | LuxAlgo, Concord p2c, Sniper Trades |
| MACD+RSI double-confirmation | **73% WR, 0.88% avg gain, n=235** | QuantifiedStrategies (equity) |
| Crypto discount factor | **~25%** (equity → crypto degradation per literature) | Sister-prim OOS meta |
| **Realistic crypto sophisticated WR target** | **52–58%** | Derived: 73% × 0.75 × 0.95 OOS |
| Realistic post-OOS live WR (lower bound) | **48–52%** | After 25–50% Sharpe degradation |
| Signal frequency | **~0.8% of candles** | PMC9920669 (n=10, 1,462 days) |
| Pivot separation window | **10–60 candles** | PMC9920669 methodology (3–60 academic, 10 minimum for noise) |
| Friction Sharpe erosion (typical crypto fees+slippage) | **~47%** | BSIC modelling |
| OOS degradation ceiling | **> 30% Sharpe loss = reject** | QuantVPS, arxiv 2602.10785 |
| Parameter plateau criterion | **PF variance < 25% across 5×4 grid** | Sister sophisticated meta |
| Bullish-bearish forward ROI asymmetry | **~10×** (60-day BTC) | SaintQuant |
| Required R:R after fees | **≥ 1:2** | Required for breakeven at 33% naive WR; profitable at 50% confluence WR |

### Critical Failure Modes (12, Quantified)

1. **Persistent uptrend** (`EMA200 slope > 0 & ADX > 35`) — **#1 failure mode from PMC9920669**; divergence persists indefinitely as trend repeatedly invalidates seller exhaustion, each new print a fresh loss
2. **Single-oscillator signal** (RSI only OR MACD only) — drops 15–25pp WR vs required double; current code OR-gate is the exact failure mode
3. **Rolling-min pivot detection** — flags continuation lows as candidates; drops effective WR by ~10pp via false signal volume
4. **Same-candle entry without next-candle structure break** — drops 5–10pp WR
5. **Sub-1h timeframe** — friction Sharpe erosion ~47% baseline; HFT variant of similar rules sign-flips entirely (+84k gross → −99k net)
6. **No volume-thinning filter** — admits divergences where seller cohort is NOT actually thinning (false mechanism)
7. **No divergence throttle** — re-fires on persistent divergence, creating loss cascade in parabolic moves
8. **Curve-fit "magic number" parameters** (e.g. divergence_lookback = 17) — fails plateau test, indicates overfit to in-sample
9. **OOS cliff** — > 30% Sharpe degradation indicates the filter combination is unstable; reject and re-derive
10. **Multiple-testing inflation** — 5 lookback × 4 RSI gap × 2 timeframe = 40 cells; PBO probability rises sharply above 20 cells without Deflated Sharpe correction
11. **News-driven capitulation freefall** (4h RSI < 20) — divergence pattern still prints but mechanism (seller exhaustion) is absent; pattern is a coincidence
12. **Whitelisted BTC/ETH in persistent uptrend** — fires on the exact pairs PMC9920669 explicitly warns against; whitelist filter must be active

### Critical Limitation

**No own-data backtest. The 12-filter unit has never been tested as a unit against the PMC9920669 counter-result.** This sophisticated prim sits in the bank with the **highest falsification risk of any entry** — the only prim that, if own-data plateau test fails, must be marked as **anti-prim** rather than re-refined. The hidden-divergence companion (intermediate, cycle 16) covers the regime this one excludes; if both fail, the RSI divergence mechanism is invalidated for crypto as an asset class — a high-value negative result.

Sophisticated tier here means **"every failure mode is quantified and the falsification path is exact,"** NOT "this works." Deployment is blocked pending:
- (a) Own-data walk-forward across bull → bear → accumulation phases on BTC/ETH 4h
- (b) Parameter plateau test on `divergence_lookback ∈ [10,15,20,25,30]` and `rsi_divergence_min ∈ [3,5,7,10]` — PF variance must be < 25%
- (c) CPCV + Deflated Sharpe correction for the 20+ tested parameter combinations
- (d) Direct comparison against PMC9920669 baseline (same regime windows) to confirm refinement actually inverts the negative result
- (e) Friction-adjusted OOS Sharpe within 30% of IS Sharpe
- (f) Head-to-head backtest vs hidden-divergence intermediate to validate regime partition

### Regime Partition — 4 Sophisticated + 1 Intermediate

| Regime | Prim | Level | Notes |
|---|---|---|---|
| Ranging (ADX < 20, BBW pctl < 40) | rsi-oversold-mean-reversion | sophisticated | 3 academic anchors |
| Ranging-to-mild-trend (ADX < 30) | liquidity-sweep-reversal | sophisticated | n=2,847 SFP anchor |
| Trending structural (ADX 25–35 rising) | ema-pullback-dynamic-support | sophisticated | 8 sources |
| **Exhaustion / late-bear** | **bullish-rsi-divergence (regular)** | **sophisticated** | **Carries published negative evidence; falsification path exact** |
| Trending momentum (uptrend pullback) | hidden-bullish-rsi-divergence | intermediate | Designed to test sister consensus |

4 sophisticated prims now cover 4 distinct regimes. Hidden-divergence remains intermediate pending its own elevation cycle.

### Implementation Gaps in YujiDivergenceStrategy

`user_data/strategies/YujiDivergenceStrategy.py`:
1. Replace `rolling(lookback).min()` (lines 112–116) with true 5-bar pivot via `scipy.signal.argrelextrema(close, np.less, order=5)` matched to `argrelextrema(rsi, np.less, order=5)` on aligned indices
2. Enforce pivot separation 10–60 candles (clamp pivot pair distance)
3. Convert lines 181–184 OR-gate to AND-gate: `buy_double_div` ONLY (reject single-oscillator)
4. Add regime exclusion: `~(ema_200_slope > 0 & adx > 35)` — compute slope as `ema_200 > ema_200.shift(20)`
5. Next-candle structure break: `close > close.shift(1) & close > rolling(5).max().shift(1)`
6. Volume-thinning filter: `volume.iloc[pivot_2] < 0.8 * volume.iloc[pivot_1]`
7. Divergence throttle: state variable that blocks re-fire until `close < pivot_2_low` invalidation
8. Pair whitelist: exclude BTC/USDT, ETH/USDT when `close > ema_200 & ema_200.slope > 0 & adx > 30`
9. Promote to 4h primary TF (currently 1h); add 1h as secondary HTF confirm
10. Fee-aware R:R gate: target distance / stop distance ≥ 2 × (1 + 2 × fee_rate)
11. **Parameter plateau test (BLOCKING):** IntParameter `divergence_lookback ∈ [10,15,20,25,30]` × `rsi_divergence_min ∈ [3,5,7,10]`; PF variance < 25% across all 20 cells; reject prim entirely if no plateau
12. **CPCV + Deflated Sharpe correction** — 20+ tested cells require Bailey-Borwein-Lopez de Prado multiple-testing correction; report DSR not raw Sharpe

### Conditions Log Entry

- **Works when:** Late-bear or ranging-exhaustion regime (NOT persistent uptrend); true 5-bar pivot pair separated 10–60 candles; **REQUIRED double divergence** (RSI HL ≥ 5pt AND MACD-hist HL); volume declining across pivots; next-candle structure break; price at defended support; divergence throttle active; 4h primary TF; BTC/ETH only OUTSIDE persistent uptrend; fee-adjusted R:R ≥ 1:2; parameter plateau verified; OOS Sharpe ≥ 70% of IS
- **Fails when:** Persistent uptrend on majors — **#1 failure mode (PMC9920669)**; single-oscillator signal; rolling-min pivot detection; same-candle entry; sub-1h TF (friction sign-flip); no volume thinning; no divergence throttle; curve-fit parameters; > 30% OOS degradation; > 20 untested parameter cells without DSR; news capitulation; BTC/ETH in uptrend phase
- **Best pair(s):** BTC/USDT, ETH/USDT in late-bear or accumulation; whitelisted out during persistent uptrend
- **Best timeframe:** 4h primary; 1h secondary; never sub-1h
- **Key numbers:** Naive ~33% WR → confluence 60–65% → MACD+RSI double 73% WR (equity, n=235) → realistic crypto target **52–58% WR** post-25% discount → live lower bound **48–52% WR** post-OOS; signal freq ~0.8%; friction Sharpe erosion ~47%; bullish-bearish ROI asymmetry ~10×; required R:R ≥ 1:2; OOS ceiling > 30% Sharpe loss = reject; PF variance < 25% across 20-cell parameter grid
- **Critical findings:** (1) **Only sophisticated prim with published negative evidence at its parent root** — PMC9920669 rated naive LEAST EFFECTIVE of all RSI variants tested on 10 cryptos. Sophisticated tier means failure modes are quantified and falsification path is exact, NOT "this works." (2) WR ladder monotonic with filter count: 33% → 65% → 73% across 3 source classes; ~25% crypto discount = realistic 52–58% target. (3) Required R:R ≥ 1:2 means even at marginal WR, payoff asymmetry (~10× bullish-bearish ROI per SaintQuant) creates positive expectancy IF stops are tight to pivot-2 low. (4) Friction model from sister sophisticated prims (BSIC, FMZQuant) applies — 47% Sharpe erosion at typical crypto fees; sub-1h ban is mandatory for survival. (5) **Parameter plateau is the sophistication test, not a refinement option** — if no profitable region exists across 20 parameter cells, the prim must be marked **anti-prim** rather than re-refined. (6) Multiple-testing inflation crosses PBO threshold at 20 cells; CPCV + Deflated Sharpe correction is mandatory not optional. (7) Mutual exclusivity with hidden-divergence companion (intermediate) — head-to-head backtest is the primary research deliverable; both prims surviving validates regime partition; both failing invalidates the divergence mechanism for crypto.
- **Evidence:** 11 sources — PMC9920669 (peer-reviewed negative result), QuantifiedStrategies MACD+RSI n=235, QuantifiedStrategies divergence "difficult to quantify" verdict, LuxAlgo RSI at S/R, FXOpen + ACY + Babypips + Alchemy hidden-vs-regular distinction, Kraken naive failure rate, Concord p2c structure-break confirmation, SaintQuant BTC bullish-bearish asymmetry, Bailey-Borwein-Lopez de Prado PBO/DSR (SSRN 2326253), BSIC + PANews + FMZQuant friction modelling, QuantPedia + arxiv 2602.10785 OOS meta-analysis, Schwab divergence methodology, TradingView pivot library left/right consensus, QuantVPS RSI mean reversion overfit case (+28.4% IS → −79.3% live)
- **Implementation gaps:** 12 in YujiDivergenceStrategy.py (see prim file). **BLOCKING:** parameter plateau test (gap #11) and CPCV+DSR correction (gap #12) — without these, sophisticated tier is misnamed and prim must be returned to intermediate or marked anti-prim
- **Last validated:** never (highest falsification risk in the bank — sophisticated tier means failure modes are quantified, NOT that the prim works; deployment blocked pending 6-step verification)

### Next Cycle Recommendation

**BACKTEST-ANALYSIS** is now the shared blocker across **4 sophisticated + 1 intermediate** freqtrade prims. The single highest-leverage backtest is the **head-to-head walk-forward of bullish-rsi-divergence (regular sophisticated, this prim) vs hidden-bullish-rsi-divergence (intermediate, cycle 16)** on the same BTC/ETH 4h data window covering bull → bear → accumulation phases. This test is uniquely structured because:

- It directly adjudicates a published negative result (PMC9920669)
- It directly tests an unverified practitioner consensus (FXOpen/ACY/Babypips hidden-vs-regular reliability hierarchy)
- The four possible outcomes are all load-bearing (both survive / hidden survives / both fail / regular survives)
- Failure path is clean: anti-prim marking is unambiguous, no re-refinement loop

Secondary research path: extract **capitulation-exhaustion** prim from YujiExtinctionBurstStrategy as a NEW naive prim (climactic selling + vol spike + extreme oscillators). This is a distinct mechanism class (climax volume + multi-oscillator extreme, not divergence-based) and would complete the 5th regime axis: panic-reversal vs the existing exhaustion-reversal (this prim).

### Sources

- [PMC9920669 — Effectiveness of RSI Signals in Timing Cryptocurrency Market](https://pmc.ncbi.nlm.nih.gov/articles/PMC9920669/) (peer-reviewed negative result anchor)
- [QuantifiedStrategies — MACD and RSI Strategy (73% WR, n=235)](https://www.quantifiedstrategies.com/macd-and-rsi-strategy/)
- [QuantifiedStrategies — Divergence Trading Strategy "difficult to quantify" verdict](https://www.quantifiedstrategies.com/divergence-trading-strategy/)
- [QuantifiedStrategies — RSI2 Connors equity baseline (PF 2.08, n=288)](https://www.quantifiedstrategies.com/rsi-2-strategy/)
- [LuxAlgo — 5 RSI Entry Strategies Using Support and Resistance (60–65% WR at 1:2 R:R)](https://www.luxalgo.com/blog/5-rsi-entry-strategies-using-support-and-resistance/)
- [Concord p2c — Bullish Divergence Backtest with Structure-Break Confirmation](https://www.concordp2c.com/is-bullish-divergence-reliable-backtested-insights-and-common-mistakes-to-avoid/)
- [Kraken Learn — RSI Divergences (~33% bare-signal WR)](https://www.kraken.com/learn/rsi-divergences-what-they-how-they-work)
- [SaintQuant — Bullish Divergence RSI Crypto (10× forward-ROI asymmetry)](https://saintquant.com/blog/173-bullish-divergence-rsi-how-smart-crypto-traders-spot-early-reversals)
- [Bailey/Borwein/Lopez de Prado — Probability of Backtest Overfitting (SSRN 2326253)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2326253)
- [Bailey — Deflated Sharpe Ratio](https://www.davidhbailey.com/dhbpapers/deflated-sharpe.pdf)
- [BSIC — Transaction Cost Modelling: Sharpe Erosion ~47%](https://bsic.it/backtesting-series-episode-5-transaction-cost-modelling/)
- [PANews — Slippage: The Most Underrated Profit Killer](https://www.panewslab.com/en/articles/019cf1ab-bde1-752c-b41b-a5d46fda4080)
- [FMZQuant — Volatility-Optimized RSI Mean Reversion (HFT sign-flip)](https://medium.com/@FMZQuant/volatility-optimized-rsi-mean-reversion-trading-strategy-a83eda318fab)
- [QuantPedia — In-Sample vs Out-of-Sample Analysis (McLean-Pontiff 26%)](https://quantpedia.com/in-sample-vs-out-of-sample-analysis-of-trading-strategies/)
- [arxiv 2602.10785 — Walk-Forward Optimization in Crypto](https://arxiv.org/html/2602.10785)
- [ScienceDirect — Backtest Overfitting ML Era (CPCV)](https://www.sciencedirect.com/science/article/abs/pii/S0950705124011110)
- [QuantVPS — Real-world overfit example (+28.4% IS → −79.3% live)](https://www.quantvps.com/blog/swing-failure-pattern-strategy)
- [Schwab — Chart Divergences for Trading Decisions](https://www.schwab.com/learn/story/using-chart-divergences-to-make-trading-decisions)
- [FXOpen — Hidden vs Regular Divergence](https://fxopen.com/blog/en/what-is-the-difference-between-regular-and-hidden-divergence/)
- [ACY — RSI Hidden Divergence](https://acy.com/en/market-news/education/how-to-spot-rsi-hidden-divergence-j-o-121814/)
- [Babypips — Hidden Divergence](https://www.babypips.com/learn/forex/hidden-divergence)
- [Alchemy Markets — Hidden Divergence](https://alchemymarkets.com/education/hidden-divergence/)
