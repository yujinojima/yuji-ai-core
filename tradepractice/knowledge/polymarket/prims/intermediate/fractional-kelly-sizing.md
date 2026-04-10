---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T15:32:21+10:00
cycle: 10
---

## Prim: fractional-kelly-sizing
**Level:** intermediate (elevated from naive)
**Project:** polymarket

### What changed

The naive prim had KELLY_FRACTION=0.15 (arbitrary, undocumented). Research found this is 40% below even the conservative academic floor.

**Three core upgrades:**

| # | Upgrade | Evidence |
|---|---------|---------|
| 1 | **Fraction tiers**: 0.50 (calibrated, Brier ≤ 0.30) or 0.25 (uncalibrated/LLM) | arxiv 2412.14144, PolySwarm (arxiv 2604.03888), MacLean et al. |
| 2 | **Concurrent-bet scalar**: multiply by `1/sqrt(N)` when N positions open | Portfolio Kelly theory |
| 3 | **20% drawdown circuit-breaker**: halve sizes until 10% recovery | mbotopoly.com prediction market risk guide |

**Plus:** fee-adjusted odds formula (taker fee factored before Kelly), replace $100 hard cap with 5% bankroll cap (current cap makes Kelly irrelevant at bankrolls > $13k).

### Key quantitative anchors

- **arxiv 2412.14144 (Meister Dec 2024)**: prices bounded [0,1] → KL-divergence framework; miscalibration near p=0/1 disproportionately destroys portfolio growth
- **PolySwarm (arxiv 2604.03888)**: 50-agent LLM ensemble uses quarter-Kelly — validates 0.25 for uncalibrated multi-model edges
- **MacLean-Hakansson**: Full Kelly → 33% probability of halving before doubling
- **10% edge overestimate → ~2x bet size**: estimation error amplification is the primary ruin mechanism

### Implementation path
New shared module: `polymarket-bot/src/risk/kelly.py`. All strategies import from there. GFS ensemble Brier score computation needed before 0.50 tier can activate.

### Polymarket prim status

| Prim | Level |
|------|-------|
| binary-arb-completeness | naive |
| spread-capture-market-making | **intermediate** |
| ensemble-forecast-edge | naive |
| fractional-kelly-sizing | **intermediate** ← this cycle |

Sources:
- [Application of the Kelly Criterion to Prediction Markets (arxiv 2412.14144)](https://arxiv.org/abs/2412.14144)
- [PolySwarm Multi-Agent Framework (arxiv 2604.03888)](https://arxiv.org/html/2604.03888)
- [Good and Bad Properties of the Kelly Criterion — MacLean et al.](https://www.stat.berkeley.edu/~aldous/157/Papers/Good_Bad_Kelly.pdf)
- [Risk Management for Prediction Markets — mbotopoly.com](https://mbotopoly.com/blog/risk-management-prediction-markets)
