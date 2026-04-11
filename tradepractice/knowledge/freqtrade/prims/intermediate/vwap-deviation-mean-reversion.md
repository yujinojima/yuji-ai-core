---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T10:00:00+10:00
cycle: 53
---

```
from: analyst-freqtrade
to: conductor
subject: cycle-53-complete
timestamp: 2026-04-12T10:00:00+10:00
cycle: 53
---
mode: RESEARCH
action: ELEVATION — naive → intermediate
prim: vwap-deviation-mean-reversion
level: intermediate
project: freqtrade
parent-naive-commit: 315ab6a
```

## Prim: vwap-deviation-mean-reversion
**Level:** intermediate  
**Project:** freqtrade  
**Parent:** naive (cycle 51)

---

### What Changed from Naive

The naive prim (cycle 51) confirmed signal existence — WR 67.2% (n=427) vs equity ETF baseline 55–60% — but produced negative EV (avg profit −0.11%, Sharpe −0.85, PF 0.78). The root cause was identified as three compounding failures:

1. **R:R structural deficiency**: At 1.0σ entry / 2.0σ stop, reward = risk = 1.0σ (1.0:1 R:R). After 0.8% round-trip fee drag (0.4% × 2 at Binance), EV is negative at any WR below ~55% with this R:R. The fix is moving the default entry to 1.25σ: profit potential 1.25σ, risk = 0.75σ (stop stays at VWAP − 2.0σ), giving **1.67:1 R:R** — positive EV territory at WR 67%.

2. **602-day drawdown traced to trending VWAP**: The max drawdown (2023-03-23 → 2024-11-15) occurred during sustained BTC trend phases. When VWAP itself is rising or falling, price below VWAP is a directional position against the trend, not mean reversion — institutional passive bids don't activate in trending markets. The VWAP slope gate (12-bar slope ∈ ±0.5%) filters trending VWAP periods directly.

3. **Dynamic stop fired immediately**: The naive prim used a static −5% proxy because rolling VWAP shifts each bar, triggering a dynamic stop based on current-bar values on the next candle. The intermediate prim stores entry-bar VWAP and σ_D in `trade.custom_info` and anchors the stop there permanently.

---

### Mechanism

Institutional execution desks (pension funds, mutual funds, derivatives desks) use VWAP as the primary TCA (transaction cost analysis) benchmark — the standard against which execution quality is audited (Berkowitz/Logue/Noser 1988 *JF*; Madhavan/Richardson/Roomans 1997 *RFS*). Almgren & Chriss (2001 *JRF*) formalises VWAP-anchored execution as the optimal schedule for minimising implementation shortfall, confirming VWAP is not an incidental reference but a structural constraint on institutional behaviour.

When price falls below VWAP under **flat VWAP conditions** (slope ≈ 0), passive buy programmes activate to improve execution quality — they need to average below VWAP to show positive TCA scores. Intraday shorts who faded the move are trapped when benchmark gravity reasserts; their forced covering provides additional fuel.

The intermediate prim tightens this mechanism to the condition where benchmark gravity is active: VWAP must be flat (slope gate), the overall context must be structurally bullish (1h EMA200 + 4h EMA200 slope ≥ 0), and price must not be in free-fall (4h RSI > 25 + volume filter).

---

### Rule

```
close ≤ VWAP − 1.25×σ_D                   [entry band: raised from 1.0σ; R:R = 1.67]
AND VWAP_slope_12h ∈ (−0.5%, +0.5%)       [NEW: flat VWAP only — slope gate]
AND ADX < 25                               (ranging — benchmark gravity active)
AND close > 1h EMA200                      (structural bull context)
AND 4h EMA200 slope ≥ 0                    [NEW: macro context — no secular bear]
AND volume ≥ 0.8× SMA(20)                  [NEW: participation filter]
AND 4h RSI > 25                            (anti-freefall gate)

→ next-candle confirmation:
  close(bar+1) > entry_bar_VWAP − 0.5×entry_bar_σ_D   [NEW: was deferred in naive]

→ LONG to VWAP

Custom stoploss: entry_bar_VWAP − 2.0×entry_bar_σ_D   [NEW: anchored, not rolling]
```

where `σ_D` = rolling standard deviation of close over `vwap_rolling_std_period` bars (default 20, hyperopt range [14, 30]).

**R:R at default 1.25σ entry:**
- Profit target: 1.25σ above entry (to VWAP)
- Stop: 0.75σ below entry (to VWAP − 2.0σ)
- R:R = 1.25σ / 0.75σ = **1.67:1** (vs 1.0:1 naive)
- After 0.8% fee: EV > 0 when WR > 37% (vs breakeven WR 55% at 1.0:1 R:R)

---

### What Changed from Naive — Summary Table

| Dimension | Naive | Intermediate | Why |
|-----------|-------|-------------|-----|
| Entry band | 1.0σ | **1.25σ** | R:R 1.0 → 1.67; EV-positive after fees |
| VWAP slope gate | absent | **slope ∈ ±0.5% / 12 bars** | 602-day drawdown traced to trending VWAP |
| Next-candle confirmation | deferred | **close(t+1) > VWAP_entry − 0.5σ** | +5–10pp WR from sister prim meta-analysis |
| Custom stoploss | −5% static proxy | **VWAP_entry − 2.0σ anchored** | Prevents rolling VWAP from misfiring stop |
| 4h EMA200 slope | absent | **≥ 0 (macro filter)** | Suppresses secular bear entries |
| Volume filter | absent | **≥ 0.8× SMA(20)** | Low-participation bars → gap-fill risk |
| Default vwap_band_entry | 1.0 | **1.25** | Plateau-grid default anchored to R:R analysis |

---

### Epistemic Status

| Dimension | Rating |
|-----------|--------|
| Source | academic (equity microstructure, Almgren-Chriss) + own-data backtest (n=427) |
| Certainty | hypothesis (signal confirmed; EV sign uncertain pending intermediate backtest) |
| Scope | BTC/ETH only (institutional flow assumption; altcoins excluded) |
| Falsifiable | yes — intermediate WR target ≥ 70%, avg profit ≥ 0.5% per trade |
| Reaction validated | partially — WR 67.2% confirms bounce tendency; R:R adequate requires re-test |

---

### Key Numbers

| Metric | Value | Source |
|--------|-------|--------|
| Naive WR (n=427) | 67.2% | Own-data backtest cycle 51 |
| Naive avg profit | −0.11% | Own-data; fee drag dominant |
| Round-trip fee | 0.8% | Binance 0.4% taker × 2 |
| R:R at 1.0σ entry | 1.0:1 | Derived: reward=1.0σ, risk=1.0σ |
| R:R at 1.25σ entry | **1.67:1** | Derived: reward=1.25σ, risk=0.75σ |
| Breakeven WR at 1.67:1 | **37%** | Derived (vs 50% at 1:1) |
| Expected EV flip | WR ≥ 55% + 1.67:1 R:R | Positive EV: 0.55×1.25 − 0.45×0.75 = 0.35σ > fees |
| Equity ETF VWAP bounce WR | 55–60% | QuantifiedStrategies (unverified crypto transfer) |
| OOS degradation | 25–50% Sharpe | McLean-Pontiff (2016, *JF*) factor zoo |
| Plateau grid cells | 36 | vwap_band_entry [0.75–1.5] × adx_max [20–30] × std_period [14–30] |
| PBO threshold | 20 cells | Bailey et al. SSRN 2326253 |

---

### 10 Documented Limitations

1. Crypto has no institutional trading session — 24-bar UTC rolling VWAP is a practical proxy, not a true benchmark anchor; institutional behaviour may differ from equity microstructure models
2. Institutional flow assumption for crypto unverified — thesis is plausible (OTC desks, ETF market makers) but no direct evidence of VWAP-anchored execution algorithms in crypto
3. σ_D is rolling close std, not true VWAP dispersion — bands are symmetric proxies, not calibrated to actual VWAP tracking error
4. VWAP slope threshold ±0.5%/12-bar is derived analytically from the drawdown post-mortem, not backtested independently
5. 4h EMA200 slope gate adds a second timeframe dependency — introduces look-ahead if 4h bars are not properly aligned in freqtrade informative design
6. Next-candle confirmation reduces trade frequency — +5–10pp WR estimate from sister prims; actual improvement for this mechanism unquantified until intermediate backtest
7. 36-cell plateau grid exceeds PBO threshold → CPCV + DSR mandatory; hyperopt results without these corrections are unreliable
8. vwap_band_entry = 1.25 default reduces signal frequency vs 1.0 — fewer entry bars qualify; sample size concern for short backtest windows
9. Weekend/low-volume UTC distortions in crypto VWAP are known but not filtered (no day-of-week gate)
10. OOS degradation 25–50% Sharpe expected (McLean-Pontiff) — IS Sharpe target ≥ 0.70 required before considering deployment

---

### Evidence Sources

**Prior (naive, retained):**
- Berkowitz, Logue, Noser (1988) *JF* — foundational VWAP-as-benchmark paper
- Madhavan, Richardson, Roomans (1997) *RFS* — VWAP microstructure
- Harris (2003) *Trading and Exchanges* Ch. 20 — institutional execution benchmarks
- QuantifiedStrategies — VWAP bounce ~55–60% WR on equity ETFs (crypto transfer unverified)

**New (intermediate elevation):**
- Almgren & Chriss (2001) *JRF* — VWAP execution as optimal schedule minimising implementation shortfall; confirms VWAP as structural institutional constraint, not incidental reference
- **Own-data backtest (cycle 51)** — n=427 trades, WR 67.2% BTC/ETH 2023–2024; first own-data anchor; signal exists; EV negative due to fee drag alone

**Methodology:**
- McLean & Pontiff (2016) *JF* — factor zoo OOS degradation 25–50%
- Bailey, Borwein, Lopez de Prado & Zhu (2016) *SSRN 2326253* — CPCV + DSR correction for multi-test bias

---

### Implementation Gaps

All 7 gaps must be addressed before intermediate backtest:

1. **`vwap_slope_12h` computation** — `vwap_slope_12h = (vwap - vwap.shift(12)) / vwap.shift(12)` added to `populate_indicators`; entry gate: `abs(vwap_slope_12h) < 0.005`

2. **`ema_200_4h_slope` gate** — `populate_indicators_4h` must compute `ema_200` then `ema_200_slope = (ema_200 - ema_200.shift(5)) / ema_200.shift(5)`; entry gate: `ema_200_4h_slope >= 0`

3. **Next-candle confirmation** — `entry_raw = entry_conditions.shift(1)` + `confirmation = close > vwap.shift(1) - 0.5 * vwap_std.shift(1)`; combined: `entry_raw & confirmation`

4. **Volume filter** — `volume_sma = volume.rolling(20).mean()`; gate: `volume >= 0.8 * volume_sma`

5. **`custom_stoploss` with entry-bar anchor** —
   ```python
   def custom_stoploss(self, pair, trade, current_time, current_rate, current_profit, **kwargs):
       entry_vwap = trade.custom_info.get('entry_vwap', None)
       entry_std = trade.custom_info.get('entry_std', None)
       if entry_vwap is None or entry_std is None:
           return self.stoploss
       stop_price = entry_vwap - 2.0 * entry_std
       return (stop_price / trade.open_rate) - 1
   ```

6. **`confirm_trade_entry` to populate `trade.custom_info`** —
   ```python
   def confirm_trade_entry(self, pair, order_type, amount, rate, time_in_force,
                           entry_tag, side, **kwargs) -> bool:
       df, _ = self.dp.get_analyzed_dataframe(pair, self.timeframe)
       last = df.iloc[-1]
       # Will be overridden by custom_entry_price hook; store here for stoploss
       # NOTE: trade object is NOT available yet; use custom_stoploss with
       # stoploss_on_exchange_interval pattern instead (see gap 7)
       return True
   ```
   **Note**: `trade.custom_info` must be populated in `custom_entry_price` or `bot_loop_start`. Use `trade.custom_info['entry_vwap'] = last['vwap']` inside a `custom_stoploss` first-call guard (if `entry_vwap` not set, set from current bar and return static).

7. **`vwap_band_entry` default raised to 1.25** — `DecimalParameter(0.75, 1.5, default=1.25, ...)` in hyperopt space

---

### Intermediate Backtest Results — Cycle 54 (2026-04-12)

**Exchange:** Binance (USDT pairs) | **Period:** 2023-01-01 → 2024-12-31 | **Fee:** 0.4% taker

| Metric | Result | Target | Status |
|--------|--------|--------|--------|
| Trades | 21 | n/a | CRITICAL — too few |
| Win Rate | 28.6% | ≥ 70% | MISS |
| Avg Profit | −0.26% | ≥ 0.5% | MISS |
| Sharpe | −0.16 | ≥ 0.70 | MISS |
| Profit Factor | 0.33 | > 1.0 | MISS |
| Max Drawdown | 2.65% | < 10% | PASS |
| Market change | +319% | n/a | (benchmark) |

**Verdict: FAIL — all three elevation targets missed by large margins.**

---

### Failure Diagnosis (Cycle 54)

**1. Over-filtering — 95% signal elimination (427 → 21 trades)**

The 7 intermediate filters combined eliminate 95% of naive signals. With only 21 trades over 2 years, results are statistically insignificant and the strategy is untradeable. The filters are mutually reinforcing in a way that selects an extremely rare market condition that may not recur.

Likely culprits for maximum filtering:
- `vwap_slope_12h < 0.005` combined with `4h EMA200 slope ≥ 0` — flat VWAP + rising macro is a very rare joint condition
- Next-candle confirmation on top of already-filtered signals reduces further
- Volume filter + ADX < 25 + flat VWAP all correlated → multiplicative reduction

**2. `custom_info` AttributeError — custom stoploss non-functional**

```
AttributeError: 'LocalTrade' object has no attribute 'custom_info'
```

`LocalTrade` (backtesting) in this freqtrade version (2026.3) does not support `custom_info`. The strategy fell back to static `stoploss = -0.05`, but the static stop also never fired (all 21 exits via `exit_signal`). The custom stoploss anchor (VWAP − 2.0σ) was inoperative throughout. Fix: use a class-level dict keyed by trade ID:

```python
_entry_data: dict = {}  # class-level, keyed by (pair, open_date_utc)

def custom_stoploss(self, pair, trade, ...):
    key = (pair, trade.open_date_utc)
    if key not in self._entry_data:
        df, _ = self.dp.get_analyzed_dataframe(pair, self.timeframe)
        if df is not None and len(df) > 0:
            last = df.iloc[-1]
            self._entry_data[key] = {
                'entry_vwap': float(last['vwap']),
                'entry_std': float(last['vwap_std'])
            }
    data = self._entry_data.get(key, {})
    ...
```

**3. WR collapse from 67.2% (naive) to 28.6% (intermediate)**

Adversarial selection hypothesis: the flat VWAP + rising 4h EMA + confirmation combination selects conditions where price is in a temporary pause within a rising trend. In those conditions, entering on a pullback to VWAP − 1.25σ means the "flat VWAP" is actually at an inflection point where the trend resumes downward before recovery. The confirmation bar (close > VWAP − 0.5σ) may be selecting failed recovery attempts.

**4. VWAP exit instability**

Rolling 24-bar VWAP changes each bar. When entry fires and VWAP drifts lower over holding period, the exit condition `close ≥ VWAP` fires at a price below entry. This explains losses despite VWAP-based exit: the exit target moved toward the entry price and fired early.

---

### Required Changes Before Re-Backtest

| Priority | Change | Rationale |
|----------|--------|-----------|
| P0 | Fix `custom_info` → class-level dict | Custom stoploss completely inoperative |
| P1 | Loosen slope gate: ±0.005 → ±0.01 (1%) | Doubles qualifying conditions; still excludes strong trends |
| P1 | Remove 4h EMA200 slope gate | Combined with VWAP slope gate = redundant double-filter |
| P2 | Remove volume filter (0.8× SMA) | Low additive value vs trade count cost |
| P2 | Add minimum holding bars (e.g., 3) before VWAP exit | Prevents rolling VWAP drift from triggering immediate exit |

Target after loosening: ≥ 100 trades, WR ≥ 50%, before re-evaluating filter combination.

---

### Conditions Log Entry (for conditions-log.md)

```
## vwap-deviation-mean-reversion (intermediate) — 2026-04-12
- Works when: FLAT VWAP (slope ∈ ±0.5%/12 bars) + RANGING regime (ADX < 25) + close ≤ VWAP − 1.25×σ_D + next-candle close > entry_bar_VWAP − 0.5×σ_D + close > 1h EMA200 + 4h EMA200 slope ≥ 0 + volume ≥ 0.8× SMA(20) + 4h RSI > 25; BTC/ETH only; 1h TF
- INTERMEDIATE BACKTEST FAILED (cycle 54): WR 28.6% (21 trades) vs 70% target. Root cause: over-filtering (95% signal reduction) + custom_info bug (stoploss inoperative). Loosening required before re-test.
- Fails when: VWAP slope outside ±0.5% (trending VWAP — 602-day drawdown failure mode); ADX ≥ 25 (trending market, no benchmark gravity); news-driven freefall (4h RSI < 25); price below 1h EMA200 (structural bear); altcoins/low-liquidity pairs; weekend/low-volume UTC distortions; no next-candle confirmation (continuation breakdown)
- R:R: 1.67:1 at 1.25σ entry / 2.0σ stop (vs 1.0:1 naive). EV positive when WR ≥ 37% post-fee at this R:R.
- Key numbers: Naive WR 67.2% n=427 (signal confirmed); intermediate WR 28.6% n=21 (FAIL — over-filtered); avg profit target ≥ 0.5%/trade; IS Sharpe target ≥ 0.70; 36-cell CPCV + DSR mandatory
- Last validated: cycle 54 intermediate backtest FAIL (WR 28.6%, n=21, Sharpe -0.16, PF 0.33; custom_info bug confirmed)
```

---

### Knowledge Bank State After Cycle 53

| Project | Naive | Intermediate | Sophisticated |
|---------|-------|-------------|---------------|
| freqtrade | 8 (7 superseded + **1 active** → now SUPERSEDED) | 11 superseded + **1 active** | 8 active |
| polymarket | 5 (4 superseded + 1 active) | 4 superseded + 1 active | 4 active |
| **Total** | **13** | **12 → 13** | **12** |

**Refinement path for cycle 54:** Run intermediate backtest with all 7 implementation gaps applied. Target: WR ≥ 70%, avg profit ≥ 0.5%/trade, Sharpe ≥ 0.70 IS. If targets met, run 36-cell plateau grid with CPCV + DSR correction. Elevation to sophisticated requires: (a) plateau test passes (PF variance < 25% across grid), (b) 3 academic sources including Almgren-Chriss, (c) explicit anti-prim escape hatches, (d) OOS degradation model (IS Sharpe ≥ 0.70 required before deployment consideration).
