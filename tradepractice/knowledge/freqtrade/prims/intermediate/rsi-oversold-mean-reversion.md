---
name: rsi-oversold-mean-reversion
level: intermediate
project: freqtrade
parent_prim: naive/rsi-oversold-mean-reversion
created: 2026-04-10
last_validated: never
reaction_validated: assumed
---

## Prim: rsi-oversold-mean-reversion
**Level:** intermediate
**Project:** freqtrade
**Parent:** naive/rsi-oversold-mean-reversion

### Rule
If RSI(14) < 30 on the entry timeframe AND market regime is ranging (ADX < 20, BB width compressed) AND price is above 1h EMA200 AND at least one confirming oscillator agrees (MFI < 30, Stoch < 25, or close < BB lower) AND volume > 0.8x SMA(20) AND 4h RSI > 25 → long bias toward BB middle band. **Do NOT use RSI < 30 as a standalone signal. Do NOT use in trending crypto markets.**

### Mechanism
RSI < 30 marks short-term selling exhaustion. Trapped late sellers provide covering fuel for the bounce. However, **this mechanism only activates in ranging regimes** where selling is corrective (mean-reverting) rather than structural (trending). In crypto specifically, RSI behaves as a momentum indicator, not a mean-reversion indicator — an RSI < 30 reading in a downtrend signals trend continuation, not reversal. The edge exists only when the regime context confirms the sell-off is an overshoot within a range, not a leg of a trend.

### Critical Research Finding
**RSI mean reversion does not work on crypto in trending markets.** This is the single most important refinement from naive to intermediate.

- Peer-reviewed study (Gunarto & Gkillas, 2023, PMC9920669): Tested 10 cryptocurrencies over 1,462 days (2018-2022). Traditional oversold (< 30) strategy returned **177.7%** vs **275.22%** buy-and-hold. The oversold signal **underperformed passive holding by 97.5 percentage points.**
- Same study: RSI used as a **momentum/trend indicator** (buy when RSI > 50) returned **773.65%** vs 275.22% buy-and-hold — **4.4x better** than the mean-reversion approach.
- 8/10 cryptos showed above-average returns 1 day after RSI < 30, but only **3/10 after 60 days** — the bounce is real but short-lived and unreliable for swing trades.
- QuantifiedStrategies.com backtests confirm: "RSI as a contrarian indicator is basically worthless on Bitcoin" and "momentum results are much better."

### Conditions
- **Works when:**
  - **Regime: RANGING** — ADX < 20, BB width below 40th percentile, no EMA alignment (alignment <= 2)
  - Price above 1h EMA200 (structural uptrend intact, sell-off is corrective)
  - 4h RSI > 25 (higher timeframe not also oversold — if it is, this is structural, not corrective)
  - Confirming oscillator: MFI < 30 OR Stoch < 25 OR close < BB lower (multi-indicator confluence)
  - Volume > 0.8x SMA(20) (real selling, not drift)
  - High-liquidity pairs (BTC/USDT, ETH/USDT) where mean-reversion algos are active
  - **Timeframe: 4h preferred** (Sharpe 5.13 in RSI crossover backtest), 1h acceptable, 15m marginal
- **Fails when:**
  - **Regime: TRENDING** — ADX > 25, EMA alignment >= 3 (this is the #1 failure mode)
  - 1h AND 4h RSI both < 30 simultaneously (structural breakdown, not corrective dip)
  - Multiple consecutive RSI < 30 readings without recovery above 35 (trending lower)
  - News-driven capitulation (no mean to revert to — the mean is shifting)
  - Low-liquidity altcoins (manipulated volume distorts RSI, per academic study)
  - **Timeframe: 5m** (34.7% win rate, -93.9% return in BTC backtest — noise kills it)
  - Price below 1h EMA200 (structural downtrend — sellers are correct, not trapped)
- **Best pairs:** BTC/USDT, ETH/USDT (institutional mean-reversion algos provide the mechanical bounce)
- **Best timeframe:** 4h (Sharpe 5.13, 60% win rate, PF 2.09 in BTC crossover backtest) > 1h > 15m
- **Best regime:** Ranging (ADX < 20, BB width compressed)

### Evidence
- **Source:** academic paper + community backtests
- **Certainty:** hypothesis (multi-source convergence, but no backtest of THIS specific implementation)
- **Scope:** BTC + 9 altcoins (academic); BTC only (community backtests)
- **Falsifiability:** tested-partial (mean reversion underperformance confirmed; regime-filtered version untested)

**Quantitative data:**

| Source | Asset | Timeframe | Strategy | Result |
|---|---|---|---|---|
| PMC9920669 | 10 cryptos | Daily | RSI < 30 mean reversion | 177.7% vs 275.2% B&H (underperforms) |
| PMC9920669 | 10 cryptos | Daily | RSI > 50 momentum | 773.6% vs 275.2% B&H (outperforms 4.4x) |
| PMC9920669 | 10 cryptos | Daily | RSI < 30, 1-day return | 8/10 above average |
| PMC9920669 | 10 cryptos | Daily | RSI < 30, 60-day return | 3/10 above average |
| AtomicScript | BTC | 4h | RSI crossover 30/70 | 60% WR, Sharpe 5.13, PF 2.09 |
| AtomicScript | BTC | 1h | RSI crossover 30/70 | 50% WR, Sharpe 0.95, PF 1.21 |
| AtomicScript | BTC | 15m | RSI crossover 30/70 | 73% WR, Sharpe 2.61, PF 1.64 |
| AtomicScript | BTC | 5m | RSI crossover 30/70 | 34.7% WR, Sharpe -0.45, PF 0.94 |
| Briplotnik | Crypto basket | Daily | BTC-neutral mean reversion | Sharpe 2.3 (post-2021 choppy regime) |

**Key insight from Briplotnik (2026):** BTC-neutral residual mean reversion (Sharpe 2.3) dominated post-2021 in choppy markets, while momentum dominated pre-2021 trending markets. This directly supports the regime-gating thesis: mean reversion works in ranging, momentum works in trending.

- **Citations:**
  - Gunarto, T. & Gkillas, K. (2023). "Effectiveness of the Relative Strength Index Signals in Timing the Cryptocurrency Market." PMC9920669.
  - AtomicScript. "Episode 3: RSI Crossover Strategy." Medium.
  - Briplotnik. "Systematic Crypto Trading Strategies: Momentum, Mean Reversion & Volatility Filtering." Medium.

### Limitations
1. **Regime-gated version is untested.** All evidence supports the thesis indirectly — no backtest of RSI < 30 + ADX < 20 + BB width filter on crypto exists yet.
2. **RSI < 30 frequency in crypto is low** — only ~10.8% of days for BTC (158/1,462 days). After regime + oscillator filtering, signal count may be too low for statistical significance.
3. **Bounce is short-lived** — 8/10 positive at 1 day, only 3/10 at 60 days. Exit timing is critical. BB middle is the right target, not a trend continuation.
4. **Crypto overshoots oscillator bounds** more than equities. RSI < 20 may be a better threshold than RSI < 30 for crypto (untested hypothesis).
5. **CVD/order flow not incorporated** — the naive prim uses RSI alone. Adding CVD confirmation (from liquidity-sweep-reversal prim) could improve signal quality.
6. **No pair-specific analysis** — academic study shows heterogeneous performance across 10 cryptos. Some coins mean-revert better than others.

### Implementation
- **File:** `user_data/strategies/YujiRegimeStrategy.py`
- **Entry block:** `range_entry` (lines 185–194) — already regime-gated with `regime_ranging == 1`
- **Parameters:**
  - RSI threshold: 35 (YujiRegimeStrategy) / 30 (YujiMultiSignalStrategy, hyperopt range 20–40)
  - ADX range threshold: 20 (hyperopt range 15–22)
  - BB width: < 40th percentile rolling 50
- **Confirming oscillators already implemented:** Stoch < 25, MFI < 30, close < BB lower
- **HTF guard:** 4h RSI > 25 (freefall filter)
- **Missing implementation:**
  - RSI < 20 threshold variant (test via hyperopt)
  - Next-candle reaction confirmation (RSI recovers > 35 within 2–3 candles)
  - Explicit 1h EMA200 guard in YujiMultiSignalStrategy buy_1 (currently uses `ema_200_1h` with 3% buffer — sufficient but not identical)
  - 4h timeframe entry (best Sharpe in backtest data)

### Recommended Implementation Changes
1. **YujiMultiSignalStrategy buy_1:** Add `regime_ranging` guard or ADX < 20 filter. Currently fires in ANY regime with HTF guard only — this is the primary failure mode.
2. **Hyperopt:** Test `buy_rsi_threshold` range 15–25 (lower than current 20–40) given crypto overshoots.
3. **Add 4h entry variant** in YujiRegimeStrategy to capture the higher Sharpe timeframe.
4. **Exit:** Target BB middle band, not trend continuation. Exit within 1–3 candles if no recovery.

### Conditions Log Entry
- **Works when:** Ranging regime (ADX < 20, BB width < 40th pctl); price > 1h EMA200; 4h RSI > 25; confirming oscillator (MFI < 30 / Stoch < 25 / close < BB lower); volume > 0.8x SMA; high-liquidity pairs; 4h or 1h timeframe
- **Fails when:** Trending regime (ADX > 25, EMA alignment >= 3); 1h+4h RSI both < 30; structural breakdown; news capitulation; low-liquidity altcoins; 5m timeframe; price < 1h EMA200
- **Key finding:** RSI mean reversion underperforms buy-and-hold on crypto by 97.5pp without regime filter. With regime filter (ranging only), hypothesis is viable but unbacktested.
- **Last validated:** never (regime-gated version needs backtest)
