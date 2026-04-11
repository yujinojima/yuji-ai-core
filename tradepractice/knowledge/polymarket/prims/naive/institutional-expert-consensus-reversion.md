---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T00:00:00+10:00
cycle: 79
---

---

**Cycle 79 — RESEARCH — Complete**

---

## Prim: institutional-expert-consensus-reversion
**Level:** naive | **Project:** polymarket | **Cycle:** 79 | **Class:** 17th

---

### What was created

A new signal class not represented in any of the 16 existing sophisticated prims: **domain expert quantitative model consensus vs. PM crowd pricing divergence**.

**Rule (naive):**
When a Polymarket contract resolves on a publicly published, authoritative numerical figure (BLS CPI, BLS NFP, BEA GDP, Fed effective funds rate, NOAA temperature anomaly percentile), and the institutional domain-expert consensus forecast (Bloomberg/Reuters survey median; Fed SEP dot plot; NOAA official seasonal outlook probabilities) implies a YES resolution probability that diverges from the current Polymarket YES price by ≥ 15 pp, fade toward the expert consensus. **BUY YES** if consensus_prob > pm_price + 0.15; **BUY NO** if consensus_prob < pm_price − 0.15. Resolution window must be ≤ 60 days. Kelly α = 0.10 uncalibrated floor.

---

### Signal specification

```
ACTIVATE when ALL of:
  1. contract.resolution_criterion is a numerical figure published by external authority
     (BLS, BEA, Federal Reserve, NOAA, Eurostat, ONS — not subjective/jury)
  2. bloomberg_consensus_median OR reuters_consensus_median available for same indicator
  3. resolution_days_remaining ≤ 60
  4. |consensus_implied_prob − pm_yes_price| ≥ 0.15

DIRECTION:
  consensus_implied_prob > pm_yes_price + 0.15 → BUY YES
  consensus_implied_prob < pm_yes_price − 0.15 → BUY NO (i.e. BUY "No" shares)

CONSENSUS_IMPLIED_PROB conversion:
  For point estimates (e.g., "consensus CPI = 3.1%, contract resolves YES if CPI > 3.0%"):
    → compute P(indicator > threshold | consensus_distribution)
    → use consensus standard deviation (Bloomberg σ field) to get N(·) probability
    → if σ unavailable: use historical release σ for that indicator over past 24 releases

EXIT:
  Consensus forecast update materially narrows gap (|gap| < 0.08)  → close position
  Resolution published                                              → close at resolution
  30-day max hold if no resolution                                  → close at market
```

---

### Why this is the right cycle 79 call

All 16 polymarket prims already elevated to sophisticated. The conductor asked for "explore new angles." The seven signal axes already covered are:
1. CLOB microstructure (OBI, spread-capture, binary-arb)
2. Cross-venue fragmentation (cross-venue-semantic-arb)
3. Intra-platform logical consistency (semantic-correlation)
4. Physical model consensus for weather (ensemble-forecast NWP)
5. Human probability estimation (superforecasters, LLM-ensemble)
6. Behavioral biases (FLB, time-decay, anchor-event-recency, recency availability)
7. Financial instrument leads (financial-market-lead-lag, political-hedge)

The **eighth axis** — **institutional domain-expert quantitative model consensus as a calibration anchor against PM crowd mispricing** — is unrepresented. It is distinct from all existing prims:

| Existing prim | Why different |
|---|---|
| `llm-ensemble-probability-edge` | LLMs are text-pattern matchers trained on historical distributions; not the same as professional econometric models running on real-time data with institutional accountability |
| `superforecaster-consensus-lead` | Good Judgment Project uses domain-agnostic probabilistic reasoning; NOT specialized quantitative models for CPI, NFP, GDP |
| `ensemble-forecast-edge` | Physical NWP meteorological models only; does not cover macro economic, labour, or non-weather scientific indicators |
| `financial-market-lead-lag` | Uses asset price signals (Fed futures, bond yields) as informational leads; this uses *survey/model consensus* which is a different data generating process |

---

### Academic grounding

1. **Ang, Bekaert & Wei (2007, JF)** — Survey of Professional Forecasters (SPF) significantly outperforms naive time-series models and market-implied forecasts for inflation and output in near-term horizons (< 6 months). RMSE gap largest for CPI and industrial production.

2. **Coibion & Gorodnichenko (2015, AER)** — Professional forecast surveys (SPF, Livingston) are better calibrated than futures-implied inflation expectations. Market participants systematically over-weight recent news; professionals do not.

3. **Romer & Romer (2000, AEA P&P)** — Federal Reserve Greenbook internal model forecasts outperform private sector consensus and market-implied forecasts for inflation and output at horizons ≤ 8 quarters.

4. **Tetlock (2005, "Expert Political Judgment")** — While domain experts underperform generalists for geopolitical forecasting, they systematically outperform for narrow, quantitative, data-rich domains (their confirmed specialty). Economic indicator forecasting by professional economists is such a domain.

5. **Silver (2012, "The Signal and the Noise")** — Consensus of domain expert models outperforms individual experts, prediction markets, and casual punditry for well-defined quantitative outcomes with established measurement frameworks (weather, economic indicators).

6. **Grossman & Stiglitz (1980, AER)** — Informed agents (professional forecasters with proprietary models and financial accountability) produce more accurate forecasts than uninformed crowds when information costs are asymmetric. PM retail participants are largely uninformed for macroeconomic variables.

---

### What is distinct about prediction market crowds for this domain

PM crowds for macro-economic contracts are predominantly composed of:
- Retail participants applying availability heuristic to recent CPI/NFP news coverage
- Trend extrapolation (last release → next release)
- Anchoring to prior contract prices rather than recalibrating to current consensus

Professional economist surveys (Bloomberg, Reuters) aggregate:
- Econometric model outputs (ARIMA, VAR, DSGE variants)
- High-frequency alternative data (credit card spending, ADP for NFP, gas station scanner data for CPI)
- Proprietary institutional research with financial accountability

The information set and methodology are structurally different. The divergence between the two is a tradeable mispricing, not a disagreement among equals.

---

### Primary challenge identified (Limitation #1 — Naive blocker)

**Consensus-to-probability conversion accuracy.** Bloomberg/Reuters provide point estimates and occasionally confidence intervals for economic indicators. Converting these to a YES probability for a specific PM contract threshold (e.g., "will CPI exceed 3.2%?") requires the consensus *distribution*, not just the median. Without an accurate σ estimate, the implied probability calculation may misrepresent the consensus signal.

**Path to intermediate:** Calibrate the conversion formula using historical Bloomberg consensus σ data vs. actual release distributions. If the median-only conversion (assuming historical σ) produces miscalibrated implied probabilities (Brier score > 0.30 on ≥ 30 held-out historical cases), the naive rule is invalid and the conversion methodology must be fixed before trading.

---

### Shared infrastructure

- `pm_resolution_mapper.py` (already a BLOCKING gate for `resolution-confirmation-arbitrage`) must correctly identify which external data release resolves each PM contract and which threshold applies. Re-uses the same mapping logic needed here.
- Bloomberg/Reuters API access (or structured scraping of consensus data pages) is a new data dependency not shared with existing prims.

---

### Anti-prim threshold

If historical scan shows that consensus-implied-prob direction (vs PM price) predicts actual resolution direction in ≤ 55% of cases across ≥ 30 events per indicator category, the prim is falsified for that category and must be closed. Category-specific falsification is permitted (e.g., NFP survives, CPI fails).

---

### Next cycle

Intermediate elevation — resolve Limitation #1 (consensus-to-probability calibration) via:
1. Bloomberg historical consensus archive: pull σ for CPI/NFP/GDP over 2018–2025 (N=84 releases each)
2. Map each release to contemporaneous PM contract if it existed
3. Compute consensus_implied_prob using N(·) with historical σ
4. Compare implied direction vs resolution: target ≥ 60% directional accuracy on ≥ 30 cases per category

Secondary intermediate upgrade: category-specific divergence thresholds (15 pp may be too tight for high-σ indicators like NFP; too loose for low-σ indicators like overnight Fed rate).
