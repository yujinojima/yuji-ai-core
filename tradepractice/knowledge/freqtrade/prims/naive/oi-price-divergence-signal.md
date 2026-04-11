---
name: oi-price-divergence-signal
level: naive
project: freqtrade
parent_prim: none
created: 2026-04-12
last_validated: never
reaction_validated: assumed
---

## Situation

### Setup
Futures market at a 20-bar price low (or high). Open interest has declined ≥ 5% over the same 20-bar window. Price and OI are diverging: price is at a new extreme but the futures book is shrinking, not growing.

### Trigger
Simultaneous conditions: `close < close.rolling(20).min().shift(1)` (price at new 20-bar low) AND `oi_change_20bar < -0.05` (OI down ≥ 5% over 20 bars) AND `RSI(14) < 40`.

### Reaction
- **Accepted:** Price reverses after the signal bar. Next 1–3 candles close above the signal bar's low. Volume rises on the reversal candle. OI stabilises or starts rising (new longs entering).
- **Rejected:** Price continues lower. OI continues declining (capitulation not complete). Signal bar is followed by another red candle below its low.
- **Unclear:** Flat price action for 3–5 bars after signal. OI neither recovers nor collapses further. Waiting for direction.

### Agent Behaviour
- **Who is acting:** Forced liquidations — leveraged longs closing involuntarily as price breaks below stop clusters. Each liquidation reduces OI.
- **Who is trapped:** Remaining longs who entered earlier in the move; late shorts who entered near the current low expecting continuation.
- **Who is wrong:** Shorts entering at the low when the liquidation wave is near exhaustion. When forced-selling dries up, no sustained supply exists to push price lower. Late shorts provide the fuel for the reversal (short-covering rally).

### Outcome
- **If accepted:** Long entry; target prior swing high or 20-bar high. Mechanism: OI declining at lows = supply exhaustion, not genuine new short interest. Reversal driven by short-covering + fresh longs.
- **If rejected:** No action. Declining OI at new lows with continuation = structural unwinding (position deleveraging or loss of interest), not exhaustion. This is the primary failure mode.
- **If unclear:** Wait. Do not enter on ambiguous OI data (flat or erratic series).

## Rule
Price makes a 20-bar new low AND OI declines ≥ 5% over the same 20-bar window AND RSI(14) < 40 → long bias (washout complete, forced-liquidation wave exhausting). Entry on next-candle open only. Hard stop: below signal-bar low. Secondary meta-signal: price makes 20-bar new HIGH with OI declining ≥ 5% → suppress other long entries (short-covering rally, not genuine directional expansion; suppress longs in sister prims for 72h).

## Mechanism
In futures markets, OI represents aggregate outstanding contracts. When price declines AND OI declines simultaneously, the price move is driven by existing longs closing (liquidation) — not by new shorts opening. When that liquidation wave is nearly exhausted (OI has declined materially), the remaining supply pressure dissipates. A price reversal becomes likely because: (1) the forced-sellers are nearly gone; (2) late short-sellers entering at the lows have no continuation supply to support them; (3) short-covering by those same late shorts provides upward pressure. This is mechanistically distinct from funding-rate-crowding-reversal (which uses carry cost as signal) and capitulation-exhaustion-reversal (which requires RSI<20 + N≥5 reds + volume spike — extreme distress). This prim operates at moderate distress (RSI 30–45) in the post-peak-liquidation zone.

Academic anchor: Bessembinder & Seguin (1993, Journal of Finance) — OI reflects speculative depth; price-OI divergence signals positioning exhaustion, not directional conviction. Hong & Yogo (2012, JFE) — OI changes predict futures returns; declining OI at price extremes has negative autocorrelation. Chatrath, Ramchander & Song (1996, Journal of Futures Markets) — OI changes lead price reversals in commodity futures.

## Conditions
- **Works when:** Price at 20-bar low + OI declining (forced-liquidation thesis) + RSI 30–45 (moderate distress, not capitulation extremes) + trending or mildly trending regime (ADX 20–40) + genuine open interest data available (futures market, not spot)
- **Fails when:** OI declining due to structural deleveraging unrelated to the price move (ETF creation/redemption, quarterly futures rollover, exchange-wide deleveraging cycle) | thin market with erratic OI spikes | news-driven price move (fundamental repricing, not positioning exhaustion) | deep trending bear market (OI declines can persist for months) | RSI < 25 (territory of capitulation-exhaustion-reversal; prim overlap)
- **Best pairs:** BTC/USDT:USDT, ETH/USDT:USDT (liquid perpetual futures with reliable OI data)
- **Best timeframe:** 1h (data resolution; sub-1h OI data unreliable on most exchanges; 4h reduces signal frequency below useful threshold)
- **Best regime:** Post-trend correction (ADX 20–35, declining); NOT deep-bear persistent downtrend (ADX > 40 with consistent OI decline over weeks)

## Evidence

### Source Quality
- **Source:** paper (traditional futures) + anecdote (crypto practitioner reports)
- **Certainty:** guess (mechanism documented in traditional futures literature; crypto-specific win rate unknown; no own-data backtest)
- **Scope:** traditional futures (Bessembinder & Seguin, Chatrath et al.) — crypto applicability assumed but untested
- **Falsifiable:** untested (no backtest run; data download required)
- **Reaction observed:** no (zero own trades; assumed from traditional futures analogue)

### Data
- Period: N/A — no backtest
- Trades: 0
- Win rate: unknown (traditional futures analogue: not directly measured for this rule specification)
- Profit: unknown
- Max drawdown: unknown
- Sharpe: unknown
- Acceptance rate: unknown
- Rejection rate: unknown
- Unclear rate: unknown
- Parameter grid (untuned): `oi_change_threshold` ∈ [0.03, 0.05, 0.08, 0.10] × `lookback` ∈ [10, 15, 20, 30] × `rsi_max` ∈ [35, 40, 45] = 48-cell plateau; CPCV + DSR mandatory if plateau > 20 cells (this exceeds threshold)

## Limitations
1. **Crypto OI measurement heterogeneity.** Exchange-reported OI differs between perpetual and dated futures; Binance perpetual OI ≠ CME OI. Cross-exchange OI aggregation would improve signal but is not implemented.
2. **Binance variable OI update interval (GitHub #12583).** Binance OI candles have variable refresh intervals; the freqtrade `open_interest` candle type may have gaps or irregular spacing on some pairs. Must verify data completeness before backtest.
3. **Quarterly futures rollover contamination.** Every quarter, dated futures expiry creates artificial OI decline as contracts roll. This is not positioning exhaustion — it is mechanical. Rollover windows (last week of March, June, September, December) must be excluded or the signal will fire spuriously.
4. **ETF creation/redemption interference.** BTC/ETH spot ETF AP arbitrage creates OI changes on the futures leg that are unrelated to directional positioning. Post-ETF approval (2024+), this is an increasing source of false signals; magnitude unknown.
5. **Overlap with capitulation-exhaustion-reversal.** When RSI < 25, both prims fire. Mutual exclusivity logic required: if capitulation-exhaustion-reversal conditions are met (RSI<20 + N≥5 reds + volume>3×SMA), defer to that prim; suppress oi-price-divergence-signal. Stacking produces correlated N_eff ≈ 1.0 (not 2.0).
6. **No regime exclusion.** Deep bear markets (EMA200 slope strongly negative, ADX > 40) can have persistently declining OI for weeks. The 20-bar lookback will fire repeatedly with no reversal. A regime gate (e.g., 4h EMA200 slope gate) is absent from the naive rule and is a critical intermediate upgrade.
7. **Untuned threshold (oi_change_threshold = 0.05).** The 5% OI decline threshold is a heuristic with no empirical basis in crypto. Traditional futures literature uses rate-of-change in different units. Plateau test across [0.03, 0.05, 0.08, 0.10] is mandatory before any forward deployment.
8. **No volume confirmation gate.** The naive rule uses RSI as the only secondary filter. A volume spike or CVD divergence gate (buying pressure despite price new low) would increase precision. Absence of this is a known intermediate upgrade path.
9. **McLean-Pontiff OOS degradation.** If this mechanism shows edge in IS backtest, expect 25–50% Sharpe degradation OOS (McLean-Pontiff 2016, JF). The 48-cell plateau + CPCV + DSR correction mandatory before live deployment.
10. **Traditional futures → crypto transfer uncertainty.** Bessembinder & Seguin (1993) and Chatrath et al. (1996) studied agricultural and financial futures with different microstructure (floor trading, different liquidity profiles, no 24/7 market). Crypto OI dynamics have additional noise from retail leverage, liquidation cascades, and CEX-specific liquidation engines. The mechanism plausibly transfers but WR in crypto is genuinely unknown.

## Implementation
- **File:** `YujiOIPriceDivergenceStrategy.py` (created 2026-04-12; stubs correctly, no trades fire until OI data available)
- **Data requirement:** `freqtrade download-data --trading-mode futures --pairs BTC/USDT:USDT ETH/USDT:USDT --timeframe 1h --candle-types open_interest` — **BLOCKED**: freqtrade 2026.3 does not support `open_interest` as a valid `--candle-types` argument (valid: spot, futures, mark, index, premiumIndex, funding_rate). `CandleType.OPEN_INTEREST` does not exist in the enum. Resolution: await upstream freqtrade PR or implement external OI ingestion pipeline.
- **Informative pairs:** `BTC/USDT:USDT` and `ETH/USDT:USDT` with `candle_type: CandleType.OPEN_INTEREST` — not yet wired (enum member absent in 2026.3; see above)
- **Parameter:** `oi_change_threshold=0.05`, `oi_lookback=20`, `rsi_max=40` (all untuned)
- **Code:**

```python
# In informative_pairs():
# ("BTC/USDT:USDT", "1h", CandleType.OPEN_INTEREST)

# After merge_informative_pair():
oi = dataframe['open_interest_1h']  # from informative pair
close = dataframe['close']

oi_change_20bar = (oi - oi.shift(20)) / (oi.shift(20).abs() + 1e-9)
price_new_low_20bar = close < close.rolling(20).min().shift(1)
price_new_high_20bar = close > close.rolling(20).max().shift(1)

# Entry signal: washout complete
dataframe['oi_washout_long'] = (
    price_new_low_20bar &
    (oi_change_20bar < -0.05) &
    (dataframe['rsi'] < 40)
).astype(int)

# Meta-indicator: suppress other long prims (short-covering rally)
dataframe['oi_covering_rally'] = (
    price_new_high_20bar &
    (oi_change_20bar < -0.05)
).astype(int)

# NOTE: Requires open_interest candle type availability check.
# NOTE: Exclude quarterly rollover windows (March/June/September/December final week).
# NOTE: oi_covering_rally suppresses sister prims in populate_entry_trend() for 72h.
```

- **Reaction detection:** Accepted = price closes above signal-bar high on next candle. Rejected = price closes below signal-bar low on next candle.

## Situation Log

| Date | Pair | TF | Setup | Trigger | Reaction | Outcome | Notes |
|------|------|----|-------|---------|----------|---------|-------|
| — | — | — | — | — | — | — | No observed instances. Naive prim, reaction assumed. |

## Refinement History
- 2026-04-12: Created as naive prim from traditional futures literature (Bessembinder & Seguin 1993; Hong & Yogo 2012; Chatrath et al. 1996). 11th freqtrade mechanism axis: positioning exhaustion via OI-price divergence. Mechanistically distinct from funding-rate-crowding-reversal (carry cost/flow vs positioning stock) and capitulation-exhaustion-reversal (RSI<20 extreme distress vs moderate RSI 30–45 zone). Data download + frequency scan required before intermediate elevation.
- 2026-04-12: `YujiOIPriceDivergenceStrategy.py` created (tradepractice cycle 5). Strategy validates OK (freqtrade list-strategies: OK). NEW BLOCKER discovered: `CandleType.OPEN_INTEREST` absent from freqtrade 2026.3 enum; `--candle-types open_interest` also rejected by CLI. Strategy stubs OI as NaN — no trades fire. This additional blocker must be resolved (upstream freqtrade or external OI pipeline) before any backtest is possible. Intermediate elevation now has 2 blockers: (1) OI candle support in freqtrade, (2) Binance #12583 data completeness check.
