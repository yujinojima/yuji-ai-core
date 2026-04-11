---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T13:16:50+10:00
cycle: 19
---

---

## Prim: hidden-bullish-rsi-divergence
**Level:** sophisticated (refined from intermediate)
**Project:** freqtrade
**Parent:** intermediate/hidden-bullish-rsi-divergence

### ⛔ ANTI-PRIM — Escape Hatch (A) Triggered (Cycle 40)

**28-cell plateau test result (2023-01-01 – 2024-12-01, BTC/ETH 4h):**

| Cells | WR Range | PF > 1 | Conclusion |
|---|---|---|---|
| 28/28 | 27.3% – 40.0% | **0 / 28** | ANTI-PRIM |

Full grid (7 lookback × 4 gap):

| Cell | Lookback | Gap | Trades | WR% | Total Profit% |
|---|---|---|---|---|---|
| 01 | 8 | 2 | 5 | 40.0 | −3.32 |
| 02 | 8 | 3 | 5 | 40.0 | −3.32 |
| 03 | 8 | 5 | 5 | 40.0 | −3.32 |
| 04 | 8 | 7 | 5 | 40.0 | −3.32 |
| 05 | 12 | 2 | 10 | 30.0 | −7.42 |
| 06 | 12 | 3 | 10 | 30.0 | −7.42 |
| 07 | 12 | 5 | 6 | 33.3 | −4.98 |
| 08 | 12 | 7 | 6 | 33.3 | −4.98 |
| 09 | 16 | 2 | 10 | 30.0 | −7.42 |
| 10 | 16 | 3 | 10 | 30.0 | −7.42 |
| 11 | 16 | 5 | 6 | 33.3 | −4.98 |
| 12 | 16 | 7 | 6 | 33.3 | −4.98 |
| 13 | 20 | 2 | 10 | 30.0 | −7.42 |
| 14 | 20 | 3 | 10 | 30.0 | −7.42 |
| 15 | 20 | 5 | 6 | 33.3 | −4.98 |
| 16 | 20 | 7 | 6 | 33.3 | −4.98 |
| 17 | 25 | 2 | 11 | 27.3 | −9.01 |
| 18 | 25 | 3 | 11 | 27.3 | −9.01 |
| 19 | 25 | 5 | 7 | 28.6 | −6.61 |
| 20 | 25 | 7 | 6 | 33.3 | −4.98 |
| 21 | 30 | 2 | 11 | 27.3 | −9.01 |
| 22 | 30 | 3 | 11 | 27.3 | −9.01 |
| 23 | 30 | 5 | 7 | 28.6 | −6.61 |
| 24 | 30 | 7 | 6 | 33.3 | −4.98 |
| 25 | 40 | 2 | 11 | 27.3 | −9.01 |
| 26 | 40 | 3 | 11 | 27.3 | −9.01 |
| 27 | 40 | 5 | 7 | 28.6 | −6.61 |
| 28 | 40 | 7 | 6 | 33.3 | −4.98 |

**Diagnostic observation:** `rsi_hidden_min_gap` is non-discriminating — changing gap 2→3→5→7 produces identical results at same lookback (except gap 2-3 vs 5-7 boundary). The RSI difference between p2 and p1 in the hidden divergence condition always exceeds tested thresholds, meaning this parameter has no real filtering power.

**Mechanism assessment:** The sophisticated gate stack (EMA ribbon ≥ 3, ADX 20–45 rising, RSI > 50, Wyckoff vol ≤ 50% impulse peak, Fibonacci pullback ≤ 50%) suppresses signal count to 5–11 trades per cell but does not improve quality. WR degrades toward 27% at wider lookbacks (more signals, worse quality).

**Do not re-refine.** The anti-prim is structural — the mechanism (hidden divergence as trend continuation) does not produce positive expectancy on BTC/ETH 4h in this 2-year window spanning bull, bear, and accumulation phases. PMC9920669 momentum-side alignment did not translate to backtest edge.

---

### Original Prim Record (Cycle 19, Pre-Anti-Prim)

**What Elevated This from Intermediate**

13 sources (up from 8). Elevation adds: mechanistic cross-reference from PMC9920669, quantified friction model, OOS ceiling, Wyckoff volume threshold (≤ 50% of impulse peak, replacing "declining"), R:R upgrade from 1:1.5 → 1:2, 28-cell parameter plateau requirement, CPCV+DSR correction mandate, and two anti-prim escape hatches.

### Key Numbers

| Metric | Value |
|---|---|
| Expected live WR (projected) | 55–62% — NOT ACHIEVED |
| Post-OOS lower bound (projected) | 50–55% — NOT ACHIEVED |
| Backtest WR range (28-cell) | 27.3% – 40.0% |
| Parameter grid | 28 cells (7 × 4) |
| Anti-prim trigger | Escape hatch (A): plateau fails |

### Bank State After Cycle 40 Anti-Prim

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | 0 |
| Intermediate | 0 active | 1 (superforecaster-consensus-lead) |
| Sophisticated | **6** (rsi-oversold, ema-pullback, liq-sweep, bullish-rsi-div, ensemble-forecast-edge, funding-crowding) | 8 |
| Anti-prim | **1** (hidden-bullish-rsi-divergence) | 0 |

**Net freqtrade bank: 6 active sophisticated prims (hidden-div removed from active)**
