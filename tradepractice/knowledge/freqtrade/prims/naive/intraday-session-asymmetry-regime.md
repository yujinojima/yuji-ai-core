---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T16:20:29+10:00
cycle: 174
---

---

```
from: analyst
subject: analyst-result
timestamp: 2026-04-14T17:30:00+10:00
cycle: 174
```

---

**Cycle 174 — RESEARCH — Complete**

---

## Prim: intraday-session-asymmetry-regime
**Level:** naive → **intermediate** | **Axis:** 28 | **Project:** freqtrade | **Commit:** `47d56f3`

---

### What was produced

**Intermediate Rule — Session Scalar (DST-aware, prim-class-routed):**

```
session_deviation:   OVERLAP +0.10× | NY +0.08× | LONDON 0.00× | ASIAN/DEAD −0.08× | WEEKEND 0.00×
prim-class weight:   Class A (MR) → 1.00× | Class B (momentum) → ADX-scaled 0.85/0.50/0.25×
DOW multiplier:      Monday 1.025× | Friday 0.975× | Tue–Thu 1.000×
pair discount:       BTC 1.00× | ETH 0.90× | other 0.75×
```

**Five advances over naive (cycle 172):**

| # | Advance | Mechanism |
|---|---------|-----------|
| 1 | DST-aware classification via `zoneinfo` | Fixed ±1h misclassification for ~180d/year (US/EU clock shifts) |
| 2 | OVERLAP as distinct sub-session 1.10× | London + NY desks simultaneously active = double institutional clustering (Admati-Pfleiderer 1988) |
| 3 | ADX prim-class routing | In strong trends (ADX>35), momentum prims receive 0.25× weight → converge to 1.00× (trend dominates session) |
| 4 | Day-of-week modulation | Monday premium +2.5% on deviation; Friday reduction −2.5% (Caporale/Plastun 2019; Aharon/Qadan 2019) |
| 5 | Pair discount | ETH 0.90×; other 0.75× (BTC has strongest institutional session identity) |

---

### New academic anchors at intermediate (2 additions)

| Source | Finding |
|--------|---------|
| **Aharon & Qadan (2019, Finance Research Letters)** | BTC GARCH-M 2013–2018: Monday premium + negative Friday drift both p<0.10. Independent DOW confirmation beyond Caporale/Plastun. |
| **Heston, Korajczyk & Sadka (2010, Journal of Finance)** | Institutional volume clusters at session opens. Overlapping sessions (London + NY simultaneously) create double-peak pattern — mechanistic ground for OVERLAP 1.10× scalar. |

---

### Gate status after cycle 174

```
G_DATA_28 / G_DATA_28B / G_DATA_28C  ← ALL CLEARED (UTC clock + ADX + OHLCV)
G1_28A  NY+OVERLAP vs ASIAN WR Δ≥+2pp   ← FIRST BARRIER (OHLCV only; no API key)
G1_28B  Monday vs Tue–Thu Δ≥+0.5pp      ← runs on same G1_28A dataset
G1_28C  OVERLAP WR ≥ NY WR confirmed    ← runs on same G1_28A dataset
INDEP_28  all ρ<0.30 empirical          ← analytical (not blocking)
G2_28   24-cell CPCV+DSR                ← blocking; requires G1 first
```

G1_28A is the **cheapest gate in the entire freqtrade bank**: pure OHLCV, no API key, no external service. Script to create: `analysis/g1-session-asymmetry-scan.py`.

---

### Bank state after cycle 174

| Tier | Freqtrade | Delta |
|------|-----------|-------|
| Naive | **23** | −1 (axis 28 elevated) |
| Intermediate | **31** | +1 (axis 28 added) |
| Sophisticated | 32 | unchanged |

**28 freqtrade regime axes defined.**

---

### Next cycle recommendations

**(A) IMPLEMENT (highest priority) — G1_28A session WR scan:**
Create `analysis/g1-session-asymmetry-scan.py`. Pull BTC/USDT 1h OHLCV 2020–2024 (already available locally or from Binance public REST). Label each bar via `classify_session()`. Compute next-4h log return per session label. Mann-Whitney U test (NY+OVERLAP vs ASIAN). Target: WR Δ ≥ +2pp, p<0.10. G1_28B and G1_28C run on the same dataset at zero additional cost.

**(B) RESEARCH — sophisticated elevation path:**
Five items remain for sophisticated elevation (documented in prim file): G1 empirical confirmation, ETH pair-specific IS calibration, OVERLAP sub-window split (OVERLAP_OPEN vs OVERLAP_CLOSE), per-signal-type IS calibration (Class A split by signal type), and seasonal macro-regime stability test.

**(C) RESEARCH — new freqtrade axis 29:**
With 31 intermediate and 32 sophisticated, the naive tier is now thin at 23. Consider whether any structural gap remains in the 28-axis regime coverage. Candidates: liquidity depth stratification (bid-ask spread regime — not captured by OBI or CVD), or a cross-exchange basis arbitrage signal distinct from axis 13 (perp-spot basis).
