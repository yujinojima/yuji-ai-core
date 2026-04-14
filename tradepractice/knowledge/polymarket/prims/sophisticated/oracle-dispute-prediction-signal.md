---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T21:37:49+10:00
cycle: 183
---

---

**Cycle 183 — RESEARCH — Complete**

---

## Prim: oracle-dispute-prediction-signal
**Level:** sophisticated | **Elevated from:** intermediate (cycle 180) | **Project:** polymarket

---

### Four Sophisticated Upgrades

**1. CPCV+DSR 9-Cell OOS Validation Framework**

Mode A plateau: LLM_tier ∈ {0.65, 0.72, 0.80} × DTE_sub ∈ {2–4, 4–7, 7–10} = 9 cells. K=5 folds, T2=0.20, C=100 LH paths; 7d purge + 48h embargo. DSR ≥ 0.50 centroid (Mode A × DTE 4–7 × LLM 0.72); SR_IS floor 0.80 (reflects honest thin-edge expectation). Floor α: 0.05 Mode A / 0.04 Mode B until G_CPCV cleared. Three anti-prims: AP-1 (centroid DSR ≤ 0 → retire Mode A); AP-2 (≥5/9 cells fail → retire prim); AP-3 (live WR < 0.48 @ N_eff ≥ 15 → suspend Mode A). Bailey-Borwein-López de Prado (SSRN 2326253, 2015).

**2. DTE Sub-Period Stability via Cramton-Schwartz**

G_DTE gate: r_DTE = P(dispute|DTE 2–5) / P(dispute|DTE 6–10) at N≥15 per window (from G_DATA_UMA). r_DTE ≥ 1.30 + CPCV sub-period stability → tighten Mode A DTE_max 10→7. r_DTE < 1.0 → AP-CRAM_INVERTED (restrict to DTE 5–10 only). Non-blocking; DTE_PRIOR_ONLY tag until cleared. Grounded in Cramton & Schwartz (1991) strategic-delay model.

**3. Framing Lift Quantification**

G_FRAME: framing_lift = mean(YES_VWAP_24h) − 0.50 from N≥30 qualifying markets; bootstrap 95% CI. lift ≥ +0.02 → Mode A α 0.10→0.115 (cap 0.12), Mode B 0.07→0.082 (cap 0.085); EV_adj = EV_base + lift × (1 − P_dispute). AP-FRAME_INV: lift < −0.02 → directional NO bias removed + LLM gate compensator +0.05. Non-blocking fallback framing_lift = 0. Kahneman & Tversky (1979) framing + Ariely et al. (2003) arbitrary coherence.

**4. N_eff Correlated-Position Kelly Scaling**

OracleDisputeCorrelationTracker. N_eff = N / (1 + (N−1) × ρ̄); α_adj = α × (N_eff/N). ρ priors: same-category 0.35, cross-category 0.15, same-event 0.65, vs RCA **Tier D = 0.05** (independent; non-overlapping timing formalised). N_max = 4 concurrent; event-cycle cap N_max = 2 same-event. EH-5: N_eff ≤ 1.2 → ODPS_CAT_SATURATED. MacLean & Thorp (2011).

---

**Gate status:** G_LLM + G_DATA_UMA + G_CPCV blocking; G_DTE + G_FRAME + G_RHO non-blocking (fallbacks active). N=0 own-data. DRY_RUN until G_LLM ∧ G_DATA_UMA cleared.

**Bank state:** naive 23 | intermediate 24 | sophisticated **27** (+1)

**14 sources total** (+4 vs intermediate: Bailey-Borwein-López de Prado 2015, Kahneman & Tversky 1979, Ariely et al. 2003 QJE, MacLean & Thorp 2011)
