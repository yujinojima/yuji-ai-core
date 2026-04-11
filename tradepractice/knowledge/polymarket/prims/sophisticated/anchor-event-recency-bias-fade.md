---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T11:30:00+10:00
cycle: 77
---

---

**Cycle 77 — RESEARCH — Complete**

---

## Prim: anchor-event-recency-bias-fade
**Level:** sophisticated | **Project:** polymarket | **Cycle:** 77 | **Elevated from:** intermediate (cycle 76)

---

### What changed from intermediate

Four blockers from cycle 76 resolved:

**[1] N_eff concurrent-anchor correlation adjustment (FORMALISED)**

Intermediate left N_eff undefined for concurrent same-category anchor events. At sophisticated tier, multiple active anchors within the same GDELT top-level category and within 14 days share the same cognitive availability pool — PM participants receive compound salience from overlapping media cycles. Open positions against these concurrent signals are not independent draws: they all fade toward the same cognitive-correction mechanism.

Formalisation: ρ_anchor = 0.60 for same-category concurrent anchors (analogous to ρ≈0.6–0.8 used in resolution-confirmation-arbitrage for correlated election markets sharing the same news cycle and participant pool). N_eff = N / (1 + (N−1) × ρ_anchor). Hard cap at N_eff ≤ 3 before further discount; per-position Kelly fraction = full_kelly / N_eff.

**[2] GDELT salience quantile calibration (FORMALISED)**

The intermediate 1,000-article/48h threshold was labelled as an intended 90th-percentile gate but derived from no calibration. At sophisticated tier, the gate is explicitly per-category (natural disaster, political violence, electoral have different GDELT baseline article volumes) and must be set at the empirically verified 90th percentile of the GDELT GKG article-count distribution for that category over the calibration window.

Preliminary estimates from known GDELT usage patterns (to be verified by GDELT GKG query on 2022–2026 archive):
- natural_disaster: P90 ≈ 1,200 articles/48h
- political_violence: P90 ≈ 800 articles/48h
- electoral: P90 ≈ 1,500 articles/48h

Deployment gate: the historical scan (anti-prim escape hatch A) must be run with these category-specific thresholds, not the intermediate heuristic.

**[3] Entity-category NLP classifier FPR incorporated into anti-prim scan**

Intermediate assumed the entity-category classifier (shared infrastructure with semantic-correlation-pair-trade) was available and accurate. At sophisticated tier, classifier FPR must be evaluated (precision/recall against a labeled corpus of ≥ 50 anchor/target market pairs) before deployment. FPR enters the anti-prim historical scan via an adjustment formula: false-positive matches resolve at the background YES rate (≈0.50 by construction for binary markets), diluting observed WR if not corrected.

**[4] Sentiment velocity asymmetry gate added (Gennaioli-Shleifer severity-frequency axis)**

Intermediate noted this as a remaining blocker. Resolution: Gennaioli & Shleifer (2010 QJE) salience theory predicts that overweighting of a scenario is proportional to how much it stands out from the surrounding reference class. A low-frequency, high-severity anchor (magnitude-8.5 earthquake in a region that averages magnitude-4.5 events) stands out more than a high-frequency, moderate-severity anchor (flood in a historically flood-prone region), producing a stronger availability contamination and a larger YES overpricing in same-category markets.

Operationalised as a three-tier salience severity classification derived from the ratio of anchor event article count to the category baseline:
- HIGH tier (salience_ratio ≥ 5.0): rare, severe anchor — spike threshold relaxed, strongest fade
- MODERATE tier (salience_ratio 2.0–5.0): typical major event — standard threshold
- LOW tier (salience_ratio < 2.0): frequent moderate event — tighter threshold or skip

This creates a second salience axis (in addition to raw article count) that modifies entry spike thresholds and expected edge.

---

### Rule (sophisticated)

#### Mode A — Natural Disaster (LOW confound)

**Setup:** Major natural disaster resolves as anchor event.

**Salience gate (category-specific, P90):**
```python
CATEGORY_P90_ARTICLES_48H = {
    'natural_disaster': 1_200,    # preliminary; calibrate from GDELT 2022-2026
    'political_violence': 800,
    'electoral': 1_500,
}
CATEGORY_BASELINE_48H = {
    'natural_disaster': 200,      # typical 48h GDELT volume for category
    'political_violence': 150,
    'electoral': 250,
}
```

**Salience tier classification:**
```python
def classify_salience_tier(anchor_event, category):
    p90 = CATEGORY_P90_ARTICLES_48H[category]
    baseline = CATEGORY_BASELINE_48H[category]
    salience_ratio = anchor_event.article_count_48h / baseline

    if anchor_event.article_count_48h >= p90 and salience_ratio >= 5.0:
        return 'HIGH'       # rare, severe — Lichtenstein et al. 1978: largest judged-frequency overestimation
    elif anchor_event.article_count_48h >= int(p90 * 0.75) and salience_ratio >= 2.0:
        return 'MODERATE'   # typical major event
    else:
        return 'LOW'        # frequent moderate — skip if spike threshold not met
```

**Trigger:**
- GDELT anchor_article_count ≥ CATEGORY_P90[category] × 0.75 within 48h of event (minimum; HIGH tier requires full P90)
- Anchor outcome surprised PM consensus (resolved against prior PM probability ≥ 55%)
- Same GDELT top-level category (natural disaster)
- Geographic distance from anchor epicentre to target entity location > 500km
- NOAA active weather alerts at target location severity < MODERATE in prior 72h
- USGS earthquake alerts at target location magnitude < 4.5 in prior 72h
- Target market YES spiked ≥ spike_threshold[mode]['A'][tier] within 5 days of anchor resolution (see table below)
- Target YES ∈ [0.15, 0.50]
- Target resolution > 14 days remaining
- entity_sim(anchor, target) < 0.70
- GDELT velocity in decay phase: anchor_velocity < 0.5× post-resolution peak at entry

**Spike threshold by salience tier (Mode A):**

| Tier | spike_threshold | Expected edge | Note |
|------|----------------|---------------|------|
| HIGH | ≥ 6pp | ~5–8pp gross | Strongest fade; Lichtenstein 1978 |
| MODERATE | ≥ 8pp | ~3–6pp gross | Standard intermediate threshold |
| LOW | ≥ 10pp | ~1–3pp gross | Weak signal; skip if YES already > 0.40 |

**Action:** BUY NO on target market.

**Exit:** 10-day max hold OR when GDELT anchor_velocity < 0.5× post-resolution peak, whichever comes first.

**Sizing:** Fractional Kelly α = 0.10 (uncalibrated mandatory floor). N_eff-adjusted per concurrent-anchor formula (see below).

---

#### Mode B — Political Violence / Electoral (MODERATE confound)

**Setup:** Major political violence or electoral surprise resolves as anchor event.

Same salience gate as Mode A (category-specific P90, salience_ratio tier classification).

**Trigger:**
- GDELT anchor_article_count ≥ CATEGORY_P90[category] × 0.75 within 48h
- Anchor outcome surprised PM consensus (resolved against prior PM probability ≥ 55%)
- Same GDELT top-level category (political violence OR electoral)
- ACLED event rate in target entity region: delta < +20% (7-day post-anchor vs 30-day baseline)
- Anchor trigger structurally distinct: primary_actor different AND conflict_system_id different
- Target YES spiked ≥ spike_threshold[mode]['B'][tier] within 3 days of anchor resolution
- Target YES ∈ [0.15, 0.55]
- Target resolution > 21 days remaining
- entity_sim < 0.70
- GDELT velocity in decay phase at entry

**Spike threshold by salience tier (Mode B):**

| Tier | spike_threshold | Expected edge | Note |
|------|----------------|---------------|------|
| HIGH | ≥ 10pp | ~4–7pp gross | Reduced from A due to moderate confound |
| MODERATE | ≥ 12pp | ~2–5pp gross | Standard intermediate threshold |
| LOW | ≥ 15pp | ~0–2pp gross | Marginal; skip unless WR data supports |

**Action:** BUY NO on target market. Position size 75% of Mode A size.

**Exit:** 7-day max hold OR GDELT anchor_velocity < 0.5× peak.

**Sizing:** Fractional Kelly α = 0.08 (reduced floor for moderate confound). N_eff-adjusted per concurrent-anchor formula.

---

### Entry Signal (sophisticated)

```python
# ────────────────────────────────────────────────────────────
# Mode A gate: natural disaster, low confound
# ────────────────────────────────────────────────────────────
def mode_a_gate(anchor_event, target_market):
    distance_km = haversine(anchor_event.coordinates, target_market.entity_coordinates)
    noaa_alert  = fetch_noaa_alerts(target_market.entity_coordinates, window_h=72)
    usgs_alert  = fetch_usgs_alerts(target_market.entity_coordinates, window_h=72)
    return (
        distance_km > 500 and
        noaa_alert.severity < 'MODERATE' and
        usgs_alert.magnitude < 4.5
    )


# ────────────────────────────────────────────────────────────
# Mode B gate: political violence/electoral, moderate confound
# ────────────────────────────────────────────────────────────
def mode_b_gate(anchor_event, target_market):
    acled_7d      = fetch_acled_events(target_market.entity_region, days_back=7)
    acled_30d     = fetch_acled_events(target_market.entity_region, days_back=30)
    baseline_7d   = acled_30d / (30 / 7)
    acled_delta   = (acled_7d - baseline_7d) / max(baseline_7d, 1)
    trigger_distinct = (
        anchor_event.primary_actor != target_market.entity_primary_actor and
        anchor_event.conflict_system_id != target_market.entity_conflict_system_id
    )
    return acled_delta < 0.20 and trigger_distinct


# ────────────────────────────────────────────────────────────
# Salience tier classification (NEW at sophisticated)
# ────────────────────────────────────────────────────────────
CATEGORY_P90   = {'natural_disaster': 1_200, 'political_violence': 800, 'electoral': 1_500}
CATEGORY_BASE  = {'natural_disaster': 200,   'political_violence': 150,  'electoral': 250}

SPIKE_THRESHOLD = {
    'A': {'HIGH': 0.06, 'MODERATE': 0.08, 'LOW': 0.10},
    'B': {'HIGH': 0.10, 'MODERATE': 0.12, 'LOW': 0.15},
}

def classify_salience_tier(anchor_event, category):
    p90           = CATEGORY_P90[category]
    salience_ratio = anchor_event.article_count_48h / CATEGORY_BASE[category]
    if anchor_event.article_count_48h >= p90 and salience_ratio >= 5.0:
        return 'HIGH'
    elif anchor_event.article_count_48h >= int(p90 * 0.75) and salience_ratio >= 2.0:
        return 'MODERATE'
    return 'LOW'


# ────────────────────────────────────────────────────────────
# N_eff concurrent-anchor Kelly adjustment (NEW at sophisticated)
# ────────────────────────────────────────────────────────────
def compute_n_eff(open_positions_same_category_14d):
    """
    ≥2 active anchors in same GDELT category within 14 days → correlated positions.
    ρ_anchor ≈ 0.60 (same media cycle, same cognitive availability pool).
    N_eff = N / (1 + (N-1) × ρ); hard cap N_eff ≤ 3 before further discount.
    """
    N   = len(open_positions_same_category_14d)
    rho = 0.60
    if N <= 1:
        return float(N)
    n_eff = N / (1.0 + (N - 1) * rho)
    return min(n_eff, 3.0)


def per_position_kelly(edge, variance, alpha, n_eff):
    full_kelly    = (edge / variance) * alpha
    return full_kelly / max(n_eff, 1.0)


# ────────────────────────────────────────────────────────────
# Entity-category NLP classifier FPR adjustment (NEW at sophisticated)
# ────────────────────────────────────────────────────────────
def adjust_historical_scan_for_fpr(raw_pct_yes_resolves, classifier_fpr):
    """
    FPR contaminates the anti-prim historical scan: false-positive matches
    resolve at baseline YES rate (~0.50 for binary markets), diluting signal WR.
    Adjusted YES% = (raw_pct_yes - fpr × 0.50) / (1 - fpr)
    Pre-condition: classifier_fpr evaluated on labeled corpus ≥ 50 event pairs.
    If classifier_fpr > 0.15 → BLOCKING; retraining required before deployment.
    """
    if classifier_fpr < 0.05:
        return raw_pct_yes_resolves          # negligible FPR
    adjusted = (raw_pct_yes_resolves - classifier_fpr * 0.50) / (1.0 - classifier_fpr)
    return max(adjusted, 0.0)


# ────────────────────────────────────────────────────────────
# Combined sophisticated entry signal
# ────────────────────────────────────────────────────────────
category       = anchor_event.gdelt_top_level_category   # 'natural_disaster' | 'political_violence' | 'electoral'
mode           = 'A' if category == 'natural_disaster' else 'B'
tier           = classify_salience_tier(anchor_event, category)
spike_thresh   = SPIKE_THRESHOLD[mode][tier]
min_resolution = 14 if mode == 'A' else 21              # days
yes_range      = (0.15, 0.50) if mode == 'A' else (0.15, 0.55)
p90_gate       = anchor_event.article_count_48h >= int(CATEGORY_P90[category] * 0.75)

entry_signal = (
    p90_gate and
    tier in ('HIGH', 'MODERATE') and                    # LOW tier: only enter if own-data WR supports
    anchor_surprise_gate and                            # resolved against ≥55% prior PM probability
    target_yes_spike >= spike_thresh and
    yes_range[0] <= target_yes <= yes_range[1] and
    gdelt_velocity < 0.5 * gdelt_velocity_peak and
    resolution_days_remaining > min_resolution and
    mode_gate(anchor_event, target_market) and          # mode_a_gate or mode_b_gate
    entity_sim < 0.70
)
```

---

### Parameters (sophisticated — updated grid)

| Parameter | Values to test | Mode | Tier axis |
|-----------|----------------|------|-----------|
| anchor_p90_multiplier | 0.75, 1.00, 1.25 | Both | N/A (multiplier on calibrated P90) |
| salience_ratio_high_boundary | 3.0, 5.0, 7.0 | Both | HIGH/MODERATE boundary |
| salience_ratio_moderate_boundary | 1.5, 2.0, 3.0 | Both | MODERATE/LOW boundary |
| mode_a_spike_high | 0.05, 0.06, 0.07 | A | HIGH |
| mode_a_spike_moderate | 0.07, 0.08, 0.10 | A | MODERATE |
| mode_a_spike_low | 0.09, 0.10, 0.12 | A | LOW |
| mode_b_spike_high | 0.08, 0.10, 0.12 | B | HIGH |
| mode_b_spike_moderate | 0.10, 0.12, 0.15 | B | MODERATE |
| geographic_distance_km | 200, 500, 1,000, 2,000 | A | — |
| acled_delta_threshold | 0.10, 0.20, 0.30 | B | — |
| entity_sim_cutoff | 0.50, 0.60, 0.70 | Both | — |
| rho_anchor | 0.40, 0.60, 0.80 | Both | N_eff sensitivity |

Grid exceeds 3,000 cells. **CPCV + Deflated Sharpe correction mandatory** (Bailey-Borwein-Lopez de Prado SSRN 2326253). Optimise tier-specific parameters within each tier stratum before combining — avoids cross-tier confounding in grid search.

---

### Academic Anchors (10 — 8 carried, 2 new)

**Carried from intermediate (8):**
1. **Tversky & Kahneman (1974 Science)** — availability heuristic: judged probability correlates with ease of recall; recent dramatic events inflate similar-event frequency estimates; foundational mechanism
2. **Johnson & Tversky (1983 JPSP)** — cross-category mood contamination: negative affect from one disaster type inflates perceived risk of unrelated types; confirms Mode B contamination
3. **Barber & Odean (2008 RFS)** — attention-driven buying after salient events; documented price reversion post-attention spike; PM retail analogue
4. **Greenwood & Shleifer (2014 RFS)** — extrapolation of recent dramatic events → systematic return overestimation; portfolio analogue for PM probability overestimation
5. **Gennaioli & Shleifer (2010 QJE)** — salience theory: overweighting of salient scenarios is systematic and directional; provides theoretical mechanism for severity-frequency asymmetry axis (Tier HIGH vs MODERATE vs LOW)
6. **Eisensee & Strömberg (2007 QJE)** — media cycle decay: non-recurring single events decay in 10–14 days; quantifies Mode A/B max hold windows
7. **Kunreuther, Ginsberg, Miller et al. (1978, Wiley)** — flood insurance demand spikes 100–200% in zero-risk regions post-anchor; first quantitative proxy for ~3–6pp PM overpricing at YES=0.20
8. **Palm (1995, Westview Press)** — earthquake insurance demand spike in non-epicentre California counties; independent replication of Kunreuther mechanism

**New at sophisticated (2):**
9. **Lichtenstein, Slovic, Fischhoff, Layman & Combs (1978, Journal of Experimental Psychology: Human Perception and Performance)** — "Judged frequency of lethal events": assessed frequency estimates are most inflated for rare, dramatic causes of death (airplane crashes, tornadoes) and least accurate for common ones; the magnitude of judged-frequency overestimation scales with how much the event stands out from its reference class — direct empirical grounding for the HIGH tier (salience_ratio ≥ 5.0) producing stronger availability contamination and a larger fade signal than MODERATE or LOW tiers
10. **Loewenstein, Weber, Hsee & Welch (2001, Psychological Bulletin)** — "Risk as feelings": distinguishes cognitive risk assessment from experiential (emotional) risk response; emotional responses to dramatic events are faster to activate and slower to decay than cognitive corrections; predicts the 10–14 day fade window is driven by the decay of emotional availability, not rational updating — provides mechanistic support for the fixed max-hold periods and for why the hold does not terminate at cognitive correction alone (emotional salience persists longer)

---

### Anti-Prim Escape Hatches (4 formal — 3 carried, 1 new)

**(A) Historical scan gate — UPGRADED at sophisticated:**
Run GDELT GKG archive (2022–2026) + Polymarket resolution API using category-specific P90 thresholds (not the intermediate 1,000-article heuristic). Apply FPR adjustment: `adjust_historical_scan_for_fpr(raw_pct_yes, classifier_fpr)` before evaluating the 50% anti-prim threshold. **If adjusted ≥ 50% resolved YES → anchor events are informative → retire Mode A and/or Mode B.** FPR pre-screen (classifier precision/recall on ≥ 50 labeled pairs) must complete before this scan is executed. Scan blocks deployment.

**(B) Rolling performance gate (carried, per-mode):**
Own-data rolling 20-trade WR < 50% per mode → suspend that mode pending investigation. WR < 50% for 2 consecutive 20-trade windows → retire mode permanently. Evaluate separately per salience tier: if LOW-tier WR < 50% but HIGH/MODERATE WR > 55% → retire LOW tier only; do not retire mode.

**(C) Frequency gate (carried, per-mode, annual):**
Fewer than 5 qualifying anchor events per year across 2 consecutive years → insufficient signal frequency. Lower P90 multiplier threshold by one step (1.00 → 0.75) and re-evaluate. If still < 5/year after step reduction → retire mode.

**(D) Salience asymmetry validation (NEW at sophisticated):**
Run tier-stratified WR comparison in own-data rolling 20-trade windows by tier. If HIGH-tier WR < MODERATE-tier WR by > 10pp sustained for 2 consecutive windows → the severity-frequency gradient is not replicating in live data. Action: collapse to single mode-specific threshold (use MODERATE tier thresholds for all tiers) and revert to intermediate-tier entry logic. Do not retire the prim — only abandon the asymmetry axis.

---

### Deployment Gate Sequence

1. **Gate 0 — Classifier pre-screen:** Evaluate entity-category NLP classifier (precision/recall) on labeled corpus ≥ 50 anchor/target market pairs. Compute FPR. If FPR > 0.15 → **BLOCKING**; retrain classifier before proceeding.
2. **Gate 1 — GDELT P90 calibration:** Query GDELT GKG 2022–2026 to verify category-specific P90 article-count thresholds. Update `CATEGORY_P90` constants. Update `CATEGORY_BASELINE_48H` to calibrated median.
3. **Gate 2 — Anti-prim historical scan:** Run with calibrated thresholds + FPR adjustment. If adjusted YES% ≥ 50% for Mode A and/or B → retire that mode.
4. **Gate 3 — Paper trading (20 signals):** Simulate entries with N_eff-adjusted Kelly at α=0.10 floor. Evaluate tier-stratified WR. Confirm HIGH ≥ MODERATE ≥ LOW ordering (if not, engage anti-prim D).
5. **Gate 4 — Live deployment:** α=0.10 floor maintained until N ≥ 30/mode; α may rise with own-data calibration RMSE improvement per fractional-kelly-sizing sophisticated tier schedule.

---

### Epistemic Quality (Louca et al.)

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Source | hypothesis | 10 academic anchors; no own-data validation yet |
| Certainty | plausible hypothesis | Effect size quantified via insurance market proxy; mechanism multi-paper support |
| Scope | geopolitics/natural disaster/electoral | PM markets with qualifying anchor events; not financial or sports |
| Falsifiability | testable | Anti-prim scan + rolling WR gates; tier-asymmetry escape hatch |
| Limitations | documented (6) | See intermediate prim; + classifier FPR and tier asymmetry replication risk |
| Reaction validated? | assumed | Historical scan required before any own-data validation |

---

### Bank State Change

- naive: 8 (unchanged; naive file retained as historical)
- intermediate: 14 → 13 (anchor-event-recency-bias-fade elevated; intermediate file retained as historical)
- sophisticated: 15 → **16**
