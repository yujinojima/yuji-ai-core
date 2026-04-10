---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T13:54:31+10:00
cycle: 4
---

---

## Prim: ensemble-forecast-edge
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule
If GFS 30-member ensemble probability for a temperature bracket exceeds Polymarket YES price by >= 8%, BUY YES. If ensemble says less likely by >= 8%, BUY NO. Size via fractional Kelly.

### Mechanism
Information asymmetry: 30-member GFS ensemble (free, public, requires processing) vs. casual bettors pricing on single-point forecasts. Weather prediction markets are new, illiquid, attract non-quantitative participants.

### Conditions
- Works when: Well-calibrated model; illiquid market; 1-3 day horizon; uncertain brackets (YES $0.20-$0.80)
- Fails when: Efficient market; horizon >5 days; extreme weather; tail brackets (30 members = coarse); station-model mismatch
- Best pairs: Weather temperature brackets
- Best timeframe: 1-3 days before resolution

### Evidence
- Source: code extraction
- Certainty: guess
- Data: 0 trades, pending backtest
- Citation: `polymarket-bot/src/weather/strategy.py`

### Limitations
1. 30-member ensemble = 3.3% probability resolution per member
2. Single model (GFS only, no ECMWF/NAM blend)
3. No calibration layer (raw ensemble counts = probabilities)
4. Station vs. model grid-point bias unknown
5. No ensemble spread/confidence check
6. No execution cost awareness

### Implementation
- File: `polymarket-bot/src/weather/strategy.py`
- Parameters: MIN_EDGE=0.08, MIN_LIQUIDITY=500
- Key logic: `analyze_event()` computes `model_prob - market_prob >= 0.08` per bracket

### Assessment: all extractable polymarket prims complete

| # | Prim | Strategy | Status |
|---|------|----------|--------|
| 1 | binary-arb-completeness | ArbStrategy | done (cycle 2) |
| 2 | spread-capture-market-making | SpreadStrategy | done (cycle 2) |
| 3 | **ensemble-forecast-edge** | WeatherStrategy | **created this cycle** |
| 4 | **fractional-kelly-sizing** | WeatherStrategy | **created this cycle** |

**Files updated:**
- `knowledge/polymarket/prims/naive/ensemble-forecast-edge.md` — created
- `knowledge/polymarket/prims/naive/fractional-kelly-sizing.md` — created
- `knowledge/epistemic-index.md` — 2 polymarket naive rows added
- `knowledge/conditions-log.md` — 2 polymarket conditions added

**Polymarket naive extraction complete.** All 3 strategies (ArbStrategy, SpreadStrategy, WeatherStrategy) fully decomposed into 4 naive prims. No remaining extractable prims in the codebase.

**Next cycle recommendations:**
1. RESEARCH: Elevate `ensemble-forecast-edge` to intermediate — find calibration evidence for GFS ensembles on temperature prediction markets, multi-model blending approaches, and optimal edge thresholds
2. RESEARCH: Elevate `fractional-kelly-sizing` to intermediate — find optimal Kelly fraction for prediction market edge distributions, correlation-adjusted Kelly for concurrent bets
3. BACKTEST-ANALYSIS: Run `backtest_weather.py` to validate ensemble-forecast-edge on historical weather markets
