---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T07:03:46+10:00
cycle: 15
---

---

## Prim: binary-arb-completeness
**Level:** intermediate (elevated from naive)
**Project:** polymarket

### What changed

The naive prim had a flat MIN_ARB_EDGE=$0.02 with no model of the four structural failure modes.

**Four core upgrades:**

| # | Upgrade | Evidence |
|---|---------|---------|
| 1 | **Category-aware fee floor**: `min_edge = 2 × fee_rate × p × (1−p) + 0.005` | Polymarket fee formula: `C·feeRate·p·(1-p)` (docs.polymarket.com) |
| 2 | **Gap persistence filter (<90s)**: reject gaps older than 90s — real arb absorbed in 2–30s by bots | Professional MM <10ms latency vs WS 50ms (newyorkcityservers.com 2026) |
| 3 | **Partial-fill recovery protocol**: less-liquid leg first; cancel-and-unwind if second leg fails within 5s | Execution atomicity gap confirmed in arb.py, cycle 2 |
| 4 | **Binary-only scope**: exclude neg_risk multi-outcome markets — N-leg atomicity scales linearly with outcomes | ArbStrategy code structure analysis |

**Plus:** lockup-adjusted net edge logging (`gross_gap − fee_cost − days_to_resolution × 0.000137`), competitor-absorbed guard (depth at parity = bots already won), market-void state check before submission.

### Category minimum edges (at p=0.50, most conservative)

| Category | Fee rate | Min edge |
|---|---|---|
| Geopolitics | 0% | $0.005 |
| Sports | 3% | $0.020 |
| Politics/finance | 4% | $0.025 |
| Weather | 5% | $0.030 |
| Crypto | 7.2% | $0.041 |

### Key quantitative anchors

- **Lockup cost**: 5% risk-free annualized → 0.0137%/day; 30-day market: 0.41%; 7-day: 0.096%
- **Net APY on 2% gap after fees**: 7-day → 104% APY; 30-day → 24.3% APY (still attractive)
- **Bot absorption**: gaps survive <30s on efficient markets; >90s = structural issue, not opportunity

### Implementation gaps (7 — none resolved yet in code)
1. Category not fetched (ArbStrategy uses flat MIN_ARB_EDGE regardless of market category)
2. Gap timestamp not tracked (no age filter)
3. neg_risk not filtered (multi-outcome markets accepted)
4. Leg ordering not optimized (currently arbitrary)
5. No fill confirmation/partial-fill recovery
6. No lockup cost computation
7. No depth check vs position size before submission

### Files updated
- `knowledge/polymarket/prims/intermediate/binary-arb-completeness.md` — created
- `knowledge/epistemic-index.md` — naive SUPERSEDED, intermediate row added
- `knowledge/conditions-log.md` — naive SUPERSEDED, intermediate entry added
- Commit: `e504177`

### Polymarket prim status

| Prim | Level |
|------|-------|
| binary-arb-completeness | **intermediate** ← this cycle |
| spread-capture-market-making | intermediate |
| fractional-kelly-sizing | intermediate |
| ensemble-forecast-edge | intermediate |

**All 4 polymarket prims now at intermediate. No remaining naive prims.**

### Next cycle recommendations
1. **(A) Elevate binary-arb-completeness to sophisticated** — requires live paper-trade data (gap age distribution, partial-fill rate, actual APY per category). 30-day scanner run needed.
2. **(B) Elevate any polymarket intermediate to sophisticated** — spread-capture is the strongest candidate (Avellaneda-Stoikov implementation + live MM P&L data would anchor it).
3. **(C) Freqtrade focus** — 4 naive + 4 intermediate freqtrade prims, 0 sophisticated yet; hidden-bullish-rsi-divergence needs a BACKTEST-ANALYSIS cycle.
