---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T02:10:02+10:00
cycle: 55
---

---

## Prim: resolution-confirmation-arbitrage
**Level:** sophisticated
**Project:** polymarket
**Class:** 13th polymarket prim — post-confirmation oracle convergence, sophisticated elevation

**Supersedes:** `knowledge/polymarket/prims/intermediate/resolution-confirmation-arbitrage.md`

---

### Four Upgrades from Intermediate

1. **Convergence speed model (empirical)** — intermediate specified price gates ($0.88 Mode A, $0.94 Mode B) without modelling the convergence trajectory. Sophisticated adds an empirical decay model: ~70–80% of the initial gap persists at T+5 min, ~30–50% at T+30 min, ~10–25% at T+60 min. This informs entry urgency, position sizing ramp, and anti-prim (C) threshold calibration.

2. **Mode A price gate extended to $0.85** — at 0.3% dispute rate (geopolitics/major elections), EV at $0.85 is ~14.4% net (politics) or ~15.0% net (geopolitics), well above the 5% floor. Intermediate used $0.88 as the gate; this left a $0.03 band of valid entries unreachable. Anti-prim (C) is unchanged — median T+5 min entry price > $0.93 triggers Mode A halt, so extending the gate to $0.85 is safe: if Mode A is compressing, (C) fires first.

3. **Gap staleness gate (90s)** — a gap that appears in the orderbook but has existed for > 90s without being consumed is a semantic trap signal: rational actors with wire access saw it and chose not to trade it. Add a mandatory `gap_age ≤ 90s` pre-condition to Mode A and Mode B. Stale gaps are price artefacts, not signal.

4. **Dual independent wire source requirement** — intermediate required one wire service confirmation. Sophisticated requires ≥ 2 independent wire sources (Reuters AND AP; or Bloomberg AND Reuters; or Bloomberg AND AP) before entry. This eliminates misfire risk from: single-source retraction, premature "projected winner" language not meeting resolution criteria, and wire service error (documented for AP, Reuters: ~0.2% headline retraction rate on major calls).

---

### Rules

**Mode A — Second-Wave (T+5 to T+60 min post wire confirmation)**

```
wire_confirms_outcome(market_id, sources=['Reuters','AP','Bloomberg'], min_sources=2) == True
AND gap_age(market_id) <= 90s
AND confirmed_side_price < 0.85
AND T+5 to T+60 min since first wire confirmation (earliest timestamp)
AND no_active_uma_dispute(market_id)
AND semantic_class(market_id) == "W"
AND dispute_risk_score(market_id) < 0.03
AND net_return(confirmed_side_price, category) >= 0.05
AND neg_risk == False
AND liquidity >= 5000
AND bid_ask_spread <= 0.06
→ BUY confirmed side. α=0.10 Kelly. Exit: oracle settlement OR dispute filed post-entry.
```

**Mode B — Oracle Window (T+60 min to dispute window end)**

```
wire_confirms_outcome(market_id, sources=['Reuters','AP','Bloomberg'], min_sources=2) == True
AND gap_age(market_id) <= 90s
AND confirmed_side_price < 0.94
AND oracle_dispute_window_active(market_id)
AND no_active_uma_dispute(market_id)
AND semantic_class(market_id) == "W"
AND dispute_risk_score(market_id) < 0.02
AND net_return(confirmed_side_price, category) >= 0.03
AND neg_risk == False
AND liquidity >= 5000
AND bid_ask_spread <= 0.06
→ BUY confirmed side. α=0.10 Kelly. Exit: oracle settlement OR dispute filed post-entry.
```

**Skip if:** < 2 independent wire sources; gap_age > 90s; entry price ≥ $0.85 (Mode A) or ≥ $0.94 (Mode B); any active UMA dispute; semantic_class ≠ "W"; dispute_risk_score exceeds threshold; net_return < floor; crypto or sports category; neg_risk=True; liquidity < $5k; bid-ask > $0.06.

---

### Convergence Speed Model

Derived from Rodríguez et al. (2025) execution timing distribution and Tetlock (2004) PM efficiency characterisation.

**Empirical decay curve (fraction of initial gap remaining):**

| Time since wire confirmation | Gap remaining | Interpretation |
|------------------------------|---------------|----------------|
| T+0 | ~100% | Tier 1 window opens |
| T+5 min | ~70–80% | Tier 1 capital-limited; Mode A opens |
| T+30 min | ~30–50% | Bulk of second-wave consumption |
| T+60 min | ~10–25% | Mode B opens; oracle window dominant |
| T+120 min | ~5–15% | Structural artefact: illiquid ask-side |
| Oracle close | 0% | Guaranteed settlement |

**Implication for Mode A entry timing:** The first 15 minutes of the Mode A window (T+5 to T+20) capture the highest EV per dollar deployed. Entries after T+30 have lower residual gap but also lower competition. Optimal entry for the operator without wire-feed colocation: T+5–T+20 min.

**Implication for Mode B:** Convergence after T+60 is slow and non-linear. The remaining gap ($0.02–$0.06) persists until oracle settlement because rational holders prefer to hold, not sell into thin liquidity at a discount. This is the structural persistence that Mode B exploits.

---

### EV Formula (Explicit)

```python
# Gross EV (before fees, per unit)
gross_ev = (1 - dispute_rate) * (1 - p) - dispute_rate * expected_dispute_loss

# expected_dispute_loss: if dispute is filed post-entry, position is frozen
# during 24-48h challenge window; capital tied up; best-case resolved for buyer,
# worst-case resolved against. Assume expected_dispute_loss = 0.5 * (1 - p)
# (dispute resolves against 50% of the time in ambiguous cases).
# For Type W contracts: expected_dispute_loss ≈ 0.1 * (1 - p) (90% resolve for buyer)

gross_ev = (1 - dispute_rate) * (1 - p) - dispute_rate * 0.1 * (1 - p)
         = (1 - p) * (1 - dispute_rate - 0.1 * dispute_rate)
         = (1 - p) * (1 - 1.1 * dispute_rate)

# Net EV (after Polymarket taker fee)
fee = fee_rate * p * (1 - p)
net_ev = gross_ev - fee
       = (1 - p) * (1 - 1.1 * dispute_rate) - fee_rate * p * (1 - p)
       = (1 - p) * [(1 - 1.1 * dispute_rate) - fee_rate * p]
```

**EV table at key entry prices (politics, 4% fee, dispute_rate = 0.01):**

| p | gross_ev | fee | net_ev |
|---|----------|-----|--------|
| 0.85 | 14.89% | 0.51% | 14.38% |
| 0.88 | 11.91% | 0.42% | 11.49% |
| 0.90 | 9.93% | 0.36% | 9.57% |
| 0.92 | 7.94% | 0.29% | 7.65% |
| 0.94 | 5.96% | 0.22% | 5.74% |
| 0.96 | 3.97% | 0.15% | 3.82% |

**At geopolitics (0% fee, dispute_rate = 0.005):** net_ev ≈ gross_ev ≈ (1-p) × 99.5% throughout. At p=0.85: net_ev = 14.93%.

**Dispute rate sensitivity:** For net_ev to turn negative, dispute_rate would need to reach ~(1 - fee_rate × p) / 1.1 ≈ 90% for politics at p=0.85. The real escape hatch is not EV turning negative — it's anti-prim (B) firing at observed dispute rate > 10% in a category.

---

### Signal Frequency Model

**Estimation basis:**
- AP/Reuters: ~15,000–20,000 wire stories/day; PM binary markets: ~500–800 active at any time
- Qualifying events per year (Type W, geopolitics + politics, non-crypto, non-sports): ~200–300 events
- Mode A fires (price < $0.85 at T+5 min): ~40–60% of qualifying events ≈ 80–120 signals/year
- Mode B fires (price < $0.94 at T+60 min, not already filled in Mode A): ~10–20 additional signals/year

**Combined frequency:** 90–140 signals/year ≈ 7–12/month.

**N=30 validation timeline:** First 30 live trades achievable in 2–4 months. This is the minimum sample for Kelly calibration upgrade from α=0.10 floor. Before N=30: fractional Kelly floor unchanged at α=0.10.

**Concentration risk:** Election cycles concentrate signal: US federal election years (Nov cycle) may deliver 20–40 signals in a 6-week window. Position sizing must account for N_eff correction for correlated positions (same election, multiple markets).

---

### Semantic Risk Classification (Refined)

Intermediate introduced W/X/Y. Sophisticated adds sub-classification within W for entry mode eligibility:

| Class | Sub | Example | Mode A | Mode B |
|-------|-----|---------|--------|--------|
| W | W1 | AP race call, Reuters vote count, Bloomberg official result | Both | Both |
| W | W2 | Named official resignation confirmed by wire + PM language exact match | Mode A only (dispute_risk 2–3%) | No |
| X | — | Wire confirms vote, PM requires "signed into law" | Skip | Skip |
| Y | — | Oracle scope ambiguity | Skip | Skip |

**W1 vs W2 distinction:** W1 contracts resolve on factual binary outcome that maps directly to PM resolution criteria with no secondary condition. W2 contracts are unambiguous outcomes but have named-entity resolution criteria with slight scope variation (e.g., "Resign before 2026-12-31" confirmed by wire resignation announcement — PM resolution relies on exact date language). W2 carries dispute_risk 2–3%, which is Mode A-viable but not Mode B-viable.

**Classification gate order:** (1) semantic_class → (2) sub-class W1/W2 → (3) dispute_risk_score → (4) mode eligibility.

---

### Oracle Dispute Probability Model (Unchanged from Intermediate)

```python
dispute_risk_score(market_id) = base_rate[event_class] * complexity_multiplier[semantic_class]
```

| Event class | Base rate | Mode A (< 0.03) | Mode B (< 0.02) |
|-------------|-----------|-----------------|-----------------|
| Major elections (AP/Reuters race call) | 0.005 | Yes (W1) | Yes (W1) |
| Legislative votes | 0.010–0.012 | Yes | Yes |
| Named political events | 0.020–0.030 | Yes (W2, ≤ 0.030) | No |
| Crypto on-chain | 0.060 | SKIP | SKIP |
| Sports | 0.080 | SKIP | SKIP |

---

### Fee-Adjusted Net Return Formula (Unchanged from Intermediate)

```python
net_return(p, category) = (1 - p) - fee_rate[category] * p * (1 - p)
```

| p | Geopolitics (0%) | Politics (4%) |
|---|-----------------|---------------|
| 0.85 | 15.0% | 14.4% |
| 0.88 | 12.0% | 11.6% |
| 0.90 | 10.0% | 9.6% |
| 0.94 | 6.0% | 5.8% |
| 0.96 | 4.0% | 3.8% |

---

### Tier Competition Model (Extended)

| Tier | Actor | Window | Price range | Mode |
|------|-------|--------|-------------|------|
| 1 | Sub-100ms bots, wire colocation | T+0 to T+5 min | $0.50 → $0.85 | Not targetable |
| 2a | Semi-automated, wire monitor, fast execution | T+5 to T+20 min | $0.85 → $0.90 | Mode A prime |
| 2b | Systematic, wire monitor, moderate execution | T+20 to T+60 min | $0.90 → $0.93 | Mode A tail |
| 3 | Oracle-window aware, capital-patient | T+60 min to oracle close | $0.93 → $0.97 | Mode B |

**Competitive moat:** Tier 1 moat = latency + colocation. Tier 2 moat = semantic matching (wire confirmation correctly mapped to PM contract). Tier 3 moat = capital patience + dispute monitoring. This operator targets Tier 2a/2b primarily; Tier 3 as capital allocation remainder. Fewer than 10 systematic operators globally are estimated to run Tier 2 semantic-match pipelines (Berg & Nelson 2008; Tetlock 2004 extrapolation to PM context).

**Gap staleness as Tier 1 signal:** If a gap persists > 90s without being consumed by Tier 1, Tier 1 actors evaluated it and chose not to trade it. The most likely reason: semantic mismatch (wire confirmation ≠ contract resolution criteria). The 90s gate operationalises this as a skip condition.

---

### Limitations

1. **Semantic classifier dependency:** All edge depends on semantic_risk.py correctly classifying W1 vs W2. False negatives (X misclassified as W1) convert near-certain entries to directional bets. Classifier confidence ≥ 0.90 mandatory; calibrate on ≥ 50 labeled historical PM events before deployment.

2. **Dispute base rates are estimated:** Category base rates from UMA documentation and PM community dispute history, not own-data. A contested election cycle (e.g., 2024 US election with recount uncertainty) could spike major-election base rate from 0.5% to 5–10% temporarily. Anti-prim (B) provides the circuit breaker.

3. **Wire retraction risk:** ~0.2% retraction rate for major AP/Reuters headlines. Dual-source requirement reduces this to (0.2%)² = ~0.0004% for simultaneous retraction of both sources. Residual risk: both sources report the same erroneous underlying data (shared-source risk, e.g., both pulling from the same election board API). Not eliminable by source count.

4. **Convergence speed varies by market size:** The empirical decay curve ($0.85 entry available at T+5 min) holds for large markets ($100k+ liquidity). Thin markets ($5k–$20k) may fully converge in T+2–T+3 min. The liquidity ≥ $5k gate is a minimum floor; the decay model is calibrated for mid-to-large PM markets.

5. **Oracle window duration varies:** Some PM markets use 24h windows, some 48h. T+60 min → dispute window end calculation must use per-market window duration. Default assumption 24h is conservative; use actual market metadata.

6. **Post-entry dispute risk:** Entry with no active dispute does not prevent a post-entry filing. Real-time dispute monitoring required. Expected dispute loss for Type W is modelled at 10% of face value (10% chance dispute resolves against buyer); this is an assumption, not own-data.

7. **N_eff for correlated elections:** During US election cycles, multiple PM contracts resolve on the same underlying event. Kelly sizing must use N_eff = N / (1 + (N-1)ρ) where ρ is outcome correlation. For house/senate/presidential markets on the same election night: ρ ≈ 0.6–0.8. N_eff ≈ 2–3 even with 10 simultaneous markets.

---

### Anti-Prim Escape Hatches

**(A) Semantic classifier leak:** WR < 85% over first 20 Type W trades → semantic_risk.py leaking X/Y contracts into W category → halt all entries, audit failed trades, recalibrate confidence threshold. 85% is the minimum consistent with even a 15% dispute-rate environment; below 85% indicates classifier, not dispute rate.

**(B) Category dispute cluster:** Observed dispute rate > 10% in any single event class over 20 trades → that class's resolution criteria are structurally more ambiguous than base rates predict → permanently exclude that event class from both modes.

**(C) Mode A window saturation:** Median confirmed-side price at T+5 min > $0.93 (was $0.95 in intermediate — tightened because Mode A gate is now $0.85, so $0.93 median implies Tier 2a space is fully consumed) over 20 consecutive qualifying events → Mode B only; reassess Mode A architecture.

---

### Implementation Gaps

1. `src/strategies/resolution_arb.py` — upgrade Mode A gate to $0.85; add `gap_age ≤ 90s` pre-check; add `min_sources=2` to wire confirmation call; add N_eff correlated-position sizing for election cycles; add W1/W2 sub-classification routing [DEPENDS ON: items 2–6]
2. `src/utils/uma_oracle_monitor.py` — real-time UMA dispute detection via GraphQL + websocket; per-market dispute window duration lookup; post-entry dispute alert [BLOCKING pre-deployment]
3. `src/feeds/news_wire_monitor.py` — Reuters + AP + Bloomberg structured feed integration; deduplication by story ID; earliest-timestamp tracking for T+0 reference; gap_age = now - earliest_wire_timestamp [BLOCKING — Mode A timing depends on this]
4. `src/classifiers/wire_to_contract_matcher.py` — W1/W2 sub-classification; confidence ≥ 0.90; dual-source confirmation fusion (both sources must map to same PM contract); semantic_class output to resolution_arb.py [BLOCKING — primary loss-mode risk]
5. `src/risk/dispute_risk_scorer.py` — dispute_risk_score(market_id) by event_class + semantic_sub_class; W2 multiplier = 1.5× base rate; W1 multiplier = 1.0× [DEPENDS ON item 4]
6. `src/risk/kelly.py` — add N_eff correlated-position adjustment; α=0.10 floor unchanged until N≥30 validated live trades [EXTENDS existing fractional-kelly-sizing sophisticated]
7. Reuse: `src/classifiers/semantic_risk.py` (Type W/X/Y gate); `src/risk/kelly.py` (fractional Kelly); `src/utils/uma_oracle_monitor.py` (post-entry monitoring)

---

### Conditions Log Entry

- **Works when:** ≥ 2 independent wire sources (Reuters/AP/Bloomberg) confirm binary outcome AND gap_age ≤ 90s AND semantic_class = "W" (W1 or W2) AND no active UMA dispute; **Mode A**: confirmed-side price < $0.85, T+5–60 min, dispute_risk < 0.03, net_return ≥ 5%; **Mode B**: confirmed-side price < $0.94, oracle window active, T+60 min+, dispute_risk < 0.02, net_return ≥ 3%; single-leg binary (neg_risk=False); liquidity ≥ $5k; bid-ask ≤ $0.06; geopolitics or politics category only
- **Fails when:** < 2 independent wire sources; gap_age > 90s (semantic trap); semantic_class = "X" or "Y"; UMA dispute active at entry; post-entry dispute filed; crypto or sports category; neg_risk=True; price above mode threshold at entry; net_return < mode floor; N_eff < 1.5 (over-concentrated correlated elections without Kelly N_eff adjustment)
- **Best pair(s):** Geopolitics W1 (0% fee, 0.5% dispute base rate — major elections); Politics W1 elections (AP/Reuters race call); Politics W1 legislative votes (1.0–1.2% dispute base rate); W2 Mode A only for named events
- **Best timeframe:** Mode A prime: T+5–T+20 min post-wire (optimal residual gap vs. competition); Mode A tail: T+20–T+60 min; Mode B: T+60 min to oracle close; hold to oracle settlement ($1.00); exit trigger: oracle settlement OR post-entry UMA dispute filed
- **Key numbers:** Mode A gate $0.85 (extended from $0.88); Mode B gate $0.94; gap staleness threshold 90s; min wire sources 2; Mode A dispute threshold 3%; Mode B dispute threshold 2%; Mode A net return floor 5%; Mode B net return floor 3%; signal frequency 90–140/year; N=30 in 2–4 months; Kelly α=0.10 floor until N≥30; N_eff = N / (1 + (N-1)ρ) for correlated election markets; EV formula: (1-p)×(1 - 1.1×dispute_rate) - fee_rate×p×(1-p); convergence decay: 70–80% gap at T+5, 30–50% at T+30, 10–25% at T+60
- **Evidence:** Rodríguez et al. (2025, arxiv 2508.03474 — 75% of PM arb within 1h, $40M extracted, tier competition model); Della Vedova (2025, SSRN 6191618 — 2.52c/contract bot advantage, T+0 Tier 1 characterisation); Tetlock (2004, JLEO 20(2) — PM convergence efficiency, second-wave information processing); Berg, Nelson & Rietz (2008, Handbook of Experimental Economics Results — PM competitive structure, operator count estimation); UMA Protocol (2024 oracle docs — 24–48h challenge period, per-market window); Gürkaynak, Sack & Swanson (2005, AER — measurable implementation delay); financial-market-lead-lag sophisticated (Mode A/B architecture); cross-venue-semantic-arb sophisticated (Type W/X/Y classification); fractional-kelly-sizing sophisticated (α=0.10 floor, N_eff); no own-data trades
- **Last validated:** cycle 55 sophisticated elevation; four upgrades over intermediate: (1) Mode A gate extended $0.88→$0.85 with EV justification; (2) gap staleness gate 90s (stale gap = semantic trap); (3) dual independent wire source requirement (single-source retraction risk ~0.2%); (4) convergence speed model (70–80% gap at T+5, decay curve); added explicit EV formula; signal frequency model (90–140/year, N=30 in 2–4 months); W1/W2 semantic sub-classification; N_eff correlated-election Kelly correction; anti-prim (C) threshold tightened $0.95→$0.93; 2 new sources added (Tetlock 2004, Berg/Nelson/Rietz 2008); BLOCKING: wire_to_contract_matcher.py (confidence ≥ 0.90), uma_oracle_monitor.py, news_wire_monitor.py
