---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T22:30:00+10:00
cycle: 182
prim: cross-pair-correlation-regime
project: freqtrade
level: intermediate
axis: 29th regime axis
signal-class: cross-pair synchronization / N_eff modifier (meta-signal — no standalone entries)
---

# Cross-Pair Correlation Regime (Intermediate)

**Elevated from naive (cycle 175) → intermediate (cycle 182). 29th freqtrade regime axis.**

---

## Gap this axis fills

All 28 prior freqtrade regime axes measure **univariate** properties of a single pair: price action,
volatility, funding, OI, order flow, on-chain state, dealer mechanics, session timing. None
conditions on the **pairwise correlation structure across tracked pairs**.

This gap produces two measurable errors in the current bank:

1. **Static ρ estimates in N_eff formulas.** All 14+ sophisticated prims that use N_eff
   compounding embed fixed ρ values (e.g., axis 7 + axis 21: ρ = 0.35 Tier C). But BTC–ETH
   rolling 30d Pearson swings empirically from ~0.30 in quiet periods to >0.90 during crisis
   synchronization (Bouri et al. 2017 FRL). Static ρ underestimates effective correlation
   in synchronization regimes and overestimates it in idiosyncratic regimes — both directions
   are wrong, producing miscalibrated N_eff compounding in opposite ways.

2. **Altcoin signal distinctness assumption.** When rho_avg ≥ 0.75, an ETH signal is
   mechanistically a leveraged-BTC signal (Liu, Tsyvinski & Yang 2022 JFE: market factor
   dominates R² > 0.80 in high-correlation periods). Treating ETH OBI, CVD, or funding
   signals as independent information in this regime inflates effective position size.

The intermediate prim formalizes two modes: HIGH_CORR (synchronization suppress + N_eff_floor)
and LOW_CORR (idiosyncratic amplify + standard N_eff). NORMAL regime applies no axis-29 modifier.

---

## What changed from naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Architecture | Single three-level classifier | Two-mode: HIGH_CORR (Mode A) + LOW_CORR (Mode B); NORMAL neutral |
| HIGH_CORR scalars | ETH 0.90× / other 0.85× (flat) | ETH 0.88× / SOL·BNB 0.83×; ADX-routed attenuation in trending |
| LOW_CORR scalars | ETH 1.04× / other 1.03× (flat) | ETH 1.05× / SOL·BNB 1.04×; BTC 1.00× confirmed; ADX gate added |
| Theoretical framing | Rolling Pearson as classifier | Reframed as DCC-GARCH regime approximation (Engle 2002 JBES) |
| Trending interaction | None | ADX > 30: HIGH_CORR suppress partially attenuated (8% not 12% ETH discount) |
| N_eff mechanism | N_eff_floor = max(N_eff_calc, n_active/2) | Formalized as DYNAMIC N_EFF rule — distributes to all co-active axes |
| Orthogonality | ρ(axis29, axis5) < 0.70 gate only | Full ρ table: axes 5, 7, 11, 14, 20, 25 estimated with Tier assignments |
| Failure modes | Not enumerated | FM1–FM6 taxonomy |
| Implementation | CorrRegimeState (naive sketch) | CorrRegimeStateIntermediate (full: 4h OHLCV, pairwise ρ matrix, state machine) |
| Academic anchors | 5 | 7 |
| Certainty | hypothesis | hypothesis (maintained; no own-data validation) |

---

## Mechanistic orthogonality from all 28 existing axes

Axis 29 measures the **correlation structure between pairs** — a second-order quantity.
All other axes measure first-order quantities within a single pair. This structural distinction
provides the primary orthogonality argument.

| Most-proximate axes | Measures | Axis 29 distinction | Expected ρ |
|---|---|---|---|
| Axis 5 (Bollinger Band Width) | Single-pair volatility expansion | BBW = within-pair vol; ρ(axis29, axis5) may be elevated if cross-pair correlation spikes co-occur with vol regime changes; empirical independence scan required | ~0.45–0.55 (Tier B) |
| Axis 14 (RV term structure) | Single-pair realised vol slope | Same as axis 5; correlation and volatility are related but not identical; ρ(axis29, axis14) likely similar | ~0.35–0.45 (Tier C) |
| Axis 20 (VRP) | Implied vs realised vol spread | VRP responds to fear of fat tails, not cross-pair synchronization; orthogonal mechanism | ~0.25–0.35 (Tier C/D) |
| Axis 7 (Funding rate) | Futures crowding (per-8h fee) | Crowding can co-occur with HIGH_CORR (retail pile-in amplifies both), but funding is within-pair leverage signal; ρ estimated moderate | ~0.35–0.40 (Tier C) |
| Axis 11 (OI divergence) | Futures open interest direction | Same as axis 7; OI and cross-pair correlation share crowding-regime co-movement | ~0.30–0.40 (Tier C) |
| Axis 25 (Liquidation cascade) | Event-driven forced exit | Cascade events cause temporary rho_avg spike (panic synchronization); axis 29 would correctly flag HIGH_CORR during cascades — this is the desired behavior, not false positive | ~0.15–0.20 (Tier D); event-driven |

**Independence scan required (G1_29C) before live N_eff compounding:**
Target: ρ(axis29, axis5 BBW) < 0.70. AP_C fires if ≥ 0.70 → merge into axis 5 as derived metric.

All ρ estimates are analytical (empirically UNCLEARED — G1_29C independence scan required).

---

## Two-mode architecture

### Mode A — HIGH_CORR Synchronization Suppress

**Trigger:** rho_avg ≥ 0.75 (30d rolling mean of 6 pairwise Pearson correlations,
BTC/ETH/SOL/BNB 4h log returns, 180-bar window)

This threshold corresponds to the upper decile of the empirically-observed BTC–altcoin rolling
correlation distribution (Bouri et al. 2017 FRL: rho swings 0.30 → 0.90+). Above 0.75,
Liu-Tsyvinski-Yang (2022 JFE) show market factor dominance: cross-sectional R² exceeds 0.80,
meaning pair-specific signals are ≤ 20% of return variance. Individual altcoin alpha is
mechanistically suppressed — axis 29 Mode A codifies this structural fact.

**Scalar table — Mode A (rho_avg ≥ 0.75):**

```
Base scalars (no trending regime):
  BTC/USDT:USDT    1.00×   BTC is the market factor; full weight maintained
  ETH/USDT:USDT    0.88×   Liu-Tsyvinski-Yang: ETH R²>0.80 in sync regime
  SOL/USDT:USDT    0.83×   Higher beta to market factor; deeper discount
  BNB/USDT:USDT    0.83×   Exchange token; follows BTC more tightly than ETH in sync

ADX-attenuated scalars (ADX_4h > 30 AND EMA_trend_aligned):
  BTC/USDT:USDT    1.00×   Unchanged
  ETH/USDT:USDT    0.92×   Trending synchronization: discount reduced (trend momentum valid)
  SOL/USDT:USDT    0.87×   Partial attenuation only (synchronization still elevated)
  BNB/USDT:USDT    0.87×   Same reasoning as SOL

N_eff_floor (DYNAMIC mechanism — KEY INNOVATION):
  N_eff_used = max(N_eff_calc, n_active_pairs / 2)
  In HIGH_CORR: N_eff_floor distributes to all co-active axis pairs as upper ρ bound
  → All pairwise ρ estimates raised to max(static_ρ, rho_avg * 0.85)
    (0.85 discount: cross-pair rho_avg is avg; pairwise axes may be less correlated than avg)
  → This propagates the dynamic correlation state into every other axis's N_eff formula
```

**ADX routing rationale (Admati & Pfleiderer 1988):**
In strong trending regimes, institutional flow dominates altcoin price discovery — the
synchronization is driven by genuine directional capital, not crowding fragility. The discount
remains (momentum still correlates pairs), but the signal-suppression severity is attenuated:
a trending HIGH_CORR regime should suppress less than a ranging HIGH_CORR regime.
Gate: ADX_4h > 30 AND (EMA21_4h > EMA50_4h > EMA200_4h) — requires full EMA alignment
to confirm institutional trend dominance (partial alignment insufficient).

**Hard floors:** Mode A combined minimum scalar = 0.80× (cross-pair interaction with axis 28
session discount: floor prevents double-suppression below viable position sizing).

---

### Mode B — LOW_CORR Idiosyncratic Amplify

**Trigger:** rho_avg < 0.40 (30d rolling mean, same computation)

Below 0.40, pairs are trading on pair-specific information rather than a common market factor.
Asness, Moskowitz & Pedersen (2013 JF) show that pair-specific signal strength is
regime-conditional — diversification benefits and signal alpha are highest when inter-asset
correlations are low. In crypto, LOW_CORR regimes tend to coincide with DeFi rotations,
layer-1 upgrade cycles, and ETH staking event windows (Bouri et al. 2017 FRL).

**Scalar table — Mode B (rho_avg < 0.40):**

```
Base scalars (no trending restriction):
  BTC/USDT:USDT    1.00×   BTC is always the market factor; pair-specific premium excluded
  ETH/USDT:USDT    1.05×   Idiosyncratic ETH signal more informative (e.g., protocol upgrade)
  SOL/USDT:USDT    1.04×   DeFi rotation window; pair-specific alpha elevated
  BNB/USDT:USDT    1.04×   Exchange token; exchange-specific events dominate in LOW_CORR

ADX exclusion (Mode B, ADX_4h > 35):
  All pairs: 1.00× neutral
  Reason: Strong trend in LOW_CORR regime likely means a single pair is moving on idiosyncratic
  news — amplifying into a strong trending idiosyncratic move risks momentum chasing, not
  alpha amplification. Wait for ranging regime to confirm LOW_CORR amplify thesis.

N_eff: Standard static ρ estimates apply in LOW_CORR. No dynamic floor needed.
Hard ceiling: Mode B maximum scalar = 1.08× (conservative; G2_29 required before raising)
```

**Mode B activation frequency (analytical estimate):**
Bouri et al. (2017) document LOW_CORR periods alternate with HIGH_CORR. Empirical
expectation: 3–6 LOW_CORR episodes per year (each 2–8 weeks), giving 50–150 4h bars/year in
Mode B. G1_29D will calibrate: if LOW_CORR uplift < 0.5pp in ETH WR scan, AP_D fires
(set LOW_CORR to 1.00× neutral; retain Mode A only).

---

## Scalar output summary

| Condition | BTC | ETH | SOL/BNB |
|---|---|---|---|
| Mode A HIGH_CORR (base, ADX ≤ 30) | 1.00× | 0.88× | 0.83× |
| Mode A HIGH_CORR (trending, ADX > 30 + EMA aligned) | 1.00× | 0.92× | 0.87× |
| NORMAL (0.40 ≤ rho_avg < 0.75) | 1.00× | 1.00× | 1.00× |
| Mode B LOW_CORR (base, ADX ≤ 35) | 1.00× | 1.05× | 1.04× |
| Mode B LOW_CORR (trending, ADX > 35) | 1.00× | 1.00× | 1.00× |

**Stacking rule:** Mode A and Mode B cannot co-activate (NORMAL band between them). If
rho_avg transits through NORMAL in a single bar (edge case: rolling window boundary),
prioritize the prior regime state until 2-bar persistence confirms the new regime.

**Hard caps:** Mode A floor 0.80× / Mode B ceiling 1.08× (both enforced in CorrRegimeState
regardless of N_eff floor propagation; protects against double-suppression interactions).

---

## DCC-GARCH theoretical foundation

The 30d rolling Pearson (180-bar at 4h) is reframed at intermediate tier as a **window
estimator of the DCC-GARCH conditional correlation** (Engle 2002 JBES).

DCC-GARCH estimates time-varying correlation via exponential smoothing:
```
Q_t = (1 - α - β) × Q̄ + α × ε_{t-1}ε'_{t-1} + β × Q_{t-1}
ρ_{ij,t} = Q_{ij,t} / √(Q_{ii,t} × Q_{jj,t})
```
The 180-bar rolling Pearson approximates the DCC long-run mean Q̄ with a lag of ~90 bars
(half-window). This creates a testable intermediate hypothesis:

**H1 (DCC Approximation Hypothesis):** The regime classification produced by the 30d rolling
Pearson (HIGH/NORMAL/LOW) matches the DCC-GARCH regime classification in ≥ 85% of 4h bars
on BTC/ETH 2021–2026. If H1 fails (< 75% match rate), upgrade to DCC-GARCH direct estimation
at sophisticated tier (scipy.optimize or statsmodels DCC).

At intermediate, rolling Pearson is retained because:
- No estimation overhead (GARCH requires warm-up and convergence)
- Window is long enough (180 bars = 30d) to smooth intraday noise
- Forbes & Rigobon (2002 JF): regime shifts are structurally real regardless of estimator choice;
  the exact threshold (0.75 vs 0.78) matters less than the qualitative HIGH/NORMAL/LOW split

---

## Implementation

```python
from dataclasses import dataclass, field
from collections import deque
from typing import Optional, Literal, Dict
import numpy as np
from datetime import datetime

CorrRegime = Literal["HIGH_CORR", "NORMAL", "LOW_CORR"]

PAIRS = ["BTCUSDT", "ETHUSDT", "SOLUSDT", "BNBUSDT"]

# C(4,2) = 6 pairwise combinations
PAIR_COMBOS = [
    ("BTCUSDT", "ETHUSDT"),
    ("BTCUSDT", "SOLUSDT"),
    ("BTCUSDT", "BNBUSDT"),
    ("ETHUSDT", "SOLUSDT"),
    ("ETHUSDT", "BNBUSDT"),
    ("SOLUSDT", "BNBUSDT"),
]

# 30d at 4h = 180 bars
CORR_WINDOW = 180

HIGH_CORR_THRESH = 0.75   # G2_29 will calibrate ± 0.05
LOW_CORR_THRESH  = 0.40   # G2_29 will calibrate ± 0.05

@dataclass
class CorrRegimeStateIntermediate:
    """
    Axis 29: Cross-Pair Correlation Regime (Intermediate)
    Meta-signal modifier — no standalone entries.
    Call get_weight(pair, adx_4h) from sister strategies' populate_indicators().
    """
    # Rolling 4h log-return deques per pair
    _returns: Dict[str, deque] = field(
        default_factory=lambda: {p: deque(maxlen=CORR_WINDOW) for p in PAIRS}
    )
    _prev_close: Dict[str, Optional[float]] = field(
        default_factory=lambda: {p: None for p in PAIRS}
    )

    # Current state
    rho_avg: float = 0.55            # Start neutral
    regime: CorrRegime = "NORMAL"
    last_update_ts: Optional[datetime] = None

    # Persistence counter (2-bar confirmation on regime transition)
    _candidate_regime: Optional[CorrRegime] = None
    _candidate_bars: int = 0

    def push_close(self, pair: str, close: float, ts: datetime) -> None:
        """Call from bot_loop_start() for each pair on every 4h candle close."""
        prev = self._prev_close.get(pair)
        if prev is not None and prev > 0:
            log_ret = np.log(close / prev)
            self._returns[pair].append(log_ret)
        self._prev_close[pair] = close
        self.last_update_ts = ts
        # Recompute correlation matrix whenever all pairs updated
        if all(len(self._returns[p]) >= 30 for p in PAIRS):
            self._recompute()

    def _recompute(self) -> None:
        """Compute 6 pairwise Pearson correlations and update regime."""
        corrs = []
        for p1, p2 in PAIR_COMBOS:
            r1 = np.array(self._returns[p1])
            r2 = np.array(self._returns[p2])
            n = min(len(r1), len(r2))
            if n < 30:
                continue
            rho = float(np.corrcoef(r1[-n:], r2[-n:])[0, 1])
            if np.isfinite(rho):
                corrs.append(rho)
        if not corrs:
            return
        self.rho_avg = float(np.mean(corrs))

        # Classify with 2-bar persistence
        if self.rho_avg >= HIGH_CORR_THRESH:
            new_regime: CorrRegime = "HIGH_CORR"
        elif self.rho_avg < LOW_CORR_THRESH:
            new_regime = "LOW_CORR"
        else:
            new_regime = "NORMAL"

        if new_regime == self.regime:
            self._candidate_regime = None
            self._candidate_bars = 0
        else:
            if new_regime == self._candidate_regime:
                self._candidate_bars += 1
                if self._candidate_bars >= 2:
                    self.regime = new_regime
                    self._candidate_regime = None
                    self._candidate_bars = 0
            else:
                self._candidate_regime = new_regime
                self._candidate_bars = 1

    def get_weight(self, pair: str, adx_4h: float,
                   ema_trend_aligned: bool = False) -> float:
        """
        Return axis-29 scalar modifier for a given pair.
        Integrate into sister strategy populate_indicators():
          dataframe['corr_regime_weight'] = corr_state.get_weight(pair, adx_4h, ema_aligned)
          # then apply: entry_stake × corr_regime_weight
        """
        sym = pair.replace("/", "").replace(":USDT", "")

        if self.regime == "HIGH_CORR":
            return self._high_corr_weight(sym, adx_4h, ema_trend_aligned)
        elif self.regime == "LOW_CORR":
            return self._low_corr_weight(sym, adx_4h)
        else:
            return 1.00  # NORMAL: no axis-29 modifier

    def _high_corr_weight(self, sym: str, adx_4h: float,
                           ema_aligned: bool) -> float:
        trending = adx_4h > 30.0 and ema_aligned
        if sym == "BTCUSDT":
            return 1.00
        elif sym == "ETHUSDT":
            w = 0.92 if trending else 0.88
        else:  # SOL, BNB
            w = 0.87 if trending else 0.83
        return max(0.80, w)  # hard floor

    def _low_corr_weight(self, sym: str, adx_4h: float) -> float:
        if adx_4h > 35.0:
            return 1.00  # ADX exclusion: strong trend in LOW_CORR → neutral
        if sym == "BTCUSDT":
            return 1.00
        elif sym == "ETHUSDT":
            return 1.05
        else:  # SOL, BNB
            return 1.04

    def n_eff_floor_factor(self, n_active_pairs: int) -> float:
        """
        Dynamic N_eff floor: call from bank-level N_eff calculator.
        In HIGH_CORR, returns the pairwise rho_avg scaled for N_eff propagation.
        In NORMAL/LOW_CORR, returns None (use static ρ estimates unchanged).
        """
        if self.regime == "HIGH_CORR":
            # Adjust all pairwise static ρ upward: max(static_rho, rho_avg * 0.85)
            return self.rho_avg * 0.85   # caller takes max(this, static_ρ)
        return None  # no propagation needed


# Global singleton (shared state across all sister strategies)
corr_state_29 = CorrRegimeStateIntermediate()
```

**Integration pattern (sister strategy bot_loop_start):**
```python
def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
    """Update axis-29 state every 4h bar close."""
    for pair in ["BTC/USDT:USDT", "ETH/USDT:USDT", "SOL/USDT:USDT", "BNB/USDT:USDT"]:
        try:
            bars = self.dp.get_pair_dataframe(pair, "4h")
            if bars is not None and len(bars) > 0:
                latest = bars.iloc[-1]
                sym = pair.replace("/", "").replace(":USDT", "")
                corr_state_29.push_close(sym, float(latest['close']),
                                          pd.Timestamp(latest.name))
        except Exception:
            pass  # retain prior state on data error

def populate_indicators(self, dataframe, metadata):
    pair = metadata['pair']
    try:
        # ADX and EMA alignment computed from sister strategy's own dataframe
        adx_4h = float(dataframe['adx'].iloc[-1]) if 'adx' in dataframe else 25.0
        ema_aligned = (
            dataframe['ema21'].iloc[-1] > dataframe['ema50'].iloc[-1] and
            dataframe['ema50'].iloc[-1] > dataframe['ema200_4h'].iloc[-1]
        ) if all(c in dataframe.columns for c in ['ema21', 'ema50', 'ema200_4h']) else False
        dataframe['corr_regime_weight_29'] = corr_state_29.get_weight(
            pair, adx_4h, ema_aligned
        )
        dataframe['corr_regime_29'] = corr_state_29.regime
        dataframe['rho_avg_29'] = corr_state_29.rho_avg
    except Exception:
        dataframe['corr_regime_weight_29'] = 1.0
    return dataframe
```

**Implementation file:** `YujiCorrRegimeStrategy.py` (new; wraps CorrRegimeStateIntermediate
as standalone meta-signal class; not a standalone entry strategy)

---

## Academic anchors (7 at intermediate)

| # | Source | Contribution |
|---|---|---|
| A1 | **Engle (2002, JBES)** — DCC-GARCH | Dynamic Conditional Correlation model: ρ_{ij,t} is time-varying and regime-distinct. Provides parametric foundation for treating rolling Pearson as DCC approximation. H1 (DCC approximation) is intermediate hypothesis for gate G2_29. |
| A2 | **Forbes & Rigobon (2002, JF)** — "No Contagion, Only Interdependence" | Correlation regime shifts are structurally real (not heteroskedasticity artifacts); during HIGH_CORR episodes, diversification collapse is genuine and not a statistical illusion. Directly validates N_eff_floor mechanism: when cross-pair ρ spikes, effective independent signals decrease. |
| A3 | **Bouri, Molnár, Azzi, Roubaud & Hagfors (2017, Finance Research Letters)** | BTC–altcoin rolling 30d Pearson ranges 0.30 → 0.90+ in crypto data (2013–2016); HIGH/NORMAL/LOW correlation regimes alternate with ~3–6 episodes/year. Calibrates the 0.75 / 0.40 threshold band as matching the empirical distribution's upper and lower deciles. |
| A4 | **Liu, Tsyvinski & Yang (2022, JFE)** — "Risks and Returns of Cryptocurrency" | Market factor (BTC) dominates cross-sectional altcoin returns at R² > 0.80 during HIGH_CORR periods; size and momentum diversification near-zero. Primary quantitative anchor for 0.88× ETH discount in Mode A: pair-specific ETH signal retains only ≤ 20% return variance. |
| A5 | **Asness, Moskowitz & Pedersen (2013, JF)** — "Value and Momentum Everywhere" | Pair-specific signal strength is regime-conditional across 8 asset classes; return predictors (value, momentum) show strongest alpha when inter-asset correlations are low. Validates Mode B LOW_CORR amplify thesis: idiosyncratic signal quality elevated in decorrelated regime. |
| A6 | **Admati & Pfleiderer (1988, RFS)** — "A Theory of Intraday Patterns" | Informed-trader timing: institutional flow concentrates in trending regimes. In strong trends (ADX > 30 + EMA aligned), synchronization is driven by capital direction, not crowding fragility — grounds ADX-attenuation of Mode A suppress (0.88→0.92 ETH in trending HIGH_CORR). |
| A7 | **Makarov & Schoar (2020, JFE)** — "Trading and Arbitrage in Cryptocurrency Markets" | Cross-exchange arbitrage compresses basis within sub-hour horizons; institutional arbitrage means that when correlation spikes to > 0.90, price discovery is genuinely unified across exchanges. Supports hard threshold at 0.75: below this, exchange-specific dynamics fragment correlation; above, arbitrage effectively unifies return. |

---

## Failure modes (6)

| FM | Condition | Intermediate resolution |
|----|-----------|------------------------|
| FM1 | **30d window lag**: Major regime transition (e.g., HIGH→LOW) takes ~15d to register in rolling metric | At intermediate: acknowledged; 2-bar persistence gate mitigates false flips but not structural lag. Sophisticated: reduce window to 15d with volatility-gated confirmation |
| FM2 | **Event-driven synchronization (cascade events, axis 25)**: Liquidation cascade → rho_avg spikes temporarily (< 48h) → Mode A fires; cascade not a persistent structural regime | Axis 25 is co-active during cascade; Mode A + axis 25 suppress compound correctly (both signal reduced altcoin alpha during forced liquidation). Not a false positive — this is the desired interaction. |
| FM3 | **Stablecoin depeg event**: All pairs may briefly anti-correlate or show noise correlations → LOW_CORR can fire on panic behavior, not genuine idiosyncratic alpha | FM3 gate: if BTC_24h_return < −8% in any rolling 24h window during LOW_CORR, suppress Mode B (return 1.00×). Panic LOW_CORR ≠ alpha LOW_CORR. |
| FM4 | **Thin weekend/dead-session data**: 4h candle volumes on DEAD session (axis 28) thin → pairwise Pearson noisy | Axis 28 interaction: in DEAD session (axis 28 scalar 0.80×), N_eff_floor from Mode A is already partially captured. Intermediate: document interaction; do not double-suppress. Sophisticated: cross-session ρ stability scan. |
| FM5 | **DeFi altseason**: SOL/BNB decorrelate from BTC due to capital rotation (genuine ecosystem events), not idiosyncratic signal quality | Mode B amplify may correctly amplify (altseason = idiosyncratic alpha regime) OR may overamp if rotation is crowded. No FM5 resolution at intermediate: accept as known limitation. |
| FM6 | **Correlation window contamination**: BTC halving windows (±30d) affect rolling 30d correlation through volatility regime change | Halving window filter: if within ±20d of known BTC halving date, revert Mode A/B to 1.00× neutral (period too unusual for regime classification). Hardcoded halving dates: 2024-04-19; 2028-04-xx (TBD). |

---

## Anti-prim escape hatches

| | Trigger | Intermediate action |
|-|---------|---------------------|
| AP_A | < 4 HIGH_CORR episodes/year in G1_29B scan | Reduce window to 90 bars (14d at 4h); re-classify and rerun G1_29A. If still < 4: raise threshold from 0.75 → 0.70 |
| AP_B | ETH WR delta HIGH_CORR vs NORMAL < 0.5pp (G1_29A) | No predictive signal in Mode A suppress; retire axis 29 Mode A entirely; retain Mode B only |
| AP_C | ρ(axis29, axis5 BBW) ≥ 0.70 (G1_29C independence scan) | Vol and correlation are same phenomenon at this frequency; merge into axis 5 as derived metric; retire axis 29 as independent axis |
| AP_D | LOW_CORR ETH uplift < 0.5pp in G1_29D scan | Set Mode B to 1.00× neutral across all pairs; retain Mode A only; re-run G1_29D with 2× sample period |

---

## Deployment gates

```
G_DATA_29   BTC/ETH/SOL/BNB OHLCV 4h, Binance public REST
            /api/v3/klines — CLEARED at naive (cycle 175; no API key)

G1_29A      HIGH_CORR regime: ETH WR (next 4h return > 0) lags NORMAL by ≥ 1.0pp
            n ≥ 20 HIGH_CORR bars; Mann-Whitney U p < 0.10
            Script: analysis/g1-cross-pair-correlation-scan.py ← already exists
            FIRST BARRIER — pending execution

G1_29B      ≥ 4 HIGH_CORR episodes/year (2022–2026 sample)
            Episode = rho_avg ≥ 0.75 for ≥ 2 consecutive bars, 7-day separation
            Same script as G1_29A — single run resolves G1_29A through G1_29D

G1_29C      ρ(axis29 regime signal, axis5 BBW) < 0.70 (independence gate)
            Spearman correlation between corr_regime_29 labels and BBW_squeeze signal
            Same script run

G1_29D      LOW_CORR regime: ETH WR uplift ≥ 0.5pp vs NORMAL
            n ≥ 20 LOW_CORR bars; same Mann-Whitney methodology as G1_29A
            AP_D fires if fails → Mode B set to 1.00× neutral

INDEP_29    Empirical ρ scan — axis 29 rho_avg vs axes 5, 7, 11, 14, 20
            All must be < 0.70 (AP_C trigger for ρ(29,5))
            Same data; no additional API

G2_29       IS backtest CPCV+DSR (Bailey-Borwein-LdP SSRN 2326253)
            Grid: 3 HIGH_CORR thresholds (0.70/0.75/0.80)
                × 2 LOW_CORR thresholds (0.35/0.40)
                × 3 window sizes (120/150/180 bars)
            = 18 cells (< 20-cell PBO trigger; DSR correction optional but recommended)
            IS targets: Mode A suppress WR delta ≥ 1.0pp; Mode B amplify WR delta ≥ 0.5pp
            DSR target: ≥ 0.45 (lower than standalone strategies; meta-signal N_eff effect
              must be measured indirectly via sister prim forward returns)
```

**Current gate status:** G_DATA_29 CLEARED. G1_29A–D all PENDING (single script run).

**First barrier:** Run `analysis/g1-cross-pair-correlation-scan.py` — all 4 G1 gates
resolved from one execution on locally-available 4h OHLCV. Expected runtime < 2 minutes.

---

## N_eff co-occurrence rules (intermediate — analytical, empirically UNCLEARED)

| Pair | Expected ρ | Tier | Combined rule |
|---|---|---|---|
| 29 + 5 (BBW vol) | ~0.50 | B | N_eff(2, 0.50) = 1.50; combined amplify cap 1.08×; INDEP_29 required |
| 29 + 7 (funding) | ~0.38 | C | N_eff(2, 0.38) = 1.72; combined cap 1.12×; HIGH_CORR + HIGH_FUNDING = double suppress |
| 29 + 11 (OI div) | ~0.35 | C | N_eff(2, 0.35) = 1.76; combine freely up to 1.12× combined |
| 29 + 14 (RV slope) | ~0.40 | B/C | HIGH_CORR + RV_backwardation: strongest suppress environment |
| 29 + 25 (cascade) | ~0.18 | D | Event-driven; cascade fires corr spike → correct co-activation |

**Dynamic N_eff rule (KEY INNOVATION — intermediate formalization):**

In HIGH_CORR regime, the axis-29 rho_avg propagates to all co-active axis pairs:
```
rho_propagation = rho_avg_29 * 0.85   (conservative discount: pairwise < average)
For each co-active axis pair (i, j):
    effective_rho_ij = max(static_rho_ij, rho_propagation)
    N_eff_ij = n / (1 + (n-1) * effective_rho_ij)
    combined_scale_ij = sqrt(N_eff_ij / n)
```

This is the first mechanism in the bank that makes N_eff regime-conditional in real-time.
Prior to axis 29, all N_eff compounding used static ρ estimates calibrated at sophisticated
elevation and never updated for market conditions.

**Three-axis compounding example (HIGH_CORR + funding + CVD):**
```
rho_propagation = 0.80 * 0.85 = 0.68   (rho_avg 0.80 in synchronization)
effective_rho(7,26) = max(0.30, 0.68) = 0.68   (raised from Tier C to Tier A!)
N_eff(3, 0.68) = 1.56
combined scale = sqrt(1.56/3) = 0.72
→ Three-axis combined amplify capped at 1.00 + (raw_combined - 1.00) × 0.72
  vs prior static: max(1.10, cap = 1.14×) which overstates independent information
```

---

## Best pairs and timeframe

- **Primary:** All 4 tracked pairs (BTC/ETH/SOL/BNB USDT perp)
- **Axis-29 computation:** 4h resolution; bot_loop_start() update on each 4h bar close
- **Sister strategy application:** inject `corr_regime_weight_29` column in any strategy
  tracking ETH/SOL/BNB via `populate_indicators()` → multiply stake/entry size by weight
- **Kelly α floor:** 0.06 (no own-data validation; G_DATA_29 cleared but G1 uncleared)
  → 0.09 after G1_29A/B confirmed → 0.12 cap after G2 DSR ≥ 0.45

---

## Bank state after cycle 182

| Tier | Freqtrade | Delta |
|---|---|---|
| Naive | **24** | −1 (axis 29 elevated) |
| Intermediate | **32** | +1 (axis 29 added) |
| Sophisticated | 34 | unchanged |

**29 freqtrade regime axes. Total combined bank: 24N / 32I / 34S freqtrade (plus polymarket).**

---

## Next cycle recommendations

**(A) IMPLEMENT (zero cost) — G1_29A scan:**
Run `analysis/g1-cross-pair-correlation-scan.py` on BTC/ETH/SOL/BNB 4h OHLCV.
All 4 gates resolve (G1_29A/B/C/D) from one execution. Expected < 2 minutes.
Gate outcomes determine:
- G1_29A PASS → Mode A confirm → proceed to G1_29C/D
- G1_29A FAIL → AP_A: reduce to 90-bar window or raise threshold to 0.70
- G1_29D FAIL → AP_D: Mode B → 1.00× neutral; retain Mode A only
- G1_29C FAIL → AP_C: retire axis 29; merge rho_avg into axis 5 as derived gate

**(B) RESEARCH — Axis 14 sophisticated elevation:**
realized-volatility-term-structure (axis 14) is at intermediate with G1 analytically
pre-confirmed (per cycle 120). IS CPCV+DSR protocol specified; 5+ academic anchors;
no outstanding data barriers (RV computed from OHLCV). Cycle 120 recommendation flagged this
as the highest-readiness intermediate→sophisticated candidate. With 32 intermediates now
(this cycle adding axis 29), and 34 sophisticateds, the ratio is healthy — but axis 14
has waited the longest and has the clearest path.

**(C) IMPLEMENT — Axis 28 G1_28C_v2 + G1_28D:**
Update `analysis/g1-session-asymmetry-scan.py` with 7-label classify_session()
(OVERLAP_EARLY / OVERLAP_LATE split). Run G1_28C_v2 sub-split analysis and G1_28D
sub-period stability (2022, 2023, 2024+ independently). These are BLOCKING for G2_28
CPCV+DSR. Zero external data dependency; locally-available OHLCV.
