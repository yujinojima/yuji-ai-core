---
name: superforecaster-consensus-lead
level: intermediate
project: polymarket
parent_prim: naive/superforecaster-consensus-lead
created: 2026-04-11
last_validated: never
---

## Prim: superforecaster-consensus-lead
**Level:** intermediate (refined from naive)
**Project:** polymarket
**Parent:** naive/superforecaster-consensus-lead

### Rule
**Mode A — Fresh Divergence:** Metaculus community median OR GJP consensus diverges ≥ 10% from PM YES price AND divergence is ≤ 48h old AND Metaculus last update < 24h AND ≥ 150 predictors AND resolution horizon 7–30 days AND PM bid-ask ≥ 3% (inefficiency gate) AND geopolitics category only → buy PM in Metaculus direction. α=0.10 Kelly floor.

**Mode B — Persistent Calibration Gap:** Divergence ≥ 8% has persisted ≥ 72h AND Metaculus consensus stable (< 2pp change in 24h) AND ≥ 100 predictors AND resolution horizon 30–90 days AND PM bid-ask ≥ 2% AND geopolitics or politics/finance category → buy PM in Metaculus direction. α=0.10 Kelly floor.

**Both modes require:** semantically equivalent question (manual review — no automated matcher yet); PM liquidity $5k–$50k; resolution > 7 days; NOT near-term binary (< 7 days = PM advantage, not Metaculus); BLOCKING: `src/classifiers/metaculus_pm_matcher.py` does not yet exist.

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Mechanism basis | GJP 30% Brier advantage (tournament) | **Quantified: Metaculus Brier 0.111 vs Polymarket 0.187 — ~40% accuracy gap on same event class** |
| Signal design | Single threshold ≥ 8% | **Two-mode: Mode A (fresh, ≥10%) and Mode B (persistent ≥72h, ≥8%)** |
| Horizon | 3–90 days (flat) | **7-day floor required** (PM outperforms expert consensus at < 7 days per Wiley 2012) |
| Predictor gate | ≥ 100 predictors | **≥ 150 Mode A; ≥ 100 Mode B** |
| Domain | geopolitics/politics | **Mode A: geopolitics only; Mode B: geopolitics + politics/finance** |
| Recency gate | none | **Metaculus update < 24h (stale signal risk)** |
| Sophistication gate | PM $5k–$50k | **+ bid-ask ≥ 3% Mode A; ≥ 2% Mode B** (bots have not absorbed) |
| Mechanism type | "calibrated beats financial" | **Articulated as calibration-based convergence, NOT time-lag (different mechanism from financial-lead-lag)** |
| Certainty | hypothesis | **hypothesis (4 sources with quantified mechanism; no own-data)** |

### Mechanism Distinction from financial-market-lead-lag

| Dimension | financial-market-lead-lag | superforecaster-consensus-lead |
|---|---|---|
| Why PM is wrong | Retail attention delay (seconds/minutes) | Base-rate neglect, narrative bias, recency weighting |
| Lead source | Institutional trading (CME, sub-minute) | Score-incentivised calibration (Brier minimisation) |
| Convergence trigger | Fast participants arbitrage the lag | PM participants discover calibration gap (slower) |
| Hold horizon | Minutes to days | Days to months |
| Domain | FOMC/monetary policy only | Geopolitics, elections, international events |
| Contractual guarantee | None (probabilistic) | None (probabilistic) |
| Primary failure mode | Bot competition (execution speed) | Semantic non-fungibility (question scope) |

### Evidence — 8 Sources

| Source | Finding |
|---|---|
| **Tetlock & Mellers (2015, Psych Sci) [inherited]** | GJP superforecasters beat intelligence community prediction markets (with classified data) by **30% Brier score reduction**; beat unfiltered forecasters by 60% |
| **Manifund comparison / Medium (2024-2025)** | Metaculus Brier score **0.111** vs Polymarket **0.187** on matched events — ~40% accuracy gap. 2022 US midterms: Metaculus ranked highest, Polymarket below average |
| **Atanasov, Mellers, Tetlock et al. (SSRN 4691513, 2024)** — "Crowd Prediction Systems: Markets, Polls, and Elite Forecasters" | Team prediction polls (with temporal decay + performance weighting + recalibration) **outperformed or tied prediction markets**. CDA markets underperformed LMSR markets; aggregated polls tied LMSR. Evidence that calibration-weighted consensus extracts superior accuracy |
| **Wiley 2012 — "Do Prediction Markets Produce Well-Calibrated Probability Forecasts?" (Tetlock/Columbia)** | PMs well-calibrated at < 1 year horizons; calibration degrades at longer horizons. **Calibration is NOT better in liquid markets** — counterintuitive finding suggesting high-liquidity PM efficiency is not uniformly superior to expert consensus. **< 7 day horizon: PM advantage** (financial incentives dominate) |
| **Good Judgment 2024 (Good Judgment website)** | GJP teams outperformed futures markets by **30%** in accuracy for FOMC interest rate decisions — cross-domain calibration advantage extends beyond geopolitics (analogous to our prim but higher-frequency domain) |
| **Mellers et al. (2015, Psych Sci) [inherited]** | Active de-biasing (recalibration training + team aggregation) produces ~50% noise reduction, 25% bias reduction, 25% information improvement — quantifies the mechanism |
| **Reichenbach & Walther (SSRN 5910522) [in bank]** | Polymarket 94% accuracy, closely tracks realized probabilities; but 70% of users unprofitable. **PM is accurate on aggregate but unevenly distributed** — the aggregate accuracy is compatible with exploitable per-market divergences from better-calibrated sources |
| **Snowberg & Wolfers (2004, JEP) [inherited]** | Prediction markets and expert consensus co-price events; co-pricing is sequential, not simultaneous |

### Key Numbers

| Metric | Value |
|---|---|
| Metaculus Brier score | **0.111** |
| Polymarket Brier score | **0.187** |
| Calibration gap | **~40%** (lower Brier = better) |
| GJP vs IC prediction markets | **−30% Brier** (superforecasters win) |
| GJP vs futures (FOMC, 2024) | **30% outperformance** |
| < 7 day horizon | **PM advantage** — Metaculus signal invalid |
| Signal threshold Mode A | **≥ 10%** divergence (< 48h old) |
| Signal threshold Mode B | **≥ 8%** divergence (≥ 72h persistent) |
| Required PM bid-ask | **≥ 3% Mode A; ≥ 2% Mode B** |
| Kelly floor | **α=0.10** (no calibration history yet) |
| Realistic live WR target | **Unknown** — no own-data; 55–65% hypothesised from Brier gap |

### 8 Documented Limitations (Intermediate)
1. **Semantic non-fungibility (#1)** — no automated classifier exists; manual review per market; blocking implementation gap
2. **Horizon inversion** — at < 7 days, PM outperforms expert consensus (Wiley 2012); this prim inverts if applied too close to resolution
3. **Convergence mechanism is weak and slow** — no contractual or mechanical force; reliance on PM participants discovering the calibration gap
4. **Metaculus calibration domain** — advantage best documented for geopolitics/AI milestones/long-horizon; political binary near-term less clear
5. **No empirical WR data** — the specific test "when Metaculus diverges ≥ 8%, what % resolves in Metaculus direction?" does not exist in published literature; this prim remains hypothesis-class despite academic basis
6. **PM sophistication gate is crude** — bid-ask ≥ 3% is a proxy for low sophistication; sophisticated PM-native participants could be present in any liquidity range
7. **Mode A threshold (10%) is arbitrary** — chosen to exclude noise; may be too conservative (misses 8–10% divergences that are real) or too loose (still catches PM inefficiencies in Mode A domain)
8. **Recency gate creates staleness risk** — Metaculus questions on slow-moving events may have low update frequency; a 72h consensus stability in Mode B could indicate poor participation, not conviction

### 5 Implementation Gaps
1. `src/classifiers/metaculus_pm_matcher.py` — semantic question equivalence checker (BLOCKING for all trades)
2. `src/signals/metaculus_feed.py` — Metaculus API integration: question ID, community median, predictor count, last update timestamp
3. `src/strategies/superforecaster_lead.py` — Mode A/B logic, divergence staleness check, bid-ask gate
4. `src/risk/antiprims.py` — anti-prim circuit breakers (A) and (B) monitoring (shared with other PM prims)
5. Predictor count quality filter — ≥ 150 for Mode A; distribution of predictors matters (10 superforecasters > 150 random users)

### Anti-Prim Escape Hatches (2 Formal)
- **(A) Convergence null**: rolling 20 divergence events → Metaculus direction resolves correctly < 55% → calibration advantage not exploitable on PM binary format → anti-prim
- **(B) Domain failure**: own-data ≥ 30 trades on geopolitics events → WR < 52% → mechanism absent for this event class → anti-prim (domain)

### Bank State After Cycle 40

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | **0** | **0** (superforecaster-consensus-lead elevated) |
| Intermediate | 0 | **1** (superforecaster-consensus-lead) |
| Sophisticated | 7 | 8 |

### Next Cycle Recommendation
**(A) RESEARCH** — find any empirical study that directly tests calibrated forecasting platform consensus vs prediction market prices as a directional trading signal. Primary search: "Metaculus Polymarket divergence resolution accuracy", "superforecaster prediction market trading", arxiv 2024-2026. Key deliverable: a single study with WR numbers when calibrated consensus deviates by a threshold amount. If such a study exists, it could elevate this prim to sophisticated. If it doesn't, own-data collection is the only path.
**(B) IMPLEMENT** — `src/classifiers/metaculus_pm_matcher.py`: match Metaculus questions to Polymarket questions using sentence-transformer embedding ≥ 0.85 + resolution-criteria keyword veto (Type A/B/C from cross-venue-semantic-arb prim). 50 labeled pairs unblocks the first live trade.

Recommend **(A)** first — if no study exists, own-data is a multi-month collection effort; knowing this now sets expectations. **(B)** can run in parallel with (A) as the implementation prerequisite.

### Sources
- [Tetlock & Mellers (2015, Psych Sci) — GJP superforecasters vs intelligence community](https://doi.org/10.1177/0956797615574898)
- [Manifund project — Comparing Forecasting Platform Accuracy (Brier scores)](https://manifund.org/projects/comparing-forecasting-platform-accuracy)
- [Medium — Why I Reject the Comparison of Metaculus to Prediction Markets](https://metaculus.medium.com/why-i-reject-the-comparison-of-metaculus-to-prediction-markets-4175553bcbb8)
- [Atanasov, Mellers, Tetlock et al. (SSRN 4691513, 2024) — Crowd Prediction Systems](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4691513)
- [Wiley (2012) — Do Prediction Markets Produce Well-Calibrated Probability Forecasts?](https://onlinelibrary.wiley.com/doi/abs/10.1111/j.1468-0297.2012.02561.x)
- [Good Judgment 2024 — GJP vs futures markets FOMC outperformance](https://goodjudgment.com/superforecasting/)
- [Mellers et al. (2015, Psych Sci) — Superforecasting mechanism decomposition](https://doi.org/10.1177/0956797615579358)
- [Reichenbach & Walther (SSRN 5910522) — Exploring Decentralized Prediction Markets](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5910522)
