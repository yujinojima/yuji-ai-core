---
name: rsi-oversold-mean-reversion
level: naive
project: freqtrade
parent_prim: none
created: 2026-04-10
last_validated: never
reaction_validated: assumed
---

## Prim: rsi-oversold-mean-reversion
**Level:** naive
**Project:** freqtrade
**Parent:** none

### Situation

**Setup:** Price has sold off enough for RSI(14) to fall below 30 on the entry timeframe. Market participants have collectively driven price to a statistically uncommon low-momentum reading. Oversold RSI concentrates trapped short-term sellers and shaken-out longs near a potential exhaust point.

**Trigger:** RSI(14) crosses below 30 (extreme oversold threshold) on the 15m or 1h chart.

**Reaction:**
- **Accepted:** Price stabilises, RSI recovers above 35 within 2–3 candles, candle body is green or doji with lower wick — buyers absorbing the sell pressure.
- **Rejected:** Price continues lower, RSI stays below 30 or makes new lows — no absorption, sellers still in control, possibly trending down.
- **Unclear:** Price stalls but no directional close; RSI bounces then rolls back near 30.

**Agent Behaviour:**
- **Who is acting:** Short-term momentum sellers closing positions, potential mean-reversion algos triggering at RSI floor.
- **Who is trapped:** Sellers who shorted into the oversold zone; if price reverses sharply, they must cover, adding fuel.
- **Who is wrong:** Late sellers entering at extreme oversold; their stop-covers drive the bounce.

**Outcome:**
- If accepted: mean-reversion continuation toward RSI ~50–55, approximate target = BB middle band.
- If rejected: trend continuation lower; DO NOT hold — this is a capitulation scenario, not a mean reversion.
- If unclear: no action; wait for candle close confirmation.

### Rule
If RSI(14) < 30 on the entry timeframe AND reaction is accepted (price holds + RSI recovers), take a long position biased toward mean reversion to RSI ~50 or BB middle band.

### Mechanism
RSI < 30 marks a zone where short-term selling momentum is statistically exhausted. Trapped sellers (who shorted into the move) provide covering-fuel for the bounce. This works because it exploits the mechanical forced-exit of late sellers, not because RSI itself is predictive. The edge disappears in downtrends because sellers are not trapped — they are correct.

### Conditions
- **Works when:** ranging or mildly bullish regime; price above 1h EMA200; selling is corrective not structural
- **Fails when:** strong downtrend (ADX > 25, EMA alignment bearish); news-driven capitulation; price breaking multi-day support; 1h/4h RSI also < 30 simultaneously
- **Best pairs:** untested — hypothetically better on high-liquidity pairs (BTC/USDT, ETH/USDT) where mean-reversion algos are active
- **Best timeframe:** untested — used on 15m in YujiMultiSignalStrategy, 1h in YujiRegimeStrategy
- **Best regime:** ranging (ADX < 20, BB width compressed)

### Evidence
- **Source:** anecdote (extracted from strategy code logic, not backtested)
- **Certainty:** guess
- **Scope:** untested
- **Falsifiable:** untested
- **Reaction observed:** assumed — no forward-test or backtest results available
- **Data:** pending backtest
- **Citation:** YujiMultiSignalStrategy.py buy_1 (lines 191–196); YujiRegimeStrategy.py range_entry (lines 185–194)

### Limitations
- RSI < 30 in a strong downtrend is a continuation signal, not reversal — this is the primary failure mode.
- No information about how often RSI < 30 triggers in the historical data.
- No win-rate data for this signal in isolation vs. in combination with other filters.
- Failure conditions for crypto specifically are unknown — crypto overshoots oscillator bounds more than equities.
- The strategies never use RSI < 30 in isolation; always combined (MFI, BB, Stoch). This prim's standalone edge is entirely untested.

### Implementation
- **File:** `user_data/strategies/YujiMultiSignalStrategy.py`
- **Parameter:** `buy_rsi_threshold` (IntParameter, default=30, range 20–40)
- **Code:** `dataframe["rsi"] < self.buy_rsi_threshold.value` (buy_1, line 192)
- **Reaction detection:** not implemented — code fires entry signal without confirming reaction candle; reaction confirmation is an intermediate refinement

### Conditions Log Entry
- **Works when:** ranging market, price above 1h EMA200, 1h RSI < 65, 4h RSI < 70
- **Fails when:** downtrend (EMA alignment bearish), ADX > 25, 1h/4h RSI also oversold
- **Last validated:** never
