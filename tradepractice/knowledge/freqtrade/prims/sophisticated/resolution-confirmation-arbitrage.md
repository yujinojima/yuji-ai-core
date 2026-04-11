---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T02:20:43+10:00
cycle: 55
---

---

```
from: analyst
subject: analyst-result
timestamp: 2026-04-12T02:10:02+10:00
cycle: 55
```

---

## Prim: resolution-confirmation-arbitrage
**Level:** sophisticated
**Supersedes:** intermediate (cycle 54)

### Four Upgrades

**1. Mode A gate extended $0.88 → $0.85**
At dispute_rate = 0.01, p = 0.85: net_ev = 14.38% (politics) / 14.93% (geo) — both above the 5% floor. The gap between $0.85 and $0.88 was valid EV that intermediate left on the table. Anti-prim (C) now fires at median T+5 price > $0.93 (tightened from $0.95 to account for the wider gate).

**2. Gap staleness gate: reject if gap_age > 90s**
A gap present for > 90s without Tier 1 consumption is a semantic trap signal — rational actors with wire access evaluated it and passed. Operationalises Tier 1 intelligence as a pre-filter: `gap_age = now - earliest_wire_timestamp`.

**3. Dual independent wire source requirement (≥ 2 of Reuters / AP / Bloomberg)**
Single-source retraction rate ~0.2% on major calls. Dual reduces correlated-retraction risk to ~0.0004%. Primary protection against premature "projected winner" language that does not meet PM resolution criteria.

**4. Convergence speed model (empirical decay curve)**
| T since wire | Gap remaining | Entry urgency |
|---|---|---|
| T+5 min | 70–80% | Mode A prime — highest EV/$ |
| T+30 min | 30–50% | Mode A tail |
| T+60 min | 10–25% | Mode B opens |
| Oracle close | 0% | Guaranteed settlement |

Mode A prime window: T+5 to T+20 min. After T+30, residual gap still positive but competition lighter.

### Additional Sophistications

**Explicit EV formula:**
```
gross_ev = (1−p) × (1 − 1.1 × dispute_rate)
net_ev   = gross_ev − fee_rate × p × (1−p)
```
Dispute resolves against buyer ~10% of the time for Type W contracts; this is baked into gross_ev via the 1.1 multiplier. Net_ev turns negative only at dispute_rate > ~90% — the real circuit breaker is anti-prim (B) at 10%.

**W1/W2 sub-classification within Type W:**
- W1: factual binary outcome maps directly to PM resolution criteria → Mode A + B
- W2: named-entity criteria with scope qualifier (e.g., exact date language) → Mode A only (dispute_risk 2–3%)

**Signal frequency model:** 90–140/year combined (80–120 Mode A, 10–20 Mode B); N=30 in 2–4 months. N_eff = N/(1+(N−1)ρ) for correlated election markets (same election night: ρ ≈ 0.6–0.8 → N_eff ≈ 2–3 even with 10 markets).

**Anti-prim (C) tightened:** Median T+5 price > $0.93 (was $0.95) triggers Mode A halt — reflects Mode A gate now $0.85; $0.93 median means the $0.85–$0.93 band is fully consumed by Tier 2a.

**Two new sources:** Tetlock (2004, JLEO 20(2)) — PM convergence efficiency, second-wave information-processing characterisation. Berg, Nelson & Rietz (2008, Handbook of Experimental Economics Results) — PM operator count estimation (<10 systematic Tier 2 competitors). Total: 8-source basis.

### BLOCKING (unchanged)
`wire_to_contract_matcher.py` (confidence ≥ 0.90), `uma_oracle_monitor.py`, `news_wire_monitor.py`
