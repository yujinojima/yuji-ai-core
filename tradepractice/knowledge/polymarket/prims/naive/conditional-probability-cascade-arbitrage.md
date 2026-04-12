# Prim: conditional-probability-cascade-arbitrage
**Level:** naive
**Cycle introduced:** 114
**Project:** polymarket
**Axis:** 21 (first naive-active prim since all 20 prior axes reached sophisticated)

---

## Core Hypothesis

When Polymarket simultaneously lists upstream market U (e.g. "Will X win the primary?") and
downstream market D (e.g. "Will X win the presidency?") where D logically requires U, the
Bayesian product constraint is exact:

> P(D) ≈ P(U) × r, where r = P(D=YES | U=YES)

Any price state where P(D)_market > P(U)_market is a subset axiom violation. Any price state
where |P(D) − P(U)×r| > threshold reflects the **conjunction fallacy** (Tversky & Kahneman 1983):
traders price each leg on its own narrative, estimating P(A∩B) > P(B).

**Unique property vs. 20 existing prims:** deterministic convergence at upstream resolution.
If U resolves YES, D must immediately re-price. If U resolves NO, D collapses to ≈0.
This is a contractually forced exit, not a belief-change exit.

---

## Signal Rule (Naive)

- Identify U→D cascade pair (both listed on Polymarket)
- Estimate r from prior table (≥ 15 comparable historical instances) or structural logic
- **Threshold:** |P(D)_market − P(U)_market × r| > 0.08 (0.12 when r CI > 0.20)
  - Conjunction fallacy (P(D) > P(U)×r): BUY NO on D, BUY YES on U
  - Under-conditioning (P(D) < P(U)×r): BUY YES on D, BUY NO on U
- **Hard-floor:** P(D) > P(U) by >2 pp = subset axiom violation → always trade
- **Sizing:** α=0.10 Kelly floor (mandatory until calibration history exists)
- **Exit:** upstream resolution / gap closure / 60-day max

---

## Academic Basis

1. **Tversky & Kahneman (1983, Psych Rev)** — conjunction fallacy; P(A∩B) > P(B) violation
2. **Tversky & Kahneman (1974, Science)** — representativeness heuristic
3. **Bar-Hillel (1980, Acta Psych)** — conditional probability updating failure under incentives
4. **Wolfers & Zitzewitz (2004, JEP)** — PM cross-market consistency violations
5. **Manski (2006, JFE)** — explicit cross-market probability constraint violations in PM data
6. **Leigh & Wolfers (2006, Economic Record)** — IEM state-vs-national cascade 2–4 pp inconsistency
7. No peer-reviewed PM-specific cascade test exists — own-data extraction is the mandatory next step

---

## Implementation (Cycle 114)

| File | Status |
|---|---|
| `src/strategies/cascade_detector.py` | Implemented — keyword pattern matching, G0 uncleared |
| `src/strategies/conditional_rate_db.py` | Implemented — hard-coded priors, G2 uncleared |
| `src/strategies/conditional_cascade_arbitrage.py` | Implemented — signals suspended (all gates uncleared) |

Strategy registered: NOT YET added to `scanner.py` (awaiting G0 precision validation).

---

## Blocking Gates

| Gate | Description | Status |
|---|---|---|
| G0 | Cascade pair detector precision ≥ 0.85 on 50-item spot-check | UNCLEARED |
| G1 | Gamma API cascade pair database ≥ 50 pairs (2022-2024) | UNCLEARED |
| G2 | Beta-Binomial r calibration per type (CI ≤ 0.20, N ≥ 15) | UNCLEARED |
| G3 | IS backtest: conjunction fallacy direction dominance (Mann-Whitney U) | UNCLEARED |
| G4 | Information vs. bias gate (`is_conditional_independent_event()`) | UNCLEARED |

All gates uncleared → live signals suspended. Strategy logs opportunities for manual review.

---

## Limitations

1. Cascade detection requires NLP + domain knowledge — pattern matching only (G0 uncleared)
2. Conditional rate r estimation is primary analytical blocker (few instances, wide CIs)
3. Asymmetric liquidity risk (downstream leg often thinner)
4. Resolution timing mismatch (unexpected early upstream resolution = tail risk)
5. Information vs. bias confound (genuine conditional-independent news can legitimately break r)
6. Correlated exposure with `base-rate-neglect-fade` (same underlying bias, different framing)
7. No production deployment — all 5 gates must clear before live trading

---

## Refinement Path (Intermediate)

1. **Gamma API extraction** — pull resolved markets 2022-2024, identify U→D pairs manually,
   spot-check precision ≥ 0.85 on N=30 (clears G0 + G1)
2. **Beta-Binomial r database** — ≥ 15 instances/type, flag CI > 0.20 as r-uncertain (clears G2)
3. **IS backtest** — Mann-Whitney U, conjunction direction dominance, measure gap/convergence (clears G3)
4. **Information gate** — `is_conditional_independent_event()` heuristic excludes genuine P(D|U) shifts (clears G4)

---

## Why This Is the 21st Prim (Not a Variant)

| Closest existing prim | Why cascade is distinct |
|---|---|
| `cross-venue-semantic-arb` | Same event, different venues — no Bayesian product constraint |
| `semantic-correlation-pair-trade` | Bidirectional correlation, no causal direction, no deterministic exit |
| `binary-arb-completeness` | Single market P(YES)+P(NO)=1 — no cross-market structure |
| `base-rate-neglect-fade` | Single market vs. category frequency — no two-leg product constraint |

---

## Bank State (After Cycle 114)

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive (superseded) | 15 | 20 |
| Naive (active) | 0 | **1** |
| Intermediate | 20 | 20 |
| Sophisticated | 20 | 20 |
