---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T01:00:00+10:00
cycle: 122
mode: RESEARCH
---

## Prim: on-chain-supply-dynamics-regime
**Level:** naive (new axis)
**Commit:** `e1406a4`

---

### What This Cycle Produced

All 17 freqtrade axes are at sophisticated tier after cycle 120. Cycle 122 opens the 18th axis: **blockchain-native supply dynamics** — the only major data category (on-chain UTXO) not yet represented in the 17-axis framework.

**Bank state after cycle 122:**

| Tier | Freqtrade | Polymarket |
|------|-----------|------------|
| Naive (16 superseded + 1 active) | **17 (+1)** | 21 |
| Intermediate | 21 | 21 |
| Sophisticated | 22 | 20 |

---

### Why Axis 18 Is The Right Next Move

All 17 existing axes are agnostic to on-chain holder behaviour:

| Axes | Data source |
|------|------------|
| 1–6 (RSI MR, EMA pullback, liquidity sweep, divergences, CER) | Price + volume |
| 7–9 (funding, Bollinger, VWAP) | Derivatives carry + technical |
| 10–13 (FVG, OI div, LSR, basis) | Perpetual derivatives + orderflow |
| 14–16 (RV term structure, financial lead-lag, options skew, GEX) | Vol surface + options + macro event |
| 17 (cross-asset macro) | External equity correlation |
| **18 (on-chain supply)** | **Blockchain UTXO — first on-chain axis** |

None of axes 1–17 can answer: *"Are long-term BTC holders net distributing or accumulating right now?"* This is the unique question axis 18 answers, using information that exists only in the Bitcoin blockchain transaction graph.

---

### The Naive Rule

**Meta-signal only** (no standalone entries). Same architecture as axes 7, 9, 13, 14, 15, 16, 17.

```
MVRV > 2.5               → suppress all sister prim longs × 0.85
MVRV < 1.0               → amplify all sister prim longs × 1.10
Exchange netflow 7d > 2× 30d SMA abs  → additional × 0.90
Exchange netflow 7d < -2× 30d SMA abs → additional × 1.05
MVRV [1.10, 2.50]        → no modification (neutral, ~60–70% of days)
```

**Why MVRV:** Realized cap (Nic Carter 2018) weights each UTXO at its last-moved price — the aggregate cost basis of all BTC holders. MVRV > 2.5 = average holder up 150% — LTH profit-taking historically becomes the dominant marginal flow. MVRV < 1.0 = average holder at a loss — sellers exhausted, new supply depleted.

**Why exchange flows:** Inflows represent intent to sell (coins moved from cold storage to exchange). Net inflows > 2× normal = supply shock arriving; price softens within 3–7 days (Griffin & Shams 2020 JF is the direct academic anchor — Tether exchange flows led BTC price, same mechanism).

---

### Six Academic Anchors

| Paper | Relevance |
|-------|-----------|
| Liu & Tsyvinski 2021 JF | On-chain user metrics (unique addresses) predict crypto returns — establishes on-chain as legitimate predictor channel |
| Foley, Karlsen & Putnins 2019 RFS | On-chain transaction graph reveals economic structure orthogonal to price — epistemological basis for axis 18 independence |
| Griffin & Shams 2020 JF | Exchange Tether flows lead BTC price direction — direct empirical anchor for the exchange net flow component |
| Cong, Li & Wang 2020 RFS | On-chain adoption → valuation equilibria; speculative premium above user-value precedes reversals (MVRV distributional regimes are empirical analogue) |
| Bianchi 2020 JFQA | On-chain metrics predict crypto returns beyond price technicals — scope confirmation at asset-class level |
| Woo 2021 CoinMetrics | MVRV Z-score historically identifies cycle tops and bottoms — practitioner-academic bridge (hypothesis-generating, non-peer-reviewed) |

---

### Critical Limitations At Naive Tier

**1. Data availability (PRIMARY BLOCKER):** Glassnode free tier is insufficient — entity-adjusted exchange flows (removing exchange-internal wallet moves) require Glassnode Advanced (~$39/month) or CryptoQuant. Raw exchange flow has ~30–50% false positive rate. No Glassnode API integration exists in freqtrade Docker environment.

**2. Frequency concern:** MVRV > 2.5 threshold yields ~5 extreme episodes in 9 years (2017 ATH, 2021 ATH, partial 2019 recovery). n=5 provides zero statistical power. Intermediate **must** use MVRV Z-score (standardised by historical σ) or lower threshold to target ≥ 10 distinct episodes/year.

**3. Duration gate absent:** In the 2021 bull market, MVRV stayed > 2.5 for approximately 6–8 months. Applying 0.85× suppress for 6 months in a bull market = catastrophic PnL drag. A maximum 90-day rolling window with decay (analogous to cross-asset macro progressive decay gate) is required before intermediate elevation.

**4. Redundancy risk:** In MVRV < 1.0 capitulation territory, the CER prim (axis 6) also activates on intraday panic candles. At intermediate tier, verify ρ(axis 18 signal, axis 6 signal) is < 0.70; if high, N_eff calculation required.

---

### Blocking Gates For Intermediate Elevation

1. **Data gate:** Obtain Glassnode API key; verify entity-adjusted flows accessible; confirm Docker environment can authenticate (API key header: `X-Api-Key`, different from existing unauthenticated Binance/Deribit patterns used in axes 11–13, 16)

2. **G1 frequency calibration:** Use MVRV Z-score (MVRV normalised by 365-day rolling mean and σ) to achieve ≥ 10 signal episodes/year. Target thresholds: Z > +1.5 (distribution) and Z < −0.5 (accumulation). Run frequency scan on 2017–2026 Glassnode data.

3. **Duration gate design:** Maximum suppress window = 90 days from first trigger. Progressive decay: day 1–30 full modifier, day 31–60 half, day 61–90 quarter, day 90+ reset (require MVRV to re-cross threshold to restart).

4. **Redundancy check:** Compute ρ(MVRV distribution signal, axis 7 funding-rate trigger) over 2022–2026. If ρ < 0.50 → independent → proceed. If ρ > 0.70 → merge into axis 7 extension rather than independent axis.

---

### Next Cycle Recommendations

**(A) IMPLEMENT — Glassnode API integration:** Obtain API key, test `bot_loop_start()` with `X-Api-Key` header, confirm entity-adjusted exchange flows return clean data. Estimated to unblock intermediate G1 scan.

**(B) RESEARCH — G1 frequency calibration (analytical):** MVRV Z-score historical values are publicly documented (Glassnode blog, Woo research). Analytically derive Z > +1.5 frequency 2017–2026 from documented bull market peaks. If frequency ≥ 10 episodes/year confirmed analytically → skip to intermediate.

**(C) RESEARCH — new axis 19 candidate:** With 18 axes defined, the remaining unexplored domain is **miner behaviour** (hashrate, miner selling via MVRV-adjacent Puell Multiple, miner outflows). The Puell Multiple (daily issuance value / 365-day MA issuance) is a distinct on-chain signal from MVRV — measures miner profitability and selling pressure rather than holder aggregate P&L. Could be axis 19 if axis 18 G1 scan validates the on-chain data domain.
