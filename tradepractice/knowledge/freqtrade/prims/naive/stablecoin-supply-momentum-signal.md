---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T06:13:51+10:00
cycle: 135
---

---

**CYCLE 135 — ANALYST RESULT**

```
from: analyst
subject: analyst-result
cycle: 135
prim: stablecoin-supply-momentum-signal
project: freqtrade
level: naive
axis: 22
signal-class: crypto-market liquidity proxy (meta-signal — no standalone entries)
```

---

## Prim: stablecoin-supply-momentum-signal
**Level:** naive — **SUPERSEDED** by intermediate (cycle 137) | **Project:** freqtrade | **Axis:** 22nd regime axis

### Rationale for new axis (not intermediate elevation)

All 24 freqtrade intermediate prims already have sophisticated versions. The conductor directive fallback — "explore new angles" — applies. Axis 22 is the only remaining orthogonal demand-side signal class: **total crypto-ecosystem USD-equivalent capital reserves**, measured via USDT + USDC combined circulating supply. No existing axis captures this — axis 18 measures what BTC holders do with BTC; axis 21 measures regulated institutional ETF flow; axis 22 measures the full dry-powder reservoir across all participants and all vehicles.

### Rule

`stablecoin_z` = (supply_growth_7d − mean_90d) / std_90d  
where `supply_growth_7d` = (USDT+USDC supply[t] / supply[t−7]) − 1.

- **stablecoin_z > +1.5** → AMPLIFY sister prim longs **1.06×**
- **stablecoin_z < −1.5** → SUPPRESS sister prim longs **0.92×**
- Neutral zone → 1.00×

Kelly α = 0.05 (naive floor). No standalone entries.

### Mechanism
Three causal pathways: (1) **Dry powder accumulation** — institutions convert USD → stablecoin before executing large BTC buys over multiple sessions (T+1 to T+7 lead); (2) **DeFi yield recycling** — protocol reward stablecoins rotate to BTC (T+2 to T+14); (3) **Retail on-ramp** — biweekly stablecoin accumulation before BTC purchase (T+3 to T+10).

### Evidence — 3 academic anchors
| Source | Finding |
|--------|---------|
| **Ante, Fiedler & Strehle (2021, FRL)** | VAR: USDT issuance → positive BTC returns T+1 to T+3; t-stat > 2.0; n=1,461 daily obs |
| **Griffin & Shams (2020, JF)** | IRF: +1.5% cumulative 3-day BTC return post-USDT issuance (mechanism debated but empirical finding robust) |
| **Saggu & Ante (2023, FRL)** | β=0.31 stablecoin market cap changes vs BTC intraday return (p<0.01; holds at 1h/4h/24h) |

### Key advantages over axis 21 (ETF flow)
| Dimension | Axis 21 (ETF flow) | Axis 22 (stablecoin supply) |
|-----------|--------------------|-----------------------------|
| Data window | 27 months (Jan 2024–) | 75 months (Jan 2020–) |
| Participants captured | Regulated institutional only | Retail + DeFi + institutional (total) |
| Mechanism | AP arbitrage (mechanical, specific) | Capital reserve accumulation (diffuse, broader) |
| Data source | CoinGlass API (requires key) | DeFiLlama (free, no key) |

### G1 Blocking Gates
- G_DATA: DeFiLlama API test + cross-chain dedup verification
- G1: frequency scan (n≥10 amplify events in 75m data; 7-day separation)
- Lead/lag: regression slope on next-3d BTC return vs stablecoin_z_{t−1} positive
- Independence: ρ(stablecoin_z, axis 7) < 0.70; ρ(stablecoin_z, axis 21) < 0.70

### 4 anti-prim gates
(A) frequency < 8 events at any threshold ≤ +2.0σ; (B) no T+1 predictive slope; (C) ρ ≥ 0.70 vs axis 7; (D) ρ ≥ 0.70 vs axis 21

### Bank state after cycle 135
| Tier | Freqtrade | Polymarket |
|------|-----------|-----------|
| Naive | **20** (+1: stablecoin-supply-momentum) | ~21 |
| Intermediate | 24 | ~21 |
| Sophisticated | 24 | ~23 |
