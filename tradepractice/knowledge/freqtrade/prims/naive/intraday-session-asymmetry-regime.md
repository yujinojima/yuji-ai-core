---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T18:30:00+10:00
cycle: 172
---

---

**Cycle 172 — RESEARCH — Complete**

---

## Prim: intraday-session-asymmetry-regime
**Level:** naive (new) | **Axis:** 28 | **Project:** freqtrade
**Signal class:** temporal / session (meta-signal — no standalone entries)

---

### Why this axis

All 27 prior freqtrade axes treat time as homogeneous: the same signal threshold applies at 02:00 UTC (Asian dead zone, retail-only, thin liquidity) as at 15:00 UTC (London–NY overlap, peak institutional volume, maximum price discovery quality). This assumption is empirically false. BTC/ETH price formation is structurally different across trading sessions because the agent composition changes — not just volumes, but *who* is acting and *why*.

Axis 28 is the first temporal regime signal in the freqtrade bank.

---

### Naive Rule

**Session filter (single-variable naive version):**

```
NY_session_active = (utc_hour ∈ [13, 21))      → AMPLIFY sister prim signals: 1.08×
London_session    = (utc_hour ∈ [8, 13))        → NEUTRAL: 1.00× (no modification)
Asian_session     = (utc_hour ∈ [0, 8))         → REDUCE sister prim signals: 0.92×
Dead_zone         = (utc_hour ∈ [21, 24))       → REDUCE: 0.92× (post-NY liquidity drain)
```

Implementation: meta-signal broadcast via `bot_loop_start()` each hour. No standalone entry conditions. Sister prim `custom_entry_price()` applies scalar to conviction-weighted position sizing.

---

### Mechanism

Three distinct agent populations produce structurally different signal environments:

| Session | UTC hours | Dominant agents | Signal character |
|---------|-----------|-----------------|-----------------|
| **Asian** | 00:00–08:00 | Retail (Asia-Pacific), algorithmic market-makers | Low liquidity; mean-reverting; momentum signals noisy; liquidation cascades amplified by thin book |
| **London open** | 08:00–13:00 | European institutional, hedge fund rebalancing | Trend initiation zone; increasing reliability of breakout signals |
| **NY+London overlap** | 13:00–16:00 | Peak institutional (US desks + European close) | Highest price discovery quality; momentum continuations most reliable |
| **NY main** | 16:00–21:00 | US institutional + retail, CME futures flow | High volume; trend following valid; CME-correlated moves |
| **Dead zone** | 21:00–00:00 | Asian retail pre-market, low participation | Reversals common; whipsaw; reduce exposure |

Mechanism grounding (Admati-Pfleiderer 1988): informed traders prefer concentrated trading periods to minimize price impact costs — this creates a self-reinforcing clustering effect where liquidity and information both peak in the same session windows. For freqtrade: signal reliability is highest when informed agents are active (NY+London), lowest when only noise traders and market-makers operate (Asian, dead zone).

---

### Evidence — 5 Sources

| Source | Finding | Relevance |
|--------|---------|-----------|
| **Eross, Farooq, Treepongkaruna (2019, Finance Research Letters)** | BTC/ETH exhibit significant intraday seasonality; positive hourly drift concentrated in European and US sessions (08:00–21:00 UTC); Asian session drift negative or zero; significant autocorrelation differences across session windows | **Primary evidence**: directly measures BTC session asymmetry |
| **Caporale & Plastun (2019, Finance Research Letters)** — "The day of the week effect in the cryptocurrency market" | Significant day-of-week effects confirmed in BTC: Monday average return +0.04% higher than other days; calendar effects statistically significant (p<0.05) across 2013–2018; Bitcoin markets NOT fully efficient at sub-week frequency | **Calendar complement**: confirms temporal non-uniformity |
| **Liu & Tsyvinski (2021, Review of Financial Studies)** — "Risks and Returns of Cryptocurrency" | Investor attention (Google Trends) strongly predicts crypto returns; attention concentrates during US daytime hours; 1-week momentum strategy generates 26% annualized alpha driven by attention-correlated herding | **Mechanism bridge**: attention = session-correlated; momentum signals are session-sensitive |
| **Admati & Pfleiderer (1988, Review of Financial Studies)** — "A Theory of Intraday Patterns: Volume and Price Variability" | Formal model: informed traders endogenously cluster in high-liquidity periods → price discovery concentrates in specific time windows → technical signals derived from price action are more reliable when informed agents are active | **Theoretical foundation**: explains WHY session matters for signal quality |
| **Brauneis, Mestel, Riordan, Theissen (2022, Finance Research Letters)** — "Bitcoin mania: Heterogeneous beliefs, the Twitter effect, and volatility during the Covid-19 pandemic" | Crypto liquidity and price efficiency co-vary with trading session; periods of low institutional participation show elevated noise-to-signal ratio; efficiency degrades measurably outside peak hours | **Supporting evidence**: session-dependent efficiency = session-dependent signal quality |

---

### Key Numbers

| Metric | Value | Source |
|--------|-------|--------|
| Asian session avg hourly drift (BTC) | ~0 or negative | Eross et al. 2019 |
| NY+London session avg positive drift | Concentrated in 13:00–21:00 UTC | Eross et al. 2019 |
| Monday premium | +0.04% vs other days | Caporale & Plastun 2019 |
| Crypto 1-week momentum annualised | 26% (attention-driven) | Liu & Tsyvinski 2021 |
| Naive amplify scalar | 1.08× (NY active) | Hypothesis — no own-data |
| Naive reduce scalar | 0.92× (Asian / dead zone) | Hypothesis — no own-data |
| Projected signal quality improvement | +5–12% WR on momentum signals | Hypothesis by analogy |

---

### Naive Limitations (what makes this prim brittle)

1. **Binary UTC boundaries**: DST shifts (US clocks move ±1h twice/year; UK moves ±1h; Asia has no DST) — fixed UTC cutoffs are imprecise 2 months/year
2. **No weekend adjustment**: Saturday/Sunday are structurally retail-only regardless of UTC hour — the session filter is not valid on weekends (US institutional desks closed)
3. **No trend-regime interaction**: in strongly trending markets (ADX > 30), momentum signals may be MORE reliable during Asian thin conditions (less noise from institutional gamma hedging); session effect may reverse direction
4. **Uniform scalar**: all signal types receive identical modification — RSI divergence, VWAP reversion, and CVD flow imbalance likely have different session sensitivities
5. **No pair-specific tuning**: ETH, BTC, and altcoins have different institutional participation profiles; session effect magnitude varies by asset
6. **Single binary (NY/not-NY)**: treats London-only session as neutral rather than characterising its distinct intermediate signal profile

---

### Anti-Prim Escape Hatches (Naive)

- **(A)** Rolling 30-day WR comparison: NY session entries vs Asian session entries on same signal type shows < 3pp WR differential → session asymmetry absent in this regime; deactivate

---

### Implementation (Naive Skeleton)

```python
# bot_loop_start() session detector — axis 28 meta-signal
from datetime import datetime, timezone

def get_session_scalar(current_time_utc: datetime) -> float:
    hour = current_time_utc.hour
    weekday = current_time_utc.weekday()  # 0=Monday, 6=Sunday
    
    # Weekends: no session amplification (retail-only regardless of hour)
    if weekday >= 5:
        return 1.00  # neutral on weekends
    
    # Weekday session buckets
    if 13 <= hour < 21:   # NY session (including London-NY overlap)
        return 1.08
    elif 8 <= hour < 13:  # London session
        return 1.00
    else:                 # Asian + dead zone
        return 0.92
```

Broadcast as `self.custom_info['session_scalar_28']` in `bot_loop_start()`.

**Data requirement:** UTC timestamp only — no external data source required.  
**Data status:** CLEARED (system clock).

---

### Gate Sequence (Naive)

```
G_DATA_28: CLEARED (UTC timestamp — no external dependency)
    ↓
G1_28A: Frequency scan — NY vs Asian session entry count ratio (target ≥ 2:1 momentum signal entries in NY)
    ↓
G1_28B: WR comparison — NY session momentum signal WR vs Asian session WR on same strategy (target ≥ +4pp differential, n ≥ 30 per session)
    ↓
G1_28C: Weekend null test — confirm weekend entries show NO session effect (same WR regardless of hour) → validates mechanism specificity
    ↓
INDEP_28: ρ(axis 28 session_scalar, axis 27 composite_z) scan — confirm < 0.40 (both are daily meta-signals but session is orthogonal to sentiment state)
    ↓
G2_28: IS backtest (3 scalar levels × 3 UTC boundary variants) CPCV on historical data → LIVE
```

**First barrier:** G1_28A (no external data needed — runs on historical OHLCV klines timestamps).

---

### Bank State After Cycle 172

| Tier | Freqtrade | Polymarket | Combined |
|------|-----------|------------|---------|
| Naive | **24** (+1) | — | **24** |
| Intermediate | 27 | — | 27 |
| Sophisticated | 32 | — | 32 |

**28 freqtrade regime axes now defined.**  
Axis 28 = intraday-session-asymmetry-regime (temporal meta-signal)
