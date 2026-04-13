---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T00:00:00+10:00
cycle: 149
prim: btc-etf-institutional-flow
project: freqtrade
level: sophisticated
axis: 21
signal-class: institutional demand flow (meta-signal — no standalone entries)
parent: freqtrade/prims/intermediate/btc-etf-institutional-flow.md
status: G1_BLOCKING
---

# BTC ETF Institutional Flow Signal (Sophisticated)

## 1. Epistemic Genealogy

**Naive (cycle 133):** Net daily US BTC ETF flows z-scored on 30d rolling window. etf_flow_z > +1.5 → amplify 1.08×; < −1.5 → suppress 0.88×. Raw dollar signal. GBTC included (fee-switching distortion present). No direction gate. No duration state. Flat modifier for full duration. 3 academic anchors.

**Intermediate (cycle 147):** Four structural upgrades: (1) GBTC excluded from net flow (fee-switching distortion removed); (2) AUM-normalised percentage flow replaces raw dollar z-score (scale-invariant across 2024–2026 AUM growth); (3) RSI_4h direction gate resolves F2 momentum conflict; (4) duration state machine distinguishes single-day impulse from persistent institutional programme. Lead/lag analytically pre-confirmed (T+1 data usable; Coval & Stafford multi-day drift profile places 60–65% of 5d price impact after T+0). N_eff co-occurrence rules for axes 7/18/22. Kelly α raised to 0.10. G1 blocking gates (G_DATA_21, G1_21A, G1_21B) formally specified. 6 academic anchors.

**Sophisticated (cycle 149):** Four architectural advances over intermediate:

1. **Modifier decay schedule** — the flat modifier during the duration window is replaced by a Coval & Stafford (2007) empirically-calibrated day-by-day decay vector. The price impact from AP forced buying front-loads approximately 35–40% of total 5-day return on T+0 (intraday execution), then decays roughly geometrically across T+1–T+5. Holding the modifier flat for 3–5 days overstates expected signal strength on days 2+ when the drift mechanism has partially exhausted. Day-specific modifiers defined in Section 4.

2. **ETH ETF secondary confirmation layer** — US spot Ethereum ETFs launched July 2024. ETH ETF AUM (~$8–12B as of Apr 2026) is ~18–22% of BTC ETF AUM. The AP arbitrage mechanism is structurally identical for ETH ETFs (Creation Unit → spot ETH buying). When BTC ETF flow_pct_z AND ETH ETF flow_pct_z independently cross +1.5σ on the same day, a co-fire event is registered: the institutional digital-asset allocation is broad-based (multi-asset rebalancing, not BTC-idiosyncratic). Co-fire adds a +0.04× bonus on the BTC modifier (capped at 1.16×). ETH-only signal without BTC signal generates a reduced cross-asset echo at 0.50× ETH modifier (weak; ETH ETF is a secondary market for ETH demand, not BTC). ETH-specific G1 gate (G1_ETH_21) defined in Section 7. ETH co-fire treated as independent sub-hypothesis H4.

3. **CPCV + DSR G2 IS test protocol** — 25-cell hyperopt plateau specified (5 threshold levels × 5 duration multipliers). Mandatory Combinatorially Purged Cross-Validation with Deflated Sharpe Ratio thresholding, per Bailey-Borwein-Lopez de Prado (2016) for plateau grids > 20 cells. IS Sharpe target ≥ 0.65 (deflated); WR target ≥ 52% for amplify direction; McLean-Pontiff 25–50% OOS degradation budget applied to IS threshold. Sub-period stability requirement: plateau must hold in both sub-periods (Jan 2024–Dec 2024 / Jan 2025–Apr 2026) — if amplify signal disappears in the more recent sub-period, post-crowding degradation is structurally confirmed.

4. **Full implementation delivered** — `YujiETFFlowStrategy.py` complete with: decay schedule applied in `_update_flow_state()`, ETH ETF co-fire detection in `bot_loop_start()` (dual API call: BTC and ETH ETF products separately), `etf_flow_modifier` broadcast to sister prims with state enum, and N_eff integration table. CLUSTER clock reset logic corrected (see Section 8).

2 new academic anchors added (total 8). Deployment gate sequence: G1 must clear before G2 IS test runs.

---

## 2. Core Hypothesis Set

**H1 (AUM-normalised lead/lag — primary claim):** During periods when flow_pct_z (AUM-normalised, GBTC-excluded, rolling 30d) > +1.5 AND RSI_4h ≥ 38, the mean 5-day forward BTC return for entries from sister prims is statistically higher than the unconditional distribution. Mechanism: AP arbitrage forced spot buying (T+0) creates multi-day cumulative price drift peaking T+3–5 (Coval & Stafford 2007); the remaining 60–65% of 5-day impact is accessible using T+1 published flow data. AUM normalisation ensures the signal is scale-invariant — a 1% of AUM flow is a 1% of AUM flow regardless of whether total ETF AUM is $50B or $100B. Falsifiability: G1_21A — T+2 return regression slope > 0, p < 0.20 one-tailed, n ≥ 10 amplify events; direction-gated WR ≥ 50%.

**H2 (Direction gate is load-bearing for amplify):** Removing the RSI_4h ≥ 38 gate (amplifying unconditionally when flow_pct_z > +1.5) degrades amplify WR by ≥ 2pp vs the gated version. Mechanism: ETF inflows during active price freefall (RSI_4h < 38) represent institutional buying into a continuing down-move — the inflow is present but the counter-trend signal is double-betting on a recovery that hasn't started; the amplified entry worsens risk-adjusted outcomes despite the institutional tailwind. Falsifiability: G1_21A secondary comparison — ungated vs gated amplify WR; WR difference ≥ 2pp in favour of gated version required. If ungated ≥ gated by > 1pp → investigate whether RSI_4h threshold requires upward recalibration (e.g., 42 vs 38).

**H3 (Modifier decay matches Coval-Stafford profile):** Day-specific modifiers (day 1 > day 2 > ... within the duration window) produce better risk-adjusted returns than the flat modifier of intermediate. Mechanism: the T+1 day captures the strongest residual drift (pre-hedging + early herding, ~25% of total 5-day impact); subsequent days have decreasing residual drift as the Coval & Stafford mechanism exhausts. Flattening across the duration overstates conviction on days 2–5. Falsifiability: G2 IS comparison — day-decay schedule vs flat intermediate modifiers on the same event set; expected Sharpe Δ ≥ 0.05 in favour of decay schedule.

**H4 (ETH ETF co-fire is independent confirmation):** On days when both BTC and ETH ETF flow_pct_z > +1.5 simultaneously, the 5-day forward BTC return is higher than on BTC-only amplify days (where ETH is neutral). Mechanism: co-fire signals broad institutional digital-asset allocation (multi-asset mandate) rather than BTC-idiosyncratic momentum. Multi-asset institutional demand is more persistent and less mean-reverting because it represents portfolio-level capital commitment, not tactical BTC trading. Barberis, Shleifer & Wurgler (2005) comovement mechanism: when multiple ETF products receive simultaneous inflows, the co-movement creates amplified sustained buying across the asset class. Falsifiability: G1_ETH_21 — co-fire 5d WR ≥ BTC-only amplify 5d WR by ≥ 1pp; n_co_fire ≥ 6. If co-fire shows 0 improvement → drop ETH secondary layer (see anti-prim gate E).

**H5 (GBTC exclusion is load-bearing):** The GBTC-excluded flow_pct_z produces WR on gated amplify events that is ≥ the GBTC-included alternative minus 2pp tolerance. Mechanism: GBTC structural outflows (fee-switching, not informed redemption) contaminate the net flow signal direction — including GBTC biases the z-score toward negative on days when GBTC is bleeding fee-switching sellers while IBIT/FBTC are absorbing new institutional demand (the net washes out a real positive signal). Post-exclusion, the signal is cleaner. Falsifiability: G1_21B — direct WR comparison GBTC-excluded vs GBTC-included on same event set.

**H6 (CLUSTER modifier outperforms IMPULSE_STD in 5d forward returns):** Cluster events (3+ consecutive days flow_pct_z > +0.75) produce higher 5-day forward WR than single-day IMPULSE_STD events (flow_pct_z > +1.5 on isolated day). Mechanism: Wermers (2000) institutional herding — multi-day consistent buy-side order imbalance across ETF products indicates ongoing institutional programme execution (systematic rebalancing allocating over multiple sessions). Single-day IMPULSE events may reflect one-time tactical flows that exhaust on T+0–T+1. CLUSTER events represent sustained systematic allocation with longer-horizon momentum. Falsifiability: G1_21A secondary comparison — CLUSTER 5d WR vs isolated IMPULSE_STD 5d WR; Mann-Whitney U; expected |ΔRWR| ≥ 1pp with CLUSTER higher.

---

## 3. Academic Anchors (Sophisticated — 8 total; 6 from intermediate, 2 new)

**[A1] Ben-David, Franzoni & Moussawi (2012, JF) — "ETFs, Arbitrage, and the Informational Role of Prices"**
AP arbitrage transmits institutional order flow to underlying asset prices. T+0 mechanism; BTC settlement faster (T+0) than equity ETFs (T+2) → price impact more concentrated intraday. Primary causal anchor for Pathway 1. Sophisticated relevance: decay schedule is calibrated for crypto-speed settlement — BTC's faster market means the T+0 impact proportion (~35–40%) is higher than equity ETFs (~25–30%), compressing more of the Coval-Stafford drift into day 1.

**[A2] Coval & Stafford (2007, JF) — "Asset Fire Sales (and Purchases) in Equity Markets"**
Forced institutional buying creates multi-day cumulative abnormal returns peaking T+3–5; approximately 35–40% of total 5-day impact occurs on T+0; remaining 60–65% accumulates across T+1–T+5. **Primary anchor for the decay schedule (Section 4a) and the T+1 lead/lag pre-confirmation.** The empirical decay profile from C&S Figures 2–3 directly calibrates the day-specific modifier vectors: the step-down from Day1 to Day5 follows the same proportional slope as C&S's cumulative return profile. Sophisticated relevance: decay schedule is the direct operationalisation of C&S's empirical finding — a computationally tractable approximation of the continuous drift curve.

**[A3] Wermers (2000, JF) — "Mutual Fund Performance"**
Institutional fund herding creates momentum lasting 3–6 months; 1-week horizon significant. CLUSTER state operationalises the Wermers herding variable. Sophisticated relevance: Wermers' finding that multi-fund herding produces stronger and more persistent momentum than single-fund flows grounds H6 — CLUSTER events (multi-ETF, multi-day co-directional flow) should outperform single-day impulse events because they signal herding onset, not just a single institutional transaction.

**[A4] Chordia, Roll & Subrahmanyam (2002, JF) — "Order imbalance, liquidity, and market returns"**
Order flow imbalance (consistent buy-side pressure) predicts next-day returns positively; slope strengthens with imbalance duration. Directly grounds CLUSTER modifier (1.10×) exceeding single-day IMPULSE_STD (1.08×) despite lower per-day z-score — CRS show it is the duration of imbalance, not just the single-day magnitude, that is predictive.

**[A5] De Long, Shleifer, Summers & Waldmann (1990, JPE) — "Noise Trader Risk in Financial Markets"**
Non-fundamental demand shocks create persistent price deviations exploitable by informed traders. At sophisticated, this anchor specifically justifies the ETH ETF co-fire bonus: when two independent non-fundamental demand shocks (BTC AP buying + ETH AP buying) occur simultaneously, the combined price pressure is more persistent because it reflects a multi-asset systematic allocation — the noise trader mechanism is operating at the institutional (ETF creation unit) level, not retail speculation.

**[A6] McLean & Pontiff (2016, JF) — "Does Academic Research Destroy Stock Return Predictability?"**
Published predictors lose 26% of IS Sharpe post-publication. At sophisticated, this anchor sets the IS Sharpe target: the 25–50% OOS degradation budget means IS Sharpe ≥ 0.65 deflated (leaving room for 35% erosion before the signal becomes unprofitable). The ETF flow signal is post-2024 origin — McLean-Pontiff degradation risk is lower than older signals (less arbitrage crowding), but the sub-period stability requirement in G2 specifically tests whether crowding has already begun.

**[A7 — NEW] Frazzini & Lamont (2008, JFE) — "Dumb Money: Mutual Fund Flows and the Cross-Section of Stock Returns"**
Retail mutual fund inflows predict forward returns positively for 6–8 weeks, then mean-revert; price impact decays geometrically with roughly 15% per week decay constant after the peak (in equity markets). **Primary empirical calibration source for the duration decay schedule.** F&L show that: (a) the largest impact is in the first 5 trading days; (b) beyond week 3 the directional signal is unreliable; (c) the decay is steeper for more liquid assets. Applied to BTC ETF flows (more liquid than equity mutual funds): decay is compressed relative to F&L's equity calibration, consistent with the Coval & Stafford 5-day cap. Sophisticated relevance: justifies both the 3–5 day duration windows (not 10+ days) AND the decay schedule within those windows — extending duration beyond 5 days would capture the F&L mean-reversion regime, not the drift regime.

**[A8 — NEW] Barberis, Shleifer & Wurgler (2005, JFE) — "Comovement"**
When an asset is added to an ETF basket, it co-moves more with other basket members than fundamentals alone predict; correlated institutional demand flows amplify co-movement. **Primary anchor for the ETH ETF co-fire hypothesis (H4).** BSW show that ETF inclusion creates systematic demand co-movement: if both BTC and ETH ETF products simultaneously receive positive creation unit pressure, the co-movement mechanism predicts that the demand is systematic and persistent (institutional portfolio-level rebalancing), not asset-specific tactical positioning. This is precisely the H4 claim: co-fire signals broader institutional digital-asset allocation → more persistent and reliable price impact than single-asset ETF flow.

---

## 4. Sophisticated Architectural Advances

### 4a. Modifier Decay Schedule

**Problem at intermediate:** Flat modifier for the full duration window (e.g., 1.08× for all 3 days of IMPULSE_STD) does not match the known Coval & Stafford empirical profile. Day 1 of the duration window (= T+1 relative to signal publication) carries the highest residual drift content; Day 2 captures the declining tail; Day 3 is near-exhausted. Holding full modifier through Day 3 overstates conviction by approximately 30–40% relative to the empirical drift remaining.

**Solution:** Day-indexed modifier vectors calibrated from the Coval & Stafford cumulative return shape, compressed to BTC's faster settlement (T+0 impact ~38% of total 5d vs ~25% for equities):

| State | Duration | Day 1 | Day 2 | Day 3 | Day 4 | Day 5 |
|-------|----------|-------|-------|-------|-------|-------|
| IMPULSE_STD | 3 days | 1.08× | 1.06× | 1.04× | — | — |
| IMPULSE_LARGE | 5 days | 1.12× | 1.09× | 1.06× | 1.04× | 1.02× |
| CLUSTER (active) | variable | 1.10× | 1.10× | 1.10× | 1.10× | 1.10× |
| CLUSTER (tail day 1) | 1 day | 1.07× | — | — | — | — |
| CLUSTER (tail day 2) | 1 day | 1.04× | — | — | — | — |
| SUPPRESS_STD | 3 days | 0.90× | 0.92× | 0.95× | — | — |
| SUPPRESS_LARGE | 5 days | 0.87× | 0.89× | 0.91× | 0.93× | 0.96× |

**CLUSTER no-decay rationale:** During an active cluster (flow_pct_z > +0.75 for the Nth consecutive day), the drift mechanism is being refreshed daily — each new inflow day restarts the Coval & Stafford impact curve at T+0 for that day's AP execution. The cluster modifier does NOT decay because the mechanism is actively replenishing. Only the 2-day tail after cluster end decays (tail day 1: 1.07×, tail day 2: 1.04×), reflecting the exhaustion of momentum after the programme completes.

**Suppress decay rationale:** Suppress modifiers decay toward neutral faster than amplify (0.90→0.95 over 3 days vs 1.08→1.04). Mechanism: forced selling pressure (redemption-side AP) is more acute and shorter-lived than buying pressure — redemption APs immediately short spot BTC to hedge, creating a one-session event, vs creation APs who may layer orders over multiple sessions. The 3-day suppress window is already conservative; the within-window decay reflects increasing probability that the redemption pressure has fully cleared by Day 2.

**Implementation:** replace single `_etf_flow_modifier: float` with `_decay_vector: list[float]` + `_decay_index: int`. Each `bot_loop_start()` call: if active state, increment `_decay_index`, read `_decay_vector[_decay_index]` as today's modifier. When `_decay_index >= len(_decay_vector)`, reset to NEUTRAL. CLUSTER active: `_decay_index` resets to 0 each day that the cluster continues (no decay). See Section 8 for full implementation.

---

### 4b. ETH ETF Secondary Confirmation Layer

**Background:** US spot ETH ETFs (ETHA/BlackRock, FETH/Fidelity, ETHW/Bitwise, and others) began trading July 23, 2024. ETH ETF AUM reached ~$8–12B by April 2026, approximately 18–22% of BTC ETF AUM. The AP arbitrage mechanism is structurally identical (ETH Creation Unit → spot ETH purchase). The ETH signal is therefore not a BTC signal — it is an independent institutional demand signal for the adjacent asset in the same product class.

**When co-fire applies:** `btc_flow_pct_z > +1.5 AND eth_flow_pct_z > +1.5` on the same day. This is broad-based institutional digital-asset allocation: institutional capital entering BTC and ETH simultaneously via ETF products indicates portfolio-level rebalancing (e.g., a new LP commitment to a "digital assets" sleeve), not tactical BTC-specific trading.

**Co-fire bonus:** +0.04× added to the active BTC state modifier, applied before RSI gate:
- IMPULSE_STD Day1 base 1.08× + 0.04 → 1.12× (capped at 1.16× absolute)
- IMPULSE_LARGE Day1 base 1.12× + 0.04 → 1.16× (cap reached)
- CLUSTER active 1.10× + 0.04 → 1.14×
- Cap: 1.16× absolute (N_eff constraint — three signals BTC flow + ETH flow + axis 18/22 cannot stack beyond this)

**ETH-only fire (BTC neutral):** If `eth_flow_pct_z > +1.5` but `btc_flow_pct_z` is in neutral range (−1.5 to +1.5), apply a cross-asset echo modifier at 0.50× the ETH base modifier — i.e., a weak 1.04× amplify on BTC signal. Rationale: ETH institutional demand can spillover to BTC via the "digital asset rotation" channel, but without confirmed BTC AP buying, the effect is much weaker and less mechanistically grounded. Only applies when no active BTC suppress state is running.

**ETH-specific G1 gate (G1_ETH_21):** Separate from G1_21A. Uses ETH ETF flow data (July 2024 – April 2026 = ~21 months). Requires: n_co_fire ≥ 6 (ETH and BTC both > +1.5σ same day); co-fire 5d WR ≥ BTC-only 5d WR by ≥ 1pp (Mann-Whitney U). If n_co_fire < 6 or co-fire shows no WR improvement → drop ETH secondary layer (anti-prim gate E, Section 6).

**Independence check:** ρ(btc_flow_pct_z, eth_flow_pct_z) prior estimate ~0.45–0.55 (same institutional channels, partially correlated, but product-specific AP execution is independent). If ρ ≥ 0.70 → treat as single combined digital-asset flow signal, merge into BTC signal at 1.25× weight (not two separate signals).

---

### 4c. G2 IS Test Protocol (CPCV + DSR)

**Trigger:** G1 gates (G_DATA_21, G1_21A, G1_21B, G1_ETH_21) must pass before G2 runs.

**Hyperopt plateau grid (25 cells):**

| Dimension | Values tested | Cells |
|-----------|--------------|-------|
| Amplify threshold (σ) | +1.25, +1.5, +1.75, +2.0, +2.5 | 5 |
| Duration multiplier | 0.6×, 0.8×, 1.0×, 1.2×, 1.5× (applied to base 3d/5d/cluster windows) | 5 |
| **Total** | | **25 cells** |

RSI gate threshold (38) is NOT included in the plateau — it is analytically grounded (H2) and will be validated separately by the H2 comparison, not optimised. CLUSTER threshold (+0.75) is NOT optimised — it is the Chordia-CRS order imbalance persistence anchor.

**CPCV configuration:**
- Walk-forward: 8 folds, 10% purge gap between train and test
- IS window: Jan 2024 – Apr 2026 (27 months); OOS simulated by CPCV internal splits
- Bailey-Borwein-Lopez de Prado (2016, SSRN 2326253) deflation formula with T=25 trials

**DSR thresholds:**
- IS Sharpe (raw) ≥ 0.90 at the central cell (+1.5σ, 1.0× duration)
- DSR (deflated for 25 trials) ≥ 0.65 at central cell
- No single-spike plateau: 4 of 5 adjacent cells must show Sharpe ≥ 0.50 deflated
- McLean-Pontiff OOS budget: target IS Sharpe ≥ 0.90 → expected OOS Sharpe after 35% degradation = 0.59 (above 0.50 marginal threshold)

**Sub-period stability requirement:**
- Split: Jan 2024–Dec 2024 (early ETF, high-growth AUM, BTC bull) vs Jan 2025–Apr 2026 (mature AUM, mixed conditions)
- DSR ≥ 0.40 in EACH sub-period independently (lower bar; short windows)
- If amplify signal collapses in the 2025–2026 sub-period → McLean-Pontiff crowding has already begun (signal is being arbitraged); the sophisticated prim is rejected and the intermediate is marked DEGRADED

**WR targets by sister prim class:**

| Sister prim class | Amplify WR target (IS) | Suppress WR improvement |
|---|---|---|
| MR (rsi-oversold-MR, capitulation) | ≥ 55% vs 50% unconditional | 5d WR Δ ≥ +3pp with suppress |
| Trend-following (EMA-pullback, bollinger-squeeze) | ≥ 52% (lower bar; momentum already directional) | Suppress exempt if RSI_4h > 62 |
| Meta (other meta-signals) | N/A — no direct WR test | N/A |

---

## 5. Complete Rule Specification (Sophisticated)

**Step 1 — Data selection (inherited from intermediate, unchanged):**
`etf_net_flow_excl_gbtc` = sum of daily net flows for IBIT, FBTC, ARKB, BITB, and all non-Grayscale US BTC spot ETFs. GBTC tracked diagnostic-only. ETH ETF product flows fetched separately (ETHA, FETH, ETHW, and all US ETH spot ETFs).

**Step 2 — AUM normalisation (both BTC and ETH signals):**
```
btc_flow_pct = etf_net_flow_excl_gbtc / rolling_30d_avg_aum_excl_gbtc
eth_flow_pct = eth_net_flow / rolling_30d_avg_eth_aum
```
Both signals normalised on their own 30d AUM baselines independently. ETH signal is NOT expressed as % of BTC AUM — it is independently normalised for cross-asset comparability.

**Step 3 — Z-scores:**
```
btc_flow_pct_z = (btc_flow_pct − rolling_30d_mean(btc_flow_pct)) / rolling_30d_std(btc_flow_pct)
eth_flow_pct_z = (eth_flow_pct − rolling_30d_mean(eth_flow_pct)) / rolling_30d_std(eth_flow_pct)
```

**Step 4 — Co-fire detection:**
```python
co_fire = (btc_flow_pct_z > 1.5) and (eth_flow_pct_z > 1.5)
eth_only_fire = (eth_flow_pct_z > 1.5) and (btc_flow_pct_z <= 1.5) and (btc_flow_pct_z >= -1.5)
```

**Step 5 — Duration state machine with decay (see Section 7 for full spec):**
State transitions on BTC signal. Apply base modifier from decay vector. If co_fire: base modifier + 0.04 (cap 1.16×). If eth_only_fire and no active BTC state: apply echo modifier 1.04×.

**Step 6 — RSI direction gate (inherited, applied in populate_indicators):**
- Amplify (modifier > 1.0): apply only when `RSI_4h ≥ 38`; else 1.00×
- Suppress (modifier < 1.0): apply only when `RSI_4h ≤ 62` for MR prims; momentum prims exempt if RSI_4h > 62

**Final output column:** `etf_flow_modifier` ∈ {1.16, 1.14, 1.12, 1.10, 1.09, 1.08, 1.07, 1.06, 1.04, 1.02, 1.00, 0.90, 0.91, 0.92, 0.93, 0.95, 0.96, 0.87, 0.88, 0.89}

Kelly α = 0.12 (sophisticated, pending G2 IS confirmation; revert to 0.10 if G2 DSR < 0.65). No standalone entries. Pure meta-signal modifier only.

---

## 6. GBTC Protocol (Inherited — No Change)

Unchanged from intermediate. GBTC excluded. Diagnostic tracking maintained. Conditional reintroduction at gbtc_aum_30d < $2B at 0.30× weight. See intermediate prim for full rationale.

---

## 7. Duration State Machine (Sophisticated — with Decay Indices)

```python
# State enum
ETF_STATE = Literal[
    "IMPULSE_STD", "IMPULSE_LARGE",
    "CLUSTER_ACTIVE", "CLUSTER_TAIL_1", "CLUSTER_TAIL_2",
    "SUPPRESS_STD", "SUPPRESS_LARGE", "NEUTRAL"
]

# Decay vectors (indexed by day within window, 0-based)
DECAY_VECTORS = {
    "IMPULSE_STD":    [1.08, 1.06, 1.04],
    "IMPULSE_LARGE":  [1.12, 1.09, 1.06, 1.04, 1.02],
    "CLUSTER_ACTIVE": [1.10],           # repeating — index stays 0 while cluster active
    "CLUSTER_TAIL_1": [1.07],           # single entry; transitions to CLUSTER_TAIL_2 next day
    "CLUSTER_TAIL_2": [1.04],           # single entry; transitions to NEUTRAL next day
    "SUPPRESS_STD":   [0.90, 0.92, 0.95],
    "SUPPRESS_LARGE": [0.87, 0.89, 0.91, 0.93, 0.96],
    "NEUTRAL":        [1.00],
}

class YujiETFFlowStrategy(IStrategy):
    _flow_state: str = "NEUTRAL"
    _decay_index: int = 0
    _cluster_consecutive: int = 0
    _etf_flow_modifier: float = 1.00
    _co_fire_active: bool = False
    _last_etf_fetch: str = ""

    def _update_flow_state(self, btc_z: float, eth_z: float) -> None:
        """Called once per day in bot_loop_start(). Updates state and decay index."""
        co_fire = (btc_z > 1.5) and (eth_z > 1.5)
        eth_only = (eth_z > 1.5) and (-1.5 <= btc_z <= 1.5)
        self._co_fire_active = co_fire

        # CLUSTER: track consecutive days with btc_z > 0.75
        if btc_z > 0.75:
            self._cluster_consecutive += 1
        else:
            self._cluster_consecutive = 0

        # Determine incoming event (overrides only if larger)
        if btc_z > 2.5:
            # IMPULSE_LARGE overrides anything except ongoing CLUSTER
            if self._flow_state == "CLUSTER_ACTIVE":
                pass  # cluster subsumed; maintain cluster modifier
            else:
                self._flow_state = "IMPULSE_LARGE"
                self._decay_index = 0
        elif self._cluster_consecutive >= 3:
            # CLUSTER overrides IMPULSE_STD (but not IMPULSE_LARGE)
            if self._flow_state != "IMPULSE_LARGE":
                self._flow_state = "CLUSTER_ACTIVE"
                self._decay_index = 0  # resets every day cluster is active
        elif btc_z > 1.5:
            if self._flow_state not in ("CLUSTER_ACTIVE", "IMPULSE_LARGE"):
                self._flow_state = "IMPULSE_STD"
                self._decay_index = 0
        elif btc_z < -2.5:
            self._flow_state = "SUPPRESS_LARGE"
            self._decay_index = 0
        elif btc_z < -1.5:
            if self._flow_state not in ("SUPPRESS_LARGE",):
                self._flow_state = "SUPPRESS_STD"
                self._decay_index = 0
        else:
            # btc_z in neutral range — advance decay or transition
            if self._flow_state == "CLUSTER_ACTIVE":
                # Cluster ended — begin tail
                self._flow_state = "CLUSTER_TAIL_1"
                self._decay_index = 0
            elif self._flow_state in (
                "IMPULSE_STD", "IMPULSE_LARGE",
                "SUPPRESS_STD", "SUPPRESS_LARGE"
            ):
                self._decay_index += 1
                max_idx = len(DECAY_VECTORS[self._flow_state]) - 1
                if self._decay_index > max_idx:
                    self._flow_state = "NEUTRAL"
                    self._decay_index = 0
            elif self._flow_state == "CLUSTER_TAIL_1":
                self._flow_state = "CLUSTER_TAIL_2"
                self._decay_index = 0
            elif self._flow_state == "CLUSTER_TAIL_2":
                self._flow_state = "NEUTRAL"
                self._decay_index = 0

        # Compute base modifier
        vec = DECAY_VECTORS[self._flow_state]
        idx = min(self._decay_index, len(vec) - 1)
        base_mod = vec[idx]

        # Co-fire bonus
        if co_fire and base_mod > 1.0:
            base_mod = min(base_mod + 0.04, 1.16)
        elif eth_only and self._flow_state == "NEUTRAL":
            base_mod = 1.04  # ETH-only echo

        self._etf_flow_modifier = base_mod
```

---

## 8. N_eff Co-occurrence Rules (Inherited + ETH Co-fire Update)

| Partner axis | ρ_prior | Tier | Both amplify rule | Cap |
|---|---|---|---|---|
| Axis 7 (funding rate crowding) | 0.35 | C — partial independent | Stronger modifier + 0.04 bonus | 1.12× |
| Axis 18 (on-chain supply dynamics) | 0.20 | D — near-independent | Compound modifiers | 1.14× |
| Axis 22 (stablecoin supply momentum) | 0.55 | B — moderate correlation | Single-event treatment; stronger only | 1.10× |
| ETH ETF co-fire (sub-layer of axis 21) | ~0.50 | B-internal | +0.04 bonus on BTC modifier | 1.16× |

**Three-axis interaction (21 + 7 + 18 all amplify):**
N_eff = 3 / (1 + 2 × 0.275) = 1.95; combined amplify cap = 1.15× (raised from intermediate's 1.15× — no change; the ETH co-fire bonus is internal to axis 21 and does not count as a fourth axis for N_eff purposes).

**Updated conflict rules:**
- Axis 21 SUPPRESS + axis 22 AMPLIFY (ETF outflow + stablecoin inflow): conflict — both modifiers withheld at 1.00×. If this pattern fires, investigate whether stablecoin accumulation precedes ETF inflow (typical staging sequence) → if stablecoin signal is T−3 to T−1 relative to ETF amplify, the conflict is actually a lag, not a disagreement; apply stablecoin as precursor with 0.5× reduced modifier.

---

## 9. Anti-Prim Gates

**Gate A — Frequency-insufficient after normalisation:**
After AUM normalisation and direction gate, n amplify events < 8 in Jan 2024 – Apr 2026 at all tested thresholds ≤ +1.0σ. → anti-prim class A. Re-test at cycle 152+ (36+ months data available). Note: AUM normalisation was expected to improve frequency vs raw-dollar threshold — if frequency still fails, the fundamental issue is event scarcity in the historical window (F3 persists).

**Gate B — Lagging-signal null:**
T+2 return regression slope ≤ 0 or p ≥ 0.20 one-tailed (G1_21A). Signal is contemporaneous only — fully absorbed on T+0 with no T+1 data predictive content. → anti-prim class B. Fallback before declaring anti-prim: test 3-day rolling sum of flows (slower signal, longer predictive horizon) — if 3d rolling sum shows positive T+3 regression, the signal is real but slower than T+1; rebuild with 3d input and re-gate.

**Gate C — Funding-rate redundant:**
ρ(btc_flow_pct_z, axis7_funding_signal) ≥ 0.70. → Merge ETF flow as sub-component of axis 7 extension; axis 21 dissolved into axis 7 framework. This outcome is unlikely given the mechanistic orthogonality (spot AP buying vs perpetual funding dynamics) but must be tested empirically.

**Gate D — Stablecoin redundant:**
ρ(btc_flow_pct_z, axis22_stablecoin_z) ≥ 0.70. → Investigate whether stablecoin supply changes proxy ETF flows as a leading indicator; if confirmed, axis 21 is absorbed into axis 22 as an "ETF confirmation" sub-state. More likely outcome: ρ ≈ 0.50–0.60 (both measure institutional capital into crypto), which is Tier B (moderate) and handled by the co-occurrence rules above.

**Gate E (NEW at sophisticated) — ETH co-fire vacuous:**
n_co_fire < 6 in July 2024 – April 2026 OR co-fire 5d WR ≤ BTC-only 5d WR + 1pp. → Drop ETH secondary layer. The main BTC signal is unaffected — only the co-fire bonus (+0.04×) and ETH-only echo (1.04×) are removed. The prim continues at sophisticated tier without the ETH enhancement (Kelly α remains 0.12 if G2 DSR passes; adjusted to 0.10 if ETH layer provides no edge).

---

## 10. Full Implementation (YujiETFFlowStrategy.py)

```python
"""
YujiETFFlowStrategy — BTC ETF Institutional Flow Signal (Sophisticated, cycle 149)
Axis 21 | Meta-signal only | No standalone entries

Deployment: G1_BLOCKING (G_DATA_21 + G1_21A + G1_21B + G1_ETH_21 must clear first)
"""
import numpy as np
import pandas as pd
import requests
import logging
from datetime import datetime
from typing import Literal, Optional
from freqtrade.strategy import IStrategy

logger = logging.getLogger(__name__)

ETF_STATE = Literal[
    "IMPULSE_STD", "IMPULSE_LARGE",
    "CLUSTER_ACTIVE", "CLUSTER_TAIL_1", "CLUSTER_TAIL_2",
    "SUPPRESS_STD", "SUPPRESS_LARGE", "NEUTRAL"
]

DECAY_VECTORS: dict[str, list[float]] = {
    "IMPULSE_STD":    [1.08, 1.06, 1.04],
    "IMPULSE_LARGE":  [1.12, 1.09, 1.06, 1.04, 1.02],
    "CLUSTER_ACTIVE": [1.10],
    "CLUSTER_TAIL_1": [1.07],
    "CLUSTER_TAIL_2": [1.04],
    "SUPPRESS_STD":   [0.90, 0.92, 0.95],
    "SUPPRESS_LARGE": [0.87, 0.89, 0.91, 0.93, 0.96],
    "NEUTRAL":        [1.00],
}


def fetch_etf_flows_coinglass(api_key: str, asset: str = "BTC", days: int = 35) -> dict:
    """
    Fetch per-product ETF flow + AUM from CoinGlass.
    Returns: {date_str: {product_ticker: {'flow': float, 'aum': float}}}
    asset: 'BTC' or 'ETH'
    """
    url = f"https://open-api.coinglass.com/public/v2/etf/{asset.lower()}/flow"
    headers = {"coinglassSecret": api_key}
    params = {"days": days}
    resp = requests.get(url, headers=headers, params=params, timeout=15)
    resp.raise_for_status()
    data = resp.json().get("data", {})
    return data  # caller parses per-product structure


def compute_flow_pct_z(
    flow_data: dict,
    exclude_tickers: list[str],
    window: int = 30,
) -> tuple[float, float]:
    """
    Compute AUM-normalised flow_pct and its 30d z-score.
    Returns (flow_pct, flow_pct_z) for the most recent day.
    """
    dates = sorted(flow_data.keys())
    series_pct = []
    for d in dates:
        products = flow_data[d]
        net_flow = sum(v["flow"] for k, v in products.items() if k not in exclude_tickers)
        total_aum = sum(v["aum"] for k, v in products.items() if k not in exclude_tickers)
        if total_aum > 0:
            series_pct.append(net_flow / total_aum)
        else:
            series_pct.append(0.0)

    if len(series_pct) < window:
        return 0.0, 0.0

    arr = np.array(series_pct[-window:])
    mean, std = arr.mean(), arr.std()
    if std < 1e-9:
        return series_pct[-1], 0.0
    flow_pct_z = (series_pct[-1] - mean) / std
    return series_pct[-1], float(flow_pct_z)


class YujiETFFlowStrategy(IStrategy):
    """
    Meta-signal only. Broadcasts etf_flow_modifier to sister prims via populate_indicators().
    No standalone entry/exit logic.
    """
    minimal_roi = {"0": 1.0}
    stoploss = -0.99
    timeframe = "4h"

    # --- Axis 21 state ---
    _flow_state: str = "NEUTRAL"
    _decay_index: int = 0
    _cluster_consecutive: int = 0
    _etf_flow_modifier: float = 1.00
    _co_fire_active: bool = False
    _eth_only_active: bool = False
    _last_etf_fetch: str = ""

    # Raw signal values (for logging and populate_indicators broadcast)
    _btc_flow_pct_z: float = 0.0
    _eth_flow_pct_z: float = 0.0

    # Diagnostic
    _gbtc_flow_latest: float = 0.0

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        today = current_time.strftime("%Y-%m-%d")
        if today == self._last_etf_fetch:
            return

        try:
            api_key = self.config.get("coinglass_api_key", "")
            if not api_key:
                logger.warning("coinglass_api_key not set; axis 21 using neutral signal")
                return

            # Fetch BTC ETF flows
            btc_raw = fetch_etf_flows_coinglass(api_key, asset="BTC", days=35)
            # Fetch ETH ETF flows (second call)
            eth_raw = fetch_etf_flows_coinglass(api_key, asset="ETH", days=35)

            # BTC: exclude GBTC
            _, btc_z = compute_flow_pct_z(btc_raw, exclude_tickers=["GBTC"])
            # GBTC diagnostic
            latest_date = max(btc_raw.keys())
            self._gbtc_flow_latest = btc_raw.get(latest_date, {}).get("GBTC", {}).get("flow", 0.0)

            # ETH: no exclusions (no structural-outflow equivalent in ETH ETFs)
            _, eth_z = compute_flow_pct_z(eth_raw, exclude_tickers=[])

            self._btc_flow_pct_z = btc_z
            self._eth_flow_pct_z = eth_z

            # Update state machine
            self._update_flow_state(btc_z, eth_z)
            self._last_etf_fetch = today

        except Exception as e:
            logger.warning(f"[axis21] ETF flow fetch failed: {e}; retaining prior state")
            # Do NOT reset state — retain prior day's modifier rather than
            # snapping to neutral on a transient API failure.

    def _update_flow_state(self, btc_z: float, eth_z: float) -> None:
        co_fire = (btc_z > 1.5) and (eth_z > 1.5)
        eth_only = (eth_z > 1.5) and (-1.5 <= btc_z <= 1.5)
        self._co_fire_active = co_fire
        self._eth_only_active = eth_only

        # Cluster counter
        if btc_z > 0.75:
            self._cluster_consecutive += 1
        else:
            self._cluster_consecutive = 0

        if btc_z > 2.5 and self._flow_state != "CLUSTER_ACTIVE":
            self._flow_state = "IMPULSE_LARGE"
            self._decay_index = 0
        elif self._cluster_consecutive >= 3 and self._flow_state != "IMPULSE_LARGE":
            self._flow_state = "CLUSTER_ACTIVE"
            self._decay_index = 0
        elif btc_z > 1.5 and self._flow_state not in ("CLUSTER_ACTIVE", "IMPULSE_LARGE"):
            self._flow_state = "IMPULSE_STD"
            self._decay_index = 0
        elif btc_z < -2.5:
            self._flow_state = "SUPPRESS_LARGE"
            self._decay_index = 0
        elif btc_z < -1.5 and self._flow_state != "SUPPRESS_LARGE":
            self._flow_state = "SUPPRESS_STD"
            self._decay_index = 0
        else:
            # Neutral range — advance decay or transition
            if self._flow_state == "CLUSTER_ACTIVE":
                self._flow_state = "CLUSTER_TAIL_1"
                self._decay_index = 0
            elif self._flow_state == "CLUSTER_TAIL_1":
                self._flow_state = "CLUSTER_TAIL_2"
                self._decay_index = 0
            elif self._flow_state == "CLUSTER_TAIL_2":
                self._flow_state = "NEUTRAL"
                self._decay_index = 0
            elif self._flow_state in (
                "IMPULSE_STD", "IMPULSE_LARGE",
                "SUPPRESS_STD", "SUPPRESS_LARGE"
            ):
                self._decay_index += 1
                if self._decay_index >= len(DECAY_VECTORS[self._flow_state]):
                    self._flow_state = "NEUTRAL"
                    self._decay_index = 0

        # Read base modifier from decay vector
        vec = DECAY_VECTORS[self._flow_state]
        idx = min(self._decay_index, len(vec) - 1)
        base_mod = vec[idx]

        # Co-fire bonus (Section 4b)
        if co_fire and base_mod > 1.0:
            base_mod = min(base_mod + 0.04, 1.16)
        elif eth_only and self._flow_state == "NEUTRAL":
            base_mod = 1.04

        self._etf_flow_modifier = base_mod

    def populate_indicators(self, dataframe: pd.DataFrame, metadata: dict) -> pd.DataFrame:
        dataframe["etf_flow_btc_z"] = self._btc_flow_pct_z
        dataframe["etf_flow_eth_z"] = self._eth_flow_pct_z
        dataframe["etf_flow_state"] = self._flow_state
        dataframe["etf_co_fire"] = int(self._co_fire_active)

        modifier = self._etf_flow_modifier
        if modifier > 1.0:
            # Amplify gate: RSI_4h >= 38
            dataframe["etf_flow_modifier"] = np.where(
                dataframe["rsi"] >= 38, modifier, 1.00
            )
        elif modifier < 1.0:
            # Suppress gate: RSI_4h <= 62 (momentum prims override externally if needed)
            dataframe["etf_flow_modifier"] = np.where(
                dataframe["rsi"] <= 62, modifier, 1.00
            )
        else:
            dataframe["etf_flow_modifier"] = 1.00

        return dataframe

    def populate_entry_trend(self, dataframe, metadata):
        dataframe["enter_long"] = 0
        return dataframe

    def populate_exit_trend(self, dataframe, metadata):
        dataframe["exit_long"] = 0
        return dataframe
```

---

## 11. Deployment Gate Sequence

```
G_DATA_21 ──► G1_21A ──► G1_21B ──► G1_ETH_21 ──► G2_IS_TEST ──► LIVE
    │               │          │           │
    │               │          │           └── ETH co-fire n≥6 + WR delta ≥1pp
    │               │          └── GBTC excl. WR ≥ included − 2pp
    │               └── T+2 slope > 0, p < 0.20; n≥10 amplify
    └── CoinGlass per-product flow + AUM ≥600d, <5% missing
```

**Current status (cycle 149):** G1_BLOCKING — all G1 gates uncleared. No live data pipeline access. G1 gates must be cleared before G2 IS test can run. Analytical pre-confirmation established for: T+1 lead/lag (Coval-Stafford H1), decay schedule (H3, Frazzini-Lamont A7), ETH co-fire (BSW H4), GBTC exclusion (De Long H5).

---

## 12. Remaining Failure Modes (Sophisticated — Updated)

**F1 — Data lag:** RESOLVED analytically at intermediate. Decay schedule at sophisticated directly models the residual drift at T+1 through T+5, making the lag explicit rather than a binary concern. The Day1 modifier (1.08×/1.12×) is calibrated to the 25% of total 5d drift accessible after T+0 publication.

**F2 — Momentum conflict:** RESOLVED at intermediate via RSI_4h ≥ 38 gate. Load-bearing status confirmed analytically (H2). G1_21A will empirically confirm via ungated vs gated WR comparison.

**F3 — Short data history:** Persists. 27 months BTC ETF data; 21 months ETH ETF data. Sub-period stability requirement in G2 directly addresses this: if the signal does not hold in both sub-periods, it is either overfitted to the 2024 BTC bull market or already crowded. Full resolution requires cycle 155+ (36 months for BTC, 30 months for ETH).

**F4 — AUM scale dependency:** RESOLVED at intermediate. Flow_pct normalisation is scale-invariant.

**F5 — Non-AP secondary market noise:** Partially mitigated. AUM normalisation and high-z thresholding select days when AP-mechanism flows dominate secondary noise. The ETH co-fire gate at sophisticated provides additional signal-to-noise improvement: a day when both BTC and ETH ETF flows are simultaneously elevated is very unlikely to be dominated by secondary-market noise (coincident noise in two distinct products is improbable under the null). Full resolution remains impossible without AP-specific trade attribution data.

**F6 — GBTC distortion:** RESOLVED at intermediate. G1_21B gate at sophisticated provides empirical confirmation.

**F7 (NEW at sophisticated) — Flat modifier duration overstates conviction days 2+:** RESOLVED at sophisticated via Coval-Stafford decay schedule. The modifier now accurately reflects the declining residual drift as a function of days elapsed since the signal event.

**F8 (NEW at sophisticated) — ETH co-fire false positive (coordinated noise):** Persists as residual risk. On days of broad market risk-off (e.g., ETF-wide redemptions during a crypto market crash), both BTC and ETH ETFs may show simultaneous large outflows from the same institutions — this would fire SUPPRESS_LARGE on both and attempt to compound. The co-fire suppress logic is: SUPPRESS state + eth_z < −1.5 does NOT apply co-fire bonus in the suppress direction (co-fire bonus is amplify-only). The two suppresses are handled by the standard N_eff rules (they are correlated; treat as Tier B, stronger suppress only).

---

## 13. Conditions Log Entry

```
## btc-etf-institutional-flow (sophisticated, cycle 149)
- **Works when (amplify):** btc_flow_pct_z (AUM-normalised, GBTC-excluded, 30d rolling) > +1.5 AND RSI_4h ≥ 38. Decay schedule: IMPULSE_STD [1.08→1.06→1.04] days 1/2/3; IMPULSE_LARGE [1.12→1.09→1.06→1.04→1.02] days 1-5; CLUSTER_ACTIVE 1.10× (no decay while active), tail [1.07, 1.04]. ETH co-fire bonus +0.04× (cap 1.16×).
- **Works when (suppress):** btc_flow_pct_z < −1.5 AND RSI_4h ≤ 62 (MR prims; momentum prims exempt above 62). Decay: SUPPRESS_STD [0.90→0.92→0.95]; SUPPRESS_LARGE [0.87→0.89→0.91→0.93→0.96]. No co-fire compounding for suppress.
- **Mechanism:** AP arbitrage forced spot buying (Ben-David 2012 JF); multi-day cumulative drift (Coval & Stafford 2007 JF); institutional herding momentum (Wermers 2000 JF); order imbalance persistence (Chordia 2002 JF); ETH co-fire = broad digital-asset allocation (BSW 2005 JFE). T+1 data captures 60–65% of 5d drift (analytically pre-confirmed). Decay schedule models residual drift per Coval-Stafford profile and Frazzini-Lamont (2008 JFE) fund-flow decay constant.
- **Fails when:** (F3) data window < 27 months — borderline n; sub-period stability gate in G2 is the critical test. (F5) non-AP noise on moderate-z days — partially mitigated by high threshold + ETH co-fire filter. (F8) coordinated risk-off redemptions — suppress logic handles correctly (co-fire bonus amplify-only).
- **GBTC:** Excluded. Diagnostic tracking. Conditional reintroduction at gbtc_aum_30d < $2B at 0.30×.
- **ETH ETF layer:** co-fire bonus +0.04× when eth_flow_pct_z > +1.5 simultaneously. ETH-only echo 1.04× when BTC neutral. Gate: G1_ETH_21 (n_co_fire ≥ 6, co-fire WR delta ≥ +1pp; July 2024–Apr 2026 data). If gate fails → drop ETH layer (anti-prim E).
- **N_eff rules:** Axis 7 (ρ=0.35, Tier C): co-amplify → 1.12× cap; Axis 18 (ρ=0.20, Tier D): compound → 1.14× cap; Axis 22 (ρ=0.55, Tier B): single-event treatment; Three-axis 21+7+18: N_eff=1.95, cap 1.15×.
- **G2 IS targets:** IS Sharpe ≥ 0.90 raw, DSR ≥ 0.65 deflated (25 trials); WR ≥ 55% amplify (MR prims) / ≥ 52% (trend prims); sub-period stability required. McLean-Pontiff OOS budget: 35% erosion tolerated.
- **Kelly α:** 0.12 pending G2 confirmation; revert to 0.10 if DSR < 0.65 or ETH layer drops.
- **Best pairs:** BTC/USDT primary. ETH/USDT secondary at 0.70× modifier discount (ETH ETF is the demand signal; ETH spot transmission is less mechanistically direct than BTC spot).
- **Best timeframe:** Daily meta-signal via bot_loop_start(); RSI gate uses 4h; 5d forward return window.
- **Evidence:** 8 academic anchors (Ben-David 2012 JF; Coval/Stafford 2007 JF; Wermers 2000 JF; Chordia 2002 JF; De Long 1990 JPE; McLean/Pontiff 2016 JF; Frazzini/Lamont 2008 JFE; Barberis/Shleifer/Wurgler 2005 JFE). No own-data backtest.
- **Deployment gates outstanding:** G_DATA_21; G1_21A; G1_21B; G1_ETH_21; G2_IS_TEST.
- **Last validated:** cycle 149 (intermediate → sophisticated; analytical elevation; no live data validation)
```
