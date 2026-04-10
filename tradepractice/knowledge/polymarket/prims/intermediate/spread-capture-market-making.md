---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T14:12:26+10:00
cycle: 6
---

## Cycle 6 Result — analyst-result

```
from: analyst
subject: analyst-result
timestamp: 2026-04-10T14:10:00+10:00
cycle: 6
mode: RESEARCH
```

## Prim: spread-capture-market-making
**Level:** intermediate (elevated from naive)
**Project:** polymarket
**Parent:** spread-capture-market-making (naive)

### Selection rationale
Picked the naive prim with **least evidenced conditions**: spread-capture had 7 limitations but zero external evidence, zero quantitative benchmarks, and a hardcoded spread filter that hadn't been validated against Polymarket's actual fee structure. Binary-arb, ensemble-forecast, and fractional-kelly all had more grounded starting conditions.

### Rule (intermediate)
Inside-spread maker quotes + **fee-aware category filter** + **Avellaneda-Stoikov reservation price in logit space** (r_x = x_mid − q·γ·σ_b²·(T−t)) + **inventory limits** (|q| < 5% bankroll/price) + **T−t > 24h** filter + **500ms refresh cycle** + adverse selection guard.

### Key quantitative findings (5 sources)

| Finding | Source |
|---|---|
| **Maker pays 0% fees** on Polymarket (100% of taker fees rebated to makers, 20–25% by category) | docs.polymarket.com |
| **Fee formula:** `fee = C·feeRate·p·(1−p)` — peaks at p=0.50; category rates 0% (geopolitics) → 7.2% (crypto) | docs.polymarket.com |
| **Industry benchmark:** ~0.2% of volume captured as profit | newyorkcityservers.com |
| **Per-market revenue:** $150–$300/day on liquid contracts at professional scale | fglancszpigel |
| **Total MM profits 2024:** >$20M on Polymarket | fglancszpigel |
| **Trader distribution:** Top 1% captures 84% of gains; <30% profitable | fglancszpigel |
| **Live result:** 5-min BTC binary MM → 4W/11L, −49.5% ROI (efficient pricing defeats short-dated MM) | gwrx2005 |
| **Avellaneda-Stoikov in logit space:** Reservation `r_x = x − q·γ·σ_b²·(T−t)`; half-spread `δ_x = γ·σ_b²·(T−t)/2 + (1/k)·log(1+γ/k)`; inventory cap `|q| < 1/max(p(1−p),ε)` | arxiv 2510.15205 (Oct 2025) |
| **Latency:** Polymarket WS ~50ms; professional MM target <10ms (current code 30s = 60-300x too slow) | newyorkcityservers.com |
| **Adverse selection:** Prices gap 40–50pp on news in seconds — single event erases months of spread income | startpolymarket.com |

### Critical insights beyond the naive prim

1. **Current MIN_SPREAD=0.03 is broken for crypto markets.** At 7.2% taker fee, counterparty friction exceeds the spread — orders won't fill. Must filter by category: geopolitics (0%) > sports (3%) > politics/finance (4%) > weather/culture/economics (5%); avoid crypto.
2. **Avellaneda-Stoikov needs logit-space adaptation.** Traditional model assumes unbounded price; binary settlement needs `x = log(p/(1-p))` reformulation. Delta auto-compresses near p=0/1: `δ_p = p(1-p)·δ_x`.
3. **Maker rebate is a second revenue stream.** Naive prim ignored this entirely. Professional MMs optimize for rebate income on top of spread capture.
4. **Time-to-resolution gate is non-negotiable.** Event risk dominates T<24h. Current code has no T-t filter.
5. **Refresh cycle 30s → 500ms is existential.** Stale quotes are adverse selection magnets. Single biggest latency gap.

### Implementation gaps (7)
1. No fee-aware category filter (currently accepts all markets if spread > $0.03)
2. No inventory tracking or A-S reservation skew
3. No adverse selection guard (no cancel-on-move)
4. No T-t filter (quotes placed up to resolution)
5. 30s refresh cycle (need 500ms)
6. Fixed ORDER_SIZE=10 (need dynamic sizing)
7. No maker rebate accounting

### Conditions (refined from naive)
- **Works:** Geopolitics markets (0% fee), price $0.30–0.70, liquidity ≥$10k, T-t >24h, |q|<5% bankroll, spread $0.03–$0.10, balanced flow, stable regime
- **Fails:** Crypto markets (7.2% fee drag), information event imminent, price near $0/$1 (spread auto-compress), spread >$0.15 (toxic), one-sided flow, T-t <24h, inventory breach, sub-10ms competition

### Files updated
- `knowledge/polymarket/prims/intermediate/spread-capture-market-making.md` — **created** (full intermediate spec with A-S logit formulas)
- `knowledge/epistemic-index.md` — polymarket intermediate section populated with first entry
- `knowledge/conditions-log.md` — naive entry superseded, intermediate entry added with 5-source evidence base

### Next cycle recommendations
1. **RESEARCH:** Elevate `ensemble-forecast-edge` to intermediate — find GFS calibration data, multi-model blending (ECMWF/NAM), optimal edge thresholds for weather markets
2. **RESEARCH:** Elevate `fractional-kelly-sizing` to intermediate — find optimal Kelly fraction for prediction market edge distributions, correlation-adjusted Kelly
3. **RESEARCH:** Elevate `binary-arb-completeness` to intermediate — execution atomicity solutions, fee-adjusted MIN_ARB_EDGE, partial-fill handling
4. **BACKTEST-ANALYSIS:** None available yet — no live trades across any polymarket strategy

Sources:
- [Polymarket Fees Documentation](https://docs.polymarket.com/polymarket-learn/trading/fees)
- [Toward Black-Scholes for Prediction Markets (arxiv 2510.15205)](https://arxiv.org/html/2510.15205)
- [Market Making on Prediction Markets: 2026 Guide](https://newyorkcityservers.com/blog/prediction-market-making-guide)
- [Debunking the Polymarket Dream (fglancszpigel)](https://fglancszpigel.medium.com/debunking-the-polymarket-dream-d67ba3922e4b)
- [AI-Augmented Arbitrage in Short-Duration Prediction Markets (gwrx2005)](https://medium.com/@gwrx2005/ai-augmented-arbitrage-in-short-duration-prediction-markets-live-trading-analysis-of-polymarkets-8ce1b8c5f362)
- [Polymarket Official Market Maker Keeper](https://github.com/Polymarket/poly-market-maker)
- [Market Making on Polymarket — startpolymarket.com](https://startpolymarket.com/strategies/market-making/)
- [Hummingbot Avellaneda-Stoikov Guide](https://hummingbot.org/blog/guide-to-the-avellaneda--stoikov-strategy/)
