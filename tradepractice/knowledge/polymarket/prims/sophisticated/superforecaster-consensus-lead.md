---
name: superforecaster-consensus-lead
level: sophisticated
project: polymarket
parent_prim: intermediate/superforecaster-consensus-lead
created: 2026-04-11
last_validated: never
---

## Prim: superforecaster-consensus-lead
**Level:** sophisticated (refined from intermediate)
**Project:** polymarket
**Parent:** intermediate/superforecaster-consensus-lead

### What Changed from Intermediate

| Dimension | Intermediate | Sophisticated |
|---|---|---|
| Threshold structure | Flat: Mode A ≥ 10%, Mode B ≥ 8% | **3-tier source quality**: GJP/Almanis ≥ 8%; Metaculus tracked ≥ 10%; Metaculus community ≥ 12% — Atanasov et al. (2024): performance-weighted pools outperform CDA markets; unweighted community *ties* CDA; flat threshold treats unequal sources equally |
| Horizon model | 7-day floor (binary: below = no signal) | **Peaked calibration window**: < 7d PM wins; 14–45d peak edge; 45–90d declining; > 90d unreliable — Wiley (2012) establishes the < 7d boundary; Mellers (2015) mechanism decomposition implies peak at intermediate horizons when base-rate anchoring maximally separates from narrative bias |
| Signal frequency | "Unknown" | **~30–100 qualifying events/year (derived)** — 50–200 co-listed geopolitics pairs active × 15–25% with ≥ 8% divergence × quality filter; **N=30 achievable in 3–12 months** (vs financial-market-lead-lag's 4–8 years); statistically tractable by design |
| Competitive structure | "Convergence mechanism is weak" | **Slow-edge moat**: execution-irrelevant; competed by semantic matching quality not speed; estimated < 20 systematic participants globally; edge compression is information-diffusion-driven (months), not HFT-infrastructure-driven (milliseconds) |
| Predictor gate | ≥ 150 (Mode A), ≥ 100 (Mode B) raw count | **Tracked-forecaster concentration gate**: ≥ 15% of predictors with tracked status (top quartile, performance-weighted) preferred over raw count — Atanasov et al. (2024) shows performance weighting is the operative variable |
| Anti-prim escapes | 2 informal | **3 formal escape hatches with exact thresholds** |
| Certainty | hypothesis (4 sources) | **hypothesis (8 sources + derived frequency + competitive structure; no direct trading WR study — ceiling permanently acknowledged)** |

### Rule (Sophisticated)

**Source-quality-tiered Mode A — Fresh Divergence:**

| Source | Threshold | Predictor gate | Horizon |
|---|---|---|---|
| GJP / Almanis superforecaster consensus | ≥ 8% | Professional selection (no count gate) | 7–45 days |
| Metaculus tracked-forecaster subset | ≥ 10% | ≥ 15% tracked status in question community | 7–45 days |
| Metaculus community median | ≥ 12% | ≥ 200 predictors | 14–30 days |

Mode A additional gates: divergence ≤ 48h old; Metaculus last update < 24h; PM bid-ask ≥ 3%; geopolitics category only; NOT breaking news within 12h.

**Mode B — Persistent Calibration Gap:**
Any source divergence ≥ 8% persisted ≥ 72h AND Metaculus consensus stable (< 2pp change in 24h) AND ≥ 100 predictors AND resolution 30–90 days AND PM bid-ask ≥ 2% AND geopolitics or politics/finance.

**Both modes require:**
- Semantic equivalence via `metaculus_pm_matcher.py` [BLOCKING — no trade without this]
- PM liquidity $5k–$50k (below = illiquid; above = sophisticated PM participants present)
- Resolution horizon 7–90 days; **reject < 7 days unconditionally** (PM advantage)
- α=0.10 Kelly floor (mandatory — no calibration history)

**Exit:** divergence closes to < 2%, resolution, or 45-day hard stop (Mode A) / 90-day hard stop (Mode B)

### Mechanism (Formalized)

**Why Metaculus leads Polymarket (calibration-structural, not speed-structural):**
1. Score-incentivised forecasters apply base-rate anchoring + reference class forecasting; PM traders overweight recent narrative and anchor to prior prices
2. Metaculus de-biasing training: ~50% noise reduction, 25% bias reduction, 25% information improvement (Mellers 2015) — these are additive, not alternative mechanisms
3. Brier gap (0.111 vs 0.187) is the quantified calibration difference on matched events
4. Advantage peaks 14–45 days before resolution: at this horizon, financial incentives have not yet compressed PM prices toward true probability, while the calibration signal is fresh and high-information

**Convergence trigger (probabilistic, slow):**
NOT an institutional speed race. Mechanism:
1. As resolution approaches, PM participants who independently reference Metaculus (estimated 5–10% of PM volume setters for geopolitics) begin buying the underpriced side
2. Information cascade: once a visible PM participant trades toward the Metaculus price, others follow (Snowberg & Wolfers 2004: co-pricing is sequential)
3. Convergence is over days-to-weeks, not minutes — the entire hold horizon is the window, not a 30-minute burst

**Slow-edge structural contrast with financial-market-lead-lag:**

| Dimension | financial-market-lead-lag | superforecaster-consensus-lead |
|---|---|---|
| Why PM is wrong | Attention delay (seconds/minutes) | Base-rate neglect + narrative bias (days/weeks) |
| Lead source | CME (institutional, sub-second) | Metaculus (calibrated humans, daily updates) |
| Convergence speed | Minutes-to-hours | Days-to-weeks |
| Execution constraint | Speed (73% arb by bots < 100ms) | **Semantic matching quality** |
| Hold horizon | Minutes-to-days | Days-to-weeks (peak: 14–45d) |
| Competitive moat | Need co-location + institutional access | Need semantic matcher + API integration |
| Moat erosion trajectory | Fast (sub-minute in 2025, sub-second by 2027) | **Slow** — semantic complexity persists |

### Calibration-Horizon Curve

| Horizon | PM advantage | Metaculus advantage | Mode gate |
|---|---|---|---|
| T < 7d | **YES** — financial incentives, microstructure, recency anchor dominate | Stale or updating too slowly | **REJECT unconditionally** |
| T 7–14d | Mixed | Emerging | Mode A minimum viable; community threshold only (≥ 12%) |
| T **14–45d** | Partial | **Peak** — reference class weight maximized; narrative bias most separable from calibrated judgment | **Mode A optimal zone** |
| T 45–90d | Low | Good but declining | Mode B viable |
| T > 90d | Very low | High variance; calibration advantage uncertain | **REJECT both modes** |

Evidence: Wiley (2012) < 7d PM advantage (direct); Mellers et al. (2015) mechanism decomposition implies peak separation when base-rate anchoring is maximally useful relative to recency bias; Atanasov et al. (2024) team polls outperform CDA markets at 30–90d horizons.

### Signal Frequency Model (Derived)

| Stage | Count |
|---|---|
| Active Metaculus geopolitics/politics questions | ~2,000–4,000 |
| With Polymarket semantic equivalent (~2–5% co-listing, per 2601.01706 applied to Metaculus) | **40–200 pairs** |
| With resolution horizon 7–90 days | ~20–100 |
| With ≥ 8% divergence (15–25% of co-listed geopolitics pairs at any time) | **~5–20 active pairs** |
| Annual qualifying events (4× annual turnover at 7–45d holds) | **~30–100/year** |

**Statistical power implications:**
- N=30: achievable in **3–12 months** (vs financial-market-lead-lag 4–8 years)
- N=100: achievable in **12–36 months**
- WR margin at N=30: ±18% (95% CI); at N=100: ±10%
- **Most statistically tractable PM information-edge prim in the bank**

Conservative floor (50% semantic false-negative rate): 15–50/year.

### Competitive Structure — Slow-Edge Moat

**Who is trading this signal (estimated):**
1. **Automated Metaculus-API bots**: technically possible; requires semantic matcher (costly); estimated < 10 teams globally in 2026
2. **Manual PM traders referencing Metaculus**: exists; these ARE the convergence mechanism; scale = 5–10% of PM volume setters for geopolitics
3. **Systematic PM funds**: possibly 2–5 teams globally; most institutional PM activity is faster-signal oriented (OBI, arb, MM)

**Why the edge persists in 2026:**
- At 7-45 day hold horizons, execution speed is irrelevant — a 200ms system has zero advantage over a 5-minute system
- Semantic matching quality (not latency) is the barrier to entry
- Edge compression is information-diffusion-driven: edge decays as more PM participants discover Metaculus as a reference, not as HFT infrastructure improves
- Compression timeline: months-to-years, not milliseconds-to-seconds

**Moat erosion anti-prim triggers:**
- Polymarket native Metaculus API integration (would instantly close the gap)
- Large automated semantic matching deployment (months to build; 3-5 max competitors)

### Evidence — 8 Sources (unchanged; no direct WR study exists)

| Source | Finding |
|---|---|
| **Tetlock & Mellers (2015, Psych Sci)** | GJP superforecasters beat IC prediction markets by 30% Brier; beat unfiltered by 60% |
| **Manifund / Medium (2024-2025)** | Metaculus Brier **0.111** vs Polymarket **0.187** (~40% gap); 2022 US midterms: Metaculus ranked highest |
| **Atanasov, Mellers, Tetlock et al. (SSRN 4691513, 2024)** | **Performance-weighted** team polls outperform CDA markets; unweighted polls tie CDA — operative variable is weighting quality, not raw consensus. Grounds source-quality-tiered thresholds. |
| **Wiley (2012) — Economic Journal** | PM well-calibrated at < 1 year; **< 7 days: PM advantage** (financial incentives dominate); calibration NOT better in liquid markets — high-liquidity ≠ better-calibrated |
| **Good Judgment (2024)** | GJP outperformed futures markets by 30% for FOMC interest rate decisions — cross-domain calibration advantage confirmed beyond geopolitics |
| **Mellers et al. (2015, Psych Sci)** | Active de-biasing: ~50% noise reduction, 25% bias reduction, 25% information improvement — mechanism quantification |
| **Reichenbach & Walther (SSRN 5910522)** | PM 94% aggregate accuracy; 70% unprofitable — aggregate accuracy compatible with per-market exploitable divergences |
| **Snowberg & Wolfers (2004, JEP)** | PM and expert consensus co-price events **sequentially, not simultaneously** — directly anchors slow convergence model |

**Source quality ceiling (permanently acknowledged):** No peer-reviewed paper directly tests "Metaculus diverges from PM → resolve in Metaculus direction" as a trading signal with measured WR. Sophisticated tier = mechanism grounded + failure modes quantified + frequency model derived + competitive structure analyzed. Certainty stays at **hypothesis**.

### Key Numbers

| Metric | Value |
|---|---|
| Metaculus Brier score | **0.111** |
| Polymarket Brier score | **0.187** |
| Calibration gap | **~40%** |
| Peak calibration horizon | **14–45 days** |
| < 7-day horizon verdict | **PM advantage — unconditional reject** |
| GJP threshold | ≥ 8% divergence |
| Metaculus tracked threshold | ≥ 10% divergence |
| Metaculus community threshold | ≥ 12% divergence |
| Annual qualifying events | **~30–100 (derived)** |
| N=30 statistical horizon | **3–12 months** |
| Estimated systematic competitors | **< 20 globally** |
| Competitive moat type | Semantic matching quality (not execution speed) |
| Kelly floor | α=0.10 (no calibration history) |
| Realistic WR target | **55–65% (hypothesis from Brier gap — not measured)** |
| Breakeven WR at 4% fee, 1:1 R:R | 52% |
| Safe WR target (3× friction margin) | 57% |

### 10 Documented Limitations

1. **Semantic non-fungibility (#1)** — no automated matcher exists; manual review required; blocking implementation gap; cannot be eliminated, only gated via `metaculus_pm_matcher.py`

2. **< 7-day horizon inversion** — PM outperforms expert consensus at T < 7 days (Wiley 2012); any position with < 7 days remaining should exit or reduce immediately

3. **No direct WR evidence** — no paper or practitioner study measures "when Metaculus diverges ≥ 8%, what % resolves in Metaculus direction?"; this is the critical open question; prim remains hypothesis regardless of academic grounding

4. **Source quality hierarchy is aggregation-dependent** — Atanasov et al. (2024) shows unweighted community median *ties* prediction markets (not beats); the tiered thresholds (8/10/12%) are derived from this finding; applying flat 8% to community median is the intermediate's error

5. **Convergence mechanism is weak and slow** — no contractual force; relies on ~5–10% of PM volume setters referencing Metaculus; convergence can fail entirely (news breaks, Metaculus consensus is wrong, PM-native participants independently reach same probability)

6. **Frequency model is derived, not measured** — the 30-100/year estimate requires a 3-month semantic scan to validate; actual co-listing rate (2-5%) and divergence rate (15-25%) are extrapolated from arxiv 2601.01706 applied to Metaculus scale

7. **Metaculus domain specialization** — strongest calibration on OECD geopolitics and AI/technology milestones; non-Western geopolitics, sports, entertainment may not carry equivalent advantage; Mode A restricted to geopolitics for this reason

8. **Mode B resolution risk** — 30-90 day hold in wrong direction = full loss; no stop-loss prevents resolution-day loss if entered wrong; the 90-day hard stop limits opportunity cost but not directional risk

9. **Breaking news asymmetry** — when Metaculus diverges upward from PM (Metaculus says more likely), unscheduled bad news collapses the position immediately; 12h news gate manages scheduled events only

10. **PM sophistication gate (crude proxy)** — bid-ask ≥ 3% is a proxy for low sophistication; sophisticated PM participants can be present at any liquidity level; the $5k-$50k range and bid-ask gate together are imperfect filters

### Anti-Prim Escape Hatches (3 Formal)

**(A) Convergence null — rolling 20 events:** Metaculus direction resolves correctly < 55% across 20 rolling qualifying events → calibration advantage not exploitable on PM binary format at defined thresholds → mark anti-prim (mechanism absent)

**(B) WR floor — 30 geopolitics trades:** Own-data 30 trades in geopolitics category (0% fee) → WR < 52% → calibration-based convergence absent for geopolitics-accessible events → mark anti-prim (domain)

**(C) Frequency collapse — annual scan:** Active qualifying pairs (≥ 8% divergence, 7–90 days, $5k–$50k) < 10/year for 2 consecutive years → co-listing rate insufficient for statistical validation OR PM has absorbed the calibration signal → mark anti-prim (frequency)

### Implementation Gaps (5 — all BLOCKING)

1. **`src/classifiers/metaculus_pm_matcher.py`** [BLOCKING ALL TRADES] — sentence-transformer embedding ≥ 0.85 + Type A/B/C keyword veto (from semantic_risk.py) + source-quality tier classifier (GJP vs Metaculus tracked vs community); 50 labeled pairs required for threshold calibration

2. **`src/signals/metaculus_feed.py`** — Metaculus API v3: question ID, community median, tracked-forecaster subset median (tracked-status field), predictor count, tracked-count, last update timestamp, resolution date

3. **`src/strategies/superforecaster_lead.py`** — source-quality-tiered Mode A (3-row threshold table); Mode B staleness + stability gate; peaked horizon window (reject T < 7d unconditionally; apply community threshold ≥ 12% only at T 14-30d); bid-ask gate; breaking-news 12h blackout

4. **`src/risk/antiprims.py`** — three circuit-breakers: rolling-20 WR tracker (anti-prim A); 30-trade geopolitics WR tracker (anti-prim B); annual qualifying-event counter (anti-prim C); log to `user_data/superforecaster_log.json`

5. **Tracked-forecaster quality proxy** — Metaculus API `track_record` field identifies top-quartile forecasters; if unavailable, fallback: require raw predictor count ≥ 200 for community-median signal (stricter than intermediate's 150/100)

### Conditions Log Entry
- Works when: Semantic equivalence confirmed; GJP ≥ 8% / Metaculus tracked ≥ 10% / community ≥ 12% divergence; horizon 14–45d (Mode A peak); PM $5k–$50k; bid-ask ≥ 3% (Mode A); geopolitics category; no breaking news 12h; divergence ≤ 48h old; Metaculus updated < 24h
- Fails when: Semantic mismatch (#1); T < 7 days (PM outperforms); PM > $50k (sophisticated participants priced in); breaking news (PM updates faster than Metaculus cycle); community-median source without performance weighting (ties markets, not beats — use ≥ 12% threshold only); groupthink on high-profile polarised events
- Last validated: never

## Refinement History
- 2026-04-11 (cycle 39): Created as naive prim. 9th polymarket prim class.
- 2026-04-11 (cycle 40): Elevated to intermediate. Two-mode signal; Brier gap quantified (0.111 vs 0.187); 7-day floor; 8-source basis.
- 2026-04-11 (cycle 41): Elevated to sophisticated. Three core upgrades: (1) source-quality-tiered thresholds from Atanasov et al. (2024); (2) peaked calibration window (14–45d) from Wiley 2012 + mechanism analysis; (3) signal frequency model (~30–100/year, N=30 in 3–12 months) + slow-edge competitive moat analysis. No direct WR study found — hypothesis ceiling acknowledged.

## Next Refinement Path (Beyond Sophisticated)
Only path to certainty upgrade: own-data collection.
- 15 trades: first statistical signal (WR within ±25%)
- 30 trades: anti-prim escape hatch threshold (WR within ±18%)
- 100 trades: hypothesis → evidence upgrade threshold (WR within ±10%)

Sources:
- [Tetlock & Mellers (2015, Psych Sci)](https://doi.org/10.1177/0956797615574898)
- [Manifund — Comparing Forecasting Platform Accuracy](https://manifund.org/projects/comparing-forecasting-platform-accuracy)
- [Metaculus Medium — Why I Reject the Comparison to Prediction Markets](https://metaculus.medium.com/why-i-reject-the-comparison-of-metaculus-to-prediction-markets-4175553bcbb8)
- [Atanasov, Mellers, Tetlock et al. (SSRN 4691513, 2024) — Crowd Prediction Systems](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4691513)
- [Wiley (2012) — Do Prediction Markets Produce Well-Calibrated Probability Forecasts?](https://onlinelibrary.wiley.com/doi/abs/10.1111/j.1468-0297.2012.02561.x)
- [Good Judgment 2024 — GJP vs futures markets](https://goodjudgment.com/superforecasting/)
- [Mellers et al. (2015, Psych Sci)](https://doi.org/10.1177/0956797615579358)
- [Reichenbach & Walther (SSRN 5910522)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5910522)
- [Snowberg & Wolfers (2004, JEP) — Prediction Markets](https://doi.org/10.1257/0895330041371277)
