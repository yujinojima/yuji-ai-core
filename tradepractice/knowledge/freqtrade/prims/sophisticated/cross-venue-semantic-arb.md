---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T18:02:50+10:00
cycle: 33
---

Commit `c566f13`.

---

## Prim: cross-venue-semantic-arb
**Level:** sophisticated (refined from intermediate)
**Project:** polymarket
**Parent:** intermediate/cross-venue-semantic-arb

### Rule
**5-type LLM semantic classifier** (sentence-transformer embedding ≥ 0.92 + Type A/B/C/D/E keyword veto) + **dynamic friction floor** `(0.07 + PM_fee_rate) × p × (1−p) + 0.0215` + Class 1 buffer +2.5% (+3.5% for Type D scope markers) + **staged bilateral fill** (<5s timeout) + **Kalshi Rule 6.3(c) loss model** (last-price settlement, not binary −$1) → execute geopolitics × Kalshi Political only.

### Three Critical Elevations from Intermediate

**1. Cardi B Super Bowl (Feb 2026) + Type E Classifier**

Third documented divergence case — $47.3M Kalshi + $10M Polymarket volume on a single event. Kalshi invoked **Rule 6.3(c)**: outcome deemed ambiguous under CFTC guidelines → settled at last price (YES=$0.26, NO=$0.74). Polymarket resolved YES at $1. Type D scope qualifier: "perform" vs "appear/cameo."

New **Type E** extracted from mention market analysis (Kalshi NFL resolution methodology): Kalshi restricts to "designated play-by-play/color commentators"; Polymarket resolves for any broadcast audio. Keywords: "designated [role]", "official commentary" vs "any mention", "any broadcast participant."

**5-type classifier taxonomy (3 cases empirically anchored):**

| Type | Pattern | Case |
|---|---|---|
| **A** — Quantitative threshold | "at least N", "equivalent to [standard]", "minimum" | Bitcoin Reserve (SPR-equivalent) |
| **B** — Time window | "consecutive", "continuous", "exceeding N hours" | Government shutdown (>24h) |
| **C** — Documentation standard | "White House official", "NYT", "credible reporting" | Government shutdown (WH vs credible) |
| **D** — Scope qualifier | "perform", "full", "partial", "temporary" | Cardi B (perform vs appear) |
| **E** — Information source scope | "designated commentator", "any broadcast participant", "field audio" | NFL mention markets |

**2. Rule 6.3(c) Loss Model — Resolution Asymmetry Characterized**

Divergence is NOT always binary total loss (−$1). Kalshi's CFTC-regulatory Rule 6.3(c) introduces a third outcome:

| Scenario | Kalshi | Polymarket | Arb impact |
|---|---|---|---|
| Both binary same direction | $1 / $0 | $1 / $0 | Net flat (fees lost) |
| Divergent binary | $0 (NO) | $1 (YES) | −$1 on wrong leg |
| **Rule 6.3(c)** | $0.26 YES / $0.74 NO (last price) | $1 YES | Capital returned, gain eliminated |

Rule 6.3(c) = partial capital return (not total loss), but eliminates the expected arb gain AND reveals the semantic risk was real. Gate addition: Class 1 Type D markers → +3.5% buffer total (2.5% Class 1 + 1.0% Rule 6.3(c) cushion).

**3. LLM Semantic Scorer (arxiv 2512.02436)**

IBM + Columbia (Dec 2025): agentic AI for prediction market semantic clustering achieves **60–70% accuracy**; induces trading strategies with ~20% average weekly returns. Validates embedding-over-keyword for borderline resolution text similarity. Hybrid (embedding + Type A/B/C/D/E veto) should exceed 70% accuracy ceiling and eliminate known error classes. **BLOCKING**: labeled corpus ≥ 50 co-listed events with known resolution outcomes required before deployment.

### Key Numbers

| Metric | Value |
|---|---|
| Co-listed pairs/year (2025+) | 1,200–1,500 |
| Class 2 skip rate | 25–35% |
| Average gap 2025 | 1.2% (below 3.90% floor — most events unviable) |
| Viable events/year post-filter | **3–8** |
| Gap persistence | **2–7 seconds** |
| LLM classifier accuracy | **60–70%** (arxiv 2512.02436) |
| Cardi B combined volume | $57.3M ($47.3M Kalshi + $10M PM) |
| Rule 6.3(c) settlement | YES=$0.26, NO=$0.74 (not binary) |
| Known divergence cases | **3** (shutdown, Bitcoin Reserve, Cardi B) |
| Empirical divergence rate | < 0.2% of co-listed events |
| Gap compression rate | ~1.7pp/year (4.5% avg 2023 → 1.2% 2025) |

### Anti-Prim Escape Hatches (3 Formal)
- **(A) Gap compression**: rolling 30-day median viable gap < 2.5% → structural saturation → mark anti-prim
- **(B) Rule 6.3(c) rate > 15%**: Kalshi CFTC regulatory ambiguity structurally disrupts binary settlement assumption → mark anti-prim
- **(C) Filter failure**: 2+ semantic divergence losses in 12 months despite Class 2 filter → unclassified Type F → retire and rebuild classifier on labeled corpus

### Bank State After Cycle 33

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | 0 |
| Intermediate | 0 | 0 |
| Sophisticated | 7 | **6** (binary-arb, spread-capture, ensemble-forecast, fractional-kelly, obi-informed, **cross-venue-semantic-arb NEW**) |

**All prims across both projects at sophisticated tier.**

### Files Updated
- `knowledge/polymarket/prims/sophisticated/cross-venue-semantic-arb.md` (created, 9-source, 200 lines)
- `knowledge/epistemic-index.md` (intermediate SUPERSEDED; sophisticated polymarket table +1 row → 6 sophisticated)
- `knowledge/conditions-log.md` (intermediate marked [historical], sophisticated entry appended)
- Commit: `c566f13`

### Next Cycle Recommendation
**(A) BACKTEST-ANALYSIS** — shared blocker across all 7 freqtrade sophisticated prims; divergence head-to-head (bullish-rsi-divergence vs hidden-bullish-rsi-divergence) remains highest-value test; any of 4 outcomes load-bearing.
**(B) IMPLEMENT** — funding-rate-crowding-reversal threshold recalibration: escape hatch (A) triggered in cycle 32 (0.10%/8h never fires in 2022-2026); recalibrate to ~0.05-0.07% threshold which fired 26-91 times over same period. Cheapest test in the bank (conditional WR analysis on sister prim backtests + historical funding data).
**(C) IMPLEMENT** — cross-venue-semantic-arb labeled corpus: build minimum 50-event labeled dataset of co-listed Polymarket × Kalshi events with known resolution outcomes; calibrate LLM embedding thresholds for Class 0/1/2; this unblocks the only deployment-ready sophisticated polymarket prim with no current code implementation.

Recommend **(B)** — threshold recalibration converts a suspended sophisticated prim back to active status with minimal research effort; the data (historical funding rates) already exists.

### Sources (9)
- [arxiv 2601.01706 — Semantic Non-Fungibility in Prediction Markets (Gebele & Matthes, Jan 2026)](https://arxiv.org/abs/2601.01706)
- [arxiv 2512.02436 — Semantic Trading: Agentic AI for Clustering and Relationship Discovery (IBM+Columbia, Dec 2025)](https://arxiv.org/abs/2512.02436)
- [Fortune — Cardi B Super Bowl prediction market divergence (Feb 2026)](https://fortune.com/2026/02/11/did-cardi-b-perform-at-super-bowl-prop-bet-kalshi-polymarket/)
- [CBS News — Cardi B prediction market dispute (Feb 2026)](https://www.cbsnews.com/news/cardi-b-super-bowl-prediction-market-dispute/)
- [DeFiRate — How Kalshi and Polymarket Settle Event Contracts (Rule 6.3(c))](https://defirate.com/prediction-markets/how-contracts-settle/)
- [AhaSignals — Cross-Platform Prediction Market Arbitrage Strategies](https://ahasignals.com/research/prediction-market-arbitrage-strategies/)
- [Monad Blog — Prediction Markets Cannot Agree on the Truth](https://blog.monad.xyz/blog/prediction-market-arbitrage)
- [newyorkcityservers.com — Prediction Market Arbitrage Guide 2026](https://newyorkcityservers.com/blog/prediction-market-arbitrage-guide)
- [laikalabs.ai — Polymarket & Kalshi Arbitrage Opportunities 2026 (LA Mayoral 7.53% case)](https://laikalabs.ai/prediction-markets/polymarket-kalshi-arbitrage-guide)
