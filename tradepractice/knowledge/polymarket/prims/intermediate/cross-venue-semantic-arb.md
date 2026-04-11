---
name: cross-venue-semantic-arb
level: intermediate
project: polymarket
parent_prim: naive/cross-venue-semantic-arb
created: 2026-04-11
last_validated: never
reaction_validated: no
---

## Prim: cross-venue-semantic-arb
**Level:** intermediate (elevated from naive)
**Project:** polymarket
**Parent:** naive/cross-venue-semantic-arb

### What Changed

The naive prim had three structural weaknesses: flat gap thresholds (4.5% geopolitics, 7% crypto) that ignored probability-dependence; "manual review" for semantic equivalence with no deployable ruleset; and "simultaneous market orders" that are impossible cross-chain without atomic execution.

**Three core upgrades:**

| # | Upgrade | Evidence |
|---|---------|---------|
| 1 | **Dynamic friction floor**: `min_gap(p) = (0.07 + PM_fee_rate) × p × (1−p) + 0.020 + 0.0015` — replaces flat thresholds; friction varies 2.78–7.50% depending on p and category | Kalshi fee formula (`0.07×P×(1−P)`) + Polymarket category fee docs + naive prim's 2% slip estimate |
| 2 | **3-class semantic risk classifier**: deterministic keyword/rule-based; Class 0 = execute; Class 1 = add 2.5% buffer; Class 2 = skip — replaces "manual review" with a deployable pre-trade gate | 2024 failure case taxonomy (shutdown, Bitcoin Reserve) + arxiv 2601.01706 structural divergence analysis |
| 3 | **Staged bilateral fill protocol**: cross-venue USD-equivalent depth ranking → less-liquid leg first as limit order → liquid leg as market order within 3s → cancel-and-unwind if 5s elapsed — replaces impossible "simultaneous market orders" | binary-arb-completeness sophisticated protocol (same partial-fill logic, cross-venue adaptation) |

### Rule (Intermediate)

Identify co-listed event on Polymarket and Kalshi. Score semantic equivalence via 3-class classifier. If Class 0 or 1: compute `min_gap(p)` using dynamic friction floor; execute only if observed gap > `min_gap(p)` (+ 2.5% buffer for Class 1). Submit less-liquid leg first as limit at best ask; upon fill confirmation, submit liquid leg as market order within 3s; cancel-and-unwind if total elapsed > 5s without both legs confirmed.

### Mechanism

Same as naive: structural fragmentation between informationally disconnected venues creates persistent pricing gaps. The intermediate refinement adds three filters that eliminate the three primary loss mechanisms:
- **Friction filter**: prevents entering trades that are structurally fee-negative at the observed probability p
- **Semantic filter**: eliminates the catastrophic total-loss scenario (100% on wrong leg when platforms resolve oppositely)
- **Fill protocol**: eliminates directional binary exposure from partial fills (one leg fills, other does not)

### Dynamic Friction Floor

**Formula:**
```
min_gap(p, pm_category) = 
    Kalshi_fee(p)       = 0.07 × p × (1−p)
  + PM_fee(p, cat)      = PM_fee_rate × p × (1−p)
  + slippage            = 0.020  (2% flat — conservative for thin cross-venue books)
  + bridge_cost         = 0.0015 (ZeroHash USDC↔USD, empirical from newyorkcityservers.com 2026)
```

**Viability table at p=0.50 (peak friction, most conservative):**

| Polymarket Category | Kalshi Coeff | PM Rate | Combined Fee | Slip | Bridge | **Total (p=0.50)** |
|---|---|---|---|---|---|---|
| Geopolitics | 0.07 | 0.00 | 1.75% | 2.0% | 0.15% | **3.90%** |
| Politics/Finance | 0.07 | 0.04 | 3.75% | 2.0% | 0.15% | **5.90%** |
| Sports | 0.07 | 0.03 | 3.25% | 2.0% | 0.15% | **5.40%** |
| Weather | 0.07 | 0.05 | 4.50% | 2.0% | 0.15% | **6.65%** |
| Crypto | 0.07 | 0.072 | 5.35% | 2.0% | 0.15% | **7.50%** |

**Tail bracket advantage (p=0.10 or p=0.90):**

| PM Category | Combined Fee at p=0.10 | Total (with slip + bridge) |
|---|---|---|
| Geopolitics | 0.07 × 0.09 = 0.63% | **2.78%** |
| Politics | (0.07+0.04) × 0.09 = 0.99% | **3.14%** |
| Crypto | (0.07+0.072) × 0.09 = 1.28% | **3.43%** |

**Paradox**: tail brackets (p < 0.15 or p > 0.85) have the lowest friction floor (2.78% for geopolitics) but also the highest semantic risk — resolution conditions for near-certain or near-impossible events are most likely to have platform-specific language about "partial" conditions, magnitude thresholds, and timing boundaries. The Class 2 semantic skip rate is estimated highest in tail brackets.

**Practical constraint**: only Geopolitics × Kalshi Political is structurally viable as a systematic strategy at taker execution. All other category combinations require gaps > 5.4% to cover taker friction — pushing into the semantic-risk zone.

### 3-Class Semantic Risk Classifier

**Four failure-mode types** (derived from documented 2024 divergence cases):

| Type | Pattern | Example |
|---|---|---|
| **A — Quantitative threshold** | "exceeding", "at least", "equivalent to [standard]", "minimum of", "more than [N]" | Bitcoin Reserve: "any amount" vs "SPR-equivalent" |
| **B — Time window boundary** | "exceeding [N] hours", "consecutive", "continuous", "within [N] days", "before [date]" | Shutdown: "announcement" vs "shutdown exceeding 24h" |
| **C — Documentation standard** | "confirmed by White House", "New York Times", "official statement" vs "credible reporting", "consensus of" | Polymarket "credible reporting" vs Kalshi "WH or NYT" |
| **D — Scope qualifier** | "partial", "full", "complete", "temporary", "permanent", "federal-level" | Shutdown: partial vs complete shutdown distinction |

**3-class classification rules:**

```
Class 0 (IDENTICAL — execute at min_gap(p)):
  - No Type A, B, C, or D markers in resolution text diff
  - Core resolution clause word overlap ≥ 80% (token-level)
  - Both platforms reference same oracle/source
  - No prior documented divergence for this event type

Class 1 (EQUIVALENT — execute at min_gap(p) + 2.5% additional buffer):
  - No Type A or B markers
  - Type C or D present but does NOT change resolution outcome for expected scenarios
    (e.g., different wording for "win" in an election with binary outcome)
  - Core event entity is identical (same person, same country, same legislation)

Class 2 (DIVERGENT/UNKNOWN — SKIP):
  - Any Type A or B marker present (quantitative threshold or time window difference)
  - Type C present AND event has precedent divergence in same category
  - Resolution text overlap < 60% (token-level)
  - Event type in high-divergence categories: 
      government_shutdown, executive_orders with conditions, asset_reserve_policies,
      treaty_ratification, administrative_declarations
  - "Unknown": no rule triggers but first-time event type with no comparator
```

**Estimated classification rates** (from documented failure case analysis):
- ~40–50% of co-listed events: Class 0 (simple binary outcomes with clear, equivalent language)
- ~20–30%: Class 1 (same event, minor documentation wording differences)
- ~25–35%: Class 2 (complex conditional events, executive-action-dependent resolution)

**Skip rate**: approximately 25–35% of co-listed events should be skipped via Class 2. The residual 65–75% requires further friction-floor filtering.

### Bilateral Fill Protocol

**Step 1 — Cross-venue liquidity ranking:**
Compare depth in USD-equivalent on each side:
```
depth_USD(venue, price, size) = 
    sum(order_qty × order_price for orders within 2% of target_price)
    expressed in USDC (PM) or USD-equivalent (Kalshi)
```
Less-liquid venue = venue with smaller `depth_USD(venue, target_price, position_size)`.

**Step 2 — Staged submission:**
1. Submit leg 1 (less-liquid venue) as **limit order at best ask** — accepts fill at current price or better; avoids market-order slippage on thin venue
2. On fill confirmation (WebSocket receipt OR REST poll within 1s): immediately submit leg 2 (liquid venue) as **market order** — prioritizes fill speed over price over-run
3. Timeout: if leg 1 not confirmed within 3s of submission → cancel leg 1; abort trade

**Step 3 — Cancel-and-unwind protocol:**
- If leg 2 not confirmed within 5s of leg 1 fill → attempt cancel of leg 2 (if limit)
- Mark position as "directional exposure — unwind required"
- Liquidate leg 1 at market immediately; log exposure duration and P&L impact
- Resolution timing monitor: after both legs fill, subscribe to oracle feeds on both platforms; log timestamp delta between resolution events (anti-prim indicator if Kalshi systematically resolves 2h+ before Polymarket on same events)

**Step 4 — Class 1 enhanced monitoring:**
For Class 1 trades (EQUIVALENT): monitor both platforms for resolution conflict signal (one resolves YES, other still open) → if detected before own platform resolves, attempt liquidation of confirmed leg at market.

### Conditions

- **Works when:** Semantic Class 0 or 1; gap > min_gap(p, category) (+ 2.5% for Class 1); bilateral accounts pre-funded; cross-venue depth ≥ 3× position size on both legs; time-to-resolution > 6h (extended from naive's 4h — protects against resolution-race on Class 1 trades); staged fill protocol completes within 5s; Polymarket category geopolitics (cheapest friction)
- **Fails when:** Semantic Class 2 (quantitative threshold or time window difference present — SKIP); gap ≤ min_gap(p, category) (fee-negative at observed p); cross-venue depth insufficient on less-liquid leg (fills at significantly worse price, erodes edge); resolution timing asymmetry triggers naked exposure before both legs resolve; ZeroHash USDC↔USD conversion delayed (Kalshi-side capital unavailable); tail bracket (p < 0.10 or p > 0.90) Class 1 trade — friction is low but semantic risk is high; leg 2 unfilled within 5s creates directional binary exposure
- **Best pairs:** Polymarket geopolitics (0% fee) × Kalshi political market (0.07 coeff) at p ≈ 0.20–0.80; target gap > 4.5% (net positive after 3.90% floor + 0.5–1% safety buffer)
- **Best timeframe:** Real-time WebSocket both venues; execute staged fill < 5s total; resolution horizon > 6h

### Evidence

- **Source:** paper + practitioner + derived
- **Certainty:** hypothesis (mechanism confirmed by academic dataset; friction floor derived analytically; classifier rules derived from documented failure cases; zero own-data trades)
- **Data:** arxiv 2601.01706: 6% of 100k+ events co-listed, 2–4% average persistent deviation (below practical taker floor at p=0.50); practitioner combined friction > 5% on most viable gaps (newyorkcityservers.com 2026); 0 own trades — pending live deployment
- **Citation:** [arxiv 2601.01706](https://arxiv.org/abs/2601.01706); [Kalshi fee documentation](https://kalshi.com/docs/fee-schedule); [Polymarket fee docs](https://docs.polymarket.com/polymarket-learn/trading/fees); [newyorkcityservers.com 2026 guide](https://newyorkcityservers.com/blog/prediction-market-arbitrage-guide); binary-arb-completeness sophisticated (fill protocol analogy)

### Limitations (6, refined from naive)

1. **Semantic classifier false negative rate unknown** — the 3-class rule set was derived from 2 documented failure cases; novel event types may carry Type A/B/C/D risks without triggering the keyword patterns. A hedge fund with ML semantic matching will classify better. Estimated FN rate: unknown.

2. **Slippage model is flat 2%** — actual slippage depends on position size vs depth. A $200 position on a $50k-deep market has near-zero slippage; a $2,000 position on a $5k-deep market has 5%+ slippage. The 2% flat is conservative for small positions, inadequate for large ones. Dynamic slippage model is the primary intermediate gap.

3. **No atomic bridge** — cross-chain atomicity remains absent. The staged fill protocol mitigates partial-fill risk but does NOT eliminate directional exposure in the 0–5s window between fills. A price shock during that window creates binary loss on one leg.

4. **Bilateral capital efficiency** — double pre-funded capital for any single trade. A 5% gap on a $200 position generates $10 profit but requires $400 in pre-deployed capital ($200 per venue). Effective ROI = 10/400 = 2.5% per trade; annualized only via trade frequency.

5. **Resolution timing asymmetry (unquantified)** — no data on how often Kalshi resolves N hours before Polymarket on same events. Intermediate classification: suspected. Monitoring protocol added but no threshold-based classifier for "resolution-race" markets yet.

6. **Class 1 buffer of 2.5% is heuristic** — derived by inspection of documented failure cases (gaps of 10–20% were legitimate contract differences, not mispricings). Buffer should eventually be calibrated against the base rate of resolution divergence per event type. Current 2.5% is conservative for simple Class 1 cases, possibly insufficient for complex ones.

### Implementation

- **Existing code:** NONE — new strategy
- **New file:** `src/strategies/cross_venue_arb.py`
- **New modules:**
  - `src/classifiers/semantic_risk.py` — `SemanticRiskClassifier.classify(pm_resolution_text, kalshi_resolution_text) → (class_id: int, markers_found: list)`
  - `src/utils/cross_venue_depth.py` — `depth_usd_equivalent(venue, market_id, target_price, position_size) → float`
  - `src/execution/bilateral_fill.py` — `BilateralFillProtocol.execute(leg1_venue, leg1_market, leg2_venue, leg2_market, position_size) → FillResult`
- **Key parameters:**
  - `KALSHI_FEE_COEFF = 0.07`
  - `BRIDGE_COST = 0.0015`
  - `SLIPPAGE_FLAT = 0.020` (to be replaced by dynamic model at sophisticated tier)
  - `CLASS_1_BUFFER = 0.025`
  - `FILL_TIMEOUT_LEG2_S = 5`
  - `MIN_RESOLUTION_HORIZON_H = 6`
  - `MIN_DEPTH_MULTIPLIER = 3.0` (depth ≥ 3× position size on each leg)

### Conditions Log Entry
- Works when: Semantic Class 0 or 1; gap > `(0.07 + PM_fee_rate) × p × (1−p) + 0.0215` + 2.5% for Class 1; bilateral depth ≥ 3× position size; time-to-resolution > 6h; geopolitics × political (lowest combined friction); staged fill completes < 5s
- Fails when: Semantic Class 2 (Type A/B markers — quantitative threshold or time window difference); gap ≤ dynamic friction floor; resolution < 6h; depth insufficient on less-liquid leg; ZeroHash conversion delay; leg 2 unfilled within 5s (directional exposure)
- Last validated: never

## Refinement History
- 2026-04-11: Created as naive prim (cycle 30). 2026-04-11 (cycle 32): Elevated to intermediate. Three upgrades: (1) dynamic friction floor formula replacing flat thresholds; (2) 3-class deterministic semantic classifier from failure-case taxonomy; (3) staged bilateral fill protocol with cross-venue liquidity ranking.

## Next Refinement Path (Sophisticated)
Three upgrades required:
1. **NLP semantic scorer** — sentence-transformer cosine similarity on resolution texts (e.g., `all-MiniLM-L6-v2`); replace token-overlap with embedding similarity; calibrate Class 0/1/2 thresholds against a labeled dataset of co-listed events with known resolution outcomes
2. **Dynamic slippage model** — replace 2% flat with `position_size / depth_at_target_price × price_impact_factor`; requires live depth data from both Kalshi and Polymarket CLOBs at order-submission time
3. **Resolution-race classifier** — detect markets where Kalshi oracle polling schedule is systematically earlier than Polymarket's; add time-delta threshold gate (reject if estimated resolution-timing asymmetry > 2h on same event)
