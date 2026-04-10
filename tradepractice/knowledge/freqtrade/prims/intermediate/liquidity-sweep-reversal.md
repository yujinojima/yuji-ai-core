---
name: liquidity-sweep-reversal
level: intermediate
project: freqtrade
parent_prim: naive/liquidity-sweep-reversal
created: 2026-04-10
last_validated: never
reaction_validated: assumed
---

## Prim: liquidity-sweep-reversal
**Level:** intermediate (refined from naive)
**Project:** freqtrade
**Parent:** naive/liquidity-sweep-reversal

### Rule
Wick below swing low by >= 0.3% + close back above + bullish candle + CVD delta positive & rising + near VP level (POC/VAL) + volume > 0.8x SMA + **RANGING-TO-MILD-TREND regime** (ADX < 30) + minimum wick depth filter + **next-candle confirmation preferred** → long to next VP level (POC/VAH). **Fails in strong trends (ADX > 35) where sweeps become genuine breakdowns.**

### Critical Finding

**Liquidity sweeps are the RANGING/TRANSITIONAL regime complement to EMA pullback (trending) and RSI mean reversion (ranging).** Sweeps exploit trapped agents at structural levels — a fundamentally different mechanism from oscillator mean reversion or trend continuation. The edge is regime-dependent: sweeps reverse in ranges but extend in trends.

| Source | Finding |
|---|---|
| EUR/USD liquidity pool study (ResearchGate, 2024) | PDL sweeps → bullish reversal to PDH on **23.8% of days** (20/84); alternating PDH/PDL sweeps on 7.14% of days |
| Bitcoin weekly SFP (Benzinga, 2026) | Weekly swing failure pattern: **91% success rate** (20/22 SFPs followed by >10% move), but n=22 since Mar 2021 |
| BTC 4H SFP backtest (community) | SFP + candle close confirmation + 1:2 RR raised WR from **45-55% to 55-60%** |
| CVD divergence studies (S&P E-mini) | Persistent CVD divergence precedes reversal **65-75% of the time**; ~70% of major intraday pullbacks preceded by CVD signal |
| Volume Profile POC reversion (FuturesHive) | Mean reversion to POC: **75%+ WR** in ranging markets; **85%+ WR** with HVN + POC + Fibonacci confluence |
| SMC backtest consensus | Sweep + structure shift: **60-70% WR** in ranging; lone wicks without confirmation: ~50% (coin flip) |
| Regime dependency (multiple) | Sweep reversal works in ranging/mild trend; fails in strong trends where breakdowns are genuine |

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| **Regime** | "ranging to mildly trending" (guessed) | **RANGING-TO-MILD-TREND (ADX < 30); fails when ADX > 35 (genuine breakdown)** |
| **Wick depth** | no minimum | **>= 0.3% below swing low (min_wick_depth_pct); noise wicks produce false signals** |
| **Confirmation** | same-candle (bullish close) | **Next-candle confirmation preferred; same-candle WR 45-55%, with confirmation 55-60%** |
| **CVD quality** | "positive and rising" | **CVD divergence (price LL, CVD HL) is strongest signal; simple positive CVD is weaker** |
| **VP proximity** | near POC/VAL | **POC reversion 75%+ WR; VAL + POC confluence strongest; sweeps away from VP levels are noise** |
| **Volume** | > 0.8x SMA (code) | **Confirmed: volume spike during rejection adds confidence; 25%+ of candle volume outside swing level** |
| **Timeframe** | 15m (untested) | **1h-4h most reliable; 15m viable for entry precision; avoid 5m** |
| **Pairs** | untested | **High-liquidity pairs (BTC/ETH) — thin order books on alts produce fake sweeps that wander** |
| **Certainty** | guess | **hypothesis (convergent multi-source, but no dedicated crypto sweep backtest)** |

### Situation (Agent Model)

**Setup:** Price approaches a prior swing low where stop-loss orders cluster. VP level (POC/VAL) nearby confirms institutional interest at this price. Market is in ranging or mild trend regime (ADX < 30).

**Trigger:** Candle wicks below the swing low by >= 0.3%, sweeping stop-loss orders. Close recovers above the swing low with bullish body.

**Reaction:**
- **Accepted (reversal):** Next candle holds above swing low; CVD delta positive and rising (real buying pressure absorbing the sweep); volume spikes during rejection. Trapped breakout shorts must cover → mechanical fuel for upside move toward POC/VAH.
- **Rejected (breakdown):** Next candle closes below swing low; CVD stays negative; volume weak or continues selling. The sweep was not a trap — genuine breakdown. ADX > 35 context makes this more likely.
- **Unclear:** Price stalls at swing low; CVD flat; low volume. No directional conviction. Wait.

**Agent Behaviour:**
- **Who is acting:** Institutional flow sweeping stops to fill buy orders at lower prices.
- **Who is trapped:** Breakout shorts who entered below the swing low. Their stop-covers fuel the reversal.
- **Who is wrong:** Late sellers entering at the extreme. If the sweep reverses, their exits add to upside fuel.

### Conditions
- **Works when:** RANGING-TO-MILD-TREND regime (ADX < 30); near VP level (POC/VAL); clear prior swing low with stop clusters; CVD delta positive and rising (ideally divergent — price LL, CVD HL); wick depth >= 0.3% below swing low; volume spike on rejection candle (> 0.8x SMA, ideally > 1.5x); bullish close above swing low; next-candle holds above; high-liquidity pair (BTC/ETH)
- **Fails when:** Strong trend (ADX > 35) — sweeps become genuine breakdowns, not traps; multiple consecutive sweeps at same level (support is breaking, not holding); no CVD confirmation (dead-cat bounce); low volume sweep (noise wick, not institutional); thin order book pair (exotic alts — price wanders after sweep); 5m timeframe (too much noise); no nearby VP level (no structural significance); news-driven capitulation
- **Best pairs:** BTC/USDT, ETH/USDT (institutional flow, deep order books, stop clusters are meaningful)
- **Best timeframe:** 1h-4h (most reliable for sweep significance); 15m viable for entry precision within higher-TF context; avoid 5m

### Evidence
- **Source:** community backtests + one academic study (EUR/USD liquidity pools) + CVD studies (futures)
- **Certainty:** hypothesis (convergent multi-source, but no dedicated BTC sweep backtest with this exact setup)
- **Scope:** tested on EUR/USD (academic), BTC weekly (SFP), S&P futures (CVD); crypto 15m sweep-specific backtest: pending
- **Falsifiability:** testable — can backtest sweep detection + CVD + VP proximity + regime filter vs no-regime
- **Reaction validated:** assumed — no forward-test; SFP weekly data shows 91% reaction rate but n=22
- **Data:** Weekly SFP 91% (n=22); 4H SFP 55-60% WR with confirmation; CVD divergence 65-75% reversal rate; POC reversion 75%+ WR in ranging
- **Citations:**
  - ResearchGate: "Examining Short-Term Trend Reversals via Previous Day Liquidity Pools" (2024)
  - Benzinga: Bitcoin weekly SFP 91% accuracy (Jan 2026)
  - LuxAlgo: CVD explained — 65-75% divergence reversal rate
  - FuturesHive: Volume Profile POC mean reversion 75%+ WR (2025)

### Limitations
1. **CVD is approximated from candle close position** — not real order flow. On 15m candles, this is a rough proxy. True CVD requires tick data or exchange taker buy/sell.
2. **No dedicated crypto sweep backtest exists.** The 91% weekly SFP stat is BTC-only, n=22, weekly TF — cannot extrapolate to 15m.
3. **5-bar pivot swing detection misses complex structures.** Double bottoms, head-and-shoulders lows, and multi-bar consolidation lows are not captured.
4. **Same-candle entry (current code) fires before reaction is confirmed.** The intermediate prim recommends next-candle confirmation but the strategy enters same-candle.
5. **No regime filter in current code.** Strategy fires in all regimes. Strong-trend sweeps are genuine breakdowns, not traps.
6. **Secondary entry (lines 200-212) drops the VP proximity requirement** — this removes the structural significance anchor and likely degrades WR.
7. **Anchored VWAP loop** (lines 329-343) is O(n) per candle — may be slow on long backtests but not a signal quality issue.

### Implementation Gaps in YujiSmartMoneyStrategy

1. **Regime filter** — add ADX < 30 gate (or ADX < 25 for conservative) to `populate_entry_trend`. Currently fires in all regimes including strong downtrends where sweeps are genuine breakdowns.
2. **Next-candle confirmation** — current code enters same-candle. Add `sweep_bullish.shift(1)` to confirm the sweep candle's signal with a holding candle. Raises WR from ~50% to 55-60%.
3. **CVD divergence** — current code checks `cvd_delta > 0 & rising`. Stronger signal: check CVD making higher low while price makes lower low (divergence). Add: `(dataframe["cvd_delta"] > dataframe["cvd_delta"].shift(swing_lookback))` while `(dataframe["low"] < dataframe["low"].shift(swing_lookback))`.
4. **Secondary entry quality** — lines 200-212 drop VP proximity. Consider removing or requiring AVWAP + RSI < 40 + regime gate to maintain signal quality.
5. **Volume spike threshold** — current `volume > volume_sma * 0.8` is weak. The rejection candle should show elevated volume: consider `volume > volume_sma * 1.2` or `volume > volume_sma * 1.5` for the sweep candle specifically.

### Conditions Log Entry
- **Works when:** RANGING-TO-MILD-TREND (ADX < 30); near VP level (POC/VAL); wick >= 0.3% below swing low; CVD positive+rising (divergence preferred); volume > 0.8x SMA; bullish close above swing low; high-liquidity pair; 1h-4h timeframe (15m for precision)
- **Fails when:** Strong trend (ADX > 35); consecutive sweeps at same level; no CVD confirmation; low volume; thin order book alts; 5m noise; news capitulation; no VP level nearby
- **Last validated:** never (needs backtest with regime filter + next-candle confirmation)
