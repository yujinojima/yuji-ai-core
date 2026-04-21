---
from: analyst
subject: analyst-result
timestamp: 2026-04-21T17:45:00+10:00
cycle: 203
prim: stablecoin-depeg-systemic-stress
project: freqtrade
level: naive [historical — superseded by intermediate, cycle 203]
axis: 34
signal-class: stablecoin peg-stability circuit breaker (meta-signal — suppress only)
parent: none (direct creation)
status: SUPERSEDED by intermediate (cycle 203)
---

# Stablecoin Depeg Systemic Stress — Naive

## Rule

When a major stablecoin (USDT, USDC, market cap > $5B) deviates > 0.30% from its $1.00 peg on any major venue (Binance, Coinbase, Kraken) for ≥ 3 consecutive hours → apply 0.88× SUPPRESS to all active AMPLIFY modifiers across all pairs.

## Mechanism

Stablecoin depeg events create DeFi collateral stress: positions using USDC/USDT as collateral are immediately undercollateralised at a lower collateral value, triggering forced liquidations independent of crypto asset price movements. This is an exogenous monetary shock (stablecoin issuance/custody failure) distinct from endogenous price-triggered liquidation cascades (axis 25).

## Conditions

- **Works when:** Major stablecoin depeg sustained ≥ 3h; banking/custody counterparty stress is cause
- **Fails when:** Algorithmic stablecoin (not collateral-backed); short-term venue glitch < 30 min; BTC/ETH price decline is primary driver (axis 25 already fires)
- **Best pairs:** All pairs (circuit-breaker applies universally when stablecoin used as quote currency or DeFi collateral)
- **Best timeframe:** Meta-signal; checked every 15 min via bot_loop_start()

## Evidence

| Source | Finding |
|--------|---------|
| Lyons & Viswanath-Natraj (2023 JFE) | Stablecoin depeg mechanics; USDC cross-venue spread dynamics |
| Gorton & Zhang (2021 NBER 29166) | Systemic stablecoin risk; collateral-backed vs algorithmic vulnerability taxonomy |

**Certainty:** hypothesis. **Scope:** crypto-specific. **Reaction validated:** assumed.

Known historical episodes: USDC depeg March 10–13 2023 (SVB crisis; low $0.87); USDT brief depeg May 2022 (Terra/Luna contagion; low $0.9850); UST death spiral May 2022.

## Limitations

No circuit breaker applies for algorithmic stablecoin depegs (UST-type) because the mechanism is a death spiral rather than a recoverable banking event — the signal persistence model is different and must be handled at sophisticated tier.

## Implementation

- **File:** `user_data/strategies/base_meta_signal.py` (to be created)
- **Parameter:** `stablecoin_depeg_threshold = 0.003` (0.30%)
- **Reaction detection:** Poll CoinGecko `/simple/price` USDT+USDC every 15 min; if |price − 1.00| > threshold for ≥3 consecutive readings → activate circuit breaker

## Refinement History
- 2026-04-21: Created as naive (cycle 203). Immediately superseded by intermediate same cycle.
