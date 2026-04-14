---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T17:30:00+10:00
cycle: 174
prim: intraday-session-asymmetry-regime
project: freqtrade
level: intermediate
axis: 28th regime axis
signal-class: temporal / session (meta-signal — no standalone entries)
supersedes: naive (cycle 172)
---

# Intraday Session Asymmetry Regime (Intermediate)

**Elevated naive → intermediate (cycle 174). 28th freqtrade regime axis.**

## What changed at intermediate

Five advances over naive (cycle 172):

1. **DST-aware UTC boundaries** — naive prim used hardcoded UTC integer cutoffs, misclassifying
   session membership for ~180 days/year when US/EU clocks shift ±1h during daylight saving
   transitions. Intermediate uses `zoneinfo.ZoneInfo` for precise local-time calculation.

2. **London-NY overlap as distinct sub-session** — the 4-hour window where both London AND NY
   institutional desks are simultaneously active (UTC 12–17 in US summer / 13–17 in US winter)
   produces the highest liquidity density and most efficient price discovery of any session window.
   Elevated to 1.10× (above naive's uniform NY scalar of 1.08×).

3. **ADX trend-regime routing** — in strong trending regimes (ADX > 25), momentum prims are
   already directionally committed. The session composition effect on their reliability is reduced.
   Class B (momentum) prims receive ADX-scaled session weight; Class A (MR/contrarian) prims
   receive full scalar in all regimes.

4. **Day-of-week modulation** — Monday's institutional premium (+0.04% per Caporale & Plastun 2019)
   and Friday's profit-taking reduction captured as a ±2.5% multiplier on the session deviation
   magnitude. Null days (Tuesday–Thursday) unchanged.

5. **Pair-class discount** — BTC has the strongest institutional session identity. ETH retains
   session structure but weaker (DeFi-native flows, protocol upgrade dynamics). Other pairs
   closer to 24/7 retail. Pair discount scales scalar magnitude from 1.00× (BTC) → 0.75×
   (other).

---

## Session taxonomy (DST-aware)

DST affects session UTC boundaries twice per year:

| Period | US DST | EU DST | NY UTC open | NY UTC close | London UTC open | London UTC close |
|--------|--------|--------|-------------|--------------|-----------------|------------------|
| Winter | off    | off    | 13:00       | 21:00 (22:00)| 08:00           | 16:00 (17:00)    |
| Spring | on     | on     | 12:00       | 20:00 (21:00)| 07:00           | 15:00 (16:00)    |
| Oct gap| off    | on     | 13:00       | 21:00        | 07:00           | 15:00            |
| March gap| on   | off    | 12:00       | 20:00        | 08:00           | 16:00            |

*Canonical institutional hours: 08:00–17:00 local time for both NY and London.*

```python
from zoneinfo import ZoneInfo
from datetime import datetime
from typing import Literal

SessionLabel = Literal["OVERLAP", "NY", "LONDON", "ASIAN", "DEAD", "WEEKEND"]

def classify_session(utc_dt: datetime) -> SessionLabel:
    """
    Classify a UTC datetime into one of 6 session labels.
    Uses zoneinfo for correct DST handling — never hardcode UTC integers.
    """
    if utc_dt.weekday() >= 5:          # Saturday=5, Sunday=6
        return "WEEKEND"

    ny_tz  = ZoneInfo("America/New_York")
    lon_tz = ZoneInfo("Europe/London")

    ny_h  = utc_dt.astimezone(ny_tz).hour
    lon_h = utc_dt.astimezone(lon_tz).hour

    ny_active  = 8 <= ny_h  < 17       # NY:     08:00–17:00 local
    lon_active = 8 <= lon_h < 17       # London: 08:00–17:00 local

    if ny_active and lon_active:
        return "OVERLAP"               # double institutional flow
    if ny_active:
        return "NY"
    if lon_active:
        return "LONDON"
    if 0 <= utc_dt.hour < 8:
        return "ASIAN"                 # ~UTC 00:00–08:00 (DST effect minimal on Asian hours)
    return "DEAD"                      # post-NY pre-Asian
```

**Session frequency (approximate, weekdays only):**
- OVERLAP: ~4h/day → ~20h/week (London-NY overlap window varies ±1h by DST)
- NY (exclusive): ~4–5h/day → ~20–25h/week
- LONDON (exclusive): ~4–5h/day → ~20–25h/week
- ASIAN: ~8h/day → ~40h/week
- DEAD: ~3–4h/day → ~15–20h/week

---

## Scalar computation

```
session_deviation:
  OVERLAP:  +0.10  (intermediate advance: distinct from NY standard)
  NY:       +0.08  (retained from naive)
  LONDON:    0.00  (retained from naive; neutral)
  ASIAN:    −0.08  (retained from naive)
  DEAD:     −0.08  (retained from naive)
  WEEKEND:   0.00  (retained from naive)

prim_class_weight (new at intermediate):
  Class A (MR / contrarian prims):
    RSI oversold, VWAP deviation, FVG discovery, capitulation-exhaustion,
    liquidity-sweep-reversal, bollinger-squeeze, hidden RSI divergence → 1.00

  Class B (momentum / trend-following prims):
    EMA-pullback, trend continuation, funded momentum → ADX-scaled:
      ADX_4h < 25:  weight = 0.85
      ADX_4h 25–35: weight = 0.50
      ADX_4h > 35:  weight = 0.25

dow_multiplier (applied to session_deviation):
  Monday:  1.025   (Caporale & Plastun 2019: +0.04% Monday premium)
  Friday:  0.975   (profit-taking reduction; weekend liquidity avoidance)
  Tue–Thu: 1.000   (no DOW evidence)
  Weekend: 1.000   (session_deviation already 0.00 for weekends)

pair_discount:
  BTC/USDT:USDT perpetual:  1.00
  ETH/USDT:USDT perpetual:  0.90
  Other perpetuals:          0.75

scalar_A  = max(0.88, min(1.12, 1.0 + session_deviation × 1.00 × dow_mult × pair_disc))
scalar_B  = max(0.92, min(1.10, 1.0 + session_deviation × class_B_weight × dow_mult × pair_disc))
```

**Hard caps:** Class A: 1.12× amplify / 0.88× suppress. Class B: 1.10× / 0.92×.
(Class B range narrowed because momentum prims already carry their own ADX filtering.)

---

## Worked examples

```
OVERLAP, Wednesday, MR prim (Class A), BTC:
  1.0 + (0.10 × 1.00 × 1.00 × 1.00) = 1.100×  ✓

OVERLAP, Monday, MR prim (Class A), BTC:
  1.0 + (0.10 × 1.00 × 1.025 × 1.00) = 1.1025 → capped at 1.12×  ✓

OVERLAP, Wednesday, momentum (Class B, ADX < 25), BTC:
  1.0 + (0.10 × 0.85 × 1.00 × 1.00) = 1.085×  ✓

OVERLAP, Wednesday, momentum (Class B, ADX > 35), BTC:
  1.0 + (0.10 × 0.25 × 1.00 × 1.00) = 1.025×  (nearly neutral for strong trends)  ✓

NY, Monday, MR prim, BTC:
  1.0 + (0.08 × 1.00 × 1.025 × 1.00) = 1.082×  ✓

ASIAN, Thursday, MR prim, ETH:
  1.0 + (−0.08 × 1.00 × 1.000 × 0.90) = 1.0 − 0.072 = 0.928×  ✓

ASIAN, Friday, MR prim, BTC:
  1.0 + (−0.08 × 1.00 × 0.975 × 1.00) = 0.922×  ✓

ASIAN, Friday, momentum (ADX > 35), BTC:
  1.0 + (−0.08 × 0.25 × 0.975 × 1.00) = 0.981×  (near-neutral: strong trend immunity)  ✓

DEAD, Friday, MR prim, BTC:
  1.0 + (−0.08 × 1.00 × 0.975 × 1.00) = 0.922×  ✓
```

---

## Implementation

```python
from dataclasses import dataclass, field
from typing import Optional, Literal
from zoneinfo import ZoneInfo
from datetime import datetime

SessionLabel = Literal["OVERLAP", "NY", "LONDON", "ASIAN", "DEAD", "WEEKEND"]
PrimClass    = Literal["MR", "MOMENTUM"]

SESSION_DEVIATION: dict[SessionLabel, float] = {
    "OVERLAP":  0.10,
    "NY":       0.08,
    "LONDON":   0.00,
    "ASIAN":   -0.08,
    "DEAD":    -0.08,
    "WEEKEND":  0.00,
}

DOW_MULT: dict[int, float] = {0: 1.025, 4: 0.975}  # 0=Mon, 4=Fri; else 1.00

# ADX thresholds ascending; last threshold catches all remaining
CLASS_B_ADX_WEIGHTS = [(25, 0.85), (35, 0.50), (float("inf"), 0.25)]

PAIR_DISCOUNT: dict[str, float] = {}  # populated at runtime; default 0.75

def _pair_discount(pair: str) -> float:
    if "BTC" in pair:  return 1.00
    if "ETH" in pair:  return 0.90
    return 0.75


@dataclass
class SessionState28:
    session_label:      SessionLabel = "DEAD"
    session_scalar_mr:  float = 1.00    # broadcast as session_scalar_28_mr
    session_scalar_mom: float = 1.00    # broadcast as session_scalar_28_mom
    adx_4h:             Optional[float] = None
    pair:               str = "BTC/USDT:USDT"
    last_utc_dt:        Optional[datetime] = None


class YujiSessionAsymmetry28:
    """
    Axis 28 — Intraday Session Asymmetry Regime (Intermediate).
    Meta-signal modifier — no standalone entries.
    Call get_scalar(prim_class) from sister strategies' confirm_trade_entry().
    Call update() from bot_loop_start() on every new bar open.
    """
    _state: SessionState28 = SessionState28()

    @classmethod
    def update(cls, utc_dt: datetime, adx_4h: float,
               pair: str = "BTC/USDT:USDT") -> None:
        """
        Recompute session scalars. Call on every 1h bar open.
        adx_4h: current ADX(14) on 4h timeframe.
        pair: e.g. 'BTC/USDT:USDT', 'ETH/USDT:USDT'.
        """
        cls._state.adx_4h = adx_4h
        cls._state.pair = pair
        cls._state.last_utc_dt = utc_dt

        label = cls._classify_session(utc_dt)
        cls._state.session_label = label

        dev       = SESSION_DEVIATION[label]
        dow_mult  = DOW_MULT.get(utc_dt.weekday(), 1.00)
        pair_disc = _pair_discount(pair)

        # Class A (MR) — full scalar
        raw_mr = 1.0 + dev * 1.00 * dow_mult * pair_disc
        cls._state.session_scalar_mr = max(0.88, min(1.12, raw_mr))

        # Class B (momentum) — ADX-scaled
        b_weight = next(
            w for (threshold, w) in CLASS_B_ADX_WEIGHTS
            if adx_4h < threshold
        )
        raw_mom = 1.0 + dev * b_weight * dow_mult * pair_disc
        cls._state.session_scalar_mom = max(0.92, min(1.10, raw_mom))

    @classmethod
    def _classify_session(cls, utc_dt: datetime) -> SessionLabel:
        if utc_dt.weekday() >= 5:
            return "WEEKEND"
        ny_tz  = ZoneInfo("America/New_York")
        lon_tz = ZoneInfo("Europe/London")
        ny_h   = utc_dt.astimezone(ny_tz).hour
        lon_h  = utc_dt.astimezone(lon_tz).hour
        ny_active  = 8 <= ny_h  < 17
        lon_active = 8 <= lon_h < 17
        if ny_active and lon_active:
            return "OVERLAP"
        if ny_active:
            return "NY"
        if lon_active:
            return "LONDON"
        if 0 <= utc_dt.hour < 8:
            return "ASIAN"
        return "DEAD"

    @classmethod
    def get_scalar(cls, prim_class: PrimClass = "MR") -> float:
        """Return session modifier for the current bar. Thread-safe read."""
        if prim_class == "MR":
            return cls._state.session_scalar_mr
        return cls._state.session_scalar_mom

    @classmethod
    def current_label(cls) -> SessionLabel:
        return cls._state.session_label
```

**Integration pattern:**
```python
# In bot_loop_start() of any sister strategy:
from .YujiSessionAsymmetry28 import YujiSessionAsymmetry28

def bot_loop_start(self, current_time, active_pairs, refresh_reason):
    utc_now  = datetime.utcnow().replace(tzinfo=ZoneInfo("UTC"))
    adx_4h   = self._get_adx_4h()  # from last 4h candle close
    YujiSessionAsymmetry28.update(utc_now, adx_4h, pair=self.config["stake_currency"])

# In confirm_trade_entry():
def confirm_trade_entry(self, pair, order_type, amount, rate, ...):
    prim_class = "MR" if self._is_mr_signal(pair) else "MOMENTUM"
    scalar = YujiSessionAsymmetry28.get_scalar(prim_class)
    adjusted_stake = amount * scalar
    ...
```

---

## Academic anchors (7 at intermediate)

| # | Source | Contribution |
|---|--------|-------------|
| A1 | **Eross, Farooq & Treepongkaruna (2019, Finance Research Letters)** — "Intraday effects in cryptocurrency markets" | BTC exhibits significant intraday seasonality; positive hourly drift concentrated 08:00–21:00 UTC; Asian session (00:00–08:00 UTC) returns ≈ 0 or negative. Direct empirical anchor for ASIAN −0.08× and NY/OVERLAP AMPLIFY scalars. |
| A2 | **Caporale & Plastun (2019, Finance Research Letters)** — "The day of the week effect in the cryptocurrency market" | Tests BTC daily returns 2013–2018 using OLS and ANOVA. Finds statistically significant day-of-week effects (p<0.05); Monday premium +0.04% confirmed; Friday marginal negative bias. Direct anchor for dow_mult = {Monday: 1.025, Friday: 0.975}. |
| A3 | **Liu & Tsyvinski (2021, Review of Financial Studies)** — "Risks and Returns of Cryptocurrency" | Investor attention is strongly session-correlated: 26% annualized alpha from crypto momentum is driven by attention peaks during US market hours. Validates NY/OVERLAP scalar for momentum (Class B) prims in non-trending regimes. |
| A4 | **Admati & Pfleiderer (1988, Review of Financial Studies)** — "A Theory of Intraday Patterns: Volume and Price Variability" | Foundational theory: informed traders endogenously cluster into high-liquidity windows; price discovery is temporally concentrated. OVERLAP window mechanism: both London AND NY institutional desks simultaneously active → endogenous double-clustering → highest information content per candle. Direct mechanism for OVERLAP 1.10× exceeding NY 1.08×. |
| A5 | **Brauneis, Mestel, Riordan & Theissen (2022, Finance Research Letters)** — "How to measure the liquidity of cryptocurrency markets?" | Crypto market efficiency measurably degrades outside institutional session windows; noise-to-signal ratio is session-dependent. Mechanism for DEAD/ASIAN −0.08× scalars: elevated noise = reduced reliability for all signal types. |
| A6 | **Aharon & Qadan (2019, Finance Research Letters)** — "Bitcoin and the day-of-the-week effect" | Tests BTC daily returns 2013–2018 using GARCH-M. Finds statistically significant Monday premium and negative Friday drift (p<0.10 both directions). Independent confirmation of both directions of the DOW multiplier, separate from Caporale & Plastun (A2). |
| A7 | **Heston, Korajczyk & Sadka (2010, Journal of Finance)** — "Intraday Patterns in the Cross-Section of Stock Returns" | Institutional volume clustering at session opens creates intraday return patterns driven by institutional schedule. At the London-NY overlap, two independent institutional clusters operate simultaneously → double-peak volume pattern. Mechanism for OVERLAP sub-session distinction over NY standard. Equity market evidence; extrapolation to crypto justified by the institutional arbitrageur presence since the 2020–2024 TradFi-crypto convergence (ETF era). |

---

## Failure modes (5)

| FM | Condition | Resolution |
|----|-----------|------------|
| FM1 | **DST transition misclassification** | If `zoneinfo` library unavailable on host (missing `tzdata` system package), DST transitions cause ±1h session misclassification for ~180 days/year. Resolution: install `pip install tzdata` as deployment requirement. Fallback: hardcoded UTC integers with a known ±1h error band; log warning and apply 0.50× scalar weight during known DST transition windows (±3d of transition dates). |
| FM2 | **Strong trending regime vs Class B prim** | ADX > 35 → Class B weight = 0.25×; session scalar effectively neutralises. This is CORRECT behaviour — in a strong directional trend, session composition is secondary to trend momentum. Do not override. |
| FM3 | **Weekend shock events (regulatory news, exchange hack)** | Weekend scalars are neutral (1.00×). Sharp weekend moves can generate large signals in sister prims. Axis 28 does not suppress weekend signals — this is by design: there is no institutional session structure to reference. If a weekend breakout is real, sister prims should fire; axis 28 simply stays neutral. |
| FM4 | **ETH session divergence (DeFi protocol upgrades, altseason)** | ETH's 0.90× pair discount partially accounts for its different institutional profile. During major ETH protocol events (post-merge hard forks, EIP activations), ETH session dynamics may deviate further. Anti-prim AP_D provides escape: if G1_28A shows ρ(axis28_ETH, axis28_BTC) < 0.70, lower ETH discount to 0.75×. |
| FM5 | **DOW effect decay post-2020** | Caporale & Plastun (2019) used 2013–2018 data; Aharon & Qadan (2019) used 2013–2018 data. The Monday/Friday effect may have been arbitraged away by algorithmic market makers post-2020. G1_28B must confirm WR differential on 2020–2024 data. AP_C fires if differential < 0.5pp. |

---

## Anti-prim escape hatches (4)

| AP | Trigger | Action |
|----|---------|--------|
| A | **G1_28A fails:** NY session WR ≤ Asian session WR + 2pp (n ≥ 40 episodes each) | Core session asymmetry absent in IS data. Revert to uniform naive scalar ±0.04× (reduce magnitude by half) until G2 IS scan provides direct CPCV confirmation. |
| B | **Direction inversion:** NY session WR < 50% for MR prims (n ≥ 20 episodes) | Contrarian result — amplifying NY degrades MR prim performance. Invert scalars: try REDUCE for NY, AMPLIFY for ASIAN. Re-run G1_28A before live deployment. |
| C | **DOW null (G1_28B):** Monday vs Tue–Thu WR differential < 0.5pp on n ≥ 20 Mondays | DOW effect below detection threshold. Set all DOW multipliers to 1.00× (neutralise DOW module). Session module retained unchanged. |
| D | **ETH session divergence:** ρ(session_label_ETH, session_label_BTC) < 0.70 empirically | ETH session profile diverges structurally. Apply 0.75× pair discount to ETH (reduce from 0.90×); investigate pair-specific session calibration before G2. |

---

## Deployment gates

```
G_DATA_28:   UTC system clock with DST-aware zoneinfo — CLEARED (zero external dependency)
G_DATA_28B:  ADX_4h from freqtrade built-in OHLCV indicators — CLEARED
G_DATA_28C:  BTC/ETH hourly OHLCV with UTC timestamp (standard Binance /fapi klines) — CLEARED

G1_28A:  Session WR differential scan — NY (+ OVERLAP) vs ASIAN
         Method: label every 1h BTC/USDT:USDT bar 2020–2024 via classify_session()
                 compute next-4h log return; bin by session_label
                 Mann-Whitney U test (NY+OVERLAP group vs ASIAN group)
         Target: WR differential ≥ +2pp; p < 0.10 (one-tailed)
         AP routing: AP_A if Δ < 2pp; AP_B if direction inverted
         Script: analysis/g1-session-asymmetry-scan.py (to be created)
         Status: UNCLEARED (empirical; first barrier)

G1_28B:  DOW WR differential scan — Monday vs Tue–Thu baseline
         Method: bin G1_28A results by weekday
                 compare Monday WR vs Tue–Thu WR
         Target: Monday premium ≥ +0.5pp; p < 0.15 (weak threshold; known small DOW signal)
         AP routing: AP_C if < 0.5pp differential
         Status: UNCLEARED (empirical; runs on same G1_28A dataset, no new data needed)

G1_28C:  OVERLAP window confirmation
         Method: from G1_28A data, isolate OVERLAP-classified bars
                 compare OVERLAP WR vs NY-standard WR vs ASIAN WR
         Target: OVERLAP WR ≥ NY WR (OVERLAP scalar 1.10× justified over NY 1.08×)
                 OVERLAP frequency ≥ 20 episodes/year (sufficient for Mann-Whitney)
         Status: UNCLEARED (empirical; same dataset as G1_28A)

INDEP_28: ρ(session_label_scalar, all other axes) empirical scan
          Target: all ρ < 0.30 (temporal axis expected near-zero correlation with
                  funding rates, on-chain metrics, ETF flows, social sentiment)
          Expected: ρ ≈ 0.00–0.10 (time-of-day is causally orthogonal to structural state)
          Status: ANALYTICAL (empirical confirmation pending; no blocking)

G2_28:   IS backtest CPCV+DSR
         Grid: 4 session scalars × 3 DOW multiplier variants × 2 prim-class splits = 24 cells
         DSR: Bailey-Borwein-Lopez de Prado (SSRN 2326253) — mandatory if scalars grid-searched
         Targets: IS Sharpe ≥ 0.70 per class; DSR ≥ 0.50 deflated; session WR Δ ≥ +2pp
         Status: BLOCKING (requires G1_28A/B/C first)
```

**Gate status summary (updated cycle 175 — G1 empirical results):**
```
G_DATA_28 / G_DATA_28B / G_DATA_28C  ← ALL CLEARED (zero external data dependency)
G1_28A (session WR differential)     ← FAIL  Δ=+0.50pp (need ≥+2pp), p=0.21 (need <0.10)
G1_28B (DOW WR differential)         ← PASS  Monday Δ=+1.06pp vs Tue–Thu, p=0.0075
G1_28C (OVERLAP vs NY confirmation)  ← FAIL  OVERLAP WR=49.84% < NY WR=53.19% (Δ=−3.35pp)
INDEP_28                              ← analytical (not blocking)
G2_28 (IS CPCV+DSR)                  ← BLOCKED (requires G1 clearance; G1_28A/C failing)
```

**AP_A ACTIVE** — G1_28A failed (Δ < 2pp). Per anti-prim routing, revert session_deviation
magnitudes to ±0.04× (naive magnitude, halved from intermediate) until G2 CPCV provides
direct confirmation. DOW multipliers retained (G1_28B PASS).

**Empirical session WR order (BTC/USDT 1h, 2022-01-01 → 2026-04-09, n=37,428 bars):**
```
NY:       53.19%  n=5,480   ← STRONGEST (contradicts OVERLAP > NY assumption)
ASIAN:    51.40%  n=8,293
WEEKEND:  50.80%  n=10,704
OVERLAP:  49.84%  n=3,423   ← WEAKER than ASIAN (contradicts Admati-Pfleiderer mechanism)
DEAD:     49.91%  n=2,929
LONDON:   48.28%  n=6,595   ← WEAKEST
```

**Key contradiction:** The intermediate prim assigned OVERLAP=+0.10× > NY=+0.08× based on
the double-institutional-clustering mechanism (Admati-Pfleiderer 1988; Heston et al. 2010).
Empirically, OVERLAP underperforms ASIAN by −1.56pp and NY by −3.35pp on next-4h WR.
Possible explanations for analyst:
1. London-close sell-pressure during OVERLAP window dominates the NY-open buying
2. The double-institutional-clustering theory applies to equity markets (Heston 2010 data) but
   crypto OVERLAP is dominated by cross-desk hedging and ETF rebalancing → net-negative for
   directional positioning
3. Data period (2022-2026) is post-Luna, post-FTX — institutional participation profile may
   differ from the 2013–2020 era studied in the academic anchors

**Revised AP_A scalar (active until G2):**
```python
SESSION_DEVIATION_AP_A = {   # ±0.04× magnitude (half of intermediate)
    "OVERLAP":  +0.04,   # reduced from +0.10 (G1_28C fail: empirically underperforms NY)
    "NY":       +0.04,   # confirmed dominant session; retains positive sign
    "LONDON":    0.00,   # unchanged
    "ASIAN":    -0.04,   # reduced from -0.08 (G1_28A fail: differential too small)
    "DEAD":     -0.04,   # reduced from -0.08
    "WEEKEND":   0.00,   # unchanged
}
```

**Script:** `analysis/g1-session-asymmetry-scan.py` (created cycle 175)

---

## N_eff independence (preliminary)

Axis 28 is a temporal meta-signal. All other axes are structural (price, derivatives, on-chain,
order flow, sentiment). Time-of-day has no causal overlap with funding rates, MVRV, ETF flows,
or F&G composites. Expected ρ(axis28, all others) ≈ 0.00–0.05.

| Pair | Expected ρ | Tier | Combined rule |
|------|-----------|------|--------------|
| 28 + axis 27 (social sentiment) | ~0.05 | D | Combine freely; F&G state is daily; session is hourly |
| 28 + axis 7 (funding rate) | ~0.02 | D | Combine freely; funding is 8h cumulative; session is instantaneous |
| 28 + axis 26 (CVD) | ~0.10 | D | Combine freely; CVD is execution-state; session is temporal context |
| 28 + any other axis | ~0.00–0.10 | D | Combine freely; no N_eff penalty anticipated |

**Maximum combined scalar (three-axis compounding, all D-tier):**
Axis 28 + axis 27 + axis 7 simultaneously:
- N_eff(3, ρ̄≈0.05) ≈ 2.90; combined cap 1.22× / floor 0.82×
- Apply conservative hard cap regardless: 1.20× amplify / 0.82× suppress

**Independence hypothesis H_INDEP_28:** Session temporal state adds orthogonal information because
it captures instantaneous liquidity-supply composition (who is at the desk), not market price or
structural state. Falsification condition: INDEP_28 empirical scan finds ρ ≥ 0.30 with any axis
→ investigate whether that axis has a structural-temporal coupling before compounding.

---

## Best pairs and timeframe

- **Primary:** BTC/USDT:USDT perpetual (1.00× pair discount; strongest institutional session identity)
- **Secondary:** ETH/USDT:USDT perpetual (0.90× pair discount; weaker session identity due to
  DeFi-native flows and protocol-upgrade-driven irregular institutional participation)
- **Other perpetuals:** 0.75× pair discount (retail-dominated; session structure weaker)
- **Timeframe:** Classification updated on every 1h bar open via `bot_loop_start()`; session
  membership is stable within a 1h window; 4h strategy entries use the classification of the
  4h candle's open hour
- **Kelly α:** 0.00 (meta-signal; no standalone entries) → N/A for this axis directly; sister
  prim Kelly α is scaled by the session modifier

---

## What remains for sophisticated elevation

1. **G1 empirical confirmation** (G1_28A session WR differential) — the primary blocker; runs
   on standard OHLCV with no API key; create `analysis/g1-session-asymmetry-scan.py`

2. **Pair-specific IS calibration** — ETH session profile may require a fully independent
   calibration rather than a fixed 0.90× scalar; sophisticated tier tests ETH independently

3. **Sub-session granularity** — OVERLAP window (4h block) may contain micro-structure within
   it: the London-close / NY-peak transition (~UTC 15–17) may have different dynamics than
   London-open / NY-pre-market (~UTC 12–14); sophisticated tier may split OVERLAP into
   OVERLAP_OPEN and OVERLAP_CLOSE

4. **Per-signal-type IS calibration** — Class A vs Class B split is analytically motivated here;
   sophisticated tier requires independent IS WR measurements for each class separately
   (some MR signals may be MORE session-sensitive than others within Class A)

5. **Seasonal macro-regime stability** — DOW and session effects may differ in bull vs bear vs
   sideways crypto macro regimes; Caporale & Plastun (2019) aggregated across all regimes;
   sophisticated tier requires sub-regime stability test

---

## Bank state after cycle 174

| Tier | Freqtrade | Note |
|------|-----------|------|
| Naive | **23** (−1) | axis 28 elevated to intermediate |
| Intermediate | **31** (+1) | axis 28 added |
| Sophisticated | 32 | unchanged |

**28 freqtrade regime axes defined.**
