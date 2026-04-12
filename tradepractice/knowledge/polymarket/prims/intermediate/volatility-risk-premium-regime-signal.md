---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T09:00:00+10:00
cycle: 134
---

## Prim: volatility-risk-premium-regime-signal
**Level:** intermediate | **Project:** polymarket | **Cycle:** 134 | **Class:** 22nd (new class, direct intermediate entry)

---

### Signal Class

Crypto options implied vol substantially exceeds realised vol (positive VRP) in fear-regime episodes. Retail PM participants who hold both crypto positions and PM contracts anchor to recent volatility — they underprice recovery outcomes in crypto-category PM markets. Negative VRP (complacency: options cheap vs RV) inverts the mechanism — participants underprice downside scenarios.

The VRP is the expected compensation for bearing variance-of-variance risk (Carr & Wu 2009 JFE). In crypto, Han & Li (2019 JFE) confirmed that positive VRP predicts positive next-week BTC returns — a direct quantitative anchor for the cross-market signal's direction. The PM channel is sentiment contagion: the same retail participants who drive PM prices also observe DVOL as a real-time fear indicator and systematically underweight mean-reversion expectations.

**Distinct from financial-market-lead-lag (FMLL):**
- FMLL uses spot price and volume flows from TradFi as lead indicators for PM resolution probabilities
- VRP uses the *options premium gap* (implied − realised vol) as a sentiment state variable
- FMLL operates via arbitrageur attention; VRP operates via retail fear/complacency contagion
- The two can fire simultaneously → require N_eff correction (sophisticated tier)

**Target categories:** `crypto_price`, `crypto_adoption` only. Political, sports, weather, macro categories excluded — no crypto vol linkage.

---

### Mode A — Fear Premium → Recovery Underpricing

```
ACTIVATE (Mode A) when ALL of:
  1. pm_category ∈ {'crypto_price', 'crypto_adoption'}
  2. pm_contract direction = YES (bullish crypto outcome)
  3. VRP_z = (DVOL_30d − RV_30d) / rolling_std(90d) > +1.5     # fear premium elevated
  4. dvol_data_age_hours ≤ 24                                    # Deribit API fresh
  5. rv_bars_available ≥ 30                                       # Yang-Zhang RV warm-up met
  6. pm_liquidity ≥ $5,000
  7. pm_resolution_days ≤ 90                                     # far-horizon signal too attenuated
  8. NOT within 6h pre-expiry window (resolution_days < 0.25)

DIRECTION: BUY YES (fear premium → market underprices bullish recovery)

SIZE (unvalidated floor):
  alpha = 0.06   # G_IS uncleared; floor only
  Kelly fraction = alpha × (edge / odds)  — edge estimated from VRP_z percentile vs base rate

EXIT:
  VRP_z drops below +0.5 → close (fear premium normalising)
  PM price reverts to within 5pp of consensus implied prob → close
  Resolution published → close at resolution
  Max hold: 14 days
  Anti-prim A: if BTC price −5% in prior 24h AND VRP_z > +1.5 (crash still accelerating) → EXIT
```

### Mode B — Complacency → Downside Underpricing

```
ACTIVATE (Mode B) when ALL of:
  1. pm_category ∈ {'crypto_price', 'crypto_adoption'}
  2. pm_contract direction = NO (bearish crypto outcome, i.e. resolution fails bullish threshold)
  3. VRP_z < −1.5                                                # complacency: options cheap vs RV
  4. dvol_data_age_hours ≤ 24
  5. rv_bars_available ≥ 30
  6. pm_liquidity ≥ $5,000
  7. pm_resolution_days ≤ 90
  8. NOT within 6h pre-expiry window

DIRECTION: BUY NO (complacency → market overprices continuation of bullish trend)

SIZE (unvalidated floor):
  alpha = 0.04   # lower conviction than Mode A (negative VRP noisier predictor)
  Kelly fraction = alpha × (edge / odds)

EXIT:
  VRP_z rises above −0.5 → close (complacency normalising)
  PM NO price rises to within 5pp of inverse implied prob → close
  Resolution published → close at resolution
  Max hold: 14 days
```

---

### VRP_z Computation

```python
import numpy as np
import pandas as pd

def compute_vrp_z(dvol_series: pd.Series, ohlcv_daily: pd.DataFrame,
                  rv_window: int = 30, z_window: int = 90) -> pd.Series:
    """
    VRP_z = (DVOL_30d − RV_YZ_30d) / rolling_std(90d)
    DVOL from Deribit public API (ATM 30d implied vol index, annualised %)
    RV_YZ: Yang-Zhang estimator from OHLCV (handles overnight gaps)
    """
    # Yang-Zhang estimator components
    ln_oc = np.log(ohlcv_daily['close'] / ohlcv_daily['open'])
    ln_cc = np.log(ohlcv_daily['close'].shift(1) / ohlcv_daily['close'].shift(2))
    ln_co = np.log(ohlcv_daily['open'] / ohlcv_daily['close'].shift(1))
    ln_ho = np.log(ohlcv_daily['high'] / ohlcv_daily['open'])
    ln_lo = np.log(ohlcv_daily['low'] / ohlcv_daily['open'])
    ln_hc = np.log(ohlcv_daily['high'] / ohlcv_daily['close'])
    ln_lc = np.log(ohlcv_daily['low'] / ohlcv_daily['close'])

    k = 0.34 / (1.34 + (rv_window + 1) / (rv_window - 1))
    sigma_oc = ln_oc.rolling(rv_window).var()
    sigma_cc = ln_cc.rolling(rv_window).var()
    sigma_rs = (ln_ho * (ln_ho - ln_hc) + ln_lo * (ln_lo - ln_lc)).rolling(rv_window).mean()
    rv_yz = np.sqrt((sigma_cc + k * sigma_oc + (1 - k) * sigma_rs) * 252) * 100  # annualised %

    vrp = dvol_series - rv_yz   # > 0: fear premium; < 0: complacency
    vrp_z = (vrp - vrp.rolling(z_window).mean()) / vrp.rolling(z_window).std()
    return vrp_z
```

**Data sources:**
- DVOL: Deribit public API `/api/v2/public/get_index_price` (DVOL-BTC index, free-tier)
- OHLCV: Binance BTC/USDT daily bars (Binance REST API, free)
- Warm-up: 30 bars RV + 90 bars z-score = 120 days minimum before first signal

---

### Blocking Gates

| Gate | Condition | Status |
|------|-----------|--------|
| G_DATA | Deribit DVOL API key confirmed + OHLCV pipeline live | UNCLEARED |
| G_HIST | ≥ 50 Gamma API resolved crypto PM markets (2022–2024) extracted; VRP_z at entry date reconstructable | UNCLEARED |
| G_IS | IS backtest: Mode A WR ≥ 52% at N ≥ 15; Mode B WR ≥ 50% at N ≥ 15; Mann-Whitney U p < 0.10 one-tailed | UNCLEARED |

All modes DRY_RUN until G_DATA + G_IS cleared.

---

### Failure Modes

- **Anti-prim A (crash-in-progress):** VRP_z > +1.5 but BTC still falling → Mode A fires during freefall, not recovery. Symptom: Mode A WR < 45% with BTC_change_24h < −5%. Resolution: add RV direction gate (sophisticated tier advance 1).
- **Anti-prim B (category bleed):** Crypto VRP influences non-crypto PM markets (e.g., Elon Musk political markets). Symptom: WR < 50% in non-crypto categories when VRP_z > +1.5. Resolution: enforce category filter strictly; no exceptions.
- **Anti-prim C (FMLL double-counting):** Concurrent FMLL + VRP signal on same market → position size is sum of two correlated signals, effective Kelly overstates edge. Resolution: N_eff correction (sophisticated tier advance 3).

---

### Evidence

| Source | Finding | Relevance |
|--------|---------|-----------|
| Han & Li (2019 JFE) | Positive VRP → positive next-week BTC returns; R²≈5% weekly | Direct crypto VRP→returns link; mode direction justified |
| Bollerslev, Tauchen & Zhou (2009 RFS) | VRP predicts S&P 500 excess returns; R²≈3% quarterly | Foundational mechanism; cross-asset VRP predictability |
| Carr & Wu (2009 JFE) | VRP formal model: variance sellers earn premium for variance-of-variance risk | Mechanism decomposition; VRP interpretation |
| Baker & Wurgler (2006 JF) | Investor sentiment indices predict returns across asset classes | Fear contagion mechanism; PM retail sentiment linkage |
| Whaley (2009 J Portfolio Mgmt) | VIX as investor fear gauge; fear × asset price relationship | DVOL as analogous fear signal for crypto |
| Bekaert & Hoerova (2014 JFE) | VRP proxies conditional variance uncertainty + risk aversion | Mechanism decomposition: why VRP moves PM prices |

**Certainty:** plausible hypothesis (mechanism: Carr & Wu + Han & Li academic anchors strong; PM channel: sentiment contagion hypothesis, not yet validated). N = 0 own-data. All gates UNCLEARED. DRY_RUN.

---

### Path to Sophisticated Elevation

Four structural advances required:

1. **RV Direction Gate** — Mode A requires `rv_7d_trend < 0` (crash abating). Resolves anti-prim A.
2. **Resolution Proximity Multiplier** — tiered discount by resolution horizon (<14d→1.0×, 14–30d→0.85×, 30–90d→0.70×). Near expiry, DVOL options market converges with PM resolution timing.
3. **FMLL N_eff Correction** — when FMLL signal fires on same market, ρ=0.60 (both derive from derivatives+price data); combined Kelly uses N_eff = N × (1−0.60) = 0.40N; cap 1.15× amplify / floor 0.80× suppress.
4. **CPCV+DSR 9-cell plateau** — VRP_z threshold ∈ {+1.0, +1.5, +2.0} × window ∈ {60d, 90d, 120d}; DSR ≥ 0.90 for Mode A; DSR ≥ 0.85 for Mode B; anti-prim: DSR ≤ 0 → mode retired.

**Prim bank after cycle 134:** polymarket **21 naive** (all superseded) / **22 intermediate** (+1: volatility-risk-premium-regime-signal) / **22 sophisticated**
