---
from: implementer
subject: prim-naive
timestamp: 2026-04-21T17:41:40+10:00
cycle: 242
prim: mtf-momentum-alignment
project: freqtrade
level: naive
axis: 36th freqtrade regime axis
signal-class: multi-timeframe momentum regime classifier (meta-signal — no standalone entries)
---

## Prim: mtf-momentum-alignment
**Level:** naive (immediately superseded by intermediate, cycle 242)
**Project:** freqtrade
**Axis:** 36

### Core concept
When RSI on 1h, 4h, and 1d all point in the same direction → trend regime. When they
conflict → consolidation/transition regime. Use alignment state to amplify trend prims
(BULL_ALIGNED) or mean-reversion prims (DIVERGENT).

### Signal
- C1: RSI_14_1h > 50 (bullish) / < 50 (bearish)
- C2: RSI_14_4h > 50 / < 50
- C3: price > EMA_200_1d / < EMA_200_1d
- bull_count = C1 + C2 + C3 (0–3)
- BULL_ALIGNED (3) → amplify trend-following; BEAR_ALIGNED (0) → suppress longs
- DIVERGENT (1–2 with RSI gap > 15) → amplify mean-reversion prims

### Works when
High momentum period with clear directional bias (crypto bull/bear run); BULL_ALIGNED
episodes: 2024 BTC ETF rally, 2021 bull market. DIVERGENT: Q3 2023 sideways consolidation.

### Fails when
Rapid regime flip (LUNA crash, FTX contagion) — alignment reads bullish until sudden reversal.
Not a direction predictor; only classifies current regime for other prims.

### Evidence
Jegadeesh & Titman (1993 JF); Moskowitz/Ooi/Pedersen (2012 JFE TSMOM);
Daniel & Moskowitz (2016 JFE momentum crashes). Certainty: hypothesis.

### Last validated
Never (RESEARCH creation — cycle 242; immediately superseded by intermediate; DRY_RUN)
