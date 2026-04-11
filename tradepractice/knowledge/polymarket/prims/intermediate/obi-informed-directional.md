---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T15:28:56+10:00
cycle: 26
---

Commit `d996a6c`.

---

## Prim: obi-informed-directional
**Level:** intermediate (elevated from naive)
**Project:** polymarket
**Parent:** naive/obi-informed-directional

### What changed

The naive prim had three structural weaknesses: IR computed on wash-inflated raw depth; single IR=0.65 threshold applied regardless of liquidity; flat 30-min hold horizon regardless of category.

**Three core upgrades:**

| # | Upgrade | Evidence |
|---|---------|---------|
| 1 | **Wash-adjusted IR** — `V_bid_5s / V_ask_5s` (orders resting ≥ 5s only); wash traders add/cancel in ms; aged-order filter isolates genuine intent | Columbia SSRN 5714122 (Sirolly et al., Nov 2025): sports 45% wash, elections ~17%, avg 25%; arxiv 2507.22712: parent-order lifetime filtration → "systematically stronger directional association" |
| 2 | **Liquidity-tiered threshold** — thin ($2k–$5k): IR_clean > 0.80; mid ($5k–$50k): IR_clean > 0.65; skip <$2k (book too thin) and >$50k (bots <200ms response, no window) | Bawa: R²=0.65 validated in mid-liquidity range; QuantStrategy.io: thin/high-volatility instruments require 80–90% threshold |
| 3 | **Category-specific hold horizons + exclusions** — sports EXCLUDED (45% wash + live-score adverse selection <5min); crypto EXCLUDED (7.2% fee); politics/finance 15–30min; geopolitics 30–60min | arxiv 2603.03152 (Tsang & Yang): VR(6)=1.84 at political shock — persistent directional drift; spread-capture sophisticated adverse selection windows (same dataset) |

### Key quantitative anchors

| Metric | Value | Source |
|--------|-------|--------|
| 58% directional WR at IR>0.65 | mid-liquidity prediction markets | Bawa / arxiv 2603.03152 (single source — hypothesis) |
| OBI R² = 0.65 | short-interval variance | arxiv 2603.03152 |
| Sports wash rate | 45% of volume | Columbia SSRN 5714122 |
| Elections/politics wash | ~17% | Columbia SSRN 5714122 |
| VR(6) at political shock | 1.84 (persistent drift) | arxiv 2603.03152 |
| Breakeven WR geopolitics (0% fee) | 50.0% | fee math |
| Breakeven WR politics (4% fee) | 52.0% | fee math |
| EV at 58% WR, 4% fee, 1:1 R:R | +0.12/unit | derived |

### 6 implementation gaps (intermediate)

1. `DepthSnapshot.v_bid_aged / v_ask_aged` — requires CLOB WebSocket order-age tracking (not in Gamma API). Code falls back to raw with 25% wash haircut until integrated.
2. `_ir_threshold()` — tiered selector ✅ implemented
3. `Market.category` — field absent from dataclass; must be fetched from Gamma API metadata
4. Category exclusion gate ✅ implemented (sports/crypto)
5. Category-specific hold horizon ✅ attached to signal reason
6. CLOB WebSocket order-age feed — prerequisite for items 1 and 3

### Prim status

| Prim | Level |
|------|-------|
| binary-arb-completeness | sophisticated |
| spread-capture-market-making | sophisticated |
| fractional-kelly-sizing | sophisticated |
| ensemble-forecast-edge | sophisticated |
| capitulation-exhaustion-reversal | intermediate (freqtrade) |
| **obi-informed-directional** | **intermediate ← this cycle** |

### Sources (4)
- [arxiv 2603.03152 — Political Shocks and Price Discovery in Prediction Markets](https://arxiv.org/abs/2603.03152)
- [Columbia SSRN 5714122 — Network-Based Detection of Wash Trading](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5714122)
- [arxiv 2507.22712 — Order Book Filtration and Directional Signal Extraction at High Frequency](https://arxiv.org/abs/2507.22712)
- [Navnoor Bawa — The Mathematical Execution Behind Prediction Market Alpha](https://navnoorbawa.substack.com/p/the-mathematical-execution-behind)
