---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T15:11:18+10:00
cycle: 8
---

All three knowledge-bank files updated. Emitting the cycle result.

---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T15:08:00+10:00
cycle: 8
---

---

## Prim: liquidity-sweep-reversal
**Level:** sophisticated (refined from intermediate)
**Project:** freqtrade
**Parent:** intermediate/liquidity-sweep-reversal

### Rule
Wick >= 0.3% below swing low + bullish close back above + **next-candle confirmation** + CVD divergence (filter only) + volume > 1.2x SMA + within 2% of VP POC/VAL + ADX < 30 + BTC/ETH 1h–4h + **fixed stop below wick low** + R:R >= 1:2 → long to next VP level. **RANGING-TO-MILD-TREND regime only.**

### What Elevated This from Intermediate

9 independent sources (up from 6), with the **first large-n quantitative anchor** (n=2,847 vs prior n=22 at intermediate) plus quantified failure modes and OOS expectations.

| New Finding | Source | Impact |
|---|---|---|
| **n=2,847 SFP BTC/ETH/alts 2022–2025: 68% WR, PF 1.92** (vol-confirmed) | QuantVPS | First large-sample quantitative anchor — replaces n=22 |
| **73% of liquidation events within 2% of swing levels** | QuantVPS | Mechanistic justification for stop-cluster edge |
| **"Perfect HTF SFPs" 85–95% reliability** (selection-biased) | Morpher/PrimeXBT | Upper-bound ceiling for best-case setups |
| **Naked POC ~80% revisit within 10 sessions** | Buildix | Strengthens VP target beyond prior "75%+" |
| **CVD in isolation underperforms; works as filter only** (2018–2024) | Bookmap | Downgrades lone-CVD setups — filter, not trigger |
| **"Textbook setups fail ~40% of the time"** base rate | Bookmap | Anchors realistic WR ceiling near 60%, not 80% |
| **Expected OOS Sharpe /2 to /3** (McLean-Pontiff 26% OOS, 58% post-publication) | QuantPedia / arxiv 2602.10785 | Bounds live vs backtest |
| **Live BTC SMC leaderboard: PF 1.51, n=82** | HorizonAI | Realistic live benchmark below backtest headline |
| **Best reversals within 1–2 candles of wick** | LuxAlgo/QuantVPS | Tightens confirmation window |

### Key Numbers

| Metric | Value |
|---|---|
| WR (vol-confirmed SFP, n=2,847) | **68%** |
| PF (vol-confirmed SFP) | **1.92** |
| WR (bare wick, no confirmation) | ~50% |
| WR (+ candle close + R:R 1:2) | 55–60% |
| Live realistic WR (post-OOS) | **55–62%** |
| Naked POC revisit (10 sessions) | ~80% |
| Liquidations within 2% of swing | 73% |
| Live BTC SMC leaderboard | PF 1.51 (n=82) |
| Textbook failure base rate | ~40% |
| Expected OOS degradation | 26–58% Sharpe loss |

### Critical Failure Modes (Quantified)
1. **Strong trend (ADX > 35)** — sweeps become genuine breakdowns. **#1 failure mode.** Walk-forward 2020→2021 studies confirm regime flip collapse.
2. **CVD in isolation** — 2018–2024 backtests confirm underperformance vs filter use.
3. **Parameter sensitivity (HIGH)** — FMZQuant explicitly documents curve-fit risk on wick depth, lookback, volume multiplier.
4. **OOS degradation** — expect /2 to /3 Sharpe loss vs in-sample.
5. **Same-candle entry** — drops 5–10pp WR.
6. **No VP anchor** — secondary entry (no POC/VAL) drops ~20pp WR.
7. **SMC automation gap** — mechanical 5-bar pivots capture only ~70% of visual setups.
8. **Base-rate ceiling** — do not expect live WR above 68%; realistic target is 55–62%.

### 10 Implementation Gaps in YujiSmartMoneyStrategy
1. ADX < 30 regime gate (currently fires in all regimes — #1 priority)
2. `sweep_bullish.shift(1)` + close confirmation (replace same-candle entry)
3. CVD as divergence filter only (`cvd_hl & price_ll`), never trigger
4. Volume threshold 0.8x → **1.2x** SMA(20)
5. Wick depth `>= 0.3%` enforcement
6. **Fixed stop** below sweep wick low (NOT ATR trail — sister prim showed PF crash 2.0 → 0.603)
7. R:R >= 1:2 target logic
8. Pair whitelist BTC/USDT, ETH/USDT only
9. Drop secondary entry (no-VP variant)
10. Walk-forward optimization before deployment

### Regime Partition — Complete at Sophisticated

| Regime | Prim | Level | ADX |
|---|---|---|---|
| Ranging | rsi-oversold-mean-reversion | intermediate | < 20 |
| Ranging-to-mild-trend | **liquidity-sweep-reversal** | **sophisticated** | **< 30** |
| Trending | ema-pullback-dynamic-support | sophisticated | 25–35 |

2/3 freqtrade prims now at sophisticated. RSI mean reversion remains the next elevation candidate (has academic PMC9920669 anchor; needs parameter-sensitivity and OOS degradation quantification).

### Critical Limitation
**No own-data backtest.** The specific 10-filter combination has never been tested as a unit. This is the #1 gap blocking deployment. Next cycle should be BACKTEST-ANALYSIS or own-data walk-forward.

### Files Updated
- `knowledge/freqtrade/prims/sophisticated/liquidity-sweep-reversal.md` (created)
- `knowledge/epistemic-index.md` (sophisticated table: +1 row)
- `knowledge/conditions-log.md` (intermediate superseded, sophisticated entry added)

Sources:
- [QuantVPS — Swing Failure Pattern Strategy (n=2,847 backtest)](https://www.quantvps.com/blog/swing-failure-pattern-strategy)
- [QuantVPS — SFP Explained: Smart Money Liquidity Clustering](https://www.quantvps.com/blog/swing-failure-pattern-explained)
- [Morpher — Swing Failure Pattern: Identifying Reversals](https://www.morpher.com/blog/swing-failure-pattern)
- [LuxAlgo — Swing Failure Pattern Indicator](https://www.luxalgo.com/library/indicator/swing-failure-pattern-sfp/)
- [Bookmap — CVD Trading Strategy & Divergence (2018–2024 filter analysis)](https://bookmap.com/blog/how-cumulative-volume-delta-transform-your-trading-strategy)
- [Buildix — Volume Profile: Naked POC 80% Revisit](https://www.buildix.trade/blog/volume-profile-trading-strategies-value-area-naked-poc-free-guide-2026)
- [HorizonAI — Backtesting Smart Money Concepts (live BTC PF 1.51)](https://www.horizontrading.ai/learn/backtesting-smart-money-concepts)
- [QuantPedia — In-Sample vs Out-of-Sample Analysis (McLean-Pontiff)](https://quantpedia.com/in-sample-vs-out-of-sample-analysis-of-trading-strategies/)
- [arxiv 2602.10785 — Walk-Forward Optimization in Crypto](https://arxiv.org/html/2602.10785)
- [FMZQuant — Dynamic ATR Contrarian Sweep System (parameter sensitivity)](https://medium.com/@FMZQuant/dynamic-atr-contrarian-trading-strategy-market-liquidity-sweep-and-reversal-breakthrough-e2a09908e598)
