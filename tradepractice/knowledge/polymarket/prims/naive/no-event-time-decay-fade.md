---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T23:31:48+10:00
cycle: 48
---

All three files written. Here is the cycle 48 output:

---

## Prim: no-event-time-decay-fade
**Level:** naive  
**Project:** polymarket  
**Class:** 11th polymarket prim — first temporal trajectory mechanism

---

### Rule

```
YES > actuarial_yes(λ_cat, days_remaining) × 1.30
AND days_remaining < 21
AND no positive YES catalyst in last 72h
→ BUY NO. α=0.10 Kelly.

actuarial_yes(λ, T) = 1 - exp(-λ × T)
```

Initial λ lookup (requires empirical calibration before deployment):

| Category | λ/day |
|----------|-------|
| geopolitics_military | 0.003 |
| legislative_passage | 0.005 |
| executive_action | 0.008 |
| diplomatic_agreement | 0.002 |

---

### Mechanism

Binary PM contracts are equivalent to binary call options. For Poisson-process events, fair YES = 1 − exp(−λ × T), which decays monotonically toward zero as days_remaining shrinks. Traders who set or bought YES early in a contract's life **anchor** to that original price and fail to adjust it downward as time passes without event occurrence (Kahneman & Tversky 1974). The actuarial fair value decays; the market price does not.

**Distinction from FLB:**

| | FLB Fade | Time-Decay Fade |
|-|----------|-----------------|
| Mechanism | Static probability weighting distortion | Dynamic: anchoring blocks temporal decay |
| Region | YES < 0.07 any horizon | YES 0.05–0.35 final ≤21 days |
| Variable | Current YES level | YES / actuarial_fair(λ, T) ratio |

The two prims are non-overlapping. FLB fires on the probability level; time-decay fires on the trajectory.

---

### Blocking Validation

`gamma_calibration_scan()` against PM resolved markets: bin YES prices at final-14-days snapshot into 0.05–0.15 / 0.15–0.25 / 0.25–0.35 buckets. Pass = overpricing_ratio ≥ 1.30 in ≥ 2 buckets (n ≥ 20 each). **This scan and λ calibration must both pass before any capital deployment.**

---

### Files written

- `knowledge/polymarket/prims/naive/no-event-time-decay-fade.md` — full prim
- `knowledge/epistemic-index.md` — new row appended to Polymarket Naive table
- `knowledge/conditions-log.md` — full conditions entry appended
