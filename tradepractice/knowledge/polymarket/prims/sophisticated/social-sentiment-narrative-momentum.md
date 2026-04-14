---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T16:02:49+10:00
cycle: 173
---

---

**Cycle 173 — RESEARCH — Complete**

---

## Prim: social-sentiment-narrative-momentum
**Level:** sophisticated (elevated) | **Project:** polymarket | **Axis:** 27 | **Cycle:** 173

---

### What was produced

**Elevation path:** intermediate (cycle 169, freqtrade-framed) → sophisticated (cycle 173, full polymarket reconstruction)

The intermediate prim had the right behavioral mechanism — availability heuristic mispricing from narrative extremes — but used the wrong frame (AMPLIFY/SUPPRESS on crypto price signals rather than Kelly-fraction PM positions).

---

### Five structural additions

**1. Event-level entity matching (BLOCKING)**
GDELT GKG actor/theme tags → PM market title cosine similarity ≥ 0.75. This is the primary infrastructure gate — no signal fires without confirming the social narrative being measured actually maps to the PM market's underlying event.

**2. Multi-source narrative composite**
```
narrative_z = 0.50 × GDELT_AvgTone_z + 0.30 × Twitter_mention_z + 0.20 × Reddit_submission_z
```
All components z-scored vs 30-day rolling baseline. Fallback rules for each source.

**3. Consensus anchor gate**
Signal requires `yes_price − consensus_prior ≥ 5pp` (Mode A) or `prior − yes_price ≥ 3pp` (Mode B). Consensus = Metaculus median (≥3 forecasters) or category-IPW base rate fallback. Prevents firing on markets with no base-rate anchor.

**4. CPCV + Deflated Sharpe (36-cell)**
3 × `narrative_z` thresholds × 3 × `price_gap` floors × 4 CPCV folds. IS Sharpe ≥ 0.90 (Mode A) / ≥ 0.80 (Mode B). DSR ≥ 0.50 mandatory.

**5. N_eff Tier A correction**
ρ(SSNM, social-attention-divergence) expected 0.55–0.65 → Tier A rule: `max(α_SSNM, α_SAD)` when both fire, no compounding.

---

### Critical distinction from social-attention-divergence-signal (axis 23)

| | SAD | SSNM |
|---|---|---|
| Trigger | Volume spike ≥5× composite | Sentiment z-extreme (contrarian) |
| Mechanism | Information diffusion lag | Availability heuristic bias |
| Direction | Momentum (follow) | Contrarian (fade) |
| Horizon | 4–8 hours | 7–30 days |
| Comparison | None | vs consensus prior |

---

### Bank state after cycle 173

| Tier | Polymarket | Freqtrade |
|------|-----------|-----------|
| Naive | 22 | 23 |
| Intermediate | **22** (−1) | 27 |
| Sophisticated | **26** (+1) | 32 |
