---
prim: anchor-event-recency-bias-fade
level: sophisticated
elevated_from: intermediate
cycle: 77
bank: naive 8 · intermediate 13 · sophisticated 16
---

## Prim: anchor-event-recency-bias-fade
**Level:** sophisticated | **Elevated from:** intermediate (cycle 76) | **Bank:** naive 8 · intermediate 13 · sophisticated **16**

---

### What changed from intermediate

**[1] N_eff concurrent-anchor Kelly adjustment**
Formalised at ρ_anchor = 0.60 (same cognitive availability pool as concurrent same-category media cycles — analogous to the ρ≈0.6–0.8 used in resolution-confirmation-arb for correlated election markets). N_eff = N / (1 + (N−1) × 0.60), hard cap at N_eff ≤ 3. Per-position Kelly fraction = full_kelly / N_eff. Anchors within 14 days in same category/mode group count toward N.

**[2] GDELT salience quantile calibration**
Category-specific P90 thresholds replace the intermediate single 1,000/48h heuristic:
- natural_disaster: ~1,200 articles/48h
- political_violence: ~800 articles/48h
- electoral: ~1,500 articles/48h

These are preliminary estimates pending GDELT GKG 2022–2026 archive query (Gate 1 in deployment sequence). CATEGORY_BASELINE_48H denominators (200/150/250) also calibrated, enabling salience_ratio computation.

**[3] Entity-category NLP classifier FPR incorporated**
Classifier must be evaluated on a labeled corpus of ≥ 50 anchor/target market pairs before deployment (Gate 0, now BLOCKING). FPR enters the anti-prim historical scan via:
```
adjusted_pct_yes = (raw_pct_yes − FPR × 0.50) / (1 − FPR)
```
FPR > 0.15 blocks deployment until retraining.

**[4] Gennaioli-Shleifer severity-frequency salience tier**
Three-tier classification on `salience_ratio = article_count_48h / category_baseline`:
- **HIGH** (ratio ≥ 5.0 AND count ≥ P90): rare, severe anchor — relaxed spike threshold, strongest expected fade. Grounded by Lichtenstein et al. (1978 JEPHPP): assessed frequency overestimation is largest for rare, dramatic events.
- **MODERATE** (ratio 2.0–5.0): standard intermediate thresholds.
- **LOW** (ratio < 2.0): tighter threshold or skip without own-data support.

Tier-specific spike thresholds:

| Mode | HIGH | MODERATE | LOW |
|------|------|----------|-----|
| A (natural_disaster) | ≥6pp/5d | ≥8pp/5d | ≥10pp/5d |
| B (political/electoral) | ≥10pp/3d | ≥12pp/3d | ≥15pp/3d |

---

### Rule (sophisticated)

Same two-mode structure as intermediate, with tier-aware and N_eff-adjusted sizing:

#### Mode A — Natural Disaster (LOW confound)

**Setup:** Major natural disaster resolves as anchor event.

**Trigger:** GDELT article_count_48h > P90_natural_disaster (~1,200, preliminary) + anchor surprises PM consensus (resolved against prior PM probability ≥ 55%) + same natural-disaster category + tier-specific YES spike + geographic_distance > 500km + NOAA < MODERATE + USGS < 4.5 at target location (72h) + target YES ∈ [0.15, 0.50] + resolution > 14d + entity_sim ∈ (0.10, 0.70).

**Action:** BUY NO on target market.

**Exit:** 10-day max hold OR when GDELT anchor_velocity < 0.5× post-resolution peak.

**Sizing:** Fractional Kelly α = 0.10 / N_eff. N_eff = N / (1 + (N−1)×0.60), capped at 3.

---

#### Mode B — Political Violence / Electoral (MODERATE confound)

**Setup:** Major political violence or electoral surprise resolves as anchor event.

**Trigger:** GDELT article_count_48h > P90_category (preliminary) + surprise gate + ACLED delta < +20% + distinct primary_actor AND conflict_system_id + tier-specific YES spike + YES ∈ [0.15, 0.55] + resolution > 21d.

**Action:** BUY NO at 0.75× / N_eff size.

**Exit:** 7-day max hold OR GDELT anchor_velocity < 0.5× peak.

**Sizing:** Fractional Kelly α = 0.08 / N_eff.

---

### 5-Gate Deployment Sequence

| Gate | Description | Status |
|------|-------------|--------|
| 0 (BLOCKING) | Entity-category NLP classifier FPR ≤ 0.15 on ≥ 50 labeled pairs | NOT IMPLEMENTED |
| 1 | GDELT GKG 2022–2026 P90 calibration (confirms category thresholds) | NOT IMPLEMENTED |
| 2 | Anti-prim historical scan with FPR adjustment: ≥ 50% YES resolution → retire mode | Depends on Gate 1 |
| 3 (BLOCKING) | Cross-market entity similarity pipeline (cosine sim 0.10–0.70) | NOT IMPLEMENTED |
| 4 | 20-signal paper trading with tier-stratified WR; live at α=0.10 floor | Depends on Gates 0–3 |

---

### Anti-Prim Escape Hatches (4)

**(A) Historical scan gate (pre-deployment, mandatory):**
GDELT GKG 2022–2026 + PM resolution API: if ≥ 50% same-category target markets resolved YES after anchor → retire mode. FPR adjustment applied: `adjusted_pct_yes = (raw_pct_yes − FPR×0.50) / (1 − FPR)`.

**(B) Rolling performance gate (live, per-mode):**
Own-data rolling 20-trade WR < 50% per mode → suspend. WR < 50% for 2 consecutive windows → retire mode.

**(C) Frequency gate (per-mode, annual):**
< 5 qualifying anchor events per year for 2 consecutive years → lower salience threshold one step and re-evaluate; if still < 5/year → retire mode.

**(D) Tier asymmetry collapse (sophisticated-specific):**
If HIGH-tier own-data WR < MODERATE-tier WR by > 10pp for 2 consecutive 20-trade windows → tier asymmetry not replicating → set `escape_hatch_d_collapse = True` in config, collapsing to intermediate single-threshold logic.

---

### Academic Anchors (10)

1. **Tversky & Kahneman (1974 Science)** — availability heuristic; foundational mechanism
2. **Johnson & Tversky (1983 JPSP)** — cross-category mood contamination; Mode B mechanism
3. **Barber & Odean (2008 RFS)** — attention-driven retail buying; PM retail analogue
4. **Greenwood & Shleifer (2014 RFS)** — extrapolation of recent events → return overestimation
5. **Gennaioli & Shleifer (2010 QJE)** — salience theory: systematic directional bias; grounds tier system
6. **Eisensee & Strömberg (2007 QJE)** — media cycle decay; grounds Mode A 10d / Mode B 7d hold windows
7. **Kunreuther et al. (1978, Wiley)** — insurance demand +100–200% in zero-risk regions; ~3–6pp PM overpricing at YES=0.20
8. **Palm (1995, Westview Press)** — earthquake insurance +30% in non-epicentre counties; independent replication
9. **Lichtenstein, Slovic, Fischhoff, Layman & Combs (1978 JEPHPP)** — judged-frequency overestimation scales with event rarity/drama; grounds HIGH-tier asymmetry (relaxed spike threshold for rare severe anchors)
10. **Loewenstein, Weber, Hsee & Welch (2001 Psychological Bulletin)** — emotional risk response decays slower than cognitive correction; explains 10–14d fade window set by emotional, not cognitive, availability decay

---

### Parameters (plateau-ready grid — unchanged from intermediate)

| Parameter | Values to test | Mode |
|-----------|----------------|------|
| anchor_salience_threshold | P90_cat × 0.5, P90_cat, P90_cat × 1.5 | Both |
| mode_a_spike by tier | HIGH: 4–8pp / MOD: 6–10pp / LOW: 8–12pp | A |
| mode_b_spike by tier | HIGH: 8–12pp / MOD: 10–15pp / LOW: 12–18pp | B |
| rho_anchor | 0.40, 0.60, 0.80 | Both |
| geographic_distance_km | 200, 500, 1,000, 2,000 | A |
| acled_delta_threshold | 0.10, 0.20, 0.30 | B |
| entity_sim_cutoff | 0.50, 0.60, 0.70 | Both |

**CPCV + Deflated Sharpe correction mandatory** when optimising (Bailey-Borwein-Lopez de Prado SSRN 2326253).
