---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T20:38:37+10:00
cycle: 40
---

---

## Prim: superforecaster-consensus-lead
**Level:** intermediate (refined from naive)
**Project:** polymarket
**Parent:** naive/superforecaster-consensus-lead
**Commit:** `f80f0b5`

### Rule
**Mode A — Fresh Divergence:** Metaculus median OR GJP diverges ≥ 10% from PM YES (≤ 48h old, Metaculus update < 24h, ≥ 150 predictors, bid-ask ≥ 3%, horizon 7–30d, **geopolitics only**) → buy PM in Metaculus direction. α=0.10 Kelly floor.

**Mode B — Persistent Calibration Gap:** Divergence ≥ 8% persisted ≥ 72h (≥ 100 predictors, bid-ask ≥ 2%, horizon 30–90d, geopolitics + politics/finance) → buy PM in Metaculus direction. α=0.10 Kelly floor.

**Both modes:** PM $5k–$50k; manually verified semantic equivalence; BLOCKING: `metaculus_pm_matcher.py`.

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Mechanism basis | GJP 30% tournament advantage | **Metaculus Brier 0.111 vs PM 0.187 — ~40% accuracy gap on matched events** |
| Signal design | Single ≥ 8% threshold | **Two-mode: Mode A (fresh ≥10%) and Mode B (persistent ≥8% for ≥72h)** |
| Horizon | 3–90 days flat | **7-day floor: PM outperforms expert consensus at < 7 days (Wiley 2012)** |
| Predictor gate | ≥ 100 | **≥ 150 Mode A; ≥ 100 Mode B** |
| Domain | geopolitics/politics | **Mode A: geopolitics only; Mode B: geopolitics + politics/finance** |
| Efficiency gate | none | **bid-ask ≥ 3% (Mode A); ≥ 2% (Mode B)** |
| Mechanism type | "calibrated beats financial" | **Calibration-based convergence — NOT time-lag (mechanistically distinct from financial-lead-lag)** |

### Mechanism Distinction from financial-market-lead-lag

| Dimension | financial-market-lead-lag | superforecaster-consensus-lead |
|---|---|---|
| Why PM is wrong | Retail attention delay (sub-minute lag) | Base-rate neglect, narrative bias, recency overweighting |
| Lead source | Institutional trading (CME, faster access) | Score-incentivised calibration (Brier minimisation) |
| Convergence trigger | Fast participants arbitrage the lag | PM participants discover calibration gap (slower) |
| Hold horizon | Minutes to days | Days to months |
| Contractual guarantee | None | None |

### Evidence — 8 Sources

| Source | Finding |
|---|---|
| **Tetlock & Mellers (2015, Psych Sci)** | GJP superforecasters beat IC prediction markets (with classified data) by **30% Brier reduction**; beat unfiltered forecasters 60% |
| **Manifund / Medium Metaculus comparison** | Metaculus Brier **0.111** vs Polymarket **0.187** on matched events — ~40% gap. 2022 US midterms: Metaculus ranked highest; Polymarket below average |
| **Atanasov, Mellers, Tetlock et al. (SSRN 4691513, 2024)** — "Crowd Prediction Systems" | Team prediction polls with aggregation (temporal decay + performance weighting + recalibration) **outperformed or tied prediction markets**. Calibrated aggregation extracts superior accuracy |
| **Wiley 2012 — "Do Prediction Markets Produce Well-Calibrated Probability Forecasts?"** | PMs well-calibrated at < 1 year; calibration NOT better in liquid markets. **< 7-day horizon: PM advantage** — drives the 7-day floor |
| **Good Judgment 2024** | GJP teams **outperformed futures markets by 30%** for FOMC interest rate decisions — cross-domain calibration advantage extends beyond geopolitics |
| **Mellers et al. (2015, Psych Sci)** | Active de-biasing = ~50% noise reduction + 25% bias reduction + 25% information improvement — mechanism decomposition |
| **Reichenbach & Walther (SSRN 5910522) [in bank]** | PM 94% accurate overall; 70% of users unprofitable — aggregate accuracy compatible with per-market exploitable divergences |
| **Snowberg & Wolfers (2004, JEP)** | PM and expert consensus co-price events sequentially, not simultaneously |

### Key Numbers

| Metric | Value |
|---|---|
| Metaculus Brier score | **0.111** |
| Polymarket Brier score | **0.187** |
| Calibration gap | **~40%** |
| GJP vs IC prediction markets | **−30% Brier** |
| GJP vs futures (FOMC, 2024) | **+30% outperformance** |
| Horizon floor | **7 days** (PM advantage below) |
| Mode A divergence threshold | **≥ 10%** (< 48h old) |
| Mode B divergence threshold | **≥ 8%** (≥ 72h persistent) |
| Realistic live WR target | **55–65%** (hypothesis — no own-data) |

### Critical Limitation
No empirical study exists that directly tests "when Metaculus diverges ≥ 8% from PM, what % resolves in Metaculus direction?" The WR target (55–65%) is derived from the Brier gap by analogy. The prim cannot advance beyond hypothesis until own-data collection begins.

### Anti-Prim Escape Hatches (2 Formal)
- **(A) Convergence null**: rolling 20 divergence events → WR < 55% → calibration advantage not exploitable on PM binary format
- **(B) Domain failure**: 30 geopolitics trades → WR < 52% → mechanism absent for this event class

### Bank State After Cycle 40

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | **0** | **0** |
| Intermediate | 0 | **1** (superforecaster-consensus-lead) |
| Sophisticated | 7 | 8 |

### Next Cycle Recommendations
**(A) RESEARCH** — find any empirical study directly testing calibrated-forecast-platform divergence from prediction markets as a directional signal. Target: "Metaculus Polymarket trading", "superforecaster prediction market accuracy divergence", arxiv 2024-2026. A single study with WR data at a threshold could elevate to sophisticated. If no study exists, own-data collection is the path.
**(B) IMPLEMENT** — `metaculus_pm_matcher.py`: sentence-transformer embedding ≥ 0.85 + Type A/B/C keyword veto from cross-venue-semantic-arb prim. 50 labeled Metaculus-PM pairs unlocks first live trade.
**(C) BACKTEST-ANALYSIS** — hidden-bullish-rsi-divergence 28-cell plateau test (anti-prim precursor WR=30% at n=10 from cycle 37). Cheapest definitive test in the freqtrade bank — if plateau fails, removes a prim.
