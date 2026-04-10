---
name: ema-pullback-dynamic-support
level: intermediate
project: freqtrade
parent_prim: naive/ema-pullback-dynamic-support
created: 2026-04-10
last_validated: never
reaction_validated: assumed
---

## Prim: ema-pullback-dynamic-support
**Level:** intermediate (refined from naive)
**Project:** freqtrade
**Parent:** naive/ema-pullback-dynamic-support

### Rule
EMA alignment >= 3 + ADX 25–35 (rising) + **first or second pullback to 21 EMA only** + 4h bullish (EMA50 > EMA200) + bullish candle + MACD hist rising + RSI 40–65 + volume > 0.8x SMA → long toward prior swing high. **TRENDING regime only. Exit on ADX decline from peak or EMA alignment breakdown.**

### Critical Finding

**EMA pullback is the mirror complement to RSI mean reversion: it works ONLY in trending markets, just as RSI mean reversion works ONLY in ranging markets.** Crypto spends ~60% of time in ranges where EMA pullbacks whipsaw constantly.

| Source | Finding |
|---|---|
| Raschke "Holy Grail" (Street Smarts, 1995) | ADX > 30 + first pullback to 20 EMA = highest-probability trend continuation. **First retracement is most profitable.** |
| IEEE (Algorithmic Crypto Trading using EMA, 2024) | EMA strategy on crypto: **PF 3.5, WR 60%, RR 2.2** — outperformed deep learning by 9.37% |
| PakunFX BTC 1H backtest (Aug 2023–May 2025) | EMA 21/50 pullback speed strategy: **PF 1.965** |
| BTC 30min backtest (Jan 2024–Jul 2025) | **WR 47.8%, PF 2.01, max DD 5.77%** |
| DOGE 2H multi-indicator (Jan 2021–Mar 2026) | **WR 70.7%, PF 1.80, DD 1.71%** (with confluence filters) |
| PRUVIQ (2026) | Crypto spends **~60% of time in ranges** — EMA crossovers whipsaw in these periods |
| ADX crypto research consensus | Crypto needs ADX **25–30** threshold (higher than equities due to volatility); ADX > 35 = reversal risk |

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| **Regime** | "trending" (implied) | **TRENDING ONLY — confirmed by multiple sources; ~60% of crypto time is ranging where this fails** |
| **ADX range** | default 25 (lower bound) | **25–35 sweet spot; ADX > 35 = reversal/exhaustion risk** |
| **ADX direction** | not checked | **Must be rising — declining ADX from 30+ = trend exhaustion (exit signal)** |
| **Pullback count** | <= 2 touches (code) | **First pullback most profitable (Raschke); <=2 confirmed correct; >=3 = level exhausted** |
| **Timeframe** | "untested" | **1h best for crypto pullbacks (PF 1.97); 30m viable (PF 2.01); avoid 5m** |
| **Pairs** | "untested" | **BTC/ETH preferred (institutional trend-following flow); altcoins noisier** |
| **Evidence** | anecdote | **IEEE paper + community backtests + Raschke pattern** |
| **Certainty** | guess | **hypothesis (convergent multi-source)** |
| **Volume** | not in pullback entry | **Required: volume > 0.8x SMA confirms real participation** |

### Mechanism
In a confirmed uptrend (EMA ribbon aligned, ADX 25–35 rising), the 21 EMA concentrates re-entry bids from trend-followers. The first pullback after trend establishment has the highest probability because:
1. **Positioned longs** defend the level with limit bids
2. **Countertrend shorts** are trapped and must cover when price holds
3. **Momentum algos** re-enter on EMA touch + bullish confirmation

Edge degrades with each subsequent test because: buyer conviction weakens, stops tighten, and the level becomes "known" — attracting more shorts than longs.

Edge **disappears entirely** in ranging markets (~60% of crypto time) because EMA alignment is unstable, pullbacks are noise not signal, and the mechanical covering-fuel from trapped shorts doesn't exist.

### Conditions
- **Works when:** TRENDING regime (ADX 25–35, rising); EMA alignment >= 3 (8 > 21 > 50 > 100); 4h EMA50 > EMA200; RSI 40–65; first or second pullback to 21 EMA; volume > 0.8x SMA(20); bullish candle close above EMA; MACD histogram rising
- **Fails when:** RANGING regime (ADX < 20, flat EMA ribbon) — **#1 failure mode**; ADX > 35 (trend exhaustion/reversal risk); 3+ EMA21 tests in 20 candles (level degraded); 4h bearish (EMA50 < EMA200); RSI < 35 (breakdown) or > 70 (blow-off top); low volume pullback (no institutional participation); parabolic move that skips EMA entirely
- **Best pairs:** BTC/USDT, ETH/USDT (institutional trend-following flow active)
- **Best timeframe:** 1h (PF ~2.0, best signal-to-noise); 30m viable; avoid 5m (whipsaw)
- **Best regime:** TRENDING (ADX 25–35, rising, EMA alignment >= 3)

### Evidence
- **Source:** IEEE paper + community backtests + Raschke pattern + code extraction
- **Certainty:** hypothesis (convergent multi-source, no own backtest yet)
- **Scope:** BTC/ETH on 1h (strongest evidence); other pairs/timeframes extrapolated
- **Falsifiable:** untested with own data — needs freqtrade backtest
- **Data:**
  - IEEE EMA crypto: PF 3.5, WR 60%, RR 2.2
  - BTC 1H pullback: PF 1.965 (Aug 2023–May 2025)
  - BTC 30min: WR 47.8%, PF 2.01, DD 5.77% (Jan 2024–Jul 2025)
  - DOGE 2H confluence: WR 70.7%, PF 1.80, DD 1.71%
- **Citations:**
  - IEEE Xplore: "Algorithmic Crypto Trading using EMA Strategy" (2024)
  - Raschke & Connors, "Street Smarts" (1995) — Holy Grail setup
  - PakunFX EMA Pullback Speed Strategy (TradingView)
  - PRUVIQ: "EMA Crossover Strategy: Why It Often Fails in Crypto"

### Limitations
1. **No own backtest** — all performance numbers from external sources with different exact parameters
2. **Raschke's Holy Grail is for equities/futures** — crypto adaptation is hypothesis, not proven
3. **ADX 25–35 sweet spot** is consensus, not backtested on our pairs/timeframe
4. **Parabolic crypto moves** skip the 21 EMA entirely — signal never fires during strongest trends
5. **Same-candle entry** — no next-candle confirmation; reaction is assumed, not observed
6. **EMA alignment >= 3 frequency** in crypto unknown — may be rare, limiting trade count
7. **Altcoin applicability** uncertain — BTC/ETH data may not transfer to low-liquidity pairs

### Implementation

**Current code (YujiTrendRiderStrategy.py)** already implements most intermediate conditions:
- EMA alignment >= 3 (line 194) ✓
- Low touches 21 EMA (line 195) ✓
- Close above 21 EMA (line 196) ✓
- Bullish candle (line 197) ✓
- MACD hist rising (line 198) ✓
- RSI 40–65 (lines 199–200) ✓
- EMA21 touch count <= 2 (line 201) ✓
- ADX > threshold (line 181, trending gate) ✓
- 4h bullish (line 186, htf_bullish gate) ✓

**Gaps to close for full intermediate implementation:**
1. **ADX direction check** — add `adx > adx.shift(1)` (rising ADX) to entry conditions
2. **ADX ceiling** — add `adx < 35` to avoid late-trend exhaustion entries
3. **Volume filter on pullback** — add `volume > volume_sma * 0.8` to `buy_pullback` (currently only on `buy_acceleration`)

**File:** `user_data/strategies/YujiTrendRiderStrategy.py`
**Entry block:** `buy_pullback` (lines 193–202)
**Parameters:** `adx_threshold` default=25 (range 18–30); consider narrowing to 25–30

### Conditions Log Entry
- **Works when:** TRENDING regime (ADX 25–35, rising); EMA alignment >= 3; 4h EMA50 > EMA200; RSI 40–65; first/second pullback to 21 EMA; volume > 0.8x SMA; bullish candle + MACD hist rising
- **Fails when:** RANGING regime (ADX < 20, ~60% of crypto time); ADX > 35 (exhaustion); 3+ EMA tests (level degraded); 4h bearish; RSI < 35 or > 70; low volume; parabolic skip
- **Last validated:** never (needs backtest with ADX direction + ceiling filters)
