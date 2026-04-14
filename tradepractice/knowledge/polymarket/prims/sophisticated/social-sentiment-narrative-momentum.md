---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T16:30:00+10:00
cycle: 173
---

## Prim: social-sentiment-narrative-momentum
**Level:** sophisticated | **Project:** polymarket | **Cycle:** 173 | **Elevated from:** intermediate (cycle 169)

---

### What changed from intermediate

The intermediate prim (cycle 169) framed this signal using the freqtrade AMPLIFY/SUPPRESS structure (F&G composite + social volume velocity) against crypto price signals. For polymarket this is the wrong frame: PM markets resolve against specific real-world events, not crypto price movements. The intermediate concept captures the right behavioral mechanism — availability heuristic overweighting of narratively salient outcomes — but the operationalisation needed full reconstruction.

**Five structural additions complete the sophisticated tier:**

1. **Event-level entity matching** — GDELT GKG actor/theme tags mapped to PM market title via cosine similarity (≥ 0.75 required). Replaces the aggregate F&G / crypto-index composite with topic-specific narrative scores for the PM market's underlying event.

2. **Multi-source narrative composite** — GDELT GKG AvgTone z-score (50%) + Twitter entity-mention z-score (30%) + Reddit submission-velocity z-score (20%) over a 30-day rolling baseline. Each source normalized independently before weighting. Fallback rules specified for each source.

3. **Consensus anchor gate** — Signal requires PM YES price to deviate ≥ 5pp from a consensus prior (Metaculus median, or category-IPW base rate when Metaculus coverage < 3 forecasters). Prevents firing on genuinely uncertain markets with no base-rate anchor.

4. **CPCV + Deflated Sharpe protocol** — 36-cell parameter grid (3 composite_z thresholds × 3 price_gap floors × 4 CPCV folds). IS Sharpe ≥ 0.90 (Mode A) / ≥ 0.80 (Mode B) required; DSR ≥ 0.50 mandatory threshold per Bailey/Borwein/López de Prado (2016 SSRN 2326253).

5. **N_eff correction for SAD correlation** — ρ(SSNM, social-attention-divergence-signal) expected 0.55–0.65 (both consume social signals for PM-adjacent events) → Tier A rule: when both prims fire on same market, use only the higher-Kelly signal; no compounding. All other ρ estimates documented with Tier assignment.

---

### Core Mechanism

**Availability heuristic mispricing** (Tversky & Kahneman 1973): When social narrative about a PM market's underlying event E is in an extreme state — either vastly amplified (availability inflation) or narratively neglected below baseline (availability deflation) — PM participants systematically over- or underestimate P(E resolves YES) relative to actuarial base rates.

This is structurally distinct from `social-attention-divergence-signal`, which captures the momentum gap between an attention spike and the PM price update (4h horizon, volume-based, directional). SSNM captures a longer-horizon contrarian signal where the PM price HAS updated to reflect narrative, but has overshot vs base rate due to a cognitive bias that persists until resolution approaches.

| Dimension | social-attention-divergence | social-sentiment-narrative-momentum |
|---|---|---|
| Trigger | Volume spike (≥5× composite) | Sentiment z-extreme (contrarian) |
| Mechanism | Information diffusion lag | Availability heuristic bias |
| Direction | Momentum (follow spike) | Contrarian (fade extreme) |
| Horizon | 4–8 hours | 7–30 days |
| Price zone | 0.35–0.65 | 0.15–0.85 |
| Comparison | None (pure lag) | vs consensus prior |

---

### Rule

#### Composite Narrative Score

```python
def compute_narrative_composite(event_entity: str,
                                 resolution_date: date,
                                 lookback_days: int = 30) -> float:
    """
    Returns composite narrative z-score for the PM market's underlying event.
    All components z-scored vs their own 30-day rolling baseline.
    """
    gdelt_z  = gdelt_avgtone_z(event_entity, lookback_days)      # GDELT GKG AvgTone
    twitter_z = twitter_mention_z(event_entity, lookback_days)   # entity mention count
    reddit_z  = reddit_submission_z(event_entity, lookback_days) # submission velocity

    # Fallback scalars when source unavailable
    if twitter_z is None:  twitter_z = gdelt_z  # proxy gdelt if Twitter absent
    if reddit_z  is None:  reddit_z  = 0.0      # reddit optional, zero if absent

    return 0.50 * gdelt_z + 0.30 * twitter_z + 0.20 * reddit_z

def get_consensus_prior(market) -> float:
    """Returns actuarial prior P(YES) for the market."""
    metaculus = fetch_metaculus_median(market.title)  # ≥3 forecasters required
    if metaculus is not None:
        return metaculus
    return category_ipw_base_rate(market.category, market.resolution_criteria)
```

---

#### Mode A — Narrative Overbetting (Availability Inflation)

```
composite_z < -2.0                    # extreme positive narrative (positive tone → negative z in fade direction)
                                      # NOTE: gdelt AvgTone > 0 = positive; extreme positive narrative = composite_z < -2.0
                                      # (framing: positive z = negative sentiment; negative z = positive sentiment)
  … actually: let narrative_z be defined so positive = MORE positive sentiment
  (0.50 × AvgTone_z + 0.30 × mention_z + 0.20 × reddit_z) > +2.0   → availability inflation → FADE YES
```

**Clarified entry (positive narrative → fade YES):**

- `narrative_z > +2.0` (extreme positive narrative about the event)
- `market.yes_price ∈ [0.55, 0.85]` (non-trivially elevated, but not at ceiling)
- `market.yes_price − consensus_prior ≥ 0.05` (PM has deviated upward from base rate)
- `market.days_to_resolution ≥ 7` (enough time for bias correction)
- `market.liquidity_USD ≤ 500_000` (whale-dominated markets resist bias correction)
- Entity match cosine ≥ 0.75

**Signal:** FADE YES → buy NO at current price. Hold until: (a) `narrative_z` drops below +1.0 OR (b) PM YES price falls within 3pp of `consensus_prior` OR (c) 21 days elapsed, whichever first.

**Kelly α:** `0.09 × price_gap_scalar × neff_adj` where `price_gap_scalar = min(2.0, (yes_price − prior) / 0.05)`.

---

#### Mode B — Narrative Neglect (Availability Deflation)

- `narrative_z < -1.8` (event topic narratively silent / below baseline)
- `market.yes_price ∈ [0.15, 0.45]` (suppressed but not at floor)
- `consensus_prior − market.yes_price ≥ 0.03` (YES underpriced vs base rate)
- `market.days_to_resolution ≤ 30` (approaching resolution; neglect must correct before close)
- Same liquidity and entity-match gates as Mode A

**Signal:** BUY YES. Hold until: (a) `narrative_z` rises above −1.0 OR (b) YES price within 3pp of `consensus_prior` OR (c) 14 days elapsed.

**Kelly α:** `0.07 × price_gap_scalar × neff_adj`.

---

#### Mode C — Post-Shock Residual Fade (New at sophisticated)

Distinct from SAD (which captures the initial shock lag). Mode C targets the RESIDUAL overshoot after the first wave of attention-driven traders have already updated prices.

- `gdelt_velocity_z > +3.5` in the prior 4h (news burst detected)
- `market.yes_price` has moved > 8pp in the SAME 4h window
- `narrative_z` is in the SAME direction as price move AND `narrative_z > +2.5`
- Wait window: hold-off 6h after burst (let SAD-type traders exhaust first)
- After 6h: if `market.yes_price` still > pre-burst level + 5pp AND `consensus_prior` delta < 3pp → FADE the residual overshoot
- Kelly α: 0.06×; max hold 10 days

---

#### Mutual Exclusion and Mode Priority

```
Mode A priority > Mode C > Mode B (when multiple modes fire simultaneously)
A and B cannot co-fire (A fires when narrative_z > +2.0, B fires when < -1.8 — mutually exclusive by definition)
C fires in Mode A direction only (fade direction = same as Mode A when burst confirms positive narrative)
```

---

#### N_eff Corrections (All Analytical — INDEP scan BLOCKING)

| Pair | Expected ρ | Tier | Rule |
|---|---|---|---|
| SSNM + social-attention-divergence | 0.55–0.65 | A | Single-signal: use max(α_SSNM, α_SAD); no compounding |
| SSNM + news-velocity-directional | 0.40–0.50 | B | Combined floor 0.78×; suppress wins if both fire |
| SSNM + anchor-event-recency-bias | 0.25–0.35 | C | N_eff(2, 0.30) = 1.43; cap 1.20× |
| SSNM + llm-ensemble-probability | 0.15–0.25 | D | Independent; free compound |
| SSNM + category-base-rate-neglect | 0.10–0.20 | D | Independent; free compound |

Hard caps after all N_eff adjustments: **Amplify ≤ 0.15× Kelly** / **Suppress floor N/A** (PM is directional, not meta-signal).

---

#### Failure Modes (FM Taxonomy)

| Code | Condition | Circuit Breaker |
|---|---|---|
| FM1 | Entity match cosine < 0.75 → GDELT articles do not map to PM market | Skip signal; log `FM1_ENTITY_MISMATCH` |
| FM2 | Narrative z-extreme is informational (GDELT velocity > 4.0 — genuine breaking news) | Require `gdelt_velocity_z < 3.5` at Mode A/B entry; Mode C handles burst case |
| FM3 | Market liquidity > $500k → sophisticated participants dominate; availability bias corrected faster | Skip signal; log `FM3_WHALE_MARKET` |
| FM4 | Days to resolution < 72h → not enough correction time | Skip signal; log `FM4_NEAR_EXPIRY` |
| FM5 | Consensus prior unavailable (Metaculus < 3 forecasters AND base rate database miss) | Skip signal; log `FM5_NO_PRIOR` — BLOCKING |
| FM6 | ρ(SSNM, SAD) confirmed > 0.70 at INDEP scan → essentially same signal | Demote SSNM to SAD addendum; retire standalone |
| FM7 | Mode A WR < 50% at N = 20 over first live quarter | Suspend Mode A; raise `narrative_z` threshold to +2.5 |
| FM8 | Mode B WR < 50% at N = 15 | Suspend Mode B; raise to `narrative_z < -2.2` |

---

### Formal Hypotheses

| Hypothesis | Test | Gate |
|---|---|---|
| H1: Mode A WR ≥ 58% (next-21d outcome) when narrative_z > +2.0 AND yes_price > prior + 5pp | Mann-Whitney U one-tailed p < 0.10 at N ≥ 20 | G2 BLOCKING |
| H2: Mode B WR ≥ 55% (next-14d outcome) when narrative_z < -1.8 AND yes_price < prior - 3pp | Mann-Whitney U one-tailed p < 0.10 at N ≥ 15 | G2 BLOCKING |
| H3: Mode C WR ≥ 55% (next-10d outcome) after post-burst fade entry | N ≥ 10 required; Mann-Whitney p < 0.15 | G2 secondary |
| H4: Signal edge persists post-2024 (IS-1: 2022–2023 vs IS-2: 2024+) | Both sub-periods WR ≥ 53% at N ≥ 10 each | G2 sub-period BLOCKING |
| H5: IS Sharpe ≥ 0.90 (Mode A) / 0.80 (Mode B) on 36-cell CPCV; DSR ≥ 0.50 | CPCV K=10, T2=20%, C=200 | G3 BLOCKING |

---

### CPCV + Deflated Sharpe Grid

**Grid (36 cells = 3 × 3 × 4 CPCV folds):**

| Parameter | Values |
|---|---|
| `narrative_z_threshold` (Mode A entry) | +1.8, +2.0, +2.3 |
| `price_gap_floor` (yes_price − prior) | 0.03, 0.05, 0.08 |
| `hold_window_days` | 10, 14, 21 |
| CPCV folds K | 4 (outer) |

3 × 3 × 4 = 36 combinatorial paths. Metric: WR (primary); Sharpe (secondary confirmation).

**IS Sharpe targets** (McLean-Pontiff 58% post-publication decay budget):
- Mode A IS Sharpe ≥ 0.90 → expected live Sharpe ≥ 0.38 (minimum viable)
- Mode B IS Sharpe ≥ 0.80 → expected live Sharpe ≥ 0.34

**DSR threshold:** DSR ≥ 0.50 = FULL deployment; DSR 0.20–0.50 = paper trading only; DSR < 0.20 = anti-prim A fires.

**Anti-overfit plateau test:** Collapse 36-cell WR to 1D projections for each parameter. If ≥ 2 parameters show < 3pp WR range across values → robust to parameter choice → proceed. If any parameter shows > 10pp WR cliff → deploy at ±1 value only around CPCV-selected optimum.

---

### Anti-Prim Escape Hatches (7)

**(A) IS WR gate:** Mode A WR < 50% at N ≥ 20 → retire Mode A.
**(B) Entity match precision gate:** Entity matching precision < 70% on 50-market evaluation set → Mode A and B suspended until pipeline improved.
**(C) Consensus prior coverage gate:** FM5 fires > 40% of all qualifying signals → base rate database coverage insufficient → BLOCKING; expand category_ipw_base_rate before any live deployment.
**(D) SAD correlation gate (INDEP):** ρ(SSNM, SAD) > 0.70 confirmed → demote to SAD Mode C addendum; retire SSNM as standalone.
**(E) Sub-period decay gate:** IS-1 WR ≥ 60% (N ≥ 10) but IS-2 WR < 50% (N ≥ 10) → mechanism decay; suspend; 6-month rolling OOS monitoring; retire if 3 consecutive windows WR < 50%.
**(F) Mode C frequency collapse:** Mode C fires < 5 times per year → insufficient signal frequency → deactivate Mode C, remove from deployment.
**(G) Post-publication decay confirmation (McLean-Pontiff):** If own-data post-deployment Sharpe < 0.35 (Mode A) over N ≥ 30 live trades → ML decay confirmed → raise narrative_z threshold to +2.5 and re-run CPCV.

---

### Data Sources

| Source | Role | Status |
|---|---|---|
| GDELT GKG API (2.0 realtime) | AvgTone z-score + velocity | BLOCKED (integration required) |
| Twitter/X enterprise API | Entity mention count z-score | BLOCKED ($5k+/mo; academic proxy alternatives: Brandwatch, GNIP) |
| Reddit Pushshift / PRAW | Submission velocity z-score | SOFT BARRIER (free via PRAW; rate limits) |
| Metaculus API | Consensus prior (primary) | SOFT BARRIER (free; coverage patchy on non-forecasting-focused markets) |
| Gamma API (Polymarket historical) | Resolution outcomes for IS scan | SOFT BARRIER (established in other polymarket prims) |
| `category_ipw_base_rate` module | Consensus prior fallback | BLOCKED (requires full Gamma historical resolution database; shared dependency with category-base-rate-neglect-fade) |

**First barrier:** GDELT GKG entity-matching pipeline — entity resolution precision ≥ 70% on 50 test markets (G1). Use the same pipeline architecture developed for `news-velocity-informed-directional` if available.

---

### Gate Sequence

```
G_DATA: GDELT GKG + Twitter proxy + Metaculus API + Gamma API → BLOCKING
  ↓
G1: Entity matching precision ≥ 70% on 50-market test set → BLOCKING
  ↓
G2: IS scan H1 + H2 (Mode A WR ≥ 58%, Mode B ≥ 55%; sub-period H4) → BLOCKING
  ↓
G3: CPCV + DSR (36-cell; DSR ≥ 0.50) → BLOCKING
  ↓
G4: INDEP scan — ρ(SSNM, SAD) < 0.70 confirmed → BLOCKING
  ↓
G5: 90-day paper trading (Mode A + B; Mode C DRY_RUN until N ≥ 10) → BLOCKING
  ↓
LIVE (Mode A + B); Mode C live activation after N ≥ 10 paper trades pass H3
```

Kelly α schedule:
- G_DATA partial + G1: 0.06 floor (DRY_RUN)
- G2 cleared: 0.09
- G3 DSR ≥ 0.50: 0.12
- G5 complete: 0.15 cap
- Anti-prim G fires: 0.10 hard cap; threshold raised

---

### Academic Anchors (11)

| Anchor | Contribution |
|---|---|
| Tversky & Kahneman (1973, Cognitive Psychology 5:207–232) | Availability heuristic — core mechanism; people estimate probability by ease of exemplar recall → narratively salient events → systematically overestimated |
| Sunstein & Zeckhauser (2011, J. Legal Analysis 3:1–70) | Availability cascade — socially amplified narratives → collective risk overestimation; mechanism for why narrative_z extremes → persistent PM mispricing |
| Bordalo, Gennaioli & Shleifer (2012, JF 67:1243–1285) | Salience theory — salient outcomes are overweighted in probability assessments; grounds the fade direction for Mode A (overshoot in salience direction) |
| Da, Engelberg & Gao (2011, JF 66:1461–1499) | SVI → return predictability with 2-week reversal; attention effect is transient → grounds hold_window ≤ 21d and fade direction for availability inflation |
| Garcia & Schweitzer (2015, RSOS 2:150-084) | BTC Twitter volume spikes → price reversal 1–3d; social volume velocity as leading reversal indicator; ground for Mode C 6h hold-off window |
| Tetlock (2007, JF 62:1139–1168) | News pessimism predicts next-day equity returns; media sentiment z-scores validated as quantifiable predictors |
| Cowgill & Zitzewitz (2015, ReStat 97:565–582) | PM prices reflect systematic cognitive biases from participant population; empirical evidence that PM mispricings from bias exist and persist days-weeks |
| Barber & Odean (2008, RFS 21:785–818) | Attention-driven buying → overpriced assets; retail investors buy attention-grabbing assets → grounds Mode A fade (availability inflation creates overbuying) |
| Rothschild & Wolfers (2012, AER P&P 102:107–112) | PM prices vs polls show systematic deviations; PM participants do not aggregate information perfectly → availability bias can persist until resolution |
| Bailey, Borwein & López de Prado (2016, JPM / SSRN 2326253) | Deflated Sharpe Ratio mandatory for hyperopt grids; DSR ≥ 0.50 deployment threshold |
| McLean & Pontiff (2016, JF 71:5–32) | Anomaly Sharpe decays ~58% post-publication; sets IS Sharpe ≥ 0.90 target for 0.38 minimum live edge |

---

### Conditions Summary

**Works when (Mode A — Availability Inflation Fade):**
- `narrative_z > +2.0` (extreme positive topic narrative)
- `market.yes_price ∈ [0.55, 0.85]`
- `market.yes_price − consensus_prior ≥ 0.05`
- `days_to_resolution ≥ 7`; `liquidity ≤ $500k`
- Entity match cosine ≥ 0.75; consensus prior available (G5)
- G2 IS scan passed; G3 DSR ≥ 0.50; G4 INDEP ρ < 0.70

**Works when (Mode B — Narrative Neglect Accumulation):**
- `narrative_z < -1.8` (narratively silent event)
- `market.yes_price ∈ [0.15, 0.45]`
- `consensus_prior − market.yes_price ≥ 0.03`
- `days_to_resolution ≤ 30`
- Same entity match and gate requirements

**Works when (Mode C — Post-Shock Residual Fade):**
- Initial news burst: `gdelt_velocity_z > +3.5` (prior 4h)
- Price moved > 8pp in same 4h; 6h hold-off elapsed
- Residual overshoot ≥ 5pp above pre-burst; `consensus_prior` delta < 3pp
- `narrative_z > +2.5` (burst confirmed extreme)

**Fails when:**
- Entity match < 0.75 (FM1)
- News burst informational (FM2 — `gdelt_velocity_z > 3.5` at Mode A/B entry; route to Mode C instead)
- Liquidity > $500k (FM3)
- Days to resolution < 72h (FM4)
- No consensus prior (FM5 — BLOCKING)
- ρ(SSNM, SAD) > 0.70 confirmed (FM6 — demote to SAD mode)
- Mode A/B WR < 50% at N = 20/15 (FM7/FM8 — suspend + recalibrate)

---

### Bank State Change

- naive: 22 (unchanged)
- intermediate: 23 → 22 (social-sentiment-narrative-momentum elevated; intermediate file retained as historical — marked SUPERSEDED)
- sophisticated: 25 → 26 (+1: social-sentiment-narrative-momentum)
