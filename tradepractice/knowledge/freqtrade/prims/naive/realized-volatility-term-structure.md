---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T17:43:24+10:00
cycle: 103
---

---

```
from: analyst
subject: analyst-result
timestamp: 2026-04-12T00:00:00+10:00
cycle: 103
```

## Prim: realized-volatility-term-structure
**Level:** naive → intermediate (cycle 103)  
**Project:** freqtrade | **Axis:** 14th regime axis

---

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Directional gate | None | **4h EMA200 slope positive** — MANDATORY mechanism precondition (not a filter). Coiling in downtrend = type-B contamination. Same structural role as uptrend gate in CER. |
| Compression momentum | None | **`rv_ratio.shift(N) > rv_ratio`** — ratio must be actively declining (compression deepening). Plateau contango = null signal. |
| Episode persistence | None | **5-bar below-threshold persistence** — rejects 1–2 bar ratio dips (within lognormal noise band per ABDL 2001). |
| Hot-regime ADX exception | None | **Skip suppression if `ADX_4h ≥ 35`** — trending crash ≠ oscillation; CER handles panic regime, RV prim does not suppress there. |
| BBW dual-confirmation | None | **If BBW squeeze simultaneously active → amplify BBW prim entry 1.15×** (convergence of two independent vol-compression frameworks). |
| Entry architecture | Standalone (naive) | **Meta-signal only** — amplify sister prims 1.15× (coiling) or suppress 0.85× (hot). Same architecture as funding-rate-crowding-reversal and perp-spot-basis. No standalone entries until G1–G2 validate forward return anomaly. |
| Warmup guard | None | **NaN guard on `rv_long`** before rolling ops (first 168 bars otherwise misclassified as coiling). |

---

### New Academic Anchors (5 total)

1. **Corsi (2009 JFE) — HAR-RV**: RV term structure slope is the primary statistical predictor of next-period vol regime (R²=0.47–0.71). Primary mandate for using `RV_S/RV_L` as a regime classifier.

2. **Andersen, Bollerslev, Diebold & Labys (2001 JASA)**: RV is lognormal, long-memory; slope half-life ≈ 5–10d equities → 10–20d crypto (per Katsiampa GARCH persistence). Justifies the 5-bar persistence requirement — below-threshold episodes that don't persist are noise.

3. **Bollerslev, Tauchen & Zhou (2009 RFS) — Variance risk premium**: Hot vol spike → agents overpay for variance insurance → vol mean-reverts → prices stabilise. This is the forward-return mechanism underlying the hot-regime suppression signal.

4. **Katsiampa (2017 FRL) — Bitcoin GARCH(1,1) α+β=0.968**: Extended contango persistence (10–20d) + sharper amplitude on compression break. Justifies 1.15× amplification magnitude (vs 1.05× which would be appropriate for equities).

5. **Bekaert & Hoerova (2014 JME)**: Vol term structure slope used as macro regime classifier by central banks. Cross-asset validation that this is not an equity-specific heuristic.

---

### BBW Independence Argument

Two enumerated divergence scenarios where axes disagree (theoretical; empirical G4 at sophisticated):

- **Post-crash stabilisation:** BBW neutral (30–50th pctl); `RV_ratio` still > 1.50 (24-bar crash echo hasn't decayed). RV suppresses; BBW doesn't.  
- **Low-vol drift (2019 BTC):** BBW neutral (35–45th pctl); `RV_ratio` < 0.45 (contango, uptrend active). RV amplifies; BBW silent.

Theoretical ρ estimate < 0.50. G4 empirical Spearman ρ test required at sophisticated (pass: ρ < 0.70).

---

### Blocking Gates for Sophisticated

| Gate | Criterion | Fail action |
|---|---|---|
| **G1** (BLOCKING) | Frequency scan BTC/ETH 1h 2022–2026: ≥ 15 qualifying coiling episodes/year (n ≥ 60 IS) | Collapse into BBW prim gate if n < 15/yr |
| **G2** (BLOCKING) | Mann-Whitney U p < 0.05 at 24h forward returns, coiling vs baseline uptrend | Retire amplification; meta-signal removed |
| **G3** (confirming) | Threshold requires ≤ ±0.15 adjustment across BTC/ETH/SOL/BNB | Restrict scope to BTC/ETH only |
| **G4** (confirming) | Spearman ρ(RV_coiling, BBW_squeeze) < 0.70 on BTC 1h | Collapse into BBW axis, not new axis |

---

### Bank State After Cycle 103

| Tier | Freqtrade | Polymarket | Total |
|---|---|---|---|
| Naive | 14 (all superseded) | 0 active | 14 |
| Intermediate | 1 active: **realized-volatility-term-structure** | — | 18 |
| Sophisticated | 11 (incl. anti-prim precursors) | 18 | 18 |

---

### Next Cycle Recommendation

**(A) RESEARCH-ANALYSIS** — run G1 frequency scan offline on BTC/USDT:USDT 1h data 2022–2026 with the intermediate coiling gate applied (`rv_ratio < 0.60 AND declining ≥ 3 bars AND 4h slope positive AND 5-bar persistence`). Measure: episodes/year, median duration, breakdown by year. If n ≥ 15/year confirmed → G2 Mann-Whitney U test on 12h/24h/48h forward returns. Both G1+G2 pass → intermediate confirmed for sophisticated elevation with plateau grid.

**(B) BACKTEST-PENDING** — `vwap-deviation-mean-reversion` re-backtest (blocking since cycle 63, target n ≥ 100, WR ≥ 55%, Sharpe ≥ 0.70) remains the longest-standing unexecuted test gate in the bank.
