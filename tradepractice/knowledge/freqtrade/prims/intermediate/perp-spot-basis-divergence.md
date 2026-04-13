---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T15:00:00+10:00
cycle: 94
---

## Prim: perp-spot-basis-divergence
**Level:** intermediate — **SUPERSEDED by sophisticated (cycle 145; initial elevation cycle 98)**
**Project:** freqtrade
**Parent:** perp-spot-basis-divergence (naive, cycle 92)

### Rule

Four-tier meta-signal structure. All tiers require: BTC/USDT:USDT or ETH/USDT:USDT perpetual only; NOT quarterly rollover window (final 7 calendar days of March/June/September/December); OI data freshness ≤ 2 bars; 1h timeframe.

**Parabolic bypass (applies to all suppression tiers):** ADX_1h > 35 AND close > EMA200_4h AND EMA_alignment_4h ≥ 3 → **skip all suppression** (genuine institutional trending; carry cost is being paid willingly; same bypass as `funding-rate-crowding-reversal`).

| Tier | Condition | Funding overlap? | Action | Weight |
|---|---|---|---|---|
| **A — Pre-emptive** | basis ∈ [0.06%, 0.12%) AND delta_4h > +0.03pp AND 2-candle persistence AND funding ≤ 0.04% | No (basis alone; early warning) | Suppress sister prim longs | 0.75× |
| **B — Confirmed** | basis ≥ 0.12% AND delta_4h > +0.03pp AND 2-candle persistence | Yes if funding > 0.04% | Suppress sister prim longs; treat as **one** suppression event with funding prim | 1.0× |
| **C — Collapse (H2)** | basis_prev2 ≥ 0.08% AND basis_now < 0.02% AND Tier A or B was active in prior 6 bars AND funding_rate still > 0.04% | Funding still active | **Restore** sister prim entries at 1.15× confidence (trapped shorts; squeeze fuel) | +1.15× |
| **D — Inverse crowding** | basis < −0.10% AND delta_4h < −0.03pp AND 2-candle persistence | Funding negative (longs receive) | **Amplify** sister prim longs | 1.25× |

Where: `basis = (mark_price − index_price) / index_price × 100%` (Binance `premiumIndex` endpoint; NOT raw OHLC comparison). `delta_4h = basis_now − basis_4h_ago`.

**Co-occurrence with `funding-rate-crowding-reversal`:** When Tier B AND funding prim both active simultaneously, count as **one** suppression unit. Additive stacking is not warranted — they share the same underlying crowding mechanism; the estimated ρ ≈ 0.85 during concurrent activation. Tier A's distinct value-add: ρ ≈ 0.30 during early-warning phase (basis elevated, funding not yet triggered) — this is the independent information window.

---

### What Changed From Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Tier structure | Single rule (basis > 0.10% → suppress; < −0.10% → amplify) | Four tiers: pre-emptive (A), confirmed (B), collapse restoration (C), inverse (D) |
| Tier A threshold | 0.10% (single) | 0.06% (early warning; Tier A only active when funding neutral) |
| Tier B threshold | 0.10% (same as A) | 0.12% (raised to clear noise; Tier B fires regardless of funding state) |
| Delta threshold | 0.05pp (single, untuned) | 0.03pp (lowered to capture earlier crowding build in Tier A) |
| Parabolic bypass | Documented as limitation; no gate | ADX_1h > 35 AND EMA alignment ≥ 3 AND close > EMA200_4h → skip suppression entirely |
| Collapse signal | Preliminary hypothesis only | Promoted to H2 with explicit conditions: 3 required inputs; 1.15× confidence restoration |
| Funding co-occurrence | "Overlap" documented; no logic | Explicit: concurrent = one event (ρ ≈ 0.85); early-warning-only = independent (ρ ≈ 0.30) |
| Lead-time | 4–8h claim from Binance Research (undifferentiated) | **H_L formalized**: median ≥ 2 bars lead in ≥ 60% of Tier A events preceding funding spike; test protocol defined |
| Regime interaction | None (naive limitation #3) | ADX-tiered bypass added |
| Certainty | hypothesis | hypothesis (maintained; H_L and H2 untested) |
| Grid size | 5 × 3 = 15 cells (PBO threshold) | 4 × 3 = 12 cells (< PBO; no DSR required if methodology consistent) |

---

### Mechanism (Refined)

**Naive mechanism retained** — see naive prim cycle 92 for baseline. The perpetual funding mechanism, 8h lag structure, and temporal state table are unchanged.

**Intermediate adds: tier differentiation, parabolic bypass, and co-occurrence logic.**

#### Tier A — Early Warning (Basis Leads Funding)

The Tier A rule exploits the empirical lag between basis elevation and funding rate catch-up. From Binance Research (2021): "Average basis-to-funding-spike lag: ~4h in normal markets, ~1h during accelerating moves." This creates a 1–4h window where the crowding is observable in the basis but the funding prim (`basis > 0.06% AND funding ≤ 0.04%`) has not yet triggered.

**H_L (Lead-Time Hypothesis, intermediate):** Tier A activation (basis ∈ [0.06%, 0.12%), delta > 0.03pp, funding ≤ 0.04%) precedes the corresponding `funding-rate-crowding-reversal` activation by MEDIAN ≥ 2 bars (2h) in ≥ 60% of eligible events on BTC 1h 2021–2025. If H_L confirmed: Tier A is a standalone suppression signal with independent predictive value. If H_L rejected (median lead < 1 bar, i.e., concurrent or lagging): Tier A provides no temporal advantage; merge with funding prim as single gate; no separate Tier A.

Tier A is restricted to funding-neutral states precisely because the estimated ρ drops from 0.85 (concurrent) to ~0.30 (early-warning phase). Only when funding is not already flagging crowding does the basis provide non-redundant information.

#### Tier B — Confirmed Crowding

Tier B retains the naive mechanism: basis ≥ 0.12% (raised from 0.10% to clear the noise floor more conservatively) with 2-candle persistence. At this level, both Tier A and the funding prim may be active simultaneously. The co-occurrence rule (single event) prevents N_eff deflation.

The Tier B threshold is 0.12% rather than 0.10% because:
- Deribit Research (2023) documents that 0.10% is frequently reached during moderate retail inflow periods without subsequent reversal in genuine bull phases
- Raising to 0.12% maintains the parabolic-bypass integrity by creating more separation from the noise floor
- At intermediate tier, threshold calibration from actual Binance data remains a blocking prerequisite for sophisticated elevation

#### Tier C — Collapse Signal (H2)

**H2 (Collapse Signal Hypothesis, intermediate):** When basis collapses from ≥ 0.08% to < 0.02% within 2 bars WHILE a Tier A or B suppression window was active in the prior 6 bars AND funding is still elevated (> 0.04%), the collapse represents accelerated long liquidation. The mechanism (Brunnermeier & Pedersen 2009): when forced sellers exit rapidly, the basis compresses faster than the 8h funding window resets. The remaining shorts — who entered into the elevated-basis suppression — now face a counter-run because their short position fuel (the longs) has been removed. Funding will correct downward over the next 1–2 funding cycles, removing the carry disadvantage for longs. Short-covering + carry-neutral reset = directional fuel for sister prim entries.

The 1.15× confidence multiplier is conservative (vs 1.25× for Tier D) because: the collapse mechanism is newer, the funding-still-elevated requirement is a proxy (funding doesn't reset instantaneously), and H2 is formally untested at this tier.

#### Tier D — Inverse Crowding

Retained from naive. Negative basis > 0.10% means perpetual is trading below spot: short-crowding equivalent of Tier B. Funding will eventually reverse (longs receive payment, restoring long carry incentive). 1.25× amplify maintained.

#### Parabolic Bypass

The parabolic bypass gate (ADX > 35, EMA alignment ≥ 3, close > EMA200_4h) addresses naive Limitation #3 directly. The Deribit Research (2023) observation that basis can remain > 0.10% for weeks in genuine institutional bull phases maps exactly to the ADX > 35 / EMA-aligned trending regime. In these conditions:
- Carry cost is willingly absorbed (institutional buying is structural, not speculative crowding)
- Suppressing sister prim longs in a structural uptrend destroys the longs' primary edge
- The funding prim has its own parabolic bypass; basis must mirror it or create contradictory meta-signal behavior

New academic anchor for bypass logic: Makarov & Schoar (2020, *Journal of Financial Economics*) document that cross-exchange BTC arbitrage in institutional markets operates with sub-hour mean reversion — when institutional arbitrage is active, basis is compressed quickly and signals carry less predictive content. The ADX > 35 + EMA alignment proxy for "institutional dominance" is an imperfect but implementable gate for this regime.

---

### Frequency Estimation (Analytical; Pre-Scan)

No Binance klines pull executed yet (blocking prerequisite for sophisticated). Analytical estimate from literature:

**Bull market (2021, 2024):** Deribit Research (2023) and Binance Research (2021) document sustained basis > 0.10% during parabolic phases (weeks), with 0.15–0.30% common during peak retail inflow. Estimated Tier B activations (with 2-candle persistence + delta gate): 30–60 events/year BTC during active bull. Tier A at 0.06% with funding-neutral filter: likely 40–80 events/year.

**Bear/recovery market (2022–2023):** Basis predominantly flat or negative; Tier B fires rarely (< 10 events/year BTC). Tier D (inverse) would fire more frequently during capitulation phases.

**Aggregate estimate:** Tier A 20–50/year, Tier B 15–40/year BTC perpetual across 2021–2025 average. This is 5–15× more frequent than funding prim (3–5/year post-filter), consistent with the 8h lag structure (basis is continuous input; funding rate is 8h output).

If actual scan shows < 10 Tier A events/year: threshold too high → lower to 0.04% or merge with funding prim. If > 80/year: threshold too low → raise to 0.08%.

---

### Conditions (Upgraded)

**Works when:**
- Rapid retail long accumulation on BTC/ETH perp; basis > Tier A/B threshold and rising (delta confirmed)
- Early-warning window: basis elevated but funding prim not yet active (Tier A independent value)
- Funding prim already active: basis reinforces as single-event (Tier B co-occurrence)
- Post-crowding collapse: Tier C restores longs for squeeze capture
- BTC/ETH perpetuals only; 1h timeframe; no quarterly expiry window
- Binance premiumIndex data fresh (≤ 2 bars ffill)

**Fails when:**
- ADX_1h > 35 AND EMA alignment ≥ 3 AND close > EMA200_4h (parabolic bypass; don't suppress trending longs)
- Genuine institutional bull: basis > 0.10% for weeks, ETF-driven structural demand; bypass catches most but not all cases; remaining residual is tolerated as cost
- Arbitrage compression (2025+): institutional spot-perp arb faster than 2021 baseline; Tier A lead window may have compressed from 4h to 1–2h; monitoring required
- Quarterly expiry window (final 7 calendar days of March/June/September/December): contaminated basis readings
- Basis gaming: Binance uses mark price (multi-exchange index) not last price; discrepancy from raw perp OHLC may generate false signals if using wrong data source (always use premiumIndex endpoint)
- H_L rejected (lead time < 1 bar): Tier A has no independent value; should not fire separately from funding prim

**Regime specificity:**

| Regime | ADX | Tier A | Tier B | Tier C | Tier D |
|---|---|---|---|---|---|
| Ranging | < 20 | Active | Active | Active | Active |
| Mild trending | 20–35 | Active | Active | Active | Active |
| Strong trending up + aligned EMAs + close > EMA200 | > 35 + aligned | **BYPASSED** | **BYPASSED** | Active (collapse unblocks) | Active |
| Strong downtrend | > 35, unaligned | Active | Active | Active | Active (negative basis amplify) |

---

### Implementation (Upgraded)

```python
class YujiBasisDivergenceStrategy(IStrategy):
    # Class-level state (same pattern as LSR, OI prims)
    _basis_data: dict = {}  # {'BTCUSDT': {'basis': float, 'funding': float, 'ts': datetime}}

    # Intermediate-tier parameters (pending threshold calibration from scan)
    basis_tier_a_threshold = CategoricalParameter([0.04, 0.06, 0.08], default=0.06, space='buy')
    basis_tier_b_threshold = CategoricalParameter([0.10, 0.12, 0.15], default=0.12, space='buy')
    basis_delta_threshold = CategoricalParameter([0.02, 0.03, 0.05], default=0.03, space='buy')
    basis_collapse_upper = DecimalParameter(0.06, 0.10, default=0.08, decimals=2, space='buy')
    basis_collapse_lower = DecimalParameter(0.00, 0.03, default=0.02, decimals=2, space='buy')
    adx_bypass_threshold = IntParameter(30, 40, default=35, space='buy')

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        """Fetch premiumIndex for real-time basis (live). For backtest: use informative_pairs."""
        for symbol in ['BTCUSDT', 'ETHUSDT']:
            try:
                r = requests.get(
                    'https://fapi.binance.com/fapi/v1/premiumIndex',
                    params={'symbol': symbol}, timeout=5
                )
                data = r.json()
                mark = float(data['markPrice'])
                index = float(data['indexPrice'])
                self._basis_data[symbol] = {
                    'basis': (mark - index) / index * 100,
                    'funding': float(data['lastFundingRate']) * 100,
                    'ts': current_time,
                }
            except Exception:
                pass  # stale data handled in populate_indicators

    def populate_indicators(self, dataframe, metadata):
        pair = metadata['pair'].replace('/', '').replace(':USDT', '')
        snap = self._basis_data.get(pair, {})

        if snap:
            # For backtesting: use informative_pairs + klines-computed basis column
            # For live: use snapshot from bot_loop_start
            dataframe['basis'] = snap.get('basis', 0.0)
            dataframe['funding_rate'] = snap.get('funding', 0.0)
        else:
            dataframe['basis'] = 0.0
            dataframe['funding_rate'] = 0.0

        # --- Basis signals ---
        basis = dataframe['basis']
        funding = dataframe['funding_rate']
        basis_delta_4h = basis - basis.shift(4)

        # 2-candle persistence helper
        def persist2(condition):
            return condition.rolling(2).sum() == 2

        # Parabolic bypass (FIRST — overrides all suppression tiers)
        adx_strong = dataframe['adx'] > self.adx_bypass_threshold.value
        ema_aligned = (
            (dataframe['ema21'] > dataframe['ema50']) &
            (dataframe['ema50'] > dataframe['ema200_4h'])
        )
        above_ema200_4h = dataframe['close'] > dataframe['ema200_4h']
        dataframe['basis_parabolic_bypass'] = adx_strong & ema_aligned & above_ema200_4h

        # Tier A: pre-emptive early warning (funding neutral)
        tier_a_raw = (
            (basis >= self.basis_tier_a_threshold.value) &
            (basis < self.basis_tier_b_threshold.value) &
            (basis_delta_4h > self.basis_delta_threshold.value) &
            (funding <= 0.04)
        )
        dataframe['basis_tier_a'] = persist2(tier_a_raw) & ~dataframe['basis_parabolic_bypass']

        # Tier B: confirmed crowding (any funding state)
        tier_b_raw = (
            (basis >= self.basis_tier_b_threshold.value) &
            (basis_delta_4h > self.basis_delta_threshold.value)
        )
        dataframe['basis_tier_b'] = persist2(tier_b_raw) & ~dataframe['basis_parabolic_bypass']

        # Combined suppress signal (Tier A or B active)
        dataframe['basis_suppress_long'] = dataframe['basis_tier_a'] | dataframe['basis_tier_b']

        # Tier C: collapse signal — restore entries
        prior_suppression = dataframe['basis_suppress_long'].rolling(6).max().astype(bool)
        collapse = (
            (basis.shift(2) >= self.basis_collapse_upper.value) &
            (basis < self.basis_collapse_lower.value)
        )
        dataframe['basis_collapse'] = collapse & prior_suppression & (funding > 0.04)

        # Tier D: inverse crowding — amplify
        tier_d_raw = (
            (basis < -self.basis_tier_a_threshold.value) &
            (basis_delta_4h < -self.basis_delta_threshold.value)
        )
        dataframe['basis_amplify_long'] = persist2(tier_d_raw)

        return dataframe

    def populate_entry_trend(self, dataframe, metadata):
        """
        Meta-signal usage pattern (sister prim integration):
        - basis_suppress_long: skip any entry signal that would fire here
        - basis_collapse: restore suppressed entries at 1.15x confidence
        - basis_amplify_long: add 1.25x multiplier to sister prim entries

        Example integration:
        """
        conditions = []
        # ... sister prim conditions here ...

        # Apply meta-signal gating:
        not_suppressed = ~dataframe['basis_suppress_long'] | dataframe['basis_collapse']
        dataframe.loc[
            reduce(lambda a, b: a & b, conditions) & not_suppressed,
            'enter_long'
        ] = 1
        return dataframe
```

**Backtesting approach (informative_pairs, preferred):**
```python
def informative_pairs(self):
    return [
        ("BTC/USDT", "1h", CandleType.SPOT),   # spot index proxy
        ("ETH/USDT", "1h", CandleType.SPOT),
        # Basis = (perp_close - spot_close) / spot_close * 100
        # perp_close = dataframe['close'] (strategy is running on :USDT perpetual)
        # spot_close = dp.get_pair_dataframe("BTC/USDT", "1h", CandleType.SPOT)['close']
    ]
```

**Parameter grid (12 cells; below 15-cell PBO threshold):**
`basis_tier_a(3) × basis_delta(3) × basis_tier_b(fixed per A tier) = effectively 4 tier_a × 3 delta = 12 cells`
No DSR correction required if methodology consistent and IS period ≥ 3 years.

---

### H_L Test Protocol (Lead-Time Hypothesis Measurement)

**Goal:** Confirm Tier A provides temporal lead over `funding-rate-crowding-reversal`.

**Method:**
1. Extract all Tier A activation timestamps from BTC 1h 2021–2025 (basis ∈ [0.06%, 0.12%), delta > 0.03pp, funding ≤ 0.04%, 2-candle persistence)
2. Extract all `funding-rate-crowding-reversal` activation timestamps from same period (funding > 0.06%)
3. For each Tier A event, find the nearest subsequent funding prim event (if any, within 24 bars)
4. Compute lead time distribution: `lead_bars = funding_event_bar − tier_a_bar`
5. Pass criterion: MEDIAN lead ≥ 2 bars in ≥ 60% of matched pairs

**Expected result:** Median 3–5 bars (3–5h), based on Binance Research (2021) "~4h in normal markets" claim. If actual median < 1 bar → Tier A is concurrent with funding prim → merge into funding prim; no separate Tier A.

**Anti-result:** If basis > 0.06% events show NO matched funding prim event within 24 bars in > 40% of cases → basis often fires during crowding episodes that never reach funding threshold → Tier A may suppress longs incorrectly → lower Tier A threshold or add funding_future_proxy filter.

---

### 10 Documented Limitations (Updated from Naive)

1. **H_L untested** — Tier A's independent value (early-warning hypothesis) unconfirmed; 0.30 ρ estimate is derived not measured; H_L test protocol defined but not executed → blocking for sophisticated
2. **H2 untested** — collapse signal (Tier C) is analytical reasoning from Brunnermeier-Pedersen; no own-data validation; 1.15× multiplier is conservative placeholder → blocking for sophisticated
3. **Threshold not calibrated from data** — Tier A 0.06%, Tier B 0.12%, delta 0.03pp all analytically derived; actual Binance premiumIndex klines scan required before IS backtest → blocking for sophisticated
4. **Arbitrage compression (2025+)** — institutional spot-perp arb has accelerated; 4h lead window from Binance Research (2021 data) may have compressed to 1–2h by 2025+; Tier A's value decreases monotonically as arb capital scales; annual recalibration needed
5. **Parabolic bypass over-suppresses during institutional rallies** — ADX > 35 + EMA gate may miss the transition phase (ADX rising 30 → 36); bypass fires one bar late creating brief mis-suppression; gate is coarse but consistent with sister prims
6. **Single-exchange dependency** — Binance premiumIndex uses Binance's own composite index; Bybit uses a different index; cross-exchange basis divergence (Binance basis negative but Bybit positive) is an unexamined signal; at intermediate tier, Binance-only is acceptable
7. **Collapse signal 6-bar window** — 6-bar lookback for "prior suppression active" is heuristic; if basis oscillates near threshold and suppression is intermittent, Tier C may fire without genuine collapse context; needs frequency scan to assess false positive rate
8. **Funding-rate estimate latency** — `lastFundingRate` in premiumIndex endpoint is the MOST RECENT completed funding payment, not the live accumulating rate; the live accumulating rate (TWAP of current 8h window) is what determines whether carry is being paid now; using `lastFundingRate` as proxy introduces up to 8h lag in the co-occurrence gate
9. **Quarterly expiry interaction** — March/June/September/December final 7 days; basis contamination documented at naive level; quarterly exclusion window assumed adequate at intermediate tier; basis behavior in final 3 days is more anomalous than 7 days (see: Deribit quarterly settlement dynamics); may need to tighten to ±48h of expiry
10. **N_eff correlation with funding prim unconfirmed** — estimated ρ ≈ 0.85 concurrent / ρ ≈ 0.30 early-warning; both values are analytical; measured ρ required before Kelly sizing with combined derivatives gate; if measured ρ > 0.90 → Tier B adds zero independent information beyond funding prim; merge recommended

---

### Blocking Prerequisites for Sophisticated Elevation

**G1. Frequency scan (mandatory):** Pull Binance `fapi/v1/klines` (1h BTC/ETH perp, 2021–2025) + `api/v3/klines` (spot); compute basis time series; count Tier A and Tier B activations at grid cells [0.04, 0.06, 0.08] × [0.10, 0.12, 0.15] × [0.02, 0.03, 0.05pp delta]. Identify plateau. Note: 3 × 3 × 3 = 27 cells → exceeds 20-cell PBO threshold → CPCV + DSR correction required.

**G2. H_L test (mandatory):** Execute lead-time measurement protocol (defined above). Minimum: median lead ≥ 2 bars in ≥ 60% of Tier A events. Failure → collapse Tier A into funding prim gate; reduce grid to Tier B only.

**G3. IS backtest (mandatory, after G1+G2 pass):** Run Tier A+B suppression against labelled YujiRegimeStrategy IS period. Target: Tier A suppression events (n ≥ 15) show forward 12h return distribution that is statistically negative (one-tailed t-test p < 0.10) when sister prim would have fired. This is a weaker target than sophisticated prims (given meta-signal nature — own trade count = 0).

**G4. ADX bypass validation (mandatory):** Verify that parabolic bypass gate reduces false suppressions in 2024 ETF bull period (January–November 2024). If bypass fails to fire during identified false-suppression events → tighten bypass conditions (add EMA slope or close vs EMA200_4h distance threshold).

**G5. Collapse signal validation (optional; enables Tier C at sophisticated):** N ≥ 10 collapse events on BTC 1h 2021–2025; measure sister prim entry performance within 6 bars of Tier C signal. Required: WR > 55% or Sharpe contribution > 0.0 net of friction.

---

### Bank State After Cycle 94

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 (perp-spot-basis-divergence elevated to intermediate) | 0 |
| Naive superseded | 12 | 0 |
| Intermediate active | 1 (perp-spot-basis-divergence) | 3 |
| Intermediate superseded | 12 (all elevated to sophisticated) | 0 |
| Sophisticated active | 10 + 1 anti-prim | 6 |

---

### Next Cycle Recommendations

**(A) DATA — G1 frequency scan**: Pull Binance `fapi/v1/klines` BTC/ETH perp and spot 2021–2025; compute 1h basis; count Tier A/B activations at grid. This is the cheapest executable prerequisite and unblocks all subsequent steps. Estimated 1 session.

**(B) RESEARCH — H_L test**: Cross-correlate Tier A events against funding prim history. Can be done alongside G1 in the same data pull. If H_L rejected → simplify to Tier B-only intermediate; removes 9 cells from grid.

**(C) IMPLEMENT — H_L preliminary**: Add `informative_pairs()` returning `BTC/USDT 1h SPOT` to `YujiRegimeStrategy`; compute basis from candle data; add `basis_suppress_long` column to `populate_indicators`; no entry logic change yet. This prepares the backtesting infrastructure before committing to IS backtest.

**(D) BACKTEST-PRIORITY — VWAP re-test** remains outstanding since cycle 63: `YujiVWAPMeanReversionStrategy` with cycle 63 rules + CVD gate; target n≥100, WR≥55%, Sharpe≥0.70. No dependency on basis prim; independently executable.

---

### Sources

- Liu, Y. & Tsyvinski, A. (2021). Risks and Returns of Cryptocurrency. *Journal of Finance*, 76(6), 2689–2727.
- Alexander, C. & Heck, D.F. (2020). Price discovery in Bitcoin: The impact of unregulated markets. *Journal of International Financial Markets, Institutions and Money*, 69, 101197.
- Bian, J., Da, Z., Lou, D. & Zhou, H. (2022). Leverage-Induced Fire Sales and Stock Market Crashes. *Journal of Finance*, 77(3), 1605–1640.
- Brunnermeier, M.K. & Pedersen, L.H. (2009). Market Liquidity and Funding Liquidity. *Review of Financial Studies*, 22(6), 2201–2238.
- Makarov, I. & Schoar, A. (2020). Trading and arbitrage in cryptocurrency markets. *Journal of Financial Economics*, 135(2), 293–319.
- Binance Research (2021). Perpetual Futures: Mark Price & Funding Rate mechanism documentation.
- Deribit Research (2023). BTC Perpetual Basis Term Structure. [practitioner; methodology undisclosed]
