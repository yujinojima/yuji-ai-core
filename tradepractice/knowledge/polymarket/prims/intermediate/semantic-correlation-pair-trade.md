---
name: semantic-correlation-pair-trade
level: intermediate
project: polymarket
parent_prim: naive/semantic-correlation-pair-trade
created: 2026-04-11
last_validated: never
reaction_validated: no
---

## Prim: semantic-correlation-pair-trade
**Level:** intermediate (elevated from naive — academic evidence sufficient to bypass naive tier)
**Project:** polymarket
**Parent:** naive/semantic-correlation-pair-trade

### What Changed from Naive

The naive prim had a flat 5% divergence threshold with no model of the relationship types, no friction formula, and no failure mode taxonomy.

**Three core upgrades:**

| # | Upgrade | Evidence |
|---|---------|---------|
| 1 | **4-class relationship taxonomy** (Implication / Positive Correlation / Temporal Chain / Anti-correlation) with per-class implied probability constraint formula | Logic + arxiv 2512.02436 relationship clustering methodology |
| 2 | **Dynamic friction floor**: `min_edge(p, category) = fee_rate × p × (1−p) + 0.015 + 0.03` — far lower than cross-venue arb; single-venue single-position removes bilateral capital requirement | Polymarket fee docs + bid-ask spread empirical estimate 1.5% |
| 3 | **Resolution oracle risk gate**: reuse 3-type oracle divergence classifier from cross-venue-semantic-arb (Types A/B/C) — markets with different oracle thresholds or documentation standards are NOT semantically equivalent even if embedding similarity is high | cross-venue-semantic-arb sophisticated failure taxonomy |

### Rule (Intermediate)

Identify a Polymarket market pair with sentence-transformer cosine similarity ≥ 0.82 AND a verifiable 4-class logical relationship. Compute the implied price constraint for the relationship class. If the observed price of the lagging market deviates from the implied constraint by > `min_edge(p, category)`, enter a long position on the underpriced market. Exit when: (a) deviation closes to < 1.5%, (b) either market resolves, (c) 14 days elapsed without convergence, or (d) asymmetric news catalyst detected on either market.

### Mechanism

Polymarket participants operate in fragmented information silos. A bettor specialised in "US Senate control" does not simultaneously monitor "US presidential race" to check for consistency. No bot infrastructure currently exists to enforce intra-platform price consistency across non-exhaustive correlated pairs (binary-arb-completeness covers the exhaustive-sum case; this prim covers the non-exhaustive correlation case). The arxiv 2512.02436 paper validates this mechanism at scale: 60–70% relationship classification accuracy; ~20% average return per week-long horizon in their simulated strategy.

The edge source differs fundamentally from all 6 existing polymarket prims:
- **Not binary-arb**: no contractual ΣP = $1 guarantee — this is probabilistic convergence
- **Not cross-venue arb**: same venue, same rails, no bilateral capital or USDC/USD conversion
- **Not spread-capture**: directional long, not market-making
- **Not weather/ensemble**: no NWP forecast data
- **Not OBI**: no CLOB depth signal
- **Not Kelly**: this IS the bet that Kelly sizes

### 4-Class Relationship Taxonomy

**Class 1 — Implication (A implies B)**
```
Constraint: P(B) ≥ P(A) × P(B|A)
            where P(B|A) is an informed prior on the conditional probability

Example:
  A = "Trump wins 2028 Republican primary"  [observed: 72%]
  B = "Trump wins 2028 general election"   [observed: 38%]
  Informed prior: P(general win | primary win) ≈ 0.50 (recent election data)
  Implied P(B) ≥ 0.72 × 0.50 = 0.36
  Observed P(B) = 0.38 → within implied range; no trade
  If observed P(B) = 0.25 → underpriced by ~11pp vs implied lower bound

Action: If P(B) < P(A) × P(B|A) → BUY B (underpriced)
        If P(A) > P(B) / P(B|A) → P(A) overpriced; but harder to short on Polymarket
```

**Class 2 — Positive Correlation (same causal driver)**
```
Constraint: Price movement in A without corresponding movement in B
            exceeds the historical mean-reversion speed for that market pair

Example:
  A = "Democrats win Senate 2026"     [was 45%; jumps to 60%]
  B = "Democrats win House 2026"      [remains at 35%]
  Both driven by Democratic electoral wave; lag exceeds historical correlation

Action: If P(A) moves +15pp but P(B) stays flat → BUY B if divergence > min_edge
        Note: requires correlation history estimate or same-day news catalyst as trigger
```

**Class 3 — Temporal Chain (same metric, adjacent time horizons)**
```
Constraint: P(A) ≥ P(B) where A is a nearer-term version of B
            (nearer-term outcome must be at least as likely as farther-term)

Example:
  A = "Fed cuts rates in Q1 2026"      [observed: 30%]
  B = "Fed cuts rates before Q3 2026"  [observed: 22%]
  P(B) ≥ P(A) required (A is a subset of B's horizon window)
  Observed: 22% < 30% → B is mispriced by ~8pp

Action: If P(A) > P(B) where A is subset-horizon of B → BUY B
```

**Class 4 — Anti-correlation (mutual exclusivity, non-exhaustive)**
```
Constraint: P(A) + P(B) ≤ 1 + P(neither) where P(neither) is informed estimate
            Note: if P(A) + P(B) > 1.00 → this becomes binary-arb-completeness
                  (buy both; guaranteed profit at resolution)

Example:
  A = "Candidate X wins mayoral race"  [observed: 60%]
  B = "Candidate Y wins mayoral race"  [observed: 55%]
  Sum = 1.15 > 1.00 → binary-arb territory (handle via binary-arb-completeness)
  
  If A = 55%, B = 25%, P(neither) ≈ 20%: A + B = 80% ≈ acceptable
  But if A suddenly drops to 35% and B stays at 25%: B may be underpriced
  if the "sum must be approximately 1 - P(neither)" constraint is violated

Action: Anti-correlation trades are most reliable when one contract moves
        significantly and the other fails to adjust proportionally.
        Use only Class 4 when sum stays clearly below 1.00 (avoid binary-arb zone).
```

### Dynamic Friction Floor

**Formula:**
```
min_edge(p, category) =
    Polymarket_fee(p, cat)    = fee_rate × p × (1−p)
  + bid_ask_slippage          = 0.015  (1.5% flat, taker execution conservative estimate)
  + safety_buffer             = 0.030  (3% — covers resolution oracle risk residual)
```

**Viability table at p=0.50 (peak friction):**

| Category | Fee Rate | PM Fee at p=0.50 | Slippage | Buffer | **Total Floor** |
|---|---|---|---|---|---|
| Geopolitics | 0% | 0% | 1.5% | 3% | **4.5%** |
| Politics/Finance | 4% | 1.0% | 1.5% | 3% | **5.5%** |
| Sports | 3% | 0.75% | 1.5% | 3% | **5.25%** |
| Weather | 5% | 1.25% | 1.5% | 3% | **5.75%** |

**Tail bracket advantage (p=0.10):**

| Category | PM Fee | Total Floor |
|---|---|---|
| Geopolitics | 0% | **4.5%** (same as p=0.50 — geopolitics has no fee term) |
| Politics | 4% × 0.09 = 0.36% | **4.86%** |

**Structural advantage over cross-venue-semantic-arb:** This prim's friction floor (4.5%–5.75%) is comparable to cross-venue's geopolitics floor (3.90%), but without bilateral capital lockup, ZeroHash conversion risk, or Rule 6.3(c) ambiguous settlement risk. The residual risk is correlation breakdown (probabilistic) not binary divergence (catastrophic).

### Resolution Oracle Risk Gate

Reuse Type A/B/C/D keyword veto from `semantic_risk.py` (cross-venue-semantic-arb classifier):

| Type | Pattern | Action |
|---|---|---|
| **A — Quantitative threshold** | "at least N", "minimum", "equivalent to [standard]" | Require both contracts use SAME numeric threshold; if different → Class 2 ONLY (add 2% extra buffer) |
| **B — Time window** | "consecutive", "within N hours", "before [date]" | Require window definitions align within ±24h; if divergent → SKIP |
| **C — Documentation standard** | "credible reporting" vs "official statement" | No cross-contract oracle comparison needed (same venue); flag for manual review only |
| **D — Scope qualifier** | "perform" vs "appear", "complete" vs "partial" | Same-venue contracts with scope difference → check resolution rule text match > 80% |

**Key difference from cross-venue classifier**: same-venue contracts use Polymarket's single resolution standard. The primary oracle risk here is not platform divergence but **resolution criteria specification divergence within Polymarket** (one contract "at least 5 rate cuts", another "at least 3 rate cuts" — positively correlated but with different trigger thresholds).

### Conditions

- **Works when:**
  - Relationship class confirmed (Class 1, 2, 3, or 4)
  - Sentence-transformer embedding similarity ≥ 0.82 (same threshold as cross-venue Class 0 minus slack for intra-platform) 
  - Implied price constraint violated by > `min_edge(p, category)`
  - Both markets liquid ≥ $5k (lagging market depth ≥ 2× target position)
  - Resolution horizons within 14 days of each other (temporal basis risk)
  - No Type B (time window) oracle divergence between the two contracts
  - NOT an exhaustive-sum pair (P(A) + P(B) < 0.99 → use binary-arb-completeness instead)
  - No asymmetric news catalyst active on either market (same-day scheduled announcements)
  - Position sized via fractional-kelly-sizing sophisticated (correlated N_eff adjustment: ρ ≈ 0.60–0.85 for causally linked markets → N_eff ≈ 1.2–1.5 for 2 positions)

- **Fails when:**
  - Contracts are semantically similar but resolve on different oracles (Type A: one requires "3 cuts" the other "5 cuts" — correlation exists but constraint is not violated by their price relationship)
  - Correlation breaks due to asymmetric new information (one contract gets a direct news catalyst; the other doesn't; the divergence IS the new information, not a misprice)
  - Liquidity in the lagging market is too thin for convergence to happen before resolution
  - Resolution horizon divergence > 14 days (temporal basis risk — P(A) by Q1 and P(B) by Q4 have legitimate calendar discount)
  - Relationship is perceived but unverifiable (narrative similarity without logical structure — e.g., two different countries' election markets that look similar but are independent)
  - Exhaustive-sum market pair (binary-arb-completeness is the correct prim)

- **Best pairs:** Class 1 implication pairs (clearest constraint, lowest ambiguity) on geopolitics category (0% fee) OR Class 3 temporal chain pairs (mechanistically cleanest — subset horizon must be priced ≥ superset horizon)
- **Best timeframe:** Days to 2 weeks holding horizon (arxiv 2512.02436 week-long strategy); check daily for convergence; exit at 14-day maximum

### Evidence

- **Source:** paper (arxiv 2512.02436, IBM+Columbia, Dec 2025) — primary anchor
- **Certainty:** hypothesis — mechanism validated academically; own-data zero
- **Data:**
  - 60–70% relationship classification accuracy (LLM embedding + agentic reasoning)
  - ~20% average return per week-long horizon (simulation in arxiv 2512.02436)
  - No own trades; no live deployment
  - Binary-arb-completeness sophisticated documented $40M intra-platform arb extracted 2024–2025 (related mechanism, exhaustive-sum subset)
- **Citation:** [arxiv 2512.02436 — Semantic Trading (IBM+Columbia, Dec 2025)](https://arxiv.org/abs/2512.02436); binary-arb-completeness sophisticated (combinatorial analogy); cross-venue-semantic-arb sophisticated (oracle risk taxonomy analogy)

### Limitations (7)

1. **Convergence not guaranteed** — unlike binary-arb-completeness, there is no contractual mechanism forcing prices to converge before resolution. Divergence can persist or widen if the correlation model is wrong.

2. **~20% weekly return from simulation** — the arxiv 2512.02436 return figure is from a research strategy simulation, not live trading with real Polymarket fees, actual liquidity constraints, or real execution. Discount estimate: 20% gross → 12–15% net after friction in favourable conditions.

3. **Relationship classifier accuracy 60–70%** — 30–40% classification error rate. For Class 1 (implication), the error takes the form of misidentifying a causal link that doesn't hold. For Class 2 (positive correlation), the error is overestimating correlation coefficient. The 3% safety buffer partially covers this.

4. **No own-data conditional probability priors** — Class 1 requires an estimate of P(B|A) (e.g., P(general win | primary win)). This prior must be sourced from historical election data or modelled externally. Wrong prior = wrong implied constraint = false trade signal.

5. **Portfolio correlation adjustment** — simultaneous positions in multiple correlated pairs require N_eff from fractional-kelly-sizing sophisticated. Two positions in the same causal cluster (e.g., "Trump primary" and "Trump general") have ρ ≈ 0.80–0.90 → N_eff ≈ 1.05 → sizing very conservative; holding both neutralizes the edge.

6. **Asymmetric news detection absent** — no implementation for detecting when one market's price movement IS new information (correct pricing) vs. IS a divergence (misprice). Current spec uses "same-day scheduled announcements" as a proxy gate; unscheduled news remains unhandled.

7. **No implementation** — `src/strategies/correlated_pair_trade.py` does not exist. `src/classifiers/semantic_risk.py` (from cross-venue-semantic-arb) handles the oracle risk gate but not the relationship class scoring.

### Implementation

- **New file:** `src/strategies/correlated_pair_trade.py`
- **New module:** `src/classifiers/relationship_type.py` — `RelationshipClassifier.classify(market_a_text, market_b_text, market_a_price, market_b_price) → (class_id: int, constraint_violation_pp: float, implied_price_a: float, implied_price_b: float)`
- **Reuses:** `src/classifiers/semantic_risk.py` (Type A/B/D oracle veto)
- **Reuses:** `src/risk/kelly.py` (fractional-kelly-sizing sophisticated)
- **Key parameters:**
  - `MIN_EMBEDDING_SIMILARITY = 0.82`
  - `MIN_DIVERGENCE_FROM_FLOOR_PP = 0.00` (trade at exactly min_edge; no extra buffer beyond the formula)
  - `MAX_HOLD_DAYS = 14`
  - `MIN_LIQUIDITY_EACH_MARKET = 5000`
  - `EXIT_CONVERGENCE_PP = 1.5` (exit when deviation narrows to < 1.5%)
  - **BLOCKING before deployment:** validated set of ≥ 20 Class 1 implication pairs with known resolution outcomes to calibrate P(B|A) priors and verify the 60–70% classifier accuracy claim holds on Polymarket's actual market text format

### Conditions Log Entry
- Works when: Class 1/3 implication or temporal chain; embedding ≥ 0.82; constraint violated > `fee_rate × p(1−p) + 0.015 + 0.03`; both liquid ≥ $5k; resolution horizons within 14d; not exhaustive-sum pair
- Fails when: Oracle divergence (different thresholds, same topic); asymmetric news catalyst; illiquid secondary market; exhaustive-sum (use binary-arb); correlation breaks before resolution
- Last validated: never

## Refinement History
- 2026-04-11: Created as naive and immediately elevated to intermediate, cycle 34 RESEARCH. Academic anchor: arxiv 2512.02436 (IBM+Columbia, Dec 2025). No code extraction — new capability class. Oracle risk taxonomy from cross-venue-semantic-arb sophisticated. Friction floor derived from Polymarket fee formula.

## Next Refinement Path (Sophisticated)
Three upgrades required:
1. **Calibrated P(B|A) prior database** — historical election, legislative, and economic event outcome database for Class 1 implication; validates the constraint formula against realized outcomes
2. **Asymmetric news catalyst detector** — classify price movements as "new information" vs "divergence" using OBI sophisticated prim (IR signal change at movement time) + news-event calendar (if IR is balanced during the price move in A, it is more likely correlation-driven than information-driven)
3. **Own-data convergence rate by class** — 50-trade sample per relationship class needed to confirm arxiv 2512.02436 ~20% return claim holds live; calibrate `MAX_HOLD_DAYS` per class (Class 3 temporal chains likely converge faster than Class 2 positive correlation)
