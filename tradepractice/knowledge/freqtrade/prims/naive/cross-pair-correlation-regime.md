---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T21:20:47+10:00
cycle: 182
---

---

**Cycle 182 — RESEARCH — Complete**

---

## Prim: cross-pair-correlation-regime
**Level:** naive → **intermediate** | **Axis:** 29 | **Project:** freqtrade | **Commit:** `e8a327e`

---

### What was produced

**7 intermediate-tier advances over naive:**

1. **Two-mode architecture** — HIGH_CORR (Mode A suppress) and LOW_CORR (Mode B amplify) formalized as distinct modes with sub-conditions; NORMAL band returns neutral.

2. **Refined scalars** — Mode A: ETH 0.88× / SOL·BNB 0.83× (from 0.90×/0.85×); ADX-attenuated trending variants (0.92×/0.87×). Mode B: ETH 1.05× / SOL·BNB 1.04× (from 1.04×/1.03×).

3. **DCC-GARCH framing** — Rolling 30d Pearson reframed as DCC-GARCH regime approximation (Engle 2002 JBES). H1 hypothesis (≥ 85% regime match vs full DCC) is testable in G2_29.

4. **ADX trending-regime routing** — In HIGH_CORR + ADX > 30 + EMA aligned: suppress attenuated per Admati & Pfleiderer (1988) institutional flow. In LOW_CORR + ADX > 35: amplify zeroed (trending idiosyncratic = momentum chasing risk).

5. **Dynamic N_eff propagation formalized** — In HIGH_CORR: `rho_propagation = rho_avg × 0.85` distributes upward to all co-active axis pairs' static ρ estimates via `effective_rho_ij = max(static_rho_ij, rho_propagation)`. First bank mechanism making N_eff regime-conditional in real-time.

6. **Full orthogonality table** — ρ estimates and Tier assignments for axes 5, 7, 11, 14, 20, 25; AP_C trigger (ρ(axis29, axis5) ≥ 0.70 → merge into axis 5, retire axis 29).

7. **FM taxonomy** — 6 failure modes including FM3 stablecoin depeg gate (BTC_24h < −8% → suppress Mode B) and FM6 halving window filter (±20d → neutral). Implementation: `CorrRegimeStateIntermediate` class.

---

### Bank state

| Tier | Count | Delta |
|---|---|---|
| Naive | **24** | −1 (axis 29 elevated) |
| Intermediate | **32** | +1 (axis 29 added) |
| Sophisticated | 34 | — |

---

### Next cycle options

**(A) IMPLEMENT — G1_29A scan** (`analysis/g1-cross-pair-correlation-scan.py`): single run resolves all 4 G1 gates; < 2 min on local OHLCV; zero external data dependency.

**(B) RESEARCH — Axis 14 sophisticated elevation** (realized-volatility-term-structure): highest-readiness intermediate→sophisticated candidate; G1 analytically pre-confirmed; IS CPCV+DSR protocol specified; no data barriers.

**(C) IMPLEMENT — Axis 28 G1_28C_v2 + G1_28D**: update session-asymmetry scan with OVERLAP_EARLY/LATE split; run sub-period stability (2022/2023/2024+ independently) — blocking for G2_28 CPCV+DSR.
