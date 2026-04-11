---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T09:15:00+10:00
cycle: 76
---

---

**Cycle 76 — RESEARCH — Complete**

---

## Prim: anchor-event-recency-bias-fade
**Level:** intermediate | **Project:** polymarket | **Cycle:** 76 | **Elevated from:** naive (cycle 75)

---

### What changed from naive

**Naive blocker resolved:** The naive prim identified the information vs bias confound as its primary blocker. Availability bias predicts a fade (BUY NO); a genuine base-rate update predicts a hold or continuation. No filter separated these at the naive level.

**Resolution mechanism:** Two-mode structure with external condition-stability gates. If underlying physical or security conditions are unchanged after the anchor event, a same-category YES price spike is more likely cognitive bias than information. The gates are sourced from observable external data (NOAA/USGS for natural disasters; ACLED for political violence) rather than PM price history alone, making them pre-trade verifiable.

**Effect size anchored:** Insurance market research (Kunreuther et al. 1978; Palm 1995) quantifies the mechanism: flood/earthquake insurance purchases spike 100–200% in regions with no change in actuarial risk within weeks of a distant anchor disaster. Extrapolating to PM: a 3–6pp YES overpricing at YES=0.20 is plausible for Mode A — first quantitative anchor for this prim class.

**Decay timeline grounded:** Eisensee & Strömberg (2007 QJE) media cycle research: news competition compresses event coverage; non-recurring single events decay within 10–14 days. Mode A hold max set at 10 days; Mode B at 7 days (political events attract sustained follow-up coverage, shortening the independent decay window).

---

### Rule (intermediate)

#### Mode A — Natural Disaster (LOW confound)

**Setup:** Major natural disaster resolves as anchor event.

**Trigger:** GDELT anchor_article_count > 1,000 within 48h of event. Anchor outcome surprised PM consensus (resolved against prior PM probability ≥ 55%). Same GDELT top-level category (natural disaster). Geographic distance from anchor epicentre to target entity location > 500km. NOAA active weather alerts at target location severity < MODERATE in prior 72h. USGS earthquake alerts at target location magnitude < 4.5 in prior 72h. Target market YES spiked ≥ 8pp within 5 days of anchor resolution. Target YES ∈ [0.15, 0.50]. Target resolution > 14 days remaining. entity_sim(anchor, target) < 0.70.

**Reaction (cognitive):** Cross-category availability contamination. PM participants who witnessed the anchor disaster update same-category probabilities upward. No independent physical threat exists at the target entity's location — the price move is pure cognitive salience transfer.

**Action:** BUY NO on target market.

**Exit:** 10-day max hold OR when GDELT anchor_velocity < 0.5× post-resolution peak, whichever comes first.

**Sizing:** Fractional Kelly α = 0.10 (uncalibrated mandatory floor).

---

#### Mode B — Political Violence / Electoral (MODERATE confound)

**Setup:** Major political violence or electoral surprise resolves as anchor event.

**Trigger:** GDELT anchor_article_count > 1,000 within 48h. Anchor outcome surprised PM consensus (resolved against prior PM probability ≥ 55%). Same GDELT top-level category (political violence OR electoral). ACLED event rate in target entity region: delta < +20% comparing 7-day rate post-anchor to 30-day baseline pre-anchor (security conditions stable). Anchor trigger is structurally distinct from target: primary_actor different AND conflict_system_id different (not the same conflict network). Target YES spiked ≥ 12pp within 3 days of anchor resolution (tighter window — political contagion resolves faster or confirms faster). Target YES ∈ [0.15, 0.55]. Target resolution > 21 days remaining. entity_sim < 0.70.

**Reaction (cognitive):** Johnson & Tversky (1983) cross-category mood contamination: negative affect from one political violence event inflates perceived probability of different-trigger political violence. The information vs bias confound is only partially resolved at intermediate (ACLED and distinct trigger gate reduce but do not eliminate it — some political violence does spread via network contagion).

**Action:** BUY NO on target market. Position size 75% of Mode A size (moderate vs low confound weighting).

**Exit:** 7-day max hold OR GDELT anchor_velocity < 0.5× peak.

**Sizing:** Fractional Kelly α = 0.08 (reduced floor for moderate confound).

---

### Entry Signal (combined)

```python
# Mode A: natural disaster, low confound
def mode_a_gate(anchor_event, target_market):
    distance_km = haversine(anchor_event.coordinates, target_market.entity_coordinates)
    noaa_alert = fetch_noaa_alerts(target_market.entity_coordinates, window_h=72)
    usgs_alert = fetch_usgs_alerts(target_market.entity_coordinates, window_h=72)
    return (
        distance_km > 500 and
        noaa_alert.severity < 'MODERATE' and
        usgs_alert.magnitude < 4.5
    )

# Mode B: political violence/electoral, moderate confound
def mode_b_gate(anchor_event, target_market):
    acled_7d  = fetch_acled_events(target_market.entity_region, days_back=7)
    acled_30d = fetch_acled_events(target_market.entity_region, days_back=30)
    baseline_7d = acled_30d / (30 / 7)
    acled_delta = (acled_7d - baseline_7d) / max(baseline_7d, 1)
    trigger_distinct = (
        anchor_event.primary_actor != target_market.entity_primary_actor and
        anchor_event.conflict_system_id != target_market.entity_conflict_system_id
    )
    return acled_delta < 0.20 and trigger_distinct

SPIKE_THRESHOLD = {'A': 0.08, 'B': 0.12}
MIN_RESOLUTION  = {'A': 14,   'B': 21}   # days

entry_signal = (
    anchor_salience > 1000 and
    anchor_surprise_gate and                        # resolved against ≥55% prior PM prob
    target_yes_spike >= SPIKE_THRESHOLD[mode] and
    target_yes_in_range and                         # [0.15,0.50] A | [0.15,0.55] B
    gdelt_velocity < 0.5 * gdelt_velocity_peak and  # decay phase — not peak salience
    resolution_days_remaining > MIN_RESOLUTION[mode] and
    mode_gate(anchor_event, target_market) and
    entity_sim < 0.70
)
```

---

### Parameters (plateau-ready grid)

| Parameter | Values to test | Mode |
|-----------|----------------|------|
| anchor_salience_threshold | 500, 750, 1,000, 1,500, 2,000 | Both |
| mode_a_spike | 0.06, 0.08, 0.10, 0.12 | A |
| mode_b_spike | 0.10, 0.12, 0.15, 0.18 | B |
| geographic_distance_km | 200, 500, 1,000, 2,000 | A |
| acled_delta_threshold | 0.10, 0.20, 0.30 | B |
| entity_sim_cutoff | 0.50, 0.60, 0.70 | Both |

Grid size: 5 × 4 × 4 × 4 × 3 × 3 = 2,880 cells (exceeds 20). **CPCV + Deflated Sharpe correction mandatory** when optimising (Bailey-Borwein-Lopez de Prado SSRN 2326253).

---

### Academic Anchors (8 — 4 carried, 4 new)

**Carried from naive:**
1. **Tversky & Kahneman (1974 Science)** — availability heuristic: judged probability correlates with ease of recall of instances; recent dramatic events inflate similar-event frequency estimates; foundational mechanism for this prim
2. **Johnson & Tversky (1983 JPSP)** — cross-category mood contamination: negative affect from one disaster type (e.g., disease outbreak) increases perceived risk of unrelated disaster types (floods, violence); confirms Mode B cross-category contamination
3. **Barber & Odean (2008 RFS)** — attention-driven retail buying after salient events (glitter effect); price reversion documented post-attention spike; PM retail analogue
4. **Greenwood & Shleifer (2014 RFS)** — extrapolation of recent dramatic events → systematic return overestimation; portfolio analogue for PM probability overestimation

**New at intermediate:**
5. **Gennaioli & Shleifer (2010 QJE)** — salience theory: agents overweight the most salient recent analog when forming probability estimates; overweighting is systematic and directional (toward the salient scenario), not random noise; provides theoretical mechanism for why anchor events produce predictable directional biases rather than symmetric noise
6. **Eisensee & Strömberg (2007 QJE)** — news media competition and event coverage: single non-recurring events decay from media cycle in 10–14 days as new events compete; quantifies Mode A decay window (10-day max hold) and Mode B decay window (7-day max hold for events with ongoing follow-up risk)
7. **Kunreuther, Ginsberg, Miller et al. (1978, Wiley)** — *Disaster Insurance Protection: Public Policy Lessons*: flood insurance purchase rates in unaffected regions spike 100–200% within weeks of distant anchor flood event despite no change in actuarial flood risk; first quantitative proxy for PM mispricings — 3–6pp overpricing at YES=0.20 extrapolated from 100–200% insurance demand spike in zero-risk regions
8. **Palm (1995, Westview Press)** — earthquake insurance demand in non-epicenter California counties: 30% purchase spike in counties with no seismic exposure change after Northridge earthquake; independent replication of Kunreuther mechanism; confirms availability bias in risk perception is cross-geographic and not explained by information updating

---

### Anti-Prim Escape Hatches (3 formal)

**(A) Historical scan gate (pre-deployment, mandatory):**
Run GDELT GKG archive (2022–2026) + Polymarket resolution API: identify all anchor events meeting salience/surprise criteria; find all same-category target markets that triggered the YES spike criteria; check resolution outcomes. **If ≥ 50% resolved YES → anchor events are informative, not distorting → retire Mode A and/or Mode B as applicable.** This scan must be completed before any own-data validation.

**(B) Rolling performance gate (live, per-mode):**
Own-data rolling 20-trade WR < 50% per mode → suspend that mode pending investigation. WR < 50% for 2 consecutive 20-trade windows → retire mode permanently. The 50% threshold is the break-even floor before fees at α=0.10 Kelly sizing.

**(C) Frequency gate (per-mode, annual):**
Fewer than 5 qualifying anchor events per year across 2 consecutive years → insufficient signal frequency for the mode's confound gates to be calibrated against real data. Lower salience threshold by one step (e.g., 1,000 → 750) and re-evaluate. If still < 5/year after threshold reduction → retire mode.

---

### What remains for sophisticated

1. **N_eff correlation adjustment:** Multiple active anchor events may trigger overlapping Mode A/B signals. At intermediate, the N_eff correction is not formalised. Sophisticated tier requires: if ≥ 2 active anchor events in same GDELT category within 14 days, treat open positions as correlated — reduce Kelly N_eff proportionally (N_eff ≤ 3 concurrent positions before correlation discount).

2. **Salience quantile calibration:** The 1,000 GDELT article/48h threshold is currently a heuristic (intended to capture 90th percentile event salience). Sophisticated tier requires: calibrate threshold against actual GDELT GKG distribution by category (e.g., natural disaster vs political violence may have different article count distributions); set mode-specific thresholds at verified 90th percentile.

3. **Entity-category NLP classifier:** The "same GDELT category" matching requires a PM market entity classifier. Intermediate assumes this is available (shared infrastructure with semantic-correlation-pair-trade); sophisticated tier requires formal evaluation of classifier precision/recall and inclusion of its FPR in the anti-prim historical scan.

4. **Sentiment velocity asymmetry:** Gennaioli-Shleifer (2010) predicts that the salience effect should be stronger when the anchor event is a high-severity outlier (not merely a high-frequency event). Sophisticated tier: add GDELT severity score as a second salience axis; test whether the fade signal is stronger for "low-frequency, high-severity" anchor events vs "high-frequency, moderate-severity" events — aligns with salience theory's within-category predictions.

---

### Bank State Change

- naive: 9 → 8 (anchor-event-recency-bias-fade elevated; naive file retained as historical)
- intermediate: 13 → 14
- sophisticated: 15 (unchanged)
