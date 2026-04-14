---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T14:00:00+10:00
cycle: 168
prim: social-sentiment-narrative-momentum
project: freqtrade
level: intermediate
axis: 27th regime axis
signal-class: behavioral / sentiment (meta-signal — no standalone entries)
---

# Social Sentiment Narrative Momentum (Intermediate)

**New prim, created directly at intermediate (cycle 168). 27th freqtrade regime axis.**

## Gap this axis fills

All 26 existing freqtrade axes measure structural market phenomena: on-chain blockchain state
(axes 18, 19, 21, 23), options dealer mechanics (axes 15, 16, 17), order flow and execution
(axes 24, 26), volatility dynamics (axes 14, 20), price structure (axes 1–13), and event-driven
cascades (axis 25). None measures **expressed retail sentiment** — the composite of what retail
participants say they feel about the market via social media, search behaviour, and sentiment
survey instruments.

This is the behavioral gap. The mechanism that axis 27 exploits is well-documented:

1. **Cognitive availability bias** (Kahneman 2011): Recent salient events (large price moves,
   viral narratives) are overweighted. When BTC falls 20%, extreme fear is anchored to that event;
   actual statistical recovery probability is underpriced.
2. **Herding dynamics** (Gennaioli & Shleifer 2010): Agents form expectations based on
   salience-weighted samples of similar situations. At extremes (F&G < 15 or > 85), the crowd is
   maximally herded — meaning the marginal informed trader faces a maximally mispriced asset.
3. **Social volume velocity divergence** (Garcia & Schweitzer 2015): A spike in social volume
   that diverges from price direction signals narrative-price dissonance. The crowd is talking
   about a move that isn't happening — or has already reversed — which predicts rapid convergence.

## Mechanistic orthogonality from all 26 existing axes

| Axis | Measures | Axis 27 distinction |
|------|----------|---------------------|
| 7 (Funding rate) | Futures crowding (per-8h fee) | Axis 7 = funding mechanics; Axis 27 = expressed crowd belief composite; different sources, different timescales (4–8h vs 7–21d) |
| 18 (On-chain supply) | LTH/STH cost basis (blockchain state) | Blockchain state ≠ social expression; MVRV measures realised P&L, not stated opinion |
| 21 (ETF flow) | Institutional demand (filing-derived) | Institutional capital ≠ retail narrative; ETF flows precede sentiment extremes |
| 24/26 (OBI / CVD) | Order book / executed flow | What traders DO (execute) ≠ what they SAY (social sentiment); different lead/lag structure |
| 11 (OI divergence) | Futures open interest direction | Derivative positioning ≠ social expressed belief; OI measures speculative commitment |
| 25 (Liquidation cascade) | Event-driven forced exit | Discrete event vs continuous sentiment composite |

Expected ρ estimates (all below Tier B threshold before empirical confirmation):
- Axis 27 + Axis 7: ρ ≈ 0.35 (both contrarian; but F&G is 7-factor vs single rate; Tier C)
- Axis 27 + Axis 18: ρ ≈ 0.20 (expressed opinion vs blockchain state; Tier D)
- Axis 27 + Axis 21: ρ ≈ 0.25 (retail sentiment vs institutional capital; Tier D)
- Axis 27 + Axis 11: ρ ≈ 0.40 (crowding → sentiment sequence; partial overlap; Tier B/C)

All ρ estimates are analytical (empirically UNCLEARED — G1 independence scan required).

---

## Two-mode architecture

### Mode A — F&G Extremes Contrarian

**Trigger:** Alternative.me Fear & Greed Index (F&G) enters extreme zone.

**Mode A-Long (amplify):**
```
F&G < 15 (extreme fear, < 10th percentile of 2019–2024 daily distribution)
AND ADX_4h < 25 (non-trending regime — in trends, sentiment extremes persist)
AND BTC_dominance ∈ [42%, 68%] (altseason exclusion — BTC sentiment confounded)
AND duration_in_extreme ≤ 14d (duration cap — prevents amplifying into sustained bear)
→ AMPLIFY sister prim longs: 1.12×
Duration: up to 14 calendar days per activation
Reactivation cooldown: 7d after Mode A-Long deactivation
```

**Mode A-Short (suppress):**
```
F&G > 85 (extreme greed, > 90th percentile)
AND ADX_4h < 25
AND BTC_dominance ∈ [42%, 68%]
AND duration_in_extreme ≤ 10d
→ SUPPRESS sister prim longs: 0.82×
Duration: up to 10 calendar days per activation
Reactivation cooldown: 7d after Mode A-Short deactivation
```

**Rationale for asymmetric caps (14d vs 10d):**
Fear regimes tend to overshoot and persist longer before recovery (Kahneman 2011 loss aversion
asymmetry). Greed regimes at crypto extremes reverse faster (retail distribution into
institutional accumulation — Admati & Pfleiderer 1988 informed trader timing).
The 14d/10d cap is the intermediate hypothesis; G1_27B will calibrate via empirical data.

**ADX routing logic:**
- ADX_4h < 15 (ranging): Mode A fires at full weight
- ADX_4h 15–25 (moderate): Mode A fires at 0.85× scaled weight
- ADX_4h > 25 (trending): Mode A deactivated; returns 1.00× neutral
  (In strong trends, sentiment extremes are information, not bias — Da et al. 2011 trending SVI
  shows momentum rather than reversal; the contrarian mechanism requires ranging context)

### Mode B — Social Volume Velocity Divergence

**Trigger:** Santiment social_volume_total for BTC-USD deviates from 30-day baseline with
simultaneous price direction divergence.

**Mode B-Suppress (narrative bubble):**
```
social_vol_z_24h > +2.5 (z-score vs 30d rolling mean, 1 std)
AND price_change_24h < -1% (price falling while narrative is euphoric)
AND F&G ∈ [40, 75] (moderate zone — not already in extreme; Mode A not active)
→ SUPPRESS sister prim longs: 0.88×
Duration: 7 calendar days maximum
```

**Mode B-Amplify (capitulation of narrative):**
```
social_vol_z_24h < -1.5 (narrative collapse — below-baseline social engagement)
AND price_change_24h < -3% (price is falling while no one is talking — silent capitulation)
AND F&G ∈ [25, 55] (moderate, not yet extreme fear — Mode A not yet triggered)
→ AMPLIFY sister prim longs: 1.07×
Duration: 10 calendar days maximum
```

**Rationale for Mode B:**
Garcia & Schweitzer (2015) found that social media volume peaks PRECEDE BTC price reversals by
1–3 days. A social volume spike without confirming price direction = narrative overshoot.
A social volume collapse in moderate F&G while price falls = pre-capitulation exhaustion of
selling narrative, which historically precedes technical recovery bounces.

---

## Scalar outputs

| Condition | Modifier |
|-----------|----------|
| Mode A-Long (full, ADX < 15) | 1.12× |
| Mode A-Long (partial, ADX 15–25) | 1.10× |
| Mode A-Short (full, ADX < 15) | 0.82× |
| Mode A-Short (partial, ADX 15–25) | 0.85× |
| Mode B-Suppress | 0.88× |
| Mode B-Amplify | 1.07× |
| Neutral / all gates failed | 1.00× |

**Stacking rule:** Mode A and Mode B are mutually exclusive by design (Mode B requires F&G in
moderate zone [25–75], which prohibits Mode A activation at extremes < 15 or > 85). If F&G is
ambiguously in [15–25] or [75–85] transition zone: Mode A takes precedence at 0.75× weight
(transition zone → reduced conviction).

**Hard caps:** Amplify ≤ 1.15× / Suppress ≥ 0.80× (enforce in strategy code regardless of
future escalation; maintains loss control under unexpected F&G persistence).

---

## Data sources and implementation

### Primary: Alternative.me Fear & Greed Index

```python
# Endpoint: completely free, no API key, historical 2018-present
GET https://api.alternative.me/fng/?limit=60&format=json
# Returns: list of {value, value_classification, timestamp} for last 60 days
```

F&G is a composite of 7 factors:
1. Volatility (25%): current BTC volatility vs 30d/90d averages
2. Market momentum/volume (25%): current volume vs 30d average in bullish market
3. Social media (15%): Twitter hashtag counts and interaction rates
4. Surveys (15%): Weekly CoinMarketCap surveys (currently on hold)
5. Bitcoin dominance (10%): rising dominance = fear (rotation from alts to BTC safe haven)
6. Google Trends (10%): BTC search terms, "Bitcoin crash" queries
7. (Historical: volatility component updated quarterly)

**G_DATA_27A status: CLEARED** — public endpoint, no authentication, historical from 2018.

### Secondary: Santiment Social Volume

```python
# Santiment API (freemium, 90-day trial or $49/mo Lite tier)
# Endpoint: social_volume_total for bitcoin, daily resolution
import requests
headers = {"Authorization": f"Apikey {SANTIMENT_KEY}"}
params = {"slug": "bitcoin", "from": from_date, "to": to_date, "interval": "1d"}
GET https://api.santiment.net/graphql  # social_volume_total query
```

**G_DATA_27B status: SOFT BARRIER** — requires Santiment API key.
**Fallback (Mode B proxy):** Google Trends BTC-USD weekly search volume via pytrends:
```python
from pytrends.request import TrendReq
pytrends = TrendReq()
pytrends.build_payload(["Bitcoin"], timeframe="today 3-m")
df = pytrends.interest_over_time()  # returns weekly index 0–100
```
Google Trends is free (no API key), but lower temporal resolution (weekly vs daily). When
Santiment unavailable, Mode B operates at 0.50× scalar weight (conservative; higher FP rate
acknowledged in FM6).

### Implementation file: YujiSocialSentimentStrategy.py

```python
from collections import deque
from dataclasses import dataclass
from typing import Optional, Literal
import requests
import numpy as np

FG_API = "https://api.alternative.me/fng/?limit=60&format=json"

@dataclass
class SocialSentimentState:
    fg_value: Optional[int] = None          # 0–100 daily F&G
    fg_duration_in_extreme: int = 0         # days in current extreme zone
    mode_a_side: Optional[Literal["long","short"]] = None
    mode_a_days_active: int = 0
    mode_a_cooldown_remaining: int = 0
    social_vol_z: Optional[float] = None    # 30d z-score
    mode_b_active: bool = False
    mode_b_days_remaining: int = 0
    adx_4h: Optional[float] = None
    btc_dom: Optional[float] = None         # BTC dominance %

class YujiSocialSentimentMetaSignal:
    """
    Axis 27: Social Sentiment Narrative Momentum
    Meta-signal modifier — no standalone entries.
    Call get_weight() from sister strategies' populate_indicators().
    """
    _state: SocialSentimentState = SocialSentimentState()
    _fg_history: deque = deque(maxlen=60)   # 60d rolling F&G values

    @classmethod
    def update(cls, adx_4h: float, btc_dom: float) -> None:
        """Call from bot_loop_start() with 24h cooldown (F&G updates daily)."""
        try:
            resp = requests.get(FG_API, timeout=10)
            data = resp.json()["data"]
            fg = int(data[0]["value"])
            cls._fg_history.append(fg)
            cls._state.fg_value = fg
            cls._state.adx_4h = adx_4h
            cls._state.btc_dom = btc_dom
            cls._advance_state()
        except Exception:
            pass  # retain previous state on API failure

    @classmethod
    def _advance_state(cls) -> None:
        s = cls._state
        # Cooldown tick
        if s.mode_a_cooldown_remaining > 0:
            s.mode_a_cooldown_remaining -= 1

        # ADX routing: compute adx_scale
        if s.adx_4h is None or s.adx_4h > 25:
            adx_scale = 0.0  # Mode A deactivated in trending
        elif s.adx_4h < 15:
            adx_scale = 1.0
        else:
            adx_scale = 0.85

        # BTC dominance gate
        dom_ok = s.btc_dom is not None and 42.0 <= s.btc_dom <= 68.0

        # Mode A logic
        if s.fg_value is not None and adx_scale > 0 and dom_ok and s.mode_a_cooldown_remaining == 0:
            if s.fg_value < 15:
                if s.mode_a_side != "long":
                    s.mode_a_side = "long"
                    s.mode_a_days_active = 0
                s.fg_duration_in_extreme += 1
                s.mode_a_days_active += 1
                if s.mode_a_days_active > 14:
                    cls._deactivate_mode_a()
            elif s.fg_value > 85:
                if s.mode_a_side != "short":
                    s.mode_a_side = "short"
                    s.mode_a_days_active = 0
                s.fg_duration_in_extreme += 1
                s.mode_a_days_active += 1
                if s.mode_a_days_active > 10:
                    cls._deactivate_mode_a()
            else:
                if s.mode_a_side is not None:
                    cls._deactivate_mode_a()
                s.fg_duration_in_extreme = 0
        else:
            if s.mode_a_side is not None and (adx_scale == 0.0 or not dom_ok):
                cls._deactivate_mode_a()

    @classmethod
    def _deactivate_mode_a(cls) -> None:
        cls._state.mode_a_side = None
        cls._state.mode_a_days_active = 0
        cls._state.mode_a_cooldown_remaining = 7  # 7d cooldown

    @classmethod
    def update_social_vol(cls, social_vol_z: float) -> None:
        """Call separately with Santiment z-score (or Google Trends proxy)."""
        cls._state.social_vol_z = social_vol_z

    @classmethod
    def get_weight(cls, price_change_24h: float,
                   santiment_available: bool = True) -> float:
        s = cls._state
        if s.fg_value is None:
            return 1.0

        # Hard cap/floor enforced
        raw = cls._compute_raw_weight(price_change_24h, santiment_available)
        return max(0.80, min(1.15, raw))

    @classmethod
    def _compute_raw_weight(cls, price_change_24h: float,
                             santiment_available: bool) -> float:
        s = cls._state
        adx = s.adx_4h or 30.0

        # Mode A takes precedence if active
        if s.mode_a_side == "long":
            scale = 1.0 if adx < 15 else 0.85
            return 1.12 * scale + (1 - scale)
        if s.mode_a_side == "short":
            scale = 1.0 if adx < 15 else 0.85
            return (0.82 * scale + 1.0 * (1 - scale))

        # Transition zone (F&G 15–25 or 75–85) — Mode A at 0.75× conviction
        if s.fg_value is not None:
            if s.fg_value < 25 and adx < 25:
                return 1.0 + 0.75 * (1.12 - 1.0)
            if s.fg_value > 75 and adx < 25:
                return 1.0 - 0.75 * (1.0 - 0.82)

        # Mode B logic
        z = s.social_vol_z
        vol_scale = 1.0 if santiment_available else 0.50

        if z is not None and 40 <= (s.fg_value or 50) <= 75:
            if z > 2.5 and price_change_24h < -1.0:
                return 1.0 - (1.0 - 0.88) * vol_scale  # suppress
        if z is not None and 25 <= (s.fg_value or 50) <= 55:
            if z < -1.5 and price_change_24h < -3.0:
                return 1.0 + (1.07 - 1.0) * vol_scale  # amplify

        return 1.00
```

---

## Academic anchors (7 at intermediate)

| # | Source | Contribution |
|---|--------|-------------|
| A1 | **Da, Engelberg & Gao (2011, Journal of Finance)** — "In Search of Attention" | Google SVI (search volume index) predicts future stock returns: +14.8% excess return in weeks 1–2, then reversal. Primary mechanism: retail attention is a lagging, herding-driven signal. Crypto extrapolation: BTC search spikes = late retail entry = contrarian fade. |
| A2 | **Bollen, Mao & Zeng (2011, Journal of Computational Science)** | Twitter mood states predict DJIA 2–6 days ahead with Granger causality (F=0.005); "Calm" state most predictive (calm vs anxious maps to F&G 40–60 neutral vs extreme). 87.6% accuracy on direction in 2008 Twitter data. Mechanism: aggregate mood encodes crowd expectation. |
| A3 | **Garcia & Schweitzer (2015, Royal Society Open Science)** | BTC-specific: positive Twitter sentiment → next-day positive BTC returns (Granger p < 0.01); negative sentiment → negative returns. Social volume SPIKES precede price reversals by 1–3 days (Mode B mechanism). Directly validates Mode B-Suppress: social volume spike into price weakness = pre-reversal signal. |
| A4 | **Kristoufek (2013, Nature Scientific Reports)** — "BitCoin meets Google Trends and Wikipedia" | BTC-specific: Google Trends and Wikipedia search volumes are Granger-caused BY price AND Granger-cause price (bidirectional). Above-trend search → positive price momentum short-term; below-trend → negative. Supports Mode B z-score velocity measure. |
| A5 | **Shen, Urquhart & Wang (2019, Finance Research Letters)** — "Does Twitter predict Bitcoin?" | Twitter volume (not sentiment) significantly predicts BTC next-day returns and volatility (Granger p < 0.05); out-of-sample R² improvement over baseline models. Pure volume signal (Mode B axis) validated independently from sentiment directional signal (Mode A). |
| A6 | **Baker & Wurgler (2007, Journal of Financial Economics)** — "Investor Sentiment in the Stock Market" | Survey-based sentiment composite (BW index) is contrarian predictor of cross-sectional returns; hard-to-value, speculative assets (BTC is the canonical modern example) show strongest sentiment sensitivity. Validates F&G contrarian mechanism at extreme zones. |
| A7 | **Gennaioli & Shleifer (2010, QJE)** — "What Comes to Mind" | Salience theory: agents over-represent available scenarios proportional to their salience weight. At F&G < 15, "crash scenarios" are maximally salient → downside overpriced → upside underpriced. At F&G > 85, "moon scenarios" maximally salient → upside overpriced. Provides theoretical mechanism grounding for Mode A contrarian thresholds. |

**What remains for sophisticated elevation:**
1. Hour-of-week stratification (weekend F&G dynamics — less institutional flow → higher retail noise → potentially stronger contrarian signal; Admati-Pfleiderer 1988 informed timing)
2. Multi-source composite: F&G (weighted 60%) + Santiment social_vol_z (25%) + Google Trends BTC (15%) → composite sentiment score replacing single F&G threshold
3. CPCV+DSR 36-cell grid (3 F&G thresholds [10/15/20] × 3 hold periods [7/14/21d] × 4 time-splits) — mandatory if threshold is grid-searched
4. McLean-Pontiff (2016) decay check: social sentiment signal became widely known post-2015 (multiple academic papers, retail awareness); needs post-2018 subsample test vs pre-2018 baseline
5. Empirical N_eff correlation matrix (actual ρ values for axes 7, 11, 18, 21)

---

## Failure modes (6)

| FM | Condition | Resolution |
|----|-----------|------------|
| FM1 | Trending regime: ADX_4h > 25 | Mode A deactivated; returns 1.00× neutral |
| FM2 | Major macro event ±48h (GDELT > 500 BTC-relevant articles/24h) | F&G reflects information, not bias; both modes return 1.00× in GDELT event window |
| FM3 | Alternative.me API outage | Retain last known state; discard if > 48h stale; return 1.00× |
| FM4 | Altseason: BTC_dom < 42% | Capital rotation confounds BTC-specific sentiment; both modes return 1.00× |
| FM5 | F&G sustained extreme (> 14d long / > 10d short) | Duration cap enforced; Mode A deactivated; cooldown begins |
| FM6 | Santiment API unavailable | Mode B operates at 0.50× scalar; Google Trends weekly proxy accepted as fallback |

---

## Anti-prim escape hatches (4)

| AP | Trigger | Action |
|----|---------|--------|
| A | F&G < 15 events/year < 3 (2019–2024 scan) | Signal too rare for statistical power; raise threshold to F&G < 20 and rescan |
| B | Mode A WR ≤ 50% over n = 20 activations in IS period | Contrarian mechanism absent; retire Mode A; axis reduces to Mode B only |
| C | Mode B social volume FP rate > 60% (Santiment) | Narrative divergence not predictive at 24h resolution; retire Mode B or raise z threshold to > 3.0 |
| D | Empirical ρ ≥ 0.60 vs axis 7 (funding rate) | N_eff overlap too high; merge Mode A into axis 7 as additive sentiment feature; do not operate as independent signal |

---

## Deployment gates

```
G_DATA_27A: Alternative.me F&G API historical 2018–2024 (60-day rolling) — CLEARED
G_DATA_27B: Santiment social_volume_total (90-day trial or $49/mo) — SOFT BARRIER
             Fallback: pytrends Google Trends BTC-USD weekly — CLEARED (free)

G1_27A: Frequency scan — F&G < 15 events per year (2019–2024, daily data)
         Target: ≥ 4 events/year (otherwise AP_A raises threshold)
         Script: analysis/g1-social-sentiment-fg-scan.py

G1_27B: WR conditional — next-14d BTC return > 0 given F&G < 15 activation (n ≥ 15)
         Target: WR ≥ 55% (Mode A-Long contrarian)

G1_27C: Frequency scan — F&G > 85 events per year
         Target: ≥ 3 events/year (greed extremes rarer in 2019–2024 sample)

G1_27D: Mode B social volume velocity co-occurrence (n ≥ 15 events with z > 2.5 + price diverge)
         Target: suppress WR ≥ 52% on next-7d return

INDEP_27: Empirical ρ scan — axis 27 vs axes 7, 11, 18, 21
           Target: all ρ < 0.60 (Tier C or below); AP_D fires if ρ(27, 7) ≥ 0.60

G2_27:   IS backtest CPCV+DSR
         Grid: 3 F&G thresholds (10/15/20) × 3 hold periods (7/14/21d) × 4 time splits = 36 cells
         DSR gate: Bailey-Borwein-Lopez de Prado (SSRN 2326253) mandatory if threshold grid-searched
         Targets: Mode A-Long DSR ≥ 0.50; Mode A-Short DSR ≥ 0.45; Mode B DSR ≥ 0.40
```

**Current gate status:** G_DATA_27A CLEARED. All others UNCLEARED (empirical).
**First barrier:** G1_27A (F&G frequency scan — cheap, uses already-cleared free API data).

---

## N_eff co-occurrence rules (preliminary — empirical confirmation pending)

| Pair | Expected ρ | Tier | Combined rule |
|------|-----------|------|--------------|
| 27 + 7 (funding) | ~0.35 | C | N_eff(2, 0.35) = 1.76; combined cap 1.18×/floor 0.84× |
| 27 + 11 (OI div) | ~0.40 | B/C | If both amplify: 0.78× combined floor (conservative) |
| 27 + 18 (on-chain) | ~0.20 | D | Combine freely; max three-axis cap 1.22× |
| 27 + 21 (ETF flow) | ~0.25 | D | Combine freely |
| 27 + 25 (cascade) | ~0.15 | D | Independent timescales; combine freely |

All ρ values are analytical estimates. Empirical INDEP_27 scan required before live three-axis
compounding.

---

## Best pairs and timeframe

- **Primary:** BTC/USDT:USDT (highest F&G relevance; F&G is explicitly BTC-weighted)
- **Secondary:** ETH/USDT:USDT at 0.75× scalar discount (F&G is BTC-specific; ETH sentiment
  may diverge during altseason or protocol upgrade windows)
- **Timeframe:** 1h strategy entries; F&G refreshes daily → bot_loop_start() with 24h
  cooldown; Mode A/B state carried into all 4h candles until next daily update
- **Kelly α floor:** 0.06 (no analytical pre-confirmation; G_DATA_27A cleared but G1 uncleared)
  → 0.09 after G1_27A/B confirmed → 0.12 cap after G2 DSR ≥ 0.50

---

## Bank state after cycle 168

| Tier | Freqtrade | Polymarket | Combined |
|------|-----------|------------|---------|
| Naive | 23 | 0 | 23 |
| Intermediate | **28** (+1: social-sentiment-narrative-momentum axis 27) | 1 | **29** |
| Sophisticated | 31 | 0 | 31 |

**27 freqtrade regime axes now defined.**

---

## Next cycle recommendations

**(A) IMPLEMENT — G1_27A frequency scan:**
Use already-cleared Alternative.me API. Pull full historical daily F&G 2019–2024.
Count F&G < 15 episodes (7d-separated), F&G > 85 episodes (7d-separated).
Check AP_A: < 3 events/year → raise threshold to 20/80 and rescan.
Script: `analysis/g1-social-sentiment-fg-scan.py`. Estimated 2h implementation.

**(B) RESEARCH — G1_27B conditional WR:**
For each F&G < 15 activation (from G1_27A), measure BTC return over next 7/14/21d.
Binomial test p < 0.10 with WR ≥ 55% at n ≥ 15 → G1_27B cleared.
This and G1_27A together would analytically pre-confirm Mode A for G2_27.

**(C) RESEARCH — BTC-specific post-2018 F&G backtesting literature:**
Search arxiv 2023–2026 for "Fear and Greed Index Bitcoin trading strategy" or
"sentiment indicator cryptocurrency contrarian." A single paper with WR data at F&G thresholds
could provide an A1-tier anchor for the sophisticated gate and calibrate the 15/85 vs 20/80
threshold debate empirically.

**(D) DECIDE — Polymarket intermediate elevation:**
Three polymarket prims remain at intermediate: `anchor-event-recency-bias-fade`,
`no-event-time-decay-fade`, `superforecaster-consensus-lead`. The no-event-time-decay-fade prim
has the most structurally complete intermediate definition and its remaining blockers (Mode A/B
empirical WR at n = 30 per bucket) are achievable with a data pull. Recommend as next polymarket
RESEARCH target if cycle 169 reverts to polymarket project.
