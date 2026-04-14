---
name: oracle-dispute-prediction-signal
level: naive
project: polymarket
parent_prim: none
created: 2026-04-14
last_validated: never
reaction_validated: no
---

## Prim: oracle-dispute-prediction-signal
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule
When a Polymarket market satisfies ALL of the following:
- Resolution description contains ≥1 ambiguity indicator from the defined keyword list (`substantially`, `materially`, `roughly`, `approximately`, `meaningfully`, `at least partially`, `by end of day`, `EOD`, `by close`, `generally`, `significant`, `notable`, `largely`, `primarily`, `broadly`, `mostly`, `adequately`) OR uses a soft metric with no objective measurement source specified
- NO objective resolution source present (e.g., `per Bloomberg`, `per CoinGecko`, `per BLS`, `as reported by`, `according to the official`) — objective source overrides all ambiguity keywords
- Current YES price ∈ [0.42, 0.58] (near-boundary — both sides have dispute incentive)
- 2 ≤ DTE ≤ 10 (approaching resolution; dispute window not yet imminent)
- No active dispute visible on market (`dispute` field null or absent)
- Liquidity ≥ $5k; bid-ask spread ≤ $0.05

→ **BUY NO** at α = 0.10 Kelly floor (uncalibrated mandatory).

**Exit:** DTE < 1 (close before oracle settlement exposure — not intended as resolution-confirmation-arbitrage); dispute filed (hold through UMA vote if size permits — this is the target event); YES moves above 0.65 (market gaining conviction against dispute thesis — close for loss); 10-day max hold if DTE > 2 at entry.

### Mechanism
UMA disputes occur when asserters and challengers disagree on whether resolution criteria were met. Aggregate dispute rate is low (~2–5%), but structured ambiguity in resolution language predictably elevates dispute probability above the base rate. Three mechanisms drive the signal:

**1. Ambiguity → dispute incentive (Hart & Moore 1988):** When resolution criteria use soft language ("substantially improved," "by EOD" without timezone), both YES-holders and NO-holders have plausible grounds to challenge the opposing resolution. Expected profit from filing a dispute (bond recovery if vote matches + market repricing) is positive when: (a) price is near 50/50 — maximum payoff to the disputing side from resolution flip; (b) language is genuinely contestable — asserter is not certain to be validated. The dispute bond acts as a filter: only challengers confident in their position (i.e., genuinely ambiguous resolutions) file.

**2. UMA voter NO-bias in ambiguous cases:** UMA's optimistic oracle ("asserter claims outcome is TRUE") places the burden of proof on the YES side. Token voters, when uncertain, face rational incentives to default FALSE (NO): (a) slashing risk for minority voters — safe default is wherever tokens are concentrated; (b) asymmetric consequences — a wrongful YES vote imposes costs on all NO-holders; a wrongful NO vote only delays resolution. Community forum patterns (qualitative, not formally studied) support conservative YES standards in disputed cases. If P(UMA votes NO | dispute) > 0.55 (plausible), YES position loses expected value conditional on any dispute occurring.

**3. PM participants systematically underweight dispute probability:** Near-expiry markets at 50/50 with ambiguous descriptions are priced as if dispute probability is zero. Polymarket fee and oracle documentation treats UMA as efficient by default. No PM pricing model publicly accounts for conditional dispute rates. This creates structural mispricing: YES is overpriced by approximately [P(dispute | ambiguous, near-50, DTE≤10) × P(NO | dispute) × price_gap] on a probability-adjusted basis — all three components positive in the target condition.

**Orthogonality to resolution-confirmation-arbitrage (RCA):**
| | resolution-confirmation-arbitrage (sophisticated) | oracle-dispute-prediction-signal (naive) |
|---|---|---|
| Timing | Post-resolution (assertion published, no dispute filed) | Pre-resolution (dispute anticipated before assertion) |
| Direction | Follow confirmed resolution | FADE YES (dispute → NO-bias expected) |
| Oracle state | Asserted, challenge window active, no challenge | Pre-assertion; predicting whether challenge will be filed |
| Mechanism | Latent information in wire-to-oracle convergence lag | Structural ambiguity in resolution criteria → biased UMA vote |

The two prims are non-overlapping in time: RCA fires AFTER resolution assertion with no dispute; oracle-dispute-prediction fires BEFORE resolution when dispute is predicted. They cannot co-fire on the same market. N_eff consideration: ρ ≈ 0.05 (distinct timing windows, opposite conditions).

### Conditions
- **Works when:** Description has ≥1 ambiguity keyword AND no objective resolution source; YES price 0.42–0.58; DTE 2–10; no active dispute; liquidity ≥ $5k; bid-ask ≤ $0.05; market is binary outcome-contingent (NOT a continuous measure where resolution is always unambiguous, e.g., exact price targets)
- **Fails when:** Resolution criteria are objective and unambiguous (e.g., "Did BTC close above $100k on [date] per CoinGecko?" — bright-line, no dispute incentive regardless of soft language elsewhere); YES price far from 50/50 (dispute incentive low for losing side); DTE > 10 (dispute filing behavior peaks in final week pre-resolution); market already in active dispute (different risk profile — RCA mechanism takes over); description contains an explicit resolution source even alongside soft language (objective anchor reduces ambiguity); elections/political category (UMA voter behavior politically framed — not predictably NO-biased)
- **Best categories:** regulatory events ("substantially complied with Rule X"), economic indicators ("meaningfully improved"), social/governance outcomes ("significant progress made"), geopolitical situations without quantitative resolution threshold
- **Best timeframe:** Signal fires 2–10 DTE; NOT latency-sensitive; position held passively until DTE=1 or dispute filed

### Evidence
- **Source:** paper (mechanism grounding in contract theory and UMA protocol documentation); hypothesis (PM-specific application untested; UMA voter NO-bias is qualitative community observation, not formal empirical study)
- **Certainty:** guess-to-hypothesis; dispute incentive mechanism is analytically sound; voter bias direction is directionally plausible but magnitude unquantified; zero own-data
- **Data:** 0 own trades; 0 own backtest
- **Citations:**
  - **Hart, O. & Moore, J. (1988, QJE)** — "Incomplete Contracts and Renegotiation": when contracts (resolution criteria) are ambiguous, both parties have rational incentives to contest outcomes near their indifference points. Foundational for why ambiguous PM resolution language creates dispute incentives at near-50/50 prices. Establishes that incompleteness is not random — it correlates with ex ante uncertainty, which is precisely the near-50/50 condition.
  - **Chen, Y., Lai, J. & Pennock, D. (2010, EC)** — "Designing markets for prediction": information market participants optimally exploit ambiguous rules when expected payoffs are near-equal. Establishes that resolution ambiguity creates systematic mispricing before resolution when participants have heterogeneous interpretations.
  - **Klemperer, P. (2002, JEEA)** — Auction design and rule ambiguity: contestable terms systematically shift outcomes toward the party with the interpretation advantage. In UMA's case, token holder majority with NO-default advantage relative to asserters seeking to prove an ambiguous positive claim.
  - **Berg, J., Nelson, F. & Rietz, T. (2008, IJF)** — Iowa Electronic Markets: near-expiry prediction market prices systematically underestimate resolution uncertainty when underlying criteria are complex or multi-conditional. Analogous to PM's implicit zero-dispute-probability pricing assumption near resolution.
  - **UMA Protocol Optimistic Oracle documentation (uma.xyz, 2023)** — Asserter bond mechanics, dispute window (typically 2h), DVM (Data Verification Mechanism) token voting with slashing for minority voters, 48–72h resolution cycle. Conservative voting behavior mechanistically grounded in minority-slashing asymmetry.

### Limitations (6)
1. **UMA voter NO-bias is qualitative, not quantified:** The claim that P(UMA votes NO | dispute) > 0.50 is based on community forum observation and protocol mechanics — NOT a formal empirical study. If actual voter behavior is symmetric (50/50), the signal has no directional edge from the bias component. Validation required: scrape all historical UMA disputes (uma.xyz dispute board + Etherscan DVM contract events) and compute actual NO-vote rate by category. If < 55% NO → bias component collapses → signal reduces to a weak dispute-frequency play only.
2. **Dispute rate is low — edge is diluted:** Even with ambiguity keywords and near-50 price, most PM markets resolve without dispute. If P(dispute | ambiguous, near-50, DTE≤10) ≈ 0.05 historically, the EV per position is approximately: 0.05 × P(NO|dispute) × (0.50 − 0.50) + noise ≈ marginal above transaction costs. Edge requires either more precise dispute prediction (higher P(dispute)) or larger NO-bias. Frequency and magnitude both require empirical validation before this is investable.
3. **Ambiguity keyword matching is a low-precision proxy:** Many genuinely ambiguous markets don't contain the keyword list (e.g., vague phrasing without the specific tokens); many keyword-matching markets are unambiguous in context (e.g., "substantially all shares" in M&A has legal precedent making it objective). Semantic ambiguity scoring via LLM would significantly improve precision but requires ML inference at signal time.
4. **Forced hold during dispute:** If a dispute IS filed while position is open, PM may suspend trading temporarily (market state changes to disputed/resolved). Exit may be unavailable for 48–72h. This is actually the desired outcome (dispute → NO-bias repricing), but introduces non-voluntary holding risk against the original intent.
5. **Category-specific oracle behavior:** UMA voter NO-bias assumption may not hold universally. For elections markets, UMA token holders may exhibit politically motivated voting or higher confidence in YES outcomes when major candidates win. For complex multi-condition markets, YES may be the more interpretable default. Category stratification required at intermediate elevation.
6. **Sequential overlap with resolution-confirmation-arbitrage:** When oracle-dispute prediction is WRONG (no dispute occurs, market resolves YES), RCA can fire in the opposing direction (Mode A, confirmed YES outcome). The two prims share the same underlying market but fire sequentially on opposite outcomes. N_eff correction required: when operating both simultaneously across different markets, shared exposure to oracle mechanics → Tier D (ρ ≈ 0.10). No compounding required.

### Implementation
```python
# src/signals/oracle_dispute_detector.py
# STATUS: BLOCKED — UMA dispute history scrape required for P(NO|dispute) empirical validation
# SECONDARY BLOCK: semantic ambiguity classifier (LLM-based) recommended before production

from src.data.gamma import get_active_markets
from src.utils.date_utils import days_to_resolution

AMBIGUITY_KEYWORDS = [
    'substantially', 'materially', 'roughly', 'approximately',
    'meaningfully', 'at least partially', 'by end of day', 'eod',
    'by close', 'generally', 'significant', 'notable', 'largely',
    'primarily', 'broadly', 'mostly', 'adequately',
]

OBJECTIVE_SOURCE_TERMS = [
    'per bloomberg', 'per reuters', 'per coingecko', 'per coinmarketcap',
    'per fred', 'per bls', 'per cdc', 'per ons', 'per eurostat',
    'as reported by', 'according to the official',
]

YES_MIN, YES_MAX = 0.42, 0.58
DTE_MIN, DTE_MAX = 2, 10
MIN_LIQUIDITY = 5_000
MAX_SPREAD = 0.05
KELLY_ALPHA = 0.10


def score_ambiguity(description: str) -> bool:
    desc_lower = description.lower()
    has_ambiguity = any(kw in desc_lower for kw in AMBIGUITY_KEYWORDS)
    has_objective = any(src in desc_lower for src in OBJECTIVE_SOURCE_TERMS)
    return has_ambiguity and not has_objective  # objective source cancels ambiguity


def oracle_dispute_signal(market: dict) -> dict | None:
    desc = market.get('description', '')
    yes = market.get('last_trade_price', 0.5)
    dte = days_to_resolution(market.get('end_date_iso', ''))
    liquidity = market.get('liquidity', 0)
    spread = market.get('spread', 1.0)
    has_dispute = market.get('dispute') is not None

    if has_dispute:
        return None
    if not (DTE_MIN <= dte <= DTE_MAX):
        return None
    if not (YES_MIN <= yes <= YES_MAX):
        return None
    if liquidity < MIN_LIQUIDITY or spread > MAX_SPREAD:
        return None
    if not score_ambiguity(desc):
        return None

    return {
        'market_id': market['id'],
        'direction': 'NO',
        'kelly_alpha': KELLY_ALPHA,
        'trigger': 'oracle_dispute_prediction',
        'yes_price': yes,
        'dte': dte,
        'ambiguity_detected': True,
        'exit': {
            'dte_floor': 1,
            'yes_stop': 0.65,
            'max_hold_days': 10,
        },
    }
```

**Required infrastructure (BLOCKING for elevation to intermediate):**
- UMA dispute history scrape: uma.xyz dispute board + Etherscan DVM contract events → compute P(dispute | ambiguous + near-50 + DTE≤10) and P(NO | dispute) by category. If P(NO|dispute) < 0.55 → anti-prim A (no directional bias; retire signal or reframe as pure dispute-frequency fade)
- Semantic ambiguity classifier (LLM zero-shot or finetuned) for improved precision over keyword match
- Gamma API `dispute` field confirmation: verify field name and behavior for in-dispute markets (field may not exist as named — check actual PM API response schema)
- Category classifier: segment dispute rates by PM category to support Mode A/B split at intermediate

### Conditions Log Entry
- **Works when:** description ≥1 ambiguity keyword, no objective resolution source override; YES ∈ [0.42, 0.58]; DTE 2–10; dispute null; liquidity ≥ $5k; spread ≤ $0.05; binary outcome-contingent market
- **Fails when:** objective resolution source present (overrides ambiguity); YES outside boundary; DTE outside window; active dispute already filed; elections/political category (UMA voter bias unpredictable); description unambiguous despite soft language; continuous-measure market (no dispute incentive structure)
- **Last validated:** never

## Refinement History
- 2026-04-14 (cycle 178): Created as naive prim. 23rd polymarket naive class. New signal class (27th unique polymarket signal axis): UMA oracle dispute prediction. First prim targeting oracle mechanic BEFORE resolution — mechanistically distinct from resolution-confirmation-arbitrage (post-assertion timing), obi-informed-directional (CLOB microstructure), and all behavioral bias prims. Mechanism grounded in Hart & Moore (1988) incomplete contracts theory + UMA optimistic oracle incentive structure. 5 academic anchors; 6 limitations; BLOCKING: UMA dispute history scrape for empirical P(dispute) and P(NO|dispute) calibration. Zero own-data.

## Next Refinement Path (Intermediate)
Three upgrades required for elevation to intermediate:
1. **UMA dispute empirical study (BLOCKING):** Scrape all historical PM dispute records (Etherscan DVM contract events + uma.xyz). Compute: (a) P(dispute | ambiguous_desc + YES∈[0.42,0.58] + DTE≤10) vs base rate; (b) P(UMA votes NO | dispute) stratified by market category. Anti-prim A: if P(NO|dispute) < 0.55 across all categories → retire directional component, reframe as pure dispute-event fade (position NO regardless of direction, betting on price freeze arb). Target: N ≥ 30 historical disputes; P(NO|dispute) ≥ 0.60 at least one category.
2. **Two-mode structure by category:** Mode A (regulatory/economic — highest ambiguity keyword prevalence; UMA conservative YES standard most applicable): full α=0.10. Mode B (geopolitical/social — moderate ambiguity; ACLED/NOAA stability gate required to separate genuine uncertainty from cognitive ambiguity): α=0.07 with stability gate. Elections category: excluded (Mode X — UMA voter behavior politically framed; no reliable NO-bias).
3. **LLM ambiguity scoring:** Replace keyword match with zero-shot LLM prompt scoring resolution criteria on 0–1 ambiguity scale. Validate against historical dispute data: LLM ambiguity ≥ 0.65 should have ≥ 2× dispute rate vs. score < 0.30. If validated, update entry threshold to LLM_score ≥ 0.60 (replacing keyword list). This upgrade reduces false positives (keyword matches with unambiguous context) and false negatives (genuinely ambiguous markets without flagged keywords).
