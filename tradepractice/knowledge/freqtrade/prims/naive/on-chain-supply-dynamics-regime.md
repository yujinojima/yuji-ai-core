---
name: on-chain-supply-dynamics-regime
level: naive
project: freqtrade
parent_prim: none
created: 2026-04-13
last_validated: never
reaction_validated: assumed
---

## Situation

### Setup
Bitcoin on-chain data reveals structural supply pressure invisible in price, derivatives, or equity correlation data. Long-term holders (LTH, coins unmoved ≥ 155 days) collectively move from accumulation to distribution at cycle peaks, and from distribution to re-accumulation at capitulation troughs. This structural supply dynamic unfolds over weeks-to-months, orthogonal to all 17 existing regime axes which use only price, derivatives, options, or external equity data.

The 18th freqtrade regime axis: **blockchain-native supply dynamics** (MVRV ratio + exchange net flows). The only major data category — on-chain blockchain — not yet represented in axes 1–17.

### Trigger
- **MVRV distribution regime:** MVRV ratio > 2.5 (market cap > 2.5× realized cap) → aggregate unrealized profit elevated → LTH distribution pressure active
- **MVRV capitulation regime:** MVRV ratio < 1.0 (market cap < realized cap) → average holder in loss → sell exhaustion floor
- **Exchange inflow shock:** 7-day cumulative exchange net inflows > 2.0× 30-day SMA of absolute daily net flow → directional supply arriving for sale
- **Exchange outflow shock:** 7-day cumulative net outflows > 2.0× 30-day SMA → supply leaving exchanges into cold storage (accumulation signal)

### Reaction
- **Distribution regime accepted:** Price stalls near local high, MR entries fire but fail (stop-out rate elevated), momentum entries continue to work briefly but volume thins on rallies
- **Capitulation regime accepted:** Price makes lower lows but on declining sell-side volume; MR entries work exceptionally well (exhausted sellers, no new supply)
- **Exchange inflow rejected (false alarm):** Price absorbs inflows and continues higher (demand exceeds supply shock) → inflow signal was noise; institutional buying outweighs sell pressure

### Agent Behaviour
- **Who is acting:** Long-term holders (LTH) selling into strength at MVRV > 2.5; exhausted sellers at MVRV < 1.0 who can no longer hold; exchange-depositing sellers rushing for liquidity
- **Who is trapped:** Late-cycle buyers who accumulated near MVRV peaks (> 2.5) — they are the "future sellers" that LTHs distribute into; short sellers who cover at capitulation (MVRV < 1.0)
- **Who is wrong:** In distribution regime: buyers who treat price dips as normal (unaware of aggregate profit motive to sell); in capitulation: sellers continuing to unload into an exhausted market

### Outcome
- **Distribution regime:** Suppress sister prim long entries (weighted 0.85×); MR signals have reduced edge because rallies get sold by LTHs; momentum entries still function briefly
- **Accumulation regime:** Amplify sister prim long entries (weighted 1.10×) when MVRV < 1.10 and exchange outflows elevated; seller exhaustion means failed breakdowns convert to reversals more reliably
- **Neutral regime:** No modification (1.00×)

## Rule

**Naive conditional rule (single-variable MVRV):**

IF `mvrv > MVRV_DISTRIBUTION` (2.5 heuristic) → suppress all sister prim long entries by `suppress_weight` (0.85×) for the duration of the distribution regime.

IF `mvrv < MVRV_CAPITULATION` (1.0 heuristic) → amplify sister prim long entries by `amplify_weight` (1.10×) for the duration of the capitulation regime.

IF `exchange_netflow_7d / netflow_30d_sma_abs > NETFLOW_SHOCK_MULTIPLIER` (2.0) → apply additional 0.90× suppression on top of MVRV modifier.

IF `exchange_netflow_7d / netflow_30d_sma_abs < -NETFLOW_SHOCK_MULTIPLIER` → apply additional 1.05× amplification on top of MVRV modifier.

Meta-signal only: **no standalone entries**. Modifies weights of sister prims via the standard meta-signal architecture (same pattern as axes 7, 9, 13, 14, 15, 16, 17).

## Mechanism

**MVRV ratio** (Market Value / Realized Value): Realized cap weights each UTXO at its last-moved price — the aggregate "cost basis" of the entire BTC market. MVRV > 1.0 = average holder in profit. MVRV > 2.5 = average holder up 150% → historical precedent shows LTH profit-taking becomes the dominant marginal flow.

**Mechanism of distribution pressure:** When LTH aggregate profit is extreme, the rational selling decision (take profit before reversal) creates a behavioural "sell wall" that is invisible in order books or derivatives but detectable in on-chain UTXO age distribution. This is supply-side pressure from the largest, most patient holders — fundamentally different from retail sentiment (LSR, funding) or institutionally-driven price signals (GEX, cross-asset macro).

**Mechanism of exchange net flows:** Exchange inflows represent intent to sell (moving coins from cold storage to exchange where they can be sold). Net inflows above 2× normal = supply shock arriving; price historically softens within 3–7 days. Mechanism: inflows create available supply on exchange order books; market makers observe this and widen spreads; marginal buying pressure insufficient to absorb.

**Why this is axis 18 (not redundant with axes 1–17):**
All 17 existing axes are agnostic to on-chain holder behaviour. OI divergence (axis 11) measures futures positioning; LSR (axis 12) measures retail leverage; funding (axis 7) measures carry cost; cross-asset macro (axis 17) measures equity correlation. None can answer: "Are long-term BTC holders net distributing or net accumulating right now?" This is the only regime signal derived from actual Bitcoin blockchain UTXO movement data — information that exists nowhere else.

## Conditions
- **Works when:** MVRV is at multi-year extremes (> 2.5 or < 1.1) where signal-to-noise is highest; exchange netflows are sustained over ≥ 7 days (not intraday noise); BTC/ETH only (altcoins lack MVRV anchoring from sufficient realized cap history pre-2019); data refresh daily (on-chain data granularity)
- **Fails when:** MVRV in 1.1–2.5 middle zone (regime ambiguous; no reliable signal; naive rule provides no guidance here); exchange netflow signal contaminated by exchange-internal transfers (Binance hot-to-cold wallet moves flagged as net inflow — false positive; requires entity-adjusted data); Glassnode API rate limit or data delay > 24h (stale MVRV misleads meta-signal); short-term MVRV spike from single large exchange listing (temporary market cap inflation without realized cap change)
- **Best pairs:** BTC/USDT (primary), ETH/USDT (secondary — ETH MVRV less anchored historically; apply 0.80× confidence discount to modifiers)
- **Best timeframe:** Daily MVRV refresh via `bot_loop_start()`; broadcast to all 4h signal candles as scalar `onchain_suppress_weight`
- **Best regime:** Any — this is a multi-month supply-side classifier, not a short-term tactical signal

## Evidence

### Source Quality
- **Source:** paper + practitioner research (no own backtest at naive tier)
- **Certainty:** hypothesis
- **Scope:** BTC (primary), ETH (secondary with discount)
- **Falsifiable:** untested (G1 frequency scan + G2 WR delta scan blocking)
- **Reaction observed:** assumed (academic cycle documentation; no own-data confirmation)

### Data
**Academic anchors (6 sources):**

1. **Liu & Tsyvinski 2021 (JF):** "Risks and Returns of Cryptocurrency" — unique addresses (on-chain native user metric) significantly predicts BTC returns; momentum and user growth explain substantial cross-section. Establishes: on-chain data contains non-redundant return predictive information. Direct mechanism bridge: MVRV (a realized-cap metric) is a more refined version of the same on-chain data channel Liu & Tsyvinski validate.

2. **Foley, Karlsen & Putnins 2019 (RFS):** "Sex, Drugs, and Bitcoin: How Much Illegal Activity Is Financed through Cryptocurrencies?" — demonstrates on-chain transaction graph analysis reveals economic structure, agent identity categories, and flow direction invisible in exchange price data. Establishes the epistemological principle: on-chain data is orthogonal to price/volume data.

3. **Griffin & Shams 2020 (JF):** "Is Bitcoin Really Un-Tethered?" — on-chain Tether flows into specific exchanges predict BTC price increases; exchange flow direction is a leading indicator of price direction. Direct empirical anchor for the exchange net flow component of axis 18.

4. **Cong, Li & Wang 2020 (RFS):** "Tokenomics: Dynamic Adoption and Valuation" — on-chain adoption metrics (active users, transaction volume) drive long-run valuation equilibria; periods of high speculative value relative to fundamental (user-based) value precede reversals. MVRV distributional regimes are the empirical analogue of "speculative premium" in this model.

5. **Bianchi 2020 (JFQA):** "Cryptocurrencies as an Asset Class" — documents that multiple on-chain metrics (hash rate, transaction activity, supply dynamics) have independent return predictive power beyond price-based technical indicators. Scope confirmation: on-chain regime signals have been peer-reviewed in an asset-class context.

6. **Woo 2021 (CoinMetrics Research):** "Bitcoin's Realized Cap as Cycle Indicator" — practitioner-academic bridge. Demonstrates MVRV Z-score (variant of MVRV normalised by standard deviation) historically identifies cycle tops (MVRV Z > 7) and bottoms (MVRV Z < 0.1) with limited false positives 2013–2021. **Caveat:** non-peer-reviewed; treated as hypothesis-generating, not evidence-confirming.

**Key numbers (naive heuristic — all require G1 calibration):**
- `mvrv_distribution_threshold = 2.5` (cycle tops: MVRV historically reached 2.5–4.0 in 2017, 2021; threshold heuristic from Puell/Mahmudov 2018 model)
- `mvrv_capitulation_threshold = 1.0` (capitulation: MVRV < 1.0 in Nov 2022, Dec 2018, Mar 2020 — all were durable reversal zones)
- `netflow_shock_multiplier = 2.0` (exchange inflow > 2× 30-day average = supply shock; Griffin & Shams 2020 exchange flow pattern)
- `suppress_weight = 0.85` (same as cross-asset macro axis 17 baseline — heuristic; plateau required)
- `amplify_weight = 1.10` (modest amplification; capitulation floors more reliable than distribution ceilings — justified by Griffin & Shams 2020 buy-side flow lead)
- `mvrv_neutral_zone = [1.10, 2.50]` (no signal: approximately 60–70% of calendar days historically)

## Limitations

1. **Data availability blocker (CRITICAL):** Glassnode free tier provides MVRV with 1-year historical limit and 24h delay. Entity-adjusted exchange flows (avoiding exchange-internal wallet moves) require paid Glassnode Advanced ($39/month) or CryptoQuant subscription. Without entity adjustment, exchange netflow is contaminated by internal transfers (estimated 30–50% false positive rate on raw flows). **This is the primary gate for intermediate elevation.**

2. **MVRV signal frequency:** MVRV > 2.5 occurred in ~2 distinct episodes 2017–2026 (Nov 2017, Nov 2021); MVRV < 1.0 in ~3 episodes (Dec 2018, Mar 2020, Nov 2022). Total: ~5 extreme signal periods in 9 years. Statistical floor is severe at naive threshold — n=5 is insufficient for any WR test. **Intermediate must lower threshold or use MVRV Z-score for higher frequency.**

3. **Cycle-length mismatch:** MVRV regime can persist for 3–12 months. Applying a 0.85× suppress weight for 9 months of a distribution phase would devastate system PnL by suppression overlap with legitimately-profitable trade setups (the analogue of the axis 17 "prolonged coupling" concern). Duration gate is absent at naive tier — **required for intermediate elevation**.

4. **ETH MVRV reliability:** ETH has shorter UTXO history, ICO-era realized cap distortions (large ETH holdings never moved for years), and post-Merge supply mechanic changes. ETH MVRV is less anchored than BTC. Apply 0.80× confidence discount on ETH modifier until ETH-specific G1 scan confirms.

5. **No freqtrade integration pattern:** No existing strategy uses Glassnode or CryptoQuant API. The `bot_loop_start()` REST pattern (from axes 11, 12, 13, 16) is the template, but Glassnode API authentication (API key in headers) differs from the Binance/Deribit unauthenticated endpoints used by prior axes. Implementation gap: API key management in Docker environment.

6. **Redundancy risk with existing axes:** In capitulation regime (MVRV < 1.0), the capitulation-exhaustion-reversal prim (axis 6) is already designed for this scenario. If MVRV < 1.0 overlaps with CER signal conditions, axis 18 amplification and CER standalone entry may double-count the same opportunity — N_eff calculation required at intermediate tier.

## Implementation

- **File:** `YujiOnChainSupplyStrategy.py` (not yet created; follows bot_loop_start() REST pattern)
- **API endpoint:** Glassnode v1: `https://api.glassnode.com/v1/metrics/market/mvrv` (requires API key header: `X-Api-Key`)
- **Exchange flows endpoint:** `https://api.glassnode.com/v1/metrics/transactions/transfers_to_exchanges_sum` + `transfers_from_exchanges_sum`
- **Cache pattern:** class-level dict `_onchain_data` (same as `_oi_data`, `_lsr_data`, `_basis_data`, `_dvol_data`)
- **Broadcast pattern:** `populate_indicators` reads `_onchain_data` into scalar column `onchain_supply_weight` (same as `macro_suppress_weight` in cross-asset-macro strategy)
- **Code skeleton:**
```python
def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
    import requests
    headers = {"X-Api-Key": self.glassnode_api_key}
    params = {"a": "BTC", "i": "24h", "f": "JSON"}
    # MVRV
    r = requests.get(
        "https://api.glassnode.com/v1/metrics/market/mvrv",
        headers=headers, params=params, timeout=10
    )
    data = r.json()
    if data:
        latest = data[-1]
        self._onchain_data["mvrv"] = latest.get("v", None)
    # Exchange net flow
    inflow = requests.get(
        "https://api.glassnode.com/v1/metrics/transactions/transfers_to_exchanges_sum",
        headers=headers, params=params, timeout=10
    ).json()
    outflow = requests.get(
        "https://api.glassnode.com/v1/metrics/transactions/transfers_from_exchanges_sum",
        headers=headers, params=params, timeout=10
    ).json()
    # ... compute 7-day net and 30-day SMA in class-level rolling buffer
```
- **Reaction detection:** No standalone entries; `onchain_supply_weight` multiplied into `entry_signal` score before thresholding in `populate_entry_trend`

## Situation Log

| Date | Pair | TF | Setup | Trigger | Reaction | Outcome | Notes |
|------|------|----|-------|---------|----------|---------|-------|
| 2021-11 | BTC | Daily | MVRV 3.1 (ATH zone) | Price peaks, LTH distribution | n/a (RESEARCH only) | Price -70% over 12 months | MVRV > 3.0 at peak — consistent with distribution regime hypothesis |
| 2022-11 | BTC | Daily | MVRV 0.88 (below realized cap) | FTX collapse, forced liquidation | n/a (RESEARCH only) | Price +200% over 12 months from trough | MVRV < 1.0 at capitulation — consistent with accumulation hypothesis |
| 2020-03 | BTC | Daily | MVRV 0.94 (COVID crash) | Exchange inflow shock | n/a (RESEARCH only) | Price +1200% over 18 months | MVRV < 1.0 + exchange inflow spike → both signals simultaneously |

## Refinement History
- 2026-04-13: Created as naive prim — cycle 122. 18th freqtrade regime axis. First on-chain (blockchain-native) regime classifier. Data blocker (Glassnode API auth + entity-adjusted flows) is primary intermediate gate. 6 academic anchors established. Frequency concern: MVRV extreme episodes ~5 in 9 years — intermediate must use MVRV Z-score or lower threshold for acceptable frequency.
- 2026-04-13: **SUPERSEDED by intermediate — cycle 123.** Four structural upgrades: (1) five-zone gradient (binary 2.5/1.0 → Zone 1–5 with MVRV 2.0/2.5/1.1/1.0 thresholds + Z-score secondary + SOPR dual-confirmation for Zone 3/5 full weight); (2) duration gate state machine (90d suppress / 30d amplify; INACTIVE/PHASE_1/PHASE_2; 5-day neutral reset); (3) N_eff redundancy protocol (4 co-occurrence rules for axis 6 CER and axis 7 funding with multiplicative compounding floor 0.72×); (4) SOPR API integration + entity-adjusted flow endpoints + complete bot_loop_start() implementation pattern. 8 sources (6 carried + Shirakashi 2019 Glassnode SOPR + Carter & Le Calvez 2018 realized cap). See: freqtrade/prims/intermediate/on-chain-supply-dynamics-regime.md

## Anti-Prim Gates (Naive)

**A. Frequency collapse:** G1 scan (Glassnode historical 2017–2026) shows MVRV > 2.5 occurs in < 3 distinct episodes over 9 years → n=3 provides no statistical power → lower threshold to MVRV > 2.0 and rescan; if still < 5 episodes → anti-prim class A (frequency-insufficient)

**B. Redundancy with existing axis:** G2 shows ρ(MVRV distribution signal, funding-rate-crowding-reversal signal) > 0.70 over 2022–2026 → axis 18 is derivative of axis 7 information → merge into axis 7 extension rather than new axis; if also ρ(MVRV, CER) > 0.70 → anti-prim (redundant with existing architecture)

**C. WR delta null:** G3 conditional WR scan across sister prims shows WR delta in MVRV distribution regime vs neutral < 2pp across all sister prims → mechanism not detectable in 4h entry data → anti-prim A

**Blocking for intermediate elevation:**
1. **Data gate:** Glassnode API access confirmed (API key obtained; Docker env integration verified); entity-adjusted exchange flows available (not raw transfers)
2. **G1 frequency scan:** MVRV threshold calibrated to produce ≥ 10 distinct episodes/year using MVRV Z-score variant or threshold lowered to 1.8/1.3
3. **Duration gate:** Maximum suppress duration capped (e.g., 90-day rolling window resets; avoid 9-month blanket suppression)
4. **Redundancy check:** ρ(axis 18, axis 7) computed — if < 0.50, axes are independent → proceed to intermediate
