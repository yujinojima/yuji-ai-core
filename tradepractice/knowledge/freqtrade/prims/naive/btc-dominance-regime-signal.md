---
from: analyst
subject: analyst-result
timestamp: 2026-04-15T01:35:00+10:00
cycle: 193
prim: btc-dominance-regime-signal
project: freqtrade
level: naive
axis: 31st regime axis
signal-class: intra-crypto capital rotation (meta-signal — no standalone entries)
---

> **SUPERSEDED by intermediate** — see intermediate/btc-dominance-regime-signal.md (cycle 193)

## Prim: btc-dominance-regime-signal
**Level:** naive (superseded by intermediate, same cycle)
**Axis:** 31st freqtrade regime axis
**Type:** meta-signal modifier (no standalone entries)

---

### Naive Rule

```
BTC.D = bitcoin_percentage_of_total_market_cap (CoinGecko /api/v3/global)
btcd_30d_pct = (BTC.D[t] - BTC.D[t-30d]) / BTC.D[t-30d]

btcd_30d_pct > 0  (BTC dominance rising)  → SUPPRESS non-BTC pair longs: 0.90×
btcd_30d_pct < 0  (BTC dominance falling) → AMPLIFY non-BTC pair longs: 1.10×
BTC pairs: 1.00× always (BTC is the ratio numerator — self-referential)
```

**Data source:** CoinGecko `/api/v3/global` → `bitcoin_percentage_of_total_market_cap` field
(free, no API key, JSON; updated ~00:00 UTC daily)

**Mechanism (naive):** Bitcoin's share of total crypto market cap reflects the direction of
intra-crypto capital flows. When BTC.D rises, capital concentrates in Bitcoin relative to
altcoins — altcoin prices underperform. When BTC.D falls, capital rotates into altcoins —
altcoin entries carry positive excess return expectation.

**Mechanistic distinction from existing axes:**
- **vs axis 17** (cross-asset macro correlation): axis 17 = BTC-SPX ρ (external market
  synchronization); axis 31 = BTC.D intra-crypto capital rotation (independent of equity markets)
- **vs axis 27** (social sentiment): axis 27 uses BTC.D ∈ [42%, 68%] as a VALIDITY GATE to
  confirm market structure; axis 31 makes the BTC.D TREND itself the signal
- **vs axis 29** (cross-pair correlation): axis 29 = return synchronization across crypto pairs;
  axis 31 = relative market cap share rotation (high sync can coexist with either rising or
  falling BTC.D; distinct information channels)
- **vs axis 30** (DXY): axis 30 = dollar vs BTC (external monetary); axis 31 = BTC vs altcoins
  (internal crypto rotation); diverged 2021 (DXY neutral, BTC.D fell 72%→40% altseason)

---

**Limitations at naive tier:**
1. No z-score threshold — fires continuously on any directional change (excessive noise; every
   day with slightly different BTC.D triggers modifier)
2. Stablecoin distortion unaddressed — USDT/USDC supply growth mechanically depresses BTC.D
   without any altcoin outperformance; naive fires spuriously
3. No validity bounds on BTC.D level — below 38% (stablecoin-dominated) or above 70%
   (crypto winter BTC consolidation) the rotation signal is structurally distorted
4. BTC ETF post-2024 regime change unaccounted — institutional ETF inflows compressed
   BTC.D structural range; naive modifiers are pre-ETF heuristics
5. New chain launches (SOL 2020, SUI 2023) dilute altcoin aggregate non-rotationally;
   naive cannot distinguish structural dilution from rotation

**Failure modes (5 identified):**
1. **FM1 — Stablecoin supply distortion**: USDT/USDC minting inflates total market cap → BTC.D
   falls → AMPLIFY fires without genuine altcoin rotation. Partially corrected at intermediate
   via 90d rolling z-score baseline (slow structural drift is in the baseline).
2. **FM2 — Continuous threshold noise**: naive fires every day; signal-to-noise ratio near zero
   for small directional moves. Resolved at intermediate via ±1.5σ gate.
3. **FM3 — New asset dilution**: New layer-1 chains enter market cap at high FDV → structural
   BTC.D decline; not capital rotation. Rolling baseline absorbs slowly but spikes can mislead.
4. **FM4 — Post-ETF regime shift**: Jan 2024 BTC spot ETF approval attracted institutional
   BTC demand → BTC.D range shifted upward; 0.90×/1.10× modifiers need post-ETF recalibration.
5. **FM5 — API rate limit / outage**: CoinGecko free tier 30 calls/min; no fallback data source
   at naive. Resolved at intermediate via CoinMarketCap Pro free-tier fallback.

---

**Superseded by intermediate (cycle 193):** z-score threshold ±1.5σ, validity gate [38%,70%],
three-channel academic mechanistic documentation, N_eff formalisation, G1 gate protocol,
stablecoin-adjusted baseline, CoinMarketCap fallback.
