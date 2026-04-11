---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T08:46:40+10:00
cycle: 76
---

---

**Cycle 76 — RESEARCH — Complete**

---

## Prim: anchor-event-recency-bias-fade
**Level:** intermediate | **Elevated from:** naive (cycle 75) | **Project:** polymarket

---

### What was resolved

**Naive blocker (information vs bias confound) resolved** via a two-mode structure with external condition-stability gates:

**Mode A — Natural Disaster (low confound)**
GDELT > 1,000/48h + anchor surprises PM (≥55% prior) + same natural-disaster category + target YES spike ≥ 8pp/5d + **geographic distance > 500km** + **NOAA < MODERATE + USGS < 4.5** at target location (72h) + YES ∈ [0.15, 0.50] + resolution > 14d → **BUY NO**, 10-day max hold, α=0.10

**Mode B — Political Violence / Electoral (moderate confound)**
Same salience/surprise gates + YES spike ≥ 12pp/3d + **ACLED delta < +20%** + **distinct primary_actor AND conflict_system_id** + YES ∈ [0.15, 0.55] + resolution > 21d → **BUY NO at 0.75× size**, 7-day max hold, α=0.08

The gates are observable pre-trade. If underlying conditions are unchanged → price spike is cognitive availability contamination, not information.

---

### New anchors at intermediate

| Source | Contribution |
|--------|-------------|
| Gennaioli & Shleifer (2010 QJE) | Salience theory — bias is systematic and directional, not random noise |
| Eisensee & Strömberg (2007 QJE) | Media cycle decay → Mode A 10d / Mode B 7d hold windows |
| Kunreuther et al. (1978) | Insurance demand +100–200% in zero-risk regions → ~3–6pp PM overpricing at YES=0.20 |
| Palm (1995) | +30% earthquake insurance in non-epicentre counties (independent replication) |

### What remains for sophisticated

1. N_eff Kelly adjustment for concurrent anchor events (≥ 2 in same category/14d)
2. Mode-specific GDELT salience quantile calibration (1,000 article threshold → verify 90th percentile per category)
3. Entity-category NLP classifier precision/recall evaluation
4. Salience asymmetry gate (low-frequency high-severity anchors may produce stronger fades than high-frequency moderate-severity — Gennaioli-Shleifer prediction)

**Bank state:** naive 9→8 | intermediate 13→**14** | sophisticated 15
