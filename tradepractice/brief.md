# TradePractice Brief

> Edit before each window. Tells agents what to research and optimise.

## Focus Areas

### Freqtrade
- Backtest all 5 strategies over 30-day and 90-day windows
- Research optimal indicator combinations for crypto on 15m/1h timeframes
- Find community strategies with proven backtests (freqtrade GitHub, Discord, Reddit)
- Hyperopt parameter ranges for YujiMultiSignalStrategy
- Compare regime detection approaches (ADX vs ATR ratio vs volatility clustering)

### Polymarket
- Research prediction market edge: what signals predict mispricing?
- Study orderbook microstructure for better spread strategy
- Research Kelly criterion for position sizing vs fixed size
- Find academic papers on binary option market making
- Wire WebSocket feed into live strategy loop

## Research Sources

- GitHub: freqtrade/freqtrade-strategies, iterativv/NostalgiaForInfinity
- Papers: arxiv.org quantitative finance, SSRN
- Forums: r/algotrading, r/freqtrade, Polymarket Discord
- Docs: freqtrade.io, docs.polymarket.com

## Constraints

- All strategy changes must maintain dry-run as default
- Never commit API keys, private keys, or wallet addresses
- Backtest before deploying any strategy change
- Document the rationale for every parameter change
- Keep strategies compatible with freqtrade stable Docker image

## Knowledge Accumulation

Research findings persist in knowledge/ directory between windows.
Each window should build on previous findings, not repeat them.
