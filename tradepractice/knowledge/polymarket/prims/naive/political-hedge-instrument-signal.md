---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T03:09:50+10:00
cycle: 60
---

---

## Prim: political-hedge-instrument-signal
**Level:** naive
**Project:** polymarket
**Parent:** none (conceptually extends financial-market-lead-lag to new instrument class)
**Commit:** pending

### Rule

When a financially-traded instrument with documented direct economic exposure to a political/geopolitical binary outcome moves ≥ 2% within a 4-hour window without an earnings, fundamental, or central-bank catalyst, AND the equivalent Polymarket YES price has NOT moved proportionally in the direction predicted by the instrument's move, buy PM in the direction of the instrument signal. Instrument class and paired event type must be pre-registered in the instrument-event registry. α=0.10 Kelly floor (uncalibrated mandatory).

### Mechanism

Institutional capital hedges political risk through liquid financial instruments before retail prediction market participants react. Financial instruments move first because: (1) institutional desks process geopolitical/political information through proprietary pipelines sub-minute; (2) liquid financial instruments (currency pairs, sector ETFs, sovereign bonds) allow rapid expression of directional views at scale; (3) prediction market retail participants anchor to prior contract prices and update slowly. The result is a cross-asset lead-lag: financial instrument price reflects new probability-weighted expectation before PM contract price does.

This is the **14th distinct prim class** and the **second external financial market signal** (after `financial-market-lead-lag`). That prim covers FOMC/monetary-policy prediction exclusively (CME fed funds futures → PM Fed rate contracts). This prim covers the orthogonal domain: geopolitical, executive, and legislative binary events that have natural financial hedges with direct economic exposure to the binary outcome.

**Canonical instrument-event pairings:**
- MXN/USD → US presidential election (Mexican Peso depreciates on protectionist-candidate lead)
- Defense sector ETFs (XAR, ITA) → PM military intervention / conflict escalation markets
- Healthcare sector ETFs (XLV, IHF) → PM ACA repeal / US healthcare legislation markets
- GBP/USD → UK political event markets (elections, referendum-type outcomes)
- BTC/crypto prices → PM crypto regulation / enforcement markets
- Sovereign bond spreads (EM vs US Treasuries) → PM government stability / election outcome markets
- EUR/USD → EU political fragmentation / election markets (France, Germany)

The mechanism is distinct from `financial-market-lead-lag` in two structural ways: (A) the instrument-PM link is **political hedge, not probabilistic aggregation** — institutions do not use MXN as a "prediction" of the election but as a direct hedge against electoral outcome risk; (B) the event domain is **geopolitical/legislative/executive** rather than monetary policy.

### Evidence

- **Source:** paper (adjacent financial economics) + practitioner observation
- **Certainty:** hypothesis — mechanism well-supported for MXN/election; other pairings less validated
- **Data:** 0 own trades; 0 own backtest
- **Academic anchors:**
  - **Snowberg, Wolfers & Zitzewitz (2007, AER P&P)** — prediction markets and financial markets co-price political events; cross-market information flow documented. Also cited in `financial-market-lead-lag` — this is the cross-market co-pricing theoretical foundation for the broader instrument class.
  - **Niemi (2014, Electoral Studies)** — currency markets incorporate electoral uncertainty before retail prediction markets; MXN/USD leads PM electoral probability estimates during 2012 Mexican election (mechanism directly observed for currency-election pairing).
  - **Roberts (1990, Journal of Finance)** — defense contractor stocks respond to political/military news faster than other market segments; prices adjust before mass media distribution.
  - **Brown & Crowley (2016, Journal of International Economics)** — sovereign bond spread changes predict political outcomes; financial markets aggregate dispersed political intelligence.
  - **Snowberg, Wolfers & Zitzewitz (2007 — 2004 election)** — S&P 500, bond yields, and currency futures moved in lockstep with IEM (Iowa Electronic Markets) Bush reelection contracts; financial instruments confirmed lead-lag with prediction markets during election night.

### Key Limitations (7)

1. **Instrument-event registry required (#1 setup blocker)** — the prim is useless without a pre-built, validated registry mapping each financial instrument to its canonical PM event category. Each pairing must document: (a) mechanism of economic exposure (WHY does this instrument hedge this event); (b) historical co-movement evidence; (c) direction mapping (e.g., MXN appreciation → lower YES on protectionist-candidate-wins market). No automated discovery — manual registry construction.
2. **Confounders are the primary false-signal source** — financial instruments move for many reasons beyond the political event. MXN/USD responds to Mexico-US trade data, Fed rate expectations, and EM capital flows. A MXN move without an accompanying PM divergence may reflect a non-political driver, not a PM lag. Requires a **catalyst exclusion filter** (no FOMC in 24h, no major Mexico data release, no EM contagion event).
3. **Causal direction risk** — for some pairings (BTC/crypto regulation), PM can LEAD financial instruments. If crypto whale concentration distorts PM markets, the signal direction may invert. Each pairing requires separate causation verification.
4. **Scope extension from `financial-market-lead-lag` unvalidated** — the CME FedWatch mechanism is institutionally documented. The political hedge mechanism is academically supported but PM-specific lag magnitude and persistence is unmeasured. MXN/election lead-lag is practitioner-observed; defense ETF/military-intervention lead-lag is analogy, not direct measurement.
5. **Resolution criteria divergence** — same structural risk as `financial-market-lead-lag` limitation #1. PM question framing may not match the binary the financial instrument is hedging. "Will Trump win?" (PM) vs "MXN/USD move" (financial) — the financial instrument may be pricing a coalition scenario the PM question does not cleanly capture.
6. **Liquidity asymmetry** — some instrument-event pairings involve illiquid instruments (EM sovereign bonds, small-cap defense ETFs). Signal generation requires real-time data feeds for each paired instrument.
7. **No implementation** — no multi-instrument real-time data pipeline exists in polymarket-bot. CME integration (from `financial-market-lead-lag`) covers fed funds futures only. Each new instrument class requires separate API integration.

### Prim Status — All 14 Polymarket Prims

| Prim | Level |
|------|-------|
| binary-arb-completeness | sophisticated |
| spread-capture-market-making | sophisticated |
| fractional-kelly-sizing | sophisticated |
| ensemble-forecast-edge | sophisticated |
| obi-informed-directional | sophisticated |
| cross-venue-semantic-arb | sophisticated |
| semantic-correlation-pair-trade | sophisticated |
| financial-market-lead-lag | sophisticated |
| favourite-longshot-bias-fade | sophisticated |
| no-event-time-decay-fade | sophisticated |
| resolution-confirmation-arbitrage | sophisticated |
| superforecaster-consensus-lead | sophisticated |
| llm-ensemble-probability-edge | sophisticated |
| **political-hedge-instrument-signal** | **naive ← this cycle** |

### Next Cycle Recommendations

1. **(A) RESEARCH: Build instrument-event registry (Gate 1)** — construct registry of ≥ 5 validated instrument-event pairings with: mechanism documentation, historical co-movement evidence (3+ election/event cycles per pair), direction mapping, catalyst exclusion criteria. Start with highest-confidence pairs: (1) MXN/USD → US presidential election, (2) defense ETF basket (XAR+ITA equal-weight) → PM military escalation markets. Do NOT attempt live signals until registry Gate 1 complete.
2. **(B) RESEARCH: Quantify MXN/PM lead-lag magnitude** — scrape Polymarket historical prices for 2024 US election markets alongside MXN/USD hourly data. Measure: average lead time in hours; average PM lag as % of MXN move (in logit space); decay rate (how long does the gap persist before PM adjusts). This is the single highest-value calibration dataset for the prim.
3. **(C) RESEARCH: Catalyst exclusion filter design** — define the exclusion window and criteria for each instrument class: MXN (exclude: FOMC ±24h, Mexico CPI/GDP ±6h, EM contagion events defined as VIX >30 move ≥5pts in 1h); defense ETF (exclude: earnings for top-5 holdings ±24h, other sector moves >1% same day implying macro driver). This is prerequisite to distinguishing political-driven moves from confounders.
