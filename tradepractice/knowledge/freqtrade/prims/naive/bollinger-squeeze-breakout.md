---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T21:00:50+10:00
cycle: 42
---

---

## Prim: bollinger-squeeze-breakout
**Level:** naive
**Project:** freqtrade
**Parent:** none
**Commit:** `c113989`

### Rule
BBW percentile < 20th (rolling 125 bars) for ≥ 5 consecutive bars + BB fully inside Keltner Channel (squeeze active) → on first squeeze release bar with momentum positive + next-candle hold above BBM → long to BBU / prior swing high. Stop below squeeze range low.

### Mechanism
Volatility is mean-reverting (ARCH/GARCH stylized fact): low-vol periods cluster and revert to higher vol. Inside the squeeze, market participants are in balanced-disagreement equilibrium — neither side has directional conviction. Positions accumulate on both sides. When BB expands through KC, one side is instantly wrong and forced to exit. Momentum histogram direction reveals which side absorbed the compression; positive = buyers netted the squeeze. Trapped: short-side agents who faded the coiling range, whose stop-covers fuel the directional expansion.

**Mechanistically distinct from all 7 existing prims:**

| Prim | Mechanism | Key trigger |
|---|---|---|
| rsi-oversold-mean-reversion | Oscillator exhaustion in ranging | RSI < 30 regime gate |
| liquidity-sweep-reversal | Stop cluster sweep + reclaim | Swing low wick + CVD |
| ema-pullback-dynamic-support | Trend re-entry at EMA | EMA21 touch in trend |
| bullish-rsi-divergence | Two-pivot oscillator gap | Price LL + RSI HL |
| capitulation-exhaustion-reversal | Panic seller cohort collapse | N reds + RSI < 20 + vol |
| funding-rate-crowding-reversal | Derivatives crowding | Perpetual funding rate spike |
| hidden-bullish-rsi-divergence (ANTI-PRIM) | Counter-trend trap | Price HL + RSI LL |
| **bollinger-squeeze-breakout** | **Vol compression → forced directional expansion** | **BBW < 20th pctl + BB inside KC + momentum at release** |

**Critical epistemic note:** The `rsi-oversold-mean-reversion` sophisticated prim explicitly lists failure mode #7 as "BB squeeze → expansion = trend birth, NOT reversion — filter out post-squeeze candles." This prim fires exactly in that excluded window. The two prims are mutually exclusive by regime design.

**8th regime axis:**

| Regime | Prim | Level |
|---|---|---|
| Ranging (ADX < 20, BBW stable) | rsi-oversold-mean-reversion | sophisticated |
| Ranging-to-mild-trend (ADX < 30) | liquidity-sweep-reversal | sophisticated |
| Trending structural (ADX 25–35 rising) | ema-pullback-dynamic-support | sophisticated |
| Exhaustion/late-bear | bullish-rsi-divergence | sophisticated |
| Panic capitulation | capitulation-exhaustion-reversal | sophisticated |
| Derivatives crowding | funding-rate-crowding-reversal | sophisticated |
| Trending momentum pullback | hidden-bullish-rsi-divergence | ANTI-PRIM |
| **Vol compression → expansion** | **bollinger-squeeze-breakout** | **naive (NEW)** |

### Evidence

| Source | Finding |
|---|---|
| **Bollinger (2001, "Bollinger on Bollinger Bands")** | BBW 6-month rolling low = "Bollinger Squeeze"; ~15–20% of bars qualify; breakout resolves within 15 bars; founding document |
| **Engle (1982, ARCH) + Bollerslev (1986, GARCH)** | Volatility clustering is a stylized fact: low-vol periods mean-revert to high-vol; theoretical anchor for squeeze-as-transition-boundary |
| **Carter (2012, "Mastering the Trade")** | TTM Squeeze: BB inside KC = squeeze (red dot); release = directional signal; momentum histogram bias; practitioner WR claim 65–70% (methodology undisclosed) |
| **LazyBear TradingView TTM Squeeze Pro** | Most-published community backtest vehicle; typical WR 55–65% over 3–6 month windows (selection-biased; no methodology disclosure) |
| **VolatilityBox (already in bank)** | BBW pctl < 20 = squeeze; squeeze → expansion = regime change, not reversion; validates percentile approach already in bank |
| **Connors & Alvarez (2009)** | Regime distinction operative: low-vol = mean-reversion edge; post-squeeze = momentum edge |

- **Source:** anecdote (Bollinger + Carter practitioner; no peer-reviewed crypto backtest)
- **Certainty:** hypothesis (mechanism grounded in ARCH/GARCH theory; directional signal unverified on crypto)
- **Data:** pending — WR and frequency on BTC/ETH 1h/4h entirely unknown

### Conditions
- **Works when:** Genuine accumulation period (extended compression ≥ 5 bars); directional momentum positive at release; HTF neutral-to-bullish (4h EMA200); BTC/ETH 4h; volume ≥ SMA(20) at release
- **Fails when:** Micro-squeeze chop (≥ 3 squeezes in 20 bars); HTF bearish context; same-candle entry; KC multiplier miscalibrated; altcoins with sparse volume
- **Best pairs:** untested — BTC/USDT, ETH/USDT hypothetically
- **Best timeframe:** untested — 4h probable; 1h produces excess micro-squeezes

### 10 Documented Limitations
1. No peer-reviewed crypto backtest — Carter/LazyBear WR claims are practitioner with selection bias risk
2. Squeeze duration threshold (≥ 5 bars) untuned — plateau test required on [3, 5, 8, 10, 15]
3. Same-candle entry without next-candle confirmation costs 5–10pp WR (sister prim meta)
4. Momentum histogram direction may be noise on crypto — "which side accumulated" inference untested
5. No regime gate — may fire in all ADX regimes, conflating with sister prims in trending regimes
6. KC ATR scalar sensitivity unknown — 1.5× vs 2.0× substantially changes squeeze definition and frequency
7. Repeated micro-squeeze failure mode unquantified: how many consecutive squeezes kill the edge?
8. Signal frequency on BTC/ETH 4h unknown — if < 10/year, statistical validation requires 5+ years
9. Exit logic underspecified: BBU is dynamic; prior swing high requires pivot detection
10. No CVD directional filter at release (would confirm which side absorbed the squeeze)

### Implementation
```python
bb = ta.bbands(close, length=20, std=2.0)
kc = ta.kc(high, low, close, length=20, scalar=1.5)
bbw = (bb['BBU_20_2.0'] - bb['BBL_20_2.0']) / bb['BBM_20_2.0']
bbw_pctl = bbw.rolling(125).rank(pct=True)
squeeze = (bb['BBU_20_2.0'] < kc['KCUe_20_1.5']) & (bb['BBL_20_2.0'] > kc['KCLe_20_1.5'])
squeeze_duration = squeeze.groupby((~squeeze).cumsum()).cumcount()
squeeze_qualified = squeeze & (bbw_pctl < 0.20) & (squeeze_duration >= 5)
squeeze_release = squeeze_qualified.shift(1) & ~squeeze_qualified
momentum = ta.mom(close, length=12)
entry_signal = squeeze_release & (momentum > 0)
# Next-candle confirmation: entry_signal.shift(1) & (close > bbm.shift(1))
```
- **Parameters (untuned):** `squeeze_duration_min=5`, `kc_scalar=1.5`, `bbw_window=125`, `mom_length=12`
- **Plateau grid:** `duration_min ∈ [3,5,8,10,15]` × `kc_scalar ∈ [1.5,2.0]` × `bbw_pctl ∈ [15,20,25]` = 30 cells; DSR correction mandatory

### Conditions Log Entry
- **Works when:** BBW < 20th pctl ≥ 5 bars, BB inside KC, momentum positive at release, next-candle accepted
- **Fails when:** Micro-squeeze chop; HTF bearish; same-candle entry; KC miscalibrated
- **Last validated:** 2026-04-11 (cycle 42 — frequency count only; WR unvalidated)

### Frequency Count (Cycle 42)

Data: Binance BTC/USDT + ETH/USDT 4h, 2022-01-01 → 2025-01-01 (3 years)
Parameters: duration_min=5, kc_scalar=1.5, bbw_pctl=0.20, mom_length=12, next-candle confirmation

| Pair | Confirmed entries | Annual rate |
|---|---|---|
| BTC/USDT 4h | 23 | 7.7/year |
| ETH/USDT 4h | 23 | 7.7/year |
| **Combined** | **46** | **15.3/year** |

**Verdict: anti-prim (A) NOT triggered** (15.3 ≥ 15/year combined threshold)
→ Proceed to 30-cell plateau test (next cycle)

Note: per-pair rate is 7.7/year. At 7.7/year over 3 years = 23 signals. Statistical validation per pair requires ~5 years minimum. Combined pool passes the frequency gate.

Strategy implemented: `YujiSqueezeBreakoutStrategy.py` (4h, BTC/AUD + ETH/AUD on Kraken)

### Bank State After Cycle 42

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | **1** (bollinger-squeeze-breakout) | 0 |
| Intermediate | 0 | 0 |
| Sophisticated | 6 | 9 |
| Anti-prim | 1 (hidden-div) | 0 |

### Next Cycle Recommendation
**(A) PLATEAU TEST** — run 30-cell hyperopt grid on YujiSqueezeBreakoutStrategy: duration_min ∈ [3,5,8,10,15] × kc_scalar ∈ [1.5,2.0] × bbw_pctl ∈ [15,20,25]; apply DSR correction; WR > 55% in ≥1 cell → intermediate promotion candidate.
**(B) IMPLEMENT** — fomc_pm_mapper.py classifier (single BLOCKING dependency for financial-market-lead-lag sophisticated prim). Bounded: last 20 resolved PM Fed questions from Gamma API → label clean vs exclude → validate classifier.
**(C) IMPLEMENT** — metaculus_pm_matcher.py (BLOCKING for superforecaster-consensus-lead sophisticated prim). Same pattern: 50 labeled Metaculus-PM pairs → calibrate embedding threshold.

Recommend **(A)** — frequency gate passed; plateau test is the next binary decision point for intermediate promotion.

### Sources
- Bollinger, J. (2001). *Bollinger on Bollinger Bands*. McGraw-Hill.
- Engle, R.F. (1982). Autoregressive Conditional Heteroscedasticity. *Econometrica*, 50(4), 987–1007.
- Bollerslev, T. (1986). Generalized Autoregressive Conditional Heteroscedasticity. *Journal of Econometrics*, 31(3), 307–327.
- Carter, J. (2012). *Mastering the Trade* (2nd ed.). McGraw-Hill.
- [LazyBear — TTM Squeeze Pro (TradingView)](https://www.tradingview.com/script/nqQ1DT5a-TTM-Squeeze-Pro/)
- [VolatilityBox — Bollinger Bands Squeeze and Percentile](https://volatilitybox.com/research/bollinger-bands-volatility/) (already in bank)
