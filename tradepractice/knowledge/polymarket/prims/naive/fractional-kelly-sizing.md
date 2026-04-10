---
name: fractional-kelly-sizing
level: naive
project: polymarket
parent_prim: none
created: 2026-04-10
last_validated: never
reaction_validated: assumed
---

## Situation

### Setup
A positive-edge trade has been identified (e.g., ensemble-forecast-edge). The question is how much capital to allocate.

### Trigger
Edge >= threshold (MIN_EDGE=0.08). Kelly formula produces positive bet size.

### Reaction
- **Accepted:** Position size matches edge magnitude — larger bets on larger edges, smaller on marginal edges. Bankroll survives drawdowns.
- **Rejected:** Edge estimate was wrong; Kelly oversized the bet relative to true edge. Drawdown exceeds tolerance.
- **Unclear:** Edge exists but Kelly fraction is too conservative to generate meaningful returns.

### Agent Behaviour
- **Who is acting:** Quantitative bettor using Kelly criterion vs. flat-size bettors.
- **Who is trapped:** Fixed-size bettors who overbet marginal edges and underbet strong edges.
- **Who is wrong:** Anyone betting without edge-proportional sizing (either overbetting or underbetting).

### Outcome
- **If accepted:** Geometric growth rate maximized over many bets. Bankroll compounds.
- **If rejected:** Edge estimation error amplified by Kelly sizing. Ruin risk if full Kelly used.
- **If unclear:** Fractional Kelly (15%) provides safety margin but may underperform in short samples.

## Rule
Size each bet as 15% of full Kelly: `position = 0.15 * kelly_fraction * bankroll`. Cap at min(5% of bankroll, $100). Kelly fraction = `(win_prob * odds - lose_prob) / odds` where `odds = (1/market_price) - 1`.

## Mechanism
Kelly criterion maximizes long-run geometric growth rate of capital by betting proportionally to edge. Full Kelly is optimal but has extreme variance; fractional Kelly (15%) sacrifices ~15% of growth rate for ~85% reduction in drawdown variance. In prediction markets with binary resolution, the odds structure maps cleanly to Kelly.

## Conditions
- **Works when:** Edge estimate is accurate; many independent bets (law of large numbers); bankroll large enough for Kelly to produce meaningful sizes; binary resolution (clean payoff structure)
- **Fails when:** Edge estimate is wrong (garbage in → garbage out); correlated bets (weather events in same city/date); small sample (Kelly needs many iterations); bankroll too small (Kelly produces sub-minimum bet sizes); market impact at calculated size
- **Best pairs:** All Polymarket binary markets where edge is quantifiable
- **Best timeframe:** Per-trade sizing decision
- **Best regime:** Any — Kelly is regime-agnostic (edge-dependent, not market-dependent)

## Evidence

### Source Quality
- **Source:** code extraction + Kelly criterion theory (well-established)
- **Certainty:** hypothesis (Kelly math is proven; application to this context is unvalidated)
- **Scope:** all binary prediction market bets
- **Falsifiable:** untested in this implementation
- **Reaction observed:** no

### Data
- Period: none
- Trades: 0
- Win rate: pending
- Profit: pending
- Max drawdown: pending
- Sharpe: pending
- Acceptance rate: pending
- Rejection rate: pending
- Unclear rate: pending

## Limitations
1. **KELLY_FRACTION=0.15 is arbitrary** — no analysis of optimal fraction for this edge distribution. Literature suggests 0.25-0.50 for well-estimated edges.
2. **Edge estimation quality unknown** — Kelly amplifies estimation error. If model_prob is miscalibrated, Kelly sizes are systematically wrong.
3. **No correlation adjustment** — multiple weather bets in same geography/timeframe are correlated. Kelly assumes independence.
4. **Bankroll definition unclear** — `config.max_position_usd * 10` is a proxy, not actual available capital.
5. **Triple cap (Kelly * fraction, 5% bankroll, $100)** — the $100 MAX_BET hard cap makes Kelly irrelevant for bankrolls > ~$13k (Kelly would suggest >$100 on strong edges).
6. **No drawdown tracking** — bankroll is static, not updated after wins/losses. Kelly should resize based on current capital.
7. **Binary-only** — Kelly formula assumes binary payoff. Multi-bracket events have correlated outcomes not captured.
8. **No bet-frequency adjustment** — Kelly optimal for sequential independent bets. Concurrent bets on same event need portfolio-level Kelly.

## Implementation
- **File:** `polymarket-bot/src/weather/strategy.py`
- **Parameter:** KELLY_FRACTION=0.15, MAX_BET=100.0
- **Code:** `kelly_bet(win_prob, market_price, bankroll)` → `min(kelly * 0.15 * bankroll, bankroll * 0.05, MAX_BET)`
- **Reaction detection:** None. No post-trade tracking of whether sizing was appropriate.
- **Integration:** Called by `analyze_event()` for each bracket with edge >= MIN_EDGE

## Situation Log

| Date | Pair | TF | Setup | Trigger | Reaction | Outcome | Notes |
|------|------|----|-------|---------|----------|---------|-------|
| — | — | — | No observations yet | — | — | — | Needs live data |

## Refinement History
- 2026-04-10: Created as naive prim from WeatherStrategy code extraction (cycle 4 ASSESS)
