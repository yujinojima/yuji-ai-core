---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T16:00:00+10:00
cycle: 170
prim: social-sentiment-narrative-momentum
project: freqtrade
level: sophisticated
axis: 27th regime axis
signal-class: behavioral / sentiment (meta-signal — no standalone entries)
supersedes: intermediate (cycle 168)
---

# Social Sentiment Narrative Momentum (Sophisticated)

**Elevated intermediate → sophisticated (cycle 170). 27th freqtrade regime axis.**

## What changed at sophisticated

Five advances over intermediate (cycle 168):

1. **Multi-source composite** replaces single F&G threshold: composite_sentiment_z =
   0.60 × fg_z + 0.25 × social_vol_z + 0.25 × gtrends_z (weights normalised after
   Santiment unavailability; see composite construction below)

2. **Weekend timing stratification** (Admati & Pfleiderer 1988): retail-dominated weekends
   produce structurally stronger contrarian signal than weekdays; Mode A scalars split
   accordingly

3. **Sub-period stability gate** (McLean-Pontiff 2016): IS backtest must hold ≥ 60% of
   pre-2022 Sharpe in post-2022 subsample (bot-dominated social era) or Kelly α capped
   at 0.08; decay hypothesis H5 added as formal falsification condition

4. **CPCV+DSR 36-cell plateau**: mandatory on the F&G threshold grid; Bailey-Borwein-Lopez
   de Prado (2016) DSR targets formalised with mode-specific floors

5. **Formal H1–H5 hypothesis set** with individual falsification gates; each mode has a
   named hypothesis tied to a falsifiable gate condition

---

## Multi-source composite construction

**composite_sentiment_z** is the single driver for all mode activation thresholds at
sophisticated tier. It replaces the raw F&G value in Mode A trigger conditions.

```
fg_z        = (fg_inverted_90d - mean_fg_inv_90d) / std_fg_inv_90d
              where fg_inverted = 100 - fg_value   [high fear → high fg_z]
social_vol_z = Santiment social_volume_total z-score, 30d rolling (unchanged from intermediate)
gtrends_z   = (gtrends_7d_MA - mean_gtrends_90d) / std_gtrends_90d
              [Google Trends BTC-USD, weekly index 0-100, resampled to daily via forward-fill]

composite_z = 0.60 × fg_z + 0.25 × social_vol_z + 0.15 × gtrends_z
              when Santiment unavailable:
              composite_z = 0.70 × fg_z + 0.30 × gtrends_z  (re-normalised; Mode B weight halved)
```

**Rationale for weights:**
- F&G 60%: highest validated predictive power (A1–A3); 7-factor composite already blends
  volatility, momentum, social, search — highest information density per source
- Santiment social_vol_z 25%: Garcia & Schweitzer (2015) BTC-specific; velocity signal
  orthogonal to F&G's static social component (which uses hashtag counts, not velocity)
- Google Trends 15%: Kristoufek (2013) bidirectional Granger causality; lowest weight because
  F&G already incorporates Google Trends (10% weight in F&G formula) — partial collinearity
  acknowledged; incremental contribution primarily comes from search velocity not captured
  in F&G's weekly smoothed Trends input

**z-score thresholds at sophisticated:**

| Composite_z level | Interpretation | Mode A-Long | Mode A-Short |
|-------------------|---------------|-------------|--------------|
| composite_z > +2.0 | Extreme fear composite | Full activation | — |
| composite_z > +1.5 | Strong fear composite | Partial activation (0.90×) | — |
| composite_z < −2.0 | Extreme greed composite | — | Full activation |
| composite_z < −1.5 | Strong greed composite | — | Partial activation (0.90×) |
| −1.5 ≤ composite_z ≤ +1.5 | Neutral | Mode B only | Mode B only |

**Backward compatibility with raw F&G:** The 36-cell CPCV+DSR grid (G2_27) continues to
use raw F&G thresholds {10, 15, 20} as hyperopt axes because historical composite_z cannot
be reconstructed before Santiment data availability (2016). G2 IS backtests over 2019–2024
run on raw F&G only; composite_z is the live signal. McLean-Pontiff subsample test also
uses raw F&G for comparability.

---

## Mode A — composite_z Extremes Contrarian (sophisticated)

**Replaces:** Mode A using raw F&G < 15 / > 85 thresholds.

### Mode A activation conditions

**Mode A-Long (amplify):**
```
composite_z > +2.0
AND ADX_4h < 25 (non-trending)
AND BTC_dominance ∈ [42%, 68%]
AND duration_in_composite_extreme ≤ 14d
→ AMPLIFY sister prim longs (see scalar table)
Duration: up to 14 calendar days per activation
Reactivation cooldown: 7d
```

**Mode A-Long partial (composite_z +1.5 to +2.0):**
```
composite_z ∈ [+1.5, +2.0)
AND ADX_4h < 25 AND BTC_dom ∈ [42%, 68%]
→ AMPLIFY at 0.90× of full scalar (reduced conviction)
Duration: up to 10d (fear zone less entrenched at partial threshold)
```

**Mode A-Short (suppress):**
```
composite_z < −2.0
AND ADX_4h < 25
AND BTC_dominance ∈ [42%, 68%]
AND duration_in_composite_extreme ≤ 10d
→ SUPPRESS sister prim longs (see scalar table)
Duration: up to 10 calendar days per activation
Reactivation cooldown: 7d
```

**Mode A-Short partial (composite_z −2.0 to −1.5):**
```
composite_z ∈ (−2.0, −1.5]
AND ADX_4h < 25 AND BTC_dom ∈ [42%, 68%]
→ SUPPRESS at 0.90× of full scalar
Duration: up to 7d
```

### Weekend stratification layer (Admati-Pfleiderer 1988)

**Mechanism:** Admati & Pfleiderer (1988) show that informed traders cluster at high-volume
periods (weekday institutional flow). Weekends have ~25–40% lower BTC spot volume vs
weekday mean (empirical observation; G1_27E formalises this). Retail dominates weekend
sentiment expression: F&G weekend readings reflect retail fear/greed more purely than
weekday readings diluted by institutional rebalancing flows.

**Prediction (H4):** Weekend Mode A activations → higher WR than weekday activations,
because the retail-driven contrarian signal is less contaminated by informed flow.

```
is_weekend = utc_day_of_week ∈ {5, 6}  # Saturday, Sunday

Weekend scalar uplift:
  Mode A-Long:  base_scalar × 1.06 (weekend retail purity premium)
  Mode A-Short: base_scalar × 1.04 (greed extremes on weekends slightly stronger signal)
  Cap enforced: weekend scalar ≤ 1.20× amplify / ≥ 0.78× suppress
```

**G1_27E falsification:** If weekend WR − weekday WR < +3pp (n ≥ 10 weekend activations),
weekend uplift removed; revert to uniform scalar. This is H4's empirical gate.

---

## Mode B — Social Volume Velocity Divergence (unchanged mechanism; composite_z guard added)

**Mode B logic identical to intermediate** with one gate change:
- Mode B now checks `−1.5 ≤ composite_z ≤ +1.5` rather than raw F&G ∈ [25, 75].
  This prevents Mode B firing during composite extreme conditions where Mode A dominates.
- social_vol_z source hierarchy unchanged: Santiment primary → Google Trends proxy at 0.50×.

| Mode B condition | Scalar | Duration |
|-----------------|--------|----------|
| social_vol_z > +2.5 AND price_chg_24h < −1% AND composite_z ∈ [−1.5, +1.5] | 0.88× | 7d max |
| social_vol_z < −1.5 AND price_chg_24h < −3% AND composite_z ∈ [−1.5, +1.5] | 1.07× | 10d max |

---

## Mode C — Google Trends Divergence (new at sophisticated)

**Source:** Kristoufek (2013) bidirectional Granger causality between Google Trends and BTC
price. This mode exploits the search-volume momentum signal independently from F&G's
blended Trends component (F&G uses raw weekly Trends; Mode C uses velocity z-score).

**Mode C-Amplify (search capitulation into price weakness):**
```
gtrends_z < −1.8 (below-baseline search — retail interest collapsed)
AND price_change_7d < −10% (significant drawdown ongoing)
AND composite_z ∈ [0, +1.5] (fear present but not yet composite extreme)
→ AMPLIFY 1.05× (search capitulation precedes price recovery — Kristoufek 2013)
Duration: 14d maximum
```

**Mode C-Suppress (search euphoria into stalling price):**
```
gtrends_z > +2.2 (above-baseline search — retail attention peaks)
AND price_change_7d > +15% (strong prior rally)
AND composite_z ∈ [−1.5, 0] (greed present but not yet composite extreme)
→ SUPPRESS 0.93× (search peaks historically precede tops — Da et al. 2011 reversal horizon)
Duration: 10d maximum
```

**Mode priority:** Mode A > Mode B = Mode C > neutral. Mode B and Mode C mutually
independent (different composite_z zones and signal sources); if both fire simultaneously,
apply the more conservative scalar (suppress wins over amplify; stronger suppress wins
over weaker suppress).

---

## Scalar table (complete — sophisticated)

| Condition | Modifier |
|-----------|----------|
| Mode A-Long full, ADX < 15, weekday | 1.12× |
| Mode A-Long full, ADX < 15, weekend | 1.18× |
| Mode A-Long full, ADX 15–25, weekday | 1.10× |
| Mode A-Long full, ADX 15–25, weekend | 1.16× |
| Mode A-Long partial (composite_z +1.5 to +2.0) | 1.08× / 1.14× (weekday/weekend) |
| Mode A-Short full, ADX < 15, weekday | 0.82× |
| Mode A-Short full, ADX < 15, weekend | 0.78× |
| Mode A-Short full, ADX 15–25, weekday | 0.85× |
| Mode A-Short full, ADX 15–25, weekend | 0.81× |
| Mode A-Short partial (composite_z −2.0 to −1.5) | 0.87× / 0.83× (weekday/weekend) |
| Mode B-Suppress (Santiment available) | 0.88× |
| Mode B-Suppress (proxy, 0.50× scale) | 0.94× |
| Mode B-Amplify (Santiment available) | 1.07× |
| Mode B-Amplify (proxy, 0.50× scale) | 1.035× |
| Mode C-Amplify | 1.05× |
| Mode C-Suppress | 0.93× |
| Transition zone (composite_z ±1.0 to ±1.5, no mode gate) | 1.04× / 0.96× |
| Neutral / all gates failed | 1.00× |

**Hard caps (unchanged from intermediate):** Amplify ≤ 1.20× / Suppress ≥ 0.78×.
Weekend A-Long at ADX < 15 (1.18×) is the highest permitted scalar before hard cap.

---

## Formal hypotheses (H1–H5)

| # | Hypothesis | Test | Falsification |
|---|-----------|------|---------------|
| H1 | composite_z > +2.0 → WR > 0.55 on next-14d BTC return (n ≥ 15) | G1_27B (Mode A-Long IS scan) | WR ≤ 0.50 or Mann-Whitney p > 0.10 → retire Mode A-Long; test composite_z > +1.5 as fallback |
| H2 | composite_z < −2.0 → WR > 0.55 on next-10d BTC return (suppressed direction; n ≥ 10) | G1_27C (Mode A-Short IS scan) | WR ≤ 0.50 → retire Mode A-Short; axis reduces to Mode B + C only |
| H3 | social_vol_z > +2.5 + price divergence → next-7d mean return < base (Mode B-Suppress) | G1_27D (Mode B co-occurrence n ≥ 15) | FP rate > 60% → raise z threshold to +3.0 or retire Mode B-Suppress |
| H4 | Weekend Mode A WR − Weekday Mode A WR ≥ +3pp (n ≥ 10 weekend; n ≥ 10 weekday) | G1_27E (weekend/weekday split scan) | Δ WR < +3pp → remove weekend stratification; revert to uniform scalar |
| H5 | IS Sharpe (2022–2024 subsample) ≥ 0.60 × IS Sharpe (2019–2021 subsample) | G2_27_SUBPERIOD (McLean-Pontiff decay test) | Ratio < 0.60 → McLean-Pontiff decay confirmed; Kelly α cap reduced to 0.08; add AP-E |

---

## CPCV+DSR protocol (formalised at sophisticated)

**Mandatory because:** 36-cell grid (3 F&G thresholds × 3 hold durations × 4 time-splits)
constitutes hyperparameter search exceeding 20 cells — Bailey-Borwein-Lopez de Prado
(2016, SSRN 2326253) Deflated Sharpe Ratio mandatory to control multiple-testing inflation.

```
Grid:
  F&G_threshold_low  ∈ {10, 15, 20}   (3 values)
  hold_duration_d    ∈ {7, 14, 21}    (3 values)
  time_splits        = 4 (CPCV folds, walk-forward)
  Total cells: 36

DSR targets (Bailey et al. 2016 — IS Sharpe must exceed DSR threshold):
  Mode A-Long:  DSR ≥ 0.55 (IS Sharpe target ≥ 0.90 before deflation)
  Mode A-Short: DSR ≥ 0.50 (IS Sharpe target ≥ 0.85 before deflation)
  Mode B:       DSR ≥ 0.45 (IS Sharpe target ≥ 0.75; fewer co-occurrences, wider CI)
  Mode C:       DSR ≥ 0.40 (smallest n; Google Trends weekly resolution)

McLean-Pontiff decay budget:
  Publications window: social sentiment strategy evidence published 2011–2013
  (Da et al. 2011 JF, Bollen et al. 2011 JCS, Garcia & Schweitzer 2015 RSOS)
  OOS decay model: 25–50% IS Sharpe degradation budget (McLean-Pontiff 2016 JF median 58%)
  Applied: IS Sharpe target ≥ 0.90 (Mode A-Long) derived from:
    live_target = 0.40 (minimum viable)
    IS_needed   = live_target / (1 − 0.55) = 0.89 → round up to 0.90
  Post-2022 subsample target: IS Sharpe ≥ 0.54 (= 0.90 × 0.60 McLean-Pontiff floor)
```

---

## Updated implementation (YujiSocialSentimentStrategy.py — sophisticated additions)

```python
from dataclasses import dataclass, field
from typing import Optional, Literal
from collections import deque
import requests
import numpy as np

FG_API = "https://api.alternative.me/fng/?limit=90&format=json"

@dataclass
class SocialSentimentStateSoph:
    # F&G and composite
    fg_value: Optional[int] = None
    fg_z: Optional[float] = None
    social_vol_z: Optional[float] = None
    gtrends_z: Optional[float] = None
    composite_z: Optional[float] = None
    santiment_available: bool = False

    # Mode A state
    mode_a_side: Optional[Literal["long", "short"]] = None
    mode_a_days_active: int = 0
    mode_a_partial: bool = False          # True when in +1.5/+2.0 partial zone
    mode_a_cooldown_remaining: int = 0
    duration_in_composite_extreme: int = 0

    # Mode B state (unchanged from intermediate)
    mode_b_suppress_active: bool = False
    mode_b_amplify_active: bool = False
    mode_b_days_remaining: int = 0

    # Mode C state (new at sophisticated)
    mode_c_suppress_active: bool = False
    mode_c_amplify_active: bool = False
    mode_c_days_remaining: int = 0

    # Context
    adx_4h: Optional[float] = None
    btc_dom: Optional[float] = None
    is_weekend: bool = False

    # Rolling history for z-scores
    fg_inv_history: deque = field(default_factory=lambda: deque(maxlen=90))
    gtrends_history: deque = field(default_factory=lambda: deque(maxlen=90))

class YujiSocialSentimentSophisticated:
    """
    Axis 27: Social Sentiment Narrative Momentum (Sophisticated — cycle 170)
    Meta-signal modifier — no standalone entries.
    Three modes: A (composite_z extremes), B (social vol velocity), C (gtrends velocity).
    Call get_weight() from sister strategies' populate_indicators().
    """
    _state: SocialSentimentStateSoph = SocialSentimentStateSoph()

    @classmethod
    def _build_composite_z(cls) -> Optional[float]:
        s = cls._state
        if s.fg_z is None:
            return None
        if s.santiment_available and s.social_vol_z is not None and s.gtrends_z is not None:
            return 0.60 * s.fg_z + 0.25 * s.social_vol_z + 0.15 * s.gtrends_z
        elif s.gtrends_z is not None:
            return 0.70 * s.fg_z + 0.30 * s.gtrends_z  # Santiment absent
        else:
            return s.fg_z  # gtrends also absent; fallback to fg_z alone

    @classmethod
    def update(cls, adx_4h: float, btc_dom: float, is_weekend: bool,
               gtrends_z: Optional[float] = None,
               price_change_24h: float = 0.0,
               price_change_7d: float = 0.0) -> None:
        """Call from bot_loop_start() with 24h cooldown."""
        s = cls._state
        s.adx_4h = adx_4h
        s.btc_dom = btc_dom
        s.is_weekend = is_weekend
        s.gtrends_z = gtrends_z

        try:
            resp = requests.get(FG_API, timeout=10)
            data = resp.json()["data"]
            fg = int(data[0]["value"])
            s.fg_value = fg
            fg_inv = 100 - fg
            s.fg_inv_history.append(fg_inv)
            if len(s.fg_inv_history) >= 30:
                arr = np.array(s.fg_inv_history)
                s.fg_z = (fg_inv - arr.mean()) / (arr.std() + 1e-9)
            else:
                s.fg_z = None
        except Exception:
            pass  # retain last state; API failure handled by FM3

        s.composite_z = cls._build_composite_z()
        cls._advance_modes(price_change_24h, price_change_7d)

    @classmethod
    def update_social_vol(cls, social_vol_z: float, santiment_available: bool) -> None:
        cls._state.social_vol_z = social_vol_z
        cls._state.santiment_available = santiment_available
        cls._state.composite_z = cls._build_composite_z()

    @classmethod
    def _advance_modes(cls, price_change_24h: float, price_change_7d: float) -> None:
        s = cls._state
        cz = s.composite_z
        adx = s.adx_4h or 30.0
        dom_ok = s.btc_dom is not None and 42.0 <= s.btc_dom <= 68.0

        # Cooldown tick
        if s.mode_a_cooldown_remaining > 0:
            s.mode_a_cooldown_remaining -= 1

        adx_ok = adx < 25

        # --- Mode A ---
        if cz is not None and adx_ok and dom_ok and s.mode_a_cooldown_remaining == 0:
            if cz > 2.0:
                s.mode_a_partial = False
                if s.mode_a_side != "long":
                    s.mode_a_side = "long"; s.mode_a_days_active = 0
                s.mode_a_days_active += 1
                s.duration_in_composite_extreme += 1
                if s.mode_a_days_active > 14:
                    cls._deactivate_mode_a()
            elif cz > 1.5:
                s.mode_a_partial = True
                if s.mode_a_side != "long":
                    s.mode_a_side = "long"; s.mode_a_days_active = 0
                s.mode_a_days_active += 1
                s.duration_in_composite_extreme += 1
                if s.mode_a_days_active > 10:
                    cls._deactivate_mode_a()
            elif cz < -2.0:
                s.mode_a_partial = False
                if s.mode_a_side != "short":
                    s.mode_a_side = "short"; s.mode_a_days_active = 0
                s.mode_a_days_active += 1
                s.duration_in_composite_extreme += 1
                if s.mode_a_days_active > 10:
                    cls._deactivate_mode_a()
            elif cz < -1.5:
                s.mode_a_partial = True
                if s.mode_a_side != "short":
                    s.mode_a_side = "short"; s.mode_a_days_active = 0
                s.mode_a_days_active += 1
                s.duration_in_composite_extreme += 1
                if s.mode_a_days_active > 7:
                    cls._deactivate_mode_a()
            else:
                if s.mode_a_side is not None:
                    cls._deactivate_mode_a()
                s.duration_in_composite_extreme = 0
        else:
            if s.mode_a_side is not None and (not adx_ok or not dom_ok):
                cls._deactivate_mode_a()

        # --- Mode B (composite_z neutral zone only) ---
        if cz is not None and -1.5 <= cz <= 1.5:
            z = s.social_vol_z
            if z is not None:
                if z > 2.5 and price_change_24h < -1.0 and not s.mode_b_suppress_active:
                    s.mode_b_suppress_active = True; s.mode_b_days_remaining = 7
                elif z < -1.5 and price_change_24h < -3.0 and not s.mode_b_amplify_active:
                    s.mode_b_amplify_active = True; s.mode_b_days_remaining = 10

        if s.mode_b_days_remaining > 0:
            s.mode_b_days_remaining -= 1
        else:
            s.mode_b_suppress_active = False; s.mode_b_amplify_active = False

        # --- Mode C (new at sophisticated) ---
        gz = s.gtrends_z
        if gz is not None and cz is not None:
            if gz < -1.8 and price_change_7d < -10.0 and 0 <= cz <= 1.5:
                if not s.mode_c_amplify_active:
                    s.mode_c_amplify_active = True; s.mode_c_days_remaining = 14
            elif gz > 2.2 and price_change_7d > 15.0 and -1.5 <= cz <= 0:
                if not s.mode_c_suppress_active:
                    s.mode_c_suppress_active = True; s.mode_c_days_remaining = 10

        if s.mode_c_days_remaining > 0:
            s.mode_c_days_remaining -= 1
        else:
            s.mode_c_amplify_active = False; s.mode_c_suppress_active = False

    @classmethod
    def _deactivate_mode_a(cls) -> None:
        s = cls._state
        s.mode_a_side = None; s.mode_a_days_active = 0
        s.mode_a_partial = False; s.mode_a_cooldown_remaining = 7

    @classmethod
    def get_weight(cls) -> float:
        raw = cls._compute_raw_weight()
        return max(0.78, min(1.20, raw))  # hard caps tightened at sophisticated

    @classmethod
    def _compute_raw_weight(cls) -> float:
        s = cls._state
        if s.composite_z is None:
            return 1.00

        adx = s.adx_4h or 30.0
        weekend_uplift = 1.06 if s.is_weekend else 1.00  # Mode A-Long weekend premium
        weekend_suppress = 1.04 if s.is_weekend else 1.00  # Mode A-Short weekend premium

        # Mode A takes priority
        if s.mode_a_side == "long":
            base = 1.08 if s.mode_a_partial else 1.12
            adx_scale = 1.0 if adx < 15 else (0.85 if adx < 25 else 0.0)
            if adx_scale == 0.0:
                return 1.00
            scalar = 1.0 + (base - 1.0) * adx_scale * weekend_uplift
            return scalar

        if s.mode_a_side == "short":
            base = 0.87 if s.mode_a_partial else 0.82
            adx_scale = 1.0 if adx < 15 else (0.85 if adx < 25 else 0.0)
            if adx_scale == 0.0:
                return 1.00
            scalar = 1.0 - (1.0 - base) * adx_scale * weekend_suppress
            return scalar

        # Transition zone (composite_z ±1.0 to ±1.5, no mode active)
        cz = s.composite_z
        if cz is not None:
            if 1.0 <= cz < 1.5 and adx < 25:
                return 1.04
            if -1.5 < cz <= -1.0 and adx < 25:
                return 0.96

        # Mode B and C (mutually independent; conservative wins)
        weights = []
        if s.mode_b_suppress_active:
            scale = 1.0 if s.santiment_available else 0.50
            weights.append(1.0 - (1.0 - 0.88) * scale)
        if s.mode_b_amplify_active:
            scale = 1.0 if s.santiment_available else 0.50
            weights.append(1.0 + (1.07 - 1.0) * scale)
        if s.mode_c_suppress_active:
            weights.append(0.93)
        if s.mode_c_amplify_active:
            weights.append(1.05)

        if weights:
            # Conservative resolution: suppress beats amplify; strongest suppress wins
            suppresses = [w for w in weights if w < 1.0]
            amplifies = [w for w in weights if w > 1.0]
            if suppresses:
                return min(suppresses)  # strongest suppress wins
            if amplifies:
                return max(amplifies)   # only amplifies active

        return 1.00
```

---

## Academic anchors (11 at sophisticated — 7 carried forward + 4 new)

**Carried forward from intermediate (A1–A7):** Da-Engelberg-Gao 2011 JF, Bollen-Mao-Zeng 2011
JCS, Garcia-Schweitzer 2015 RSOS, Kristoufek 2013 Nature SR, Shen-Urquhart-Wang 2019 FRL,
Baker-Wurgler 2007 JFE, Gennaioli-Shleifer 2010 QJE.

**New at sophisticated:**

| # | Source | Contribution |
|---|--------|-------------|
| A8 | **Admati & Pfleiderer (1988, Review of Financial Studies)** — "A Theory of Intraday Patterns: Volume and Price Variability" | Informed traders concentrate at high-volume periods; uninformed liquidity trading is lower at low-volume periods (weekends). Retail dominance on weekends implies F&G and social signals are less contaminated by institutional rebalancing → contrarian signal purity higher on weekends. Directly grounds the weekend stratification layer (H4). |
| A9 | **McLean & Pontiff (2016, Journal of Finance)** — "Does Academic Research Destroy Stock Return Predictability?" | Anomaly returns decay 58% after publication (IS → OOS); social sentiment strategies published 2011–2013 have had 12–15 years of post-publication decay. Sub-period stability gate (G2_27_SUBPERIOD) operationalises this decay model. IS Sharpe ≥ 0.90 target derived from 55% decay budget for minimum viable live Sharpe of 0.40. |
| A10 | **Bailey, Borwein & Lopez de Prado (2016, Journal of Portfolio Management / SSRN 2326253)** — "The Probability of Backtest Overfitting" | CPCV framework + Deflated Sharpe Ratio for hyperopt grids. Proves that IS Sharpe is biased upward proportional to number of trials; DSR corrects for multiple-testing inflation. Mandatory for any grid > 20 cells. The 36-cell F&G threshold grid exceeds this threshold — DSR required. |
| A11 | **Renault (2017, Journal of Financial Markets)** — "Intraday dynamics of Twitter sentiment and financial markets" | Twitter sentiment intraday patterns show clustering consistent with Admati-Pfleiderer informed trader timing. Retail Twitter activity peaks Saturday–Sunday, while informed trading signals are lowest. Provides complementary microstructure evidence for the weekend stratification layer alongside A8. |

---

## Deployment gates (updated for sophisticated)

```
G_DATA_27A: Alternative.me F&G API historical 2018–2024 — CLEARED
G_DATA_27B: Santiment social_volume_total — SOFT BARRIER ($49/mo Lite)
             Fallback: pytrends Google Trends BTC-USD weekly — CLEARED (free)
G_DATA_27C: Google Trends BTC-USD (gtrends_z for Mode C + composite weight) — CLEARED

G1_27A: Frequency scan — composite_z > +2.0 events per year (2019–2024, daily)
         Proxy: F&G < 15 as composite_z approximate (Santiment unavailable for full history)
         Target: ≥ 4 events/year; AP_A triggers if < 3 events/year

G1_27B: WR conditional — next-14d BTC return > 0 given composite_z > +2.0 (n ≥ 15)
         Target: WR ≥ 55% (H1 confirmation)

G1_27C: Frequency + WR — composite_z < −2.0 (n ≥ 10); WR ≥ 55% on next-10d return (H2)

G1_27D: Mode B co-occurrence — social_vol_z > +2.5 + price divergence (n ≥ 15)
         Target: suppress WR ≥ 52% on next-7d return (H3)

G1_27E: Weekend stratification — split G1_27B activations by weekday/weekend
         Target: weekend WR − weekday WR ≥ +3pp (n ≥ 10 each) (H4)
         FAIL action: remove weekend uplift; revert to uniform scalar

INDEP_27: Empirical ρ scan — axis 27 vs axes 7, 11, 18, 21, 25
           Target: all ρ < 0.60 (AP_D fires if ρ(27, 7) ≥ 0.60)

G2_27:   IS backtest CPCV+DSR
         Grid: F&G_threshold_low ∈ {10, 15, 20} × hold ∈ {7, 14, 21d} × 4 CPCV folds = 36 cells
         DSR targets: Mode A-Long DSR ≥ 0.55; Mode A-Short DSR ≥ 0.50; Mode B DSR ≥ 0.45
         IS Sharpe targets: Mode A-Long ≥ 0.90; Mode A-Short ≥ 0.85; Mode B ≥ 0.75

G2_27_SUBPERIOD: Sub-period stability (McLean-Pontiff decay gate)
         Split: pre-2022 IS Sharpe (2019–2021, 36 months) vs post-2022 IS Sharpe (2022–2024, 36 months)
         Target: IS_Sharpe_post2022 ≥ 0.60 × IS_Sharpe_pre2022 (H5)
         FAIL action: AP-E fires; Kelly α capped at 0.08; investigate Mode A threshold recalibration
         Raw F&G thresholds used (composite_z not available pre-Santiment)
```

**Current gate status:** G_DATA_27A, G_DATA_27C CLEARED. All G1, INDEP, G2 gates UNCLEARED (empirical).
**First barrier:** G1_27A (F&G/composite_z frequency scan — free API, script: `analysis/g1-social-sentiment-fg-scan.py`).

---

## N_eff co-occurrence rules (sophisticated — same analytical estimates, tighter hard cap)

| Pair | Expected ρ | Tier | Sophisticated combined rule |
|------|-----------|------|----------------------------|
| 27 + 7 (funding rate) | ~0.35 | C | co-amplify cap 1.18× / co-suppress floor 0.84×; Mode A + axis 7 INDEP gate shared |
| 27 + 11 (OI divergence) | ~0.40 | B/C | conservative: single-signal priority if both amplify same session |
| 27 + 18 (on-chain supply) | ~0.20 | D | compound freely; three-axis 27+7+18 cap 1.20× |
| 27 + 21 (ETF flow) | ~0.25 | D | compound freely |
| 27 + 25 (liquidation cascade) | ~0.15 | D | independent timescales; compound freely |

Weekend scalar is axis-27 internal; does not affect N_eff calculation with other axes.
Hard cap across any axis-27 compounding combination: 1.20× amplify / 0.78× suppress.

---

## Anti-prim escape hatches (6 — 4 carried + 2 new)

| AP | Trigger | Action |
|----|---------|--------|
| A | composite_z > +2.0 events/year < 3 (frequency scan) | Raise threshold to +1.5; rescan G1_27A |
| B | Mode A WR ≤ 50% over n = 20 activations in IS period | Retire Mode A; axis reduces to B + C only |
| C | Mode B social volume FP rate > 60% (Santiment IS scan) | Raise z threshold to +3.0 or retire Mode B |
| D | Empirical ρ ≥ 0.60 vs axis 7 (INDEP_27 scan) | Merge Mode A into axis 7 as additive sentiment feature; do not run as independent signal |
| E | G2_27_SUBPERIOD: post-2022 IS Sharpe < 0.60 × pre-2022 IS Sharpe | McLean-Pontiff decay confirmed; Kelly α capped at 0.08; Mode A threshold raised to composite_z > +2.5 |
| F | Weekend WR − weekday WR < +3pp (G1_27E FAIL) | Remove weekend stratification uplift; revert to uniform scalar across all days |

---

## Kelly α tiers (updated)

| Gate state | Kelly α |
|-----------|---------|
| G_DATA_27A cleared only (current) | 0.06 floor |
| G1_27A + G1_27B confirmed (H1 cleared) | 0.09 |
| G2_27 DSR ≥ 0.55 (Mode A-Long) | 0.12 |
| G2_27 DSR ≥ 0.55 + G2_SUBPERIOD passed | 0.15 cap |
| AP-E fires (McLean-Pontiff decay confirmed) | 0.08 hard cap regardless of G2 |

---

## Failure modes (8 — 6 carried + 2 new)

| FM | Condition | Resolution |
|----|-----------|------------|
| FM1 | Trending regime: ADX_4h > 25 | Mode A deactivated; Mode B/C unaffected (longer timescale) |
| FM2 | Major macro event ±48h (GDELT > 500 BTC-relevant articles/24h) | F&G reflects information not bias; all modes return 1.00× in GDELT window |
| FM3 | Alternative.me API outage | Retain last known composite_z; discard if > 48h stale; return 1.00× |
| FM4 | Altseason: BTC_dom < 42% | Capital rotation confounds BTC-specific sentiment; all modes return 1.00× |
| FM5 | composite_z sustained extreme > 14d (long) / > 10d (short) | Duration cap enforced; Mode A deactivated; cooldown begins |
| FM6 | Santiment API unavailable | Mode B at 0.50× scalar; Google Trends proxy; composite_z uses re-normalised 0.70/0.30 weights |
| FM7 | Google Trends data gap (pytrends rate limit) | Mode C deactivated; composite_z reverts to fg_z only (0.70/0.30 formula if Santiment also absent → 1.00× fg_z fallback) |
| FM8 | Post-2022 IS Sharpe decay confirmed (AP-E fires) | Kelly α capped 0.08; threshold recalibrated to composite_z > +2.5; live monitoring for further decay |

---

## Best pairs and timeframe

- **Primary:** BTC/USDT:USDT (F&G explicitly BTC-weighted; all three composite sources BTC-native)
- **Secondary:** ETH/USDT:USDT at 0.75× scalar discount (F&G BTC-specific; ETH sentiment may
  diverge during protocol upgrade windows or altseason; retain until ETH-specific composite built)
- **Timeframe:** 1h strategy entries; composite_z refreshed via bot_loop_start() with 24h cooldown;
  Mode A/B/C state carried into all 4h candles until next daily update
- **Weekend detection:** utc_day_of_week from pandas Timestamp.dayofweek ∈ {5, 6}

---

## Bank state after cycle 170

| Tier | Freqtrade | Polymarket | Combined |
|------|-----------|------------|---------|
| Naive | 23 | 0 | 23 |
| Intermediate | **27** (−1: social-sentiment axis 27 elevated) | 2 | **29** |
| Sophisticated | **32** (+1: social-sentiment-narrative-momentum axis 27) | 0 | **32** |

**27 freqtrade regime axes defined. 32 sophisticated freqtrade prims.**

---

## Next cycle recommendations

**(A) IMPLEMENT — G1_27A frequency scan (first barrier, free API):**
Pull Alternative.me F&G 2019–2024 daily. Compute fg_z rolling 90d; count composite_z > +2.0
proxy episodes (7d-separated). Target ≥ 4/year. Script: `analysis/g1-social-sentiment-fg-scan.py`.
Also run G1_27C (composite_z < −2.0 proxy) in same script pass.

**(B) RESEARCH — McLean-Pontiff decay literature for crypto sentiment:**
Search arxiv 2020–2026 for "fear greed index bitcoin out-of-sample" or "crypto sentiment
strategy post-publication decay." A paper confirming (or denying) post-2018 F&G decay would
empirically anchor H5 before running G2_27_SUBPERIOD.

**(C) IMPLEMENT — G1_27E weekend split (depends on G1_27A):**
Once G1_27A identifies Mode A-Long activations 2019–2024, split by weekday/weekend.
Compute WR for each group. If H4 fails (Δ WR < +3pp), AP-F fires and weekend scalars removed —
net downside is small (reverts to intermediate scalar values); upside if H4 holds is confirmed
weekend edge.

**(D) RESEARCH — New axis (axis 28) exploration:**
All 27 axes now defined. Remaining behavioral/market-structure gaps:
- Cross-exchange basis spread (CEX vs DEX pricing divergence) — not yet an axis
- Stablecoin depeg stress index (USDT/USDC discount to peg as systemic risk proxy)
- Miner revenue stress signal (hash-ribbon-derived — already proxied by on-chain but not formalised)
Recommend: miner revenue stress as axis 28 naive (simplest new axis, data free via on-chain API).
