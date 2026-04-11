---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T00:00:00+10:00
cycle: 52
---

## Prim: resolution-confirmation-arbitrage
**Level:** naive
**Project:** polymarket
**Parent:** none (12th polymarket prim class)

### Rule

```
wire_service_confirms_outcome(market_id) == True
AND confirmed_side_price < 0.90        # YES confirmed → YES still < 0.90
AND no_active_uma_dispute(market_id)   # oracle not challenged
AND resolution_type(market_id) == "W"  # unambiguous binary (semantic_risk.py)
→ BUY confirmed side. α=0.10 Kelly floor. Hold to oracle settlement ($1.00).
```

Wire services: Reuters, AP, Bloomberg (machine-readable feeds, not social media).
Confirmed-YES: buy YES when confirmed outcome = YES AND YES_price < 0.90.
Confirmed-NO: buy NO when confirmed outcome = NO AND NO_price < 0.90 (i.e., YES_price > 0.10).

### Mechanism

Three-component delay between public wire confirmation and full price convergence to $1.00/$0.00:

**Component 1 — Information processing lag (5–60 min):** Retail PM participants discover confirmed event outcomes sequentially via social media, not wire services. Institutional desks with direct wire feeds are a minority. Each new buyer arriving pushes YES toward $1.00, but the full retail cohort takes 5–60 min to fully update.

**Component 2 — UMA oracle mechanics (1–48h):** Polymarket uses an Optimistic Oracle (UMA). After the initiator submits the resolution price, a 24–48h challenge window opens. Market price cannot settle to exactly $1.00/$0.00 until this window expires unopposed. Rational late participants holding YES see no legal settlement until oracle confirms — and some wait, leaving the price below $1.00.

**Component 3 — Last-mile liquidity reluctance ($0.05–$0.10):** The final convergence range (YES $0.90→$1.00) has thin ask-side depth. YES holders who would provide sell-side liquidity at $0.95–$0.99 either already exited at lower prices, or are rationally waiting for oracle settlement at $1.00 rather than selling early at $0.97. This creates a structural thin-book effect in the final cents.

**Distinction from binary-arb-completeness:**
binary-arb-completeness exploits ΣP < 1 **before** event resolution — buys BOTH YES+NO simultaneously, profit guaranteed by contract math. This prim exploits a single-contract price NOT at $1.00/$0.00 **after** event outcome is publicly confirmed — buys ONE side only, convergence guaranteed by oracle settlement mechanics, not contract math.

**Distinction from financial-market-lead-lag:**
financial-market-lead-lag uses a probabilistic price signal (CME FedWatch probability) as the primary input. This prim uses a binary factual confirmation (wire service reports event occurred) — not a probability update, but a certainty update.

### Conditions

**Works when:**
- Wire service confirmation of binary event outcome is unambiguous and machine-readable (structured feed, not headline parsing)
- PM YES price still in range where edge exceeds fees: YES < 0.90 for confirmed-YES (geopolitics: any gap; politics: gap > 4pp needed)
- No active UMA dispute (query via oracle dispute API before entry)
- Contract resolution criteria clearly maps to confirmed fact — resolution_type = "W" per semantic_risk.py Type W/X/Y/Z classifier (reuse existing cross-venue arb classifier)
- Liquidity ≥ $5k; bid-ask ≤ $0.06 (last-mile depth is thin; wider tolerance than pre-resolution prims)
- Category: geopolitics (0% fee, clean binary outcomes); politics (4% fee, elections/appointments with clear binary resolution)
- Contract is single-leg binary (NOT neg_risk multi-market bundle — those settle collectively)

**Fails when:**
- Resolution criteria ambiguous: confirmed fact ≠ contract resolution criteria (Type X/Y/Z contract — oracle may resolve differently from wire service report)
- UMA dispute is active: challenger has contested initial oracle price submission — outcome reverts to uncertain; position becomes directional exposure, not resolution arb
- Wire service reports outcome but contract has "if and only if" language, effective-date conditions, or scope carveouts that the wire report does not address
- Price already above $0.92 (gap < 0.08; net of taker fees, return < 0 for politics 4% category, marginal for geopolitics)
- Contract is neg_risk multi-market bundle (resolution is conditional on sibling markets)
- Crypto category (7.2% fee rate, highest oracle dispute rate by category — mechanism structurally impaired)
- Sports category (resolution criteria frequently involve official standings/appeals; dispute rate elevated)

**Best pairs:**
- Geopolitics (0% fee) + clear binary outcomes (war ceasefire achieved/not, sanctions imposed/not, leader removed/not)
- Politics — elections with confirmed winner (0–4% fee; AP/Reuters call = unambiguous confirmation)
- Politics — appointments confirmed by legislative body (confirmation vote = wire-confirmable binary)

**Best timeframe:**
- Entry: within 0–60 min of wire confirmation (75% of arb window closes within 1h; arxiv 2508.03474)
- Hold: 1–48h to oracle settlement; no active management required — theta works via oracle mechanics
- Exit: oracle settlement at $1.00 OR manual exit if UMA dispute is filed post-entry (convert to position-management mode)

### Evidence

| Source | Certainty | Data | Citation |
|--------|-----------|------|----------|
| IMDEA Madrid arxiv 2508.03474 | high | 75% of PM arb orders execute within 1h post-resolution; $40M extracted Apr2024–Apr2025 | Rodríguez et al. 2025 |
| Della Vedova SSRN 6191618 | medium | 2.52c/contract bot execution advantage; resolution-lag component included in model | Della Vedova 2025 |
| UMA Optimistic Oracle documentation | high | 24–48h challenge window after initial price submission; dispute rate ~3–8% by category (internal) | UMA Protocol 2024 |
| Gürkaynak, Sack & Swanson 2005 AER | medium | Measurable implementation delay between information availability and price in fast institutional markets | Gürkaynak, Sack & Swanson 2005 AER |

Overall evidence certainty: **hypothesis** — mechanism is theoretically sound and consistent with all four sources; zero own-data trades; resolution-specific window not isolated in any PM paper.

### Limitations

1. **Latency competition:** Resolution arb is the most latency-sensitive prim in this bank. Tier 1 bots (<100ms) will consume the largest gaps (YES < 0.70) in sub-second. The viable window is Tier 2 (5–60 min) for retail-side price discovery delay, and Tier 3 (1–48h) for the oracle mechanics window. This prim targets Tier 2–3 specifically — NOT a bot-speed play.

2. **Oracle dispute risk:** A UMA challenge filed AFTER entry converts a near-certain convergence trade into an unresolved directional position. Dispute rate ~3–8% by category (UMA internal documentation). This is the primary asymmetric risk. Pre-entry oracle status check is mandatory; post-entry real-time monitoring required.

3. **Semantic matching:** Mapping wire service headline to a specific PM question's resolution criteria is an unsolved NLP problem at production quality. This is the same barrier as cross-venue-semantic-arb Type W/X/Y/Z classification — reuse semantic_risk.py classifier but requires its own validation corpus for resolution-time matching.

4. **Reaction validated:** untested. No own-data trades.

### Implementation

New files required:
- `src/strategies/resolution_arb.py` — main strategy: wire confirmation input, oracle dispute check, price gap check, Type W filter, Kelly sizing, entry and hold-to-settlement logic
- `src/utils/uma_oracle_monitor.py` — real-time oracle dispute status monitoring (UMA GraphQL API or event websocket)

Reuse existing files:
- `src/classifiers/semantic_risk.py` — Type W/X/Y/Z classifier for resolution criteria ambiguity veto (already built for cross-venue arb)
- `src/risk/kelly.py` — fractional-kelly-sizing sophisticated; α=0.10 floor

New files required (feeds):
- `src/feeds/news_wire_monitor.py` — Reuters/AP/Bloomberg structured wire integration; event confirmation extractor

**BLOCKING before any live deployment:**
Wire-to-contract semantic matcher: must map wire confirmation to specific PM question with resolution criteria match confidence ≥ 0.90. Without this, Type X/Y/Z oracle disputes are unvetted and the prim's primary failure mode is uncontrolled.

### Files updated

- `knowledge/polymarket/prims/naive/resolution-confirmation-arbitrage.md` — created (this file)
- `knowledge/epistemic-index.md` — new row appended to Polymarket Naive table
- `knowledge/conditions-log.md` — entry appended
