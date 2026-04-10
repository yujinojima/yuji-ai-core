---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T13:35:38+10:00
cycle: 1
---

---

## Prim: ema-pullback-dynamic-support
**Level:** intermediate (refined from naive)
**Project:** freqtrade
**Parent:** naive/ema-pullback-dynamic-support

### Rule
EMA alignment >= 3 + ADX 25–35 (rising) + **first/second pullback to 21 EMA only** + 4h bullish + bullish candle + MACD hist rising + RSI 40–65 + volume > 0.8x SMA → long. **TRENDING regime only.**

### Critical Finding

**EMA pullback is the mirror complement to RSI mean reversion.** RSI mean reversion works ONLY in ranging markets; EMA pullback works ONLY in trending markets. Together they partition the regime space.

| Source | Finding |
|---|---|
| Raschke Holy Grail (Street Smarts, 1995) | ADX > 30 + first pullback to 20 EMA = highest-probability trend continuation |
| IEEE (Algorithmic Crypto Trading using EMA, 2024) | EMA crypto: **PF 3.5, WR 60%, RR 2.2** |
| PakunFX BTC 1H (Aug 2023–May 2025) | EMA 21/50 pullback: **PF 1.965** |
| BTC 30min (Jan 2024–Jul 2025) | **WR 47.8%, PF 2.01, DD 5.77%** |
| PRUVIQ (2026) | Crypto spends **~60% of time in ranges** where EMA pullbacks whipsaw |
| ADX consensus | Crypto needs ADX **25–30** (higher than equities); ADX > 35 = reversal risk |

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| **Regime** | implied trending | **TRENDING ONLY — confirmed; ~60% of crypto time is ranging where this fails** |
| **ADX** | default 25 | **25–35 sweet spot; must be rising; >35 = exhaustion risk** |
| **Pullback count** | <=2 (code) | **First pullback most profitable (Raschke); confirmed >=3 = exhausted** |
| **Timeframe** | untested | **1h best (PF ~2.0); 30m viable; avoid 5m** |
| **Pairs** | untested | **BTC/ETH preferred** |
| **Certainty** | guess | **hypothesis (convergent multi-source)** |

### Implementation Gaps in YujiTrendRiderStrategy
1. **ADX direction** — add `adx > adx.shift(1)` (rising) to `buy_pullback`
2. **ADX ceiling** — add `adx < 35` to avoid exhaustion entries
3. **Volume filter** — add `volume > volume_sma * 0.8` to `buy_pullback` (currently only on `buy_acceleration`)

### Files Updated
- `knowledge/freqtrade/prims/intermediate/ema-pullback-dynamic-support.md` (created)
- `knowledge/epistemic-index.md` (intermediate table updated)
- `knowledge/conditions-log.md` (naive superseded, intermediate entry added)
- Commit: `2a2ceca`
