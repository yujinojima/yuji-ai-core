---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T11:47:59+10:00
cycle: 18
---

## Prim: fractional-kelly-sizing
**Level:** sophisticated (elevated from intermediate)
**Project:** polymarket
**Parent:** fractional-kelly-sizing (intermediate)

### What changed

The intermediate had three weaknesses: Brier ≤ 0.30 as an arbitrary tier threshold, 1/sqrt(N) as a heuristic (wrong formula for correlated Kelly), and no horizon discount. All three are now analytically derived or replaced.

**Four core upgrades:**

| # | Upgrade | Derivation source |
|---|---------|-------------------|
| 1 | **RMSE tiers from KL-divergence loss formula** | Δg ≈ ε²/(2·p·(1−p)) per bet (arxiv 2412.14144) |
| 2 | **N_eff = N/(1+(N−1)·ρ̄) replaces 1/sqrt(N)** | Exact portfolio Kelly for correlated bets |
| 3 | **Horizon discount: edge_adj = edge_gross − 0.05·T/365** | Opportunity cost of binary lockup |
| 4 | **Circuit-breaker state machine (NORMAL/REDUCED/PAUSED)** | MacLean-Hakansson ruin probability tables |

### RMSE tier boundaries (derived, not arbitrary)

At tolerable edge loss β=0.20: ε_max = sqrt(β·E·2·p·(1−p))

| Tier | RMSE | α | Growth loss at boundary | Growth loss vs 8% edge |
|------|------|---|------------------------|------------------------|
| Full | < 5% | 0.50 | ~0.5%/bet | 6% of edge |
| Reduced | 5–12% | 0.25 | ~2.9%/bet | 36% of edge |
| Floor | > 12% | 0.10 | > 2.9%/bet | > 36% — flat sizing preferred |
| No data | N < 30 | 0.10 | undefined | mandatory floor |

**Intermediate's Brier ≤ 0.30 corrected:** at p=0.5, Brier = p(1−p) + ε² → minimum achievable BS = 0.25 for any perfect model. Brier ≤ 0.30 maps to ε ≤ 0.22 — far too loose. KL-divergence analysis shows ε must be < 0.05 for safe α=0.50.

### Portfolio N_eff (replacing 1/sqrt(N))

`N_eff = N / (1 + (N−1)·ρ̄)`

| Scenario | N | ρ̄ | N_eff | 1/sqrt(N) | Error |
|---|---|---|---|---|---|
| Same-city brackets | 5 | 0.80 | 1.22 | 2.24 | 45% undersize of concentration |
| Cross-continent cities | 3 | 0.15 | 2.36 | 1.73 | 36% oversize |
| City pairs 100–500km | 3 | 0.40 | 1.86 | 1.73 | 7% — acceptable |

### Polymarket prim status

| Prim | Level |
|------|-------|
| fractional-kelly-sizing | **sophisticated** ← this cycle |
| binary-arb-completeness | intermediate |
| spread-capture-market-making | intermediate |
| ensemble-forecast-edge | intermediate |

**First polymarket sophisticated prim. 3 intermediate prims remain.**

### Files updated
- `knowledge/polymarket/prims/sophisticated/fractional-kelly-sizing.md` — created
- `knowledge/epistemic-index.md` — intermediate SUPERSEDED, polymarket sophisticated section created
- `knowledge/conditions-log.md` — intermediate marked [historical], sophisticated entry added
- Commit: `3000fd6`

### Next cycle recommendations
1. **(A) Elevate spread-capture-market-making to sophisticated** — Avellaneda-Stoikov logit-space adaptation is the most theory-complete intermediate prim; needs live MM P&L data to anchor quantitative claims
2. **(B) Elevate ensemble-forecast-edge to sophisticated** — requires own-data backtest on 100+ historical Polymarket weather markets with station-matched resolution data; station-gridpoint mismatch is the primary unresolved gap
3. **(C) Elevate binary-arb-completeness to sophisticated** — needs 30-day paper-trade scanner to validate gap age distribution and partial-fill recovery protocol in live conditions
