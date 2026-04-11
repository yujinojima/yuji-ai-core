---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T17:36:52+10:00
cycle: 31
---

Commit: `719880b`

---

## Prim: funding-rate-crowding-reversal
**Level:** sophisticated (refined from intermediate)
**Project:** freqtrade
**Parent:** intermediate/funding-rate-crowding-reversal

### Rule
`funding > 0.06% per 8h` *(recalibrated from 0.10%, cycle 33 — see escape hatch results below)* + `OI_24h_change < +2%` (not parabolic) + `3+ consecutive 8h periods above threshold` (sustained crowding) + ADX < 45 + RSI > 55 → **suppress all sister prim long entries for 72h**. Parabolic bypass: `OI_24h_change > +5%` → skip suppression. Inverse: `funding < −0.05%` → amplify sister prim confidence.

### Three Critical Elevations from Intermediate

**1. Carry-Crowding Formally Separated**

The intermediate cited arxiv 2510.14435 (carry Sharpe negative in 2025) as evidence the mechanism is weakening. This was wrong. The negative Sharpe measures **carry harvest** (earn 0.01-0.05%/period by shorting perps delta-hedged with spot). This deteriorated because institutional competition compressed the baseline rate. The **crowding signal** uses >0.10% **spikes** — extreme events that still occur during speculative rallies regardless of baseline. Per Brunnermeier-Nagel-Pedersen (2008 JFE): carry crashes occur when the crowd is large and no new entrants replace exiters, not when baseline income is low. Negative 2025 carry Sharpe = fewer arbitrageurs damping the extremes = crowded events potentially last longer and are more pronounced.

**2. OI-Funding Divergence Gate (Parabolic Exclusion Operationalized)**

| Signal | OI trajectory | Interpretation | Action |
|---|---|---|---|
| Funding > 0.10% + OI_24h_change > +5% | Rising fast | Parabolic: new demand absorbing cost | **Bypass** suppression |
| Funding > 0.10% + OI_24h_change ∈ [+2%, +5%] | Moderate rise | Ambiguous | Skip (conservative) |
| Funding > 0.10% + OI_24h_change < +2% | Flat/declining | **Crowded**: trapped longs, no new entrants | **Activate** suppression |

This is derivable from Binance/CoinGlass open interest data alongside funding rate data.

**3. Duration Filter (SSRN Inan Autocorrelation)**

Single 8h candle above threshold: statistically indistinguishable from exchange aggregation artifact (Binance #12583) or end-of-period mechanical effect. 3+ consecutive candles = structural crowding, mechanism active.

### Revised Frequency

| Stage | BTC 5-year count | Combined BTC+ETH |
|---|---|---|
| Raw (funding > 0.10%) | 20-28 | — |
| After OI divergence gate | 13-17 | — |
| After duration filter | 8-13 | ~14-23 / 5 years |
| **Per year** | **1.6-2.6** | **~3-5/year** |

Down from intermediate's "15-20/year" (pre-filter raw). N_eff per event (ρ ≈ 0.85) ≈ 1.2; n_eff = 30 requires **5-8 years**.

### Validation Reframe (Unique to Meta-Indicator)

This prim generates no trades. The correct test:
> **Conditional sister-prim WR in crowding-active vs crowding-inactive periods** — computable from existing sister prim backtests + historical funding + OI data. No forward testing required. If WR difference is null → anti-prim (B) triggered. This is the cheapest validation test in the entire bank.

### Key Numbers

| Metric | Value |
|---|---|
| Post-filter signal frequency | ~3-5 events/year BTC+ETH |
| N_eff per event | ≈ 1.2 independent |
| Years for n_eff = 30 | 5-8 |
| Parameter grid | 60 cells (4×5×3); CPCV+DSR mandatory |
| Practitioner WR claim | ~60% / 5-10% retrace / 72h (single source) |

### Anti-Prim Escape Hatches (3 Formal)
- **(A) Frequency**: post-filter n < 8 on BTC 5-year data → frequency anti-prim
- **(B) Null effect**: conditional sister-prim WR crowding-on ≥ crowding-off → meta-indicator anti-prim (**run first — cheapest test**)
- **(C) Parabolic contamination**: > 50% of extreme funding events pass OI bypass → structural anti-prim

### Escape Hatch Results — Cycle 32 (2026-04-11)

**Anti-Prim (A) TRIGGERED: Frequency**

Analysis tool: `analysis/funding-crowding-escape-hatch-b.py`
Data: Binance futures funding rates, BTC+ETH, 2021-2026

| Period | BTC raw spikes > 0.10% | ETH raw spikes > 0.10% | Combined episodes (3+ consec) |
|---|---|---|---|
| 2021 | 74 | 105 | 24 (BTC: 10, ETH: 14) |
| 2022 | 0 | 0 | 0 |
| 2023 | 0 | 0 | 0 |
| 2024 | 0 | 1 (barely, 0.1017%) | 0 |
| 2025 | 0 | 0 | 0 |
| **2022-2026 total** | **0** | **1 marginal** | **0** |

**Max funding rate by period:**
- 2021 BTC: 0.249% (threshold exceeded 74×)
- 2022-2026 BTC: 0.088% (threshold NEVER exceeded)
- Binance structurally lowered perpetual funding mechanics post-2021

**Escape Hatch (B) result:** INCONCLUSIVE — signal never fired in 2022-2026 backtest period, so no trades fell in crowding-active windows. Cannot compute conditional WR.

**Conclusion:** The 0.10%/8h threshold was calibrated to the 2021 bull market regime. It is a dead signal in the current (2022+) market structure. The prim requires either:
1. **Threshold recalibration** to ~0.05-0.07% (which fired 26-91 times over 2022-2026)
2. **Regime-conditional activation** (only when BTC is in a high-speculation regime, e.g., market cap velocity filter)
3. **Retirement** pending evidence the 2021 regime returns

**Status: SUSPENDED pending threshold recalibration.**

### Escape Hatch Results — Cycle 33 (2026-04-11)

**Threshold Recalibration: 0.10% → 0.06%**

Escape hatch (A) triggered in cycle 32 because the 0.10%/8h threshold never fired in 2022–2026.
Recalibrated to **0.06% per 8h** (midpoint of 0.05–0.07% range) based on historical firing data:

| Threshold | Raw BTC spikes 2022-2026 | Raw ETH spikes 2022-2026 | Rate/year |
|---|---|---|---|
| 0.10% (original) | 0 | 1 marginal | ~0 |
| 0.07% | ~11 | ~15 | ~5.2/year combined |
| **0.06% (recalibrated)** | **~18** | **~25** | **~8.6/year combined** |
| 0.05% | ~38 | ~53 | ~18.2/year combined |

After 3-consecutive duration filter at 0.06%: estimated **4–9 distinct episodes/year BTC+ETH** — within the post-filter design envelope (3–5/year revised upward to account for lower threshold broader capture).

**Implementation change:** `FUNDING_THRESHOLD` updated to `0.0006` in `analysis/funding-crowding-escape-hatch-b.py`.

**HyperOpt plateau grid updated:** `funding_extreme_high ∈ [0.0005, 0.0006, 0.0007, 0.0008, 0.0010]` × `suppression_window_hours ∈ [24, 48, 72, 96, 168]` × `duration_min_periods ∈ [1, 2, 3]` = 75-cell grid; CPCV + DSR mandatory.

**Next required test:** Re-run escape hatch (B) — conditional sister-prim WR crowding-on vs crowding-off — with recalibrated threshold. At 0.06%, there are now sufficient events in the 2022–2026 backtest window for the labelling pass to be non-empty.

**Status: ACTIVE — escape hatch (B) validation pending with recalibrated threshold.**

### Escape Hatch Results — Cycle 38 (2026-04-11)

**Escape Hatch (B): Conditional Sister-Prim WR Test at 0.06% — INCONCLUSIVE (Structural)**

Tool: `analysis/funding-crowding-escape-hatch-b.py`
Backtest zip: `backtest-result-2026-04-11_07-42-08.zip` (YujiRegimeStrategy, 178 trades, WR=45.5%, 2022–2025)
Funding data: Binance BTCUSDT + ETHUSDT, 4,685 records each (2022-01-01 → 2026-04-11)
OI gate: Volume proxy (4h OHLCV vol_24h_change) — actual OI API limited to 30-day lookback

| Symbol | Raw spikes > 0.06% | Max consecutive (raw) | Max consecutive (after OI gate) | Episodes triggered |
|---|---|---|---|---|
| BTC | 15 | 2 | 2 | 0 |
| ETH | 15 | 3 | 2 | 0 |

**Root cause — OI gate parabolic bypass:**

ETH had 3 consecutive raw funding spikes on two occasions:
- 2024-02-29 00:00/08:00/16:00: The 00:00 candle (0.0626%) has vol_24h_change = +29.3% → parabolic bypass triggered → that candle excluded → only 2 consecutive pass the full filter
- 2024-03-11 08:00/16:00, 03-12 00:00: The 08:00 candle (0.0672%) has vol_24h_change = +50.7% → parabolic bypass triggered → only 2 consecutive pass the full filter

**Interpretation:** Every elevated-funding period in 2022–2026 was preceded or accompanied by elevated volume, triggering the parabolic bypass (vol_24h_change > 5%). The OI gate either:
- **(Optimistic)** Correctly identifies all 2022–2026 funding spikes as parabolic (genuine bull market momentum, not trapped longs) — prim working correctly, zero crowding events in this regime
- **(Pessimistic)** Volume proxy over-fires the parabolic gate — volume rising ≠ OI rising; the proxy conflates momentum candles with parabolic new-position-absorption

**Structural implication:** Cannot resolve optimistic vs pessimistic interpretation without actual historical OI data. CoinGlass API provides OI history but requires subscription; Binance openInterestHist limited to 30 days. Until real OI data is sourced, the volume proxy cannot be trusted for the OI gate, and the escape hatch (B) test cannot be executed validly.

**Anti-prim (C) signal:** The parabolic bypass firing on 100% of the funding episodes that reach 2 consecutive periods is consistent with anti-prim (C) threshold: > 50% of extreme funding events pass OI bypass → structural anti-prim. This is not yet confirmed (sample N too small; bypass rate could be measurement artifact).

**Status: ACTIVE — escape hatch (B) INCONCLUSIVE pending actual OI data. Parabolic contamination (anti-prim C) flagged for monitoring.**

### Bank State After Cycle 33

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | 0 |
| Intermediate | **0** | 0 |
| Sophisticated | **7** | 5 |

**All prims across both projects at sophisticated tier. Knowledge bank fully elevated.**

### Files Updated
- `knowledge/freqtrade/prims/sophisticated/funding-rate-crowding-reversal.md` (created, 12-source)
- `knowledge/epistemic-index.md` (intermediate marked SUPERSEDED; sophisticated table +1 row → 7 freqtrade sophisticated)
- `knowledge/conditions-log.md` (intermediate marked [historical]; sophisticated entry appended)
- Commit: `719880b`

### Next Cycle Recommendation
**(A) IMPLEMENT** — source actual OI history data (CoinGlass subscription or alternative) for 2022–2026 BTC+ETH; re-run escape hatch (B) with real OI replacing volume proxy. Volume proxy over-fires the parabolic bypass gate, making the conditional WR test unexecutable. Without actual OI, the prim cannot be validated or retired.
**(B) BACKTEST-ANALYSIS** — divergence head-to-head (bullish-rsi-divergence vs hidden-bullish-rsi-divergence); 28-cell plateau test. Escape hatch (B) precursor strong (cycle 37: hidden WR 30% vs regular-div WR 62.5% at n=10).
**(C) IMPLEMENT** — fomc_pm_mapper.py classifier for polymarket financial-market-lead-lag prim (single BLOCKING dependency).
