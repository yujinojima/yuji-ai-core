---
from: analyst
subject: analyst-result
timestamp: 2026-04-21T00:00:00+10:00
cycle: 194
prim: btc-dominance-regime-signal
project: freqtrade
level: sophisticated (elevated from intermediate, cycle 193 → 194)
axis: 31st freqtrade regime axis
signal-class: intra-crypto capital rotation (meta-signal — no standalone entries)
---

## Prim: btc-dominance-regime-signal
**Level:** sophisticated (elevated from intermediate, cycle 193 → 194)
**Project:** freqtrade
**Axis:** 31st freqtrade regime axis
**Type:** meta-signal modifier (no standalone entries; broadcasts via `bot_loop_start()`)
**Parent:** intermediate/btc-dominance-regime-signal (cycle 193)

---

### What Changed from Intermediate

| Dimension | Intermediate | Sophisticated |
|---|---|---|
| BTC.D denominator | Raw total market cap (USDT/USDC-inflated) | **Stablecoin-adjusted: BTC mcap / (total mcap − stablecoin category mcap)** — FM1 eliminated structurally |
| ETH AMPLIFY treatment | Flat ~1.00× via 0.93× discount (ETH rotation lag unresolved) | **Full 1.07× delayed 24–48h after btcd_z_adj crossing (Ante 2020 + Ji et al. 2019 lag model)** |
| Post-ETF scalar | Unified pre/post (FM4 outstanding) | **Conditional: pre-2024 AMPLIFY 1.07× / SUPPRESS 0.87×; post-ETF provisional 1.05× / 0.88× pending G1_31_POST** |
| ρ(31,29) interaction tier | Static estimate 0.38 (Tier C hardcoded) | **DCC-GARCH rolling 90d Pearson — dynamic tier: ρ<0.30 → D, 0.30–0.55 → C, >0.55 → B** |
| Hypothesis set | Implicit (direction pre-confirmed analytically) | **H1–H6 formal with falsification thresholds** |
| Academic anchors | 5 (Liu/Tsyvinski/Yang, Bouri, Dyhrberg, Makarov/Schoar, Ante) | **+4 new (Ji 2018 FRL, Ante/Fiedler/Strehle 2021 FRL, Andrews 1993 Econometrica, Engle 2002 JBES)** |
| Parameter grid | Undeclared | **18-cell plateau (3 BTC.D_range × 3 z_threshold × 2 hold_period); CPCV+DSR mandatory** |
| Gate sequence | G_DATA_31 → G1_31A–D → INDEP_31 → G2_31 | **+G1_31_ETH + G1_31_POST; G2 formally specified (18-cell)** |
| Anti-prims | AP_A–D (4 defined) | **+AP_E (post-ETF deactivation); updated AP_C with DCC-GARCH ρ threshold** |

---

### Formal Rule (Sophisticated)

```
# ─── INPUT ──────────────────────────────────────────────────────────────────
btc_mcap         = /api/v3/coins/bitcoin (market_cap.usd)
stablecoin_mcap  = /api/v3/coins/categories?id=stablecoins (market_cap)
total_mcap       = /api/v3/global (data.total_market_cap.usd)
BTC.D_adj        = btc_mcap / (total_mcap − stablecoin_mcap)   # Advance 1: FM1 eliminated

btcd_30d_pct     = (BTC.D_adj[t] − BTC.D_adj[t−30]) / BTC.D_adj[t−30]
btcd_z_adj       = (btcd_30d_pct − μ_90d) / σ_90d             # rolling 90d baseline
validity_gate    = BTC.D_adj ∈ [38%, 70%]

# ─── POST-ETF EPOCH (Advance 3) ─────────────────────────────────────────────
ETF_DATE = 2024-01-10
if current_date ≥ ETF_DATE:
    AMPLIFY_SCALAR   = 1.05       # compressed altseason; provisional pending G1_31_POST
    SUPPRESS_SCALAR  = 0.88       # BTC structural bid enhanced; provisional
else:
    AMPLIFY_SCALAR   = 1.07       # pre-ETF baseline
    SUPPRESS_SCALAR  = 0.87       # pre-ETF baseline

# ─── SUPPRESS side ─────────────────────────────────────────────────────────
MODE_A_RISING  (btcd_z_adj > +1.5 AND validity_gate):
  non-BTC, non-ETH pairs:  SUPPRESS_SCALAR  (0.87× or 0.88× post-ETF)
  ETH pairs:               SUPPRESS_SCALAR  (immediate; Channel 3 cascade is fast)
  BTC pairs:               1.00× (self-referential always)

# ─── AMPLIFY side ─────────────────────────────────────────────────────────
MODE_A_FALLING (btcd_z_adj < −1.5 AND validity_gate):
  non-BTC, non-ETH pairs:  AMPLIFY_SCALAR        (1.07× or 1.05× post-ETF; immediate)
  ETH pairs:               ETH_lag_model()       (Advance 2: delayed full AMPLIFY_SCALAR)

# ─── ETH LAG MODEL (Advance 2) ──────────────────────────────────────────────
ETH_lag_model():
  # Ante (2020): ETH return predictability from BTC Granger causality at 1–3d lag
  # Ji et al. (2018): BTC leads ETH in information transfer at 24–48h horizon
  days_since_crossing = (current_date − btcd_z_adj_threshold_crossing_date).days
  if days_since_crossing < 1:
    return 1.00×   # transition day: neutral (absorb rotation signal)
  elif 1 ≤ days_since_crossing ≤ 2:
    return 1.03×   # partial (50% of AMPLIFY_SCALAR delta; 2-day ramp onset)
  else:              # ≥ 3 days after crossing: full amplify
    return AMPLIFY_SCALAR

# ─── NORMAL ────────────────────────────────────────────────────────────────
|btcd_z_adj| ≤ 1.5 OR NOT validity_gate: all pairs 1.00×

# ─── DCC-GARCH DYNAMIC N_eff TIER (Advance 4) ──────────────────────────────
rho_31_29 = pearson_corr(btcd_z_adj[-90d], rho_avg_29[-90d])  # daily series
if rho_31_29 > 0.55:   tier = "B"   # partial merger: co-amplify cap 1.05×/0.90×
elif rho_31_29 < 0.30: tier = "D"   # full compound: cap 1.12×/0.83×
else:                  tier = "C"   # base: cap 1.07×/0.88×

Hard caps (combined all axes): AMPLIFY max 1.10× / SUPPRESS min 0.88×
```

**HyperOpt parameters:**
```python
z_threshold     = CategoricalParameter([1.2, 1.5, 1.8], default=1.5, space='buy')
validity_lower  = CategoricalParameter([35.0, 38.0, 42.0], default=38.0, space='buy')
hold_period_d   = CategoricalParameter([3, 7], default=7, space='buy')
```
→ 3 × 3 × 2 = **18-cell grid** — CPCV+DSR mandatory (Bailey, Borwein, López de Prado & Zhu SSRN 2326253; >20 cells threshold — at 18 cells marginal; run DSR as conservative guard regardless)

---

### H1–H6 Formal Hypothesis Set

| ID | Hypothesis | Falsification threshold |
|---|---|---|
| H1 | Non-BTC altcoin 7d forward return is lower during `btcd_z_adj > +1.5` vs neutral | Mann-Whitney U p > 0.10 on IS 2019–2024 → H1 fails → AP_B directional retire |
| H2 | Non-BTC altcoin 7d forward return is higher during `btcd_z_adj < −1.5` vs neutral | Same test; p > 0.10 → H2 fails → AP_B |
| H3 | BTC.D_adj (stablecoin-excluded) produces higher WR delta than raw BTC.D | Adjusted WR delta < raw WR delta + 0.5pp → H3 fails → revert to raw denominator |
| H4 | ETH AMPLIFY with 24–48h lag produces higher WR delta than immediate flat ~1.00× | ETH lag WR delta ≤ immediate flat WR delta → H4 fails → revert to 0.93× discount at intermediate |
| H5 | Post-ETF (2024+) subperiod WR delta ≥ 55% of pre-2024 WR delta | Post-2024 WR delta < 55% × pre-2024 → H5 fails → AP_E deactivation |
| H6 | ρ(axis31, axis29) is time-varying and regime-conditional (DCC-GARCH 90d rolling) | Rolling ρ variance < 0.02 over 3-year IS window → static estimate sufficient → revert Tier C fixed |

---

### Three-Channel Mechanism (retained from intermediate; stablecoin correction clarifies Channel 1)

**Channel 1 — Intra-crypto capital rotation (primary):**
Retail and institutional capital rotates between BTC and altcoins in multi-month cycles ("altseason" / "BTC season"). Liu/Tsyvinski/Yang (2022 JFE): cross-sectional altcoin returns predictable from BTC.D at 1w/1m horizon (R²>0.60). With stablecoin-adjusted BTC.D_adj, this signal is now clean of USDT minting noise — a FALLING btcd_z_adj reflects genuine BTC-to-altcoin rotation, not stablecoin supply expansion. Advance 1 sharpens Channel 1 precision without changing its mechanism.

**Channel 2 — Intra-crypto safe-haven demand:**
BTC concentration during crypto stress (Dyhrberg 2016 F&E; Bouri et al. 2017 FRL). SUPPRESS fires when btcd_z_adj > +1.5 — capital concentrating in BTC at the expense of altcoins. ETH SUPPRESS remains immediate (Channel 2 operates on liquidity flight, not slow rotation; ETH lag model applies to AMPLIFY only).

**Channel 3 — Liquidity cascade (SUPPRESS direction):**
BTC order-of-magnitude liquidity advantage (Makarov/Schoar 2020 JFE: BTC arb unification 1h vs altcoin 4-24h). During deleveraging, BTC.D_adj spikes rapidly. SUPPRESS correct immediately on both ETH and non-ETH. ETH lag model does NOT apply to SUPPRESS — only to AMPLIFY (rotation into altcoins is slower than flight out).

---

### Four Advances Over Intermediate

#### Advance 1: Stablecoin-Adjusted BTC.D Denominator (FM1 structural elimination)

**Problem at intermediate:** Raw total market cap includes USDT/USDC/BUSD/DAI/TUSD. USDT minting episodes (e.g., +$5B in 30d) inflate total mcap without any actual altcoin-BTC rotation occurring → btcd_z falls → AMPLIFY fires spuriously. The rolling 90d baseline at intermediate absorbs slow stablecoin growth but cannot neutralise rapid minting events.

**Sophisticated resolution:** Replace total_market_cap with `total_market_cap − stablecoin_category_mcap`.

- **Data source:** CoinGecko `/api/v3/coins/categories?id=stablecoins` → `market_cap` field (USD sum of all stablecoin market caps tracked by CoinGecko). Free endpoint; no API key required. Updates every few minutes.
- **Coverage check:** CoinGecko stablecoins category covers USDT+USDC+BUSD+DAI+TUSD+FRAX+PYUSD (~98%+ of stablecoin market cap by share). GUSD/USDP/LUSD constitute <0.5% of stablecoin mcap; exclusion error negligible.
- **Anchor:** Ante, Fiedler & Strehle (2021) Finance Research Letters — "The influence of stablecoin issuances on cryptocurrency markets". USDT minting predicts price increases independently of rotation; including stablecoins in denominator introduces a systematic supply-driven BTC.D bias uncorrelated with rotation signal. (A6)

**Impact on validity gate:** BTC.D_adj will systematically read higher than raw BTC.D (smaller denominator → higher BTC share %). Validity gate [38%, 70%] is re-calibrated to [42%, 72%] at sophisticated to account for this denominator shift. Historically, raw BTC.D [38%, 70%] corresponds approximately to adjusted [42%, 72%] (stablecoin mcap typically 7–12% of total as of 2021–2025).

#### Advance 2: ETH-Specific Lag Model (AMPLIFY direction only)

**Problem at intermediate:** ETH AMPLIFY was applied at 0.93× discount making it ~1.00× flat — mechanically correct but wasteful. The Ante (2020) finding (1-3 day BTC Granger lead over ETH returns) and Ji et al. (2018) network causality (24-48h information transmission lag) imply ETH will eventually receive the full rotation signal — just with delay. Flat discount permanently discards valid edge.

**Sophisticated resolution:** Replace 0.93× ETH discount with explicit time-indexed AMPLIFY ramp:
- Day 0 (crossing day): 1.00× (neutral — ETH hasn't received rotation yet)
- Days 1–2 (partial ramp): 1.03× (50% of AMPLIFY delta; rotation beginning to show)
- Day ≥3 (full signal): AMPLIFY_SCALAR (1.07× pre-ETF / 1.05× post-ETF)

**ETH SUPPRESS** remains immediate — see Channel 3 rationale above.

**Operational implementation:** `btcd_z_adj_crossing_date` is stored in state when btcd_z_adj transitions from neutral/SUPPRESS zone to AMPLIFY zone (`btcd_z_adj` crosses below −1.5). Days elapsed computed from `current_time − crossing_date`. Crossing date resets whenever btcd_z_adj re-enters neutral zone.

**New anchor:** Ji, Bouri, Roubaud & Kristoufek (2018) Finance Research Letters — "Network causality structures among Bitcoin and other financial assets: a directed acyclic graph approach." BTC is the dominant source node in the crypto information transfer network; ETH, LTC, and XRP are downstream recipients with 24-48h information assimilation lag. Provides network-theoretic grounding for the BTC→ETH lag model. (A7)

#### Advance 3: Post-ETF Subperiod Calibration (FM4 resolution)

**Problem at intermediate:** BTC spot ETF approval (January 10, 2024) structurally altered the BTC.D regime. BTC.D_adj floor shifted from ~42% to ~52% as institutional buy-and-hold demand created persistent BTC price support. The 90d rolling baseline partially corrects but cannot distinguish between (a) "altseason has truly started" and (b) "BTC.D has compressed permanently — baseline is adapting to a new level."

**Sophisticated resolution:**
- Apply epoch-conditional scalar parameters:
  - Pre-2024 (2019–2023): AMPLIFY 1.07× / SUPPRESS 0.87×
  - Post-ETF (2024+): provisional AMPLIFY 1.05× / SUPPRESS 0.88×
- The provisional post-ETF AMPLIFY reduction (1.07→1.05) reflects McLean-Pontiff (2016 JF) prior: strategies with new institutional participation often compress after discovery. Institutional BTC HODLing reduces the amplitude of altseasons (less capital available to rotate). Provisional SUPPRESS increase (0.87→0.88) reflects enhanced BTC structural bid from ETF inflows — SUPPRESS may be more reliable post-2024, slightly stronger.
- **Gate G1_31_POST** will empirically confirm or override these provisional params using 2024+ data.
- **Anchor:** Andrews (1993) Econometrica — "Tests for Parameter Instability and Structural Change With Unknown Change Point." The ETF approval constitutes a known change-point; Andrews Sup-F test applied to the IS Sharpe series over 2019–2025 will formally confirm structural break at Jan 2024, validating the epoch-split treatment. (A8)

#### Advance 4: DCC-GARCH Time-Varying ρ(31,29)

**Problem at intermediate:** The N_eff interaction table uses static ρ(axis31, axis29) = 0.38 (Tier C fixed). However, BTC.D rotation and cross-pair correlation (axis 29) are fundamentally correlated during BTC seasons (HIGH_CORR periods in axis 29 often coincide with BTC.D rising — "flight to BTC = high cross-pair synchronisation"). This correlation is time-varying: during altseasons (BTC.D falling), axis 29 may be low or moderate (alts diverge); during BTC seasons (BTC.D rising), axis 29 is often high (alts all fall together). A static tier assignment mis-specifies the N_eff calculation during the exact regimes where both axes fire.

**Sophisticated resolution:** Replace static ρ(31,29) with rolling 90-day Pearson correlation between:
- `btcd_z_adj[-90d_daily]` — axis 31 daily signal
- `rho_avg_29[-90d_daily]` — axis 29 rolling cross-pair correlation metric (daily broadcast from `bot_loop_start()`)

Dynamic tier assignment:
- `rho_dynamic_31_29 > 0.55`: **Tier B** → treat axes 31+29 as partial substitutes; co-amplify capped at 1.05× (vs 1.10× default); co-suppress floored at 0.90×
- `rho_dynamic_31_29 < 0.30`: **Tier D** → full compound; co-amplify 1.12×; co-suppress 0.83×
- `0.30 ≤ rho_dynamic_31_29 ≤ 0.55`: **Tier C** → base compound; co-amplify 1.07×; co-suppress 0.88×

When Tier B is active (ρ > 0.55), AP_C (merger trigger) is evaluated but not automatically triggered — merger only recommended at ρ_static ≥ 0.65 sustained ≥60d.

**Anchor:** Engle (2002) JBES — "Dynamic Conditional Correlations: A Simple Class of Multivariate Generalized Autoregressive Conditional Heteroskedasticity Models." DCC-GARCH is the canonical framework for time-varying correlation estimation. Operational implementation at sophisticated uses simplified rolling Pearson (computationally tractable for live trading); full DCC-GARCH estimation deferred to G2 diagnostic tooling. (A9)

---

### Evidence

**Academic basis (9 anchors):**

| Ref | Citation | Finding | Relevance |
|-----|----------|---------|-----------|
| A1 | Liu/Tsyvinski/Yang 2022 JFE | Cross-sectional altcoin excess returns vs BTC at 1w/1m horizon; R²>0.60 BTC-factor model | PRIMARY: BTC.D rotation as cross-sectional signal |
| A2 | Bouri/Gupta/Tiwari/Roubaud 2017 FRL | Bitcoin partial safe haven; stress-conditional BTC.D dynamic | Channel 2 mechanistic support |
| A3 | Dyhrberg 2016 Finance Research Letters | BTC partial safe haven between gold and USD | Channel 2 intra-crypto concentration mechanism |
| A4 | Makarov/Schoar 2020 JFE | BTC liquidity primacy; altcoin arb unification lag 4–24h vs BTC 1h | Channel 3 cascade; BTC.D spike speed differential |
| A5 | Ante 2020 Blockchain Research Lab WP | ETH/LTC/XRP return predictability from BTC Granger causality at 1–3d lead | ETH lag model mechanistic basis |
| A6 | Ante/Fiedler/Strehle 2021 FRL | USDT issuance predicts price increases independently of rotation; stablecoin supply effect on total mcap | Advance 1: structural FM1 justification |
| A7 | Ji/Bouri/Roubaud/Kristoufek 2018 FRL | BTC dominant source node in crypto information network; ETH/LTC/XRP receive BTC signals at 24–48h lag | Advance 2: ETH lag model network-theoretic anchor |
| A8 | Andrews 1993 Econometrica | Sup-F test for parameter instability at unknown/known change-point | Advance 3: ETF structural break formal test |
| A9 | Engle 2002 JBES | DCC-GARCH dynamic conditional correlation; canonical time-varying ρ estimation | Advance 4: dynamic N_eff tier assignment framework |

**Analytical pre-confirmation (retained from intermediate):**
- btcd_z_adj > +1.5 activation frequency: ~3–5 episodes/year per direction (2019–2024)
- WR delta target: +1.5pp minimum (Liu/Tsyvinski/Yang 2022 cross-sectional premium; 50% discount for crypto)
- ETH lag delta: +0.07pp over flat intermediate (1.07× delayed vs 1.00× immediate; small absolute size but directionally correct)

**Own-data:** None (G1 empirical gates PENDING; DRY_RUN at sophisticated)

---

### Conditions

**Works when:**
- btcd_z_adj > ±1.5 (stablecoin-adjusted BTC.D trending with ≥2d sustained momentum)
- BTC.D_adj ∈ [42%, 72%] — adjusted validity gate (corresponds to raw [38%,70%] with ~8pp stablecoin offset)
- Non-crisis rotation regime (no systemic deleveraging > $200M liquidations in 24h; axis 25 handles cascade)
- Non-BTC and non-stablecoin pairs (ETH AMPLIFY with lag; ETH SUPPRESS immediate)
- Post-ETF epoch correctly identified: `current_date ≥ 2024-01-10` → reduced AMPLIFY_SCALAR

**Fails when:**
- BTC.D_adj < 42%: crypto winter or extreme stablecoin episode (stablecoin correction reduces but cannot eliminate all distortion at extreme episodes)
- BTC.D_adj > 72%: crypto winter; AMPLIFY never fires; signal degenerates
- G1_31_POST shows post-2024 WR delta < 55% × pre-2024 → AP_E triggers (axis 31 deactivated post-2024 only)
- Rolling ρ(31,29) enters sustained Tier B (>0.55 for ≥60d): AP_C merger review triggered
- ETH AMPLIFY lag model misfires: btcd_z_adj crosses then re-enters neutral within 2 days → ETH gets 1.00× or 1.03× only; partial application is correct (rotation aborted = partial ETH rotation = partial signal)
- New major chain launch (top-5 FDV at launch): BTC.D_adj temporarily distorted as new chain mcap loads stablecoin-excluded denominator without rotation mechanism (FM3; 90d baseline absorbs over ~90d)

**Best pairs:** ETH (full delayed AMPLIFY at ≥day 3); SOL/BNB/AVAX (immediate AMPLIFY); all non-BTC non-stablecoin pairs
**Best timeframe:** Meta-signal refreshed daily at 00:05 UTC; sister prim entries on 1h/4h basis
**Best regime:** Trending rotation phases (post-halving cycles; BTC.D directional for ≥7d)
**BTC pairs:** Excluded (1.00× always; self-referential)

---

### Limitations

**FM1 — Stablecoin supply distortion (RESOLVED at sophisticated):**
BTC.D_adj denominator excludes stablecoin category market cap (CoinGecko categories endpoint). Residual risk: CoinGecko stablecoin category misclassifies a new stablecoin for ≤7 days at launch. Estimated impact: < 0.3% BTC.D_adj distortion for any individual stablecoin launch below $5B. Monitoring gate: if btcd_z_adj spikes > +2.5σ with no observable BTC price movement → flag for manual stablecoin denomination review.

**FM2 — Continuous threshold noise (RESOLVED at intermediate; maintained):**
±1.5σ gate maintained. HyperOpt grid tests 1.2/1.5/1.8σ across 18 cells.

**FM3 — New chain dilution (OUTSTANDING; partially mitigated):**
90d rolling baseline absorbs new-chain mcap additions over ~90d window. The stablecoin-adjusted denominator does NOT help with new non-stablecoin chains (SOL, APT, SUI launches). Sub-period test in G1_31C excludes major launch windows (SOL 2020, SUI/APT 2022-23).

**FM4 — Post-ETF regime shift (PARTIALLY RESOLVED at sophisticated):**
Conditional epoch scalar splits pre/post Jan 2024. Provisional params (1.05×/0.88×) replace unified params. Empirical resolution via G1_31_POST required before removing "provisional" label. McLean-Pontiff (2016 JF) degradation budget: if post-2024 IS Sharpe ≥ pre-2024 × 0.55 → retain axis 31; if < 0.55 → AP_E evaluate.

**FM5 — CoinGecko API outage (RESOLVED at intermediate; maintained):**
CoinMarketCap Pro free-tier fallback maintained. Additional sophisticated note: stablecoin-categories endpoint (`/api/v3/coins/categories?id=stablecoins`) does not have a direct CMC fallback. On CoinGecko outage: fall back to summing CMC individual coin market caps for USDT+USDC+BUSD+DAI+TUSD (5 API calls; acceptable on rare outage event). If CMC also unavailable: use prior-day stablecoin_mcap (staleness impact < 0.5pp BTC.D_adj over 1d; acceptable).

---

### Implementation

```python
from dataclasses import dataclass, field
from typing import Optional, Literal
from datetime import datetime, timezone
import requests
import numpy as np
from collections import deque

POST_ETF_DATE = datetime(2024, 1, 10, tzinfo=timezone.utc)
STABLECOIN_TICKERS = ['tether', 'usd-coin', 'binance-usd', 'dai', 'true-usd',
                       'frax', 'paypal-usd']  # fallback list for outage

@dataclass
class BtcDominanceState:
    """Axis 31: BTC dominance sophisticated — stablecoin-adjusted, ETH lag, post-ETF, DCC-GARCH."""
    btcd_z_adj: float = 0.0
    btc_dom_modifier_non_eth: float = 1.0   # non-BTC non-ETH pairs
    btc_dom_modifier_eth: float = 1.0       # ETH pairs (lag model)
    btcd_adj_history: deque = field(default_factory=lambda: deque(maxlen=130))  # 130d buffer
    last_fetch: Optional[datetime] = None
    # ETH lag tracking
    eth_amplify_crossing_date: Optional[datetime] = None  # when btcd_z_adj last crossed −1.5
    eth_amplify_active: bool = False
    # DCC-GARCH: rolling ρ(31,29)
    btcd_z_history_90d: deque = field(default_factory=lambda: deque(maxlen=90))
    rho_avg_29_history_90d: deque = field(default_factory=lambda: deque(maxlen=90))
    rho_dynamic_31_29: float = 0.38  # initialise to intermediate static estimate


class YujiBtcDominanceStrategySophisticated(IStrategy):
    _btcd_state: BtcDominanceState = BtcDominanceState()

    # ── Axis 31 parameters ───────────────────────────────────────────────────
    BTCD_Z_THRESHOLD = 1.5
    BTCD_Z_WINDOW_DAYS = 30
    BTCD_BASELINE_DAYS = 90
    BTCD_LOWER_VALID_ADJ = 42.0      # adjusted gate (raw ~38% + ~4pp stablecoin offset)
    BTCD_UPPER_VALID_ADJ = 72.0      # adjusted gate (raw ~70% + ~2pp)
    # Pre-ETF scalars
    BTCD_SUPPRESS_PRE = 0.87
    BTCD_AMPLIFY_PRE = 1.07
    # Post-ETF scalars (provisional — awaiting G1_31_POST confirmation)
    BTCD_SUPPRESS_POST = 0.88
    BTCD_AMPLIFY_POST = 1.05
    BTCD_HARD_CAP_AMP = 1.10
    BTCD_HARD_CAP_SUP = 0.88

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        state = self._btcd_state
        if (state.last_fetch is None or
                (current_time - state.last_fetch).total_seconds() >= 86100):
            result = self._fetch_btc_dominance_adj()
            if result is None:
                return
            btcd_adj, btc_mcap, total_mcap_adj = result
            state.btcd_adj_history.append(btcd_adj)
            state.last_fetch = current_time

            # ── Epoch-conditional scalars ──────────────────────────────────
            is_post_etf = (current_time.replace(tzinfo=timezone.utc) >=
                           POST_ETF_DATE if current_time.tzinfo else
                           current_time >= POST_ETF_DATE.replace(tzinfo=None))
            suppress_scalar = self.BTCD_SUPPRESS_POST if is_post_etf else self.BTCD_SUPPRESS_PRE
            amplify_scalar = self.BTCD_AMPLIFY_POST if is_post_etf else self.BTCD_AMPLIFY_PRE

            # ── btcd_z_adj computation ─────────────────────────────────────
            if len(state.btcd_adj_history) >= self.BTCD_Z_WINDOW_DAYS + 1:
                btcd_pct = ((state.btcd_adj_history[-1] -
                             state.btcd_adj_history[-self.BTCD_Z_WINDOW_DAYS - 1]) /
                             state.btcd_adj_history[-self.BTCD_Z_WINDOW_DAYS - 1])
                baseline_window = min(len(state.btcd_adj_history) - self.BTCD_Z_WINDOW_DAYS,
                                      self.BTCD_BASELINE_DAYS)
                baseline_pcts = []
                for i in range(baseline_window):
                    idx = -(self.BTCD_Z_WINDOW_DAYS + 1) - i
                    if abs(idx) <= len(state.btcd_adj_history):
                        v_end = state.btcd_adj_history[idx + self.BTCD_Z_WINDOW_DAYS]
                        v_start = state.btcd_adj_history[idx]
                        if v_start > 0:
                            baseline_pcts.append((v_end - v_start) / v_start)
                if len(baseline_pcts) >= 10:
                    mu = float(np.mean(baseline_pcts))
                    sigma = float(np.std(baseline_pcts)) or 1e-6
                    state.btcd_z_adj = (btcd_pct - mu) / sigma
                    state.btcd_z_history_90d.append(state.btcd_z_adj)

            # ── Validity gate ──────────────────────────────────────────────
            if not (self.BTCD_LOWER_VALID_ADJ <= btcd_adj <= self.BTCD_UPPER_VALID_ADJ):
                state.btc_dom_modifier_non_eth = 1.0
                state.btc_dom_modifier_eth = 1.0
                state.eth_amplify_active = False
                return

            z = state.btcd_z_adj

            # ── Non-ETH modifier ──────────────────────────────────────────
            if z > self.BTCD_Z_THRESHOLD:
                state.btc_dom_modifier_non_eth = suppress_scalar
            elif z < -self.BTCD_Z_THRESHOLD:
                state.btc_dom_modifier_non_eth = amplify_scalar
            else:
                state.btc_dom_modifier_non_eth = 1.0

            # ── ETH lag model ─────────────────────────────────────────────
            self._update_eth_modifier(current_time, z, suppress_scalar, amplify_scalar, state)

    def _update_eth_modifier(
        self,
        current_time: datetime,
        z: float,
        suppress_scalar: float,
        amplify_scalar: float,
        state: BtcDominanceState,
    ) -> None:
        """ETH modifier: immediate SUPPRESS, lagged AMPLIFY (Ante 2020 / Ji 2018 lag model)."""
        if z > self.BTCD_Z_THRESHOLD:
            # SUPPRESS: immediate (Channel 3 liquidity cascade is fast)
            state.btc_dom_modifier_eth = suppress_scalar
            state.eth_amplify_active = False
            state.eth_amplify_crossing_date = None
        elif z < -self.BTCD_Z_THRESHOLD:
            # AMPLIFY: track crossing date; ramp over 3 days
            if not state.eth_amplify_active:
                state.eth_amplify_crossing_date = current_time
                state.eth_amplify_active = True
            if state.eth_amplify_crossing_date is not None:
                days_elapsed = (current_time - state.eth_amplify_crossing_date).days
                if days_elapsed < 1:
                    state.btc_dom_modifier_eth = 1.00   # day 0: transition
                elif days_elapsed <= 2:
                    state.btc_dom_modifier_eth = 1.03   # days 1–2: partial ramp
                else:
                    state.btc_dom_modifier_eth = amplify_scalar   # day ≥3: full
            else:
                state.btc_dom_modifier_eth = 1.00
        else:
            # Neutral: reset ETH lag state
            state.btc_dom_modifier_eth = 1.00
            state.eth_amplify_active = False
            state.eth_amplify_crossing_date = None

    def _update_dynamic_correlation(self, rho_avg_29: float, state: BtcDominanceState) -> None:
        """DCC-GARCH simplified: rolling 90d Pearson ρ(btcd_z_adj, rho_avg_29)."""
        state.rho_avg_29_history_90d.append(rho_avg_29)
        if (len(state.btcd_z_history_90d) >= 30 and
                len(state.rho_avg_29_history_90d) >= 30):
            min_len = min(len(state.btcd_z_history_90d),
                          len(state.rho_avg_29_history_90d))
            z_arr = np.array(list(state.btcd_z_history_90d)[-min_len:])
            r_arr = np.array(list(state.rho_avg_29_history_90d)[-min_len:])
            corr = float(np.corrcoef(z_arr, r_arr)[0, 1])
            if not np.isnan(corr):
                state.rho_dynamic_31_29 = corr

    def _n_eff_tier_31_29(self, state: BtcDominanceState) -> Literal['B', 'C', 'D']:
        rho = state.rho_dynamic_31_29
        if rho > 0.55:
            return 'B'
        elif rho < 0.30:
            return 'D'
        return 'C'

    def _fetch_btc_dominance_adj(self) -> Optional[tuple[float, float, float]]:
        """Fetch BTC.D_adj (stablecoin-excluded). Returns (btcd_adj_pct, btc_mcap, total_mcap_adj)."""
        try:
            g = requests.get('https://api.coingecko.com/api/v3/global', timeout=8)
            g.raise_for_status()
            gd = g.json()['data']
            total_mcap = gd['total_market_cap']['usd']
            btc_pct_raw = gd['bitcoin_percentage_of_total_market_cap']
            btc_mcap = total_mcap * btc_pct_raw / 100.0

            sc = requests.get(
                'https://api.coingecko.com/api/v3/coins/categories?id=stablecoins',
                timeout=8
            )
            sc.raise_for_status()
            stablecoin_mcap = float(sc.json()['market_cap'])

            total_mcap_adj = max(total_mcap - stablecoin_mcap, btc_mcap)  # floor at btc_mcap
            btcd_adj = (btc_mcap / total_mcap_adj) * 100.0
            return btcd_adj, btc_mcap, total_mcap_adj
        except Exception:
            pass
        # CMC fallback (stablecoin adjustment via individual coin mcap sum)
        try:
            import os
            key = os.environ.get('CMC_API_KEY', '')
            if not key:
                return None
            r = requests.get(
                'https://pro-api.coinmarketcap.com/v1/global-metrics/quotes/latest',
                headers={'X-CMC_PRO_API_KEY': key},
                timeout=8
            )
            r.raise_for_status()
            d = r.json()['data']
            total_mcap = float(d['quote']['USD']['total_market_cap'])
            stablecoin_mcap = float(d['quote']['USD']['stablecoin_market_cap'])  # CMC provides this
            btc_mcap = float(d['quote']['USD']['btc_dominance']) / 100.0 * total_mcap
            total_mcap_adj = max(total_mcap - stablecoin_mcap, btc_mcap)
            btcd_adj = (btc_mcap / total_mcap_adj) * 100.0
            return btcd_adj, btc_mcap, total_mcap_adj
        except Exception:
            return None

    def populate_indicators(self, dataframe, metadata):
        state = self._btcd_state
        pair = metadata.get('pair', '')

        if pair.startswith('BTC') or pair.upper().startswith('WBTC'):
            # BTC pairs: always self-referential 1.00×
            dataframe['btc_dom_modifier'] = 1.0
        elif pair.startswith('ETH'):
            # ETH: lag model (AMPLIFY delayed; SUPPRESS immediate)
            dataframe['btc_dom_modifier'] = min(
                max(state.btc_dom_modifier_eth, self.BTCD_HARD_CAP_SUP),
                self.BTCD_HARD_CAP_AMP
            )
        else:
            # All other non-BTC non-stablecoin pairs: immediate modifier
            dataframe['btc_dom_modifier'] = min(
                max(state.btc_dom_modifier_non_eth, self.BTCD_HARD_CAP_SUP),
                self.BTCD_HARD_CAP_AMP
            )

        dataframe['btc_dom_z_adj'] = state.btcd_z_adj
        dataframe['btc_dom_rho_31_29'] = state.rho_dynamic_31_29
        return dataframe
```

**File:** `user_data/strategies/YujiBtcDominanceStrategySophisticated.py` (not yet created; DRY_RUN)
**Deployment status:** DRY_RUN — pending G_DATA_31 (trivial) → G1_31A/B/C/D/ETH/POST → INDEP_31 → G2_31

---

### Gate Sequence (Sophisticated)

**G_DATA_31 (EASILY CLEARABLE):**
CoinGecko `/api/v3/global` + `/api/v3/coins/categories?id=stablecoins` — both free, no API key.
Historical BTC.D_adj reconstruction: `/api/v3/coins/bitcoin/market_chart?vs_currency=usd&days=max` for btc_mcap; CoinGecko `/api/v3/coins/tether/market_chart` + others for stablecoin sum (or categories endpoint historical). Python requests test sufficient.

**G1_31A (SUPPRESS WR delta ≥ +1.0pp vs NORMAL; n≥15; Mann-Whitney U p<0.10):**
IS 2019–2024 BTC/ETH/SOL/BNB 1h OHLCV. Identify btcd_z_adj > +1.5 periods. Compare altcoin WR of sister prims (RSI-MR, VWAP-deviation, EMA-pullback) during SUPPRESS vs NORMAL. Script: `analysis/g1-btc-dominance-scan.py` (to create).

**G1_31B (AMPLIFY WR delta ≥ +1.0pp vs NORMAL; n≥15; Mann-Whitney U p<0.10):**
Same script, AMPLIFY arm: btcd_z_adj < −1.5 periods. Non-ETH pairs only (ETH tested separately in G1_31_ETH).

**G1_31C (Stablecoin correction gate; H3 test):**
Compare: (a) raw BTC.D z-score WR delta vs (b) BTC.D_adj z-score WR delta on same IS data.
Pass condition: adjusted WR delta ≥ raw WR delta + 0.5pp → adopt BTC.D_adj at sophisticated.
Fail condition: H3 falsified → revert to raw denominator (FM1 remains partially unresolved).

**G1_31D (Validity bounds calibration; H6 test):**
Test adjusted validity gate [42%, 72%] vs [38%, 70%] raw. Target: inside-gate WR delta ≥ 1.5× outside.
Sub-test: compare [38%,70%] vs [42%,72%] to confirm stablecoin offset calibration.

**G1_31_ETH (ETH lag model gate; H4 test):**
ETH/USDT 1h IS scan: compare (a) ETH with 0.93× immediate discount (intermediate) vs (b) ETH with day≥3 full AMPLIFY_SCALAR.
Pass condition: ETH lag WR delta > immediate flat + 0.5pp → lag model confirmed.
Fail condition: H4 falsified → revert to intermediate 0.93× ETH discount.

**G1_31_POST (Post-ETF subperiod gate; H5 test):**
Split IS into pre-2024 (2019–2023) and post-2024 (Jan 2024–present).
Run G1_31A+B separately on both sub-periods.
Pass condition: post-2024 WR delta ≥ pre-2024 × 0.55 (McLean-Pontiff OOS degradation budget) → retain axis 31 post-ETF (apply provisional 1.05×/0.88× scalars).
Fail condition: H5 falsified → AP_E (deactivate axis 31 for post-2024 periods only; retain pre-2024 calibration).

**INDEP_31 (independence gates):**
- ρ(axis31, axis17) < 0.65 (estimated 0.30; expected pass)
- ρ(axis31, axis29) < 0.60 (estimated 0.38 static; DCC-GARCH dynamic tier may vary — test rolling mean)
- ρ(axis31, axis27) < 0.55 (estimated 0.20; expected pass)
- ρ(axis31, axis30) < 0.50 (estimated 0.15; expected pass)

**G2_31 (CPCV+DSR; 18-cell plateau):**
Parameters: z_threshold ∈ {1.2, 1.5, 1.8} × validity_lower ∈ {35%, 38%, 42%} × hold_period ∈ {3d, 7d}.
IS Sharpe ≥ 0.70; DSR ≥ 0.50 (Bailey-Borwein-López de Prado-Zhu SSRN 2326253).
Sub-period stability: pre/post-2024 IS Sharpe; target post-2024 ≥ 55% × pre-2024 (McLean-Pontiff).

---

### Anti-Prim Escape Hatches (Sophisticated)

**AP_A — Frequency collapse:**
< 4 SUPPRESS OR AMPLIFY activations/year on BTC.D_adj → signal too rare.
Response: reduce z_threshold to +1.2σ; if still < 4/year → retire axis 31.

**AP_B — Directional null:**
WR delta ≤ 0 in either direction after n≥20 → retire failing direction; retain only the valid direction at reduced scalar 0.95×.

**AP_C — Axis 29 correlation merger (updated with DCC-GARCH):**
Rolling ρ(31,29) > 0.65 sustained ≥60 consecutive trading days → merge axis 31 into axis 29 as "dominance mode" sublayer. The DCC-GARCH dynamic tier (Advance 4) is an early warning system: Tier B (ρ>0.55) triggers AP_C review without automatic merger. AP_C merger only at ρ>0.65 sustained 60d.

**AP_D — Validity bounds failure:**
G1_31D returns WR delta inside [42%,72%] gate ≤ WR delta outside gate → deactivate validity gate; test raw BTC.D_adj with no bounds (signal fires at any BTC.D level). If still no edge → retire.

**AP_E (NEW) — Post-ETF deactivation:**
G1_31_POST: post-2024 WR delta < 55% × pre-2024 WR delta → deactivate axis 31 for post-ETF periods only. Pre-ETF calibration retained for back-context. When reactivated in future: confirm fresh calibration window of ≥18 months post-2024 data before restoring.

---

### N_eff Interaction Table (Sophisticated — DCC-GARCH dynamic)

| Pair | Static ρ est. | DCC-GARCH tier | Normal co-amplify cap | Normal co-suppress floor | Notes |
|------|-------------|----------------|----------------------|--------------------------|-------|
| axis 17 (cross-asset macro) | 0.30 | C (stable) | 1.08× | 0.86× | ρ(17,31) not expected to vary much; macro-crypto correlation and intra-crypto rotation correlate only in risk-off |
| axis 27 (social sentiment) | 0.20 | D (stable) | 1.10× | 0.85× | F&G and BTC.D rotation: low structural connection |
| axis 29 (cross-pair correlation) | 0.38 **dynamic** | B/C/D per rolling ρ | B: 1.05×; C: 1.07×; D: 1.12× | B: 0.90×; C: 0.88×; D: 0.83× | KEY dynamic tier — DCC-GARCH most important here |
| axis 30 (DXY) | 0.15 | D (stable) | 1.12× | 0.83× | DXY and BTC.D decorrelated (2021 altseason with weak DXY; ETF-period independent) |
| axis 25 (liquidation cascade) | 0.20 | D (suppress-only) | N/A | 0.86× | Cascade suppress (axis 25) + BTC.D rising (axis 31 SUPPRESS): both valid; additive but both within hard cap |

Combined worst-case: axis 31 + axis 29 (Tier C) + axis 17 (Tier C) all fire simultaneously:
N_eff = 3 / (1 + 2×0.30) = 1.875; per-signal Kelly capped accordingly. Hard cap 1.10×/0.88× prevents over-compounding.

If axis 29 enters Tier B (ρ>0.55 dynamically): axis 31 + axis 29 co-fire capped at 1.05× (partial substitutes; one signal largely redundant). Adding axis 17 then: N_eff = 2 effective signals (axis17 independent + (31+29) merged); compound cap 1.08×.

---

### Conditions Summary (conditions-log format)

**Works when (MODE_A_RISING — SUPPRESS):** btcd_z_adj > +1.5; BTC.D_adj ∈ [42%,72%]; non-crisis rotation regime. Non-ETH non-BTC: 0.87× (pre-ETF) / 0.88× (post-ETF). ETH: immediate SUPPRESS (same scalars). 3–5 activations/year analytically pre-confirmed. Channels 1+2+3 all support SUPPRESS direction.

**Works when (MODE_A_FALLING — AMPLIFY):** btcd_z_adj < −1.5; validity gate active. Non-ETH non-BTC: immediate 1.07× (pre-ETF) / 1.05× (post-ETF). ETH: 1.00× day 0 → 1.03× days 1–2 → full AMPLIFY_SCALAR day ≥3 (Ante 2020 / Ji 2018 lag model). 3–5 activations/year per direction.

**Fails when:** BTC.D_adj outside [42%,72%]; crypto winter; G1_31_POST H5 fail (AP_E); rolling ρ(31,29) > 0.65 sustained (AP_C merger review); new-chain dilution within 90d window (FM3); simultaneous axis 25 Phase 1 active (both SUPPRESS simultaneously — N_eff floor applies at hard cap 0.88×).

**Gate progress:** G_DATA_31: CLEARABLE (trivial) → G1_31A/B (IS scan PENDING) → G1_31C (stablecoin correction H3 PENDING) → G1_31D (validity bounds H6 PENDING) → G1_31_ETH (ETH lag H4 PENDING) → G1_31_POST (post-ETF H5 PENDING) → INDEP_31 (ρ gates, analytically expected to pass) → G2_31 (18-cell CPCV+DSR).

**Prim bank after cycle 194:** freqtrade **27 naive** (unchanged) / **34 intermediate** (unchanged; btc-dominance superseded at sophisticated) / **37 sophisticated** (+1: btc-dominance axis 31 elevated). **31 freqtrade regime axes defined.**
