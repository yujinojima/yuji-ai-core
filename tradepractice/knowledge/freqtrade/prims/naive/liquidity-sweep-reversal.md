---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T13:12:00+10:00
cycle: 1
---

---

## Prim: liquidity-sweep-reversal
**Level:** naive
**Project:** freqtrade
**Parent:** none

### Rule
If price wicks below a prior swing low AND closes back above it with a bullish candle AND CVD delta is positive and rising → long bias toward next VP level (POC/VAH), conditional on acceptance.

### Mechanism
Stop-loss clusters below swing lows create liquidity pools. Institutional flow sweeps these stops to fill large buy orders from forced sellers at lower prices. The wick-and-reclaim reveals the sweep is complete. Trapped breakout shorts must cover → mechanical upside fuel. CVD confirms real buying pressure vs dead-cat bounce.

### Conditions
- **Works when:** Near VP level (POC/VAL); clear swing low with stop clusters; CVD positive; volume > 0.8x SMA; ranging/mild trend
- **Fails when:** Strong macro downtrend; no CVD confirmation; low volume sweep; multiple consecutive sweeps (genuine breakdown)
- **Best pairs:** untested
- **Best timeframe:** 15m (YujiSmartMoneyStrategy)

### Evidence
- **Source:** anecdote (code extraction)
- **Certainty:** guess
- **Data:** pending backtest

### Key Limitations
1. CVD approximated from candle close position — not real order flow
2. Entry fires same-candle, no next-candle confirmation
3. No regime guard on primary signal
4. No minimum wick depth threshold — noise wicks trigger false signals
5. 5-bar pivot swing detection may miss/flag wrong levels

### Implementation
- **File:** `YujiSmartMoneyStrategy.py`
- **Entry:** lines 179–187 (primary), 191–201 (secondary)
- **Sweep detection:** `_detect_bullish_sweep()` lines 270–282
- **CVD:** lines 114–124
- **VP:** `_compute_volume_profile_series()` lines 340–411

---

**Gap assessment — remaining uncaptured prims** (4 strategies read, 8 unread):

| Priority | Strategy | Signal | Status |
|---|---|---|---|
| 1 | YujiDivergenceStrategy | Bullish RSI divergence (price LL + RSI HL) | **uncaptured** |
| 2 | YujiExtinctionBurstStrategy | Capitulation (consecutive red + vol spike + extreme oscillators) | **uncaptured** |
| 3 | YujiScalperStrategy | BB %B oversold + StochRSI | **uncaptured** (overlaps RSI prim) |
| 4 | YujiFluidStrategy | unread | **unread** |
| 5 | YujiStrategy/V2/V3 | unread | **unread** |
| 6 | YujiInverseScalperStrategy | unread | **unread** |

Next cycle should extract the **bullish-rsi-divergence** prim from YujiDivergenceStrategy — it's the most distinct remaining signal with a clean agent model (weakening sellers failing to push RSI lower despite pushing price lower).
