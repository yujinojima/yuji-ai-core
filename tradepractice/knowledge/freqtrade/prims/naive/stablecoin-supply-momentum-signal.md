---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T00:00:00+10:00
cycle: 135
prim: stablecoin-supply-momentum-signal
project: freqtrade
level: naive
axis: 22
signal-class: crypto-market liquidity proxy (meta-signal — no standalone entries)
parent: none
status: ACTIVE
---

# Stablecoin Supply Momentum Signal (Naive)

## Epistemic Genealogy

**Naive (cycle 135):** New axis. Combined USDT + USDC circulating supply 7-day growth rate, z-scored vs 90-day rolling baseline, as a crypto-ecosystem liquidity ("dry powder") proxy. Rapid supply expansion → capital entering crypto ecosystem not yet deployed to BTC → AMPLIFY long MR entries 1.06×; rapid supply contraction → capital leaving ecosystem → SUPPRESS long MR entries 0.92×. Single variable. No standalone entries. Pure meta-signal modifier. 3 academic anchors. G1 blocking gate: G_DATA confirm (DeFiLlama API test + cross-chain dedup verification) + frequency scan + lead/lag regression.

---

## Rule

**Stablecoin Supply Momentum Signal (naive):**

Compute `stablecoin_supply_combined` = USDT_circulating_supply_USD + USDC_circulating_supply_USD
(DeFiLlama Stablecoins API, free tier, daily granularity, algorithmic stablecoins excluded).

Compute `supply_growth_7d` = (stablecoin_supply_combined[t] / stablecoin_supply_combined[t−7]) − 1.

Compute `stablecoin_z` = (supply_growth_7d − mean_90d) / std_90d (rolling 90-day z-score).

- **stablecoin_z > +1.5**: **AMPLIFY sister prim longs 1.06×**. Crypto-ecosystem capital reserves growing faster than baseline → more dry powder available for BTC deployment.
- **stablecoin_z < −1.5**: **SUPPRESS sister prim longs 0.92×**. Capital leaving crypto ecosystem → structural demand headwind for BTC.
- **−1.5 ≤ stablecoin_z ≤ +1.5**: no modifier (1.00×).

Kelly floor: α=0.05 (naive — no IS calibration). No standalone entries.

**Raw threshold alternative (naive — if < 90 days of rolling history):**
- supply_growth_7d > +1.5% per 7 days → amplify 1.06×
- supply_growth_7d < −1.0% per 7 days → suppress 0.92×
- Between −1.0% and +1.5% → neutral 1.00×

Asymmetric raw thresholds: stablecoin supply growth is right-skewed (large episodic issuance events dominate; contraction is rarer and smaller).

---

## What Stablecoins Are and Why They Matter

Stablecoins are USD-pegged digital assets that function as the primary settlement and reserve currency of the crypto ecosystem. As of April 2026:

| Stablecoin | Issuer | Approx Market Cap |
|-----------|--------|-------------------|
| USDT | Tether | ~$140B |
| USDC | Circle | ~$40B |
| USDS/DAI | MakerDAO | ~$8B |
| FDUSD | First Digital | ~$4B |

USDT + USDC constitute >85% of total stablecoin market cap. They function as:
1. The primary BTC trading pair on centralised exchanges (BTC/USDT is the highest-volume pair globally)
2. The primary settlement currency for crypto-to-fiat conversion
3. The reserve asset for DeFi protocols (yield farming, liquidity provision)
4. The temporary parking vehicle for institutional participants between deployments

**Issuance and redemption mechanics:**
- USDT: Tether issues new tokens upon receipt of USD from qualified counterparties (exchanges, institutions). Issuance happens in batches, several times per week when demand exceeds available float.
- USDC: Circle issues against 1:1 USD held in US Treasury money-market funds. Regulated monthly attestation. Near-instant issuance for qualified institutional clients; redeemable on demand.
- Redemption (burning) occurs when holders return stablecoins to issuer for USD.

**Signal interpretation:** When stablecoin supply grows above its recent baseline rate, more USD-equivalent capital has been injected into the crypto ecosystem than usual. This capital sits as USDT/USDC until it is deployed to buy BTC/altcoins, used as collateral in DeFi, or transferred to an exchange in anticipation of trading. The supply signal is a **leading indicator of potential BTC demand** — it measures the reservoir filling, not the flood.

---

## Mechanism — 3 Causal Pathways

**Pathway 1 — Dry Powder Accumulation (primary, 1–7 day lag)**
When institutional participants (crypto hedge funds, family offices, OTC desks) plan to acquire BTC, they first convert USD to USDT/USDC via Tether/Circle and park it in stable reserve while executing their BTC acquisition over multiple sessions. The stablecoin supply increase precedes the BTC buying by 1–7 days (the time to work a large position across multiple sessions to minimise market impact). This creates a predictable: stablecoin supply surge → BTC buying pressure in T+1 to T+7 window.

**Pathway 2 — DeFi Yield Recycling (2–14 day lag)**
DeFi yield farmers accumulate stablecoins from protocol rewards and then periodically rotate into BTC to capture upside. Periods of high stablecoin supply growth often coincide with elevated DeFi incentive programs, which subsequently drive rotation to risk assets including BTC. This pathway explains why the stablecoin-BTC lead can extend beyond the simple "buy order queue" explanation.

**Pathway 3 — Retail On-Ramp Signal (3–10 day lag)**
Retail participants use stablecoin purchases as the first step in a crypto investment journey: buy USDC on Coinbase → transfer to exchange → buy BTC. Retail investors typically accumulate stablecoins over a pay cycle (biweekly/monthly), then deploy. A supply surge driven by retail is visible as a broad-based increase across small-wallet addresses on-chain (detectable via Etherscan but not required for this signal). The supply signal captures aggregate retail deployment intent before the BTC purchase executes.

**Why meta-signal (not standalone entry trigger):**
The stablecoin supply signal measures capital INTENT, not price-action TRIGGER. It does not tell you when to enter BTC — it tells you whether the macro environment of crypto capital availability is supportive or hostile. A 1.06× amplifier when supply is surging is appropriate: the MR entry trigger still comes from price-action (RSI, VWAP, OI divergence), but the probability of a successful MR recovery is elevated when more capital is available to bid the recovery.

---

## Distinction from All 21 Existing Freqtrade Axes

| Axis | Signal type | Domain | Why distinct from stablecoin supply |
|------|------------|---------|-------------------------------------|
| 7: funding-rate-crowding | Perpetual funding rate | Derivatives | Measures derivatives sentiment (who is long/short in perps); stablecoin = spot capital reserve in USD |
| 11: cross-asset-macro-correlation | DXY, US10Y, SPX, Gold | Macro/equity | Measures fiat market correlation; stablecoin supply is a separate crypto-native capital metric orthogonal to DXY |
| 14: realized-vol-term-structure | Realised volatility shape | Vol regime | Vol-based; does not measure capital reserves available for deployment |
| 18: on-chain-supply-dynamics | MVRV, SOPR, BTC exchange flows | BTC on-chain | Measures what BTC holders are DOING with their BTC; stablecoin = what USD holders are DOING with their USD — orthogonal assets, orthogonal chains |
| 19: miner-supply-profitability | Puell multiple, hash rate | Mining economics | Supply-side (miner selling pressure); stablecoin = demand-side capital reserve |
| 20: VRP (volatility-risk-premium) | RV − IV | Options | Options mispricing; orthogonal to dollar capital level |
| 21: btc-etf-institutional-flow | ETF net daily flows | Regulated institutional | Specific vehicle (ETF wrapper), specific counterparty (AP arbitrageurs); stablecoin = total ecosystem capital across all vehicles and counterparties including retail, DeFi, and unregulated institutional |

**Axis 22 is the only axis that:**
1. Captures **total crypto-ecosystem USD-equivalent capital reserves** (not BTC-specific, not derivatives-specific, not regulated-channel-specific)
2. Measures **pre-deployment demand** rather than active buying/selling behaviour
3. Reflects aggregate retail, DeFi, and institutional capital simultaneously
4. Operates on **stablecoin blockchain data** (Ethereum, Tron) rather than BTC chain data, derivatives data, or equity channel data

No existing axis captures this signal class.

---

## Evidence — 3 Academic Anchors

**[A1] Ante, Fiedler & Strehle (2021, Finance Research Letters) — "The Influence of Stablecoin Issuances on Cryptocurrency Markets"**
Using a VAR framework with USDT issuance events from January 2017 to December 2020 (1,461 daily observations), found that USDT issuance events are followed by statistically significant positive BTC returns in the 1–3 days post-issuance (t-statistic > 2.0). Proposed mechanism: stablecoin issuance provides the liquidity medium for institutional-scale purchases. Naive relevance: establishes the causal direction (issuance → BTC return, not reverse) and the 1–3 day forward window as the predictive horizon. The paper uses discrete issuance event counts; this prim extends to a continuous supply growth rate z-score for finer-grained signal.

**[A2] Griffin & Shams (2020, Journal of Finance) — "Is Bitcoin Really Untethered?"**
Found that Tether issuance patterns from 2017–2018 preceded positive BTC returns. IRF (impulse response function) shows BTC returns peak at +1.5% cumulative over days 1–3 post-issuance, then partially decay. While the supply-driven interpretation of the mechanism is debated (partially rebutted by Hoegner 2020; CFTC settlement did not confirm manipulation), the key empirical finding remains: "hours and days after Tether is printed, Bitcoin prices rise." Naive relevance: provides quantified forward-return estimates (+1.5% cumulative 3-day) for calibrating modifier size; confirms 1–3 day lead regardless of mechanism debate.

**[A3] Saggu & Ante (2023, Finance Research Letters) — "Intraday Bitcoin Price Movements: The Role of the U.S. Dollar, Stablecoins, Technical Indicators, and Safe-Havens"**
Using intraday data (2018–2021), found that stablecoin market capitalisation changes are one of the strongest explanatory variables for intraday BTC price movements (β = 0.31, p < 0.01), outperforming DXY, technical indicators, and safe-haven assets (gold, VIX). The relationship holds at 1h, 4h, and 24h timeframes. Naive relevance: establishes stablecoin supply as an independent explanatory variable at multiple timeframes used in freqtrade strategies; β = 0.31 implies economically significant scale at the intraday to daily trading horizon.

---

## Key Numbers (Naive — All Hypotheses)

| Parameter | Value | Status |
|-----------|-------|--------|
| Data source | DeFiLlama Stablecoins API (free tier, no API key) | Free; JSON; daily granularity |
| Stablecoins included | USDT + USDC only | Top 2 by market cap; >85% of total; excludes algorithmic |
| Data availability | Jan 2020 – present (~75 months as of Apr 2026) | Much longer than ETF data (27m) |
| Growth rate window | 7-day rolling | Captures weekly capital cycle; less noise than daily |
| z-score normalisation window | 90 trading days | Captures quarterly capital cycles; wider than ETF's 30d |
| Amplify threshold | stablecoin_z > +1.5 | Hypothesis — plateau scan at G1 |
| Suppress threshold | stablecoin_z < −1.5 | Hypothesis — plateau scan at G1 |
| Amplify modifier | 1.06× | Conservative; smaller than VRP (1.10×/1.15×) given less direct mechanism |
| Suppress modifier | 0.92× | Slightly stronger than amplify; capital exit is a more definitive signal |
| Forward window | T+1 to T+7 (Ante et al. 2021 VAR; Pathway 1) | Peak at T+3 |
| Kelly α | 0.05 (naive) | No IS validation |
| Expected amplify frequency | 10–20 z-score events/year at ±1.5σ | 75m data window; much higher than ETF estimate |
| Expected WR delta | +2–4pp vs unconditional | Conservative; Ante 2021 implies ~1.5% cumulative 3d |
| Expected ρ vs axis 7 | < 0.40 | Stablecoin supply changes weekly; funding 8-hourly |
| Expected ρ vs axis 21 | < 0.55 | Both demand-side; different channels; test at G1 |
| Assets | BTC primary; ETH secondary (USDC heavily DeFi-native) | ETH signal may be stronger via Pathway 2 |

---

## Key Failure Modes (Naive — Identified, Not Yet Mitigated)

**F1 — Velocity vs level conflation**: Signal uses 7-day growth rate, not absolute level. A supply surge when total level is already at historical peak (e.g., $200B combined) may mean something different from a surge when supply is recovering from a contraction. Level context may be required at intermediate tier (add MVRV-analogous "stablecoin level regime" gate).

**F2 — Tether opacity risk**: Tether's reserve attestations have historically been unreliable (2019 NYAG settlement; Deltec audit questions). A USDT issuance event may not represent genuine USD inflow — it may represent undisclosed commercial paper or rehypothecation. This introduces noise into the causal mechanism. Mitigation at intermediate: run USDC-only variant (regulated, monthly attestation, redeemable 1:1 with US Treasuries) and compare signal quality.

**F3 — Regulatory regime change**: SEC/FinCEN action against Tether or Circle could cause rapid stablecoin redemptions unrelated to BTC demand. False suppress signal. Mitigation at intermediate: cross-reference with news-velocity filter; if known regulatory event is driving contraction, neutralise signal.

**F4 — ETH-stablecoin DeFi dilution**: When ETH is in a major DeFi cycle (new protocols, yield incentive programs), USDC supply grows rapidly due to ETH-DeFi usage, not BTC demand. The signal fires, but capital may deploy to ETH rather than BTC. Mitigation at intermediate: if USDC growth rate >> USDT growth rate (ETH-DeFi indicator), reduce BTC amplify modifier to 1.02×.

**F5 — Algorithmic stablecoin exclusion**: DAI, FRAX, LUSD are backed by crypto collateral, not USD. Including them would contaminate the "USD capital flowing in" signal with "BTC/ETH being collateralised." Must exclude algorithmic stablecoins. DeFiLlama API allows filtering by peg type (peggedUSD) and backing mechanism (fiat-backed).

**F6 — Cross-chain USDT bridge transit double-counting**: USDT exists on 12+ chains (Ethereum, Tron, BSC, Solana, Arbitrum, Polygon, etc.). DeFiLlama aggregates cross-chain supply but may double-count USDT during bridge transit (minted on Tron, bridged to Ethereum shows on both chains during transit window). DeFiLlama's methodology mitigates this but must be verified at G_DATA step.

---

## Open Questions for Intermediate Elevation

1. **G_DATA confirm**: Does DeFiLlama Stablecoins API return reliable combined USDT + USDC supply? Does total match external sources (CoinGecko, Tether Transparency dashboard, Circle attestations)? Verify cross-chain deduplication methodology in DeFiLlama docs.

2. **G1 frequency scan**: How many `stablecoin_z > +1.5` (7d growth, 90d window) events occur in Jan 2020 – Apr 2026? With 75 months × estimated 10–20/year → n ≈ 60–125 total. If this high, tighten threshold to z > +2.0.

3. **Lead/lag test**: Does supply_growth_7d at time t predict positive BTC 3d forward return at t+3? Regress next-3d BTC return on stablecoin_z_{t−1} (using T+1 data). If slope only positive at t=0 (contemporaneous) → lagging indicator only → anti-prim B.

4. **USDC-only variant**: Does isolating USDC produce better frequency/WR than USDT+USDC combined? USDC also has better DeFi-BTC vs ETH-BTC decomposition (USDC is dominant in ETH DeFi; USDT is dominant in BTC trading pairs on centralised exchanges).

5. **Axis 7 and axis 21 independence**: ρ(stablecoin_z, axis 7 funding_rate_signal) and ρ(stablecoin_z, axis 21 etf_flow_z). Require both ρ < 0.65 for independent axis designation.

6. **Normalisation window comparison**: 30d vs 90d vs 180d. 90d is a hypothesis — the quarterly capital allocation cycle. Test whether 30d (monthly) or 180d (biannual) produces better forward-return predictability at G1.

7. **Suppress threshold calibration**: Supply contractions are rarer and smaller in magnitude than expansions (structural positive trend in stablecoin supply since 2020). The −1.5σ suppress threshold may be too sensitive given rarity. Test −1.5σ vs −2.0σ.

---

## Implementation Notes

**DeFiLlama Stablecoins API (free, no key required):**
```python
import requests
import pandas as pd
from datetime import datetime, timedelta

def fetch_stablecoin_supply(coins: list = ["USDT", "USDC"], lookback_days: int = 180) -> pd.DataFrame:
    """
    Fetch combined circulating supply of selected fiat-backed stablecoins from DeFiLlama.
    No API key required. Returns DataFrame indexed by date with 'supply_usd' column.
    DeFiLlama handles cross-chain deduplication (aggregates by canonical issuance chain).
    """
    base_url = "https://stablecoins.llama.fi"
    meta = requests.get(f"{base_url}/stablecoins?includePrices=false", timeout=15).json()
    
    target_ids = {
        coin['symbol']: coin['id']
        for coin in meta['peggedAssets']
        if coin['symbol'] in coins and coin.get('pegType') == 'peggedUSD'
    }
    
    dfs = []
    cutoff = datetime.utcnow() - timedelta(days=lookback_days)
    for symbol, coin_id in target_ids.items():
        resp = requests.get(
            f"{base_url}/stablecoincharts/all?stablecoin={coin_id}",
            timeout=15
        ).json()
        rows = []
        for entry in resp:
            dt = datetime.utcfromtimestamp(entry['date'])
            if dt < cutoff:
                continue
            supply = entry.get('totalCirculatingUSD', {}).get('peggedUSD', 0)
            rows.append({'date': dt.date(), 'supply': supply})
        dfs.append(pd.DataFrame(rows))
    
    combined = pd.concat(dfs, ignore_index=True)
    combined = combined.groupby('date')['supply'].sum().reset_index()
    combined.columns = ['date', 'supply_usd']
    return combined.sort_values('date').set_index('date')


def compute_stablecoin_z(supply_df: pd.DataFrame,
                          growth_window: int = 7,
                          z_window: int = 90) -> float:
    """
    Compute rolling z-score of 7d supply growth rate vs 90d baseline.
    Returns scalar stablecoin_z for today's signal.
    """
    supply = supply_df['supply_usd']
    growth_7d = supply.pct_change(growth_window)
    mean = growth_7d.rolling(z_window).mean().iloc[-1]
    std = growth_7d.rolling(z_window).std().iloc[-1]
    latest = growth_7d.iloc[-1]
    if pd.isna(std) or std == 0:
        return 0.0
    return float((latest - mean) / std)
```

**FreqTrade integration (bot_loop_start pattern):**
```python
class YujiStablecoinMomentumStrategy(IStrategy):
    _stablecoin_z: float = 0.0
    _last_stablecoin_fetch: str = ""

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        today = current_time.strftime("%Y-%m-%d")
        if today == self._last_stablecoin_fetch:
            return
        try:
            supply_df = fetch_stablecoin_supply(["USDT", "USDC"], lookback_days=180)
            self._stablecoin_z = compute_stablecoin_z(supply_df)
            self._last_stablecoin_fetch = today
        except Exception as e:
            self.log.warning(f"Stablecoin supply fetch failed: {e}; using neutral")
            self._stablecoin_z = 0.0

    def populate_indicators(self, dataframe, metadata):
        z = self._stablecoin_z
        if z > 1.5:
            dataframe["stablecoin_modifier"] = 1.06
        elif z < -1.5:
            dataframe["stablecoin_modifier"] = 0.92
        else:
            dataframe["stablecoin_modifier"] = 1.00
        dataframe["stablecoin_z"] = z
        return dataframe
```

---

## Anti-Prim Gates

- **(A) Frequency-insufficient**: G1 scan shows `stablecoin_z > +1.5` (7d growth, 90d window) produces < 8 distinct non-overlapping amplify events (7-day separation minimum) in Jan 2020 – Apr 2026. After lowering threshold to +1.0, still < 8 events → anti-prim class A (frequency-insufficient; wider data window or threshold recalibration required).

- **(B) Lagging-signal null**: Lead/lag regression shows stablecoin_z at time t has no statistically significant positive slope on BTC returns at t+1, t+2, t+3 using T+1 published data. If only contemporaneous (t=0) correlation → signal is purely confirmatory (post-hoc, not predictive) → anti-prim class B. Flip to: use 14-day rolling supply change instead of 7-day.

- **(C) Axis 7 redundant**: ρ(stablecoin_z, axis 7 funding_rate_crowding signal) ≥ 0.70 → stablecoin supply does not add independent information beyond derivatives-market sentiment → merge as sub-component of axis 7 extension → anti-prim class C.

- **(D) Axis 21 redundant**: ρ(stablecoin_z, axis 21 etf_flow_z) ≥ 0.70 → both capturing "institutional demand building" without sufficient differentiation → combine as weighted average demand signal or discard lower-performing → anti-prim class D.

---

## G1 Scan Target

**Script**: `analysis/g1-stablecoin-supply-scan.py`

```python
# Inputs: DeFiLlama combined USDT+USDC supply (Jan 2020 – Apr 2026, daily)
#         BTC daily OHLCV from Binance (same period)
# Steps:
# 1. Compute supply_growth_7d and stablecoin_z (90d window) for each day
# 2. Threshold plateau scan: z ∈ [1.0, 1.25, 1.5, 1.75, 2.0] amplify
#    z ∈ [-1.0, -1.25, -1.5, -1.75, -2.0] suppress
# 3. Count distinct non-overlapping events per threshold (7-day separation)
# 4. For each event: compute forward 1d, 3d, 7d BTC return
# 5. Mann-Whitney U test: amplify vs neutral days; suppress vs neutral days
# 6. Independence checks: ρ(stablecoin_z, axis 7), ρ(stablecoin_z, axis 21)
# 7. Lead/lag regression: next-3d BTC return ~ stablecoin_z_{t-1} (T+1 data)
# Gate PASS criteria:
#   - Frequency: n ≥ 10 amplify + n ≥ 5 suppress in Jan 2020–Apr 2026
#   - Direction: amplify → 3d forward return median > neutral (p < 0.15 one-tailed)
#   - Lead: slope on next-3d return vs stablecoin_z (T+1 data) positive
#   - Independence: ρ(stablecoin_z, axis 7) < 0.70; ρ(stablecoin_z, axis 21) < 0.70
```

---

## Novelty Assessment — Why This Axis Did Not Exist Before

The stablecoin market only reached systemic scale after 2020 (USDT surpassed $10B March 2020; USDC launched Oct 2018 but grew to significant scale in 2021). Key structural reasons this is a new axis, not a reformulation of existing signals:

1. **Pre-2020 inapplicability**: All existing MR and momentum axes were developed using 2017–2019 BTC data when stablecoin supply was too small to be reliable (USDT < $5B; most trading was BTC/USD directly on Bitfinex/Coinbase). The signal literally did not exist in the calibration data.

2. **Post-2020 market structure change**: BTC/USDT replaced BTC/USD as the dominant trading pair in 2020. Stablecoins became the primary on/off ramp for institutional and retail capital. This structural change makes stablecoin supply relevant today in a way it was not pre-2020.

3. **No equivalent prior signal**: Before stablecoins, the equivalent "dry powder" signal would have been OTC broker USD balance reports (private, not available). Stablecoins are the first transparent, publicly auditable measure of crypto-market USD reserves.

4. **Orthogonal to axis 21 (ETF flow)**: ETF flow measures regulated institutional capital via a specific regulated vehicle. Stablecoin supply measures the entire crypto-native capital reservoir across all participants and all vehicles — a fundamentally broader and different signal.

---

## Next-Cycle Elevation Targets (Intermediate)

Priority for cycle 136+ intermediate elevation:
1. Execute G_DATA confirm (DeFiLlama API test call; verify cross-chain dedup; compare vs Tether Transparency + Circle attestations)
2. Execute G1 frequency scan with lead/lag regression (Jan 2020 – Apr 2026)
3. If G1 passes: USDC-only variant comparison vs USDT+USDC combined
4. If G1 passes: axis 7 and axis 21 independence checks
5. If G1 passes: F4 DeFi dilution mitigation (USDC growth decomposition — USDC/USDT ratio as ETH-DeFi indicator)
6. If G1 passes: normalisation window comparison (30d vs 90d vs 180d)
7. If G1 passes: suppress threshold calibration (−1.5σ vs −2.0σ given rarity of contractions)
