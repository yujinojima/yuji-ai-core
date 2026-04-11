---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T20:18:52+10:00
cycle: 38
---

Commit `84a8f3e`.

---

## Prim: financial-market-lead-lag
**Level:** sophisticated (refined from intermediate)
**Project:** polymarket
**Parent:** intermediate/financial-market-lead-lag

### Rule
**Mode A — Second-Wave (T+5–30 min post-release):** CME FedWatch ≥ 5pp shift on specific FOMC meeting contract within 30 min of CPI/NFP/PCE or 15 min of FOMC AND PM lags AND bid-ask ≥ 2% AND gap ≥ 6% → enter T+5 to T+30 min only (skip first 5 min HFT burst). α=0.10 Kelly floor.

**Mode B — Persistent Drift:** CME leads PM ≥ 3 consecutive trading days AND gap ≥ 8% AND bid-ask ≥ 3% AND no data release within 48h → buy PM in CME direction. α=0.10 Kelly floor.

**Both modes:** Single-meeting binary PM only (specific FOMC date, ≥25bp bracket); liquidity ≥ $10k; resolution > 2h; **fomc_pm_mapper.py classifier BLOCKING — no trade without it**.

### What Changed from Intermediate

| Dimension | Intermediate | Sophisticated |
|---|---|---|
| Mechanism anchor | "CME leads 63.4%" (Medium) | **Kuttner (2001 JME): fed funds futures = canonical policy surprise benchmark; Gürkaynak (2005 AER): sub-minute institutional update; lag = retail attention delay** |
| Mode A window | "30 min post-release" | **Second-wave only: T+5–T+30 min; Tier 1 HFT burst (73% of PM arb) clears first 5 min** |
| Competitive model | "73% bots, Mode B less competed" | **Stratified 3-tier: Tier 1 <100ms bots (NOT targeted), Tier 2 5–30 min (Mode A), Tier 3 1–3 days (Mode B)** |
| Frequency | Unspecified | **Mode A: 2–4/year; Mode B: 2–3/year; combined 4–7/year** |
| Statistical framework | Absent | **N=30 requires 4–8 years; WR margin ±18%; breakeven 52%; safe target 57%** |
| New sources | 6 | **8 (+Kuttner 2001 JME, +Wolfers & Zitzewitz 2004 JEP)** |
| Anti-prim escapes | 2 informal | **3 formal** |

### New Evidence for Elevation

| Source | Finding |
|---|---|
| **Kuttner (2001, JME) [NEW]** | Fed funds futures absorb monetary policy surprises efficiently — establishes CME FedWatch as the canonical "correct" probability benchmark; any PM deviation = measurable retail lag, not informed disagreement |
| **Wolfers & Zitzewitz (2004, JEP) [NEW]** | PM are slower to incorporate complex financial/economic information than political events — specific mechanism for why CPI/NFP interpretation creates Mode A lag (requires macro-financial expertise) |

### Stratified 3-Tier Model

| Tier | Who | Speed | What they operate |
|---|---|---|---|
| 1 | HFT bots | <100ms | Mechanical PM arb — 73% of profits |
| **2** | **Human arbitrageurs, sophisticated PM players** | **5–30 min** | **Mode A window: CME updated, PM stale** |
| 3 | Retail PM participants | Hours to days | Mode B window: attention allocation lag |

### Key Numbers

| Metric | Value |
|---|---|
| CME leads PM | **63.4% of FOMC cycles** (practitioner, Medium) |
| Average PM lag | **~1.44 days** (practitioner, Medium) |
| Mode A frequency | **2–4/year** |
| Mode B frequency | **2–3/year** |
| N=30 deployment horizon | **4–8 years** (FOMC calendar constrained) |
| WR margin at N=30 | **±18%** (95% CI, Wald) |
| Breakeven WR at 4% fee | **52%** |
| Safe WR target | **57%** |

### Anti-Prim Escape Hatches (3 Formal)
- **(A) Gap compression**: rolling 20 Mode A events → median gap at T+5 mark < 4% → second-wave absorbed by faster arbitrageurs → Mode A anti-prim
- **(B) Null WR**: own-data 30 combined trades → WR < 52% → mechanism not exploitable at available execution → full anti-prim
- **(C) Calendar collapse**: Fed steady-state policy → < 2 Mode A events/year for ≥ 3 consecutive years → FOMC-calendar frequency anti-prim (not a parameter problem)

### Bank State After Cycle 38

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | 0 |
| Intermediate | 0 | **0** |
| Sophisticated | 7 | **8** |

**All 15 prims at sophisticated tier.**

### Next Cycle Recommendation
**(A) IMPLEMENT** — `fomc_pm_mapper.py` is the single BLOCKING dependency. Bounded: retrieve last 20 resolved Polymarket Fed questions from Gamma API; label each as single-meeting-binary-clean vs exclude; build classifier; validate. Historical data only — no live infrastructure needed. Unlocks the only prim with zero own-data validation.
**(B) BACKTEST-ANALYSIS** — hidden-bullish-rsi-divergence escape hatch (B) precursor is strong (cycle 37: WR 30% vs regular-div 62.5% at n=10). 28-cell plateau test is the next binary gate: if no plateau → definitive anti-prim.
**(C) IMPLEMENT** — funding-rate-crowding-reversal escape hatch (B): conditional sister-prim WR test at recalibrated 0.06% threshold. Cheapest freqtrade validation.

Recommend **(A)**.
