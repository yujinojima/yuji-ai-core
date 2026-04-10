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

## ema-pullback-dynamic-support (naive)
- **Works when:** EMA alignment >= 3 (EMA8 > EMA21 > EMA50 > EMA100); ADX > 20; 4h EMA50 > EMA200 (higher-timeframe bullish); RSI 40–65 (mid-range, not overbought or broken); price has not tested 21 EMA more than 2x in last 20 candles
- **Fails when:** EMA alignment <= 2 (trend weakening or absent); ADX < 18 (choppy); 4h bearish EMA cross; RSI < 35 (breakdown not pullback); 3+ 21 EMA tests in 20 candles (level losing support significance)
- **Best pair(s):** untested
- **Best timeframe:** untested — implemented on 1h in YujiTrendRiderStrategy; likely noisy on 15m
- **Evidence:** code extraction only — no backtest
- **Last validated:** never

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
