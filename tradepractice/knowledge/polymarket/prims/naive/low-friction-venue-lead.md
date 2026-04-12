---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T14:50:02+10:00
cycle: 95
---

---

**Cycle 95 — RESEARCH — Complete**

---

## Prim: low-friction-venue-lead
**Level:** naive | **Project:** polymarket | **Cycle:** 95 | **Class:** 18th

---

### What was created

A new signal axis not represented in any of the 17 existing sophisticated prims: **behavioral anchoring lag between zero/low-capital-risk prediction venues and large-position Polymarket**.

**Rule (naive):**
~~When Manifold Markets community price OR PredictIt financially-incentivised price diverges from the semantically equivalent Polymarket YES price by ≥ 10 pp, and the divergence formed within the last 6 hours, BUY Polymarket in the direction of the low-friction venue. Exit when the gap closes to ≤ 3 pp or at 72-hour max. PM liquidity $5k–$50k; resolution horizon 7–60 days; α=0.10 Kelly floor.~~ — **SUPERSEDED** by intermediate (cycle 96)

### Why this is the 18th distinct class

| Existing prim | Why this prim is different |
|---|---|
| `superforecaster-consensus-lead` | Uses expert *probability estimates* (Metaculus/GJP) — slow-updating deliberate signals; this prim uses *live market prices* on venues with zero/low capital stakes |
| `cross-venue-semantic-arb` | Simultaneous bilateral arb on two *financially-incentivised* venues (PM + Kalshi) — risk-free; Manifold cannot be hedged (play money), no atomic bridge to PredictIt → purely directional lead-lag |
| `news-velocity-informed-directional` | Measures rate of external information entering the public domain; this prim measures how a *market community has already aggregated that information* into a price |

### Mechanism

Two behavioral frictions slow Polymarket price updates when new information arrives:
1. **Loss aversion anchoring** — participants holding $5k–$50k positions resist updating beliefs that would cause them to realise losses (Kahneman-Tversky 1979)
2. **Capital commitment friction** — exiting and re-entering a large position requires capital deployment or loss realisation; on Manifold (play money) and PredictIt ($850 cap) this cost is near-zero

Result: Manifold and PredictIt reprice within minutes; Polymarket lags by hours. The gap is a directional signal, not an arbitrageable spread.

### Primary open question (Limitation #6)

**Granger causality direction is untested.** The mechanism predicts Manifold→PM lead, but PM may lead Manifold in some conditions. This is the decisive intermediate-elevation gate: historical cross-correlation of Manifold vs PM time series on N≥50 co-listed political events (2022–2025).

### 6 academic anchors

Kahneman-Tversky 1979 Econometrica (loss aversion) · Shleifer-Vishny 1997 JF (limits of arbitrage) · Wolfers-Zitzewitz 2004 JEP (prediction market efficiency and friction) · Servan-Schreiber et al. 2004 Electronic Markets (play-money vs real-money calibration) · Pennock et al. 2001 PNAS (play/real-money divergence patterns) · Grossman-Stiglitz 1980 AER (informed agents + friction)

### Bank state after cycle 95

| Level | Count | Active |
|---|---|---|
| Naive | 18 | 1 (low-friction-venue-lead) |
| Intermediate | 17 | 0 |
| Sophisticated | 17 | 17 |

### Next cycle recommendations

1. **(A) RESEARCH: Elevate low-friction-venue-lead to intermediate** — primary gate: test Granger causality on historical Manifold vs PM price time series for N≥50 co-listed political events (2022–2025). If Manifold leads PM in ≥ 60% of directional moves, mechanism is validated. If direction is inverted → anti-prim. Calibrate divergence threshold by category (election/economic/tech).
2. **(B) BUILD: manifold_pm_matcher.py** — semantic equivalence classifier; reuse `metaculus_pm_matcher.py` architecture from `superforecaster-consensus-lead`; different resolver authority lookup (Manifold = community vote; PredictIt = AP/official); test on 50 manually labeled pairs.
3. **(C) RESEARCH: Calibrate threshold** — 10 pp is derived by analogy; test whether threshold differs by source (Manifold vs PredictIt), category, and PM liquidity tier.
