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

## rsi-oversold-mean-reversion (naive)
- **Works when:** Ranging market (ADX < 20, BB width compressed); price above 1h EMA200; 1h RSI < 65; 4h RSI < 70; sell-off is corrective not structural
- **Fails when:** Downtrend (EMA alignment bearish, ADX > 25); 1h or 4h RSI also < 30; news-driven capitulation; price breaking major multi-day support
- **Best pair(s):** untested
- **Best timeframe:** untested — implemented on 15m (YujiMultiSignalStrategy) and 1h (YujiRegimeStrategy)
- **Evidence:** code extraction only — no backtest
- **Last validated:** never

## ema-pullback-dynamic-support (naive)
- **Works when:** EMA alignment >= 3 (EMA8 > EMA21 > EMA50 > EMA100); ADX > 20; 4h EMA50 > EMA200 (higher-timeframe bullish); RSI 40–65 (mid-range, not overbought or broken); price has not tested 21 EMA more than 2x in last 20 candles
- **Fails when:** EMA alignment <= 2 (trend weakening or absent); ADX < 18 (choppy); 4h bearish EMA cross; RSI < 35 (breakdown not pullback); 3+ 21 EMA tests in 20 candles (level losing support significance)
- **Best pair(s):** untested
- **Best timeframe:** untested — implemented on 1h in YujiTrendRiderStrategy; likely noisy on 15m
- **Evidence:** code extraction only — no backtest
- **Last validated:** never

---

## Polymarket Conditions

<!-- Auto-populated by tradepractice analyst -->

## ema-pullback-dynamic-support (naive) — 2026-04-10
- **Works when:** trending market, EMA ribbon fully aligned, ADX > 20, 4h bullish, RSI 40–65
- **Fails when:** EMA alignment degrading, choppy (ADX < 18), breakdown (RSI < 35), level over-tested
- **Last validated:** never
