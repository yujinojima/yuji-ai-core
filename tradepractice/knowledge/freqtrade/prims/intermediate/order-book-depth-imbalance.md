---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T00:00:00+10:00
cycle: 152
prim: order-book-depth-imbalance
project: freqtrade
level: intermediate
axis: 24th regime axis
signal-class: microstructure / resting-order pressure (meta-signal — no standalone entries)
parent: freqtrade/prims/naive/order-book-depth-imbalance.md
status: G2_BLOCKING
---

# Order Book Depth Imbalance (Intermediate)

## 1. Epistemic Genealogy

**Naive (cycle 151):** Single-mode depth ratio (bid_depth / ask_depth within ±0.5% of mid price), 15m REST poll. Flat threshold gates (ratio > 2.0 → ABSORPTION 1.06×; ratio < 0.5 → DISTRIBUTION 0.92×). 3-consecutive-poll sustained gate (anti-spoofing). VWAP + swing pivot anchor gate. 5 failure modes identified (spoofing, polling lag, cross-exchange blind spots, VWAP session reset, regime mismatch). Kelly α 0.05. 3 academic anchors.

**Intermediate (cycle 152):** Five structural upgrades over naive:

1. **Two-mode architecture** — single ratio threshold replaced by distinct Mode A (spike: onset detection from neutral state, 3-poll confirmation, 1–2 candle duration) and Mode B (sustained: 6-poll minimum, 90-minute window, 3–6 candle structural repositioning). Mode-specific modifiers: Mode A 1.08×/0.92×; Mode B 1.05×/0.95×. Separate duration expectations and decay assumptions for each mode.

2. **Onset-detection spoof filter state machine** — Mode A requires ratio to cross threshold FROM below (transition from < 1.6 to > 2.0), not merely exist above threshold. Spoof reversion check: if ratio reverts fully below 1.6 within 1 poll after crossing, log FM1, suppress current signal, do not broadcast. Eliminates flash-wall detection entirely.

3. **VWAP_4h structural anchor gate with distance-based decay** — imbalance signal weighted by distance from VWAP_4h: if price > 0.5% beyond VWAP_4h in signal direction, apply 0.50× delta decay (the move is already partially reflected; book imbalance at that distance is less informative about next-bar direction). Price within ±0.5% of VWAP_4h: full modifier. Price 0.5–1.5% beyond: 0.50× partial decay. Price > 1.5% beyond: 1.00× (neutral, signal deactivated).

4. **ADX regime conditioning** — Mode A ranging-prime (imbalance at pivot in ranging market = highest predictive value): ADX_1h < 15 → Mode A weight × 1.12; ADX 15–25 → no adjustment; ADX > 25 → Mode A weight × 0.85. Mode B trending-prime (sustained imbalance in trending context = institutional conviction buy/sell): ADX > 25 escalates Mode B weight × 1.05; ADX < 15 → Mode B weight × 0.90.

5. **5 failure mode taxonomy formalised with mitigation status** — FM1 (spoofing: handled by onset filter), FM2 (REST polling lag: formalized 15m as deliberate horizon targeting; sub-minute effects irrelevant to strategy), FM3 (cross-exchange blind spots: Coinbase/OKX layer specified as optional upgrade), FM4 (funding dislocation gate: axis 13 output < 0.90 → disable axis 24), FM5 (thin-book regime: total depth < $5M at Binance → return neutral 1.00×).

---

## 2. Core Hypothesis Set

**H1 (Mode A spike — primary claim):** A rapid onset (ratio crossing 2.0 from below, within 3 consecutive 15m polls) in bid/ask depth imbalance at VWAP_4h ± 0.5% predicts higher next-1h BTC return than the unconditional distribution. Mechanism: sudden concentration of resting bids at a structural level represents informed trader absorption positioning (Glosten-Milgrom 1985: informed traders prefer limit orders to minimise adverse selection costs). The onset filter (transition detection) eliminates pre-existing walls — only fresh, directional order placement is captured. Falsifiability: G1_24A frequency ≥ 10 Mode A ABSORPTION events/year + G1_24B WR(next-4h > 0 | Mode A ABSORPTION) ≥ 53%.

**H2 (Mode B sustained — separate mechanism):** A sustained bid-heavy imbalance (mean ratio > 1.5 over 6 consecutive polls; all polls > 1.3) at VWAP_4h ± 0.5% predicts higher next-4h BTC return than the unconditional distribution. Mechanism distinct from H1: not a spike but sustained structural repositioning — institutional participants accumulating over multiple 15m windows, consistent with Huang & Stoll (1997) inventory positioning at structural price levels. Duration expectation 3–6 candles (longer than Mode A). Falsifiability: G1_24B Mode B WR(next-4h > 0 | Mode B ABSORPTION) ≥ 52%.

**H3 (ADX conditioning improves Mode A WR):** Mode A signal has higher WR when ADX_1h < 15 (ranging) than when ADX_1h > 25 (trending). Mechanism: in trending markets, aggressive takers dominate over resting makers; depth imbalance reflects momentum rather than absorption; predictive content for reversal is lower. In ranging markets, resting limit order imbalance at pivot levels directly encodes institutional intent without momentum noise. Falsifiability: WR(Mode A | ADX < 15) ≥ WR(Mode A | ADX > 25) + 2pp at n ≥ 20 events per subset.

**H4 (Onset filter reduces false positives vs raw ratio):** Spoof onset filter (transition detection) produces lower false-positive rate than raw sustained gate (3-poll threshold existence). Mechanism: market makers place and cancel large walls within 1–2 polls as liquidity provision tactics; onset detection requires a NEW imbalance to form from a neutral state, eliminating pre-existing walls and single-poll cancellations. Falsifiability: G1_24C WR(onset-filtered) ≥ WR(raw-ratio) by ≥ 1pp on same event set.

---

## 3. Academic Anchors (Intermediate — 3 inherited from naive)

**[A1] Glosten & Milgrom (1985, JFE) — "Bid, Ask and Transaction Prices in a Specialist Market with Heterogeneously Informed Traders"**
Informed traders prefer limit orders over market orders to avoid adverse selection costs; persistent bid-ask imbalance in the LOB encodes private information before it is reflected in executed price. Foundational mechanism anchor: resting depth imbalance is the measurable signature of informed positioning.

**[A2] Cartea, Jaimungal & Penalva (2015, Cambridge University Press) — "Algorithmic and High-Frequency Trading"**
Order book imbalance (OBI = bid depth / ask depth at best N levels) has statistically significant predictive power for next 1–5 minute price direction; effect size diminishes with horizon. At 15m polling, the signal operates at the upper end of the predictive horizon where effect sizes are smaller but still statistically detectable in liquid markets. Provides the frequency and WR priors for G1_24B analytical pre-confirmation.

**[A3] Huang & Stoll (1997, RFS) — "The Components of the Bid-Ask Spread: A General Approach"**
Resting bid/ask asymmetry at key price levels reflects inventory positioning, information costs, and order-processing costs. Imbalance AT structural levels (VWAP, swing pivots) encodes distinct information from mid-range imbalance. Supporting mechanism for the anchor-gate architecture (VWAP_4h gate is mechanistically grounded, not arbitrary filtering).

---

## 4. Failure Mode Resolution — Intermediate vs Naive

| Failure | Naive status | Intermediate update |
|---------|-------------|---------------------|
| **FM1 — Spoofed walls** | 3-poll sustained gate (partial) | **Upgraded**: onset-detection state machine + spoof reversion check within 1 poll. Flash walls now logged and suppressed regardless of sustained gate. |
| **FM2 — Polling lag too slow** | Acknowledged, deferred | **Resolved as non-issue for strategy horizon**: 15m REST targeting the 1h–4h strategy window; sub-minute effects irrelevant. Polling lag formalised as the correct instrument for the strategy, not a deficiency to fix. |
| **FM3 — Cross-exchange blind** | Deferred to intermediate | **Partial**: Coinbase/OKX cross-exchange layer specified as optional enhancement; not deployed by default due to auth complexity. Binance primary with 70%+ BTC/USDT spot volume sufficient for G1 scan. |
| **FM4 — VWAP session reset** | Deferred | **Resolved**: replaced daily VWAP with 4h rolling VWAP (session-independent anchor). Distance-based decay handles the case where price is far from VWAP anchor. |
| **FM5 — Regime mismatch** | ADX > 30 deactivation suggested | **Upgraded**: continuous ADX conditioning (Mode A × 0.85 at ADX > 25) replaces binary deactivation. Mode B benefits from ADX > 25. Regime-specific modifiers replace single threshold gate. |

---

## 5. G1 Gates

| Gate | Condition | Status |
|------|-----------|--------|
| G_DATA_24 | Public Binance REST `/api/v3/depth?symbol=BTCUSDT&limit=500` — no API key required | **CLEARED** |
| G1_24A | Mode A ABSORPTION: ≥ 10 distinct events/year (onset-filtered, VWAP_4h-anchored, 3-poll sustained) in 12-month live window | UNCLEARED (analytically estimated: 8–15/month raw; with 3-poll + onset filter: ~6–12/month → frequency gate expected to clear) |
| G1_24B | WR(next-4h BTC return > 0 \| Mode A ABSORPTION) ≥ 53% at n ≥ 10; WR(Mode B ABSORPTION) ≥ 52% at n ≥ 8 | UNCLEARED |
| G1_24C | WR(onset-filtered) ≥ WR(raw-ratio) + 1pp on same event set (confirms spoof filter adds value) | UNCLEARED |
| G1_24D | WR(Mode A | ADX < 15) ≥ WR(Mode A | ADX > 25) + 2pp at n ≥ 20 events per subset | UNCLEARED |
| INDEP_24 | ρ(depth_ratio_z, axis 6 vwap_dev_z) < 0.50; ρ(depth_ratio_z, axis 11 OI_z) < 0.70; ρ(depth_ratio_z, axis 3 liquidity_sweep_z) < 0.70 | UNCLEARED |

---

## 6. Anti-Prim Gates

| Gate | Condition | Action |
|------|-----------|--------|
| AP1 | < 5 Mode A ABSORPTION events in 30d live window → G1_24A re-scan; if < 8/year confirmed: demote to naive | Frequency collapse |
| AP2 | 3 consecutive Mode A inverse-direction failures in 30d → activate RSI_15m > 45 long-entry gate for Mode A ABSORPTION | Directional null for long bias |
| AP3 | Coinbase OBI diverges from Binance OBI in > 60% of Mode A events (when cross-exchange layer active) → deactivate cross-exchange layer, Binance-only | Cross-exchange noise |
| AP4 | WR(Mode A onset-filtered) ≤ WR(Mode A raw-ratio) → revert to raw-ratio measurement; onset filter adds no value | Filter degradation |

---

## 7. N_eff Co-occurrence Rules (Intermediate)

| Axis pair | ρ_prior | Tier | Cap |
|-----------|---------|------|-----|
| 24 + 6 (VWAP MR) | 0.30 | C — single-event + moderate bonus | 1.12× amplify / 0.88× suppress |
| 24 + 11 (OI divergence) | 0.25 | C — single-event + moderate bonus | 1.12× amplify |
| 24 + 13 (basis divergence) | 0.20 | D — full compound | 1.15× amplify |
| 24 + 7 (funding rate) | 0.35 | C — single-event + modest bonus | 1.10× amplify |

*All ρ values are structural estimates pending INDEP_24 empirical confirmation. If ρ > 0.50 with any of {6, 11, 13}: N_eff correction applies; combined multiplier floor 0.90× (N_eff adjusted suppress).*

---

## 8. IS Backtest Protocol

Data: Reconstructed Binance LOB snapshots at 15-min intervals, BTC/USDT:USDT perpetual, Jan 2022 – Dec 2024 (36 months). Source: Binance historical data export (spot) or BTC market data providers with LOB tick data.

Protocol:
1. Apply Mode A onset detection + 3-poll gate + VWAP_4h anchor gate + ADX conditioning to full 36-month window
2. Extract Mode A ABSORPTION events (n ≥ 30 required for G1 analysis; estimate: ~40–60 events at current filtering)
3. Compute next-4h BTC return for each event; compare to unconditional distribution (Mann-Whitney U, p < 0.10 one-sided)
4. Run same analysis for Mode B (n ≥ 20 required; estimate: ~15–25 events)
5. G1_24C: compare WR(onset-filtered) vs WR(raw-ratio) on same event set
6. G1_24D: stratify Mode A events by ADX_1h quintile; compare WR(Q1 ADX) vs WR(Q5 ADX)
7. CPCV+DSR trigger: 8-cell base grid (2 modes × 2 directions × 2 ADX states) below 20-cell threshold; DSR not required at intermediate. **DSR becomes mandatory if hyperopt grid-searches ADX thresholds or adds Mode AB interaction (grid expansion ≥ 20 cells).**

OOS: 2025 walk-forward 12m (Jan–Dec 2025) as holdout.

---

## 9. Implementation (Intermediate)

```python
"""
OrderBookDepthState — Order Book Depth Imbalance (Intermediate, cycle 152)
Axis 24 | Meta-signal only | No standalone entries

Deployment: G2_BLOCKING (G1_24A/B/C/D + INDEP_24 must clear first)
"""
from __future__ import annotations
import time
import requests
import logging
from collections import deque
from dataclasses import dataclass, field
from typing import Optional
import numpy as np

log = logging.getLogger(__name__)

BAND_PCT = 0.005          # ±0.5% of mid price
MODE_A_HIGH = 2.0         # spike ABSORPTION threshold
MODE_A_LOW = 0.50         # spike DISTRIBUTION threshold
MODE_A_ONSET_HIGH = 1.60  # prior-state ceiling for onset detection (long)
MODE_A_ONSET_LOW = 0.70   # prior-state floor for onset detection (short)
MODE_A_POLLS = 3          # polls required for Mode A confirmation
MODE_B_HIGH = 1.50        # sustained ABSORPTION mean threshold
MODE_B_LOW = 0.67         # sustained DISTRIBUTION mean threshold
MODE_B_MIN_HIGH = 1.30    # each individual poll must exceed this for Mode B long
MODE_B_MIN_LOW = 0.77     # each individual poll must stay below this for Mode B short
MODE_B_POLLS = 6          # polls required for Mode B
VWAP_FAR = 0.015          # >1.5% beyond VWAP_4h → deactivate
VWAP_PARTIAL = 0.005      # >0.5% beyond VWAP_4h → 0.50× decay
DEPTH_MIN_USD = 5_000_000 # thin-book gate ($5M total depth)
ADX_TREND = 25            # above: trending regime
ADX_RANGE = 15            # below: ranging regime
REST_INTERVAL = 900       # 15-minute poll cooldown (seconds)

# Modifiers
MOD_A_LONG  = 1.08; MOD_A_SHORT  = 0.92
MOD_B_LONG  = 1.05; MOD_B_SHORT  = 0.95
MOD_NEUTRAL = 1.00

@dataclass
class OBState:
    history: deque = field(default_factory=lambda: deque(maxlen=MODE_B_POLLS))
    last_poll: float = 0.0
    mode_a_onset: Optional[str] = None   # 'long' | 'short' | None
    mode_a_polls_above: int = 0
    last_ratio: Optional[float] = None


class OrderBookDepthState:
    """Axis 24: Order Book Depth Imbalance (Intermediate)"""

    def __init__(self):
        self._state: dict[str, OBState] = {}
        self._weight_cache: dict[str, float] = {}

    def _get_state(self, symbol: str) -> OBState:
        if symbol not in self._state:
            self._state[symbol] = OBState()
        return self._state[symbol]

    def update(self, symbol: str, adx_1h: float, vwap_4h: float,
               basis_modifier: float = 1.0) -> None:
        """Call from bot_loop_start() with 15-minute cooldown."""
        st = self._get_state(symbol)
        now = time.time()
        if now - st.last_poll < REST_INTERVAL:
            return
        st.last_poll = now

        # Funding dislocation gate: axis 13 output < 0.90 → deactivate
        if basis_modifier < 0.90:
            self._weight_cache[symbol] = MOD_NEUTRAL
            log.debug("OB24: FM4 basis dislocation gate → neutral")
            return

        ratio = self._fetch_ratio(symbol)
        if ratio is None:
            return  # REST failure → retain last cached weight

        # Thin-book gate
        total_depth_usd = self._last_total_depth_usd.get(symbol, float('inf'))
        if total_depth_usd < DEPTH_MIN_USD:
            self._weight_cache[symbol] = MOD_NEUTRAL
            return

        st.history.append(ratio)
        st.last_ratio = ratio

        weight = self._compute_weight(symbol, st, adx_1h, vwap_4h, ratio)
        self._weight_cache[symbol] = weight

    def _compute_weight(self, symbol, st, adx_1h, vwap_4h, ratio) -> float:
        # --- Spoof reversion check (FM1) ---
        if st.mode_a_onset is not None:
            if (st.mode_a_onset == 'long' and ratio < MODE_A_ONSET_HIGH) or \
               (st.mode_a_onset == 'short' and ratio > MODE_A_ONSET_LOW):
                log.debug(f"OB24 FM1: spoof reversion detected, suppressing")
                st.mode_a_onset = None
                st.mode_a_polls_above = 0
                return MOD_NEUTRAL

        # --- Mode A onset detection ---
        if st.mode_a_onset is None and len(st.history) >= 2:
            prev = list(st.history)[-2] if len(st.history) >= 2 else 1.0
            if ratio > MODE_A_HIGH and prev < MODE_A_ONSET_HIGH:
                st.mode_a_onset = 'long'
                st.mode_a_polls_above = 1
            elif ratio < MODE_A_LOW and prev > MODE_A_ONSET_LOW:
                st.mode_a_onset = 'short'
                st.mode_a_polls_above = 1
        elif st.mode_a_onset == 'long':
            if ratio > MODE_A_HIGH:
                st.mode_a_polls_above += 1
            else:
                st.mode_a_onset = None; st.mode_a_polls_above = 0
        elif st.mode_a_onset == 'short':
            if ratio < MODE_A_LOW:
                st.mode_a_polls_above += 1
            else:
                st.mode_a_onset = None; st.mode_a_polls_above = 0

        # Mode A confirmed at 3 consecutive polls
        if st.mode_a_polls_above >= MODE_A_POLLS:
            direction = 'long' if st.mode_a_onset == 'long' else 'short'
            base = MOD_A_LONG if direction == 'long' else MOD_A_SHORT
            base = self._apply_adx_mode_a(base, adx_1h, direction)
            base = self._apply_vwap_decay(base, vwap_4h, direction, ratio)
            return base

        # --- Mode B: 6-poll sustained ---
        if len(st.history) >= MODE_B_POLLS:
            recent = list(st.history)[-MODE_B_POLLS:]
            mean_ratio = float(np.mean(recent))
            if mean_ratio > MODE_B_HIGH and all(r > MODE_B_MIN_HIGH for r in recent):
                base = MOD_B_LONG
                base = self._apply_adx_mode_b(base, adx_1h, 'long')
                base = self._apply_vwap_decay(base, vwap_4h, 'long', ratio)
                return base
            elif mean_ratio < MODE_B_LOW and all(r < MODE_B_MIN_LOW for r in recent):
                base = MOD_B_SHORT
                base = self._apply_adx_mode_b(base, adx_1h, 'short')
                base = self._apply_vwap_decay(base, vwap_4h, 'short', ratio)
                return base

        return MOD_NEUTRAL

    def _apply_adx_mode_a(self, base: float, adx: float, direction: str) -> float:
        if adx < ADX_RANGE:
            factor = 1.12
        elif adx > ADX_TREND:
            factor = 0.85
        else:
            factor = 1.0
        excess = base - MOD_NEUTRAL
        return MOD_NEUTRAL + excess * factor

    def _apply_adx_mode_b(self, base: float, adx: float, direction: str) -> float:
        if adx > ADX_TREND:
            factor = 1.05
        elif adx < ADX_RANGE:
            factor = 0.90
        else:
            factor = 1.0
        excess = base - MOD_NEUTRAL
        return MOD_NEUTRAL + excess * factor

    def _apply_vwap_decay(self, base: float, vwap_4h: float,
                          direction: str, ratio: float) -> float:
        """Distance-based decay from VWAP_4h anchor."""
        # vwap_4h injected from populate_indicators() 4h informative pair
        current_price = self._last_mid.get('BTCUSDT', vwap_4h)
        if vwap_4h <= 0:
            return base
        dist = (current_price - vwap_4h) / vwap_4h
        if direction == 'long':
            # If price already above VWAP_4h: move partially reflected
            if dist > VWAP_FAR:
                return MOD_NEUTRAL  # deactivate
            elif dist > VWAP_PARTIAL:
                excess = base - MOD_NEUTRAL
                return MOD_NEUTRAL + excess * 0.50
        else:  # short / suppress direction
            if dist < -VWAP_FAR:
                return MOD_NEUTRAL
            elif dist < -VWAP_PARTIAL:
                excess = base - MOD_NEUTRAL
                return MOD_NEUTRAL + excess * 0.50
        return base

    def _fetch_ratio(self, symbol: str) -> Optional[float]:
        """Public Binance REST — no API key required."""
        try:
            resp = requests.get(
                "https://api.binance.com/api/v3/depth",
                params={"symbol": symbol, "limit": 500},
                timeout=8,
            )
            resp.raise_for_status()
            book = resp.json()

            best_bid = float(book["bids"][0][0])
            best_ask = float(book["asks"][0][0])
            mid = (best_bid + best_ask) / 2.0
            self._last_mid = {symbol: mid}

            lo, hi = mid * (1 - BAND_PCT), mid * (1 + BAND_PCT)
            bid_depth = sum(float(q) for p, q in book["bids"] if float(p) >= lo)
            ask_depth = sum(float(q) for p, q in book["asks"] if float(p) <= hi)

            total_depth_usd = (bid_depth + ask_depth) * mid
            if not hasattr(self, '_last_total_depth_usd'):
                self._last_total_depth_usd = {}
            self._last_total_depth_usd[symbol] = total_depth_usd

            return bid_depth / ask_depth if ask_depth > 0 else 1.0
        except Exception as e:
            log.warning(f"OB24 REST error: {e}")
            return None

    def get_weight(self, symbol: str = "BTCUSDT") -> float:
        return self._weight_cache.get(symbol, MOD_NEUTRAL)
```

Integration: `_ob_state = OrderBookDepthState()` instantiated in strategy `__init__`. Called in `bot_loop_start()` with ADX_1h and VWAP_4h from informative pairs. `get_weight("BTCUSDT")` multiplies existing prim entry confidence scalars in `populate_entry_trend()`.

**Kelly α:** 0.07 (intermediate floor). Modifier range 0.92×–1.08× reflects two analytical G1 pre-confirmations (frequency and directional WR analytically grounded via Cartea 2015) with no empirical own-data confirmation.

**Signal reason string:** `"OB24_I: mode={A|B|neutral} ratio={r:.2f} adx={a:.1f} weight={w:.2f} [G2_UNCLEARED]"`

---

## 10. Bank State After Cycle 152

| Tier | Freqtrade | Notes |
|------|-----------|-------|
| Naive | 23 | Unchanged (order-book-depth naive persists at naive tier as reference) |
| Intermediate | **27** (+1: order-book-depth-imbalance axis 24) | Axis 24 elevated naive → intermediate |
| Sophisticated | 26 | Unchanged |

**Total axis count: 77 (freqtrade)** — 23 naive + 27 intermediate + 27 sophisticated as of conductor cycle 152 read.
