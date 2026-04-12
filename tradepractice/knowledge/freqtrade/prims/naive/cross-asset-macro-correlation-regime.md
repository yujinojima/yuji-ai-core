---
name: cross-asset-macro-correlation-regime
level: naive
project: freqtrade
parent_prim: none
created: 2026-04-12
last_validated: 2026-04-12
reaction_validated: assumed
---

## Situation

### Setup
BTC/USDT perpetual is in any technical state (ranging, trending, post-liquidation sweep). Rolling 30-day Pearson correlation between BTC daily log-returns and SPX daily log-returns rises above +0.50 and continues rising for ≥ 3 consecutive daily readings. Institutional cross-asset risk allocation is driving BTC price action instead of crypto-native supply/demand dynamics.

### Trigger
`ρ_30d(BTC, SPX) ≥ +0.50 AND ρ rising (ρ_30d > ρ_prev by ≥ 0.05)` confirmed on 3 consecutive daily refreshes. This signals transition from crypto_native regime to equity_coupled regime.

### Reaction
- **Equity-coupled (ρ ≥ 0.50, rising):** All crypto-native signal prims lose calibration — they fire on moves caused by equity macro flows (institutional risk-on/risk-off) rather than crypto-endogenous supply/demand. Apply 0.85× entry confidence weight to all sister prims (axes 1–14). If equity regime is additionally risk-on (SPX > 20d MA, VIX < 18), amplify momentum prims 1.05×.
- **Crypto-native (ρ ≤ +0.20):** No modification. All 16 prior axes operate at calibrated weight. This is the structural baseline against which axes 1–16 were designed.
- **Transition (ρ crossing +0.20 → +0.50 within 10 days):** Suppress all prims 0.80× for 5 days — regime whipsawing creates the highest noise state.

### Agent Behaviour
- **Who is acting:** Post-2020 institutional allocators (macro funds, ETF arbitrageurs, crypto treasury holders) treating BTC as high-beta risk asset. When SPX drops on risk-off, they reduce BTC simultaneously.
- **Who is trapped:** Crypto-native signal traders running RSI divergence, VWAP deviation, FVG fill, capitulation reversal — these prims are calibrated against crypto-endogenous exhaustion, not against institutional macro deleveraging. They trigger early into structural waterfalls.
- **Who is wrong:** Mean-reversion buyers who interpret macro-driven selloffs as crypto-specific capitulation exhaustion.

### Outcome
- **If regime confirmed equity-coupled:** Sister prim entries suppressed to 0.85×. Reduces false triggers caused by equity macro flows masquerading as crypto-native setups.
- **If regime crypto-native:** All prims full weight. Majority of trading time (structural baseline).
- **If transition:** Maximum suppression (0.80×) for 5-day buffer. Avoids whipsaw during regime flip.

## Rule

Compute 30-day rolling Pearson correlation between BTC/USDT daily log-returns and SPX daily log-returns (source: Yahoo Finance `^GSPC`, refreshed daily via `bot_loop_start()`).

**High-correlation regime (ρ_30d ≥ +0.50 AND ρ_30d > ρ_prev_30d by ≥ 0.05, confirmed ≥ 3 consecutive daily readings):**
→ SUPPRESS all crypto-native signal prims 0.85× (axes 1–14 entry confidence)
→ If equity risk-on confirmed (SPX > 20d MA AND VIX < 18): AMPLIFY momentum prims (axes 2, 8) 1.05× additionally

**Low/negative correlation regime (ρ_30d ≤ +0.20 OR ρ_30d < 0):**
→ NO modification — all sister prims operate at full weight (calibrated baseline state)

**Regime transition (ρ_30d crosses from < 0.20 → ≥ 0.50 within 10 days):**
→ SUPPRESS all prims 0.80× for 5 days (transition uncertainty)

**No standalone entries. Pure meta-signal modifier. BTC/USDT:USDT only (apply same regime state to ETH sister prim entries — ETH correlation closely tracks BTC correlation).**

## Mechanism

Since 2020, BTC has exhibited episodic coupling with equities driven by two structural forces:

**[1] Institutional cross-asset allocation:** Post-2020 institutional adoption (MicroStrategy, ETF products, treasury allocations) links BTC's demand curve to risk appetite expressed across equity portfolios. When institutional investors reduce risk (risk-off: sell equities, sell BTC simultaneously), and increase risk (risk-on: buy equities, buy BTC), BTC behaves as a high-beta risk asset. In this coupled regime, crypto-native signals (RSI divergence, FVG fill, liquidity sweep) fire on moves that are actually driven by equity macro flows — generating false signals because the underlying agent configuration is "institutional deleveraging," not "retail capitulation" or "order flow imbalance."

**[2] Liquidation cascade spillover:** In 2022 (LUNA/3AC) and 2020 (COVID crash), BTC correlation with equities spiked as cross-asset margin calls forced simultaneous selling. The liquidation mechanism crossed asset classes. During these periods, mean-reversion prims (RSI-oversold, VWAP, capitulation-exhaustion) fired repeatedly against a structural macro waterfall — not against a crypto-specific exhaustion.

**Why axis 17 is orthogonal to all 16 prior axes:**

| Axes | Mechanism | Data source |
|------|-----------|-------------|
| 1–9 (RSI, EMA, sweep, div, cap, funding, BBW, VWAP, FVG) | Crypto OHLCV + derivatives | Crypto exchange native |
| 10–12 (OI, LSR, basis) | Crypto derivatives positioning | Binance REST |
| 13–14 (RV term structure, financial-market lead-lag) | Vol surface / cross-market info | Crypto + CME/PM |
| 15 (IV skew) | Options market sentiment | Deribit |
| 16 (GEX) | Options market mechanical flow | Deribit |
| **17 (cross-asset macro correlation)** | **BTC-SPX rolling regime state** | **OHLCV + free equity API** |

Axis 17 is the only axis that measures the **external macro regime driver** — it asks "is BTC currently behaving like a crypto asset or like a risk asset?" All 16 prior axes assume crypto-native behavior. When the answer is "risk asset," axes 1–16 lose calibration. This is the gap that none of the existing 16 axes can address, because all 16 use crypto-endogenous data only.

## Conditions

- **Works when:** ρ_30d genuinely elevated (sustained institutional risk-appetite linkage, ETF era 2024+); equity macro regime is itself directional (SPX trending, ADX_SPX > 20, not range-bound); BTC has significant institutional ownership (2022+; pre-2020 correlation was sporadic and structurally different); VIX regime identifiable (< 18 = risk-on; > 28 = risk-off; 18–28 = ambiguous)
- **Fails when:** Crypto-specific catalyst dominates (LUNA collapse, FTX — correlation spikes but cause is crypto-endogenous, not equity-macro; suppressing crypto signals is wrong); ρ_30d is in the 0.30–0.50 range without rising confirmation (no clear regime; suppression creates false drag); SPX data source latency > 24h (free API delay means 4h BTC signals see day-old regime state); pre-2020 era (different institutional ownership structure, different correlation regime)
- **Best pairs:** BTC/USDT:USDT, ETH/USDT:USDT (apply same regime state)
- **Best timeframe:** Meta-signal refreshed daily (regime transitions are days-to-weeks; 4h refresh is excessive and wastes API calls)
- **Best regime:** All regimes — this is a meta-classifier, not a directional signal

## Evidence

| Source | Finding |
|--------|---------|
| Bouri, Molnár, Azzi, Roubaud & Hagfors (2017, *Finance Research Letters*) | BTC provides diversification benefits when equity markets decline; negative correlation to S&P 500 in down markets; correlation unstable over time |
| Conlon & McGee (2020, *Finance Research Letters*) | During COVID crash (Feb–Apr 2020), BTC correlation with S&P 500 rose sharply — failed as safe haven; first documented acute equity-coupling episode |
| Corbet, Meegan, Larkin, Lucey & Yarovaya (2018, *Economics Letters*) | Cryptocurrency markets show increasing integration with traditional financial markets post-2017 |
| Liu & Tsyvinski (2021, *Journal of Finance*, 76(6)) | Already in bank (basis prim citation); documents crypto as increasingly correlated with equity risk factors during institutional adoption phase |
| Fang, Bouri, Gupta & Roubaud (2019, *Finance Research Letters*) | BTC-equity correlation is regime-dependent: high during crisis periods, near-zero during calm |
| Kajtazi & Moro (2019, *International Review of Financial Analysis*) | Rolling correlation BTC/S&P500 is highly time-varying (range: −0.20 to +0.70 over 2014–2018) |
| Umar, Trabelsi & Alqahtani (2021, *Finance Research Letters*) | Post-COVID, BTC correlation with equity markets structurally elevated vs pre-COVID baseline |

- **Source:** paper (7 academic anchors) + anecdote (practitioner observation: "BTC goes down when SPX goes down in risk-off")
- **Certainty:** hypothesis (correlation exists in literature; threshold calibration for 0.50 suppression gate = heuristic, not own-data)
- **Scope:** BTC/USDT on Binance perpetuals, 2022+ (institutional adoption era; pre-2020 correlation behavior is different structural regime)
- **Falsifiability:** yes — ρ_30d timeseries computable; conditional entry WR during ρ ≥ 0.50 vs ρ < 0.20 measurable on any existing sister prim backtest

## 10 Documented Limitations

1. **ρ threshold (0.50) is heuristic, uncalibrated** — what rolling correlation level constitutes "equity-driven regime" vs noise? Empirical scan across [0.30, 0.40, 0.50, 0.60, 0.70] vs conditional sister prim WR is the blocking test
2. **Crypto-endogenous vs equity-macro causation conflation** — correlation can spike from a crypto-specific event (FTX) that also causes equity losses via contagion; in that case, suppressing crypto signals is wrong (the signal source IS crypto-native)
3. **30-day rolling window unoptimized** — optimal correlation window may be 14d (faster to regime changes) or 60d (less noise); plateau scan required: [14, 21, 30, 45, 60]
4. **SPX data source latency** — free APIs (Yahoo Finance) typically provide daily close data; no sub-daily resolution; regime state is coarse-grained (daily bar only)
5. **Correlation rising vs level gate unspecified** — "ρ rising" direction confirmation is naive (comparing today vs prior 30d window); proper implementation requires rate-of-change or smoothing
6. **Regime transition window (5-day suppress at 0.80×) is heuristic** — correlation regime transitions take 1–15 days; the 5-day window may over- or under-suppress
7. **SPX proxy not natively available in freqtrade** — requires `bot_loop_start()` external API call (Yahoo Finance yfinance library or Alpha Vantage free tier); adds an external dependency; backtesting with this data requires a separate data pipeline
8. **Interaction with existing meta-signals (funding, basis, IV skew, GEX)** — when multiple meta-signals suppress simultaneously, compounding is possible; the 1.30× global cap applies but the compounding floor is undefined
9. **Regime persistence asymmetry unknown** — high-correlation episodes may be short (COVID: 6 weeks) or long (2022 bear: 9 months); suppressing at 0.85× for a 9-month period would degrade strategy performance massively; duration gate needed
10. **VIX-regime integration not specified at naive level** — amplification of momentum prims during risk-on (VIX < 18) is mentioned in the rule but VIX data requires a second external API call and its own threshold calibration

## Implementation

```python
import yfinance as yf
import numpy as np
import pandas as pd
from datetime import datetime, timedelta

class YujiCrossAssetMacroStrategy(IStrategy):
    """
    Cross-Asset Macro Correlation Regime — NAIVE (cycle 116)
    17th freqtrade regime axis: BTC-SPX rolling correlation as regime classifier.
    No standalone entries — meta-signal modifier only.
    Refreshed daily (regime transitions are days-to-weeks, not hourly).
    """

    _macro_regime: dict = {
        'rho_30d': 0.0,
        'regime': 'crypto_native',  # 'equity_coupled' | 'transition' | 'crypto_native'
        'suppress_weight': 1.0,
        'last_updated': None,
    }

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        """Refresh SPX and BTC daily returns; compute rolling 30-day Pearson ρ."""
        try:
            # Refresh at most once per day
            if (self._macro_regime['last_updated'] is not None and
                    (current_time - self._macro_regime['last_updated']).total_seconds() < 86400):
                return

            # Fetch SPX daily data (65 days lookback for 30d correlation + buffer)
            start = (current_time - timedelta(days=65)).strftime('%Y-%m-%d')
            spx = yf.download('^GSPC', start=start, progress=False, auto_adjust=True)
            if spx.empty:
                return

            # Compute SPX log returns (daily)
            spx_close = spx['Close'].squeeze()
            spx_ret = np.log(spx_close / spx_close.shift(1)).dropna()

            # Fetch BTC daily data from same window
            btc = yf.download('BTC-USD', start=start, progress=False, auto_adjust=True)
            if btc.empty:
                return
            btc_close = btc['Close'].squeeze()
            btc_ret = np.log(btc_close / btc_close.shift(1)).dropna()

            # Align on common dates
            common_idx = spx_ret.index.intersection(btc_ret.index)
            if len(common_idx) < 15:
                return  # insufficient data

            spx_aligned = spx_ret.loc[common_idx]
            btc_aligned = btc_ret.loc[common_idx]

            # 30-day rolling Pearson ρ (last 30 observations)
            rho_30d = spx_aligned.iloc[-30:].corr(btc_aligned.iloc[-30:])
            # Prior window (days -35 to -5) for direction check
            rho_prev = spx_aligned.iloc[-35:-5].corr(btc_aligned.iloc[-35:-5])

            rho_rising = (rho_30d - rho_prev) > 0.05  # ρ increasing

            if rho_30d >= 0.50 and rho_rising:
                regime = 'equity_coupled'
                suppress_weight = 0.85
            elif rho_30d >= 0.50 and not rho_rising:
                regime = 'equity_coupled'
                suppress_weight = 0.88  # moderate suppression even if not rising
            elif 0.20 < rho_30d < 0.50:
                regime = 'transition'
                suppress_weight = 0.92  # mild suppression in ambiguous zone
            else:
                regime = 'crypto_native'
                suppress_weight = 1.00  # no modification

            self._macro_regime = {
                'rho_30d': float(rho_30d),
                'rho_prev': float(rho_prev),
                'regime': regime,
                'suppress_weight': suppress_weight,
                'last_updated': current_time,
            }

        except Exception as e:
            logger.warning(f"Cross-asset macro regime update failed: {e}")

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """Broadcast regime state as scalar indicator columns."""
        snap = self._macro_regime
        dataframe['macro_rho_30d'] = snap.get('rho_30d', 0.0)
        dataframe['macro_regime_equity_coupled'] = snap.get('regime') == 'equity_coupled'
        dataframe['macro_regime_transition'] = snap.get('regime') == 'transition'
        dataframe['macro_suppress_weight'] = snap.get('suppress_weight', 1.0)
        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """No standalone entries — meta-signal only."""
        return dataframe
```

**Integration in sister prims (example — apply macro_suppress_weight to tighten thresholds):**
```python
# In populate_entry_trend() of any sister prim:
# Simplest approximation: in equity_coupled regime, require higher-conviction setup
macro_suppressed = dataframe['macro_regime_equity_coupled']

# Tighten RSI threshold when equity-coupled (0.85× confidence approximated as stricter gate)
rsi_threshold = dataframe['rsi'].where(~macro_suppressed, other=25)  # 30 → 25 when coupled

# OR use custom_stake_amount() to scale position size by suppress_weight:
# def custom_stake_amount(self, ...):
#     return default_stake * self._macro_regime['suppress_weight']
```

**Parameters (untuned — intermediate elevation blockers):**
- `rho_threshold_coupled`: `0.50` (heuristic; plateau scan [0.30, 0.40, 0.50, 0.60, 0.70] required)
- `rho_threshold_neutral`: `0.20` (below this = crypto_native; untuned)
- `rho_window_days`: `30` (plateau scan [14, 21, 30, 45, 60] required)
- `suppress_weight_coupled`: `0.85`
- `suppress_weight_transition`: `0.92`

**Plateau grid (for intermediate elevation):** `rho_threshold_coupled ∈ [0.30, 0.40, 0.50, 0.60]` × `rho_window ∈ [14, 21, 30, 45]` = 16 cells — under PBO threshold; no CPCV/DSR required at intermediate tier.

---

## Sources

- Bouri, E., Molnár, P., Azzi, G., Roubaud, D. & Hagfors, L.I. (2017). On the hedge and safe haven properties of Bitcoin: Is it really more than a diversifier? *Finance Research Letters*, 20, 192–198.
- Conlon, T. & McGee, R. (2020). Safe haven or risky hazard? Bitcoin during the COVID-19 bear market. *Finance Research Letters*, 35, 101607.
- Corbet, S., Meegan, A., Larkin, C., Lucey, B. & Yarovaya, L. (2018). Exploring the dynamic relationships between cryptocurrencies and other financial assets. *Economics Letters*, 165, 28–34.
- Fang, L., Bouri, E., Gupta, R. & Roubaud, D. (2019). Does global economic uncertainty matter for the volatility and hedging effectiveness of Bitcoin? *International Review of Financial Analysis*, 61, 29–36.
- Kajtazi, A. & Moro, A. (2019). The role of bitcoin in well-diversified portfolios: A comparative global study. *International Review of Financial Analysis*, 61, 143–157.
- Liu, Y. & Tsyvinski, A. (2021). Risks and Returns of Cryptocurrency. *Journal of Finance*, 76(6), 2689–2727. [Also cited in basis prim]
- Umar, Z., Trabelsi, N. & Alqahtani, F. (2021). Connectedness between cryptocurrency and technology sectors and the role of uncertainty. *Finance Research Letters*, 38, 101460.
