---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T14:03:15+10:00
cycle: 5
---

---

## Prim: ema-pullback-dynamic-support
**Level:** sophisticated (refined from intermediate)
**Project:** freqtrade
**Parent:** intermediate/ema-pullback-dynamic-support

### Rule
EMA alignment >= 3 + ADX 25–35 (rising) + **first pullback to 21 EMA only** + 4h bullish + bullish candle + MACD hist rising + RSI 40–65 + volume > 0.8x SMA + **fixed stop below swing low** → long. **TRENDING regime only.**

### What Elevated This from Intermediate

8 independent sources (up from 4) now converge, with **quantified failure modes** that the intermediate lacked:

| New Finding | Source | Impact |
|---|---|---|
| **57–76% false signal rate** without regime filter | MA cross study (1960–2025) | Quantifies WHY ADX gate is mandatory |
| **ADX adds only ~1pp** (69.9% → 71%) | Coinmonks (8,765 patterns) | ADX value = avoiding ranging losses, not boosting wins |
| **ATR trailing stop kills the edge** (PF 0.603, WR 28%) | Betashorts (2026) | Fixed stop below swing low is the only viable approach |
| **Underperforms B&H in bull markets** (26% vs 42.5%) | IEEE/arxiv (BTC, 2024) | Edge is drawdown avoidance, not absolute return |
| **PF 1.61–2.68 cross-asset** (same strategy) | QuantifiedStrategies (AAPL vs NVDA) | HIGH parameter sensitivity — asset choice dominates |
| **25–50% OOS degradation expected** | Walk-forward meta-analysis | WFE ~72% for multi-indicator EMA systems |
| **IEEE PF 3.5 not reproducible** | Own analysis | Was EMA cross, not pullback; underperformed B&H on same data |
| **PRUVIQ "60% ranging" has no data** | Own verification | Downgraded from intermediate evidence table |

### Key Numbers
- **PF:** ~2.0 (BTC 1H), range 1.61–2.68 cross-asset
- **WR:** ~48% (BTC), range 35.7%–57.7% cross-asset
- **DD:** 5.77% (BTC 30m) to 27.01% (NVDA daily)
- **OOS degradation:** expect 25–50%
- **False signals without regime gate:** 57–76%

### Evidence
- **Source:** paper + community backtests (8 sources)
- **Certainty:** evidence (convergent multi-source)
- **Falsifiability:** tested-pass (PF > 1.5 across 5 backtests) AND tested-fail (ATR trail, B&H comparison)

### Critical Limitation
**No own-data backtest.** The specific filter combination has never been tested as a unit. This is the #1 gap blocking further elevation. Next cycle should be BACKTEST-ANALYSIS.

### Files Updated
- `knowledge/freqtrade/prims/sophisticated/ema-pullback-dynamic-support.md` (created)
- `knowledge/epistemic-index.md` (sophisticated table populated)
- `knowledge/conditions-log.md` (intermediate superseded, sophisticated entry added)

### Conditions Log Entry
- **Works when:** TRENDING regime (ADX 25–35, rising); first pullback to 21 EMA; 1h TF; BTC/ETH
- **Fails when:** RANGING (57–76% false signals); ATR trailing stop (PF 0.603); bull market B&H comparison; low-liquidity alts
- **Key numbers:** PF ~2.0, WR ~48%, 25–50% OOS degradation expected
- **Last validated:** never

Sources:
- [IEEE — Algorithmic Crypto Trading using EMA (2024)](https://ieeexplore.ieee.org/iel8/11034707/11034773/11035368.pdf)
- [arxiv — Technical Analysis Meets Machine Learning: Bitcoin Evidence](https://arxiv.org/html/2511.00665v1)
- [PakunFX — EMA Pullback Speed Strategy (TradingView)](https://www.tradingview.com/script/cxhQ5d5x-EMA-Pullback-Speed-Strategy/)
- [Coinmonks — Crypto Backtest: 15+ Trading Strategies](https://medium.com/coinmonks/crypto-backtest-the-most-extensive-analysis-15-trading-strategies-58f06deca2bd)
- [Betashorts — EMA Pullback Backtest Failure Analysis (2026)](https://medium.com/@betashorts1998/i-fixed-the-biggest-flaw-in-my-last-backtest-the-strategy-still-lost-money-64022a65e370)
- [QuantifiedStrategies — 8/21 EMA 10yr Backtest](https://www.quantifiedstrategies.com/exponential-moving-average-trading-strategy/)
- [Thrive.fi — Crypto Market Regime Detection](https://thrive.fi/blog/trading/crypto-market-regime-detection)
- [Raschke Holy Grail — TradingSetupsReview](https://www.tradingsetupsreview.com/the-holy-grail-trading-setup/)
