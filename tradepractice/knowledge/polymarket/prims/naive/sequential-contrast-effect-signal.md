---
name: sequential-contrast-effect-signal
level: naive
project: polymarket
parent_prim: none
created: 2026-04-13
last_validated: never
reaction_validated: no
---

## Prim: sequential-contrast-effect-signal
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule
Within 7 days of a high-salience anchor event E_A resolving in category C (GDELT article_count_48h > P90_category; resolved against prior PM consensus ≥ 55%), identify a distinct minor event E_M in the same category C where:
- E_M has an active PM market with YES ∈ [0.12, 0.65]
- E_M GDELT article_count_48h ∈ [P40, P75] for that category (moderate salience — present but overshadowed)
- E_M YES price is ≤ (category_base_rate − 0.10) — underpriced relative to empirical resolution frequency
- entity_sim(E_A, E_M) < 0.70 (distinct events, not continuations or cascade stages)
- E_M resolution > 14 days remaining
- E_M market liquidity ≥ $5k; bid-ask ≤ $0.05
- ACLED/NOAA conditions at E_M entity location are STABLE (no deterioration ≥ +20% ACLED delta or NOAA MODERATE+ alert within 72h — information confound guard)

→ **BUY YES on E_M.** α = 0.10 Kelly floor (uncalibrated mandatory).

**Exit:** gap to YES closes within 5 pp of category base rate; OR anchor E_A GDELT velocity < 0.3× peak (anchor fully decayed); OR 14-day max hold; OR E_M resolution within 3 days.

### Mechanism
**Contrast effect in sequential probability judgment (Parducci 1965; Tversky & Simonson 1993):** When a dramatic high-salience event E_A occurs in category C, subsequent minor events E_M in the same category are judged against E_A's magnitude as a reference anchor. E_M appears "small" by comparison. PM participants systematically UNDERWEIGHT E_M's probability through three sub-mechanisms:

1. **Range-frequency contrast (Parducci 1965):** E_A sets a new dramatic maximum in the experiential range for category C. E_M, being moderate in salience, is deflated relative to this new range maximum. Participants estimate P(E_M) by where E_M falls in the recalibrated range — lower than the objective base rate.

2. **Attention diversion:** E_A consumes news-cycle capacity and forecasting attention. Skilled PM participants (superforecasters, systematic traders) focus on E_A's aftermath. E_M is priced primarily by less-calibrated retail during E_A's shadow period.

3. **Coherent arbitrariness (Ariely, Loewenstein & Prelec 2003):** E_A establishes an implicit "dramatic benchmark." E_M's probability estimate is constrained to appear consistent with being "less dramatic" than E_A's resolution — an arbitrary coherence constraint that is unrelated to E_M's actual base rate.

**Directional relationship to anchor-event-recency-bias-fade:**

| Signal | Direction | Target | Mechanism |
|---|---|---|---|
| anchor-event-recency-bias-fade | BUY NO | OTHER markets in category C (OVER-inflated by E_A's availability) | Availability heuristic: E_A increases perceived category frequency |
| **sequential-contrast-effect** | **BUY YES** | **E_M directly (UNDER-priced by comparison to E_A)** | **Contrast: E_M appears unlikely relative to dramatic E_A benchmark** |

The two prims are **complementary and non-conflicting**: from the same anchor event E_A, anchor-recency-bias fires BUY NO on OTHER markets over-inflated by E_A's salience; sequential-contrast fires BUY YES on the specific minor concurrent event E_M that is under-deflated by contrast. Both can be active simultaneously from a single anchor event, targeting different markets in opposite directions.

**Why this does NOT overlap with anchor-event-recency-bias-fade:**
- AERB-fade requires a TARGET market that is a DIFFERENT event from E_A — it INFLATES that other event
- sequential-contrast requires a TARGET market E_M that EXISTS CONCURRENTLY with E_A — it DEFLATES that concurrent event
- AERB-fade: E_A happened → OTHER events in category over-priced → BUY NO
- sequential-contrast: E_A happened → CONCURRENT E_M in category under-priced → BUY YES

### Conditions
- **Works when:** High-salience anchor event E_A resolved in past 7 days (GDELT > P90 category-specific threshold); a distinct concurrent E_M market in same category with moderate GDELT salience (P40–P75); E_M YES < category base rate − 10 pp; anchor E_A salience has peaked (velocity declining, not still rising); stable underlying conditions at E_M location (ACLED/NOAA gates); E_M is NOT a cascade dependent of E_A (no logical U→D relationship); E_M resolution > 14 days; E_M liquidity ≥ $5k
- **Fails when:** E_A provides genuine probability-REDUCING information about E_M (genuine confound — e.g., E_A was a peace agreement that reduces E_M conflict probability); E_M and E_A are sequential stages of same event (use conditional-probability-cascade-arbitrage); E_A salience is still rising (anchor effect not yet established); category base rate database unavailable (BLOCKING — shared with category-base-rate-neglect-fade); E_M in FLB zone (YES < 0.10 — defer to FLB prim); ACLED/NOAA conditions at E_M deteriorating (genuine information updating)
- **Best categories:** geopolitics_military (high anchor event frequency; stable actuarial base rates); elections_foreign (multiple concurrent elections create natural contrast opportunities); diplomatic_agreement (failed negotiations create contrast for subsequent talks)
- **Best timeframe:** Signal fires 2–7 days post-anchor-event; hold up to 14 days; NOT latency-sensitive

### Evidence
- **Source:** paper (behavioral psychology — contrast effects, range-frequency theory); hypothesis (PM-specific application untested)
- **Certainty:** guess-to-hypothesis; mechanism is well-grounded; PM-specific magnitude entirely unknown; zero own-data
- **Data:** 0 own trades; 0 own backtest
- **Citations:**
  - **Parducci, A. (1965, Psychological Review)** — Range-frequency theory: judged magnitudes are determined by where a stimulus falls in the range AND frequency distribution of contextual stimuli. A dramatic prior event (E_A) expands the range ceiling; subsequent moderate events (E_M) are deflated relative to this new ceiling. Foundational mechanism for underpricing of E_M.
  - **Tversky, A. & Simonson, I. (1993, Psychological Review)** — Context effects in choice: contrast effects cause options to appear less attractive when high-quality comparisons are available. Directly applicable: E_M appears less probable when the dramatic E_A outcome is salient.
  - **Schwarz, N. & Bless, H. (1992, Personality and Social Psychology Bulletin)** — Assimilation vs contrast effects in social judgment: salient exemplars trigger contrast when they are extreme outliers, pulling subsequent judgments AWAY from the exemplar. E_A as extreme outlier → E_M judgments deflated toward lower probability.
  - **Johnson, E.J. & Tversky, A. (1983, JPSP)** — Cross-category affect contamination; establishes that E_A affects E_M through affect and salience channels. This prim targets the CONTRAST component of this finding.
  - **Hogarth, R.M. & Einhorn, H.J. (1992, Psychological Review)** — Belief-adjustment model: sequential information processing anchors on prior extreme data points; subsequent adjustments underestimate recalibration needed. E_A provides a dramatic prior; E_M's probability is adjusted insufficiently upward from the implicitly deflated anchor.
  - **Ariely, D., Loewenstein, G. & Prelec, D. (2003, QJE)** — "Coherent arbitrariness": arbitrary first anchors have lasting, coherent effects on subsequent willingness-to-accept/pay. E_A's dramatic resolution establishes an implicit probability benchmark; E_M is priced to appear "coherently smaller."

### Limitations (7)
1. **Information vs. contrast confound (#1 blocker — identical to AERB-fade primary):** E_M may be genuinely less likely BECAUSE of E_A (e.g., E_A was a diplomatic breakthrough that reduces subsequent military escalation probability). The ACLED/NOAA stability gate partially addresses this but cannot fully separate genuine information updating from cognitive contrast. Calibration requires historical resolution scan: if > 50% of E_M markets priced below base rate after E_A anchor resolve as YES → mechanism valid; if < 50% → confound dominates → anti-prim A.
2. **Category base rate database BLOCKING:** Signal requires knowing E_M category base rate to compute the "underpriced by ≥ 10 pp" gate. This is the EXACT same infrastructure as category-base-rate-neglect-fade. Cannot deploy without it. Timeline: same as CBRNF database construction.
3. **GDELT calibrated baseline BLOCKING:** The P40–P75 salience range for E_M requires a calibrated GDELT article count baseline per category. Same infrastructure dependency as anchor-event-recency-bias-fade (P90 threshold calibration). Cannot deploy without it.
4. **Mechanism direction ambiguity:** Under some conditions, E_A creates AVAILABILITY inflation rather than CONTRAST deflation for E_M. Schwarz & Bless (1992) identify the conditions: contrast fires when E_A is perceived as an OUTLIER (uncommon, dramatic); assimilation fires when E_A is perceived as TYPICAL (common, representative). The GDELT P90 threshold (E_A is an outlier by definition) biases toward contrast, but this boundary is not sharply defined. Mode A (natural disasters) is most likely pure contrast. Mode B (political violence) has more ambiguity.
5. **Directional overlap with AERB-fade:** Both prims are triggered by the SAME anchor event E_A. When both fire (AERB on other markets = BUY NO; sequential-contrast on E_M = BUY YES), they share anchor event infrastructure but their N_eff correlation is moderate (ρ ≈ 0.30 — same trigger, different targets). Kelly N_eff reduction required when both active from same E_A.
6. **Signal frequency:** Requires BOTH a qualifying anchor event (P90 GDELT) AND a co-occurring moderate-salience E_M (P40–P75) in the same category. Estimated 8–20 qualifying pairs/year (lower than AERB-fade which only requires E_A, not the concurrent E_M pairing).
7. **Category taxonomy dependency:** The P40–P75 range for E_M requires knowing the GDELT category baseline. Without the category-specific per-day article count distributions, the salience thresholds cannot be computed.

### Implementation
```python
# src/signals/sequential_contrast_detector.py
# BLOCKED: category_base_rates.py + GDELT baseline calibration must exist first

from src.data.category_base_rates import CategoryBaseRateDB
from src.data.gdelt import get_gdelt_velocity, get_category_p90_threshold
from src.classifiers.category_tagger import classify_market
from src.utils.entity_sim import compute_entity_sim

CONTRAST_GAP_THRESHOLD = 0.10      # YES must be this far below category base rate
MIN_LIQUIDITY = 5000
MAX_BID_ASK = 0.05
MIN_RESOLUTION_DAYS = 14
ANCHOR_WINDOW_DAYS = 7              # look-back for anchor events
EM_SALIENCE_MIN_PCTL = 0.40         # E_M must have moderate (not zero) coverage
EM_SALIENCE_MAX_PCTL = 0.75         # E_M must not itself be a high-salience event
ENTITY_SIM_CUTOFF = 0.70            # E_A and E_M must be distinct events
KELLY_ALPHA = 0.10                  # mandatory floor

def scan_contrast_opportunities(
    active_markets: list[dict],
    recent_anchor_events: list[dict],  # E_A events: {entity, category, resolution_time, gdelt_count}
    base_rate_db: CategoryBaseRateDB,
    gdelt_baselines: dict,             # {category: {p40: float, p75: float, p90: float}}
) -> list[dict]:
    """
    For each recent high-salience anchor event E_A, scan for concurrent
    moderate-salience markets E_M in the same category that are underpriced
    by contrast deflation.
    """
    signals = []

    for anchor in recent_anchor_events:
        days_since_anchor = (datetime.now() - anchor['resolution_time']).days
        if days_since_anchor > ANCHOR_WINDOW_DAYS:
            continue

        anchor_category = anchor['category']
        baselines = gdelt_baselines.get(anchor_category, {})
        if not baselines:
            continue

        for market in active_markets:
            em_category, conf = classify_market(market['title'])
            if conf < 0.75 or em_category != anchor_category:
                continue

            entity_sim = compute_entity_sim(anchor['entity'], market['title'])
            if entity_sim >= ENTITY_SIM_CUTOFF:
                continue  # E_M is a continuation of E_A

            em_gdelt = get_gdelt_velocity(extract_entity(market['title']))
            em_count_48h = em_gdelt['velocity_24h'] * 2
            if not (baselines['p40'] <= em_count_48h <= baselines['p75']):
                continue  # E_M too quiet or itself too salient

            yes = market['yes_price']
            if not (0.12 <= yes <= 0.65):
                continue
            if market['liquidity'] < MIN_LIQUIDITY:
                continue
            if market['bid_ask_spread'] > MAX_BID_ASK:
                continue
            if market['resolution_days'] < MIN_RESOLUTION_DAYS:
                continue

            cell = base_rate_db.get_rate(em_category)
            if cell is None or not cell['eligible']:
                continue

            base_rate = cell['base_rate']
            gap = base_rate - yes
            if gap < CONTRAST_GAP_THRESHOLD:
                continue

            signals.append({
                'market_id': market['id'],
                'direction': 'YES',
                'gap_below_base_rate': gap,
                'base_rate': base_rate,
                'category': em_category,
                'anchor_entity': anchor['entity'],
                'days_since_anchor': days_since_anchor,
                'em_salience_pctl_approx': em_count_48h / baselines['p90'],
                'kelly_alpha': KELLY_ALPHA,
                'mechanism': 'sequential_contrast_effect',
            })

    return signals
```

**Required infrastructure (all BLOCKING):**
- `src/data/category_base_rates.py` — shared with category-base-rate-neglect-fade; must be built first
- `src/data/gdelt.py` — GDELT article-count baseline per category (P40/P75/P90 by category; shared with anchor-event-recency-bias-fade)
- `src/classifiers/category_tagger.py` — NLP category classifier (shared with CBRNF and AERB-fade)
- `src/utils/entity_sim.py` — cosine similarity between anchor entity and E_M market title (shared with anchor-event-recency-bias-fade)

### Conditions Log Entry
- Works when: High-salience anchor event E_A resolved in past 7 days (GDELT > P90 category-specific); distinct minor concurrent event E_M in same category (GDELT P40–P75); E_M YES < category_base_rate − 10 pp; entity_sim(E_A, E_M) < 0.70; stable conditions at E_M location (no ACLED/NOAA deterioration); E_M resolution > 14 days; E_M liquidity ≥ $5k; bid-ask ≤ $0.05
- Fails when: Genuine probability-reducing confound from E_A (ACLED/NOAA gates fail); cascade relationship (E_M logically requires E_A outcome — use conditional-probability-cascade-arbitrage); category base rate database unavailable (BLOCKING); E_M in FLB zone (YES < 0.10); anchor still rising (not yet at peak)
- Last validated: never

## Refinement History
- 2026-04-13 (cycle 136): Created as naive prim. 23rd polymarket signal class. Contrast effect mechanism (Parducci 1965 range-frequency; Tversky & Simonson 1993 contrast in choice) — the DEFLATION counterpart to anchor-event-recency-bias-fade's INFLATION mechanism. Both prims triggered by same high-salience anchor event but predict OPPOSITE DIRECTIONS on DIFFERENT target markets: AERB-fade → BUY NO on OTHER over-inflated markets; sequential-contrast → BUY YES on concurrent E_M under-deflated market. 6 academic anchors; 7 limitations; BLOCKING: category base rate database + GDELT calibrated baseline (shared infrastructure with CBRNF and AERB-fade). Zero own-data.

## Next Refinement Path (Intermediate)
Three upgrades required:
1. **Historical resolution scan:** Using GDELT GKG 2022–2026 archive + PM resolution API: identify all (E_A high-salience, E_M moderate-salience same category) pairs; check whether E_M markets that met entry criteria resolved YES or NO. If < 50% resolved YES → contrast deflation mechanism absent or confound dominates → retire as anti-prim A. Target: ≥ 60% YES resolution rate on N ≥ 20 qualifying pairs.
2. **Two-mode structure:** Mode A (natural disasters — lowest information confound, actuarial rates stable) vs Mode B (political violence/elections — moderate confound, ACLED delta gate required). Distinct spike thresholds per mode (analogous to AERB-fade intermediate).
3. **Contrast vs availability direction classifier:** Formalise when E_A triggers contrast (E_M underpriced → BUY YES) vs availability (E_M overpriced → BUY NO). Decision boundary: if anchor-event-recency-bias-fade ALSO fires on E_M in the same direction → availability dominates; if AERB-fade is silent on E_M → contrast mechanism active. Use GDELT salience tier of E_A (HIGH-tier E_A → stronger contrast; MODERATE-tier → more assimilation) as the classifier per Schwarz & Bless (1992).
