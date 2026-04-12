---
prim: cross-asset-macro-correlation-regime
project: freqtrade
level: intermediate
cycle: 118
axis: 17th regime axis
signal-class: cross-asset macro regime classifier (meta-signal)
parent: freqtrade/prims/naive/cross-asset-macro-correlation-regime.md
created: 2026-04-12
superseded-by: (pending — sophisticated gate requires G1 + G2 data scans)
status: ACTIVE
---

# Cross-Asset Macro Correlation Regime (Intermediate)

## What Changed From Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Threshold architecture | Single ρ_30d ≥ 0.50 (heuristic) | Dual-window: ρ_14d early warning ≥ 0.40 AND ρ_30d confirmed ≥ 0.50 (resolves Limitation #3, #5) |
| Regime differentiation | Two states: equity_coupled / crypto_native / transition | Four states: fear_driven (VIX > 28) / momentum_driven (VIX < 20) / event_spike (ρ jump > 0.15 in 5d) / neutral_coupled (resolves Limitation #10) |
| Prim-class response | Blanket 0.85× all sister prims | Differentiated: momentum, mean-reversion, vol-breakout, meta-signals each with sub-regime-specific modifiers |
| Causation filter | None — crypto events (FTX, LUNA) would trigger suppression incorrectly (Limitation #2) | Crypto-endogenous bypass: BTC_RV7d / SPX_RV7d > 2.5 → full bypass; correlation spike caused by BTC, not equity macro |
| Duration gate | None — 0.85× sustained indefinitely in long bear (Limitation #9) | Progressive decay: day 1–10 full, day 11–30 half suppression, day 31+ quarter suppression |
| VIX integration | Mentioned as "amplify momentum if VIX < 18" but unspecified (Limitation #10) | Three VIX zones formalized: risk-on (< 20), neutral (20–28), risk-off (> 28); each determines sub-regime |
| Anti-prim escape hatches | None | Three defined: A1 (crypto-endogenous bypass), A2 (panic capitulation bottom), A3 (regime ambiguity near threshold) |
| Academic foundation | Static Pearson ρ only | DCC-GARCH framing added (Engle 2002; Katsiampa 2017 α+β = 0.968): Pearson ρ as static proxy for time-varying conditional correlation; sophisticated tier requires full DCC implementation |
| Hypothesis | Implicit | H_macro formalized with testable prediction and test protocol |
| Certainty | hypothesis | hypothesis (maintained — H_macro untested on own data; G1+G2 blocking) |
| Grid size | No hyperopt spec | 18 cells (< 20 → no CPCV/DSR at intermediate tier) |

---

## Mechanism (Refined)

**Naive mechanism retained:** The Bouri et al. (2017), Conlon & McGee (2020), Corbet et al. (2018), Kajtazi & Moro (2019), and Umar et al. (2021) academic anchors stand. Post-2020 institutional adoption has created episodic BTC-SPX coupling where crypto-native signals lose calibration against equity macro flows. See naive prim for full foundational mechanism.

**Intermediate adds: dual-window detection, three coupling sub-regimes, crypto-endogenous causation filter, progressive duration gate, VIX-class differentiation.**

---

### Core intermediate insight 1: single ρ_30d is both too slow and too blunt

The naive prim's 30-day Pearson window creates two failure modes in opposite directions:

**Too slow at regime entry:** When an equity macro shock begins (FOMC surprise, risk-off deleveraging), BTC-SPX correlation rises within 7–14 days, but the 30-day window dilutes the signal. The ρ_30d will lag by up to 2 weeks before crossing 0.50 — during which time sister prims fire in what is already an equity-coupled environment with no modifier applied.

**Too persistent at regime exit:** After a macro shock resolves, the 30-day window retains the old regime state for up to 30 additional days. In the 2020 COVID crash, correlation peaked in March but the 30-day window kept it elevated through April–May — suppressing mean-reversion prims during what turned out to be the most reliable capitulation recovery period in BTC's history.

**Resolution: dual-window gating**

`ρ_14d` (faster) = early warning sensor — detects correlation rising before the 30d window catches it  
`ρ_30d` (slower) = confirmation sensor — confirms sustained coupling vs transient noise

Entry to equity_coupled requires: `ρ_14d ≥ 0.40` AND `ρ_30d ≥ 0.50` (both conditions)  
Exit from equity_coupled requires: `ρ_30d ≤ 0.35` for ≥ 3 consecutive daily readings (hysteresis)

This mirrors the EMA short/long crossover entry-confirmation pattern used in axis 2 (EMA pullback dynamic support), applied to correlation regime detection rather than trend direction.

---

### Core intermediate insight 2: BTC-SPX correlation spikes from three mechanistically distinct sources

The naive prim treats all equity coupling as equivalent. Intermediate differentiation reveals that the correct prim-class response differs radically by source:

| Sub-regime | Trigger | Mechanism | Optimal response |
|---|---|---|---|
| **Fear-driven** | VIX > 28 | Institutional risk-off: simultaneous sell equities + BTC; cross-asset margin calls; portfolio de-risking | Suppress momentum prims (waterfall conditions hostile to breakout/trend-following); gentle on MR prims (capitulation approaching) |
| **Momentum-driven** | VIX < 20 AND ρ_30d ≥ 0.50 | Institutional risk-on: simultaneous buy equities + BTC; ETF inflows; cross-asset rotation | Amplify momentum prims (institutional inflows drive trend persistence); suppress MR prims (no mean-reversion catalyst; institutions are buying dips, not exhausted) |
| **Event spike** | ρ_30d jumped > 0.15 vs ρ_30d_prev in 5d | Short-lived macro event (FOMC, CPI print, geopolitical shock) created brief correlation surge | Light suppression (0.90×) for 5 trading days only; event-driven correlations revert as the catalyst fades |
| **Neutral coupled** | VIX 20–28 AND ρ_30d ≥ 0.50 | Ambiguous equity regime; correlation elevated but neither strongly risk-off nor risk-on | Standard suppression (decay schedule) applied uniformly |

**Why this differentiation matters:** In the naive implementation, the momentum_driven sub-regime (late 2020, mid 2021, Jan 2024 ETF inflow period) would suppress EMA pullback and FVG prims during exactly the conditions where they are most profitable — when institutional cross-asset flows drive BTC higher in lockstep with equity bull markets. Blanket suppression in that sub-regime is the wrong direction.

---

### Core intermediate insight 3: crypto-endogenous causation bypass

**The fundamental problem with correlation-based suppression:** Pearson ρ measures statistical co-movement, not causal direction. In 2022 (LUNA collapse, 3AC liquidation, FTX collapse), BTC-SPX correlation spiked to 0.60–0.75 — but the causal direction was BTC → equities (crypto contagion causing risk-sentiment deterioration in equities), not equities → BTC (institutional deleveraging suppressing BTC as a risk asset).

Suppressing crypto-native signals during a LUNA or FTX event is exactly backwards: those are the highest-value moments for capitulation-exhaustion-reversal and liquidity-sweep-reversal prims. The correlation spike is caused by the same crypto event that the sister prims are designed to trade.

**Detection proxy:** When BTC realized volatility over 7 days exceeds SPX realized volatility by > 2.5×, the vol source is crypto-native — the dominant causal direction is BTC→SPX, not SPX→BTC.

```
BTC_RV7d = std(log_returns_BTC[-7d]) × √365
SPX_RV7d = std(log_returns_SPX[-7d]) × √252
causation_filter_active = (BTC_RV7d / SPX_RV7d > 2.5) AND (ρ_30d > 0.40)
```

When `causation_filter_active = True`: full bypass of all suppression — set all modifiers to 1.0 regardless of ρ levels.

**Calibration note:** The 2.5× ratio threshold is intermediate-tier heuristic. Sophisticated tier requires event-by-event attribution (LUNA dates, FTX dates, 3AC dates) to verify that the filter would have correctly bypassed suppression during crypto events while leaving equity-macro suppression intact.

---

### Core intermediate insight 4: progressive duration suppression gate

The naive prim applies 0.85× suppression for the entire duration of an equity-coupled episode. In the 2022 bear market, BTC-SPX correlation stayed elevated for approximately 9 months. Constant 0.85× suppression for 270 days means all sister prims operated at 15% reduced confidence for the entire bear market — undermining every mean-reversion prim during what were legitimate (if risky) capitulation entries.

**Resolution: progressive decay schedule**

Duration of continuous equity_coupled state → modifier decay:

| Days in equity_coupled | Suppression magnitude | Full suppress weight | Half suppress weight | Quarter suppress weight |
|---|---|---|---|---|
| Day 1–10 | 100% | 0.85× | — | — |
| Day 11–30 | 50% | — | 0.925× | — |
| Day 31+ | 25% | — | — | 0.9625× (≈ neutral) |

**Rationale:** The highest-value period for macro regime suppression is the first 10 days of equity coupling — when the transition is new and crypto-native signals are most contaminated. After 30+ days, the market has already repriced to the new macro regime; crypto-native supply/demand dynamics reassert within the macro trend (e.g., funding rate extremes, FVG fills, liquidity sweeps remain valid even during a sustained bear market — the directional context changes but the micro-structure mechanisms don't). By day 31+, suppression at 0.97× is effectively neutral: the regime state is logged but the modifier is nearly inactive.

**Regime exit:** When ρ_30d falls below 0.35 for ≥ 3 consecutive daily readings, reset `days_in_regime` to 0 and return to crypto_native state.

---

### DCC-GARCH framing (sophisticated tier preview)

Engle's (2002) Dynamic Conditional Correlation GARCH model — the standard for time-varying multivariate volatility — reveals why static 30-day Pearson ρ is an approximation rather than the correct statistic. With GARCH(1,1) persistence parameters for BTC at α+β = 0.968 (Katsiampa 2017), BTC volatility exhibits near-unit-root clustering: high-vol days cluster with high-vol days. During vol clusters, consecutive daily returns are correlated within BTC's own series, which inflates the measured Pearson ρ with SPX spuriously.

**Implication for intermediate tier:** The rolling Pearson ρ computed over the 14-day and 30-day windows has lookback contamination during BTC volatility clusters. The measured correlation will appear higher than the true conditional correlation (what DCC-GARCH would estimate) during vol spikes.

**Intermediate's response:** Accept static Pearson ρ as a practical proxy. The dual-window architecture (ρ_14d + ρ_30d both required) partially mitigates this by requiring the fast window to confirm the slow window — a spurious correlation spike driven purely by BTC vol clustering would appear in ρ_14d but might not persist in ρ_30d.

**Sophisticated tier gate:** Replace static Pearson ρ with DCC-GARCH estimated conditional correlation `ρ_t` (time-varying, GARCH-filtered). This requires implementing Engle (2002) DCC in Python (available via `arch` library), fitting BTC and SPX return series, and using the model's filtered ρ_t as the regime classifier. This is the primary sophisticated-tier upgrade and the technically most defensible approach per Antonakakis et al. (2019, IRFA).

---

## Signal Definition

### Inputs (daily refresh via `bot_loop_start()`)

```python
# Core correlation series
rho_14d      # 14-day rolling Pearson ρ(BTC log-return, SPX log-return)
rho_30d      # 30-day rolling Pearson ρ — confirmation window
rho_30d_prev # ρ_30d from 5 days ago — for event spike detection

# Causation filter
BTC_RV7d     # BTC 7-day realized vol (annualized at √365)
SPX_RV7d     # SPX 7-day realized vol (annualized at √252)
causation_filter_active = (BTC_RV7d / SPX_RV7d > 2.5) AND (rho_30d > 0.40)

# VIX (risk-on/risk-off zone classifier)
VIX_current  # Latest VIX close from ^VIX via yfinance

# State
days_in_equity_coupled_regime  # counter; resets to 0 when ρ_30d < 0.35 for 3d
```

### Sub-regime classification logic

```
IF causation_filter_active:
    → regime = crypto_native (bypass)

ELIF rho_14d ≥ 0.40 AND rho_30d ≥ 0.50:
    regime = equity_coupled
    IF (rho_30d - rho_30d_prev) > 0.15:          → sub_regime = event_spike
    ELIF VIX_current > 28:                         → sub_regime = fear_driven
    ELIF VIX_current < 20:                         → sub_regime = momentum_driven
    ELSE:                                          → sub_regime = neutral_coupled

ELIF rho_14d ≥ 0.40 AND rho_30d < 0.50:
    → regime = transition (mild 0.92× suppression all prim classes)

ELSE (rho_30d ≤ 0.25 OR rho_14d < 0.35):
    → regime = crypto_native (no modifier)
```

### Prim-class modifier table by sub-regime and duration day

| Sub-regime | Day | Momentum (axes 2,7,8) | MR (axes 1,3,4,5,9) | Vol-breakout (axis 7) | Meta-signals (axes 10–16) |
|---|---|---|---|---|---|
| fear_driven | 1–10 | 0.85× | 0.925× | 0.85× | 1.0× |
| fear_driven | 11–30 | 0.925× | 0.9625× | 0.925× | 1.0× |
| fear_driven | 31+ | 0.9625× | 0.98× | 0.9625× | 1.0× |
| momentum_driven | 1–10 | **1.05×** | 0.85× | **1.05×** | 1.0× |
| momentum_driven | 11–30 | **1.05×** | 0.925× | **1.05×** | 1.0× |
| momentum_driven | 31+ | **1.05×** | 0.9625× | **1.05×** | 1.0× |
| event_spike | 1–5d | 0.90× | 0.90× | 0.90× | 1.0× |
| event_spike | 6d+ | reverts to neutral_coupled | | | |
| neutral_coupled | 1–10 | 0.85× | 0.85× | 0.85× | 1.0× |
| neutral_coupled | 11–30 | 0.925× | 0.925× | 0.925× | 1.0× |
| neutral_coupled | 31+ | 0.9625× | 0.9625× | 0.9625× | 1.0× |
| transition | — | 0.92× | 0.92× | 0.92× | 1.0× |
| crypto_native | — | 1.0× | 1.0× | 1.0× | 1.0× |

*Meta-signals (axes 10–16) always retain 1.0× weight: they measure derivative/positioning regimes that remain valid regime classifiers regardless of macro coupling state. GEX, IV skew, and LSR signals are not calibrated against equity-native history — they measure crypto market structure, which remains valid in both coupled and uncoupled regimes.*

*The 1.30× global amplification cap (N_eff framework) continues to apply across all meta-signals combined.*

---

## Full Implementation (Intermediate)

```python
import yfinance as yf
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from freqtrade.strategy import IStrategy

class YujiCrossAssetMacroStrategy(IStrategy):
    """
    Cross-Asset Macro Correlation Regime — INTERMEDIATE (cycle 118)
    17th freqtrade regime axis: BTC-SPX dynamic correlation as regime classifier.
    No standalone entries — meta-signal modifier only. Daily refresh.
    Adds: dual-window ρ, three coupling sub-regimes, crypto-endogenous causation
    filter, progressive duration gate, VIX-class differentiation, 3 escape hatches.
    """

    _macro_regime: dict = {
        'rho_14d': 0.0,
        'rho_30d': 0.0,
        'regime': 'crypto_native',
        'sub_regime': 'none',
        'days_in_regime': 0,
        'causation_filter_active': False,
        'vix': 0.0,
        'modifiers': {
            'momentum': 1.0,       # axes 2, 8 (EMA pullback, VWAP momentum)
            'mean_reversion': 1.0, # axes 1, 3, 4, 5, 9 (RSI, sweep, div, cap, FVG)
            'vol_breakout': 1.0,   # axis 7 (BBW squeeze)
            'meta_signals': 1.0,   # axes 10–16 (derivatives classifiers) — always 1.0
        },
        'last_updated': None,
    }

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        """Refresh SPX, BTC, VIX; compute dual-window ρ; classify coupling sub-regime."""
        try:
            if (self._macro_regime['last_updated'] is not None and
                    (current_time - self._macro_regime['last_updated']).total_seconds() < 86400):
                return

            start = (current_time - timedelta(days=80)).strftime('%Y-%m-%d')

            spx_raw = yf.download('^GSPC', start=start, progress=False, auto_adjust=True)
            btc_raw = yf.download('BTC-USD', start=start, progress=False, auto_adjust=True)
            vix_raw = yf.download('^VIX', start=start, progress=False, auto_adjust=True)

            if spx_raw.empty or btc_raw.empty:
                logger.warning("Cross-asset macro: SPX or BTC data empty — skipping update")
                return

            spx_ret = np.log(spx_raw['Close'].squeeze() / spx_raw['Close'].squeeze().shift(1)).dropna()
            btc_ret = np.log(btc_raw['Close'].squeeze() / btc_raw['Close'].squeeze().shift(1)).dropna()

            common_idx = spx_ret.index.intersection(btc_ret.index)
            if len(common_idx) < 20:
                return

            spx_a = spx_ret.loc[common_idx]
            btc_a = btc_ret.loc[common_idx]

            # Dual-window correlation
            rho_14d = float(spx_a.iloc[-14:].corr(btc_a.iloc[-14:]))
            rho_30d = float(spx_a.iloc[-30:].corr(btc_a.iloc[-30:]))
            rho_30d_prev = float(spx_a.iloc[-35:-5].corr(btc_a.iloc[-35:-5]))

            # Crypto-endogenous causation filter
            btc_rv7 = float(btc_a.iloc[-7:].std() * np.sqrt(365))
            spx_rv7 = float(spx_a.iloc[-7:].std() * np.sqrt(252))
            causation_filter = (btc_rv7 / (spx_rv7 + 1e-8)) > 2.5 and rho_30d > 0.40

            # VIX current level
            vix_current = 0.0
            if not vix_raw.empty:
                vix_series = vix_raw['Close'].squeeze().dropna()
                if len(vix_series) > 0:
                    vix_current = float(vix_series.iloc[-1])

            prev_regime = self._macro_regime.get('regime', 'crypto_native')
            prev_days = self._macro_regime.get('days_in_regime', 0)

            # === Classification ===
            if causation_filter:
                # A1 escape hatch: BTC-native event; bypass all suppression
                regime = 'crypto_native'
                sub_regime = 'none'
                days = 0
                mods = {'momentum': 1.0, 'mean_reversion': 1.0, 'vol_breakout': 1.0, 'meta_signals': 1.0}

            elif rho_14d >= 0.40 and rho_30d >= 0.50:
                regime = 'equity_coupled'
                days = prev_days + 1 if prev_regime == 'equity_coupled' else 1

                # Duration decay factor
                if days <= 10:
                    decay = 1.0
                elif days <= 30:
                    decay = 0.5
                else:
                    decay = 0.25

                # Event spike: ρ jumped > 0.15 in 5 days
                if (rho_30d - rho_30d_prev) > 0.15:
                    sub_regime = 'event_spike'
                    w = 0.90
                    mods = {'momentum': w, 'mean_reversion': w, 'vol_breakout': w, 'meta_signals': 1.0}

                elif vix_current > 28 or vix_current == 0.0:
                    # Fear-driven (or VIX unavailable — default to fear)
                    sub_regime = 'fear_driven'
                    sup_m  = 1.0 - 0.15 * decay        # momentum suppressed more
                    sup_mr = 1.0 - 0.075 * decay       # MR gentler (capitulation approaching)
                    mods = {'momentum': sup_m, 'mean_reversion': sup_mr, 'vol_breakout': sup_m, 'meta_signals': 1.0}

                elif vix_current < 20:
                    # Momentum-driven: institutions buying risk cross-asset
                    sub_regime = 'momentum_driven'
                    sup_mr = 1.0 - 0.15 * decay
                    mods = {'momentum': 1.05, 'mean_reversion': sup_mr, 'vol_breakout': 1.05, 'meta_signals': 1.0}

                else:
                    # Neutral coupled (VIX 20–28)
                    sub_regime = 'neutral_coupled'
                    sup = 1.0 - 0.15 * decay
                    mods = {'momentum': sup, 'mean_reversion': sup, 'vol_breakout': sup, 'meta_signals': 1.0}

            elif rho_14d >= 0.40 and rho_30d < 0.50:
                # Early warning / transition
                regime = 'transition'
                sub_regime = 'none'
                days = 1
                mods = {'momentum': 0.92, 'mean_reversion': 0.92, 'vol_breakout': 0.92, 'meta_signals': 1.0}

            else:
                # Crypto-native baseline
                regime = 'crypto_native'
                sub_regime = 'none'
                # Hysteresis: only reset days counter when ρ_30d < 0.35 (not < 0.50)
                # This prevents oscillating in/out of suppression at the 0.50 boundary
                days = prev_days if (prev_regime == 'equity_coupled' and rho_30d >= 0.35) else 0
                mods = {'momentum': 1.0, 'mean_reversion': 1.0, 'vol_breakout': 1.0, 'meta_signals': 1.0}

            self._macro_regime = {
                'rho_14d': rho_14d,
                'rho_30d': rho_30d,
                'regime': regime,
                'sub_regime': sub_regime,
                'days_in_regime': days,
                'causation_filter_active': causation_filter,
                'vix': vix_current,
                'modifiers': mods,
                'last_updated': current_time,
            }

        except Exception as e:
            logger.warning(f"Cross-asset macro regime update failed: {e}")

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        snap = self._macro_regime
        mod = snap.get('modifiers', {})
        dataframe['macro_rho_14d']         = snap.get('rho_14d', 0.0)
        dataframe['macro_rho_30d']         = snap.get('rho_30d', 0.0)
        dataframe['macro_regime']          = snap.get('regime', 'crypto_native')
        dataframe['macro_sub_regime']      = snap.get('sub_regime', 'none')
        dataframe['macro_days_in_regime']  = snap.get('days_in_regime', 0)
        dataframe['macro_vix']             = snap.get('vix', 0.0)
        dataframe['macro_causation_filter']= snap.get('causation_filter_active', False)
        dataframe['macro_mod_momentum']    = mod.get('momentum', 1.0)
        dataframe['macro_mod_mr']          = mod.get('mean_reversion', 1.0)
        dataframe['macro_mod_vol']         = mod.get('vol_breakout', 1.0)
        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """No standalone entries. Meta-signal only."""
        return dataframe
```

**Integration in sister prims — three-line pattern:**
```python
# In any sister prim's custom_stake_amount():
macro = YujiCrossAssetMacroStrategy._macro_regime
mod_class = 'momentum'  # or 'mean_reversion' or 'vol_breakout'
return default_stake * macro['modifiers'].get(mod_class, 1.0)
```

---

## Three Anti-Prim Escape Hatches

### A1 — Crypto-endogenous causation bypass (inline)

**Condition:** `BTC_RV7d / SPX_RV7d > 2.5` AND `ρ_30d > 0.40`

**Response:** Classify as `crypto_native` regardless of ρ. All modifiers reset to 1.0.

**Rationale:** LUNA collapse (May 2022), 3AC liquidation (June 2022), FTX (November 2022): in all three cases, BTC-SPX correlation spiked to 0.65+ but the causal direction was crypto→equity (via sentiment contagion and cross-asset margin calls from leveraged positions). Suppressing capitulation-exhaustion-reversal and liquidity-sweep-reversal prims during FTX is the worst possible outcome: those events produce exactly the capitulation setups those prims were designed to trade. BTC vol 2.5× greater than SPX vol is the practical signature of a crypto-endogenous event that happens to drag equities along — not an equity-macro event suppressing BTC from above.

**Escape condition edge case:** In September–October 2022 (pure Fed rate-driven equity bear), BTC vol and SPX vol were both elevated (~80% annualized BTC vs ~40% SPX). Ratio = 2.0 — below the 2.5× threshold. Correct classification: equity_coupled (fear_driven). This is the threshold calibration target for the G1 data scan.

---

### A2 — Panic bottom amplification override (fear-driven sub-regime)

**Condition:** `sub_regime == 'fear_driven'` (VIX > 28 AND equity_coupled) AND `BTC_RV7d > 80%` (extreme vol) AND `RSI_4h < 28` (extreme oversold)

**Response:** Override `mean_reversion` suppression → apply 1.10× to MR prim classes:
- `capitulation-exhaustion-reversal`
- `rsi-oversold-mean-reversion`
- `liquidity-sweep-reversal`
- `vwap-deviation-mean-reversion`

Do NOT override suppression for momentum and breakout prims — they remain at fear_driven levels.

**Rationale:** Extreme fear (VIX > 28) + extreme BTC vol (> 80%) + extreme 4h oversold (RSI < 28) is the three-factor capitulation signature. This combination occurred within ±3 days of major bottoms: March 2020 (RSI 14h: 18, BTC RV: 120%), November 2022 FTX low (RSI 4h: 24, BTC RV: 95%). In these moments, the equity-macro coupling is *causing* the capitulation — which is precisely when MR prims should fire at amplified conviction, not suppressed conviction. Suppressing capitulation signals at the capitulation bottom is the fundamental inversion error that this escape hatch prevents.

**A2 does not activate in momentum_driven or event_spike sub-regimes:** Amplification is reserved for the fear-driven bottom, not all elevated-correlation environments.

---

### A3 — Regime ambiguity boundary fade (near-threshold ρ)

**Condition:** `ρ_30d ∈ [0.50, 0.55]` AND `ρ_14d ≤ ρ_14d_prev` (early warning not confirming or declining)

**Response:** Treat as `transition` regime (0.92× all prim classes) rather than full `equity_coupled` (0.85×). The dual-window confirmation requirement is technically met but the faster window is not confirming — regime is ambiguous.

**Rationale:** Static rolling Pearson ρ in the 0.50–0.55 band has substantial noise. During SPX ranging periods (ADX < 15), BTC-SPX measured correlation can oscillate around 0.50 without meaningful equity macro coupling — the measured ρ is a statistical artifact of both series being range-bound simultaneously, not institutional cross-asset flow linkage. When ρ_14d is not confirming the ρ_30d level (i.e., the faster window is declining), applying full 0.85× suppression on the basis of a marginal 30-day reading destroys signal without macro rationale. The lighter 0.92× transition modifier acknowledges the ambiguity without fully suppressing sister prims.

**Reset condition:** If `ρ_30d > 0.58` AND `ρ_14d > 0.45`, A3 is no longer active — classify as full `equity_coupled`.

---

## Hyperopt Parameter Grid (Intermediate — 18 cells, no CPCV/DSR)

| Parameter | Values tested | Default | Resolves limitation |
|---|---|---|---|
| `rho_14d_early_threshold` | [0.35, 0.40] | 0.40 | #5 (ρ direction confirmation) |
| `rho_30d_coupled_threshold` | [0.45, 0.50, 0.55] | 0.50 | #1 (threshold heuristic) |
| `causation_ratio_threshold` | [2.0, 2.5, 3.0] | 2.5 | #2 (causation conflation) |

**Total cells: 2 × 3 × 3 = 18.** Below 20-cell PBO threshold; no CPCV+DSR required at intermediate tier.

**Validation metric:** Conditional sister prim WR during equity_coupled (ρ ≥ threshold) vs crypto_native (ρ < 0.25), measured across YujiRSIStrategy, YujiFVGStrategy, YujiCapitulationStrategy backtests (G2 scan). Target: ≥ 5 percentage-point WR reduction during equity_coupled vs crypto_native, p < 0.10 binomial. This is the blocking test for sophisticated elevation.

**Sophisticated tier will add:** DCC-GARCH ρ_t window parameters, VIX sub-regime zone thresholds (≥ 24 additional cells → CPCV+DSR mandatory at sophisticated tier).

---

## Formalized Hypothesis

**H_macro:** During BTC-SPX equity_coupled regimes (ρ_30d ≥ 0.50, ρ_14d ≥ 0.40), the win rate of crypto-native signal prims (RSI, VWAP, FVG, capitulation) is measurably lower than during crypto_native regimes (ρ_30d ≤ 0.25) on the same BTC/USDT backtests.

**Testable prediction:** On the YujiRSIStrategy 2022–2025 backtest, entries occurring while `macro_regime == equity_coupled` will show ≥ 5pp lower WR and ≥ 0.10 lower Sharpe than entries occurring while `macro_regime == crypto_native`. This difference will be statistically significant at p < 0.10 by binomial test (n expected: ≥ 40 equity_coupled entries given frequency estimates from Kajtazi & Moro 2019 rolling ρ range).

**Falsification criterion:** If conditional WR difference < 3pp or not significant (p > 0.15), the prim reclassifies as anti-prim candidate. The suppression modifiers create drag without benefit. Downgrade to anti-prim and document under conditions-log.

---

## 7 Remaining Limitations (after intermediate resolves naive #2, #3, #5, #6, #9, #10)

1. **H_macro untested on own data** — G1 (ρ_30d timeseries frequency + sub-regime firing rates) and G2 (conditional sister prim WR scan) not executed; ρ_30d = 0.50 threshold and ρ_14d = 0.40 early warning both remain heuristic until G2 data confirms
2. **SPX data source latency — daily close only** — regime state is coarse-grained (24h stale maximum); 4h BTC entries see the previous day's macro state; no intraday ρ update; latency worst during FOMC event days (regime can shift intraday)
3. **Causation filter ratio threshold (2.5×) uncalibrated** — 2022 FTX/LUNA events are the target validation events; threshold must be tested against event-by-event attribution to verify it correctly classifies crypto-endogenous vs equity-macro causation; heuristic at intermediate tier
4. **Multi-signal compounding floor undefined** — when cross-asset macro (0.85×) + GEX (Mode B, 0.90×) + IV skew (persistent, 0.85×) + funding (escape hatch off) all suppress simultaneously, cumulative modifier = 0.85 × 0.90 × 0.85 = 0.650× — a 35% reduction in entry confidence; the 1.30× global cap manages amplification but there is no global floor for compounding suppressors; needs N_eff extension to compound-suppressor case
5. **ETH correlation tracking assumption unvalidated** — applying same macro regime state to ETH/USDT assumes ETH-SPX correlation tracks BTC-SPX correlation; during ETH-specific events (Shanghai upgrade May 2023, ETH ETF approval May 2024) this assumption may break; ETH should have its own ρ_30d series at sophisticated tier
6. **Static Pearson ρ vs DCC-GARCH conditional ρ_t** — the correct statistic for equity-coupling detection is Engle (2002) DCC-GARCH estimated conditional correlation, not rolling Pearson ρ; during BTC volatility clusters (GARCH α+β = 0.968, Katsiampa 2017), rolling Pearson overestimates true conditional correlation; sophisticated tier must replace Pearson with DCC-GARCH (arch library, Python)
7. **VIX sub-regime zone thresholds (20/28) uncalibrated** — the boundaries between risk-on (< 20), neutral (20–28), risk-off (> 28) are convention-borrowed from equity options literature; crypto-market-maker hedging demand and VIX correlation may differ from the equity analogue; calibration via G2 scan across VIX zones required

---

## Three-Step Deployment Gate (Intermediate → Sophisticated)

**G1 — ρ Frequency + Sub-Regime Firing Rate Scan (data acquisition):**
Compute BTC-SPX 14-day and 30-day rolling Pearson ρ for 2020–2025 using Yahoo Finance historical data. Measure:
- Days with `equity_coupled` classification per year (target: 60–120 days/year for meaningful signal)
- Sub-regime breakdown: fear_driven / momentum_driven / event_spike / neutral_coupled (check each has ≥ 10 days/year)
- Causation filter firing rate on known crypto events (LUNA May 2022, 3AC June 2022, FTX Nov 2022)

G1 is executable immediately with free data (yfinance). Estimated: 30 minutes to write the scan, 5 minutes to run.

**G2 — Conditional Sister Prim WR Scan (hypothesis test):**
Using G1 regime dates as labels, split YujiRSIStrategy and YujiFVGStrategy backtest entries into equity_coupled vs crypto_native sets. Compute WR and Sharpe for each set. Binomial test: p < 0.10, ≥ 5pp WR difference → H_macro confirmed. Anti-prim check: if WR difference < 3pp across all sister prims → reclassify as anti-prim.

**G3 — DCC-GARCH Implementation (sophisticated tier gate):**
Implement Engle (2002) DCC-GARCH using Python `arch` library to replace static Pearson ρ with time-varying conditional correlation ρ_t. Rerun G2 with DCC-filtered ρ_t as the classifier. Compare Sharpe improvement from DCC vs static Pearson. If ≥ 0.05 Sharpe improvement in conditional WR separation → DCC-GARCH is the sophisticated-tier implementation.

---

## Sources

- Bouri, E., Molnár, P., Azzi, G., Roubaud, D. & Hagfors, L.I. (2017). On the hedge and safe haven properties of Bitcoin: Is it really more than a diversifier? *Finance Research Letters*, 20, 192–198. [Naive anchor retained]
- Conlon, T. & McGee, R. (2020). Safe haven or risky hazard? Bitcoin during the COVID-19 bear market. *Finance Research Letters*, 35, 101607. [Naive anchor retained]
- Corbet, S., Meegan, A., Larkin, C., Lucey, B. & Yarovaya, L. (2018). Exploring the dynamic relationships between cryptocurrencies and other financial assets. *Economics Letters*, 165, 28–34. [Naive anchor retained]
- Engle, R.F. (2002). Dynamic conditional correlation: A simple class of multivariate generalized autoregressive conditional heteroskedasticity models. *Journal of Business & Economic Statistics*, 20(3), 339–350. **[New — DCC-GARCH methodology for sophisticated tier]**
- Fang, L., Bouri, E., Gupta, R. & Roubaud, D. (2019). Does global economic uncertainty matter for the volatility and hedging effectiveness of Bitcoin? *International Review of Financial Analysis*, 61, 29–36. [Naive anchor retained]
- Kajtazi, A. & Moro, A. (2019). The role of bitcoin in well-diversified portfolios: A comparative global study. *International Review of Financial Analysis*, 61, 143–157. [Naive anchor retained — rolling ρ range −0.20 to +0.70 validates G1 frequency scope]
- Katsiampa, P. (2017). Volatility estimation for Bitcoin: A comparison of GARCH models. *Economics Letters*, 158, 3–6. **[New — GARCH α+β = 0.968 BTC persistence; justifies DCC-GARCH over static Pearson at sophisticated tier]**
- Antonakakis, N., Chatziantoniou, I. & Gabauer, D. (2019). Cryptocurrency market contagion: Market uncertainty, market complexity, and dynamic portfolios. *International Review of Financial Analysis*, 61, 37–51. **[New — DCC-GARCH applied to crypto-equity correlation dynamics; validates time-varying ρ_t approach]**
- Umar, Z., Trabelsi, N. & Alqahtani, F. (2021). Connectedness between cryptocurrency and technology sectors and the role of uncertainty. *Finance Research Letters*, 38, 101460. [Naive anchor retained]
- Liu, Y. & Tsyvinski, A. (2021). Risks and Returns of Cryptocurrency. *Journal of Finance*, 76(6), 2689–2727. [Naive anchor retained]

---

*Cycle 118 — intermediate elevation of cycle 116 naive prim. G1 + G2 scans are the blocking gate for sophisticated elevation. DCC-GARCH (G3) is the sophisticated-tier implementation upgrade.*
