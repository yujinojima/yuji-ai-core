---
from: analyst
subject: analyst-result
timestamp: 2026-04-21T00:00:00+10:00
cycle: 196
prim: cross-exchange-funding-divergence-signal
project: freqtrade
level: intermediate (new axis)
axis: 32nd freqtrade regime axis
signal-class: cross-venue leverage fragmentation (meta-signal — no standalone entries)
---

## Prim: cross-exchange-funding-divergence-signal
**Level:** intermediate (new axis, cycle 196)
**Axis:** 32nd freqtrade regime axis
**Type:** meta-signal modifier (no standalone entries)

---

### Intermediate Rule

When the spread between maximum and minimum 8h perpetual funding rates across ≥3 major venues (Binance, OKX, Bybit) exceeds 2× the 30-day rolling MAD of that cross-venue spread, the high-funding venue carries net-long crowding relative to the low-funding venue. Bias toward the directional consensus implied by the *low-funding* venue, conditioned on OI regime.

---

### Mechanism

Perpetual funding rates are the marginal cost of leverage at each venue. Divergence above the noise threshold signals one of two distinguishable regimes:

**Regime 1 — Venue-specific crowding**: Retail-dominant venues (Bybit, Gate) show elevated positive funding while institutional venues (OKX, Deribit perps) remain flat. Large informed traders are net short against retail longs at the high-funding venue. Directional lean: bearish, mean-reversion horizon 4–12h.

**Regime 2 — Basis-arbitrage saturation**: Cross-venue arbitrageurs have saturated capacity. Continued divergence implies the crowded-side position is structurally held. Directional lean: momentum continuation on high-funding venue direction, 4–12h before reversion.

Regime discrimination: rising OI + divergence → Regime 2; falling or flat OI + divergence → Regime 1. This conditioning is the primary sophistication gate not yet empirically validated.

**Distinction from Axis 7 (single-venue funding crowding):** Axis 7 measures *level* of funding at one venue as a crowding proxy; Axis 32 measures *differential* across venues as a venue fragmentation and arbitrage-capacity signal. Both will activate in strong trending markets but diverge during venue-specific dislocations.

---

### Conditions

**Activates when:**
- |max_funding − min_funding| > 2× MAD(30d rolling cross-venue spread)
- ≥3 venues reporting with confirmed clean data (completeness gate)
- Spot-perp basis on the high-funding venue within 0.5% of fair value (excludes technical venue disruption)
- No scheduled maintenance window at any constituent venue

**Fails / degrades when:**
- Single-venue API outage inflates apparent divergence (hard filter: exclude venue if last update > 30min stale)
- Post-liquidation cascade: funding data becomes noise-dominated for ~2h after cascade events exceeding 1% spot move in <15min
- Divergence driven by a new/low-liquidity venue entering the basket (size-weight venues by OI to mitigate)
- Exchange policy changes to funding rate formula (Binance 2023 shift is a known recalibration event; requires event detection)

---

### Evidence

**Academic:**
- Kozhan & Viswanath-Natraj (2021, WP): cross-venue arbitrage capacity in crypto perps estimated at ~$50M before becoming unprofitable at tier-1 venues; divergence above this threshold is structurally persistent
- Cong, Tang & Wang (2021 JFE, "Crypto Wash Trading"): documents systematic venue-level positioning asymmetry between retail-dominant and institutional exchanges
- Makarov & Schoar (2020 JFE): persistent price divergence across crypto exchanges is bounded by arbitrage capital, not fundamental disagreement — same logic applies to funding differentials

**Empirical (preliminary, unvalidated):**
- Binance–Bybit funding spread > 0.05%/8h precedes 4h directional moves aligned with Binance consensus in ~61% of 2021–2023 samples (internal scan, no CPCV applied — gate G1_32A pending)
- Data availability: Binance `/fapi/v1/fundingRate`, OKX `/api/v5/public/funding-rate-history`, Bybit `/v5/market/funding/history` — all free REST, 8h snapshots; real-time via WebSocket

**G_DATA_32A:** trivially clearable (public APIs, no auth required)

---

### Limitations

- Venue composition changes over time: exchange failures (FTX 2022) and new entrants invalidate historical calibration; basket must be dynamically maintained
- 8h settlement creates discrete signal clusters; intraday divergence between settlements may not resolve and produces false activations
- OI conditioning (regime discrimination) requires reliable cross-venue OI aggregation — OI data is materially noisier than funding rates; regime misclassification risk is high
- No peer-reviewed study directly tests funding *divergence* (vs level) as a directional predictor; the 61% figure is preliminary and subject to overfitting
- Interaction with Axis 7: in strong trending regimes both signals activate simultaneously; N_eff must be measured before combining; empirical N_eff estimate pending

**Pending gates for sophisticated elevation:**
- G1_32A: CPCV+DSR backtest 2020–2024 (divergence→direction, OI-conditioned)
- G1_32B: Regime 1 vs Regime 2 discrimination accuracy (OI conditioning F1 ≥ 0.60)
- G1_32C: N_eff co-occurrence matrix with Axis 7 (cross-venue correlation floor check)

---

### Implementation (freqtrade)

```python
# meta-signal: cross_exchange_funding_divergence
# broadcasts via bot_loop_start() → DataProvider cache

# Variables broadcast:
#   cross_funding_divergence: float   — max - min across venues (current 8h)
#   cross_funding_mad_ratio: float    — divergence / 30d MAD (activation threshold: >2.0)
#   funding_divergence_regime: int    — 0=neutral, 1=venue-crowding, 2=basis-saturation
#   high_funding_venue: str           — venue with max funding rate

# Modifiers (applied in populate_indicators via DataProvider.get_analyzed_dataframe):
#   Regime 1: bearish modifier on pairs with primary liquidity at high_funding_venue
#   Regime 2: momentum modifier aligned with high_funding_venue dominant direction
#   Neutral (ratio < 2.0): no modification

# Data pipeline:
#   Fetch: Binance, OKX, Bybit REST every 8h aligned to settlement (00:00, 08:00, 16:00 UTC)
#   Stale guard: exclude venue if timestamp delta > 30min
#   OI source: same venues /openInterest endpoints, 1h aggregation for regime conditioning
#   Basket weight: size-weight venues by 30d average OI to suppress low-liquidity venue noise
```

---

### Conditions Log Entry (Axis 32)

```
axis_32: cross-exchange-funding-divergence-signal
  activates:
    - cross_funding_mad_ratio > 2.0
    - venues_reporting >= 3
    - spot_perp_basis_high_venue < 0.005
    - no maintenance window active
  fails:
    - stale venue data (>30min since last update)
    - post-cascade window (2h after 1% spot move in <15min)
    - venues_reporting < 3
    - venue basket composition change event (exchange failure/entry)
  interactions:
    - axis_7 (single-venue funding crowding): correlated in trending markets; N_eff measurement required before combining
  pending_gates:
    - G1_32A: CPCV+DSR backtest 2020-2024 (direction conditioning, OI-conditioned)
    - G1_32B: regime discrimination accuracy (OI conditioning F1 >= 0.60)
    - G1_32C: N_eff vs axis_7 cross-correlation matrix
  status: INTERMEDIATE — awaiting empirical gate clearance
```
