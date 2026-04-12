---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T09:19:12+10:00
cycle: 143
---

## Prim: sequential-contrast-effect-signal
**Level:** intermediate | **Project:** polymarket | **Cycle:** 143 | **Elevated from:** naive (cycle 136)

---

### What changed from naive

**Naive primary blockers resolved:**

- **Limitation #1 (information vs contrast confound):** The naive prim flagged this as the primary blocker but provided no structural resolution beyond the flat ACLED/NOAA stability guard. The intermediate elevation introduces mode-specific external condition-stability gates per category type — NOAA/USGS for natural disasters (Mode A), ACLED delta + distinct-trigger for political violence/electoral (Mode B).

- **Limitation #4 (mechanism direction ambiguity):** The naive prim could not determine when E_A causes contrast deflation on E_M (→ BUY YES) vs availability inflation (→ BUY NO via AERB-fade). The intermediate elevation formalises the contrast vs availability direction classifier: AERB-fade silence on E_M confirms contrast mechanism; AERB-fade firing BUY NO on E_M signals availability dominates → skip sequential-contrast on E_M.

**Three upgrades at intermediate:**
1. **Two-mode condition-stability structure** — separates natural disasters (Mode A: geographically bounded actuarial risk, lowest confound) from political violence/electoral (Mode B: moderate confound, ACLED-gated). Distinct spike thresholds, hold periods, and Kelly scalars per mode. Mirrors AERB-fade cycle 76 intermediate architecture.
2. **Contrast vs availability direction classifier** — formalises when sequential-contrast fires vs when AERB-fade governs the same E_M market. Grounded in Schwarz & Bless (1992) outlier-vs-typical E_A condition and Mussweiler & Strack (2000) selective accessibility model.
3. **IS backtest protocol** — GDELT GKG 2022–2026 + PM Gamma API resolution scan; N ≥ 20 qualifying (E_A, E_M) pairs per mode; WR ≥ 60% YES resolution validates mechanism; WR < 50% → anti-prim A; Mann-Whitney U p < 0.10.

---

### Rule (intermediate)

#### Mode A — Natural Disaster (LOW confound)

**Setup:** High-salience natural disaster anchor event E_A resolves, establishing a new dramatic reference for the category.

**Trigger:** GDELT anchor_article_count_48h > P90_natural_disaster (~1,200/48h preliminary) AND anchor resolved against PM consensus ≥ 55% (surprised PM) AND same GDELT `natural_disaster` category AND E_M GDELT article_count_48h ∈ [P40, P75] for natural_disaster category (moderate salience — overshadowed but present) AND E_M YES < category_base_rate − 10pp AND geographic distance from E_A epicentre to E_M entity location > 500km AND NOAA active alert at E_M location severity < MODERATE (72h) AND USGS magnitude < 4.5 at E_M location (72h) AND entity_sim(E_A, E_M) < 0.70 AND E_M YES ∈ [0.12, 0.65] AND E_M resolution > 14 days AND E_M liquidity ≥ $5k AND bid-ask ≤ $0.05 AND anchor E_A GDELT velocity declining (< 0.7× peak — anchor established, not still rising) AND contrast_vs_availability_gate(E_M) == 'CONTRAST'.

**Reaction (cognitive):** Parducci (1965) range-frequency recalibration — E_A expands the upper bound of the experiential range for the natural_disaster category. E_M, having moderate salience, is deflated relative to the new range ceiling. Geographic distance (> 500km) and NOAA/USGS stability gates confirm no genuine causal link between E_A and E_M.

**Action:** BUY YES on E_M.

**Exit:** 14-day max hold OR gap to category_base_rate closes within 5pp OR anchor GDELT velocity < 0.3× peak (anchor fully decayed) OR E_M resolution within 3 days.

**Sizing:** Fractional Kelly α = 0.10 (uncalibrated mandatory floor). HIGH-tier anchor (GDELT salience_ratio ≥ 1.5): full α. MODERATE-tier anchor (ratio 1.0–1.5): 0.5× position scalar (Schwarz & Bless 1992 assimilation-contrast boundary ambiguous below ratio 1.5).

---

#### Mode B — Political Violence / Electoral (MODERATE confound)

**Setup:** High-salience political violence or electoral anchor event E_A resolves.

**Trigger:** Same structure as Mode A but: GDELT anchor_count > P90_category (political_violence ~800/48h; electoral ~1,500/48h preliminary) AND ACLED event rate at E_M entity region delta < +20% (7-day rate post-anchor vs 30-day baseline — security conditions stable at E_M location) AND anchor primary_actor ≠ E_M entity primary_actor AND anchor conflict_system_id ≠ E_M entity conflict_system_id (structurally distinct conflict network — not cascade) AND E_M YES < category_base_rate − 10pp AND E_M resolution > 21 days AND same entity_sim, liquidity, bid-ask, velocity, contrast_vs_availability_gate requirements.

**Reaction (cognitive):** Same contrast deflation mechanism as Mode A. ACLED delta < +20% and distinct-actor gate confirm E_M region security conditions are unchanged — the E_M market is NOT being correctly repriced on new information.

**Action:** BUY YES on E_M at 0.75× Mode A size.

**Exit:** 10-day max hold (shorter than Mode A — political narratives shift faster) OR gap to base rate closes within 6pp OR ACLED delta spikes above +20% post-entry (genuine conditions change → exit immediately) OR E_M resolution within 3 days.

**Sizing:** Fractional Kelly α = 0.08 (reduced for moderate confound). MODERATE-tier anchor: additional 0.5× scalar (total 0.75 × 0.5 = 0.375× Mode A for ambiguous cases).

---

#### Contrast vs Availability Direction Classifier

The same anchor event E_A can produce two opposite signals on the same E_M market:
- **AERB-fade** fires BUY NO when E_M is OVER-priced due to availability inflation (E_A's salience dragged E_M probability up)
- **Sequential-contrast** fires BUY YES when E_M is UNDER-priced due to contrast deflation (E_A made E_M appear "small")

These are mutually exclusive predictions on the same E_M market. The classifier uses AERB-fade's signal state as the discriminator:

```python
def contrast_vs_availability_gate(e_m_market, aerb_fade_signals, anchor_gdelt_count, p90_threshold):
    """
    Returns 'CONTRAST', 'CONTRAST_UNCERTAIN', or 'AVAILABILITY'.
    
    Logic:
    1. If AERB-fade is firing BUY NO on e_m_market from the same E_A:
       → availability dominates → skip sequential-contrast → 'AVAILABILITY'
    2. If AERB-fade is NOT firing on e_m_market:
       → contrast mechanism active → proceed → 'CONTRAST' or 'CONTRAST_UNCERTAIN'
    3. Salience tier determines certainty:
       HIGH (ratio ≥ 1.5): outlier E_A → contrast (Schwarz & Bless 1992)
       MODERATE (ratio 1.0–1.5): typical E_A → ambiguous → 0.5× scalar
    """
    aerb_firing_on_em = any(
        s.market_id == e_m_market.id and s.direction == 'NO'
        for s in aerb_fade_signals
    )
    if aerb_firing_on_em:
        return 'AVAILABILITY'

    salience_ratio = anchor_gdelt_count / p90_threshold
    if salience_ratio >= 1.5:
        return 'CONTRAST'          # outlier anchor → full position
    elif salience_ratio >= 1.0:
        return 'CONTRAST_UNCERTAIN'  # proceed at 0.5× scalar
    else:
        return 'AVAILABILITY'      # below P90 — anti-prim B, no signal
```

**Why AERB-fade silence on E_M is the contrast indicator:** AERB-fade fires when E_M is over-priced (availability lifted it). Sequential-contrast fires when E_M is under-priced (contrast deflated it). When AERB-fade sees no signal on E_M, the market has NOT been inflated by availability — it is the type of market that has been overlooked and possibly deflated relative to its base rate.

**N_eff Kelly reduction when both prims active from same E_A on DIFFERENT markets:** ρ ≈ 0.30 (shared trigger, different targets). Apply N_eff correction: `alpha_adj = alpha / sqrt(1 + 0.30 * (N_concurrent - 1))` where N_concurrent = number of co-active positions from the same E_A across both prims.

---

### Parameters (Plateau-Ready Grid)

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

Grid size: 3×3×3×3×3×3×3×3 = 6,561 cells. **CPCV + Deflated Sharpe correction mandatory** when optimising (Bailey-Borwein-Lopez de Prado SSRN 2326253).

---

### IS Backtest Protocol (G3)

**Source:** GDELT GKG 2022–2026 archive + PM Gamma API resolution database.

**Method:**
1. Identify all anchor events E_A meeting HIGH-tier criteria (GDELT count > P90 category-specific) within the IS window.
2. For each E_A, scan PM active markets within 7 days for E_M in the same category with: (a) GDELT salience ∈ [P40, P75]; (b) entity_sim(E_A, E_M) < 0.70; (c) YES < category_base_rate − 10pp; (d) Mode A: geographic distance > 500km + NOAA/USGS gates; Mode B: ACLED delta < 20% + distinct actor gate.
3. Apply contrast_vs_availability_gate — exclude E_M markets where AERB-fade also fires BUY NO (availability supersedes).
4. Check resolution: did E_M markets meeting all entry criteria resolve YES?
5. Compute WR per mode separately.

**Pass criteria:**
- WR ≥ 60% at N ≥ 20 qualifying pairs per mode → mechanism validated; unlock live paper trading
- WR 50–59% at N ≥ 20 → borderline; MODERATE-tier only (full position only for HIGH-tier anchors)
- WR < 50% at N ≥ 20 → anti-prim A → retire mode

**Mann-Whitney U test:** WR vs null WR = 0.50, one-tailed, p < 0.10.

---

### Academic Anchors (8 — 6 carried, 2 new)

**Carried from naive:**
1. **Parducci (1965, Psychological Review)** — Range-frequency theory: judged magnitudes are determined by where a stimulus falls in the range AND frequency distribution of contextual stimuli. E_A expands range ceiling for the category; E_M is deflated relative to this new ceiling. Foundational mechanism.
2. **Tversky & Simonson (1993, Psychological Review)** — Context effects in choice: options appear less attractive when high-quality comparisons are available. E_M appears less probable when dramatic E_A is salient. Corroborates range-frequency mechanism at the choice/judgment level.
3. **Schwarz & Bless (1992, Personality and Social Psychology Bulletin)** — Assimilation vs contrast: salient OUTLIER exemplars trigger contrast (E_M deflated); salient TYPICAL exemplars trigger assimilation (E_M inflated). Grounds salience_ratio ≥ 1.5 (HIGH) as the contrast-dominant boundary; MODERATE-tier ambiguous.
4. **Johnson & Tversky (1983, JPSP)** — Cross-category mood and salience contamination; E_A affects E_M through affect and salience channels. Grounds why same-category contrast operates across geographically distinct events.
5. **Hogarth & Einhorn (1992, Psychological Review)** — Belief-adjustment model: sequential information processing anchors on prior extreme data points; subsequent adjustments are insufficient. E_A provides a dramatic prior; E_M's probability is adjusted insufficiently upward from the implicitly deflated anchor.
6. **Ariely, Loewenstein & Prelec (2003, QJE)** — Coherent arbitrariness: arbitrary first anchors have lasting, coherent effects on subsequent probability estimation. E_A's dramatic resolution establishes an implicit probability benchmark; E_M is priced to appear "coherently smaller."

**New at intermediate:**
7. **Mussweiler & Strack (2000, JPSP)** — Selective accessibility model: extreme standards (P90 outliers) activate knowledge that is *inconsistent* with the target → contrast effect. Typical standards (within normal range) activate *consistent* knowledge → assimilation. Grounds why P90 threshold is the assimilation/contrast boundary specifically: below P90, the anchor is "typical" enough that assimilation may dominate. Corroborates Schwarz & Bless mechanism at the information-processing level.
8. **Kahneman & Miller (1986, Psychological Review)** — Norm theory: unusual events construct their own norm; E_M is evaluated against E_A as a local norm rather than against the category base rate. Explains why contrast deflation persists: E_M cannot "escape" the E_A norm while E_A is recent and salient. Grounds the 7-day anchor window and the anchor velocity decay exit condition.

---

### Anti-Prim Escape Hatches (3 formal)

**(A) IS scan gate (pre-deployment, mandatory):**
GDELT 2022–2026 + PM Gamma API resolution scan returns WR < 50% at N ≥ 20 qualifying (E_A, E_M) pairs per mode → contrast deflation mechanism absent or confound dominates in observed PM data → retire that mode. This is the primary epistemic escape hatch: it directly tests whether the Parducci cognitive mechanism produces YES-biased outcomes in real PM markets.

**(B) Salience gate (per-signal):**
E_A salience_ratio < 1.0 (anchor count fails to reach P90 threshold) → E_A is not a qualifying outlier → no contrast trigger → skip silently. Fires as a per-signal skip, not a mode retirement.

**(C) ACLED confound gate (Mode B, per-signal):**
Mode B ACLED delta at E_M entity region ≥ +20% post-anchor → genuine security conditions deterioration → information confound; skip signal. Fires as a per-signal skip with ACLED_CONFOUND_SKIP log entry.

**Anti-prim D (direction classifier failure, rolling):**
If AERB-fade and sequential-contrast co-fire on the SAME E_M market in opposite directions (AERB fires BUY NO; contrast fires BUY YES on same E_M) more than 20% of evaluated pairs at N ≥ 30 → the direction classifier partition is broken in practice → rebuild classifier using GDELT salience tier as hard separation (HIGH-tier E_A → sequential-contrast exclusive; MODERATE-tier → AERB-fade exclusive on same E_M).

---

### Entry Signal (combined)

```python
# Mode A: natural disaster, low confound
def mode_a_gate(anchor_event, em_market):
    distance_km = haversine(anchor_event.coordinates, em_market.entity_coordinates)
    noaa_alert   = fetch_noaa_alerts(em_market.entity_coordinates, window_h=72)
    usgs_alert   = fetch_usgs_alerts(em_market.entity_coordinates, window_h=72)
    return (
        distance_km > 500 and
        noaa_alert.severity < 'MODERATE' and
        usgs_alert.magnitude < 4.5
    )

# Mode B: political violence/electoral, moderate confound
def mode_b_gate(anchor_event, em_market):
    acled_7d  = fetch_acled_events(em_market.entity_region, days_back=7)
    acled_30d = fetch_acled_events(em_market.entity_region, days_back=30)
    baseline  = acled_30d / (30 / 7)
    acled_delta = (acled_7d - baseline) / max(baseline, 1)
    distinct = (
        anchor_event.primary_actor != em_market.entity_primary_actor and
        anchor_event.conflict_system_id != em_market.entity_conflict_system_id
    )
    return acled_delta < 0.20 and distinct

CONTRAST_GAP_PP = {'A': 0.10, 'B': 0.10}   # pp below category base rate
MIN_RESOLUTION  = {'A': 14, 'B': 21}         # days remaining

entry_signal = (
    anchor_gdelt_count > P90_category and
    anchor_surprise_gate and                          # resolved against >= 55% prior PM prob
    em_salience_in_range(P40, P75) and                # moderate salience
    yes_price < category_base_rate - CONTRAST_GAP_PP[mode] and
    yes_price in [0.12, 0.65] and
    entity_sim(anchor, em_market) < 0.70 and
    gdelt_velocity < 0.70 * gdelt_velocity_peak and  # anchor established, not rising
    resolution_days_remaining > MIN_RESOLUTION[mode] and
    mode_gate(anchor_event, em_market) and            # mode-specific confound gate
    contrast_vs_availability_gate(em_market, aerb_fade_signals, anchor_gdelt_count, P90) == 'CONTRAST'
)
```

---

### What Remains for Sophisticated

1. **G3 historical scan completion** — must demonstrate WR ≥ 60% YES resolution at N ≥ 20 qualifying (E_A, E_M) pairs per mode before sophisticated elevation. Stratify WR by mode and salience tier to validate Schwarz-Bless prediction (HIGH-tier WR > MODERATE-tier WR).

2. **N_eff Kelly correction for concurrent AERB-fade positions** — when both prims are active from the same E_A on different E_M markets simultaneously, ρ ≈ 0.30. Sophisticated formalises: `alpha_adj = alpha / (1 + 0.30 × (N_concurrent − 1))` with per-anchor position tracking.

3. **Salience tier empirical calibration** — P40/P75/P90 thresholds derived from GDELT GKG category distribution (2022–2026 archive). The salience_ratio ≥ 1.5 HIGH boundary follows Parducci & Perrett (1971) and Wedell & Parducci (1988) theoretically but requires IS validation: G3 scan stratified by salience_ratio tier, confirming WR(HIGH) > WR(MODERATE).

4. **Contrast strength predictor (Schwarz-Bless outlier gate)** — contrast is strongest when E_A is perceived as a category OUTLIER (rare type, not common). Sophisticated: add "anchor type frequency" gate — if E_A is a category-common type (e.g., monthly data release), contrast weakens toward assimilation; if E_A is category-rare (e.g., major unexpected conflict outbreak), contrast is strongest. Operationalises Hsee et al. (1999 Psychological Bulletin) evaluability principle.

5. **CPCV + Deflated Sharpe plateau** — 8-parameter grid optimisation (see parameters table); mandatory before live capital deployment.

---

### Conditions

**Works when (Mode A — Natural Disaster):**
- HIGH-tier E_A: GDELT count > P90_natural_disaster AND resolved against PM consensus ≥ 55% AND salience_ratio ≥ 1.0
- E_M same `natural_disaster` category; GDELT salience ∈ [P40, P75]
- E_M YES < category_base_rate − 10pp; YES ∈ [0.12, 0.65]
- entity_sim(E_A, E_M) < 0.70
- Geographic distance > 500km AND NOAA < MODERATE AND USGS < 4.5 at E_M location (72h)
- Anchor GDELT velocity declining (< 0.7× peak — anchor established)
- AERB-fade NOT firing BUY NO on E_M (contrast mechanism confirmed by classifier)
- E_M resolution > 14 days; liquidity ≥ $5k; bid-ask ≤ $0.05
- G3 backtest cleared (WR ≥ 60% at N ≥ 20) — BLOCKING for live signals

**Works when (Mode B — Political Violence / Electoral):**
- Same structure; ACLED delta at E_M region < +20%; distinct primary_actor AND conflict_system_id
- E_M resolution > 21 days; 0.75× Mode A position size; α = 0.08

**Fails when:**
- Anti-prim A: IS scan WR < 50% at N ≥ 20 → mechanism invalidated; suspend mode
- Anti-prim B: E_A salience_ratio < 1.0 (below P90) → no qualifying anchor → skip
- Anti-prim C: ACLED delta ≥ +20% at E_M region (Mode B) → genuine escalation → skip
- AERB-fade fires BUY NO on E_M from same E_A → availability dominates → skip (AVAILABILITY gate)
- E_A is still rising in GDELT velocity (≥ 0.7× peak) → anchor not yet established → wait
- E_M is a cascade stage of E_A (logical U→D relationship) → use conditional-probability-cascade-arbitrage
- Category base rate database unavailable → BLOCKING (shared with CBRNF)
- GDELT P40/P75/P90 baselines unavailable → BLOCKING (shared with AERB-fade)
- E_M YES < 0.10 (FLB zone) → defer to favourite-longshot-bias-fade

---

### Bank State Change

- naive: 22 → 21 (sequential-contrast-effect-signal elevated; naive file retained as historical)
- intermediate: 21 → 22
- sophisticated: 23 (unchanged)
