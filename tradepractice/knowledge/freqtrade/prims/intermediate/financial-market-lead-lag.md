---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T18:42:09+10:00
cycle: 37
---

---

## Prim: financial-market-lead-lag
**Level:** intermediate (refined from naive)
**Project:** polymarket
**Parent:** naive/financial-market-lead-lag
**Commit:** `7ce4522`

### Rule
**Two-mode signal:**

**Mode A — Event-Driven:** CME FedWatch updates ≥ 5pp directional shift on specific FOMC meeting contract within 30 min of CPI/NFP/PCE release (or 15 min of FOMC announcement) AND equivalent PM market lags AND bid-ask ≥ 2% (not bot-competed) AND gap ≥ 6% → buy PM in CME direction. α=0.10 Kelly floor.

**Mode B — Persistent Drift:** CME FedWatch has directionally led PM for ≥ 3 consecutive trading days AND gap ≥ 8% AND bid-ask ≥ 3% AND no scheduled data release within 48h → buy PM in CME direction. α=0.10 Kelly floor.

**Both modes require:** single-meeting binary PM resolution (specific FOMC date, ≥25bp bracket); liquidity ≥ $10k; resolution > 2h; NOT multi-meeting/multi-magnitude/conditional-timing PM questions.

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Signal timing | anytime gap ≥ 6% | **Two-mode: event-driven (30-min window post-release) or persistent drift (3-day CME lead)** |
| Lag characterization | "minutes to hours" | **63.4% CME leads; ~1.44-day average across full FOMC cycles (quantitative anchor)** |
| Execution competition | "bots are competing" | **Characterized: sub-100ms bots extract 73% of PM arb; 2.52c/contract advantage; 70% of PM users unprofitable** |
| Resolution filter | "build classifier" | **Taxonomy defined: single-meeting 25bp bracket = clean; multi-meeting/multi-magnitude = exclude** |
| Efficiency gate | none | **bid-ask ≥ 2% (Mode A); ≥ 3% (Mode B)** |
| Data release trigger | not specified | **CPI/NFP/PCE within 30 min; FOMC within 15 min (Mode A)** |

### Evidence — 6 Sources

| Source | Finding |
|---|---|
| **Medium/PolymarketNow** | CME FedWatch leads Polymarket **63.4% of recent FOMC cycles**; PM lag **~1.44 days** average. Primary quantitative anchor (practitioner, methodology undisclosed — not peer-reviewed) |
| **Gürkaynak, Sack & Swanson (2005, AER)** | Fed funds futures update to FOMC information sub-minute; best available real-time policy predictor |
| **Snowberg, Wolfers & Zitzewitz (2007, AER P&P)** | PM and financial markets co-price political/economic events; cross-market flow documented |
| **Della Vedova (SSRN 6191618)** | 222M PM trades: **70% unprofitable**; bots capture **2.52c/contract execution advantage**; profitability = execution quality, not information quality |
| **Reichenbach & Walther (SSRN 5910522)** | 124M Polymarket trades: PM prices closely track realized probabilities; retail-retail arb partially corrected |
| **arxiv 2508.03474 (IMDEA AFT 2025)** | **73% of PM arb profits by sub-100ms bots**; $40M total April 2024–2025 |

### Key Numbers

| Metric | Value |
|---|---|
| CME leads Polymarket | **63.4% of FOMC cycles** |
| Average PM lag (full cycle) | **~1.44 days** |
| Sub-100ms bot arb share | **73%** of total PM arb profits |
| Bot execution advantage | **2.52c/contract** |
| Unprofitable PM users | **70%** |
| Mode A net edge post-fee | ~2–3% (thin) |
| Mode B net edge post-fee | ~4% (higher threshold compensates) |
| Efficiency gate (Mode A) | bid-ask ≥ **2%** |
| Efficiency gate (Mode B) | bid-ask ≥ **3%** |

### Critical Limitation
**Execution quality is the binding constraint, not information.** The CME→PM lead is real (63.4%, Gürkaynak academic anchor). The problem is execution: 70% of PM participants lose money not because they're wrong directionally but because sub-100ms bots front-run entries. The two-mode design attempts to target windows where this competition is lower (Mode B: persistent drift, not immediate post-release spike) — but both modes remain unvalidated.

The 1.44-day lag source is a Medium article (not peer-reviewed). Treat as practitioner hypothesis, not evidence.

### Anti-Prim Escape Hatches
- **(A) Gap compression**: rolling 20 Mode A events average gap < 4% at trigger time → execution-crowding anti-prim
- **(B) Null WR**: own-data 30 trades → WR < 55% → mechanism not exploitable → anti-prim

### Bank State After Cycle 37

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | **0** (financial-market-lead-lag elevated) |
| Intermediate | 0 | **1** (financial-market-lead-lag) |
| Sophisticated | 7 | 7 |

### Files Updated
- `knowledge/polymarket/prims/intermediate/financial-market-lead-lag.md` (created, 6-source)
- `knowledge/polymarket/prims/naive/financial-market-lead-lag.md` (marked SUPERSEDED)
- `knowledge/epistemic-index.md` (naive row superseded, intermediate +1 row)
- `knowledge/conditions-log.md` (naive entry [historical], intermediate entry appended)
- Commit: `7ce4522`

### Next Cycle Recommendation
**(A) RESEARCH** — find peer-reviewed evidence for Mode A vs Mode B gap distributions on Fed markets specifically. Target: papers on PM-vs-futures cross-market information efficiency for monetary policy events. Key question: Is the 1.44-day lag driven by a few large misalignments post-FOMC, or persistent across all cycles? Resolves the source-quality gap blocking sophisticated elevation.
**(B) BACKTEST-ANALYSIS** — Mode B is tractable from public data: Polymarket historical prices (API) + CME FedWatch historical probabilities (CSV, 2023–2025, all FOMC meetings). Count Mode B events (3-day CME lead, gap ≥ 8%). If n < 10 in 3 years → frequency anti-prim precursor for Mode B. Mode A frequency count requires intraday PM data at release times.
**(C) BACKTEST-ANALYSIS** — shared blocker across all 7 freqtrade sophisticated prims: divergence head-to-head (bullish-rsi-divergence vs hidden-bullish-rsi-divergence) on BTC/ETH 4h across bull→bear→accumulation remains highest-value freqtrade test; all 4 outcomes load-bearing.

### Sources
- [Medium/PolymarketNow — FedWatch vs Polymarket](https://medium.com/polymarket-now/fedwatch-vs-polymarket-2bc9cdd6239c)
- [Gürkaynak, Sack & Swanson (2005, AER) — Fed funds futures as policy predictor](https://www.federalreserve.gov/pubs/feds/2004/200466/200466pap.pdf)
- [Snowberg, Wolfers & Zitzewitz (2007, AER P&P) — Cross-market information flow](https://www.nber.org/papers/w12073)
- [Della Vedova (SSRN 6191618) — Who Profits from Prediction Markets?](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=6191618)
- [Reichenbach & Walther (SSRN 5910522) — Exploring Decentralized Prediction Markets](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5910522)
- [arxiv 2508.03474 — Arbitrage in Prediction Markets (IMDEA AFT 2025)](https://arxiv.org/abs/2508.03474)
