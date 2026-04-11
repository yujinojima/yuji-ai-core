---
name: superforecaster-consensus-lead
level: sophisticated
project: polymarket
parent_prim: intermediate/superforecaster-consensus-lead
created: 2026-04-11
last_validated: never
reaction_validated: no
---

## Prim: superforecaster-consensus-lead
**Level:** sophisticated (elevated from intermediate, cycle 41)
**Project:** polymarket
**Parent:** intermediate/superforecaster-consensus-lead

### What Changed from Intermediate

| Dimension | Intermediate | Sophisticated |
|---|---|---|
| Threshold structure | Flat: Mode A ≥ 10%, Mode B ≥ 8% | **3-tier source quality**: GJP/Almanis ≥ 8%; Metaculus tracked ≥ 10%; community ≥ 12% — Atanasov et al. (2024): unweighted community *ties* markets, not beats |
| Horizon model | 7-day binary floor | **Peaked calibration window**: < 7d reject; 14–45d peak; 45–90d declining; > 90d reject |
| Signal frequency | "Unknown" | **~30–100/year (derived)**; N=30 achievable in 3–12 months — most tractable PM information-edge prim in bank |
| Competitive structure | "Convergence mechanism is weak" | **Slow-edge moat**: < 20 systematic competitors; semantic matching is the barrier, not execution speed; compression timeline months-to-years |
| Predictor gate | Raw count (≥ 150 / ≥ 100) | **Tracked-forecaster concentration gate** ≥ 15% tracked status — Atanasov (2024): performance weighting is the operative variable |
| Anti-prim escapes | 2 informal | **3 formal with exact thresholds** |

### Rule (Sophisticated)

**Mode A — Fresh Divergence (source-quality-tiered):**

| Source | Threshold | Predictor gate | Horizon |
|---|---|---|---|
| GJP / Almanis | ≥ 8% | Professional selection | 7–45 days |
| Metaculus tracked-forecaster subset | ≥ 10% | ≥ 15% tracked status | 7–45 days |
| Metaculus community median | ≥ 12% | ≥ 200 predictors | **14–30 days only** |

Mode A gates: divergence ≤ 48h old; Metaculus update < 24h; PM bid-ask ≥ 3%; geopolitics only; no breaking news 12h.

**Mode B — Persistent Calibration Gap:**
Any source ≥ 8% persisted ≥ 72h; Metaculus stable < 2pp/24h; ≥ 100 predictors; horizon 30–90d; bid-ask ≥ 2%; geopolitics or politics/finance.

**Both modes:** Semantic equivalence via `metaculus_pm_matcher.py` [BLOCKING]; PM $5k–$50k; resolution 7–90 days; α=0.10 Kelly floor.

**Exit:** divergence < 2%, resolution, or 45-day hard stop (Mode A) / 90-day hard stop (Mode B).

### Calibration-Horizon Curve

| Horizon | Verdict | Mode gate |
|---|---|---|
| T < 7d | **REJECT unconditionally** (PM wins) | — |
| T 7–14d | Mixed | Mode A minimum viable, community threshold only |
| **T 14–45d** | **PEAK** — base-rate anchoring maximally separable from narrative bias | **Mode A optimal zone** |
| T 45–90d | Good but declining | Mode B viable |
| T > 90d | High variance | **REJECT both modes** |

### Key Numbers

| Metric | Value |
|---|---|
| Metaculus Brier | **0.111** |
| Polymarket Brier | **0.187** |
| Calibration gap | **~40%** |
| Peak horizon | **14–45 days** |
| Annual qualifying events | **~30–100 (derived)** |
| N=30 horizon | **3–12 months** |
| Estimated systematic competitors | **< 20 globally** |
| Certainty ceiling | **hypothesis** (no direct WR study exists) |
| Realistic WR target | **55–65%** (derived from Brier gap) |

### Anti-Prim Escape Hatches (3 Formal)

- **(A)** Rolling 20 divergence events resolve in Metaculus direction < 55% → mechanism absent → anti-prim
- **(B)** Own-data 30 geopolitics trades WR < 52% → calibration convergence absent for this domain → anti-prim (domain)
- **(C)** < 10 qualifying events/year for 2 consecutive years → co-listing rate insufficient → anti-prim (frequency)

### Honest Ceiling

No peer-reviewed paper directly tests "Metaculus diverges ≥ 8% from PM → WR when betting Metaculus direction." The 55–65% target is analogical inference from the Brier gap, not measured. Sophisticated tier is earned by: mechanism quantified, failure modes documented, frequency model derived, competitive structure analyzed — not by proved trading performance. Certainty stays at **hypothesis** permanently until N≥30 own-data.

### Implementation Gaps (5, BLOCKING in sequence)

1. `src/classifiers/metaculus_pm_matcher.py` [BLOCKING ALL TRADES]
2. `src/signals/metaculus_feed.py` — tracked-forecaster subset via API
3. `src/strategies/superforecaster_lead.py` — 3-tier threshold + peaked horizon
4. `src/risk/antiprims.py` — three circuit-breakers
5. Tracked-forecaster quality proxy (Metaculus `track_record` field)

### Conditions Log Entry
- Works when: source-tiered divergence (GJP ≥ 8%; Metaculus tracked ≥ 10%; community ≥ 12%) in peak horizon 14–45d; divergence ≤ 48h; Metaculus update < 24h; ≥ 15% tracked-forecaster concentration (or ≥ 200 community); PM bid-ask ≥ 3%; geopolitics; no breaking news 12h; semantic equivalence confirmed
- Fails when: T < 7d (PM wins); T > 90d (high variance); community threshold without 14–30d horizon; tracked concentration < 15%; breaking news within 12h; semantic equivalence unconfirmed (metaculus_pm_matcher.py not yet built)
- Last validated: never

## Refinement History
- 2026-04-11 (cycle 39): Created as naive prim
- 2026-04-11 (cycle 40): Elevated to intermediate — two-mode signal (A/B), 7-day floor, Metaculus Brier 0.111 vs PM 0.187 quantified, 8 evidence sources, 2 formal anti-prims
- 2026-04-11 (cycle 41): Elevated to sophisticated — 3-tier source-quality thresholds (GJP/tracked/community), peaked calibration horizon curve (14–45d peak), signal frequency derived (~30–100/year), competitive moat characterized (< 20 systematic competitors), tracked-forecaster concentration gate (≥ 15%), 3 formal anti-prim escape hatches with exact thresholds
