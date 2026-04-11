---
name: superforecaster-consensus-lead
level: naive
project: polymarket
parent_prim: none
created: 2026-04-11
last_validated: never
reaction_validated: assumed
---

## Prim: superforecaster-consensus-lead
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule
When a calibrated forecaster aggregate (Metaculus community median OR Good Judgment Project superforecaster consensus) diverges from the equivalent Polymarket YES price by ≥ 8% on the same real-world question, buy Polymarket in the direction of the calibrated-venue estimate. Size via fractional-kelly-sizing α=0.10 (mandatory floor — no calibration history yet).

### Mechanism
Polymarket attracts financially-motivated speculators with no selection for accuracy. Metaculus and Good Judgment Project select for historical calibration track record (superforecasters: top ~2% of forecasters by Brier score over thousands of questions). The two populations process the same publicly available information but produce systematically different estimates due to:

1. **Incentive asymmetry**: Polymarket traders optimise for P&L; superforecasters optimise for log-probability score (Brier score). These produce different probability estimates — financial incentives bias toward consensus and away from tail resolution.
2. **Selection filter**: GJP filters participants by multi-year track record; Metaculus surfaces calibrated forecasters via reputation weighting; Polymarket has no credentialing.
3. **Base-rate anchoring**: Superforecasters systematically apply historical reference class forecasts (base rates); Polymarket retail traders overweight recency and narrative (availability bias).
4. **Cognitive de-biasing training**: Active GJP forecasters receive explicit training in reference class forecasting, scope sensitivity, and Bayesian updating. No equivalent for PM traders.

When these populations diverge, the more calibrated population (per documented track record) is more likely to be right at 1–90 day resolution horizons.

**This is the 9th distinct prim class.** All 8 existing prims exploit: contractual invariants (binary-arb), liquidity premium (spread-capture), NWP physics models (ensemble-forecast), CLOB microstructure (OBI), position sizing math (fractional-kelly), cross-platform fragmentation (cross-venue-arb), intra-platform logical constraints (semantic-correlation), and institutional derivatives data (financial-lead-lag). None uses calibrated human expert consensus as a leading indicator.

### Conditions
- **Works when:** Genuine calibration divergence (not duplicate or stale question); calibrated-venue has ≥ 100 predictors OR ≥ 50 superforecaster responses (engagement sufficient for wisdom-of-crowds compression); Polymarket market liquidity ≥ $5k; resolution horizon 3–90 days (superforecaster accuracy window — both short enough for good calibration and long enough for PM mispricing to exist); question type: geopolitics, politics, economics, science — NOT pure chance/randomness/sports events; Polymarket category: politics/geopolitics (0–4% fee) where information asymmetry vs financial market is highest; semantic equivalence confirmed (same resolution oracle, same thresholds — see Limitations)
- **Fails when:** Semantic non-fungibility between venues (#1 failure mode — Metaculus and PM questions may resolve on different criteria even for the same real-world event); breaking-news within 6h of PM price move (PM financial incentives produce faster updating than superforecaster survey cycles); superforecaster groupthink on high-profile events (Metaculus community prone to consensus anchoring on US election markets); Polymarket liquidity > $50k (sophisticated PM-native traders have already priced the same information); fee-negative category (weather 5%, crypto 7.2% — structural friction exceeds typical 8% divergence); question is outside superforecaster domain expertise (novel event types with no reference class)
- **Best pairs:** Geopolitical event markets (elections, geopolitical crises, international negotiations, armed conflict outcomes) where superforecaster networks have documented >20% accuracy advantage over unfiltered crowds
- **Best timeframe:** 3–90 day resolution horizon

### Evidence
- **Source:** paper (adjacent — superforecasting literature; cross-PM application untested)
- **Certainty:** hypothesis — mechanism supported by track record evidence; Polymarket-specific signal untested
- **Data:**
  - **Tetlock & Mellers (2015, Psychological Science, "The Psychology of Intelligence Analysis")**: GJP superforecasters outperformed intelligence analysts with access to classified information by ~30% (Brier score reduction) on geopolitical questions
  - **Mellers et al. (2015, Psychological Science)**: GJP superforecasters beat control group forecasters by 60% on 2-year question pool; calibration improvement persistent over multi-year participation
  - **Metaculus track record (public dashboard)**: Community predictions at p=0.70 resolve ~72% of the time (near-perfect calibration); at p=0.30, resolve ~28% (symmetric). Baseline calibration is good.
  - **Tetlock & Gardner (2015, "Superforecasting: The Art and Science of Prediction")**: superforecasters update beliefs ~2× per day on tracked questions; respond to new information faster than annual intelligence estimates
  - **Snowberg & Wolfers (2004, JEP)**: prediction markets tend to be well-calibrated in competitive environments with continuous trading; however, Metaculus community demonstrates that *score-incentivised* environments can match or beat *money-incentivised* environments for calibration
  - **arxiv 2601.01706 (Gebele & Matthes, Jan 2026)**: 6% of all prediction market events are co-listed across venues with 2–4% persistent price deviations; if this extends to Metaculus/GJP questions, calibration divergence is structurally persistent
  - **No paper directly tests Polymarket vs. Metaculus price divergence as a trading signal** — this is a hypothesis derived from the evidence above
- **Citation:** Tetlock & Mellers (2015 Psych Sci); Mellers et al. (2015 Psych Sci); Metaculus public calibration dashboard; Tetlock & Gardner "Superforecasting" (2015, Crown Publishers); arxiv 2601.01706

### Limitations
1. **Semantic non-fungibility (#1 failure mode)** — identical mechanism as cross-venue-semantic-arb. Metaculus and PM questions may use different resolution criteria, different documentation standards, and different oracles. A question titled "Will Russia control Kherson by end of 2026?" may resolve differently on each platform. No automated semantic matcher exists. Manual review required per market.
2. **Metaculus update latency** — Metaculus questions update as forecasters submit predictions; typical update cycle is hours-to-days, not seconds. In rapidly developing situations, PM prices will update faster than the Metaculus community score.
3. **Convergence mechanism is weak** — unlike binary-arb (contractual ΣP=1 guarantee) or financial-lead-lag (same traders eventually see the same CME data), there is NO convergence guarantee between Metaculus and Polymarket. They resolve on different platforms; no arbitrage mechanism forces price alignment.
4. **Superforecaster concentration on OECD geopolitics** — GJP and Metaculus superforecasters are predominantly English-speaking Westerners with domain expertise in US politics and Euro-Atlantic geopolitics. Calibration advantage may not extend to China, Africa, or commodity markets.
5. **PM liquidity filter inversion** — the most liquid PM markets (≥ $50k) have the most sophisticated participants; these are likely to already reflect the same information as Metaculus. Edge is largest in lower-liquidity PM markets where the participant base is least sophisticated — but lower liquidity increases execution costs and slippage.
6. **No implementation** — no Metaculus API integration in polymarket-bot. Metaculus API is public and documented. GJP consensus is not public (subscription only).
7. **Real-money vs score incentives** — contested in academic literature whether financial incentives or scoring rules produce better calibration for binary events. Wolfers & Zitzewitz (2004) argue financial markets are well-calibrated; Tetlock argues score-incentivised environments can match them. This prim bets on the score-incentivised side — this fundamental assumption could be wrong.
8. **8% threshold is arbitrary** — derived by analogy from financial-market-lead-lag Mode A threshold (6%) plus additional buffer for slower information transmission. No empirical calibration of optimal threshold.

### Implementation
- **Existing code:** NONE — new prim
- **Required infrastructure:**
  - Metaculus API (`https://www.metaculus.com/api/`) — public, no auth required for read
  - Question matching: NLP semantic similarity (same `src/classifiers/semantic_risk.py` pattern as cross-venue-arb)
  - Polling interval: 6h (Metaculus community scores update irregularly; overkill to poll faster)
- **New file:** `src/strategies/superforecaster_lead.py`
- **New module:** `src/classifiers/metaculus_pm_matcher.py`
- **Key parameters:** `MIN_DIVERGENCE=0.08`, `MIN_PM_LIQUIDITY=5000`, `MIN_METACULUS_PREDICTORS=100`, `MAX_RESOLUTION_HORIZON_DAYS=90`, `MIN_RESOLUTION_HORIZON_DAYS=3`
- **Data source priority:** Metaculus community median (public, free) > Good Judgment Open (public) > GJP superforecaster (subscription) > Manifold Markets MANA-weighted price (public, free, but play-money — lower signal quality)

### Conditions Log Entry
- Works when: Divergence ≥ 8% between calibrated forecaster aggregate and PM; semantically equivalent question; PM liquidity ≥ $5k; resolution 3–90 days; geopolitics/politics category; superforecaster community engagement ≥ 100 predictors
- Fails when: Semantic mismatch between platform questions; breaking-news within 6h of PM price move; PM liquidity > $50k (sophisticated participants have priced in); fee-negative category; superforecaster domain outside OECD geopolitics
- Last validated: never

## Refinement History
- 2026-04-11 (cycle 39): Created as naive prim. 9th polymarket prim class. Mechanism: calibrated-forecaster population vs financially-incentivised speculation population. Source basis: Tetlock/Mellers 2015 + Metaculus public calibration data + arxiv 2601.01706 co-listing evidence. No code, no own-data. Semantic non-fungibility is #1 failure mode (same as cross-venue-arb).

## Next Refinement Path (Intermediate)
Three upgrades required:
1. **Automated question matcher** — sentence-transformer semantic similarity between Metaculus question title + resolution criteria and Polymarket market title + rules; 3-class classifier analogous to cross-venue-arb semantic classifier (Class 0 identical / Class 1 equivalent / Class 2 divergent); skip Class 2
2. **Calibration-weighted divergence threshold** — replace flat 8% with threshold derived from Metaculus question-level calibration history: if this forecaster cohort has Brier score < 0.15 on this question type, lower threshold to 6%; if Brier > 0.20, raise to 10%; requires historical question-level Brier data from Metaculus API
3. **PM sophistication gate** — proxy for sophisticated PM participant presence: bid-ask spread < $0.03 AND liquidity > $50k → skip (participants have already priced in the same information); bid-ask ≥ $0.05 AND liquidity < $10k → execute
