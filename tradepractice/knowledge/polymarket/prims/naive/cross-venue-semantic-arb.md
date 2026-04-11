---
name: cross-venue-semantic-arb
level: naive
project: polymarket
parent_prim: none
created: 2026-04-11
last_validated: never
reaction_validated: assumed
---

## Prim: cross-venue-semantic-arb
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule
When the same real-world event is co-listed on Polymarket and Kalshi, buy the lower-priced YES and the lower-priced NO across the two venues such that combined cost < $1.00. Profit = $1.00 − total cost at resolution.

### Mechanism
Prediction market venues are informationally fragmented. The same event trades as two distinct assets with no shared liquidity, no common settlement layer, and different institutional participant pools. This structural fragmentation produces persistent price deviations averaging 2–4% in liquid markets (arxiv 2601.01706, 100k+ events, 2018–2025) even when underlying information is identical. The arb mechanism is identical to within-Polymarket `binary-arb-completeness` except the "two sides" are on different platforms with different settlement rails, different fee structures, and critically — potentially different resolution conditions.

6% of all prediction market events are concurrently listed across platforms per arxiv 2601.01706. Of those, a subset will have both semantically equivalent contracts AND a price gap exceeding combined friction.

### Conditions
- **Works when:** Same event, IDENTICAL resolution semantics (same oracle, same threshold, same wording equivalent); gross gap > 4.5% (geopolitics) or > 7% (crypto); bilateral accounts pre-funded on both platforms; both legs liquid; time-to-resolution > 4h; no pending semantic dispute
- **Fails when:** Resolution semantics differ (primary failure mode — see limitations); combined friction exceeds gross gap (structural for most 2-4% deviations); resolution divergence (platforms resolve the same event oppositely); capital bridge latency prevents both legs filling before resolution; USDC/USD conversion delayed (Kalshi uses USD via ZeroHash, Polymarket uses USDC on Polygon)
- **Best pairs:** Geopolitics category on Polymarket (0% taker fee) × equivalent Kalshi political market (1.75% taker fee at p=0.50)
- **Best timeframe:** Real-time WebSocket monitoring; execution must complete both legs within seconds; resolution horizon > 4h

### Evidence
- **Source:** paper (arxiv 2601.01706, Gebele & Matthes, Jan 2026)
- **Certainty:** hypothesis — mechanism confirmed by academic dataset; own-data zero
- **Data:** 6% of 100k+ events co-listed across 10 venues; persistent 2–4% execution-aware price deviation in liquid/info-rich settings; bid-ask compression from 4.5% (2023) to 1.2% (2025) across PM venues
- **Practitioner claims:** "12–20% monthly returns" reported (Leviathan News, 2026); counter-evidence: "combined fees 5%+ mean spreads under 5% unprofitable" and "retail-accessible opportunities hover ~2–3%, making them fee-negative" (newyorkcityservers.com)
- **Citation:** [arxiv 2601.01706](https://arxiv.org/abs/2601.01706); [newyorkcityservers.com 2026 arbitrage guide](https://newyorkcityservers.com/blog/prediction-market-arbitrage-guide); [Leviathan News on X](https://x.com/leviathan_news/status/2007769183031877664)

### Limitations (6 — documented at naive level)

1. **Semantic non-fungibility (#1 failure mode)** — "same event" is not always the same contract. Documented divergence:
   - 2024 US government shutdown: Polymarket resolved YES ("OPM shutdown announcement"), Kalshi resolved NO ("actual shutdown exceeding 24h"). Opposite-leg holders lost 100%.
   - Trump Bitcoin Reserve: Polymarket required "hold any amount"; Kalshi required "designated National Bitcoin Reserve equivalent to Strategic Petroleum Reserve." Gap of 10–20% reflected legitimate contract difference, not misprice.
   - Resolution standards: Polymarket uses "official info or consensus of credible reporting"; Kalshi requires "confirmation from White House or NYT." Same real-world event, different documentation thresholds.

2. **No atomic execution** — Polymarket operates on Polygon (USDC, on-chain); Kalshi operates on USD via banking (ZeroHash conversion hours). Capital cannot be atomically bridged. Both legs require pre-funded balances. If leg 1 fills and leg 2 fails to fill, directional binary exposure on a single-venue position.

3. **Friction floor exceeds average deviation** — at p=0.50, combined friction:
   - Minimum (maker×2, geopolitics): Kalshi maker 0.4375% + Polymarket maker 0% + bridge 0.15% ≈ **0.6%** (fill not guaranteed — liquidity provision risk)
   - Practical (taker×2, geopolitics): Kalshi taker 1.75% + Polymarket 0% + bid-ask slip ~2% + bridge 0.15% ≈ **3.9%**
   - Worst (taker×2, crypto): Kalshi 1.75% + Polymarket 1.80% + slip 2% + bridge 0.15% ≈ **5.7%**
   - Arxiv 2601.01706 average deviation (2–4%) is BELOW the practical taker friction floor (3.9–5.7%). Only the tail distribution (>5% gap) is routinely executable for profit as takers — and that is exactly the segment highest in semantic risk.

4. **Bilateral capital lockup** — capital must be pre-deployed on BOTH platforms permanently. A $1k account on each = $2k locked to generate $50 profit on a 5% gap. Opportunity cost is bilateral, not single-venue.

5. **Resolution timing asymmetry** — Kalshi can resolve hours before Polymarket on identical events (different oracle polling schedules). A platform resolving first unwinds one leg of the position, leaving naked exposure on the remaining platform until that platform resolves.

6. **Semantic classifier absent** — no automated method for scoring resolution equivalence between Polymarket and Kalshi market specifications. Manual review per market is current requirement; scales poorly.

### Implementation
- **Existing code:** NONE in `polymarket-bot/` — new prim, not extracted from codebase
- **GitHub references:** CarlosIbCu/polymarket-kalshi-btc-arbitrage-bot, realfishsam/prediction-market-arbitrage-bot, TopTrenDev/polymarket-kalshi-arbitrage-bot — open-source references exist
- **Required infrastructure:** Kalshi REST API + Polymarket Gamma API + unified event matcher + bilateral WebSocket price feeds
- **New file path:** `src/strategies/cross_venue_arb.py`
- **Key parameters:** MIN_CROSS_VENUE_EDGE, SEMANTIC_RISK_THRESHOLD, bilateral account monitors
- **Execution:** simultaneous market orders on both legs (not sequential); accept partial-fill risk explicitly

### Conditions Log Entry
- Works when: co-listed event with identical resolution semantics; gap > 3.9% (practical taker floor, geopolitics); bilateral liquidity > 2× position size; both legs fill within 2s
- Fails when: semantic non-fungibility (resolution divergence); gap ≤ friction; capital bridge delay; resolution timing asymmetry creates naked exposure
- Last validated: never

## Refinement History
- 2026-04-11: Created as naive prim from research cycle 30. Source: arxiv 2601.01706 (Jan 2026) + Kalshi/Polymarket fee documentation + historical semantic failure cases. No code extraction — new capability class.

## Next Refinement Path (Intermediate)
Three upgrades required:
1. **Semantic similarity scorer** — NLP-based market title + resolution rule comparison to assign semantic risk score (0=identical / 1=equivalent / 2=divergent/unknown); skip score ≥ 2
2. **Friction-tiered edge floor** — per-category edge floor accounting for both platforms' exact fee formula at event probability p; binary viability table vs gap magnitude
3. **Bilateral fill protocol** — simultaneous order submission with <2s second-leg timeout; cancel-and-liquidate if second leg fails; leg ordering by liquidity (less-liquid leg first)
