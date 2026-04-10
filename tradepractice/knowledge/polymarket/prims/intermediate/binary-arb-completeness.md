---
name: binary-arb-completeness
level: intermediate
project: polymarket
parent_prim: binary-arb-completeness (naive)
created: 2026-04-11
last_validated: never
reaction_validated: no
---

## Prim: binary-arb-completeness
**Level:** intermediate (elevated from naive)
**Project:** polymarket
**Parent:** binary-arb-completeness (naive)

### What changed

The naive prim had a flat MIN_ARB_EDGE=$0.02 and no model of the four critical failure modes: (1) fee structure is category-dependent and non-flat, (2) non-atomic execution creates directional exposure on partial fill, (3) persistent gaps signal structural problems rather than opportunity, (4) capital lockup opportunity cost degrades net return on long-dated markets.

**Four core upgrades:**

| # | Upgrade | Evidence |
|---|---------|---------|
| 1 | **Category-aware fee floor**: `min_edge = 2 × fee_rate × p × (1−p) + buffer` instead of flat $0.02 | docs.polymarket.com fee formula: `fee = C·feeRate·p·(1-p)` |
| 2 | **Gap persistence filter (<90s)**: reject gaps older than 90 seconds at discovery — bots absorbed real arb within 2–30s | Polymarket WS latency ~50ms; professional MM target <10ms (newyorkcityservers.com 2026) |
| 3 | **Partial-fill recovery protocol**: less-liquid leg first; immediate cancel-and-unwind if second leg fails within 5s | Execution atomicity gap in ArbStrategy (confirmed in arb.py code review, cycle 2) |
| 4 | **Lockup-adjusted net edge**: `net_edge = gross_gap − fee_cost − (days_to_resolution × 0.000137)` | Risk-free rate 5% annualized → 0.0137%/day; 30-day lockup costs 0.41% |

**Plus:** binary-only scope (exclude neg_risk multi-outcome markets — atomicity problem scales linearly with number of outcomes, N=5 event needs all 5 legs to fill), competitor-absorbed guard (bid-ask spread < $0.01 on both sides with >$5k depth = bots already at parity), market-voiding risk flag (check `active` + `closed` state on both tokens before submitting).

### Key quantitative findings

| Finding | Source/Derivation |
|---|---|
| **Taker fee by category**: geopolitics 0%, sports 3%, politics/finance 4%, weather/culture/economics 5%, crypto 7.2% | docs.polymarket.com |
| **Fee formula**: `fee_per_leg = fee_rate × price × (1−price)` — peaks at p=0.50 | docs.polymarket.com |
| **Two-leg taker cost at p=0.50**: geopolitics $0, sports $0.015, politics $0.020, weather $0.025, crypto $0.036 | derived from fee formula |
| **Category minimum edges** (fee + 0.5% buffer, at p=0.50): geo $0.005, sports $0.020, politics $0.025, weather $0.030, crypto $0.041 | derived |
| **Bot absorption time**: professional MM <10ms latency, WS 50ms → real arb gaps close in 2–30s | newyorkcityservers.com 2026 |
| **Capital lockup cost**: 5% annual risk-free → 0.0137%/day; 30-day market: 0.41%; 7-day market: 0.096% | treasury yield proxy |
| **Net APY on 2% gap after fees**: 7-day market: 2% × (365/7) ≈ 104% APY; 30-day: 24.3% APY | derived |
| **Neg-risk atomicity cost**: N-outcome event requires N fills; partial fill exposure = (N−1) uncovered positions | ArbStrategy code structure |
| **gwrx2005 AI-arb live result (Polymarket)**: -49.5% ROI over 15 trades (MM strategy, NOT pure arb) — not directly applicable but confirms execution complexity | gwrx2005 Medium (cycle 6 reference) |

### Rule (intermediate)
Enter arb when:
1. `gross_gap = 1.00 − YES_price − NO_price ≥ min_category_edge(category, YES_price, NO_price)`
2. `gap_age_seconds < 90` (gap discovered within 90s of current timestamp)
3. `market.active == True AND market.closed == False` (both token states)
4. `liquidity >= $10,000 AND depth_on_each_side >= position_size_USD / price`
5. `market.market_type == "binary"` (not neg_risk)
6. Submit less-liquid leg first, then more-liquid leg within 5 seconds. If second leg not filled within 5s, cancel first leg and unwind at market.

`min_category_edge(cat, p_yes, p_no) = 2 × fee_rate[cat] × avg_p × (1−avg_p) + 0.005`
where `avg_p = (p_yes + p_no) / 2`

### Mechanism

Prediction market binary arbitrage exploits guaranteed settlement: exactly one of YES/NO pays $1.00 regardless of outcome. If total cost < $1.00, the profit is locked in at execution. Edge comes from:

1. **Retail misprice lag**: unsophisticated bettors set YES/NO independently without checking completeness
2. **Liquidity fragmentation**: thin books allow temporary price divergence before bots rebalance
3. **Fee asymmetry ignorance**: bettors in zero-fee categories (geopolitics) leave wider, more exploitable gaps

The prim is NOT a skill-based edge (no information advantage). It is pure mechanical arbitrage. Therefore the ONLY risk is execution failure (partial fill, market void, fee miscalculation).

### Conditions
- **Works when:** Category fee below gap minus buffer; fresh gap (<90s); binary market only; both sides liquid enough to fill at quote; no voiding event
- **Fails when:** Gap is stale (>90s — bots already tried and failed, structural issue); partial fill on second leg (creates directional binary bet not arb); market voided after one leg fills (loss > arb gain); fee_rate not correctly determined by category; neg_risk multi-outcome (N-leg atomicity); lockup cost exceeds net gain on long-dated markets with thin gaps; competitor bot already front-ran at better price
- **Best markets:** Geopolitics (0% fee — any positive gap is profitable); political binary markets (4% fee — need 2.5%+ gap)
- **Best timeframe:** Real-time; gap detection to submission < 2 seconds

### Evidence
- **Source:** code extraction + Polymarket fee documentation + derived calculations
- **Certainty:** hypothesis (fee math is verified; gap persistence threshold and partial-fill protocol are untested best-practice derivations)
- **Scope:** Polymarket binary markets only
- **Falsifiability:** testable — run paper-trade arb scanner for 30 days, log gap age at discovery, leg-fill rate, net P&L per category
- **Reaction validated:** no — zero live arb trades in codebase

### Limitations
1. **Partial-fill atomicity** — no atomic execution exists on Polymarket CLOB; second-leg failure rate unknown; 5s timeout is arbitrary
2. **Gap age estimation requires reliable timestamp** — WebSocket message timestamps may lag 50–500ms; "fresh gap" detection has noise floor
3. **Market voiding** — Polymarket has voided markets for controversy/ambiguity; arb holds binary exposure until resolution; void probability unmodelled
4. **Fee formula assumes taker-only** — if arb bot can post maker quotes, fee = 0; current ArbStrategy uses market orders (taker) — opportunity to rework as two-sided aggressive limit orders
5. **Category inference not in code** — ArbStrategy doesn't fetch market category; currently uses flat MIN_ARB_EDGE; must add category API call
6. **Neg_risk exclusion needs code flag** — market.neg_risk field exists in API; currently not filtered
7. **No live data** — zero trades; all estimates derived from fee docs + theory

### Implementation
- **File:** `polymarket-bot/src/strategies/arb.py`
- **Changes needed:**
  1. Add `market.category` field and category → fee_rate lookup dict
  2. Replace flat `MIN_ARB_EDGE = 0.02` with `compute_min_edge(category, yes_price, no_price)`
  3. Add `market.gap_discovered_at` timestamp; reject if `now - gap_discovered_at > 90`
  4. Add `market.neg_risk` filter: skip if `market.neg_risk == True`
  5. Reorder leg submission: determine less-liquid leg by depth, submit first
  6. Add fill confirmation polling: if leg-2 not confirmed filled within 5s, cancel leg-1 and market-sell
  7. Add `lockup_adjusted_net_edge` log field: `gross_gap - fee_cost - days_to_resolution * 0.000137`

### Conditions Log Entry
- Works when: Gap fresh (<90s), binary market, category-cleared fee threshold met, both sides liquid
- Fails when: Stale gap (competitor absorbed or structural trap), partial fill (directional exposure), market voided, neg_risk multi-leg
- Last validated: never (paper-trade scanner needed — 30-day minimum sample)
