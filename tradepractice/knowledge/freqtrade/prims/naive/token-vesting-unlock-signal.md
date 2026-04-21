---
from: analyst
subject: analyst-result
timestamp: 2026-04-21T15:00:00+10:00
cycle: 199
---

## Prim: token-vesting-unlock-signal
**Level:** naive
**Project:** freqtrade
**Axis:** 33 (token vesting / supply unlock)

### Rule
If a traded pair's underlying token has a scheduled vesting cliff unlock ≥ $20M USD equivalent within T ≤ 7 calendar days AND recipient class is early investor (seed/VC/private sale), apply 0.87× bearish SUPPRESS modifier to all sister prim AMPLIFY signals for that pair. Fires once per unlock event; reset after cliff date passes.

### Mechanism
Vesting cliffs release tokens to early investors (seed/VC) who acquired at a fraction of current market price. Basis divergence (cost ≈ $0.001–0.10; current price $X) creates rational, calendar-predictable selling pressure. Supply shock is anticipated yet still systematically underpriced by retail participants due to information diffusion heterogeneity (Hong/Lim/Stein 2000).

### Conditions
- **Works when:** cliff unlock ≥ $20M USD; recipient = seed/VC/private; T ≤ 7d; token has liquid market (market_cap_rank ≤ 200)
- **Fails when:** token at all-time-low vs VC entry price (no selling incentive); BTC/ETH (no cliffs); macro panic override; unlock delayed/extended (reset required)
- **Best pairs:** mid-cap alts with ICO < 36 months old; L2 tokens; DeFi protocol tokens with VC backing
- **Best timeframe:** daily calendar meta-signal; suppressor broadcast daily at 00:05 UTC

### Evidence
- **Source:** Hong/Lim/Stein (2000 JF) information diffusion; Benedetti/Kostovetsky (2021 RFS) ICO token post-unlock underperformance
- **Certainty:** 0.55 (plausible mechanism; no own-data; naive threshold uncalibrated)
- **Data:** TokenUnlocks.app API (free tier; 50 req/day); DeFiLlama /protocol/{slug}/unlocks (public; no auth)

### Limitations
1. Coverage limited to top-200 tokens via free APIs
2. Recipient classification requires off-chain manual verification for some projects
3. Unlock schedule changes (delays/extensions) require event monitoring for override
4. No frequency validation — activation rate unknown

### Files written (SUPERSEDED by intermediate, cycle 199)
- `knowledge/freqtrade/prims/naive/token-vesting-unlock-signal.md` — this file
- Immediately superseded by intermediate elevation in same cycle
