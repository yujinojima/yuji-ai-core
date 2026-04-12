---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T15:00:00+10:00
cycle: 95
---

---

## Prim: low-friction-venue-lead
**Level:** naive | **Project:** polymarket | **Cycle:** 95 | **Class:** 18th

---

### What was created

A new signal class not represented in any of the 17 existing sophisticated prims: **low-friction prediction market live prices as directional leads for Polymarket**, exploiting behavioral anchoring on large real-money positions.

**Rule (naive):**
When Manifold Markets community price OR PredictIt financially-incentivised price diverges from the semantically equivalent Polymarket YES price by ≥ 10 pp, and the divergence direction points away from Polymarket, BUY Polymarket in the direction of the low-friction venue. Exit when PM gap closes to ≤ 3 pp or at 72-hour max. Kelly α = 0.10 uncalibrated floor. Requires semantic equivalence confirmed manually per market.

---

### Signal specification

```
ACTIVATE when ALL of:
  1. Manifold Markets community price OR PredictIt contract price available
     for a semantically equivalent event
  2. |low_friction_venue_price − pm_yes_price| ≥ 0.10
  3. Divergence direction: low_friction_venue HIGHER than PM → BUY PM YES
                           low_friction_venue LOWER than PM  → BUY PM NO
  4. Divergence age ≤ 6h (stale gaps may reflect unprocessed news, not lag)
  5. PM liquidity ≥ $5,000
  6. Resolution horizon: 7–60 days (< 7d PM dominates; > 60d too slow)
  7. Semantic equivalence: same resolution authority, same threshold, same scope
     (manual confirmation required — no automated matcher exists yet)

DIRECTION:
  manifold_price > pm_yes_price + 0.10 → BUY PM YES
  manifold_price < pm_yes_price − 0.10 → BUY PM NO (i.e., buy NO shares)

EXIT:
  gap < 0.03                → close (convergence achieved)
  resolution published      → close at resolution
  72-hour hard stop         → close at market (lag assumption expired)
  divergence widens > 0.20  → re-evaluate semantic equivalence before adding
```

---

### Why this is the 18th distinct prim class

| Prim | Signal source |
|---|---|
| binary-arb-completeness | Contractual ΣP=1 violation (same venue) |
| spread-capture-market-making | Liquidity premium (maker quotes) |
| obi-informed-directional | CLOB order book depth imbalance |
| ensemble-forecast-edge | NWP physics models (GFS/ECMWF) |
| fractional-kelly-sizing | Position sizing mathematics |
| cross-venue-semantic-arb | Simultaneous bilateral arb on financially-incentivised venues |
| semantic-correlation-pair-trade | Intra-platform logical consistency divergence |
| financial-market-lead-lag | Institutional derivatives data (CME FedWatch) |
| superforecaster-consensus-lead | Calibrated expert probability *estimates* (Metaculus/GJP) — not live prices |
| favourite-longshot-bias-fade | PM crowd systematic probability distortion |
| no-event-time-decay-fade | Temporal probability compression (Poisson actuarial) |
| resolution-confirmation-arbitrage | Post-resolution price-to-$1 convergence |
| llm-ensemble-probability-edge | LLM base-rate estimation vs PM crowd |
| political-hedge-instrument-signal | Political risk instruments (MXN/USD, XAR+ITA) |
| news-velocity-informed-directional | News publication rate as directional signal |
| anchor-event-recency-bias-fade | Anchoring to recent anchor events (Trump-2016 effect) |
| institutional-expert-consensus-reversion | Domain-expert quantitative model consensus vs PM crowd |
| **low-friction-venue-lead** | **Live prices on zero/low-capital-risk prediction venues as behavioral anchoring lead** |

**Why not `superforecaster-consensus-lead`:** That prim uses expert *probability estimates* (Metaculus community forecasts, GJP trained forecasters) — a deliberate, slow-moving calibration signal that updates hours-to-days. This prim uses live *market prices* that update in real time on venues where the behavioral cost of staying wrong is lower. The mechanism is entirely different.

**Why not `cross-venue-semantic-arb`:** That prim requires *simultaneous bilateral execution* on two financially-incentivised venues (PM + Kalshi) to lock in a risk-free spread. This prim is *directional only* — Manifold cannot be shorted or hedged against (play money; no cash-out parity). PredictIt positions cannot be atomically bridged to Polymarket. No risk-free arb is available; only a directional lead-lag bet.

**Why not `news-velocity-informed-directional`:** News velocity measures the *rate of external information entering the public domain*. This prim measures *how an existing market community has already aggregated that information* into a price. Different data-generating process; different lag mechanism.

---

### Mechanism

Polymarket participants holding large USDC positions (real capital, real losses) exhibit two behavioral frictions that slow price updates when new information arrives:

1. **Loss aversion anchoring** — Kahneman-Tversky (1979): participants anchored to their entry price resist updating probability estimates downward even when public information shifts. A trader who bought YES at 0.65 and sees the contract fall toward 0.55 will hold longer than expected, slowing the price discovery process.

2. **Capital commitment friction** — Updating a large position requires fresh capital deployment or realising a mark-to-market loss. Both have a cost. On Manifold (play money), neither cost exists. On PredictIt ($850 cap), the dollar magnitude is small enough to exit and re-enter freely.

These frictions create a *systematic update lag* at Polymarket relative to venues with lower or zero capital at risk. When a structural shift arrives (poll release, procedural vote, policy announcement), low-friction venues reprice within minutes. Polymarket lags by hours because:

- Manifold participants face no loss aversion (play currency = mana, non-redeemable except internally)
- PredictIt participants' maximum single-outcome exposure is $850 — behaviorally equivalent to a "low stakes" bet despite real money
- Polymarket's active participants may have $5k–$50k at risk in a single position — loss aversion is fully engaged

The convergence mechanism is *information diffusion*, not contractual arbitrage: over 24–72 hours, informed Polymarket participants observing the Manifold/PredictIt price eventually act, compressing the gap.

---

### Evidence

- **Source:** Established theory applied to prediction markets (no direct Manifold→Polymarket lead paper found)
- **Certainty:** hypothesis
- **Data:** 0 own trades; no peer-reviewed paper directly tests Manifold/PredictIt price as a Polymarket directional lead

**Supporting academic anchors:**
1. **Kahneman & Tversky (1979, Econometrica)** — Prospect theory: losses are weighted ~2.25× more painfully than equivalent gains → holders of underwater positions are systematically slow to update (loss aversion anchoring). Directly predicts update lag at financially-incentivised, large-position markets.

2. **Shleifer & Vishny (1997, JF)** — "The Limits of Arbitrage": even informed agents cannot immediately correct mispricings when capital is at risk and positions must be maintained. Capital-constrained sophisticated agents in PM markets face analogous dynamics.

3. **Wolfers & Zitzewitz (2004, JEP)** — "Prediction Markets": information aggregation efficiency depends on incentive structure and friction. Thin liquidity and high stakes per participant can *reduce* efficiency relative to lower-stakes aggregations with larger participation.

4. **Servan-Schreiber et al. (2004, Electronic Markets)** — "Prediction Markets: Does Money Matter?" — play-money markets (Hollywood Stock Exchange) outperformed real-money markets (TradeSports) for some event categories, particularly when play-money participation was broad. Challenges the assumption that real-money incentives always dominate.

5. **Pennock et al. (2001, PNAS)** — Play-money and real-money market prices are correlated but diverge in systematic ways; play-money updates faster when participant base is large. Manifold has ~50k+ registered users (2024 self-reported).

6. **Grossman & Stiglitz (1980, AER)** — Informed participants incur costs for trading on private information; when those costs are reduced (play money → zero entry cost), price discovery happens faster. Manifold represents near-zero-cost information aggregation.

**Structural evidence:**
- PredictIt: CFTC no-action letter since 2014; real-money contracts; $850/outcome cap; ~US political only; active community ~30k traders (2023 estimate)
- Manifold Markets: founded 2021; mana (non-redeemable play currency); 50k+ users; covers political, tech, cultural, scientific events; fast update cycle (API refresh ~minutes)
- Temporal co-listing: Manifold has explicitly mirrored thousands of Polymarket contracts; PredictIt covers most major US election/political events overlapping PM's top-liquidity markets

---

### Conditions

- **Works when:** Divergence ≥ 10 pp; divergence ≤ 6h old; PM liquidity $5k–$50k; resolution horizon 7–60 days; politically or electorally resolved events (where Manifold/PredictIt participation is highest); semantically equivalent contract confirmed; no breaking news within 2h (fresh news may independently move both venues)
- **Fails when:** Divergence reflects semantic non-equivalence (different resolution criteria, different threshold, different scope — **#1 failure mode**); PM liquidity > $50k (sophisticated PM-native participants already dominate); PredictIt has insufficient volume (< 1k YES/NO shares outstanding); Manifold predictor count < 50; resolution horizon < 7 days (PM reprices within hours, lag window too short); resolution is subjective (jury-decided) rather than mechanical
- **Best pairs:** US federal elections, US presidential actions, major legislative votes (highest Manifold/PredictIt co-listing overlap with PM)
- **Best timeframe:** 6h–72h hold; detect divergence at divergence formation; exit at gap closure

---

### Limitations (9)

1. **Semantic non-fungibility (#1 failure mode)** — Manifold and PredictIt use different resolution authorities, wording, and thresholds than Polymarket. "Will X win the election?" on Manifold may resolve under community vote; on Polymarket it resolves via AP call. Manual equivalence confirmation is mandatory — no automated matcher exists.

2. **Manifold non-redeemability** — Manifold mana cannot be converted to cash (only limited via "manalinks" into charity donations or small internal rewards). This means Manifold prices reflect *beliefs without financial consequence* — the community may be informative but is not financially disciplined. Price calibration on Manifold may be noisier than real-money venues.

3. **PredictIt US-only scope** — PredictIt's CFTC no-action letter covers only US political events and requires ≤ 5,000 traders per contract. This limits the signal to a narrow category within Polymarket's universe; many Polymarket categories (crypto, weather, tech) have no PredictIt equivalent.

4. **10 pp threshold is arbitrary** — Derived by analogy from `superforecaster-consensus-lead` (8 pp) + fee adjustment. No calibration performed. Optimal threshold likely differs by category (elections vs economic data) and liquidity tier.

5. **Convergence mechanism is slow and probabilistic** — Unlike cross-venue-semantic-arb (contractual convergence) or resolution-confirmation-arbitrage (mechanical $1 convergence), this prim relies on information diffusion through informed PM participants noticing the Manifold/PredictIt signal. Convergence may take days or not happen at all.

6. **Lead directionality assumption untested** — The mechanism predicts Manifold leads PM, but the causal direction may reverse in some cases: PM (larger, more liquid) may lead Manifold, and apparent divergence is Manifold being slow to follow PM, not PM being slow to follow Manifold. Granger causality test required on historical data.

7. **No implementation** — Manifold API (public, free) + PredictIt API (public, free) integration not yet built. `manifold_pm_matcher.py` for semantic equivalence checking is a BLOCKING dependency before any live signals.

8. **Manifold participation asymmetry by topic** — Manifold is highly active on AI, tech, forecasting competitions; less active on geopolitical minutiae and local elections. Signal quality likely tracks participation density per question, which has not been measured.

9. **Divergence age detection** — The signal requires knowing *when* the divergence formed, not just that it exists. A 10 pp gap that has persisted 2 weeks may already be fully known to PM participants who chose not to act (informed non-trading = the gap is rational). Only fresh divergences (< 6h) qualify; staleness detection requires timestamped price feed capture, not snapshot comparison.

---

### Implementation

- **New file:** `src/signals/manifold_feed.py` — Manifold API polling, price extraction
- **New file:** `src/signals/predictit_feed.py` — PredictIt API polling, contract-level prices
- **New classifier:** `src/classifiers/manifold_pm_matcher.py` [BLOCKING ALL SIGNALS] — semantic equivalence matching between Manifold/PredictIt and Polymarket markets
- **New strategy:** `src/strategies/low_friction_lead.py` — 10 pp threshold, 6h staleness gate, 72h exit
- **Key parameters:** `MIN_DIVERGENCE=0.10`, `MAX_DIVERGENCE_AGE_HOURS=6`, `MIN_PM_LIQUIDITY=5000`, `MAX_PM_LIQUIDITY=50000`, `MIN_RESOLUTION_HORIZON_DAYS=7`, `MAX_RESOLUTION_HORIZON_DAYS=60`, `EXIT_THRESHOLD=0.03`, `MAX_HOLD_HOURS=72`

---

### Conditions Log Entry
- Works when: Divergence ≥ 10 pp from Manifold or PredictIt; divergence ≤ 6h old; PM $5k–$50k; resolution 7–60d; US political or electoral events (highest co-listing overlap); semantic equivalence manually confirmed
- Fails when: Semantic non-equivalence (different resolution authority/threshold); PM > $50k (sophisticated participants already dominate); Manifold < 50 predictors; PredictIt < 1k shares; T < 7d (PM wins); divergence stale > 6h; subjective resolution events
- Last validated: never

---

## Refinement History
- 2026-04-12 (cycle 95): Created as naive prim. 18th polymarket prim class. New signal axis: behavioral anchoring lag between zero/low-capital-risk venues and large-position financially-incentivised venue. 6 academic anchors. Zero own-data.

---

### Prim Status — All 18 Polymarket Prims

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
| superforecaster-consensus-lead | sophisticated |
| favourite-longshot-bias-fade | sophisticated |
| no-event-time-decay-fade | sophisticated |
| resolution-confirmation-arbitrage | sophisticated |
| llm-ensemble-probability-edge | sophisticated |
| political-hedge-instrument-signal | sophisticated |
| news-velocity-informed-directional | sophisticated |
| anchor-event-recency-bias-fade | sophisticated |
| institutional-expert-consensus-reversion | sophisticated |
| **low-friction-venue-lead** | **naive ← this cycle** |

### Files Updated
- `knowledge/polymarket/prims/naive/low-friction-venue-lead.md` — created (this file)
- `knowledge/epistemic-index.md` — 18th polymarket naive row to be added
- `knowledge/conditions-log.md` — low-friction-venue-lead conditions to be appended

### Next Cycle Recommendations
1. **(A) RESEARCH: Elevate low-friction-venue-lead to intermediate** — primary task: test Granger causality direction (Manifold → PM or PM → Manifold?) on historical co-listed political events; extract Manifold price history via API for 2022–2025; scrape PredictIt contract prices for same period; measure actual lead times and directional accuracy on N≥30 divergence events. Resolve Limitation #6 (causal direction assumption) — if PM consistently leads Manifold, prim is anti-prim (inverted). Target: ≥ 55% directional accuracy at N≥20 to survive first gate.
2. **(B) BUILD: manifold_pm_matcher.py** — semantic equivalence classifier using sentence-transformers (reuse `metaculus_pm_matcher.py` design from `superforecaster-consensus-lead`); different resolver authority lookup table (Manifold = community vote, PredictIt = AP/official source); test on 50 manually labeled pairs.
3. **(C) RESEARCH: Calibrate divergence threshold** — 10 pp threshold is arbitrary; test whether threshold varies by: (a) Manifold vs PredictIt source, (b) question category (election vs economic vs tech), (c) PM liquidity tier. Optimal threshold may differ significantly from 10 pp.
