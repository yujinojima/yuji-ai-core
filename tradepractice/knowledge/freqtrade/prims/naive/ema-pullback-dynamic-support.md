---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T12:44:17+10:00
cycle: 1
---

---

## Prim: ema-pullback-dynamic-support
**Level:** naive
**Project:** freqtrade
**Parent:** none

### Rule
If EMA alignment >= 3 AND price low touches 21 EMA AND close is above 21 EMA AND candle is bullish AND MACD histogram is rising AND reaction accepted (holds above 21 EMA) → continuation long bias toward prior high.

### Mechanism
In a confirmed uptrend, the 21 EMA concentrates re-entry bids from trend-followers. Countertrend shorts (betting on reversal) are trapped when price holds the level and must cover, fuelling the next leg. Edge disappears when EMA alignment degrades — the level is no longer defended by enough positioned buyers.

### Conditions
- **Works when:** EMA alignment >= 3, ADX > 20, 4h EMA50 > EMA200, RSI 40–65, <= 2 prior EMA21 tests in 20 candles
- **Fails when:** EMA alignment <= 2, ADX < 18, 4h bearish, RSI < 35, 3+ EMA21 tests (level losing significance)
- **Best pairs:** untested
- **Best timeframe:** untested — implemented 1h (YujiTrendRiderStrategy)

### Evidence
- **Source:** anecdote (code extraction)
- **Certainty:** guess
- **Data:** pending backtest
- **Citation:** `YujiTrendRiderStrategy.py` `buy_pullback` block, lines 184–192

### Limitations
- Late-trend EMA alignment (2→3 during distribution) produces false signals
- Parabolic crypto moves skip the 21 EMA entirely — signal never fires
- Sharp breakdowns print a bearish candle touching 21 EMA, but the close is below it; code filters this but reaction confirmation is still same-candle, not next-candle
- Frequency of EMA alignment >= 3 in crypto historical data: unknown

### Implementation
- **File:** `user_data/strategies/YujiTrendRiderStrategy.py`
- **Parameter:** `ema_slow` default=21; `adx_threshold` default=25
- **Code:** `buy_pullback` (lines 184–192)
- **Reaction detection:** partial — bullish candle + MACD hist rising; no next-candle confirmation

### Conditions Log Entry
- **Works when:** trending market, EMA ribbon fully aligned, ADX > 20, 4h bullish, RSI 40–65
- **Fails when:** EMA alignment degrading, choppy (ADX < 18), breakdown (RSI < 35), level over-tested
- **Last validated:** never
