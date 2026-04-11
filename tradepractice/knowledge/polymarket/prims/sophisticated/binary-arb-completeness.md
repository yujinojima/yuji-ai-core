---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T14:53:43+10:00
cycle: 22
---

---

## Prim: binary-arb-completeness
**Level:** sophisticated (elevated from intermediate)
**Project:** polymarket
**Parent:** intermediate/binary-arb-completeness

### Rule
APY-gated edge floor (`max(2×fee_rate×p(1−p)+0.005, 0.24×T_days/365)`) + tiered gap age (<30s=tier-1; 30–90s=tier-2 depth-verify; >90s=reject) + binary-only (neg_risk=False) + depth ceiling (min(depth_yes,depth_no)×0.90) + less-liquid leg first + 5s timeout + cancel-and-unwind + combinatorial scope (multi-market exhaustive sets ΣP<$0.995, N≤4 legs).

### Mechanism
Information asymmetry between structured arb bots and casual market participants. The YES+NO<$1 invariant is contract-enforced; deviation creates guaranteed profit at resolution. Edge compresses with competition — 2026 viable window is tier-2 structural illiquidity plays (30–90s gap age) where HFT bots assessed depth as insufficient.

### Four Core Upgrades

| # | Upgrade | Evidence |
|---|---------|---------|
| 1 | **Tiered gap age** — median 2.7s (2026, down from 12.3s 2024); 73% of profits by <100ms bots | Finance Magnates / ILLUMINATION 2026 |
| 2 | **APY-gated lockup floor** — replaces flat 0.0137%/day estimate; 3% gap on 90-day = 12% APY (below 24% threshold) | tokenmetrics.com, tradetheoutcome.com |
| 3 | **Combinatorial arb scope** — multi-market exhaustive sets; $40M includes both binary and combinatorial | arxiv 2508.03474 (IMDEA, AFT 2025) |
| 4 | **Partial fill loss model** — 78% failure rate in low-liquidity; depth ceiling = min(depth_yes,depth_no)×0.90 | navnoorbawa.substack.com |

### Key Numbers

| Metric | Value |
|--------|-------|
| Median gap age 2024 | 12.3s |
| Median gap age 2026 | **2.7s** |
| Profits by <100ms bots | 73% |
| Total arb extracted (Apr 2024–Apr 2025) | $40M |
| Top arbitrageur | $2.01M at $496/trade avg |
| Partial fill failure rate (low-liquidity) | 78% |
| Required APY threshold | 24% |
| 3% gap / 7-day market | 156% APY — viable |
| 3% gap / 90-day market | 12% APY — **reject** |
| Anti-prim trigger | Median gap age < 3s AND >80% close in <5s |

### Anti-Prim Escape Hatch
Rolling 30-day scanner: if median gap age < 3s AND >80% close in <5s → HFT saturation → mark anti-prim, do not re-refine.

### Prim Status

| Prim | Level |
|------|-------|
| binary-arb-completeness | **sophisticated** ← this cycle |
| spread-capture-market-making | sophisticated |
| fractional-kelly-sizing | sophisticated |
| ensemble-forecast-edge | sophisticated |

**All 4 polymarket prims now at sophisticated tier. Zero remaining naive or intermediate prims.**

Commit: `617f940`

### Next Cycle Recommendations
1. **(A) New naive prim: OBI-informed directional** — OBI IR > 0.65 predicts direction at 58% accuracy (from spread-capture-market-making sophisticated research, arxiv 2603.03152 Bawa); a qualitatively distinct signal class from all 4 existing prims; no implementation yet
2. **(B) Cross-venue arb prim** — Polymarket vs Kalshi on same events; Kalshi held 62% of prediction market volume Sep 2025; structural price divergences create a new arb class not modeled in binary-arb-completeness (different settlement, USDC↔USD bridge, different fee structures)
3. **(C) BACKTEST-ANALYSIS mode** — deploy 30-day gap age scanner on arb.py to validate tier-2 gap age distribution and determine if the anti-prim threshold (3s median) has been breached in 2026

Sources:
- [Unravelling the Probabilistic Forest: Arbitrage in Prediction Markets (arxiv 2508.03474)](https://arxiv.org/abs/2508.03474)
- [Beyond Simple Arbitrage: 4 Polymarket Strategies Bots Actually Profit From in 2026 (ILLUMINATION)](https://medium.com/illumination/beyond-simple-arbitrage-4-polymarket-strategies-bots-actually-profit-from-in-2026-ddacc92c5b4f)
- [Building a Prediction Market Arbitrage Bot: Technical Implementation (Navnoor Bawa)](https://navnoorbawa.substack.com/p/building-a-prediction-market-arbitrage)
- [Prediction Market Arbitrage: A Complete Guide (tokenmetrics.com)](https://tokenmetrics.com/blog/prediction-market-arbitrage/)
- [Polymarket Arbitrage Strategies 2026 (tradetheoutcome.com)](https://www.tradetheoutcome.com/polymarket-strategy-2026/)
- [Polymarket Introduces Dynamic Fees to Curb Latency Arbitrage (Finance Magnates)](https://www.financemagnates.com/cryptocurrency/polymarket-introduces-dynamic-fees-to-curb-latency-arbitrage-in-short-term-crypto-markets/)
