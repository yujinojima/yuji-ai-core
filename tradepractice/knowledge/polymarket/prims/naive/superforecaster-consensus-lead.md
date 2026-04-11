---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T20:29:21+10:00
cycle: 39
---

---

## Prim: superforecaster-consensus-lead
**Level:** naive
**Project:** polymarket
**Parent:** none
**Commit:** `1a96b1c`

### Rule
When Metaculus community median OR Good Judgment Project superforecaster consensus diverges from Polymarket YES price by ≥ 8% on a semantically equivalent question, buy Polymarket in the direction of the calibrated-venue estimate. Size via fractional-kelly-sizing α=0.10 (mandatory floor — no calibration history).

### Mechanism
Two distinct forecaster populations process the same public information differently:

| Population | Incentive | Selection | Bias correction | Update rate |
|---|---|---|---|---|
| Polymarket traders | P&L maximisation | None | None | Seconds (financial) |
| GJP superforecasters | Brier score (log-prob) | Top 2% by track record | Active de-biasing training | Hours-to-days (deliberate) |

Score-incentivised forecasters apply base-rate anchoring and reference class forecasting; PM traders overweight recency and narrative. When populations diverge ≥ 8%, the calibrated population is more likely correct at 3–90 day resolution horizons.

**Why this is the 9th distinct prim class:**

| Prim | Signal source |
|---|---|
| binary-arb | Contractual ΣP=1 violation |
| spread-capture | Liquidity premium (maker quotes) |
| ensemble-forecast-edge | NWP physics models (GFS/ECMWF) |
| obi-informed-directional | CLOB microstructure (order flow imbalance) |
| fractional-kelly | Position sizing mathematics |
| cross-venue-semantic-arb | Cross-platform structural fragmentation |
| semantic-correlation | Intra-platform logical consistency |
| financial-market-lead-lag | Institutional derivatives data (CME FedWatch) |
| **superforecaster-consensus-lead** | **Calibrated human expert consensus** |

### Evidence
- **Source:** paper (adjacent; cross-PM application untested)
- **Certainty:** hypothesis
- **Data:**
  - Tetlock & Mellers (2015, Psychological Science): GJP superforecasters beat intelligence analysts with classified access by **30% Brier score reduction**; beat unfiltered forecasters by **60%**
  - Metaculus public calibration: p=0.70 resolves ~72% of the time; p=0.30 resolves ~28% (near-perfect calibration)
  - arxiv 2601.01706: 6% of 100k+ events co-listed across PM venues; persistent 2–4% deviations — mechanism is structurally analogous to cross-venue divergence but via quality-of-forecasters rather than fee structure
  - **No peer-reviewed paper directly tests Polymarket vs. Metaculus divergence as a trading signal** — hypothesis class
- **Citation:** Tetlock & Mellers (2015 Psych Sci); Mellers et al. (2015 Psych Sci); Metaculus calibration dashboard; Tetlock & Gardner "Superforecasting" (2015, Crown); Snowberg & Wolfers (2004, JEP); arxiv 2601.01706

### Conditions
- **Works when:** Divergence ≥ 8%; semantically equivalent question (same oracle, threshold, scope); PM liquidity $5k–$50k; resolution horizon 3–90 days; geopolitics/politics category; calibrated venue ≥ 100 predictors
- **Fails when:** Semantic non-fungibility (#1 failure mode); breaking news within 6h; PM liquidity > $50k (sophisticated PM-native participants have already priced in the same information); fee-negative category (weather 5%, crypto 7.2%); outside OECD geopolitics domain
- **Best pairs:** Geopolitical event markets — elections, crises, international negotiations
- **Best timeframe:** 3–90 day horizon; 6h polling cycle

### Limitations (8)
1. **Semantic non-fungibility (#1)** — same question ≠ same contract across platforms; manual review required per market; no automated matcher exists
2. **Metaculus update latency** — superforecasters update hours-to-days; PM prices update in seconds; fast-moving situations favour PM
3. **Convergence mechanism weak** — no contractual or mechanical force aligning PM to Metaculus; probabilistic only
4. **Superforecaster geographic concentration** — GJP/Metaculus calibrated on OECD geopolitics; calibration advantage may not extend to non-Western events
5. **PM liquidity paradox** — largest edge in low-liquidity PM markets where execution costs and slippage are highest
6. **No implementation** — Metaculus API (public, free) integration required
7. **Real-money vs score incentives** — contested; this prim bets on score-incentivised calibration — the fundamental assumption could be wrong
8. **8% threshold is arbitrary** — derived by analogy from financial-lead-lag; no empirical calibration

### Implementation
- **New file:** `src/strategies/superforecaster_lead.py`
- **New module:** `src/classifiers/metaculus_pm_matcher.py`
- **Key parameters:** `MIN_DIVERGENCE=0.08`, `MIN_PM_LIQUIDITY=5000`, `MIN_METACULUS_PREDICTORS=100`, `MAX_RESOLUTION_HORIZON_DAYS=90`

### Conditions Log Entry
- Works when: Divergence ≥ 8%; semantically equivalent; PM $5k–$50k; resolution 3–90d; geopolitics/politics; ≥ 100 Metaculus predictors
- Fails when: Semantic mismatch; breaking news; PM > $50k (sophisticated participants); fee-negative; groupthink on high-profile events
- Last validated: never

## Refinement History
- 2026-04-11 (cycle 39): Created as naive prim. 9th polymarket prim class. 6-source academic basis. Zero own-data.

---

### Prim Status — All 9 Polymarket Prims

| Prim | Level |
|------|-------|
| binary-arb-completeness | sophisticated |
| spread-capture-market-making | sophisticated |
| fractional-kelly-sizing | sophisticated |
| ensemble-forecast-edge | sophisticated |
| obi-informed-directional | sophisticated |
| cross-venue-semantic-arb | sophisticated |
| semantic-correlation-pair-trade | sophisticated |
| financial-market-lead-lag | sophisticated |
| **superforecaster-consensus-lead** | **naive ← this cycle** |

### Files Updated
- `knowledge/polymarket/prims/naive/superforecaster-consensus-lead.md` — created
- `knowledge/epistemic-index.md` — 9th polymarket naive row added
- `knowledge/conditions-log.md` — superforecaster-consensus-lead conditions appended

### Next Cycle Recommendations
1. **(A) RESEARCH: Elevate superforecaster-consensus-lead to intermediate** — find papers that directly test Metaculus/GJP prices vs prediction market prices; quantify historical Metaculus-vs-Polymarket divergence on co-listed geopolitical events; build semantic question matcher; determine optimal divergence threshold by question category and predictor count. Target: does calibration advantage persist at 3–7 day horizons where PM is most actively traded?
2. **(B) IMPLEMENT: fomc_pm_mapper.py** — the BLOCKING dependency for financial-market-lead-lag sophisticated (only prim with zero own-data and a BLOCKING implementation gate). Historical Polymarket Fed questions available from Gamma API. Bounded work: 20 labeled questions unlocks first live trade.
3. **(C) BACKTEST-ANALYSIS: hidden-bullish-rsi-divergence escape hatch B confirmation** — 28-cell plateau test required to confirm or deny the anti-prim precursor (WR 30% n=10 from cycle 37). If plateau also fails → definitive anti-prim; one data point eliminates a prim from the bank.
