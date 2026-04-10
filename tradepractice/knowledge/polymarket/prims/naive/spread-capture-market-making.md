---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T13:39:50+10:00
cycle: 2
---

---

## Prim: spread-capture-market-making
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule
If bid-ask spread is $0.03–$0.15 and liquidity >= $5,000, place inside-spread limit orders on both sides. Profit = captured spread if both legs fill.

### Mechanism
Exploits the liquidity premium: impatient traders pay wide prediction market spreads (3-15%) for immediacy. Market makers earn the spread by bearing inventory risk. Wide spreads in prediction markets vs traditional markets reflect lower liquidity and higher information asymmetry.

### Conditions
- Works when: Wide spreads ($0.03–$0.15); stable prices; balanced flow; high liquidity (>$5k); long time to resolution
- Fails when: Spread < $0.03 (fees eat profit); spread > $0.15 (illiquid/toxic flow); information event imminent; one-sided flow; competing MM bots

### Evidence
- Source: code extraction
- Certainty: guess
- Data: pending — zero live trades
- Citation: `polymarket-bot/src/strategies/spread.py`

### Limitations
1. **No inventory management** — partial fills create unbounded directional exposure
2. **No adverse selection defence** — informed traders pick off stale quotes
3. **Fixed ORDER_SIZE=10** — no dynamic sizing for spread width or volatility
4. **No order cancellation/refresh** — stale quotes increase risk
5. **Fee impact unquantified** — CLOB fees may consume spread on tighter markets
6. **No queue priority model** — competing MMs front-run quotes
7. **Confidence hardcoded 0.5** — no edge estimation

### Implementation
- File: `polymarket-bot/src/strategies/spread.py`
- Parameters: MIN_SPREAD=0.03, MAX_SPREAD=0.15, ORDER_SIZE=10.0
- Key logic: `scan()` places BUY YES at `best_bid + tick`, SELL YES at `best_ask - tick`

### Conditions Log Entry
- Works when: Spread $0.03–$0.15, liquidity >= $5k, balanced flow, stable market
- Fails when: Narrow spread (<fees), toxic flow, one-sided volume, imminent resolution
- Last validated: never

---

### Assessment: remaining extractable prims

| # | Prim | Strategy | Status |
|---|------|----------|--------|
| 1 | binary-arb-completeness | ArbStrategy | done (cycle 2) |
| 2 | **spread-capture-market-making** | SpreadStrategy | **created this cycle** |
| 3 | ensemble-forecast-edge | WeatherStrategy | next cycle |
| 4 | fractional-kelly-sizing | WeatherStrategy | next cycle |

**Files updated:**
- `knowledge/polymarket/prims/naive/spread-capture-market-making.md` — created
- `knowledge/epistemic-index.md` — polymarket naive row added
- `knowledge/conditions-log.md` — polymarket spread conditions added
