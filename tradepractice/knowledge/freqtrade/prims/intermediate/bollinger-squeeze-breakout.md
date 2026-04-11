---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T21:47:07+10:00
cycle: 46
---

Cycle 46 complete. Here is the analyst result:

---

```
from: analyst
subject: analyst-result
timestamp: 2026-04-11T21:38:34+10:00
cycle: 46
```

## Prim: bollinger-squeeze-breakout
**Level:** intermediate (refined from naive)
**Project:** freqtrade
**Parent:** naive/bollinger-squeeze-breakout

### Rule
BBW percentile < 20th (rolling 125 bars) for **≥ 8 consecutive bars** + BB fully inside KC (`kc_scalar = 1.5–2.0`, plateau-verified) + **4h EMA200 slope positive** (`ema_200 > ema_200.shift(20)`) + **ADX_4h < 35** (not parabolic) → on first squeeze release bar: **close > open** (bullish body) AND momentum > 0 AND volume ≥ **1.5× SMA(20)** AND **CVD net positive over last 3 bars** + **next-candle structure break** (`close > release_candle_high.shift(1)` AND `close > bbm.shift(1)`) → long to BBU / prior swing high. Stop below squeeze range low.

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Squeeze duration | ≥ 5 bars | **≥ 8 bars** (Connors: longer compression → larger trapped cohort; 8-bar filter removes ~40% micro-squeezes) |
| Release candle | momentum > 0 only | **close > open AND momentum > 0** (body direction + oscillator both required) |
| Volume | ≥ SMA(20) | **≥ 1.5× SMA(20)** (institutional participation threshold) |
| Directional confirmation | none | **CVD net positive over last 3 bars** (pre-release order flow evidence) |
| HTF context | qualitative "neutral-to-bullish" | **4h EMA200 slope positive** — mechanism gate (downtrend releases enter seller supply, not trapped-cohort unwind) |
| ADX | none | **ADX_4h < 35** — parabolic exclusion |
| Confirmation | `close > bbm.shift(1)` | **`close > release_high.shift(1)` AND `close > bbm.shift(1)`** (structure break) |
| Certainty | guess | **hypothesis** (GARCH persistence + Connors duration-magnitude + convergent practitioner) |

### New Academic Anchor

**Katsiampa (2017), Finance Research Letters** — Bitcoin GARCH(1,1): α+β = **0.968** (near unit-root). Equities typical α+β ≈ 0.90–0.94. Implication: crypto volatility compressions are stickier and expansions are more violent than equity equivalents. A ≥ 8-bar squeeze at the 20th BBW percentile is genuinely uncommon on crypto — not calendar noise — and represents a more extreme trapped-agent configuration than the same reading on equities. This is the mechanism amplifier that distinguishes a crypto squeeze implementation from Carter's equity TTM Squeeze.

### 7 Implementation Gaps (YujiSqueezeBreakoutStrategy.py)

1. `squeeze_duration >= 5` → `squeeze_duration >= 8`
2. Add `(close > open)` to `entry_signal`
3. Add CVD 3-bar rolling net:
   ```python
   cvd_delta = (close - low) / (high - low + 1e-9) * volume
   cvd_3bar_net = cvd_delta.rolling(3).sum()
   entry_signal = entry_signal & (cvd_3bar_net > 0)
   ```
4. `volume >= volume_sma` → `volume >= 1.5 * volume_sma`
5. Add 4h informative pair; `ema_200_4h > ema_200_4h.shift(20)` gate
6. Add `ADX_4h` from 4h informative; `adx_4h < 35` gate
7. Next-candle: `close > bbm.shift(1)` → `close > release_high.shift(1) & close > bbm.shift(1)`

### Plateau Grid (45 cells — DSR mandatory)

`duration ∈ [5, 8, 10, 12, 15]` × `kc_scalar ∈ [1.5, 1.75, 2.0]` × `bbw_pctl ∈ [0.15, 0.20, 0.25]` = 45 cells. CPCV + Deflated Sharpe correction required. PF variance < 25% across stable plateau = intermediate → sophisticated promotion criterion.

### Anti-Prim Escape Hatches

**(A)** If backtest signal count < 15 in 3yr at ≥ 8 bar threshold → frequency collapse → relax to ≥ 5 and re-evaluate.
**(B)** No plateau cell WR > 52% across 45-cell grid → mechanism not producing edge on crypto 4h → anti-prim.

### Bank State After Cycle 46

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | **0** (bollinger-squeeze superseded) | 0 |
| Intermediate | **1** (bollinger-squeeze-breakout) | 0 |
| Sophisticated | 6 active + 1 anti-prim | 10 |

### Next Cycle Recommendation

**(A) BACKTEST-ANALYSIS** — run 45-cell plateau grid on `YujiSqueezeBreakoutStrategy.py` with the 7 implementation gaps applied; primary gate: WR > 52% in any stable plateau region → intermediate confirmed; no plateau → anti-prim (B). Data: BTC+ETH 4h 2022-01-01 → 2025-01-01. DSR correction mandatory before sophisticated elevation.
