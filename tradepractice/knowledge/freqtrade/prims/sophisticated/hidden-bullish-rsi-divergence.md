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

### What Elevated This from Intermediate

13 sources (up from 8). Elevation adds: **mechanistic cross-reference from PMC9920669, quantified friction model, OOS ceiling, Wyckoff volume threshold (≤ 50% of impulse peak, replacing "declining"), R:R upgrade from 1:1.5 → 1:2, 28-cell parameter plateau requirement, CPCV+DSR correction mandate, and two anti-prim escape hatches.**

### Key New Findings

| Finding | Source | Impact |
|---|---|---|
| PMC9920669 momentum side (RSI>50) returned **+498pp vs B&H** vs reversal side −97.5pp | PMC9920669 (same study as sister prim negative anchor) | Hidden div aligns with WINNING side of only peer-reviewed crypto study — mechanistic support without being tested directly |
| Friction Sharpe erosion **~47%** | BSIC | Mandatory sub-1h ban; R:R ≥ 1:2 required (1:1.5 too friction-sensitive) |
| **OOS degradation 26–58%** ceiling | QuantPedia + arxiv 2602.10785 | Bounds live WR at 50–55% post-OOS |
| **28 cells = PBO threshold crossed** (7 lookback × 4 gap = 28 > 20) | Bailey-Borwein-Lopez de Prado | CPCV + DSR correction mandatory; raw Sharpe disallowed |
| **Wyckoff "test on low volume"** = volume ≤ 50% of prior impulse peak | Wyckoff / SMC corpus | Upgrades from qualitative "declining" to quantified threshold |

### Key Numbers

| Metric | Value |
|---|---|
| Mechanism alignment | Momentum side of PMC9920669 (+498pp) vs sister prim's reversal side (−97.5pp) |
| Expected live WR | **55–62%** (premium over sister's 52–58%; trend-continuation vs reversal mechanism) |
| Post-OOS lower bound | **50–55%** (vs sister's 48–52%) |
| Signal frequency | < 0.5% of candles |
| Friction Sharpe erosion | ~47% |
| Parameter grid | 28 cells (7 × 4); PBO threshold crossed → DSR mandatory |
| EV at 55% WR / 1:2 R:R | +0.65 per unit risk |

### Anti-Prim Escape Hatches
- **(A) Plateau fails** across 28 cells → mark anti-prim, do not re-refine
- **(B) Head-to-head shows hidden WR ≤ regular WR in trend regime** → "practitioner hierarchy inverted for crypto" — high-value negative result, mark anti-prim with full documentation

### Bank State After Cycle 19

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | 0 |
| Intermediate | **0 active** | 3 |
| Sophisticated | **5** (rsi-oversold, ema-pullback, liq-sweep, bullish-rsi-div, hidden-div) | 1 |

All freqtrade prims at sophisticated. 5-axis regime partition complete. The two divergence prims now sit at the same tier — the head-to-head walk-forward is the highest-value single test in the bank (any of 4 outcomes is load-bearing research output).

### Next Cycle
**BACKTEST-ANALYSIS** — the only blocker remaining. Primary target: head-to-head walk-forward of `bullish-rsi-divergence` (sophisticated, EXHAUSTION regime) vs `hidden-bullish-rsi-divergence` (sophisticated, TRENDING MOMENTUM regime) on same BTC/ETH 4h data window across bull → bear → accumulation phases. Run parameter plateau (20-cell and 28-cell grids) with DSR correction on both simultaneously.
