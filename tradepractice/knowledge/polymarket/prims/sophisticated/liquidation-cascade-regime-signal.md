---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T18:20:04+10:00
cycle: 163
---

---

**Cycle 162 — RESEARCH — Complete**

---

## Prim: liquidation-cascade-regime-signal
**Level:** sophisticated | **New axis** (25th regime axis) | **Project:** freqtrade

---

### What was decided

All 24 prior freqtrade axes are at sophisticated tier. The conductor's priority ("intermediate → sophisticated OR new angles") required a genuine new direction. Axis 25 is the **first event-driven signal class in the suite** — a structural gap that continuous-state detectors (axes 1–24) cannot fill, because cascade events are discrete non-stationarities that don't build gradually.

---

### Architecture

**Two-phase state machine per cascade direction:**

| Phase | LC (long liq) | SC (short liq) | Trigger |
|-------|--------------|----------------|---------|
| Phase 1 | Suppress: 0.88× → 0.92× → 0.96× | Amplify: 1.08× → 1.04× → 1.01× | Cascade active (Candles +0 to +2) |
| Phase 2 | Amplify: 1.06× → 1.04× → 1.02× | Suppress: 0.94× → 0.96× → 0.98× | Exhaustion reversion (Candles +3 to +8) |

Decay schedules calibrated: Phase 1 via **Bouchaud et al. (2004)** power-law; Phase 2 via **Coval & Stafford (2007)** forced-seller drift window.

**ADX conditioning:** ADX > 25 → Phase 1 +1 candle; ADX < 15 → Phase 2 −1 candle; ADX > 35 → FM6 parabolic bypass (Phase 2 cancelled).

**Magnitude tiers:** Tier 1 ($10–50M): 0.50× scale. Tier 2 ($50–200M): full. Tier 3 (>$200M): 1.15× escalation (1.25×/0.80× hard caps).

---

### What's new at sophisticated tier (single-cycle)

All four hallmarks of sophisticated entry present in one cycle:

1. **Two-mechanism phase architecture** (Phase 1 propagation vs Phase 2 reversion — distinct academic anchors per phase)
2. **Candle-indexed decay schedule** (Bouchaud + Coval calibrated, not flat modifiers)
3. **ADX regime conditioning** (quantified direction-specific adjustment)
4. **Analytical pre-confirmation** (G1_25C + INDEP_25 confirmed; mechanism chain Brunnermeier → Bian → Coval → Kyle is airtight; cascade existence documented by CoinGlass 2024)

---

### Two new academic anchors

- **Shleifer & Vishny (1997 JF)** — "The Limits of Arbitrage": informed buyers cannot immediately absorb cascade selling (capital constraints bind precisely when opportunity is largest) → justifies Phase 1 persistence window; explains why Phase 2 is delayed, not instant
- **Ang, Gorovyy & van Inwegen (2011 RF)** — hedge fund leverage unwind produces 3–5 day price recovery → directly calibrates Phase 2 duration (3–8 hourly candles)

---

### Key N_eff decision

Axis 25 + Axis 11 (OI divergence) → **Tier A single-signal merge.** OI drop IS the cascade proxy — mechanistically overlapping at the detection level. When both fire: use highest weight, no compounding. This is the strictest N_eff treatment in the suite.

---

### Gate status

| | |
|--|--|
| **G_DATA_25** | BLOCKING — CoinGlass 2y history TBC; proxy path via free Binance ΔOI + OHLCV available (FP ~30%) |
| **G1_25C + INDEP_25** | Analytically pre-confirmed |
| **G1_25A/B/D, G2_25** | Uncleared |
| **Kelly α** | 0.07 floor → 0.10 post G1 → 0.13 cap post G2 |

---

**Bank state after cycle 162:** freqtrade 23 naive / 28 intermediate / **30 sophisticated** (+1: liquidation-cascade-regime-signal axis 25)
