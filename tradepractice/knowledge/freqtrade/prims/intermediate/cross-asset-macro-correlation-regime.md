---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T23:45:45+10:00
cycle: 118
---

```
from: analyst
subject: analyst-result
timestamp: 2026-04-12T23:58:00+10:00
cycle: 118
mode: RESEARCH
```

## Prim: cross-asset-macro-correlation-regime
**Level:** intermediate (17th freqtrade regime axis, elevation from naive)
**Commit:** `638e67b`

---

### What This Cycle Produced

The only active naive freqtrade prim (cycle 116) has been elevated to intermediate. All 15 prior freqtrade naive slots are now superseded. The 17th regime axis moves from a single heuristic ρ threshold to a four-regime differentiation architecture.

**Bank state after cycle 118:**

| Tier | Freqtrade | Polymarket |
|------|-----------|------------|
| Naive (superseded) | **15** (all superseded) | 21 |
| Intermediate | **21** (+1) | 20 |
| Sophisticated | 21 | 20 |

---

### The Five Core Upgrades

**[1] Dual-window correlation gating** — The naive single ρ_30d = 0.50 heuristic lags 2 weeks at regime entry and overstays 30 days at regime exit. Intermediate requires ρ_14d ≥ 0.40 (early warning) AND ρ_30d ≥ 0.50 (confirmation) together. This mirrors the EMA short/long crossover confirmation logic used in axis 2. Exit hysteresis: ρ_30d must fall below 0.35 (not 0.50) to avoid oscillation at the boundary.

**[2] Four coupling sub-regimes** — Blanket 0.85× suppression was wrong-direction in two common scenarios:
- `fear_driven` (VIX > 28): suppress momentum 0.85×, gentle on MR (0.925×) — capitulation approaching
- `momentum_driven` (VIX < 20): **amplify momentum 1.05×**, suppress MR 0.85× — institutions buying risk cross-asset
- `event_spike` (ρ jumped > 0.15 in 5 days): 0.90× all for 5 days only — transient event, not structural regime
- `neutral_coupled` (VIX 20–28): standard 0.85× decay schedule

**[3] Crypto-endogenous causation bypass (A1)** — The fundamental error: suppressing BTC capitulation signals during FTX/LUNA, where the correlation spike was caused BY the crypto event, not BY equity macro flows. Bypass condition: `BTC_RV7d / SPX_RV7d > 2.5`. When BTC vol is 2.5× greater than SPX vol, the causal direction is BTC→SPX. Full bypass, all modifiers = 1.0.

**[4] Progressive duration gate** — 9-month equity-coupled regimes (2022 bear) with constant 0.85× suppression would have crippled all sister prims through the entire bear market. Day 1–10: full suppression; day 11–30: half (0.925×); day 31+: quarter (0.966×). After 30 days, the market has repriced; crypto micro-structure reasserts within the macro trend.

**[5] DCC-GARCH framing** — Engle (2002) DCC-GARCH is the correct statistic for time-varying conditional correlation. Static 30-day Pearson overestimates ρ during BTC vol clusters (α+β = 0.968, Katsiampa 2017). Intermediate documents this explicitly and targets DCC-GARCH replacement at sophisticated tier via the Python `arch` library.

---

### Blocking Gate for Sophisticated Elevation

All three gates are free/cheap and can be executed any time:

**G1 (30 min):** Compute BTC-SPX rolling ρ_14d and ρ_30d for 2020–2025 via yfinance. Count sub-regime firing rates (target: fear_driven ≥ 10 days/year, momentum_driven ≥ 10/year, event_spike ≥ 3/year). Verify causation filter fires on LUNA May 2022, FTX November 2022.

**G2 (4–6 hours):** Label YujiRSIStrategy + YujiFVGStrategy backtest entries by macro regime (equity_coupled vs crypto_native). Binomial test: ≥ 5pp WR reduction in equity_coupled, p < 0.10. This is H_macro's confirmation. If < 3pp across all sister prims → anti-prim reclassification.

**G3 (2–4 hours):** Implement Engle (2002) DCC-GARCH via `arch` library. Replace static Pearson ρ with time-varying ρ_t. Rerun G2 with DCC-filtered classifier. Compare Sharpe separation. ≥ 0.05 Sharpe improvement → DCC is the sophisticated implementation.

---

### Next Cycle Recommendations

**(A) IMPLEMENT — G1 scan (highest priority, free):** 30 minutes of Python. `yf.download(['BTC-USD', '^GSPC', '^VIX'])` → compute dual-window ρ → label sub-regimes → verify causation filter on LUNA/FTX dates. This unblocks G2.

**(B) IMPLEMENT — G2 conditional WR scan:** Split any existing freqtrade backtest output by macro regime date labels from G1. The H_macro test result either confirms the mechanism (→ sophisticated path) or triggers anti-prim classification.

**(C) RESEARCH — new axis 18:** All 16 prior freqtrade regime axes now have intermediate counterparts. The bank has no remaining naive freqtrade prims. If the conductor targets further bank expansion, the unexplored territory is: on-chain supply dynamics (HODL waves, MVRV ratio, exchange net flows) — a pure blockchain-native regime axis that has no overlap with any of the 17 existing axes (which all use derivatives, equity, or price data).
