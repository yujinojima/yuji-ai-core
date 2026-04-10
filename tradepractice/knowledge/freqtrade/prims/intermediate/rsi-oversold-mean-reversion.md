---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T13:24:03+10:00
cycle: 3
---

---

## Prim: rsi-oversold-mean-reversion
**Level:** intermediate (refined from naive)
**Project:** freqtrade
**Parent:** naive/rsi-oversold-mean-reversion

### Rule
RSI(14) < 30 + **RANGING regime** (ADX < 20, BB width compressed) + price > 1h EMA200 + confirming oscillator (MFI/Stoch/BB) + volume > 0.8x SMA → long to BB middle. **Do NOT use in trending crypto markets.**

### Critical Finding

**RSI mean reversion does not work on crypto without regime gating.** Three independent sources converge:

| Source | Finding |
|---|---|
| PMC9920669 (10 cryptos, 1,462 days) | RSI < 30 mean reversion: **177.7%** vs 275.2% buy-and-hold (**underperforms by 97.5pp**) |
| Same study | RSI > 50 momentum: **773.6%** vs 275.2% (**outperforms 4.4x**) |
| Same study | RSI < 30 bounce: 8/10 positive at 1 day, **only 3/10 at 60 days** |
| AtomicScript BTC backtest | 4h timeframe best: Sharpe **5.13**, WR 60%, PF 2.09 |
| Briplotnik (2026) | BTC-neutral mean reversion Sharpe **2.3** post-2021 (choppy/ranging regime) |

**Key insight:** Mean reversion dominates in ranging markets; momentum dominates in trending markets. The regime gate is the activation condition.

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| **Regime** | "works in ranging" (guessed) | **RANGING ONLY** (confirmed by academic study) |
| **Trending** | "fails in downtrend" (suspected) | **Confirmed failure — underperforms passive by 97.5pp** |
| **Timeframe** | "untested" | **4h best (Sharpe 5.13), 5m lethal (WR 34.7%)** |
| **Pairs** | "untested" | **BTC/ETH preferred** (institutional algo activity) |
| **Evidence** | anecdote | **Academic paper + community backtests** |
| **Certainty** | guess | **hypothesis** (convergent multi-source) |

### Implementation Gap Found

**YujiRegimeStrategy** already regime-gates correctly (`regime_ranging == 1`).
**YujiMultiSignalStrategy buy_1** fires RSI < 30 in ANY regime with only an HTF guard — **this is the primary failure mode that needs fixing.**

### Files Updated
- `knowledge/freqtrade/prims/intermediate/rsi-oversold-mean-reversion.md` (created)
- `knowledge/epistemic-index.md` (intermediate table added)
- `knowledge/conditions-log.md` (naive superseded, intermediate entry added)
- Commit: `b0773cc`
