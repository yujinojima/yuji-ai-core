---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T06:15:00+10:00
cycle: 68
---

---

## Prim: news-velocity-informed-directional
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule
`V_t = article_count(event, past 30 min) / baseline_rate > 3.0` AND `sentiment_sign ≠ 0` → BUY YES (positive sentiment spike) or BUY NO (negative sentiment spike). Hold until `V_t < 1.5` or 90-minute max. Size via `fractional-kelly-sizing` sophisticated prim.

### Mechanism
News publication velocity — the rate at which new articles are published about a market event — leads prediction market price updates by a measurable lag. When a developing story spikes in coverage (velocity > 3× baseline), institutional and quantitatively sophisticated participants update their probability estimates within 5–15 minutes; the broader Polymarket participant pool incorporates the information over 30–120 minutes. This lag creates a directional window: trade in the direction the news sentiment points before the market fully adjusts. The signal is not *what* the probability should be (ensemble forecast) nor *what financial instruments are pricing in* (financial-market-lead-lag); it is the *rate of new information entering the public domain*, which correlates with market under-reaction to a developing story.

Distinct from all 14 existing polymarket prims:
- `ensemble-forecast-edge` / `llm-ensemble-probability-edge` / `superforecaster-consensus-lead`: slow-moving consensus, not real-time velocity
- `financial-market-lead-lag` / `political-hedge-instrument-signal`: financial instrument prices as proxy signals, not news publication rate
- `resolution-confirmation-arbitrage`: post-resolution window, not pre-resolution signal
- `obi-informed-directional`: CLOB depth imbalance as signal source (effect), not news publication rate (cause)

### Evidence
- **Source:** Tetlock (2007 JF) — news sentiment predicts next-day equity returns (single equity-market source; prediction market analogue unverified)
- **Source:** Cowgill & Zitzewitz (2015 ReStat) — prediction market prices react to event news with heterogeneous lag; early movers systematically lead
- **Source:** Ranco et al. (2015) — Twitter message volume (velocity proxy) precedes prediction market price movements on specific political events
- **Certainty:** hypothesis — no peer-reviewed study directly tests news *velocity* (rate of publication) as a directional signal in binary prediction markets; all anchors are indirect
- **Data:** 0 own trades
- **Critical risk:** Velocity spike may confirm an already-priced move (institutional bots reading same feeds and acting in <1s); 30-minute window may arrive after market has fully adjusted

### Limitations (8)
1. Velocity threshold (3×) and window (30 min) are heuristics — no calibration performed
2. Baseline rate estimation methodology undefined (rolling 24h average? day-of-week adjusted? pre-event vs live-event period?)
3. Sentiment direction detection requires NLP pipeline not yet built — polarity classification error rate unknown
4. News source quality filter absent — tabloid spike ≠ Reuters spike; no source authority weighting
5. Entity matching to Polymarket market is unresolved — "news about event X" requires NLP entity extraction and market-text alignment
6. Professional bots (Polymarket Research, PolySwarm) likely operate sub-30s on same signal — retail 30-minute lag assumption may be wrong in liquid markets
7. No fee model — 5% geopolitics fee eats ≈ 4pp directional edge at p=0.50; only viable if directional move ≥ 9pp within hold window
8. Single academic source (Ranco et al.) tests Twitter volume as velocity proxy for prediction markets, not structured news databases; generalisability to GDELT/NewsAPI unknown

### Files
- `knowledge/polymarket/prims/naive/news-velocity-informed-directional.md` — created
- `knowledge/epistemic-index.md` — 15th polymarket prim row to be added
- `knowledge/conditions-log.md` — news-velocity conditions to be appended

### Prim status

| Prim | Level |
|------|-------|
| binary-arb-completeness | sophisticated |
| spread-capture-market-making | sophisticated |
| fractional-kelly-sizing | sophisticated |
| ensemble-forecast-edge | sophisticated |
| obi-informed-directional | naive |
| cross-venue-semantic-arb | sophisticated |
| semantic-correlation-pair-trade | sophisticated |
| financial-market-lead-lag | sophisticated |
| favourite-longshot-bias-fade | sophisticated |
| no-event-time-decay-fade | sophisticated |
| resolution-confirmation-arbitrage | sophisticated |
| superforecaster-consensus-lead | sophisticated |
| llm-ensemble-probability-edge | sophisticated |
| political-hedge-instrument-signal | sophisticated |
| **news-velocity-informed-directional** | **naive ← this cycle** |

### Next cycle recommendations
1. **(A) RESEARCH: Elevate news-velocity-informed-directional to intermediate** — find peer-reviewed prediction market reaction-lag studies; determine optimal velocity threshold and baseline window via own-data frequency scan; test GDELT article count as velocity proxy on historical Polymarket events; add sentiment direction classifier
2. **(B) RESEARCH: Elevate obi-informed-directional to intermediate** — wash-adjusted OBI methodology (Bawa arxiv 2603.03152 implementation); calibrate IR threshold by liquidity tier; validate 58% directional accuracy claim
3. **(C) BUILD: news-velocity pipeline prototype** — GDELT GKG real-time feed → entity matching to Polymarket market title → article count aggregation → velocity ratio calculation; determine whether 30-minute lag assumption holds on liquid markets
