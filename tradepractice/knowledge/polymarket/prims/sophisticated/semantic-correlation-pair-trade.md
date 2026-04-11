---
name: semantic-correlation-pair-trade
level: sophisticated
project: polymarket
parent_prim: intermediate/semantic-correlation-pair-trade
created: 2026-04-11
last_validated: never
---

## Prim: semantic-correlation-pair-trade
**Level:** sophisticated (refined from intermediate)
**Project:** polymarket
**Parent:** intermediate/semantic-correlation-pair-trade
**Commit:** [cycle 35]

### Rule
**Granger causality pre-screen** (time-series leader confirmed) + **LLM semantic re-rank** (economic transmission mechanism plausible per event descriptions) + **sentence-transformer embedding ≥ 0.82** + **4-class relationship confirmed** (Class 1 Implication / Class 2 Positive Correlation / Class 3 Temporal Chain / Class 4 Anti-correlation) + **oracle veto clear** (no Type A/B/D from semantic_risk.py) + **NOT exhaustive-sum** (binary-arb-completeness handles those) + **dynamic friction floor** `fee_rate×p(1−p)+0.015+0.03` (geopolitics: 4.5%; politics: 5.5%) + **Bregman/KL-divergence position sizing** (max_profit = KL distance from current prices to no-arbitrage polytope) + both markets liquid ≥ $5k + resolution horizons within 14 days + **asymmetric loss model** by class + **14-day hard stop** OR convergence-to-<1.5% exit + fractional-kelly-sizing sophisticated (correlated N_eff ≈ 1.1–1.5).

### What Changed from Intermediate

| Dimension | Intermediate | Sophisticated |
|---|---|---|
| Lead-market identification | none (static pair detection) | **Granger causality statistical pre-screen** (identifies which market leads) |
| LLM re-ranking | classifier accuracy 60–70% (static) | **LLM semantic stage re-ranks by economic transmission mechanism — doubles PnL at 7-day horizon** (2602.07048, 18 evaluations) |
| Position sizing | Kelly N_eff | **Bregman projection / KL divergence** (max_profit = distance to no-arbitrage polytope; Frank-Wolfe iterative) |
| Loss model | uniform convergence risk | **Asymmetric by class**: Class 3 near-zero downside (deterministic math constraint); Class 1 P(B|~A)×position; Class 2 highest downside (correlation not causation) |
| Signal frequency | implied "20 pairs for calibration" | **7,000+ markets with combinatorial mispricings in 12 months** (2508.03474) — scope 350× larger than intermediate assumed |
| Convergence time | "daily convergence check" | **75% of arb-type orders execute within 1 hour; probabilistic correlation trades: 7-day median hold** (2602.07048) |
| Certainty | hypothesis | **hypothesis (4-source convergent; first real-money extraction evidence)** |
| Anti-prim escapes | none | **3 formal escape hatches** |

### Three Critical Elevations from Intermediate

**1. Real-Money Extraction Evidence (arxiv 2508.03474, IMDEA AFT 2025)**

The intermediate's only quantitative anchor was simulation (arxiv 2512.02436, ~20% weekly return). The first large-scale empirical study:
- **7,000+ Polymarket markets** with measurable combinatorial mispricings identified over 12 months (Apr 2024–Apr 2025)
- **$40M total arbitrage profits** extracted (both intra-market rebalancing + inter-market combinatorial)
- **13 logically dependent pairs** detected in 2024 US election event cluster via semantic analysis
- **75% of arb orders execute within 1 hour** of signal detection
- Framework: integer programming for logical dependency detection, **Bregman divergence (= KL divergence)** for profit calculation, Frank-Wolfe algorithm for portfolio optimization

This converts the "20% simulation return" from an uncalibrated hypothesis to a mechanism confirmed by real extraction at scale.

**2. Granger + LLM Hybrid Doubles PnL (arxiv 2602.07048, Feb 2026)**

Pure static relationship detection (intermediate's approach) exposes the prim to fragile correlations. New hybrid architecture:
- **Stage 1**: Granger causality on implied probability time-series → identifies candidate leader-follower pairs
- **Stage 2**: LLM re-ranks candidates by asking "does a plausible economic transmission mechanism exist?"
- **Result**: Total PnL doubles at 7-day horizon vs Granger alone across 18 rolling evaluations on Kalshi Economics
- **Mechanism**: Improvement is primarily **downside risk reduction**, not WR increase — LLM filters relationships that look statistically correlated but lack causal structure; when those fail, the losses are large
- **Critical implication**: The sophisticated prim's primary target is avoiding correlation breakdowns (Type II errors), not improving win rate on genuine pairs

**3. Bregman/KL Divergence as Position Sizing Principle (Rootdata + 2508.03474)**

The maximum profit any trade can achieve on a correlated pair = **KL divergence between the current joint price distribution and the no-arbitrage polytope**. Frank-Wolfe algorithm approaches this iteratively. This provides:
- A principled maximum position size (sized to KL distance, not edge estimate alone)
- A multi-pair portfolio framework (Frank-Wolfe optimizes across simultaneous opportunities)
- A formalized "distance to profitable" gate: if KL distance < friction floor, skip

### Evidence — 7 Sources

| Source | Finding |
|---|---|
| **arxiv 2508.03474** (IMDEA AFT 2025, peer-reviewed) | 7,000+ combinatorial mispricings; $40M extracted; 13 election logical pairs; 75% orders within 1h; Bregman/KL divergence framework |
| **arxiv 2602.07048** (Feb 2026) | Granger+LLM hybrid doubles PnL at 7-day horizon (18 evaluations); downside reduction is the mechanism, not WR improvement |
| **arxiv 2512.02436** (IBM+Columbia, Dec 2025) | 60–70% relationship detection accuracy; ~20% weekly return simulation; 4-class taxonomy validated |
| **Rootdata "Mathematical Infrastructure" 2026** | Frank-Wolfe + Bregman for multi-pair combinatorial portfolio; KL divergence = correct distance measure |
| **Moontower** (option chain temporal mispricing) | 2–4% persistent mispricing in most liquid prediction markets; negative APY/time-to-resolution relationship (short horizons = higher APY) |
| **binary-arb-completeness sophisticated** (by analogy) | Mechanical arb converges in 2.7s; combinatorial/probabilistic requires 7-day hold — hold horizon is the principal risk differentiator |
| **fractional-kelly-sizing sophisticated** | N_eff = N/(1+(N−1)·ρ̄) for correlated positions; ρ ≈ 0.80 for same-event cluster → N_eff ≈ 1.1 |

### Key Numbers

| Metric | Value |
|---|---|
| Markets with combinatorial mispricings (12mo) | **7,000+** (2508.03474) |
| Real arbitrage profits extracted (Apr2024–Apr2025) | **$40M** (combined intra+inter) |
| Logical pairs in 2024 US election | **13 detected, 5 profitable** |
| Hybrid PnL improvement vs Granger alone | **~2× at 7-day horizon** (2602.07048, 18 evaluations) |
| LLM relationship detection accuracy | **60–70%** (2512.02436) |
| Persistent mispricing in liquid prediction markets | **2–4%** (Moontower) |
| Convergence speed (mechanical arb) | 75% within 1 hour |
| Probabilistic correlation hold horizon | **7-day median** (2602.07048) |
| N_eff for same-event correlated cluster (ρ≈0.80) | ≈ **1.1** |
| Friction floor (geopolitics) | 4.5% at p=0.50 |
| Friction floor (politics/finance) | 5.5% at p=0.50 |
| Class 3 temporal chain downside risk | **≈ 0** (deterministic constraint; P(Tn) ≥ P(T1) by math) |
| Class 2 positive correlation downside risk | **Highest class** (correlation not causation; breakdowns asymmetric) |

### Asymmetric Loss Model by Class

| Class | Mechanism | Downside on Breakdown | Notes |
|---|---|---|---|
| **1 — Implication** | P(B) ≥ P(A)·P(B\|A) | P(B\|~A) × position | Requires P(B\|A) prior; wrong prior → false signal |
| **2 — Positive Correlation** | ΔP(A) without ΔP(B) | **Highest** — correlation may reverse on news | LLM stage most critical here; Granger weakest |
| **3 — Temporal Chain** | P(event by Tn) ≥ P(event by T1) | **Near-zero** — mathematical constraint; cannot invert | First backtest target; no prior needed |
| **4 — Anti-correlation** | P(A) + P(B) + ε < $1 | Moderate — similar to binary-arb near-guarantee | Best when exhaustive candidates detected |

**Class 3 is the highest-confidence subtype**: the constraint P(Tn) ≥ P(T1) (for Tn > T1) is as close to no-arbitrage-guaranteed as prediction market correlated trading gets. If "Fed cuts by Q1 2026" trades at 40% but "Fed cuts by Q2 2026" trades at 35%, the violation is mathematical, not probabilistic. This is the beachhead position from which to build own-data validation.

### 9 Documented Limitations

1. Convergence is probabilistic, not contractual — unlike binary-arb-completeness, no resolution mechanism enforces price equality; divergence can widen or persist for full 14-day window
2. **~20% simulation return is gross** — net after 4.5%+ geopolitics friction floor + slippage on lagging (less liquid) market: estimated net 12–15% per hold; unverified in live trading
3. Granger causality is spurious in short time-series (prediction markets exist only weeks/months) — LLM re-rank is mandatory filter, not optional
4. Class 2 positive correlation: LLM may approve economic mechanism that does not survive a news shock; the "mechanism" is only plausible at time of detection, not guaranteed to persist
5. Position sizing on lagging market is constrained by depth: max_position = min(depth_lagging × 0.80, KL-divergence-sized position); deep imbalances can be > market can absorb
6. Portfolio-level N_eff ≈ 1.1 means two correlated positions are effectively one — Kelly sizing must enforce this or risk overcapitalization
7. 7,000+ combinatorial mispricings includes both large (exploitable) and tiny (sub-floor) gaps; the exploitable universe at ≥ 4.5% is smaller — own-data scanner needed to quantify
8. No own-data live trades; simulation and cross-paper inference is the entire evidence base
9. P(B|A) prior calibration for Class 1 still blocking — 20 resolved implication pairs needed; Class 3 eliminates this requirement entirely (P(Tn) ≥ P(T1) needs no prior)

### Anti-Prim Escape Hatches (3 Formal)

**(A) Net edge compression**: rolling 20-trade mean net edge < 4.5% (geopolitics friction floor) → HFT has absorbed logical arbitrage → structural saturation → mark anti-prim

**(B) Correlation breakdown rate > 25%**: more than 1 in 4 identified relationships inverts or fails to converge before resolution despite LLM semantic filter → classifier structural failure or lead-lag relationship generation changed → rebuild classifier on fresh labeled corpus OR mark anti-prim

**(C) Convergence failure rate > 40%**: more than 2 in 5 divergences never close to < 1.5% within 14-day hold window → probabilistic convergence mechanism absent for target category → mark anti-prim

### Implementation Gaps (8)

1. **`src/strategies/correlated_pair_trade.py`** (new file): market-pair scanner, violation detection, entry/exit logic
2. **`src/classifiers/relationship_type.py`**: `RelationshipClassifier.classify(text_a, text_b) → (class_id, embedding_sim, violation_pp)`; sentence-transformer + oracle veto via semantic_risk.py
3. **`src/classifiers/lead_lag.py`**: Granger causality on p_implied time-series; LLM semantic re-rank via prompt "does market A's resolution causally drive market B's probability?" — **BLOCKING for Class 2**
4. **`src/risk/bregman.py`**: `KLDistanceToNoArb(prices_a, prices_b, constraint_type) → max_profit_pp` using Frank-Wolfe iteration; Class 3 simplification: `max_profit = abs(p_t1 - p_tn)`
5. **Asymmetric stop logic**: Class 1/2: stop if deviation widens > 2× entry gap; Class 3: no-stop (constraint cannot invert); Class 4: stop if ΣP rises above $0.99
6. **N_eff enforcement**: correlated position register; if ρ(pair_a, pair_b) > 0.60 within same event cluster, N_eff adjustment applied across both; prevents double-Kelly
7. **Three anti-prim circuit-breakers**: `EdgeTracker` (anti-prim A), `CorrelationBreakTracker` (anti-prim B), `ConvergenceTracker` (anti-prim C); all persisted to `user_data/`
8. **BLOCKING for deployment**: own-data scanner on Class 3 temporal chain pairs (e.g., Fed rate cut horizons, election-by-date markets); count signals ≥ 4.5% friction floor; if < 10 in 3 months → frequency anti-prim precursor

### Conditions Log Entry
- Works when: Class 3 (deterministic constraint) or Class 1/2 with Granger+LLM confirmed; embedding ≥ 0.82; constraint violation > 4.5%+ friction floor; both ≥ $5k liquid; resolution within 14d of each other; no Type A/B oracle divergence; not exhaustive-sum
- Fails when: Convergence not guaranteed and correlation breaks; asymmetric news catalyst; lagging market too illiquid; resolution horizons diverge > 14 days; Class 2 without Granger+LLM confirmation; prior calibration absent for Class 1; exhaustive-sum pair (binary-arb-completeness is correct prim)
- Last validated: never

### Sources (7)
- [arxiv 2508.03474 — Unravelling the Probabilistic Forest: Arbitrage in Prediction Markets (IMDEA AFT 2025)](https://arxiv.org/abs/2508.03474)
- [arxiv 2602.07048 — LLM as a Risk Manager: LLM Semantic Filtering for Lead-Lag Trading in Prediction Markets (Feb 2026)](https://arxiv.org/abs/2602.07048)
- [arxiv 2512.02436 — Semantic Trading: Agentic AI for Clustering and Relationship Discovery in Prediction Markets (IBM+Columbia, Dec 2025)](https://arxiv.org/abs/2512.02436)
- [Rootdata — Polymarket Arbitrage Bible: The Real Gap is in the Mathematical Infrastructure (2026)](https://www.rootdata.com/news/572346)
- [Moontower — Prediction Market Arbitrage: Using Option Chains to Find Mispriced Bets](https://moontowermeta.com/prediction-market-arbitrage-using-option-chains-to-find-mispriced-bets/)
- [binary-arb-completeness sophisticated (hold horizon analogy)](knowledge/polymarket/prims/sophisticated/binary-arb-completeness.md)
- [fractional-kelly-sizing sophisticated (N_eff formula)](knowledge/polymarket/prims/sophisticated/fractional-kelly-sizing.md)
