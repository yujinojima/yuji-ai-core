---
from: analyst
subject: analyst-result
timestamp: 2026-04-15T00:10:03+10:00
cycle: 188
prim: dxy-dollar-strength-regime
project: freqtrade
level: naive
axis: 30th regime axis
signal-class: dollar monetary regime (meta-signal — no standalone entries)
---

> **SUPERSEDED by intermediate** — see intermediate/dxy-dollar-strength-regime.md (cycle 188)

## Prim: dxy-dollar-strength-regime
**Level:** naive (superseded by intermediate, same cycle)
**Axis:** 30th freqtrade regime axis
**Type:** meta-signal modifier (no standalone entries)

---

### Naive Rule

```
DXY (US Dollar Index) 30d percentage change z-score (rolling 90d):
  dxy_z > 0 (dollar strengthening)   → suppress sister prim longs 0.90×
  dxy_z < 0 (dollar weakening)       → amplify sister prim longs 1.10×
```

**Data source:** yfinance `DX-Y.NYB` (public, no auth; same client as axis 17 SPX)

**Mechanism (naive):** Bitcoin's inflation-hedge narrative creates a systematic inverse
relationship with the US dollar. When the dollar strengthens, demand for alternative stores
of value falls; when the dollar weakens, demand rises.

**Limitations at naive tier:**
- No z-score threshold — fires continuously on any direction (too noisy)
- No magnitude calibration — every basis-point change treated equally
- No distinction between spike (sudden shock) and sustained trend (regime shift)
- No academic confirmation of threshold levels
- No independence check from SPX correlation (axis 17)
- Modifier levels (0.90×/1.10×) are uncalibrated practitioner heuristics
- Does not account for dollar strength during coordinated risk-off (ρ(DXY, BTC) can be positive in acute crashes)

**Failure modes (5 identified):**
1. **F1 — Acute risk-off conflation**: During sudden market crashes, DXY may rise AND BTC falls simultaneously (both risk-off and dollar strength → correct suppress signal, but mechanism is macro fear, not dollar demand). Naive prim cannot distinguish.
2. **F2 — Threshold ambiguity**: Any dxy_z ≠ 0 fires; most days show trivial dollar movement that has no meaningful BTC relationship.
3. **F3 — Lag ambiguity**: BTC-DXY relationship operates at days-to-weeks, not intraday; naive has no lag model.
4. **F4 — Independence from axis 17 unverified**: SPX correlation regime (axis 17) already captures some macro state — naive adds noise if ρ(dxy_z, axis17_rho) ≥ 0.70.
5. **F5 — Single-direction bias**: ρ(BTC, DXY) is on average negative but has sub-periods of positive correlation (2022 crash); naive applies flat modifier in all conditions.

---

**Superseded by intermediate (cycle 188):** two-mode threshold architecture, academic mechanistic grounding, N_eff formalisation, G1 gate protocol.
