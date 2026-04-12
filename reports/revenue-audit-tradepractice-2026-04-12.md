# Revenue Audit: Tradepractice Knowledge Base
**Date:** 2026-04-12 | **Auditor:** Money Maker Agent | **Tag:** REVENUE-DIRECT

---

## 1. ICE Scores — All 41 Sophisticated Prims

### Scoring Key
- **Impact (I):** Annual revenue potential if prim works as theorized (1=negligible, 10=$50k+/yr)
- **Confidence (C):** Evidence strength + backtest results + academic grounding (1=pure speculation, 10=proven profitable)
- **Ease (E):** Proximity to deployment (1=years away, 10=deploy today)
- **ICE = I x C x E** (max 1000)

### Freqtrade (21 prims)

| # | Prim | I | C | E | ICE | Status |
|---|------|---|---|---|-----|--------|
| 1 | bollinger-squeeze-breakout | 5 | 3 | 4 | 60 | Backtest needed; CPCV+DSR blocking |
| 2 | bullish-rsi-divergence | 4 | 2 | 3 | 24 | Published NEGATIVE evidence (PMC9920669); elevated to document failure |
| 3 | capitulation-exhaustion-reversal | 3 | 1 | 1 | 3 | ZERO positive anchor; 4-8yr validation; declining crash amplitude |
| 4 | cross-venue-semantic-arb | 4 | 2 | 2 | 16 | 3-8 events/yr; Kalshi Rule 6.3(c) loss model; hypothesis |
| 5 | dealer-gamma-exposure-regime-signal | 5 | 3 | 3 | 45 | Evidence (analytical); D1/D2 data quality BLOCKING |
| 6 | ema-pullback-dynamic-support | 5 | 4 | 5 | 100 | Best evidence base (8 sources); ATR stop kills edge known; underperforms B&H |
| 7 | ensemble-forecast-edge (FT) | 4 | 2 | 2 | 16 | Crypto variant; low relevance |
| 8 | fair-value-gap-price-discovery | 5 | 3 | 4 | 60 | CVD gate added; no own backtest yet; strong academic base |
| 9 | financial-market-lead-lag (FT) | 3 | 2 | 2 | 12 | Cross-listed with PM; low signal frequency |
| 10 | funding-rate-crowding-reversal | 6 | 4 | 5 | 120 | Suppression signal; cheapest validation test in bank |
| 11 | **hidden-bullish-rsi-divergence** | 0 | 0 | 0 | **0** | **ANTI-PRIM: 28/28 cells WR 27-40%, PF=0 across all. DEAD.** |
| 12 | liquidity-sweep-reversal | 6 | 4 | 4 | 96 | Best quant anchor (n=2,847, 68% WR); live PF 1.51 benchmark; no own backtest |
| 13 | long-short-ratio-contrarian | 5 | 3 | 4 | 60 | Suppression signal; tiered ADX gate; needs conditional WR test |
| 14 | oi-price-divergence-signal | 5 | 3 | 3 | 45 | 8 blocking gates; Coinglass data needed |
| 15 | options-iv-skew-regime-signal | 4 | 2 | 2 | 16 | Deribit data dependency; sparse crypto options market |
| 16 | perp-spot-basis-divergence | 5 | 3 | 4 | 60 | Data available on Kraken/Binance; needs implementation |
| 17 | realized-volatility-term-structure | 4 | 3 | 3 | 36 | Regime overlay; mid-priority |
| 18 | resolution-confirmation-arbitrage | 3 | 2 | 3 | 18 | Cross-listed PM; thin |
| 19 | rsi-oversold-mean-reversion | 4 | 3 | 4 | 48 | Classic; well-documented failure modes |
| 20 | semantic-correlation-pair-trade | 4 | 2 | 2 | 16 | LLM-dependent; Class 3 temporal chain most promising |
| 21 | vwap-deviation-mean-reversion | 5 | 3 | 5 | 75 | ONLY prim with confirmed own-data point (naive WR 67.2%); ALL subsequent backtests NEGATIVE (PF 0.04-0.78) |

### Polymarket (20 prims)

| # | Prim | I | C | E | ICE | Status |
|---|------|---|---|---|-----|--------|
| 1 | anchor-event-recency-bias-fade | 5 | 3 | 3 | 45 | GDELT calibration BLOCKING; N_eff Kelly good |
| 2 | binary-arb-completeness | 4 | 3 | 4 | 48 | Gap age median 2.7s (2024: 12.3s); 73% profits by <100ms bots; STRUCTURAL DECAY |
| 3 | category-base-rate-neglect-fade | 6 | 3 | 3 | 54 | 6-gate sequence; survivorship bias correction strong; Gate 0 BLOCKING |
| 4 | cross-venue-semantic-arb | 5 | 3 | 2 | 30 | 3 empirical cases; 5-type classifier; 3-8 events/yr |
| 5 | ensemble-forecast-edge (PM) | 6 | 4 | 4 | 96 | Weather markets; edge compressing 30%/yr; EMOS pipeline specified |
| 6 | favourite-longshot-bias-fade | 7 | 5 | 6 | **210** | Strongest PM prim. Mode A tail: YES $0.03-0.05 geopolitics. Academic base rock solid. Low complexity. |
| 7 | financial-market-lead-lag (PM) | 5 | 3 | 3 | 45 | fomc_pm_mapper.py BLOCKING; 4-7 signals/yr |
| 8 | fractional-kelly-sizing | - | - | - | N/A | Sizing framework, not signal; supports all prims |
| 9 | institutional-expert-consensus-reversion | 5 | 3 | 2 | 30 | Bloomberg API BLOCKING; N=0 trades |
| 10 | llm-ensemble-probability-edge | 7 | 4 | 4 | **112** | PolySwarm arxiv shows + alpha on PM; RMSE-tiered Kelly; N>=30 calibration BLOCKING |
| 11 | low-friction-venue-lead | 5 | 3 | 3 | 45 | Granger test formalized; 3-tier confidence |
| 12 | news-velocity-informed-directional | 6 | 3 | 4 | 72 | GDELT + wire-service filter; sentiment gate; actionable |
| 13 | no-event-time-decay-fade | 7 | 4 | 4 | **112** | Actuarial model; Lambda calibration BLOCKING but data available via Gamma API |
| 14 | obi-informed-directional | 5 | 2 | 3 | 30 | Single-source 58% WR; thin evidence |
| 15 | political-hedge-instrument-signal | 4 | 2 | 2 | 16 | Niche; low frequency |
| 16 | resolution-confirmation-arbitrage | 4 | 3 | 5 | 60 | Bot running but category filter too restrictive; 0 signals live |
| 17 | semantic-correlation-pair-trade | 5 | 3 | 2 | 30 | Class 3 temporal chain most promising |
| 18 | spread-capture-market-making | 5 | 3 | 3 | 45 | Passive income model; latency competitive |
| 19 | superforecaster-consensus-lead | 6 | 3 | 3 | 54 | metaculus_pm_matcher.py BLOCKING |
| 20 | wallet-reputation-directional | 4 | 2 | 2 | 16 | Blockchain data pipeline heavy |

---

## 2. Top 10 Prims by ICE Score

| Rank | Prim | System | ICE | Key Advantage |
|------|------|--------|-----|---------------|
| **1** | **favourite-longshot-bias-fade** | PM | **210** | Decades of academic evidence; simplest mechanism; lowest implementation cost |
| **2** | **funding-rate-crowding-reversal** | FT | **120** | Suppression signal (improves ALL other prims); cheapest validation test |
| **3** | **llm-ensemble-probability-edge** | PM | **112** | PolySwarm shows real PM alpha; 70% of PM accounts lose (favourable venue) |
| **4** | **no-event-time-decay-fade** | PM | **112** | Actuarial/Poisson model; clear math; Gamma API data accessible |
| **5** | **ema-pullback-dynamic-support** | FT | **100** | 8 independent sources; concrete filters; realistic WR bounds |
| **6** | **liquidity-sweep-reversal** | FT | **96** | n=2,847 external validation; live benchmark PF 1.51 |
| **7** | **ensemble-forecast-edge** | PM | **96** | Weather = repeatable; NWP calibration quantified; but edge compressing fast |
| **8** | **vwap-deviation-mean-reversion** | FT | **75** | Only prim with own-data; but ALL backtests losing money |
| **9** | **news-velocity-informed-directional** | PM | **72** | GDELT pipeline actionable; wire-service filter reduces noise |
| **10** | **fair-value-gap-price-discovery / bollinger-squeeze** | FT | **60** | Tied; both need first backtest |

---

## 3. Fastest Path to First Dollar

### Polymarket — favourite-longshot-bias-fade (2-4 weeks)
**Blockers remaining:**
1. Fund Polymarket wallet (USDC deposit via Polygon)
2. Implement Mode A scanner: filter geopolitics markets, YES $0.03-$0.05, liquidity >= $5k
3. Manual execution for first 10 trades (no bot needed)
4. Track WR against 58-68% target

**Why this is fastest:** The mechanism is the simplest in the entire bank. You are selling overpriced YES on near-zero-probability events. The academic evidence (Snowberg & Wolfers, Griffith 1949, etc.) spans 75 years. No classifier, no NLP, no GDELT, no Granger test. Just find geopolitical longshots and sell YES.

### Freqtrade — funding-rate-crowding-reversal (1-2 weeks as suppression layer)
**Blockers remaining:**
1. Add funding rate check to YujiSmartMoneyStrategy (data already available via Binance API)
2. When funding > 0.06%/8h for 3+ periods, suppress long entries for 72h
3. This costs nothing to implement and improves every other strategy

---

## 4. Revenue Timeline

| System | First Profitable Trade | Steady Revenue | Confidence |
|--------|----------------------|----------------|------------|
| Polymarket (FLB fade) | May 2026 (manual) | Q3 2026 ($50-200/mo) | Medium |
| Polymarket (time-decay fade) | June 2026 | Q3 2026 ($50-150/mo) | Medium |
| Polymarket (LLM ensemble) | Q3 2026 | Q4 2026 ($100-500/mo) | Low-Medium |
| Freqtrade (any prim) | Unknown | Unknown | **Very Low** |

**Freqtrade honest assessment:** Every single backtest has been unprofitable. 28/28 plateau cells for hidden-RSI-divergence returned WR 27-40%. VWAP had one positive naive data point (67.2% WR) but all sophisticated backtests show PF 0.04-0.78. The ScalperStrategy lost 24.9% over 101 trades. The RegimeStrategy lost money on 178 trades (PF 0.56). There is no evidence that any freqtrade prim generates positive returns on your data.

---

## 5. Critical Assessment

### The Knowledge-Deployment Gap is Enormous

**115 cycles of research have produced zero dollars of revenue.** The tradepractice system has become an autonomous knowledge generation engine that creates increasingly sophisticated analytical reports, but the connection between "sophisticated knowledge" and "profitable deployment" is broken.

### Intellectual Exercises vs. Revenue-Viable

**Intellectual exercises (STOP researching):**
- hidden-bullish-rsi-divergence — already proven ANTI-PRIM; remove from active consideration
- capitulation-exhaustion-reversal — ZERO positive anchor at any tier; 4-8yr validation window; declining crash amplitude means the phenomenon itself is disappearing
- bullish-rsi-divergence — published NEGATIVE evidence; elevated only to document failure modes
- options-iv-skew-regime-signal — Deribit data dependency makes this impractical; crypto options market too thin
- cross-venue-semantic-arb — 3-8 events per year; Kalshi Rule 6.3(c) creates non-binary loss; structurally unviable at scale
- political-hedge-instrument-signal — niche, low frequency
- wallet-reputation-directional — heavy blockchain data pipeline for unproven signal

**Revenue-viable (DEPLOY or validate NOW):**
- favourite-longshot-bias-fade — simplest, strongest evidence, deploy manually this week
- no-event-time-decay-fade — actuarial math is clean; Gamma API scan is bounded work
- llm-ensemble-probability-edge — PolySwarm evidence is the strongest external validation in the bank
- funding-rate-crowding-reversal — free improvement to existing bot; implement as suppression layer

### Knowledge Generation Rate vs. Validation Rate

**The prim generation rate is dangerously outpacing validation.** At 14 cycles per 5-hour window and ~$2/cycle, you are spending $28/day generating new analytical reports while having validated exactly 1 prim with own data (VWAP, which then failed). The remaining 40 sophisticated prims have ZERO own-data validation.

**Cost of research so far:** ~$600 across 115 cycles (estimated from budget data). This has produced a knowledge base with deep academic grounding but zero revenue.

**The ratio should invert:** 80% of cycles should be IMPLEMENT/BACKTEST-ANALYSIS, not RESEARCH elevation. Every new RESEARCH cycle that elevates a prim to sophisticated without first validating the existing sophisticated prims is destroying expected value.

### Backtest Results Are Uniformly Bad

From the actual backtest data:
- **YujiVWAPMeanReversionStrategy:** -57.1% on 1,641 trades (PF 0.04)
- **YujiScalperStrategy:** -24.9% on 101 trades (PF 0.07)
- **YujiMultiSignalStrategy:** -21.3% on 46 trades (PF 0.17)
- **YujiRegimeStrategy:** -5.9% on 178 trades (PF 0.56)
- **28-cell divergence plateau:** ALL CELLS NEGATIVE (PF 0.20-0.34)
- **Only positive result:** YujiStrategy with +2.5% on 12 trades (PF 9.57) — too few trades to be statistically meaningful

This is a strong signal that the Freqtrade prim knowledge, however sophisticated epistemically, does not translate to profitable crypto spot trading.

---

## 6. Recommended Action Plan — THIS WEEK

### Action 1: Deploy FLB Fade on Polymarket (Manual, 2 hours)
1. Fund PM wallet with $100 USDC
2. Find 3-5 geopolitical markets with YES $0.03-$0.07, resolution within 90 days
3. Sell YES (= buy NO) with $10-20 per position
4. Track in spreadsheet: market, entry, exit, PnL
5. **This is your first dollar.** No bot, no classifier, no NLP. Just the oldest bias in prediction markets.

### Action 2: Implement Funding Rate Suppression in Freqtrade (4 hours)
1. Add `funding_rate` data fetch to YujiSmartMoneyStrategy (already on Kraken)
2. When `funding_rate > 0.06%` for 3+ consecutive periods, suppress all long entries
3. This is the cheapest validation test in the entire freqtrade bank
4. Run backtest with/without suppression — compare PF and max drawdown
5. If suppression improves results by measurable margin, it validates the mechanism for ALL sister prims

### Action 3: STOP all RESEARCH elevation cycles; switch to BACKTEST-ANALYSIS only
1. Edit tradepractice cron to force `mode: BACKTEST-ANALYSIS` for next 20 cycles
2. Priority backtest queue:
   - liquidity-sweep-reversal (strongest external evidence, n=2,847)
   - ema-pullback-dynamic-support (8 sources, concrete filters)
   - fair-value-gap-price-discovery (academic base + CVD gate)
3. Any prim that fails backtest → mark ANTI-PRIM and stop spending cycles on it
4. **Revenue mandate: no new sophisticated elevation until at least 1 prim generates positive backtest returns**

---

## Summary Numbers

| Metric | Value |
|--------|-------|
| Sophisticated prims | 41 (21 FT + 20 PM) |
| Confirmed anti-prims | 1 (hidden-rsi-divergence) |
| Prims with own-data validation | 1 (VWAP — failed) |
| Prims with positive backtest | 0 |
| Revenue generated to date | $0.00 |
| Research cost to date | ~$600 |
| Fastest path to first dollar | FLB fade on PM (manual, this week) |
| Recommended research:deployment ratio | 20:80 (currently ~95:5) |
