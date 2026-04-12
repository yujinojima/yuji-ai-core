---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T15:01:24+10:00
cycle: 96
---

---

**Cycle 96 — RESEARCH — Complete**

---

## Prim: low-friction-venue-lead
**Elevation:** naive → intermediate | **Project:** polymarket | **Cycle:** 96

---

### What was produced

The naive prim (cycle 95) established the signal concept: behavioral anchoring lag between low/zero-capital-risk prediction venues and Polymarket. The intermediate tier adds the two-mode architecture with venue-specific friction quantification.

### Key intermediate upgrades

**Two-mode split** (single-venue naive → venue-specific intermediate):

| | Mode A — Manifold | Mode B — PredictIt |
|---|---|---|
| Gap threshold | 10 pp (play-money noise floor) | 8 pp (real-money precision) |
| Divergence age | ≤ 6h | ≤ 12h ($850 cap slows gap closure) |
| PM liquidity | $5k–$50k only | $15k–$200k |
| Categories | elections/politics/geopolitics | elections/economics/US politics |
| Exit gap | 3 pp / 48h max | 4 pp / 96h max |

**Capital friction model quantified:**
- Manifold: ≈0% friction → zero loss aversion → fastest updater; high noise rate → needs larger gap
- PredictIt: ≈0.50% round-trip + $850 cap → financially incentivised signal at lower threshold, but structurally cannot close PM gaps alone (position size too small)
- PM: ≈2% on wins → participants resist updating even when aware of the divergence

**H_G protocol** (decisive gate, analogous to H_L in perp-spot-basis): Granger causality test on historical Manifold vs PM time series (N≥50 political events, 2022–2025). Mode A requires Manifold leads in ≥60% of directional moves; Mode B requires PredictIt leads in ≥55%. Failure of either mode → that mode is anti-prim.

**Anti-prim escape hatches** (three per convention):
- A: H_G fails (direction inverted)
- B: No mode WR > 50% in N≥30 IS backtest
- C: Live WR < 45% after 30 combined trades

**3 academic anchors added** at intermediate (vs 6 at naive): Atanasov et al. 2016 *Management Science* (real vs play-money prediction accuracy), Budescu & Chen 2015 *Management Science* (financial incentive filters noise — Mode B mechanism), Cowgill & Zitzewitz 2015 *ReStat* (information transmission speed in incentivised vs non-incentivised markets).

### Blocking for sophisticated (G1–G3)

1. **G1 H_G test** — Granger causality data pull; Manifold API + PM Gamma historical data; most tractable DATA prerequisite
2. **G2 semantic matcher** — `low_friction_pm_matcher.py`; reuses `metaculus_pm_matcher.py` pattern; precision ≥ 0.85 at N=50 labeled pairs
3. **G3 IS backtest** — after G1+G2; WR ≥ 55% or median gap closure ≥ 6 pp per mode

### Bank state after cycle 96

| Level | Freqtrade | Polymarket | Total |
|---|---|---|---|
| Naive superseded | 12 | 18 | 30 |
| Naive active | 0 | 0 | 0 |
| Intermediate active | 1 (perp-spot-basis) | 1 (low-friction-venue-lead) | **2** |
| Sophisticated active | 10 + 1 anti-prim | 17 | **28** |

### Next cycle recommendations

**(A) DATA — G1 H_G test:** Pull Manifold API historical prices for N≥50 political events co-listed on PM; align with PM Gamma data; run directional lead-time analysis. Answers the decisive prim-vs-anti-prim question. Cheapest executable gate.

**(B) BUILD — `low_friction_pm_matcher.py`:** Reuse `metaculus_pm_matcher.py` architecture; add oracle-class detection; test on 50 manually labeled pairs. Parallelizable with G1.

**(C) RESEARCH — perp-spot-basis-divergence H_L test:** Remains highest-value freqtrade deliverable. Analytical formalisation of H_L sample size requirements (N_eff for median test; ~4–5 years BTC data for N≥20 Tier A events) is a RESEARCH cycle deliverable even without the data pull.

**(D) BACKTEST — VWAP re-test:** `YujiVWAPMeanReversionStrategy` cycle 63 rules + CVD gate; n≥100, WR≥55%, Sharpe≥0.70; independent of all above.
