---
name: binary-arb-completeness
level: sophisticated
project: polymarket
parent_prim: intermediate/binary-arb-completeness
created: 2026-04-11
last_validated: never
---

## Prim: binary-arb-completeness
**Level:** sophisticated (elevated from intermediate)
**Project:** polymarket
**Parent:** intermediate/binary-arb-completeness

### Rule
**APY-gated edge floor** (`max(2 × fee_rate[category] × p × (1−p) + 0.005, 0.24 × T_days/365)`) + **tiered gap age** (< 30s = tier-1 high confidence; 30–90s = tier-2 depth-verify only; > 90s = reject) + binary-only (neg_risk=False) + **depth-adjusted position ceiling** (min(depth_yes, depth_no) × 0.90) + less-liquid leg first + 5s second-leg timeout + cancel-and-unwind with directional loss accounting + **combinatorial scope** (exhaustive mutually-exclusive multi-outcome sets where ΣP < $0.995) + anti-prim circuit-breaker if rolling 30-day median gap age < 3s.

### What Elevated This from Intermediate

6 sources (up from 2). Elevation adds: **quantified bot competition landscape with gap age distribution, APY-gated lockup model replacing flat daily cost, combinatorial arb signal class, depth-ceiling partial fill model with 78% failure baseline, anti-prim saturation circuit-breaker, and dynamic fee exclusion for crypto category**.

### Four Core Upgrades

| # | Upgrade | Evidence |
|---|---------|---------|
| 1 | **Tiered gap age** — 2.7s median (2026); 73% profits by <100ms bots; tier-1 < 30s, tier-2 30–90s depth-verify, >90s reject | Finance Magnates / ILLUMINATION 2026 bot data |
| 2 | **APY-gated lockup floor** — `0.24 × T_days/365` replaces flat 0.0137%/day estimate; 3% gap on 90d = 12% APY (below threshold) | tokenmetrics.com + tradetheoutcome.com calculation |
| 3 | **Combinatorial arb scope** — multi-market exhaustive sets where ΣP < $0.995; $40M total includes both binary and combinatorial | arxiv 2508.03474 (IMDEA Networks, AFT 2025) |
| 4 | **Depth-ceiling partial fill model** — 78% failure rate in low-liquidity markets; pre-order ceiling = min(depth_yes, depth_no) × 0.90 | navnoorbawa.substack.com execution analysis |

### Gap Age Tiers (Quantified)

| Tier | Age | Interpretation | Action |
|------|-----|----------------|--------|
| 1 | 0–30s | Competition hasn't seen it or chose not to take | Execute immediately |
| 2 | 30–90s | Low-liquidity structure play; bots avoided for a reason | Verify depth ≥ 3× position before proceeding |
| 3 | > 90s | Structural trap, voiding risk, or illiquid bait | Reject |

**Why 30s not 2.7s**: the 2.7s median is the competition threshold for HFT bots; gaps surviving >30s represent a qualitatively different signal class — either structural illiquidity or markets where HFT bots assessed depth as insufficient. The tier-2 window (30–90s) is worth investigating with depth verification, not blindly rejecting.

### APY-Gated Lockup Model

```
required_APY = 0.24  (5% risk-free annualized × 5 opportunity-cost buffer)
lockup_floor = required_APY × T_days / 365

Combined min_edge = max(
    2 × fee_rate[category] × p × (1-p) + 0.005,  # fee floor (from intermediate)
    lockup_floor                                   # NEW: lockup APY gate
)
```

| T_days | Lockup floor | Binding for category |
|--------|-------------|----------------------|
| 7 | 0.46% | Geopolitics only (fee floor 0.5%) — both comparable |
| 14 | 0.92% | Geopolitics (0.5% fee floor) — lockup dominates |
| 30 | 1.97% | Geopolitics + sports — lockup dominates |
| 60 | 3.95% | All categories — lockup dominates fee floor |
| 90 | 5.92% | All categories — very difficult threshold; near anti-prim |

**Practitioner benchmark**: $2.01M top arbitrageur at 4,049 transactions = $496 avg profit/trade. At $5k deployed per leg, breakeven is ~9.9% gap net of fees — implies professional actors target much wider gaps than the minimum floor.

### Combinatorial Arb Extension

Beyond binary YES+NO intra-market arb: identify exhaustive mutually-exclusive outcome sets across multiple markets where `Σ(prices_of_all_outcomes) < $0.995`.

```python
# Example: election has 3 candidate markets
# Candidate A YES: $0.45
# Candidate B YES: $0.30  
# Candidate C YES: $0.18
# Sum = $0.93 → combinatorial gap = $0.07 (before fees)
# Buy all three → guaranteed $1.00 at resolution
```

**Feasibility constraints**:
- N-leg atomicity scales with outcomes: 2-leg binary (existing) → 3-leg combinatorial (adds 1 sequential fill risk) → N-leg (risk grows combinatorially)
- Practical limit: N ≤ 4 legs before execution risk exceeds gap size
- Semantic matching requires LLM/embedding layer to identify related markets
- $40M total ($24M market rebalancing + ~$16M combinatorial) per arxiv 2508.03474

### Partial Fill Loss Model

**Baseline**: 78% of arbitrage opportunities in low-liquidity markets fail due to execution inefficiencies.

```
pre_order_ceiling = min(depth_yes_at_price, depth_no_at_price) × 0.90

Expected partial fill loss:
  P(partial) ≈ 0.78 × (1 - min_liquidity_ratio)   # higher when depths unbalanced
  E(loss | partial) = spread_at_cancellation × position_filled_leg
  E(loss) = P(partial) × E(loss | partial)

Net EV of trade = gross_gap × position - fee_cost - E(loss)
Reject if net EV < 0
```

**Directional unwind protocol** (if leg 2 fails after 5s):
1. Do NOT hold the filled leg — immediately post limit sell at mid-price
2. If not filled within 30s, market-sell to unwind directional exposure
3. Log the realized loss as `partial_fill_cost` against category P&L

### Competition Landscape

| Bot class | Latency | Gap age captured | Addressable for this prim? |
|-----------|---------|-----------------|---------------------------|
| HFT bots | <100ms | 0–2.7s (73% of profits) | No — beyond Python reach |
| Algo bots | 100ms–5s | 2.7s–30s | Marginal — requires asyncio + WebSocket |
| Retail/manual | >10s | 30s–90s (tier-2) | Yes — the viable window |
| Structural traps | >90s | Reject — not real opportunities | N/A |

**Power law**: top 10 arbs capture 21% of total ($8.18M of $40M). Top 1 = $2.01M at 4,049 trades. Entry into consistent profitability requires infrastructure investment, not just signal improvement.

### Failure Modes (6 Quantified)

1. **HFT saturation** — 73% of arb profits captured by <100ms bots; Python WebSocket at 50ms is insufficient for tier-0 gaps. The only real edge window is tier-2 structural illiquidity plays.
2. **APY collapse on long-dated markets** — 3% gap on 90-day market = 12% APY (below 24% required floor); the fee floor overstates viability for long-horizon markets with thin gaps.
3. **Partial fill directional exposure** — 78% failure rate in low-liquidity; depth asymmetry between YES/NO sides (2:1 depth ratio → ~35% partial fill probability on the thin side).
4. **Combinatorial leg failure** — N-leg arb where N≥3 has sequential fill risk; if leg 3 fails after 1 and 2 fill, must unwind 2 positions simultaneously under adverse conditions.
5. **Market voiding post-fill** — Polymarket ~2–5% void rate; if leg 1 fills and market voids, recovery depends on void settlement terms (typically $0.50 on binary — partial recovery).
6. **Dynamic fee changes** — Polymarket introduced dynamic fees for 15-min crypto markets (Feb 2026); fee_rate is not static at category level for short-duration crypto markets.

### Anti-Prim Circuit-Breaker

If rolling 30-day scanner shows:
- Median gap age < 3s (HFT bots absorbing in real-time)
- AND >80% of detected gaps close within 5s

→ binary arb edge is structurally absorbed by HFT competition. Mark anti-prim. Do NOT re-refine — this is a structural market efficiency change.

**Current 2026 status**: gaps compressed from 12.3s median (2024) to 2.7s median — approaching but not yet at anti-prim threshold. Tier-2 (30–90s structural illiquidity) window remains viable.

### Implementation Gaps (9 — none resolved in code)

1. Category fee_rate not fetched dynamically (uses flat MIN_ARB_EDGE)
2. Gap timestamp not tracked (no age tier classification)
3. neg_risk not filtered (multi-outcome markets accepted)
4. Leg ordering not depth-optimized (currently arbitrary)
5. **NEW**: APY-gated lockup floor not computed (`T_days` not fetched from market end_date)
6. **NEW**: Pre-order depth ceiling not enforced (no 0.90× depth check)
7. **NEW**: Partial fill loss accounting not tracked (no net EV computation)
8. **NEW**: Combinatorial arb detector not implemented (binary-only scope)
9. **NEW**: Anti-prim circuit-breaker scanner not running (30-day gap age distribution not logged)

### Evidence

- **Source:** paper + practitioner data
- **Certainty:** hypothesis (no own-data scanner; all quantitative claims from external sources; gap age distribution not validated on own infrastructure)
- **Scope:** binary Polymarket markets; combinatorial extension adds multi-market scope
- **Falsifiability:** testable — deploy 30-day scanner, log gap age distribution, compare to 2.7s benchmark
- **Limitations:** documented (6 failure modes + anti-prim circuit-breaker)

### Key Numbers

| Metric | Value |
|--------|-------|
| Median gap age 2024 | 12.3s |
| Median gap age 2026 | **2.7s** (compression driven by bot competition) |
| % profits by <100ms bots | 73% |
| Total arb extracted Apr 2024–Apr 2025 | $40M (market rebalancing + combinatorial) |
| Top arbitrageur | $2.01M at 4,049 trades ($496/trade avg) |
| Top 10 arbs share of total | 21% ($8.18M of $40M) |
| Partial fill failure rate (low-liquidity) | 78% |
| Required APY threshold | 24% (5% risk-free × 5 opportunity cost multiplier) |
| 3% gap on 7-day market | 156% APY — well above threshold |
| 3% gap on 30-day market | 36% APY — viable |
| 3% gap on 90-day market | 12% APY — below threshold, reject |
| Tier-1 gap window | < 30s |
| Tier-2 gap window | 30–90s (depth-verify) |
| Anti-prim trigger | median gap age < 3s AND >80% close in <5s |

### Sources (6)

- [Unravelling the Probabilistic Forest: Arbitrage in Prediction Markets (arxiv 2508.03474, IMDEA Networks, AFT 2025)](https://arxiv.org/abs/2508.03474) — $40M total, market rebalancing vs combinatorial decomposition, power law top-10 ($8.18M)
- [Beyond Simple Arbitrage: 4 Polymarket Strategies Bots Actually Profit From in 2026 (ILLUMINATION/Finance Magnates)](https://medium.com/illumination/beyond-simple-arbitrage-4-polymarket-strategies-bots-actually-profit-from-in-2026-ddacc92c5b4f) — 2.7s median gap age (down from 12.3s), 73% profits by <100ms bots, 14 of top 20 wallets are bots
- [Building a Prediction Market Arbitrage Bot: Technical Implementation (Navnoor Bawa, Substack)](https://navnoorbawa.substack.com/p/building-a-prediction-market-arbitrage) — partial fill failure rates, execution atomicity analysis, depth-adjusted sizing approach
- [Prediction Market Arbitrage: A Complete Guide (tokenmetrics.com)](https://tokenmetrics.com/blog/prediction-market-arbitrage/) — capital lockup APY model, optimal resolution timeframe analysis (2–8 weeks)
- [Polymarket Arbitrage Strategies 2026 (tradetheoutcome.com)](https://www.tradetheoutcome.com/polymarket-strategy-2026/) — APY calculation anchors (7-day 156%, 90-day 12%), capital lockup constraint framing
- [Polymarket Introduces Dynamic Fees to Curb Latency Arbitrage (Finance Magnates)](https://www.financemagnates.com/cryptocurrency/polymarket-introduces-dynamic-fees-to-curb-latency-arbitrage-in-short-term-crypto-markets/) — dynamic fee changes for crypto 15-min markets (Feb 2026); fee_rate is not static
