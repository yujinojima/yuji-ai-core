---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T18:27:13+10:00
cycle: 35
---

Commit `702c515`.

---

## Prim: semantic-correlation-pair-trade
**Level:** sophisticated (refined from intermediate)
**Project:** polymarket
**Parent:** intermediate/semantic-correlation-pair-trade

### Rule
**Granger causality pre-screen** + **LLM semantic re-rank** (economic transmission mechanism plausible; doubles PnL at 7-day horizon vs Granger alone — arxiv 2602.07048, 18 evaluations) + embedding ≥ 0.82 + **4-class taxonomy** + oracle veto (Type A/B/D) + NOT exhaustive-sum + friction floor 4.5%+ + **Bregman/KL-divergence position sizing** (max_profit = KL distance to no-arbitrage polytope; Frank-Wolfe multi-pair) + **asymmetric stop by class** + 14-day hard stop OR convergence-to-<1.5% exit + Kelly N_eff ≈ 1.1.

### Three Critical Elevations from Intermediate

**1. Real-Money Extraction Evidence (arxiv 2508.03474, IMDEA AFT 2025)**

The intermediate's only anchor was simulation. First large-scale empirical study:
- **7,000+ Polymarket markets** with combinatorial mispricings over 12 months
- **$40M total profits** extracted (intra + inter-market combinatorial)
- **13 logically dependent pairs** in 2024 US election; 5 profitable
- **75% of orders execute within 1 hour** — but this is for mechanical arb; probabilistic correlation holds are 7-day median
- Mathematical framework: Bregman divergence = KL divergence; Frank-Wolfe iterates to max profit

**2. Granger + LLM Hybrid Doubles PnL (arxiv 2602.07048, Feb 2026)**

Pure static classification (intermediate) exposes Class 2 to fragile correlations. Hybrid architecture:
- Stage 1: Granger causality on implied probability time-series → identifies lead-follow direction
- Stage 2: LLM re-ranks by economic transmission plausibility
- Result: **Total PnL doubles at 7-day horizon** across 18 rolling evaluations on Kalshi Economics
- Mechanism: **Downside risk reduction**, not WR increase — LLM filters relationships that statistically correlate but causally don't; their breakdowns are catastrophic losses

**3. Asymmetric Loss Model by Class**

| Class | Mechanism | Downside |
|---|---|---|
| **3 — Temporal Chain** | P(event by Tn) ≥ P(event by T1) | **≈ 0** — mathematical constraint, cannot invert |
| **1 — Implication** | P(B) ≥ P(A)·P(B\|A) | P(B\|~A) × position; prior needed |
| **4 — Anti-correlation** | ΣP(A)+P(B) < $1 | Moderate |
| **2 — Positive Correlation** | ΔP(A) without ΔP(B) | **Highest** — correlation ≠ causation; breakdowns asymmetric |

**Class 3 Temporal Chain is the beachhead**: deterministic constraint, no prior calibration, near-zero downside, first own-data target.

### Key Numbers

| Metric | Value |
|---|---|
| Markets with combinatorial mispricings (12mo) | **7,000+** |
| Profits extracted Apr2024–Apr2025 | **$40M** |
| Logical pairs in 2024 election | **13 detected, 5 profitable** |
| Hybrid PnL vs Granger alone (7-day) | **~2×** (downside reduction mechanism) |
| LLM detection accuracy | **60–70%** |
| Persistent mispricing in liquid markets | **2–4%** |
| Mechanical arb execution | 75% within 1 hour |
| Probabilistic hold horizon | **7-day median** |
| N_eff for same-event cluster (ρ≈0.80) | **≈ 1.1** |

### Anti-Prim Escape Hatches (3 Formal)
- **(A) Net edge < 4.5%** rolling 20-trade → HFT absorbed logical arbitrage → anti-prim
- **(B) Breakdown rate > 25%** → LLM classifier structural failure → rebuild or anti-prim
- **(C) Convergence failure > 40%** within 14-day windows → mechanism absent → anti-prim

### Bank State After Cycle 35

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | 0 |
| Intermediate | 0 | **0** |
| Sophisticated | 7 | **7** |

**All 14 prims across both projects at sophisticated tier.**

### Files Updated
- `knowledge/polymarket/prims/sophisticated/semantic-correlation-pair-trade.md` (created, 7-source)
- `knowledge/epistemic-index.md` (intermediate SUPERSEDED; sophisticated polymarket table +1 row → 7 sophisticated)
- `knowledge/conditions-log.md` (intermediate marked [historical]; sophisticated entry appended)
- Commit: `702c515`

### Next Cycle Recommendation
**(A) IMPLEMENT** — Class 3 Temporal Chain scanner on Polymarket: scan for "event by date-A" / "event by date-B" pairs where P(A) < P(B) (violation of deterministic constraint); count violations ≥ 4.5% over 60 days; if < 5 violations, frequency anti-prim precursor. This is the cheapest validation in the bank — no Granger, no prior, just math.
**(B) BACKTEST-ANALYSIS** — shared blocker across all 7 freqtrade prims; divergence head-to-head (bullish-rsi-divergence vs hidden-bullish-rsi-divergence) remains highest-value single test.
**(C) IMPLEMENT** — funding-rate-crowding-reversal escape hatch (B): conditional sister-prim WR test with recalibrated 0.06% threshold; cheapest test in freqtrade bank.

Recommend **(A)** — brings the first own-data validation to the bank's newest sophisticated prim; deterministic Class 3 means any violation found is a live tradeable signal with near-zero downside.

### Sources
- [arxiv 2508.03474 — Unravelling the Probabilistic Forest: Arbitrage in Prediction Markets (IMDEA AFT 2025)](https://arxiv.org/abs/2508.03474)
- [arxiv 2602.07048 — LLM as a Risk Manager: LLM Semantic Filtering for Lead-Lag Trading in Prediction Markets (Feb 2026)](https://arxiv.org/abs/2602.07048)
- [arxiv 2512.02436 — Semantic Trading: Agentic AI for Clustering and Relationship Discovery (IBM+Columbia, Dec 2025)](https://arxiv.org/abs/2512.02436)
- [Rootdata — Polymarket Arbitrage Bible: The Real Gap is in the Mathematical Infrastructure (2026)](https://www.rootdata.com/news/572346)
- [Moontower — Prediction Market Arbitrage: Using Option Chains to Find Mispriced Bets](https://moontowermeta.com/prediction-market-arbitrage-using-option-chains-to-find-mispriced-bets/)
- [arxiv 2508.03474 full text — $40M, 7,000+ markets, Bregman projection](https://arxiv.org/html/2508.03474v1)
- [ILLUMINATION — Beyond Simple Arbitrage: 4 Polymarket Strategies Bots Actually Profit From in 2026](https://medium.com/illumination/beyond-simple-arbitrage-4-polymarket-strategies-bots-actually-profit-from-in-2026-ddacc92c5b4f)
