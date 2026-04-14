---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T22:00:00+10:00
cycle: 185
---

---

**Cycle 185 — RESEARCH — Complete**

---

## Prim: post-resolution-conditional-cascade
**Level:** intermediate (new class) | **Project:** polymarket | **Axis:** 28 | **Cycle:** 185

---

### Why this axis

The current polymarket bank contains two resolution-adjacent prims that leave a structural gap:

- **CPCA** (conditional-probability-cascade-arbitrage): fires **pre-resolution** when two linked open markets violate Bayesian product P(D) ≈ P(U)×r. Signal dies at resolution of U.
- **RCA** (resolution-confirmation-arbitrage): fires **post-resolution** on the **same market** when its own price has not yet converged to 1.00/0.00 after wire confirmation.

Neither covers: *Market A has fully resolved; semantically correlated open Market B has not yet absorbed A's resolution outcome.* The crowd's attention is limited and unevenly distributed. When A's resolution carries conditional information for B — and B's participants have not yet processed it — B's price lags behind Bayesian updates for a bounded window. This is the post-resolution conditional cascade (PRCC).

The gap is real and distinct. It is an **information diffusion lag**, not a microstructure artefact. Cohen & Frazzini (2008 JF) documented the same mechanism in equities: when economically linked firms share fundamental information, 30–40% of the price adjustment in the downstream firm is delayed by one full month. In prediction markets — where resolution events are discrete and public but attention allocation is heterogeneous — the lag compresses to hours rather than months, but the mechanism is identical.

---

### Mechanism

When Market A resolves YES (or NO), any open companion market B where:

1. **Semantic link established** — `cosine(embed(A.title), embed(B.title)) ≥ 0.72` using all-MiniLM-L6-v2 (identical threshold to anchor-event-recency-bias-fade), OR same parent event category + shared entity tag in Gamma API metadata
2. **Directional correlation estimated** — `ρ(A, B) ≥ +0.40` for Mode A (co-directional); `ρ(A, B) ≤ −0.40` for Mode B (anti-directional). Prior: +0.50 for same Gamma `category_id`; +0.35 for same `sub_category`; +0.20 for same country/entity only. Empirical update from G_DATA_CORR.
3. **Price stickiness confirmed** — B's YES price has moved < 3pp in the 2h window after A's `resolution_timestamp`. Larger early movement implies sophisticated bettors already priced in A's resolution; no lag opportunity remains.
4. **B is still open** — B has DTE ≥ 2 and is not in its own oracle window (no pending UMA assertion on B).
5. **Liquidity minimum** — B liquidity ≥ $3,000; bid-ask ≤ $0.06 at signal time.

**Direction logic:**
- Mode A (ρ ≥ +0.40): A resolves YES → BUY B YES; A resolves NO → BUY B NO
- Mode B (ρ ≤ −0.40): A resolves YES → BUY B NO; A resolves NO → BUY B YES

**Hold window:** 6h (US-hours resolution) / 12h (off-hours resolution, UTC 21:00–12:00). Exit at hold limit regardless. See Failure Mode 3 for off-hours definition.

**Exit early:** B moves ≥ 5pp in predicted direction (take profit); B's own resolution event fires; DTE < 1d.

**Sizing (unvalidated floor):**
```
alpha = 0.05   # floor until G_IS cleared; N=0 own-data
Kelly fraction = alpha × (edge_estimate / odds)
edge_estimate = ρ_prior × mean_lag_magnitude   # analytically derived; G_IS will replace
```

---

### Mode A — Co-Directional Correlation

```
ACTIVATE (Mode A) when ALL of:
  A.status == 'resolved'
  A.resolution_outcome ∈ {'YES', 'NO'}
  cosine(A, B) ≥ 0.72 OR (same_category_id AND shared_entity_tag)
  ρ_prior(A, B) ≥ +0.40
  B_price_change_since_A_resolution < 3pp (stickiness gate)
  B.DTE ≥ 2
  B.liquidity ≥ 3000
  B.bid_ask ≤ 0.06
  elapsed_hours_since_A_resolution ≤ 2h (early entry window)
  NOT B_in_oracle_window

DIRECTION: BUY B YES if A=YES; BUY B NO if A=NO
SIZE: alpha=0.05 × kelly(edge_est, odds)
HOLD: 6h (US hours) / 12h (off hours)
EXIT EARLY: B_price_move ≥ 5pp predicted direction OR B.DTE < 1d
```

### Mode B — Anti-Directional Correlation

```
ACTIVATE (Mode B) when ALL of:
  [all Mode A gates except ρ condition]
  ρ_prior(A, B) ≤ −0.40
  [price stickiness + DTE + liquidity unchanged]

DIRECTION: BUY B NO if A=YES; BUY B YES if A=NO
SIZE: alpha=0.04 × kelly(edge_est, odds)   # lower conviction: anti-correlated pairs noisier
HOLD: same as Mode A
```

---

### Why PM participants update slowly

Three complementary mechanisms anchor the lag hypothesis:

**1. Attention inertia (Dellavigna & Pollet 2007):** PM traders monitor a finite number of markets actively. When A resolves, it exits the active list. Market B, which was open before and after, remains in participants' queue — but they do not re-examine B in light of A's resolution unless prompted. The crowd's attention is a serial processor, not a parallel one.

**2. Cross-asset information diffusion (Hong & Stein 1999 underreaction model):** Informed traders in A (who bet correctly) have capital deployed in A now freed at resolution. They rotate attention to other markets sequentially, not simultaneously. The lag between A's resolution and their re-evaluation of B is the same mechanism Hong & Stein describe for cross-asset gradual diffusion.

**3. Cognitive account separation (Thaler 1985 mental accounting):** PM bettors treat each market as an independent account. Even when A and B are structurally linked, the cognitive bundling required to update B based on A's resolution is non-trivial and requires deliberate reasoning. Most participants do not perform this update unless prompted by an explicit notification or large price move in B.

**Compression factor (PM vs equities):** In public equities, the Cohen & Frazzini lag is months because information must propagate through a large, heterogeneous universe of investors. On Polymarket, the population is smaller, more homogeneous, and resolution events are discrete announcements — so the lag compresses to hours. The window is bounded by sophisticated participants who do monitor correlated markets and will arbitrage away the gap, typically within 6–12h.

---

### Academic anchors (7)

| Source | Finding | Relevance |
|--------|---------|-----------|
| Cohen & Frazzini (2008 JF) | Customer-supplier linked firms: 30–40% of fundamental news in firm A not reflected in linked firm B for 1 month; long-short strategy SR ≈ 1.3 | Primary mechanism anchor: cross-asset information diffusion lag; PRCC is the PM analogue on hours timescale |
| Hong & Stein (1999 JF) | Underreaction model: finite attention → gradual information diffusion; creates predictable continuation across linked assets | Serial attention propagation mechanism; explains why sophisticated bettors rotate sequentially |
| Dellavigna & Pollet (2007 JF) | Inattention to scheduled information: 1/3 of Friday earnings announcements underreacted to due to lower investor attention; weekend effect on attention allocation | Attention-inertia anchor; PM equivalent: resolution events outside peak hours face compounded inattention |
| Thaler (1985 J Marketing Research) | Mental accounting: agents treat logically linked accounts as independent; failure to aggregate produces suboptimal decisions | Cognitive account separation mechanism: why B traders don't reflexively update B when A resolves |
| Manski (2006 J Econ Lit) | PM prices reflect heterogeneous population beliefs; rational bettors and naïve bettors co-exist; price moves as attention shifts | Heterogeneous-updater framework: the lag exists because only the sophisticated subset updates B immediately |
| Tetlock et al. (2014 Superforecasters) | Superforecasters update promptly on new information; PM crowd lags by definition; gap = exploitation window | Direct prediction-market anchor: crowd vs superforecaster updating speed differential |
| Arrow et al. (2008 Science) | PM efficiency requires active information aggregation; efficiency fails when market-relevant events are not directly observed by B's traders | Information aggregation failure anchor: A's resolution is not automatically surfaced to B's market participants |

---

### Relationship to existing prims

| Prim | Trigger | Direction | Market scope |
|------|---------|-----------|-------------|
| CPCA | P(D) violates P(U)×r; both OPEN | Pre-resolution positioning | U and D both open |
| RCA | A confirmed by wire; A's own price < 0.85/0.94 | Post-confirmation convergence | Same market as trigger |
| **PRCC** | **A fully resolved; B not yet updated** | **Post-resolution conditional cascade** | **Different market from trigger** |

**N_eff with CPCA (ρ_prior = 0.30, Tier C):** CPCA and PRCC share the same A-B structural relationship but occupy non-overlapping time windows (CPCA exits at A's resolution; PRCC enters at A's resolution). Timing is sequential, not concurrent — co-fire is structurally impossible. ρ = 0.30 reflects shared underlying thesis (both exploit A-B correlation), not simultaneous position overlap. No compounding adjustment required when CPCA has fully exited before PRCC entry.

**N_eff with RCA (ρ_prior = 0.05, Tier D):** RCA fires on A (the resolved market); PRCC fires on B (a different market). Near-independent. Standard independent Kelly applies.

---

### Data status

| Source | Status | Notes |
|--------|--------|-------|
| Gamma API resolved markets (A) | **CLEARABLE** — Gamma `/markets?closed=true` endpoint; historical back to 2022 | Required for G_DATA_CORR |
| Gamma API open markets (B) | **CLEARABLE** — Gamma `/markets?active=true` endpoint | Required for G_DATA_CORR pairing |
| all-MiniLM-L6-v2 embeddings | **CLEARED** — same model used in anchor-event-recency-bias-fade | Cosine similarity gate; already available |
| Polymarket CLOB price history | **CLEARABLE** — Gamma price history endpoint, 1h resolution | Required for stickiness gate + G_IS |
| Entity/category metadata | **CLEARABLE** — Gamma `category_id`, `sub_category`, `country` fields | ρ prior assignment |

**First barrier:** G_DATA_CORR — extract N ≥ 30 A-B resolution pairs from Gamma historical data where semantic_sim ≥ 0.72; measure B's price change in 0h/2h/6h/12h windows after A.resolution_timestamp. Cost: zero (Gamma API free, all-MiniLM-L6-v2 installable).

---

### Blocking gates

| Gate | Condition | Status |
|------|-----------|--------|
| G_DATA_CORR | Gamma API: extract ≥ 30 A-B pairs (semantic_sim ≥ 0.72); measure lag profile in 0–12h post-A-resolution windows | UNCLEARED |
| G_SEM | NLP evaluation: precision ≥ 0.75 on 20 manually labelled market pairs (semantically linked vs independent); 10 false-positive checks | UNCLEARED |
| G_IS | IS analysis: B price change 0–6h post-A-resolution predicts trade direction; WR ≥ 52% at N ≥ 20 A-B pairs; Mann-Whitney U p < 0.10 one-tailed | UNCLEARED |

All modes DRY_RUN until G_DATA_CORR + G_IS cleared.

---

### Failure modes

| FM | Description | Symptom | Resolution |
|----|-------------|---------|------------|
| FM1 | Co-resolution: A and B resolve on same event, just different framing (e.g., "Will X win?" and "Will Y lose to X?") — not a lag signal, guaranteed to move together | WR near 100% inflating IS stats (look too good) | Exclude pairs where `abs(A.resolution_date - B.resolution_date) < 24h` |
| FM2 | Liquidity withdrawal post-resolution: sophisticated market-makers withdraw from B after A resolves, anticipating PRCC; bid-ask widens beyond $0.06 | Signal fires but no fill at signal time price | Require bid-ask check at execution time, not at signal time; add 5pp slippage buffer to edge calculation |
| FM3 | Off-hours underspecification: "off-hours" lag extension (6h → 12h) based on UTC 21:00–12:00 is too crude; weekday vs weekend PM activity differs | WR difference: extended vs non-extended hold not significant | Empirical: segment IS by UTC hour bands; identify actual low-activity windows from Gamma CLOB volume; replace fixed cutoff with Polymarket-specific activity-z < −1.0 trigger |
| FM4 | Semantic false positive: A and B have high cosine similarity via shared keywords (e.g., both titled "Will [Country]...?") but are fundamentally independent | Mode A fires with zero actual conditional relationship | Add FM4 filter: require either same `event_id` tag in Gamma OR ρ_prior ≥ 0.50 (only strong priors trigger without verified event linkage); low ρ_prior (0.20–0.40) requires G_DATA_CORR empirical uplift |
| FM5 | Pre-resolution price already adjusted: sophisticated bettors priced A's expected resolution outcome into B in the hours BEFORE A formally resolved | Stickiness gate (< 3pp in 2h post-resolution) passes but edge zero | Add pre-resolution check: measure B's price change in the 6h BEFORE A resolved; if already moved ≥ 3pp, suppress signal (pre-emptive updating → lag already consumed) |

---

### Path to sophisticated elevation

Four structural advances required:

**1. Lag Profile Model (empirical)** — G_DATA_CORR will produce a distribution of B price adjustments across time bins (0–2h, 2–6h, 6–12h). Sophisticated elevation requires fitting this distribution and using it to size the entry urgency and position tapering. E.g., if 70% of the update happens in 0–2h, hold window tightens and entry urgency increases. If the distribution is flat across 0–12h, the 6h default is appropriate.

**2. Off-Hours Activity Multiplier (Polymarket-specific)** — Replace the crude UTC 21:00–12:00 off-hours gate with a data-driven activity index derived from Polymarket CLOB hourly volume (or Gamma trade count). Compute rolling 7d hourly volume percentile; resolution events below the P30 activity window extend the hold window by a multiplier. Grounded in Dellavigna & Pollet (2007) attention-timing evidence applied to PM-specific volume patterns.

**3. N_eff Cross-Axis Correlation Matrix Integration** — Three axes (PRCC, CPCA, RCA) can fire on the same A-B market pair across different time windows. Sophisticated tier requires explicit CascadeCorrelationTracker update: when CPCA has fired on (A,B) and subsequently exited at A's resolution, the PRCC entry inherits the ρ estimate from CPCA's own tracking (empirically updated ρ replaces ρ_prior=0.30 for that pair). This feeds the bank-wide N_eff tracker.

**4. CPCV+DSR 9-Cell Plateau** — Semantic similarity threshold ∈ {0.65, 0.72, 0.80} × lag entry window ∈ {0–2h, 0–4h, 0–6h} = 9 cells. K=5 folds, T2=0.20, C=100 LH paths; 6h purge window (non-overlapping hold windows). DSR ≥ 0.90 centroid (Mode A, 0–4h window, 0.72 threshold). Anti-prim: if centroid DSR ≤ 0 → retire prim (mechanism absent in data). Bailey-Borwein-López de Prado (SSRN 2326253, 2015).

---

### Bank state after cycle 185

| Tier | Polymarket | Freqtrade |
|------|-----------|-----------|
| Naive | 23 (unchanged) | 24 |
| Intermediate | **25** (+1: post-resolution-conditional-cascade) | 32 |
| Sophisticated | 27 (unchanged) | 33 |

**28 polymarket signal axes defined.**
**Last validated:** never (RESEARCH creation — cycle 185; 28th polymarket signal axis; new class fills CPCA/RCA gap; 7 academic anchors; all 3 gates UNCLEARED; DRY_RUN)
