## Prim: institutional-expert-consensus-reversion
**Level:** sophisticated | **Project:** polymarket | **Cycle:** 81 | **Class:** 18th (elevation from intermediate cycle 80)

**Bank state:** 17 naive / 17 intermediate / 17 sophisticated

---

### What changed from intermediate

Five additions, each resolving one of the five "What remains for sophisticated elevation" items listed at the end of the cycle 80 intermediate prim:

1. **Macro-regime overlay** — `MacroRegimeState` gate (quantitative, not manual)
2. **N_eff concurrent-position Kelly** — correlation-adjusted Kelly for same-week CPI + NFP
3. **Revision-contamination model** — Mode B gap premium formalised: 0.15 → 0.20
4. **Adaptive efficiency gate calibration** — post-own-data protocol for the $200k/1.5% filter
5. **WFE with CPCV + DSR** — Bailey/Lopez de Prado 9-cell grid; anti-prim C formalised

---

### Signal specification

#### Calibrated σ table

```python
SIGMA = {
    # Category            σ estimate   Units              Source basis
    'CPI_MoM':            0.16,       # pp                BLS 2015–2025, N=120
    'CPI_YoY':            0.22,       # pp                BLS 2015–2025, N=120
    'NFP':                70,          # thousands jobs    BLS 2015–2025, N=120
    'PCE_Core_MoM':       0.10,       # pp                BEA 2015–2025, N=120
    'GDP_Advance_QoQ':    0.45,       # pp annualized     BEA 2015–2025, N=40
    'PPI_MoM':            0.22,       # pp                BLS 2015–2025, N=120
}

# Implied probability conversion
from scipy.stats import norm

def consensus_implied_prob(consensus_median, threshold, sigma, direction='above'):
    """direction: 'above' if contract resolves YES when release > threshold"""
    z = (threshold - consensus_median) / sigma
    if direction == 'above':
        return 1 - norm.cdf(z)
    else:
        return norm.cdf(z)
```

---

#### [NEW] Macro-regime overlay — MacroRegimeState

Replaces the intermediate manual suspension note. Applied before computing gap thresholds.

```python
from enum import Enum

class MacroRegimeState(Enum):
    STABLE   = 'stable'    # multiplier 1.0 — baseline thresholds unchanged
    ELEVATED = 'elevated'  # multiplier 1.2 — gap thresholds tighten proportionally
    SUSPEND  = 'suspend'   # hard SUSPEND — no entry; resumption criteria required

def get_macro_regime(vix: float, surprise_z: float, consecutive_breaks: int) -> MacroRegimeState:
    """
    vix: VIX level at time of entry evaluation
    surprise_z: trailing 3-month surprise Z-score = mean(|actual - consensus| / σ_cat)
    consecutive_breaks: count of releases where |actual - consensus| > 3×σ_cat (consecutive)

    Bordalo/Shleifer (2020): overreaction asymmetry is time-varying, largest in high-volatility
    regimes. Gap thresholds tighten (multiplier > 1) during elevated regime to avoid trading
    into periods where consensus calibration degrades.
    """
    if consecutive_breaks >= 2:
        return MacroRegimeState.SUSPEND
    if vix > 25 or surprise_z > 2.0:
        return MacroRegimeState.ELEVATED
    return MacroRegimeState.STABLE

REGIME_MULTIPLIER = {
    MacroRegimeState.STABLE:   1.0,
    MacroRegimeState.ELEVATED: 1.2,
    MacroRegimeState.SUSPEND:  None,  # no trading
}

# Resumption from SUSPEND requires ALL of:
#   1. 6-month wait from first structural-break release
#   2. Brier score ≤ 0.20 on N ≥ 10 most-recent releases of that category
#   3. VIX < 22 at resumption date
SUSPEND_RESUMPTION_CRITERIA = {
    'min_wait_months': 6,
    'brier_threshold': 0.20,
    'min_brier_n': 10,
    'vix_ceiling': 22,
}
```

**Applied as:** `effective_gap_threshold = base_gap × REGIME_MULTIPLIER[regime]`

---

#### Mode A — High-frequency monthly indicators

```
ACTIVATE (Mode A) when ALL of:
  1. category ∈ {CPI_MoM, CPI_YoY, NFP, PCE_Core_MoM, PPI_MoM}
  2. Bloomberg/Reuters consensus median published within last 48h
  3. resolution_days_remaining ≤ 30
  4. pm_liquidity ≥ $5,000
  5. pm_bid_ask_spread ≥ 2%
  6. NOT within 12h pre-release blackout window
  7. NOT efficiently-priced market — see adaptive gate below
  8. consensus_sigma = SIGMA[category]
  9. regime = get_macro_regime(vix, surprise_z, consecutive_breaks)
  10. regime != SUSPEND
  11. gap = |consensus_implied_prob - pm_yes_price|
  12. effective_gap_threshold = 0.10 × REGIME_MULTIPLIER[regime]
  13. gap ≥ effective_gap_threshold
  14. consensus_age_hours ≤ 48

DIRECTION:
  consensus_implied_prob > pm_yes_price + effective_gap_threshold → BUY YES
  consensus_implied_prob < pm_yes_price - effective_gap_threshold → BUY NO

SIZE:
  kelly_fraction = (edge / odds) × alpha_scale
  alpha_scale = 0.10 base (floor)
  # Increase to 0.15 if gap ≥ 0.18 AND consensus_age ≤ 24h AND category ∈ {CPI_MoM, NFP}
  # See N_eff adjustment below for concurrent positions

EXIT:
  Gap narrows below 0.06                                        → close
  Resolution published                                          → close at resolution
  20-day max hold                                               → close at market
  Consensus update revises median by > 0.5 × σ_cat            → reassess entry validity
```

---

#### [NEW] N_eff concurrent-position Kelly

MacLean/Thorp/Ziemba 2010 (Ch. 3): portfolio Kelly for correlated concurrent positions.

```python
def kelly_alpha_adjusted(base_alpha: float, concurrent_active: list[str]) -> float:
    """
    base_alpha: base Kelly fraction (0.10 or 0.15)
    concurrent_active: list of category codes for currently active positions

    Applied when CPI and NFP both activate within the same 5-business-day macro week.
    Central ρ = 0.50 (Coibion/Gorodnichenko SPF data 2010–2022; highest during inflationary
    periods when both CPI and NFP signals appear simultaneously).

    For N > 2: generalised via 1 / (1 + (N-1) × ρ_avg) approximation.
    """
    RHO_CENTRAL = 0.50   # CPI-NFP correlation (SPF, 2010-2022)
    RHO_AVG     = 0.40   # fallback for non-CPI/NFP pairs

    n = len(concurrent_active)
    if n <= 1:
        return base_alpha

    if n == 2 and set(concurrent_active) <= {'CPI_MoM', 'CPI_YoY', 'NFP'}:
        # Two correlated macro positions in same week
        return base_alpha / (1 + RHO_CENTRAL)

    # N > 2 generalisation
    return base_alpha / (1 + (n - 1) * RHO_AVG)

# Trigger condition: CPI and NFP release dates fall within same 5-business-day window
# (typically third Friday NFP + following Wednesday CPI, or reverse sequence)
CONCURRENT_WINDOW_DAYS = 5
```

---

#### Mode B — Lower-frequency / higher revision-risk indicators

```
ACTIVATE (Mode B) when ALL of:
  1. category ∈ {GDP_Advance_QoQ, PPI_MoM, CPI revision releases}
  2. Bloomberg/Reuters consensus median published within last 72h
  3. resolution_days_remaining ≤ 60
  4. pm_liquidity ≥ $5,000
  5. pm_bid_ask_spread ≥ 2%
  6. NOT within 12h pre-release blackout window
  7. NOT efficiently-priced market — see adaptive gate below
  8. consensus_sigma = SIGMA[category]
  9. regime = get_macro_regime(vix, surprise_z, consecutive_breaks)
  10. regime != SUSPEND
  11. gap = |consensus_implied_prob - pm_yes_price|
  12. effective_gap_threshold = 0.20 × REGIME_MULTIPLIER[regime]   # [was 0.15 at intermediate]
  13. gap ≥ effective_gap_threshold
  14. consensus_age_hours ≤ 72
  15. pm_contract.resolves_on == 'advance_release'
  16. NOT GDP contract if revision cycle < 30 days away

DIRECTION:
  consensus_implied_prob > pm_yes_price + effective_gap_threshold → BUY YES
  consensus_implied_prob < pm_yes_price - effective_gap_threshold → BUY NO

SIZE:
  alpha_scale = 0.10 (floor, no scaling bonus — lower-confidence category)
  N_eff adjustment does NOT apply to Mode B (signals non-concurrent by construction)

EXIT:
  Gap narrows below 0.12   → close  [adjusted from 0.10 to reflect higher base threshold]
  Resolution published     → close at resolution
  30-day max hold         → close at market
```

---

#### [NEW] Revision-contamination model (Mode B gap premium)

BEA Advance→Preliminary revision archive (N=92 quarters 2000–2023):
- Mean absolute revision: 0.42pp
- Std of revision: 0.52pp

Formalised as a **+0.05pp Mode B gap premium**, raising the base gap from 0.15 to 0.20.

**No quadrature addition** — contracts resolve on the Advance figure, not the Preliminary. The premium reflects survey population heterogeneity (some surveys poll for "true" level, others explicitly for Advance), not an independent noise process that compounds quadratically with σ.

```python
MODE_B_GAP_BASE     = 0.15   # intermediate baseline
MODE_B_GAP_PREMIUM  = 0.05   # BEA revision contamination premium
MODE_B_GAP_TOTAL    = 0.20   # effective Mode B gap (pre-regime multiplier)
```

---

#### [NEW] Adaptive efficiency gate calibration

The $200k/1.5% filter at intermediate was a single static threshold. Sophisticated adds a post-own-data calibration protocol.

```
EFFICIENCY GATE (default — pre-own-data):
  NOT (pm_liquidity > $200,000 AND pm_bid_ask_spread < 1.5%)

CALIBRATION PROTOCOL (post-own-data, per category):
  1. Bucket own trades by liquidity tier: <$50k / $50k–$100k / $100k–$200k / >$200k
  2. Compute WR within each bucket
  3. If WR drops below 55% in a higher-liquidity bucket → filter tightens to exclude that tier

TIERED ESCALATION TRIGGER:
  3 losses at pm_liquidity > $100k within any 3-month window
  → escalate filter one tier (e.g. $200k → $300k threshold)
  → if filter raised to $500k still fails → trigger anti-prim C

FILTER TIERS:
  Tier 0 (default): liq > $200k AND spread < 1.5%  → exclude
  Tier 1 (escalated): liq > $300k AND spread < 1.2% → exclude
  Tier 2 (escalated): liq > $500k AND spread < 1.0% → exclude
  Tier 3: if Tier 2 fails → anti-prim C
```

---

#### [NEW] 27-cell plateau grid

Three-axis parameter space across gap/premium/filter. Formalises frequency-vs-purity tradeoff.

```
Axis A — Mode A gap:       {0.08, 0.10, 0.12}
Axis B — Mode B gap:       {0.18, 0.20, 0.23}  (base + premium variants)
Axis C — Efficiency filter: {$200k, $300k, $500k}

27 cells total. Selected trade-off points:

  Tightest cell (0.12 / 0.23 / $500k):
    - Estimated WR: 68–74%
    - Risk: Mode A N=30 takes 7+ years at monthly cadence
    - Reject as default — frequency cost unacceptable

  Default baseline (0.10 / 0.20 / $200k):
    - Estimated WR: 62–68%
    - Mode A N=30 reachable in ~3 years (CPI/NFP)
    - Median frequency-purity balance — selected pending own-data WFE

  Loosest cell (0.08 / 0.18 / $200k):
    - Estimated WR: 55–62%
    - Higher signal frequency; Brier degradation risk
    - Fallback only if baseline CPCV Sharpe is negative
```

---

### WFE with CPCV + DSR

Bailey/Lopez de Prado 2014 (SSRN 2326253) — Combinatorially Purged Cross-Validation + Deflated Sharpe Ratio.

```
PARAMETER GRID (9 cells):
  gap ∈ {0.08, 0.10, 0.12} × alpha ∈ {0.10, 0.15, 0.25}

PASS GATE:
  DSR ≥ 0.95 on baseline parameter set (gap=0.10, alpha=0.10)
  at N ≥ 40 Mode A own-trades

ANTI-PRIM C (new at sophisticated):
  CPCV Sharpe ≤ 0 → retire Mode A
  This supersedes WR-alone monitoring because it corrects for:
    - Multiple testing bias (9 cells evaluated)
    - Serial correlation in trade outcomes (macro calendar clustering)
  DSR failure at N=40 is the primary falsification criterion for Mode A.

MODE B WFE NOTE:
  GDP_Advance signal frequency: 0–1 per year
  N=30 statistical inference horizon: 30–60+ years
  Mode B CANNOT be evaluated via WFE within any practical horizon.
  Mode B is retained for learning and academic completeness only.
  No anti-prim monitoring is feasible for Mode B.
  Mode A is the sole operative strategy.
```

---

### Anti-prim escape hatches (5 — sophisticated formalisation)

**A — Category-level directional calibration failure:**
If consensus-implied direction predicts actual resolution direction in ≤ 55% of cases at N ≥ 30 for a given category → close that category permanently. Category-specific: NFP surviving does not save CPI.

**B — σ miscalibration (Brier score):**
If the Gaussian probability conversion produces Brier score > 0.25 at N ≥ 30 → suspend that category; recalibrate σ before reactivating. Target: Brier ≤ 0.20.

**C — CPCV Sharpe failure (new at sophisticated):**
CPCV Sharpe ≤ 0 on the baseline parameter cell (gap=0.10, alpha=0.10) at N ≥ 40 → retire Mode A. Primary falsification criterion. Stronger than WR-only (anti-prim A) because it corrects for multiple testing and serial correlation.

**D — High-volatility macro regime suspension:**
If CPI_MoM actual surprise > 3× SIGMA['CPI_MoM'] for 2 consecutive months → SUSPEND (MacroRegimeState). Resumption criteria: 6-month wait + Brier ≤ 0.20 / N≥10 + VIX < 22.

**E — Efficiency gate escalation to Tier 3:**
If tiered escalation reaches $500k filter and still fails (3 losses at liq > $100k within 3m) → anti-prim C triggered simultaneously.

---

### Academic grounding (11 anchors — 10 carried + 1 new)

**Carried from intermediate (10):**

1. **Ang, Bekaert & Wei (2007, JF)** — SPF outperforms naive time-series and market-implied forecasts for near-term inflation/output.
2. **Coibion & Gorodnichenko (2015, AER)** — SPF better calibrated than futures-implied expectations; professionals don't over-weight recent news.
3. **Romer & Romer (2000, AEA P&P)** — Fed Greenbook outperforms private sector consensus at horizons ≤ 8 quarters.
4. **Tetlock (2005)** — Domain experts outperform generalists in narrow quantitative domains with established measurement.
5. **Silver (2012)** — Consensus of expert models outperforms individual experts and prediction markets for quantitative outcomes.
6. **Grossman & Stiglitz (1980, AER)** — Informed agents produce superior forecasts when information acquisition costs are asymmetric.
7. **Bordalo, Gennaioli, Ma & Shleifer (2020, JF)** — Consensus median is better calibrated than individual forecasts; overreaction asymmetry is time-varying. Formalised as MacroRegimeState at sophisticated.
8. **Patton & Timmermann (2010, JAE)** — Consensus RMSE improvement 15–25% for CPI, 10–20% for NFP vs best individual. Calibrates the 10pp Mode A threshold.
9. **Clements (2014)** — σ anchors for CPI, NFP, GDP consistent with SIGMA dict. Confirms structural breaks during COVID/GFC.
10. **Gürkaynak & Wolfers (2006, NBER WP 12510)** — 8–25pp divergence between consensus and economic derivative markets; consensus WR 65–72%. Pre-Polymarket baseline.

**New at sophisticated (1):**

11. **MacLean, Thorp & Ziemba (2010, "The Kelly Capital Growth Investment Criterion," Ch. 3)** — Portfolio Kelly for correlated concurrent positions: `α_adj = α / (1 + ρ)`. Central ρ = 0.50 from Coibion/Gorodnichenko SPF data 2010–2022. Extended to N > 2 via `1 / (1 + (N-1) × ρ_avg)`. Directly grounds the N_eff adjustment for same-week CPI+NFP activation.

---

### Epistemic quality dimensions

| Dimension | Naive | Intermediate | Sophisticated |
|---|---|---|---|
| **Source** | Survey forecast aggregation | Same + σ from BLS/BEA | Same + MacroRegimeState gate, N_eff Kelly, BEA revision archive |
| **Certainty** | Moderate — conversion unspecified | Higher — σ anchored, 10 sources | Highest — regime gate quantitative; concurrent Kelly formalised; CPCV DSR falsification |
| **Scope** | Vague authoritative figure | Explicit categories + σ table; GDP revision separated | Same + 27-cell plateau grid; Mode B operationally retired; adaptive efficiency gate |
| **Falsifiability** | ≤ 55% WR at N≥30 | Per-mode; Mode A rolling 20-trade | Anti-prim C: CPCV Sharpe ≤ 0 at N≥40 Mode A (primary); WR (secondary) |
| **Limitations** | σ unspecified; threshold uncalibrated | API blocker; Bordalo overreaction as manual note | API blocker remains; Mode B unvalidatable (structural, accepted) |

---

### Known failure modes

**Mode A specific:**
- **Consensus serial autocorrelation (CPI):** If consensus > actual for last 3 releases of same indicator, apply directional bias correction of −0.5σ before computing implied prob.
- **Announcement drift cancellation (NFP):** First-release revision avg 41k jobs 2000–2023. Verify Bloomberg NFP consensus is for advance figure specifically.
- **Concurrent position correlation underestimation:** ρ = 0.50 is highest during inflationary periods (Coibion/Gorodnichenko); may understate correlation during non-inflationary cycles. Monitor with actual trade pair outcomes once N ≥ 20 concurrent pairs.

**Mode B specific (academic reference only):**
- **GDP advance vs preliminary divergence:** Mode B gate 15 blocks contracts resolving on Preliminary.
- **Seasonal adjustment methodology change:** Manual review required for January (annual benchmark revision month).
- **Operationally retired:** 0–1 signals/year → N=30 unachievable in any practical horizon. No anti-prim monitoring feasible.

---

### Deployment gates (ordered)

```
Gate 0 — CURRENT BLOCKER: Bloomberg/Reuters API access
  Bloomberg Terminal or Data License API
  Minimum fields: consensus_median, consensus_σ, consensus_age
  Reuters Eikon / LSEG Data alternative accepted

Gate 1 — pm_resolution_mapper.py (shared blocker)
  Maps PM contract → (indicator, threshold, direction, release_vintage)
  Must correctly handle: CPI_MoM vs CPI_YoY, advance vs preliminary distinction

Gate 2 — σ calibration validation
  Pull Bloomberg historical consensus archive: CPI/NFP/PCE_Core 2015–2025 (N=120 each)
  Pull GDP_Advance/PPI_MoM 2015–2025
  Compute implied probability for historical instances where PM contract existed
  Target: Brier score ≤ 0.25 on N ≥ 30 per category before live trading

Gate 3 — Anti-prim historical scan (escape hatch A)
  Scan PM archive for all resolved macro-indicator contracts
  Confirm directional accuracy ≥ 60% per category at N ≥ 30
  Gürkaynak/Wolfers baseline: 65–72%

Gate 4 — Paper trading (20 signals per mode per category)
  Mode A: CPI and NFP reach 20 signals within 12–18 months
  Mode B: GDP_Advance ~5 years — learning only, no anti-prim gate required
  WR target: ≥ 60% (Bonferroni-corrected per category)

Gate 5 — Live at α = 0.10 Kelly floor
  Apply N_eff adjustment from first trade if CPI+NFP concurrent
  Apply MacroRegimeState gate from first trade

Gate 6 — WFE (CPCV + DSR) at N ≥ 40 Mode A own-trades
  9-cell grid (gap × alpha)
  DSR ≥ 0.95 on baseline cell → confirm; CPCV Sharpe ≤ 0 → anti-prim C

Gate 7 — Adaptive efficiency gate calibration
  Bucket WR by liquidity tier
  Escalate filter tier if 3 losses at liq > $100k within 3m
```

---

### Shared infrastructure

- `pm_resolution_mapper.py` (shared blocker)
- Bloomberg/Reuters consensus API (net-new)
- `SIGMA` dict — standalone module
- `MacroRegimeState` class — new at sophisticated; standalone
- `kelly_alpha_adjusted()` — new at sophisticated; standalone

---

### Epistemic status

**Level:** sophisticated — MacroRegimeState quantitative gate, N_eff concurrent Kelly, Mode B gap premium formalised, adaptive efficiency gate protocol, CPCV+DSR WFE with anti-prim C as primary falsification criterion. Mode B operationally retired (learning only). Blocking: Bloomberg API + pm_resolution_mapper.py + σ calibration validation (Gates 0, 1, 2). N = 0 own trades.
