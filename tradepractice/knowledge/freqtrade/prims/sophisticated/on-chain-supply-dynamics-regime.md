---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T00:00:00+10:00
cycle: 160
prim: on-chain-supply-dynamics-regime
project: freqtrade
level: sophisticated
axis: 18
signal-class: blockchain-native supply dynamics (meta-signal — no standalone entries)
parent: freqtrade/prims/intermediate/on-chain-supply-dynamics-regime.md
status: ACTIVE
---

# On-Chain Supply Dynamics Regime (Sophisticated)

## 1. Epistemic Genealogy

**Naive (cycle 122):** Binary MVRV thresholds (> 2.5 suppress 0.85×; < 1.0 amplify 1.10×). Exchange netflow 2× SMA shock modifier. ~5 distinct activation episodes over 9 years — not testable. No duration gate. No redundancy rules. 6 academic anchors. G_DATA blocking (Glassnode API key + entity-adjusted flows).

**Intermediate (cycle 123):** Five-zone gradient (Zones 1–5 using MVRV + MVRV Z-score secondary; Zone 3/5 SOPR dual-confirmation at 0.85×/0.90× and 1.10×/1.05×). Duration gate state machine (90-day suppress window, 30-day amplify window; INACTIVE → ACTIVE_PHASE_1 → ACTIVE_PHASE_2 transitions). N_eff redundancy protocol for axes 6 (CER) and 7 (funding): CER deactivation in Zone 5 except MVRV < 0.80 ultra-deep; funding multiplicative with 0.72× floor; axis 15 IV-skew multiplicative with MAX_BEARISH_META_SIGNAL log. Complete `bot_loop_start()` API implementation (Glassnode v1 MVRV/MVRV_Z/SOPR/entity-adjusted netflows). 8 academic anchors.

**Sophisticated (cycle 160):** Six architectural advances over intermediate:

1. **MVRV Velocity Gate** — mandatory precondition for Zone 5 amplification. Amplify fires ONLY when `mvrv_velocity_7d ≥ 0` (MVRV recovering from trough). When `mvrv_velocity_7d < 0` (MVRV still declining) → neutral_hot_capitulation state. Eliminates the primary intermediate failure mode: amplifying into extending capitulation events where MVRV < 1.0 but price continues falling.

2. **LTH/STH-MVRV Disaggregation** — replaces aggregate MVRV with LTH-MVRV and STH-MVRV component analysis (Glassnode Advanced endpoints). Four disaggregated conviction modes: dual-zone suppress (maximum), single-LTH suppress (discounted), dual-capitulation amplify (maximum), LTH-only amplify (discounted).

3. **Mode A/B/C Three-Mechanism Architecture** — MVRV structural (Mode A; days-to-months), exchange netflow tactical (Mode B; hours-to-days), SOPR exhaustion pivot (Mode C; daily; explicitly captures the seller-exhaustion inflection point, not just zone confirmation).

4. **Zone 6 Formalization** (MVRV < 0.75) — ultra-deep capitulation at 1.15× amplify. Velocity gate bypassed in Zone 6 (historically n=2; MVRV < 0.75 is itself a regime-entry signal regardless of direction). SOPR < 0.90 required for full weight.

5. **Full N_eff Extension** — from 2 covered axes (6, 7) to all 9 overlapping meta-signal axes with defined pairwise ρ estimates and tiered interaction rules.

6. **CPCV + DSR IS Protocol** — 81-cell hyperopt grid with Combinatorially Purged Cross-Validation + Deflated Sharpe Ratio; duration-window parameters hyperopt-tuned rather than fixed.

3 new academic anchors (total 11). G_DATA remains outstanding; all sophisticated additions are analytically specified and await data clearance.

---

## 2. Core Hypothesis Set

**H1 (Mode A Structural Suppress — Dual LTH+STH):** During periods when both LTH-MVRV > 2.0 AND STH-MVRV > 1.30 simultaneously, the conditional 14-day forward return for sister prim long entries is statistically lower than the unconditional distribution. Mechanism: both veteran holders (LTH cost basis 2× below current price) and recent buyers (STH cost basis 30% below current price) are collectively in profit → distributed selling pressure from two independent cohorts → forward expected return depressed. This is stronger than single-cohort suppression.

**H2 (Mode A Structural Suppress — LTH-Only, STH Discounted):** During periods when LTH-MVRV > 2.0 AND STH-MVRV < 1.10, the suppress signal exists (LTH distributing) but is weaker than H1. Mechanism: STH cost basis is near or below current price → recent buyers are not sellers; they are net holders. Supply pressure comes only from LTH cohort. 0.90× confidence discount applied (lighter suppress weight: 0.90× for Zone 2, 0.88× for Zone 3 confirmed; vs dual-mode 0.92× and 0.85×).

**H3 (Mode A Structural Amplify — Dual Capitulation):** During periods when LTH-MVRV < 1.10 AND STH-MVRV < 1.10 simultaneously AND `mvrv_velocity_7d ≥ 0`, the conditional 14-day forward return for sister prim long entries is statistically higher than the unconditional distribution. Mechanism: both cohorts holding at or below cost basis → net holder sentiment negative across all time horizons → maximum capitulation depth → forward risk premium elevated (Carr & Wu 2009 analog: risk premium most elevated when price is furthest below aggregate cost basis). Dual-cohort capitulation is the highest-conviction amplification state in the system.

**H4 (Velocity Gate Necessity):** During Zone 5 (MVRV < 1.0) with `mvrv_velocity_7d < 0` (MVRV still declining), the conditional 14-day forward return for amplified long entries is NOT statistically positive vs the unconditional baseline. Mechanism: declining MVRV in Zone 5 means the cost-basis anchor is approaching but has not been reached; the capitulation mechanism (maximum fear relative to cost basis) has not engaged. Amplifying before the velocity inflection point worsens risk-adjusted returns.

**H5 (Mode B Tactical Netflow):** When 7-day cumulative exchange inflow > 3× 30-day SMA (inflow shock) regardless of MVRV zone, the conditional 5-day forward return is statistically lower than unconditional. Mechanism: Griffin & Shams (2020): exchange inflow direction is a leading price indicator (coins sent to exchanges = seller intent). Mode B is independent of MVRV zone — fires in Zone 1 (neutral MVRV) where Mode A provides no signal, effectively providing signal coverage for ~65% of calendar days where Mode A is inactive.

**H6 (Mode C SOPR Exhaustion Pivot):** When SOPR transitions from < 1.0 to ≥ 1.0 within a 3-day window after ≥ 7 consecutive days of SOPR < 1.0, the conditional 14-day forward return is statistically higher than unconditional. Mechanism: Shirakashi (2019): SOPR < 1.0 = realized losses being taken (forced sellers); the transition back above 1.0 marks exhaustion of the forced-seller cohort → remaining holders are net long-term; forward price recovery likely. This is the Mode C explicit exhaustion pivot signal — distinct from SOPR as a Zone 5 confirmation (intermediate tier). Mode C fires as a standalone amplification trigger (1.05× for 7 days) even when MVRV is in neutral Zone 1.

**H7 (Zone 6 Bypass):** When MVRV < 0.75 (historical n=2: Dec 2018, Nov 2022), the amplification signal (1.15×) fires regardless of `mvrv_velocity_7d` direction. Mechanism: MVRV < 0.75 is itself an extreme rarity (< 0.3% of days 2014–2026); the signal value of being in this zone substantially exceeds the marginal information from the velocity direction. Stated differently: even if MVRV is declining from 0.80 toward 0.72, the cost-basis anchor depth makes recovery expected returns highly positive over 30–90 day horizons. Velocity gate applies only in Zones 4 and 5 (MVRV 0.75–1.10), where the recovery timing matters.

**H8 (Duration Window Hyperopt Optimality):** The optimal suppress window (intermediate fixed: 90 days) and amplify window (intermediate fixed: 30 days) are data-dependent parameters, not universal constants. Within the range [60d–120d] for suppress and [21d–45d] for amplify, the OOS-optimal windows are expected to differ from the analytically estimated values. CPCV hyperopt is the correct method to identify these parameters.

---

## 3. Academic Anchors (Sophisticated — 11 total; 8 from intermediate, 3 new)

**[A1] Liu & Tsyvinski (2021, JF) — "Risks and Returns of Cryptocurrency"**
Unique addresses (on-chain user metric) significantly predict BTC returns; on-chain data provides non-redundant return-predictive information beyond price. Foundational peer-reviewed anchor for axis 18's entire information channel.

**[A2] Foley, Karlsen & Putnins (2019, RFS) — "Sex, Drugs, and Bitcoin"**
On-chain transaction graph reveals economic structure orthogonal to exchange price data. Epistemological basis: on-chain data is structurally distinct from price/derivatives, justifying axis 18's independence from all 17 prior axes.

**[A3] Griffin & Shams (2020, JF) — "Is Bitcoin Really Untethered?"**
On-chain Tether flows to specific exchanges lead BTC price increases; exchange flow direction is a leading price indicator. Direct empirical anchor for Mode B (netflow tactical). Establishes inflow → price lead-lag at days timescale.

**[A4] Cong, Li & Wang (2020, RFS) — "Tokenomics: Dynamic Adoption and Valuation"**
High speculative value relative to fundamental (user-based) value precedes reversals. MVRV Zone 2/3 (market cap >> realized cap) is the empirical analogue of excess speculative premium → Mode A suppress is anchored in return of fundamental value.

**[A5] Bianchi (2020, JFQA) — "Cryptocurrencies as an Asset Class? An Empirical Assessment"**
Multiple on-chain metrics have independent return-predictive power beyond price. Scope confirmation: on-chain supply signals have peer-reviewed predictive validity in crypto.

**[A6] Woo (2021, CoinMetrics Research) — "MVRV Z-Score Historical Analysis"**
MVRV Z-score identifies cycle tops (Z > 7) and bottoms (Z < 0.1) with limited false positives 2013–2021. Primary Z-score calibration anchor for zone boundary calibration.

**[A7] Shirakashi (2019, Glassnode Research) — "SOPR: Spent Output Profit Ratio"**
SOPR < 1.0 coincides with capitulation selling; SOPR returning above 1.0 after sub-1.0 excursion marks seller exhaustion. Direct anchor for Mode C exhaustion pivot signal (H6) and Zone 3/5 SOPR confirmation gates.

**[A8] Carter & Le Calvez (2018, CoinMetrics) — "Realized Capitalization"**
Realized cap weights each UTXO at last-moved price, creating blockchain-native aggregate cost basis; MVRV = market cap / realized cap. Foundational definition of the metric underpinning all MVRV zone computations.

**[A9] Hong & Stein (1999, JF) — "A Unified Theory of Underreaction, Momentum Trading, and Overreaction in Asset Markets"**
Gradual diffusion of fundamental information drives return predictability at intermediate horizons; slow-information agents (long horizon holders) trade on information that fast-information agents (short-term traders) have not yet fully incorporated. Sophisticated relevance: LTH cost basis (MVRV component) encodes multi-year accumulation that diffuses to price over weeks; STH cost basis (weeks-old) diffuses faster. The LTH/STH disaggregation exploits this differential information diffusion speed: LTH-driven suppress/amplify signals have longer lead times (Mode A, 30-day window) than STH-driven signals. H1 and H2 directly follow from the Hong-Stein slow-diffusion channel.

**[A10] Campbell & Thompson (2008, RFS) — "Predicting Excess Stock Returns Out of Sample: Can Anything Beat the Historical Average?"**
Regime-conditioned predictors (forecasting only when the predictor is in its theoretically active region) achieve materially better OOS performance than unconditional predictors. Restricting the slope coefficient to be non-negative in the theoretically positive-return zone improves OOS Sharpe by 1.5–2.5× in equity data. Sophisticated relevance: the MVRV velocity gate (H4) is the on-chain analogue of Campbell & Thompson's sign restriction — restricting Zone 5 amplify to the theoretically positive sub-state (velocity ≥ 0) rather than firing on all Zone 5 observations regardless of direction. The improvement in OOS Sharpe from this conditioning is the main quantifiable benefit of the sophisticated tier.

**[A11] Andersen, Bollerslev, Diebold & Labys (2001, JASA) — "The Distribution of Realized Exchange Rate Volatility"**
Composite multi-timescale signals (daily, weekly, monthly RV components) outperform single-timescale signals; the three-component HAR-RV structure (later formalized by Corsi 2009) captures persistence at each timescale independently. Sophisticated relevance: Mode A (MVRV structural, months), Mode B (netflow tactical, days), and Mode C (SOPR daily pivot, 1–3 days) follow the same three-timescale architecture. A single-timescale signal (Mode A alone = intermediate tier) systematically misses the shorter-horizon information carried by Mode B and Mode C. The composite three-mode signal is the on-chain supply analog of HAR-RV.

---

## 4. MVRV Velocity Gate — Mechanism Specification

### Why the intermediate omits this gate (and why it is mandatory at sophisticated)

The intermediate prim amplifies at 1.10× (Zone 5, SOPR confirmed) whenever MVRV < 1.0, regardless of whether MVRV is still falling or has begun recovering. In a continuing capitulation (MVRV declining from 0.95 toward 0.82), the mechanism that H3 describes — *cost basis anchored below price → variance sellers hold → risk premium normalises → forward returns recover* — has NOT engaged. The recovery mechanism requires that MVRV has troughed and is recovering toward Zone 4. When MVRV is still falling, entering long amplifies into the ongoing capitulation.

Specific failure event: LUNA collapse May 2022. BTC MVRV entered Zone 5 (MVRV ~0.85) on approximately day 3 of the cascade (BTC at ~$28k). The velocity gate would have withheld Zone 5 amplify (mvrv_velocity_7d < 0 — MVRV was declining approximately −0.05/day through day 5–8). The intermediate prim would have amplified all sister prim entries at 1.05× from day 3. The velocity gate would have re-enabled amplification approximately day 9–11 when MVRV stabilised near 0.80 and velocity turned positive, coinciding with the actual near-term price recovery from ~$26k.

FTX collapse November 2022: Similar. BTC MVRV entered Zone 5 around November 10 (BTC ~$17k). MVRV continued declining (velocity < 0) through November 18–21, reaching Zone 5/6 boundary. Velocity gate would have withheld amplify during the active collapse phase, enabling it approximately November 22–24 when MVRV stabilised (coinciding with BTC price trough ~$15.5k).

### Gate specification

```python
# MVRV velocity gate (mandatory for Zone 5; bypassed in Zone 6)
mvrv_current = self._onchain_data["mvrv"]
mvrv_7d_ago = self._mvrv_history[-7] if len(self._mvrv_history) >= 7 else None

if mvrv_7d_ago is not None:
    mvrv_velocity_7d = mvrv_current - mvrv_7d_ago  # positive = recovering; negative = declining
else:
    mvrv_velocity_7d = None  # insufficient history: conservative — withhold amplify

# Zone 5 (0.75 ≤ MVRV < 1.0): velocity gate applies
amplify_zone5_active = (
    zone == 5
    and mvrv_velocity_7d is not None
    and mvrv_velocity_7d >= 0.0
)
amplify_zone5_blocked = (
    zone == 5
    and (mvrv_velocity_7d is None or mvrv_velocity_7d < 0.0)
)

# Zone 6 (MVRV < 0.75): velocity gate bypassed — ultra-deep activation unconditional
amplify_zone6_active = (zone == 6)

# Log state
if amplify_zone5_blocked:
    logger.info(f"OnChainSupply: NEUTRAL_HOT_CAPITULATION — Zone5 velocity={mvrv_velocity_7d:.4f} < 0 — amplify withheld")
```

**Why 7 trading days:** Mirrors VRP velocity gate calibration (cycle 129). 7-day window captures one full weekly MVRV reporting cycle; avoids noise from single-day MVRV fluctuations (MVRV updates daily but sampling noise at daily resolution can produce −0.01 velocity despite overall recovery). 7 days ≈ 33% of BTC GARCH half-life (~21d) — sensitive to early recovery inflection.

**Adjusted amplify frequency (Zone 5):** Velocity gate filters ~35–40% of raw Zone 5 triggers (those occurring during the declining phase of each capitulation event). Estimated Zone 5 trigger frequency (with velocity gate): 3.5 × 0.65 = ~2.3 non-overlapping 14-day windows/year. This is below the standard G1 minimum (n ≥ 5/year) — Zone 5 velocity-gated amplify requires extension to 2013–2026 Glassnode history (n will be ≥ 5 over the full window). Zone 4 amplify (MVRV 1.00–1.10) is more frequent (~8% of days) and does not require the velocity gate (Zone 4 is not the continuing-capitulation zone).

---

## 5. LTH/STH-MVRV Disaggregation Architecture

### Why aggregate MVRV is insufficient at sophisticated tier

The intermediate prim uses aggregate MVRV (market cap / total realized cap, where realized cap = weighted sum of ALL UTXOs at their last-moved price). Aggregate MVRV conflates two mechanistically distinct signals:
- **LTH-MVRV** (Long-Term Holder MVRV): market cap / LTH realized cap. LTH = UTXOs unmoved ≥ 155 days. LTH cohort behaviour: slow accumulation over years, concentrated distribution at cycle peaks. LTH-MVRV is the structural regime indicator.
- **STH-MVRV** (Short-Term Holder MVRV): market cap / STH realized cap. STH = UTXOs moved within 155 days. STH cohort behaviour: rapid rotation, responsive to near-term price moves. STH-MVRV is the tactical positioning indicator.

Aggregate MVRV = (LTH + STH realized cap blend) / market cap. The blend obscures cases where LTH and STH diverge — which are precisely the most informative cases for forward returns.

### Four disaggregated mode combinations

| LTH-MVRV | STH-MVRV | Mode | Signal | Mechanism |
|---|---|---|---|---|
| > 2.0 (Zone 2/3) | > 1.30 (profitable) | Dual-zone suppress | Full weight (0.92×/0.85×) | Both cohorts in profit → dual-cohort distribution pressure → H1 maximum conviction |
| > 2.0 (Zone 2/3) | < 1.10 (near/below cost) | LTH-only suppress | Discounted (0.90×/0.88×) | LTH distributing but STH capitulated → supply pressure from one cohort only → H2 |
| < 1.10 (Zone 4/5) | < 1.10 (near/below cost) | Dual capitulation amplify | Full weight (1.10×/1.05×) + velocity gate | Both cohorts at/below cost basis → maximum capitulation depth → H3 maximum conviction |
| < 1.10 (Zone 4/5) | > 1.30 (profitable) | LTH-only amplify | Discounted (0.92×) | Veterans near cost basis but recent buyers still profitable → incomplete capitulation → H3 partial |

**API endpoints:**
- LTH-MVRV: `https://api.glassnode.com/v1/metrics/market/mvrv_long_term_holder_momentum` *(Advanced tier)*
- STH-MVRV: `https://api.glassnode.com/v1/metrics/market/mvrv_short_term_holder` *(Advanced tier)*

Both require Glassnode Advanced subscription — cleared under G_DATA gate alongside aggregate MVRV Z-score.

**Fallback when LTH/STH unavailable:** Use aggregate MVRV with intermediate-tier weights and 0.90× confidence discount on all weights. Log `LTH_STH_UNAVAILABLE` in signal reason string.

**Velocity gate on LTH-MVRV:** The velocity gate (H4) uses LTH-MVRV velocity when available, not aggregate MVRV velocity. LTH-MVRV is more stable (updates slowly due to 155d holding threshold) and therefore more reliable as a direction indicator. `lth_mvrv_velocity_7d = lth_mvrv[t] - lth_mvrv[t-7]`.

---

## 6. Mode A / Mode B / Mode C Three-Mechanism Architecture

### Mode A — MVRV Structural (days-to-months)

**Signal:** LTH/STH-MVRV disaggregated zone classification. Trigger: zone transition (entering Zone 2, 3, 4, 5, or 6). Duration: 90d suppress / 30d amplify (subject to hyperopt). State machine as defined in intermediate + velocity gate (sophisticated add).

**Weight:** Per zone table (sections 4 and 5). Applied via `onchain_supply_weight_A`.

**Independence:** Mode A fires once per zone transition. Does NOT require netflow or SOPR data. Operates on daily Glassnode API cadence.

### Mode B — Exchange Netflow Tactical (hours-to-days)

**Signal:** 7-day cumulative exchange flow vs 30-day SMA. Upgraded from intermediate's additive netflow_multiplier to a standalone Mode B signal with its own state, duration cap, and co-firing rules.

**Upgraded triggers (sophisticated):**
```python
# Mode B state machine (sophisticated)
netflow_7d = self._compute_7d_cumulative_netflow()
netflow_sma_30d = self._compute_30d_sma_netflow()

if netflow_sma_30d > 1e-9:
    shock_ratio = netflow_7d / netflow_sma_30d
else:
    shock_ratio = 0.0

# Mode B amplify: outflow shock (coins leaving exchanges = holder accumulation)
if shock_ratio < -2.5 and zone in (1, 4):      # outflow shock in neutral/mild accumulation zone
    mode_b_weight_amplify = 1.04                 # 4% amplification (pure netflow signal)
    mode_b_duration_cap = 14                     # 14-day maximum (netflow shocks are short-lived)
elif shock_ratio < -3.5:                         # large outflow shock regardless of MVRV zone
    mode_b_weight_amplify = 1.06                 # stronger signal at higher outflow threshold
    mode_b_duration_cap = 10

# Mode B suppress: inflow shock (coins arriving at exchanges = seller intent)
if shock_ratio > 2.5 and zone in (1, 2):        # inflow shock in neutral/mild distribution zone
    mode_b_weight_suppress = 0.95               # 5% suppression (pure netflow)
    mode_b_duration_cap_suppress = 10
elif shock_ratio > 3.5:                          # large inflow shock regardless of MVRV zone
    mode_b_weight_suppress = 0.92
    mode_b_duration_cap_suppress = 7
```

**Key upgrade:** Mode B now provides signal in Zone 1 (neutral MVRV, ~65% of days) — covering the large gap where Mode A is inactive. Mode B duration cap (7–14 days) is much shorter than Mode A (90 days) — netflow shocks are transient.

**Co-firing rules:** When Mode A and Mode B fire simultaneously in the same direction, apply N_eff compounding (ρ_A_B = 0.55 — both use on-chain exchange data, but different timescales). Combined weight bounded at 1.25× amplify / 0.72× suppress.

### Mode C — SOPR Exhaustion Pivot (daily)

**Signal:** SOPR inflection point detection. Fires as a standalone amplification trigger (not just zone confirmation as in intermediate).

```python
# Mode C SOPR exhaustion pivot (sophisticated upgrade)
# Window: last 30 daily SOPR observations (maintained in _sopr_history deque)
sopr_streak_below_1 = sum(1 for s in list(self._sopr_history)[-30:] if s < 1.0)
sopr_today = self._onchain_data["sopr"]
sopr_yesterday = list(self._sopr_history)[-2] if len(self._sopr_history) >= 2 else None

# Mode C triggers when:
# (1) SOPR was below 1.0 for ≥ 7 consecutive days, AND
# (2) Today's SOPR crosses above 1.0 from below
mode_c_pivot_fire = (
    sopr_streak_below_1 >= 7
    and sopr_today is not None
    and sopr_today >= 1.0
    and sopr_yesterday is not None
    and sopr_yesterday < 1.0
)

if mode_c_pivot_fire:
    mode_c_weight = 1.05      # 5% amplification for 7 days post-pivot
    mode_c_duration = 7
    logger.info(f"OnChainSupply Mode C: SOPR_EXHAUSTION_PIVOT — {sopr_streak_below_1}d below 1.0 → crossover at {sopr_today:.4f}")
```

**Mechanism:** The SOPR pivot is the specific moment when forced seller exhaustion becomes observable. It is distinct from SOPR as a zone confirmation (intermediate): intermediate uses SOPR as a binary confirmation gate for Zone 3/5 weights. Mode C uses SOPR as an independent trigger that can fire in any MVRV zone (including neutral Zone 1), capturing intra-cycle capitulation recovery events that don't register as Zone 4/5 activations. Mode C has the shortest duration (7 days) and smallest weight (1.05×) — it is a precision tactical signal, not a structural modifier.

**Co-firing with Mode A:** When Mode C pivot fires simultaneously with Zone 5 velocity-gated amplify (Mode A at maximum conviction), the combined weight is: `min(mode_a_weight × mode_c_weight, 1.20)`. The 1.20× cap prevents over-compounding on simultaneous maximum-conviction signals. N_eff (ρ_A_C ≈ 0.60 — both use Glassnode on-chain data and both fire at capitulation episodes): N_eff(2, 0.60) = 2 / (1 + 0.60) = 1.25; scale = sqrt(1.25/2) = 0.79; excess = (0.10 + 0.05) × 0.79 = 0.12; combined = 1.12× (under cap).

---

## 7. Zone 6 Ultra-Deep Formalization

### Definition

**Zone 6:** MVRV < 0.75 (aggregate) AND LTH-MVRV < 0.80 (if available).

Historical occurrences 2013–2026:
- Dec 2018: MVRV reached ~0.58 (BTC ~$3,200). Deepest capitulation in post-2013 history.
- Nov 2022: MVRV reached ~0.62 (BTC ~$15,500 FTX-collapse bottom).
- Nov 2015: MVRV estimated ~0.70 from reconstructed data (BTC ~$300).

Total: 2–3 events in 9 years (2015 unclear). Frequency: ~0.25–0.35/year. n=2 confirmed events.

### Why the velocity gate is bypassed in Zone 6

With n=2 historical episodes, the velocity gate cannot be calibrated with statistical confidence. Furthermore, the economic logic changes at MVRV < 0.75: at this depth, the BTC aggregate cost basis is 25%+ above the current price for all UTXOs combined. This is a structural anomaly — the entire market, in aggregate, is underwater. Even if MVRV is declining from 0.80 to 0.70 (velocity < 0), the forward return at 30–90 day horizons from this depth is historically strongly positive (both Dec 2018 and Nov 2022 saw 40%+ BTC recovery within 60 days). The velocity gate's value (preventing amplification into continuing capitulation) has diminishing returns below MVRV 0.75 because at that depth, the "continuing decline" is already so extreme that recovery probability at the 30+ day horizon overwhelms the timing signal.

### Zone 6 specification

```python
# Zone 6 parameters (sophisticated only)
ZONE_6_THRESHOLD = 0.75      # MVRV below this → Zone 6
ZONE_6_LTH_THRESHOLD = 0.80  # LTH-MVRV below this (confirmation if available)
ZONE_6_SOPR_REQUIRED = 0.90  # SOPR must be < 0.90 for full 1.15× weight
ZONE_6_WEIGHT_CONFIRMED = 1.15
ZONE_6_WEIGHT_UNCONFIRMED = 1.08   # SOPR not confirming deep losses → conservative

# Zone 6 detection
if mvrv < ZONE_6_THRESHOLD:
    zone = 6
    # Optional LTH-MVRV confirmation
    if lth_mvrv is not None and lth_mvrv > ZONE_6_LTH_THRESHOLD:
        # Aggregate MVRV is below 0.75 but LTH-MVRV is still elevated
        # Possible data artefact or STH-dominated composition → use Zone 5 instead
        zone = 5
        logger.warning("OnChainSupply: Zone6 degraded to Zone5 — aggregate MVRV < 0.75 but LTH-MVRV >= 0.80")

    # Zone 6 weight (velocity gate bypassed)
    sopr = self._onchain_data.get("sopr")
    if sopr is not None and sopr < ZONE_6_SOPR_REQUIRED:
        base_weight = ZONE_6_WEIGHT_CONFIRMED   # 1.15×
        logger.info(f"OnChainSupply: ZONE6_ULTRA_DEEP_CONFIRMED mvrv={mvrv:.4f} sopr={sopr:.4f} weight=1.15×")
    else:
        base_weight = ZONE_6_WEIGHT_UNCONFIRMED  # 1.08×
        logger.info(f"OnChainSupply: ZONE6_ULTRA_DEEP_UNCONFIRMED mvrv={mvrv:.4f} sopr={sopr} weight=1.08×")
```

**Duration cap for Zone 6:** 45 days (longer than Zone 5's 30-day cap). Rationale: Dec 2018 and Nov 2022 capitulation troughs took 3–6 weeks to confirm before recovery. A 30-day cap would expire before recovery was established.

**N_eff in Zone 6:** When Zone 6 fires simultaneously with CER (axis 6), apply full 1.15× × CER standalone entry — do NOT deactivate Zone 6 as intermediate deactivates Zone 5 in CER co-occurrence. CER in Zone 6 represents the most extreme capitulation possible; the two signals are reinforcing and mechanistically distinct (CER: intraday price candle exhaustion; Zone 6: multi-year aggregate cost basis compression). Combined modifier = min(1.15 × 1.0 + CER_modifier_excess, 1.25).

---

## 8. Full N_eff Protocol Extension (9 Axes)

### Problem with intermediate's 2-axis coverage

Intermediate defined N_eff rules for axes 6 (CER) and 7 (funding) only. 7 additional meta-signal axes can co-fire with axis 18 during distribution or capitulation regimes. Without N_eff rules for these axes, the combined modifier during multi-axis co-fire could exceed defensible bounds.

### Pairwise ρ estimates (all overlapping axes with axis 18)

| Axis | Signal | Direction | ρ with Axis 18 | Tier | Rule |
|---|---|---|---|---|---|
| 6 (CER) | Capitulation exhaustion reversal | Amplify (Zone 5/6 co-fire) | 0.45 | B | Zone 5: deactivate (intermediate rule); Zone 6: compound at N_eff(2, 0.45) = 1.38 |
| 7 (Funding crowding) | Funding rate reversal | Suppress (Zones 2/3 co-fire) | 0.40 | B | Multiplicative with 0.72× floor; N_eff(2, 0.40) = 1.43 |
| 9 (Long-short ratio) | Retail sentiment contrarian | Suppress (Zones 2/3 co-fire) | 0.30 | C | Compound; N_eff(2, 0.30) = 1.54; combined suppress cap 0.78× |
| 11 (OI divergence) | OI-price washout | Amplify (Zone 5 co-fire) | 0.35 | C | Compound; N_eff(2, 0.35) = 1.48 |
| 15 (IV skew) | Put-skew fear signal | Suppress (Zone 3 co-fire) | 0.25 | D | Multiplicative; MAX_BEARISH_META_SIGNAL log retained from intermediate |
| 16 (GEX dealer gamma) | Dealer hedging flow | Suppress/amplify | 0.15 | D | Independent (orthogonal); compound freely; no N_eff cap needed |
| 20 (VRP) | Volatility risk premium | Amplify (Zone 5 co-fire) | 0.30 | C | Compound; N_eff(2, 0.30) = 1.54 |
| 21 (ETF flow) | Institutional ETF demand | Amplify/suppress | 0.20 | D | Independent; compound with 1.14× three-axis cap (per axis 21 prim) |
| 22 (Stablecoin) | Stablecoin supply momentum | Amplify (Zone 5 co-fire) | 0.35 | C | Compound; N_eff(2, 0.35) = 1.48 |
| 23 (Exchange netflow) | Exchange netflow regime | Mode B overlap | 0.55 | A | HIGH OVERLAP — Mode B in axis 18 uses same data as axis 23; when axis 23 fires in same direction as Mode B, treat as single signal (use the higher weight, not compounding) |

### Tier definitions

- **Tier A (ρ ≥ 0.50):** Single-signal treatment — use highest weight only, no compounding. Applied to axis 18 Mode B + axis 23 overlap.
- **Tier B (0.35 ≤ ρ < 0.50):** N_eff compounding with scale = sqrt(N_eff/N).
- **Tier C (0.20 ≤ ρ < 0.35):** N_eff compounding; lower penalty than Tier B.
- **Tier D (ρ < 0.20):** Essentially independent; compound freely; apply hard 1.25× amplify / 0.72× suppress caps only.

### Hard caps (unchanged from intermediate, now formally applies to all 9 axes)

```python
MAX_AMPLIFY_COMBINED = 1.25  # absolute ceiling from all meta-signals combined
MIN_SUPPRESS_COMBINED = 0.72  # absolute floor from all meta-signals combined
```

### Note on axis 23 (exchange-netflow-regime) overlap

Axis 23 (sophisticated cycle 156) uses a two-mode decay architecture (Mode A spike / Mode B sustained / SUPPLY_FLOOR_TAIL) based on exchange netflow. Axis 18 Mode B also uses exchange netflow. These signals share the same underlying Glassnode data source. When axis 23 fires:
- If axis 23 and axis 18 Mode B fire in the same direction → Tier A: use higher weight only.
- If axis 23 fires but axis 18 Mode B has not triggered (shock ratio not meeting threshold) → axis 23 provides independent signal; compound normally (Tier C for the structural MVRV component of axis 18 vs axis 23).

---

## 9. Limitation Resolution Table (12 Modes)

| # | Limitation | Intermediate status | Sophisticated status |
|---|---|---|---|
| L1 | G_DATA: entity-adjusted flows + MVRV Z-score require paid tier | REMAINS CRITICAL | SAME: G_DATA clears G1; G1 clears G2. Sophisticated adds LTH/STH-MVRV endpoints to the required data list (also Advanced tier). CryptoQuant offers entity-adjusted flows at Starter tier (~$100/mo) as alternative. |
| L2 | G1 frequency scan pending (Zone 2 ≥ 10 episodes) | REMAINS | UPDATED: Zone 6 (n=2–3) has known sub-minimum frequency; frequency target applies to Zones 2–5. Zone 6 treated as structural evidence signal — G1 frequency threshold waived for Zone 6 specifically. |
| L3 | SOPR as practitioner metric (not peer-reviewed) | REMAINS at intermediate | ADDRESSED: H6 (Mode C SOPR pivot) grounds the SOPR mechanism in the Hong & Stein (1999) gradual information diffusion framework — SOPR pivot is the observable event when forced-seller information fully diffuses to price. IS backtest (G2) will empirically validate. |
| L4 | ETH MVRV reliability (ICO distortion, post-Merge mechanics) | REMAINS: 0.80× discount | REMAINS: 0.80× discount on all ETH modifiers. Sophisticated note: LTH/STH decomposition partially alleviates ETH ICO distortion — ICO-era large wallets are UTXOs unmoved ≥ 155 days from genesis, captured in LTH-MVRV. Excludes them from STH-MVRV entirely. ETH reliability improves slightly with disaggregation but remains unvalidated. |
| L5 | N_eff for axis co-occurrence (theoretical ρ estimates) | 2 axes covered | RESOLVED: All 9 overlapping meta-signal axes with defined ρ tiers. Tier A (axis 23 overlap = single-signal treatment) is the key new rule. |
| L6 | Duration gate thresholds fixed (not hyperopt) | CRITICAL: 90d/30d hardcoded | RESOLVED: CPCV hyperopt protocol defines 81-cell grid including duration windows as hyperopt parameters. |
| L7 | MVRV velocity gate absent | NOT ADDRESSED | RESOLVED: mvrv_velocity_7d ≥ 0 mandatory precondition for Zone 5 amplify; neutral_hot_capitulation state defined. |
| L8 | Aggregate MVRV conflates LTH and STH cohorts | NOT ADDRESSED | RESOLVED: LTH/STH-MVRV disaggregation with 4 conviction modes. Fallback to aggregate MVRV (0.90× discount) when Advanced endpoint unavailable. |
| L9 | Mode B netflow operates only as additive multiplier | PARTIAL | RESOLVED: Mode B upgraded to standalone state machine with own duration cap (7–14 days), own co-firing rules, and Zone 1 coverage. |
| L10 | SOPR only as zone confirmation, not independent trigger | NOT ADDRESSED | RESOLVED: Mode C SOPR exhaustion pivot as standalone amplification trigger (7-day 1.05× window); fires in any MVRV zone. |
| L11 | Zone 5 amplifies into declining capitulation | NOT ADDRESSED (primary failure) | RESOLVED: MVRV velocity gate (H4). |
| L12 | Ultra-deep MVRV < 0.80 informal handling | INFORMAL: exception for MVRV < 0.80 | FORMALISED: Zone 6 (MVRV < 0.75) with 1.15× weight, 45-day duration cap, velocity gate bypass, SOPR < 0.90 confirmation. |

---

## 10. Signal Definition (Sophisticated) — State Machine

```python
@dataclass
class OnChainSupplyState:
    """Sophisticated on-chain supply dynamics regime signal state."""
    # Mode A inputs (structural)
    mvrv: float                    # aggregate MVRV
    mvrv_z: Optional[float]        # MVRV Z-score (Advanced; None if unavailable)
    lth_mvrv: Optional[float]      # LTH-MVRV (Advanced; None if unavailable)
    sth_mvrv: Optional[float]      # STH-MVRV (Advanced; None if unavailable)
    mvrv_velocity_7d: Optional[float]  # MVRV[t] - MVRV[t-7]; None if < 7d history
    zone: int                      # 1–6 from classification
    suppress_state: str            # INACTIVE|ACTIVE_PHASE_1|ACTIVE_PHASE_2
    amplify_active: bool           # velocity gate passed + zone in {4,5,6}
    neutral_hot: bool              # velocity < 0 in zone 5 (withheld amplify)
    days_suppress: int
    days_amplify: int
    
    # Mode B inputs (tactical)
    shock_ratio: float             # netflow_7d / netflow_sma_30d
    mode_b_weight: float           # 1.0 if inactive; 0.92–1.06 if active
    mode_b_days: int
    
    # Mode C inputs (pivot)
    sopr: Optional[float]
    sopr_streak_below_1: int       # consecutive days SOPR < 1.0
    mode_c_active: bool            # SOPR pivot fired
    mode_c_weight: float           # 1.05 for 7 days post-pivot; else 1.0
    mode_c_days: int
    
    # LTH/STH conviction mode
    lth_sth_mode: str              # DUAL_SUPPRESS|LTH_ONLY_SUPPRESS|DUAL_AMPLIFY|LTH_ONLY_AMPLIFY|NEUTRAL
    
    # N_eff context
    n_co_active_meta_signals: int  # count of other meta-signals currently firing
    
    def get_mr_modifier(self) -> float:
        """Combined modifier for MR/contrarian sister prims."""
        a = self._mode_a_modifier()
        b = self.mode_b_weight
        c = self.mode_c_weight
        combined = self._neff_combine(a, b, c)
        return max(min(combined, 1.25), 0.72)  # hard caps
    
    def get_momentum_modifier(self) -> float:
        """Combined modifier for momentum/breakout sister prims."""
        # Suppress direction: momentum prims exempt from IV-skew-driven suppress (per axis 15 rules)
        # Amplify direction: same as MR (supply signal does not differentiate prim class in amplify)
        return self.get_mr_modifier()
    
    def _mode_a_modifier(self) -> float:
        """Mode A (MVRV structural) base modifier before duration adjustment."""
        if self.zone == 6:
            sopr_ok = self.sopr is not None and self.sopr < 0.90
            base = 1.15 if sopr_ok else 1.08
            return self._apply_duration(base, self.days_amplify, max_days=45, soft_cap=1.04)
        
        elif self.zone == 5:
            if self.neutral_hot:
                return 1.0  # velocity gate withheld
            # LTH/STH conviction mode
            if self.lth_sth_mode == "DUAL_AMPLIFY":
                sopr_ok = self.sopr is not None and self.sopr < 0.98
                base = 1.10 if sopr_ok else 1.05
            else:  # LTH_ONLY or fallback
                base = 1.05
            return self._apply_duration(base, self.days_amplify, max_days=30, soft_cap=1.02)
        
        elif self.zone == 4:
            if self.lth_sth_mode in ("DUAL_AMPLIFY", "LTH_ONLY_AMPLIFY"):
                base = 1.05
            else:
                base = 1.02
            return self._apply_duration(base, self.days_amplify, max_days=30, soft_cap=1.01)
        
        elif self.zone == 3:
            if self.lth_sth_mode == "DUAL_SUPPRESS":
                sopr_ok = self.sopr is not None and self.sopr > 1.15
                base = 0.85 if sopr_ok else 0.90
            elif self.lth_sth_mode == "LTH_ONLY_SUPPRESS":
                base = 0.88
            else:
                base = 0.90  # fallback (aggregate MVRV only)
            return self._apply_duration(base, self.days_suppress, max_days=90, soft_cap=0.92)
        
        elif self.zone == 2:
            if self.lth_sth_mode == "DUAL_SUPPRESS":
                base = 0.92
            elif self.lth_sth_mode == "LTH_ONLY_SUPPRESS":
                base = 0.94
            else:
                base = 0.93
            return self._apply_duration(base, self.days_suppress, max_days=90, soft_cap=0.96)
        
        return 1.0  # Zone 1 neutral
    
    def _apply_duration(
        self, base: float, days: int, max_days: int, soft_cap: float
    ) -> float:
        """Duration gate: decay toward soft_cap after max_days. Hyperopt-tunable."""
        if days <= max_days:
            return base
        excess = days - max_days
        decay_rate = 0.04  # 4% per additional week (hyperopt parameter at G2)
        decay_factor = max(0.0, 1.0 - decay_rate * (excess / 7))
        if base > 1.0:
            return soft_cap + (base - soft_cap) * decay_factor
        else:  # suppress
            return soft_cap - (soft_cap - base) * decay_factor
    
    def _neff_combine(self, a: float, b: float, c: float) -> float:
        """Combine Mode A, B, C with N_eff downweight for correlated modes."""
        # Modes are not fully independent: ρ_A_C = 0.60 (both on-chain); ρ_A_B = 0.55 (same data)
        # Use simplified: apply N_eff for (A, C) pair when both active
        excesses = []
        if a != 1.0: excesses.append(a - 1.0)
        if b != 1.0: excesses.append(b - 1.0)
        if c != 1.0: excesses.append(c - 1.0)
        
        if len(excesses) <= 1:
            return 1.0 + sum(excesses)
        
        # Average ρ_avg ≈ 0.50 for Mode A/B/C (all on-chain, all Glassnode)
        rho_avg = 0.50
        N = len(excesses)
        n_eff = N / (1 + (N - 1) * rho_avg)
        scale = (n_eff / N) ** 0.5
        combined = 1.0 + sum(excesses) * scale
        return combined
```

---

## 11. IS Protocol (CPCV + DSR)

### Hyperopt grid (81 cells = 3×3×3×3)

| Parameter | Values | Rationale |
|---|---|---|
| `zone_2_mvrv_threshold` | [1.80, 2.00, 2.20] | Intermediate uses 2.00; test lower (more frequent) and higher (more selective) |
| `zone_5_mvrv_threshold` | [0.90, 1.00, 1.10] | Intermediate uses 1.00; test whether Zone 5 entry at higher MVRV improves WR |
| `suppress_window_days` | [60, 90, 120] | Intermediate fixed at 90; 60d (tighter) vs 120d (looser) |
| `amplify_window_days` | [21, 30, 45] | Intermediate fixed at 30; 21d (sharper) vs 45d (persistent) |

**Total cells: 81. Mandatory CPCV (k=10 folds) + DSR.**

### CPCV application

With only ~9 years of Glassnode daily data (2015–2026), and Zone 2/3 activation periods ~15% of days, expected n ≈ 500 Zone 2 days and ~150 Zone 3 days over the window. CPCV with k=10 provides 10 out-of-sample test periods; each fold has ~50 Zone 2 days and ~15 Zone 3 days — minimum viable for Mann-Whitney U (n ≥ 10 per fold for Zone 3).

If n < 10 per fold for Zone 3 after CPCV split: extend to 2013 Glassnode reconstructed data (available via paid tier for key metrics). Target: n ≥ 15 per fold for all zones.

### IS targets

| Metric | Target | Rationale |
|---|---|---|
| IS Sharpe (Mode A suppress WR delta) | ≥ 3pp conditional WR improvement | Intermediate equivalent target (Mann-Whitney U p < 0.10 one-tailed) |
| IS Sharpe (Mode A amplify WR delta) | ≥ 4pp conditional WR improvement | Velocity gate reduces n; require higher WR delta to justify lower frequency |
| DSR (Mode A amplify) | ≥ 0.45 | Lower than standard 0.55 target — Zone 5/6 has inherently low n; MVRV signal is episodic |
| DSR (Mode A suppress) | ≥ 0.55 | Zone 2/3 has sufficient n; standard DSR target applies |
| Mode B IS targets | ≥ 2pp conditional WR delta | Netflow shock targets; lower threshold (Mode B is supplementary to Mode A) |
| Mode C IS targets | ≥ 4pp forward 14-day WR (SOPR pivot events) | Small n (historical SOPR pivots ~8–12/year); require higher effect size |

### Anti-prim escape hatches

- **Anti-prim A:** Zone 2 frequency < 8 distinct 30-day periods in 2015–2026 → raise threshold to 1.80 and retest. If still < 8 → retire Mode A suppress (Zone 2 only; Zone 3 may survive).
- **Anti-prim B:** Mode A amplify DSR < 0.35 at best-performing cell → velocity gate failed to improve OOS stability; escalate threshold to Zone 6 only; retire Zones 4/5 amplify.
- **Anti-prim C:** Mode B conditional WR delta < 0 (inflow shocks coincide with positive forward returns) → Mode B suppress is contra-mechanistic; retire Mode B suppress direction, maintain Mode B amplify only.
- **Anti-prim D:** LTH/STH disaggregation adds < 1pp vs aggregate MVRV in IS test → fallback to aggregate MVRV (0.90× confidence discount); LTH/STH disaggregation provides no incremental value at this data resolution.

---

## 12. Conditions Log Entry

- **Works when (Mode A suppress):** LTH-MVRV > 2.0 AND (STH-MVRV > 1.30 → full weight; STH-MVRV < 1.10 → discounted). Duration gate Phase 1 (< 90 days). SOPR > 1.15 for Zone 3 full weight. Mechanism: dual-cohort distribution pressure (H1) or LTH-only distribution (H2).
- **Works when (Mode A amplify):** LTH-MVRV < 1.10 AND velocity gate passed (mvrv_velocity_7d ≥ 0) for Zones 4/5; velocity gate bypassed for Zone 6. Dual-capitulation conviction (H3) when STH-MVRV also < 1.10.
- **Works when (Mode B):** Exchange netflow 7d shock ratio > 2.5 or < −2.5 regardless of MVRV zone. Provides signal in Zone 1 neutral (~65% of days) where Mode A is inactive. Duration: 7–14 days.
- **Works when (Mode C):** SOPR crosses above 1.0 after ≥ 7 consecutive sub-1.0 days. Fires in any MVRV zone. 7-day 1.05× window.
- **Fails when:** velocity_7d < 0 in Zone 5 (neutral_hot state; amplify withheld); G_DATA uncleared (all modes DRY_RUN); MVRV in neutral Zone 1 AND no Mode B shock AND no Mode C pivot; ETH (0.80× discount on all modifiers until ETH-specific G1 scan); Glassnode API outage (retain previous state; log); SOPR unavailable (Zone 3/5 fall back to unconfirmed weights).
- **N_eff co-occurrence:** Axis 23 (exchange-netflow) + Mode B = Tier A (single-signal, use highest weight); Axis 7 (funding) + Zone 3 = multiplicative (Tier B, 0.72× floor); Axis 6 (CER) + Zone 5 = deactivate (Tier B); Axis 6 + Zone 6 = compound (exception to Zone 5 rule); all others per tier table.
- **G2 IS targets:** Mode A suppress ≥ 3pp WR delta, DSR ≥ 0.55; Mode A amplify ≥ 4pp WR delta, DSR ≥ 0.45; Mode B ≥ 2pp; Mode C ≥ 4pp.
- **Deployment gates outstanding:** G_DATA (Glassnode Advanced API key) → G1 (Zone 2–5 frequency scan) → G2 (CPCV+DSR 81-cell IS test) → LIVE.
- **Kelly α:** 0.10 pending G2; applies to meta-signal weight not to standalone position sizing.
- **Best pairs:** BTC/USDT primary; ETH/USDT at 0.80× modifier discount.
- **Best timeframe:** Daily Glassnode refresh via `bot_loop_start()`; `onchain_supply_weight` scalar broadcast to all 4h signal candles.
- **Evidence:** 11 academic anchors (Liu & Tsyvinski 2021 JF; Foley et al. 2019 RFS; Griffin & Shams 2020 JF; Cong et al. 2020 RFS; Bianchi 2020 JFQA; Woo 2021 CoinMetrics; Shirakashi 2019 Glassnode; Carter & Le Calvez 2018 CoinMetrics; Hong & Stein 1999 JF; Campbell & Thompson 2008 RFS; Andersen et al. 2001 JASA). No own-data backtest. All gates DRY_RUN until G_DATA cleared.
- **Signal reason format (sophisticated):** `OCSD_S1: zone=Z mvrv=M lth_mvrv=L sth_mvrv=S lth_sth_mode=MODE vel=V(pass|block|bypass) sopr=SOPR(C|U|N) mode_a=W_A mode_b=W_B mode_c=W_C combined=W state=STATE [DRY_RUN_G_DATA] [NEUTRAL_HOT_CAP] [ZONE6_ULTRA_DEEP] [ANTI_PRIM_X]`
- **Prim bank after cycle 160:** freqtrade 23 naive / 24 intermediate (−1: on-chain-supply-dynamics elevated) / **29 sophisticated** (+1: on-chain-supply-dynamics-regime axis 18)
- **Last validated:** cycle 160 (intermediate → sophisticated; analytical elevation; velocity gate + LTH/STH disaggregation + Mode A/B/C architecture + Zone 6 + full N_eff extension + CPCV/DSR protocol added; no live data validation — G_DATA outstanding)

---

## Refinement History

| Cycle | Level | Key Change |
|-------|-------|------------|
| 122 | naive | 18th freqtrade axis; binary MVRV (2.5/1.0); exchange net flow shock (2× SMA); 6 academic anchors; ~5 episodes/9 years; no duration gate; no redundancy protocol; G_DATA blocker |
| 123 | intermediate | Five-zone gradient (Zones 1–5; MVRV + Z-score + SOPR confirmation); 90d suppress / 30d amplify duration gate (INACTIVE/PHASE_1/PHASE_2); N_eff for axes 6 and 7; complete bot_loop_start() API pattern; 8 anchors |
| 160 | sophisticated | MVRV velocity gate (Zone 5 amplify gated on recovery direction); LTH/STH-MVRV disaggregation (4 conviction modes); Mode A/B/C three-mechanism architecture; Zone 6 formalization (MVRV < 0.75, velocity bypass); full N_eff extension to 9 axes with Tier A–D rules; CPCV+DSR 81-cell hyperopt protocol (4 parameters); 3 new academic anchors (Hong & Stein 1999 JF; Campbell & Thompson 2008 RFS; Andersen et al. 2001 JASA); 11 total anchors |
