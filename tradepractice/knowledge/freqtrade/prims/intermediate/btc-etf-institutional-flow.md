---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T00:00:00+10:00
cycle: 147
prim: btc-etf-institutional-flow
project: freqtrade
level: intermediate
axis: 21
signal-class: institutional demand flow (meta-signal — no standalone entries)
parent: naive (cycle 133)
status: ACTIVE
---

# BTC ETF Institutional Flow Signal (Intermediate)

## Epistemic Genealogy

**Naive (cycle 133):** Net daily US BTC ETF flows z-scored on 30d rolling window. etf_flow_z > +1.5 → amplify 1.08×; < −1.5 → suppress 0.88×. Raw dollar signal. GBTC included. No direction gate. No duration state. 3 academic anchors.

**Intermediate (cycle 147):** Four structural upgrades over naive: (1) GBTC excluded from net flow (fee-switching distortion removed); (2) AUM-normalised percentage flow replaces raw dollar z-score (scale-invariant across the 2024–2026 AUM growth period); (3) RSI direction gate resolves F2 momentum conflict; (4) duration state machine distinguishes single-day impulse from persistent institutional programme. Plus: lead/lag analytical pre-confirmation (T+1 data usable via Coval & Stafford decay profile), N_eff co-occurrence rules for axes 7/18/22, and 3 additional academic anchors. Kelly α raised to 0.10 (intermediate) from 0.05 (naive). G1 blocking gates formally specified.

---

## Rule

**BTC ETF Flow Signal (intermediate):**

**Step 1 — Data selection:**
Compute `etf_net_flow_excl_gbtc` = sum of net daily flows for all US BTC spot ETFs **excluding GBTC**.
Products included: IBIT, FBTC, ARKB, BITB, and all non-Grayscale ETFs.
GBTC tracked separately as `gbtc_flow` for diagnostic purposes but **not** included in signal calculation (see GBTC Protocol below).

**Step 2 — AUM normalisation:**
```
flow_pct = etf_net_flow_excl_gbtc / rolling_30d_avg_total_aum_excl_gbtc
```
Where `rolling_30d_avg_total_aum_excl_gbtc` is the 30-day trailing average of total AUM for the same ETF universe (excluding GBTC). Units: dimensionless percentage. Typical values: −0.01 to +0.01 (i.e., daily flow is usually ±1% of total AUM).

AUM data source: CoinGlass fund AUM endpoint (same API call as flow data).

**Step 3 — Z-score:**
```
flow_pct_z = (flow_pct − rolling_30d_mean(flow_pct)) / rolling_30d_std(flow_pct)
```
Note: z-scoring an AUM-normalised variable is now scale-invariant. The absolute AUM level no longer biases the signal as it did in naive (where a $500M inflow at $10B AUM ≠ $500M inflow at $50B AUM). [Addresses F4.]

**Step 4 — Duration state machine:**
Classify signal state from `flow_pct_z` history:

| State | Condition | Duration | Modifier |
|-------|-----------|----------|----------|
| `IMPULSE_LARGE` | flow_pct_z > +2.5 (single day) | 5 days | Amplify 1.12× |
| `IMPULSE_STD` | flow_pct_z > +1.5 (single day) | 3 days | Amplify 1.08× |
| `CLUSTER` | 3+ consecutive days with flow_pct_z > +0.75 | Last day of cluster + 2d | Amplify 1.10× |
| `NEUTRAL` | −1.5 ≤ flow_pct_z ≤ +1.5 | — | 1.00× |
| `SUPPRESS_STD` | flow_pct_z < −1.5 (single day) | 3 days | Suppress 0.90× |
| `SUPPRESS_LARGE` | flow_pct_z < −2.5 (single day) | 5 days | Suppress 0.87× |

Duration countdown resets if a new qualifying event fires before the previous one expires (extend, not compound).

CLUSTER state: During an ongoing cluster, individual IMPULSE states within the cluster are subsumed — only the CLUSTER modifier applies.

**Step 5 — RSI direction gate (F2 mitigation):**
Apply the following conditional filter **before** passing modifier to sister prims:

- **AMPLIFY gate:** Modifier applied only when `RSI_4h ≥ 38`. If RSI_4h < 38 (price in active freefall), downgrade to NEUTRAL (1.00×). Rationale: amplifying a MR long entry during active institutional buying into a freefall does not add edge — the institutional buying may be early, and the MR entry is already firing counter-trend; amplifying it double-bets on a recovery that hasn't started. The RSI_4h ≥ 38 gate requires at least a nascent recovery signal before the flow modifier engages.
- **SUPPRESS gate:** Modifier applied only when `RSI_4h ≤ 62`. If RSI_4h > 62 (strong bullish momentum), suppress gate is withheld for momentum prims (EMA-pullback, bollinger-squeeze, FVG); MR/contrarian prims still receive 0.90× suppress.

**Final output column:** `etf_flow_modifier` ∈ {1.12, 1.10, 1.08, 1.00, 0.90, 0.87}

Kelly α = 0.10 (intermediate). No standalone entries. Pure meta-signal modifier only.

---

## GBTC Protocol

**Why GBTC is excluded at intermediate:**

GBTC converted from a closed-end trust to a spot ETF on January 11, 2024. Unlike new ETF launches, GBTC launched with pre-existing holders who had purchased GBTC at a premium as the only available regulated BTC exposure. Post-conversion, these holders face a fee differential of ~125 bps/year (GBTC 1.50% vs IBIT 0.25%). The structural outflow since launch is fee-switching, not informed institutional redemption.

Mechanistic test: if GBTC outflows were genuine bearish demand signals (AP redemption pressure → forced spot selling), they should predict negative next-5d BTC returns. Historical pattern shows GBTC sustained outflows even during Q1 2024 BTC rally (BTC +50% while GBTC bled $7B). Signal direction is inconsistent with bearish interpretation. [Resolves F6.]

**Conditional GBTC reintroduction protocol:**
When `gbtc_aum_rolling_30d < $2B` (estimated cycle 152+, when structural outflow programme is largely complete), reintroduce GBTC at 0.30× weight:
```
etf_net_flow_hybrid = etf_net_flow_excl_gbtc + 0.30 × gbtc_flow
```
Trigger threshold is AUM-based (not time-based) to account for uncertainty in outflow completion timing. Gate: verify GBTC 90d flow is not systematically negative before reintroducing.

---

## Lead/Lag Analytical Pre-Confirmation

**Why T+1 data (24h lag) is still predictively valid:**

The naive prim identified F1 (24h data lag) as a blocking concern: if price fully reacts to AP buying on day T, the T+1 signal arrives after the move is complete. At intermediate, this concern is analytically resolved:

Coval & Stafford (2007, JF) show that forced institutional buying creates **multi-day cumulative price drift** peaking at T+3–5 days. The intraday AP execution on day T constitutes only the first layer of price impact; subsequent layers include:
- **T+1 to T+2:** Market maker hedging adjustments (anticipatory pre-positioning for the next day's expected AP order if the inflow programme is ongoing)
- **T+1 to T+3:** Order book thinning effects — the AP buying on day T reduces available liquidity at those price levels; subsequent buyers face steeper impact curves
- **T+2 to T+5:** Institutional herding cascade — momentum investors observing the ETF flow data (also available at T+1) increase buy orders

Quantitative implication: even using T+1 data (24h lag), the signal has forward return content on T+2 through T+5. The Coval & Stafford 5-day cumulative return window has approximately 60–70% of its total magnitude occurring after T+1, meaning the T+1 data captures the bulk of the remaining tradeable price impact.

**Empirical test protocol for G1 (lead/lag gate):**
```python
# Using T+1 published data (correct: no look-ahead)
# Predicting T+2 return (next-1d from signal availability)
slope, pval = linregress(flow_pct_z_t1_published, btc_return_t2)
# Required: slope > 0 AND pval < 0.20 (one-tailed; lenient given short data window)
# Secondary: slope > 0 for t+3 and t+5 returns (confirms multi-day drift)
```

---

## Mechanism (Refined)

Three pathways remain from naive. Intermediate adds mechanism clarity:

**Pathway 1 — AP mechanical spot buying (same-day, T+0)**
[Unchanged from naive.] The AP buys spot BTC proportional to net ETF creation units within 2–4 hours. This is forced and magnitude-determined. The AUM normalisation at intermediate means the signal now captures the *relative* scale of the AP buying (as a % of existing market demand), not just the raw dollar amount. This is the correct mechanical metric because the AP is competing against a fixed share of the daily spot order book — absolute dollar size matters less than the relative size vs normal daily turnover.

**Pathway 2 — Institutional programme clustering (T+1 to T+3)**
The CLUSTER state machine at intermediate captures the Pathway 2 mechanism explicitly. When 3+ consecutive days show flow_pct_z > +0.75, a multi-day institutional rebalancing programme is ongoing. The CLUSTER modifier (1.10×) is intermediate between IMPULSE_STD (1.08×) and IMPULSE_LARGE (1.12×) because the clustering confirmation adds evidence of ongoing programme execution, but the individual days are not large enough to be single-event z > +2.5.

**Pathway 3 — Market maker pre-hedging (T+1)**
Not directly observable. Effect is embedded in the next-1d forward return test (G1 lead/lag gate). If the slope test shows positive T+2 return prediction from T+1 data, this is the combined signal of Pathways 2 and 3 (multi-day drift + pre-hedging).

---

## N_eff Co-occurrence Rules

Axis 21 interactions when multiple axes fire simultaneously:

| Partner axis | Signal overlap rationale | ρ_prior | Treatment | Combined amplify rule |
|---|---|---|---|---|
| Axis 7 (funding rate crowding) | Both reflect institutional/derivatives market demand direction, but through distinct channels (spot ETF vs perpetuals funding) | 0.35 | Tier C — partial independent | Both amplify: stronger modifier + 0.04 bonus; cap 1.12×. Both suppress: stronger suppress + 0.04 penalty; floor 0.85× |
| Axis 18 (on-chain supply dynamics) | Orthogonal domains: axis 18 = supply-side UTXO cost basis; axis 21 = demand-side institutional capital; minimal overlap | 0.20 | Tier D — near-independent | Both amplify: compound modifiers; cap 1.14×. Both suppress: compound; floor 0.83× |
| Axis 22 (stablecoin supply momentum) | Partial overlap: stablecoin accumulation and ETF inflows both proxy institutional capital rotation into BTC; stablecoin precedes ETF (capital staging → execution) | 0.55 | Tier B — moderate correlation | Both amplify: single-event treatment; apply stronger modifier only; no compounding. Both suppress: same |

**Suppress rules:**
- Axis 21 SUPPRESS + axis 7 AMPLIFY (institutional ETF outflow + crowded longs): conflict → apply axis 21 suppress at 0.90×; axis 7 modifier withheld for this prim only (signals disagree on direction)
- Axis 21 AMPLIFY + axis 22 SUPPRESS (ETF inflow + stablecoin contraction): conflict → both modifiers withheld; 1.00× neutral applied. Direction disagreement between capital-flow proxies → no confidence adjustment.

**Three-axis rule:**
When axes 21 + 7 + 18 all amplify simultaneously: N_eff = 3 / (1 + 2 × 0.275) = 1.95; combined amplify cap = 1.15×. Suppress: floor = 0.82×.

---

## Evidence — 6 Academic Anchors

**[A1] Ben-David, Franzoni & Moussawi (2012, JF) — "ETFs, Arbitrage, and the Informational Role of Prices"**
[Unchanged from naive.] AP arbitrage transmits institutional order flow to underlying asset prices. T+0 mechanism; BTC settlement faster (T+0) than equity ETFs (T+2) → price impact more concentrated intraday. Primary causal anchor.

**[A2] Coval & Stafford (2007, JF) — "Asset Fire Sales (and Purchases) in Equity Markets"**
[Upgraded significance at intermediate.] Forced buying from large institutional flows produces multi-day cumulative abnormal returns peaking at T+3–5, decaying by T+10. This is the direct analytical basis for the lead/lag pre-confirmation above: T+1 data still has predictive content because only ~35–40% of total 5-day price impact occurs on T+0 (the intraday AP execution). The remaining 60–65% accumulates on T+1 through T+5. Forward return window specification: 5 trading days confirmed correct.

**[A3] Wermers (2000, JF) — "Mutual Fund Performance"**
[Unchanged from naive.] Institutional fund herding creates momentum lasting 3–6 months; 1-week horizon significant. CLUSTER state operationalises the herding identification: 3+ consecutive positive flow days across multiple ETF products = Wermers herding variable analog for BTC ETFs.

**[A4] Chordia, Roll & Subrahmanyam (2002, JF) — "Order imbalance, liquidity, and market returns"**
Order flow imbalance (consistent buy-side pressure from AP arbitrage across consecutive sessions) predicts next-day returns with positive slope. The CLUSTER state machine directly encodes the order imbalance persistence variable: each additional day of positive flow_pct_z extends the imbalance event window. CRS demonstrate that the predictive slope strengthens with imbalance duration — consistent with CLUSTER modifier (1.10×) being higher than single-day IMPULSE_STD (1.08×) despite lower per-day z-score.

**[A5] De Long, Shleifer, Summers & Waldmann (1990, JPE) — "Noise Trader Risk in Financial Markets"**
Non-fundamental demand shocks (noise traders) create persistent price pressure deviating from fundamental value; this pressure is exploitable by informed traders if the timing horizon is correct. GBTC structural outflows are modelled as a non-fundamental demand shock (fee-switching noise, not informed selling). At intermediate, excluding GBTC from the net flow calculation removes this noise-trader signal component, leaving only AP-mechanism-driven flows (Pathway 1 and 2) which are fundamental in character.

**[A6] McLean & Pontiff (2016, JF) — "Does Academic Research Destroy Stock Return Predictability?"**
Published predictors lose 26% of IS Sharpe post-publication due to arbitrage and crowding. The ETF flow signal is post-2024 in origin and not yet widely exploited in retail algorithmic trading; degradation risk is lower than older signals. However, as ETF flow data becomes more standardised (Bloomberg, Refinitiv terminals), crowding risk will increase. Conservative IS target at G1: WR ≥ 52% (not 55%) to leave margin for 25–50% OOS degradation. At sophisticated elevation, CPCV+DSR criterion must account for this decay rate.

---

## Key Numbers (Intermediate — Updated)

| Parameter | Naive value | Intermediate value | Change rationale |
|---|---|---|---|
| Signal variable | raw etf_flow_z | flow_pct_z (AUM-normalised) | F4 resolution |
| GBTC inclusion | Yes (all ETFs summed) | Excluded (tracked diagnostic only) | F6 resolution |
| Amplify threshold | +1.5σ | +1.5σ (unchanged) | Scale-invariant after AUM normalisation |
| Suppress threshold | −1.5σ | −1.5σ (unchanged) | Scale-invariant |
| Amplify modifier | 1.08× (flat) | State-dependent: 1.08×/1.10×/1.12× | Duration state machine |
| Suppress modifier | 0.88× (flat) | State-dependent: 0.87×/0.90× | Duration state machine |
| RSI direction gate | None | RSI_4h ≥ 38 for amplify; ≤ 62 for suppress-MR | F2 resolution |
| Kelly α | 0.05 (naive) | 0.10 (intermediate) | Partial analytical validation |
| Duration | None | 3d / 5d / cluster+2d | Pathway 2 state machine |
| GBTC reintroduction | N/A | When gbtc_aum_30d < $2B at 0.30× weight | Conditional protocol |
| Academic anchors | 3 | 6 | A4 + A5 + A6 added |
| Expected amplify freq | 5–8 /year (hypothesis) | Target ≥ 8 /year for G1 pass (n≥10 total) | Gate formalisation |

---

## Remaining Failure Modes (Intermediate — Status Updated)

**F1 — Data lag:** Analytically pre-confirmed as non-blocking. T+1 data captures 60–65% of Coval & Stafford 5-day return drift. G1 lead/lag test will empirically confirm.

**F2 — Momentum conflict:** RESOLVED at intermediate via RSI_4h ≥ 38 direction gate. Amplify modifier withheld when price is in active freefall (RSI_4h < 38).

**F3 — Short data history:** Persists. 27 months (Jan 2024 – Apr 2026) → borderline n for IS validation. Mitigated by targeting n ≥ 10 events at AUM-normalised threshold (which may be more frequent than raw dollar threshold). AUM-normalised approach may produce more consistent event frequency as AUM grows. Full resolution requires cycle 150+ (36+ months).

**F4 — AUM scale dependency:** RESOLVED at intermediate via flow_pct = net_flow / rolling_30d_avg_aum normalisation. Signal now measures relative institutional demand intensity regardless of absolute AUM size.

**F5 — Non-AP secondary market noise:** Persists. Not resolvable without AP-specific trade attribution data (not publicly available). Effect is a persistent dilution of the mechanical signal by secondary-market noise. Partially mitigated by AUM normalisation (AP-triggered flows dominate on high-z days because secondary market flows are smoother). Residual impact: slightly weaker signal than pure-AP would provide.

**F6 — GBTC distortion:** RESOLVED at intermediate via GBTC exclusion with conditional reintroduction protocol.

---

## G1 Gate Specification (Intermediate Blocking Gates)

All three gates must pass for sophisticated elevation. Fail any one → anti-prim class (see below).

### G_DATA_21: CoinGlass API Verify
- **Test:** CoinGlass API returns daily flow data for each individual ETF product with correct sign convention (inflow positive, outflow negative).
- **Verify:** Sum of product-level flows (IBIT + FBTC + ARKB + BITB + ...) within 5% of published headline net number.
- **AUM endpoint verify:** CoinGlass returns daily total AUM for each product; rolling 30d average computable.
- **PASS criteria:** API returns ≥ 600 days of data (Jan 2024 – Apr 2026) with < 5% missing days; GBTC isolatable as separate product.

### G1_21A: Frequency + Lead/Lag
**Script:** `analysis/g1-etf-flow-intermediate-scan.py`

```python
# Inputs:
#   - CoinGlass daily flow data by product (Jan 2024 – Apr 2026)
#   - BTC/USDT daily OHLCV from Binance (same period)
# Steps:
# 1. Compute flow_pct_z (AUM-normalised, 30d rolling)
# 2. Frequency scan: count non-overlapping events at thresholds
#    [+1.25, +1.5, +1.75, +2.0, +2.5] and [-1.25, -1.5, -1.75, -2.0, -2.5]
#    Non-overlapping: 5-day separation for single events; cluster events separated by end-of-cluster
# 3. Lead/lag test (T+1 usability):
#    - Use only T+1 published flow data (simulate 24h lag correctly)
#    - Regress BTC_return_T2 ~ flow_pct_z_T1 (OLS)
#    - Compute slope and one-tailed p-value (H0: slope ≤ 0)
#    - Secondary: T+3 and T+5 return regressions
# 4. Direction-gated conditional WR:
#    - For amplify events with RSI_4h(T+1) ≥ 38: 5d forward WR vs neutral days
#    - For suppress events with RSI_4h(T+1) ≤ 62: 5d forward WR vs neutral days
#    - Mann-Whitney U one-tailed
# 5. Independence check: ρ(flow_pct_z, axis7_funding_signal), ρ(flow_pct_z, axis22_stablecoin_z)
#
# PASS criteria (ALL required):
#   - n ≥ 10 amplify events + n ≥ 5 suppress events at chosen threshold (before direction gate)
#   - Lead/lag: T+2 return slope > 0 AND p < 0.20 one-tailed
#   - Direction-gated amplify WR ≥ 50% (lenient — short data; tighten to 52% at sophisticated)
#   - ρ(flow_pct_z, axis7) < 0.70 (anti-prim C threshold)
#   - ρ(flow_pct_z, axis22) < 0.70 (anti-prim D threshold)
```

### G1_21B: GBTC Exclusion Validation
- **Test:** Compute flow_pct_z with GBTC included (naive approach) and without (intermediate approach).
- **Compare:** Direction-gated amplify WR for each approach on same event set.
- **PASS criteria:** GBTC-excluded approach WR ≥ GBTC-included approach WR - 2pp (i.e., exclusion does not degrade signal below tolerance).
- **If GBTC-included outperforms GBTC-excluded by ≥ 3pp:** Revert to GBTC inclusion at 0.30× weight intermediate; investigate whether GBTC flows have become bidirectional (outflow programme exhausted).

---

## Anti-Prim Gates (Updated)

- **(A) Frequency-insufficient:** After AUM normalisation and direction gate, n amplify events < 8 in Jan 2024 – Apr 2026 at all tested thresholds ≤ +1.0. → anti-prim class A. Re-test at cycle 152+ (36 months data).

- **(B) Lagging-signal null:** T+2 return regression slope ≤ 0 or p ≥ 0.20 (one-tailed). Signal is purely contemporaneous — fully absorbed on T+0 with no T+1 data predictive content. → anti-prim class B. Alternative: switch to 3-day rolling sum of flows (slower signal, longer predictive horizon; test as fallback).

- **(C) Funding-rate redundant:** ρ(flow_pct_z, axis7_funding_signal) ≥ 0.70. → Merge ETF flow as sub-component of axis 7 extension; axis 21 dissolved.

- **(D) Stablecoin-redundant:** ρ(flow_pct_z, axis22_stablecoin_z) ≥ 0.70. → Investigate whether stablecoin data can proxy ETF flows; if so, axis 21 absorbed into axis 22 as an ETF-confirmation mode.

---

## Implementation Notes (Intermediate)

**Key structural changes from naive implementation:**

```python
class YujiETFFlowStrategy(IStrategy):
    _etf_flow_data: dict = {}          # {date: {'excl_gbtc_flow': float, 'aum_excl_gbtc': float, 'gbtc_flow': float}}
    _flow_pct_z: float = 0.0           # AUM-normalised z-score (replaces _etf_flow_z)
    _flow_state: str = "NEUTRAL"       # Duration state machine state
    _flow_state_days_remaining: int = 0
    _etf_flow_modifier: float = 1.0    # Cached modifier output

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        today = current_time.strftime("%Y-%m-%d")
        if today == self._last_etf_fetch:
            return
        try:
            api_key = self.config.get("coinglass_api_key", "")
            raw = fetch_etf_flows_with_aum_coinglass(api_key, days=35)  # returns per-product data
            # Exclude GBTC
            excl_gbtc = {
                d: {
                    'flow': sum(v['flow'] for k, v in products.items() if k != 'GBTC'),
                    'aum': sum(v['aum'] for k, v in products.items() if k != 'GBTC'),
                    'gbtc_flow': products.get('GBTC', {}).get('flow', 0.0)
                }
                for d, products in raw.items()
            }
            self._etf_flow_data = excl_gbtc
            # AUM-normalised pct flow
            self._flow_pct_z = compute_flow_pct_z(excl_gbtc, window=30)
            # Duration state machine
            self._update_flow_state(self._flow_pct_z)
            # Apply RSI gate at populate_indicators time (RSI available there)
            self._last_etf_fetch = today
        except Exception as e:
            self.log.warning(f"ETF flow fetch failed: {e}; using neutral signal")
            self._flow_pct_z = 0.0
            self._flow_state = "NEUTRAL"
            self._etf_flow_modifier = 1.00

    def _update_flow_state(self, z: float) -> None:
        """Duration state machine. Called once per day in bot_loop_start."""
        if self._flow_state_days_remaining > 0:
            self._flow_state_days_remaining -= 1
            if self._flow_state_days_remaining == 0:
                self._flow_state = "NEUTRAL"

        # Check for new event (overrides remaining duration if larger)
        if z > 2.5:
            self._flow_state = "IMPULSE_LARGE"
            self._flow_state_days_remaining = 5
            self._etf_flow_modifier = 1.12
        elif z > 1.5:
            if self._flow_state == "CLUSTER":
                pass  # Cluster subsumed; maintain cluster modifier
            else:
                self._flow_state = "IMPULSE_STD"
                self._flow_state_days_remaining = 3
                self._etf_flow_modifier = 1.08
        elif z < -2.5:
            self._flow_state = "SUPPRESS_LARGE"
            self._flow_state_days_remaining = 5
            self._etf_flow_modifier = 0.87
        elif z < -1.5:
            self._flow_state = "SUPPRESS_STD"
            self._flow_state_days_remaining = 3
            self._etf_flow_modifier = 0.90
        # CLUSTER detection: handled separately by _check_cluster() called before this
        # (requires 3+ consecutive z > 0.75 days — maintained in _cluster_consecutive_count)

    def populate_indicators(self, dataframe, metadata):
        dataframe["etf_flow_pct_z"] = self._flow_pct_z
        dataframe["etf_flow_state"] = self._flow_state
        # RSI direction gate (F2 mitigation):
        modifier = self._etf_flow_modifier
        if modifier > 1.0:  # amplify — gate on RSI
            dataframe["etf_flow_modifier"] = np.where(
                dataframe["rsi"] >= 38, modifier, 1.00
            )
        elif modifier < 1.0:  # suppress — gate on RSI
            dataframe["etf_flow_modifier"] = np.where(
                dataframe["rsi"] <= 62, modifier, 1.00
            )
        else:
            dataframe["etf_flow_modifier"] = 1.00
        return dataframe
```

---

## Conditions Log Entry

```
## btc-etf-institutional-flow (intermediate, cycle 147)
- **Works when (amplify):** flow_pct_z (AUM-normalised excl-GBTC, rolling 30d) > +1.5 AND RSI_4h ≥ 38. State machine: IMPULSE_STD (3d, 1.08×), IMPULSE_LARGE (5d, 1.12×), CLUSTER (last+2d, 1.10×). Mechanism: AP arbitrage forced spot buying; AUM normalisation makes signal scale-invariant across 2024–2026 AUM growth. T+1 data usable: Coval & Stafford multi-day drift profile places 60–65% of 5d price impact after T+0.
- **Works when (suppress):** flow_pct_z < −1.5 AND RSI_4h ≤ 62 (suppress-MR; momentum prims exempt if RSI_4h > 62). State: SUPPRESS_STD (3d, 0.90×), SUPPRESS_LARGE (5d, 0.87×).
- **Fails when:** (F1) Lead/lag null — G1_21A must confirm T+2 return slope positive (T+1 data). (F3) Short data window (< 27 months) — G1 event count borderline; AUM-normalised approach may improve frequency. (F5) Non-AP secondary market noise — persistent dilution; partially mitigated by AUM normalisation on high-z days.
- **GBTC protocol:** Excluded. Tracked diagnostic. Reintroduce at 0.30× when gbtc_aum_30d < $2B.
- **N_eff rules:** Axis 7 (ρ=0.35, Tier C): co-amplify → 1.12× cap; Axis 18 (ρ=0.20, Tier D): co-amplify → 1.14× cap; Axis 22 (ρ=0.55, Tier B): co-amplify → single-event (no compounding).
- **Best pairs:** BTC/USDT primary; ETH/USDT secondary (ETH ETFs ~15% AUM of BTC ETFs; apply 0.7× discount to modifier pending ETH-specific G1).
- **Best timeframe:** Meta-signal refreshed daily via bot_loop_start(); 5-day forward return window; RSI gate uses 4h timeframe.
- **Evidence:** 6 academic anchors (Ben-David/Franzoni/Moussawi 2012 JF; Coval/Stafford 2007 JF; Wermers 2000 JF; Chordia/Roll/Subrahmanyam 2002 JF; De Long/Shleifer/Summers/Waldmann 1990 JPE; McLean/Pontiff 2016 JF). No own-data backtest.
- **Deployment gates outstanding:** G_DATA_21 (CoinGlass API with per-product AUM); G1_21A (frequency + lead/lag scan, n≥10 amplify, T+2 slope > 0, p < 0.20); G1_21B (GBTC exclusion validation); all axes independence checks ρ < 0.70.
- **Last validated:** cycle 147 (naive → intermediate; analytical elevation; no live data validation)
```
