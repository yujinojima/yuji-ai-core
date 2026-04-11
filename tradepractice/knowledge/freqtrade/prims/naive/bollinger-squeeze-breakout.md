---
name: bollinger-squeeze-breakout
level: naive
project: freqtrade
parent_prim: none
created: 2026-04-11
last_validated: never
reaction_validated: assumed
---

## Prim: bollinger-squeeze-breakout
**Level:** naive
**Project:** freqtrade
**Parent:** none

### Situation

**Setup:** BBW (Bollinger Band Width = (BBU−BBL)/BBM) compresses below its 20th rolling percentile for ≥ 5 consecutive bars AND BB is fully contained inside Keltner Channel (BBU < KCU AND BBL > KCL). Market participants are in a low-disagreement equilibrium: positions accumulate on both sides with no directional conviction. Volatility coils.

**Trigger:** Squeeze releases — BBU crosses above KCU (or BBL crosses below KCL) on the current bar, for the first time after ≥ 5 consecutive bars of active squeeze. Momentum oscillator (MACD histogram or 12-bar momentum) is positive at release bar.

**Reaction:**
- **Accepted:** Close holds above the squeeze midpoint (BBM); follow-through on next bar; volume ≥ 1.0× SMA(20). The release is directional — trapped wrong-side agents are exiting.
- **Rejected:** Price immediately reverses back inside the squeeze range within 2 bars. The breakout was a false start; no edge.
- **Unclear:** BBW barely exits KC; momentum oscillator near zero; volume below average. Wait for candle close.

**Agent Behaviour:**
- **Who is accumulating:** Informed buyers positioning in the squeeze range, absorbing sell pressure at a tight range.
- **Who is trapped:** Late shorts who sold the perceived "breakdown" within the squeeze, now caught by upside expansion.
- **Who is wrong:** Breakout fade traders (those who sold the squeeze release expecting it to fail); their stops provide upside fuel.

**Outcome:**
- If accepted: directional expansion toward BB upper / prior swing high; volatility mean-reversion from compressed regime.
- If rejected: no action; do not chase the failed breakout.
- If unclear: wait for next close.

### Rule
BBW percentile < 20th (rolling 125 bars) for ≥ 5 consecutive bars AND BB inside KC (squeeze active) → watch. On first squeeze release bar with momentum positive → long if reaction is accepted (next-candle hold above BBM). Target BBU / prior swing high. Stop below squeeze range low.

### Mechanism
Volatility is mean-reverting (ARCH/GARCH stylized fact): low-vol periods cluster and revert to higher vol. The BB squeeze identifies the transition boundary. Inside the squeeze, the market is in a balanced-disagreement equilibrium — neither side has conviction. When volatility expands, one side is instantly wrong. The momentum histogram reveals which side absorbed the squeeze: positive = buyers netted the compression; their trapped short counterparts provide the covering fuel.

**Mechanistically distinct from all 7 existing prims:**

| Prim | Mechanism | Key trigger |
|---|---|---|
| rsi-oversold-mean-reversion | Oscillator exhaustion in ranging | RSI < 30 regime gate |
| liquidity-sweep-reversal | Stop cluster sweep + reclaim | Swing low wick + CVD |
| ema-pullback-dynamic-support | Trend re-entry at EMA | EMA21 touch in confirmed trend |
| bullish-rsi-divergence | Two-pivot oscillator gap | Price LL + RSI HL pair |
| capitulation-exhaustion-reversal | Panic seller cohort collapse | N consecutive reds + RSI < 20 |
| funding-rate-crowding-reversal | Derivatives crowding signal | Perpetual funding rate extreme |
| hidden-bullish-rsi-divergence (ANTI-PRIM) | Counter-trend trap in uptrend | Price HL + RSI LL |
| **bollinger-squeeze-breakout** | **Vol compression → forced directional expansion** | **BBW < 20th pctl + BB inside KC + momentum at release** |

**RSI mean-reversion sophisticated prim explicitly excludes this regime** (failure mode #7: "BB squeeze → expansion = trend birth, NOT reversion — filter out post-squeeze candles"). This prim fires exactly in that excluded window.

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
- **Source:** anecdote (mechanism from Bollinger 2001 + Carter TTM practitioner; crypto WR pending backtest)
- **Certainty:** hypothesis (mechanism grounded in volatility cycle theory; directional signal unverified on crypto)
- **Scope:** untested on BTC/ETH
- **Falsifiability:** untested
- **Data:**

| Source | Finding |
|---|---|
| **Bollinger (2001, "Bollinger on Bollinger Bands")** | BBW 6-month rolling low = "Bollinger Squeeze"; ~15–20% of bars in squeeze; breakout event typically resolves within 15 bars; founding document for the mechanism |
| **Engle (1982, ARCH paper) + Bollerslev (1986, GARCH)** | Volatility clustering is a stylized fact of financial time series: low-vol periods revert to high-vol; the squeeze is the vol-cycle transition boundary (theoretical anchor) |
| **Carter (2006/2012, TTM Squeeze)** | BB inside KC (ATR-based) = squeeze (red dot); release = directional signal; momentum histogram bias at release = directional filter; practitioner claim 65–70% WR (methodology undisclosed, selection bias suspected) |
| **LazyBear TradingView TTM Squeeze Pro** | Most-published community backtest vehicle; typical reported WR 55–65% over 3–6 month windows (selection-biased sample; no methodology disclosure) |
| **VolatilityBox (already in bank, rsi-oversold sophisticated prim)** | BBW percentile < 20 = squeeze; stable mid-range = mean-reversion viable; squeeze → expansion = REGIME CHANGE (not reversion) |
| **Connors & Alvarez (2009)** | Low-volatility mean-reversion systems outperform in ranging; high-volatility breakout systems outperform post-squeeze; regime distinction is the operative variable |

**What is NOT known:**
- Crypto-specific WR on BTC/ETH 1h or 4h with confirmed methodology
- Optimal squeeze duration before release (≥3 bars? ≥5? ≥10?) — plateau test required
- Whether momentum histogram direction adds WR vs random release — is direction a real signal or noise?
- Squeeze frequency on BTC/ETH 1h vs 4h — if < 10/year on 4h, statistical validation blocked
- KC multiplier sensitivity (ATR scalar 1.5 vs 2.0 vs 2.5) — changes squeeze frequency substantially

### Conditions
- **Works when:** Genuine accumulation period (extended compression, not noise); directional momentum confirmed at release; 4h trend context supportive (EMA200 slope neutral-to-positive); BTC/ETH on 1h–4h; volume ≥ SMA(20) at release bar
- **Fails when:** Range-bound chop with repeated micro-squeezes (≥ 3 squeeze events in 20 bars = overused level, loses predictive value); squeeze releases against HTF trend; same-candle entry without next-candle hold confirmation; KC multiplier too wide (reduces squeeze frequency below statistical viability); altcoins with sparse volume (BB calculation unreliable)
- **Best pairs:** untested — BTC/USDT, ETH/USDT hypothetically (institutional accumulation makes squeeze mechanism plausible; better volume for BB calculation)
- **Best timeframe:** untested — 4h likely superior to 1h (fewer false micro-squeezes); daily possible but too rare for statistical validation within feasible backtest window

### Limitations
1. No peer-reviewed crypto backtest — WR claims from Carter/LazyBear are practitioner with undisclosed methodology
2. Squeeze duration threshold (≥ 5 bars) is untuned — plateau test required on [3, 5, 8, 10, 15] bar minimum
3. Same-candle entry on release bar — no next-candle confirmation costs 5–10pp WR per sister prim meta-analysis
4. Momentum histogram direction may be noise on crypto — the "which side accumulated" inference is untested
5. No regime gate — may fire in all ADX regimes, conflating mechanism with sister prims in trending regimes
6. KC ATR multiplier sensitivity unknown — 1.5× vs 2.0× substantially changes squeeze definition and frequency
7. Repeated micro-squeeze failure mode unquantified: how many consecutive squeezes kill the edge?
8. Signal frequency on BTC/ETH 4h unknown — if < 10 qualifying per year, backtest requires 5+ years
9. Exit logic underspecified: BBU as target is dynamic; prior swing high requires pivot detection from sister prim methodology
10. No volume-based directional filter (CVD at squeeze release would confirm direction — not yet in rule)

### Implementation
- **Strategy:** New signal tier in YujiMultiSignalStrategy or standalone YujiSqueezeStrategy
- **Indicators (pandas-ta):**
  ```python
  bb = ta.bbands(close, length=20, std=2.0)
  kc = ta.kc(high, low, close, length=20, scalar=1.5)
  bbw = (bb['BBU_20_2.0'] - bb['BBL_20_2.0']) / bb['BBM_20_2.0']
  bbw_pctl = bbw.rolling(125).rank(pct=True)          # 6-month percentile
  squeeze = (bb['BBU_20_2.0'] < kc['KCUe_20_1.5']) & (bb['BBL_20_2.0'] > kc['KCLe_20_1.5'])
  squeeze_duration = squeeze.groupby((~squeeze).cumsum()).cumcount()
  squeeze_qualified = squeeze & (bbw_pctl < 0.20)     # squeeze below 20th pctl
  squeeze_release = squeeze_qualified.shift(1) & ~squeeze_qualified  # first bar out
  momentum = ta.mom(close, length=12)                  # or macd histogram
  entry_signal = squeeze_release & (momentum > 0) & (squeeze_duration.shift(1) >= 5)
  ```
- **Parameters (untuned):** `squeeze_duration_min=5`, `kc_scalar=1.5`, `bbw_window=125`, `mom_length=12`
- **Plateau test targets:** `squeeze_duration_min ∈ [3, 5, 8, 10, 15]` × `kc_scalar ∈ [1.5, 2.0]` × `bbw_pctl ∈ [15, 20, 25]` = 30-cell grid

### Conditions Log Entry
- **Works when:** BBW < 20th pctl (125-bar), squeeze ≥ 5 bars, BB inside KC, momentum positive at release, BTC/ETH 4h
- **Fails when:** Micro-squeeze chop (≥ 3 squeezes in 20 bars); HTF bearish; no volume confirmation; same-candle entry
- **Last validated:** never

### Sources
- Bollinger, J. (2001). *Bollinger on Bollinger Bands*. McGraw-Hill. (BBW squeeze concept, ~15-20% squeeze frequency)
- Engle, R.F. (1982). ARCH models — J. Econometrica. (Volatility clustering theoretical anchor)
- Bollerslev, T. (1986). GARCH — Journal of Econometrics. (Volatility mean-reversion theoretical anchor)
- Carter, J. (2012). *Mastering the Trade* (2nd ed.). McGraw-Hill. (TTM Squeeze indicator origin)
- [LazyBear TradingView — TTM Squeeze Pro](https://www.tradingview.com/script/nqQ1DT5a-TTM-Squeeze-Pro/) (most-published community backtest vehicle)
- [VolatilityBox — Bollinger Bands Volatility: Squeeze and Percentile](https://volatilitybox.com/research/bollinger-bands-volatility/) (already in bank via rsi-oversold sophisticated prim)
