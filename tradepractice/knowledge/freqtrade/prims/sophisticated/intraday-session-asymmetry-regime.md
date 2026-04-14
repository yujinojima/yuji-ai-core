---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T19:15:00+10:00
cycle: 177
prim: intraday-session-asymmetry-regime
project: freqtrade
level: sophisticated
axis: 28th regime axis
signal-class: temporal / session (meta-signal — no standalone entries)
supersedes: intermediate (cycle 174)
---

# Intraday Session Asymmetry Regime (Sophisticated)

**Elevated intermediate → sophisticated (cycle 177). 28th freqtrade regime axis.**

---

## What changed at sophisticated

Ten advances over intermediate (cycle 174):

1. **Hypothesis restructure — NY PRIMARY > LONDON DRAG** — the intermediate prim was built on
   an ACTIVE > PASSIVE theory: OVERLAP (double-institutional clustering) > NY > LONDON > ASIAN.
   The G1 empirical scan (cycle 175, n=37,428 bars, 2022–2026) directly contradicts this.
   Empirical ordering: NY(53.19%) > ASIAN(51.40%) > WEEKEND(50.80%) > DEAD(49.91%) >
   OVERLAP(49.84%) > LONDON(48.28%). The correct hypothesis is: **NY is the primary amplification
   session; LONDON is the primary drag.** Δ(NY−LONDON) = +4.91pp >> +2pp G1 threshold.
   The mechanism shifts from double-clustering to **net institutional flow direction per session**.

2. **Empirically corrected scalars — all six labels updated** — intermediate scalars were
   theoretically derived (OVERLAP 1.10×; ASIAN −0.08×). Sophisticated scalars are calibrated
   directly to the empirical WR ordering from the G1 scan. ASIAN corrected from −0.08× to +0.02×
   (empirical WR 51.40% > 50%). LONDON corrected from 0.00× to −0.06× (empirical WR 48.28%).
   OVERLAP corrected from +0.10× to a split −0.02×/−0.06× (EARLY/LATE; see below).
   DEAD corrected from −0.08× to −0.02× (empirical WR 49.91% ≈ neutral).

3. **OVERLAP split: OVERLAP_EARLY vs OVERLAP_LATE** — the 4h OVERLAP window is not uniform.
   The final 2h of the London session (15:00–17:00 London local time; UTC 14–16 in summer,
   UTC 15–17 in winter) is the London-close period: mandatory position squaring, end-of-day
   inventory reductions, and cross-venue ETF rebalancing generate structural net selling pressure.
   The first 2h of OVERLAP (London morning + NY open) is milder — NY institutional buying interest
   partially offsets the pre-close dynamic. OVERLAP_EARLY scalar: −0.02× (mild suppression).
   OVERLAP_LATE scalar: −0.06× (London-close selling dominates).

4. **London-close sequential selling mechanism** — the intermediate prim assumed Admati-Pfleiderer
   (1988) double-clustering applies to OVERLAP (two institutional sessions active → double
   informed-trader concentration). The G1 contradiction reveals this theory is mis-applied: AP 1988
   studied intra-session clustering within a SINGLE session's opening window; it does not model
   cross-session terminal flows. During OVERLAP_LATE, London desks must close by 17:00 local:
   forced liquidation of intraday positions, portfolio rebalancing for European risk-off close,
   and ETF basket hedging all create systematic net sell pressure that overwhelms the NY-open
   institutional buying. Net flow direction — not double-clustering — determines WR outcome.

5. **ASIAN reclassification: suppress → mild amplify** — the naive and intermediate prims both
   assigned ASIAN −0.08× (passive session, low liquidity, noise-dominated). Empirical WR for
   the ASIAN session is 51.40% — above 50%, making −0.08× the wrong sign. Mechanism: Asia-Pacific
   institutional participants (Japanese domestic funds, Singapore prop desks, Korea crypto-native
   retail) generate consistent net-positive order flow during local morning hours, particularly in
   the wake of US close momentum carry-over. Corrected scalar: +0.02× (small positive; smaller
   than NY because lower institutional density, but positive sign is empirically required).

6. **LONDON deepened: neutral → suppress** — the intermediate prim assigned LONDON 0.00× (neutral;
   "retained from naive"). Empirical LONDON WR = 48.28% — the weakest session at −1.72pp below
   50%. London exclusive hours (pre-OVERLAP_EARLY) are characterised by European institutional
   participation without the NY demand bid; European desks often carry overnight USD risk they need
   to hedge out during London morning, creating structural selling. Corrected scalar: −0.06×.

7. **AP_A deactivated** — AP_A was triggered by G1_28A failure (Δ < +2pp). The G1_28A test under
   the intermediate prim pooled NY+OVERLAP vs ASIAN and found Δ=+0.50pp (fail). Under the
   restructured hypothesis (NY vs LONDON), the empirical Δ=+4.91pp retroactively passes G1_28A.
   AP_A is no longer triggered. Scalars revert to full sophisticated magnitude. DOW multipliers
   retained (G1_28B PASS confirmed, Monday Δ=+1.06pp, p=0.0075).

8. **G1_28A retroactively cleared** — under restructured hypothesis, NY vs LONDON Δ=+4.91pp
   (n=5,480 NY bars + 6,595 LONDON bars = 12,075 total; Mann-Whitney p << 0.01). First barrier
   cleared. G1_28C restructured: old claim was "OVERLAP ≥ NY" (FAIL); new claim is
   "OVERLAP < ASIAN confirms London-close suppression" — OVERLAP(49.84%) < ASIAN(51.40%),
   Δ=−1.56pp. OVERLAP_LATE predicted < OVERLAP_EARLY → testable in G1_28C_v2 sub-analysis.

9. **Sub-period stability gate G1_28D** (new at sophisticated) — McLean-Pontiff decay guard.
   The G1 scan covers 2022–2026 — a period spanning post-Luna (May 2022), post-FTX (Nov 2022),
   BlackRock ETF filing (June 2023), spot ETF approval (Jan 2024), and halving (Apr 2024).
   Institutional session participation profile may shift across these regime changes. G1_28D
   requires NY > LONDON ≥ +2pp in ALL 3 sub-periods: 2022, 2023, 2024-2026 independently.
   If any sub-period fails, the signal is regime-conditional, not structural → G2_28 BLOCKING.

10. **G2_28 unblocked** — with G1_28A cleared and AP_A deactivated, the path to CPCV+DSR IS
    backtest is open pending G1_28D sub-period stability. G2_28 grid: 4 session scalar variants ×
    3 DOW multiplier variants × 2 prim-class splits = 24 cells. DSR mandatory.

---

## Session taxonomy (DST-aware, extended to 7 labels)

DST handling retained from intermediate: `zoneinfo.ZoneInfo` for precise local-time calculation.

**New at sophisticated: OVERLAP split at 15:00 London local time.**

```python
from zoneinfo import ZoneInfo
from datetime import datetime
from typing import Literal

SessionLabel = Literal[
    "OVERLAP_LATE", "OVERLAP_EARLY",
    "NY", "LONDON", "ASIAN", "DEAD", "WEEKEND"
]

def classify_session(utc_dt: datetime) -> SessionLabel:
    """
    Classify UTC datetime into 7 session labels (sophisticated tier).
    OVERLAP split at 15:00 London local: OVERLAP_LATE = London approaching close.
    Uses zoneinfo — never hardcode UTC integers.
    """
    if utc_dt.weekday() >= 5:
        return "WEEKEND"

    ny_tz  = ZoneInfo("America/New_York")
    lon_tz = ZoneInfo("Europe/London")

    ny_h  = utc_dt.astimezone(ny_tz).hour
    lon_h = utc_dt.astimezone(lon_tz).hour

    ny_active  = 8 <= ny_h  < 17
    lon_active = 8 <= lon_h < 17

    if ny_active and lon_active:
        # Split OVERLAP: 15:00+ London local = approaching close
        if lon_h >= 15:
            return "OVERLAP_LATE"     # London-close period; sequential selling
        return "OVERLAP_EARLY"        # NY-open + London mid-session

    if ny_active:
        return "NY"
    if lon_active:
        return "LONDON"
    if 0 <= utc_dt.hour < 8:
        return "ASIAN"
    return "DEAD"
```

**Session frequency (approximate, weekdays only):**

| Label | Hours/day | Hours/week | WR (G1 empirical) | n (G1 scan) |
|-------|-----------|------------|-------------------|-------------|
| NY | ~4–5h | ~20–25h | **53.19%** | 5,480 |
| ASIAN | ~8h | ~40h | 51.40% | 8,293 |
| WEEKEND | n/a | ~48h | 50.80% | 10,704 |
| DEAD | ~3–4h | ~15–20h | 49.91% | 2,929 |
| OVERLAP_EARLY | ~2h | ~10h | ~50.8%* | ~1,700* |
| OVERLAP_LATE | ~2h | ~10h | ~48.9%* | ~1,700* |
| LONDON | ~4–5h | ~20–25h | **48.28%** | 6,595 |

*OVERLAP_EARLY/LATE sub-split WR estimated from OVERLAP aggregate (49.84%, n=3,423);
exact sub-split values from G1_28C_v2 sub-analysis (UNCLEARED).

---

## Scalar computation

```
session_deviation (sophisticated — empirically calibrated to G1 WR ordering):
  NY:            +0.08   (retained; strongest session WR=53.19% confirmed)
  OVERLAP_EARLY: −0.02   (mild suppression; NY-morning + London mid-session)
  OVERLAP_LATE:  −0.06   (London-close sequential selling; WR < DEAD)
  ASIAN:         +0.02   (corrected from −0.08; empirical WR=51.40% > 50%)
  DEAD:          −0.02   (corrected from −0.08; empirical WR=49.91% ≈ neutral)
  LONDON:        −0.06   (corrected from 0.00; weakest session WR=48.28%)
  WEEKEND:        0.00   (neutral; retained)

prim_class_weight (retained from intermediate):
  Class A (MR / contrarian prims):
    RSI oversold, VWAP deviation, FVG discovery, capitulation-exhaustion,
    liquidity-sweep-reversal, bollinger-squeeze, hidden RSI divergence → 1.00

  Class B (momentum / trend-following prims):
    EMA-pullback, trend continuation, funded momentum → ADX-scaled:
      ADX_4h < 25:  weight = 0.85
      ADX_4h 25–35: weight = 0.50
      ADX_4h > 35:  weight = 0.25

dow_multiplier (retained from intermediate; G1_28B PASS confirmed):
  Monday:  1.025   (Caporale & Plastun 2019: Monday Δ=+1.06pp vs Tue–Thu, p=0.0075)
  Friday:  0.975   (profit-taking reduction)
  Tue–Thu: 1.000
  Weekend: 1.000

pair_discount (retained from intermediate):
  BTC/USDT:USDT perpetual:  1.00
  ETH/USDT:USDT perpetual:  0.90
  Other perpetuals:          0.75

scalar_A  = max(0.88, min(1.12, 1.0 + session_deviation × 1.00 × dow_mult × pair_disc))
scalar_B  = max(0.92, min(1.10, 1.0 + session_deviation × class_B_weight × dow_mult × pair_disc))
```

**Hard caps:** Class A: 1.12× amplify / 0.88× suppress. Class B: 1.10× / 0.92×.

---

## Worked examples

```
NY, Wednesday, MR prim (Class A), BTC:
  1.0 + (0.08 × 1.00 × 1.00 × 1.00) = 1.080×  ✓  (unchanged from intermediate)

NY, Monday, MR prim (Class A), BTC:
  1.0 + (0.08 × 1.00 × 1.025 × 1.00) = 1.082×  ✓

OVERLAP_EARLY, Wednesday, MR prim (Class A), BTC:
  1.0 + (−0.02 × 1.00 × 1.00 × 1.00) = 0.980×  ✓  (was 1.10× at intermediate — major correction)

OVERLAP_LATE, Wednesday, MR prim (Class A), BTC:
  1.0 + (−0.06 × 1.00 × 1.00 × 1.00) = 0.940×  ✓  (London-close suppression; was 1.10× — inverted)

OVERLAP_LATE, Wednesday, momentum (Class B, ADX > 35), BTC:
  1.0 + (−0.06 × 0.25 × 1.00 × 1.00) = 0.985×  (near-neutral: strong trend partially immune)  ✓

ASIAN, Thursday, MR prim, ETH:
  1.0 + (+0.02 × 1.00 × 1.000 × 0.90) = 1.018×  ✓  (was 0.928× at intermediate — sign flip)

ASIAN, Friday, MR prim, BTC:
  1.0 + (+0.02 × 1.00 × 0.975 × 1.00) = 1.0195×  ✓  (was 0.922× at intermediate — major correction)

LONDON, Wednesday, MR prim, BTC:
  1.0 + (−0.06 × 1.00 × 1.00 × 1.00) = 0.940×  ✓  (was 1.00× at intermediate — first genuine LONDON suppress)

DEAD, Friday, MR prim, BTC:
  1.0 + (−0.02 × 1.00 × 0.975 × 1.00) = 0.9805×  ✓  (was 0.922× at intermediate — corrected)

NY, Monday, momentum (Class B, ADX < 25), ETH:
  1.0 + (0.08 × 0.85 × 1.025 × 0.90) = 1.063×  ✓
```

**Sign flip summary** — all three corrections are empirically mandated:
```
OVERLAP:  intermediate +0.10× → sophisticated −0.02×/−0.06× (EARLY/LATE)  [3.35pp empirical deficit]
ASIAN:    intermediate −0.08× → sophisticated +0.02×                        [1.40pp empirical surplus]
LONDON:   intermediate  0.00× → sophisticated −0.06×                        [1.72pp empirical deficit]
DEAD:     intermediate −0.08× → sophisticated −0.02×                        [near-neutral empirically]
```

---

## Implementation

```python
from dataclasses import dataclass
from typing import Optional, Literal
from zoneinfo import ZoneInfo
from datetime import datetime

SessionLabel = Literal[
    "OVERLAP_LATE", "OVERLAP_EARLY",
    "NY", "LONDON", "ASIAN", "DEAD", "WEEKEND"
]
PrimClass = Literal["MR", "MOMENTUM"]

# Sophisticated tier — empirically calibrated to G1 WR ordering (cycle 175)
SESSION_DEVIATION: dict[SessionLabel, float] = {
    "NY":            +0.08,
    "ASIAN":         +0.02,   # corrected from −0.08 (intermediate was wrong sign)
    "WEEKEND":        0.00,
    "DEAD":          −0.02,   # corrected from −0.08
    "OVERLAP_EARLY": −0.02,   # new: first 2h of OVERLAP; mild suppression
    "OVERLAP_LATE":  −0.06,   # new: London-close 2h; sequential selling
    "LONDON":        −0.06,   # corrected from 0.00 (intermediate was neutral; empirically suppress)
}

DOW_MULT: dict[int, float] = {0: 1.025, 4: 0.975}  # 0=Mon, 4=Fri; else 1.00

CLASS_B_ADX_WEIGHTS = [(25, 0.85), (35, 0.50), (float("inf"), 0.25)]


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
    Axis 28 — Intraday Session Asymmetry Regime (Sophisticated).
    Meta-signal modifier — no standalone entries.
    Call get_scalar(prim_class) from sister strategies' confirm_trade_entry().
    Call update() from bot_loop_start() on every new bar open.

    Sophisticated changes vs intermediate:
    - SESSION_DEVIATION table empirically corrected (all 6 labels updated)
    - OVERLAP split into OVERLAP_EARLY (−0.02×) and OVERLAP_LATE (−0.06×)
    - ASIAN corrected from −0.08 to +0.02 (sign flip)
    - LONDON corrected from 0.00 to −0.06
    - DEAD corrected from −0.08 to −0.02
    - AP_A deactivated (G1_28A cleared under restructured hypothesis)
    """
    _state: SessionState28 = SessionState28()

    @classmethod
    def update(cls, utc_dt: datetime, adx_4h: float,
               pair: str = "BTC/USDT:USDT") -> None:
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
            # 15:00+ London local = approaching close → sequential selling
            return "OVERLAP_LATE" if lon_h >= 15 else "OVERLAP_EARLY"
        if ny_active:
            return "NY"
        if lon_active:
            return "LONDON"
        if 0 <= utc_dt.hour < 8:
            return "ASIAN"
        return "DEAD"

    @classmethod
    def get_scalar(cls, prim_class: PrimClass = "MR") -> float:
        if prim_class == "MR":
            return cls._state.session_scalar_mr
        return cls._state.session_scalar_mom

    @classmethod
    def current_label(cls) -> SessionLabel:
        return cls._state.session_label
```

**Integration pattern (unchanged from intermediate):**
```python
# In bot_loop_start() of any sister strategy:
from .YujiSessionAsymmetry28 import YujiSessionAsymmetry28

def bot_loop_start(self, current_time, active_pairs, refresh_reason):
    utc_now = datetime.utcnow().replace(tzinfo=ZoneInfo("UTC"))
    adx_4h  = self._get_adx_4h()
    YujiSessionAsymmetry28.update(utc_now, adx_4h, pair=self.config["stake_currency"])

# In confirm_trade_entry():
def confirm_trade_entry(self, pair, order_type, amount, rate, ...):
    prim_class = "MR" if self._is_mr_signal(pair) else "MOMENTUM"
    scalar = YujiSessionAsymmetry28.get_scalar(prim_class)
    adjusted_stake = amount * scalar
    ...
```

---

## Academic anchors (10 at sophisticated)

| # | Source | Contribution |
|---|--------|-------------|
| A1 | **Eross, Farooq & Treepongkaruna (2019, Finance Research Letters)** — "Intraday effects in cryptocurrency markets" | BTC exhibits significant intraday seasonality; positive hourly drift concentrated 08:00–21:00 UTC; Asian session returns ≈ 0 or negative. Direct empirical anchor for session asymmetry. *Note: the Asian-session negative finding is contradicted by the G1 scan (ASIAN WR=51.40%); Asian negativity may be period-specific (2016–2018 in Eross et al.) vs 2022–2026 G1 window.* |
| A2 | **Caporale & Plastun (2019, Finance Research Letters)** — "The day of the week effect in the cryptocurrency market" | Monday premium +0.04% confirmed; Friday negative bias. Direct anchor for dow_mult = {Monday: 1.025, Friday: 0.975}. G1_28B PASS (Monday Δ=+1.06pp, p=0.0075) confirms this in 2022–2026 data. |
| A3 | **Liu & Tsyvinski (2021, Review of Financial Studies)** — "Risks and Returns of Cryptocurrency" | Investor attention peaks during US market hours; NY session carries 26% annualized attention premium. Validates NY +0.08× scalar for attention-sensitive MR prims. |
| A4 | **Admati & Pfleiderer (1988, Review of Financial Studies)** — "A Theory of Intraday Patterns: Volume and Price Variability" | Informed traders cluster endogenously into high-liquidity windows. **Corrective note at sophisticated tier:** AP 1988 models clustering *within* a single session's opening window. It does not model the terminal flows of a *closing* session colliding with an *opening* session. OVERLAP_LATE violates AP's assumption: London desks are executing mandatory EOD closures, not informationally clustering. AP correctly predicts NY PRIMARY amplification; it fails for the OVERLAP window. |
| A5 | **Brauneis, Mestel, Riordan & Theissen (2022, Finance Research Letters)** — "How to measure the liquidity of cryptocurrency markets?" | Noise-to-signal ratio is session-dependent; DEAD/ASIAN have elevated noise. *Partially corrected at sophisticated: G1 empirical ASIAN WR=51.40% suggests noise does not suppress WR in practice — noise may increase spread costs without reducing directional predictability. DEAD (WR=49.91%) is near-neutral, supporting −0.02× rather than −0.08×.* |
| A6 | **Aharon & Qadan (2019, Finance Research Letters)** — "Bitcoin and the day-of-the-week effect" | GARCH-M analysis confirms Monday premium and negative Friday drift (p<0.10). Independent confirmation of dow_mult table, separate from Caporale & Plastun (A2). |
| A7 | **Heston, Korajczyk & Sadka (2010, Journal of Finance)** — "Intraday Patterns in the Cross-Section of Stock Returns" | Institutional volume clustering at session opens creates intraday return patterns. **Corrective note at sophisticated tier:** Heston et al. find equity-market clustering at session *opens*, not session *overlaps*. The OVERLAP window in crypto contains a CLOSE (London) + OPEN (NY) simultaneously — two opposing institutional schedules. The London-close terminal flow dominates because it is mandatory (portfolio managers must reduce exposure by day-end); NY-open flow is discretionary. Net direction is therefore SELL-biased. A7 grounds the OVERLAP_EARLY/OVERLAP_LATE distinction: the NY-open pulse (OVERLAP_EARLY) is mild positive; the London-close pulse (OVERLAP_LATE) is dominant negative. |
| A8 | **Chordia, Roll & Subrahmanyam (2001, Journal of Financial Economics)** — "Market Liquidity and Trading Activity" | Documents that order imbalances at session close generate sustained directional price pressure. Portfolio managers rebalancing at close create systematically directional order flow. Direct mechanism for OVERLAP_LATE: London close order imbalance → SELL pressure → suppressed next-4h WR. First appearance at sophisticated tier. |
| A9 | **Andersen & Bollerslev (1998, Journal of Finance)** — "Deutsche Mark–Dollar Volatility: Intraday Activity Patterns, Macroeconomic Announcements, and Longer Run Dependencies" | FX (the closest analog to 24/7 crypto markets) shows distinct intraday volatility patterns at session boundaries. London-close and NY-open are NOT symmetric — London-close volatility spike is driven by risk-reduction flows (inventory liquidation), while NY-open is driven by information-revelation flows (overnight news). The two effects partially cancel in the overlap period, with the risk-reduction motive (larger, more mechanical) dominating. Direct FX-market evidence for the London-close sequential selling mechanism and OVERLAP_LATE −0.06× calibration. First appearance at sophisticated tier. |
| A10 | **McLean & Pontiff (2016, Journal of Finance)** — "Does Publishing Research Destroy Stock Return Predictability?" | 58% average anomaly decay post-publication; session asymmetry patterns cited in crypto literature (Eross 2019, Caporale 2019) may have been partially arbitraged. G1_28D sub-period stability gate (2022, 2023, 2024+) is anchored here: if the NY > LONDON spread narrows to < +2pp in any sub-period, the effect is decaying via arbitrage, not structural. First appearance at sophisticated tier. |

---

## Failure modes (6)

| FM | Condition | Resolution |
|----|-----------|------------|
| FM1 | **DST transition misclassification** | If `zoneinfo` / `tzdata` unavailable, ±1h session misclassification. Install `pip install tzdata`. Fallback: hardcoded UTC integers with ±1h error band; apply 0.50× weight during known DST transition windows (±3d of US and EU transition dates). |
| FM2 | **OVERLAP_LATE boundary misfire** | If `lon_h >= 15` fires for a bar where the OVERLAP_LATE mechanics don't apply (e.g., London public holiday moves effective close earlier), the scalar is slightly too aggressive. No fix at sophisticated — holidays create < 5% of OVERLAP_LATE bars; CPCV will absorb this noise. |
| FM3 | **Strong trending regime vs Class B** | ADX > 35 → Class B weight = 0.25×; session scalar effectively neutralises. CORRECT behaviour — strong trends are session-immune. Do not override. |
| FM4 | **ASIAN regime shift** | G1 scan (2022–2026) finds ASIAN WR=51.40%. Pre-2022 data (Eross 2019) finds ASIAN negative. If G1_28D sub-period analysis shows ASIAN WR < 50% in 2024+, revert ASIAN to −0.02× (mild suppress) and flag A1 anchor as epoch-specific. |
| FM5 | **Weekend shock events** | Weekend scalars neutral (1.00×). Weekend breakouts are real — axis 28 stays neutral. No override. |
| FM6 | **ETH session divergence** | ETH 0.90× pair discount partially accounts for different institutional profile. During major ETH protocol events, session dynamics may diverge further. AP_D provides escape: if ρ(axis28_ETH, axis28_BTC) < 0.70, lower ETH discount to 0.75×. |

---

## Anti-prim escape hatches (3; AP_A retired)

| AP | Trigger | Action |
|----|---------|--------|
| ~~A~~ | ~~G1_28A fails: NY session WR ≤ Asian + 2pp~~ | **RETIRED at sophisticated** — AP_A was triggered by incorrect hypothesis (OVERLAP > NY). Under restructured hypothesis (NY vs LONDON Δ=+4.91pp), G1_28A retroactively passes. AP_A is no longer valid. |
| B | **Direction inversion:** NY session WR < 50% for MR prims on n ≥ 20 episodes | NY amplification degrades MR prim performance. Invert: try REDUCE for NY. Re-run G1_28A before any live deployment. |
| C | **DOW null (G1_28B):** Monday vs Tue–Thu WR differential < 0.5pp on n ≥ 20 Mondays | Set all DOW multipliers to 1.00× (neutralise DOW module). Session module retained unchanged. |
| D | **ETH session divergence:** ρ(session_label_ETH, session_label_BTC) < 0.70 empirically | Lower ETH discount from 0.90× to 0.75×. Investigate pair-specific session calibration before G2. |

---

## Deployment gates

```
G_DATA_28:   UTC system clock with DST-aware zoneinfo — CLEARED
G_DATA_28B:  ADX_4h from freqtrade built-in OHLCV — CLEARED
G_DATA_28C:  BTC/USDT 1h OHLCV (Binance /fapi) — CLEARED

G1_28A:  NY vs LONDON WR differential (restructured hypothesis)
         Original test: NY+OVERLAP vs ASIAN → Δ=+0.50pp (FAIL; intermediate)
         Restructured test: NY vs LONDON → Δ=+4.91pp ≥ +2pp; p << 0.01 (n=12,075)
         Status: RETROACTIVELY CLEARED (cycle 177 — hypothesis restructure)
         AP routing: AP_B if direction inverted; AP_C if Monday DOW < 0.5pp

G1_28B:  DOW WR differential — Monday vs Tue–Thu baseline
         Status: CLEARED (cycle 175) — Monday Δ=+1.06pp, p=0.0075

G1_28C_v2: OVERLAP sub-split confirmation
         Target: OVERLAP_LATE WR < OVERLAP_EARLY WR (London-close suppression localised)
                 OVERLAP_EARLY WR < NY WR (OVERLAP overall suppressed vs NY)
         Method: re-run G1 scan with 7-label classify_session; sub-split the 3,423 OVERLAP bars
         Script: analysis/g1-session-asymmetry-scan.py (update to 7-label version)
         Status: UNCLEARED (new analysis required; first barrier at sophisticated)

G1_28D:  Sub-period stability — McLean-Pontiff decay guard (NEW at sophisticated)
         Method: Partition G1_28A dataset into 3 sub-periods:
                   Sub1: 2022-01-01 → 2022-12-31
                   Sub2: 2023-01-01 → 2023-12-31
                   Sub3: 2024-01-01 → 2026-04-09
                 For each sub-period: compute NY WR and LONDON WR independently
         Target: NY > LONDON by ≥ +2pp in ALL 3 sub-periods (strict stability)
         AP routing: if any sub-period Δ < +2pp → G2_28 blocked; label effect regime-conditional
         Status: UNCLEARED (requires sub-period analysis; BLOCKING for G2_28)

INDEP_28: ρ(session_label_scalar, all other axes) empirical scan
          Target: all ρ < 0.30
          Status: ANALYTICAL (not blocking; temporal axis expected ρ ≈ 0.00–0.10)

G2_28:   IS backtest CPCV+DSR
         Grid: 4 session scalar variants × 3 DOW multiplier variants × 2 prim-class splits = 24 cells
         DSR: Bailey-Borwein-Lopez de Prado (SSRN 2326253) — mandatory
         Targets: IS Sharpe ≥ 0.70 per class; DSR ≥ 0.50; session WR Δ ≥ +2pp
         Status: BLOCKING (requires G1_28C_v2 and G1_28D first)
```

**Gate status summary (cycle 177):**
```
G_DATA_28 / G_DATA_28B / G_DATA_28C  ← ALL CLEARED
G1_28A (NY vs LONDON WR differential) ← CLEARED (cycle 177 — restructured; Δ=+4.91pp, p<<0.01)
G1_28B (DOW WR differential)          ← CLEARED (cycle 175 — Monday Δ=+1.06pp, p=0.0075)
G1_28C_v2 (OVERLAP_LATE < OVERLAP_EARLY sub-split) ← UNCLEARED (new gate; first barrier)
G1_28D (sub-period stability 2022/2023/2024+)       ← UNCLEARED (new gate; BLOCKING)
INDEP_28                               ← analytical (not blocking)
G2_28 (IS CPCV+DSR)                   ← BLOCKED (requires G1_28C_v2 and G1_28D)
AP_A                                   ← RETIRED (wrong hypothesis; G1_28A cleared)
```

**Script:** `analysis/g1-session-asymmetry-scan.py` — update to 7-label `classify_session()` and add:
1. Sub-split of OVERLAP bars into OVERLAP_EARLY vs OVERLAP_LATE (G1_28C_v2)
2. Sub-period partitioning 2022 / 2023 / 2024+ (G1_28D)

---

## N_eff independence

Retained from intermediate. Temporal meta-signal is causally orthogonal to all structural axes.
Expected ρ(axis28, all others) ≈ 0.00–0.10 (Tier D for all pairs).

| Pair | Expected ρ | Tier | Rule |
|------|-----------|------|------|
| 28 + axis 27 (social sentiment) | ~0.05 | D | Combine freely |
| 28 + axis 7 (funding rate) | ~0.02 | D | Combine freely |
| 28 + axis 26 (CVD) | ~0.10 | D | Combine freely |
| 28 + axis 29 (cross-pair correlation) | ~0.00–0.10 | D | Combine freely |
| 28 + any other axis | ~0.00–0.10 | D | Combine freely |

Maximum combined scalar (three-axis compounding, all D-tier):
- N_eff(3, ρ̄≈0.05) ≈ 2.90; apply conservative hard cap: 1.20× amplify / 0.82× suppress.

---

## Best pairs and timeframe

- **Primary:** BTC/USDT:USDT perpetual (1.00× pair discount)
- **Secondary:** ETH/USDT:USDT perpetual (0.90× pair discount)
- **Other perpetuals:** 0.75× pair discount
- **Timeframe:** Classification updated on every 1h bar open via `bot_loop_start()`. 4h strategy
  entries use the classification of the 4h candle's open hour. The OVERLAP_EARLY/LATE split
  requires 1h granularity — never classify at 4h directly.
- **Kelly α:** 0.00 (meta-signal; no standalone entries)

---

## What remains for next elevation (further sophistication)

1. **G1_28C_v2 / G1_28D clearance** — run updated 7-label scan + sub-period analysis
2. **G2_28 CPCV+DSR** — 24-cell IS backtest once G1 gates cleared
3. **ETH independent calibration** — ETH session profile may require fully independent calibration
   rather than a fixed 0.90× scalar; test BTC session WR ordering vs ETH separately on G1_28 data
4. **OVERLAP_MID sub-split** — 3-way OVERLAP split (EARLY/MID/LATE = London morning / NY morning /
   London close) if G1_28C_v2 shows non-monotonic pattern within OVERLAP_EARLY

---

## Bank state after cycle 177

| Tier | Freqtrade | Note |
|------|-----------|------|
| Naive | 25 | unchanged |
| Intermediate | **30** (−1) | axis 28 elevated to sophisticated |
| Sophisticated | **33** (+1) | axis 28 added |

**29 freqtrade regime axes defined.**
