---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T00:19:12+10:00
cycle: 52
---

---

## Prim: resolution-confirmation-arbitrage
**Level:** naive
**Project:** polymarket
**Class:** 12th polymarket prim — first post-confirmation oracle convergence mechanism

---

### Rule

```
wire_service_confirms_outcome(market_id) == True
AND confirmed_side_price < 0.90
AND no_active_uma_dispute(market_id)
AND resolution_type(market_id) == "W"   # unambiguous binary
→ BUY confirmed side. α=0.10 Kelly floor. Hold to oracle settlement ($1.00).
```

---

### Mechanism

Three-component delay between public wire confirmation and full price convergence:

1. **Information processing lag (5–60 min):** retail PM participants discover event outcomes sequentially via social media; only institutional desks have direct wire feeds
2. **UMA oracle mechanics (1–48h):** optimistic oracle challenge window — market cannot settle to $1.00/$0.00 until the window expires unopposed; rational holders wait rather than sell at $0.97
3. **Last-mile liquidity reluctance ($0.90–$1.00):** thin ask-side depth in final convergence range; holders prefer oracle settlement at $1.00 over early liquidity provision at $0.97

**Key distinction from binary-arb-completeness:** binary-arb buys BOTH YES+NO BEFORE resolution using ΣP<1 structural gap. This prim buys ONE leg AFTER outcome is publicly confirmed, with convergence guaranteed by oracle mechanics — not contract math.

**Key distinction from financial-market-lead-lag:** that prim uses a probabilistic price signal (CME FedWatch). This prim uses a binary factual confirmation — a certainty update, not a probability update.

---

### Critical unknowns

- **Semantic matching:** mapping wire confirmation to PM resolution criteria is the same unsolved NLP problem as cross-venue arb Type W/X/Y/Z — primary loss mode if classifier leaks ambiguous contracts
- **Oracle dispute post-entry:** a challenge filed after entry converts near-certain convergence to directional exposure; real-time oracle monitoring required
- **Bot competition:** largest gaps (YES < 0.70) will be consumed sub-second by Tier 1 bots; viable window is Tier 2 (5–60 min info-processing lag) and Tier 3 (oracle mechanics hold)

---

### Files written

- `knowledge/polymarket/prims/naive/resolution-confirmation-arbitrage.md` — created
- `knowledge/epistemic-index.md` — new row appended to Polymarket Naive table
- `knowledge/conditions-log.md` — entry appended
