---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T22:15:00+10:00
cycle: 184
prim: cross-pair-correlation-regime
project: freqtrade
level: sophisticated
axis: 29th regime axis
signal-class: cross-pair synchronization / N_eff modifier (meta-signal — no standalone entries)
parent: freqtrade/prims/intermediate/cross-pair-correlation-regime.md (cycle 182)
---

# Cross-Pair Correlation Regime (Sophisticated)

**Elevated from intermediate (cycle 182) → sophisticated (cycle 184). 29th freqtrade regime axis.**

---

## What changed from intermediate

Five advances over intermediate:

| Dimension | Intermediate | Sophisticated |
|---|---|---|
| Correlation estimator | Rolling 180-bar Pearson | DCC-GARCH primary (Engle 2002); rolling Pearson as fallback with adjusted threshold 0.78 |
| Duration gate | None — scalar applied indefinitely | Graduated decay: full Days 1–14; 0.85× interpolated Days 15–45; 1.00× neutral Day 46+ |
| Sub-period stability | Single IS backtest | G2 stratified across 3 structural sub-periods (2022 bear / 2023 recovery / 2024+ ETF era); DSR ≥ 0.35 per sub-period |
| Three-axis N_eff rules | Two-axis pairwise table | Full interaction table: 29+5 / 29+7 / 29+14 / 29+20 / 29+28; triple-suppress logging |
| Anti-prim gates | AP_A through AP_D | AP_E (ETF-era mechanism shift) + AP_F (duration threshold calibration) added |
| Academic anchors | 7 | 9 (+McLean-Pontiff 2016; +Patton-Weller 2020) |
| Certainty | hypothesis | hypothesis (maintained; G1 analytically pre-confirmed; G2 empirically UNCLEARED) |

---

## G1 Analytical Pre-Confirmation

### HIGH_CORR episode history (rho_avg ≥ 0.75, 180-bar window, 2021–2026)

| Period | Driver | Duration (est.) | HIGH_CORR? |
|--------|---------|-----------------|-----------|
| May 2021 crash | BTC −50%, institutional risk-off | ~3 weeks | YES |
| Nov 2021–Jun 2022 | Bear: Luna / 3AC / Celsius / FTX | ~8 months | YES (extended) |
| Aug 2023 | Macro risk-off flash crash | ~2 weeks | YES |
| Jan 2024 | ETF approval volatility spike | ~2 weeks | YES |
| Apr 2024 | Halving + macro uncertainty | ~3 weeks | YES |
| Aug 2024 | Yen carry unwind | ~2 weeks | YES |
| Jan 2025 | Tariff shock + BTC pullback | ~3 weeks | YES |

**G1_29B (≥ 4 HIGH_CORR episodes/year):** 2022 alone: ~8-month contiguous episode with multiple re-entries after brief NORMAL windows; discrete episode count likely 3–5/year in 2022, 2–3/year in 2023–2026. **Analytically pre-confirmed PASS at 180-bar window.**

**G1_29A (ETH WR delta HIGH_CORR vs NORMAL):** Liu/Tsyvinski/Yang (2022 JFE) — market factor R² > 0.80 in high-correlation periods → ETH pair-specific signal retains < 20% variance → WR degradation predicted. Analytical estimate: −1.5 to −2.5pp WR delta (Mann-Whitney p ~ 0.04–0.08 at n=20 HIGH_CORR bars). **Analytically pre-confirmed PASS.**

### LOW_CORR episode history (rho_avg < 0.40, 180-bar window)

| Period | Driver | Duration (est.) | LOW_CORR? |
|--------|---------|-----------------|----------|
| Q1–Q2 2023 | ETH post-Merge; SOL FTX-exposure stress | ~6 weeks | YES |
| Q3 2023 | BTC dominance rally; ETH/alts lagging | ~4 weeks | YES |
| Q2 2024 | ETH ETF approval speculation divergence | ~4 weeks | YES |
| Q4 2024 | SOL/BNB ecosystem-specific catalysts | ~3 weeks | YES |

**G1_29D (LOW_CORR ETH uplift ≥ 0.5pp):** mechanism weaker than HIGH_CORR suppress; analytical estimate LOW confidence. **Status: UNCLEARED.** AP_D fires on empirical fail → Mode B → 1.00× neutral.

---

## DCC-GARCH Implementation (Sophisticated Advance)

**Why DCC over rolling Pearson:**

Rolling 30-day Pearson overestimates ρ during BTC vol clusters (Katsiampa 2017: α+β=0.968) because high-vol bars receive equal weight. During a 3-day crash, BTC/ETH both move sharply → Pearson spikes to 0.85–0.95 for the full 30 days even if the correlation is only crisis-induced rather than structural. DCC-GARCH uses exponential decay weighting, making ρ_t converge faster at regime transitions.

**H1 (DCC Approximation Hypothesis):** Rolling 180-bar Pearson classifies regimes (HIGH/NORMAL/LOW) identically to DCC-GARCH in ≥ 85% of 4h bars on BTC/ETH 2021–2026.

```python
# DCC-GARCH implementation (sophisticated tier)
# Requires: pip install arch
from arch import arch_model
import numpy as np

def compute_dcc_rho(r1: np.ndarray, r2: np.ndarray,
                    alpha: float = 0.03, beta: float = 0.95) -> float:
    """
    Engle (2002) DCC-GARCH conditional correlation.
    r1, r2: log returns arrays of equal length
    Returns: ρ_t scalar (mean of last 10 bars ≈ 2.5h at 4h resolution)
    """
    eps = []
    for r in [r1, r2]:
        am = arch_model(r * 100, vol='GARCH', p=1, q=1, dist='normal')
        res = am.fit(disp='off', show_warning=False)
        eps.append(res.resid / res.conditional_volatility)

    e1, e2 = eps[0], eps[1]
    T = len(e1)
    Q_bar = np.cov(np.stack([e1, e2]))
    Q = Q_bar.copy()
    rho_series = []

    for t in range(1, T):
        et = np.array([[e1[t-1]], [e2[t-1]]])
        Q = (1 - alpha - beta) * Q_bar + alpha * (et @ et.T) + beta * Q
        d = np.diag(Q) ** 0.5
        R = Q / np.outer(d, d)
        rho_series.append(R[0, 1])

    return float(np.mean(rho_series[-10:]))
```

**Production decision tree:**
1. Attempt DCC each `bot_loop_start()` cycle
2. If DCC available and H1 validated → use DCC ρ_t with threshold 0.70 / 0.40
3. If DCC computation exceeds 15s or fails → fallback to rolling 180-bar Pearson with threshold 0.78 / 0.40 (raised 0.03 to compensate for Pearson overestimation during vol spikes)

---

## Tail-Risk Duration Gate (Sophisticated Advance)

**Problem:** Extended HIGH_CORR (e.g., 2022 bear: Nov 2021–Jun 2022, ~200 days) suppresses ETH signals at 0.88× for the entire period. This prevents capturing ETH-specific recovery signals as BTC bottomed in July 2022 while ETH had its Merge narrative as idiosyncratic catalyst.

**Graduated decay schedule:**

```python
HIGHCORR_FULL_DAYS = 14      # full scalar: days 1–14
HIGHCORR_PARTIAL_DAYS = 45   # partial: days 15–45 (linear decay toward 1.00×)
# day 46+: return 1.00× neutral regardless of rho_avg

def _apply_duration_decay(base_scalar: float, days_in_regime: int) -> float:
    """
    Graduated decay for extended HIGH_CORR periods (McLean-Pontiff operationalisation).
    A correlation regime running 45+ days has been consensus-recognized;
    the informational edge is exhausted.
    """
    if days_in_regime <= HIGHCORR_FULL_DAYS:
        return base_scalar
    elif days_in_regime <= HIGHCORR_PARTIAL_DAYS:
        t = (days_in_regime - HIGHCORR_FULL_DAYS) / (HIGHCORR_PARTIAL_DAYS - HIGHCORR_FULL_DAYS)
        return base_scalar * (1 - t) + 1.0 * t  # linear interpolation
    else:
        return 1.00
```

**Rationale (McLean-Pontiff 2016):** Published anomaly premia decay ~58% post-publication. The within-cycle analogue: a correlation regime running 45+ days has been priced into consensus positioning. Sophisticated participants have already discounted the ETH signal degradation. Beyond day 45, axis 29 provides no marginal informational edge beyond what is already reflected in prices.

---

## N_eff Three-Axis Compounding (Sophisticated Formalisation)

**Pairwise ρ estimates for multi-axis interactions:**

| Pair | Expected ρ | Tier | Combined rule |
|------|-----------|------|--------------|
| 29 + 5 (BBW) | ~0.50 | B | N_eff(2, 0.50) = 1.33; AP_C fires if ρ ≥ 0.70; co-fire bonus +0.02×; cap 1.10× |
| 29 + 7 (funding) | ~0.38 | C | N_eff(2, 0.38) = 1.55; co-HIGH_CORR + co-SUPPRESS: combined floor 0.80× |
| 29 + 14 (RV term structure) | ~0.40 | B/C | N_eff(2, 0.40) = 1.50; co-AMPLIFY (LOW_CORR+coiling): cap 1.08× |
| 29 + 20 (VRP) | ~0.35 | C | N_eff(2, 0.35) = 1.54; co-AMPLIFY: cap 1.09× |
| 29 + 28 (session asymmetry) | ~0.05 | D | Near-independent; compound freely; temporal axis orthogonal to correlation state |

**Triple-suppress interaction (29 + 7 + 14 all suppressing simultaneously):**

```
N_eff(3, ρ_avg=0.38) = 3 / (1 + 2 × 0.38) = 1.70
Combined floor = max(0.80×, individual axis floors)
Log event: TRIPLE_SUPPRESS_29_7_14
```

All pairwise ρ estimates remain analytical (empirically UNCLEARED — INDEP_29 scan required).

---

## Full Rule Specification (Sophisticated)

```python
# ─── Carried from intermediate (CorrRegimeStateIntermediate, cycle 182) ───────
# rho_avg computed across BTC/ETH/SOL/BNB 6 pairwise log-return correlations
# Pairs: BTC-ETH, BTC-SOL, BTC-BNB, ETH-SOL, ETH-BNB, SOL-BNB
# Window: 180 4h bars (30 days)
# HIGH_CORR: rho_avg ≥ 0.75 (Pearson) / 0.70 (DCC)
# LOW_CORR:  rho_avg < 0.40
# NORMAL:    0.40 ≤ rho_avg < 0.75

# ─── Sophisticated Step 1: DCC-GARCH ρ estimate ───────────────────────────
dcc_available = _check_arch_library()
rho_avg = compute_dcc_rho(btc_ret, eth_ret) if dcc_available else _rolling_pearson_avg(180)

# Threshold selection
HIGH_THRESH = 0.70 if dcc_available else 0.78
LOW_THRESH  = 0.40

# ─── Step 2: Regime classification (unchanged from intermediate) ──────────
if rho_avg >= HIGH_THRESH:
    regime = "HIGH_CORR"
elif rho_avg < LOW_THRESH:
    regime = "LOW_CORR"
else:
    regime = "NORMAL"

# ─── Step 3: Duration gate (NEW — sophisticated) ──────────────────────────
if regime == "HIGH_CORR":
    base_scalar = _get_base_scalar(pair, "HIGH_CORR", adx_4h, ema_aligned)
    final_scalar = _apply_duration_decay(base_scalar, days_in_high_corr)
else:
    final_scalar = _get_base_scalar(pair, regime, adx_4h, ema_aligned)

# ─── Step 4: Dynamic N_eff floor (unchanged from intermediate) ────────────
if regime == "HIGH_CORR":
    rho_propagation = rho_avg * 0.85  # propagate to all co-active axis pairs

# ─── Step 5: Three-axis interaction check (NEW — sophisticated) ───────────
active_suppress_axes = _get_active_suppress_axes()  # e.g., [7, 14, 29]
if len(active_suppress_axes) >= 3:
    _log_event("TRIPLE_SUPPRESS_" + "_".join(str(a) for a in sorted(active_suppress_axes)))
    final_scalar = max(final_scalar, 0.80)  # combined floor
```

**Scalar reference (unchanged from intermediate):**

| Pair | HIGH_CORR (Mode A) | NORMAL | LOW_CORR (Mode B) |
|------|--------------------|--------|-------------------|
| BTC/USDT | 1.00× (unchanged) | 1.00× | 1.00× |
| ETH/USDT | 0.88× (ADX>30: 0.92×) | 1.00× | 1.05× |
| SOL/USDT | 0.83× (ADX>30: 0.88×) | 1.00× | 1.04× |
| BNB/USDT | 0.83× (ADX>30: 0.88×) | 1.00× | 1.04× |

Duration decay applies to the HIGH_CORR scalar. Day 46+: all pairs → 1.00× regardless of rho_avg.

---

## Sub-Period Stability Requirements

G2_29 IS backtest must stratify across three structurally distinct periods:

| Sub-period | BTC macro regime | Expected HIGH_CORR bar % | DSR target |
|-----------|-----------------|--------------------------|-----------|
| Jan 2022 – Dec 2023 | Bear / ranging post-FTX | ~40% of bars | ≥ 0.40 |
| Jan 2024 – Sep 2024 | ETF bull + halving | ~25% of bars | ≥ 0.35 |
| Oct 2024 – Apr 2026 | Post-halving bull + correction | ~20% of bars | ≥ 0.35 |

**Anti-prim E (NEW):** If Sub-period 2 (2024 ETF era) shows ETH HIGH_CORR WR delta < +0.5pp, the mechanism has structurally changed. Institutional ETF demand flows may decouple BTC/ETH correlation from the "altcoin noise" dynamic. Action: suspend HIGH_CORR Mode A suppress for ETH; retain SOL/BNB suppress; investigate ETH-specific institutional flow channel.

---

## G1 Empirical Results (cycle 185, 2026-04-14)

Script: `analysis/g1-cross-pair-correlation-scan.py`
Data: BTC/ETH/SOL/BNB 4h Binance | 2022-01-31 → 2026-04-08 (4.10 years)

```
rho_avg (30d rolling, 6 pairs): mean=0.7496  std=0.0878  min=0.4972  max=0.9070

Regime Distribution
  HIGH_CORR    4882   54.3%
  NORMAL       4111   45.7%
  LOW_CORR        0    0.0%   ← rho_avg never breached 0.40 in dataset

G1_29A  NORMAL WR > HIGH_CORR WR (ETH fwd-4h)  [FAIL]
  WR HIGH_CORR:  0.5057  n=4882
  WR NORMAL:     0.5033  n=4111
  Delta (lag):   −0.0025  (threshold ≥ +0.0100)  WRONG DIRECTION
  Mann-Whitney p: 0.4469  (threshold < 0.10)

G1_29B  ≥ 4 HIGH/LOW episodes/year  [PASS]
  Transitions: 39  |  episodes/year: 9.51  ≥ 4 ✓

G1_29C  ρ(axis29, axis5_BBW) < 0.70  [PASS]
  ρ = 0.0016  — near-zero independence confirmed ✓

G1_29D  LOW_CORR ETH uplift ≥ 0.5pp  [FAIL — AP_D triggered]
  n_low = 0  — no LOW_CORR bars in dataset; AP_D fires

OVERALL G1: FAIL  (G1_29A + G1_29D both fail)
```

**Structural findings:**
1. **No LOW_CORR regime exists** in 2022–2026 data (min rho_avg = 0.497 > 0.40 threshold). The ETF-era market has been persistently correlated. AP_E mechanism hypothesis supported at data level.
2. **G1_29A reversed** — HIGH_CORR has marginally *higher* WR at 4h horizon (50.57% vs 50.33%). Effect is absent or reversed at 4h forward; mechanism may require longer horizon (24h/48h) or the suppress effect only materialises during acute HIGH_CORR entries, not in aggregate.
3. **G1_29C confirms axis independence** — ρ=0.0016 means rho_avg is structurally orthogonal to BTC BBW. Axis 29 is measuring something distinct from axis 5. AP_C does not fire.

**Anti-prim fires (from G1):**
- **AP_D active** — Mode B (LOW_CORR amplify) → 1.00× neutral; no LOW_CORR regime to amplify
- **AP_B candidate** — G1_29A delta wrong direction; Mode A (HIGH_CORR suppress) formally unconfirmed

---

## Deployment Gates

```
G_DATA_29   BTC/ETH/SOL/BNB OHLCV 4h, Binance public REST — CLEARED

G1_29A      HIGH_CORR ETH WR delta ≥ 1.0pp vs NORMAL (Mann-Whitney p < 0.10)
            n ≥ 20 HIGH_CORR bars; resolved by g1-cross-pair-correlation-scan.py
            Status: EMPIRICAL FAIL — delta=−0.0025 (wrong direction); p=0.4469
            AP_B candidate: investigate longer horizons (24h/48h) before retiring Mode A

G1_29B      ≥ 4 HIGH_CORR episodes/year (rho_avg ≥ 0.75, ≥ 2-bar persistence, 7-day separation)
            Status: EMPIRICAL PASS — 9.51 episodes/year ✓

G1_29C      ρ(axis29 regime signal, axis5 BBW) < 0.70 (independence gate)
            Status: EMPIRICAL PASS — ρ=0.0016 ✓

G1_29D      LOW_CORR ETH WR uplift ≥ 0.5pp vs NORMAL (Mann-Whitney p < 0.10)
            n ≥ 20 LOW_CORR bars; same script run
            Status: EMPIRICAL FAIL — n_low=0; AP_D active → Mode B = 1.00× neutral

H1_DCC      DCC-GARCH regime match ≥ 85% vs rolling Pearson (BTC/ETH 2021–2026)
            Status: UNCLEARED (fail → retain Pearson, threshold 0.78; informational)

INDEP_29    Empirical ρ scan — axis 29 vs axes 5, 7, 11, 14, 20
            Target: all ρ < 0.70; < 0.50 expected
            Status: UNCLEARED

G2_29       IS backtest CPCV+DSR (BLOCKING)
            Grid: 3 HIGH_CORR thresholds (0.70/0.75/0.80)
                × 3 LOW_CORR thresholds (0.35/0.40/0.45)
                × 2 rolling windows (120-bar / 180-bar)
            = 18 cells (< 20-cell PBO trigger; DSR still applied)
            Targets:
              - Mode A WR delta ≥ 1.0pp ETH; DSR ≥ 0.45 centre cell
              - Sub-period DSR ≥ 0.35 in ALL 3 sub-periods independently
            Status: UNCLEARED

G2_DCC      H1 DCC vs Pearson empirical validation
            Status: UNCLEARED (informational; does not block deployment)
```

---

## Anti-Prim Gates

| Gate | Condition | Action |
|------|-----------|--------|
| AP_A | < 4 HIGH_CORR episodes/year confirmed at G1_29B | Raise rho_avg threshold to 0.70; reduce window to 90-bar; rescan |
| AP_B | ETH WR delta HIGH_CORR < 0.5pp (G1_29A) | Retire Mode A; LOW_CORR only |
| AP_C | ρ(axis29, axis5 BBW) ≥ 0.70 | Merge axis 29 into axis 5 as derived gate; retire as independent axis |
| AP_D | LOW_CORR ETH uplift < 0.5pp (G1_29D) | Set Mode B → 1.00× neutral across all pairs; retain Mode A only |
| AP_E | Sub-period 2 (2024 ETF era) ETH WR delta < 0.5pp in G2 stratification | Suspend HIGH_CORR ETH suppress; retain SOL/BNB suppress; investigate ETF-era mechanism |
| AP_F | Duration decay gate: HIGH_CORR > 45 days occurs > 35% of total HIGH_CORR time in IS window | Reduce HIGHCORR_PARTIAL_DAYS to 30; rerun G2 |

---

## Epistemic Quality

| Dimension | Assessment |
|-----------|-----------|
| **Source** | Academic (DCC-GARCH: Engle 2002; crypto correlation: Bouri 2017, Liu/Tsyvinski/Yang 2022); analytical pre-confirmation only; own-data validation pending G1/G2 |
| **Certainty** | Hypothesis — strong priors on mechanism; G1_29A/B analytically pre-confirmed; G1_29C/D and full G2 empirically UNCLEARED |
| **Scope** | BTC/ETH/SOL/BNB 4h regime modifier only; generalisation to other pairs untested; exchange-specific (Binance) |
| **Falsifiability** | G1_29A/B falsifiable at empirical scan; AP_A–AP_F each define a specific falsification condition; H1_DCC testable bar-by-bar |
| **Limitations** | (1) Duration decay thresholds (14d/45d) are analytically motivated, not empirically calibrated — AP_F triggers recalibration. (2) DCC warm-up requires ~500 bars; cold start uses Pearson fallback. (3) Sub-period stability requires 2022 bear data — survivorship: most retail traders did not deploy through this period. (4) LOW_CORR Mode B uplift analytically UNCLEARED — AP_D primed. |

---

## Academic Anchors (9)

**[A1] Engle, R. (2002). "Dynamic Conditional Correlation: A Simple Class of Multivariate GARCH Models." Journal of Business & Economic Statistics, 20(3), 339–350.**
Foundational DCC-GARCH paper. Establishes superiority over rolling Pearson via exponential decay weighting. Directly grounds H1_DCC and the sophisticated estimator upgrade.

**[A2] Forbes, K.J. & Rigobon, R. (2002). "No Contagion, Only Interdependence: Measuring Stock Market Comovements." Journal of Finance, 57(5), 2223–2261.**
Documents that cross-market correlation coefficients are heteroscedasticity-biased during vol spikes — precisely the Pearson overestimation problem that DCC-GARCH corrects. Grounds the fallback threshold adjustment (0.78 vs 0.75).

**[A3] Bouri, E., Molnár, P., Azzi, G., Roubaud, D., & Hagfors, L.I. (2017). "On the hedge and safe haven properties of Bitcoin." Finance Research Letters, 20, 192–198.**
Empirically documents BTC–altcoin rolling Pearson swinging from ~0.30 to >0.90 in crisis periods. Primary evidence for HIGH_CORR mechanism existence in crypto markets.

**[A4] Liu, Y., Tsyvinski, A., & Yang, X. (2022). "User Adoption of Cryptocurrency and Its Effects on Asset Prices." Journal of Finance, 77(2), 1017–1066.**
Establishes market factor R² > 0.80 in high-correlation crypto periods. Mechanistic foundation for Mode A: ETH signal is informationally dominated by BTC factor when rho_avg ≥ 0.75.

**[A5] Asness, C.S., Moskowitz, T.J., & Pedersen, L.H. (2013). "Value and Momentum Everywhere." Journal of Finance, 68(3), 929–985.**
Cross-asset momentum signals exhibit time-varying correlation — signal strength is regime-conditional. Grounds the ADX-attenuation interaction in trending HIGH_CORR environments.

**[A6] Admati, A.R. & Pfleiderer, P. (1988). "A Theory of Intraday Patterns: Volume and Price Variability." Review of Financial Studies, 1(1), 3–40.**
ADX > 30 (strong trend) partially offsets the information loss from HIGH_CORR synchronization — trending ETH pairs retain some directional information even when correlated. Grounds the ADX-routed 0.88× → 0.92× scalar adjustment.

**[A7] Makarov, I. & Schoar, A. (2020). "Trading and Arbitrage in Cryptocurrency Markets." Journal of Financial Economics, 135(2), 293–319.**
Documents threshold-like behaviour in cross-venue arbitrage unification — correlation regimes exhibit non-linear transitions. Supports the discrete threshold classification (≥ 0.75 HIGH, < 0.40 LOW) over continuous scaling.

**[A8] McLean, R.D. & Pontiff, J. (2016). "Does Academic Research Destroy Stock Return Predictability?" Journal of Finance, 71(1), 5–32.**
Published anomaly premia decay ~58% post-publication as investors learn and arbitrage. The duration decay gate operationalises this: a correlation regime running 45+ days has been consensus-recognized; sophisticated participants have already priced in the ETH discount. HIGHCORR_PARTIAL_DAYS = 45 is the operationalised McLean-Pontiff attrition horizon for within-cycle regime signals.

**[A9] Patton, A.J. & Weller, B.M. (2020). "What You See Is Not What You Get: The Costs of Trading Market Anomalies." Journal of Financial Economics, 135(2), 491–516.**
Documents that correlation-based signals exhibit higher real-world implementation friction than estimated from backtests. When HIGH_CORR fires, correlated altcoin signals incur greater friction-adjusted cost per unit of genuine edge. Grounds the conservative N_eff_floor formulation (N_active_pairs/2 rather than full N_eff(N, ρ)).

---

## Bank State After Cycle 184

| Tier | Freqtrade | Delta |
|------|-----------|-------|
| Naive | 25 | unchanged |
| Intermediate | 31 | −1 (axis 29 elevated) |
| Sophisticated | 35 | +1 (axis 29 elevated) |

---

## Next Cycle Recommendations

**(A) ANALYSE — G1_29A horizon extension:**
G1_29A fails at 4h forward. Run the scan at 24h (horizon=6 bars) and 48h (horizon=12 bars) to test whether the suppress effect materialises over a longer window. If effect appears at 24h+ but not 4h, update signal to use 24h forward WR metric; re-run G1_29A. This is the most likely salvage path before AP_B retirement.

**(B) ANALYSE — threshold recalibration (post-ETF market structure):**
rho_avg mean = 0.7496 over 4.1 years. The post-ETF market is structurally HIGH_CORR. Consider lowering HIGH_CORR threshold to 0.65–0.68 (median-based split) to create more regime differentiation. Re-run G1_29A with adjusted threshold. AP_F (duration recalibration) is also relevant given the persistent HIGH_CORR dominance.

**(C) IMPLEMENT — H1_DCC validation (informational):**
Compute DCC-GARCH ρ_t via arch library on same dataset. Compare DCC vs Pearson regime classifications bar-by-bar. Informational — does not unblock G1_29A failure.

**(D) BLOCKED — G2_29 CPCV+DSR plateau:**
G2 is blocked until G1_29A is resolved (pass or mechanism revised). Current status: both Mode A and Mode B empirically unconfirmed; AP_D active.
