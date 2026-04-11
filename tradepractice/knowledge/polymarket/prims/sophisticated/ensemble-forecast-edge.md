---
name: ensemble-forecast-edge
level: sophisticated
project: polymarket
parent_prim: intermediate/ensemble-forecast-edge
created: 2026-04-11
last_validated: never
---

## Prim: ensemble-forecast-edge
**Level:** sophisticated (refined from intermediate)
**Project:** polymarket
**Parent:** intermediate/ensemble-forecast-edge

### Rule
**ECMWF + GFS consensus** (directional agreement ≤ 2°C gap) + model run age < 6h + **ensemble_std ≤ 3°C** (convective exclusion) + **station-gridpoint distance ≤ 15km** (or ≤ 5km in complex terrain) + **EMOS-calibrated** bracket probability (or raw Φ × 1.2× spread inflation without warm-up) + **horizon-gated net edge** (≥ 7% day 1–2, ≥ 12% day 3–5, no trade day 6+) + **market efficiency clear** (liquidity > $50k AND spread < $0.02 → skip) + YES price $0.10–$0.90 + fee-adjusted WR target ≥ 58% + Kelly sizing via `fractional-kelly-sizing` sophisticated prim → long mispriced bracket.

### What Elevated This from Intermediate

9 sources (up from 5). Elevation adds: **quantified NWP accuracy ladder by horizon, ensemble spread as exclusion gate, model directional conflict gate, EMOS calibration pipeline with conservative fallback, market efficiency compression model, seasonal NWP bias map, quantified minimum WR (52.5%) from fee math, and two anti-prim escape hatches.**

### New Findings vs Intermediate

| Finding | Source | Impact |
|---|---|---|
| **NWP accuracy ladder**: Day 1 ~85% WR → Day 2 ~75% → Day 3 ~65% → Day 4–5 ~55% → Day 6+ ~50% | AMS MWR 2008 calibration + Njuguna/PolyMaster practitioner data | Replaces fixed 70–75% WR claim with horizon-specific targets |
| **ensemble_std > 3°C = convective instability signal** — ensemble is not normally distributed; Gaussian Φ invalid | AMS MWR 2008 (underdispersion analysis) | Mandatory exclusion gate — intermediate had no spread check |
| **Model directional conflict > 2°C** (ECMWF mean vs GFS mean) → signal uncertain → skip | AMS MWR 2008 (ECMWF vs GFS inter-model bias) | New rejection gate not present at intermediate |
| **EMOS calibration**: F_cal = N(a + b×μ, (c + d×σ)²) fit to 30-day rolling window reduces CRPS 15–25% vs raw Φ | AMS MWR 2008 (Hamill et al.) | Quantifies calibration improvement; adds fallback rule (1.2× spread inflation) |
| **Market efficiency compression ~30%/yr** since Degen Doppler went public | Degen Doppler / PolyMaster field data (2024→2026) | Edge compressing: 15–20% gaps in 2024 → 5–8% in 2026 on same horizons |
| **Minimum profitable WR = 52.5%** at 5% fee, 1:1 R:R. Safe minimum 58% (3× friction margin) | Fee math derivation: WR_min = (1 + fee_rate) / 2 | Replaces intermediate's implicit "≥ 7% net edge" with WR-based gate |
| **GEFS cold bias ~0.5–1°C** (summer, continental North America); ECMWF more neutral | NOAA GEFS verification data | Adds seasonal correction lookup to avoid systematic mispricing |
| **Station distance gate quantified**: ≤ 15km any terrain; ≤ 5km complex terrain | PolyMaster station-methodology + intermediate 3–5°C bias finding | Converts intermediate's qualitative bias warning to deployable threshold |
| **Edge decay is competition-driven, not regime-driven** — each public tool release compresses edges by ~3–5% | DevGenius publication analysis (50k+ readers → new bots entering) | Anti-prim condition becomes measurable: track edge-at-signal over time |

### Key Numbers

| Metric | Value |
|---|---|
| WR day 1 (3-model consensus, major city, calibrated) | ~85% |
| WR day 2 | ~75% |
| WR day 3 | ~65% |
| WR day 4–5 | ~55% (marginal — reject unless edge ≥ 12%) |
| WR day 6+ | ~50% (no edge — climatology baseline) |
| Minimum WR at 5% fee, 1:1 R:R | **52.5%** (breakeven) |
| Safe WR target (3× friction margin) | **58%** (= 7% net edge) |
| EMOS CRPS improvement vs raw Φ | 15–25% |
| EMOS warm-up requirement | 30 days of archived forecast-vs-outcome pairs |
| Conservative fallback without warm-up | 1.2× ensemble_std inflation |
| Market efficiency signal | liquidity > $50k AND bid-ask spread < $0.02 |
| Edge gap 2024 (naive) | 15–20% |
| Edge gap 2026 (sophisticated) | 5–8% (compressed by bots) |
| Edge compression per public tool release | ~3–5% per major release |
| GEFS seasonal bias | −0.5–1°C summer continental North America |
| ECMWF lead time advantage over GFS | ~1 day (consistent across all horizons) |
| Ensemble_std reject threshold | > 3°C |
| Model directional conflict reject threshold | > 2°C ECMWF vs GFS mean |
| Station distance reject (any terrain) | > 15km |
| Station distance reject (complex terrain) | > 5km |

### Friction Model

```
EV = WR × R_win - (1 - WR) × R_loss - fee_rate
At 1:1 R:R, fee_rate = 0.05 (weather category, 0% maker rebate):
  Breakeven: WR = (1 + 0.05) / 2 = 52.5%
  Safe minimum: WR = 58% (EV = 0.11 per unit — covers slippage + timing error)
  Day 1 expected: WR = 85% → EV = 0.65 (strong)
  Day 3 expected: WR = 65% → EV = 0.25 (viable)
  Day 4–5 expected: WR = 55% → EV = 0.05 (marginal — reject unless edge ≥ 12%)
```

Note: weather category has 0% maker rebate (unlike politics 50% rebate). No secondary revenue from quoting.

### EMOS Calibration Pipeline

```python
# Ensemble Model Output Statistics (EMOS / NGR calibration)
# Gneiting et al. 2005 adapted for NWP:
# F_cal = N(mu_cal, sigma_cal^2)
# mu_cal    = a + b * mu_ensemble
# sigma_cal = sqrt(c + d * var_ensemble)
# Parameters a, b, c, d fit via CRPS minimization on 30-day rolling window

# Fallback without warm-up (< 30 days history):
# mu_cal = mu_ensemble  (no bias correction)
# sigma_cal = 1.2 * sigma_ensemble  (conservative underdispersion inflation)
```

Without EMOS warm-up, raw Φ systematically underestimates bracket probability tails → model appears more confident than it is. The 1.2× spread inflation corrects this directionally without requiring calibration data.

### Seasonal NWP Bias Map (Selected Cities)

| City | Season | GEFS Bias | ECMWF Bias | Action |
|------|--------|-----------|------------|--------|
| Dallas | Jul–Aug | −1°C (cold) | −0.3°C | Prefer ECMWF as anchor |
| Chicago | Jun–Aug | −0.8°C | −0.2°C | Prefer ECMWF as anchor |
| London Heathrow | Year-round | < 0.3°C | < 0.2°C | Both acceptable |
| Tokyo | Dec–Feb | −0.5°C | −0.1°C | Prefer ECMWF as anchor |
| San Francisco | Any | > 1°C coastal fog bias | 0.5°C | Complex terrain — distance gate critical |

General rule: when GEFS and ECMWF systematic biases are in the same direction AND same magnitude, correlated-model failure risk is elevated → reject or reduce position.

### Competition Landscape

| Actor | Signal | Edge |
|---|---|---|
| Casual bettors | None / vibes | −5% baseline |
| GFS-only bots (DevGenius published) | Raw GFS member count | ~50% (no calibration) |
| Station-matched bots (PolyMaster methodology) | GFS + ECMWF Gaussian Φ | 65–70% WR |
| **This prim (sophisticated)** | EMOS-calibrated + spread gate + conflict gate | **75–85% WR day 1** |
| Unknown professional MMs | Likely ECMWF HRES deterministic | 75–85% (day 1 only) |

Competitive advantage remaining in 2026:
- ECMWF CDS API (not all bots use — requires Copernicus account)
- EMOS calibration (warm-up period is a barrier)
- Ensemble spread exclusion (most public tools do not gate on model uncertainty)
- Seasonal bias correction (not documented in any public tool)

### Failure Modes (Quantified, 10 Modes)

1. **Market efficiency absorption** — if liquidity > $50k AND spread < $0.02, professional bots have priced parity; skip. Estimated 15–25% of target markets in 2026.
2. **Convective instability** — ensemble_std > 3°C means the ensemble is not normally distributed; Gaussian Φ invalid; ~5–10% of forecasts during storm season.
3. **Model directional conflict** — ECMWF and GFS disagree directionally by > 2°C; signal uncertain; ~10–15% of day 3–5 forecasts.
4. **Station-gridpoint mismatch** — > 15km in flat terrain, > 5km in complex terrain; up to 3–5°C mean bias; affects markets in hilly cities (SF, Denver, Seoul).
5. **Stale model run** — run age > 6h; GFS updates every 6h, ECMWF 12h; must track `model_run_time` explicitly.
6. **Day 6+ horizon** — NWP skill degrades to climatology; WR ~50% → no edge at 5% fee.
7. **Seasonal GEFS bias uncorrected** — GEFS cold bias −0.5–1°C summer continental; misprices hot-day brackets.
8. **Market voiding risk** — Polymarket weather markets have ~2–5% void rate; capital locked during resolution ambiguity.
9. **Correlated city positions** — London + Paris same-day temperature bets have ρ ≈ 0.60–0.75; use `fractional-kelly-sizing` N_eff for concurrent positions.
10. **EMOS parameters stale** — if model upgrade changes ensemble characteristics, 30-day window picks up change but first 15 days carry stale parameters; reduce fraction 0.25 → 0.10 after NWP model updates.

### 8 Implementation Gaps (src/weather/strategy.py)

1. **EMOS calibration class**: `EMOSCalibrator.fit(mu_hist, sigma_hist, obs_hist)` + `EMOSCalibrator.transform(mu_new, sigma_new)` → `src/weather/calibration.py`; warm-up check: if `len(history) < 30`, apply 1.2× sigma inflation fallback
2. **Ensemble spread gate**: `if ensemble_std > 3.0: skip_trade()` — fetch from GEFS 31-member spread, ECMWF 51-member spread (mean of both); add to `analyze_event()` pre-signal check
3. **Model directional conflict gate**: `if abs(gfs_mean - ecmwf_mean) > 2.0: skip_trade()` — new check in `analyze_event()`
4. **Station distance gate**: `station_distance = haversine(station_lat, station_lon, grid_lat, grid_lon)`; complex terrain flag via DEM tile lookup; reject if complex + dist > 5km or any + dist > 15km
5. **Market efficiency gate**: `if market_liquidity > 50000 and bid_ask_spread < 0.02: skip_trade()`
6. **Seasonal bias correction**: lookup table `GEFS_BIAS[city][month]`; `ecmwf_mean_corrected = ecmwf_mean - ECMWF_BIAS.get(city, 0)`; consensus = weighted mean (ECMWF 0.60, GFS 0.40, reflecting ECMWF lead time advantage)
7. **WR gate**: replace horizon-only MIN_EDGE thresholds with explicit `expected_wr = get_expected_wr(horizon_days)` check; reject if `expected_wr < 0.58`
8. **Edge decay tracking**: `EdgeTracker.record(signal_edge, outcome)` → write to `user_data/edge_log.json`; if rolling 20-trade mean edge < 5% → emit `ANTI_PRIM_WARNING` and reduce sizing to minimum floor

### Evidence

- **Source:** paper + practitioner data
- **Certainty:** hypothesis (no own-data backtest with EMOS calibration; WR numbers are derived from source data not own-tested)
- **Scope:** major-city daily temperature bracket markets on Polymarket
- **Falsifiability:** testable — 100-trade sample required; anti-prim thresholds defined
- **Limitations:** documented (10 failure modes + 2 anti-prim escape hatches)

### Anti-Prim Escape Hatches

**(A) Market saturation**: rolling 20-trade mean net edge < 5% across all target cities → edge compressed by competition beyond recovery. Mark anti-prim. Do not re-refine — this is a structural market efficiency change, not a parameter problem.

**(B) WR plateau failure**: own-data 100+ trade sample delivers WR < 55% at day 1–2 — despite EMOS calibration, ensemble spread gate, model conflict gate. Means NWP-to-market probability gap is not a persistent edge source; competing bots respond too fast. Mark anti-prim.

Any outcome from own-data testing is load-bearing:
- WR ≥ 75% at day 1 → validates sophisticated tier, consider live deployment
- WR 58–74% → viable, run with minimum Kelly (α=0.10 floor, grow with calibration history)
- WR 52–58% → marginal, reduce horizon to day-1 only, re-evaluate after 50 more trades
- WR < 52% → anti-prim (A or B)

### Sources (9)

- [AMS MWR 2008 — Probabilistic Forecast Calibration: ECMWF and GFS Reforecasts (Hamill et al.)](https://journals.ametsoc.org/view/journals/mwre/136/7/2007mwr2410.1.xml) — EMOS calibration, CRPS improvement 15–25%, ECMWF vs GFS accuracy hierarchy
- [Njuguna / DevGenius (Feb 2026)](https://blog.devgenius.io/found-the-weather-trading-bots-quietly-making-24-000-on-polymarket-and-built-one-myself-for-free-120bd34d6f09) — $24k London bot, practitioner WR, competition landscape
- [PolyMaster (2026)](https://medium.com/@wanguolin/how-to-gain-an-edge-in-the-global-temperature-anomaly-market-1-from-weather-station-to-polymarket-c6e6fdc9444a) — station-to-grid methodology, 70–75% WR, $65k NY/London/Seoul
- [Degen Doppler — Weather Edge Finder](https://degendoppler.com/) — market efficiency signal; edge compression tracking
- [Climate Sight](https://www.climatesight.app/weather-prediction-market-strategies/) — market efficiency guard methodology
- [NOAA GEFS Verification](https://www.emc.ncep.noaa.gov/gmb/ens/ENS_OPS.html) — seasonal GEFS bias documentation, summer continental cold bias
- [ECMWF Forecast Verification](https://www.ecmwf.int/en/forecasts/charts/catalogue/plwww_m_hr_dc_wp_fc_global_ens_vertint) — ECMWF 1-day lead time advantage over GFS; BSS comparisons
- [BSIC — Transaction Cost Modelling](https://bsic.it/backtesting-series-episode-5-transaction-cost-modelling/) — friction model analogy (~47% Sharpe erosion at sister prim level; weather market fee math applied independently)
- [QuantPedia — IS vs OOS Analysis](https://quantpedia.com/in-sample-vs-out-of-sample-analysis-of-trading-strategies/) — OOS degradation framework applied to edge compression
