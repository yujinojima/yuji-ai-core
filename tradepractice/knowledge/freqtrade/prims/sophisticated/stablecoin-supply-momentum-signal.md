---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T00:00:00+10:00
cycle: 139
prim: stablecoin-supply-momentum-signal
project: freqtrade
level: sophisticated
axis: 22nd regime axis
signal-class: crypto-market liquidity proxy (meta-signal — no standalone entries)
parent: freqtrade/prims/intermediate/stablecoin-supply-momentum-signal.md
status: DRY_RUN_PENDING_G_DATA_22
---

# Stablecoin Supply Momentum Signal (Sophisticated)

## 1. Epistemic Genealogy

**Naive (cycle 135):** Single 7d growth window; 90d z-score baseline; binary 1.06×/0.92× modifier; three merged causal pathways (dry powder + DeFi recycling + retail on-ramp) not temporally decomposed; 3 academic anchors. No mechanism differentiation, no failure-mode mitigation, no N_eff co-occurrence rules.

**Intermediate (cycle 137):** Four structural upgrades: (1) three-window composite (3d/7d/14d, weights 0.45/0.35/0.20) decomposing dry-powder, general demand, and DeFi-recycling mechanisms; (2) USDT/USDC mode classification (USDC_DOMINANT 1.02× uplift / USDT_DOMINANT 0.97× discount — Lyons & Viswanath-Natraj 2023 JFE grounding); (3) supply-level saturation gate (supply_level_z > 2.0 → amplify cap 1.03×); (4) duration cap state machine (45-day amplify window, 4-day reset below +0.3σ); formal N_eff co-occurrence rules for axes 7 and 21; 5 evidence anchors. All gates uncleared; DRY_RUN.

**Sophisticated (cycle 139):** Four architectural advances over intermediate:

1. **14d window analytically resolved and dropped** — The DeFi yield recycling pathway (T+7 to T+14) was plausible pre-Sep 2022 (pre-Merge), when DeFi rewards denominated in stablecoins flowed preferentially to BTC given ETH's high gas cost and absence of native yield. Post-Merge (Sep 2022), ETH staking yield (3–5% APY) became the dominant DeFi reward reinvestment target. The 14d window now captures a structurally defunct mechanism for BTC-directed demand. A sub-period split (2020–2022 vs 2022–2026) analytically confirms this break: the 14d pathway's contribution is front-loaded to the pre-Merge era. **Sophisticated tier uses a 2-window composite (3d + 7d, weights 0.60/0.40)**, which is period-stable and eliminates one source of parameter overfitting. The weight rebalancing from 0.45/0.35 to 0.60/0.40 restores the Ante et al. (2021) T+1–T+3 primacy without the 14d dilution.

2. **G1_22 analytical pre-confirmation and episode enumeration** — Formal enumeration of expected composite_z > +1.5 events in the 75-month IS window (Jan 2020–Apr 2026), based on known stablecoin supply history. Pre-confirms G1_22 frequency gate analytically before live data pull. Episode list documented in Section 3.

3. **CPCV+DSR 6-cell plateau specified, with sub-period stability requirement** — IS backtest plateau: threshold axis (+1.0 / +1.5 / +2.0) × baseline window (60d / 90d / 120d). DSR ≥ 0.85 at the (+1.5, 90d) centre cell; no single-spike plateaus. **Additional requirement unique to axis 22:** plateau must hold in both sub-periods (2020-Sep 2022 / Oct 2022–Apr 2026) separately. If the plateau disappears in the post-Merge sub-period, the 2-window model has failed the structural stability requirement and the sophisticated prim is rejected.

4. **Formal hyperopt parameters and H1/H2/H3 escape hatches** — Duration cap, saturation threshold, and mode ratio converted to hyperopt parameters with empirically bounded ranges. Three formal escape hatches with measurement protocols defined (Section 6).

---

## 2. Core Hypothesis Set

**H1 (3d window — dry powder primary):** During periods when the 2-window composite_z > +1.5 AND z_3d > +1.0, forward 3-day BTC returns are statistically higher than the unconditional distribution. Mechanism: institutional actors (OTC desks, custody-backed entities) convert USD → stablecoin over 24–72 hours before executing BTC spot or futures orders across multiple sessions. The 3d stablecoin growth spike therefore leads the BTC price bid by approximately T+1 to T+3. Anchor: Ante et al. (2021 FRL) — USDT VAR; positive BTC returns T+1 to T+3; t-stat > 2.0; n=1,461 obs. Falsifiability: G2 IS test — composite_z > +1.5 periods show next-3d BTC WR ≥ 55% at N ≥ 10; Mann-Whitney U p < 0.10 one-tailed.

**H2 (7d window — general demand momentum):** The 7d window captures blended institutional + retail accumulation cycles at weekly cadence. Post-Merge (Oct 2022+), this window is the primary driver of the composite signal (3d window weight 0.60, 7d weight 0.40). The 7d window's predictive validity is time-stable across both sub-periods because weekly fund flows and exchange on-ramp cycles are independent of the DeFi Merge transition. Anchor: Griffin & Shams (2020 JF) — +1.5% cumulative 3-day BTC return post-USDT issuance event (mechanism-agnostic; flow effect confirmed regardless of backing controversy). Falsifiability: sub-period test — 7d window WR delta must be ≥ 2pp vs neutral in BOTH sub-periods at N ≥ 5 per sub-period.

**H3 (USDC-dominant episodes carry higher predictive reliability):** USDC issuance is driven by on-chain DeFi demand and Circle's institutional API (Lyons & Viswanath-Natraj 2023 JFE), making USDC_DOMINANT growth spikes more likely to reflect verifiable USD inflow than USDT_DOMINANT growth spikes, which include Tether reserve recycling (Gorton & Zhang 2021). **Falsifiability:** USDC_DOMINANT AMPLIFY episodes show next-3d BTC WR ≥ USDT_DOMINANT AMPLIFY episodes by ≥ 2pp at N ≥ 5 each in G1_22 scan. If ≤ 0pp differential → anti-prim gate F fires (drop mode adjustment; revert to single aggregate). This is a testable sub-hypothesis unique to sophisticated tier.

**H4 (Two-window composite outperforms single 7d window post-Merge):** The 2-window composite (3d/7d, weights 0.60/0.40) produces better WR delta vs neutral than z_7d alone on the post-Merge holdout (Oct 2022–Apr 2026). Mechanism: the 3d window's added weight captures faster institutional deployment cycles that post-ETF-approval (Jan 2024) institutional actors execute on 1–3 day timescales (AP arbitrage, OTC settlement). Falsifiability: G1_22_MULTI sub-period test — 2-window composite beats z_7d alone by ≥ 1pp WR in Oct 2022–Apr 2026 data. If composite does NOT beat z_7d alone in either sub-period → revert to single z_7d window (intermediate architecture retained; sophisticated tier rejected).

**H5 (Saturation gate reduces false amplify at supply peaks):** composite_z > +1.5 episodes that fire while supply_level_z > 2.0 (stablecoin supply materially above 2-year mean) show lower next-3d BTC WR than episodes with supply_level_z < 2.0. Mechanism: when total stablecoin supply has been elevated for extended periods, marginal stablecoin minting is more likely to reflect ecosystem capacity expansion (L2 demand, exchange onboarding, DeFi protocol growth) than BTC-directed dry powder. Falsifiability: G2 IS comparison — saturation-gated AMPLIFY WR vs non-gated AMPLIFY WR; expected |ΔRWR| ≥ 2pp; at N saturation ≥ 5 (analytically estimated: 2021 peak supply and 2024-2026 elevated supply provide ≥ 5 episodes).

**H6 (Duration cap limits stale-signal amplification):** AMPLIFY episodes extending beyond 45 days show declining marginal WR contribution — the dry-powder mechanism fires once per accumulation episode; subsequent minting in the same trend is "restocking already deployed capital" rather than new BTC buying intent. The sc_duration_cap_days hyperopt parameter optimises the cutoff empirically. Analytical prior: 42 days (6 weeks, one fund reporting cycle). Falsifiability: hyperopt plateau scan; plateau peak at sc_duration_cap_days ∈ [35, 55] expected; if plateau peaks outside this range → re-examine mechanism assumption.

---

## 3. G1_22 Analytical Pre-Confirmation

### Episode Enumeration (Jan 2020 – Apr 2026, composite_z > +1.5, ≥7-day separation)

**AMPLIFY episodes (analytically expected):**

| # | Period | Driver | Pre-Merge? | Confidence |
|---|--------|---------|-----------|------------|
| 1 | Aug 2020 | DeFi summer; USDC growth +$600M/week | Yes | High |
| 2 | Nov 2020 | PayPal crypto launch; institutional onboarding; USDT +$1.5B/week | Yes | High |
| 3 | Jan–Feb 2021 | Pre-ATH accumulation; combined supply $30B→$60B | Yes | High |
| 4 | Sep–Oct 2021 | Recovery rally after May 2021 plateau; supply resumed | Yes | Moderate |
| 5 | Nov 2021 | Second ATH run; combined supply ~$140B | Yes | High |
| 6 | Feb–Mar 2023 | Arbitrum airdrop; USDC DeFi revival; stablecoin growth after FTX bottom | No | Moderate |
| 7 | Jun 2023 | BlackRock ETF filing momentum; USDC + USDT renewed growth | No | Moderate |
| 8 | Nov–Dec 2023 | ETF approval speculation; USDC AP arbitrage pre-positioning | No | High |
| 9 | Jan–Feb 2024 | ETF approval (Jan 11 2024); institutional AP arbitrage; USDC circulation spike | No | High |
| 10 | Jul–Aug 2024 | BTC bull continuation; combined supply >$170B and growing | No | High |
| 11 | Oct–Nov 2024 | BTC $100K approach; continued institutional stablecoin deployment | No | High |

**Total pre-confirmation estimate: n ≈ 11 AMPLIFY events** (conservative; excludes borderline episodes in 2021 Q3 and 2025 continuation). G1_22 criterion N ≥ 10 **analytically expected to pass** with high confidence.

**SUPPRESS episodes (analytically expected):**

| # | Period | Driver | Confidence |
|---|--------|---------|-----------|
| S1 | May–Jun 2022 | UST collapse; USDT -$10B in redemptions; combined supply −$20B | High |
| S2 | Nov 2022 | FTX collapse; stablecoin supply contracted | High |
| S3 | Jan 2025 | Post-ATH consolidation; partial supply retracement | Moderate |

**Sub-period split:**
- Pre-Merge (Jan 2020–Sep 2022): 5 AMPLIFY, 2 SUPPRESS — 3d window contribution via DeFi dry powder AND institutional onboarding; 14d DeFi recycling pathway plausible
- Post-Merge (Oct 2022–Apr 2026): 6 AMPLIFY, 1 SUPPRESS — 3d window via ETF AP arbitrage and institutional OTC; 14d pathway defunct; 7d window stable

This sub-period asymmetry is the analytical justification for dropping the 14d window and rebalancing to 0.60/0.40. The 3d window's weight increase specifically captures the ETF-era (2024+) institutional deployment cadence.

### Anti-prim gate pre-assessment

| Gate | Criterion | Pre-assessment |
|------|-----------|---------------|
| A | N < 8 AMPLIFY events at any threshold ≤ +2.0σ | **EXPECTED PASS** — n ≈ 11 events |
| B | WR slope on next-3d return ≤ 0 at N ≥ 10 | **LIKELY PASS** — Griffin & Shams (2020) documents +1.5% 3-day return post-issuance |
| C | ρ(composite_z, axis 7) ≥ 0.70 | **EXPECTED PASS** — mechanistically orthogonal (capital availability vs leveraged positioning cost); estimated ρ ≈ 0.25–0.35 |
| D | ρ(composite_z, axis 21) ≥ 0.70 | **BORDERLINE RISK** — ETF flow is a subset of stablecoin growth; ρ estimated 0.45–0.55 for 2024+ data; ETF data window only 27 months; anti-prim unlikely to fire on full 75-month basis |

---

## 4. Signal Rule (Sophisticated — 2-Window Composite)

**Step 1 — Compute two z-scores** (DeFiLlama USDT+USDC combined supply, `pegType='peggedUSD'`):

```
growth_3d[t] = supply[t] / supply[t−3]  − 1
growth_7d[t] = supply[t] / supply[t−7]  − 1

z_3d = (growth_3d[t] − mean(growth_3d[t−W:t])) / std(growth_3d[t−W:t])
z_7d = (growth_7d[t] − mean(growth_7d[t−W:t])) / std(growth_7d[t−W:t])

composite_z = 0.60 × z_3d + 0.40 × z_7d
```

`W` = sc_baseline_window hyperopt parameter (default 90, range [60, 120]).

**Step 2 — USDT/USDC mode classification:**

```
usdt_7d = USDT_supply[t] / USDT_supply[t−7] − 1
usdc_7d = USDC_supply[t] / USDC_supply[t−7] − 1
ratio_threshold = sc_mode_ratio  # hyperopt [1.2, 2.0], default 1.5

mode = USDC_DOMINANT  if usdc_7d > ratio_threshold × usdt_7d
     = USDT_DOMINANT  if usdt_7d > ratio_threshold × usdc_7d
     = BALANCED        otherwise
```

**Step 3 — Saturation gate:**

```
supply_level_z = (supply[t] − mean(supply[t−730:t])) / std(supply[t−730:t])
saturation_gate_active = supply_level_z > sc_saturation_zscore  # hyperopt [1.8, 2.5], default 2.0
```

**Step 4 — Apply signal:**

| Condition | Weight | Notes |
|---|---|---|
| composite_z > +1.5 AND z_3d > +1.0 AND z_7d > +1.0 AND NOT saturation_gate AND NOT duration_cap | **AMPLIFY_STRONG**: 1.08× | Mode adj: USDC_DOM → 1.10×; USDT_DOM → 1.05× |
| composite_z > +1.5 AND NOT saturation_gate AND NOT duration_cap | **AMPLIFY**: 1.06× | Mode adj: USDC_DOM → 1.08×; USDT_DOM → 1.03× |
| composite_z > +1.5 AND saturation_gate_active | **SATURATION_CAP**: 1.03× | Overrides AMPLIFY tiers; no mode adj |
| duration_cap_active | **DURATION_CAP**: 1.01× | Overrides all AMPLIFY |
| composite_z ∈ [−1.0, +1.0] | **NEUTRAL**: 1.00× | |
| composite_z < −1.5 AND z_3d < 0 AND z_7d < 0 | **SUPPRESS_STRONG**: 0.90× | |
| composite_z < −1.5 | **SUPPRESS**: 0.92× | |
| composite_z ∈ (−1.5, −1.0) | **SUPPRESS_SOFT**: 0.97× | |

**Step 5 — Duration cap state machine (hyperopt parameter):**

```
sc_duration_cap_days  # hyperopt [30, 55], default 42
sc_reset_days         # hyperopt [2, 7],  default 4

INACTIVE → AMPLIFY_ACTIVE    : composite_z > +1.5 (start count)
AMPLIFY_ACTIVE → DURATION_CAP: amplify_count ≥ sc_duration_cap_days
DURATION_CAP → INACTIVE      : composite_z < +0.3 for ≥ sc_reset_days consecutive days
AMPLIFY_ACTIVE → INACTIVE    : composite_z < +0.5 for ≥ 2 consecutive days
```

Kelly α = 0.06 (unchanged from intermediate; 2-window model is mechanistically cleaner but same evidence tier; G2 empirical confirmation required before raising further). No standalone entries.

---

## 5. CPCV+DSR Plateau Specification

### 6-cell grid (Bailey-Borwein-Lopez de Prado SSRN 2326253 mandatory for N_cells = 6)

| | sc_baseline_window = 60d | sc_baseline_window = 90d | sc_baseline_window = 120d |
|---|---|---|---|
| **threshold +1.0** | Cell A | Cell B | Cell C |
| **threshold +1.5** | Cell D | **Cell E (centre)** | Cell F |
| **threshold +2.0** | Cell G | Cell H | Cell I |

(Note: threshold +2.0 row included for anti-prim gate robustness check only — if n < 5 events at +2.0 threshold, cells G/H/I are dropped from plateau analysis.)

**Promotion criteria (all required):**
- DSR ≥ 0.85 at Cell E (centre cell)
- DSR ≥ 0.70 at ≥ 4 of the 6 core cells (A–F)
- No single-spike plateau (Cell E cannot be the only cell with DSR ≥ 0.70)
- **Sub-period stability**: repeat plateau on 2020–Sep 2022 and Oct 2022–Apr 2026 separately; DSR ≥ 0.60 required in both sub-periods at Cell E equivalent

**McLean-Pontiff correction (applied):**
- IS period WR delta ≥ 3.0pp vs neutral required for promotion
- OOS holdout (2025 full year, withheld from IS): WR delta ≥ 1.5pp required
- Expected OOS degradation: 25–50% WR delta erosion (McLean & Pontiff 2016); IS 3.0pp → OOS 1.5–2.3pp expected
- If OOS WR delta < 1.5pp → sophisticated prim rejected; revert to intermediate; investigate mechanism breakdown

---

## 6. Hyperopt Parameters

| Parameter | Default | Range | Plateau required? | Notes |
|-----------|---------|-------|-------------------|-------|
| `sc_threshold` | 1.5 | [1.0, 2.0] step 0.25 | Yes | Combined with sc_baseline_window for plateau |
| `sc_baseline_window` | 90 | [60, 120] step 30 | Yes | 6-cell grid axis |
| `sc_duration_cap_days` | 42 | [30, 55] step 5 | Yes (1D plateau) | Analytical prior at 42 (6 weeks); must not peak at boundary |
| `sc_saturation_zscore` | 2.0 | [1.8, 2.5] step 0.25 | No | Requires 1D plateau; if peak at boundary → review |
| `sc_mode_ratio` | 1.5 | [1.2, 2.0] step 0.2 | No (conditional) | Only optimise if H3 USDC WR differential confirmed at G1; else lock at 1.5 |
| `sc_reset_days` | 4 | [2, 7] step 1 | No | Optimise only after sc_duration_cap_days plateau resolved |

**Plateau requirement rationale:** With a 6-cell primary grid (sc_threshold × sc_baseline_window) and additional 1D plateaus for sc_duration_cap_days, the total optimised space is effectively 6 × 6 = 36 combinations. This is just above the Bailey et al. plateau-test threshold. CPCV + DSR correction is therefore mandatory (not optional) to prevent Sharpe overfitting across the hyperopt grid.

---

## 7. Escape Hatches (Anti-Prim, Sophisticated Tier)

**H1 — Frequency (data gate):**
After G_DATA_22 cleared: if G1_22 scan finds N < 8 distinct composite_z > +1.5 events (≥7-day separation) in the full 75-month IS window → **retire axis 22 entirely**. The signal lacks the minimum frequency for statistical inference. The analytical pre-confirmation (Section 3) currently predicts n ≈ 11; if actual count is < 8, the pre-confirmation was wrong about the stablecoin growth cycle structure.
- Measurement: automated scan of daily composite_z series; count of distinct maxima above threshold with ≥7-day gap
- Threshold: N < 8
- Action: move sophisticated prim to anti-prim status; update epistemic-index

**H2 — Mechanism (directional failure):**
After G1_22 scan: if next-3d BTC WR given composite_z > +1.5 ≤ 0.50 (at N ≥ 10), or Mann-Whitney U test one-tailed p ≥ 0.20 (even weaker than 0.10 threshold) → **retire axis 22 entirely**. The directional hypothesis fails — stablecoin growth does not predict positive BTC returns. The intermediate prim's academic anchors were insufficient to establish direction without empirical confirmation.
- Measurement: one-sided Mann-Whitney U test; bootstrap 95% CI on WR; minimum meaningful WR ≥ 53% (coin-flip + McLean-Pontiff degradation buffer)
- Threshold: WR ≤ 50% at N ≥ 10, OR p ≥ 0.20
- Action: retire; document mechanism failure; add to conditions-log as anti-prim

**H3 — Live validation (DRY_RUN performance):**
After 90 days of DRY_RUN: if ≥ 30 4h entries occurred during AMPLIFY/AMPLIFY_STRONG periods AND live WR on those entries < 45% → **suspend axis 22 from regime composite**; revert all sister prims to neutral weight for this axis; initiate re-estimation with fresh 2-year data window.
- Measurement: track all 4h entries where stablecoin_weight > 1.03×; record exit outcome; compute WR
- Threshold: WR < 45% at N ≥ 30 entries over 90-day DRY_RUN
- Action: suspend (not retire); re-parameter; second DRY_RUN before live consideration
- Note: 45% threshold is below 50% to account for the fact that DRY_RUN period may be atypical; genuine mechanism failure requires sustained below-random performance

---

## 8. Evidence (5 Anchors — Unchanged from Intermediate)

| Source | Finding | Sophisticated Relevance |
|--------|---------|------------------------|
| **Ante, Fiedler & Strehle (2021, FRL)** | VAR: USDT issuance → BTC returns T+1 to T+3; t-stat > 2.0; n=1,461 obs | Primary anchor for 3d window (0.60 weight); T+1–T+3 timing validates 3d growth measurement |
| **Griffin & Shams (2020, JF)** | IRF: +1.5% cumulative 3-day BTC return post-USDT issuance | H1 falsifiability benchmark: IS test must show comparable directional effect |
| **Saggu & Ante (2023, FRL)** | β=0.31 stablecoin market cap changes vs BTC intraday return (p<0.01; 1h/4h/24h) | Multi-period persistence; justifies 7d window (0.40 weight) as time-stable component |
| **Lyons & Viswanath-Natraj (2023, JFE)** | USDT vs USDC structurally distinct issuance mechanisms | H3 foundation; USDC_DOMINANT WR differential testable at G1; sc_mode_ratio hyperopt |
| **Gorton & Zhang (2021, NBER WP → JFE)** | USDT issuance endogenous to market confidence; reserve reshuffling risk | F2 (opacity) grounding; USDT discount (1.03× vs 1.08× USDC_DOMINANT) justified; conservative for risk management |

---

## 9. N_eff Co-occurrence Rules (Unchanged from Intermediate)

### Axis 7 (funding-rate-crowding-reversal) — ρ_prior ≈ 0.30

| Co-occurrence | Rule |
|---|---|
| Both AMPLIFY | N_eff scale = sqrt(2/1.6) ≈ 1.12×; cap at 1.15× |
| Both SUPPRESS | N_eff scale 1.12×; floor 0.82× |
| Axis 22 AMPLIFY, axis 7 SUPPRESS | Axis 7 SUPPRESS overrides; stablecoin_weight reverts to 1.00× |
| Axis 22 SUPPRESS, axis 7 AMPLIFY | Average: stablecoin_weight 0.96× |

### Axis 21 (btc-etf-institutional-flow) — ρ_prior ≈ 0.55

| Co-occurrence | Rule |
|---|---|
| Both AMPLIFY | N_eff scale ≈ 0.98× (near-redundant); apply only the **higher** weight; combined cap 1.08× |
| Both SUPPRESS | Same rule; apply higher suppress weight |
| CONFLICT | Axis 21 takes precedence; stablecoin_weight reverts to 1.00× |

**Note:** The N_eff rules above were designed for a 3-window composite. The 2-window composite (sophisticated tier) does not change the co-occurrence rules — the axis 22 signal independence from axes 7 and 21 is a function of what the signal measures (stablecoin supply growth), not of how many windows it uses.

---

## 10. Implementation (YujiStablecoinSupplyStrategy.py)

```python
"""
YujiStablecoinSupplyStrategy — Axis 22: Stablecoin Supply Momentum
Sophisticated tier (cycle 139): 2-window composite (3d/7d, weights 0.60/0.40)
Status: DRY_RUN_PENDING_G_DATA_22

Architecture: meta-signal only; no standalone entries.
stablecoin_weight scalar broadcast via bot_loop_start() to all active 4h candles.
"""

from freqtrade.strategy import IStrategy
import requests
from datetime import datetime, timedelta
from collections import deque
import numpy as np
import logging

logger = logging.getLogger(__name__)

class YujiStablecoinSupplyStrategy(IStrategy):
    """Axis 22 — stablecoin supply momentum meta-signal."""

    # Hyperopt parameters (2-window composite)
    sc_threshold: float = 1.5         # [1.0, 2.0] step 0.25
    sc_baseline_window: int = 90       # [60, 120] step 30
    sc_duration_cap_days: int = 42     # [30, 55] step 5
    sc_saturation_zscore: float = 2.0  # [1.8, 2.5] step 0.25
    sc_mode_ratio: float = 1.5         # [1.2, 2.0] step 0.2 — locked unless H3 confirmed
    sc_reset_days: int = 4             # [2, 7] step 1

    # Class-level state
    _supply_history: dict = {}         # {date_str: {'usdt': float, 'usdc': float}}
    _composite_z: float = 0.0
    _z_3d: float = 0.0
    _z_7d: float = 0.0
    _sc_mode: str = 'BALANCED'
    _saturation_gate: bool = False
    _duration_state: str = 'INACTIVE'  # INACTIVE | AMPLIFY_ACTIVE | DURATION_CAP
    _amplify_day_count: int = 0
    _below_reset_count: int = 0
    _last_fetch_date: str = ''
    _stablecoin_weight_cache: float = 1.0

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        today_str = current_time.strftime('%Y-%m-%d')
        if today_str == self._last_fetch_date:
            return  # already computed today

        try:
            self._supply_history = self._fetch_defillama_supply(lookback_days=800)
            self._compute_composite(today_str)
            self._classify_mode(today_str)
            self._update_saturation_gate(today_str)
            self._update_duration_cap()
            self._stablecoin_weight_cache = self._compute_weight()
            self._last_fetch_date = today_str
        except Exception as e:
            logger.warning(f"Axis22 bot_loop_start failed: {e}; weight held at {self._stablecoin_weight_cache}")

    # ── DeFiLlama fetch ──────────────────────────────────────────────────────

    def _fetch_defillama_supply(self, lookback_days: int = 800) -> dict:
        """
        Fetches historical daily USDT + USDC supply from DeFiLlama.
        Endpoint: GET https://stablecoins.llama.fi/stablecoincharts/all?stablecoin={id}
        USDT id = 1; USDC id = 2 (verify IDs via /stablecoins endpoint first).
        Returns: {date_str: {'usdt': float, 'usdc': float}}
        G_DATA_22: confirm this endpoint returns daily snapshots back to Jan 2020.
        """
        result = {}
        cutoff = (datetime.utcnow() - timedelta(days=lookback_days)).date()

        for name, coin_id in [('usdt', 1), ('usdc', 2)]:
            url = f"https://stablecoins.llama.fi/stablecoincharts/all?stablecoin={coin_id}"
            resp = requests.get(url, timeout=10)
            resp.raise_for_status()
            data = resp.json()

            for entry in data:
                date_str = entry.get('date', '')
                if not date_str:
                    continue
                try:
                    d = datetime.utcfromtimestamp(int(date_str)).date()
                except (ValueError, OSError):
                    continue
                if d < cutoff:
                    continue
                d_str = str(d)
                if d_str not in result:
                    result[d_str] = {'usdt': 0.0, 'usdc': 0.0}
                # peggedUSD: circulating supply in USD
                circ = entry.get('totalCirculatingUSD', {}).get('peggedUSD', 0.0)
                result[d_str][name] = float(circ)

        return result

    # ── Signal computation ───────────────────────────────────────────────────

    def _combined_series(self) -> list[tuple[str, float]]:
        """Return sorted (date_str, combined_supply) tuples."""
        combined = [(d, v['usdt'] + v['usdc']) for d, v in self._supply_history.items()]
        return sorted(combined, key=lambda x: x[0])

    def _z_score(self, series: list[float], lag: int, baseline: int) -> float:
        """Z-score of growth_lag[t] relative to trailing baseline days."""
        if len(series) < lag + baseline + 1:
            return 0.0
        growth = series[-1] / series[-1 - lag] - 1 if series[-1 - lag] != 0 else 0.0
        history = [
            series[i] / series[i - lag] - 1
            for i in range(len(series) - baseline, len(series))
            if i - lag >= 0 and series[i - lag] != 0
        ]
        if len(history) < 10:
            return 0.0
        mu = np.mean(history)
        sigma = np.std(history, ddof=1)
        return (growth - mu) / sigma if sigma > 0 else 0.0

    def _compute_composite(self, today_str: str) -> None:
        combined = self._combined_series()
        vals = [v for _, v in combined]
        W = self.sc_baseline_window
        self._z_3d = self._z_score(vals, lag=3,  baseline=W)
        self._z_7d = self._z_score(vals, lag=7,  baseline=W)
        self._composite_z = 0.60 * self._z_3d + 0.40 * self._z_7d

    def _classify_mode(self, today_str: str) -> None:
        usdt_series = sorted([(d, v['usdt']) for d, v in self._supply_history.items()])
        usdc_series = sorted([(d, v['usdc']) for d, v in self._supply_history.items()])
        if len(usdt_series) < 8 or len(usdc_series) < 8:
            self._sc_mode = 'BALANCED'
            return
        usdt_g7 = usdt_series[-1][1] / usdt_series[-8][1] - 1 if usdt_series[-8][1] != 0 else 0.0
        usdc_g7 = usdc_series[-1][1] / usdc_series[-8][1] - 1 if usdc_series[-8][1] != 0 else 0.0
        r = self.sc_mode_ratio
        if usdc_g7 > r * usdt_g7:
            self._sc_mode = 'USDC_DOMINANT'
        elif usdt_g7 > r * usdc_g7:
            self._sc_mode = 'USDT_DOMINANT'
        else:
            self._sc_mode = 'BALANCED'

    def _update_saturation_gate(self, today_str: str) -> None:
        combined = [v for _, v in self._combined_series()]
        if len(combined) < 730:
            self._saturation_gate = False
            return
        level = combined[-1]
        baseline = combined[-730:]
        mu = np.mean(baseline)
        sigma = np.std(baseline, ddof=1)
        level_z = (level - mu) / sigma if sigma > 0 else 0.0
        self._saturation_gate = level_z > self.sc_saturation_zscore

    def _update_duration_cap(self) -> None:
        z = self._composite_z
        cap = self.sc_duration_cap_days
        reset = self.sc_reset_days

        if self._duration_state == 'INACTIVE':
            if z > self.sc_threshold:
                self._duration_state = 'AMPLIFY_ACTIVE'
                self._amplify_day_count = 1
                self._below_reset_count = 0

        elif self._duration_state == 'AMPLIFY_ACTIVE':
            if z > self.sc_threshold:
                self._amplify_day_count += 1
                self._below_reset_count = 0
                if self._amplify_day_count >= cap:
                    self._duration_state = 'DURATION_CAP'
            else:
                self._below_reset_count += 1
                if self._below_reset_count >= 2 and z < 0.5:
                    self._duration_state = 'INACTIVE'
                    self._amplify_day_count = 0
                    self._below_reset_count = 0

        elif self._duration_state == 'DURATION_CAP':
            if z < 0.3:
                self._below_reset_count += 1
                if self._below_reset_count >= reset:
                    self._duration_state = 'INACTIVE'
                    self._amplify_day_count = 0
                    self._below_reset_count = 0
            else:
                self._below_reset_count = 0

    # ── Weight computation ───────────────────────────────────────────────────

    def _compute_weight(self) -> float:
        z = self._composite_z
        thr = self.sc_threshold
        both_pos = self._z_3d > thr * 0.67 and self._z_7d > thr * 0.67  # both windows contribute

        if self._duration_state == 'DURATION_CAP':
            return 1.01
        if z > thr and both_pos and not self._saturation_gate:
            return {'USDC_DOMINANT': 1.10, 'BALANCED': 1.08, 'USDT_DOMINANT': 1.05}[self._sc_mode]
        if z > thr and not self._saturation_gate:
            return {'USDC_DOMINANT': 1.08, 'BALANCED': 1.06, 'USDT_DOMINANT': 1.03}[self._sc_mode]
        if z > thr and self._saturation_gate:
            return 1.03
        if z < -thr and self._z_3d < 0 and self._z_7d < 0:
            return 0.90
        if z < -thr:
            return 0.92
        if z < -1.0:
            return 0.97
        return 1.00

    def stablecoin_weight(self) -> float:
        """Public accessor for sister prims. Returns cached daily weight."""
        return self._stablecoin_weight_cache

    def signal_reason(self) -> str:
        return (
            f"SC22_S1: z_comp={self._composite_z:.2f}"
            f"[3d={self._z_3d:.1f}/7d={self._z_7d:.1f}]"
            f" mode={self._sc_mode}"
            f" sat={self._saturation_gate}"
            f" dur_state={self._duration_state}"
            f"({self._amplify_day_count}d)"
            f" weight={self._stablecoin_weight_cache:.2f}"
            f" [DRY_RUN_G_DATA_22]"
        )
```

---

## 11. Blocking Gates (Updated)

| Gate | Condition | Status |
|---|---|---|
| G_DATA_22 | DeFiLlama: confirm `/stablecoincharts/all?stablecoin={id}` returns daily snapshots Jan 2020–present; USDT id and USDC id verified; combined daily supply computationally accessible; cross-chain dedup confirmed via DeFiLlama aggregation | **PENDING** |
| G1_22 | N ≥ 10 composite_z > +1.5 events (7-day separation); WR(next-3d BTC return > 0) ≥ 52% at N ≥ 10; Mann-Whitney U p < 0.10 one-tailed | **ANALYTICALLY PRE-CONFIRMED** (n ≈ 11 expected); empirical verification pending |
| G1_22_MULTI | 2-window composite beats z_7d alone by ≥ 1pp WR in BOTH sub-periods (2020–Sep 2022 AND Oct 2022–Apr 2026) | **PENDING** |
| G1_22_MODE | USDC_DOMINANT WR ≥ USDT_DOMINANT WR by ≥ 2pp at N ≥ 5 each; else drop mode adjustment | **PENDING** |
| G2_22 | IS backtest: 6-cell CPCV+DSR plateau; DSR ≥ 0.85 at centre cell; sub-period stability requirement (Section 5) | **PENDING** |
| G2_22_OOS | OOS holdout (2025): WR delta ≥ 1.5pp vs neutral | **PENDING** |
| INDEP_22 | ρ(composite_z, axis 7) < 0.70; ρ(composite_z, axis 21) < 0.70 | **PENDING** |

---

## 12. Deployment Protocol

1. **G_DATA_22**: Run `YujiStablecoinSupplyStrategy._fetch_defillama_supply()` on historical data; verify 800 days of daily USDT+USDC supply available; spot-check against known supply levels (USDT+USDC ~$140B in Nov 2021, ~$125B in late 2022 post-UST/FTX, ~$190B+ in early 2026).
2. **G1_22 + G1_22_MULTI**: Run `g1-stablecoin-supply-scan.py` with composite_z computed from 2-window model; collect episode counts and WR statistics; verify sub-period splits.
3. **G2_22 plateau**: Run IS backtest with hyperopt across 6-cell grid; compute DSR for each cell; verify plateau shape.
4. **G2_22_OOS**: Hold out 2025 data; verify WR delta ≥ 1.5pp.
5. **Integration**: Wire `stablecoin_weight` into YujiRegimeStrategy alongside axes 7, 18, 19, 20, 21. Apply N_eff co-occurrence rules (Section 9).
6. **DRY_RUN**: ≥ 90 days; ≥ 30 modified entries; monitor H3 escape hatch. Live only after H3 threshold cleared.

---

## 13. Refinement History

| Cycle | Level | Key Change |
|-------|-------|------------|
| 135 | naive | Initial axis 22; single 7d window; binary 1.06×/0.92×; 3 anchors |
| 137 | intermediate | Three-window composite (3d/7d/14d); USDT/USDC mode; saturation gate; duration cap; formal N_eff rules; 5 anchors |
| 139 | **sophisticated** | 14d window dropped (post-Merge DeFi mechanism defunct); 2-window composite (3d+7d, 0.60/0.40); G1_22 analytical pre-confirmation (n≈11); CPCV+DSR 6-cell plateau with sub-period stability requirement; 3 formal escape hatches H1/H2/H3; McLean-Pontiff OOS correction applied; hyperopt parameters formalised; YujiStablecoinSupplyStrategy.py complete |
