---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T15:49:55+10:00
cycle: 172
superseded_by: intermediate (cycle 174)
---

> **SUPERSEDED** — Elevated to intermediate (cycle 174). See
> `knowledge/freqtrade/prims/intermediate/intraday-session-asymmetry-regime.md`
> for the current definition. This file is retained for historical reference only.

---

---

**Cycle 172 — RESEARCH — Complete**

---

## Prim: intraday-session-asymmetry-regime
**Level:** naive (new) | **Axis:** 28 | **Project:** freqtrade | **Commit:** `69c5549`

---

### What was produced

**Naive Rule — Session Filter:**
```
NY session     (utc_hour 13–21, weekday) → AMPLIFY 1.08×
London session (utc_hour  8–13, weekday) → NEUTRAL 1.00×
Asian + dead   (utc_hour  0–8, 21–24)   → REDUCE  0.92×
Weekends                                 → NEUTRAL 1.00×
```

Meta-signal only — no standalone entries. Broadcast via `bot_loop_start()` as `session_scalar_28`.

**Why axis 28:** All 27 prior axes treat time as homogeneous. Signal reliability is structurally different across sessions because agent composition changes. At 02:00 UTC (Asian retail, thin book) the same RSI divergence setup has meaningfully different edge properties than at 15:00 UTC (London–NY overlap, peak institutional flow). This is the first temporal regime signal in the freqtrade bank.

**Data dependency:** G_DATA_28 = UTC system clock — **CLEARED immediately**. Zero external data barrier. The first gate (G1_28A: NY vs Asian WR differential on momentum signals) can be run against any existing historical OHLCV dataset.

---

### Evidence — 5 Sources

| Source | Finding |
|--------|---------|
| **Eross/Farooq/Treepongkaruna (2019 FRL)** | BTC significant intraday seasonality; positive hourly drift concentrated 08:00–21:00 UTC; Asian session ≈ 0 or negative |
| **Caporale & Plastun (2019 FRL)** | Day-of-week effects in crypto confirmed; Monday premium +0.04%; p<0.05 across 2013–2018 |
| **Liu & Tsyvinski (2021 RFS)** | Investor attention = session-correlated; 26% annualized crypto momentum alpha driven by attention peaks during US hours |
| **Admati & Pfleiderer (1988 RFS)** | Theoretical foundation: informed traders cluster in high-liquidity windows; price discovery temporally concentrated |
| **Brauneis et al. (2022 FRL)** | Crypto efficiency measurably degrades outside institutional sessions; noise-to-signal is session-dependent |

---

### Naive Gaps (what's left for intermediate elevation)

1. DST-aware UTC boundary calculation (US/Europe clock shifts ±1h twice/year)
2. Trend-regime interaction (ADX > 30 may invert session effect direction)
3. Day-of-week modulation (Monday premium, Friday selling not yet captured)
4. Per-signal-type scalar tuning (RSI, CVD, VWAP likely have different session sensitivities)
5. Pair-specific session profile (ETH institutional participation differs from BTC)

---

### Bank State After Cycle 172

| Tier | Freqtrade | Note |
|------|-----------|------|
| Naive | **24** (+1) | axis 28 added |
| Intermediate | 27 | unchanged |
| Sophisticated | 32 | unchanged |

**28 freqtrade regime axes defined.**
