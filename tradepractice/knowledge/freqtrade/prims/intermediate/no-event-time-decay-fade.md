---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T23:41:56+10:00
cycle: 49
---

---

## Prim: no-event-time-decay-fade
**Level:** intermediate (refined from naive)
**Project:** polymarket
**Parent:** naive/no-event-time-decay-fade (cycle 48)

---

### What changed from naive

| Dimension | Naive | Intermediate |
|-----------|-------|-------------|
| Signal structure | Single threshold (ratio ≥ 1.30, T ≤ 21d) | **Two-mode**: Mode A (≥1.50, T≤14d) + Mode B (≥1.30, T≤21d) |
| YES lower bound | 0.05 (informal) | **0.08 hard boundary** — below = FLB territory |
| Scheduled event guard | None | **Keyword veto** (vote on / election on / scheduled meeting / etc.) |
| Catalyst definition | "no positive catalyst 72h" | **Velocity gate**: ≥ 2 articles in 72h OR any wire/agency item |
| λ methodology | "requires empirical calibration" | **MLE pipeline formalised**: Gamma API cohorts, n≥50, RMSE≤0.02 |
| Sources | 5 | **7** (+Snowberg & Wolfers 2010 AER, Ottaviani & Sørensen 2008 JFE, Thaler & Ziemba 1988 JEP, Wolfers & Zitzewitz 2006 NBER) |
| Anti-prims | 3 (A/B/C) | **4** (+D: frequency collapse) |
| Signal frequency | unstated | **20–50/year; N=30 in 8–18 months** |
| Calibration gate n | 20/bucket | **50/bucket** (raised) |

### Key mechanism addition at intermediate

The Ottaviani-Sørensen (2008) layer explains *why* YES 0.08–0.35 is the exploitable range specifically:

- Below 0.08: subeconomic return barrier shuts out professional arb ($0.05–0.08/contract) → FLB prim owns this zone
- Above 0.08: per-contract NO return ≥ $0.65 → professional arb *could* enter → but cognitive anchoring prevents retail participants from decaying YES fast enough → the overpricing persists through the T≤21 window before professionals act

This is the precise niche: large enough return to attract arb in theory, but the decay happens faster than the arb cycle. The intermediate prim captures the window.

### Files written

- `knowledge/polymarket/prims/intermediate/no-event-time-decay-fade.md` — full intermediate prim
- `knowledge/epistemic-index.md` — naive row marked SUPERSEDED; intermediate row added to Intermediate table
- `knowledge/conditions-log.md` — naive entry marked [historical — superseded by intermediate, cycle 49]; intermediate conditions entry appended
