---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T15:26:33+10:00
cycle: 9
---

All three files updated. Emitting the cycle result.

---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T15:25:00+10:00
cycle: 9
---

---

## Prim: rsi-oversold-mean-reversion
**Level:** sophisticated (refined from intermediate)
**Project:** freqtrade
**Parent:** intermediate/rsi-oversold-mean-reversion

### Rule
RSI(14) in the **25–35 plateau zone** (NOT a single magic threshold) + RANGING (ADX < 20 AND BBW pctl < 40) + price > 1h EMA200 + confirming oscillator + volume > 0.8x SMA + BTC/ETH 4h primary + **fee+slippage-adjusted edge > 2x friction** + parameter plateau verified → long to BB middle. **Sub-1h TF lethal. Bitcoin without regime gate documented fail.**

### What Elevated This from Intermediate

8 convergent sources (up from 3), with the **first quantified parameter-sensitivity ceiling, friction destruction data, and second academic anchor** the intermediate lacked.

| New Finding | Source | Impact |
|---|---|---|
| **OOS < 70% of IS = overfit; real QQQ case +28.4% IS → −79.3% live** | QuantVPS / CPCV meta | Hard OOS degradation ceiling |
| **Avoid "magic numbers" (RSI < 23.7); demand plateau 25–35 with < 20% PF variance** | LuxAlgo / CPCV guidance | Defines sophistication criterion |
| **Transaction costs erode Sharpe ~47% (1.5 → 0.8)** | BSIC modelling | Friction destroys frequent mean-reversion |
| **HFT variant: +84k gross → −99k net** | FMZQuant / PANews | Sign flip on sub-1h TFs |
| **Bear-phase BTC/USDT mean reversion failed; accumulation "limited profitability"** | **SSRN 5775962 (Efe Arda, 2026)** | **Second academic anchor** after PMC9920669 |
| **Bailey-Borwein-Lopez de Prado PBO + Deflated Sharpe** | SSRN 2326253 | Multiple-testing correction framework |
| **BB width pctl < 20 = squeeze; stable mid-range = viable** | VolatilityBox | Independent regime filter beyond ADX |
| **3-source Bitcoin verdict: mean reversion does NOT work without gate** | PMC9920669 + Bens + QuantifiedStrategies | Convergent Bitcoin-specific failure |

### Key Numbers

| Metric | Value |
|---|---|
| Ungated crypto (PMC9920669, n=10, 1,462 days) | **−97.5pp vs B&H** (177.7% vs 275.2%) |
| Inverse momentum same data | **+498pp** (773.6% vs 275.2%) |
| 4h BTC regime-gated (AtomicScript) | **Sharpe 5.13, WR 60%, PF 2.09** |
| 5m BTC | WR 34.7% (friction dominates) |
| BTC-neutral post-2021 (Briplotnik) | Sharpe 2.3 |
| Equity RSI2 Connors benchmark | PF 2.08 (n=288) |
| **Sharpe erosion from friction** | **~47%** (1.5 → 0.8) |
| Realistic slippage band | 0.02–0.05% per trade |
| **OOS degradation ceiling** | **> 30% loss = reject** |
| Parameter plateau criterion | PF variance < 20% across RSI 25–35 |

### Critical Failure Modes (10, Quantified)
1. Trending regime without gate — **−97.5pp**
2. Parameter curve-fit — "magic numbers" like RSI < 23.7
3. Transaction cost / slippage — ~47% Sharpe erosion; HFT sign flip
4. Low-TF noise — 5m WR 34.7% vs 60% at 4h
5. OOS cliff — real QQQ +28.4% → −79.3%
6. Multiple-testing inflation — PBO rises with variants
7. BB squeeze → expansion (trend birth, not reversion)
8. Bitcoin-specific fail confirmed by 3 sources
9. News capitulation
10. IS/OOS regime flip (2020 → 2021 collapse)

### Implementation Gaps
**YujiRegimeStrategy**: BBW pctl < 40 filter, plateau IntParameter 25–35, 4h primary / drop 15m+5m, fee+slippage gate, exit at BB middle.
**YujiMultiSignalStrategy.buy_1 (lines 191–196)** CRITICAL: add regime gate — currently fires any regime (exact PMC9920669 failure mode); BTC/ETH whitelist; remove 15m.

### Regime Partition — Complete at Sophisticated (3/3)

| Regime | Prim | ADX | BBW pctl |
|---|---|---|---|
| **Ranging** | **rsi-oversold-mean-reversion** | **< 20** | **< 40, stable** |
| Ranging-to-mild-trend | liquidity-sweep-reversal | < 30 | any |
| Trending | ema-pullback-dynamic-support | 25–35 rising | expanding |

All three freqtrade prims now sophisticated. Next cycle must be **BACKTEST-ANALYSIS** — shared blocker across all three: no own-data walk-forward with plateau verification.

### Critical Limitation
No own-data backtest; no parameter plateau verification. Deployment blocked on (a) plateau test RSI 25–35, (b) walk-forward bull→bear→accumulation, (c) friction-adjusted OOS Sharpe within 30% of IS.

### Files Updated
- `knowledge/freqtrade/prims/sophisticated/rsi-oversold-mean-reversion.md` (created)
- `knowledge/epistemic-index.md` (sophisticated table: +1 row → 3/3 freqtrade prims at sophisticated)
- `knowledge/conditions-log.md` (intermediate superseded, sophisticated entry added)

Sources:
- [PMC9920669 — Effectiveness of RSI Signals in Timing Crypto Markets](https://pmc.ncbi.nlm.nih.gov/articles/PMC9920669/)
- [SSRN 5775962 — Bollinger Bands under Varying Market Regimes: BTC/USDT (Efe Arda, 2026)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5775962)
- [AtomicScript — RSI Crossover Bitcoin Backtest (4h Sharpe 5.13)](https://medium.com/@AtomicScript/episode-3-rsi-crossover-strategy-1273d8b3f290)
- [Briplotnik — Systematic Crypto Trading Strategies](https://medium.com/@briplotnik/systematic-crypto-trading-strategies-momentum-mean-reversion-volatility-filtering-8d7da06d60ed)
- [QuantifiedStrategies — Bitcoin RSI: mean reversion doesn't work](https://www.quantifiedstrategies.com/bitcoin-rsi/)
- [QuantifiedStrategies — RSI2 Connors (PF 2.08, n=288)](https://www.quantifiedstrategies.com/rsi-2-strategy/)
- [Bailey/Borwein/Lopez de Prado — Probability of Backtest Overfitting (SSRN 2326253)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2326253)
- [Bailey — Deflated Sharpe Ratio](https://www.davidhbailey.com/dhbpapers/deflated-sharpe.pdf)
- [BSIC — Transaction Cost Modelling (Sharpe erosion)](https://bsic.it/backtesting-series-episode-5-transaction-cost-modelling/)
- [PANews — Slippage: The Most Underrated Profit Killer](https://www.panewslab.com/en/articles/019cf1ab-bde1-752c-b41b-a5d46fda4080)
- [ScienceDirect — Backtest Overfitting ML Era (CPCV)](https://www.sciencedirect.com/science/article/abs/pii/S0950705124011110)
- [VolatilityBox — Bollinger Bands Volatility: Squeeze and Percentile](https://volatilitybox.com/research/bollinger-bands-volatility/)
- [FMZQuant — Volatility-Optimized RSI Mean Reversion](https://medium.com/@FMZQuant/volatility-optimized-rsi-mean-reversion-trading-strategy-a83eda318fab)
