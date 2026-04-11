# Prim: No-Event Time-Decay Fade (Sophisticated)

**ID:** polymarket-time-decay-fade-s1  
**Level:** Sophisticated  
**Supersedes:** polymarket-time-decay-fade-i1 (intermediate)  
**Market:** Polymarket  
**Category:** Geopolitics (primary); Legislative (non-calendar), Executive Action, Diplomatic  
**Tags:** actuarial-decay, poisson-process, anchoring-bias, temporal-mispricing, lambda-calibration, NO-fade

---

## Rule

Buy NO on Polymarket binary markets pricing non-scheduled events where:

**Mode A (High-Conviction)**
- `actuarial_ratio = YES_market / actuarial_yes(λ_cat, days_remaining)` **≥ 1.50**
- `days_remaining` ≤ 14
- `YES_market` ∈ [0.08, 0.35]
- No positive catalyst in prior 72 hours (< 2 relevant articles; no wire/agency breaking news)
- Market question does NOT trigger scheduled-event keyword veto
- → BUY NO. Kelly fraction α = 0.10 (floor; escalate to 0.25 after Gate 2 confirms RMSE ≤ 0.02)

**Mode B (Standard)**
- `actuarial_ratio` **≥ 1.30**
- `days_remaining` ≤ 21
- `YES_market` ∈ [0.08, 0.35]
- Same catalyst and keyword guards as Mode A
- → BUY NO. Kelly fraction α = 0.10 (floor; same escalation path)

```python
actuarial_yes(λ, T) = 1 - exp(-λ × T)
actuarial_ratio     = YES_market / actuarial_yes(λ_cat, days_remaining)

# Use λ_UPPER (95th CI bound) for threshold evaluation when n < 200 resolved markets
# Use λ_MLE when n ≥ 200 (calibration mature)
```

**Scheduled-event keyword veto** (disqualifies both modes):
- `"vote on"`, `"election on"`, `"scheduled meeting"`, `"debate on [date]"`, `"hearing on"`, `"expires on"`, `"deadline on"`, `"by [month] [year]"` (explicit calendar deadline)
- Mechanism: known-date events are NOT Poisson — actuarial model produces systematically wrong λ

**Positive catalyst gate** (72h lookback):
- FAIL if ≥ 2 relevant articles mentioning the market's event with positive framing
- FAIL if any single wire/agency breaking news (Reuters, AP, Bloomberg) in 72h
- Pass = < 2 articles AND no breaking news

---

## λ Lookup Table (Calibrated Priors + External Validation)

| Category | λ_MLE/day (prior) | λ_LOWER (90% CI) | λ_UPPER (90% CI) | External Base Rate | Source |
|----------|-------------------|-------------------|-------------------|-------------------|--------|
| geopolitics_military | 0.003 | 0.0018 | 0.0042 | ~7 crises/yr globally → 0.0192/day ÷ ~6 active contracts ≈ 0.003 | ICB Dataset 1946–2019 |
| legislative_passage | 0.005 | 0.003 | 0.008 | Congressional pass rate ~4% (House bills introduced); ~0.005/day for PM-listed bills | GovTrack 2019–2024 |
| executive_action | 0.008 | 0.005 | 0.012 | ~80 executive orders/yr (Trump-era peak) ÷ ~30 active PM contracts ≈ 0.007–0.009/day | Federal Register 2017–2024 |
| diplomatic_agreement | 0.002 | 0.001 | 0.003 | Peace agreements / major treaties: ~2–4/yr globally; PM-listed subset even rarer | Uppsala PRIO dataset |

**Conservative-use rule**: Until Gamma API MLE calibration reaches n ≥ 200 resolved markets per category, use **λ_UPPER** for the actuarial_ratio denominator. This makes `actuarial_yes` larger, making `actuarial_ratio` smaller, making the signal more conservative — false negatives preferred over false positives during pre-calibration phase.

**λ calibration implementation:**

```python
def calibrate_lambda(category: str, resolved_markets: list[dict]) -> dict:
    """
    Pull resolved binary markets from Gamma API for category.
    For each resolved market, extract:
      - T_i: days_remaining at position-entry snapshot (final-14-day window)
      - resolved_yes: 1 if resolved YES, 0 if NO
    
    Fit λ_MLE via MLE: minimize negative log-likelihood of Poisson model
    equivalently: minimize sum((actuarial_yes(λ, T_i) - empirical_rate_i)^2)
    
    Returns:
      {'lambda_mle': float, 'lambda_lower': float, 'lambda_upper': float,
       'n': int, 'rmse': float, 'cohort_stable': bool}
    """
    # scipy.optimize.minimize_scalar over λ ∈ [0.001, 0.05]
    # Bootstrap 1000x for CI bounds
    # cohort_stable = True if two independent 6-month cohort λ values within 20% of each other
    pass


def gamma_calibration_scan(resolved_markets: list[dict]) -> dict:
    """
    Bin YES prices at final-14-day snapshot into three buckets.
    For each bucket: compute mean(YES_market) / mean(actuarial_yes(λ_cat, T)).
    
    PASS = overpricing_ratio ≥ 1.30 in ≥ 2 of 3 buckets, n ≥ 50 per bucket.
    """
    buckets = [(0.08, 0.15), (0.15, 0.25), (0.25, 0.35)]
    # Return per-bucket overpricing_ratio, n, and overall pass/fail
    pass
```

---

## Expected Return Quantification

The NO expected return (gross, pre-fee) as a function of `actuarial_ratio` and `YES_market`:

```
NO_expected_return = (actuarial_ratio - 1) × x / (actuarial_ratio × (1 - x))

where x = YES_market
```

**Derivation:** If actuarial fair YES = x/r (where r = actuarial_ratio), then fair NO = 1 - x/r. Market NO = 1 - x. Return = (1 - x) / (1 - x/r) - 1 = (r - 1)x / (r(1-x)).

**Return table (gross, no fees):**

| actuarial_ratio | YES = 0.10 | YES = 0.15 | YES = 0.20 | YES = 0.25 | YES = 0.30 | YES = 0.35 |
|----------------|-----------|-----------|-----------|-----------|-----------|-----------|
| 1.30           | 2.6%      | 4.1%      | 5.8%      | 7.7%      | 9.9%      | 12.4%     |
| 1.40           | 4.9%      | 7.7%      | 10.5%     | 13.3%     | 16.7%     | 20.5%     |
| 1.50           | 6.7%      | 10.3%     | 13.9%     | 17.6%     | 21.4%     | 25.9%     |
| 1.75           | 11.1%     | 16.7%     | 21.9%     | 27.3%     | 32.7%     | 38.6%     |
| 2.00           | 14.3%     | 21.0%     | 27.3%     | 33.3%     | 39.3%     | 45.5%     |

**Fee-independence proof (why 1.30 threshold clears all category friction floors):**

| Category | PM Taker Fee | Break-even ratio | Mode B threshold | Margin |
|----------|-------------|-----------------|-----------------|--------|
| Geopolitics | 0% | 1.00 | 1.30 | +30pp |
| Politics | 4% | 1.10 (at YES=0.20) | 1.30 | +20pp |
| Legislative | 4% | 1.10 | 1.30 | +20pp |
| Executive | 4% | 1.10 | 1.30 | +20pp |
| Diplomatic | 0–2% | 1.05 | 1.30 | +25pp |

At `ratio=1.30, YES=0.20`: gross return = 5.8%. After 4% taker fee → net ≈ 5.8% - 0.04×0.20/(1-0.20) = 5.8% - 1.0% = 4.8%. Still positive at all YES values in [0.08, 0.35].

**Mode A (ratio ≥ 1.50)** returns range 6.7–25.9% gross across the YES range — clearing even worst-case fee scenarios by substantial margin.

---

## Mechanism

Binary PM contracts are equivalent to binary call options. For a Poisson-process event with constant arrival rate λ, the risk-neutral fair YES price at horizon T is:

```
actuarial_yes(λ, T) = 1 - exp(-λ × T)
```

This decays monotonically toward zero as T shrinks without event occurrence. When YES_market fails to track this decay, `actuarial_ratio` rises above 1.0.

### Two-layer persistence mechanism

**Layer 1 — Cognitive (anchoring):** Kahneman & Tversky (1974) — traders anchor to the listing-day YES price and adjust insufficiently as T decreases without event occurrence. The anchor is the initial listing price (often set by the market creator or early liquidity); downward adjustment toward actuarial fair value is insufficient even in financially-incentivised environments (Manski 2006 JFE confirms persistence in Intrade).

**Layer 2 — Market structure (return threshold):** Ottaviani & Sørensen (2008) — professional capital corrects mispricing only where per-contract return exceeds friction floors. In the YES 0.08–0.35 range, NO contracts return $0.65–$0.92/contract — above all friction floors, so professional arbitrage is structurally available. Yet correction is slow because (a) the anchored retail order flow continuously replenishes overpricing, and (b) the convergence window (hours-to-days in the final 21d) is too short for the convergence to be guaranteed within a single position's hold period.

**The exploitable gap:** The actuarial decay is not priced into the YES side because retail participants do not recompute Poisson fair value — they treat current YES price as an adequate estimate of event probability, ignoring the denominator shrinkage as T → 0.

### Distinction from FLB (non-overlapping by construction)

| Dimension | FLB Fade | Time-Decay Fade |
|-----------|----------|-----------------|
| Mechanism | Static probability weighting (γ≈0.65 misperception) | Dynamic: anchoring blocks Poisson temporal decay |
| YES range | 0.03–0.07 (any horizon) | **0.08–0.35 (final ≤ 21d only)** |
| Signal variable | Current YES level | `actuarial_ratio = YES / actuarial_fair(λ,T)` |
| Persistence driver | Subeconomic return barrier (NO earns < $0.07) | Anchoring + insufficient convergence window |
| Categories | Geopolitics only | Geopolitics, politics, legislative, executive |

YES lower bound 0.08 is structurally non-overlapping: FLB operates below 0.08 (subeconomic barrier), time-decay operates from 0.08 upward (barrier absent, but anchoring persists).

---

## Deployment Gate Sequence

All gates must pass **in order** before live capital deployment.

```
Gate 1: GAMMA CALIBRATION SCAN (read-only, no capital)
  → gamma_calibration_scan() against ≥ 1 year of Gamma API resolved markets
  → PASS = overpricing_ratio ≥ 1.30 in ≥ 2 of 3 YES buckets (n ≥ 50/bucket)
  → FAIL = mechanism not present at detectable magnitude → do not proceed

Gate 2: λ EMPIRICAL MLE CALIBRATION (per-category)
  → calibrate_lambda() for each category (geopolitics, legislative, executive, diplomatic)
  → PASS = n ≥ 50 resolved markets, RMSE ≤ 0.02, cohort_stable = True
  → FAIL = raise to λ_UPPER; if still unstable → do not deploy that category
  → Escalation: n ≥ 200 achieved → promote to λ_MLE (exit conservative mode)

Gate 3: PAPER TRADING (no capital, 30 Mode A signals)
  → Run two-mode logic on live markets; log all qualifying signals
  → Track hypothetical NO resolution outcomes
  → PASS = WR ≥ 52% over 30 Mode A signals; signal frequency ≥ 5/year
  → FAIL = run escape hatch A scan; if mechanism confirmed absent → retire

Live Deployment:
  → α = 0.10 Kelly floor until Gate 2 calibration mature (n ≥ 200)
  → α escalation to 0.25 after n ≥ 200, RMSE ≤ 0.015, cohort_stable confirmed
  → Size per trade via fractional-kelly-sizing sophisticated
  → Maximum single position: 5% bankroll (hard cap)
```

---

## Competitive Moat Analysis

**Barrier to entry (why < 5 systematic operators globally):**

1. **Actuarial model requirement**: The signal is not a visual pattern — it requires computing `actuarial_yes(λ, T)` with category-calibrated λ. The vast majority of PM participants do not maintain a Poisson arrival rate model per event category.

2. **λ calibration requirement (BLOCKING)**: Requires pulling and processing Gamma API resolved market history (n ≥ 50 per category), running MLE optimisation, and validating cohort stability. This is a non-trivial data pipeline that casual participants do not build.

3. **Not latency-sensitive**: The execution window is hours-to-days (enter within 24h of signal activation; hold to resolution or catalyst invalidation). This means institutional HFT cannot extract the edge before slower systematic operators.

4. **Not addressable by simple filters**: The signal only fires when actuarial_ratio is computed — a screen for "YES < 0.35 AND T < 21d" gives too many false positives. The ratio is the distinguishing computation.

5. **Self-obscuring frequency**: ~20–50 qualifying signals/year means the strategy is too sparse for most quant funds to build dedicated infrastructure.

**Saturation risk:** Low-medium. Mechanism relies on retail anchoring, which persists as long as PM contract pools include unscored, non-actuarial participants. The entry of additional systematic operators would compress actuarial_ratio at signal fires (fewer 1.30+ opportunities), but would not eliminate the mechanism — it would shift threshold to ~1.20 and reduce frequency before eliminating edge.

**N=30 horizon:** At combined Mode A+B frequency of 20–50/year, N=30 achievable in 8–18 months. First 30 Mode A trades (higher-conviction signal) achievable in 24–48 months at 8–15/year.

---

## Evidence

1. **Kahneman & Tversky (1974, Science)** — anchoring and adjustment: subjects set on an initial value and adjust insufficiently. YES listing price = anchor; Poisson temporal decay is the adjustment that fails to occur. Direct cognitive mechanism for Layer 1 persistence.

2. **Manski (2006, JFE)** — *Interpreting the Predictions of Prediction Markets*: Intrade contract probabilities exhibit systematic persistence above/below rational Bayesian posteriors across resolution windows. Confirms anchoring operates in financially-incentivised prediction markets, not just lab settings.

3. **Snowberg & Wolfers (2010, AER)** — *Explaining the Favourite-Longshot Bias: Is It Risk-Love or Misperception?*: misperception model (γ≈0.65) — the structural deviation from Bayesian updating is cognitive, not preference-based. Explains why the actuarial ratio divergence is stable and measurable; rational risk-love models cannot reproduce the persistence pattern.

4. **Ottaviani & Sørensen (2008, JFE)** — *The Favourite-Longshot Bias: An Overview of the Main Explanations*: professional capital excluded when per-contract return falls below friction floor. In YES 0.08–0.35, per-contract NO return ≥ $0.65 — above friction floor — yet anchoring prevents correction. Pinpoints the structural reason Layer 2 alone is insufficient to eliminate the bias.

5. **Thaler & Ziemba (1988, JEP)** — parimutuel betting anomalies: temporal mispricing in horse racing with analogous form to actuarial decay. Cross-market evidence that the mechanism is cognitive (not venue-specific); holds in financially-incentivised markets across decades.

6. **Wolfers & Zitzewitz (2006, NBER WP 10504)** — prediction market design and accuracy: systematic calibration deviations across PM platforms. Background structural evidence for actuarial overpricing persisting even when arbitrage is theoretically available.

7. **Berg, Forsythe, Nelson & Rietz (2008, Handbook)** — *Results from a Dozen Years of Election Futures Markets Research*: IEM binary contracts show systematic price-path lifecycle: overpricing compresses toward resolution but incompletely. Empirical price-path evidence analogous to actuarial ratio compression that fails to complete.

8. **Cen, Hillary & Wei (2013, JFE)** — *Analyst Forecast Anchoring and Stock Returns*: financially-incentivised professional analysts anchor to prior forecasts; adjustment is quantifiably insufficient (15–30% of correct revision magnitude). PM participants exhibit the same quantitative anchoring pattern. Bridges laboratory anchoring magnitude to financially-incentivised market behaviour.

9. **Moontower APY/time-to-resolution empirical fingerprint** — empirical PM yield analysis: negative APY/time relationship; contracts with shorter time-to-resolution yield higher annualised NO returns. Direct empirical fingerprint of actuarial decay not being priced into YES. The strongest single empirical anchor for the mechanism.

---

## Anti-Prim Escape Hatches

**(A) Mechanism absent (Gate 1 null result):** Gamma API calibration scan returns `overpricing_ratio < 1.30` in all three YES buckets [0.08–0.15], [0.15–0.25], [0.25–0.35] at final-14-day snapshot, with n ≥ 50/bucket. Mechanism not present at detectable magnitude → retire prim. Do not deploy.

**(B) λ wrong-direction (Gate 2 inversion):** `λ_MLE` calibrated against resolved markets shows `actuarial_yes(λ_MLE, T_i) < empirical_resolution_rate_i` systematically across any category → Poisson model overestimates decay speed relative to actual event arrival → λ is too low → recalibrate; do not deploy that category with wrong-direction λ.

**(C) Live performance failure:** Live NO win rate < 52% over first 30 Mode A trades → halt, run escape hatch A scan, reassess λ per-category. If Gamma scan still passes → examine catalyst gate false negatives (news velocity threshold may be wrong).

**(D) Signal frequency collapse:** < 10 qualifying Mode A events/year × 2 consecutive years → market participants have learned to decay YES appropriately → actuarial_ratio rarely reaches 1.50 threshold → mechanism compressing → suspend and reassess. May indicate regime shift (more sophisticated PM participants) rather than mechanism failure.

---

## Implementation

**Required components (build sequence):**

```
Phase 1 (Gates 1–2, no capital):
  src/strategies/time_decay_fade.py     — two-mode signal logic, λ lookup, all gates
  src/calibration/lambda_calibrator.py  — calibrate_lambda() MLE pipeline [BLOCKING Gate 2]
  src/calibration/gamma_scan.py         — gamma_calibration_scan() [BLOCKING Gate 1]
  src/filters/scheduled_event_veto.py   — is_scheduled_event() keyword regex helper
  src/feeds/news_velocity.py            — 72h catalyst velocity gate (Perplexity API / NLP)

Phase 2 (Gate 3, paper trading):
  src/paper/paper_trade_logger.py       — log qualifying signals + hypothetical outcomes
  src/analysis/lambda_cohort.py         — 6-month cohort stability validation

Phase 3 (Live deployment):
  Integration with src/risk/kelly.py    — fractional-kelly-sizing sophisticated (α=0.10 floor)
  λ escalation logic                    — promote from λ_UPPER to λ_MLE at n≥200
```

**Integration points:**
- `fractional-kelly-sizing` sophisticated: α=0.10 Kelly floor; escalate to 0.25 after Gate 2 matures (n≥200, RMSE≤0.015)
- `favourite-longshot-bias-fade` sophisticated: non-overlapping by YES < 0.08 boundary; if signal fires at YES 0.06 with long T → FLB prim is correct mechanism, NOT this one
- `obi-informed-directional` sophisticated: if time-decay signal fires AND OBI shows abnormal sell-side order imbalance on YES side → higher-conviction entry; not a dependency but a complementary confirmation

---

## Signal Frequency & Operating Parameters

| Parameter | Value | Basis |
|-----------|-------|-------|
| Mode A frequency | 8–15/year | Geopolitics_military λ=0.003 → ~5–8 geopolitics; legislative+executive add 3–7 |
| Mode B frequency | 12–35/year | Broader ratio/horizon window; all 4 categories |
| Combined A+B | 20–50/year | Conservative: 20–25; optimistic market expansion: 40–50 |
| N=30 (Mode A) | 24–48 months | 8–15 Mode A/year |
| N=30 (combined) | 8–18 months | 20–50 combined/year |
| Execution window | Hours–2 days | Not latency-sensitive; theta works passively |
| Expected WR (Mode A) | 58–68% | Derived from return table at ratio≥1.50, net of fees |
| Expected WR (Mode B) | 54–62% | Lower conviction; wider YES range includes closer-to-fair markets |
| Competitive moat | < 5 systematic operators globally (estimated) | Actuarial model + λ calibration required; not visual |

---

## Epistemic Quality

| Dimension | Naive | Intermediate | Sophisticated |
|-----------|-------|-------------|---------------|
| Sources | 5 | 7 | **9** (+Berg 2008, Cen 2013) |
| Certainty | guess | hypothesis | **hypothesis** (unchanged; own-data still zero) |
| Return quantification | none | none | **full table + fee-independence proof** |
| λ validation | prior estimates only | MLE methodology specified | **external base rates + CI bounds + conservative-use rule** |
| Deployment gates | 2 blocking checks | 2 blocking gates | **3-gate sequence (Gamma scan → λ MLE → paper trading)** |
| Competitive moat | mentioned | estimated | **5-barrier analysis + saturation threshold** |
| α escalation path | 0.10 floor only | 0.10 floor + gate 2 hook | **0.10 → 0.25 protocol with n≥200 trigger** |
| Limitations | listed | quantified | **quantified + λ_UPPER conservative mode during pre-calibration** |
