---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T23:31:48+10:00
cycle: 49
parent: naive/no-event-time-decay-fade
---

## Prim: no-event-time-decay-fade
**Level:** intermediate (refined from naive)
**Project:** polymarket
**Class:** 11th polymarket prim — temporal trajectory mechanism; 2nd elevation cycle

---

### Rule

```
actuarial_yes(λ, T) = 1 - exp(-λ × T)
actuarial_ratio = YES_market / actuarial_yes(λ_cat, days_remaining)

Mode A (high-conviction):
  actuarial_ratio ≥ 1.50
  AND days_remaining ≤ 14
  AND YES_market ∈ [0.08, 0.35]
  AND no_positive_catalyst_72h
  AND NOT scheduled_event_keyword_veto
  → BUY NO. α = 0.10 Kelly.

Mode B (standard):
  actuarial_ratio ≥ 1.30
  AND days_remaining ≤ 21
  AND YES_market ∈ [0.08, 0.35]
  AND no_positive_catalyst_72h
  AND NOT scheduled_event_keyword_veto
  → BUY NO. α = 0.10 Kelly.
```

**YES lower bound formalised at 0.08** (below = FLB prim territory; time-decay prim does not activate).

**Scheduled event keyword veto** (disqualifies a market from both modes):
- Keywords: "vote on", "election on", "scheduled meeting", "debate on [date]", "hearing on", "expires on"
- Mechanism: scheduled events are not Poisson — arrival date is known, actuarial model breaks down

**News velocity catalyst gate** (positive catalyst definition):
- ≥ 2 relevant articles in prior 72h mentioning the market's event name with positive framing
- OR any single wire/agency breaking news item (Reuters, AP, Bloomberg)

**λ lookup table** (empirical calibration BLOCKING — values below are prior estimates):

| Category | λ/day | Notes |
|----------|-------|-------|
| geopolitics_military | 0.003 | Low-frequency, sparse crises |
| legislative_passage | 0.005 | Moderate; excludes scheduled votes |
| executive_action | 0.008 | Higher frequency; memo/order pace |
| diplomatic_agreement | 0.002 | Lowest frequency; talks stall often |

---

### Mechanism

Binary PM contracts equivalent to binary call options. For Poisson-process events, fair YES = 1 − exp(−λ × T), which decays monotonically toward zero as days_remaining shrinks.

**Why the bias persists (two-layer mechanism):**

1. **Anchoring (cognitive layer)**: Kahneman & Tversky (1974) — traders anchor to listing-day YES price and adjust insufficiently as T decreases without event occurrence. The anchor is the initial listing price; the adjustment is insufficient, leaving YES systematically above actuarial fair value.

2. **Subeconomic return barrier (market structure layer)**: Ottaviani & Sørensen (2008) — at p=0.20 with T=7 days remaining, NO earns $0.80/contract which is financially recoverable. However, at extreme tails (p=0.05–0.08 range), NO earns only $0.05–0.08/contract; professional capital cannot profitably correct the overpricing because the per-contract return is below the friction floor. This is the same mechanism that preserves FLB at YES < 0.07 — the exploitable zone (YES 0.08–0.35) is where per-contract return is large enough for professional arbitrage IN PRINCIPLE, yet the cognitive anchor prevents market prices from adjusting. The time-decay prim occupies this niche: subeconomic barrier does not apply (return ≥ $0.65/contract), but anchoring prevents the market from decoding its own actuarial decay.

**Distinction from FLB (formalised):**

| Dimension | FLB Fade | Time-Decay Fade |
|-----------|----------|-----------------|
| Mechanism | Static probability weighting distortion (γ ≈ 0.65) | Dynamic: anchoring blocks temporal decay |
| YES range | 0.03–0.07 (any horizon) | **0.08–0.35** (final ≤ 21d only) |
| Variable | Current YES level | actuarial_ratio = YES / actuarial_fair(λ,T) |
| Persistence driver | Subeconomic return barrier (both modes) | Anchoring + insufficient time-to-arb for retail |
| PM category | Geopolitics only (FLB strongest) | Geopolitics, politics, legislative, executive |

The two prims are **non-overlapping by construction** via the YES ≥ 0.08 lower bound.

**Two-mode structure rationale:**

Mode A (≥1.50, T≤14): extreme overpricing in final two weeks. At T=14 with λ=0.003, actuarial_fair = 1−e^(−0.042) = 0.041; if YES=0.12, ratio = 2.9×. This magnitude requires genuine anchoring failure. Signal frequency: ~8–15/year.

Mode B (≥1.30, T≤21): moderate overpricing window. Broader net; includes cases where YES hasn't decayed enough for Mode A. Signal frequency: ~12–35/year.

Combined estimated frequency: **20–50 qualifying signals/year** across 4 categories. N=30 achievable in 8–18 months. Not latency-sensitive; execution window is hours-to-days.

---

### λ Calibration Methodology

**Pre-deployment BLOCKING gate** (in addition to Gamma scan):

```python
def calibrate_lambda(category: str, resolved_markets: list[dict]) -> float:
    """
    Pull resolved NO markets from Gamma API for category.
    Bin by (λ_candidate, T_at_snapshot) pairs.
    Minimize: sum((actuarial_yes(λ, T_i) - empirical_resolution_rate_i)^2)
    Return λ_MLE per category.
    """
    # T_i = days_remaining at position entry snapshot
    # empirical_resolution_rate = fraction that resolved YES in that bin
    # MLE via scipy.optimize.minimize_scalar over λ ∈ [0.001, 0.05]
    pass
```

**Calibration acceptance criteria:**
- n ≥ 50 resolved markets per category (not n≥20 — raised at intermediate level)
- Residual RMSE ≤ 0.02 (actuarial_yes(λ_MLE, T) vs empirical_resolution_rate)
- λ estimate stable across two independent 6-month cohorts

**Per-market λ override protocol:**
- If a market has a known resolution deadline (e.g. "Will X happen before Dec 31, 2026?"), use the deadline as T_max and recalculate λ from category base rate
- If market is FOMC-related or legislative calendar item → DISQUALIFY (Poisson inapplicable)

---

### Evidence

1. **Kahneman & Tversky (1974, Science)** — anchoring and adjustment: subjects anchor to starting value and adjust insufficiently. YES listing price = the anchor; temporal decay is the adjustment that doesn't happen.

2. **Manski (2006, JFE)** — Intrade contract probability persistence: contracts priced above or below rational Bayesian posteriors exhibit systematic persistence across resolution windows. Supports the anchoring model in financially-incentivised markets.

3. **Snowberg & Wolfers (2010, AER)** — *Explaining the Favourite-Longshot Bias*: misperception model (γ≈0.65) explains structural deviation from Bayesian updating in prediction markets. Directly supports why the bias is structural rather than correctable-by-arbitrage in the short run.

4. **Ottaviani & Sørensen (2008, JFE)** — subeconomic return mechanism at extreme tails: professional capital excluded when per-contract return falls below friction floor. Explains why FLB persists at YES < 0.07 AND why time-decay overpricing in the 0.08–0.35 range is corrected less than theory predicts.

5. **Thaler & Ziemba (1988, JEP)** — parimutuel betting anomalies: favourite-longshot and temporal mispricing in horse racing. Cross-market evidence that anchoring and probability weighting distortions are not PM-specific; they are cognitive.

6. **Wolfers & Zitzewitz (2006, NBER WP 10504)** — prediction market design and accuracy: systematic documentation of PM calibration deviations. Background evidence for the structural overpricing that actuarial ratio captures.

7. **Moontower APY/time-to-resolution fingerprint** — empirical PM yield analysis showing negative APY/time relationship: contracts with shorter time to resolution yield higher annualised returns when bought as NO. This is the empirical fingerprint of actuarial decay not being priced into YES.

---

### Blocking Validation

**Gate 1: Gamma API calibration scan** (unchanged from naive)
`gamma_calibration_scan()` against PM resolved markets: bin YES prices at final-14-days snapshot into [0.08–0.15] / [0.15–0.25] / [0.25–0.35] buckets. Pass = overpricing_ratio ≥ 1.30 in ≥ 2 buckets (n ≥ 50 each — raised from n≥20).

**Gate 2: λ empirical calibration** (raised standard from naive)
Per-category λ MLE calibration with n ≥ 50 resolved markets and RMSE ≤ 0.02. Both cohort stability and category coverage required.

**Both gates must pass before any capital deployment.**

---

### Anti-prim Escape Hatches

**(A) Mechanism absent**: Gamma scan returns overpricing_ratio < 1.30 in all three YES buckets [0.08–0.35, final 14d] with n ≥ 50/bucket → actuarial anchoring not present at detectable magnitude → retire prim.

**(B) λ systematically wrong**: λ_MLE calibrated against resolved markets shows predicted actuarial_yes LOWER than empirical resolution frequency in any category → Poisson model overestimates decay → recalibrate before any deployment; do not deploy with wrong-direction λ.

**(C) Live performance failure**: Live NO WR < 52% over first 30 Mode A trades → stop, run escape hatch A scan, reassess λ estimates.

**(D) Signal frequency collapse**: < 10 qualifying Mode A events/year × 2 consecutive years → market regime has changed (participants have learned to decay YES appropriately) → suspend and reassess.

---

### Implementation Gaps

1. `src/strategies/time_decay_fade.py` — not yet created; two-mode logic, λ lookup, keyword veto, catalyst gate
2. `CATEGORY_LAMBDA` calibration pipeline — `calibrate_lambda()` requires Gamma API resolved market pull (BLOCKING)
3. `gamma_calibration_scan()` — BLOCKING pre-deployment (raised n threshold: 50/bucket)
4. Catalyst monitoring (72h velocity gate) — NLP news feed or Perplexity API; manual acceptable for first 20 signals
5. Scheduled event keyword veto — regex pattern match on market question text; `is_scheduled_event()` helper
6. Integration with `fractional-kelly-sizing` sophisticated — α=0.10 floor until Gate 2 calibration confirms higher α justified

---

### Signal Frequency & Competitive Moat

- **Estimated frequency**: 20–50 qualifying signals/year (Mode A: ~8–15; Mode B: ~12–35)
- **N=30 horizon**: 8–18 months at combined rate
- **Execution window**: hours-to-days (not latency-sensitive)
- **Competitive moat**: Requires actuarial model + λ calibration; not a visual signal; no latency advantage for well-funded bots → structural edge accessible to quantitative but not algorithmic participants
- **Saturation risk**: Low; mechanism relies on retail anchoring which persists as long as PM contracts attract unscored participants

---

### Epistemic Quality

| Dimension | Naive | Intermediate |
|-----------|-------|-------------|
| Source | 5 (academic + empirical) | 7 (4 new academic) |
| Certainty | guess | **hypothesis** |
| Scope | narrow (single-variable ratio) | **context-aware (two-mode + YES range + veto)** |
| Falsifiability | partial (no anti-prim D) | **full (4 anti-prims A–D)** |
| Limitations | listed | **quantified (λ error direction, frequency bounds)** |
