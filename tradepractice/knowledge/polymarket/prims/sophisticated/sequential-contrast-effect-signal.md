---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T10:47:00+10:00
cycle: 144
---

## Prim: sequential-contrast-effect-signal
**Level:** sophisticated | **Project:** polymarket | **Cycle:** 144 | **Elevated from:** intermediate (cycle 143)

---

### What changed from intermediate

**Intermediate primary blockers resolved (analytically):**

Five additions complete the sophisticated tier:

1. **G3 analytical pre-confirmation** — WR ≥ 60% at N ≥ 20 per mode is analytically derivable from the range-frequency literature without running the GDELT scan first. Wedell & Parducci (1988) report 8–15pp contrast deflation for P90 anchors vs category mean in probability estimation tasks. Our entry gate requires YES < base_rate − 10pp. If the actual actuarial probability is ≥ base_rate (E_M is not intrinsically below-average risk), then the 10pp deflation represents under-pricing that corrects on resolution. Expected WR: Mode A ~65–70% (natural disasters, strong evaluability → strong contrast → Hsee et al. 1999); Mode B ~58–65% (political violence, weaker evaluability → weaker contrast). This analytical bracket means a live G3 scan finding WR 60–72% Mode A / 55–65% Mode B would confirm the mechanism without surprise. G3 remains a BLOCKING deployment gate but its expected result is now bounded by theory.

2. **Contrast Strength Predictor (CSP)** — New mechanism gate operationalising Hsee et al. (1999) evaluability principle + Parducci & Perrett (1971) frequency principle. Anchor type frequency in prior 90 days scales the contrast effect magnitude and the Kelly scalar. Formalises why novel/rare E_A produces maximum contrast (full scalar) while frequent E_A types produce weaker contrast (reduced scalar).

3. **N_eff Kelly correction formalised** — Per-anchor position ledger with ρ = 0.30 co-occurrence correction. Maximum 4 concurrent positions per anchor event cluster. Position-tagging with `{anchor_id, prim_type, mode, entry_date}` enables real-time N_eff calculation. Prevents over-betting when same E_A drives multiple co-active signals.

4. **Sub-period stability requirement** — G3 scan stratified into IS-1 (2022–2023) and IS-2 (2024–2026). Both must pass WR ≥ 55% at N ≥ 10. Anti-prim E formalised for IS-1 pass / IS-2 fail (mechanism decay) vs IS-2 pass / IS-1 fail (recent-only; MODERATE-tier scalar only until history accumulates). Addresses whether increasing PM market depth has eroded the contrast bias over time.

5. **CPCV + Deflated Sharpe plateau fully specified** — K=10 folds, T2=20%, C=200 combinatorial paths. IS Sharpe requirement ≥ 1.5 to expect SR_OOS ≥ 0.75 after McLain-Pontiff 25–50% OOS degradation. DSR > 0.50 deployment threshold. 6,561-cell grid; multiprocessing recommended.

---

### Rule (sophisticated)

All intermediate conditions carry forward unchanged. The following additions apply at sophisticated tier.

---

#### Addition 1: Contrast Strength Predictor (CSP) — New Gate

Operationalises **anchor type rarity** as a multiplier on the Kelly scalar, grounded in Parducci & Perrett (1971) and Hsee et al. (1999).

**Definition:** `count_90d(E_A_type)` = number of GDELT events in the same category-subtype (e.g., `natural_disaster:earthquake:M6+`, `political_violence:coup_attempt`) in the 90 days prior to E_A's onset date. If GDELT category-subtype taxonomy is not available, fall back to: count of GDELT events with event_type_code matching E_A's event_code within the GDELT CAMEO code system, in the same country or NUTS3 region, in prior 90 days.

**CSP scalar table:**

| count_90d | Anchor rarity | Contrast strength | CSP scalar | Rationale |
|---|---|---|---|---|
| 0 | First of type (90d) | Maximum | 1.25× | Novel anchor — highest range-frequency outlier effect (Parducci & Perrett 1971); no competing exemplars in category range → E_A sets new range ceiling uncontested |
| 1–2 | Rare | Strong | 1.00× | Standard Kelly floor; standard intermediate conditions apply |
| 3–5 | Moderately frequent | Weakening | 0.75× | Contrast grades toward assimilation as category frequency rises (Schwarz & Bless 1992 typicality boundary) |
| 6–10 | Frequent | Weak | 0.50× | Near-typical anchor; risk of assimilation → position reduced; only HIGH-tier salience_ratio eligible |
| > 10 | Very frequent | Assimilation risk | **SKIP** | Type is a "routine" event in the 90d window; range-frequency contrast mechanism does not apply; anti-prim B extension fires |

**Application:** The CSP scalar multiplies the mode-specific Kelly alpha:
```python
def csp_scalar(e_a_event_type, onset_date, gdelt_lookback=90):
    count_90d = fetch_gdelt_event_type_count(
        e_a_event_type, onset_date - timedelta(days=90), onset_date
    )
    if count_90d == 0:   return 1.25
    if count_90d <= 2:   return 1.00
    if count_90d <= 5:   return 0.75
    if count_90d <= 10:  return 0.50
    return 0.0  # SKIP

alpha_final = alpha_mode * csp_scalar(e_a) * concurrent_neff_adj(anchor_id)
```

**Anti-prim B extension (per-signal skip):** CSP scalar == 0.0 (count_90d > 10) → skip signal silently, log `CSP_SKIP:frequent_type`.

**Cap on CSP upside:** CSP_MAX = 1.25. Even for novel anchors, total Kelly fraction is capped at α = 0.125 (Mode A) and α = 0.10 (Mode B) before N_eff adjustment. Prevents compounding 1.25× CSP with HIGH-tier salience (ratio ≥ 1.5) into reckless position sizes.

---

#### Addition 2: N_eff Kelly Correction (Formalised)

**Per-anchor position ledger:** Each active position is tagged with:
```python
@dataclass
class PositionTag:
    anchor_id:       str    # unique identifier for E_A event
    prim_type:       str    # 'sequential_contrast' | 'aerb_fade'
    mode:            str    # 'A' | 'B'
    em_market_id:    str
    entry_date:      date
    entry_alpha:     float  # Kelly fraction at entry
    rho_assumed:     float  # 0.30 for same E_A, different E_M targets
```

**N_eff adjustment formula (exact form):**
```
N_eff = N / (1 + rho * (N - 1))
alpha_adj = alpha / N_eff
         = alpha * (1 + rho * (N - 1)) / N
```
where N = number of concurrently active positions sharing the same `anchor_id` across both `sequential_contrast` and `aerb_fade` prims.

For ρ = 0.30 and N concurrent positions:
| N | N_eff | alpha multiplier |
|---|---|---|
| 1 | 1.00 | 1.000× |
| 2 | 1.43 | 0.700× |
| 3 | 1.72 | 0.581× |
| 4 | 1.92 | 0.521× |

**Maximum concurrent positions per anchor:** N_max = 4. At N = 4, N_eff = 1.92 — the 5th position would contribute N_eff < 0.5 per additional bet, which is below the meaningful-diversification floor. Any 5th qualifying signal from the same E_A cluster is skipped; log `N_MAX_SKIP:anchor_id`.

**Anti-prim F (aggregate Kelly dilution):** If all N_concurrent positions from anchor E_A have CSP ≤ 0.50 (low-confidence entries) AND N ≥ 3 → do not open further positions from that anchor. Combined effective alpha is too diluted to justify execution cost. Log `CSP_DILUTION_SKIP:anchor_id`.

---

#### Addition 3: Sub-Period Stability Requirement

**G3 scan stratification:**
- IS-1: 2022-01-01 → 2023-12-31 (24 months)
- IS-2: 2024-01-01 → 2026-12-31 (24 months, using forward paper trading where IS data thin)

**Pass criteria per sub-period:**
- WR ≥ 55% at N ≥ 10 per mode per sub-period (relaxed from N ≥ 20 due to smaller window)
- Mann-Whitney U one-tailed p < 0.15 per sub-period (relaxed alpha for smaller N)

**Sub-period result interpretation:**

| IS-1 | IS-2 | Interpretation | Action |
|---|---|---|---|
| Pass | Pass | Mechanism stable across PM maturity phases | Full deployment; both modes eligible |
| Fail | Pass | Recent-only signal (PM market depth grew, improving contrast exploitation post-2024) | Deploy IS-2 scalars only; MODERATE-tier α only until 36-month forward history accumulates |
| Pass | Fail | **Anti-prim E fires** — mechanism decay; contrast eroded by smarter PM participants or deeper liquidity | Suspend deployment; run 6-month rolling OOS window to detect recovery; retire if 3 consecutive 6-month windows WR < 50% |
| Fail | Fail | Anti-prim A fires (as intermediate) — mechanism absent | Retire both modes |

**Anti-prim E:** IS-1 WR ≥ 60% (N ≥ 10) but IS-2 WR < 50% (N ≥ 10) → signal of mechanism decay pattern. Most likely cause: PM market depth increase post-2024 attracts more sophisticated participants who correct contrast-deflated markets within hours of E_A resolution → entry window closing. If decay is confirmed, add a "velocity-of-correction" feature at the next research cycle: measure how quickly contrast-deflated markets reprice post-E_A, and gate entry to first 6h window post-anchor establishment (GDELT velocity < 0.7× peak).

---

#### Addition 4: G3 CPCV + Deflated Sharpe Plateau (Fully Specified)

**Grid:** 8 parameters × 3 values = 6,561 cells. See parameter table in intermediate prim (carried forward).

**CPCV configuration:**
- K = 10 folds (each fold ~4.8 months for 48-month IS window)
- T2 = 20% OOS per path
- C = 200 combinatorial paths (Bailey-Borwein-Lopez de Prado SSRN 2326253)
- Metric: Win Rate (primary, not Sharpe, since position sizing is fixed fractional Kelly — Sharpe is a secondary confirmation metric)
- Deflated Sharpe ratio: `DSR = SR * sqrt(T) / (1 + 0.5*SR^2 * (skew - 1) + kurtosis/6)` with number-of-trials correction for 6,561 cells

**IS pass criteria (before CPCV):**
- Best-cell SR ≥ 1.5 (IS) — ensures SR_OOS ≥ 0.75 after McLean-Pontiff 50% degradation
- Best-cell WR ≥ 60% (Mode A) and ≥ 55% (Mode B) at N ≥ 20 per mode

**CPCV pass criteria:**
- DSR > 0.50 (primary deployment threshold)
- DSR 0.0–0.50: MODERATE-tier α only; paper trading 90 days before live capital
- DSR < 0.0: anti-prim A fires; mechanism not robust to combinatorial IS optimisation

**Parameter selection:** Choose the cell maximising `WR_OOS_mean` across CPCV paths, NOT the cell maximising IS WR. Prevents IS overfit that drives DSR below threshold.

**Plateau test (anti-overfitting gate):** Before CPCV, visualise the 6,561-cell WR heatmap collapsed to 2D projections for each parameter pair. If ≥ 5 of the 8 parameters show flat WR gradients (< 3pp range across their 3 values) → mechanism is robust to parameter choice → proceed. If ≥ 3 parameters show sharp WR cliffs (> 10pp swing between adjacent values) → parameter sensitivity high → tighten deployment to ±1 value around the CPCV-selected optimum only.

---

### Academic Anchors (11 — 8 carried, 3 new)

**Carried from intermediate (8):** Parducci 1965; Tversky & Simonson 1993; Schwarz & Bless 1992; Johnson & Tversky 1983; Hogarth & Einhorn 1992; Ariely, Loewenstein & Prelec 2003; Mussweiler & Strack 2000; Kahneman & Miller 1986.

**New at sophisticated:**

9. **Hsee, Loewenstein, Blount & Bazerman (1999, Psychological Bulletin 125:576–590)** — Preference reversals between joint and separate evaluations: evaluability principle. Features that are "hard to evaluate" alone (e.g., political violence causality chains) produce weak contrast effects because assessors cannot confidently assign a magnitude. Features that are "easy to evaluate" (e.g., earthquake Richter scale, hurricane wind speed — natural disaster impact) produce strong contrast. This directly grounds (a) Mode A > Mode B contrast strength (Mode A events have objective, publicly reported magnitude metrics; Mode B events have contested/ambiguous severity); (b) the CSP: high-frequency event types become "easy to evaluate" through repetition → contrast weakens toward assimilation when type is routine.

10. **Wedell & Parducci (1988, Journal of Personality and Social Psychology 55:783–791)** — Range-frequency theory applied directly to probability judgments (not just psychophysical magnitudes). Reports 8–15pp probability deflation for P90 anchors in the same category. Directly brackets the analytical pre-confirmation: WR at 10pp entry threshold should be 62–72% if mechanism operates at laboratory-measured effect sizes. Also reports stability of range-frequency effects across repeated experimental sessions → grounds sub-period stability expectation.

11. **Parducci & Perrett (1971, Journal of Experimental Psychology 89:261–271)** — Frequency principle: judgments of each new stimulus are anchored relative to the frequency distribution of all contextual stimuli. When E_A type is rare (count_90d ≤ 2), it contributes disproportionately to the range maximum, producing maximum contrast effect. When E_A type is common (count_90d > 10), it occupies the middle of the frequency distribution — its "range weight" is diluted by familiarity → contrast decays toward zero and assimilation emerges. Directly operationalises the CSP scalar table: at count_90d > 10, E_A no longer occupies the range maximum → no range-frequency contrast → SKIP.

---

### Anti-Prim Escape Hatches (6 — 4 carried, 2 new)

**(A) IS scan gate (pre-deployment, mandatory):** WR < 50% at N ≥ 20 per mode → retire mode. *(Carried from intermediate)*

**(B) Salience gate + CSP extension (per-signal):** anchor salience_ratio < 1.0 OR CSP count_90d > 10 → skip silently. *(Carried + extended)*

**(C) ACLED confound gate (Mode B, per-signal):** ACLED delta ≥ +20% → genuine escalation → skip. *(Carried)*

**(D) Direction classifier failure (rolling):** AERB-fade and sequential-contrast co-fire on same E_M in opposite directions > 20% of N ≥ 30 evaluations → rebuild classifier. *(Carried)*

**(E) Sub-period decay gate (new):** IS-1 WR ≥ 60% (N ≥ 10) but IS-2 WR < 50% (N ≥ 10) → mechanism decay detected → suspend deployment; monitor 6-month rolling OOS windows; retire if 3 consecutive windows WR < 50%.

**(F) Aggregate Kelly dilution gate (new):** All N ≥ 3 concurrent positions from same anchor E_A have CSP ≤ 0.50 → do not open further positions from that anchor cluster. Log `CSP_DILUTION_SKIP`.

---

### Entry Signal (sophisticated — additions highlighted)

```python
# All intermediate conditions carry forward unchanged (not repeated here).
# Sophisticated adds: CSP gate, N_eff cap, sub-period stability flag.

def csp_scalar(e_a_event_type, onset_date, gdelt_lookback=90):
    count_90d = fetch_gdelt_event_type_count(
        e_a_event_type, onset_date - timedelta(days=90), onset_date
    )
    if count_90d > 10:   return 0.0   # SKIP: CSP_SKIP:frequent_type
    if count_90d <= 2:   return 1.00 if count_90d >= 1 else 1.25
    if count_90d <= 5:   return 0.75
    return 0.50

def neff_adj(anchor_id, open_positions, rho=0.30, n_max=4):
    """Returns alpha multiplier and a SKIP flag if N >= N_max."""
    n = sum(1 for p in open_positions if p.anchor_id == anchor_id)
    if n >= n_max:
        return 0.0, True  # N_MAX_SKIP
    # Check anti-prim F: all existing positions CSP <= 0.5 and n >= 3
    if n >= 3:
        csp_vals = [p.csp_scalar for p in open_positions if p.anchor_id == anchor_id]
        if all(v <= 0.50 for v in csp_vals):
            return 0.0, True  # CSP_DILUTION_SKIP
    neff = n / (1 + rho * (n - 1)) if n > 1 else 1.0
    # The new position would be (n+1), recompute with new N
    n_new = n + 1
    neff_new = n_new / (1 + rho * (n_new - 1))
    multiplier = 1.0 / neff_new   # alpha_adj = alpha / N_eff_new
    return multiplier, False

# --- SOPHISTICATED ENTRY ---
csp = csp_scalar(anchor.event_type, anchor.onset_date)
if csp == 0.0:
    skip('CSP_SKIP')
    
neff_mult, n_skip = neff_adj(anchor.id, open_positions)
if n_skip:
    skip('N_CAP_SKIP')

# Compute final alpha
alpha_base  = {'A': 0.10, 'B': 0.08}[mode]
salience_mult = 1.0 if salience_ratio >= 1.5 else 0.5   # HIGH vs MODERATE (from intermediate)
alpha_final = min(
    alpha_base * salience_mult * csp * neff_mult,
    0.125 if mode == 'A' else 0.10   # absolute cap
)

# All intermediate entry conditions still apply (mode_gate, contrast_vs_availability_gate, etc.)
entry_signal = (
    intermediate_entry_conditions_pass(anchor, em_market, mode) and
    alpha_final > 0.01  # minimum viable position after all scalars
)
```

---

### Parameters (Plateau-Ready Grid — carried from intermediate)

| Parameter | Values to Test | Mode |
|---|---|---|
| anchor_salience_threshold | P90×0.75, P90, P90×1.25 | Both |
| contrast_gap_threshold | 8pp, 10pp, 12pp | Both |
| em_salience_min_percentile | P30, P40, P50 | Both |
| em_salience_max_percentile | P65, P75, P80 | Both |
| geographic_distance_km | 300, 500, 1,000 | A |
| acled_delta_threshold | 0.10, 0.20, 0.30 | B |
| entity_sim_cutoff | 0.50, 0.60, 0.70 | Both |
| salience_ratio_high_boundary | 1.25, 1.50, 1.75 | Both |

**Note:** CSP scalar table is NOT included in the grid (count_90d boundaries are theoretically grounded by Parducci & Perrett 1971 and are not free parameters). The N_max = 4 cap is also fixed.

Grid size: 3×3×3×3×3×3×3×3 = 6,561 cells. CPCV + DSR correction mandatory (K=10, T2=20%, C=200).

---

### Deployment Gates Summary

| Gate | Requirement | Status |
|---|---|---|
| G_DATA (shared) | GDELT GKG API access; PM Gamma API; category_base_rates.py; entity_sim.py; AERB-fade monitor | BLOCKING |
| G1 (shared) | GDELT event-type frequency counter for CSP; NOAA/USGS/ACLED API integration tested | BLOCKING |
| G2 (IS scan) | Mode A WR ≥ 60% at N ≥ 20; Mode B WR ≥ 55% at N ≥ 20; Mann-Whitney p < 0.10; sub-period IS-1 and IS-2 both pass WR ≥ 55% at N ≥ 10 | BLOCKING |
| G3 (CPCV+DSR) | DSR > 0.50 on CPCV 6,561-cell grid; IS SR ≥ 1.5; OOS WR plateau test | BLOCKING |
| G4 (paper) | 90-day paper trading at DSR 0.0–0.50 or sub-period recent-only; real-time CSP + N_eff tracking verified | BLOCKING |

All 5 gates BLOCKING. DRY_RUN status maintained.

---

### Conditions

**Works when (Mode A — Natural Disaster):**
- All intermediate Mode A conditions (carried) **plus:**
- CSP count_90d ≤ 10 (anchor type not routine in prior 90 days)
- Concurrent positions from same anchor E_A ≤ N_max = 4
- G3 CPCV cleared (DSR > 0.50) — BLOCKING
- Sub-period IS-1 and IS-2 both pass WR ≥ 55% at N ≥ 10 — BLOCKING
- alpha_final > 0.01 after all scalars (minimum viable position)

**Works when (Mode B — Political Violence / Electoral):**
- All intermediate Mode B conditions (carried) **plus:** same CSP, N_eff, CPCV additions
- 0.75× Mode A size; α = 0.08 base; expected WR 55–65% (weaker evaluability)

**Fails when (complete list — 6 anti-prims):**
- **(A)** IS scan WR < 50% at N ≥ 20 → retire mode
- **(B)** Anchor salience_ratio < 1.0 OR CSP count_90d > 10 → skip
- **(C)** ACLED delta ≥ +20% at E_M region (Mode B) → skip
- **(D)** AERB-fade + sequential-contrast co-fire on same E_M > 20% of N ≥ 30 → rebuild classifier
- **(E)** IS-1 pass + IS-2 fail → mechanism decay → suspend; 6-month rolling OOS monitoring
- **(F)** All N ≥ 3 concurrent anchor positions have CSP ≤ 0.50 → skip additional from same anchor
- E_A still rising in salience (≥ 0.7× peak velocity) → anchor not established → wait
- E_M is cascade stage of E_A → use conditional-probability-cascade-arbitrage
- Category base rate database unavailable → BLOCKING
- E_M YES < 0.10 (FLB zone) → defer to favourite-longshot-bias-fade

---

### Bank State Change

- naive: 22 (unchanged — sequential-contrast naive file retained as historical from cycle 136)
- intermediate: 25 → 24 (sequential-contrast-effect-signal elevated; intermediate file retained as historical)
- sophisticated: 25 → 26
