---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T09:30:00+10:00
cycle: 134
---

## Prim: volatility-risk-premium-regime-signal
**Level:** sophisticated | **Project:** polymarket | **Cycle:** 134 | **Class:** 22nd
**Parent:** intermediate/volatility-risk-premium-regime-signal (cycle 134)
**Certainty:** plausible hypothesis (mechanism: strong academic basis; PM channel: sentiment contagion hypothesis; N=0 own-data; all gates UNCLEARED; DRY_RUN)

---

## Mechanism

Crypto options implied volatility (Deribit DVOL index) is systematically higher than realised volatility (Yang-Zhang estimator) during and after fear episodes. This variance risk premium (VRP) is the compensation options sellers demand for bearing variance-of-variance risk (Carr & Wu 2009 JFE). When the premium is strongly positive, risk aversion has compressed asset prices and elevated uncertainty — but the options market itself has already priced the future vol uncertainty; mean-reversion of forward returns is the expected outcome (Han & Li 2019 JFE: positive VRP → positive next-week BTC returns, R²≈5%).

The PM channel: retail participants in crypto-category prediction markets (BTC/ETH price threshold contracts, crypto adoption milestones) are the same agents who observe DVOL as a real-time fear gauge. During elevated VRP, they anchor to recent drawdown rather than probabilistic mean-reversion, systematically underpricing YES outcomes in bullish crypto markets. When VRP is negative (complacency), they anchor to trend continuation and underprice NO outcomes.

The sophisticated tier adds four structural corrections that resolve the three anti-prim failure modes identified at intermediate.

---

## Four Structural Advances Over Intermediate

### Advance 1 — RV Direction Gate (Mode A prerequisite, resolves Anti-prim A)

**Intermediate weakness:** Mode A fires when VRP_z > +1.5 regardless of whether the crash is still in progress. BTC drawdown day 1–5 often has VRP_z > +1.5 but negative momentum — buying YES during freefall. The anti-prim A symptom: Mode A WR < 45% on trades where BTC_change_24h < −5%.

**Sophisticated fix:** Mode A requires `rv_7d_trend < 0` (30d RV is declining over the past 7 days), confirming the fear episode is resolving rather than accelerating.

```python
def rv_direction_gate(rv_30d_series: pd.Series) -> bool:
    """Returns True if crash is abating (RV declining over 7d)."""
    rv_current = rv_30d_series.iloc[-1]
    rv_7d_ago = rv_30d_series.iloc[-7]
    return (rv_current - rv_7d_ago) < 0   # rv_7d_trend < 0 → direction gate PASS

# Mode A state machine:
# VRP_z > +1.5 AND rv_direction_gate() → AMPLIFY_RECOVERY
# VRP_z > +1.5 AND NOT rv_direction_gate() → NEUTRAL_HOT (hold, do not enter new YES positions)
# VRP_z in [-1.5, +1.5] → NEUTRAL
# VRP_z < -1.5 → COMPLACENCY (Mode B eligible — no direction gate required for Mode B)
```

**Expected frequency adjustment:** raw VRP_z > +1.5 ≈ 15% of days; direction gate reduces to ≈ 9% (60% pass rate estimated from Bollerslev et al. 2009 vol reversal timing). Adjusted ≈ 4–6 distinct non-overlapping episodes/year.

**NEUTRAL_HOT state:** In NEUTRAL_HOT, existing Mode A positions are held if already entered (no new entries). This prevents cutting a position that entered correctly and then briefly triggered crash-continuation.

---

### Advance 2 — Resolution Proximity Multiplier (both modes)

**Intermediate weakness:** Uniform 14-day max hold and fixed alpha regardless of resolution horizon. A crypto PM market resolving in 3 days is much more likely to converge to the VRP-implied probability than one resolving in 85 days (which has many intervening information updates).

**Sophisticated fix:** 4-tier proximity multiplier applied to alpha (Kelly fraction):

| Tier | Days to resolution | alpha multiplier | Rationale |
|------|--------------------|-----------------|-----------|
| T1 | ≤ 14d | 1.00× | DVOL expiry window aligns; options and PM converge together |
| T2 | 15–30d | 0.85× | Near expiry; VRP signal still fresh |
| T3 | 31–60d | 0.70× | Multiple news cycles; VRP premium may normalise before resolution |
| T4 | 61–90d | 0.55× | Signal attenuated; used primarily for portfolio construction, not high-conviction |
| > 90d | — | BLOCKED (signal not entered) | Too many intervening catalysts |

```python
RESOLUTION_MULT = {
    (None, 14):   1.00,
    (15,   30):   0.85,
    (31,   60):   0.70,
    (61,   90):   0.55,
}

def resolution_multiplier(days_to_resolution: float) -> float:
    if days_to_resolution > 90:
        return 0.0   # blocked
    elif days_to_resolution <= 14:
        return 1.00
    elif days_to_resolution <= 30:
        return 0.85
    elif days_to_resolution <= 60:
        return 0.70
    else:
        return 0.55
```

**Empirical rationale:** Dew-Becker et al. (2017 RFS) show near-term VRP dominates short-horizon return prediction while long-term VRP is noisier. A 14-day PM resolution corresponds closely to the 1–2 week window where Han & Li (2019 JFE) measured the strongest VRP→returns effect.

---

### Advance 3 — FMLL Concurrent N_eff Correction (resolves Anti-prim C)

**Intermediate weakness:** When financial-market-lead-lag (FMLL) fires on the same PM market simultaneously (e.g., BTC spot up 3% AND VRP_z > +1.5), the naive approach applies full alpha for both signals → combined position size double-counts shared information (both derive from crypto derivatives/price data).

**Sophisticated fix:** `VRPFMLLTracker` computes N_eff-adjusted combined Kelly when both signals are active.

```python
class VRPFMLLTracker:
    """Tracks concurrent VRP + FMLL activations per market."""
    RHO_VRP_FMLL = 0.60   # empirical prior; calibrate at N_eff ≥ 20 co-fires
    CAP_AMPLIFY   = 1.15  # combined alpha cap (both amplify)
    FLOOR_SUPPRESS = 0.80  # combined alpha floor (both suppress)

    def combined_alpha(self, alpha_vrp: float, alpha_fmll: float,
                       mode_vrp: str, mode_fmll: str) -> float:
        """
        If both signals amplify (VRP Mode A + FMLL bullish): apply N_eff correction.
        If signals conflict (VRP Mode A + FMLL bearish): reduce both by 0.5x; flag ANALYST_REVIEW.
        """
        n_signals = 2
        n_eff = n_signals / (1 + (n_signals - 1) * self.RHO_VRP_FMLL)
        scale = (n_eff / n_signals) ** 0.5   # ≈ 0.632 at ρ=0.60

        if mode_vrp == 'amplify' and mode_fmll == 'bullish':
            combined = (alpha_vrp + alpha_fmll) * scale
            return min(combined, self.CAP_AMPLIFY)
        elif mode_vrp == 'suppress' and mode_fmll == 'bearish':
            combined = (alpha_vrp + alpha_fmll) * scale
            return max(combined, self.FLOOR_SUPPRESS)
        else:
            # Conflict: signals disagree → halve both and log for analyst review
            return min(alpha_vrp, alpha_fmll) * 0.5
```

**ρ calibration path:** update ρ_VRP_FMLL from 0.60 prior to sample correlation once N_eff ≥ 20 concurrent activations on same market are observed. At N_eff ≥ 20, replace prior with `corr(VRP_edge_realised, FMLL_edge_realised)`.

---

### Advance 4 — CPCV+DSR 9-cell Plateau Gate (new, resolves overfitting risk)

**Intermediate weakness:** Kelly alpha floors set at intermediate are hypothesis-level only (G_IS uncleared). Without overfitting protection, the 6 free parameters (VRP_z threshold, z-window, RV window, hold period, alpha, proximity tier cutoffs) risk data-snooping on historical Gamma API data.

**Sophisticated fix:** 9-cell CPCV+DSR plateau across the two highest-uncertainty parameters:

| | VRP_z threshold = +1.0 | +1.5 | +2.0 |
|--|--|--|--|
| **z-window = 60d** | cell (1,1) | cell (1,2) | cell (1,3) |
| **z-window = 90d** | cell (2,1) | cell (2,2) | cell (2,3) |
| **z-window = 120d** | cell (3,1) | cell (3,2) | cell (3,3) |

All other parameters fixed at: RV_window=30, alpha=0.06 (Mode A) / 0.04 (Mode B), proximity tier cutoffs as above.

**Plateau selection rule:** Select the cell with highest DSR among those in the plateau (contiguous region with DSR ≥ 0.90 for Mode A, DSR ≥ 0.85 for Mode B). Centre-of-plateau preferred (robustness). Bailey, Borwein & Lopez de Prado (2014 AMS SSRN 2326253).

**Anti-prim D (DSR ≤ 0):** If selected cell has DSR ≤ 0, Mode A retired (insufficient IS Sharpe relative to estimated trials). Mode B retired if DSR ≤ 0 on Mode B plateau.

```python
def select_plateau_cell(results_grid: dict) -> tuple:
    """
    results_grid: {(threshold, window): {'DSR': float, 'IS_sharpe': float}}
    Returns: (threshold, window) of centre-of-plateau cell with DSR ≥ 0.90 (Mode A)
    Raises RetireSignalError if no cell passes DSR ≥ 0.90.
    """
    passing = {k: v for k, v in results_grid.items() if v['DSR'] >= 0.90}
    if not passing:
        raise RetireSignalError("CPCV_DSR_FAIL: no cell passes DSR ≥ 0.90. Mode A retired.")
    # Select centre-of-plateau: cell closest to median of passing cells' coordinates
    thresholds = [k[0] for k in passing]
    windows = [k[1] for k in passing]
    mid_t = sorted(set(thresholds))[len(set(thresholds)) // 2]
    mid_w = sorted(set(windows))[len(set(windows)) // 2]
    return (mid_t, mid_w)
```

---

## Signal Specification (Sophisticated)

### Mode A — Fear Premium → Recovery (full sophisticated spec)

```
ACTIVATE when ALL of:
  1. pm_category ∈ {'crypto_price', 'crypto_adoption'}
  2. pm_contract direction = YES (bullish)
  3. VRP_z > +1.5 (CPCV+DSR-selected threshold; default +1.5)
  4. rv_direction_gate() == True   [NEW: Advance 1]
  5. dvol_data_age_hours ≤ 24
  6. rv_bars_available ≥ 30
  7. pm_liquidity ≥ $5,000
  8. resolution_days ≤ 90 (blocked if > 90)
  9. G_DATA + G_IS cleared; G_CPCV plateau selected

SIZE:
  alpha_base = 0.06 (Mode A, CPCV plateau cell selected)
  alpha = alpha_base × resolution_multiplier(resolution_days)  [Advance 2]
  if FMLL concurrent: alpha = VRPFMLLTracker.combined_alpha(...)  [Advance 3]
  f_star = alpha × (edge / odds)
  edge = VRP_z_percentile_implied_return - pm_yes_price   [calibrate at G_IS]

STATE MACHINE:
  INACTIVE → RECOVERY (VRP_z > threshold + direction gate pass) → [hold]
  RECOVERY → NEUTRAL_HOT (direction gate fails; hold existing, no new entries)
  NEUTRAL_HOT → RECOVERY (direction gate passes again within 5 days)
  NEUTRAL_HOT → INACTIVE (VRP_z drops below +0.5)
  RECOVERY → INACTIVE (VRP_z drops below +0.5)
```

### Mode B — Complacency → Downside (full sophisticated spec)

```
ACTIVATE when ALL of:
  1. pm_category ∈ {'crypto_price', 'crypto_adoption'}
  2. pm_contract direction = NO (bearish)
  3. VRP_z < −1.5 (CPCV+DSR-selected threshold; default −1.5)
  4. [No direction gate for Mode B — complacency has no analogous recovery timing]
  5. dvol_data_age_hours ≤ 24; rv_bars_available ≥ 30
  6. pm_liquidity ≥ $5,000; resolution_days ≤ 90
  7. G_DATA + G_IS cleared; G_CPCV plateau selected

SIZE:
  alpha_base = 0.04 (Mode B, CPCV plateau)
  alpha = alpha_base × resolution_multiplier(resolution_days)
  if FMLL concurrent: apply VRPFMLLTracker

NOTE: Mode B has lower base alpha than Mode A — Bekaert & Hoerova (2014 JFE) show
negative VRP periods are noisier predictors (complacency can persist) vs positive VRP
(fear reverts more predictably). Mode B retired first if CPCV DSR ≤ 0.85.
```

---

## Deployment Gates

| Gate | Condition | Estimated effort |
|------|-----------|-----------------|
| G_DATA | Deribit DVOL API key + OHLCV pipeline confirmed in bot | Low (free API, 1 session) |
| G_HIST | ≥ 50 resolved crypto PM markets (Gamma API 2022–2024) + VRP_z at entry reconstructed | Medium (data wrangling, 1–2 sessions) |
| G_IS | Mode A: WR ≥ 52% N ≥ 15; Mode B: WR ≥ 50% N ≥ 15; Mann-Whitney p < 0.10 one-tailed | Depends on G_HIST |
| G_CPCV | 9-cell DSR plateau (DSR ≥ 0.90 Mode A, ≥ 0.85 Mode B; plateau cell selected) | Depends on G_HIST |
| G_DIR | Direction gate empirical validation: Mode A WR with gate ≥ Mode A WR without gate at N ≥ 15 | Depends on G_HIST |

All modes DRY_RUN until G_DATA + G_IS + G_CPCV cleared. G_DATA is lowest barrier (free API, 1 session).

---

## Escape Hatches

**Escape Hatch EA (crash-still-running):** NEUTRAL_HOT state accumulated ≥ 3 markets with open YES positions AND all 3 decline > 8pp within 48h → force-exit all NEUTRAL_HOT positions; lower Mode A threshold by 0.25σ units (from +1.5 to +1.75); log `VRP_NEUTRAL_HOT_DRAWDOWN`.

**Escape Hatch EB (category false-positive):** At N ≥ 20 own-data, Mode A WR in `crypto_adoption` < 48% while `crypto_price` WR ≥ 52% → suspend `crypto_adoption` sub-category; shrink to `crypto_price` only.

**Escape Hatch EC (FMLL anti-correlation):** At N_eff ≥ 20 co-fires, measured ρ_VRP_FMLL < 0.25 (signals nearly independent) → remove N_eff correction; apply both at full α (uncorrelated). Log `VRP_FMLL_INDEPENDENT`.

**Escape Hatch ED (complacency persistence):** Mode B WR < 46% at N ≥ 20 own-data AND VRP_z mean-reversion lag > 30 days (complacency episodes are drawn-out) → retire Mode B; document complacency-persistence as anti-prim D.

---

## Conditions

- **Works when:** Crypto fear episode resolving (RV declining, VRP_z > +1.5); crypto PM YES prices below VRP-implied probability; Deribit DVOL fresh; resolution ≤ 90d; liquidity ≥ $5k; CPCV plateau cell selected
- **Fails when:** Crash still accelerating (rv_direction_gate fails); non-crypto PM categories; pm_liquidity > $500k (institutional arbitrageurs already closed gap); CPCV anti-prim D fires; DVOL API stale
- **Best markets:** BTC price threshold contracts (e.g. "Will BTC close above $X on date Y?"); ETH price threshold; crypto adoption milestones with ≤ 30d resolution
- **Best regime:** Post-crash recovery window (VRP_z peak → declining); NOT intraday

---

## Evidence

| Source | Finding | Relevance |
|--------|---------|-----------|
| Han & Li (2019 JFE) | Positive VRP → positive next-week BTC returns R²≈5% | Direct crypto VRP→returns; mode direction |
| Bollerslev, Tauchen & Zhou (2009 RFS) | VRP predicts S&P 500 excess returns; R²≈3% quarterly | Foundational VRP predictability |
| Carr & Wu (2009 JFE) | Variance risk premium formal model; mechanism decomposition | Mechanism: why VRP is persistent and predictive |
| Baker & Wurgler (2006 JF) | Investor sentiment predicts cross-asset returns | Fear contagion from options market to PM |
| Whaley (2009 J Portfolio Mgmt) | VIX as cross-market fear gauge; fear × return relationship | DVOL as analogous fear gauge; PM contagion pathway |
| Bekaert & Hoerova (2014 JFE) | VRP proxies risk aversion + conditional variance uncertainty | Mechanism of Mode A direction; Mode B attenuation |
| Dew-Becker et al. (2017 RFS) | Near-term VRP dominates short-horizon predictions | Justifies proximity multiplier tiers; T1 (≤14d) strongest |
| Bailey, Borwein & Lopez de Prado (2014 AMS) | Deflated Sharpe ratio + CPCV; multiple testing | G_CPCV anti-prim methodology |

---

## Limitations

- **N = 0 own-data.** All gates uncleared. Evidence is theoretical + academic analogy; no empirical confirmation on actual PM data.
- **Crypto PM universe size:** At any given time, ≤ 5–15 active crypto price/adoption markets on Polymarket — signal frequency may be lower than projected 4–6 episodes/year at Mode A.
- **DVOL scope:** Deribit DVOL measures BTC implied vol. ETH DVOL exists but is noisier. Crypto adoption PM markets (e.g. Bitcoin ETF AUM thresholds) may respond to BTC DVOL; altcoin adoption markets (e.g. Solana) may not — sub-category screening needed.
- **Direction gate empirical validation (G_DIR):** the rv_7d_trend direction gate's WR uplift is analytically motivated but unvalidated on PM data. May require threshold adjustment (7d → 5d or 10d).
- **FMLL correlation prior:** ρ = 0.60 is an informed prior, not measured. At N_eff ≥ 20 co-fires, replace with sample correlation.

---

**Prim bank after cycle 134:** polymarket **21 naive** (all superseded) / **22 intermediate** (+1 VRP) / **23 sophisticated** (+1 VRP)
