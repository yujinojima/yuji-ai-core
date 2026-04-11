---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T18:35:19+10:00
cycle: 36
---

---

## Prim: financial-market-lead-lag
**Level:** ~~naive~~ — **SUPERSEDED** by intermediate/financial-market-lead-lag (cycle 37)
**Project:** polymarket
**Parent:** none
**Commit:** `e372ee1`

### Rule
When CME FedWatch implied probability for an FOMC meeting diverges from the equivalent Polymarket market price by ≥ 6%, buy Polymarket in the CME-predicted direction. Size via fractional-kelly-sizing α=0.10 (uncalibrated mandatory floor).

### Mechanism
Federal funds futures are traded by institutional desks (banks, hedge funds) who process CPI/NFP/PCE/FOMC data sub-minute via automated pipelines. CME FedWatch converts these futures into FOMC meeting-specific rate-change probabilities. Polymarket Fed rate markets are priced by retail participants who access the same public data but lag institutional interpretation by minutes to hours. The lag window is the edge.

This is the **8th distinct prim class** — first to use external institutional financial market data as a leading indicator. All 7 existing sophisticated prims exploit data internal to prediction market infrastructure (CLOBs, cross-venue pricing, NWP models, logical consistency). None uses traditional financial markets.

### Evidence
- **Source:** paper (adjacent financial economics)
- **Certainty:** hypothesis — mechanism well-supported; cross-market PM application untested
- **Data:** 0 own trades; 0 own backtest
- **Academic anchors:**
  - **Gürkaynak, Sack & Swanson (2005, AER)** — fed funds futures update to FOMC information sub-minute; best available real-time predictor of policy decisions
  - **Snowberg, Wolfers & Zitzewitz (2007, AER P&P)** — prediction markets and financial markets co-price political/economic events; cross-market information flow documented

### Key Limitations (6)
1. **Resolution criteria divergence (#1 failure mode)** — CME prices specific meeting date; PM questions vary ("at least one cut in 2026," "50bps cut by Q2") — no automated mapping exists; must build classifier before any trade
2. **Lag window compressing** — ~hours (2023) → ~30 min (2025); trajectory toward sub-5 min by 2027 for liquid Fed markets; time-bounded, not structural
3. **CME can be wrong** — emergency cuts, inter-meeting moves; tail events where PM social-media crowd may actually update faster
4. **Friction floor** — politics category 4% fee → net floor ~3%; 6% gap leaves ~3% net after fees + slippage; signal frequency likely low post-2025
5. **No implementation** — no CME API integration in polymarket-bot
6. **Scope extension unvalidated** — principle applies to VIX → PM election markets, Treasury futures → PM government markets, but each requires separate mapping

### Prim Status — All 8 Polymarket Prims

| Prim | Level |
|------|-------|
| binary-arb-completeness | sophisticated |
| spread-capture-market-making | sophisticated |
| fractional-kelly-sizing | sophisticated |
| ensemble-forecast-edge | sophisticated |
| obi-informed-directional | sophisticated |
| cross-venue-semantic-arb | sophisticated |
| semantic-correlation-pair-trade | sophisticated |
| **financial-market-lead-lag** | **naive ← this cycle** |

### Next Cycle Recommendations
1. **(A) RESEARCH: Elevate financial-market-lead-lag to intermediate** — find papers directly testing CME FedWatch vs prediction market lag (e.g., SSRN papers on PM information efficiency for Fed decisions); quantify historical lag distribution from CPI/NFP releases (scrape CME + PM historical data); build resolution-criteria taxonomy (PM question types that map cleanly to CME contracts vs those that don't)
2. **(B) BACKTEST-ANALYSIS: semantic-correlation-pair-trade Class 3 Temporal Chain scanner** — scan current Polymarket for "Fed cuts by Q1" / "Fed cuts by Q2" type pairs where P(T1) > P(T2) (mathematical violation); log historical violations; estimate convergence rate and magnitude — this is also the most tractable backtest target in the existing sophisticated prim bank
3. **(C) RESEARCH: Financial-market-lead-lag scope extension** — map which PM categories have analogous institutional market instruments: (Fed decisions → CME FedWatch); (US equity direction → VIX term structure); (election outcomes → S&P election-year options) — scope extension table for intermediate refinement
