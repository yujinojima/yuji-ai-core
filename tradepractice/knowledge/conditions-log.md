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

## rsi-oversold-mean-reversion (intermediate) — 2026-04-10
- **Works when:** RANGING regime only (ADX < 20, BB width < 40th pctl); price > 1h EMA200; 4h RSI > 25; confirming oscillator (MFI < 30 / Stoch < 25 / close < BB lower); volume > 0.8x SMA(20); high-liquidity pairs (BTC, ETH)
- **Fails when:** TRENDING regime (ADX > 25, EMA alignment >= 3) — **#1 failure mode, confirmed by academic study**; 1h+4h RSI both < 30 (structural breakdown); news capitulation; low-liquidity altcoins; 5m timeframe (34.7% WR); price < 1h EMA200
- **Best pair(s):** BTC/USDT, ETH/USDT (institutional mean-reversion algos active)
- **Best timeframe:** 4h (Sharpe 5.13, 60% WR, PF 2.09) > 1h (Sharpe 0.95) > 15m (Sharpe 2.61 but few trades)
- **Critical finding:** RSI mean reversion underperforms buy-and-hold on crypto by 97.5pp without regime filter (PMC9920669: 177.7% vs 275.2%). RSI as momentum indicator returns 773.6% on same data.
- **Evidence:** academic paper (PMC9920669, 10 cryptos, 1,462 days) + community backtests (AtomicScript, Briplotnik)
- **Implementation note:** YujiRegimeStrategy already regime-gates correctly. YujiMultiSignalStrategy buy_1 LACKS regime gate — primary fix needed.
- **Last validated:** never (regime-gated version needs backtest)

## ema-pullback-dynamic-support (naive → intermediate)
- **Status:** SUPERSEDED by intermediate prim. See intermediate entry below.

## ema-pullback-dynamic-support (intermediate) — 2026-04-10
- **Works when:** TRENDING regime only (ADX 25–35, rising); EMA alignment >= 3 (8 > 21 > 50 > 100); 4h EMA50 > EMA200; RSI 40–65; first or second pullback to 21 EMA (<=2 touches in 20 candles); volume > 0.8x SMA(20); bullish candle + MACD hist rising
- **Fails when:** RANGING regime (ADX < 20, flat EMA ribbon) — **#1 failure mode; crypto spends ~60% of time here**; ADX > 35 (trend exhaustion/reversal risk); 3+ EMA21 tests (level degraded); 4h bearish (EMA50 < EMA200); RSI < 35 or > 70; low volume pullback; parabolic move skipping EMA
- **Best pair(s):** BTC/USDT, ETH/USDT (institutional trend-following flow)
- **Best timeframe:** 1h (PF ~2.0, best signal-to-noise) > 30m (PF 2.01) > avoid 5m
- **Critical finding:** EMA pullback is the TRENDING-ONLY complement to RSI mean reversion (RANGING-ONLY). Raschke Holy Grail confirms first pullback after ADX > 30 is highest-probability setup. IEEE paper shows EMA crypto: PF 3.5, WR 60%.
- **Evidence:** IEEE paper (2024) + Raschke Holy Grail + community backtests (PakunFX PF 1.965, BTC 30m PF 2.01)
- **Implementation gaps:** YujiTrendRiderStrategy needs: (1) ADX rising check, (2) ADX < 35 ceiling, (3) volume filter on buy_pullback
- **Last validated:** never (needs backtest with ADX direction + ceiling filters)

## liquidity-sweep-reversal (naive → intermediate)
- **Status:** SUPERSEDED by intermediate prim. See intermediate entry below.

## liquidity-sweep-reversal (intermediate) — 2026-04-10
- **Works when:** RANGING-TO-MILD-TREND regime (ADX < 30); near VP level (POC/VAL — POC reversion 75%+ WR in ranging); wick >= 0.3% below swing low (filters noise wicks); CVD delta positive+rising, ideally divergent (price LL, CVD HL — 65-75% reversal rate); volume > 0.8x SMA on sweep candle (> 1.2x preferred); bullish close above swing low; next-candle confirmation (raises WR from ~50% to 55-60%); high-liquidity pair (BTC, ETH)
- **Fails when:** Strong trend (ADX > 35) — **#1 failure mode: sweeps become genuine breakdowns, not traps**; consecutive sweeps at same level (support breaking); no CVD confirmation (dead-cat bounce); low volume sweep (noise wick); thin order book alts (fake sweeps wander); 5m timeframe (noise); no VP level nearby (no structural significance); news-driven capitulation
- **Best pair(s):** BTC/USDT, ETH/USDT (institutional flow, deep books, meaningful stop clusters)
- **Best timeframe:** 1h-4h (most reliable) > 15m (entry precision within HTF context) > avoid 5m
- **Critical finding:** Liquidity sweep is the RANGING/TRANSITIONAL regime complement — different mechanism from RSI mean reversion (oscillator exhaustion) and EMA pullback (trend continuation). Edge = trapped agents at structural levels. Weekly BTC SFP shows 91% success (n=22), but 4H SFP only 55-60% WR with confirmation. VP proximity is the strongest filter (75%+ WR at POC).
- **Evidence:** EUR/USD liquidity pool study (ResearchGate 2024, 84 days); BTC weekly SFP (Benzinga 2026, n=22); CVD divergence studies (S&P E-mini, 65-75%); VP POC reversion (FuturesHive, 75%+ WR); SMC backtest consensus (60-70% WR with confirmation)
- **Implementation gaps:** YujiSmartMoneyStrategy needs: (1) ADX < 30 regime filter, (2) next-candle confirmation via sweep_bullish.shift(1), (3) CVD divergence check, (4) stronger volume threshold on sweep candle, (5) evaluate secondary entry quality (drops VP requirement)
- **Last validated:** never (needs backtest with regime filter + next-candle confirmation)

---

## Polymarket Conditions

## binary-arb-completeness (naive) — 2026-04-10
- **Works when:** YES+NO price sum < $0.995; both sides have depth; market liquidity > $10k; low arb bot competition
- **Fails when:** Gap < execution fees; only one leg fills (partial execution); market voided; gap closes before second leg
- **Best pair(s):** all binary Polymarket markets
- **Best timeframe:** real-time orderbook (opportunities are fleeting)
- **Evidence:** code extraction only — no live trades
- **Last validated:** never

## spread-capture-market-making (naive) — 2026-04-10
- **Works when:** Spread $0.03–$0.15; liquidity >= $5k; stable/uncertain market (YES ~$0.30–$0.70); balanced order flow; no imminent resolution; no major news catalyst
- **Fails when:** Spread < $0.03 (fees consume profit); spread > $0.15 (illiquid/toxic); information event imminent (adverse selection); one-sided flow; market trending toward resolution; competing MM bots with queue priority
- **Best pair(s):** Active binary markets with moderate uncertainty
- **Best timeframe:** Continuous limit orders
- **Evidence:** Code extraction only — no live trades or backtests
- **Critical unknowns:** No inventory management (unbounded directional exposure from partial fills); no adverse selection defence; no order cancellation/refresh; fee impact unquantified; ORDER_SIZE=10 is fixed regardless of conditions
- **Last validated:** never

## spread-capture-market-making (naive) — 2026-04-10
- Works when: Spread $0.03–$0.15, liquidity >= $5k, balanced flow, stable market
- Fails when: Narrow spread (<fees), toxic flow, one-sided volume, imminent resolution
- Last validated: never

---

