---
name: financial-market-lead-lag
level: intermediate
project: polymarket
parent_prim: naive/financial-market-lead-lag
created: 2026-04-11
last_validated: never
superseded_by: sophisticated/financial-market-lead-lag
status: SUPERSEDED
---

## Prim: financial-market-lead-lag
**Level:** intermediate (refined from naive)
**Project:** polymarket
**Parent:** naive/financial-market-lead-lag

### Rule
**Two-mode signal (event-driven OR persistent drift):**

**Mode A — Event-Driven (post-data-release):** CME FedWatch updates ≥ 5pp directional shift on a specific meeting contract within 30 min of CPI/NFP/PCE release (or 15 min of FOMC announcement) AND equivalent PM market lags → PM bid-ask spread ≥ 2% (not bot-competed) AND gap ≥ 6% → buy PM in CME direction. Size α=0.10 Kelly floor.

**Mode B — Persistent Drift:** CME FedWatch has directionally led PM for ≥ 3 consecutive trading days with gap ≥ 8% (gap NOT closed by daily close) AND PM bid-ask ≥ 3% AND no scheduled data release within 48h → buy PM in CME direction. Size α=0.10 Kelly floor.

**Both modes require:** Single-meeting binary PM resolution (specific FOMC date, yes/no on ≥25bp bracket); PM market liquidity ≥ $10k; time-to-resolution > 2h; **NOT** multi-meeting, multi-magnitude, or conditional-timing PM questions.

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Signal timing | anytime gap ≥ 6% | **Two-mode: event-driven (5-30min window) or persistent drift (3-day CME lead)** |
| Lag characterization | "minutes to hours" (hypothesis) | **63.4% CME leads; ~1.44-day avg across full cycles (quantitative anchor)** |
| Execution competition | "bots are competing" (suspected) | **Characterized: sub-100ms bots extract 73% of PM arb; 2.52c/contract advantage; actionable window = bid-ask ≥ 2%** |
| Resolution filter | "build classifier" (gap) | **Taxonomy defined: single-meeting 25bp bracket = clean; multi-meeting/multi-magnitude/conditional = exclude** |
| Efficiency gate | none | **PM bid-ask spread ≥ 2% (Mode A); ≥ 3% (Mode B); below = bot-competed** |
| Data release trigger | not specified | **CPI/NFP/PCE within 30 min; FOMC announcement within 15 min (Mode A)** |
| Certainty | hypothesis (mechanism only) | **hypothesis (quantitative lag anchor added; execution competition characterized)** |

### Mechanism — Two-Mode Activation

**Event-driven (Mode A):** CPI/NFP/PCE prints. Institutional desks process immediately via automated pipelines (Gürkaynak 2005: fed funds futures update sub-minute). CME FedWatch re-prices the specific FOMC meeting contract within seconds. PM retail participants read the same public release but lag by 5–30 minutes of interpretation time. The lag window = the edge window before bots close it.

**Persistent drift (Mode B):** Between data releases, PMC prices drift relative to CME as retail participants weight recent news differently from futures market consensus. The 1.44-day average CME lead (Medium analysis, 63.4% of cycles) indicates this is not purely post-release — PM systematically lags CME directional signals over full cycles. Mode B targets this secular drift with higher gap threshold (8%) to justify the slower, less-contested entry.

### Evidence — 6 Sources

| Source | Finding |
|---|---|
| **Medium/PolymarketNow (FedWatch vs Polymarket analysis)** | CME FedWatch leads Polymarket **63.4% of recent FOMC cycles**; average Polymarket lag **~1.44 days**. Primary quantitative anchor (methodology undisclosed — treat as practitioner hypothesis, not peer-reviewed) |
| **Gürkaynak, Sack & Swanson (2005, AER)** | Fed funds futures update to FOMC information **sub-minute**; best available real-time predictor of policy decisions. Foundational institutional speed anchor. |
| **Snowberg, Wolfers & Zitzewitz (2007, AER P&P)** | Prediction markets and financial markets co-price political/economic events; cross-market information flow documented. PM efficiency is partial, not complete. |
| **Della Vedova (SSRN 6191618)** | Analysis of 222M PM trades: **70% of traders unprofitable**; automated traders capture **2.52c/contract execution advantage**; profitability determined by **execution quality, not information quality**. Critical negative finding: being right about CME→PM direction doesn't guarantee profit if bots front-run the entry. |
| **Reichenbach & Walther (SSRN 5910522)** | Analysis of 124M Polymarket trades: PM prices closely track realized probabilities; retail-retail arbitrage has partially corrected mispricings. Efficient for most conditions; exploitable gaps are episodic. |
| **arxiv 2508.03474 (IMDEA AFT 2025)** | **73% of PM arb profits extracted by sub-100ms bots**; $40M total April 2024–2025. Confirms execution-speed asymmetry as primary constraint, not information asymmetry. |

### Key Numbers

| Metric | Value |
|---|---|
| CME leads Polymarket | **63.4% of FOMC cycles** |
| Average Polymarket lag | **~1.44 days** (across full cycle) |
| Sub-100ms bot arb share | **73%** of total PM arb profits |
| Bot execution advantage | **2.52c/contract** vs casual traders |
| Unprofitable PM users | **70%** (Della Vedova) |
| Median PM arb spread 2025 | **0.3%** (general; Fed-market specific unknown) |
| Mode A trigger window | 30 min post CPI/NFP/PCE; 15 min post FOMC |
| Mode A minimum gap | **6%** |
| Mode B minimum gap | **8%** (compensates for slower, more uncertain entry) |
| Mode B CME lead duration | **≥ 3 consecutive trading days** |
| Efficiency gate (Mode A) | bid-ask ≥ **2%** |
| Efficiency gate (Mode B) | bid-ask ≥ **3%** |

### Conditions
- **Works when:** Genuine information diffusion lag (post-release Mode A or sustained drift Mode B); PM market NOT yet bot-competed (bid-ask ≥ gate); single-meeting binary resolution; liquidity ≥ $10k; resolution > 2h
- **Fails when:** Multi-meeting/multi-magnitude/conditional PM questions (resolution criteria divergence — **#1 failure mode**); bid-ask < threshold (bots competed, 2.52c/contract advantage not beatable); emergency/inter-meeting FOMC moves (PM social-media crowd may update faster on extreme events); gap persists > 72h without narrowing (structural pricing difference, not lag); Mode A entered without data release context (no trigger event = no lag mechanism)
- **Best pairs:** FOMC-specific binary markets ("Will Fed cut at March 2026 FOMC meeting by 25bps?") — single meeting date, ≥25bp bracket, resolves on official FOMC statement
- **Best timeframe:** Mode A: execute within 5–30 min of data release; Mode B: daily check vs CME FedWatch, execute on market open

### 8 Documented Limitations

1. **Resolution criteria mismatch (#1 failure mode)** — still no automated classifier; manual screening required. Rounding rule: "if cut is 12.5bps it counts as 25bps" creates edge cases on unexpected small moves.
2. **Execution-speed asymmetry is the binding constraint, not information** — Della Vedova (SSRN 6191618) establishes that 70% of PM traders lose not because they're wrong but because they're slow. The 2.52c/contract bot advantage may eat the entire 3% net edge post-fee.
3. **1.44-day lag source quality** — Medium analysis, methodology undisclosed. Not peer-reviewed. The 63.4% lead figure is directionally plausible but cannot be treated as evidence-grade.
4. **Lag window is time-bounded** — trajectory from hours (2023) to minutes (2025) suggests < 5 min window by 2027 for the most liquid Fed markets; Mode A may require sub-second execution within 2–3 years.
5. **CME can be wrong** — inter-meeting emergency cuts, Fed communication breakdowns; prediction markets with broad participation may be faster than CME for black-swan events (Wolfers & Zitzewitz 2007 notes this).
6. **Mode B requires market NOT repriced by news** — any CPI/NFP/FOMC event within 48h resets the persistent drift signal; Mode B is viable only in quiet inter-release periods.
7. **Friction floor** — politics category 4% fee; 6% Mode A gap → 2% net; 8% Mode B gap → 4% net. Realistic slippage on PM: 0.5–1% entry + exit. Net edge after all costs: 0.5–2% (thin).
8. **Zero own-data trades** — all numbers from external sources; forward calibration mandatory before size increase above α=0.10.

### Anti-Prim Escape Hatches (2)
- **(A) Post-release gap compression**: if 20 observed Mode A events average gap < 4% at trigger time → execution-crowding anti-prim (window closed)
- **(B) Null WR**: own-data 30 trades → WR < 55% at α=0.10 → mechanism not persistently exploitable on PM → mark anti-prim

### Implementation Gaps (5)
1. `src/signals/cme_fedwatch.py` — CME API feed for FedWatch meeting-specific probabilities
2. `src/strategies/financial_lead_lag.py` — resolution-criteria classifier (single-meeting binary detector), gap tracker (Mode A: 30-min trigger window; Mode B: 3-day rolling CME lead)
3. Data release calendar integration (CPI/NFP/PCE/FOMC dates, times, consensus estimates)
4. Efficiency gate: PM bid-ask spread computation per market (CLOB WebSocket required)
5. Anti-prim circuit-breakers (A) and (B) — log gap magnitudes at trigger, log WR from trade outcomes

### Bank State After Cycle 37

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | **0** (financial-market-lead-lag elevated from naive) |
| Intermediate | 0 | **1** (financial-market-lead-lag) |
| Sophisticated | 7 | 7 |

### Next Cycle Recommendations
**(A) RESEARCH** — find peer-reviewed evidence for Mode A vs Mode B gap distributions on Fed markets specifically (not general PM arb). Target: SSRN papers on PM-vs-futures cross-market information efficiency for monetary policy. Key question: Is the 1.44-day lag a full-cycle average driven by a few large misalignments, or is it persistent across all FOMC cycles?
**(B) BACKTEST-ANALYSIS** — Mode B is tractable from public data: Polymarket historical prices (API) + CME FedWatch historical probabilities (downloadable CSV) for 2023–2025 across all FOMC meetings. Compute gap at each daily close; flag Mode B signals (3-day CME lead, gap ≥ 8%); count events, measure gap closure by resolution. If n < 10 Mode B events in 3 years → frequency anti-prim precursor.
**(C) IMPLEMENT** — Class 3 Temporal Chain scanner on semantic-correlation-pair-trade — "Fed cuts by Q1 2026" / "Fed cuts by Q3 2026" pairs where P(T1) > P(T2) is a mathematical violation, directly related to this prim's domain, and the cheapest existing-bank test to run.

### Sources
- [Medium/PolymarketNow — FedWatch vs Polymarket: Who Leads on Rate Decisions?](https://medium.com/polymarket-now/fedwatch-vs-polymarket-2bc9cdd6239c)
- [Gürkaynak, Sack & Swanson (2005, AER) — Do Actions Speak Louder Than Words? The Response of Asset Prices to Monetary Policy Actions and Statements](https://www.federalreserve.gov/pubs/feds/2004/200466/200466pap.pdf)
- [Snowberg, Wolfers & Zitzewitz (2007, AER P&P) — Partisan Impacts on the Economy: Evidence from Prediction Markets and Close Elections](https://www.nber.org/papers/w12073)
- [Della Vedova (SSRN 6191618) — Who Profits from Prediction Markets? Evidence from 222M Trades](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=6191618)
- [Reichenbach & Walther (SSRN 5910522) — Exploring Decentralized Prediction Markets: 124M Polymarket Trades](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5910522)
- [arxiv 2508.03474 — Unravelling the Probabilistic Forest: Arbitrage in Prediction Markets (IMDEA AFT 2025)](https://arxiv.org/abs/2508.03474)
