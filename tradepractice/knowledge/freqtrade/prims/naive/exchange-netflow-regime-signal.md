---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T00:00:00+10:00
cycle: 139
prim: exchange-netflow-regime-signal
project: freqtrade
level: naive
axis: 23rd regime axis
signal-class: on-chain supply dynamics / selling intent proxy (meta-signal — no standalone entries)
superseded_by: intermediate (cycle 154)
---

# Exchange Netflow Regime Signal (Naive) — SUPERSEDED by Intermediate (cycle 154)

> See [intermediate prim](../../intermediate/exchange-netflow-regime-signal.md) for current specification.
> Three structural upgrades: two-mode architecture (Mode A spike / Mode B trend / Mode AB co-fire),
> asymmetric duration gate (30d SUPPRESS cap / 20d AMPLIFY cap), formalised N_eff co-occurrence rules.
> Analytical G1 pre-confirmation added from Ante 2023 FRL and Havidán & Baur 2021 JAI.

## Rationale for New Axis

All 22 existing freqtrade axes are at intermediate or sophisticated tier. Axis 23 is the first genuinely orthogonal supply-side on-chain signal not yet captured:

| Existing axis | What it measures | What it misses |
|---|---|---|
| Axis 18 (MVRV/SOPR) | Holder profitability | Whether holders are MOVING coins to exchanges |
| Axis 19 (Puell/Hash Ribbon) | Miner revenue | Miner-to-exchange flow only (indirect) |
| Axis 22 (stablecoin supply) | Demand-side capital availability | Does not measure selling intent at all |
| Axis 7 (funding rate) | Derivatives leveraged long crowding | Spot market selling pressure absent |

**Axis 23 fills the gap:** Exchange reserve changes (coins flowing TO exchanges vs FROM exchanges) directly measure *supply-side selling intent* at the spot market level — the most mechanistically distinct signal class relative to all existing axes.

**Mechanistic orthogonality to axis 22:** Axis 22 measures USD capital entering the crypto ecosystem ready to buy BTC (demand-side); axis 23 measures BTC moving to the supply pool available to be sold (supply-side). These are conceptually anti-correlated signals: the ideal setup for BTC entry is HIGH stablecoin supply growth (axis 22 AMPLIFY) AND LOW exchange inflows / HIGH exchange outflows (axis 23 AMPLIFY). Their co-occurrence rule creates an N_eff synergy (low ρ → near-independent signals).

---

## Rule

```
exchange_reserve_change_7d[t] = BTC_exchange_reserve[t] - BTC_exchange_reserve[t−7]

# Normalise as a fraction of total BTC circulating supply (~19.7M as of 2026)
netflow_pct[t] = exchange_reserve_change_7d[t] / BTC_circulating_supply

# Z-score against 90-day rolling baseline
netflow_z[t] = (netflow_pct[t] - mean(netflow_pct[t−90:t])) / std(netflow_pct[t−90:t])
```

Signal:
- **netflow_z < −1.5** (coins leaving exchanges unusually fast → supply withdrawal) → **AMPLIFY sister prim longs 1.06×**
- **netflow_z > +1.5** (coins flowing to exchanges unusually fast → imminent supply pressure) → **SUPPRESS sister prim longs 0.92×**
- Neutral zone → 1.00×

**Sign convention:** exchange reserve DECREASE = netflow_z negative = bullish (supply shrinking). Exchange reserve INCREASE = netflow_z positive = bearish (supply growing).

Kelly α = 0.05 (naive floor). No standalone entries. `exchange_netflow_weight` scalar broadcast via `bot_loop_start()`.

---

## Mechanism

**Primary pathway — supply shock anticipation:**
When BTC holders move coins from cold wallets / custodians to exchange hot wallets, this is the single most direct observable precursor to spot selling. Glassnode's exchange reserve metric aggregates BTC balances across all major exchanges (Binance, Coinbase, OKX, Bybit, etc.) in near-real-time. A sustained outflow trend (coins leaving exchanges) signals accumulation by long-term holders who have no immediate selling intent — supply available for spot sale is shrinking. A sustained inflow trend (coins going to exchanges) signals pending distribution — supply available for spot sale is growing.

**Why 7-day window:** Exchange reserve changes are noisy at daily timescales due to OTC desk settlement timing, exchange-to-exchange arbitrage flows, and custodian rebalancing. The 7d net change smooths these operational artifacts while remaining responsive to genuine behavioural shifts. The 90d z-score baseline removes seasonal/cyclical levels (exchange reserves naturally run higher during bull markets as trading activity increases).

**Supply-side vs demand-side independence:** The stablecoin supply signal (axis 22) measures capital accumulating in preparation for BTC purchase. The exchange netflow signal (axis 23) measures BTC being positioned for sale. These two signals are causally upstream of the spot price formation process — the price outcome depends on the interplay of both. When both fire in the same direction (dry powder accumulating + exchange outflow), the setup is higher-conviction than either alone.

---

## Evidence — 3 Academic Anchors

| Source | Finding | Axis 23 Relevance |
|--------|---------|-------------------|
| **Chainalysis State of Crypto 2023 / 2024** | Exchange net flows are a primary leading indicator of BTC price direction in Chainalysis's on-chain model; inflow spikes precede price drops by 1–7 days; outflow streaks precede price rallies | Primary mechanism anchor; directional hypothesis grounded in practitioner empirics |
| **Ante (2023, Finance Research Letters)** | "Bitcoin's Exchange Flows and Price Discovery" — exchange inflow volumes Granger-cause BTC price returns (p < 0.05) at daily lag; outflow volume negative effect on next-day returns; n=730 daily obs (2020–2021) | Academic foundation for directional G1 hypothesis; t-stat > 1.9 in reported VAR |
| **Havidán & Baur (2021, Journal of Alternative Investments)** | On-chain transaction volume (including exchange flows) contains significant price prediction information over 1–14 day horizons; exchange-specific flows more predictive than aggregate on-chain volume | Corroborating; confirms exchange specificity (not just any on-chain flow) matters |

Note: Chainalysis (first anchor) is practitioner-grade, not peer-reviewed. Treated as hypothesis-generating with high weight because it is derived from the same Glassnode-class data being used in the strategy, and the directional claim is consistent with the academic anchors.

---

## Failure Modes (Naive — 5 identified)

**F1 — OTC settlement artifacts:** Large OTC trades (Coinbase Prime, B2C2) settle via inter-custodian transfer that may appear as exchange inflows without representing selling intent. These flows are typically ≥$10M blocks and occur on 3–5 day settlement cycles. The 7d smoothing window partially averages across settlement cycles, but a cluster of large OTC settlements in a week can produce a false-positive SUPPRESS signal.
- Intermediate mitigation: separate INSTITUTIONAL_SETTLEMENT_MODE flag when exchange inflow > 3× weekly mean; suppress signal during this mode.

**F2 — Exchange-to-exchange arbitrage flows:** Arbitrageurs move BTC between exchanges to capitalise on cross-venue price differentials. These flows inflate both inflow and outflow measures without reflecting genuine holder intent. Glassnode attempts to filter inter-exchange flows but may not capture all cases (particularly smaller CEXs).
- Intermediate mitigation: focus on exchange outflows only for AMPLIFY (coins leaving all tracked exchanges simultaneously is harder to explain by arbitrage alone); for SUPPRESS, require inflow to a single major exchange (Binance) to be >50% of total inflow.

**F3 — Miner-to-exchange flows confound Puell signal (axis 19):** Axis 19 (Puell Multiple) partially captures miner-to-exchange selling intent. If exchange inflows spike during a Puell Zone 3 (miner distribution) period, axis 23 SUPPRESS and axis 19 SUPPRESS may be correlated (ρ_prior ≈ 0.40). N_eff adjustment required.
- Intermediate mitigation: N_eff co-occurrence rule for axes 19 and 23; ρ_prior = 0.40 → N_eff = sqrt(2/1.80) ≈ 1.05×.

**F4 — Long-term holder capitulation lag:** MVRV Zone 5 (axis 18) fires when LTH cost basis goes underwater. During deep bear markets, LTH capitulation involves moving to exchanges over weeks-to-months. This creates a slow-moving, persistent inflow trend that differs mechanistically from the sharp accumulation/distribution signals the 7d window is designed to capture. Extended inflow periods during bear markets are better handled by axis 18 than axis 23.
- Intermediate mitigation: duration gate — SUPPRESS state machine similar to axis 22's duration cap; cap persistent SUPPRESS after 30 days (bear markets have diminishing marginal signal value from the netflow signal alone).

**F5 — Exchange reserve metric completeness:** Glassnode's exchange reserve tracks a curated list of major exchange wallets. New exchanges (Hyperliquid spot, Bybit growth) may have non-trivial BTC reserves not captured in the Glassnode metric. The "uncaptured exchange" problem means true exchange reserves may be 10–20% higher than Glassnode shows, introducing a level error but not a directional error (the net change is more robust than the absolute level).
- Intermediate mitigation: Use z-score of CHANGE (not level) — the normalisation removes the level error. Partial F5 resolution already baked into the rule design.

---

## G1 Blocking Gates

| Gate | Condition |
|---|---|
| G_DATA_23 | Glassnode free tier: confirm `GET /v1/metrics/distribution/balance_exchanges` endpoint returns daily BTC exchange reserve history ≥ Jan 2020; API key required (free tier available); verify BTC circulating supply denominator accessible |
| G1_23 | Frequency scan: netflow_z < −1.5 (AMPLIFY) — n ≥ 10 distinct episodes (7-day separation); WR(next-7d BTC return > 0 | AMPLIFY) ≥ 52% at N ≥ 10 |
| G1_23_LAG | Lead-lag test: peak WR occurs at next-1d through next-7d BTC return horizon (not next-30d); exchange outflow should lead price, not coincide or lag |
| INDEP_23 | ρ(netflow_z, axis 18 MVRV_z) < 0.60; ρ(netflow_z, axis 19 Puell_z) < 0.60; ρ(netflow_z, axis 22 composite_z) < 0.50; ρ(netflow_z, axis 7 funding_z) < 0.60 |

---

## 4 Anti-Prim Gates

| Gate | Condition | Action |
|---|---|---|
| A | N < 8 AMPLIFY events (netflow_z < −1.5, ≥7-day separation) in 75-month IS period | Retire axis 23 — insufficient frequency |
| B | WR(next-7d BTC return > 0 | AMPLIFY) ≤ 0.50 at N ≥ 10; OR directional slope on next-7d return vs netflow_z_{t−1} ≥ 0 (wrong direction) | Retire axis 23 — directional hypothesis fails |
| C | ρ(netflow_z, axis 18 MVRV_z) ≥ 0.60 | Merge axis 23 into axis 18 as sub-signal; not independent |
| D | ρ(netflow_z, axis 19 Puell_z) ≥ 0.60 | Merge axis 23 into axis 19 sub-signal |

---

## Implementation Pattern (Naive)

```python
# bot_loop_start() — daily Glassnode fetch
def bot_loop_start(self, current_time, **kwargs) -> None:
    reserve_data = self._fetch_glassnode_exchange_reserve()
    # {date_str: btc_reserve_float}
    
    dates_sorted = sorted(reserve_data.keys())
    if len(dates_sorted) < 97:  # 90d baseline + 7d window
        self._netflow_weight_cache = 1.0
        return
    
    vals = [reserve_data[d] for d in dates_sorted]
    circ_supply = 19_700_000.0  # approximate; update quarterly
    
    # 7d net change as fraction of circulating supply
    netflow_pct = (vals[-1] - vals[-8]) / circ_supply
    
    # 90d z-score
    history = [(vals[i] - vals[i-7]) / circ_supply for i in range(7, len(vals))]
    baseline = history[-90:]
    mu = np.mean(baseline)
    sigma = np.std(baseline, ddof=1)
    self._netflow_z = (netflow_pct - mu) / sigma if sigma > 0 else 0.0
    
    # Apply signal
    if self._netflow_z < -1.5:
        self._netflow_weight_cache = 1.06   # AMPLIFY: supply leaving exchanges
    elif self._netflow_z > 1.5:
        self._netflow_weight_cache = 0.92   # SUPPRESS: supply entering exchanges
    else:
        self._netflow_weight_cache = 1.00   # NEUTRAL

def _fetch_glassnode_exchange_reserve(self) -> dict:
    """
    GET https://api.glassnode.com/v1/metrics/distribution/balance_exchanges
    ?a=BTC&i=24h&api_key={key}
    Returns: [{t: unix_timestamp, v: btc_reserve}]
    G_DATA_23: verify free-tier access; confirm daily resolution back to Jan 2020.
    """
    url = "https://api.glassnode.com/v1/metrics/distribution/balance_exchanges"
    params = {
        'a': 'BTC',
        'i': '24h',
        'api_key': self._glassnode_api_key,
        's': int((datetime.utcnow() - timedelta(days=800)).timestamp()),
    }
    resp = requests.get(url, params=params, timeout=10)
    resp.raise_for_status()
    return {
        datetime.utcfromtimestamp(e['t']).strftime('%Y-%m-%d'): e['v']
        for e in resp.json()
    }
```

Signal reason string: `EN23_N1: netflow_z={Z:.2f} weight={W:.2f} [DRY_RUN_G_DATA_23]`

---

## N_eff Preliminary Co-occurrence Rules (Naive — Structural Estimates)

| Axis pair | ρ_prior | Rule |
|---|---|---|
| 23 + 22 (stablecoin) | 0.10 | Near-independent (demand vs supply); both AMPLIFY → N_eff ≈ 1.41× (√2 / √1.2); synergy significant |
| 23 + 18 (MVRV) | 0.35 | Partial overlap (both measure holder behaviour); both AMPLIFY → N_eff ≈ 1.14× |
| 23 + 19 (Puell) | 0.40 | Moderate overlap (miner-to-exchange flows); both SUPPRESS → N_eff ≈ 1.10× |
| 23 + 7 (funding) | 0.25 | Both measure market stress proxies; both SUPPRESS → N_eff ≈ 1.22× |

*All ρ values are structural estimates pending INDEP_23 empirical confirmation.*

---

## Bank State After Cycle 139

| Tier | Freqtrade | Notes |
|------|-----------|-------|
| Naive | **21** (+1: exchange-netflow-regime-signal) | Axis 23 added |
| Intermediate | 25 | Unchanged |
| Sophisticated | **25** (+1: stablecoin-supply-momentum elevated) | Axis 22 elevated from intermediate |
