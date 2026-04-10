# Conditions Log — When Each Prim Activates

> Maps trading primitives to the market conditions where they work (and fail).
> Updated by the analyst after each backtest or research cycle.

## Format

```
## [Prim Name] (level)
- **Works when:** [market conditions]
- **Fails when:** [market conditions]
- **Best pair(s):** [if pair-specific]
- **Best timeframe:** [1h, 15m, 4h]
- **Evidence:** [backtest date, period, result]
- **Last validated:** [date]
```

---

## Freqtrade Conditions

## rsi-oversold-mean-reversion (naive → intermediate)
- **Status:** SUPERSEDED by intermediate prim. See intermediate entry below.

## rsi-oversold-mean-reversion (intermediate → sophisticated)
- **Status:** SUPERSEDED by sophisticated prim. See sophisticated entry below.

## rsi-oversold-mean-reversion (intermediate) — 2026-04-10 [historical]
- **Works when:** RANGING regime only (ADX < 20, BB width < 40th pctl); price > 1h EMA200; 4h RSI > 25; confirming oscillator (MFI < 30 / Stoch < 25 / close < BB lower); volume > 0.8x SMA(20); high-liquidity pairs (BTC, ETH)
- **Fails when:** TRENDING regime (ADX > 25, EMA alignment >= 3) — **#1 failure mode, confirmed by academic study**; 1h+4h RSI both < 30 (structural breakdown); news capitulation; low-liquidity altcoins; 5m timeframe (34.7% WR); price < 1h EMA200
- **Best pair(s):** BTC/USDT, ETH/USDT (institutional mean-reversion algos active)
- **Best timeframe:** 4h (Sharpe 5.13, 60% WR, PF 2.09) > 1h (Sharpe 0.95) > 15m (Sharpe 2.61 but few trades)
- **Critical finding:** RSI mean reversion underperforms buy-and-hold on crypto by 97.5pp without regime filter (PMC9920669: 177.7% vs 275.2%). RSI as momentum indicator returns 773.6% on same data.
- **Evidence:** academic paper (PMC9920669, 10 cryptos, 1,462 days) + community backtests (AtomicScript, Briplotnik)
- **Implementation note:** YujiRegimeStrategy already regime-gates correctly. YujiMultiSignalStrategy buy_1 LACKS regime gate — primary fix needed.
- **Last validated:** never (regime-gated version needs backtest)

## rsi-oversold-mean-reversion (sophisticated) — 2026-04-10
- **Works when:** RANGING regime (ADX < 20 AND BBW percentile < 40, stable — two-source regime confirmation); price > 1h EMA200; RSI(14) in plateau zone 25–35 (NOT a single magic threshold); confirming oscillator (MFI < 30 / Stoch < 25 / close < BB lower); volume > 0.8x SMA(20); BTC/USDT or ETH/USDT only; 4h primary timeframe (1h secondary); fee+slippage-adjusted edge > 2x friction; parameter plateau verified (PF stable across RSI 25–35 with < 20% variance); OOS >= 70% of IS
- **Fails when:** TRENDING (ADX > 20 or EMA alignment ≥ 3) — **#1 failure mode: −97.5pp vs B&H on 10 cryptos over 4 years** (PMC9920669); BB squeeze → expansion (trend-birth not reversion); parameter curve-fit / "magic numbers" like RSI < 23.7 (overfit signal); sub-1h timeframe (Sharpe destroyed by friction, 5m BTC WR 34.7%); altcoins (no institutional mean-reversion flow); friction > 50% of raw edge (Sharpe erosion ~47% on typical crypto fees); HFT variant (+84k gross → −99k net); OOS < 70% of IS; news capitulation; 1h+4h RSI both < 30 (structural breakdown); IS/OOS regime flip (2020 → 2021 collapse pattern); multiple-testing inflation (> 20 parameter variants tested without Deflated Sharpe correction)
- **Best pair(s):** BTC/USDT, ETH/USDT (institutional mean-reversion algos active; altcoins excluded)
- **Best timeframe:** 4h (Sharpe 5.13, WR 60%, PF 2.09 — AtomicScript) > 1h (Sharpe 0.95) > **avoid < 1h entirely** (5m BTC WR 34.7%; friction dominates)
- **Key numbers:** Regime-gated 4h BTC: Sharpe 5.13, WR 60%, PF 2.09; ungated crypto mean reversion: −97.5pp vs B&H (177.7% vs 275.2% on PMC9920669 n=10, 1,462 days); inverse momentum same data: +498pp (773.6% vs 275.2%); Briplotnik BTC-neutral post-2021: Sharpe 2.3; transaction cost Sharpe erosion: ~47% (1.5 → 0.8); realistic slippage: 0.02–0.05%/trade; Connors RSI2 equity benchmark: PF 2.08 (n=288); OOS degradation ceiling: > 30% Sharpe loss = reject; parameter plateau criterion: PF variance < 20% across RSI 25–35
- **Critical findings:** (1) **Second academic anchor** (SSRN 5775962, Efe Arda 2026 BTC/USDT) confirms mean reversion failed in bear phase, only "limited profitability" in accumulation — bolsters PMC9920669. (2) **Parameter plateau is a sophistication criterion**, not a parameter choice: if rule only profits at RSI = 23.7, it is overfit. Must test [25, 27, 30, 32, 35] and verify plateau. (3) **Friction is a deployment killer** — BSIC/PANews/FMZQuant converge: frequent mean-reversion strategies lose ~47% of Sharpe to costs; HFT variants flip sign entirely. (4) **Real QQQ example**: RSI mean reversion +28.4% IS → −79.3% live without OOS validation — quantifies tail risk. (5) **Bitcoin verdict**: 3 independent sources (PMC9920669, Bens Crypto Talk, QuantifiedStrategies) all conclude RSI-as-mean-reversion DOES NOT WORK on Bitcoin without regime gate; RSI-as-momentum works. (6) **Multiple-testing inflation** (PBO/DSR, Bailey-Borwein-Lopez de Prado): probability of overfitting rises with every tested variant; need CPCV + Deflated Sharpe Ratio when > 20 parameter combinations tested. (7) **BB squeeze expansion** is a distinct regime — BBW < 20th pctl followed by widening is trend birth, not reversion; must filter out post-squeeze candles.
- **Evidence:** 8 independent sources including 2 academic (PMC9920669, SSRN 5775962 Efe Arda), 3 community backtests (AtomicScript, Briplotnik, QuantifiedStrategies RSI2/Bitcoin RSI), 3 methodology (PBO/DSR Bailey-Borwein, BSIC transaction cost modelling, ScienceDirect CPCV comparison)
- **Implementation gaps:** YujiRegimeStrategy range_entry needs: (1) BBW percentile < 40 filter alongside ADX < 20, (2) RSI threshold as IntParameter 25–35 with plateau verification, (3) 4h primary / 1h secondary / drop 15m+5m, (4) fee+slippage gate (refuse if edge < 2x friction), (5) exit at BB middle not RSI > 50, (6) max 2 entries per 20 candles per pair. YujiMultiSignalStrategy.buy_1 (lines 191–196) **CRITICAL FIX**: (7) add regime gate — currently fires in any regime, exact failure mode quantified by PMC9920669, (8) BTC/ETH pair whitelist, (9) remove 15m timeframe. Deployment blocked pending: plateau test on RSI 25–35, walk-forward across bull→bear→accumulation, friction-adjusted OOS Sharpe within 30% of IS.
- **Last validated:** never (needs own-data walk-forward with plateau verification — #1 blocker shared with sister sophisticated prims)

## ema-pullback-dynamic-support (naive → intermediate)
- **Status:** SUPERSEDED by intermediate prim. See intermediate entry below.

## ema-pullback-dynamic-support (intermediate → sophisticated)
- **Status:** SUPERSEDED by sophisticated prim. See sophisticated entry below.

## ema-pullback-dynamic-support (sophisticated) — 2026-04-10
- **Works when:** TRENDING regime (ADX 25–35, rising); EMA alignment >= 3; 4h EMA50 > EMA200; RSI 40–65; **first pullback to 21 EMA only** (<=1 touch in 20 candles); volume > 0.8x SMA(20); bullish candle + MACD hist rising; BTC/ETH; 1h timeframe
- **Fails when:** RANGING (ADX < 20) — **#1 failure mode: 57–76% false signal rate without regime gate**; ADX > 35 (exhaustion); ADX declining even if > 25; 3+ EMA21 tests (level exhausted); **ATR trailing stop (PF drops from ~2.0 to 0.603, WR 28%)**; crypto bull market (underperforms B&H: 26% vs 42.5%); low-liquidity alts (PF 1.61 vs 2.68 cross-asset); 5m TF; parabolic moves
- **Best pair(s):** BTC/USDT, ETH/USDT
- **Best timeframe:** 1h (PF ~2.0) > 30m (PF 2.01) > daily (PF 1.61–2.68 high variance) > avoid 5m
- **Key numbers:** PF ~2.0 (BTC 1H), WR ~48%, DD ~6% (BTC 30m). Cross-asset PF variance: 1.61–2.68. Expected OOS degradation: 25–50% (WFE ~72%).
- **Critical findings:** (1) ADX filter adds only ~1pp success rate (69.9% → 71.0%) — value is in AVOIDING ranging losses, not boosting trending wins. (2) ATR trailing stop destroys the edge entirely. (3) IEEE PF 3.5 was basic EMA cross, NOT pullback — not reproducible for this prim. (4) "60% ranging" claim (PRUVIQ) has no data backing — downgraded from intermediate.
- **Evidence:** 8 independent sources: IEEE 2024, arxiv 2511.00665, PakunFX, BTC 30m backtest, 8/21 EMA 10yr (AAPL+NVDA), Betashorts failure analysis, Coinmonks 8,765-pattern study, Raschke Holy Grail, MA cross false signal study (1960–2025)
- **Implementation:** YujiTrendRiderStrategy needs: (1) ADX rising, (2) ADX < 35 ceiling, (3) volume filter, (4) first-pullback-only filter, (5) fixed stop below swing low (NOT ATR trail), (6) target at prior swing high
- **Last validated:** never (needs own-data backtest with full filter set)

## liquidity-sweep-reversal (naive → intermediate)
- **Status:** SUPERSEDED by sophisticated prim. See sophisticated entry below.

## liquidity-sweep-reversal (intermediate → sophisticated)
- **Status:** SUPERSEDED by sophisticated prim. See sophisticated entry below.

## liquidity-sweep-reversal (sophisticated) — 2026-04-10
- **Works when:** RANGING-TO-MILD-TREND regime (ADX < 30); wick >= 0.3% below clear 5-bar swing low; bullish close back above within 1–2 candles; **next-candle confirmation (+5–10pp WR)**; volume > 1.2x SMA(20) on sweep candle; CVD divergence present as **filter only** (price LL + CVD HL); within 2% of VP POC/VAL; BTC/ETH on 1h–4h; fixed stop below wick low; R:R >= 1:2; no macro event in next 2h
- **Fails when:** Strong trend (ADX > 35) — **#1 failure mode: sweeps become genuine breakdowns**; **CVD in isolation** (2018–2024 backtests confirm underperformance vs filter use); consecutive sweeps at same level (support genuinely breaking); no VP anchor (drops ~20pp WR); same-candle entry (drops 5–10pp WR); ATR trailing stop (by analogy to sister prim); low-liquidity alts (thin books produce fake sweeps); 5m TF (noise); news capitulation; parameter curve-fit without walk-forward; SMC automation gap (~30% of visual setups missed by mechanical 5-bar pivot)
- **Best pair(s):** BTC/USDT, ETH/USDT (institutional flow, meaningful stop clusters; 73% of liquidations cluster within 2% of swing levels)
- **Best timeframe:** 1h–4h (highest SFP reliability) > 15m entry precision within HTF context > avoid 5m
- **Key numbers:** **WR 68% (n=2,847 BTC/ETH/alts 2022–2025), PF 1.92** with volume confirmation; realistic **live WR 55–62%** after OOS degradation (McLean-Pontiff: 26% lower OOS, 58% post-publication — expect Sharpe /2 to /3); ~40% base-rate failure floor (textbook setups); naked POC revisit ~80% within 10 sessions; VP POC reversion 75%+ WR in ranging; "perfect HTF SFPs" 85–95% selection-biased upper bound; live BTC SMC leaderboard strategy PF 1.51 (n=82)
- **Critical findings:** (1) SFP is the **first large-sample quantitative anchor** for this prim (n=2,847 vs prior n=22 at intermediate). (2) **CVD is a filter, not a trigger** — in-isolation use underperforms. (3) **73% of liquidation events occur within 2% of swing levels** — mechanistic justification for stop-cluster mechanism. (4) Walk-forward studies show regime-gated pattern strategies that outperformed in 2020 **collapsed in 2021** — plan for regime-change failure. (5) Parameter sensitivity is HIGH (FMZQuant); wick depth, swing lookback, volume multiplier all curve-fit easily. (6) SMC/ICT is inherently hard to fully automate — mechanical approximations capture ~70% of visual setups.
- **Evidence:** 9 independent sources — QuantVPS SFP backtest (n=2,847), QuantVPS liquidation clustering, Morpher SFP, LuxAlgo SFP, Bookmap CVD 2018–2024, Buildix VP naked POC 80%, HorizonAI SMC live benchmark, QuantPedia + arxiv 2602.10785 walk-forward/OOS degradation, FMZQuant ATR-contrarian parameter sensitivity
- **Implementation gaps:** YujiSmartMoneyStrategy needs: (1) ADX < 30 regime gate, (2) next-candle confirmation via `sweep_bullish.shift(1)`, (3) CVD as divergence filter not trigger, (4) volume threshold 0.8x → 1.2x SMA, (5) wick depth >= 0.3% enforcement, (6) fixed stop below wick low (NOT ATR trail), (7) R:R >= 1:2 target logic, (8) pair whitelist BTC/ETH only, (9) drop secondary entry (no-VP), (10) walk-forward optimization before deployment
- **Last validated:** never (needs own-data walk-forward backtest with full 10-filter set)

## bullish-rsi-divergence (naive) — 2026-04-10
- **Works when:** RANGING or LATE-BEAR (exhaustion phase, not trend-initiation); price at defended level (BB lower, VAL, prior structural support); volume declining on successive lows (seller cohort thinning); 4h RSI > 20 (not freefall capitulation); higher-timeframe trend neutral or bottoming; regular divergence on daily/4h more reliable than 1h
- **Fails when:** Parabolic or strong trending move — **#1 failure mode: divergence can persist indefinitely**, each new print a fresh losing trade; **rising BTC/ETH bull market** (PMC9920669 peer-reviewed: signal works **counterproductively** on majors in uptrends); news-driven capitulation; no next-candle confirmation; single-divergence entry without structure break; rolling-min swing detection misclassifies non-structural lows; lookback window conflates signal bandwidth with pivot separation (paper specified 3–60 candle distance between pivots, not a single window)
- **Best pair(s):** untested — hypothetically ranging or late-bear assets; **actively counterproductive on rising majors** per PMC9920669
- **Best timeframe:** untested — implemented 1h (YujiDivergenceStrategy); practitioner sources report daily more reliable but fewer signals; 1h–4h plausible trade-off
- **Frequency:** **~0.8% of candles** (PMC9920669 average across 10 cryptos, 1,462 days) — extremely rare signal, limited trade frequency, hard to validate statistically
- **Key numbers:** Naive first-signal entry: **~2 of 3 losing trades** (multiple practitioner sources); with MACD double-divergence confluence: 77% WR reported (Gate.io 2026, selection bias suspected); with structure-break + candlestick confirmation: 50–65% WR typical range, 86% outlier on n=16; Bitcoin 60-day forward ROI after bullish divergence **~10x** bearish divergence ROI (asymmetric directional bias even when WR is marginal)
- **Critical findings:** (1) **PMC9920669 rates RSI divergence the LEAST EFFECTIVE** of all RSI experiments tested in peer-reviewed crypto study — "hardest to implement, least effective." (2) Authors **explicitly advise against** RSI divergence on rising BTC/ETH (the exact pairs Yuji's bot trades). (3) **Divergence is a negative-evidence result**, not an absence of evidence — the naive rule has been formally tested and found wanting. (4) Bullish-bearish asymmetry (~10x forward ROI) suggests the signal has directional bias even if WR is low — may work better as a filter/tiebreaker than a primary trigger. (5) Hidden divergence (trend-continuation variant) is reportedly more reliable in trending markets but is NOT implemented in YujiDivergenceStrategy. (6) Confluence (MACD + structure + candlestick + volume) appears to be the only path to viability; pure RSI divergence does not survive honest testing.
- **Evidence:** 7 independent sources — PMC9920669 (peer-reviewed, 10 cryptos, 1,462 days, negative result), QuantifiedStrategies divergence backtest, Kraken Learn naive failure rate, SaintQuant Bitcoin asymmetry, Concord p2c backtest (confirmation matters), FXOpen hidden-vs-regular distinction, arxiv 2410.06935 ML technical-indicator integration
- **Implementation gaps:** YujiDivergenceStrategy.py needs: (1) **regime gate** — currently fires in any regime, exact failure mode quantified by PMC9920669; (2) **next-candle confirmation** (e.g. `bullish_rsi_div.shift(1) & close > close.shift(1)`); (3) **pivot-based swing detection** instead of rolling-min (ta.MIN with lookahead or ZigZag-style); (4) **pivot-distance enforcement** (3–60 candles between price lows per PMC9920669 methodology); (5) **divergence throttle** — block new signals until prior divergence is invalidated (prevents persistent-divergence loss cascade); (6) **structure-break filter** — require close above prior minor swing high before entry; (7) **hidden-divergence variant** for trending markets as companion prim; (8) **parameter plateau test** on divergence_lookback ∈ [10, 15, 20, 25, 30] and rsi_divergence_min ∈ [3, 5, 7, 10]; (9) **whitelist filter** — exclude persistent-uptrend BTC/ETH per academic warning.
- **Last validated:** never (naive extraction + published negative result; next cycle should refine to intermediate with regime gate + confirmation, or mark as anti-prim if confluence version doesn't survive plateau test)

---

## Polymarket Conditions

## binary-arb-completeness (naive) — 2026-04-10
- **Works when:** YES+NO price sum < $0.995; both sides have depth; market liquidity > $10k; low arb bot competition
- **Fails when:** Gap < execution fees; only one leg fills (partial execution); market voided; gap closes before second leg
- **Best pair(s):** all binary Polymarket markets
- **Best timeframe:** real-time orderbook (opportunities are fleeting)
- **Evidence:** code extraction only — no live trades
- **Last validated:** never

## spread-capture-market-making (naive → intermediate)
- **Status:** SUPERSEDED by intermediate prim. See intermediate entry below.

## spread-capture-market-making (intermediate) — 2026-04-10
- **Works when:** Spread > fee-adjusted breakeven (category-dependent); **category filter** (geopolitics 0% > sports 3% > politics/finance 4% > weather/culture/economics 5%; AVOID crypto 7.2% except very wide spreads); price $0.30–$0.70 (uncertainty zone, peak rebate income); liquidity >= $10k; **time-to-resolution > 24h**; inventory |q| < 5% bankroll/price; balanced flow; no scheduled information event in next 2h; spread $0.03–$0.10 optimal
- **Fails when:** Spread < fee-adjusted breakeven — **#1 failure mode** (current code's MIN_SPREAD=0.03 fails on crypto 7.2% markets); information event imminent (prices gap 40–50pp on news in seconds, erasing months of spread income); price approaching $0/$1 (spread auto-compresses as delta_p = p(1-p)*delta_x); spread > $0.15 (toxic flow); one-sided flow (unbounded inventory build); competing MMs with <10ms latency vs Polymarket 50ms WebSocket (current 30s refresh cycle is 60-300x too slow); T-t < 24h (event risk dominates); inventory breach (binary settlement = total loss on wrong-side); market voided
- **Best pair(s):** Geopolitics markets (0% taker fee = pure spread capture, no fee drag on counterparties) > sports > politics
- **Best timeframe:** 100–500ms refresh cycle, continuous cancel-and-replace
- **Best regime:** Stable/uncertain markets with balanced flow; NOT trending-to-resolution
- **Key numbers:** Industry benchmark ~0.2% of volume as profit; $150–$300/day per liquid market at professional scale; >$20M total MM profits on Polymarket in 2024; top 1% of traders capture 84% of gains; <30% of all traders profitable; execution edge 2.52c/contract automated vs manual; live 5-min BTC binary MM: 4W/11L -49.5% ROI (efficient pricing defeats spread capture on short-dated markets)
- **Critical findings:** (1) Maker pays 0% fee; 100% of taker fees redistributed to makers (20-25% rebate by category) — secondary revenue stream beyond spread capture. (2) Avellaneda-Stoikov model must be adapted to **logit space** for prediction markets (arxiv 2510.15205): r_x = x_mid - q*gamma*sigma_b^2*(T-t); delta_x = gamma*sigma_b^2*(T-t)/2 + (1/k)*log(1+gamma/k); inventory cap |q| < 1/max(p*(1-p), eps). (3) Single adverse selection event can erase weeks/months of spread income — binary settlement amplifies one-sided inventory risk.
- **Evidence:** 5 independent sources — Polymarket fees docs, arxiv 2510.15205 (Oct 2025, Black-Scholes for Prediction Markets), newyorkcityservers.com 2026 guide, fglancszpigel live trading analysis (gwrx2005), Polymarket/poly-market-maker official keeper
- **Implementation gaps:** Current `src/strategies/spread.py` needs: (1) fee-aware category filter, (2) inventory tracking + Avellaneda-Stoikov skew in logit space, (3) adverse selection guard (cancel-on-move), (4) time-to-resolution filter (no quotes <24h to settlement), (5) refresh cycle 30s → 500ms, (6) dynamic order sizing scaling with spread/depth, (7) maker rebate accounting
- **Last validated:** never (needs paper-trading backtest with full filter set)

## ensemble-forecast-edge (naive) — 2026-04-10
- **Works when:** GFS ensemble well-calibrated for city/season; market illiquid (casual bettors); 1-3 day horizon (peak ensemble skill); bracket boundaries within ensemble spread; liquidity >= $500; uncertain market (YES $0.20-$0.80)
- **Fails when:** Market already efficient (sophisticated bettors/bots); forecast horizon > 5 days; extreme weather (model underdispersion); tail brackets (30-member sample too small); station-vs-gridpoint bias; GFS systematic bias for geography
- **Best pair(s):** Weather temperature bracket markets on Polymarket
- **Best timeframe:** 1-3 days before resolution
- **Evidence:** Code extraction only — no live trades or backtests
- **Critical unknowns:** Single model (no ECMWF/NAM blend); no calibration layer; 30 members gives coarse probability resolution (3.3% per member); no ensemble spread confidence check; station-model mismatch unquantified; execution costs vs edge unquantified
- **Last validated:** never

## fractional-kelly-sizing (naive → intermediate)
- **Status:** SUPERSEDED by intermediate prim. See intermediate entry below.

## fractional-kelly-sizing (naive) — 2026-04-10 [historical]
- **Works when:** Edge estimate is accurate; many independent bets; bankroll large enough for Kelly to produce meaningful sizes; binary resolution
- **Fails when:** Edge miscalibrated (Kelly amplifies estimation error); correlated bets (same city/date); small sample; bankroll < $2k (sizes round to dust); MAX_BET=$100 cap binds on strong edges
- **Best pair(s):** All binary Polymarket markets with quantifiable edge
- **Best timeframe:** Per-trade sizing decision (not time-dependent)
- **Evidence:** Kelly criterion theory is well-established; this specific implementation (KELLY_FRACTION=0.15, triple cap) is untested
- **Critical unknowns:** Optimal fraction for this edge distribution (0.15 is arbitrary); no correlation adjustment for concurrent bets; no drawdown-based bankroll update; bankroll proxy (max_position*10) vs actual capital
- **Last validated:** never

## fractional-kelly-sizing (intermediate) — 2026-04-10
- **Works when:** Edge source has measurable calibration quality (Brier score or IS/OOS accuracy); dynamic bankroll tracked after each resolution; N concurrent bets ≤ 5; binary markets with defined resolution horizon; edge > 3x execution friction
- **Fails when:** Uncalibrated edge used with 0.50 tier (ruin risk from amplified estimation error — 10% edge overestimate → ~2x bet size); N > 5 correlated bets without portfolio-level Kelly; bankroll proxy instead of actual capital; $100 hard MAX_BET cap overrides Kelly at bankroll > $13k; single catastrophic resolution on wrong-side inventory; long-horizon lockup (>7d) without discount factor applied to fraction
- **Best pair(s):** All binary Polymarket markets where edge source has calibration evidence
- **Best timeframe:** Per-trade sizing; bankroll updated after each settlement
- **Key numbers:** Full Kelly → 33% probability of halving before doubling (MacLean-Hakansson); 0.25 Kelly = industry standard for uncalibrated edges (PolySwarm 50-agent system); 0.50 Kelly = appropriate for validated models with Brier ≤ 0.30; 10% edge overestimate → ~2x recommended bet size; tiered EV: small edge (2-5%) → 1-2% bankroll, medium (5-15%) → 2-4%, large (>15%) → 4-6%; 20% drawdown stop = industry standard circuit-breaker; current KELLY_FRACTION=0.15 is 40% below conservative academic floor
- **Critical findings:** (1) arxiv 2412.14144 (Meister 2024): prediction market prices bounded [0,1] — KL-divergence between model and market beliefs drives growth; miscalibration near p=0/1 disproportionately destroys portfolio growth. (2) PolySwarm (arxiv 2604.03888) uses quarter-Kelly for 50-agent ensemble uncertainty — validates 0.25 as appropriate for uncalibrated multi-model edges. (3) KELLY_FRACTION=0.15 in current code is sub-floor — 40% below even the conservative 0.25 academic recommendation; correct upward. (4) Concurrent-bet scalar 1/sqrt(N) is a practical heuristic; full solution requires covariance-adjusted portfolio Kelly.
- **Evidence:** 4 sources — arxiv 2412.14144 (Meister Dec 2024), arxiv 2604.03888 (PolySwarm), MacLean et al. (Good and Bad Properties of Kelly), mbotopoly.com prediction market risk guide
- **Implementation gaps:** (1) Calibration score logging system needed (predictions vs outcomes → Brier score), (2) true bankroll from balance API, (3) portfolio-level covariance Kelly for correlated weather bets, (4) resolution-horizon discount factor
- **Last validated:** never (needs live trade history with outcome tracking)

---


## ema-pullback-dynamic-support (sophisticated) — 2026-04-10
- **Works when:** TRENDING regime (ADX 25–35, rising); first pullback to 21 EMA; 1h TF; BTC/ETH
- **Fails when:** RANGING (57–76% false signals); ATR trailing stop (PF 0.603); bull market B&H comparison; low-liquidity alts
- **Key numbers:** PF ~2.0, WR ~48%, 25–50% OOS degradation expected
- **Last validated:** never

Sources:
- [IEEE — Algorithmic Crypto Trading using EMA (2024)](https://ieeexplore.ieee.org/iel8/11034707/11034773/11035368.pdf)
- [arxiv — Technical Analysis Meets Machine Learning: Bitcoin Evidence](https://arxiv.org/html/2511.00665v1)
- [PakunFX — EMA Pullback Speed Strategy (TradingView)](https://www.tradingview.com/script/cxhQ5d5x-EMA-Pullback-Speed-Strategy/)
- [Coinmonks — Crypto Backtest: 15+ Trading Strategies](https://medium.com/coinmonks/crypto-backtest-the-most-extensive-analysis-15-trading-strategies-58f06deca2bd)
- [Betashorts — EMA Pullback Backtest Failure Analysis (2026)](https://medium.com/@betashorts1998/i-fixed-the-biggest-flaw-in-my-last-backtest-the-strategy-still-lost-money-64022a65e370)
- [QuantifiedStrategies — 8/21 EMA 10yr Backtest](https://www.quantifiedstrategies.com/exponential-moving-average-trading-strategy/)
- [Thrive.fi — Crypto Market Regime Detection](https://thrive.fi/blog/trading/crypto-market-regime-detection)
- [Raschke Holy Grail — TradingSetupsReview](https://www.tradingsetupsreview.com/the-holy-grail-trading-setup/)
