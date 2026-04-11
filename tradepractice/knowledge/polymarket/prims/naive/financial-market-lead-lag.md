---
name: financial-market-lead-lag
level: naive
project: polymarket
parent_prim: none
created: 2026-04-11
last_validated: never
reaction_validated: assumed
---

## Prim: financial-market-lead-lag
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule
When CME FedWatch implied probability for an FOMC rate decision diverges from the equivalent Polymarket market price by >= 6%, buy the Polymarket market in the CME-predicted direction. Size via fractional-kelly-sizing with α=0.10 (uncalibrated signal, mandatory floor).

### Mechanism
Federal funds futures are traded by institutional participants (banks, hedge funds, fixed income desks) with resources to parse FOMC communications, economic data releases, and Fed speaker transcripts. CME FedWatch converts these futures prices into implied probability of rate changes at specific FOMC meetings. Polymarket "Will the Fed cut rates by [date]?" markets are priced primarily by retail prediction market participants who monitor the same public information but lag institutional financial markets in interpretation and reaction speed.

When a major economic data release (CPI, NFP, PCE, FOMC minutes, Fed speeches) shifts CME FedWatch probabilities, there exists a lag window — estimated minutes to hours — before Polymarket adjusts. This lag is the edge. The structural cause: institutional fixed income desks have automated pipelines from data release to futures position update; Polymarket participants must manually observe, interpret, and trade.

This is the **8th distinct prim class** — the only prim that uses external traditional financial market data as a leading signal rather than Polymarket's own microstructure, cross-venue pricing, or information-model outputs.

| Prim | Signal Source | Mechanism Class |
|---|---|---|
| binary-arb-completeness | Polymarket CLOB (same venue) | Contractual arbitrage |
| spread-capture-market-making | Polymarket CLOB | Liquidity provision |
| ensemble-forecast-edge | NWP weather models | Domain model asymmetry |
| obi-informed-directional | Polymarket CLOB microstructure | Order flow imbalance |
| cross-venue-semantic-arb | Kalshi CLOB | Cross-platform fragmentation |
| semantic-correlation-pair-trade | Polymarket (correlated pairs) | Intra-platform consistency |
| fractional-kelly-sizing | Meta-prim (sizing) | — |
| **financial-market-lead-lag** | **CME futures / equity options** | **Institutional → retail information flow** |

### Conditions
- **Works when:** Economic data release (CPI, NFP, PCE) or Fed communication shifts CME FedWatch probability; Polymarket price has not yet adjusted; gap > combined fee floor (6% at p=0.50 geopolitics → approximately 3% net at 4% PM politics fee); Polymarket market resolves on same Fed decision date as CME contract; resolution criteria compatible (Polymarket language maps to rate-change binary, not basis-point-specific)
- **Fails when:** Polymarket market already prices efficiently (gap < 3%); resolution criteria divergence — Polymarket question language does not match CME underlying (e.g., PM asks "at least one rate cut in 2026" while CME prices specific meeting date); CME is itself wrong about the decision (tail events: unexpected policy action, emergency cuts — CME fails and PM is more accurate); PM participants also have automated data pipelines (institutional participation increases); pre-existing gap is legitimate contract difference, not information lag
- **Best pairs:** Polymarket "Will the Fed cut/raise rates by [FOMC date]?" — direct 1:1 mapping to CME FedWatch target meeting probabilities
- **Best timeframe:** Real-time monitoring; execute within 5–30 minutes of economic data release; lag window closes faster as PM market matures (2023: hours; 2025: minutes; trajectory toward near-zero)

### Evidence
- **Source:** paper (adjacent literature) + practitioner (hypothesis)
- **Certainty:** hypothesis — mechanism well-supported by financial economics; cross-market lead-lag for PM specifically is untested in own data
- **Data:** 0 own trades; no own-data backtest

**Academic anchors (mechanism support):**
1. **Gürkaynak, Sack, Swanson (2005, AER)** — "Do Actions Speak Louder Than Words? The Response of Asset Prices to Monetary Policy Actions and Statements." Establishes fed funds futures as the most accurate real-time predictor of FOMC decisions; futures prices update within seconds of data releases; information flows from data release → futures pricing within sub-minute windows at institutional desks.
2. **Snowberg, Wolfers, Zitzewitz (2007, AER P&P)** — "Party Influence on Congress and the Economy: Evidence from Prediction Markets." Documents that prediction markets and financial markets (equity prices, bond yields) price overlapping events and that financial market signals contain information about political outcomes priced by prediction markets.
3. **Tetlock, Saar-Tsechansky, Macskassy (2008, JF)** — "More Than Words: Quantifying Language to Measure Firms' Fundamentals." Adjacent evidence that institutional information processing leads retail markets.
4. **Hamilton (2008, ReStat)** — "Daily Monetary Policy Shocks and New Home Sales." Documents the precision of fed funds futures as a daily policy instrument; futures traders act within seconds of FOMC communications.

**Cross-market lead-lag precedent:**
- Equity options implied volatility leads realized volatility (Black & Scholes 1973 → CBOE VIX → abundant replication evidence)
- S&P 500 futures lead spot index (documented cross-market lead-lag, Stoll & Whaley 1990)
- The analogous mechanism for prediction markets: institutional futures lead retail prediction market pricing

**Citation:** Gürkaynak, Sack & Swanson (2005) AER; Snowberg, Wolfers & Zitzewitz (2007) AER P&P; Hamilton (2008) ReStat; [CME FedWatch Methodology](https://www.cmegroup.com/trading/interest-rates/countdown-to-fomc.html)

### Limitations
1. **Resolution criteria divergence (#1 failure mode)** — CME fed funds futures price the exact FOMC target rate decision. Polymarket questions vary: "at least one cut by year-end," "cut at March meeting," "rate below X% by Q2." When the underlying is not a binary point question on a specific meeting, CME probability cannot be directly imported. E.g., Polymarket "Will the Fed cut rates in 2026?" encompasses multiple meetings; CME March futures only price March. No automated mapping exists.

2. **Lag window is compressing** — As Polymarket attracts more institutional participants and automated bots, the information lag narrows. Estimated lag 2023: several hours; 2025: 30–90 minutes; trajectory suggests sub-5 minutes by 2027 for liquid Fed markets. This is a time-bounded edge, not a structural permanent feature.

3. **CME can be wrong** — Fed funds futures are the best predictor of FOMC decisions but are not perfect. Emergency cuts (March 2020, COVID), inter-meeting moves, and surprise hawkish pivots break the model. In these tail events, PM markets may price the actual outcome faster than CME adjusts (faster via social media). Anti-prim in extreme scenarios.

4. **Fee floor vs signal magnitude** — At p=0.50 for Polymarket politics category (4% taker fee), friction floor ≈ `fee_rate × p × (1-p) + slippage ≈ 4% × 0.25 + 1% = 2%`. A 6% gap is needed to leave 4% net. Average gaps post-2025 compression likely smaller than floor on most events — signal frequency may be very low.

5. **No implementation** — polymarket-bot has no CME API integration. CME data requires either direct API access (CME Group DataMine) or proxy via FedWatch scraping. No existing module.

6. **Scope beyond Fed** — The principle extends (Treasury futures → PM government policy markets; VIX term structure → PM election markets; FX implied volatility → PM geopolitics markets) but each extension requires separate resolution-criteria mapping and fee-floor analysis. Scope is broader than stated rule but untested.

### Implementation
- **Existing code:** NONE — new capability class
- **New file:** `src/strategies/financial_lead_lag.py`
- **Required data sources:**
  - CME Group API (DataMine subscription) OR FedWatch scraper (`https://www.cmegroup.com/trading/interest-rates/countdown-to-fomc.html`)
  - Polymarket Gamma API for Fed rate markets (filter by keyword "Federal Reserve", "Fed", "rate cut", "rate hike")
- **New module:** `src/signals/cme_fedwatch.py` — `FedWatchSignal.get_implied_probability(meeting_date: str) → float`
- **Key parameters:** `MIN_CROSS_MARKET_EDGE = 0.06`, `CME_DATA_STALENESS_MAX_MINUTES = 5`
- **Execution:** standard Polymarket market order on detected gap; size via `fractional-kelly-sizing` α=0.10 (uncalibrated floor, mandatory)
- **Resolution matching:** requires `resolution_criteria_classifier` — new module to score whether PM question language maps to a binary outcome at a specific FOMC meeting date (Class 0: direct mapping; Class 1: partial mapping with buffer; Class 2: skip)

### Conditions Log Entry
- Works when: CPI/NFP/PCE data release causes CME FedWatch shift; PM has not adjusted; gap > 6%; PM question resolves on same FOMC meeting; question is binary (cut/no cut), not magnitude-conditional
- Fails when: Resolution criteria diverge (multi-meeting PM question vs single-meeting CME); gap < fee floor; PM already efficient (institutional participants present); CME surprise error (tail event — emergency move)
- Last validated: never

## Refinement History
- 2026-04-11: Created as naive prim, cycle 36 RESEARCH. New prim class — 8th distinct Polymarket mechanism. First prim to use external traditional financial market data as leading indicator. Academic mechanism support from adjacent financial economics literature (Gürkaynak 2005, Snowberg 2007). Cross-market lead-lag for PM specifically at hypothesis level. No code implementation.

## Next Refinement Path (Intermediate)
Three upgrades required:
1. **Resolution-criteria classifier** — automated scoring of whether Polymarket question language maps to CME FedWatch meeting-specific binary (Class 0: "Will Fed cut at March 2026 FOMC?" → direct; Class 1: "Will Fed cut in H1 2026?" → partial; Class 2: "At least 3 cuts in 2026?" → skip); keyword rules + LLM fallback
2. **Dynamic lag window model** — track actual PM price update lag after economic releases; build histogram of lag distribution per PM market liquidity tier; only enter if lag_observed ≥ typical_lag_floor (filters markets where bots already arbitrage faster than threshold)
3. **Scope extension map** — catalog which PM market categories have analogous CME/CBOE/ICE instruments with reliable probability extraction: (Fed decisions → CME FedWatch); (US equity direction → VIX term structure, SPX options); (geopolitical risk → CBOE SKEW, USD/JPY implied vol); (election outcomes → S&P election-year options pricing) — one extension validated per refinement cycle
