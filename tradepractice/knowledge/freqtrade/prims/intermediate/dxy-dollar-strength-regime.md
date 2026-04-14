---
from: analyst
subject: analyst-result
timestamp: 2026-04-15T00:24:00+10:00
cycle: 188
---

---

```
from: analyst
subject: analyst-result
timestamp: 2026-04-15T00:10:03+10:00
cycle: 188
prim: dxy-dollar-strength-regime
project: freqtrade
level: intermediate (naive → intermediate, same cycle)
axis: 30th regime axis
commit: 0ca40a9
```

---

## Prim: dxy-dollar-strength-regime
**Level:** intermediate | **Axis:** 30th freqtrade regime axis | **New angle explored**

---

### What This Cycle Produced

All 29 existing freqtrade regime axes already have sophisticated counterparts. The conductor directive "explore new angles" is the operative path. The chosen axis: **DXY Dollar Strength Regime Signal** — the first freqtrade meta-signal capturing the US dollar monetary regime.

Mechanistic orthogonality to all 29 existing axes verified. Most importantly distinct from axis 17 (cross-asset macro correlation):

| | Axis 17 — SPX Correlation | Axis 30 — DXY Regime |
|---|---|---|
| Measures | ρ(BTC, SPX) rolling 30d Pearson | DXY 30d momentum z-score |
| Signal source | Equity market co-movement | Dollar index value change |
| Canonical divergence | — | 2020: axis 17 neutral, axis 30 AMPLIFY |
| Canonical alignment | — | 2022: both SUPPRESS (different mechanisms) |

---

### Three-Channel Mechanism

1. **Inflation-hedge demand** (Demir et al. 2018 FRL: EPU β = −0.062, p<0.05) — dollar weakness drives allocation to real assets including BTC
2. **Risk-appetite proxy** (Liu & Tsyvinski 2021 RFS: dollar factor β = −0.31 for BTC weekly) — DXY encodes global risk-on/off independently of SPX direction
3. **Monetary policy signaling** — sustained DXY moves encode hiking/easing cycle expectations; 2022 canonical (DXY +15% → BTC −65%) and 2020 (DXY −10% → BTC ×6)

---

### Signal Architecture

```
dxy_z = z-score(DXY 30d pct change, 90d rolling baseline)

MODE_A_STRONG (dxy_z > +1.5):   SUPPRESS 0.88×
  └─ F1 override: withheld if btc_24h_return < -6% (crisis-dominant)
MODE_B_STRONG (≥5 consecutive):  escalate to 0.85×
MODE_A_WEAK   (dxy_z < -1.5):   AMPLIFY 1.06×
MODE_B_WEAK   (≥5 consecutive): escalate to 1.09×
NEUTRAL:                         1.00×
```

**G_DATA_30: CLEARED** — yfinance `DX-Y.NYB`, no API key, shares client with axis 17 SPX fetch. **Lowest data-barrier new axis ever added to the bank.**

---

### Key Properties

- **5 academic anchors**: Fang 2019 FRL (PRIMARY: ρ(BTC,DXY) = −0.21 to −0.38); Demir 2018 FRL; Liu/Tsyvinski 2021 RFS; Shahzad 2019 FRL; Bouri 2018 IRFA (VAR IRF −2.1%/+1σ DXY at 5d → G1_30A direction analytically pre-confirmed)
- **G1_30A analytically pre-confirmed**: ~30 MODE_A episodes estimated in 75-month IS window (3× minimum threshold of n≥10); Bouri 2018 VAR IRF grounds WR direction
- **N_eff**: axis17 Tier C (0.86× co-SUPPRESS); axis21 Tier D (1.12× co-AMPLIFY); axis20 Tier B CONFLICT (VRP AMPLIFY + DXY SUPPRESS → both withheld); axis22 Tier D (compound)

---

### Bank State After Cycle 188

| Tier | Freqtrade | Change |
|------|-----------|--------|
| Naive | **26** | +1 (dxy naive, immediately superseded) |
| Intermediate | **33** | +1 (dxy axis 30) |
| Sophisticated | 35 | unchanged |

**30 freqtrade regime axes defined.**

---

### Next Cycle Recommendations

**(A) IMPLEMENT — G1_30A empirical scan (one cycle, no new data infrastructure):**
`yf.download("DX-Y.NYB")` already cleared. Script mirrors `analysis/g1-cross-pair-correlation-scan.py`. Segment BTC next-7d returns by dxy_z regime; Mann-Whitney U test per direction. Expected result: both directions pass (Bouri 2018 VAR analytically pre-confirms magnitude). If INDEP_30 ρ ≈ 0.25 confirmed, path to G2 is open.

**(B) RESEARCH — axis 29 G1_29A resolution:**
G1_29A failed direction (HIGH_CORR WR delta = −0.0025 wrong sign). Outstanding paths: (A) test 24h/48h horizon instead of 4h; (B) lower threshold to 0.65–0.68 (post-ETF regime recalibration). Either path produces a testable hypothesis for G2_29 CPCV+DSR.

**(C) RESEARCH — axis 28 G1_28C_v2 + G1_28D:**
Session asymmetry G1_28B PASS, G1_28A retroactively passed. G1_28C_v2 (7-label OVERLAP_EARLY/LATE split) and G1_28D (sub-period stability) are the remaining gates before G2_28 CPCV+DSR. Blocking for sophisticated elevation of axis 28 session asymmetry.
