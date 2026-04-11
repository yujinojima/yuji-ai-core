---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T18:15:33+10:00
cycle: 34
---

Commit `34b6ae1`.

---

## Prim: semantic-correlation-pair-trade
**Level:** intermediate (elevated from naive in same cycle — academic evidence sufficient)
**Project:** polymarket
**Parent:** none (new prim class)

### Rule
Identify two Polymarket contracts with embedding similarity ≥ 0.82 and a verifiable logical relationship (Implication / Positive Correlation / Temporal Chain / Anti-correlation). If the observed price of the lagging contract deviates from the implied constraint by > `fee_rate × p(1−p) + 0.015 + 0.030`, enter long on the underpriced market. Exit when deviation narrows to < 1.5%, either market resolves, or 14 days elapsed.

### Mechanism
Polymarket participants trade each contract in isolated information silos. No current bot infrastructure enforces intra-platform price consistency across non-exhaustive correlated pairs. Casual bettors specialised in one market do not simultaneously monitor semantically related markets, creating transient divergences beyond the friction floor. Unlike `binary-arb-completeness`, there is no contractual ΣP = $1 guarantee — convergence is probabilistic (driven by shared information eventually reaching both markets) not mechanical.

### Why This Is the 7th Distinct Prim

| Prim | Mechanism | Risk | Capital |
|---|---|---|---|
| binary-arb | Contractual ΣP=1 violated | Near-zero at resolution | Single venue, bilateral YES+NO |
| spread-capture | Liquidity premium | Inventory risk | Single venue, maker quotes |
| ensemble-forecast | NWP information asymmetry | WR-dependent | Single market directional |
| obi-informed-directional | CLOB order flow imbalance | Directional | Single market |
| cross-venue-semantic-arb | Cross-platform structural fragmentation | Semantic non-fungibility | Bilateral capital (USDC/USD) |
| fractional-kelly-sizing | Sizing meta-prim | — | All prims |
| **semantic-correlation-pair-trade** | **Intra-platform logical consistency divergence** | **Correlation breakdown** | **Single venue, single market** |

### Dynamic Friction Floor

| Category | Floor at p=0.50 |
|---|---|
| Geopolitics (0% fee) | **4.5%** |
| Politics/Finance (4% fee) | **5.5%** |
| Sports (3% fee) | **5.25%** |
| Weather (5% fee) | **5.75%** |

Structural advantage over cross-venue-semantic-arb: same friction floor class, but no bilateral capital lockup, no ZeroHash bridge, no Rule 6.3(c) ambiguous settlement risk.

### 4-Class Relationship Taxonomy

| Class | Constraint | Clearest Signal |
|---|---|---|
| **1 — Implication** | `P(B) ≥ P(A) × P(B|A)` | "Wins primary" → "wins general" |
| **2 — Positive Correlation** | `ΔP(A)` without `ΔP(B)` exceeds correlation-adjusted expectation | Same electoral-wave driver |
| **3 — Temporal Chain** | `P(event by Tn) ≥ P(event by T1)` where T1 < Tn | "Fed cuts by Q1" vs "Fed cuts by Q3" |
| **4 — Anti-correlation (non-exhaustive)** | `P(A) + P(B) < 0.99` AND one moves without the other | Competing candidates, no exhaustive sum |

Class 3 temporal chain is mechanistically the cleanest — the constraint is mathematical, not prior-dependent. First backtest target.

### Evidence
- **Source:** paper (arxiv 2512.02436, IBM+Columbia, Dec 2025)
- **Certainty:** hypothesis
- **Data:** 60–70% relationship detection accuracy; ~20% average return per week-long horizon (simulation); zero own-data trades
- **Citation:** [arxiv 2512.02436 — Semantic Trading: Agentic AI for Clustering and Relationship Discovery in Prediction Markets](https://arxiv.org/abs/2512.02436)

### Limitations (7)
1. **Convergence not guaranteed** — no contractual mechanism; can diverge further or never close before resolution
2. **~20% return from simulation** — not live trading with real fees, real liquidity, real slippage; estimated net: 12–15% after friction
3. **Classifier accuracy 60–70%** — 30–40% error rate on borderline pairs; 3% safety buffer partially covers
4. **P(B|A) prior required for Class 1** — historical election data needed; wrong prior → wrong implied constraint → false signal
5. **Portfolio correlation adjustment mandatory** — two positions in same causal cluster have ρ ≈ 0.80 → N_eff ≈ 1.1 → effectively one position; Kelly must apply N_eff from fractional-kelly-sizing sophisticated
6. **Asymmetric news detection absent** — price movement in A may BE new information, not a divergence; OBI signal at movement time is a partial proxy
7. **No implementation** — `src/strategies/correlated_pair_trade.py` does not exist; reuses `src/classifiers/semantic_risk.py` for oracle veto only

### Implementation
- **New file:** `src/strategies/correlated_pair_trade.py`
- **New module:** `src/classifiers/relationship_type.py` — `RelationshipClassifier.classify(pm_text_a, pm_text_b, price_a, price_b) → (class_id, violation_pp, implied_price)`
- **Reuses:** `src/classifiers/semantic_risk.py` (Type A/B/D oracle veto), `src/risk/kelly.py`
- **BLOCKING:** 20 Class 1 implication pairs with known resolution outcomes for P(B|A) prior calibration

### Conditions Log Entry
- Works when: Class 1/3 (clearest constraints); embedding ≥ 0.82; constraint violated > `fee_rate×p(1−p)+0.015+0.03`; both liquid ≥ $5k; resolution within 14d of each other; not exhaustive-sum; no Type B oracle divergence
- Fails when: Criterion-specification divergence within Polymarket (same topic, different thresholds); asymmetric news as divergence source; illiquid lagging market; exhaustive-sum pair (binary-arb is correct prim)
- Last validated: never

---

### Prim Status — All 7 Polymarket Prims

| Prim | Level |
|------|-------|
| binary-arb-completeness | sophisticated |
| spread-capture-market-making | sophisticated |
| fractional-kelly-sizing | sophisticated |
| ensemble-forecast-edge | sophisticated |
| obi-informed-directional | sophisticated |
| cross-venue-semantic-arb | sophisticated |
| **semantic-correlation-pair-trade** | **intermediate ← this cycle** |

### Next Cycle Recommendations
1. **(A) RESEARCH: Elevate semantic-correlation-pair-trade to sophisticated** — find historical Polymarket Class 3 temporal chain pairs (e.g., "Fed cuts by Q1 2026" / "Fed cuts by H1 2026" — mechanically clean, mathematical constraint); scan for documented instances where temporal chain constraint was violated; calibrate Class 3 P(B|A) = 1.0 (deterministic) → no prior needed → cleanest first backtest path
2. **(B) BACKTEST-ANALYSIS: Class 3 temporal chain scanner** — identify any current/recent Polymarket temporal chain pairs where P(Tn) < P(T1); document constraint violations historically; estimate convergence rate and hold horizon
3. **(C) RESEARCH: Asymmetric news classifier for Class 2** — the primary implementation blocker for Class 2 positive correlation; OBI prim's IR signal can distinguish "information-driven" (balanced CLOB → news catalyst) from "divergence-driven" (imbalanced CLOB → correlation gap) price movements in Market A
