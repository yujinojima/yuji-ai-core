---
from: analyst
subject: analyst-result
timestamp: 2026-04-21T11:27:19+10:00
cycle: 195
---

## Prim: binary-calendar-spread-arbitrage
**Level:** intermediate | **Project:** polymarket | **Cycle:** 195 | **Class:** 29th (new class, direct intermediate entry)

---

### Signal Class

When the same underlying outcome has multiple PM contracts with staggered resolution deadlines (T1 < T2), a no-arbitrage monotonicity constraint applies: P(outcome by T2) ≥ P(outcome by T1), because the T2 event space is a strict superset of T1. PM markets violate this routinely because:

1. **Independent liquidity pools** — separate CLOB depth per expiry; no structural cross-contract arbitrage mechanism
2. **Salience bias** — retail attention and CLOB volume concentrate in the nearest expiry; far contracts remain under-followed
3. **Mental accounting** (Thaler 1985) — each contract is mentally treated as an independent bet, not as part of a joint conditional distribution
4. **Availability cascade** — near-term traders set price anchors that far-term contract holders use as reference, without adjusting for the additional time

The consequence: P(T2) is systematically priced below P(T1) × correct_ratio or, in strong-form cases, below P(T1) outright — a risk-free violation when detectable.

**Distinct from existing prims:**
- CPCA/PRCC: exploit within-event conditional price diffusion after a trigger — same-time horizon, different events
- FMLL: uses external financial market lead-lag on the same contract — single expiry
- Binary arb completeness: YES + NO ≠ 1 on the same contract — same expiry
- **BCSA**: no-arbitrage constraint across multiple expiries on the same event — structural calendar mispricing

**Target categories:** crypto price, macro economic events, political outcomes, sports series — any category where multi-expiry same-event structures are common. Exclude one-off unique events with no second contract.

---

### Mode A — Strong Violation (Near-Risk-Free Arbitrage)

```
ACTIVATE (Mode A) when ALL of:
  1. Identified pair (A_T1, A_T2) where:
       a. same_event: cosine(embed(A_T1.title), embed(A_T2.title)) ≥ 0.85, OR shared event_id/category+entity
       b. same_threshold: resolution condition identical (e.g., "Will BTC hit $X?") — NOT progressive thresholds
       c. T2 > T1 by ≥ 7 days
  2. P(A_T1) > P(A_T2) + delta_strong    # delta_strong = 0.05 (5pp violation buffer)
  3. A_T1.liquidity ≥ $3,000 AND A_T2.liquidity ≥ $3,000
  4. A_T1.bid_ask ≤ 0.06 AND A_T2.bid_ask ≤ 0.06
  5. A_T1.DTE ≥ 2 (entry meaningful before near expiry)
  6. NOT either contract in oracle window (UMA assertion pending)

DIRECTION: BUY A_T2 YES (if A_T1 YES price is the elevated one)
  If bilateral shorting available: ALSO SHORT A_T1 YES (neutralise directional exposure)
  If unilateral only: long A_T2 only (directional residual; size at alpha_unilateral < alpha_bilateral)

SIZE:
  alpha_bilateral  = 0.08     # near-arb; higher confidence
  alpha_unilateral = 0.05     # directional residual retained
  Kelly fraction   = alpha × (edge / odds);  edge = P(A_T1) − P(A_T2) − delta_strong

EXIT:
  P(A_T2) ≥ P(A_T1) − 0.01  (convergence achieved — spread closed)
  A_T1 resolves → close remaining A_T2 position at fair value
  A_T1.DTE < 1 AND violation persists → close (expiry risk)
  Max hold: A_T1.DTE − 1 day
```

### Mode B — Weak Violation (Time-Value Underpricing)

```
ACTIVATE (Mode B) when ALL of:
  1. Same pair conditions as Mode A (1a, 1b, 1c)
  2. P(A_T2) < P(A_T1) × time_ratio_floor
       where time_ratio_floor = 1 + base_rate_daily × (T2 − T1)_days × 0.5
       base_rate_daily = category-specific; default: 0.002/day for crypto_price, 0.001/day for macro
  3. P(A_T2) > 0.10 AND P(A_T2) < 0.90  (not near resolution certainty)
  4. Same liquidity/spread conditions as Mode A
  5. A_T2.DTE ≥ 14 (enough runway for spread to close)

DIRECTION: BUY A_T2 YES (time value underpriced; converges as near contract resolves or event proximity approaches)

SIZE:
  alpha = 0.04   # weaker signal; base_rate_daily estimation noisy
  Kelly fraction = alpha × (edge / odds)
  edge = P(A_T1) × time_ratio_floor − P(A_T2)

EXIT:
  P(A_T2) ≥ P(A_T1) × time_ratio_target  (target = time_ratio_floor + 0.02)
  A_T1 resolves YES → close A_T2 at next tick (strong news anchor)
  A_T1 resolves NO → evaluate: if "NO at T1 → definitely NO at T2" close at market;
                                if "NO at T1 ≠ NO at T2" (e.g., partial threshold) hold
  Max hold: 21 days OR A_T2.DTE − 3 days
```

---

### Pair Identification Logic

```python
def find_calendar_pairs(markets: list[dict]) -> list[tuple]:
    """
    Identify (T1, T2) pairs from Gamma API market list.
    Returns list of (market_T1, market_T2, mode, edge) tuples.
    """
    pairs = []
    open_markets = [m for m in markets if m['status'] == 'open' and m['dte'] >= 2]

    for i, m1 in enumerate(open_markets):
        for m2 in open_markets[i+1:]:
            if m1['resolution_date'] >= m2['resolution_date']:
                continue  # ensure T1 < T2
            t1, t2 = m1, m2

            # Semantic similarity gate
            cos_sim = cosine_similarity(embed(t1['title']), embed(t2['title']))
            if cos_sim < 0.85:
                continue

            # Threshold uniformity gate (G_PAIR pre-check)
            # NLP: extract numeric threshold from title; skip if different
            thresh_match = same_resolution_threshold(t1['title'], t2['title'])
            if not thresh_match:
                continue

            delta_dte = (t2['resolution_date'] - t1['resolution_date']).days
            if delta_dte < 7:
                continue

            p_t1 = (t1['best_ask'] + t1['best_bid']) / 2
            p_t2 = (t2['best_ask'] + t2['best_bid']) / 2

            # Mode A check
            if p_t1 > p_t2 + 0.05:
                pairs.append((t1, t2, 'A', p_t1 - p_t2))

            # Mode B check
            base_daily = 0.002 if 'crypto' in t1.get('category', '') else 0.001
            ratio_floor = 1 + base_daily * delta_dte * 0.5
            if p_t2 < p_t1 * ratio_floor and 0.10 < p_t2 < 0.90:
                pairs.append((t1, t2, 'B', p_t1 * ratio_floor - p_t2))

    return sorted(pairs, key=lambda x: -x[3])  # sort by edge descending
```

**Data sources:**
- Gamma API: market list with `resolution_date`, `best_bid`, `best_ask`, `liquidity`, `category`, `event_id`
- all-MiniLM-L6-v2 embeddings for title similarity
- Warm-up: 0 bars (signal is structural, not historical)

---

### Blocking Gates

| Gate | Condition | Status |
|------|-----------|--------|
| G_PAIR | Gamma API: ≥ 20 confirmed (T1, T2) pairs with verified same-threshold resolution conditions; NLP precision ≥ 0.80 on same-threshold classification | UNCLEARED |
| G_IS | IS: Mode A WR ≥ 60% at N ≥ 15 (below 60% implies strong-form violations often fail to converge); Mode B WR ≥ 52% at N ≥ 15; Mann-Whitney p < 0.10 | UNCLEARED |

All modes DRY_RUN until G_PAIR + G_IS cleared.

---

### Failure Modes

- **FM1 — Resolution condition divergence:** T1 resolves "BTC ≥ $100k by March" while T2 resolves "BTC ≥ $100k by June" — same threshold but different event structures. NLP must catch numeric threshold extraction; failure causes phantom Mode A signals. Resolution: `same_resolution_threshold()` NLP gate with manual spot-check on 10 FP candidates (G_PAIR).
- **FM2 — Single MM providing both quotes:** A single market maker who prices both T1 and T2 will maintain monotonicity internally; the signal fires but no fill available. Symptom: quoted spread looks exploitable but FOK orders rejected. Resolution: check maker-side volume diversity; skip pairs where top-3 wallets account for > 70% of liquidity on both sides.
- **FM3 — Progressive threshold inversion:** "Will X exceed threshold A by T1?" and "Will X exceed threshold B by T2?" where B > A (e.g., "BTC > $80k by March" vs "BTC > $120k by June"). Here P(T2) < P(T1) is correct and not exploitable. Resolution: `same_resolution_threshold()` must extract and compare numeric thresholds.
- **FM4 — Binary conditional dependence breach:** If T1 resolves NO, T2 may also resolve NO with near-certainty regardless of time extension (e.g., election: if candidate loses primary, general election market is N/A). Mode B exit rule handles this; Mode A bilateral position remains profitable regardless.
- **FM5 — Spread convergence before T1 expiry:** Strong-form violation corrects quickly when discovered by other arbitrageurs; entry must be within 4h of detection. Resolution: run pair scan every 2h; signal TTL = 4h.

---

### Evidence

| Source | Finding | Relevance |
|--------|---------|-----------|
| Harrison & Kreps (1979 RES) | Equivalent martingale measure → no-arbitrage: futures prices of nested events must be monotone in time | Primary theoretical anchor: P(T2) ≥ P(T1) is a no-arbitrage constraint, not a statistical tendency |
| Manski (2006 J Econ Lit) | PM prices reflect heterogeneous beliefs; rational and naïve traders co-exist; monotonicity not guaranteed under heterogeneous priors | Why violations persist: rational traders know T2 ≥ T1, naïve traders treat each contract independently |
| Thaler (1985 J Marketing Research) | Mental accounting: psychologically separate accounts for logically linked positions | Mechanism: retail PM traders treat T1 and T2 as independent bets, not a joint distribution |
| Tversky & Kahneman (1973 Psych Rev) | Availability heuristic: events more imaginable (near-term, vivid) judged more probable | Near-expiry salience → T2 systematically under-attended and underpriced relative to T1 |
| Bikhchandani, Hirshleifer & Welch (1992 JPE) | Information cascades: early traders' prices become anchors for later decisions | T1 price anchors T2 price; rational updating toward T1 without applying time-value correction |
| Arrow et al. (2008 Science) | PM efficiency requires active information aggregation; fails for low-attention contracts | Far-dated contracts (T2) attract less attention → slower price aggregation → mispricing persists |

**Certainty:** plausible hypothesis (strong theoretical anchor via Harrison & Kreps no-arbitrage; PM channel via Manski + Thaler mechanisms plausible; Mode A empirically testable with near-zero assumption). N = 0 own-data. All gates UNCLEARED. DRY_RUN.

---

### Path to Sophisticated Elevation

Four structural advances required:

1. **Empirical Time-Value Model** — replace `base_rate_daily` constant with category-specific empirical multiplier from G_PAIR data: `λ_cat = mean(P(T2)/P(T1)) / (T2−T1)_days` across ≥ 20 pairs per category. Replaces Mode B's rough ratio with a data-driven curve.

2. **Convergence Speed Classifier** — from G_IS data, fit a logistic model predicting time-to-convergence from: `(edge, delta_dte, liquidity_ratio, category)`. Output: expected hold duration. Feeds dynamic exit timing replacing fixed 21-day max.

3. **Cross-Signal N_eff Correction** — BCSA T2 positions may co-exist with CPCA/PRCC positions on the same T2 market. Assign ρ_BCSA×CPCA = 0.30 (both are structural; different entry triggers but same underlying contract). Apply `N_eff = N / (1 + (N−1) × ρ̄)` before sizing.

4. **CPCV+DSR 9-cell plateau** — grid: `delta_strong ∈ {0.03, 0.05, 0.08} × time_ratio_factor ∈ {0.5×, 0.75×, 1.0×}` = 9 cells. K=5 CPCV, T2=0.20, C=100 LH paths. Centroid hypothesis: DSR ≥ 0.90 at (0.05, 0.75×, Mode A). Anti-prims: AP-1 centroid DSR ≤ 0 → retire mode; AP-2 ≥ 6/9 cells fail → retire; AP-3 live WR < 0.55 at N ≥ 20 Mode A → suspend.

---

### Relationship to Existing Prims

| Prim | Trigger | Market scope | ρ with BCSA |
|------|---------|-------------|-------------|
| Binary Arb Completeness | YES + NO ≠ 1 on same contract | Same contract | 0.05 (different violation type) |
| CPCA | P(D) violates P(U)×r; both open | Two events, same time horizon | 0.25 (both structural, different trigger) |
| PRCC | A resolves; B not yet updated | Different event, post-resolution | 0.10 (sequential; rarely concurrent) |
| **BCSA** | **P(T1) > P(T2); same event, different expiry** | **Same event, multiple expiries** | — |

BCSA is structurally independent of PRCC/CPCA: it fires on same-event different-expiry pairs, not on correlated-event diffusion.

---

### Bank State (cycle 195)

| Tier | Polymarket | Freqtrade |
|------|-----------|-----------|
| Naive | 23 | — |
| Intermediate | **26** (+1: binary-calendar-spread-arbitrage, axis 29) | — |
| Sophisticated | 28 | — |

**Last validated:** never (DRY_RUN — creation cycle 195; 29th polymarket axis; G_PAIR ∧ G_IS both UNCLEARED)
