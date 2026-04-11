---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T11:30:00+10:00
cycle: 75
---

---

## Prim: anchor-event-recency-bias-fade
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule

```
anchor_event: major binary PM market has resolved within the past 7 days in category C
  AND anchor salience: GDELT article count for anchor entity > 1,000 in the 48h post-resolution window
  AND anchor outcome was SURPRISING (resolved against prior PM consensus ≥ 55%)

target_market: Polymarket YES price ∈ [0.15, 0.55]
  AND market opened or repriced ≥ 8pp within 7 days of anchor_event
  AND same category C (political violence / geopolitical conflict / natural disaster / electoral)
  AND entity_sim(target_market, anchor_event) < 0.70 (NOT the same event's continued coverage)
  AND resolution > 14 days (sufficient time for recency effect to dissipate before entry)

→ BUY NO (fade recency-inflated YES price toward base-rate expectation)
→ Kelly α = 0.10 (uncalibrated floor)
→ EXIT: 14-day max hold OR when GDELT anchor entity velocity < 0.5× peak (recency effect dissipated)
```

### Mechanism

After a major, attention-commanding event in category C resolves (election result, military engagement, earthquake), the event remains cognitively accessible to Polymarket participants for days-to-weeks via continuing news coverage. Tversky & Kahneman's availability heuristic predicts that events easily recalled from recent memory will be assigned inflated subjective probabilities in forecasting tasks. Applied to prediction markets:

1. **Attention salience**: GDELT article counts for anchor entity remain > 50% of post-resolution peak for 5–10 days (estimated from GDELT repetition decay pattern; Peress 2014). Participants drawn to category C markets by ambient media presence.
2. **Frequency over-estimation**: PM participants opening or repricing similar-category markets in the 7-day anchor window over-estimate the base rate of similar future events. A major earthquake in Country A elevates YES prices on "Will there be a major earthquake in Country B within 90 days?" above the actuarial base rate.
3. **Reversion**: As anchor event coverage normalises (Peress 2014 repetition decay), recency-driven probability inflation dissipates over 14 days and prices converge toward actuarial base rates.

**Distinct from all 15 existing polymarket prims:**
- `favourite-longshot-bias-fade`: static probability distortion for extreme values (YES < 0.07 or > 0.93); operates always-on regardless of anchor events; this prim is *dynamically triggered* by external anchor events
- `no-event-time-decay-fade`: within a SINGLE market over time — YES decays too slowly as time passes without the event occurring (anchoring to opening price); this prim is CROSS-MARKET — an anchor event in market A inflates similar market B
- `news-velocity-informed-directional`: trades the *direction* of a developing news story in real-time (15–45min entry window); this prim fades the *subsequent* recency-driven overpricing in similar markets (7–14 day hold)
- `resolution-confirmation-arbitrage`: activates AFTER the SPECIFIC event resolves to buy the confirmed leg at $0.85–$0.97; this prim fades SIMILAR markets triggered by the anchor's salience
- `superforecaster-consensus-lead`: uses calibrated forecaster consensus as reference probability (Metaculus/GJP); this prim uses actuarial base rate as reference, no external forecaster required

### Evidence

| # | Source | Finding | Application | Limitation |
|---|--------|---------|-------------|------------|
| 1 | **Tversky & Kahneman (1974, Science)** | Availability heuristic: events judged more probable when more cognitively available; recent dramatic events inflate perceived frequency of similar future events; one of the most replicated findings in cognitive psychology | **Primary mechanism anchor**: after salient event resolves, similar-event markets are overpriced | Established in laboratory settings (word frequency tasks, mortality risk); PM generalisation is analogical |
| 2 | **Kahneman & Tversky (1979, Econometrica)** | Prospect Theory: probability weighting function γ ≈ 0.65 overweights recent experience; events that have recently occurred are cognitively over-sampled → subjective probability elevated above actuarial | **Probability weighting grounding**: recent-event YES overpricing is same probability distortion mechanism as FLB but dynamically triggered, not static | PM-specific γ calibration not available; Prospect Theory field applications typically static |
| 3 | **Barber & Odean (2008, RFS)** | "All That Glitters": retail investors are net buyers of attention-grabbing stocks (news mentions, extreme price moves) on the buy side; attention drives trading, not information; equity reversion after attention spike documented | **Retail PM buyer behaviour**: by analogy, PM retail participants drawn to "exciting" event categories after high-salience anchor; over-buying YES on similar markets; attention spike followed by reversion | Equity context; financial-motive (profit/loss); PM participants may have lower reversion because position limits are softer |
| 4 | **Greenwood & Shleifer (2014, RFS)** | "Expectations of Returns and Expected Returns": survey and fund flows show extrapolation of recent dramatic events → systematic overestimation of continuation; retail forecast errors correlated with recent salient experience | **Extrapolation bias**: PM participants extrapolate from recent anchor event frequency toward similar future events; fading this extrapolation is the alpha source | Survey-based (institutional investor expectations); PM retail is different population; magnitude of extrapolation unknown in PM context |

- **Certainty:** hypothesis — 4-source academic basis; all sources are analogical (laboratory, equity market); no peer-reviewed study directly tests recency/availability bias in binary prediction markets
- **Data:** 0 own trades
- **Critical risk:** YES overpricing may reflect genuine new information (anchor event reveals higher base rate for the category — e.g., major earthquake reveals fault-line stress) rather than behavioural bias; distinguishing "information update" from "availability bias" is the central identification challenge

### Limitations (6)

1. **Information vs bias confound (PRIMARY):** After a major earthquake in Country A, YES on "earthquake in Country B?" may be elevated because (a) availability bias inflates perceived frequency (behavioural — tradeable) OR (b) seismologists revised upward inter-connected fault risk (information — not tradeable). Naive prim cannot separate these. The YES price rise could be efficient pricing of genuine information, not bias.
2. **Anchor event detection undefined:** "GDELT article count > 1,000 in 48h" is an unvalidated heuristic. What constitutes a "major" vs "minor" event sufficient to generate salience-driven overpricing is not calibrated. Threshold may produce too many or too few anchor events.
3. **Category similarity undefined:** "Same category C" requires a semantic classifier. Political violence, inter-state conflict, civil war, and terrorism overlap. "Same category" is not well-specified; category boundaries will determine signal frequency and quality significantly.
4. **YES range [0.15, 0.55] is uncalibrated:** Availability-driven overpricing may manifest across the full [0.05, 0.90] range; the specific range is derived from intuition about where base-rate overestimation is most visible (moderate probabilities), not from data. FLB already covers < 0.07; time-decay covers gradual decay above 0.35; the gap range is uncertain.
5. **14-day hold assumes predictable recency decay:** Peress (2014 JF) documents repetition decay in equity price impact; the decay rate for cognitive availability of PM anchor events is unknown. The 14-day hold window is derived from Barber & Odean (2008) attention reversion timeline in equities (1–4 weeks); PM-specific timeline not measured.
6. **Surprising outcome requirement adds tail event dependency:** "Resolved against prior PM consensus ≥ 55%" limits anchor events to genuinely surprising outcomes. This reduces signal frequency severely (only ~10–15% of PM markets resolve against the dominant probability). Most elections, regulatory decisions, and geopolitical events resolve in the direction the PM priced; true surprises are rare, limiting deployment frequency to possibly < 1–2 events/month.

### Files

- `knowledge/polymarket/prims/naive/anchor-event-recency-bias-fade.md` — created this cycle
- `knowledge/epistemic-index.md` — 16th polymarket prim row added (naive section)
- `knowledge/conditions-log.md` — anchor-event-recency conditions appended

### Prim status (cycle 75)

| Prim | Level |
|------|-------|
| binary-arb-completeness | sophisticated |
| spread-capture-market-making | sophisticated |
| fractional-kelly-sizing | sophisticated |
| ensemble-forecast-edge | sophisticated |
| obi-informed-directional | sophisticated |
| cross-venue-semantic-arb | sophisticated |
| semantic-correlation-pair-trade | sophisticated |
| financial-market-lead-lag | sophisticated |
| favourite-longshot-bias-fade | sophisticated |
| no-event-time-decay-fade | sophisticated |
| resolution-confirmation-arbitrage | sophisticated |
| superforecaster-consensus-lead | sophisticated |
| llm-ensemble-probability-edge | sophisticated |
| political-hedge-instrument-signal | sophisticated |
| news-velocity-informed-directional | sophisticated |
| **anchor-event-recency-bias-fade** | **naive ← this cycle** |

### Next cycle recommendations

1. **(A) RESEARCH: Elevate anchor-event-recency-bias-fade to intermediate** — primary task: resolve the information vs bias confound (Limitation #1) by finding historical PM examples where category prices moved after anchor events AND subsequent resolution data shows the price spike was NOT justified (i.e., actual event rate returned to historical base rate). Requires: GDELT event category classification + Polymarket historical resolution database.
2. **(B) RESEARCH: Calibrate anchor salience threshold** — scan GDELT GKG for "major" events in political violence, natural disaster, electoral, and geopolitical categories 2022–2026; measure article count distribution; set threshold at 90th percentile of category event salience distribution; estimate anchor event frequency per category per year.
3. **(C) SHARED PIPELINE: anchor detection reuses news-velocity GDELT feed** — anchor event detection (GDELT article count by entity by time window) is the same infrastructure as `news-velocity-informed-directional` entity-matching pipeline; development effort is shared; note in both prims' implementation gaps.
4. **(D) ANTI-PRIM CONSIDERATION:** If Limitation #1 cannot be resolved (information update vs bias is fundamentally unidentifiable without access to seismology/intelligence data), this prim may be an anti-prim. Intermediate elevation requires finding at least 10 historical cases where (i) anchor event → similar market spike, AND (ii) target market resolved NO (confirming the spike was bias not information). If historical resolution data shows < 50% NO resolution in those cases, retire the prim.
