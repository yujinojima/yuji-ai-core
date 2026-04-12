---
prim: on-chain-supply-dynamics-regime
project: freqtrade
level: intermediate
cycle: 123
axis: 18th regime axis
signal-class: blockchain-native supply dynamics (meta-signal — no standalone entries)
parent: freqtrade/prims/naive/on-chain-supply-dynamics-regime.md
created: 2026-04-13
---

# On-Chain Supply Dynamics Regime (Intermediate)

## Mechanism

The naive prim established the core insight: MVRV ratio and exchange net flows measure structural supply pressure invisible in price, derivatives, or equity data. Long-term holders (LTH, coins unmoved ≥ 155 days) distribute at cycle peaks and re-accumulate at capitulation troughs; this supply-side pressure is encoded in UTXO age distribution data, not in any order book or derivative instrument.

The intermediate elevation adds four structural refinements that move the signal from "binary on/off with ~5 episodes in 9 years" to "calibrated three-zone gradient with ≥ 10 signal periods annually, duration-gated, and formally de-correlated from adjacent axes":

1. **Three-zone gradient architecture** — replaces binary MVRV threshold (2.5/1.0) with a five-zone suppression/amplification gradient using both raw MVRV and MVRV Z-score. Intermediate zones (distribution elevated, accumulation elevated) fire at lower thresholds with lighter weights, providing meaningful signal at ~15–30 sub-episodes per year where the naive rule provided none.
2. **Duration gate** — 90-day rolling maximum suppress window with explicit reset protocol. Prevents the naive-tier failure mode of 9-month blanket suppression during extended distribution phases.
3. **N_eff redundancy protocol** — formal co-occurrence rules for axis 6 (capitulation-exhaustion-reversal) and axis 7 (funding-rate-crowding-reversal), replacing the naive prim's informal "redundancy concern" with defined multiplicative vs deactivation rules per zone.
4. **SOPR dual-confirmation gate** — Spent Output Profit Ratio (SOPR) as secondary on-chain signal; confirms vs contradicts the MVRV zone assessment; extreme zones (Zone 3 distribution, Zone 5 capitulation) require SOPR confirmation to apply full weight.

**Signal in one line**: MVRV Zone 2 (elevated): suppress 0.92×; Zone 3 (extreme) + SOPR confirmed: suppress 0.85×; Zone 4 (accumulation elevated): amplify 1.05×; Zone 5 (capitulation) + SOPR confirmed: amplify 1.10×; Zone 5 without SOPR confirmation: amplify 1.05×. All weights subject to duration gate (90d cap) and axis 6/7 co-occurrence rules.

**Three blocking gates**:
- G_DATA — Glassnode API access confirmed (API key obtained; Docker env integration verified; entity-adjusted exchange flows — not raw transfers — available at Glassnode Advanced tier or CryptoQuant). Blocks all execution until cleared.
- G1 — Frequency scan: G_DATA must clear first; then: MVRV Zone 2 (> 2.0) historical episode count ≥ 10 distinct month-long periods from 2017–2026 Glassnode data; MVRV Zone 4 (< 1.1) ≥ 5 distinct episodes. If frequency insufficient → threshold adjustment per §Anti-Prim Gates.
- G2 — IS backtest: conditional WR delta test (Mann-Whitney U, p < 0.10 one-tailed) per MVRV zone against sister prim WR; N ≥ 15 zone-activation periods required; ≥ 2 sister prims showing WR delta ≥ 3pp required for zone unlock. Runs after G1.

All modes DRY_RUN until G_DATA cleared.

---

## Upgrade from Naive: Four Structural Changes

### 1. Three-Zone Gradient Architecture (replaces binary MVRV thresholds)

**Naive weakness**: binary on/off at MVRV 2.5/1.0 produced only ~5 distinct activation episodes over 9 years (Nov 2017, Nov 2021 for distribution; Dec 2018, Mar 2020, Nov 2022 for capitulation). n=5 is not testable; the signal provides no discriminative information during the ~70% of calendar days where MVRV is in the 1.1–2.5 neutral zone.

**Intermediate fix**: five-zone gradient using both raw MVRV and MVRV Z-score (Glassnode v1 endpoint: `mvrv_z_score`):

#### Zone definition and suppress/amplify weights

| Zone | Name | MVRV range | MVRV Z (approx) | Weight | SOPR required? | Expected frequency |
|------|------|-----------|-----------------|--------|----------------|-------------------|
| 1 | Neutral | [1.10, 2.00) | [−0.5, 2.5) | 1.00× | N/A | ~60–65% of days |
| 2 | Distribution elevated | [2.00, 2.50) | [2.5, 4.0) | 0.92× | No (light signal) | ~10–15% of days |
| 3 | Distribution extreme | ≥ 2.50 | ≥ 4.0 | 0.85× (full) / 0.90× (unconfirmed) | Yes (for full weight) | ~3–5% of days |
| 4 | Accumulation elevated | [1.00, 1.10) | (−1.5, −0.5) | 1.05× | No (light signal) | ~8–10% of days |
| 5 | Capitulation | < 1.00 | < −1.5 | 1.10× (confirmed) / 1.05× (unconfirmed) | Yes (for full weight) | ~1–3% of days |

**Zone 2 rationale**: MVRV > 2.0 marks the boundary where LTH cohort aggregate profit exceeds 100% — the point historically associated with increased distribution intent but before the extreme sell-wall of MVRV > 2.5. Suppression at 0.92× is light and does not meaningfully suppress profitable setups, but reflects that in a Zone 2 environment MR entries should be sized conservatively (LTH are net sellers at medium strength, creating headwinds for mean-reversion longs). Zone 2 does not require SOPR confirmation; the marginal cost of an incorrect Zone 2 signal (0.92× vs 1.00× → 8% size reduction) is low.

**Zone 3 SOPR confirmation rule**: Apply full 0.85× only when SOPR > 1.15 simultaneously (coins being sold at ≥ 15% profit on average — confirms LTH distribution is active, not just elevated unrealized gain). When MVRV in Zone 3 but SOPR ≤ 1.15 → apply 0.90× (intermediate suppression; MVRV suggests potential distribution, but SOPR does not yet confirm). Rationale: MVRV is a slow lagging indicator (changes weekly); SOPR is faster (changes daily based on which UTXOs are spent). Their alignment in Zone 3 provides material confirmation that distribution pressure is realised, not just latent.

**Zone 5 SOPR confirmation rule**: Apply full 1.10× only when SOPR < 0.98 (coins being sold at a loss on average — confirms forced capitulation selling, not just price weakness near cost basis). When MVRV in Zone 5 but SOPR ≥ 0.98 → apply 1.05× (light amplification; MVRV near capitulation but selling not yet at loss → cautious amplification only). This is the intermediate tier's primary safety gate for the capitulation amplification: the worst failure mode is amplifying during a slow grind down where price is near realized cap without the actual capitulation flush that makes MR entries reliable.

**Zone boundary stability**: during rapid MVRV movements (Zone 3 → Zone 1 within a single `bot_loop_start()` cycle), hold the current zone assignment for a minimum of 1 day before transitioning to neutral. Prevents false zone exit due to intraday MVRV sampling timing.

**MVRV Z-score as secondary metric** (when available from Glassnode Advanced): compute dynamically as `(mvrv - rolling_365d_mean_mvrv) / rolling_365d_std_mvrv`. Use Z-score thresholds from the table as confirmation; if raw MVRV and Z-score disagree on zone assignment (e.g., raw MVRV = 2.10 suggests Zone 2, but Z = 1.8 suggests Zone 1 due to elevated rolling mean), use the more conservative zone (Zone 1 in this case). Disagreement between raw MVRV and Z-score signals ambiguous market structure; conservative assignment is correct.

---

### 2. Duration Gate — 90-Day Suppress Window with Reset Protocol

**Naive weakness**: Limitation #3 from naive prim: "MVRV regime can persist for 3–12 months. Applying a 0.85× suppress weight for 9 months of a distribution phase would devastate system PnL." The 2021 bull run had MVRV > 2.5 from approximately January through November 2021 (~10 months). A naive prim with no duration limit would have suppressed all sister prim long entries at 0.85× for the entire 10 months — during a period when crypto was +250%.

**Intermediate fix**: sliding 90-day maximum suppress window with two-state machine.

```
SUPPRESS_STATE: {INACTIVE, ACTIVE_PHASE_1, ACTIVE_PHASE_2}

Transitions:
  INACTIVE → ACTIVE_PHASE_1: MVRV enters Zone 2 or Zone 3; record suppress_start_date = current_date.
  ACTIVE_PHASE_1 → ACTIVE_PHASE_2: (current_date − suppress_start_date) > 90 days; log DURATION_LIMIT_REACHED.
      Effect in PHASE_2: Zone 3 weight caps at 0.90× (same as unconfirmed Zone 3); Zone 2 weight caps at 0.95×.
      Interpretation: the 90-day suppression has been running; we are still in a distribution environment but
      the meta-signal's marginal value diminishes as the regime becomes consensus-known to all market participants.
  ACTIVE_PHASE_2 → ACTIVE_PHASE_1: Zone 3 → Zone 2 transition (MVRV dropped from extreme to elevated);
      reset window to current_date. The regime has partially relaxed; restart the 90d clock for Zone 2 phase.
  ACTIVE_PHASE_2 → INACTIVE: MVRV returns to Zone 1 (< 1.80) for ≥ 5 consecutive bot_loop_start() days;
      clear suppress_start_date. Full reset: next Zone 2/3 entry restarts from PHASE_1.
  ACTIVE_PHASE_1 → INACTIVE: MVRV drops to Zone 1 for ≥ 5 days (before 90d cap reached); clear suppress_start_date.
```

**Amplification (Zone 4/5) duration gate**: Amplification zones are shorter-lived — capitulation bottoms historically last days to weeks, not months. Maximum amplification window: 30 days (not 90). After 30 days of continuous Zone 4/5 amplification, cap at Zone 4 weight (1.05×) regardless of MVRV remaining below 1.10. Reset when MVRV returns to Zone 1 for ≥ 3 days.

**Rationale for asymmetric window (90d suppress vs 30d amplify)**: Distribution phases (LTH selling into strength) are structurally prolonged; LTH accumulate over years and distribute over months. Capitulation floors are structurally acute; forced selling exhausts quickly. The asymmetric window reflects this empirical difference in regime duration.

---

### 3. N_eff Redundancy Protocol — Axis 6 (CER) and Axis 7 (Funding)

**Naive weakness**: Limitation #6 from naive prim: "In capitulation regime (MVRV < 1.0), the capitulation-exhaustion-reversal prim (axis 6) is already designed for this scenario. If MVRV < 1.0 overlaps with CER signal conditions, axis 18 amplification and CER standalone entry may double-count." No rules were specified.

**Intermediate fix**: four co-occurrence rules with defined N_eff behaviour.

#### Rule 1: CER active + Zone 5 (deep capitulation)
When `cer_signal_active = 1` AND `onchain_zone = 5` simultaneously:
- Axis 18 amplification **DEACTIVATED** (weight = 1.00×, not 1.05/1.10×).
- Rationale: CER already models capitulation exhaustion via intraday price candle structure (pin bars, volume exhaustion). When CER fires AND MVRV < 1.0, the CER entry already expresses the best available edge. Axis 18's 1.10× on top of CER's standalone entry would double-count the same opportunity, over-sizing into a position already justified by CER alone.
- N_eff = 1 (CER and MVRV < 1.0 are observing the same causal event: forced seller exhaustion).
- **Exception: ultra-deep capitulation override**: If `mvrv < 0.80` (MVRV Z-score < −2.5 if available) → restore axis 18 amplification at 1.05× regardless of CER state. MVRV < 0.80 has occurred twice in 9 years (Dec 2018, Nov 2022) and represents structurally different depth from normal CER territory — the multi-year accumulation zone. At this depth, axis 18 provides non-redundant signal (CER will fire many times during the accumulation floor over weeks; axis 18 provides the regime context that these CER entries are in a historically reliable zone for multi-month recovery).

#### Rule 2: CER active + Zone 4 (accumulation elevated)
When `cer_signal_active = 1` AND `onchain_zone = 4`:
- Axis 18 amplification **MAINTAINED** at Zone 4 weight (1.05×).
- Rationale: Zone 4 (MVRV 1.00–1.10) is above the CER natural zone (MVRV < 1.0). CER fires on acute exhaustion candles at any MVRV level; Zone 4 is a mild accumulation signal. N_eff ≈ 1.5 (partial independence; CER responds to price structure, axis 18 responds to cost basis; same causal environment but different information channels).

#### Rule 3: Funding-rate-crowding-reversal (axis 7) active + Zone 2/3
When `funding_suppress_active = 1` AND `onchain_zone ∈ {2, 3}`:
- Combined suppress weight = axis_7_weight × axis_18_weight (multiplicative, not averaging).
- Example: funding prim at 0.88× × MVRV Zone 3 unconfirmed 0.90× = 0.79× combined.
- **Maximum combined suppression cap**: no combined weight below 0.72× from meta-signals (axis 6–18 combined). Prevents "effectively shutting off all entries" during compounding suppression regimes.
- N_eff estimate for G2: ρ(axis 7 funding crowding, axis 18 MVRV distribution) estimated 0.35–0.50. Partially correlated (both bearish at BTC cycle peaks) but mechanistically distinct: funding rate = derivatives carry cost driven by leveraged positioning (hours-to-days timescale); MVRV = on-chain realized cap ratio driven by LTH cost basis (weeks-to-months timescale). Document for sophisticated-tier ρ calibration.

#### Rule 4: Zone 3 (distribution extreme) + options-iv-skew put-skew mode (axis 15)
When `iv_skew_put_mode = 1` AND `onchain_zone = 3`:
- Axes are independent (options IV reflects institutional hedging demand; MVRV reflects on-chain LTH behaviour). Apply multiplicative: iv_skew weight × mvrv weight.
- These two axes represent the two most extreme bearish co-occurrence: institutional put-buying (axis 15) + LTH distribution (axis 18). Combined is the system's strongest sell-side regime signal. Log `MAX_BEARISH_META_SIGNAL` when both active simultaneously.

---

### 4. SOPR Dual-Confirmation Gate + API Integration

**Naive weakness**: The implementation skeleton had no SOPR data fetch; no rolling buffer for the 30-day exchange netflow SMA; no duration state tracking; API key header auth untested in Docker.

**Intermediate fix**: Complete `bot_loop_start()` implementation pattern with SOPR, rolling buffers, zone computation, and duration state machine.

**SOPR mechanism**: Spent Output Profit Ratio = sum(realized value of spent UTXOs) / sum(cost basis of spent UTXOs) for all transactions in a given day. SOPR > 1.0 = coins are spent at profit on average; SOPR < 1.0 = coins spent at loss. Introduced by Glassnode Research (Shirakashi, 2019). Key empirical observation: SOPR < 1.0 historically coincides with short-duration local capitulation events; SOPR returning above 1.0 after a sub-1.0 excursion historically signals exhaustion of capitulation selling (the "SOPR retest" pattern). At intermediate tier, SOPR is used only as a Zone 3/5 confirmation check — not as a standalone signal.

**API endpoints (Glassnode v1)**:
- MVRV: `https://api.glassnode.com/v1/metrics/market/mvrv`
- MVRV Z-score: `https://api.glassnode.com/v1/metrics/market/mvrv_z_score` *(Advanced tier)*
- SOPR: `https://api.glassnode.com/v1/metrics/indicators/sopr`
- Exchange inflows (entity-adjusted): `https://api.glassnode.com/v1/metrics/transactions/transfers_volume_to_exchanges_sum` *(Advanced tier; entity-adjusted version)*
- Exchange outflows (entity-adjusted): `https://api.glassnode.com/v1/metrics/transactions/transfers_volume_from_exchanges_sum`

**Implementation pattern** (YujiOnChainSupplyStrategy.py):

```python
import requests
from collections import deque
from datetime import datetime, timedelta

class YujiOnChainSupplyStrategy(IStrategy):

    _onchain_data: dict = {
        "mvrv": None,
        "mvrv_z": None,
        "sopr": None,
        "netflow_7d": None,
        "netflow_sma_30d": None,
        "zone": 1,
        "supply_weight": 1.0,
        "suppress_start_date": None,
        "suppress_state": "INACTIVE",  # INACTIVE | ACTIVE_PHASE_1 | ACTIVE_PHASE_2
        "amplify_start_date": None,
    }

    # Rolling buffers (daily observations, max 35 entries for 30d SMA)
    _netflow_inflow_buffer: deque = deque(maxlen=35)
    _netflow_outflow_buffer: deque = deque(maxlen=35)
    _last_fetch_date: str = ""

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        today = current_time.strftime("%Y-%m-%d")
        if today == self._last_fetch_date:
            return  # Only fetch once per day (on-chain data refreshes daily)
        self._last_fetch_date = today

        headers = {"X-Api-Key": self.config.get("glassnode_api_key", "")}
        params_btc = {"a": "BTC", "i": "24h", "f": "JSON"}

        try:
            # 1. Fetch MVRV
            r_mvrv = requests.get(
                "https://api.glassnode.com/v1/metrics/market/mvrv",
                headers=headers, params=params_btc, timeout=15
            )
            if r_mvrv.ok and r_mvrv.json():
                self._onchain_data["mvrv"] = r_mvrv.json()[-1].get("v")

            # 2. Fetch MVRV Z-score (Advanced tier; optional)
            r_z = requests.get(
                "https://api.glassnode.com/v1/metrics/market/mvrv_z_score",
                headers=headers, params=params_btc, timeout=15
            )
            if r_z.ok and r_z.json():
                self._onchain_data["mvrv_z"] = r_z.json()[-1].get("v")

            # 3. Fetch SOPR
            r_sopr = requests.get(
                "https://api.glassnode.com/v1/metrics/indicators/sopr",
                headers=headers, params=params_btc, timeout=15
            )
            if r_sopr.ok and r_sopr.json():
                self._onchain_data["sopr"] = r_sopr.json()[-1].get("v")

            # 4. Fetch entity-adjusted exchange flows
            r_in = requests.get(
                "https://api.glassnode.com/v1/metrics/transactions/transfers_volume_to_exchanges_sum",
                headers=headers, params=params_btc, timeout=15
            )
            r_out = requests.get(
                "https://api.glassnode.com/v1/metrics/transactions/transfers_volume_from_exchanges_sum",
                headers=headers, params=params_btc, timeout=15
            )
            if r_in.ok and r_out.ok and r_in.json() and r_out.json():
                daily_inflow = r_in.json()[-1].get("v", 0)
                daily_outflow = r_out.json()[-1].get("v", 0)
                daily_netflow = daily_inflow - daily_outflow  # positive = net inflow (supply shock)
                self._netflow_inflow_buffer.append(daily_inflow)
                self._netflow_outflow_buffer.append(daily_outflow)

                # 7-day cumulative net and 30-day SMA of absolute daily net flow
                net_7d = sum(list(self._netflow_inflow_buffer)[-7:]) - sum(list(self._netflow_outflow_buffer)[-7:])
                abs_daily_nets = [abs(i - o) for i, o in zip(list(self._netflow_inflow_buffer), list(self._netflow_outflow_buffer))]
                sma_30d = sum(abs_daily_nets) / max(len(abs_daily_nets), 1)
                self._onchain_data["netflow_7d"] = net_7d
                self._onchain_data["netflow_sma_30d"] = sma_30d

        except Exception as e:
            # On fetch failure: retain previous values; log but do not crash
            logger.warning(f"OnChainSupply fetch error: {e}. Retaining previous state.")
            return

        # 5. Compute zone
        self._compute_zone_and_weight(current_time)

    def _compute_zone_and_weight(self, current_time: datetime) -> None:
        mvrv = self._onchain_data.get("mvrv")
        mvrv_z = self._onchain_data.get("mvrv_z")
        sopr = self._onchain_data.get("sopr")
        netflow_7d = self._onchain_data.get("netflow_7d")
        netflow_sma_30d = self._onchain_data.get("netflow_sma_30d")

        if mvrv is None:
            self._onchain_data["zone"] = 1
            self._onchain_data["supply_weight"] = 1.0
            return

        # Determine raw MVRV zone
        if mvrv >= 2.50:
            zone = 3
        elif mvrv >= 2.00:
            zone = 2
        elif mvrv < 1.00:
            zone = 5
        elif mvrv < 1.10:
            zone = 4
        else:
            zone = 1

        # Z-score conservative override (if available)
        if mvrv_z is not None:
            if mvrv_z < 2.5 and zone == 2:
                zone = 1  # Z-score disagrees: use more conservative (neutral)
            if mvrv_z > 4.0 and zone == 2:
                zone = 3  # Z-score says extreme; escalate
            if mvrv_z > -0.5 and zone == 4:
                zone = 1  # Z-score says neutral; use conservative
            if mvrv_z < -1.5 and zone == 4:
                zone = 5  # Z-score says deep capitulation; escalate

        # SOPR confirmation for Zone 3 and Zone 5
        sopr_confirmed_distribution = (sopr is not None and sopr > 1.15)
        sopr_confirmed_capitulation = (sopr is not None and sopr < 0.98)

        # Netflow shock modifier
        netflow_multiplier = 1.0
        if netflow_sma_30d and netflow_sma_30d > 1e-9:
            shock_ratio = netflow_7d / netflow_sma_30d
            if shock_ratio > 2.0 and zone in (1, 2):
                netflow_multiplier = 0.95  # Additional light suppression: supply inflow shock
            elif shock_ratio < -2.0 and zone in (1, 4):
                netflow_multiplier = 1.02  # Additional light amplification: supply outflow (accumulation)

        # Base weight by zone
        if zone == 3:
            base_weight = 0.85 if sopr_confirmed_distribution else 0.90
        elif zone == 2:
            base_weight = 0.92
        elif zone == 5:
            base_weight = 1.10 if sopr_confirmed_capitulation else 1.05
        elif zone == 4:
            base_weight = 1.05
        else:
            base_weight = 1.0  # Zone 1 neutral

        # Apply netflow modifier
        weight = base_weight * netflow_multiplier

        # 6. Apply duration gate
        weight = self._apply_duration_gate(zone, weight, current_time)

        self._onchain_data["zone"] = zone
        self._onchain_data["supply_weight"] = weight

    def _apply_duration_gate(self, zone: int, weight: float, current_time: datetime) -> float:
        state = self._onchain_data["suppress_state"]
        suppress_start = self._onchain_data["suppress_start_date"]
        amplify_start = self._onchain_data["amplify_start_date"]

        # Distribution suppression state machine (zones 2 and 3)
        if zone in (2, 3):
            if state == "INACTIVE":
                self._onchain_data["suppress_state"] = "ACTIVE_PHASE_1"
                self._onchain_data["suppress_start_date"] = current_time
            elif state == "ACTIVE_PHASE_1" and suppress_start:
                days_active = (current_time - suppress_start).days
                if days_active > 90:
                    self._onchain_data["suppress_state"] = "ACTIVE_PHASE_2"
                    logger.info("OnChainSupply: DURATION_LIMIT_REACHED — capping Zone3 weight at 0.90×")
            elif state == "ACTIVE_PHASE_2":
                # Cap at Zone 2 weight level regardless of Zone 3
                if weight < 0.90:
                    weight = 0.90  # soft cap
                if zone == 2:
                    weight = max(weight, 0.95)  # Zone 2 after 90d softens further

        elif zone == 1:
            # Check if we've been neutral long enough to reset
            if state in ("ACTIVE_PHASE_1", "ACTIVE_PHASE_2"):
                if not hasattr(self, '_neutral_since'):
                    self._neutral_since = current_time
                elif (current_time - self._neutral_since).days >= 5:
                    self._onchain_data["suppress_state"] = "INACTIVE"
                    self._onchain_data["suppress_start_date"] = None
                    self._neutral_since = None
                    logger.info("OnChainSupply: suppress state reset to INACTIVE (5d neutral zone)")
            else:
                self._neutral_since = None

        # Amplification duration gate (zones 4 and 5, max 30 days)
        if zone in (4, 5):
            if amplify_start is None:
                self._onchain_data["amplify_start_date"] = current_time
            elif (current_time - amplify_start).days > 30:
                if weight > 1.05:
                    weight = 1.05  # cap at Zone 4 level after 30d
                    logger.info("OnChainSupply: AMPLIFY_DURATION_LIMIT — capping at 1.05× (30d amplification limit)")
        elif zone == 1 and amplify_start is not None:
            if (current_time - amplify_start).days >= 3:
                self._onchain_data["amplify_start_date"] = None

        # Global floor (no combined meta-signal weight below 0.72×)
        weight = max(weight, 0.72)

        return weight
```

**Sister prim integration** (in `populate_entry_trend()` of YujiRegimeStrategy.py):
```python
# Axis 18 (on-chain supply) weight application
if "onchain_supply_weight" in dataframe.columns:
    # Axis 6 (CER) co-occurrence rule: deactivate amplification if CER already active
    if "cer_signal" in dataframe.columns:
        cer_active = dataframe["cer_signal"] == 1
        zone_5 = dataframe["onchain_zone"] == 5
        ultra_deep = dataframe["onchain_mvrv"] < 0.80 if "onchain_mvrv" in dataframe.columns else pd.Series(False, index=dataframe.index)
        # Deactivate Zone 5 amplification when CER active (unless ultra-deep)
        cancel_amplify = cer_active & zone_5 & ~ultra_deep
        dataframe.loc[cancel_amplify, "onchain_supply_weight"] = 1.0

    # Apply weight to entry score
    dataframe["entry_score"] = dataframe["entry_score"] * dataframe["onchain_supply_weight"]

    # Cap combined meta-signal suppression floor at 0.72×
    dataframe["entry_score"] = dataframe["entry_score"].clip(lower=dataframe["entry_score_prefund"] * 0.72)
```

---

## Entry Conditions (Intermediate)

### Distribution regime (Zone 2/3) — suppress sister prim long entries

ALL of:
1. `onchain_zone ∈ {2, 3}` (MVRV ≥ 2.00; Zone 3 requires SOPR > 1.15 for full 0.85× weight)
2. `suppress_state ∈ {ACTIVE_PHASE_1, ACTIVE_PHASE_2}` (duration gate live)
3. Duration gate active: Phase 1 → full zone weight; Phase 2 → soft-capped weight
4. Axis 7 co-occurrence: if funding suppress also active, apply multiplicative (floor: 0.72×)
5. **No standalone entries** — modifies `onchain_supply_weight` multiplied into sister prim entry scores

### Accumulation regime (Zone 4/5) — amplify sister prim long entries

ALL of:
1. `onchain_zone ∈ {4, 5}` (MVRV < 1.10; Zone 5 requires SOPR < 0.98 for full 1.10× weight)
2. `amplify_state` active (< 30 days since Zone 4/5 entry)
3. Axis 6 (CER) co-occurrence rule: if CER active + Zone 5 AND NOT ultra-deep (MVRV < 0.80) → deactivate amplification (weight = 1.00×)
4. **No standalone entries** — amplifies sister prim entry scores via `onchain_supply_weight`

### Netflow shock modifier (independent of MVRV zone)

- Inflow shock (7d cumulative inflows > 2× 30d SMA of abs daily net) AND Zone 1/2 → additional 0.95×
- Outflow shock (7d cumulative outflows > 2× 30d SMA) AND Zone 1/4 → additional 1.02×
- Netflow modifier does NOT override Zone 3/5 weights; only applies in neutral or mild zones where MVRV alone provides no signal

---

## Conditions

- **Works when:** MVRV in Zone 2, 3, 4, or 5 (MVRV outside the 1.10–2.00 neutral zone); BTC/USDT primary (ETH/USDT with 0.80× confidence discount on all weights until ETH-specific G1 scan run); on-chain data refresh ≤ 24h delay; entity-adjusted exchange flows available (Glassnode Advanced or CryptoQuant); Glassnode API accessible.
- **Fails when:** MVRV in neutral zone (1.10–2.00, ~60–65% of days) — no signal; raw exchange flows used instead of entity-adjusted (false positive rate 30–50% for netflow signal); MVRV data stale > 24h; Glassnode API outage/rate limit; rapid MVRV oscillation across zone boundaries (duration gate prevents rapid zone switching, but confirms this represents ambiguous market structure rather than a stable regime); ETH MVRV < 1.00 without ETH-specific calibration (ETH ICO-era large holdings distort ETH realized cap; ETH MVRV is less anchored than BTC pre-2019).
- **Fail in combination:** SOPR unavailable (Glassnode Advanced required) → Zone 3/5 weights fall back to unconfirmed level (0.90×/1.05×) instead of confirmed (0.85×/1.10×); this degrades signal quality for extreme zones but does not block execution.
- **Best pairs:** BTC/USDT:USDT (primary); ETH/USDT:USDT (secondary — 0.80× confidence discount on modifiers until ETH G1 scan).
- **Best timeframe:** Daily MVRV/SOPR refresh via `bot_loop_start()`; `onchain_supply_weight` scalar broadcast to all 4h signal candles.

---

## Evidence (8 sources)

| Source | Finding | Relevance |
|--------|---------|-----------|
| Liu & Tsyvinski (2021, JF) | Unique addresses (on-chain native user metric) significantly predicts BTC returns; on-chain data contains non-redundant return-predictive information beyond price | Primary mechanism: on-chain data is a legitimate, peer-reviewed predictor channel; MVRV is a more refined on-chain metric |
| Foley, Karlsen & Putnins (2019, RFS) | On-chain transaction graph analysis reveals economic structure orthogonal to exchange price data | Establishes epistemological basis: on-chain data is structurally distinct from price/volume/derivatives |
| Griffin & Shams (2020, JF) | On-chain Tether flows to specific exchanges lead BTC price increases; exchange flow direction is a leading price indicator | Direct empirical anchor for the exchange net flow component; establishes exchange flow → price lead-lag |
| Cong, Li & Wang (2020, RFS) | On-chain adoption metrics drive long-run valuation equilibria; high speculative value relative to fundamental (user-based) value precedes reversals | MVRV distributional regimes are the empirical analogue of "speculative premium exceeding fundamental value" in this model |
| Bianchi (2020, JFQA) | Multiple on-chain metrics (hash rate, transaction activity, supply dynamics) have independent return-predictive power beyond price-based indicators | Scope confirmation: on-chain supply signals are peer-reviewed as having asset-class predictive validity |
| Woo (2021, CoinMetrics Research) | MVRV Z-score historically identifies cycle tops (Z > 7) and bottoms (Z < 0.1) with limited false positives 2013–2021 | Primary MVRV Z-score calibration anchor; practitioner-academic bridge; treated as hypothesis-generating |
| Shirakashi (2019, Glassnode Research) | SOPR < 1.0 coincides with capitulation selling phases; SOPR returning above 1.0 after sub-1.0 excursion historically marks seller exhaustion; empirically documented 2017–2019 | Direct anchor for SOPR dual-confirmation gate in Zone 3/5; practitioner-originated but mechanism is well-specified |
| Carter & Le Calvez (2018, CoinMetrics Research) | Realized Capitalization: weights each UTXO at its last-moved price, creating the blockchain-native aggregate cost basis; MVRV = market cap / realized cap introduced | Foundational definition of realized cap; MVRV ratio is directly derived from this metric; practitioner-academic bridge |

---

## Remaining Limitations

1. **G_DATA uncleared (CRITICAL BLOCKER):** Glassnode Advanced or CryptoQuant subscription not yet obtained. Entity-adjusted exchange flows require paid access. MVRV Z-score requires Glassnode Advanced. Without entity adjustment, netflow signal has 30–50% false positive rate from exchange-internal wallet moves. Until G_DATA cleared: all outputs DRY_RUN; `onchain_supply_weight` computed but not applied to live entry scores.

2. **G1 frequency scan pending:** Zone 2 historical frequency target (≥ 10 distinct month-long periods from 2017–2026 in Glassnode data) not yet verified. If frequency insufficient at MVRV > 2.00 → threshold may need lowering to MVRV > 1.80 for Zone 2. G1 runs after G_DATA is cleared.

3. **SOPR as naive practitioner metric:** SOPR is practitioner-originated (Glassnode Research blog, not peer-reviewed journal). The empirical observations underpinning the Zone 3/5 confirmation thresholds (SOPR > 1.15 for distribution, SOPR < 0.98 for capitulation) are calibrated from Woo/Glassnode historical charts, not a formal IS backtest. At intermediate tier this is acceptable; G2 IS backtest will empirically validate or refute the SOPR confirmation rule.

4. **ETH MVRV reliability (structural):** ETH has ICO-era holdings (large ETH balances created in 2014–2016 that were never moved) distorting the realized cap. Post-Merge supply mechanic changes (EIP-1559 burn, proof-of-stake) further alter the supply dynamics that MVRV was designed to capture. The 0.80× confidence discount on all ETH modifiers is a conservative heuristic; ETH-specific G1 scan required to determine whether ETH MVRV has any predictive validity at all.

5. **N_eff for simultaneous axis co-occurrence (ρ estimate, not measured):** The ρ(axis 18, axis 7 funding) estimate of 0.35–0.50 in distribution regime is theoretical, not empirically measured on Glassnode + Binance funding data. The multiplicative co-occurrence rule (0.85× × 0.88× = 0.75×) assumes enough independence to justify compounding. G2 sophisticated-tier gate must empirically verify ρ < 0.70 before the multiplicative rule is validated.

6. **Duration gate thresholds are structural estimates:** The 90-day suppress window and 30-day amplify window are based on the empirical observation that historical BTC distribution phases lasted 6–12 months and capitulation floors lasted days to weeks. These are calibrated from n=3–5 episodes. At sophisticated tier, the window lengths should be hyperopt parameters, not fixed values.

7. **No freqtrade strategy file (YujiOnChainSupplyStrategy.py) yet created:** The intermediate implementation pattern above specifies the complete architecture, but the file has not been written. Blocking for live signal generation.

---

## Implementation Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Zone architecture (3 supply + 2 neutral) | Specified — unimplemented | Five-zone gradient with MVRV + Z-score + SOPR confirmation |
| Duration gate state machine | Specified — unimplemented | 90d suppress / 30d amplify; INACTIVE/PHASE_1/PHASE_2 |
| SOPR fetch + confirmation | Specified — unimplemented | Glassnode v1 `/indicators/sopr`; Advanced tier |
| Entity-adjusted netflow buffers | Specified — unimplemented | `deque(maxlen=35)` rolling; entity-adjusted endpoint |
| Axis 6 (CER) co-occurrence rule | Specified — unimplemented | Deactivate Zone 5 amplify when CER active (except ultra-deep MVRV < 0.80) |
| Axis 7 (funding) multiplicative rule | Specified — unimplemented | Multiplicative compounding; floor 0.72× |
| ETH 0.80× discount | Specified — unimplemented | Apply to all ETH modifier outputs |
| YujiOnChainSupplyStrategy.py | Not created | Follow `bot_loop_start()` pattern from OI/LSR strategies |
| G_DATA gate | Uncleared | Glassnode Advanced subscription required |

**Signal reason string format (intermediate)**: `OCSD_I1: zone=Z mvrv=M sopr=S(conf|unconf|N/A) state=STATE weight=W netflow_ratio=R axis7_co=Y|N axis6_co=Y|N [DRY_RUN_G_DATA] [DURATION_CAP] [SOPR_UNAVAILABLE]`

---

## Refinement History

| Cycle | Level | Key Change |
|-------|-------|------------|
| 122 | naive | Initial prim — 18th freqtrade regime axis; binary MVRV thresholds (2.5/1.0); exchange net flow shock (2× SMA); 6 academic anchors; ~5 activation episodes in 9 years; no duration gate; no redundancy protocol; data blocker (Glassnode API key + entity-adjusted flows) |
| 123 | intermediate | (1) Five-zone gradient architecture (Zone 1–5; MVRV range 1.0–2.5+ with Z-score secondary; Zone 3/5 SOPR confirmation gate — 0.85×/1.10× confirmed, 0.90×/1.05× unconfirmed); (2) Duration gate state machine (90d suppress/30d amplify; INACTIVE/PHASE_1/PHASE_2; soft-cap in PHASE_2; 5-day neutral reset); (3) N_eff redundancy protocol (4 co-occurrence rules: CER deactivation in Zone 5 except MVRV<0.80, axis 7 multiplicative with 0.72× floor, axis 15 multiplicative MAX_BEARISH_META_SIGNAL log, Zone 4/CER maintained); (4) SOPR API integration + entity-adjusted flow endpoints; complete `bot_loop_start()` pattern with rolling buffers; 2 new academic anchors (Shirakashi 2019 Glassnode SOPR, Carter & Le Calvez 2018 realized cap); 8 sources total |

---

## Path to Sophisticated (four upgrades required)

1. **G_DATA + G1 cleared — frequency scan and threshold calibration**: Obtain Glassnode Advanced (entity-adjusted flows, MVRV Z-score, SOPR). Pull BTC MVRV history 2017–2026. Confirm Zone 2 (MVRV > 2.0) produces ≥ 10 distinct month-long episodes. If frequency < 10 → lower threshold to 1.80 and rescan. Confirm ETH MVRV predictive validity via ETH-specific G1 scan; adjust ETH confidence discount.

2. **G2 cleared — IS backtest per zone against sister prim WR**: Run conditional WR delta analysis: Mann-Whitney U, p < 0.10 one-tailed, per MVRV zone. N ≥ 15 zone-activation periods per zone. WR delta target: ≥ 3pp vs neutral zone for ≥ 2 sister prims. Empirically calibrate SOPR thresholds (1.15/0.98 are structural estimates). Validate ρ(axis 18, axis 7) < 0.70 empirically.

3. **Hyperopt parameter scan**: Duration gate windows (90d suppress, 30d amplify) converted to hyperopt parameters; Zone 2 threshold range [1.75, 2.25]; Zone 4 threshold range [0.90, 1.15]; SOPR confirmation thresholds [1.05, 1.25] for distribution, [0.95, 1.00] for capitulation. Plateau analysis: verify zone thresholds are at a plateau (not optimisation peak).

4. **YujiOnChainSupplyStrategy.py + scanner integration**: Write strategy file; integrate into freqtrade multi-signal architecture (YujiRegimeStrategy.py); verify `onchain_supply_weight` broadcasts correctly across all 4h candles; OOS validation (2025 holdout); YujiOnChainSupplyStrategy added to strategy rotation. Anti-prim B: empirically compute ρ(axis 18, axis 7) — if > 0.70, merge axis 18 into axis 7 extension rather than maintaining as independent axis.
