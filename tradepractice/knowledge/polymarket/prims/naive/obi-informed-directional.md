---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T15:06:16+10:00
cycle: 24
---

---

## Prim: obi-informed-directional
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule
`IR = (V_bid − V_ask) / (V_bid + V_ask) > +0.65` → BUY YES. `IR < −0.65` → BUY NO. Hold until `|IR| < 0.30` or 30-minute max. Size via `fractional-kelly-sizing` sophisticated prim.

### Mechanism
Informed traders accumulate on one side of the CLOB before a price move, leaking directional intent via measurable depth imbalance. The 5th prim covers a signal class absent from all 4 existing prims: pure CLOB microstructure. The structural relationship with `spread-capture-market-making` sophisticated is exact — MM prim has gate `|IR| < 0.65`; when IR breaches that threshold, MM exits and OBI directional activates. Two prims, one state machine, same data feed.

### Evidence
- **Source:** Navnoor Bawa (arxiv 2603.03152) — single academic source
- **Certainty:** hypothesis — 58% directional accuracy at IR > 0.65; OBI R² = 0.65 for short-interval variance prediction
- **Data:** 0 own trades
- **Critical risk:** wash trading (20–60% of Polymarket volume per Columbia Nov 2025) contaminates IR — wash-adjusted depth computation is prerequisite before this signal is reliable

### Limitations (8)
1. Single source — 58% accuracy unreplicated
2. Wash-trading contamination — #1 risk; IR meaningless on wash-dominated depth
3. Hold horizon heuristic (30 min) — not derived
4. Signal decay rate unknown vs <200ms professional MM bots
5. No fee model — 5% weather fee leaves only 5.5pp buffer at 58% WR
6. Single threshold — IR = 0.65 not calibrated across liquidity tiers
7. No implementation in polymarket-bot
8. No persistence threshold — 3-snapshot filter is heuristic

### Files
- `knowledge/polymarket/prims/naive/obi-informed-directional.md` — created
- `knowledge/epistemic-index.md` — 5th naive row added; spread-capture naive SUPERSEDED marker fixed
- `knowledge/conditions-log.md` — OBI conditions appended
- Commit: `6e1744c`

### Prim status

| Prim | Level |
|------|-------|
| binary-arb-completeness | sophisticated |
| spread-capture-market-making | sophisticated |
| fractional-kelly-sizing | sophisticated |
| ensemble-forecast-edge | sophisticated |
| **obi-informed-directional** | **naive ← this cycle** |

### Next cycle recommendations
1. **(A) RESEARCH: Elevate obi-informed-directional to intermediate** — find wash-adjusted OBI methodology, replicate 58% directional accuracy claim independently, determine optimal threshold calibration by liquidity tier and optimal hold horizon
2. **(B) New naive prim: cross-venue arbitrage (Polymarket vs Kalshi)** — Kalshi held 62% of prediction market volume Sep 2025; same-event price divergences create an arb class structurally distinct from binary-arb-completeness (different settlement, USDC↔USD, different fee structures)
3. **(C) BACKTEST-ANALYSIS: deploy 30-day gap scanner on arb.py** — validate binary-arb-completeness tier-2 gap age distribution; determine if anti-prim threshold (3s median) has been breached in 2026
