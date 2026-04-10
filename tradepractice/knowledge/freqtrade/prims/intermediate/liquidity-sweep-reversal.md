---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T13:47:27+10:00
cycle: 3
---

---

## Prim: liquidity-sweep-reversal
**Level:** intermediate (refined from naive)
**Project:** freqtrade
**Parent:** naive/liquidity-sweep-reversal

### Rule
Wick >= 0.3% below swing low + close above + CVD divergence + near VP level (POC/VAL) + volume spike + **RANGING-TO-MILD-TREND regime (ADX < 30)** + next-candle confirmation → long to next VP level. **Fails in strong trends (ADX > 35) where sweeps become genuine breakdowns.**

### Critical Finding

**Liquidity sweeps are the RANGING/TRANSITIONAL regime complement** — different mechanism from RSI mean reversion (oscillator exhaustion) and EMA pullback (trend continuation). Edge = trapped agents at structural levels.

| Source | Finding |
|---|---|
| EUR/USD liquidity pool study (ResearchGate 2024) | PDL sweeps → bullish reversal on **23.8% of days** (20/84) |
| Bitcoin weekly SFP (Benzinga 2026) | **91% success** (20/22 SFPs → >10% move), but n=22 |
| BTC 4H SFP + confirmation | WR rises from **45-55% to 55-60%** with next-candle confirmation |
| CVD divergence (S&P E-mini futures) | Precedes reversal **65-75%** of the time |
| VP POC reversion (FuturesHive) | **75%+ WR** in ranging markets |
| SMC consensus | Sweep + structure shift: **60-70% WR**; lone wick: ~50% |

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Regime | guessed "ranging to mild" | **ADX < 30 confirmed; ADX > 35 = genuine breakdown** |
| Wick depth | no minimum | **>= 0.3% below swing low** |
| Confirmation | same-candle | **Next-candle preferred (50% → 55-60% WR)** |
| CVD | positive+rising | **Divergence (price LL, CVD HL) = strongest** |
| VP proximity | near POC/VAL | **POC reversion 75%+ WR; key filter** |
| Timeframe | 15m untested | **1h-4h best; 15m for precision; avoid 5m** |
| Certainty | guess | **hypothesis (convergent 6-source)** |

### 5 Implementation Gaps in YujiSmartMoneyStrategy
1. **Add ADX < 30 regime filter** — currently fires in all regimes
2. **Next-candle confirmation** — `sweep_bullish.shift(1)` instead of same-candle entry
3. **CVD divergence check** — price LL + CVD HL, not just positive CVD
4. **Volume spike threshold** — raise from 0.8x to 1.2x SMA on sweep candle
5. **Evaluate secondary entry** — drops VP requirement, likely degrades WR

### Files Updated
- `knowledge/freqtrade/prims/intermediate/liquidity-sweep-reversal.md` (created)
- `knowledge/epistemic-index.md` (intermediate table updated)
- `knowledge/conditions-log.md` (naive superseded, intermediate entry added)
- Commit: `7e40f25`

### Regime Partition Complete

All 3 freqtrade prims now have regime-specific activation:

| Regime | Prim | ADX Range |
|---|---|---|
| **Ranging** | rsi-oversold-mean-reversion | ADX < 20 |
| **Ranging-to-mild-trend** | liquidity-sweep-reversal | ADX < 30 |
| **Trending** | ema-pullback-dynamic-support | ADX 25-35 |

The overlap zone (ADX 25-30) allows both sweep reversal and EMA pullback — the distinguishing factor is whether price is at a structural level (sweep) or pulling back to a moving average (EMA).
