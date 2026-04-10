---
name: ensemble-forecast-edge
level: intermediate
project: polymarket
parent_prim: ensemble-forecast-edge (naive)
created: 2026-04-10
last_validated: never
---

## Situation

### Setup
A Polymarket temperature bracket market is open. Multiple NWP model runs have updated since the market's last significant price movement. The bracket's YES price does not reflect the consensus model probability.

### Trigger
**Multi-model consensus** (≥ 2 of: GFS/GEFS, ECMWF, ICON/NAM/CMC) places bracket probability above market YES price by ≥ threshold:
- Day 1–2: edge ≥ 5%
- Day 3–5: edge ≥ 10%
- Day 5+: no trade

### Reaction
- **Accepted:** Market price converges toward model consensus as Polymarket crowd updates; position profits.
- **Rejected:** Systematic model bias (station-gridpoint mismatch, underdispersion, seasonal bias) caused miscalibrated probability estimate; consensus was wrong.
- **Unclear:** Market reprices before fill; edge evaporates without meaningful position.

### Agent Behaviour
- **Who is acting:** Automated model-reader vs casual bettors pricing on single-point NWS forecasts or intuition.
- **Who is trapped:** Casual bettors anchored to yesterday's observed high, ignoring fresh model runs.
- **Who is wrong:** Anyone holding a stale-priced bracket 2–6h after a major model run update (00z/06z/12z/18z).

### Outcome
- **If accepted:** Profit on bracket resolution; WR 70–75% on day-1 consensus signals (practitioner data, multiple sources).
- **If rejected:** Systematic bias materialises; model consensus all wrong simultaneously (correlated failure).
- **If unclear:** Execution friction consumes theoretical edge.

## Rule
Buy YES on temperature bracket if ≥ 2 independent NWP models (must include ECMWF or GFS) place bracket probability above market YES price by ≥ 5% (day 1–2) or ≥ 10% (day 3–5). Use Gaussian bracket probability: `P(bracket) = Φ((high − μ_ens) / σ_ens) − Φ((low − μ_ens) / σ_ens)` where μ_ens = ensemble mean, σ_ens = max(ensemble_std, climatological_floor). Skip tail brackets (YES < $0.05 or YES > $0.95).

## Mechanism
Information asymmetry: NWP models (GFS 00z/06z/12z/18z, ECMWF 00z/12z) update every 6h and require technical access/processing. Casual Polymarket bettors price on yesterday's observed temperature, intuition, or lagged NWS point forecasts. The edge is latency arbitrage: market price has not caught up to the latest model run. On day-1 forecasts, professional models are almost always correct; crowd pricing remains anchored to stale information for hours after each model update cycle.

Secondary mechanism: model consensus (≥ 2 independent models agreeing) eliminates single-model failure modes. When GFS + ECMWF + optional third model all place bracket at 70–90%, market price at $0.15–$0.40 implies a large, exploitable mispricing.

## Conditions
- **Works when:**
  - 1–2 days before resolution (highest model skill; ECMWF Brier SS > 0.70 for temperature day-1)
  - ≥ 2 models in consensus (70–90% accuracy at day-1–2)
  - Market price "obviously wrong" (model prob ≥ $0.60 but market YES ≤ $0.35)
  - Bracket within ensemble spread (bracket mean within ±2σ of ensemble mean)
  - Market has recent price activity (non-stale orderbook)
  - Liquidity ≥ $1,000 (raised from naive $500 — thinner books have wider effective spreads)
  - Bracket bounds ≥ 1°C wide (narrow brackets have extreme sensitivity to bias)

- **Fails when:**
  - Single-model signal only (GFS or ECMWF alone without confirmation) — naive failure mode
  - Station-gridpoint mismatch: model gridpoint ≠ weather station used for resolution — **#1 systematic failure mode**
  - All models underdispersive on the specific city/season (systematic ensemble bias uncorrected)
  - Extreme weather event (convective, tropical) — ensemble spread collapses artificially
  - Day 5+ forecast (model skill degrades to near-climatology)
  - Tail bracket (YES < $0.05 or YES > $0.95) — probability estimate unreliable, too few ensemble members in tail
  - Competing bots visible (tight bid-ask spread with large depth = market already efficient)
  - Market about to resolve < 2h (price locked)

- **Best markets:** Major city daily high temperature brackets, 1–2 days to resolution; avoid exotic locations (sparse model training data, higher station bias)
- **Best timeframe:** ≥ 1h before resolution; execute within 2h of 00z/12z ECMWF update or 00z/06z/12z/18z GFS update

## Evidence

### Source Quality
- **Source:** practitioner backtests + meteorological literature + tool infrastructure
- **Certainty:** hypothesis (qualitative practitioner results are high; calibration numbers are from NWP literature, not Polymarket-specific backtests)
- **Scope:** temperature bracket markets on major-city Polymarket weather markets
- **Falsifiable:** testable — need 100+ trade sample with station-matched resolution data
- **Reaction observed:** no (no live trades from current WeatherStrategy)

### Data
- **WR 70–75%** on short-term temperature predictions using ensemble models (practitioner sources, multiple independent reports)
- **3+ model consensus accuracy:** 70–90% at day-1–2 depending on forecast distance (Ezekiel Njuguna / DevGenius, confirmed by PolyMaster Medium)
- **Documented result:** $1k → $24k trading London weather (single bot); $65k profit NY/London/Seoul (separate trader) — directionally consistent, selection bias possible
- **ECMWF day-1 skill:** maintains ~1 day of lead time advantage over GFS; calibrated ECMWF BSS > calibrated GFS BSS across all horizons (AMS MWR 2008)
- **Raw GEFS underdispersion:** known documented bias — raw ensemble member count probabilities (3.3%/member) are NOT calibrated; EMOS/NGR reduces CRPS ~15–25%
- **Edge threshold:** MIN_EDGE=0.08 (naive) is between appropriate day-1 (5%) and day-3-5 (10%) thresholds — partially correct but not horizon-aware

### Citations
- [People Are Making Millions Betting on Weather — Ezekiel Njuguna (Medium)](https://ezzekielnjuguna.medium.com/people-are-making-millions-on-polymarket-betting-on-the-weather-and-i-will-teach-you-how-24c9977b277c)
- [Found The Weather Trading Bots Making $24k on Polymarket — DevGenius, Feb 2026](https://blog.devgenius.io/found-the-weather-trading-bots-quietly-making-24-000-on-polymarket-and-built-one-myself-for-free-120bd34d6f09)
- [How to Gain an Edge in Global Temperature Anomaly Market — PolyMaster (Medium)](https://medium.com/@wanguolin/how-to-gain-an-edge-in-the-global-temperature-anomaly-market-1-from-weather-station-to-polymarket-c6e6fdc9444a)
- [Probabilistic Forecast Calibration Using ECMWF and GFS Reforecasts Part I: Temperatures — AMS MWR 2008](https://journals.ametsoc.org/view/journals/mwre/136/7/2007mwr2410.1.xml)
- [Degen Doppler — Polymarket Weather Edge Finder (tool)](https://degendoppler.com/)
- [WeatherEdge — AI Weather Intelligence for Prediction Markets](https://www.weatheredge.store/)

## Limitations
1. **No own Polymarket-specific backtest.** All WR data is practitioner anecdote or NWP literature extrapolated to prediction markets. Need 100+ resolution sample.
2. **Station-gridpoint mismatch is unresolved.** Current WeatherStrategy uses arbitrary lat/lon; resolution uses NWS ASOS station. Systematic bias uncorrected.
3. **Raw GEFS member count ≠ probability.** GFS underdispersive: 20 of 30 members in bracket ≠ 67% probability. Must use Gaussian approximation from ensemble mean/std or EMOS calibration layer.
4. **ECMWF not integrated.** Current code fetches GFS only. ECMWF access requires API key (commercial or Copernicus CDS). Multi-model consensus requires second model integration.
5. **No model-update-cycle awareness.** Strategy does not know when last model run was ingested. Stale model data is worse than no edge.
6. **Execution costs vs edge unquantified.** Weather markets have taker fees (likely 5% category). 5% MIN_EDGE would be wiped out by fees on day-1 signals.
7. **Correlated failure mode.** When NWP models are wrong simultaneously (mesoscale convection, rapid intensification), both GFS and ECMWF fail together — the consensus filter does not protect against correlated model failure.

## Implementation

### Core upgrade path (6 gaps from naive)
1. **Gaussian bracket probability** instead of raw member counting:
   ```python
   from scipy.stats import norm
   def bracket_prob(low, high, ens_mean, ens_std):
       sigma = max(ens_std, 2.0)  # climatological floor 2°C
       return norm.cdf(high, ens_mean, sigma) - norm.cdf(low, ens_mean, sigma)
   ```
2. **Multi-model consensus check**: integrate ECMWF (Copernicus CDS API) or ICON as second source. Require ≥ 2 model agreement before trade.
3. **Horizon-gated edge threshold**: `MIN_EDGE = 0.05 if hours_to_resolution <= 48 else 0.10`
4. **Station-gridpoint matching**: use NOAA GHCN station coordinates, not city centre lat/lon.
5. **Model staleness guard**: reject signal if model run age > 6h.
6. **Fee-adjusted edge**: `net_edge = model_prob - market_price - fee_rate` (weather category ~5%).

### File: `polymarket-bot/src/weather/strategy.py`
- Existing: `analyze_event()` computes `model_prob - market_prob >= MIN_EDGE`
- Replace: raw member count → `bracket_prob(low, high, gfs_mean, gfs_std)` + ECMWF confirmation

## Conditions Log Entry
See conditions-log.md: ensemble-forecast-edge (intermediate) — 2026-04-10

## Refinement History
- 2026-04-10: Created naive prim from WeatherStrategy code extraction (cycle 4 ASSESS)
- 2026-04-10: Elevated to intermediate — added multi-model consensus gate, Gaussian probability, horizon-gated thresholds, station-gridpoint correction, model staleness guard, fee-adjusted edge (cycle 12 RESEARCH)
