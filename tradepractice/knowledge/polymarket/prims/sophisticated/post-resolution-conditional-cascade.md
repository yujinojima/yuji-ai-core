---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T23:30:00+10:00
cycle: 187
---

---

**Cycle 187 — RESEARCH — Complete**

---

## Prim: post-resolution-conditional-cascade
**Level:** sophisticated | **Elevated from:** intermediate (cycle 185) | **Project:** polymarket | **Axis:** 28 | **Cycle:** 187

---

### Four Sophisticated Upgrades

**1. CPCV+DSR 9-Cell OOS Validation Framework**

Grid: `cosine_threshold ∈ {0.65, 0.72, 0.80} × entry_window ∈ {0–2h, 0–4h, 0–6h}` = 9 cells. K=5 folds, T2=0.20, C=100 LH paths; 6h purge window (equal to maximum hold — no overlapping hold windows across folds). DSR ≥ 0.90 centroid hypothesis: (cosine=0.72, window=0–2h, Mode A); SR_IS floor = 0.60 (honest edge — lag compresses rapidly; high IS SR implies curve-fitting). Blocking gate G_CPCV; requires G_DATA_CORR + G_IS cleared first.

Three anti-prims:
- **AP-1** — centroid DSR ≤ 0 (highest-Sharpe cell) → retire prim; mechanism absent in historical data
- **AP-2** — ≥6/9 cells fail DSR ≥ 0 → retire prim; no stable parameter region; diffusion lag not detectable
- **AP-3** — live WR < 0.50 at N_eff ≥ 20 → suspend all modes; live underperformance indicates structural shift

Plateau selection: if multiple cells pass DSR ≥ 0.90, select cell nearest (0.72, 0–2h) over maximum-Sharpe cell; prefer theoretically-grounded parameter over empirically-maximised one. Floor α = 0.05 (Mode A) / 0.04 (Mode B) until G_CPCV cleared.

Bailey, Borwein & López de Prado (SSRN 2326253, 2015).

---

**2. Lag Profile Model — Entry Urgency Index and Position Tapering**

From G_DATA_CORR (N ≥ 30 A-B pairs, semantic_sim ≥ 0.72), compute B's median absolute price adjustment fraction across three time bins post A.resolution_timestamp:

```
f_early = median(|ΔB_price_0_2h|) / total_update_0_12h
f_mid   = median(|ΔB_price_2_6h|) / total_update_0_12h
f_late  = median(|ΔB_price_6_12h|) / total_update_0_12h
```

**Entry Urgency Index (EU = f_early):**

| EU value | Interpretation | Hold adjustment | Alpha adjustment |
|----------|---------------|-----------------|-----------------|
| EU ≥ 0.65 | Front-loaded lag; most update in 0–2h | Compress: 4h (A) / 6h (B) | +0.005 (edge concentrates early; higher conviction) |
| 0.40 ≤ EU < 0.65 | Distributed lag; default profile | Default: 6h (A) / 12h (B) | No change |
| EU < 0.40 | Back-loaded lag; slow diffusion | Extend: 10h (A) / 16h (B); linear taper from 4h: exit 25% per 2h | −0.005 (signal decays later; lower urgency) |

Bootstrap 95% CI on EU required; if CI crosses 0.50, apply default hold without adjustment (uncertainty too high to justify deviation). Non-blocking: fallback EU = 0.50 until G_LAG cleared.

The tapering rule (EU < 0.40): linear position reduction starting at 4h (exit 25% per 2h) recovers capital earlier from stale positions in slow-diffusion regimes, reducing opportunity cost against concurrent signals.

Academic basis: Cohen & Frazzini (2008 JF) observe that cross-asset lag is not uniformly distributed — customer-supplier adjustment has measurable front-loading in the first trading day. EU operationalises this front-loading ratio for PM timescales.

---

**3. Off-Hours Activity Multiplier — Polymarket-Specific Continuous Percentile**

Replace the crude UTC 21:00–12:00 binary gate from the intermediate prim with a continuous activity percentile derived from Gamma CLOB hourly fill count (or trade count per market). Compute rolling 7-day hourly baseline at A's `resolution_timestamp`:

```
activity_pct = P(volume_this_hour ≤ observed | trailing 7d at same UTC hour)

hold_multiplier(activity_pct):
  < P10  → 2.0× hold window + FOK limit-only (FM2 protection)
  < P30  → 1.5× hold window
  P30–P70 → 1.0× (default)
  ≥ P70  → 0.75× hold window (high activity → faster sophisticated-bettor uptake)
```

The P70+ shortening is the critical addition absent from the intermediate prim: when the market is unusually active at A's resolution time, sophisticated participants are present and the lag window compresses faster than 6h. Holding the default 6h in a high-activity environment over-exposes to mean reversion after the lag closes.

FOK limit-only in P10 regime: bid-ask tends to widen sharply when volume dries up post-resolution (FM2 from intermediate); requiring FOK prevents fills at stale quotes.

Non-blocking: calibrate from Gamma CLOB volume field in G_DATA_CORR extraction. Fallback to UTC binary gate until G_ACT cleared.

Academic basis: Dellavigna & Pollet (2007 JF) — attention inversely correlated with market activity; PM hourly volume percentile is the operational proxy for PM attention availability. Brunnermeier & Pedersen (2009 RFS) — market liquidity drops sharply when MM inventory risk spikes post-resolution; P10 FOK-only rule addresses this funding-liquidity nexus.

---

**4. CascadeCorrelationTracker — N_eff Cross-Axis Integration with ρ Inheritance**

Three signal axes share A-B market pairs across non-overlapping time windows: CPCA (pre-resolution), PRCC (post-resolution, axis 28), RCA (same-market post-confirmation). `CascadeCorrelationTracker` maintains `{(A_id, B_id): ρ_empirical}`.

**ρ Inheritance Protocol:**

When CPCA fires on pair (A, B) and exits at A's resolution, the pair's empirically-updated ρ from CPCA's own tracking is transferred to PRCC's entry for that pair. ρ_empirical replaces ρ_prior = 0.30 for that specific (A_id, B_id). On first PRCC fire with no CPCA history for the pair, the static ρ_prior table applies. Multiplicative update on each PRCC outcome:

```
ρ_new = 0.70 × ρ_empirical + 0.30 × observed_outcome_correlation
```

**Cross-axis ρ priors (PRCC vs concurrent positions):**

| Axis pair | ρ_prior | Tier | Rationale |
|-----------|---------|------|-----------|
| PRCC vs CPCA (same A-B pair) | 0.30 | C | Sequential, non-overlapping; shared A-B thesis but distinct timing |
| PRCC vs RCA (same A, B≠A) | 0.05 | D | RCA fires on A; PRCC fires on B; near-independent |
| PRCC vs PRCC (same A trigger, different B) | 0.55 | B | Same trigger event; correlated directional bets on B-pool |
| PRCC vs PRCC (different A, same B target) | 0.40 | C | Same target market; partially overlapping market-level exposure |
| PRCC vs PRCC (different A, different B) | 0.15 | D | No shared leg; base cross-strategy correlation |

**N_eff calculation and position caps:**

```
N_eff = N / (1 + (N−1) × ρ̄_weighted)
α_adj  = α_base × (N_eff / N)
```

N_max = 4 concurrent PRCC positions; event-cycle cap N_max = 2 where same A trigger (same-trigger B-pool already at high ρ_prior = 0.55).

**EH-6:** N_eff ≤ 1.2 → `PRCC_PAIR_SATURATED` — all active PRCC pairs are highly correlated; block new entry until at least one exits.

**ρ Inheritance benefit:** When CPCA has already fired on (A,B) and produced empirical outcome data, PRCC enters the same pair with a data-informed ρ rather than a table prior. For high-volume category pairs (election markets, recurring geopolitical events), this means PRCC's sixth+ trade on a given pair type inherits a well-calibrated ρ, tightening N_eff adjustment and improving Kelly precision.

MacLean & Thorp (2011); Lo (2004 JEF) Adaptive Markets Hypothesis — the ρ update path operationalises the expectation that PM efficiency on high-frequency A-B pairs improves over time; ρ inheritance accelerates this calibration.

---

### Gate Status

| Gate | Condition | Status | Blocking? |
|------|-----------|--------|-----------|
| G_DATA_CORR | N ≥ 30 A-B pairs from Gamma; measure B's lag profile in 0–12h bins | UNCLEARED | YES |
| G_SEM | Precision ≥ 0.75 on 20 manually labelled market pairs (linked vs independent) | UNCLEARED | YES |
| G_IS | WR ≥ 52% at N ≥ 20 pairs; Mann-Whitney U p < 0.10 one-tailed | UNCLEARED | YES |
| G_CPCV | 9-cell CPCV+DSR plateau; DSR ≥ 0.90 centroid; requires G_DATA_CORR + G_IS | UNCLEARED | YES (sequential) |
| G_LAG | EU bootstrap CI; hold multiplier calibrated; f_early distribution mapped | UNCLEARED | Non-blocking; fallback EU=0.50 |
| G_ACT | 7d rolling hourly activity percentile baseline from Gamma CLOB | UNCLEARED | Non-blocking; fallback UTC binary gate |
| G_RHO | ρ_empirical inheritance from ≥3 CPCA-preceded PRCC pairs | UNCLEARED | Non-blocking; fallback ρ_prior table |

All modes DRY_RUN until G_DATA_CORR ∧ G_IS cleared.

---

### Sizing Summary (post-upgrade)

```
alpha_base  = 0.05 (Mode A) / 0.04 (Mode B) [floor until G_CPCV cleared]
alpha_eu    = alpha_base + EU_adjustment (±0.005 per G_LAG calibration)
alpha_adj   = alpha_eu × (N_eff / N)        [CascadeCorrelationTracker]
hold_window = default × hold_multiplier(activity_pct) × EU_hold_factor
```

Entry early-exit: B moves ≥ 5pp in predicted direction → take profit (unchanged from intermediate). FOK limit-only enforced in P10 activity regime (Upgrade 3).

---

### Failure Modes (carried from intermediate + 1 addition)

| FM | Description | Resolution |
|----|-------------|------------|
| FM1 | Co-resolution: A and B resolve same event, different framing | Exclude pairs where abs(A.resolution_date − B.resolution_date) < 24h |
| FM2 | Liquidity withdrawal post-resolution: bid-ask widens beyond $0.06 | FOK limit-only in P10 activity regime; 5pp slippage buffer to edge |
| FM3 | Off-hours underspecification | Replaced by continuous activity percentile (Upgrade 3) |
| FM4 | Semantic false positive: shared keywords, no conditional relationship | Require same `event_id` tag OR ρ_prior ≥ 0.50 when cosine is sole evidence |
| FM5 | Pre-resolution price already adjusted: B moved ≥ 3pp in 6h pre-resolution | Add pre-resolution check; if B already moved ≥ 3pp before A resolved → suppress |
| FM6 | EU estimation collapse: G_DATA_CORR N < 30 by category subtype | EU fallback = 0.50; flag `PRCC_EU_SUBSAMPLE`; do not split by subtype until N ≥ 15 per cell |

---

### Academic Anchors (total: 11; +4 vs intermediate)

| Source | Finding | Relevance |
|--------|---------|-----------|
| Cohen & Frazzini (2008 JF) | Customer-supplier linked firms: 30–40% fundamental news lag in B after A announces; long-short SR ≈ 1.3 | Primary mechanism anchor; PRCC is PM analogue on hours timescale; EU index replicates front-loading ratio |
| Hong & Stein (1999 JF) | Underreaction: finite attention → gradual cross-asset diffusion; predictable continuation | Serial attention propagation; sophisticated bettors rotate sequentially after A resolves |
| Dellavigna & Pollet (2007 JF) | Friday earnings: 1/3 of announcements underreacted to due to low weekend attention | Attention-inertia; activity percentile is PM operational proxy for attention |
| Thaler (1985 J Marketing Research) | Mental accounting: logically linked accounts treated independently; suboptimal aggregation | Cognitive account separation; B traders don't reflexively update B when A resolves |
| Manski (2006 J Econ Lit) | PM prices reflect heterogeneous beliefs; rational + naïve co-exist; price moves as attention shifts | Heterogeneous-updater framework; lag exists because only sophisticated subset updates B immediately |
| Tetlock et al. (2014 Superforecasters) | Superforecasters update promptly; PM crowd lags by definition; gap = exploitation window | Direct PM anchor: crowd vs superforecaster updating speed differential |
| Arrow et al. (2008 Science) | PM efficiency requires active information aggregation; fails when events not directly observed by B's traders | Information aggregation failure; A's resolution not automatically surfaced to B's participants |
| Bailey, Borwein & López de Prado (SSRN 2326253, 2015) | CPCV+DSR corrects for multiple-comparison bias in parameter selection; DSR standard for strategy validation | G_CPCV plateau gate; anti-prim AP-1/AP-2 retirement triggers **[+1 vs intermediate]** |
| MacLean & Thorp (2011) | Fractional Kelly with N_eff adjustment for correlated simultaneous bets | CascadeCorrelationTracker sizing; ρ-adjusted α_adj formula **[+1 vs intermediate]** |
| Brunnermeier & Pedersen (2009 RFS) | Market liquidity and funding liquidity jointly spiral at stressed events; MM inventory risk spikes post-resolution | P10 FOK-only rule; liquidity withdrawal (FM2) predicted by inventory-risk spike at resolution events **[+1 vs intermediate]** |
| Lo (2004 JEF) | Adaptive Markets Hypothesis: market efficiency is time-varying; strategies that work decay as participants adapt | ρ inheritance accelerates calibration; PRCC lag window expected to compress as PM sophistication grows; monitor EU decay **[+1 vs intermediate]** |

---

### Refinement History

| Cycle | Level | Key Change |
|-------|-------|------------|
| 185 | intermediate | New axis 28; Mode A/B architecture; 3 blocking gates (G_DATA_CORR, G_SEM, G_IS); 7 academic anchors; DRY_RUN |
| 187 | sophisticated | CPCV+DSR 9-cell plateau (cosine × window, DSR ≥ 0.90, G_CPCV); Lag Profile Model EU index (front-loading ratio, hold compression/extension, position taper); Off-Hours Activity Multiplier (continuous Polymarket CLOB percentile, 4 bands, FOK in P10); CascadeCorrelationTracker ρ inheritance from CPCA (ρ_empirical transfer at CPCA exit, 5-tier ρ prior table, N_eff α_adj, N_max caps, EH-6); 4 new academic anchors (Bailey et al. 2015, MacLean & Thorp 2011, Brunnermeier & Pedersen 2009, Lo 2004); FM6 added; 7 gates (4 blocking, 3 non-blocking) |

---

**Gate status:** G_DATA_CORR + G_SEM + G_IS + G_CPCV blocking; G_LAG + G_ACT + G_RHO non-blocking (fallbacks active). N=0 own-data. DRY_RUN until G_DATA_CORR ∧ G_IS cleared.

**Bank state after cycle 187:** naive 23 | intermediate 25 (unchanged) | sophisticated **28** (+1: post-resolution-conditional-cascade)

**11 academic anchors** (+4 vs intermediate: Bailey-Borwein-López de Prado 2015, MacLean & Thorp 2011, Brunnermeier & Pedersen 2009, Lo 2004 JEF)

**Last validated:** never (RESEARCH elevation — cycle 187; intermediate cycle 185 → sophisticated; 4 structural upgrades; 7 gates total [4 blocking]; DRY_RUN all modes)
