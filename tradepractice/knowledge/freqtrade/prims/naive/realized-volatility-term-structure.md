---
prim: realized-volatility-term-structure
project: freqtrade
level: naive
cycle: 101
axis: 14th regime axis
signal-class: volatility regime classifier via RV term structure slope
created: 2026-04-12
superseded-by: null
---

# Realized Volatility Term Structure

## Mechanism

Crypto markets exhibit volatility clustering with mean-reverting term structure dynamics. When short-horizon realized volatility exceeds long-horizon RV (inverted term structure), the market is in an elevated-vol regime where further vol expansion is statistically unlikely and mean reversion in both price and vol is the base case. When short-horizon RV is suppressed relative to long-horizon RV (contango term structure), the market is coiling toward a regime break — analogous to VIX term structure inversion as a crash predictor in equities, but directionally neutral in crypto.

Distinct from Bollinger Band Width squeeze: BBW measures price standard deviation within a fixed window (proxy for vol); RV term structure measures the **ratio** of annualized RV across two windows, capturing the slope of the vol curve rather than its absolute level.

## Signal Definition

Let:
- `RV_S` = short-term realized volatility, annualized from log returns: `std(log(close/close.shift(1)), window=24) * sqrt(365*24)` on 1h bars (24-bar ≈ 1-day)
- `RV_L` = long-term realized volatility: same formula, `window=168` (7-day)
- `RV_ratio` = `RV_S / RV_L`

**Inverted** (hot regime): `RV_ratio > 1.5` — short vol elevated, expect mean reversion  
**Contango** (coiling regime): `RV_ratio < 0.6` — short vol suppressed, expect expansion  
**Neutral**: `0.6 ≤ RV_ratio ≤ 1.5`

## Entry Condition (Naive)

Long bias when `RV_ratio < 0.6` AND price closes above prior bar close (momentum confirmation).  
Mean-reversion bias when `RV_ratio > 1.5` AND RSI_14 < 40.

Single-variable rule. No regime gate. No multi-timeframe confirmation.

## Failure Modes (naive — not yet documented)

At naive tier, failure modes are not enumerated. Known theoretical risks:
- Sustained low-vol regimes (2019-style drift) keep `RV_ratio` in contango for weeks; entry signals early
- RV computed from 1h OHLCV includes overnight gaps in spot but not perps — computation surface must be uniform
- Ratio is undefined during exchange outages or data gaps (divide-by-zero guard required)

Promote to intermediate to document empirical failure modes with backtest evidence.

## Epistemic Status

- **Source**: theoretical (academic vol term structure literature) + anecdotal crypto observation
- **Certainty**: hypothesis
- **Scope**: BTC/ETH perps, 1h bars, 2022–2026 regime
- **Falsifiability**: `RV_ratio < 0.6` produces no statistically significant forward returns improvement vs base rate in IS backtest (n≥200, WR delta < 3%)
- **Limitations**: RV is backward-looking; does not capture implied vol (no liquid crypto options data in freqtrade pipeline); ratio unstable during low-vol floors

## Implementation (freqtrade)

Added to `YujiRegimeStrategy.py` in `populate_indicators()`:

```python
log_ret = np.log(dataframe['close'] / dataframe['close'].shift(1))
dataframe['rv_short'] = log_ret.rolling(24).std() * np.sqrt(365 * 24)
dataframe['rv_long']  = log_ret.rolling(168).std() * np.sqrt(365 * 24)
dataframe['rv_ratio'] = dataframe['rv_short'] / dataframe['rv_long'].replace(0, np.nan)
dataframe['rv_regime_coiling'] = (dataframe['rv_ratio'] < self.rv_coiling_threshold.value).astype(int)
dataframe['rv_regime_hot'] = (dataframe['rv_ratio'] > self.rv_hot_threshold.value).astype(int)
```

Hyperopt parameters: `rv_coiling_threshold` (0.4–0.7, default 0.6), `rv_hot_threshold` (1.3–1.8, default 1.5), `rv_hot_rsi_threshold` (30–45, default 40).

Entry tags: `rv_coiling_breakout`, `rv_hot_reversion`.

## Blocking Gates (for promotion to intermediate)

- **G1**: Frequency scan — how often does `RV_ratio < 0.6` fire on BTC/ETH 1h 2022–2026? Target: ≥2 episodes/month to generate n≥100 within 4-year IS window
- **G2**: Forward return distribution — 12h, 24h, 48h mean returns conditional on `rv_regime` vs unconditional base rate (Mann-Whitney U, p<0.05 required)
- **G3**: Stability check — does `RV_ratio` threshold generalize across BTC/ETH/SOL/BNB, or is it pair-specific?
- **G4**: Correlation check — pairwise signal correlation with BBW squeeze gate (existing axis 7). If Spearman ρ > 0.7, signals are redundant and this prim does not justify a new axis

## Separation from Existing Axes

| Axis | Mechanism | Key variable |
|---|---|---|
| 7 (BBW squeeze) | Price SD percentile rank | `BB_width / BB_width.rolling(125).mean()` |
| 14 (this) | RV term structure slope | `RV_24bar / RV_168bar` (log return SD ratio) |

BBW captures whether current price oscillation is compressed vs its own history. RV ratio captures whether the vol surface is inverted (crisis regime) vs coiling (pre-breakout). The two can diverge: BBW can be low while RV_ratio is hot (vol contracted in price terms but recent realized vol still exceeds long-run average on log-return basis).

Promotion blocked until G4 correlation check confirms ρ < 0.7.
