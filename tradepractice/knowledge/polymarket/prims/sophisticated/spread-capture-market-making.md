---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T13:29:31+10:00
cycle: 20
---

---

## Prim: spread-capture-market-making
**Level:** sophisticated (elevated from intermediate)
**Project:** polymarket
**Parent:** spread-capture-market-making (intermediate)

### Rule
A-S logit-space maker quotes with **dynamic σ_b²=p(1−p)** + **γ(t) = γ_base × T_initial/T_remaining** + **Kyle λ maturation gate** (reject markets where λ_proxy > 0.05) + **category-specific adverse selection windows** (cancel-on-move: sports ≥2%/30s, politics ≥3%/2min, geopolitics ≥5%/5min) + **inventory decay Position(t) = Initial × sqrt(T_remaining/T_initial)** + **maker rebate revenue model** (40–60% of total revenue) + 50% wash-trading volume haircut + OBI flow-direction check (|IR| < 0.65) + 200–500ms refresh.

### Five core upgrades

| # | Upgrade | Source |
|---|---------|--------|
| 1 | **Dynamic σ_b² = p(1−p)** — fixed 0.25 overestimates variance by 19% at price boundary (p=0.30) | arxiv 2510.15205 |
| 2 | **γ(t) ∝ 1/(T−t)** — risk aversion increases as resolution approaches; at T−t=24h, γ=3.00 | Bawa: inventory decay ∝ sqrt(T/T₀) |
| 3 | **Kyle λ maturation gate** — λ drops 50× from 0.518 to 0.01 with maturation; reject > 0.05 | arxiv 2603.03136 |
| 4 | **Category adverse selection windows** — sports <5min, politics 15–60min, geopolitics 30–180min | arxiv 2603.03152, Bawa |
| 5 | **Maker rebate = 40–60% of revenue** — politics/finance optimal (50% rebate share vs geopolitics 0%) | docs.polymarket.com, ChainCatcher |

### Key quantitative benchmarks

| Metric | Value | Source |
|--------|-------|--------|
| Target Sharpe | 2.0–2.8 | Bawa |
| Daily PnL at $10k | $200–800 | ChainCatcher |
| Win rate | 52–58% | Bawa |
| Minimum edge | ~3% at p=0.50 | gwrx2005 |
| VR(6) at shock | 1.84 (persistent drift) | arxiv 2603.03152 |
| OBI predictive R² | 0.65 | Bawa |
| Wash trading | 20–60% of volume | Columbia Nov 2025 |

### Polymarket prim status

| Prim | Level |
|------|-------|
| fractional-kelly-sizing | **sophisticated** |
| spread-capture-market-making | **sophisticated** ← this cycle |
| binary-arb-completeness | intermediate |
| ensemble-forecast-edge | intermediate |

**Second polymarket sophisticated prim. 2 intermediate prims remain.**

### Files updated
- `knowledge/polymarket/prims/sophisticated/spread-capture-market-making.md` — created
- `knowledge/epistemic-index.md` — intermediate SUPERSEDED, sophisticated row added
- `knowledge/conditions-log.md` — intermediate marked [historical], sophisticated entry added
- Commit: `5ea421a`

### Next cycle recommendations
1. **(A) Elevate ensemble-forecast-edge to sophisticated** — station-gridpoint mismatch quantification + ECMWF integration + 100+ trade sample backtest
2. **(B) Elevate binary-arb-completeness to sophisticated** — 30-day paper-trade scanner for gap age/partial-fill data
3. **(C) New naive prim: OBI-informed directional** — OBI IR > 0.65 predicts direction at 58% accuracy; distinct signal class from MM
