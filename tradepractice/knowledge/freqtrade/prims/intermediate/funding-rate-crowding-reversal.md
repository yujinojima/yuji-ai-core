---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T17:18:43+10:00
cycle: 29
---

---

## Prim: funding-rate-crowding-reversal
**Level:** intermediate
**Project:** freqtrade
**Parent:** none (7th mechanism class)
**Commit:** `52e1ff6`

### Rule
BTC/ETH perpetual 8h funding rate > 0.10% per 8h (>109% annualized, top decile) + ADX < 45 + RSI > 60 → **suppress all long entries from sister prims for 72h; flag crowding regime**. Inverse: funding < −0.05% → amplify long entry confidence from sister prims. Neutral band (−0.05% to +0.10%): no modification.

### Mechanism
Perpetual futures charge longs >0.10% per 8h = >0.30% over 72h when funding is extreme. Cost pressure forces marginal longs to voluntarily exit. Fragile crowding means shared stop levels → any negative catalyst triggers cascade liquidations. Mechanical mean-reversion as long OI drops and funding normalises. **Mechanistically distinct from all 6 existing sophisticated prims** (all spot OHLCV). This is the **first positioning/cost-of-carry signal** in the bank.

**Meta-indicator role**: modifies confidence of sister prims rather than triggering independently. When crowding is active, RSI mean reversion / EMA pullback / liquidity sweep long prims carry higher false-positive risk.

### Evidence

| Source | Finding |
|---|---|
| Practitioner (2024-2026) | Top-decile funding (>0.10% per 8h) → **~60% probability of 5-10% retrace within 72h** — methodology undisclosed |
| CMU Crypto Carry (BTC Binance 2020-2022) | Carry Sharpe **12.8 and 7.0** — structural predictability in early period |
| arxiv 2510.14435 | Carry Sharpe 2020-2025: **6.45** → 4.06 in 2024 → **negative in 2025** |
| BitMEX Q3 2025 | Funding positive **92% of time** — baseline structural positive; extremes (>0.10%) are the signal |
| Jan 2026 reference | BTC funding **0.51% per 8h** = 70.2% APR paid by longs |
| BIS Working Paper 1087 | Crypto carry as systematic return factor (academic confirmation) |
| MDPI 2026 (Two-Tiered) | 17% observations with ≥20bps spreads; CEX dominates price discovery 61% > DEX |
| SSRN Inan | DAR models predict next-period funding rate better than no-change — autocorrelation confirmed |
| freqtrade #12583 | Binance changed 8h funding to variable intervals — implementation constraint |

### Key Numbers

| Metric | Value |
|---|---|
| Signal threshold | >0.10% per 8h (>109% annualized) |
| Practitioner WR claim | ~60% / 5-10% retrace / 72h window |
| Carry Sharpe 2020-2025 | 6.45 → 4.06 → **negative in 2025** |
| Funding positive baseline | 92% of all 8h periods |
| Signal frequency | **< 15-20 qualifying events/year** (BTC+ETH combined) |
| 72h suppression cost | 3 funding periods × 0.10% = 0.30% cost pressure on longs |

### 10 Documented Limitations
1. **Trend persistence** — 2020-2021 BTC: >0.10% funding for weeks during parabolic bull; naive contrarian loses repeatedly
2. Primary quantitative claim (60%/72h) is single practitioner source, no methodology disclosed
3. Carry trade deterioration in 2025 (negative Sharpe) reduces the forced-exit mechanism's strength
4. Signal frequency < 15-20/year → statistical validation requires 2-4 years minimum
5. Freqtrade infrastructure gap: futures data download + Binance variable interval (#12583)
6. 72h suppression window is untuned (may be too short in strong trends, too long in quick corrections)
7. No peer-reviewed paper directly tests funding rate extremes as directional price reversal signals
8. Cross-pair contamination: BTC/ETH funding should not suppress ALT signals
9. Swing P&L impact: 9-15 funding payments at 0.10-0.50% during extreme periods (excluded from most backtests)
10. Meta-indicator deployment requires architectural change to signal pipeline (no existing cross-prim modifier in Yuji codebase)

### 7th Regime Axis

| Regime | Prim | Level |
|---|---|---|
| Ranging (ADX < 20) | rsi-oversold-mean-reversion | sophisticated |
| Ranging-to-mild-trend (ADX < 30) | liquidity-sweep-reversal | sophisticated |
| Trending structural (ADX 25-35 rising) | ema-pullback-dynamic-support | sophisticated |
| Exhaustion/late-bear | bullish-rsi-divergence | sophisticated |
| Trending momentum (uptrend pullback) | hidden-bullish-rsi-divergence | sophisticated |
| Panic capitulation | capitulation-exhaustion-reversal | sophisticated |
| **Derivatives crowding** | **funding-rate-crowding-reversal** | **intermediate** |

First prim sourced from the **derivatives market** — extends the bank's observational space from OHLCV-only to positioning/cost-of-carry.

### Bank State After Cycle 29

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | 0 |
| Intermediate | **1** (funding-rate-crowding-reversal) | 0 |
| Sophisticated | 6 | 5 |

### Files Updated
- `knowledge/freqtrade/prims/intermediate/funding-rate-crowding-reversal.md` (created, 9-source)
- `knowledge/epistemic-index.md` (intermediate freqtrade table +1 row)
- `knowledge/conditions-log.md` (intermediate entry appended)
- Commit: `52e1ff6`

### Next Cycle Recommendation
**(A) BACKTEST-ANALYSIS** — shared blocker across all 6 sophisticated prims; the divergence head-to-head remains the single highest-value own-data test (any of 4 outcomes load-bearing).
**(B) RESEARCH** — refine funding-rate-crowding-reversal to sophisticated: key gaps are (i) quantify the trend-persistence failure mode (what ADX/EMA threshold separates "parabolic" from "correctable"?), (ii) find or derive the signal frequency on BTC 2020-2025 historical data, (iii) separate the carry-deterioration effect from the crowding-signal effect in 2025 data.
**(C) IMPLEMENT** — capitulation-exhaustion-reversal (9 implementation gaps in YujiExtinctionBurstStrategy.py); after implementation, count regime-gated signals — if n < 15, frequency anti-prim A triggered.

Recommend **(B)** next if RESEARCH mode; **(C)** if IMPLEMENT mode; **(A)** if BACKTEST-ANALYSIS mode.

### Sources
- [The Crypto Carry Trade, CMU](https://www.andrew.cmu.edu/user/azj/files/CarryTrade.v1.0.pdf)
- [Crypto as Investable Asset Class, arxiv 2510.14435](https://arxiv.org/html/2510.14435v2)
- [BIS Working Paper 1087 — Crypto Carry](https://www.bis.org/publ/work1087.pdf)
- [MDPI — Two-Tiered Structure Cryptocurrency Funding Rate Markets](https://www.mdpi.com/2227-7390/14/2/346)
- [SSRN — Predictability of Funding Rates, Inan](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5576424)
- [QuantJourney — Funding Rates as Sentiment Signal](https://quantjourney.substack.com/p/funding-rates-in-crypto-the-hidden)
- [ScienceDirect — Funding Rate Arbitrage Risk/Return Profiles](https://www.sciencedirect.com/science/article/pii/S2096720925000818)
- [freqtrade GitHub #12583 — Binance funding interval variability](https://github.com/freqtrade/freqtrade/issues/12583)
- [freqtrade GitHub #7302 — Funding rate implementation](https://github.com/freqtrade/freqtrade/issues/7302)
