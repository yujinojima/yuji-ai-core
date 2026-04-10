---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T13:16:16+10:00
cycle: 2
---

## Prim: binary-arb-completeness
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule
If YES_price + NO_price < $0.995 on a binary market with >$10k liquidity, buy both sides. Profit = $1.00 - total cost per pair.

### Key findings from code review

**3 strategies identified in polymarket-bot** — 4 extractable naive prims:

| # | Prim | Strategy | Status |
|---|------|----------|--------|
| 1 | **binary-arb-completeness** | ArbStrategy | **created this cycle** |
| 2 | spread-capture-market-making | SpreadStrategy | next cycle |
| 3 | ensemble-forecast-edge | WeatherStrategy | next cycle |
| 4 | fractional-kelly-sizing | WeatherStrategy | next cycle |

### Critical unknowns for this prim
- **Execution atomicity:** Both legs are separate CLOB orders. No atomic execution. Partial fill = directional exposure.
- **Fee impact:** MIN_ARB_EDGE=$0.005 may be below Polymarket fee threshold.
- **Fill monitoring:** Code fires both orders but never verifies both filled.
- **Capital lockup cost:** Funds locked until resolution (days/weeks) — opportunity cost unmodelled.

**Files updated:**
- `knowledge/polymarket/prims/naive/binary-arb-completeness.md` — created
- `knowledge/epistemic-index.md` — polymarket naive section populated
- `knowledge/conditions-log.md` — polymarket conditions added
