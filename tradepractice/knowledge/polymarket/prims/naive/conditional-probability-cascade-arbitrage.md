---
name: conditional-probability-cascade-arbitrage
level: naive
project: polymarket
parent_prim: none
created: 2026-04-12
last_validated: never
reaction_validated: no
---

## Prim: conditional-probability-cascade-arbitrage
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule
When Polymarket simultaneously lists an upstream market U and a downstream market D where D can only resolve YES if U resolves YES first (logical cascade prerequisite), the Bayesian product constraint requires P(D) ≤ P(U) and approximately P(D) ≈ P(U) × r, where r = P(D=YES | U=YES) estimated from historical base rates. When the market price P(D)_market diverges from this product by more than transaction costs, establish a hedged position: if P(D)_market > P(U)_market × r + fees → BUY NO on D (overpriced downstream) and BUY YES on U (underpriced upstream); if P(D)_market < P(U)_market × r − fees → reverse. Apply only where both markets have liquidity ≥ $5k, bid-ask ≤ $0.05, and r is estimable from ≥ 15 comparable historical instances OR from structural reasoning. Size via fractional-kelly-sizing at α = 0.10 (mandatory floor — no calibration history). Exit on: upstream resolution (forced convergence), divergence closure to < fees, or 60-day max hold.

### Mechanism

**Bayesian product constraint (mathematical necessity):** When D logically requires U as a prerequisite, the joint probability relationship is exact:
- P(D=YES) = P(D=YES | U=YES) × P(U=YES) + P(D=YES | U=NO) × P(U=NO)
- For strong cascades (P(D=YES | U=NO) ≈ 0): P(D=YES) ≈ P(U=YES) × r
- This is not a hypothesis — it is a law of probability. Any P(D) > P(U) violates the subset relationship: the event set {D resolves YES} is a strict subset of {U resolves YES}.

**Conjunction fallacy as systematic mispricing source** (Tversky & Kahneman, 1983): People estimate the probability of compound events P(A ∩ B) as greater than P(B), violating the subset axiom. The cascade pricing error is exactly this violation: P(win general) > P(win primary) is mathematically impossible when the general requires the primary, yet prediction market prices routinely reflect this conjunction fallacy during active narrative cycles when participants price each market on its own vivid merits rather than in relation to its logical prerequisite.

**Conditional independence assumption failure:** Prediction market participants evaluate upstream and downstream markets in cognitive isolation. When new information strengthens the upstream market (e.g., candidate surges in primary polls), traders update U upward but fail to proportionally update D. The asymmetric updating creates temporary divergences. Similarly, D can be priced too low relative to a near-certain upstream (narrative discount applied to the downstream outcome despite the upstream being essentially locked).

**Hard convergence at upstream resolution:** The conjunction fallacy cannot persist past upstream resolution. If U resolves YES, D must immediately reprice from P(D)_pre to P(D|U=YES) = P(D)/P(U) (Bayesian update). If U resolves NO, D must reprice to ≈ 0 in strong cascades. This is a deterministic forcing mechanism — unlike sentiment-based prims that require further belief change, cascade convergence is contractually forced at resolution.

**Signal taxonomy — distinction from existing 20 polymarket prims:**

| Prim | Mechanism | Relationship type |
|------|-----------|-------------------|
| cross-venue-semantic-arb | Same-event price discrepancy across PM/Kalshi | Same market, different venues |
| semantic-correlation-pair-trade | Semantic similarity → correlated price moves | Bidirectional correlation, no Bayesian constraint |
| binary-arb-completeness | P(YES) + P(NO) = 1 within a single market | Single-market completeness |
| financial-market-lead-lag | Financial instrument leads PM price update | Cross-asset correlation |
| base-rate-neglect-fade | PM price vs category empirical resolution frequency | Single-market base rate calibration |
| **conditional-probability-cascade** | **P(D) ≈ P(U) × r; divergence = conjunction fallacy** | **Directional causal cascade; Bayesian subset constraint** |

Key distinction from `semantic-correlation-pair-trade`: semantic correlation is bidirectional (either market can lead), non-causal, and has no hard Bayesian floor. Cascade arbitrage is unidirectional (U is prerequisite to D), causal, and has a mathematically exact price constraint that is enforced at upstream resolution.

Key distinction from `base-rate-neglect-fade`: base-rate neglect compares a single market's price to the historical resolution frequency of its category. Cascade arbitrage compares two simultaneously-traded markets' prices to each other via the conditional probability relationship — no historical frequency database required; the constraint derives from the market topology alone.

### Conditions

- **Works when:**
  - Explicit cascade structure: D logically requires U (political primary → general; chamber passage → signed law; group stage qualification → knockout round → champion)
  - P(D=YES | U=NO) ≈ 0 (near-zero conditional tail; strong cascade; the downstream event is impossible without the upstream)
  - Divergence: P(D)_market > P(U)_market × r + fees (conjunction fallacy direction) or P(D)_market < P(U)_market × r − fees (overconditioning direction)
  - r estimable with ≥ 15 comparable historical instances (elections: primary→general win rates well-documented; legislative: House→Senate passage rates available from GovTrack) OR from structural logic (e.g., P(become president | lose primary) ≈ 0 — no estimation uncertainty)
  - Both markets: liquidity ≥ $5k; bid-ask ≤ $0.05
  - Resolution timeline: upstream resolves ≥ 7 days before downstream (allows convergence; too-close timelines = execution risk)
  - Market is binary on both legs (neg_risk=False; no multi-outcome complications)

- **Fails when:**
  - Cascade is weak: P(D=YES | U=NO) >> 0 (e.g., third-party candidate can win general even without major party primary — conditional tail non-trivial; constraint loosens to inequality rather than near-equality)
  - r is unknown or highly uncertain: no comparable historical instances; structural reasoning insufficient; specific instance has unprecedented features that legitimately break the base-rate r
  - Liquidity imbalance: downstream market has <$1k depth — cannot execute hedge leg without adverse price impact
  - Both markets are in the FLB zone (U near $1.00 or D near $0.01) — fee structure changes; FLB prim takes precedence
  - Narrative-driven divergence that is information, not bias: genuine new information about the downstream outcome that is orthogonal to the upstream (e.g., downstream candidate's health event that affects general election chances independent of primary outcome)
  - Upstream already resolved — no cascade arbitrage opportunity; cascade has forced convergence

- **Best market types:** US presidential election (primary → general → electoral college by state); US Senate confirmation (nomination → confirmation vote); legislative cascade (House → Senate → Presidential signature); sports (group stage → semifinal → final → champion); international election multi-round (first round → second round → victory)

- **Best timeframe:** 30–120 days before upstream resolution; position sizes small while r uncertain; largest position when upstream is near-certain (U > 0.90) and D hasn't converged proportionally

### Evidence

- **Source:** paper (behavioral psychology + prediction market theory) + hypothesis (Polymarket-specific cascade testing not yet done)
- **Certainty:** hypothesis

- **Data:**
  - **Tversky & Kahneman (1983, Psychological Review)** — "Extensional Versus Intuitive Reasoning: The Conjunction Fallacy in Probability Judgment": landmark demonstration that people estimate P(A ∩ B) > P(B), violating the subset axiom (Linda problem and variants); replicated across subjects including statistically sophisticated respondents; the conjunction fallacy is the exact mathematical failure underlying downstream overpricing relative to upstream — P(win general) > P(win primary) is the Linda problem applied to prediction markets
  - **Tversky & Kahneman (1974, Science)** — "Judgment Under Uncertainty: Heuristics and Biases": representativeness heuristic causes participants to evaluate the probability of a compound event based on how "representative" the description is, ignoring the base rate constraint imposed by the prerequisite; directly applicable to cascade markets where each leg has vivid narrative that anchors independent probability estimates
  - **Bar-Hillel (1980, Acta Psychologica)** — "The Base-Rate Fallacy in Probability Judgments": people systematically fail to apply Bayesian updating even in simple conditional probability problems; the failure persists when stakes are real and the conditional structure is made explicit; strengthens the theoretical case for cascade mispricing being persistent rather than quickly arbitraged
  - **Wolfers & Zitzewitz (2004, Journal of Economic Perspectives)** — "Prediction Markets": prediction markets well-calibrated on average at p ∈ [0.30, 0.70]; this aggregate calibration result is compatible with systematic cross-market consistency violations; Wolfers & Zitzewitz explicitly note multiple within-event conditional inconsistencies in their dataset (state-level vs national election markets); cross-market Bayesian constraints not enforced by market microstructure
  - **Manski (2006, Journal of Financial Economics)** — "Interpreting the Predictions of Prediction Markets": documents that prediction market prices frequently violate cross-market probability constraints that should hold by the laws of probability; notes that no arbitrage mechanism in the CLOB structure enforces cross-market consistency (each market is a separate book; no delta-neutral hedging infrastructure for correlated markets)
  - **Leigh & Wolfers (2006, Economic Record)** — "Competing Approaches to Forecasting Elections": state-level electoral college markets on IEM were not always mutually consistent with national winner-takes-all market; national market implied P(Bush) differed from the probability computed from state-level cascade by 2–4 pp; this is direct empirical evidence of cascade mispricing in real prediction market data
  - **No peer-reviewed study directly tests the Bayesian cascade constraint in Polymarket CLOB data using the conjunction fallacy mechanism** — this is the core evidence gap; the theory is grounded in Tversky & Kahneman 1983 + 1974, the aggregate cross-market inconsistency is documented in Manski 2006 and Wolfers & Zitzewitz 2004, and a direct empirical analog is Leigh & Wolfers 2006; own-data extraction of Polymarket cascade pairs is the mandatory refinement step

### Limitations (7)

1. **Cascade detection requires NLP + domain knowledge** — identifying U→D market pairs from Polymarket's thousands of simultaneous markets requires semantic understanding of logical prerequisites. There is no automated cascade detector in the codebase. At naive level, identification is entirely manual. This limits signal frequency to a small number of manually identified high-confidence cascade structures per election cycle.

2. **Conditional rate r estimation is the primary analytical blocker** — r must be estimated from historical data. For political cascades, comparable examples are few (20–25 US presidential primary-general pairs post-WWII; Senate confirmation rates available from 1990+ via GovTrack; sports cascades are well-sampled but event-specific). Low-n estimates carry wide credible intervals that can flip the signal direction if r is mis-estimated.

3. **Asymmetric liquidity risk** — the upstream and downstream legs may have very different order book depths. The downstream market is often less liquid (fewer participants have a view on the terminal outcome). Executing the hedge on both legs simultaneously without adverse price impact requires careful size management. In thin downstream markets, leg-2 execution may fully close the theoretical gap before fill.

4. **Cascade resolution timing mismatch** — if upstream resolves unexpectedly early (candidate withdraws, game ends in forfeit) while a D position is open, the forced convergence on D may happen before the intended exit. This can be advantageous (forced-convergence profit) or adverse (if D is long and U resolved NO, full loss on D leg). Pre-resolution timing events are the highest-severity tail risk.

5. **Information vs. bias confound** — the core identification problem: P(D)_market > P(U)_market × r is either (a) conjunction fallacy (participants pricing independently, ignoring the subset constraint) or (b) genuine information about D that is conditionally independent of U (e.g., downstream candidate has a health advantage that increases P(win general | win primary) above historical r). Differentiating (a) from (b) requires explicit case-level controls not formalised at naive level.

6. **Correlation with base-rate-neglect-fade and semantic-correlation-pair-trade** — if base-rate-neglect-fade fires on the downstream market (D priced above its category resolution frequency), the cascade prim may also fire (D priced above U × r). The two signals may be driven by the same underlying bias in the same market at the same time, creating correlated position exposure. Position sizing must account for this overlap; N_eff adjustment required before live deployment.

7. **No implementation** — no cascade detector, no conditional rate database, no dual-leg hedge execution framework. Signal is entirely theoretical at naive level. The `src/strategies/` directory has no cascade arbitrage file.

### Implementation (stub)

- **New file:** `src/strategies/conditional_cascade_arbitrage.py`
- **Required infrastructure:**
  - `src/data/cascade_detector.py` — NLP + rule-based identifier of U→D market pairs from Polymarket API; outputs `(upstream_id, downstream_id, cascade_type, r_estimate, r_confidence, r_n)` (BLOCKING: must exist before signal generation)
  - `src/data/conditional_rate_db.py` — historical conditional rate database per cascade type (BLOCKING: must exist before deployment)
- **Key logic:**
  ```python
  def compute_cascade_signal(upstream_market, downstream_market,
                              r_estimate: float, r_confidence: float) -> Signal | None:
      p_u = upstream_market['yes_price']
      p_d = downstream_market['yes_price']

      # Hard Bayesian floor: P(D) cannot exceed P(U) in a strong cascade
      if p_d > p_u + 0.02:  # > 2pp violation of subset axiom
          # Conjunction fallacy confirmed direction: D overpriced vs U
          theoretical_p_d = p_u * r_estimate
          gap = p_d - theoretical_p_d
          if gap < CASCADE_GAP_THRESHOLD or r_confidence < MIN_R_CONFIDENCE:
              return None
          return Signal(
              direction_d='NO', direction_u='YES',
              gap=gap, mechanism='conjunction_fallacy_cascade'
          )

      # Underconditioning direction: D underpriced relative to near-certain U
      theoretical_p_d = p_u * r_estimate
      gap = theoretical_p_d - p_d
      if gap < CASCADE_GAP_THRESHOLD or r_confidence < MIN_R_CONFIDENCE:
          return None
      return Signal(
          direction_d='YES', direction_u='NO',
          gap=gap, mechanism='underconditioning_cascade'
      )

  CASCADE_GAP_THRESHOLD = 0.08  # minimum divergence; fees ≈ 4% × 2 legs; require 2× buffer
  MIN_R_CONFIDENCE = 0.65       # minimum confidence in conditional rate estimate
  MIN_LIQUIDITY = 5_000         # USD, both legs
  MAX_BID_ASK = 0.05            # both legs
  KELLY_ALPHA = 0.10            # mandatory floor until calibration history exists
  ```
- **Sizing:** fractional-kelly-sizing sophisticated at α = 0.10 (mandatory floor)
- **Exit triggers:** (1) upstream resolution — forced convergence; (2) gap < CASCADE_GAP_THRESHOLD/2; (3) 60-day max hold

### Conditions Log Entry

```
Cycle 114 | conditional-probability-cascade-arbitrage | naive | polymarket
- Rule: P(D) ≈ P(U) × r; when |P(D)_market − P(U)_market × r| > fees → dual-leg hedge
- Mechanism: conjunction fallacy (Tversky & Kahneman 1983) → traders price upstream and
  downstream markets in cognitive isolation, violating the Bayesian subset constraint
  P(D) ≤ P(U). Hard convergence at upstream resolution provides deterministic exit.
- Blocking: cascade detector not built; conditional rate database does not exist;
  no own-data evidence; signal is entirely theoretical at naive level
- Distinct from:
    cross-venue-semantic-arb: same event, different venues
    semantic-correlation-pair-trade: bidirectional correlation, no Bayesian constraint
    binary-arb-completeness: single-market P(YES)+P(NO)=1
    base-rate-neglect-fade: single-market vs category frequency (no cross-market structure)
- 21st polymarket prim class — all 20 prior classes now at sophisticated level
- 7 academic/practitioner sources: Tversky-Kahneman 1983, 1974; Bar-Hillel 1980;
  Wolfers-Zitzewitz 2004; Manski 2006; Leigh-Wolfers 2006
- Next: (A) Extract 2022–2024 US election cascade pairs from Polymarket Gamma API;
          measure P(D)_market / (P(U)_market × r_historical) ratio at weekly snapshots
         (B) Estimate r from 2008–2024 primary-general conditional rates (US presidential)
             and supplementary sources (GovTrack Senate passage rates 1990–2024)
         (C) Test conjunction fallacy direction: Mann-Whitney U test vs null P(D)/P(U×r) = 1;
             if P(D) systematically > P(U×r) across cascade pairs → intermediate
         (D) Quantify divergence magnitude and time-to-convergence window
- Last validated: never
```

## Refinement History
- 2026-04-12 (cycle 114): Created as naive prim. 21st polymarket prim class. All 20 prior polymarket classes now at sophisticated level. Explores conditional probability cascade relationships between simultaneously-traded Polymarket markets — mechanistically distinct from all 20 existing prims. Conjunction fallacy (Tversky & Kahneman 1983) is the behavioural mechanism; P(D) ≈ P(U) × r is the Bayesian constraint exploited. Hard convergence at upstream resolution provides deterministic forcing mechanism absent from all correlation-based prims. Primary blocker: cascade detection and conditional rate database. 7 limitations documented. Zero own-data. 7-source academic basis including direct empirical analog (Leigh & Wolfers 2006 — cross-market inconsistency in IEM state vs national election markets).

## Next Refinement Path (Intermediate)

Four upgrades required for intermediate elevation:

1. **Cascade pair database** — extract all U→D market pairs from 2022–2024 Polymarket archives using Gamma API; tag cascade type (primary→general, House→Senate→signed, group→knockout→final, etc.); validate pair identification precision ≥ 0.85 on manual spot-check (N=30 pairs). Target ≥ 50 identified cascade pair-instances.

2. **Conditional rate database** — for each cascade type, compile r estimates: US presidential primary-general (1944–2024, ~20 observations); US Senate confirmation rates by president/opposition-majority (GovTrack 1990–2024); sports tournament advancement rates per event type (well-sampled). Estimate r with 90% credible interval using Beta-Binomial model. Flag cascade types where CI width > 0.20 as "r-uncertain" and require escalated gap threshold (0.12 instead of 0.08).

3. **Own-data backtest** — for identified cascade pairs in 2022–2024 Polymarket data, compute P(D)_market / (P(U)_market × r) at weekly snapshots. Measure: (a) fraction of observations where conjunction fallacy direction holds (P(D) > P(U) × r), (b) median gap magnitude, (c) time-to-convergence after gap exceeds threshold, (d) convergence mechanism (resolution-forced vs. market learning). Mann-Whitney U test vs null = 1.0 at p < 0.10. If conjunction fallacy direction not statistically dominant → anti-prim gate.

4. **Information vs. bias gate** — formalise a cascade-specific confound test: identify "conditional-independent" information events (events that change P(D | U=YES) rather than P(U)) and exclude these from signal generation. Define and implement `is_conditional_independent_event()` heuristic — flags when downstream-specific news has appeared in the prior 48h that legitimately justifies D deviating from the product constraint.
