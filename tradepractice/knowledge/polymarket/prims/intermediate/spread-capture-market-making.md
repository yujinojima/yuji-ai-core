---
name: spread-capture-market-making
level: intermediate
project: polymarket
parent_prim: spread-capture-market-making (naive)
created: 2026-04-10
last_validated: never
reaction_validated: assumed
---

## Situation

### Setup
A binary prediction market on Polymarket CLOB with sufficient spread and liquidity. Market maker places two-sided quotes to capture the bid-ask spread.

### Trigger
Spread width, market category fees, time-to-resolution, and inventory state all pass filter thresholds (see Conditions below).

### Reaction
- **Accepted:** Both legs fill. Spread captured minus fees. Inventory returns to neutral.
- **Rejected:** Only one leg fills (adverse selection). Directional exposure held through resolution. Binary settlement at $0 or $1 amplifies loss.
- **Unclear:** Both legs fill but price moves before refresh cycle. Net P&L depends on inventory skew direction.

### Agent Behaviour
- **Who is acting:** Automated market maker providing liquidity at inside-spread quotes.
- **Who is trapped:** Impatient takers paying the spread for immediacy. Also: stale-quote MM bots caught by informed traders.
- **Who is wrong:** MMs who quote without fee awareness, inventory skew, or adverse selection defence. MMs who quote through information events.

### Outcome
- **If accepted:** ~0.2% of trading volume captured as profit (industry benchmark). $150-$300/day per liquid market at professional scale.
- **If rejected:** Single adverse selection event erases weeks/months of spread income. Binary settlement = total loss on wrong-side inventory.
- **If unclear:** Partial spread captured, residual inventory risk carried to resolution.

## Rule
Place inside-spread limit orders on both YES sides when: (1) net spread after fees > 0, (2) category-adjusted fee rate permits profit at current price, (3) inventory is within bounds, (4) no imminent resolution event, (5) time-to-resolution > 24h. Skew quotes toward inventory-reducing side using Avellaneda-Stoikov reservation price. Maker orders only (0% fee).

## Mechanism
Exploits the liquidity premium: impatient traders (takers) pay 3-15% spreads for immediacy in prediction markets. Market makers earn the spread by bearing inventory risk and adverse selection risk. Edge persists because: (1) prediction market spreads are 10-100x wider than traditional markets due to lower liquidity and higher information asymmetry, (2) maker fees are 0% on Polymarket (takers subsidize makers via rebate program), (3) binary settlement creates unique inventory risk that deters casual participants.

**Key economic structure:** 100% of taker fees are redistributed to makers. This creates a secondary revenue stream beyond spread capture — makers earn rebates (20-25% of taker fees depending on category) on top of spread profit.

## Conditions

### Works when
- **Spread > category-adjusted fee threshold** (see Fee Impact table below)
- **Market category:** Geopolitics (0% taker fee — pure spread capture), Sports/Politics/Finance (3-4% fee rate — moderate), Weather/Culture/Economics (5% — tighter margins)
- **Price in uncertainty zone:** YES $0.25-$0.75 (peak taker fee = peak maker rebate, but also peak adverse selection risk). Optimal: YES $0.30-$0.70
- **Time-to-resolution > 24 hours** (event risk scales inversely with time remaining)
- **Liquidity >= $10k** (sufficient depth to absorb quotes without moving market)
- **Balanced order flow** (no persistent one-sided volume)
- **Inventory |q| < q_max** (within position limits)
- **No scheduled information event** in next 2 hours (earnings, votes, weather resolution)
- **Spread $0.03-$0.10** (optimal zone — wide enough for profit, narrow enough to indicate active market)

### Fails when
- **CRITICAL: Spread < fee-adjusted breakeven** — the #1 failure mode. Fee formula `fee = C * feeRate * p * (1-p)` peaks at p=0.50. For crypto markets (7.2% rate), 100 shares at $0.50 costs $1.80 in taker fees. Maker avoids this, but the taker fee determines who fills against you.
- **Information event imminent** — adverse selection spikes. Prices can move 40-50pp on breaking news within seconds, exceeding any spread captured on prior round-trips.
- **Price approaching $0 or $1** — spread auto-compresses (`delta_p = p*(1-p) * delta_x`), market resolving, no edge left.
- **Spread > $0.15** — illiquid market with toxic flow. Wide spread = high adverse selection probability.
- **One-sided flow** — persistent buy or sell pressure indicates informed traders. Partial fills create unbounded directional exposure.
- **Competing MM bots with queue priority** — Polymarket WebSocket latency ~50ms; professional MMs target sub-10ms. Queue position determines fill rate.
- **Time-to-resolution < 24h** — event risk dominates spread income. Avellaneda-Stoikov model prescribes spread widening as T-t shrinks, but in practice, the optimal action is to exit.
- **Inventory breach** — holding >5% of bankroll on one side creates binary settlement risk that dwarfs spread income.
- **Market voided** — no settlement, capital locked for refund processing.

### Best pairs
Active binary markets with: moderate uncertainty (YES $0.30-$0.70), >$10k liquidity, >48h to resolution, low taker fee category (geopolitics ideal, sports/politics acceptable).

### Best timeframe
Continuous limit orders with 100-500ms refresh cycle. 30-second cycle (current implementation) is 60-300x too slow for competitive MM.

### Best regime
Stable/uncertain markets with balanced flow. NOT trending-to-resolution markets.

## Evidence

### Source Quality
- **Source:** 5 independent sources (Polymarket docs, arxiv paper, industry guides, live trading data, GitHub implementations)
- **Certainty:** hypothesis (framework is well-established in traditional MM; prediction market adaptation has limited empirical data)
- **Scope:** all binary Polymarket markets (category-adjusted)
- **Falsifiable:** testable — fee structure and spread dynamics are observable
- **Reaction observed:** no

### Data
- **Industry benchmark:** ~0.2% of trading volume as profit for professional MMs (newyorkcityservers.com)
- **Collective MM profits:** >$20M on Polymarket in 2024 (fglancszpigel)
- **Per-market daily revenue:** $150-$300 on liquid contracts at professional scale (fglancszpigel)
- **Trader distribution:** Top 1% capture 84% of trading gains; <30% of all traders earn positive returns (fglancszpigel)
- **Execution edge:** 2.52 cents/contract automated vs manual (fglancszpigel)
- **Breakeven win rate:** ~53% on 5-min BTC binary options (gwrx2005 live trading)
- **Live trading result:** 4W/11L, -49.5% ROI on 5-min BTC binaries — efficient pricing defeated spread capture (gwrx2005)
- **Execution slippage:** 2-4 cents/token in live trading vs zero in paper-trading (gwrx2005)
- **Cross-platform arb:** $40M realized from Polymarket/Kalshi simultaneous trades (fglancszpigel)
- Period: none (own implementation)
- Trades: 0
- Win rate: pending
- Profit: pending
- Max drawdown: pending
- Sharpe: pending

### Fee Impact Table (per 100 shares at various prices)

| Category | Fee Rate | Fee @ p=0.50 | Fee @ p=0.30 | Fee @ p=0.10 |
|----------|----------|-------------|-------------|-------------|
| Crypto | 0.072 | $1.80 | $1.51 | $0.65 |
| Weather | 0.050 | $1.25 | $1.05 | $0.45 |
| Politics | 0.040 | $1.00 | $0.84 | $0.36 |
| Sports | 0.030 | $0.75 | $0.63 | $0.27 |
| Geopolitics | 0.000 | $0.00 | $0.00 | $0.00 |

**Maker pays 0% fees.** But taker fee determines the friction for counterparties filling against your quotes. Higher taker fees = fewer fills = lower volume but also = higher maker rebate income.

## Limitations
1. **No inventory management** — current implementation has zero inventory tracking. Single most critical gap. Binary settlement means wrong-side inventory goes to $0.
2. **No Avellaneda-Stoikov reservation price** — quotes are symmetric around mid-price regardless of inventory. Should skew: `r = mid - q * gamma * sigma^2 * (T-t)`.
3. **No adverse selection defence** — no quote cancellation on adverse fills, no toxicity monitoring (VPIN), no news guards.
4. **Fixed ORDER_SIZE=10** — no dynamic sizing for spread width, volatility, or inventory state. Professional MMs scale size with spread and depth.
5. **30-second refresh cycle** — 60-300x too slow. Professional target: 100-500ms. Stale quotes are adverse selection magnets.
6. **No fee-awareness** — MIN_SPREAD=0.03 is below fee-adjusted breakeven for crypto markets (7.2% rate). Must filter by category.
7. **No time-to-resolution filter** — quoting 1 hour before resolution is suicide. Must exit >24h before settlement.
8. **Confidence hardcoded 0.5** — no edge estimation. Should reflect spread-to-fee ratio and inventory state.
9. **No maker rebate accounting** — ignores the 20-25% taker fee rebate that adds to MM revenue.
10. **No queue position awareness** — fill probability depends on queue depth, not just price.

## Implementation

### Current code
- **File:** `polymarket-bot/src/strategies/spread.py`
- **Parameters:** MIN_SPREAD=0.03, MAX_SPREAD=0.15, ORDER_SIZE=10.0
- **Code:** `scan()` places BUY YES at `best_bid + tick`, SELL YES at `best_ask - tick`

### Required changes for intermediate level
1. **Add fee-aware spread filter:** `min_spread[category] = f(feeRate, price)` — reject if net spread after taker friction < 0
2. **Add inventory tracking:** Track net position per market. Skew quotes using reservation price: `r = mid - q * gamma * sigma_b^2 * (T-t)`
3. **Add inventory limits:** `|q| < 0.05 * bankroll / price`. Hard-stop quoting if breached.
4. **Add time-to-resolution filter:** No new quotes if resolution < 24h. Begin unwinding at 48h.
5. **Add category filter:** Prefer geopolitics (0% fee) > sports (3%) > politics/finance (4%) > weather/culture (5%). Skip crypto (7.2%) unless spread is very wide.
6. **Add refresh cycle:** Reduce from 30s to 500ms minimum. Cancel-and-replace on adverse price moves.
7. **Add adverse selection guard:** Cancel all quotes on >3% price move within 1 minute. Widen spread after adverse fill detected.
8. **Dynamic order sizing:** `size = base_size * (spread / avg_spread) * (depth / avg_depth)`. Scale down as inventory grows.

### Avellaneda-Stoikov adaptation for prediction markets
The arxiv paper (2510.15205) provides the key adaptation: work in **logit space** (`x = log(p/(1-p))`), not price space.

```python
# Reservation price in logit space
r_x = x_mid - q * gamma * sigma_b_sq * (T - t)

# Optimal half-spread in logit space  
delta_x = (gamma * sigma_b_sq * (T - t)) / 2 + (1/k) * log(1 + gamma/k)

# Map back to probability space
bid_p = sigmoid(r_x - delta_x)
ask_p = sigmoid(r_x + delta_x)

# Inventory limit near boundaries
q_max = 1 / max(p * (1 - p), epsilon)
```

Key parameters:
- `gamma`: risk aversion (higher = wider spread, faster inventory reduction)
- `sigma_b`: belief volatility (estimate from recent price moves in logit space)
- `k`: order arrival decay rate (calibrate from historical fill data)
- `T-t`: time to resolution in normalized units

## Situation Log

| Date | Market | Category | Setup | Trigger | Reaction | Outcome | Notes |
|------|--------|----------|-------|---------|----------|---------|-------|
| -- | -- | -- | No observations yet | -- | -- | -- | Needs live data |

## Refinement History
- 2026-04-10: Created as naive prim from SpreadStrategy code extraction (cycle 2 ASSESS)
- 2026-04-10: Elevated to intermediate with 5-source evidence base (cycle 6 RESEARCH). Key additions: fee-aware filtering, Avellaneda-Stoikov inventory skew in logit space, adverse selection defence, time-to-resolution gating, category-based fee optimization, quantitative profitability benchmarks ($150-300/day/market at professional scale, ~0.2% of volume).
