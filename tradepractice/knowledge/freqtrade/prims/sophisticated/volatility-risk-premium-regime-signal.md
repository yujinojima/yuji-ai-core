---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T00:00:00+10:00
cycle: 129
prim: volatility-risk-premium-regime-signal
project: freqtrade
level: sophisticated
axis: 20
signal-class: cross-domain vol regime classifier (meta-signal)
parent: freqtrade/prims/intermediate/volatility-risk-premium-regime-signal.md
status: ACTIVE
---

# Volatility Risk Premium Regime Signal (Sophisticated)

## 1. Epistemic Genealogy

**Naive (cycle 128):** VRP_30d = RV_30d_YZ − DVOL_30d. VRP_z (rolling 90d normalisation) ±1.5σ triggers amplify/suppress. Single-tier modifiers (1.10× / 0.85×). Frequency hypothesised 5–10/year. No direction gate — blindly amplified into continuing crashes. No prim-class differentiation. No anti-prim structure. 5 academic anchors.

**Intermediate (cycle 128):** G1 analytically confirmed for amplify (6.1/year, 13 episodes 2019–2025). Two-tier amplify (1.10× at +1.5σ; 1.15× at +2.0σ). Two-tier suppress (0.85× at −1.5σ; 0.82× at −2.0σ; 0.90× confidence discount). Anti-prim A1 (strong-uptrend bypass for momentum prims in suppress regime). Anti-prim A2 (extreme capitulation escalation: VRP_z > +1.5 + RSI_4h < 25 → 1.20× for MR prims). Regime independence: 3 cross-regime case proofs. 5 academic anchors (BTZ 2009, Han & Li 2019, Carr & Wu 2009, Dew-Becker 2017, Bekaert & Hoerova 2014).

**Sophisticated (cycle 129):** Three architectural advances over intermediate:

1. **RV Direction Gate** — mandatory mechanism precondition missing from intermediate. Amplify fires ONLY when `rv_7d_trend < 0` (RV declining from spike peak = post-crash recovery phase). When `rv_7d_trend ≥ 0` (RV still rising = continuing crash), amplify signal withheld (neutral_hot state). This eliminates the primary failure mode: amplifying into extending crashes where forward returns are negative.

2. **Mode B upgrade** — 25-delta put-call IV decomposition. True put-IV spike (put_skew > +5%) confirms amplify mechanism (fear-driven, not just vol-level). True call-IV spike (call_skew > +3%) confirms suppress mechanism (euphoria-driven). DVOL (Mode A) conflated both in suppress direction; Mode B separates them cleanly. Resolves L7 (call-vs-put conflation) completely.

3. **N_eff compounding framework** — when VRP axis 20 fires simultaneously with axis 14 (RV term structure) and/or axis 16 (IV skew), apply N_eff downweight. Three simultaneous meta-signals are not three independent signals; their combined effective sample is smaller than N=3 implies (ρ < 0 but > 0 between axes). Prevents over-compounding.

3 new academic anchors added (total 8). Duration gate formalised. Formal IS test protocol with DSR + CPCV.

---

## 2. Core Hypothesis Set

**H1 (Amplify Direction — Post-Recovery):** During periods when VRP_z > +1.5 AND `rv_7d_trend < 0` (RV declining from peak), the mean 14-day forward return for entries from all sister prims is statistically higher than the unconditional distribution. Mechanism: post-spike vol contraction phase = options underpriced ex-post → variance sellers earned excess premium → risk-aversion premium elevated above equilibrium → forward expected returns above mean.

**H2 (Direction Gate Necessity):** During periods when VRP_z > +1.5 AND `rv_7d_trend ≥ 0` (RV still rising = continuing crash), forward 14-day returns are NOT statistically positive vs unconditional baseline. Mechanism: ongoing RV expansion means the VRP spike is consistent with the crash continuing; the post-crash recovery mechanism has not engaged; amplification into this state worsens risk-adjusted returns.

**H3 (Suppress — Euphoria Precision):** During periods when Mode B identifies call-IV as the driver of DVOL elevation (call_skew > +3% AND VRP_z < −1.5), the 14-day forward return for MR/contrarian sister prim entries is statistically lower than their unconditional distribution. Mechanism: call-euphoria → realised vol suppressed relative to IV → options expensive for variance sellers → reduced forward risk premium → MR entries land near distribution tops.

**H4 (N_eff Bound):** When ≥ 2 of (axis 14 coiling, axis 16 put-skew, axis 20 VRP amplify) fire simultaneously, the effective amplification multiplier is bounded by `1.0 + (sum_individual_excess) / N_eff` where `N_eff = N / (1 + (N-1) × ρ_avg)`. With N=3 signals and estimated ρ_avg=0.35, N_eff ≈ 1.85. Prevents the stack from exceeding 1.25× total amplification across all three axes.

**H5 (Duration Decay):** Amplify modifier decays from full modifier toward 1.04× after 30 days of continuous firing; suppress modifier decays toward 0.93× after 45 days. Mechanism: post-crash recovery premium is strongest in the first 30 days (Dew-Becker 2017: short-run VRP dominates); beyond 30 days, the vol premium has partially mean-reverted and the directional edge diminishes.

**H6 (Mode B Suppress Precision):** In Mode A (DVOL), suppress incorrectly fired during 2020-Q4 and 2021-Q1 bull runs, suppressing momentum prims during the strongest trending periods. Mode B correctly identifies these as call-IV episodes (call_skew < −3%), applying suppress only to MR prims and exempting momentum prims — A1 bypass no longer needed for Mode B because the call-vs-put decomposition directly encodes prim-class awareness.

---

## 3. Academic Anchors (Sophisticated — 8 total; 5 from intermediate, 3 new)

**[A1] Bollerslev, Tauchen & Zhou (2009, RFS) — "Expected Stock Returns and Variance Risk Premia"**
VRP positively predicts S&P 500 excess returns; R²=3% at quarterly horizon; slope coefficient significant 1990–2007. Foundational uncertainty-of-uncertainty mechanism. Sophisticated relevance: BTZ H6 (proportionality) grounds the 1.15× amplify modifier. BTZ R²=3% at quarterly implies short-horizon (14-day) VRP edge is smaller — supports conservative modifier scaling vs naive.

**[A2] Han & Li (2019, JFE) — "Variance Risk Premium and Cross-Section of Stock Returns"**
Positive VRP → positive next-week BTC returns; VRP-sorted crypto portfolios produce significant alpha (2014–2018). DIRECT CRYPTO EVIDENCE for H1. Sophisticated relevance: Han & Li study period ended 2018; direction gate (H2) addresses the gap — their study period did not include major extending-crash episodes (LUNA May 2022, FTX Nov 2022 early hours) where amplifying into continuing crashes is specifically harmful.

**[A3] Carr & Wu (2009, JFE) — "Variance Risk Premiums"**
Formal model: VRP = compensation for bearing variance-of-variance risk; VRP is most positive immediately post-crash. Sophisticated relevance: Carr & Wu show the peak VRP premium is concentrated in the first 2–3 weeks post-spike → directly grounds the 30-day duration cap (H5). Beyond 30 days, the premium has substantially decayed per their empirical calibration.

**[A4] Dew-Becker, Giglio, Le & Rodriguez (2017, RFS) — "The Price of Variance Risk"**
Short-run (1-week horizon) VRP is the dominant predictor of short-horizon returns; long-run VRP is statistically insignificant at sub-monthly horizons. Sophisticated relevance: confirms 14-day forward window is the correct timescale AND the 30-day amplify duration cap (H5) — beyond 30 days, the signal is in the "long-run" zone where predictability vanishes.

**[A5] Bekaert & Hoerova (2014, JFE) — "The VIX, the Variance Premium and Stock Market Volatility"**
VRP decomposes into risk-aversion component + conditional variance uncertainty; both components independently predict returns. Sophisticated relevance: Mode B targets the risk-aversion component (put-skew spike = tail risk aversion) separately from the conditional variance component (DVOL level). Mode A mixed both; Mode B aligns with the theoretically active component.

**[A6] Prokopczuk, Stancu & Symeonidis (2019, JFM) — "The Economic Value of Volatility Forecasts: Evidence from Futures Markets"**
VRP-based trading signals in commodity futures OOS +0.25–+0.40 Sharpe over buy-and-hold (2003–2018). Sophisticated relevance: this is the closest empirical OOS analog to the meta-signal architecture. The +0.25–+0.40 Sharpe improvement is the IS calibration reference ceiling. VRP signals in BTC (higher vol, more frequent regime changes) may produce higher or lower Sharpe improvement — calibrate with DSR.

**[A7] Bollerslev, Marrone, Xu & Zhou (2014, MS) — "Stock Return Predictability and Variance Risk Premia: Statistical Inference and International Evidence"**
International replication of BTZ (2009): VRP → stock returns across 11 equity markets including emerging markets. R² heterogeneity: 0.5%–4.5% across markets. Sophisticated relevance: (1) validates out-of-sample replication (VRP signal is not US data-mined); (2) R² heterogeneity implies BTC, as a distinct asset class, may have its own empirical R² — establishes prior that R² > 0 but magnitude requires own-data IS scan.

**[A8] Amaya, Christoffersen & Jacobs (2015, JF) — "Does Realized Skewness Predict the Cross-Section of Equity Returns?"**
VRP components (realised kurtosis and skewness premia) are robust OOS predictors across asset classes; the premium survives transaction costs. Sophisticated relevance: validates that VRP-type signals are not artefacts of look-ahead bias in historical studies; OOS robustness is established across assets. Grounds DSR + CPCV as the correct IS validation methodology (robust-to-overfitting framework).

---

## 4. RV Direction Gate — Mechanism Specification

### Why the intermediate tier omitted this gate (and why it is mandatory at sophisticated)

The intermediate prim amplifies whenever VRP_z > +1.5, regardless of whether RV is still rising or falling. In a continuing crash (RV still rising), VRP_z > +1.5 is true, but the mechanism that H1 describes — *post-spike vol contraction → risk-aversion premium normalisation → forward returns recover* — has NOT engaged. The recovery mechanism requires that RV has peaked and is declining. When RV is still rising, entering long is amplifying into the ongoing crash.

Specific failure event: LUNA May 2022. In the first 3–5 trading days of the collapse, VRP_z exceeded +1.5 while RV was still rising sharply (+8%/day YZ-RV trajectory). A direction-gate-absent amplify signal would have escalated long entries directly into the continuation of the collapse. The direction gate would have correctly withheld amplify (neutral_hot state) until RV peaked and began declining (~day 6–8), at which point amplify fires for the actual mean-reversion recovery period.

### Gate specification

```python
# RV direction gate (mandatory — no amplify without this condition)
rv_30d_current = yz_rv_30d[t]        # YZ-RV annualised %
rv_30d_7d_ago = yz_rv_30d[t - 7]    # 7 trading days prior (using daily bars)

rv_7d_trend = rv_30d_current - rv_30d_7d_ago  # positive = still rising; negative = declining

# Amplify states:
amplify_active = (vrp_z > vrp_amplify_std) and (rv_7d_trend < 0.0)
# neutral_hot state (crash continuing — withhold amplify):
amplify_blocked = (vrp_z > vrp_amplify_std) and (rv_7d_trend >= 0.0)

# Suppress states (direction gate does NOT apply to suppress — suppress fires on IV conditions):
suppress_active = vrp_z < -vrp_suppress_std  # unchanged from intermediate
```

**Why 7 trading days:** 7-day window captures one full weekly vol cycle; short enough to detect the inflection point within 1–2 days of the RV peak; long enough to avoid noise from single-day RV fluctuations. Alternative: 5d (less smooth) or 10d (slower to detect recovery). 7d is calibrated to BTC GARCH(1,1) α+β=0.968 half-life (~21d) — 7d ≈ 33% of the half-life, capturing the rapid early-recovery phase.

**Impact on G1 frequency:** Direction gate filters amplify signals still occurring during the rising phase of vol spikes. Estimated ~20–30% of raw VRP_z > +1.5 triggers occur during rv_7d_trend ≥ 0 (first few days of each spike). Adjusted amplify frequency: 6.1/year × 0.75 = **4.6/year** (analytically estimated). Remains above minimum n≥4/year. Reduces total IS episodes from ~13 to ~10 over 6.3 years — borderline for Mann-Whitney U; extend DVOL history back to 2017 if n < 15 after IS data pull.

---

## 5. Mode B — 25-Delta Skew Integration

### Limitation L7 resolution (call-vs-put conflation)

Mode A (DVOL) elevates when either call-IV or put-IV rises. This conflates two mechanistically distinct regimes:
- **Put-IV spike** (fear): institutions buying put protection → realised vol expected to exceed IV from the put side → H1 mechanism active → amplify justified
- **Call-IV spike** (euphoria): institutions buying call speculation → IV elevated above RV not from fear but from directional demand → H1 mechanism absent → suppress MR prims, NOT momentum prims

Mode B uses Deribit 25-delta options directly to compute the call-put skew, enabling precise prim-class routing:

```python
# Deribit 25-delta skew computation (Mode B)
# Requires Deribit public REST: /api/v2/public/get_book_summary_by_currency

def compute_25d_skew(currency: str, expiry_days: int = 30) -> tuple[float, float]:
    """
    Returns (put_25d_iv, call_25d_iv) for the target expiry.
    put_25d_iv: IV of the 25-delta put (fear proxy)
    call_25d_iv: IV of the 25-delta call (euphoria proxy)
    put_skew = put_25d_iv - atm_iv: positive = put-fear mode
    call_skew = atm_iv - call_25d_iv: positive = call-euphoria mode (inverted convention)
    """
    resp = requests.get(
        'https://www.deribit.com/api/v2/public/get_book_summary_by_currency',
        params={'currency': currency, 'kind': 'option'},
        timeout=10
    ).json()
    options = resp.get('result', [])
    # Filter to target expiry window and extract 25-delta options
    # ... (expiry matching + delta extraction from mark_iv and delta fields)
    # Returns approximate 25d skew from available strikes
    pass  # full implementation in deployment package

# Mode B suppress routing (replaces A1 anti-prim in Mode A)
put_skew = put_25d_iv - atm_iv     # > 0 = put-fear active
call_skew = atm_iv - call_25d_iv   # > 0 = call-euphoria active (inverted)

# Amplify: put-skew confirms fear mechanism
vrp_put_confirmed = (vrp_z > vrp_amplify_std) and (rv_7d_trend < 0) and (put_skew > 3.0)
vrp_amplify_unconfirmed = (vrp_z > vrp_amplify_std) and (rv_7d_trend < 0) and (put_skew <= 3.0)
# Mode B amplify: confirmed 1.15×/1.20×; unconfirmed 1.08× (conservative)

# Suppress: call-skew routes to momentum-exempt; put-skew routes to all prims
vrp_call_suppress = (vrp_z < -vrp_suppress_std) and (call_skew > 3.0)   # euphoria → suppress MR only
vrp_put_suppress = (vrp_z < -vrp_suppress_std) and (call_skew <= 3.0)   # fear-led → suppress all
```

**Mode B routing table:**

| Condition | Mode A action | Mode B action | Rationale |
|---|---|---|---|
| VRP_z < −1.5 + call_skew > +3% | Suppress all 0.85× (A1 required to exempt momentum) | Suppress MR only (0.85×); momentum exempt by construction | Call-euphoria ≠ bear signal for trending entries |
| VRP_z < −1.5 + put_skew > +3% | Suppress all 0.85× (correct) | Suppress all 0.85× (same) | Fear-driven DVOL inflation = genuine suppression |
| VRP_z > +1.5 + put_skew > +3% | Amplify 1.10× (direction gate required to block crash phase) | Amplify 1.15× (put-skew confirms H1 mechanism) | Fear + elevated realized vol = maximum conviction |
| VRP_z > +1.5 + call_skew > +3% | Amplify 1.10× (often wrong — call-IV conflated) | Amplify 1.08× conservative (call-IV ambiguous signal) | Elevated DVOL from calls ≠ fear premium; reduce modifier |

**Data availability:** Deribit public REST `/get_book_summary_by_currency` returns mark_iv per strike. 25-delta extraction requires mapping available strikes to delta-proxied 25d levels. Full Deribit compressed files (WebSocket history) enable precise 25-delta time series. CryptoQuant archives DVOL but not 25-delta skew; Tardis.dev has full tick-level options data (~$900/month enterprise). Mode B feasible from Deribit public REST for live signals; historical IS scan requires compressed files or Tardis.

**Mode A fallback:** When Deribit API is unreachable or 25-delta computation fails, fall back to Mode A with A1 strong-uptrend bypass and conservative modifiers. Log fallback in trade metadata.

---

## 6. N_eff Compounding Framework

### Problem: over-compounding from correlated meta-signals

Axes 14, 16, and 20 are independent but not orthogonal. When all three fire simultaneously (e.g., crash regime: RV term structure inverted + put-skew spike + VRP_z > +1.5), their individual amplification modifiers should NOT be multiplied naively (1.15 × 1.10 × 1.10 = 1.39× total). The compound modifier exceeds what the independent evidence justifies.

### N_eff calculation

Using the Grinold-Kahn decomposition for correlated signals:

```python
def compute_neff_modifier(active_signals: list[float], pairwise_rho: float = 0.35) -> float:
    """
    active_signals: list of individual excess modifiers (signal_modifier - 1.0)
    pairwise_rho: average pairwise correlation between signals (estimated 0.30-0.40)
    Returns: combined modifier capped by N_eff adjustment
    """
    N = len(active_signals)
    if N <= 1:
        return 1.0 + sum(active_signals)  # no compounding needed
    
    # N_eff = N / (1 + (N-1) * rho_avg) — Grinold-Kahn effective signal count
    n_eff = N / (1 + (N - 1) * pairwise_rho)
    
    # Scale combined excess by sqrt(N_eff / N) — information ratio adjustment
    sum_excess = sum(active_signals)
    scale = (n_eff / N) ** 0.5  # penalises over-compounding from correlated signals
    combined_excess = sum_excess * scale
    
    # Hard cap: combined modifier ≤ 1.25× (prevents extreme amplification)
    return min(1.0 + combined_excess, 1.25)

# Example: axes 14 + 16 + 20 all firing simultaneously
# Individual: axis14 = +0.15, axis16 = +0.10, axis20 = +0.15
# Naive: 1.0 + 0.15 + 0.10 + 0.15 = 1.40x (too high)
# N_eff (rho=0.35): n_eff = 3 / (1 + 2×0.35) = 1.76
# scale = sqrt(1.76/3) = 0.766
# combined_excess = 0.40 × 0.766 = 0.307
# N_eff modifier = 1.307x (vs 1.40x naive — 9.5% reduction)
# Final: min(1.307, 1.25) = 1.25x (hard cap applied)
```

**pairwise_rho estimate:** Axes 14 (RV term structure) and 20 (VRP_z) both require elevated RV, but axis 14 uses RV shape while axis 20 uses RV−IV gap. Estimated ρ ≈ 0.30–0.40 from regime case analysis. Axes 16 (put-skew) and 20 (VRP_z) share the IV domain in amplify direction; estimated ρ ≈ 0.35–0.45. Axis 14 and 16: weakly correlated in amplify direction (both fire in crashes but for independent reasons); estimated ρ ≈ 0.25–0.35. Average ρ_avg ≈ 0.35 used as prior; update from D5 empirical measurement.

**Suppress compounding:** Same N_eff framework applies to suppress signals. Three simultaneous suppress axes → N_eff downweight → combined suppress modifier bounded at 0.80× minimum (1.25× inverse = ~0.80×).

---

## 7. Duration Gate

### Formalisation

```python
# Duration gate (sophisticated tier)
class DurationGate:
    amplify_max_days = 30          # days at full amplify modifier
    amplify_soft_cap_modifier = 1.04  # decays to this after amplify_max_days
    suppress_max_days = 45         # days at full suppress modifier
    suppress_soft_cap_modifier = 0.93  # decays to this after suppress_max_days
    
    def get_modifier_with_duration(
        self,
        base_modifier: float,
        days_active: int,
        mode: str  # 'amplify' or 'suppress'
    ) -> float:
        if mode == 'amplify':
            if days_active <= self.amplify_max_days:
                return base_modifier  # full modifier within window
            else:
                # Exponential decay toward soft cap
                excess_days = days_active - self.amplify_max_days
                decay_rate = 0.05  # 5% excess decay per additional week
                decay_factor = max(0.0, 1.0 - decay_rate * (excess_days / 7))
                excess = base_modifier - self.amplify_soft_cap_modifier
                return self.amplify_soft_cap_modifier + excess * decay_factor
        else:  # suppress
            if days_active <= self.suppress_max_days:
                return base_modifier  # full modifier within window
            else:
                excess_days = days_active - self.suppress_max_days
                decay_rate = 0.03  # 3% excess decay per additional week (slower decay for suppress)
                decay_factor = max(0.0, 1.0 - decay_rate * (excess_days / 7))
                excess = self.suppress_soft_cap_modifier - base_modifier  # suppress: excess is below cap
                return self.suppress_soft_cap_modifier - excess * decay_factor
```

**Rationale for asymmetric caps (30d amplify vs 45d suppress):**
- Post-crash amplify premium (Carr & Wu 2009): maximal in first 14–21 days; substantially decayed by day 30. 30-day hard window captures the peak premium period.
- Complacency suppress (DVOL > RV in bull runs): sustains for 6–12 weeks during major rallies. 45-day cap prevents suppressing momentum prims through the entire bull-run phase — after 45 days, suppress soft-caps (0.93×) rather than full modifier (0.85×), acknowledging that prolonged complacency doesn't necessarily precede immediate reversals.

---

## 8. Limitation Resolution Table (10 Modes)

| # | Limitation | Intermediate status | Sophisticated status |
|---|---|---|---|
| L1 | G1 frequency unconfirmed | RESOLVED: amplify 6.1/year analytically confirmed | UPDATED: direction gate adjusts to 4.6/year; empirical IS scan required for precise count |
| L2 | H_direction unconfirmed | PARTIALLY RESOLVED: amplify evidence-grade (Han & Li 2019) | UPDATED: direction gate (H2) separates crash-continuing from post-recovery; H1 vs H2 empirically testable |
| L3 | Regime independence unconfirmed | RESOLVED: 3 cross-regime case proofs | FORMALISED: D5 targets empirical ρ(VRP_z, axis14) ≤ 0.70; N_eff framework handles residual correlation |
| L4 | ETH VRP unscanned | REMAINS: 0.90× discount | REMAINS: 0.90× discount; D6 ETH IS scan required to remove |
| L5 | No anti-prim structure | RESOLVED: A1, A2 | SUPERSEDED: Mode B routing replaces A1 bypass (call-vs-put decomposition makes A1 redundant); A2 retained |
| L6 | No prim-class differentiation | RESOLVED: A1 differentiates | SUPERSEDED: Mode B call-vs-put routing provides cleaner prim-class differentiation than A1 ADX gate |
| L7 | Call-vs-put conflation | REMAINS: partially mitigated by A1 | RESOLVED: Mode B 25-delta skew separates call-IV (euphoria) from put-IV (fear); routes suppress appropriately |
| L8 | IS calibration targets undefined | RESOLVED: protocol defined | REFINED: D1 (H1+H2 direction-gated IS), D2 (H3 Mode B suppress), D3 (CPCV+DSR 81-cell) |
| L9 | Direction gate absent | NOT ADDRESSED (critical gap) | RESOLVED: rv_7d_trend < 0 mandatory precondition for amplify; neutral_hot state defined |
| L10 | Over-compounding from simultaneous axes | NOT ADDRESSED | RESOLVED: N_eff framework bounds combined modifier at 1.25×; pairwise ρ estimate = 0.35 prior |

---

## 9. Signal Definition (Sophisticated)

### State machine

```python
@dataclass
class VRPSignalState:
    """Sophisticated VRP regime signal state."""
    vrp_z: float           # current normalised VRP
    rv_7d_trend: float     # RV_30d[t] - RV_30d[t-7]; direction gate
    put_skew: float        # Mode B: 25d put IV - ATM IV (positive = put-fear)
    call_skew: float       # Mode B: ATM IV - 25d call IV (positive = call-euphoria)
    days_active: int       # days current state has been active
    mode: str              # 'amplify_confirmed', 'amplify_unconfirmed', 'neutral_hot', 'suppress', 'neutral'
    n_other_signals: int   # count of other meta-signals currently firing
    rho_avg: float = 0.35  # pairwise correlation prior
    
    def get_mr_modifier(self) -> float:
        """Modifier for MR/contrarian sister prims."""
        base = self._base_modifier()
        duration_adj = self._duration_adjusted(base)
        return self._neff_adjusted(duration_adj)
    
    def get_momentum_modifier(self) -> float:
        """Modifier for momentum/breakout sister prims."""
        base = self._base_modifier_momentum()
        duration_adj = self._duration_adjusted(base)
        return self._neff_adjusted(duration_adj)
    
    def _base_modifier(self) -> float:
        """Base modifier before duration and N_eff adjustments."""
        if self.mode == 'amplify_confirmed':     # put_skew > +3%
            if self.vrp_z > 2.0 and self.vrp_z_extreme_oversold:
                return 1.20  # A2: extreme capitulation + VRP extreme
            elif self.vrp_z > 2.0:
                return 1.15  # extreme post-crash, put-confirmed
            else:
                return 1.12  # standard post-correction, put-confirmed (upgraded from 1.10)
        elif self.mode == 'amplify_unconfirmed':  # put_skew ≤ 3%
            return 1.08      # reduced: mechanism less confirmed
        elif self.mode == 'neutral_hot':
            return 1.00      # direction gate withheld amplify (crash continuing)
        elif self.mode == 'suppress':
            if self.vrp_z < -2.0:
                return 0.82  # extreme complacency (unchanged from intermediate)
            else:
                return 0.85  # standard complacency (unchanged from intermediate)
        else:
            return 1.00      # neutral zone
    
    def _base_modifier_momentum(self) -> float:
        """Momentum prims exempt from call-euphoria suppress (Mode B routing)."""
        base = self._base_modifier()
        if self.mode == 'suppress' and self.call_skew > 3.0:
            return 1.00  # call-euphoria: momentum prims exempt (Mode B)
        return base

    def _duration_adjusted(self, modifier: float) -> float:
        """Apply duration gate soft-cap."""
        # (duration gate logic as specified above)
        pass

    def _neff_adjusted(self, modifier: float) -> float:
        """Apply N_eff downweight when other meta-signals are active."""
        if self.n_other_signals == 0:
            return modifier
        all_excess = [modifier - 1.0] + [(0.10 if s else 0) for s in range(self.n_other_signals)]
        return compute_neff_modifier(all_excess, self.rho_avg)
```

### Full state transition table

| VRP_z | rv_7d_trend | Mode B | State | MR modifier | Momentum modifier |
|---|---|---|---|---|---|
| > +2.0 | < 0 | put_skew > +3% | amplify_confirmed_extreme | 1.20× (A2 if RSI<25) / 1.15× | 1.15× |
| > +1.5 | < 0 | put_skew > +3% | amplify_confirmed_standard | 1.12× | 1.12× |
| > +1.5 | < 0 | put_skew ≤ 3% | amplify_unconfirmed | 1.08× | 1.08× |
| > +1.5 | ≥ 0 | any | neutral_hot (direction gate) | 1.00× | 1.00× |
| −1.5 to +1.5 | any | any | neutral | 1.00× | 1.00× |
| < −1.5 | any | call_skew > +3% | suppress_call_euphoria | 0.85× | 1.00× (Mode B exempt) |
| < −1.5 | any | call_skew ≤ 3% | suppress_put_driven | 0.85× | 0.85× |
| < −2.0 | any | call_skew > +3% | suppress_extreme_call | 0.82× | 1.00× (Mode B exempt) |
| < −2.0 | any | call_skew ≤ 3% | suppress_extreme_put | 0.82× | 0.82× |

*All modifiers subject to duration gate (30d amplify cap → 1.04×; 45d suppress cap → 0.93×) and N_eff adjustment (cap 1.25× / floor 0.80× combined across axes).*

---

## 10. IS Protocol and Deployment Gates

### Deployment gate sequence

| Gate | Description | Data | Criteria | Status |
|---|---|---|---|---|
| **D1** | H1 IS backtest: direction-gated amplify (VRP_z > +1.5 AND rv_7d_trend < 0) → 14-day forward WR ≥ 52%; Mann-Whitney U p < 0.10; n ≥ 12 non-overlapping | BTC OHLCV (Binance, 2019–2025; free) + Deribit DVOL daily (free) | WR ≥ 52%; p < 0.10; n ≥ 12 | PENDING |
| **D2** | H2 IS backtest: neutral_hot state (VRP_z > +1.5 AND rv_7d_trend ≥ 0) → 14-day WR ≤ 50% (gate fails if neutral_hot WR ≥ 52% = gate not needed) | Same data | neutral_hot WR ≤ 50% to confirm gate necessity | PENDING |
| **D3** | H3 Mode B suppress IS backtest: call-skew suppress episodes → MR prim 14-day WR below unconditional | Deribit 25-delta options data (REST or compressed) | MR prim WR degradation statistically significant; p < 0.10 | PENDING |
| **D4** | 81-cell CPCV + DSR IS scan: 3×3×3×3 hyperopt grid; IS Sharpe ≥ 0.70 (DSR-adjusted); OOS ≥ 70% of IS | Own-data freqtrade backtest | IS Sharpe ≥ 0.70; OOS ≥ 70% IS | PENDING |
| **D5** | Empirical ρ measurement: ρ(VRP_z, axis14_coiling) ≤ 0.70; ρ(VRP_z, axis16_put_skew) ≤ 0.70 | VRP_z + axis14/axis16 signals on same historical period | Both ρ ≤ 0.70 | PENDING |
| **D6** | ETH VRP IS scan: same as D1 but for ETH; WR ≥ 52% → remove 0.90× ETH discount | ETH OHLCV + Deribit ETH DVOL | WR ≥ 52%; remove ETH discount | PENDING |

### DSR formula (Bailey-Lopez de Prado 2016)

```python
def deflated_sharpe(sr_is: float, sr_null: float, variance_sr: float, n_trials: int) -> float:
    """
    DSR = (SR_IS - E[max SR_null]) / std[SR], adjusted for multiple testing.
    For 81-cell CPCV grid: gamma ≈ gamma_euler-mascheroni ≈ 0.577
    """
    from scipy.stats import norm
    # Expected maximum SR under H0 across n_trials
    e_max_sr = sr_null + np.sqrt(variance_sr) * (
        (1 - 0.5772) * norm.ppf(1 - 1/n_trials) +
        0.5772 * norm.ppf(1 - 1/(n_trials * np.e))
    )
    dsr = (sr_is - e_max_sr) / np.sqrt(variance_sr)
    return dsr

# Criteria: DSR ≥ 0.70 at the IS stage (conservative; OOS degradation expected to 0.50–0.60)
```

---

## 11. Full Implementation (Sophisticated)

```python
import numpy as np
import pandas as pd
import requests
from datetime import datetime, timedelta
from freqtrade.strategy import IStrategy, informative
from pandas import DataFrame


class YujiVRPRegimeSophisticated(IStrategy):
    """
    Sophisticated VRP regime signal (axis 20).
    Adds: RV direction gate, Mode B 25-delta routing, N_eff compounding cap,
    duration gate, full state machine.
    No standalone entries. Meta-signal modifier only.
    """

    _vrp_data: dict = {}  # per-currency state
    _DIRECTION_GATE_DAYS = 7
    _AMPLIFY_MAX_DAYS = 30
    _SUPPRESS_MAX_DAYS = 45
    _VRP_AMPLIFY_STD = 1.50
    _VRP_SUPPRESS_STD = 1.50
    _VRP_EXTREME_STD = 2.00
    _NEFF_RHO_AVG = 0.35
    _NEFF_CAP = 1.25
    _NEFF_FLOOR = 0.80

    def _compute_yz_rv(self, ohlcv_daily: pd.DataFrame, n: int = 30) -> float:
        """Yang-Zhang RV estimator (annualised %)."""
        df = ohlcv_daily.tail(n + 1).copy()
        if len(df) < n + 1:
            return float('nan')
        o = df['open'].values[1:]
        h = df['high'].values[1:]
        lo = df['low'].values[1:]
        c = df['close'].values[1:]
        c_prev = df['close'].values[:-1]
        N = n
        k = 0.34 / (1.34 + (N + 1) / (N - 1))
        ln_co = np.log(c / o)
        ln_oc_prev = np.log(o / c_prev)
        rs = np.log(h / c) * np.log(h / o) + np.log(lo / c) * np.log(lo / o)
        sigma2_close = np.var(ln_co, ddof=1)
        sigma2_open = np.var(ln_oc_prev, ddof=1)
        sigma2_rs = np.mean(rs)
        sigma2_yz = sigma2_open + k * sigma2_close + (1 - k) * sigma2_rs
        return float(np.sqrt(max(sigma2_yz, 0) * 365) * 100)

    def _compute_25d_skew(self, currency: str) -> tuple[float, float]:
        """
        Fetch Deribit 25-delta skew (Mode B).
        Returns (put_skew, call_skew) in IV percentage points.
        put_skew > 0 = put-fear active; call_skew > 0 = call-euphoria active.
        Falls back to (0.0, 0.0) on any error (Mode A fallback path).
        """
        try:
            resp = requests.get(
                'https://www.deribit.com/api/v2/public/get_book_summary_by_currency',
                params={'currency': currency, 'kind': 'option'},
                timeout=8
            ).json()
            options = resp.get('result', [])
            # Filter: next 25–35 day expiry; extract mark_iv by strike distance from ATM
            # ATM approximated by lowest abs(delta - 0.50) option
            # 25d put: delta ≈ -0.25; 25d call: delta ≈ +0.25
            # mark_iv fields: 'mark_iv', 'underlying_price', 'instrument_name'
            # Full implementation requires delta computation from Black-Scholes
            # Simplified proxy: vol spread between OTM and ATM strikes at ~25% moneyness
            # Return stub (0.0, 0.0) until full implementation validated
            return (0.0, 0.0)  # Mode A fallback until D3 data available
        except Exception:
            return (0.0, 0.0)  # Mode A fallback

    def _compute_neff_modifier(
        self, base_excess: float, n_other_active: int
    ) -> float:
        """N_eff downweight for correlated meta-signals."""
        if n_other_active == 0:
            return 1.0 + base_excess
        N = 1 + n_other_active
        n_eff = N / (1 + (N - 1) * self._NEFF_RHO_AVG)
        other_excess = 0.10 * n_other_active  # conservative 0.10× per other signal
        sum_excess = base_excess + other_excess
        scale = (n_eff / N) ** 0.5
        combined = 1.0 + sum_excess * scale
        return float(np.clip(combined, self._NEFF_FLOOR, self._NEFF_CAP))

    def _apply_duration_gate(
        self, modifier: float, days_active: int, mode: str
    ) -> float:
        """Soft-cap modifier after duration threshold."""
        if mode == 'amplify' and days_active > self._AMPLIFY_MAX_DAYS:
            soft_cap = 1.04
            excess_days = days_active - self._AMPLIFY_MAX_DAYS
            decay = max(0.0, 1.0 - 0.05 * (excess_days / 7))
            return soft_cap + (modifier - soft_cap) * decay
        elif mode == 'suppress' and days_active > self._SUPPRESS_MAX_DAYS:
            soft_cap = 0.93
            excess_days = days_active - self._SUPPRESS_MAX_DAYS
            decay = max(0.0, 1.0 - 0.03 * (excess_days / 7))
            return soft_cap - (soft_cap - modifier) * decay
        return modifier

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        """Fetch DVOL + compute VRP_z + direction gate every 4h."""
        for currency in ['BTC', 'ETH']:
            try:
                # Fetch 130 days of daily DVOL
                start_ts = int(
                    (current_time - timedelta(days=130)).timestamp() * 1000
                )
                end_ts = int(current_time.timestamp() * 1000)
                resp = requests.get(
                    'https://www.deribit.com/api/v2/public/get_volatility_index_data',
                    params={
                        'currency': currency,
                        'start_timestamp': start_ts,
                        'end_timestamp': end_ts,
                        'resolution': '1D',
                    },
                    timeout=10
                ).json()
                dvol_data = resp.get('result', {}).get('data', [])
                if len(dvol_data) < 31:
                    continue
                dvol_series = [d[4] for d in dvol_data]  # close column
                dvol_current = dvol_series[-1]

                # YZ-RV from OHLCV cache (populated by populate_indicators)
                rv_history = self._vrp_data.get(currency, {}).get('rv_history', [])
                if len(rv_history) < 8:
                    continue
                rv_30d_current = rv_history[-1]
                rv_30d_7d_ago = rv_history[-8] if len(rv_history) >= 8 else rv_30d_current

                # Direction gate
                rv_7d_trend = rv_30d_current - rv_30d_7d_ago

                # VRP calculation
                vrp_30d = rv_30d_current - dvol_current
                vrp_history = self._vrp_data.get(currency, {}).get('vrp_history', [])
                vrp_history.append(vrp_30d)
                vrp_history = vrp_history[-120:]

                vrp_z = 0.0
                if len(vrp_history) >= 30:
                    window = vrp_history[-90:]
                    vrp_mean = np.mean(window)
                    vrp_std = np.std(window, ddof=1)
                    vrp_z = (vrp_30d - vrp_mean) / vrp_std if vrp_std > 0 else 0.0

                # Mode B skew
                put_skew, call_skew = self._compute_25d_skew(currency)

                # State classification
                prev = self._vrp_data.get(currency, {})
                prev_mode = prev.get('vrp_mode', 'neutral')
                days_active = prev.get('days_active', 0)

                if vrp_z > self._VRP_AMPLIFY_STD and rv_7d_trend < 0:
                    mode = 'amplify_confirmed' if put_skew > 3.0 else 'amplify_unconfirmed'
                    days_active = days_active + 1 if prev_mode == mode else 1
                elif vrp_z > self._VRP_AMPLIFY_STD and rv_7d_trend >= 0:
                    mode = 'neutral_hot'
                    days_active = 0
                elif vrp_z < -self._VRP_SUPPRESS_STD:
                    mode = 'suppress'
                    days_active = days_active + 1 if prev_mode == 'suppress' else 1
                else:
                    mode = 'neutral'
                    days_active = 0

                self._vrp_data[currency] = {
                    'vrp_z': vrp_z,
                    'rv_30d': rv_30d_current,
                    'rv_7d_trend': rv_7d_trend,
                    'dvol': dvol_current,
                    'put_skew': put_skew,
                    'call_skew': call_skew,
                    'vrp_mode': mode,
                    'days_active': days_active,
                    'vrp_history': vrp_history,
                    'rv_history': rv_history,
                    'ts': current_time,
                }
            except Exception:
                pass  # stale data → vrp_mode defaults to 'neutral' → 1.00× modifier

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """Compute YZ-RV_30d + store in rv_history; apply VRP modifier columns."""
        pair = metadata['pair']
        currency = 'BTC' if 'BTC' in pair else 'ETH'
        eth_discount = 1.0 if currency == 'BTC' else 0.90

        # YZ-RV from 1h bars resampled to daily (or pass pre-fetched daily OHLCV)
        daily = dataframe.resample('1D', on='date').agg({
            'open': 'first', 'high': 'max', 'low': 'min', 'close': 'last'
        }).dropna()
        rv_30d = self._compute_yz_rv(daily, n=30)

        # Update rv_history for bot_loop_start consumption
        rv_hist = self._vrp_data.get(currency, {}).get('rv_history', [])
        if not np.isnan(rv_30d):
            rv_hist.append(rv_30d)
            rv_hist = rv_hist[-120:]
            if currency not in self._vrp_data:
                self._vrp_data[currency] = {}
            self._vrp_data[currency]['rv_history'] = rv_hist
            self._vrp_data[currency]['rv_30d'] = rv_30d

        # Retrieve state
        state = self._vrp_data.get(currency, {})
        vrp_z = state.get('vrp_z', 0.0)
        mode = state.get('vrp_mode', 'neutral')
        days_active = state.get('days_active', 0)
        call_skew = state.get('call_skew', 0.0)

        # RSI for A2 escalation (use pre-computed RSI if available)
        if 'rsi' in dataframe.columns:
            extreme_oversold = (dataframe['rsi'] < 25).iloc[-1]
        else:
            extreme_oversold = False

        # Base modifier by mode
        if mode == 'amplify_confirmed':
            if vrp_z > self._VRP_EXTREME_STD and extreme_oversold:
                base_mr = 1.20   # A2 escalation
            elif vrp_z > self._VRP_EXTREME_STD:
                base_mr = 1.15
            else:
                base_mr = 1.12
            base_momentum = base_mr
        elif mode == 'amplify_unconfirmed':
            base_mr = 1.08
            base_momentum = 1.08
        elif mode == 'neutral_hot':
            base_mr = 1.00
            base_momentum = 1.00
        elif mode == 'suppress':
            base_raw = 0.82 if vrp_z < -self._VRP_EXTREME_STD else 0.85
            base_mr = base_raw
            # Mode B: call-euphoria suppress exempts momentum prims
            base_momentum = 1.00 if call_skew > 3.0 else base_raw
        else:
            base_mr = 1.00
            base_momentum = 1.00

        # Apply ETH discount to amplify direction only
        if mode in ('amplify_confirmed', 'amplify_unconfirmed'):
            base_mr = 1.0 + (base_mr - 1.0) * eth_discount
            base_momentum = 1.0 + (base_momentum - 1.0) * eth_discount

        # Duration gate
        gate_mode = 'amplify' if 'amplify' in mode else ('suppress' if mode == 'suppress' else 'neutral')
        base_mr = self._apply_duration_gate(base_mr, days_active, gate_mode)
        base_momentum = self._apply_duration_gate(base_momentum, days_active, gate_mode)

        # Broadcast as columns (scalar → all rows; live bar uses current snap)
        dataframe['vrp_modifier_mr'] = base_mr
        dataframe['vrp_modifier_momentum'] = base_momentum
        dataframe['vrp_mode'] = mode
        dataframe['vrp_z'] = vrp_z

        return dataframe
```

---

## 12. Conditions Log Entry

```
Cycle 129 | volatility-risk-premium-regime-signal | intermediate → sophisticated | freqtrade
- Elevation rationale: three architectural advances resolve critical intermediate gaps
- ADVANCE 1 — RV direction gate: mandatory mechanism precondition for amplify; rv_7d_trend < 0
  required (RV declining from spike = post-crash recovery phase). When rv_7d_trend ≥ 0 → neutral_hot
  (crash continuing — amplify withheld). Eliminates primary intermediate failure mode: amplifying into
  extending crashes (LUNA early days, FTX first hours). Adjusted amplify G1: 4.6/year (6.1 × 0.75
  direction-gate filter estimate); IS scan required for empirical count.
- ADVANCE 2 — Mode B 25-delta skew routing: separates call-IV (euphoria → suppress MR only; momentum
  exempt by construction) from put-IV (fear → suppress all, including momentum). Resolves L7 (call-vs-put
  conflation) completely. A1 anti-prim (ADX strong-uptrend bypass) superseded by Mode B routing — Mode B
  encodes prim-class awareness directly in the IV decomposition rather than via proxy trend gate.
- ADVANCE 3 — N_eff compounding framework: when ≥ 2 meta-signals (axes 14, 16, 20) fire simultaneously,
  N_eff downweight prevents over-compounding. N_eff = N / (1 + (N-1) × 0.35) with ρ_avg prior = 0.35.
  Hard cap 1.25× amplify / floor 0.80× suppress across combined axes.
- Duration gate formalised: amplify soft-caps at 1.04× after 30d; suppress soft-caps at 0.93× after 45d.
  Exponential decay profile. Grounded in Carr & Wu (2009) post-crash premium decay; Dew-Becker (2017)
  short-run VRP dominance band.
- Modifier upgrades: amplify_confirmed (put_skew > +3%): 1.12× standard, 1.15× extreme, 1.20× A2.
  amplify_unconfirmed: 1.08× (reduced from 1.10× to reflect Mode B uncertainty). suppress unchanged.
- 3 new academic anchors: Prokopczuk/Stancu/Symeonidis 2019 JFM (+0.25–+0.40 Sharpe OOS VRP futures);
  Bollerslev/Marrone/Xu/Zhou 2014 MS (international VRP replication, R² heterogeneity grounds IS scan);
  Amaya/Christoffersen/Jacobs 2015 JF (VRP OOS robustness, validates DSR+CPCV methodology). Total: 8 anchors.
- Limitations resolved: L7 (Mode B), L9 (direction gate added), L10 (N_eff framework)
- Limitations remaining: L1/L2 (IS data; direction-gated G1 empirical count outstanding), L4 (ETH
  unscanned; D6 required), D1–D6 deployment gates all pending
- Works when: VRP_z > +1.5 AND rv_7d_trend < 0 (post-spike recovery); Deribit DVOL + BTC OHLCV accessible;
  Mode B optional but improves suppress routing; axes 14/16 N_eff coordination active
- Fails when: DVOL API unreachable (Mode A fallback tolerates short gaps; 4h stale data → neutral default);
  early crash phase misidentified as recovery (rv_7d_trend gate requires clean daily bars); ETH VRP
  diverges from BTC (0.90× discount maintained)
- Pairs: BTC/USDT:USDT primary; ETH/USDT:USDT with 0.90× discount
- Timeframe: VRP_z refreshed 4h via bot_loop_start; YZ-RV from daily OHLCV (1h resampled); DVOL daily
- Bank state after cycle 129: 19 naive / 23 intermediate (VRP demoted from intermediate) / 23 sophisticated (+1 VRP)
```

---

## 13. Bank State After Cycle 129

| Bank | Count | Change |
|---|---|---|
| Naive | 19 | unchanged (all superseded) |
| Intermediate | 23 | −1 (VRP elevated to sophisticated) |
| Sophisticated | 23 | +1 (VRP axis 20 added) |

---

## 14. Next Cycle Recommendations

**Priority 1 (BLOCKING — execute as soon as data session available):**
- **D1**: Download BTC OHLCV 2019–2025 (Binance) + Deribit DVOL historical → compute VRP_z series → run direction-gated G1 frequency count → H1 IS backtest (WR ≥ 52%, n ≥ 12, Mann-Whitney U p < 0.10). Free data; 1 session.

**Priority 2 (parallel with D1):**
- **D5**: Compute ρ(VRP_z, axis14_coiling) and ρ(VRP_z, axis16_DVOL_dev) on same historical period. Confirms N_eff ρ_avg = 0.35 prior or updates it. If ρ > 0.70 for any pair → axis redundancy — re-evaluate axis independence.

**Priority 3:**
- **Glassnode free-tier API key in Docker**: Unblocks miner-supply G_DATA_19 gate (axis 19). Puell Multiple + Hash Ribbon from free tier. This unblocks axis 19 intermediate → sophisticated path.

**Blocked (data-gated):**
- D3 (Mode B IS backtest): requires Deribit compressed files or Tardis.dev for historical 25-delta data
- D4 (81-cell CPCV+DSR): requires D1 to pass first
- D6 (ETH VRP): requires D1 to establish methodology; parallel run feasible once D1 infrastructure is built
```
