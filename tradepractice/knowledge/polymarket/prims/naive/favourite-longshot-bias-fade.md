---
name: favourite-longshot-bias-fade
level: naive
project: polymarket
parent_prim: none
created: 2026-04-11
last_validated: never
reaction_validated: no
---

## Prim: favourite-longshot-bias-fade
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule
If YES_price < 0.07, BUY NO. If YES_price > 0.93, BUY YES. Apply only to markets with liquidity ≥ $5k, bid-ask ≤ $0.05, and resolution horizon 3–90 days. Size via fractional-kelly-sizing α=0.10 (mandatory floor — no own-data calibration). Hold to resolution.

### Mechanism
**Probability weighting** (Kahneman & Tversky 1979): humans systematically overweight small probabilities and underweight probabilities near certainty. The weighting function w(p) = p^γ / (p^γ + (1-p)^γ)^(1/γ) with γ ≈ 0.65 produces:
- At p=0.05: w(0.05) ≈ 0.13 — overweighted 2.6×
- At p=0.95: w(0.95) ≈ 0.87 — underweighted (fair = 0.95)

In competitive prediction markets this creates equilibrium prices above empirical resolution frequencies at low probabilities (lottery-ticket demand: retail bettors pay a premium for exciting unlikely outcomes) and below empirical frequencies at high probabilities (near-certainties feel "dull" — insufficient buying for a 7% payoff).

This is the **10th distinct prim class** — the only one that requires no external data feed and exploits a universal behavioural mechanism internal to Polymarket itself.

**Signal taxonomy comparison:**

| Prim | Signal source |
|---|---|
| binary-arb | Contractual ΣP=1 violation |
| spread-capture | Liquidity premium (maker quotes) |
| ensemble-forecast-edge | NWP physics models |
| obi-informed-directional | CLOB microstructure (order flow) |
| fractional-kelly | Position sizing mathematics |
| cross-venue-semantic-arb | Cross-platform structural fragmentation |
| semantic-correlation | Intra-platform logical consistency |
| financial-market-lead-lag | Institutional derivatives data (CME) |
| superforecaster-consensus-lead | Calibrated human expert consensus |
| **favourite-longshot-bias-fade** | **Intrinsic crowd probability weighting bias** |

**Key distinction from superforecaster-consensus-lead**: that prim's signal is a DIVERGENCE from an external calibrated platform (Metaculus/GJP); this prim's signal is the PRICE LEVEL ITSELF. No external reference needed. Works on all Polymarket categories including those not listed on Metaculus.

**Fee advantage at extremes**: Polymarket fees = `feeRate × p × (1−p)`. At p=0.05 with 4% politics fee: fee = 0.04 × 0.05 × 0.95 = 0.0019 per $1 contract — effectively 0.2%. The extreme-probability zone has near-zero transaction costs, making modest calibration edges viable even on tight margins.

### Conditions
- **Works when:** YES < 0.07 (buy NO) or YES > 0.93 (buy YES); geopolitics (0% fee) or politics/finance (4% fee, near-zero at extremes); liquidity ≥ $5k; bid-ask ≤ $0.05; resolution horizon 3–90 days; no breaking news within 24h; no live-score-dependent events (sports during play); market is discovery-phase (not converging to 0/1 due to resolution imminent)
- **Fails when:** Genuine fat-tail uncertainty (**#1 failure mode**) — a longshot at p=0.04 may be correctly priced for events with fat-tail resolution risk (black swans, extreme weather, assassination); no automatic classifier distinguishes behavioral overpricing from legitimate uncertainty; resolution oracle ambiguity — near-zero-probability markets often have edge-case resolution criteria where a YES surprise is driven by oracle interpretation, not the named event; sports category with live scoring (longshot pricing during games reflects real-time probability, not bias); thin liquidity < $5k (single large order creates or destroys apparent bias); crypto category (7.2% fee reduces net edge even at extremes); newly created markets (first 48h — price discovery phase before equilibrium bias forms); market price has recently moved sharply from ≥ 0.15 toward extreme (active information event underway, not stale bias)
- **Best pairs:** Geopolitics event markets (0% fee = pure behavioral-bias edge); political binary markets (4% fee, near-zero at extremes)
- **Best timeframe:** Hold to resolution; 3–90 day horizon; no active management required

### Evidence
- **Source:** paper (behavioral finance + prediction market calibration) + hypothesis (Polymarket-specific magnitude untested)
- **Certainty:** hypothesis
- **Data:**
  - **Kahneman & Tversky (1979, Econometrica)** — Prospect Theory: probability weighting function; foundational mechanism; γ ≈ 0.65 fitted to human choice data; overweighting below ~0.15, underweighting above ~0.85
  - **Snowberg & Wolfers (2010, AER)** — "Explaining the Favourite-Longshot Bias: Is it Risk-Love or Misperceptions?": FLB explained by probability weighting (not risk preferences); horse racing magnitude ~2–5% at p < 0.10; mechanism is universal across betting markets with retail participation
  - **Wolfers & Zitzewitz (2004, JEP)** — Prediction markets well-calibrated on average (p=0.30 → 31%, p=0.70 → 72%); notes "distortions in the direction of the longshot bias" at extreme probabilities; does not quantify Polymarket-specific tail bias
  - **Ottaviani & Sørensen (2008, JEcon Theory)** — "The Timing of Bets and the Favourite-Longshot Bias": theoretical model showing FLB is an equilibrium phenomenon in competitive betting markets with heterogeneous probability estimates; survives even sophisticated participant entry
  - **Manski (2006, JFE)** — "Interpreting the Predictions of Prediction Markets": documents longshot overpricing in Intrade (Polymarket's predecessor category); notes systematic calibration gap at p < 0.10 even in financially-incentivised markets
  - **Reichenbach & Walther (SSRN 5910522)** — 124M Polymarket trades, 94% overall accuracy; calibration at extreme tails not explicitly tested; 94% average accuracy is **compatible** with tail FLB coexistence (a well-calibrated average does not preclude systematic tail bias)
  - **No peer-reviewed paper directly tests FLB magnitude at p < 0.07 or p > 0.93 on Polymarket** — this is the core evidence gap; own-data collection is the refinement path

### Limitations (7)
1. **Fat-tail black swan risk (#1 failure mode)** — the mechanism assumes the longshot is overpriced due to behavioral bias; but some p=0.04 events are correctly priced for events with genuine fat-tail resolution risk. No automatic classifier exists to separate "overpriced by bias" from "fairly priced for tail event." Manual review required per market type.
2. **Polymarket-specific magnitude unknown** — horse racing FLB = 2–5% at p < 0.10; prediction market FLB = smaller (more sophisticated participants, financial incentives, public information). Magnitude could be below fee floor for some categories. Own-data is the only resolution.
3. **Competing sophisticated participants have likely partially arbitraged this** — the FLB is well-documented in academic literature; institutional prediction market participants will have faded it, compressing the available edge. The residual may be smaller than theoretical.
4. **Resolution oracle ambiguity at extremes** — near-zero-probability markets often have vague resolution criteria. When a YES resolves at p=0.03, it is often an oracle interpretation edge case, not the named event occurring. This amplifies variance beyond what pure probability weighting would predict.
5. **Market creation selection bias** — Polymarket lists near-certainty and near-impossible markets primarily for attention/engagement, not because there is genuine uncertainty. These markets may have worse-than-average oracle quality, amplifying failure mode #4.
6. **Frequency unknown** — the fraction of Polymarket markets at p < 0.07 or p > 0.93 at any given time is undocumented. Edge may be real but market volume at extremes may limit deployable capital.
7. **No implementation** — new strategy file required; no existing polymarket-bot infrastructure for systematic extreme-probability scanning

### Implementation
- **New file:** `src/strategies/longshot_fade.py`
- **Key logic:** `if YES_price < LONGSHOT_MAX: buy_NO(market)` / `if YES_price > FAVORITE_MIN: buy_YES(market)`
- **Required filters:** liquidity ≥ $5k, bid_ask ≤ $0.05, resolution_horizon 3–90 days, category NOT sports/crypto, not live-score-type
- **Key parameters:** `LONGSHOT_MAX = 0.07`, `FAVORITE_MIN = 0.93`, `MIN_LIQUIDITY = 5000`, `MAX_BID_ASK = 0.05`
- **Sizing:** fractional-kelly-sizing sophisticated at α=0.10 (mandatory — no calibration history)
- **Fat-tail guard:** manual market-type review before entry; category-level blocklist: nuclear/war-escalation/assassination/extreme-natural-disaster markets = skip regardless of price level

### Conditions Log Entry
- Works when: YES < 0.07 (buy NO) or YES > 0.93 (buy YES); geopolitics/politics; liquidity ≥ $5k; bid-ask ≤ $0.05; resolution 3–90 days; no recent breaking news; not live-scoring-dependent
- Fails when: Fat-tail genuine uncertainty (black swan events, nuclear, extreme weather); oracle ambiguity at extremes (vague resolution criteria); sports live scoring; crypto category; thin liquidity manipulation; newly listed market (<48h)
- Last validated: never

## Refinement History
- 2026-04-11 (cycle 43): Created as naive prim. 10th polymarket prim class. Behavioral-bias mechanism — the only PM prim requiring no external data feed and exploiting universal psychological probability weighting. 6-source academic basis. Zero own-data. Distinct from superforecaster-consensus-lead (external calibrated reference) — this prim uses the price level itself as signal.

## Next Refinement Path (Intermediate)
Three upgrades required:
1. **Polymarket calibration scan** — pull historical Polymarket resolution data from Gamma API; compute empirical resolution frequency at each 1pp price bucket (0–10%, 90–100%); fit calibration curve; measure FLB magnitude at extremes. If < 2% gap at p < 0.07 → mechanism weak, revise threshold or mark precursor anti-prim
2. **Fat-tail category classifier** — deterministic keyword veto for market types with legitimate fat-tail resolution risk (nuclear/existential/terrorism/extreme-natural-disaster); apply before any trade
3. **Threshold calibration** — test rule across LONGSHOT_MAX ∈ [0.03, 0.05, 0.07, 0.10] and FAVORITE_MIN ∈ [0.90, 0.93, 0.95, 0.97] on empirical calibration data; plateau criterion: resolution frequency deviation from market price > fee floor (0.3%) at chosen threshold
