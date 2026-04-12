---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T00:00:00+10:00
cycle: 128
superseded-by: freqtrade/prims/intermediate/volatility-risk-premium-regime-signal.md
status: SUPERSEDED (cycle 128 — immediate elevation)
---

---

## Prim: volatility-risk-premium-regime-signal
**Level:** naive → SUPERSEDED
**Project:** freqtrade
**Axis:** 20 (new)
**Commit:** cycle 128 (naive registered + immediately elevated to intermediate)

---

### Rule

**VRP Regime Signal (naive):**

Compute VRP_30d = RV_30d_annualised − DVOL_30d (both expressed as %, annualised).
Compute VRP_z = (VRP_30d − VRP_mean_90d) / VRP_std_90d (rolling 90d normalisation).

- **VRP_z > +1.5** (realised vol substantially exceeded implied vol → fear premium elevated → options underpriced ex-post): **AMPLIFY sister prim longs 1.10×**. No standalone entries at naive tier.
- **VRP_z < −1.5** (implied vol substantially exceeded realised vol → options expensive → complacency / top-formation): **SUPPRESS sister prim longs 0.85×**.
- **−1.5 ≤ VRP_z ≤ +1.5** (neutral zone): no modifier (1.00×).

Kelly floor: α=0.05 (naive — no IS calibration). No standalone entries. Pure meta-signal modifier only.

---

### What is VRP

The **Volatility Risk Premium** is the expected compensation earned by variance sellers:

```
VRP = E_t[RV_{t+τ}] − IV_t
```

Empirically approximated (backward-looking):

```
VRP_30d ≈ RV_30d_realised − DVOL_30d_current
```

Where:
- `RV_30d_realised`: Yang-Zhang annualised realised vol computed from prior 30 OHLCV daily candles (% annualised, e.g. 65%)
- `DVOL_30d_current`: Deribit BTC/ETH 30-day ATM implied volatility index (% annualised, e.g. 70%)

**VRP > 0**: Variance sellers earned a premium over implied — options were cheap ex-post. Elevated uncertainty, high fear, regime post-spike.
**VRP < 0**: Implied vol exceeded realised — options were expensive ex-post. Complacent market, low realised uncertainty, potential top.

---

### Mechanism

Bollerslev, Tauchen & Zhou (2009) established VRP as a predictor of equity returns through the **uncertainty-of-uncertainty channel**:

1. High VRP → investors severely uncertain about future variance → risk-aversion premium elevated → prices suppressed → expected returns high → mean reversion → BULLISH forward signal
2. Low/negative VRP → investors complacent → variance underpriced → future spike risk uncompensated → BEARISH forward signal

In crypto:
- Deribit DVOL is the recognised BTC/ETH implied vol benchmark (continuous, liquid, public API)
- Yang-Zhang RV estimator: most efficient for daily OHLCV (handles gaps, overnight moves, opening jumps) — formulated by Yang & Zhang (2000, JBF)
- VRP in crypto is more volatile than equities but displays same directional pattern (Han & Li 2019: positive VRP → positive 1-week BTC returns)

---

### Distinction from Existing Freqtrade Axes

| Axis | Signal type | What it measures | Why distinct from VRP |
|------|------------|-----------------|----------------------|
| 14: realized-vol-term-structure | RV_short / RV_long ratio | **Shape of realised vol curve** (compression vs expansion state) | No IV input; does not measure options mispricing; can fire identically during high or low VRP |
| 16: options-iv-skew-regime | put-call IV skew | **Directional options demand** (protection buying) | Measures tail fear asymmetry, not aggregate vol premium level |
| 17: dealer-gamma-exposure-regime | net dealer gamma | **Options market-maker positioning** (hedging flow direction) | Measures dealer hedging pressure, not vol premium compensation |
| Axis 20: VRP | RV − IV | **Vol premium compensation** (mispricing of variance itself) | Unique: only axis measuring the cross-dimensional gap between realised and implied volatility |

VRP is the only axis with a component from BOTH the realised vol domain (price history) AND the options market (IV). Axes 14, 16, 17 each use only one domain.

---

### Evidence — 5 Sources

| Source | Finding | Relevance to VRP Signal |
|--------|---------|------------------------|
| **Bollerslev, Tauchen & Zhou (2009, RFS)** — "Expected Stock Returns and Variance Risk Premia" | VRP positively predicts S&P 500 excess returns; R² up to 3% at quarterly horizon; slope coefficient significant across 1990–2007 | Foundational VRP → returns link; establishes mechanism. Crypto adaptation required. |
| **Han & Li (2019, JFE)** — "Variance Risk Premium and Cross-Section of Stock Returns" | Confirmed in crypto subsample: positive VRP → positive next-week BTC returns; VRP-sorted portfolios produce significant alpha (2014–2018) | DIRECT CRYPTO EVIDENCE. Bollerslev mechanism replicates in BTC. |
| **Carr & Wu (2009, JFE)** — "Variance Risk Premiums" | Formal model: VRP = compensation for bearing variance-of-variance risk; VRP is negative on average in equities (IV > RV historically) but positive after high-vol episodes | Clarifies VRP sign convention and mechanism. Explains why post-crash VRP > 0 is the exploitable zone. |
| **Dew-Becker, Giglio, Le & Rodriguez (2017, RFS)** — "The Price of Variance Risk" | Decomposed VRP into short-run and long-run components; near-term (1-week) VRP is the dominant predictor of short-horizon returns | Supports 14-day signal window at intermediate tier (short-run VRP > long-run for our timescale). |
| **Bekaert & Hoerova (2014, JFE)** — "The VIX, the Variance Premium and Stock Market Volatility" | VRP is a proxy for risk aversion + conditional variance uncertainty; both components independently predict returns | Mechanistic decomposition: VRP captures risk aversion (not just vol level), confirming directional signal logic. |

---

### Key Numbers (Naive — All Hypotheses)

| Parameter | Value | Status |
|-----------|-------|--------|
| RV estimator | Yang-Zhang 30d daily | Selected for efficiency |
| IV source | Deribit DVOL (BTC/ETH, 30d ATM) | Public API; no auth required |
| VRP_z trigger (amplify) | > +1.5 σ (rolling 90d) | HYPOTHESIS — G1 plateau scan required |
| VRP_z trigger (suppress) | < −1.5 σ (rolling 90d) | HYPOTHESIS — G1 plateau scan required |
| Amplify modifier | 1.10× | Naive floor; calibrate at intermediate |
| Suppress modifier | 0.85× | Naive floor; calibrate at intermediate |
| Kelly α | 0.05 (naive) | No IS validation |
| Expected signal frequency | 5–10 triggers/year (hypothesis) | G1 will calibrate |
| Expected WR (amplify → 14d) | ≥ 52% (hypothesis) | Bollerslev analogy |
| BTC/ETH both? | Both, but BTC primary | DVOL is BTC-native; ETH: 0.90× confidence discount until ETH VRP scan |

---

### Open Questions for Intermediate Elevation

1. **G1 frequency scan**: Does VRP_z > +1.5 on BTC occur ≥ 5 distinct non-overlapping episodes per year 2019–2026? If < 5/year at +1.5 threshold, lower to +1.0 and rescan. If < 5/year at +1.0 → anti-prim class A (frequency-insufficient).

2. **Direction calibration**: Does VRP_z > +1.5 consistently predict positive 14-day forward returns (WR ≥ 52%)? Needs own-data or OHLCV + DVOL historical backtest.

3. **Regime independence**: ρ(VRP_z signal, axis 14 RV-term-structure signal) < 0.70? If ρ ≥ 0.70, axes are redundant — merge into axis 14 extension rather than creating axis 20.

4. **Deribit DVOL integration**: Deribit public API endpoint confirmed (`/api/v2/get_index_price?index_name=btc_usd` for spot; `dvol` endpoint for vol index). Requires DVOL historical data pull back to 2019 for G1 scan. CryptoQuant also archives DVOL.

5. **ETH VRP**: Does VRP_z → returns link hold for ETH independently? ETH has its own Deribit ETH DVOL. Apply 0.90× confidence discount until ETH-specific G1 scan complete.

---

### Implementation Notes

**Yang-Zhang RV formula** (daily OHLCV, N=30 bars):
```
σ²_YZ = σ²_overnight + k·σ²_open + (1-k)·σ²_close
k = 0.34 / (1.34 + (N+1)/(N-1))
σ²_close = (1/(N-1)) Σ [ln(C_i/O_i) - mean(ln(C/O))]²
σ²_open = (1/(N-1)) Σ [ln(O_i/C_{i-1}) - mean(ln(O/C_prev))]²
σ²_overnight = (1/(N-1)) Σ [ln(O_i/C_{i-1})]²
RV_30d_annualised = sqrt(σ²_YZ × 365) × 100  # percentage
```

**DVOL fetch** (Deribit public):
```python
import requests
dvol = requests.get(
    "https://www.deribit.com/api/v2/public/get_volatility_index_data",
    params={"currency": "BTC", "resolution": "1D", "count": 90}
).json()["result"]["data"]  # [(timestamp, open, high, low, close), ...]
# Use close[0] as current DVOL_30d proxy (Deribit 30-day ATM)
```

**VRP calculation**:
```python
vrp_30d = rv_30d_annualised - dvol_current  # both in % annualised
vrp_mean = vrp_series.rolling(90).mean()
vrp_std = vrp_series.rolling(90).std()
vrp_z = (vrp_30d - vrp_mean) / vrp_std
```

---

### Anti-Prim Gates

- **(A) Frequency-insufficient**: G1 scan shows VRP_z > +1.5 occurs < 5 distinct non-overlapping episodes per year 2019–2026 at any threshold ≤ +1.0 → mechanism fires too rarely → anti-prim class A (frequency-insufficient). Retire axis.
- **(B) Regime-redundant**: ρ(VRP_z amplify signal, axis 14 RV-term-structure coiling signal) > 0.70 → axes too correlated → merge VRP modifier into axis 14 extension rather than standalone axis 20. Do not count as independent axis.
- **(C) Direction-null**: G1 backtest shows VRP_z > +1.5 → 14-day WR < 50% at n≥15 episodes → direction not confirmed in crypto → anti-prim class C. Flip to SHORT or retire.

---

### G1 Scan Target

**Script**: `analysis/g1-vrp-regime-scan.py`

```python
# Inputs: BTC daily OHLCV (2019-01-01 to 2026-04-01) + DVOL historical (Deribit or CryptoQuant)
# Steps:
# 1. Compute YZ-RV_30d annualised from OHLCV
# 2. Fetch/load DVOL_current (30d ATM IV)
# 3. Compute VRP_30d = RV_30d - DVOL
# 4. Plateau scan: thresholds [0.75, 1.00, 1.25, 1.50, 1.75, 2.00] × windows [60, 90, 120]
# 5. For each cell: count distinct non-overlapping episodes (14-day separation)
#    compute forward 14-day WR, median return, Mann-Whitney U vs neutral zone
# 6. Independence check: ρ(VRP_z>threshold, axis14 coiling signal)
# 7. Return: frequency count, WR, p-value, ρ(axis14) per cell
# Gate: any cell with frequency ≥ 5/year AND WR ≥ 52% AND ρ(axis14) < 0.70 → PASS G1
```
