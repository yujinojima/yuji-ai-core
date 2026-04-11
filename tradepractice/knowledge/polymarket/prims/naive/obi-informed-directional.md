---
name: obi-informed-directional
level: naive
project: polymarket
parent_prim: none
created: 2026-04-11
last_validated: never
reaction_validated: assumed
---

## Prim: obi-informed-directional
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule
If Order Book Imbalance Ratio `IR = (V_bid − V_ask) / (V_bid + V_ask) > +0.65`, BUY YES. If `IR < −0.65`, BUY NO. Hold until IR decays below 0.30, price target hit, or max 30-minute hold. Size via fractional-kelly-sizing prim.

### Mechanism
Informed traders accumulate on one side of the CLOB before a price move, creating a measurable depth imbalance before the quote updates. The imbalance signal leaks directional intent: IR > 0.65 means bid-side volume comprises ≥ 82.5% of total depth — structural buyer dominance that statistically precedes upward price moves.

In prediction markets specifically: participants with private information (breaking news, insider poll data) place limit orders to avoid market impact, creating OBI buildup before the market reprices. The edge window is short — seconds to minutes before arbitrageurs and other MM bots close the gap.

### Conditions
- Works when: illiquid-to-moderate markets (liquidity $1k–$50k); price in $0.20–$0.80 range; time-to-resolution > 2h; genuine depth concentration (not thin-book artefact); imbalance persists ≥ 3 consecutive snapshots
- Fails when: wash-trading-inflated volume distorts IR (Columbia Nov 2025: 20–60% of Polymarket volume is wash); thin books (< $500 total depth) where single order creates false IR; price near $0/$1 (spread auto-compresses, imbalance is structural not informational); market already efficient (liquidity > $50k — bots absorb imbalance in <200ms); imminent resolution (IR volatility extreme, mechanism undefined)
- Best pairs: Politics/finance, geopolitics markets (0–4% fee; lower friction per trade)
- Best timeframe: real-time WebSocket tick; signal window 30s–5min; NOT for slow-moving or >5 day horizon markets

### Evidence
- Source: single academic paper (microstructure)
- Certainty: hypothesis — directional accuracy 58% at IR > 0.65 threshold from Bawa (arxiv 2603.03152); no own-data backtest
- Scope: Polymarket CLOB binary markets
- Falsifiability: testable — 58% directional WR at IR > 0.65, minimum 100 trade sample
- Data: 0 own trades; academic finding: OBI R² = 0.65 for short-interval variance prediction; IR > 0.65 → 58% directional accuracy (Bawa)
- Citation: [Navnoor Bawa — Order Flow and Price Discovery in Prediction Markets (arxiv 2603.03152 or Bawa Substack)](https://navnoorbawa.substack.com)

### Limitations
1. **Single source** — 58% accuracy claim from one researcher; not independently replicated
2. **Wash trading contamination** — 20–60% of Polymarket volume is wash (Columbia Nov 2025); IR computed from wash-inflated depth is unreliable. Need wash-adjusted depth computation before IR is meaningful
3. **No hold horizon defined** — naive rule exits at "IR decays below 0.30 or 30 min." Optimal hold duration is unknown and likely market-specific
4. **Signal decay rate unknown** — at what speed does a true IR > 0.65 signal decay into noise? Professional MM bots with <200ms refresh absorb imbalance fast
5. **No fee model** — 5% weather taker fee requires WR ≥ 52.5% breakeven; 58% is marginal; 0% geopolitics taker gives 8pp buffer. Category selection matters
6. **Single threshold** — IR = 0.65 is not validated across market liquidity tiers; may require dynamic calibration (e.g., IR_threshold = f(market_depth))
7. **No implementation** — no existing code in polymarket-bot; new module required
8. **Short-term signal only** — OBI reflects order book state at one moment; no multi-timeframe confirmation; persistence filter (3 snapshots) is heuristic not derived

### Implementation
- **File:** new `polymarket-bot/src/strategies/obi_directional.py`
- **Key function:** `compute_ir(orderbook) → float` using bid/ask cumulative depth to configurable price levels (e.g., top 5 levels)
- **Entry trigger:** `ir > IR_THRESHOLD (0.65)` → BUY YES; `ir < -IR_THRESHOLD` → BUY NO
- **Exit:** `abs(ir) < IR_EXIT (0.30)` OR time > MAX_HOLD (30 min) OR price target at `entry ± IR_DELTA (configurable)`
- **Sizing:** call `fractional-kelly-sizing` sophisticated prim with edge estimated as `abs(ir) - IR_THRESHOLD` as proxy for win-probability excess above 50%
- **Wash guard:** flag trades where `total_depth < MIN_DEPTH (500)` or `bid_count < 3 OR ask_count < 3` (thin-book filter)
- **Integration note:** the spread-capture sophisticated prim already checks `|IR| < 0.65` as an MM guard; OBI-informed directional activates precisely when MM exits. The two prims are structurally complementary — a state machine can route to MM when `|IR| < 0.65` and to directional when `|IR| > 0.65`

### Conditions Log Entry
- Works when: moderate liquidity ($1k–$50k), IR persists > 3 snapshots, price $0.20–$0.80, T-t > 2h, low-fee category
- Fails when: wash-trading-dominant volume, thin book (< $500), price near $0/$1, market already efficient (> $50k), imminent resolution
- Last validated: never
