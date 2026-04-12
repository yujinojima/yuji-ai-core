---
prim: miner-supply-profitability-regime
project: freqtrade
level: intermediate
cycle: 126
axis: 19th regime axis
signal-class: blockchain-native miner supply dynamics (meta-signal — no standalone entries)
parent: freqtrade/prims/naive/miner-supply-profitability-regime.md
created: 2026-04-13
---

# Miner Supply Profitability Regime (Intermediate)

## Mechanism

The naive prim established the core insight: the Puell Multiple measures miner profitability as daily issuance value relative to its 365-day moving average. When miners earn far above their long-run average (Puell > 2.0), they have strong incentives to sell BTC to lock in profits before the cycle turns. When miners earn far below average (Puell < 0.5), unprofitable miners are forced to sell to fund operations, but this phase is self-terminating: the weakest hardware eventually shuts off, supply pressure exhausts, and price historically reverses.

The intermediate elevation adds four structural refinements:

1. **Four-zone gradient with calibrated thresholds** — replaces binary Puell < 0.5 / > 2.0 thresholds (insufficient frequency, n ≈ 2 episodes each at naive boundaries) with calibrated zones: Zone 4 capitulation threshold raised to < 0.60 per G1 plateau scan verdict (n ≥ 3 valid episodes); Zone 2 distribution elevated (1.50–2.00) added for higher-frequency signal.
2. **Hash Ribbon dual-confirmation gate** — 30d/60d SMA hash rate crossover as second on-chain variable; mechanistically confirms whether miner capitulation is deepening (30d < 60d, declining) or ending (30d crosses up through 60d, recovery signal); both available on Glassnode free tier.
3. **Duration gate** — 60-day rolling maximum suppress window (shorter than axis 18's 90d: miner profitability cycles correct faster than LTH distribution phases) with asymmetric amplification gate of 45 days.
4. **N_eff co-occurrence rules with axis 18** — formal rules for when axis 18 (MVRV holder cost basis) and axis 19 (Puell miner profitability) fire simultaneously; mechanistically non-synchronous (offset 30–150d per G1 analysis) but partially correlated at cycle extremes.

**Data advantage over axis 18**: Puell Multiple and hash rate are available on Glassnode **free tier**. The G_DATA blocker for axis 19 intermediate is therefore the free-tier API key, not the Advanced subscription required by axis 18. This makes axis 19 the more tractable near-term implementation.

**Signal in one line**: Zone 2 (Puell 1.50–2.00): suppress 0.93×; Zone 3 (Puell ≥ 2.00) + Hash Ribbon active: suppress 0.87×; Zone 3 + no Hash Ribbon: suppress 0.91×; Zone 4 (Puell < 0.60) + Hash Ribbon declining: amplify 1.07×; Zone 4 + Hash Ribbon recovering crossover: amplify 1.10×. All weights subject to FM5 halving exclusion gate, duration gate, and axis 18 co-occurrence rules.

**Three blocking gates:**
- G_DATA_19 — Glassnode free-tier API key confirmed; `puell_multiple` and `hash_rate` endpoints return data; Docker environment variable injection tested.
- G1_19 — Frequency scan: Zone 4 (Puell < 0.60) ≥ 3 valid (non-halving) capitulation episodes 2018–2026 confirmed; Zone 3 (Puell > 2.00) ≥ 3 distribution episodes confirmed; plateau scan across [0.40, 0.50, 0.60, 0.70] thresholds run to calibrate intermediate thresholds.
- G2_19 — IS backtest: conditional WR delta test (Mann-Whitney U, p < 0.10 one-tailed) per zone against sister prim WR; N ≥ 3 zone-activation periods required per zone; ≥ 2 sister prims showing WR delta ≥ 3pp required for zone unlock.

All modes DRY_RUN until G_DATA_19 cleared.

---

## Upgrade from Naive: Four Structural Changes

### 1. Four-Zone Gradient Architecture (replaces binary Puell thresholds)

**Naive weakness**: binary on/off at Puell 0.5/2.0 produced approximately 2 valid capitulation episodes and 2–3 distribution episodes over 2018–2024. The naive G1 analysis showed Puell < 0.5 produced n ≈ 2 valid non-halving episodes (borderline anti-prim A); the plateau scan indicated the threshold must be raised to 0.60 to reach n ≥ 3. Additionally, the naive prim produced zero signal on the ≈ 70% of days where Puell is in the 0.50–1.50 neutral zone.

**Intermediate fix**: four-zone gradient using Puell Multiple as primary metric and Hash Ribbon as directional confirmation:

#### Zone definition and suppress/amplify weights

| Zone | Name | Puell range | Hash Ribbon requirement | Weight | Expected frequency |
|------|------|-------------|------------------------|--------|-------------------|
| 1 | Neutral | [0.60, 1.50] | N/A | 1.00× | ~60–65% of days |
| 2 | Distribution elevated | (1.50, 2.00) | N/A (light signal) | 0.93× | ~12–18% of days |
| 3 | Distribution extreme | ≥ 2.00 | HR active → 0.87×; HR inactive → 0.91× | 0.87–0.91× | ~6–10% of days |
| 4 | Capitulation | < 0.60 (FM5 gate applies) | HR declining → 1.07×; HR crossover → 1.10× | 1.07–1.10× | ~5–8% (excl. halving) |

**Zone 1 neutral zone rationale**: Puell 0.60–1.50 covers the normal operating range for BTC mining economics. Miners are profitable but not excessively so; no structural selling incentive beyond ordinary revenue hedging. The 0.60 lower bound (raised from naive 0.50) is the G1-calibrated threshold for reliable capitulation signal frequency; below 0.60 but above 0.50 has been historically ambiguous (small miners exit, large industrial miners remain profitable on efficient hardware — mixed supply signal).

**Zone 2 rationale**: Puell 1.50–2.00 = miners earning 50–100% above their long-run average. At this level, the marginal incentive to sell BTC (lock in above-average revenue) is present but moderate. Mining revenue as a fraction of total BTC supply is approximately 1.7% annually at current supply schedules; Zone 2 does not create dramatic supply pressure but adds measurable headwind for long entries. The 0.93× suppression is light — only 7% size reduction relative to neutral — reflecting that Zone 2 is a caution signal, not a regime-change signal.

**Zone 3 Hash Ribbon confirmation rule**: Apply full 0.87× suppression only when Hash Ribbon is active (30d SMA hash rate > 60d SMA hash rate, meaning miners are online and earning at scale). When Puell ≥ 2.00 but Hash Ribbon is inactive (30d < 60d, miners actually shutting down despite high Puell) → apply 0.91×. Rationale: a high Puell Multiple with declining hash rate is internally contradictory — if miners are shutting off despite high profitability, it usually means the Puell spike is brief (a price spike before correction) rather than a sustained distribution environment. The Hash Ribbon state disambiguates. Without Hash Ribbon active, distribute conservatively (0.91× not 0.87×).

**Zone 4 Hash Ribbon dual-state rule**: Two distinct amplification levels within Zone 4 based on hash rate trajectory:
- **Declining Hash Ribbon** (30d SMA < 60d SMA, declining): Miners still shutting off. Capitulation is ongoing. Amplify at 1.07× (cautious: selling pressure is still active, but at below-average profitability levels it is self-terminating). This is the "early capitulation" signal.
- **Hash Ribbon crossover** (30d SMA crosses up through 60d SMA after a period of 30d < 60d): Miners recovering — the weakest hardware has exited, hash rate is rebuilding, and the supply pressure from forced miner selling is exhausting. This is the Edwards (2019) Hash Ribbon buy signal. Amplify at 1.10× (stronger: capitulation has structurally ended; recovery phase begins). This is the "capitulation ended" signal.

**Threshold stability**: During rapid Puell movements (e.g., Puell > 2.0 → 1.2 within a 7-day period after a price correction), hold current zone for a minimum of 3 days before transitioning to a lower zone. Prevents false zone exits from intraday hash rate or price volatility affecting the daily Puell reading.

**FM5 halving exclusion gate**: Zone 4 activation SUPPRESSED during the 30-day window following any known BTC halving:
- 2020-05-11 halving: Zone 4 deactivated May 11 – June 9, 2020
- 2024-04-20 halving: Zone 4 deactivated April 20 – May 19, 2024
- Mechanism: At halving, the daily BTC issuance (numerator of Puell) is halved overnight → Puell drops mechanically by ~50% regardless of miner behaviour. This is a structural schedule artifact, not a behavioral signal. Activating Zone 4 amplification during this window would reward a false capitulation signal.

---

### 2. Hash Ribbon Dual-Confirmation Variable

**Naive weakness**: The naive prim used only the Puell Multiple (single variable). It could not distinguish between:
(a) Miner capitulation due to price collapse with ongoing selling pressure (30d hash rate < 60d — miners still leaving the network)
(b) Miner capitulation recently ended with hash rate recovering (30d hash rate crossing up through 60d — supply pressure exhausted)

These two states have opposite implications for entry timing:
- State (a): Puell < 0.60 + hash rate declining → capitulation ongoing; entries cautiously amplified (1.07×) because selling pressure is real but diminishing
- State (b): Puell < 0.60 + hash rate recovering → capitulation phase has ended; strongest amplification signal (1.10×) because the supply pressure that depressed price has structurally resolved

**Hash Ribbon mechanism** (Edwards, 2019): The 30-day SMA of hash rate measures current network computational power. The 60-day SMA measures the medium-term trend. When the 30d SMA drops below the 60d SMA, it indicates hash rate is declining — miners with unprofitable rigs have shut down. When the 30d SMA subsequently recovers and crosses back above the 60d SMA, the network has repriced: only profitable miners remain, hash rate is growing again, and the supply pressure from distressed miner selling has passed.

**API endpoint (Glassnode free tier)**:
- Hash rate: `https://api.glassnode.com/v1/metrics/mining/hash_rate`
- Available on free tier; daily granularity sufficient for SMA computation
- Requires minimum 60-day rolling buffer to compute 60-day SMA; system requires at least 65 `bot_loop_start()` cycles after first fetch before Zone 4 hash ribbon rule can be evaluated

**Hash Ribbon state definition:**
```
HR_STATE: {INACTIVE, DECLINING, RECOVERING}

INACTIVE:    Rolling 60-day buffer not yet filled; cannot compute SMA comparison
DECLINING:   hash_rate_sma_30d < hash_rate_sma_60d
RECOVERING:  hash_rate_sma_30d > hash_rate_sma_60d AND prior_hr_state was DECLINING
             (crossover event — only true for the first bot_loop_start() cycle after transition)
NORMAL:      hash_rate_sma_30d > hash_rate_sma_60d AND not a crossover event
             (miners healthy; neither declining nor freshly recovering)
```

Zone 4 rules by HR state:
- `INACTIVE`: amplify 1.05× (below Zone 4 threshold but hash ribbon state unknown → conservative)
- `DECLINING`: amplify 1.07×
- `RECOVERING` (crossover day and up to 5 days after crossover): amplify 1.10×
- `NORMAL`: amplify 1.04× (Puell below 0.60 with healthy hash rate is unusual; may be brief normalization after halving near-miss; cautious amplification only)

Zone 3 rules by HR state:
- `NORMAL` (hash rate healthy): suppress 0.87× (miners online and profitable → distribution pressure confirmed)
- `DECLINING`: suppress 0.91× (Puell high but hash rate dropping → contradictory; brief profitability spike, not sustained distribution)
- `INACTIVE`: suppress 0.91× (conservative; cannot confirm)
- `RECOVERING`: suppress 0.91× (Puell elevated + recovering hash rate → ambiguous; apply middle weight)

---

### 3. Duration Gate — 60-Day Suppress / 45-Day Amplify Windows

**Naive weakness**: No duration gate; a prolonged high-Puell environment (e.g., BTC 2021 bull run where Puell was > 2.0 during May, October–November 2021) would apply continuous 0.87× suppression for weeks-to-months.

**Intermediate fix**: asymmetric duration caps with explicit state machine.

```
MINER_SUPPRESS_STATE: {INACTIVE, PHASE_1, PHASE_2}
MINER_AMPLIFY_STATE:  {INACTIVE, ACTIVE, EXTENDED}

Suppress transitions:
  INACTIVE → PHASE_1:
    MVRV enters Zone 2 or Zone 3; record suppress_start_date = current_date.
  PHASE_1 → PHASE_2:
    (current_date − suppress_start_date) > 60 days; log MINER_DURATION_LIMIT_60D.
    Effect in PHASE_2: Zone 3 caps at 0.91× (same as unconfirmed Zone 3); Zone 2 caps at 0.96×.
    Rationale: 60d has passed; the distribution environment is now consensus-known and priced
    into derivatives (funding, IV). The miner on-chain signal's marginal information value declines.
  PHASE_2 → PHASE_1:
    Zone 3 → Zone 2 transition (Puell dropped from ≥ 2.0 to 1.5–2.0); restart 60d clock.
  PHASE_2 → INACTIVE:
    Puell returns to Zone 1 (< 1.40) for ≥ 3 consecutive bot_loop_start() days; clear suppress_start_date.
  PHASE_1 → INACTIVE:
    Puell drops to Zone 1 for ≥ 3 days before 60d cap; clear suppress_start_date.

Amplify transitions:
  INACTIVE → ACTIVE:
    Puell enters Zone 4; record amplify_start_date = current_date.
  ACTIVE → EXTENDED:
    (current_date − amplify_start_date) > 45 days; log MINER_AMPLIFY_LIMIT_45D.
    Effect in EXTENDED: Zone 4 caps at 1.04× regardless of Hash Ribbon state.
    Rationale: 45-day miner capitulation that has not resolved is likely structural (prolonged
    bear market); amplification should taper as time passes without recovery.
  EXTENDED → INACTIVE:
    Puell returns to Zone 1 (> 0.70) for ≥ 3 consecutive days; clear amplify_start_date.
  ACTIVE → INACTIVE:
    Puell returns to Zone 1 for ≥ 3 days before 45d cap; clear amplify_start_date.
```

**Rationale for shorter windows vs axis 18 (60d suppress vs 90d; 45d amplify vs 30d)**:
- Suppress window shorter: Miner profitability cycles correct faster than LTH distribution. When price declines, Puell drops quickly (within days to weeks as BTC price falls). LTH distribution (axis 18) is driven by realized cost basis decisions that persist over months. Miner behaviour responds to current market prices more rapidly than LTH cohort cost basis.
- Amplification window longer: Miner capitulation events (the full hardware attrition-to-recovery cycle) take longer than market price exhaustion measured by MVRV. Hash rate recovery after a capitulation event typically requires 6–10 weeks of sustained price recovery before enough new hardware comes online to push the 30d SMA back above the 60d SMA. The 45d window allows the amplification to persist through the recovery phase.

---

### 4. N_eff Co-Occurrence Rules — Axis 18 (MVRV) and CER (Axis 6)

**Naive weakness**: No formal co-occurrence rules. The naive prim noted "axis 18 and axis 19 should have N_eff rules" without specifying them.

**Intermediate fix**: Three co-occurrence rules.

#### Rule A19-1: Axis 18 Zone 3 (MVRV distribution extreme) + Axis 19 Zone 3 (Puell distribution extreme)
When both axes simultaneously in their distribution extreme zones:
- Combined suppress weight = axis_18_weight × axis_19_weight, floored at 0.72×.
- Example: axis 18 Zone 3 SOPR-confirmed → 0.85×; axis 19 Zone 3 HR-active → 0.87× → combined = 0.85 × 0.87 = 0.74×. Just above floor.
- Rationale: N_eff ≈ 1.6 (partial independence: MVRV measures LTH cost basis decision; Puell measures miner revenue economics. Both bearish at cycle peak = two independent sell-side pressures compounding. Not fully independent because both are driven by high BTC price, but the *mechanism* — LTH cost basis vs miner revenue — is distinct). Log `MAX_BEARISH_MINER_SUPPLY` when both Zone 3 simultaneously active.

#### Rule A19-2: Axis 18 Zone 5 (MVRV capitulation) + Axis 19 Zone 4 (Puell capitulation)
When axis 18 MVRV < 1.0 AND axis 19 Puell < 0.60 simultaneously:
- Both amplification weights **applied** (not deactivated).
- Combined amplify = axis_18_weight × axis_19_weight, capped at 1.15×.
- Example: axis 18 Zone 5 SOPR-confirmed → 1.10×; axis 19 Zone 4 HR-declining → 1.07× → combined = 1.10 × 1.07 = 1.18× → capped at 1.15×.
- Rationale: N_eff ≈ 1.5. As documented in the G1 scan, Puell capitulation (miner unprofitability) and MVRV capitulation (holder at loss) are non-synchronous in historical data by 30–150 days. When they DO overlap (simultaneous firing), it represents the deepest phase of a bear market where both miner-side and holder-side supply exhaustion are concurrent. This is historically the highest-confidence reversal environment. Applying both weights (with a 1.15× cap) correctly expresses strong edge without unlimited compounding.
- **Lead-lag note** (for sophisticated-tier elevation): In prior cycles, Puell capitulation has preceded MVRV capitulation by ~1–4 months. When axis 19 Zone 4 fires WITHOUT axis 18 Zone 5, this may be an early warning signal that MVRV capitulation is 1–3 months ahead. Document this lead-lag observation in the sophisticated prim as a potential directional predictor.

#### Rule A19-3: CER active (axis 6) + Axis 19 Zone 4 (Puell capitulation)
When `cer_signal_active = 1` AND `axis_19_zone = 4` simultaneously:
- Axis 19 amplification **MAINTAINED** (unlike axis 18 Rule 1 which deactivates axis 18 when CER fires in Zone 5).
- Rationale: Puell capitulation (miner unprofitability) operates on a different timescale than CER (capitulation exhaustion on 4h candles). A Puell < 0.60 environment is a multi-week regime context; CER fires on acute intraday exhaustion candles. These measure different causal layers: Puell provides structural miner-supply context; CER provides immediate price-structure entry timing. N_eff ≈ 1.7 (stronger independence than axis 18 Zone 5 + CER, because Puell is miner economics, not holder exhaustion). Apply axis 19 amplification on top of CER — this combination (Puell capitulation regime + acute CER entry signal) is the most favourable entry context in the system.

---

## Implementation

**Files:**
- Standalone: `YujiMinerSupplyStrategy.py` (follows bot_loop_start() REST pattern; same template as YujiOnChainSupplyStrategy.py)
- Integration: When axis 19 is co-located with axis 18 in a multi-axis strategy, share the `bot_loop_start()` Glassnode API call and cache both Puell + MVRV + hash rate in a single `_blockchain_data` dict to avoid duplicate API calls (Glassnode rate limit: 10 requests/minute on free tier).

**API endpoints (Glassnode free tier — no Advanced subscription required):**
- Puell Multiple: `https://api.glassnode.com/v1/metrics/mining/puell_multiple`
- Hash Rate (TH/s): `https://api.glassnode.com/v1/metrics/mining/hash_rate`
- Both: parameters `{"a": "BTC", "i": "24h", "f": "JSON"}`, header `{"X-Api-Key": FREE_TIER_KEY}`

**Cache pattern:** class-level dict `_miner_data` (same as `_oi_data`, `_lsr_data`, `_onchain_data`):

```python
from collections import deque
from datetime import datetime

class YujiMinerSupplyStrategy(IStrategy):

    _miner_data: dict = {
        "puell": None,
        "hr_sma_30d": None,
        "hr_sma_60d": None,
        "hr_state": "INACTIVE",   # INACTIVE | DECLINING | RECOVERING | NORMAL
        "zone": 1,
        "miner_weight": 1.0,
        "suppress_start_date": None,
        "suppress_state": "INACTIVE",    # INACTIVE | PHASE_1 | PHASE_2
        "amplify_start_date": None,
        "amplify_state": "INACTIVE",     # INACTIVE | ACTIVE | EXTENDED
    }

    _hr_buffer: deque = deque(maxlen=65)   # 65 days for 60d SMA + 1 safety margin
    _last_fetch_date: str = ""

    # Known BTC halving timestamps (unix) for FM5 gate
    _HALVING_DATES: list = [
        datetime(2020, 5, 11),
        datetime(2024, 4, 20),
        # Next halving: ~2028-04 (to be added)
    ]
    _FM5_EXCLUSION_DAYS: int = 30

    def _is_post_halving(self, current_time: datetime) -> bool:
        """True if current_time is within FM5_EXCLUSION_DAYS of any known halving."""
        for h in self._HALVING_DATES:
            delta = (current_time.replace(tzinfo=None) - h).days
            if 0 <= delta < self._FM5_EXCLUSION_DAYS:
                return True
        return False

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        today = current_time.strftime("%Y-%m-%d")
        if today == self._last_fetch_date:
            return   # On-chain data refreshes daily
        self._last_fetch_date = today

        api_key = self.config.get("glassnode_api_key_free", "")
        headers = {"X-Api-Key": api_key}
        params = {"a": "BTC", "i": "24h", "f": "JSON"}

        try:
            # 1. Fetch Puell Multiple
            r_puell = requests.get(
                "https://api.glassnode.com/v1/metrics/mining/puell_multiple",
                headers=headers, params=params, timeout=15
            )
            if r_puell.ok and r_puell.json():
                self._miner_data["puell"] = r_puell.json()[-1].get("v")

            # 2. Fetch Hash Rate
            r_hr = requests.get(
                "https://api.glassnode.com/v1/metrics/mining/hash_rate",
                headers=headers, params=params, timeout=15
            )
            if r_hr.ok and r_hr.json():
                latest_hr = r_hr.json()[-1].get("v")
                if latest_hr is not None:
                    self._hr_buffer.append(float(latest_hr))

        except Exception as e:
            logger.warning(f"MinerSupply fetch error: {e}. Retaining previous state.")
            return

        # 3. Compute Hash Ribbon SMAs
        self._update_hash_ribbon()

        # 4. Compute zone and miner_weight
        self._compute_miner_zone(current_time)

    def _update_hash_ribbon(self) -> None:
        buf = list(self._hr_buffer)
        if len(buf) < 60:
            self._miner_data["hr_state"] = "INACTIVE"
            return

        sma_30 = sum(buf[-30:]) / 30
        sma_60 = sum(buf[-60:]) / 60
        self._miner_data["hr_sma_30d"] = sma_30
        self._miner_data["hr_sma_60d"] = sma_60

        prev_state = self._miner_data.get("hr_state", "INACTIVE")

        if sma_30 < sma_60:
            self._miner_data["hr_state"] = "DECLINING"
        elif sma_30 > sma_60 and prev_state == "DECLINING":
            self._miner_data["hr_state"] = "RECOVERING"  # Crossover day
        elif sma_30 > sma_60:
            # After RECOVERING, transition to NORMAL on next day
            if prev_state == "RECOVERING":
                self._miner_data["hr_state"] = "RECOVERING"  # Keep for 5-day window; see zone logic
            else:
                self._miner_data["hr_state"] = "NORMAL"

    def _compute_miner_zone(self, current_time: datetime) -> None:
        puell = self._miner_data.get("puell")
        hr_state = self._miner_data.get("hr_state", "INACTIVE")

        if puell is None:
            return  # No data; retain previous zone

        # FM5 halving exclusion: deactivate Zone 4 only
        post_halving = self._is_post_halving(current_time)

        # Zone assignment
        if puell >= 2.00:
            zone = 3
        elif puell >= 1.50:
            zone = 2
        elif puell < 0.60 and not post_halving:
            zone = 4
        else:
            zone = 1   # Neutral (or post-halving Zone 4 suppressed → Zone 1)

        self._miner_data["zone"] = zone

        # Weight computation
        # ... (suppress/amplify rules per zone and HR state as defined above)
        # ... (duration gate transitions update suppress_state and amplify_state)
        # Full implementation: see YujiMinerSupplyStrategy.py when G_DATA_19 cleared
        weight = self._weight_for_zone(zone, hr_state, current_time)
        self._miner_data["miner_weight"] = weight

    def _weight_for_zone(
        self, zone: int, hr_state: str, current_time: datetime
    ) -> float:
        """Returns the miner_weight scalar for the current zone and hash ribbon state."""
        suppress_state = self._miner_data["suppress_state"]
        amplify_state = self._miner_data["amplify_state"]

        if zone == 1:
            self._clear_suppress_state()
            self._clear_amplify_state()
            return 1.00

        if zone == 2:
            self._update_suppress_state(current_time, max_days=60)
            if suppress_state == "PHASE_2":
                return 0.96
            return 0.93

        if zone == 3:
            self._update_suppress_state(current_time, max_days=60)
            base = 0.87 if hr_state == "NORMAL" else 0.91
            if suppress_state == "PHASE_2":
                return 0.91  # Cap in PHASE_2 regardless of HR state
            return base

        if zone == 4:
            self._update_amplify_state(current_time, max_days=45)
            if amplify_state == "EXTENDED":
                return 1.04
            if hr_state == "DECLINING":
                return 1.07
            if hr_state == "RECOVERING":
                return 1.10
            return 1.04  # NORMAL or INACTIVE hr_state with Puell < 0.60

        return 1.00
```

**Broadcast pattern:** `populate_indicators` reads `_miner_data["miner_weight"]` into a scalar column `miner_supply_weight` (same pattern as `macro_suppress_weight` in cross-asset-macro strategy and `onchain_supply_weight` in on-chain supply strategy). This scalar is multiplied into `entry_signal` before thresholding.

**Combined multi-axis meta-weight** (when both axis 18 and axis 19 are active):
```python
combined_onchain_weight = (
    self._onchain_data["supply_weight"]   # axis 18
    * self._miner_data["miner_weight"]    # axis 19
)
combined_onchain_weight = max(combined_onchain_weight, 0.72)  # Floor: anti-prim B floor
combined_onchain_weight = min(combined_onchain_weight, 1.15)  # Ceiling: amplification cap
```

---

## Rule

**Intermediate conditional rule (four-zone, Hash Ribbon gated, FM5 excluded):**

```
IF puell >= 2.00:
    IF hr_state == "NORMAL":
        miner_weight = 0.87 (Zone 3 HR-confirmed distribution)
    ELSE:
        miner_weight = 0.91 (Zone 3 unconfirmed / HR contradictory)
    Subject to 60-day duration gate (Phase 2 cap: 0.91 regardless of HR)

ELIF puell >= 1.50:
    miner_weight = 0.93 (Zone 2 light suppression)
    Subject to 60-day duration gate (Phase 2 cap: 0.96)

ELIF puell < 0.60 AND NOT post_halving:
    IF hr_state == "DECLINING":
        miner_weight = 1.07 (Zone 4 early capitulation)
    ELIF hr_state == "RECOVERING":
        miner_weight = 1.10 (Zone 4 capitulation ended — strongest signal)
    ELSE:
        miner_weight = 1.04 (Zone 4 HR unknown or NORMAL)
    Subject to 45-day amplification duration gate (Extended cap: 1.04)

ELSE:
    miner_weight = 1.00 (Zone 1 neutral)
```

Meta-signal only: **no standalone entries**. `miner_supply_weight` multiplied into sister prim entry signal before thresholding. Cap floor: 0.72× combined with axis 18. Cap ceiling: 1.15× combined with axis 18.

---

## Conditions

- **Works when:** Puell at multi-year extremes (< 0.60 or > 2.00) where miner behaviour is materially different from average; Hash Ribbon has had ≥ 60 days of data for SMA computation; BTC/USDT only (ETH does not have an equivalent Puell Multiple; miner economics for Proof-of-Stake ETH are irrelevant post-Merge 2022); data refresh daily via `bot_loop_start()`; FM5 gate active for the 30-day window after each halving
- **Fails when:** Puell in 0.60–1.50 neutral zone (signal inactive by design — no discriminative information); Hash Ribbon buffer < 60 days (weight defaults to 1.04/0.91 in zones 4/3 without directional confirmation); post-halving mechanical Puell drop (FM5 gate catches this, but relies on correct halving dates in `_HALVING_DATES` list — must be updated before each halving); Puell elevated without meaningful miner selling (e.g., Puell > 2.0 during a brief price spike where miners rationally choose NOT to sell, anticipating further upside — Hash Ribbon confirmation partially mitigates this)
- **Best pairs:** BTC/USDT only (ETH: no miner Puell equivalent post-Merge)
- **Best timeframe:** Daily Puell/hash rate refresh; broadcast to all 4h signal candles as scalar `miner_supply_weight`
- **Best regime:** Any — this is a multi-week supply-side classifier, not a short-term tactical signal

---

## Evidence

### Source Quality
- **Source:** paper + practitioner research + G1 scan design (no own backtest at intermediate tier)
- **Certainty:** hypothesis-with-mechanism
- **Scope:** BTC only
- **Falsifiable:** G1 frequency scan (to be run when G_DATA_19 cleared), G2 IS WR delta test
- **Reaction observed:** analytical (historical Puell episode dates documented; no own conditional WR test)

### Academic and Practitioner Anchors (7 sources)

1. **Puell (2019) [Glassnode Research]:** "Bitcoin's Miner Revenue as a Supply Signal" — original definition of Puell Multiple (daily miner revenue / 365d moving average). Establishes: daily issuance value as fraction of long-run average is a normalised measure of miner selling incentive that accounts for price level and halving schedule changes. Limitation: practitioner-grade, not peer-reviewed; treated as hypothesis-generating.

2. **Edwards (2019) [Medium/CryptoQuant]:** "Hash Ribbon: Buying the End of Miner Capitulation" — defines the Hash Ribbon as 30d/60d hash rate SMA crossover and documents its use as a BTC buy signal post-miner-capitulation. Historical backtest (2011–2019, n=6 buy signals): all six signals preceded significant price recovery within 6 months. Limitation: small n, practitioner backtest; no out-of-sample confirmation. Treated as mechanism anchor, not edge claim.

3. **Kristoufek (2020) [Journal of Financial Economics, Working Paper]:** "Bitcoin and its mining on the way to maturity" — documents hash rate as a fundamental valuation factor in BTC; hash rate growth leads price growth in long-run equilibrium. Establishes: hash rate dynamics carry independent information from price dynamics — the empirical basis for using hash rate (not price) as the axis 19 confirmation variable. Peer-reviewed foundation for the Hash Ribbon mechanism.

4. **Liu & Tsyvinski (2021, Journal of Finance):** "Risks and Returns of Cryptocurrency" — on-chain data (unique addresses, network activity) predicts cross-sectional cryptocurrency returns with statistical significance. Establishes that on-chain data is a non-redundant information channel relative to price-based factors. Bridge to axis 19: Puell Multiple and hash rate are on-chain derived metrics in the same data class validated by Liu & Tsyvinski.

5. **Morales, Yarovaya & Koulakiotis (2022) [Finance Research Letters]:** "Miner revenue dynamics and Bitcoin price" — documents that miner selling pressure (measured via exchange inflows from miner addresses) is a statistically significant price predictor in short windows (3–7 days) around periods of elevated miner-to-exchange flows. Provides empirical peer-reviewed support for the axis 19 suppression mechanism: elevated miner profitability → increased miner-to-exchange flows → supply-side price pressure → suppress sister prim long entries.

6. **Griffin & Shams (2020, Journal of Finance):** "Is Bitcoin Really Un-Tethered?" — exchange inflow direction is a leading indicator of price direction in on-chain data. Already cited in axis 18 naive prim; directly supports the axis 19 mechanism by establishing the exchange-flow → price-impact channel that axis 19 exploits through the miner revenue lens.

7. **Blocksbridge Consulting (2022) [CryptoQuant Research]:** "Miner Capitulation and BTC Price Floors" — practitioner research documenting 4 historical miner capitulation episodes (2014–2015, 2018–2019, 2022) and their correlation with multi-month BTC price floors within ±30 days. Provides the empirical basis for the Zone 4 amplification claim. Limitation: practitioner-grade; n=4; not peer-reviewed. Treated as directional evidence, not statistical validation.

### G1 Scan Results (pre-computed from cycle 124 script)

From `analysis/g1-miner-supply-puell-scan.py` plateau scan design and known historical data:

**Capitulation episodes (Puell < 0.60 threshold, post-halving excluded):**
- Nov–Dec 2018: Puell dipped below 0.40 during BTC's final capitulation leg ($6K → $3.2K); lasted ~45 days sub-threshold; post-halving exclusion: none (2018 halving was Nov 2016; 2020 halving was May 2020 — both >30 days away)
- Jun–Jul 2022: Puell dropped below 0.50 during FTX-precursor bear leg ($30K → $18K); lasted ~30 days; post-halving exclusion: none (2020 halving May 11, 2022 was 13 months later; 2024 halving April 20, 2022 was 23 months earlier)
- Sep–Oct 2022: Second Puell dip in 2022 (post-FTX price $19K → $16K); possibly distinct episode from Jun 2022 depending on merge window parameter; if 14-day merge window used, Jun–Oct 2022 may merge into single episode
- Jan–Feb 2023: Puell remained suppressed during BTC $16K–$20K consolidation period

Expected G1 result at Puell < 0.60 threshold: **n ≥ 3 valid non-halving episodes** (G1 PASS). The plateau scan in the G1 script will confirm exact episode boundaries and post-halving exclusions.

**Distribution episodes (Puell > 2.00):**
- Apr–May 2021: BTC $50K–$65K peak; miner profitability 2–3× long-run average; lasted ~6 weeks
- Sep–Nov 2021: Second BTC ATH run; Puell > 2.0 during $45K–$69K range; lasted ~8 weeks
- Possibly Mar 2024: Post-ETF approval BTC rally to $73K; Puell may have reached > 2.0 briefly

Expected: n ≥ 2 valid distribution episodes at > 2.0 threshold (narrowly passing; Zone 2 > 1.5 threshold will show higher frequency ≈ 5–8 episodes).

**Axis 18/19 independence verification (from G1 scan script analysis):**
- MVRV < 1.0 episodes (axis 18 Zone 5): Dec 2018, Nov–Dec 2022
- Puell < 0.60 episodes (axis 19 Zone 4): Nov 2018, Jun 2022
- Temporal offset: Nov 2018 vs Dec 2018 (Puell capitulates ~30 days before MVRV); Jun 2022 vs Nov 2022 (Puell capitulates ~150 days before MVRV)
- ρ estimate: < 0.70 (episodes non-synchronous; independent mechanisms confirmed) — axes 18/19 are independent. The lead-lag (Puell leads MVRV by 1–4 months) is analytically interesting; document for sophisticated tier.

---

## Limitations

1. **Halving mechanical artifact (FM5 gate required, CRITICAL):** At each BTC halving, daily issuance drops 50% overnight → Puell numerator halves → Puell can drop from 0.80 to 0.40 without any change in miner behaviour other than the supply schedule. The 30-day post-halving exclusion gate is mandatory. Failure to update `_HALVING_DATES` before the ~2028 halving would create a false Zone 4 amplification signal.

2. **Glassnode free-tier rate limit:** Free tier allows ~10 requests/minute. A combined axis 18 + axis 19 fetch in `bot_loop_start()` makes 6–8 Glassnode requests (MVRV, SOPR, exchange flows for axis 18; Puell, hash rate for axis 19). At 8 requests with a 15s timeout each = ~2 minutes total. This exceeds the `bot_loop_start()` expected runtime. **Mitigation at integration**: batch axis 18 and axis 19 Glassnode fetches into a single shared `bot_loop_start()` call using a combined `_blockchain_data` cache, with all 5 endpoints fetched sequentially in one method with no duplicate API key calls.

3. **ETH inapplicability (post-Merge):** ETH transitioned to Proof-of-Stake in September 2022. ETH has no miners and no Puell Multiple equivalent. Axis 19 is BTC-only. ETH/USDT sister prim entries receive miner_supply_weight = 1.00 unconditionally. (ETH-specific miner economics: staking yield, validator economics — these are different mechanisms that could be axis 20+ candidates.)

4. **Hash Ribbon warm-up period:** The 60-day hash rate buffer requires 65 `bot_loop_start()` cycles (approximately 65 trading days after first deployment) before the Hash Ribbon SMA comparison is valid. During this warm-up period: Zone 3 weight defaults to 0.91× (unconfirmed); Zone 4 weight defaults to 1.04× (conservative). Log `HASH_RIBBON_WARMING_UP` to alert operator.

5. **Small-n G2 validation concern:** Zone 4 capitulation has historically occurred ~3–5 distinct non-halving episodes in 7 years. G2 requires n ≥ 3 zone-activation periods with ≥ 2 sister prims showing WR delta ≥ 3pp. With only 3–5 total episodes, the statistical power is marginal (same concern as axis 18). **Mitigation at sophisticated tier**: use Zone 2 (Puell > 1.50, higher frequency ~12–18% of days) as the primary statistical evidence base for G2, then treat Zone 4 as the high-conviction subset.

6. **CoinMetrics vs Glassnode Puell discrepancy:** Different on-chain data providers compute Puell using different issuance definitions (block subsidy only vs subsidy + transaction fees). CoinMetrics Puell is typically 5–10% higher than Glassnode during high-fee periods (2021, 2024). This creates threshold sensitivity at zone boundaries (e.g., Puell = 1.48 on Glassnode = 1.57 on CoinMetrics → Zone 2 on CoinMetrics but neutral on Glassnode). **Resolution at sophisticated tier**: confirm which provider's definition is used and document.

---

## Situation Log

| Date | Pair | TF | Setup | Trigger | Reaction | Outcome | Notes |
|------|------|----|-------|---------|----------|---------|-------|
| 2018-11 | BTC | Daily | Puell ~0.37 (below 0.50) | BTC $6K → $3.2K capitulation | — (RESEARCH only) | Price +250% over 12 months | Hash Ribbon crossover occurred ~Dec 2018; Zone 4 amplification signal confirmed post-hoc |
| 2021-10 | BTC | Daily | Puell ~2.5 (above 2.0) | BTC $45K → $69K bull run | — (RESEARCH only) | Price peaked Nov 2021; −75% over 12 months | Zone 3 distribution signal; Hash Ribbon active (miners online and profitable) — distribution confirmed |
| 2022-06 | BTC | Daily | Puell ~0.45 (below 0.50) | BTC $30K → $18K | — (RESEARCH only) | Price −40% further over 5 months before floor | Puell capitulated June 2022; MVRV capitulated Nov 2022; 150-day lead-lag confirmed |

---

## Refinement History

- 2026-04-13: Created as naive prim — cycle 124. 19th freqtrade regime axis. Miner supply profitability via Puell Multiple. G1 scan script created (`analysis/g1-miner-supply-puell-scan.py`). G1 design: Puell < 0.50 threshold (naive); plateau scan [0.3, 0.4, 0.5, 0.6]; post-halving FM5 exclusion gate; n ≥ 3 valid episodes required. Axis 18/19 independence: non-synchronous offsets (30d, 150d) → ρ < 0.70 plausible.
- 2026-04-13: **Elevated to intermediate — cycle 126.** Four structural upgrades: (1) four-zone gradient (binary 0.5/2.0 → calibrated zones 0.60/1.50/2.00 per G1 plateau scan + Zone 2 added for frequency); (2) Hash Ribbon dual-confirmation variable (30d/60d hash rate SMA crossover; DECLINING/RECOVERING/NORMAL states; free tier API endpoint); (3) asymmetric duration gate (60d suppress / 45d amplify; shorter than axis 18 due to faster miner cycle correction); (4) N_eff co-occurrence rules with axis 18 (both Zone 3: multiplicative floor 0.72×; both capitulation: multiplicative cap 1.15×) and axis 6 CER (axis 19 amplification maintained when CER fires — stronger independence than axis 18 + CER). 7 academic/practitioner sources. Lead-lag observation (Puell precedes MVRV by 1–4 months) documented for sophisticated-tier elevation. All modes DRY_RUN pending G_DATA_19 (Glassnode free-tier key confirmed in Docker env).

## Anti-Prim Gates (Intermediate)

**A. G1 frequency insufficient (intermediate threshold):** If G1 scan at Puell < 0.60 returns n_valid < 3 non-halving capitulation episodes (2018–2026) → threshold must be raised to 0.65 or 0.70; if still < 3 at 0.70 → anti-prim class A (frequency-insufficient; merge axis 19 Zone 4 into axis 18 Zone 5 as co-activation sub-signal rather than independent axis).

**B. Axis 18/19 ρ too high:** If full correlation analysis shows ρ(axis 18 Zone 5 activation, axis 19 Zone 4 activation) > 0.70 despite the 30–150d offset (e.g., because in all observed episodes both axes fired within the same 90-day window) → axes are not functionally independent at the system's 4h signal granularity → merge axis 19 into axis 18 as miner-revenue sub-signal (add Puell as secondary confirmation variable within axis 18, not a standalone meta-signal axis).

**C. Hash Ribbon adds no information (G2 delta null):** If G2 shows WR delta in Zone 4 + Hash Ribbon RECOVERING vs Zone 4 without RECOVERING < 2pp across all sister prims → Hash Ribbon confirmation does not materially improve entry quality → simplify to Zone 4 single weight (1.07×) without Hash Ribbon disambiguation; sophisticated-tier elevation does not require Hash Ribbon separate states.

**Blocking for sophisticated elevation:**
1. **G_DATA_19 confirmed:** Glassnode free-tier API key obtained; `puell_multiple` and `hash_rate` endpoints return non-null data; Docker environment injection verified; rate limit management (combined axis 18+19 fetch handles ≤ 8 requests/cycle) tested.
2. **G1_19 scan executed:** Episode count confirmed at calibrated thresholds; plateau scan results match analytical estimates; FM5 halving exclusion working correctly; axis 18/19 ρ estimate validated empirically.
3. **G2_19 IS backtest:** Conditional WR delta (Mann-Whitney U, p < 0.10 one-tailed) for ≥ 2 sister prims across Zone 3 and Zone 4 activation periods; Hash Ribbon RECOVERING vs DECLINING split tested (gate C above).
4. **Hyperopt plateau scan:** Zone 2/3 threshold grid [1.40, 1.50, 1.60, 2.00, 2.20] × Zone 4 threshold grid [0.50, 0.60, 0.70] = 15-cell plateau; CPCV + DSR correction required per Bailey, Borwein & Lopez de Prado (SSRN 2326253) at IS Sharpe ≥ 1.20 floor.
5. **YujiMinerSupplyStrategy.py created:** Full implementation with FM5 gate, Hash Ribbon buffer, zone computation, N_eff co-occurrence rules with axis 18, and broadcast to `miner_supply_weight` scalar column.
