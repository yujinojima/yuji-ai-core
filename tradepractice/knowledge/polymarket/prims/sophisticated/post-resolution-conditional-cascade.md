---
prim: post-resolution-conditional-cascade
alias: PRCC
level: sophisticated
axis: 28
elevated_from: intermediate
elevated_cycle: 187
project: polymarket
last_validated: never (DRY_RUN — G_DATA_CORR ∧ G_IS uncleared)
---

## Prim: post-resolution-conditional-cascade (PRCC)
**Level:** sophisticated | **Elevated from:** intermediate (cycle 185) | **Axis:** 28 | **Cycle:** 187

---

### Mechanism

When Market A resolves YES or NO, open companion Market B where:

1. **Semantic link** — `cosine(embed(A.title), embed(B.title)) ≥ 0.72` (all-MiniLM-L6-v2), OR same `event_id` / (`category_id` + shared entity tag) in Gamma metadata
2. **Directional correlation** — `ρ(A, B) ≥ +0.40` (Mode A, co-directional) or `ρ(A, B) ≤ −0.40` (Mode B, anti-directional). Priors: same `category_id` = +0.50; same `sub_category` = +0.35; same country/entity only = +0.20. Empirical update from G_DATA_CORR; CPCA ρ inheritance from CascadeCorrelationTracker (see upgrade 4)
3. **Price stickiness** — B's YES price moved < 3pp in 2h after A's `resolution_timestamp` (pre-resolution pre-emption check: if B moved ≥ 3pp in the 6h BEFORE A resolved → suppress)
4. **B is open** — B.DTE ≥ 2; no pending UMA assertion on B
5. **Liquidity** — B.liquidity ≥ $3,000; bid-ask ≤ $0.06 at execution time

**Direction:**
- Mode A (ρ ≥ +0.40): A=YES → BUY B YES; A=NO → BUY B NO
- Mode B (ρ ≤ −0.40): A=YES → BUY B NO; A=NO → BUY B YES

**Sizing (unvalidated floor until G_IS cleared):**
```
alpha_base = 0.05 (Mode A) | 0.04 (Mode B)
alpha_adj  = alpha_base × (N_eff / N)          # CascadeCorrelationTracker
edge_est   = ρ_prior × mean_lag_magnitude
Kelly      = alpha_adj × (edge_est / odds)
```

---

### Sophisticated Upgrades

#### 1. Entry Urgency Index (EU) — Lag Profile Model

Requires G_DATA_CORR. Entry urgency computed from lag distribution across A-B pairs:

```
EU = f_early = median(|ΔB_0_2h|) / total_update_0_12h
```

Bootstrap 95% CI required; fallback EU = 0.50 if G_DATA_CORR uncleared.

| EU band | Hold window | Alpha modifier |
|---------|-------------|----------------|
| EU ≥ 0.65 | Compress: 4h (US) / 8h (off-hours) | +0.005 |
| 0.40–0.65 | Default: 6h (US) / 12h (off-hours) | ±0 |
| EU < 0.40 | Extend: 10h (US) / 16h (off-hours); linear 25%/2h taper from 4h | −0.005 |

Operationalises Cohen & Frazzini (2008) front-loading ratio at PM timescales.

#### 2. Off-Hours Activity Multiplier — Continuous Polymarket Percentile

Replace UTC binary gate (21:00–12:00) with rolling 7-day hourly Gamma CLOB percentile at A's `resolution_timestamp`. Non-blocking; fallback to UTC binary gate if Gamma CLOB volume unavailable.

| CLOB percentile band | Hold multiplier | Execution |
|----------------------|-----------------|-----------|
| P < 10 | 2.0× | FOK limit-only (FM2 protection) |
| P 10–30 | 1.5× | Standard |
| P 30–70 | 1.0× (default) | Standard |
| P ≥ 70 | 0.75× (lag closes faster — sophisticated bettors active) | Standard |

P ≥ 70 shortening is new vs intermediate. Grounded in Dellavigna & Pollet (2007) and Brunnermeier & Pedersen (2009).

#### 3. CascadeCorrelationTracker — ρ Inheritance and N_eff

When CPCA exits on pair (A,B) at A's resolution, PRCC inherits `ρ_empirical` for that pair (replaces ρ_prior=0.30).

**Five-tier cross-axis ρ prior table:**

| Pair | ρ prior | Tier | Notes |
|------|---------|------|-------|
| PRCC × CPCA | 0.30 | C | Sequential (non-concurrent by design) |
| PRCC × RCA | 0.05 | D | Different markets; near-independent |
| PRCC × PRCC same-trigger A | 0.55 | B | Same A resolution event |
| PRCC × PRCC same-target B | 0.40 | C | Same B market, different A triggers |
| PRCC × PRCC independent | 0.15 | D | Different A and B |

**N_eff calculation:**
```
N_eff = N / (1 + (N−1) × ρ̄)
alpha_adj = alpha_base × (N_eff / N)
```

Limits: N_max = 4 concurrent PRCC positions; event-cycle cap N_max = 2 with same A trigger.
EH-6: N_eff ≤ 1.2 → emit `PRCC_PAIR_SATURATED`; suppress new PRCC on this A trigger.

Grounded in MacLean & Thorp (2011) portfolio Kelly sizing and Lo (2004) AMH.

#### 4. CPCV+DSR 9-Cell Plateau

**Grid:** `cosine_threshold ∈ {0.65, 0.72, 0.80} × entry_window ∈ {0–2h, 0–4h, 0–6h}` = 9 cells.
**CPCV config:** K=5 folds, T2=0.20, C=100 LH paths, 6h purge window (non-overlapping hold windows).
**Centroid hypothesis:** DSR ≥ 0.90 at (0.72, 0–2h, Mode A). SR_IS floor = 0.60.

**Anti-prims (blocking gate G_CPCV):**
| Anti-prim | Condition | Action |
|-----------|-----------|--------|
| AP-1 | Centroid cell DSR ≤ 0 | Retire prim |
| AP-2 | ≥ 6/9 cells fail DSR | Retire prim |
| AP-3 | Live WR < 0.50 at N_eff ≥ 20 | Suspend (re-evaluate at N_eff = 40) |

Gate G_CPCV requires G_DATA_CORR + G_IS cleared first. Grounded in Bailey, Borwein & López de Prado (2015).

---

### Entry Pseudocode (Mode A, sophisticated)

```
ACTIVATE (Mode A) when ALL of:
  A.status == 'resolved'
  A.resolution_outcome ∈ {'YES', 'NO'}
  cosine(A, B) ≥ 0.72 OR (same_event_id OR (same_category_id AND shared_entity_tag))
  ρ_effective(A, B) ≥ +0.40              # from CascadeCorrelationTracker or prior
  B_price_change_since_A_resolution < 3pp (stickiness gate)
  B_price_change_6h_before_A_resolution < 3pp (pre-emption gate)
  B.DTE ≥ 2
  B.liquidity ≥ 3000
  B.bid_ask ≤ 0.06 (checked at execution, not signal time)
  elapsed_hours_since_A_resolution ≤ entry_window (EU-determined)
  NOT B_in_oracle_window
  N_eff > 1.2 (not PRCC_PAIR_SATURATED)

DIRECTION: BUY B YES if A=YES; BUY B NO if A=NO
SIZE: alpha_adj × kelly(edge_est, odds)
HOLD: hold_default × activity_multiplier × eu_modifier
EXIT EARLY: B_price_move ≥ 5pp predicted direction OR B.DTE < 1d OR hold_limit
```

---

### Gate Status

| Gate | Type | Condition | Status |
|------|------|-----------|--------|
| G_DATA_CORR | Blocking | Gamma API: ≥ 30 A-B pairs (cosine ≥ 0.72); lag profile 0–12h | UNCLEARED |
| G_SEM | Blocking | NLP precision ≥ 0.75 on 20 labelled pairs; 10 FP checks | UNCLEARED |
| G_IS | Blocking | WR ≥ 52% at N ≥ 20 A-B pairs; Mann-Whitney p < 0.10 | UNCLEARED |
| G_CPCV | Blocking | 9-cell CPCV plateau; DSR ≥ 0.90 centroid; requires G_DATA_CORR + G_IS | UNCLEARED |
| G_LAG | Non-blocking | EU bootstrap CI; fallback EU = 0.50 | fallback active |
| G_ACT | Non-blocking | 7d Gamma CLOB percentile; fallback UTC binary gate | fallback active |
| G_RHO | Non-blocking | CascadeCorrelationTracker ρ inheritance; fallback ρ_prior table | fallback active |

**All modes DRY_RUN until G_DATA_CORR ∧ G_IS cleared.**

---

### Failure Modes

| FM | Description | Symptom | Resolution |
|----|-------------|---------|------------|
| FM1 | Co-resolution: A and B resolve same event different framing | WR inflated near 100% | Exclude `abs(A.res_date − B.res_date) < 24h` |
| FM2 | Liquidity withdrawal post-resolution: MMs widen bid-ask after A resolves | No fill at signal price | Bid-ask check at execution time; 5pp slippage buffer; P<10 FOK limit-only |
| FM3 | Off-hours underspecification: UTC 21:00–12:00 too crude | Hold extension WR uplift not significant | G_ACT: rolling 7d percentile bands replace UTC binary gate |
| FM4 | Semantic FP via shared keywords (e.g., both "Will [Country]...?") | Mode A fires with zero actual conditional relationship | Require same `event_id` OR ρ_prior ≥ 0.50; ρ_prior 0.20–0.40 requires G_DATA_CORR empirical uplift |
| FM5 | Pre-resolution pre-emption: sophisticated bettors priced A into B before formal resolution | Stickiness gate passes but edge zero | Suppress if B moved ≥ 3pp in 6h before A resolved |

---

### Relationship to Existing Prims

| Prim | Trigger | Market scope | ρ with PRCC |
|------|---------|-------------|-------------|
| CPCA | P(D) violates P(U)×r; both open | U and D both open | 0.30 (Tier C, sequential, non-concurrent) |
| RCA | A confirmed by wire; A's price < 0.85/0.94 | Same market as trigger | 0.05 (Tier D, different markets) |
| **PRCC** | **A fully resolved; B not yet updated** | **Different market from trigger** | — |

CPCA exits at A's resolution; PRCC enters at A's resolution — structurally non-concurrent. ρ=0.30 reflects shared thesis, not position overlap.

---

### Academic Anchors (11)

| Source | Finding | Role |
|--------|---------|------|
| Cohen & Frazzini (2008 JF) | Customer-supplier linked firms: 30–40% of fundamental news not reflected in B for 1 month; SR ≈ 1.3 | Primary mechanism: cross-asset information diffusion lag |
| Hong & Stein (1999 JF) | Finite attention → gradual diffusion across linked assets | Serial attention propagation mechanism |
| Dellavigna & Pollet (2007 JF) | Friday earnings underreaction; weekend attention inattention | Attention-timing anchor; off-hours hold extension basis |
| Thaler (1985 J Marketing Research) | Mental accounting: logically linked accounts treated as independent | Cognitive account separation mechanism |
| Manski (2006 J Econ Lit) | PM prices reflect heterogeneous beliefs; rational vs naïve co-exist | Heterogeneous-updater framework |
| Tetlock et al. (2014 Superforecasters) | Superforecasters update promptly; PM crowd lags | Direct PM anchor: exploitation window |
| Arrow et al. (2008 Science) | PM efficiency requires active aggregation; fails when B traders don't observe A's resolution | Information aggregation failure anchor |
| Bailey, Borwein & López de Prado (2015 SSRN 2326253) | CPCV+DSR framework; multiple-testing correction for backtest IS | 9-cell plateau validation methodology |
| MacLean & Thorp (2011) | Portfolio Kelly sizing under correlated positions | N_eff-adjusted Kelly sizing |
| Brunnermeier & Pedersen (2009 RFS) | Liquidity and funding constraints; sophisticated traders withdraw during illiquid windows | P<10 FOK limit-only; activity multiplier upper band |
| Lo (2004 JEF) — AMH | Adaptive markets hypothesis; α decays as sophisticated arbitrageurs discover and trade the lag | N_eff saturation guard (PRCC_PAIR_SATURATED); α_adj decay |

---

### Bank State (cycle 187)

| Tier | Polymarket | Freqtrade |
|------|-----------|-----------|
| Naive | 23 | — |
| Intermediate | 25 | — |
| Sophisticated | **28** (+1: PRCC elevated) | — |

**Last validated:** never (DRY_RUN — creation cycle 185, elevation cycle 187; 28th polymarket axis; G_DATA_CORR ∧ G_IS ∧ G_SEM ∧ G_CPCV all UNCLEARED)
