---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T15:40:39+10:00
cycle: 27
---

---

## Prim: capitulation-exhaustion-reversal
**Level:** sophisticated (refined from intermediate)
**Project:** freqtrade
**Parent:** intermediate/capitulation-exhaustion-reversal
**Commit:** `2c6c585`

### What Changed from Intermediate

| Dimension | Intermediate | Sophisticated |
|---|---|---|
| Speed gate | 15%/≤5 bars (single, untuned) | **Dual window: 10%/≤5 bars (mature-market) OR 15%/≤10 bars (legacy crash)** |
| Signal frequency | "< 5/year estimated" | **Quantified: 1-2/year BTC alone; 5-10/year on 5-pair pool** |
| Deployment | BTC + ETH implied | **Formal 5-pair minimum required for statistical viability** |
| Statistical framework | "3+ years minimum" | **Power analysis: N_eff ≈ 1.3/panic (ρ=0.90); n_eff=50 requires 4-8y multi-asset** |
| Position sizing | implied fixed stop | **Dynamic: 2% bankroll / |entry − wick_low|** |
| R:R | unspecified | **≥ 1:3 mandatory** (wick stops are 20-30% wide) |
| Friction model | not quantified | **~47% Sharpe erosion; slippage-dominant for rare-event holds** |
| Parameter grid | 4 untuned | **27-cell plateau test (3×3×3); DSR required (>20 cells)** |
| Market maturation | not addressed | **Structural anti-prim risk quantified: crash amplitude 87%→84%→77%→50%** |
| Anti-prim escapes | implied | **3 formal escape hatches** |
| Certainty | hypothesis | **hypothesis (structured, bounded, ZERO positive quantitative anchor)** |

### Key New Findings

| Source | Finding |
|---|---|
| **arxiv 2304.09939** (Bitcoin: A life in crises, Tarassov & Houlié) | ≥10 Bitcoin crisis events 2010-2021 = **~0.9 cycle-level crashes/year**; 1-3 capitulation wick events per crash |
| **CoinDesk April 1, 2026** | **"Bitcoin's crashes are shrinking every cycle"** — 2013: −87%, 2017: −84%, 2022: −77%, 2026: −50%; institutional ETF participation creating buy-the-dip floors → **structural anti-prim risk** |
| **backtestbase.com + power literature** | n=200-300 minimum for meaningful metrics; n=50 at 95% CI = ±14% WR margin; **multi-asset pooling mandatory to reach statistical floor within deployable timeframe** |
| **PMC6599809 LPPLS** | 24 bubble events across 8 cryptos / 4.5 years; super-exponential decline conceptual validation for speed gate as crash-vs-trend discriminator |

### Key Numbers

| Metric | Value |
|---|---|
| BTC 1h qualifying signal frequency | **1-2/year** |
| 5-pair pool signal frequency | **5-10/year** |
| N_eff per panic event (ρ≈0.90) | **≈1.3 independent** (N/(1+(N-1)×0.90)) |
| Deployment window for n_eff=50 | **4-8 years multi-asset** |
| WR margin of error at n=50 | ±14% (95% CI) |
| Crash amplitude trend | 87%→84%→77%→50% (declining per cycle) |
| R:R requirement | ≥ 1:3 |
| Friction Sharpe erosion | ~47% (slippage-dominant) |
| Parameter grid | 27 cells (3×3×3) |

### Anti-Prim Escape Hatches (3 Formal)
- **(A) Frequency collapse**: n < 15 signals in 5y across 5-pair pool → maturation anti-prim
- **(B) Plateau fails**: no cell with WR > 55% across 27-cell grid → mechanism anti-prim
- **(C) Live WR < 48%** over first 30 events → efficiency anti-prim

### Critical Limitation
**ZERO peer-reviewed crypto anchor at any tier.** The only sophisticated freqtrade prim with no positive quantitative anchor of any kind. Sophisticated tier means failure modes are quantified and anti-prim escape hatches are formalized — NOT that the prim works. Deployment blocked pending: (a) raw regime-gated signal count on BTC/ETH 1h 2020-2025 — if n < 15, frequency anti-prim (A) triggered before plateau test can run; (b) if n ≥ 15, proceed to 27-cell plateau test + DSR correction.

### Bank State After Cycle 27

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | 0 |
| Intermediate | **0** | 1 (obi-informed-directional) |
| Sophisticated | **6** (rsi-oversold, ema-pullback, liq-sweep, bullish-rsi-div, hidden-div, **capitulation-exhaustion NEW**) | 4 |

6-axis freqtrade regime partition is now complete.

### Next Cycle Recommendation
**(A) IMPLEMENT** — 9-gap implementation in `YujiExtinctionBurstStrategy.py` + signal count on historical data (if n < 15 in 5y, frequency anti-prim A immediately triggered).
**(B) RESEARCH** — elevate obi-informed-directional from intermediate to sophisticated (4 sources at intermediate; clear research gaps: OBI decay quantification, hold-horizon evidence, wash-filter WR improvement data, market efficiency compression rate for microstructure signals).

Recommend **(A)** first — signal count is the binary gate that determines whether (B) becomes the higher-priority path.

### Sources
- [arxiv 2304.09939 — Bitcoin: A life in crises](https://arxiv.org/abs/2304.09939)
- [CoinDesk Apr 2026 — Bitcoin's crashes are shrinking](https://www.coindesk.com/markets/2026/04/01/bitcoin-s-crashes-are-shrinking-and-wall-street-is-starting-to-notice)
- [PMC6599809 — Bitcoin bubbles predictable? LPPLS model](https://pmc.ncbi.nlm.nih.gov/articles/PMC6599809/)
- [MDPI Stats 4(4) 2021 — Bitcoin Bubbles and Crashes Detection](https://www.mdpi.com/2571-905X/4/4/56)
- [backtestbase.com — Minimum trades for a valid backtest](https://www.backtestbase.com/education/how-many-trades-for-backtest)
- [PMC9920669 — RSI signals cryptocurrency](https://pmc.ncbi.nlm.nih.gov/articles/PMC9920669/)
- [BSIC — Transaction Cost Modelling](https://bsic.it/backtesting-series-episode-5-transaction-cost-modelling/)
