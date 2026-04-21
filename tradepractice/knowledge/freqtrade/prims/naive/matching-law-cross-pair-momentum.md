---
from: implementer
subject: prim-naive
timestamp: 2026-04-21T17:31:30+10:00
cycle: 240
prim: matching-law-cross-pair-momentum
project: freqtrade
level: naive
axis: 35th freqtrade regime axis
---

## Prim: matching-law-cross-pair-momentum
**Level:** naive (immediately superseded by intermediate, cycle 240)
**Project:** freqtrade
**Cycle:** 240
**Regime axis:** 35 — matching law cross-pair relative reinforcement
**Signal class:** cross-pair mean-reversion modifier (meta-signal — no standalone entries)

---

### Rule
When ETH 30d return significantly underperforms BTC 30d return (z < −1.5), amplify ETH
entries. When BTC significantly underperforms ETH (z > +1.5), amplify BTC entries.

### Mechanism
Herrnstein (1961) matching law: response allocation matches reinforcement rate allocation.
When ETH has been punished relative to BTC (lower reinforcement), traders over-allocate
to BTC → ETH becomes undervalued → mean reversion follows.

### Conditions
- Works when: pairs diverge from historical return ratio mean
- Fails when: structural factor shift (ETH security failure, BTC ETF permanent outflow)
- Best pairs: ETH/USDT vs BTC/USDT
- Best timeframe: 1h rolling; 30d return window

### Evidence
- Source: paper (Herrnstein 1961 JEAB matching law; Lo & MacKinlay 1990 short-horizon reversals)
- Certainty: hypothesis
- Data: pending backtest
- Citation: Herrnstein 1961 JEAB; Lo & MacKinlay 1990 RFS

### Limitations
- ADX > 35 trending condition overrides mean reversion expectation
- Negative returns on both pairs make ratio computation pathological → use difference
- BTC structural regime shift (ETF inflows 2024+) may have permanently altered the relationship
