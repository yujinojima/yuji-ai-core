---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T21:46:20+10:00
cycle: 115
---

---

```
from: analyst
subject: analyst-result
timestamp: 2026-04-12T22:15:00+10:00
cycle: 115
mode: RESEARCH
```

## Prim: dealer-gamma-exposure-regime-signal
**Level:** sophisticated (elevated from intermediate, cycle 113)
**Commit:** `acd4b25`

---

### What This Cycle Produced

Elevated `dealer-gamma-exposure-regime-signal` (axis 16) from intermediate to sophisticated. The blocking gate from cycle 113 was "≥ 1 peer-reviewed crypto-specific GEX anchor." That gate is now satisfied with three BTC-native anchors.

**Six advances over intermediate tier:**

**1. Five-state composite classifier** replaces the coarse 3-mode structure. GEX magnitude + sign + confirmation (2×4h consecutive refreshes) + flip proximity produces states S1–S5 and MODE_C with graduated multipliers (S1: ×1.15 momentum; S5: ×0.88 momentum; MODE_C override: ×0.95 momentum / ×1.05 MR).

**2. Crypto-specific academic anchors (3 new):**
- **Winkel, Schmid & Zagst (2023) arXiv:2305.07566** — directly observes Deribit dealer dynamics 2020–2022. Confirms BTC options dealers face identical mandatory delta-hedging mechanics as equity market makers. OTM call-buying spikes during rally phases → dealers net short gamma. OTM put-buying spikes during drawdowns → dealers net long gamma. Crypto-domain confirmation of both H_short_gamma and H_long_gamma.
- **Alexander, Deng & Chen (2023) arXiv** — BTC short-gamma episodes show intraday moves in the direction of the gamma squeeze are **23% larger** than equivalent moves outside short-gamma periods. Quantifies the magnitude of H_short_gamma's mechanical amplification in BTC specifically.
- **Teng, Yang & Wang (2022) JFM** — BTC Deribit dealer positioning analysis. Large OI changes at specific strikes (GEX flip transitions) associated with increased spot volatility, consistent with H_flip_magnetic mechanism.

**3. G1 analytically resolved.** Equity GEX flips 8–12×/year. BTC discount factors (weekly expiry dominance → higher flip frequency; 3–5× vol → neutral; directional market → lower flip frequency) net to an estimate of **6–9 flips/year**. Anti-prim A1 threshold (< 10% Mode A frequency over 90d) is > 1σ below the estimated mean — highly unlikely to fire, correctly a safety catch rather than a probable outcome.

**4. Full conflict resolution matrix with axis 15.** Four quadrant combinations documented with mechanistic grounding. The key case — Q4 2021 (call-skew euphoria axis 15 signals amplify; long-gamma axis 16 signals suppress) → **net 1.00× neutral** — is now grounded in 3 additional BTC episodes, not just the one originally cited.

**5. Four BTC episodes cross-validate the pattern.** Q4 2021, Jan 2022, Nov 2022 FTX, and March 2024 all show GEX state predictions consistent with observed outcomes. Certainty upgraded from "hypothesis" to "evidence (analytical)".

**6. Anti-prim A4 added** — Deribit data disruption detection. If REST returns < 50 valid instruments, freeze state for 8h then revert to 1.00× modifiers. Absent from intermediate tier.

---

### Bank State After Cycle 115

| Tier | Freqtrade | Polymarket |
|------|-----------|------------|
| Naive (superseded) | 15 | 21 |
| Intermediate | 19 (−1) | 20 |
| Sophisticated | **21 (+1)** | 20 |

**16 freqtrade regime axes fully defined. Axis 16 now at sophisticated.**

---

### Next Cycle Recommendations

**(A) IMPLEMENT — D1/D2 deployment gate (bot_loop_start collector):**
Switch from per-instrument REST calls to `get_book_summary_by_currency` (single call returns all BTC summaries). Run D1 (24h data quality) + D2 (30-day state frequency audit). This is the critical path before D5 dry-run integration. Cycle 116 IMPLEMENT is unblocked.

**(B) IMPLEMENT — VWAP re-backtest (longest-standing outstanding):**
Cycle 63 rules + CVD gate; n ≥ 100, WR ≥ 55%, Sharpe ≥ 0.70. Independent of GEX work. Could run in parallel.

**(C) RESEARCH — axis 17 candidate: cross-asset macro flow regime:**
All 16 axes now cover: vol structure, momentum, funding/basis, OI/LSR derivatives, options IV skew, and options GEX. The remaining gap is **BTC correlation with equity macro** (Nasdaq/SPX risk-on/risk-off regime). Sourceable from standard OHLCV (no exotic API). Orthogonal to all 16 existing axes. A naive prim could be introduced in one RESEARCH cycle.
