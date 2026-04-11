---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T00:00:00+10:00
cycle: 65
---

## Prim: fair-value-gap-price-discovery
**Level:** intermediate (elevated from naive, cycle 65)
**Project:** freqtrade
**Parent:** naive/fair-value-gap-price-discovery (cycle 59)

### Rule
Three-candle bullish FVG (`high[i-2] < low[i]`, gap 0.3%–2.5% of price) + **formation volume ≥ 1.5× SMA(20)** + FVG age ≤ 15 bars + **no stacked FVG (< 2 gaps within ±2% of zone in prior 30 bars)** + price retraces into gap zone (next-candle body enters: `open[i+1] ≤ fvg_top`) + HTF 4h bullish (close > 4h EMA200) + **ADX < 40** → long to FVG midpoint / prior swing high. Stop below FVG low edge.

**5 condition upgrades from naive:**
1. Formation volume gate ≥ 1.5× SMA(20) — institutional imbalance criterion (Stoll 1978 dealer inventory)
2. Gap size upper bound 2.5% (was unlimited) — excludes exhaustion/news-driven permanent components (Hasbrouck 1991 temporary/permanent decomposition)
3. Gap size lower bound 0.3% (was 0.5%) — plateau test will determine; broadens search space
4. Next-candle body confirmation (was same-candle) — meta-analysis: −5–10pp WR cost without body confirmation (sister prims)
5. Stacked FVG exclusion (< 2 in ±2% × 30 bars) — stacking = persistent institutional flow, not temporary imbalance; fills improbable

### Mechanism
Three-candle bullish FVG represents a price range through which institutional order flow moved faster than market participants could establish equilibrium. No time-price-opportunity (TPO) was created in the gap zone. The intermediate elevation anchors this to three independent market microstructure mechanisms:

**[1] Dealer inventory rebalancing (Stoll 1978):** Market makers who absorbed the one-sided institutional flow (the candle-3 aggressive buyer) are left with short inventory. They adjust ask prices upward (price pressure) and widen spreads during the gap bar. As price moves away, they rebalance by pulling quotes back toward fair value — creating a gravitational pull toward the gap zone. Formation volume gate (≥1.5× SMA) is the quantitative proxy for sufficient institutional flow to create this imbalance.

**[2] Temporary vs permanent price impact (Hasbrouck 1991):** Trade price decomposes into a permanent component (informed flow: new information priced in permanently) and a temporary component (inventory/noise: dealer imbalance, noise trades — mean-reverts). FVGs sized 0.3%–2.5% are predominantly temporary-component events: large enough to reflect real institutional imbalance, small enough that they are not purely information-driven. Gaps >2.5% carry a higher probability of permanent component (earnings-type shock, structural news) — upper bound introduced.

**[3] Price pressure reversion (Hendershott & Menkveld 2014):** In equity markets, ~67% of intraday price pressure (defined as temporary deviation from efficient price, mechanistically identical to dealer inventory imbalance) reverts within the trading session. This is the best available quantitative fill rate anchor for the FVG mechanism. Crypto 24/7 market structure and higher volatility regime suggest a discount: realistic target 52–58% fill within 15 bars.

**Combined model:** FVG = institutional order flow imbalance event. Volume gate confirms institutional participation. Size bounds distinguish temporary (fillable) from permanent (structural) moves. Stacked FVG exclusion removes zones of persistent directional flow (not reversion candidates). Next-candle body confirmation distinguishes actual retracement from continuation pressure.

**Why the mechanism survives the crypto objection:** The practitioner community (ICT) claims the FVG mechanism is universal. The academic support (Stoll, Hasbrouck, Hendershott & Menkveld) is equity-derived. The bridge is Makarov & Schoar (2020 JFE, already established for VWAP prim): institutional arbitrage flow in crypto exhibits the same equilibrium-seeking behavior as equity microstructure. This does NOT guarantee the fill rate transfers — it establishes that the mechanism is present. The crypto-specific fill rate remains the primary outstanding falsification question.

### Evidence

| Source | Finding | Role |
|--------|---------|------|
| Stoll (1978, *Journal of Finance*) | Dealer inventory theory: market makers adjust bid-ask spreads to rebalance after one-sided flow; temporary price deviations mean-revert as inventory normalizes | **Mechanism anchor** — WHY FVGs form and fill; justifies volume gate |
| Hasbrouck (1991, *Journal of Finance*) | VAR decomposition: trade price = permanent (information) + temporary (inventory/noise); temporary component mean-reverts; magnitude of reversion inversely related to information content | **Filter anchor** — WHY gap size matters; justifies 0.3–2.5% bounds |
| Hendershott & Menkveld (2014, *Journal of Financial Economics*) | ~67% of intraday price pressure reverts within trading session; price pressure defined as temporary deviation from efficient price via market-maker inventory mechanism | **Fill rate anchor** — best quantitative estimate of reversion probability; 67% equity baseline → 52–58% crypto target after discount |
| Edwards & Magee (1948/2007, *Technical Analysis of Stock Trends*) | 70–80% of equity common gaps eventually fill; gap taxonomy distinguishes common/continuation/exhaustion | **Baseline fill probability** (equity); anchors upper bound expectation |
| Berkman, Dimitrov, Jain, Koch & Tice (2009, *Journal of Finance*) | Institutional attention-driven trading creates rapid directional price movement zones (gaps); retail participation lags institutional execution | **Mechanism support** — institutional execution creates FVG structure |
| LuxAlgo community backtests (TradingView, 2022–2025) | ~55–65% fill rate within 10 candles on 4h crypto; selection-biased; methodology undisclosed | **Crypto fill rate estimate** (unvalidated; used as order-of-magnitude reference only) |

- **Source:** paper (3 academic market microstructure anchors) + anecdote (practitioner + community)
- **Certainty:** hypothesis (mechanism academically anchored; no own-data backtest)
- **Scope:** one pair (crypto hypothesis; equity mechanism established cross-asset)
- **Falsifiability:** testable — specific conditions + frequency count + WR threshold defined
- **Limitations:** 8 documented (from 10 naive, 2 resolved by new conditions)
- **Reaction validated:** assumed

### Conditions
- **Works when:** Formation volume ≥ 1.5× SMA(20) (institutional imbalance event); gap 0.3–2.5% (temporary component range); single clean FVG in zone (no stack: < 2 gaps in ±2% × 30 bars); FVG age ≤ 15 bars; next-candle body retraces into zone; HTF bullish (4h EMA200 slope positive); ADX < 40 (non-parabolic move)
- **Fails when:** Strong unidirectional trend (parabolic, ADX > 40 or news-driven — permanent component dominates); stacked FVGs in same zone (persistent institutional flow, not temporary imbalance); FVG > 2.5% (exhaustion/news gap — structural move, no fill buyers); low-volume formation (thin book, not institutional — no inventory imbalance created); HTF bearish context (no fill buyers in downtrend); same-candle entry (−5–10pp WR vs next-candle confirmation)
- **Best pairs:** untested — BTC/USDT, ETH/USDT hypothetically (institutional order flow most plausible on liquid pairs with active dealer inventory)
- **Best timeframe:** untested — 4h probable (fewer noise gaps vs 1h; Hendershott & Menkveld reversion documented intraday)

### 8 Documented Limitations
*(10 naive → 8 intermediate: limitations 4a and 9 resolved by new conditions)*

1. No peer-reviewed crypto study on FVG fill rates — equity 70-80% fill (Edwards & Magee) and 67% price pressure reversion (Hendershott & Menkveld) may not transfer to 24/7 crypto markets; crypto discount estimated at 15–20pp (target: 52–58% WR)
2. ICT framework is practitioner-only — "institutional order flow" imbalance claim is now anchored to Stoll (1978) dealer inventory mechanism, but the specific ICT FVG detection method (three-candle pattern) remains unevaluated in peer-reviewed literature
3. Signal frequency on BTC/ETH 4h unknown — frequency count across `fvg_min_size ∈ [0.003, 0.005, 0.008, 0.010, 0.015]` required before statistical viability is confirmed; if n < 15/year at any threshold, anti-prim precursor
4. Gap size bounds [0.3%, 2.5%] are academically motivated but not empirically verified in crypto — the temporary/permanent decomposition (Hasbrouck 1991) supports the concept; specific crypto threshold is a testable hypothesis
5. Maximum gap age (15 bars) arbitrary — stale FVGs anecdotally less reliable; the dealer inventory mechanism (Stoll 1978) supports rapid decay of rebalancing pressure; threshold unquantified in crypto
6. "Fill" definition ambiguous — wick touch vs. close within zone vs. body crosses midpoint; different definitions produce materially different WR estimates; must standardize before backtest
7. No CVD directional filter — FVG zone retracement without confirming order flow (CVD rising on retracement candle) cannot distinguish genuine fill-retracement from continuation gap expansion; CVD filter proposed as optional upgrade at sophisticated tier
8. Volume gate threshold (1.5× SMA20) not empirically calibrated for crypto — Stoll (1978) theory supports "above-average" volume; specific multiplier requires plateau test at [1.2, 1.5, 2.0, 2.5]×

### Implementation

```python
# ── Bullish FVG detection ────────────────────────────────────────────────────
# Three-candle pattern: high[i-2] < low[i]
dataframe['fvg_bull_exists'] = dataframe['high'].shift(2) < dataframe['low']
dataframe['fvg_bull_top'] = dataframe['low']               # upper edge of gap zone
dataframe['fvg_bull_bottom'] = dataframe['high'].shift(2)  # lower edge of gap zone
dataframe['fvg_bull_size'] = (
    (dataframe['fvg_bull_top'] - dataframe['fvg_bull_bottom']) / dataframe['close']
)

# ── Gap size bounds [0.3%, 2.5%] (NEW: upper bound) ─────────────────────────
fvg_in_size_range = (
    (dataframe['fvg_bull_size'] >= self.fvg_min_size.value) &   # lower: 0.003
    (dataframe['fvg_bull_size'] <= 0.025)                        # upper: 2.5% fixed
)

# ── Formation volume gate (NEW: ≥1.5× SMA20) ────────────────────────────────
dataframe['volume_sma20'] = dataframe['volume'].rolling(20).mean()
fvg_volume_ok = dataframe['volume'] >= (self.fvg_vol_mult.value * dataframe['volume_sma20'])
# fvg_vol_mult plateau: [1.2, 1.5, 2.0, 2.5]

# ── Qualified FVG (all formation conditions met) ─────────────────────────────
fvg_qualified = dataframe['fvg_bull_exists'] & fvg_in_size_range & fvg_volume_ok

# ── Stacked FVG exclusion (NEW: < 2 FVGs within ±2% in 30 bars) ──────────────
# Count FVG formations in a rolling 30-bar window
dataframe['fvg_count_30'] = fvg_qualified.rolling(30).sum()
fvg_not_stacked = dataframe['fvg_count_30'] < 2

# Apply stack filter to qualification (if current bar forms an FVG while another
# already exists in the zone, reject)
fvg_qualified_clean = fvg_qualified & fvg_not_stacked

# ── Track most recent qualified FVG ─────────────────────────────────────────
dataframe['fvg_top'] = dataframe['fvg_bull_top'].where(fvg_qualified_clean).ffill()
dataframe['fvg_bottom'] = dataframe['fvg_bull_bottom'].where(fvg_qualified_clean).ffill()
dataframe['fvg_age'] = (~fvg_qualified_clean).groupby(
    fvg_qualified_clean.cumsum()
).cumcount()

# ── Entry: price retraces into FVG zone ─────────────────────────────────────
entry_in_zone = (
    (dataframe['close'] <= dataframe['fvg_top']) &
    (dataframe['close'] >= dataframe['fvg_bottom']) &
    (dataframe['fvg_age'] <= self.fvg_max_age.value)   # plateau: [5, 10, 15, 20]
)

# ── Next-candle body confirmation (NEW: body must enter zone, not wick) ──────
# Shift entry_in_zone forward 1 bar: confirm next candle actually entered
# Body enters zone: open ≤ fvg_top (body overlaps gap on retracement candle)
body_in_zone = entry_in_zone.shift(1).fillna(False) & (
    dataframe['open'] <= dataframe['fvg_top']
)

# ── ADX < 40 gate (NEW: exclude parabolic moves) ────────────────────────────
from ta.trend import ADXIndicator
adx_indicator = ADXIndicator(
    dataframe['high'], dataframe['low'], dataframe['close'], window=14
)
dataframe['adx'] = adx_indicator.adx()
adx_ok = dataframe['adx'] < 40

# ── HTF gate: 4h EMA200 bullish (informative pair required) ─────────────────
# entry_signal = body_in_zone & adx_ok & (dataframe['ema_200_4h'] > dataframe['ema_200_4h'].shift(20))

# ── Intermediate entry signal (without HTF — for frequency test) ─────────────
entry_signal = body_in_zone & adx_ok
```

**Parameters (plateau-ready):**
- `fvg_min_size`: `CategoricalParameter([0.003, 0.005, 0.008, 0.010, 0.015], default=0.005)`
- `fvg_max_age`: `CategoricalParameter([5, 10, 15, 20], default=15)`
- `fvg_vol_mult`: `CategoricalParameter([1.2, 1.5, 2.0, 2.5], default=1.5)`

**Plateau grid:** `fvg_min_size(5) × fvg_max_age(4) × fvg_vol_mult(4)` = 80 cells — **exceeds 20-cell PBO threshold; CPCV + DSR mandatory before deploying results**. For initial frequency scan, hold `fvg_vol_mult=1.5` fixed: 20-cell subgrid (within PBO safe zone).

**Frequency count priority:** Before full backtest, run frequency scan: count signal occurrences for each `fvg_min_size × fvg_max_age` cell on BTC/ETH 4h 2022–2025. Gate: if n < 15/year at tightest threshold (0.015 × age=5) → anti-prim precursor; if n < 30 total across 3 years at any threshold → anti-prim (statistical floor).

**Exit logic:** Target FVG midpoint (`(fvg_top + fvg_bottom) / 2`) or prior swing high (whichever closer). Stop: below `fvg_bottom` (low edge). R:R at midpoint: ~1:1; at prior swing high: variable.

**Note on implementation:** The stacked FVG filter (`fvg_count_30 < 2`) is a simplified proxy. A rigorous version would check if any prior qualified FVG zone overlaps within ±2% of the current FVG bounds. The rolling count approximation is sufficient for initial backtest; refine at sophisticated tier.

### Conditions Log Entry
- **Works when:** Formation volume ≥ 1.5× SMA(20); gap 0.3–2.5%; single FVG in zone (< 2 within ±2% × 30 bars); age ≤ 15 bars; next-candle body retraces into zone; ADX < 40; 4h EMA200 slope positive; BTC/ETH
- **Fails when:** ADX > 40 (parabolic move — permanent price impact); stacked FVGs (persistent flow); gap > 2.5% (exhaustion/news); low-volume formation (< 1.5× SMA20); HTF bearish; same-candle entry (no body confirmation)
- **Last validated:** never (cycle 65 RESEARCH elevation — first academic mechanism anchors established; no own-data backtest; frequency scan required before backtesting)

### Regime Axis Context (Updated)

| Regime | Prim | Level |
|--------|------|-------|
| Ranging oscillator exhaustion | rsi-oversold-mean-reversion | sophisticated |
| Trending EMA pullback | ema-pullback-dynamic-support | sophisticated |
| Stop cluster sweep | liquidity-sweep-reversal | sophisticated |
| Exhaustion RSI divergence | bullish-rsi-divergence | sophisticated |
| Panic capitulation | capitulation-exhaustion-reversal | sophisticated |
| Derivatives crowding | funding-rate-crowding-reversal | sophisticated |
| Volatility compression → expansion | bollinger-squeeze-breakout | sophisticated |
| VWAP institutional benchmark | vwap-deviation-mean-reversion | intermediate (re-test cycle 64 pending) |
| Trending momentum (anti-prim) | hidden-bullish-rsi-divergence | anti-prim precursor |
| **Price imbalance completion** | **fair-value-gap-price-discovery** | **intermediate (cycle 65)** |

### Next Cycle Recommendation
**(A) IMPLEMENT + FREQUENCY SCAN** — Build `YujiFVGStrategy.py` with intermediate conditions. Run frequency count on BTC/ETH 4h 2022–2025 for all 20 `fvg_min_size × fvg_max_age` cells (hold `fvg_vol_mult=1.5` fixed). Gate: if n < 30 at any cell → anti-prim. If viable, proceed to full backtest with `fvg_vol_mult` parameter.
**(B) BACKTEST-ANALYSIS** — vwap-deviation-mean-reversion cycle 64 re-test (blocking intermediate → sophisticated path; target n ≥ 100, WR ≥ 55%, Sharpe ≥ 0.70).
**(C) RESEARCH** — Find any arxiv paper on FVG fill rates in crypto specifically: "fair value gap cryptocurrency backtest", "price imbalance fill rate crypto", "order block cryptocurrency". A single paper with crypto fill rate data converts source from `paper (equity)` to `paper (crypto)` and would justify direct WR calibration without the equity-to-crypto discount assumption.

Recommend **(B)** first (unblocks blocking intermediate); **(A)** second (frequency scan is low-cost 1-cycle task).

### Sources
- Stoll, H.R. (1978). The Supply of Dealer Services in Securities Markets. *Journal of Finance*, 33(4), 1133–1151. [Dealer inventory mechanism — core FVG fill anchor]
- Hasbrouck, J. (1991). Measuring the Information Content of Stock Trades. *Journal of Finance*, 46(1), 179–207. [Permanent vs temporary price impact — gap size filter justification]
- Hendershott, T. & Menkveld, A.J. (2014). Price Pressures. *Journal of Financial Economics*, 114(3), 405–423. [67% intraday price pressure reversion — direct fill rate anchor]
- Edwards, R.D. & Magee, J. (1948/2007). *Technical Analysis of Stock Trends* (9th ed.). CRC Press. [Foundational gap theory; 70–80% common gap fill rate in equities]
- Berkman, H., Dimitrov, V., Jain, P.C., Koch, P.D., & Tice, S. (2009). Sell on the News. *Journal of Finance*, 64(5). [Institutional attention-driven trading creates gap structure]
- ICT / Huddleston, M. (2010+). Inner Circle Trader methodology. [Practitioner FVG framework — mechanism now anchored to Stoll 1978; no peer review]
- LuxAlgo (2022–2025). FVG indicator community backtests. [TradingView community — selection-biased; used as order-of-magnitude reference only]
