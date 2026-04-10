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

## liquidity-sweep-reversal (naive)
- **Works when:** Price near VP level (POC or VAL); clear prior swing low with stop clusters; CVD delta positive and rising; volume > 0.8x 20-SMA; ranging to mildly trending regime
- **Fails when:** Strong macro downtrend (4h bearish); no CVD confirmation after sweep; low volume sweep (noise); multiple consecutive sweeps at same level (genuine breakdown); no nearby VP level
- **Best pair(s):** untested — hypothetically better on liquid pairs (BTC/USDT, ETH/USDT) with institutional flow
- **Best timeframe:** 15m (YujiSmartMoneyStrategy); likely too noisy on 5m
- **Evidence:** code extraction only — no backtest
- **Last validated:** never

---

## Polymarket Conditions

## binary-arb-completeness (naive) — 2026-04-10
- **Works when:** YES+NO price sum < $0.995; both sides have depth; market liquidity > $10k; low arb bot competition
- **Fails when:** Gap < execution fees; only one leg fills (partial execution); market voided; gap closes before second leg
- **Best pair(s):** all binary Polymarket markets
- **Best timeframe:** real-time orderbook (opportunities are fleeting)
- **Evidence:** code extraction only — no live trades
- **Last validated:** never
