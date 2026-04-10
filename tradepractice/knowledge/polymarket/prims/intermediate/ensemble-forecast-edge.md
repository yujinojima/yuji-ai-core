---
from: analyst
subject: analyst-result
timestamp: 2026-04-10T17:22:11+10:00
cycle: 12
---

---

## Prim: ensemble-forecast-edge
**Level:** intermediate (elevated from naive)
**Project:** polymarket

### What changed

The naive prim had one failure: single-GFS signal, raw member-count probability, horizon-unaware MIN_EDGE=0.08.

**Three core upgrades:**

| # | Upgrade | Evidence |
|---|---------|---------|
| 1 | **Multi-model consensus gate**: GFS + ECMWF required (≥2 sources) | DevGenius/Njuguna: 3-model consensus → 70–90% accuracy day-1–2 |
| 2 | **Gaussian bracket probability**: `Φ((high−μ)/σ) − Φ((low−μ)/σ)` replaces raw member count | AMS MWR 2008 (Hamill): raw GEFS underdispersive; EMOS reduces CRPS 15–25% |
| 3 | **Horizon-gated thresholds**: 5% edge for day 1–2, 10% for day 3–5, no trade day 5+ | naive MIN_EDGE=0.08 sits between tiers — horizon-unaware |

**Plus:** station-gridpoint nearest-neighbor correction (primary systematic failure mode — resolution ASOS station ≠ model gridpoint), model staleness guard (reject if run age > 6h), fee-adjusted net edge (5% weather taker fee subtracted before signal fires), tail bracket exclusion (YES $0.05–$0.95 only).

### Key quantitative anchors

- **Practitioner consensus (Njuguna, PolyMaster, DevGenius 2026):** 70–75% WR on short-term temperature with ensemble models; $1k → $24k (London bot); $65k (NY/London/Seoul)
- **AMS MWR 2008 (Hamill et al.):** raw ECMWF + GFS ensemble surface temps biased AND underdispersive; calibrated ECMWF BSS > calibrated GFS BSS across all horizons; ECMWF maintains ~1 day lead time advantage
- **Station bias:** 10–30km gridpoint-to-station mismatch introduces 3–5°C mean bias in complex terrain — #1 unaddressed gap in WeatherStrategy

### Polymarket prim status

| Prim | Level |
|------|-------|
| binary-arb-completeness | naive |
| spread-capture-market-making | **intermediate** |
| fractional-kelly-sizing | **intermediate** |
| ensemble-forecast-edge | **intermediate** ← this cycle |

### Next cycle recommendations
1. **(A) Refine bullish-rsi-divergence to intermediate** — regime gate + pivot-based swing detection + confluence filters. Test if gated+confluence version survives PMC9920669 counter-result.
2. **(B) Elevate binary-arb-completeness to intermediate** — execution atomicity solutions (simultaneous order submission, partial-fill handling), fee-adjusted MIN_ARB_EDGE, capital-lockup opportunity cost model.
3. **(C) Elevate ensemble-forecast-edge to sophisticated** — own-data backtest on historical Polymarket weather markets with station-matched resolution data (100+ trade sample needed for statistical validity).

Sources:
- [People Are Making Millions Betting on Weather — Ezekiel Njuguna (Medium)](https://ezzekielnjuguna.medium.com/people-are-making-millions-on-polymarket-betting-on-the-weather-and-i-will-teach-you-how-24c9977b277c)
- [Found The Weather Trading Bots Making $24k — DevGenius, Feb 2026](https://blog.devgenius.io/found-the-weather-trading-bots-quietly-making-24-000-on-polymarket-and-built-one-myself-for-free-120bd34d6f09)
- [How to Gain an Edge in Global Temperature Anomaly Market — PolyMaster](https://medium.com/@wanguolin/how-to-gain-an-edge-in-the-global-temperature-anomaly-market-1-from-weather-station-to-polymarket-c6e6fdc9444a)
- [Probabilistic Forecast Calibration: ECMWF and GFS Reforecasts Part I: Temperatures — AMS MWR 2008](https://journals.ametsoc.org/view/journals/mwre/136/7/2007mwr2410.1.xml)
- [Degen Doppler — Polymarket Weather Edge Finder](https://degendoppler.com/)
- [Weather Prediction Market Strategies — Climate Sight](https://www.climatesight.app/weather-prediction-market-strategies/)
