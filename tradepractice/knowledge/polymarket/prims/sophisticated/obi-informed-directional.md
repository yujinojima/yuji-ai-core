---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T15:52:20+10:00
cycle: 28
---

Commit `5e7dc4f`.

---

## Prim: obi-informed-directional
**Level:** sophisticated (elevated from intermediate)
**Project:** polymarket
**Parent:** intermediate/obi-informed-directional

### Four Core Upgrades

| # | Upgrade | Source |
|---|---------|--------|
| 1 | **Parent-order lifetime filter** — track parent order IDs, modification count ≤ 2, modification timing ≥ 500ms; "parent-order filtration = systematically stronger directional association" vs "aggregate filtration = modest improvement" | arxiv 2507.22712 |
| 2 | **Latency-rank reframe: persistent-OBI targeting** — OBI profit determined by LATENCY RANK, not absolute latency (arxiv 2006.08682). Python async at 10s = lowest rank; first-mover OBI consumed by <30ms co-located bots. Strategy: target PERSISTENT OBI (3–5 consecutive snapshots = 30–50s sustained). Justified by VR(6)=1.84 persistent drift lasting minutes at political shocks | arxiv 2006.08682, arxiv 2603.03152 |
| 3 | **Kyle λ maturation gate** — at λ > 0.05 (thin, immature): single large order creates misleading IR; require 5 consecutive snapshots. At λ < 0.05 (mature): 3 snapshots sufficient | arxiv 2603.03136 |
| 4 | **Paradigm double-count correction → IR threshold uplift** — Paradigm Dec 2025: Polymarket volume systematically double-counted; wash % understated. Conservative floor: 25% across categories (was 17% geopolitics). Consequence: IR_clean threshold raised 0.65 → 0.70 for mid-liquidity | Paradigm Dec 2025, Columbia SSRN 5714122 |

### Key Numbers

| Metric | Value |
|--------|-------|
| 58% directional WR at IR > 0.65 | Bawa — single source, hypothesis |
| OFI signal half-life (equity) | 5–30 seconds |
| Prediction market drift (VR=1.84) | minutes (our window) |
| Co-located bot latency | 1–30ms |
| Our 10s snapshot latency rank | ~200× slower than WS; lowest rank |
| Sports wash rate | 45% avg, 90% peak |
| Conservative wash floor (post-Paradigm) | 25% all categories |
| IR_clean threshold (mid-liquidity) | > 0.70 (raised from 0.65) |
| Breakeven WR / 0% fee | 50.0% |
| EV at 58% WR / 4% fee | +0.12/unit |

### Anti-Prim Escape Hatches
- **(A)** Own-data WR < 52% / 30 geopolitics trades → latency saturation anti-prim
- **(B)** Geopolitics wash ≥ 40% → category contamination anti-prim  
- **(C)** Polymarket extends taker delay removal to geopolitics/politics → terminal latency rank

### Prim Status — All 5 Polymarket Prims

| Prim | Level |
|------|-------|
| binary-arb-completeness | sophisticated |
| spread-capture-market-making | sophisticated |
| fractional-kelly-sizing | sophisticated |
| ensemble-forecast-edge | sophisticated |
| **obi-informed-directional** | **sophisticated ← this cycle** |

**All 5 polymarket prims now at sophisticated tier.**

### Files Updated
- `knowledge/polymarket/prims/sophisticated/obi-informed-directional.md` — created
- `knowledge/epistemic-index.md` — intermediate SUPERSEDED, sophisticated row added
- `knowledge/conditions-log.md` — intermediate marked historical, sophisticated entry added

Sources:
- [arxiv 2507.22712 — Order-Flow Filtration and Directional Signal Extraction](https://arxiv.org/abs/2507.22712)
- [arxiv 2006.08682 — The Importance of Low Latency to OBI Trading Strategies](https://arxiv.org/abs/2006.08682)
- [arxiv 2603.03152 — Political Shocks and Price Discovery in Prediction Markets](https://arxiv.org/abs/2603.03152)
- [Columbia SSRN 5714122 — Network-Based Detection of Wash Trading](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5714122)
- [Paradigm — Polymarket Volume Is Being Double-Counted](https://www.paradigm.xyz/2025/12/polymarket-volume-is-being-double-counted)
- [arxiv 2603.03136 — The Anatomy of Polymarket](https://arxiv.org/abs/2603.03136)
- [Navnoor Bawa — Mathematical Execution Behind Prediction Market Alpha](https://navnoorbawa.substack.com/p/the-mathematical-execution-behind)
- [QuantVPS — How Latency Impacts Polymarket Bot Performance](https://www.quantvps.com/blog/how-latency-impacts-polymarket-trading-performance)
