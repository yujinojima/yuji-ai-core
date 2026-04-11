---
name: semantic-correlation-pair-trade
level: naive
project: polymarket
parent_prim: none
created: 2026-04-11
last_validated: never
reaction_validated: assumed
---

## Prim: semantic-correlation-pair-trade
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule
When two Polymarket contracts describe causally related events and their prices diverge beyond what the causal relationship allows, buy the underpriced contract.

### Mechanism
Participants trade each Polymarket contract in isolation. If Market A ("Trump wins general election") and Market B ("Republicans win White House") are logically linked — one implies the other — their prices should respect the implied conditional probability structure. Casual bettors specialised in one market do not simultaneously monitor semantically related markets, creating transient arbitrage-adjacent divergences. Unlike binary-arb-completeness, there is no contractual guarantee of convergence — this is probabilistic edge, not locked profit.

### Conditions
- **Works when:** Clear logical/causal relationship between two contracts; price divergence > 5%; both markets have liquidity > $1k; resolution horizon > 3 days
- **Fails when:** Same-sounding contracts resolve on different criteria (resolution oracle divergence); new asymmetric information breaks the correlation; one market is illiquid (divergence never closes)
- **Best pairs:** untested — causally related geopolitics / political event markets
- **Best timeframe:** untested — days to weeks per arxiv 2512.02436

### Evidence
- **Source:** paper (arxiv 2512.02436, IBM+Columbia, Dec 2025)
- **Certainty:** hypothesis
- **Data:** 60–70% relationship detection accuracy; ~20% average return over week-long horizons (research simulation, not live)
- **Citation:** [arxiv 2512.02436](https://arxiv.org/abs/2512.02436)

### Limitations
1. No implementation in polymarket-bot
2. No own-data backtest
3. Convergence not guaranteed (probabilistic, not contractual)
4. Resolution oracle divergence possible even for semantically similar contracts
5. Position sizing for correlated bets requires portfolio-level Kelly (handled by fractional-kelly-sizing sophisticated)

### Implementation
- File: `src/strategies/correlated_pair_trade.py` (not yet implemented)
- Reuses: `src/classifiers/semantic_risk.py` from cross-venue-semantic-arb

### Conditions Log Entry
- Works when: Causal relationship clear; divergence > 5%; liquidity > $1k; resolution horizon > 3d
- Fails when: Oracle divergence; asymmetric news catalyst; illiquid secondary market
- Last validated: never

## Refinement History
- 2026-04-11: Created as naive prim, cycle 34 RESEARCH. Immediately elevated to intermediate in same cycle. Academic anchor: arxiv 2512.02436 (IBM+Columbia, Dec 2025). No code extraction — new capability class.
