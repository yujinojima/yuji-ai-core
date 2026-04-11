---
name: obi-informed-directional
level: sophisticated
project: polymarket
parent_prim: intermediate/obi-informed-directional
created: 2026-04-11
last_validated: never
---

## Prim: obi-informed-directional
**Level:** sophisticated (elevated from intermediate)
**Project:** polymarket
**Parent:** intermediate/obi-informed-directional

### Rule
**Parent-order lifetime filter** (order tracked via CLOB WebSocket: resting ≥ 5s AND modification_count ≤ 2) + **IR_clean = (V_bid_parent − V_ask_parent) / (V_bid_parent + V_ask_parent)** + **λ-adaptive snapshot confirmation** (λ < 0.05 mature: 3 consecutive 10s snapshots; λ > 0.05 thin: 5 consecutive snapshots) + **liquidity-tiered threshold** (thin $2k–$5k: IR_clean > 0.80; mid $5k–$50k: IR_clean > 0.70 [raised from 0.65 for Paradigm double-count correction]) + **category exclusion** (sports/crypto excluded; geopolitics: 0% fee; politics/finance: 4% fee) + **persistent-OBI targeting** (NOT first-mover OBI — target residual signal sustained after HFT consumed initial imbalance) + **category-specific hold** (geopolitics 30–60min; politics/finance 15–30min) + Kelly sizing via `fractional-kelly-sizing` sophisticated prim → long mispriced side.

### What Elevated This from Intermediate

Four core upgrades. Intermediate had: 5s aggregate resting proxy (weak filtration), 3-snapshot fixed confirmation, IR_clean > 0.65 flat threshold, no latency-rank competitive model.

| # | Upgrade | Source |
|---|---------|--------|
| 1 | **Parent-order lifetime filter** — track parent order IDs, modification count, modification timing; "parent-order filtration produces systematically stronger directional association vs aggregate filtration which produces only modest improvement" | arxiv 2507.22712 |
| 2 | **Latency-rank reframe: persistent-OBI targeting** — OBI profit determined by LATENCY RANK not absolute latency; Python async at 10s occupies lowest rank; target PERSISTENT OBI (≥ 30s sustained = signal residual after HFT consumed first-mover); validated by VR(6)=1.84 persistent drift at political shocks | arxiv 2006.08682 (Byrd et al.), arxiv 2603.03152 |
| 3 | **Kyle λ maturation gate** — at λ > 0.05 (thin, immature market): single large order creates misleading OBI; require 5 consecutive snapshots (vs 3) before signal fires; at mature λ < 0.05: 3 snapshots sufficient | arxiv 2603.03136 (from spread-capture sophisticated) |
| 4 | **Paradigm double-count correction → IR threshold uplift** — Paradigm Dec 2025: Polymarket volume systematically double-counted; true wash % understated; conservative uplift: treat all categories as 25% wash floor (up from 17% geopolitics estimate); consequence: IR threshold raised from 0.65 to 0.70 for mid-liquidity markets (8% additional signal buffer above noise floor) | Paradigm Dec 2025, Columbia SSRN 5714122 |

### Mechanism

Informed traders accumulate on one side of the CLOB before a price move, leaking directional intent via measurable depth imbalance. **Prediction market OBI operates on a fundamentally different timescale than equity OBI**: equity half-life is 5–30 seconds (HFT consumed); prediction market persistent drift (VR=1.84) lasts minutes because information incorporation is slower — market participants are not co-located professionals. 

The competitive edge is NOT first-mover signal (consumed by <30ms bots). The edge is persistent imbalance: when IR_clean stays elevated across 3–5 consecutive 10s snapshots (30–50s total), HFT has already traded and the remaining imbalance reflects structural directional pressure from slower informed participants still accumulating.

Structural relationship with `spread-capture-market-making` sophisticated: MM exits when |IR| ≥ 0.65; OBI directional activates on the same CLOB depth feed. Same data, complementary regime — two prims, one state machine.

### Key Quantitative Numbers

| Metric | Value | Source |
|--------|-------|--------|
| 58% directional WR at IR > 0.65 (mid-liquidity) | single-source hypothesis | Bawa Substack Dec 2025 |
| OBI R² = 0.65 (short-interval variance) | single-source | arxiv 2603.03152 |
| IR ≥ 60–65% treated as directional across equity LOBs | cross-market corroboration | QuantStrategy.io, hftbacktest, emergentmind |
| OFI signal half-life (equity HFT) | 5–30 seconds | Multiple OFI papers |
| Prediction market drift persistence (VR=1.84 at political shock) | minutes | arxiv 2603.03152 |
| Co-located Polymarket bot latency | 1–30ms | QuantVPS 2026 |
| Polymarket WS update latency | <50ms | QuantVPS 2026 |
| Our 10s snapshot vs WS latency rank | ~200× slower | derived |
| 75% of Polymarket orders match within | ~1 hour | QuantVPS 2026 |
| Sports wash rate | 45% average (peak 90%) | Columbia SSRN 5714122 |
| Elections/politics wash rate | ~17% average (peak 95%) | Columbia SSRN 5714122 |
| Volume double-counting | systematic; wash % understated | Paradigm Dec 2025 |
| Conservative wash floor (post-Paradigm) | 25% across categories | derived |
| Parent-order filtration improvement | "systematically stronger" vs "modest" for aggregate | arxiv 2507.22712 |
| Latency rank drives profit allocation | rank > magnitude | arxiv 2006.08682 |
| Breakeven WR at 0% fee (geopolitics) | 50.0% | fee math |
| Breakeven WR at 4% fee (politics) | 52.0% | fee math |
| EV at 58% WR, 4% fee, 1:1 R:R | +0.12/unit | derived |

### Friction Model

```
EV = WR × R_win - (1-WR) × R_loss - fee_rate (taker)
Geopolitics (0% fee, maker 0% rebate):
  Breakeven: WR = 50.0%
  At 58% WR: EV = +0.16/unit ← viable
Politics/finance (4% fee, 50% rebate on maker):
  Taker cost = 4%; maker rebate = 2% (50% rebated)
  If we're taker (likely for directional OBI): EV at 58% WR = +0.12/unit ← viable
  If we use limit orders (maker): EV at 58% WR = +0.14/unit
```

### Conditions

- **Works when:** Parent-order IR_clean sustained 30–50s above threshold; geopolitics or politics/finance category; price $0.20–$0.80; time-to-resolution > 2h; market liquidity $2k–$50k; total aged depth ≥ $500; signal fires AFTER initial HFT burst (not simultaneous with price move onset); Kyle λ_proxy < 0.05 or 5-snapshot confirmation met
- **Fails when:** Sports (45% wash + live-score adverse selection <5min — #1 exclusion); crypto (7.2% fee, unknown wash); liquidity > $50k (professional bots respond in <200ms, no actionable window); thin book < $2k (single order dominates IR); signal appears simultaneously with news event (adverse selection risk — MM dynamics); first-mover OBI (consumed by <30ms bots before our 10s snapshot); wash-dominated period (all resting orders < 5s = zero aged depth); λ > 0.05 without 5-snapshot confirmation (thin immature book, single order distorts IR); resolution < 2h
- **Best markets:** Geopolitics (0% fee, lowest wash) > politics/finance (4% fee, 50% rebate)
- **Best timeframe:** Real-time WebSocket; 10s snapshot interval targeting persistent imbalance; hold 30–60min (geopolitics), 15–30min (politics)

### Failure Modes (Quantified, 8 Modes)

1. **Latency rank penalty** — lowest-rank agents retain zero profit from fast OBI signal at limit (arxiv 2006.08682). Python async at 10s: first-mover OBI is NOT our signal. Only persistent OBI (3–5 snapshots sustained) is our viable window. ~40–60% of OBI signals will have been consumed by faster bots before our snapshot captures them.
2. **Wash contamination residual** — parent-order filtration removes <200ms wash (primary) but 3–5% contamination persists during high-volatility periods when wash traders hold positions briefly. Estimated IR inflation: 3–8% in volatile periods → increases false positive rate.
3. **Paradigm double-count uncertainty** — volume figures underlying wash % estimates are systematically inflated. True wash % is unknown; 25% floor is conservative estimate. If true wash exceeds 40% in geopolitics (approaching sports levels), even parent-order filtration insufficient.
4. **Single-source 58% WR claim** — Bawa's 58% is unreplicated. Cross-market IR threshold corroboration (≥60–65% threshold) supports the signal direction but NOT the magnitude. Own-data validation is the only resolution.
5. **Kyle λ false signal** — at λ > 0.05 (thin market < $2k–$5k): a $5k order pushes price 1% AND creates IR → 0.90. This is one actor, not informed consensus. The 5-snapshot confirmation at thin markets reduces false positives but does not eliminate them.
6. **Sports peak wash contamination** — Sports peaks at 90% wash in specific weeks (Columbia). Even with sports EXCLUDED, if a geopolitics market develops sports-like wash trading patterns (e.g., coordinated accounts), the category filter alone is insufficient. The Paradigm-correction IR threshold uplift (0.65→0.70) provides a 8% additional buffer.
7. **Persistent-OBI false positive** — If informed trader holds position across 3+ snapshots while driving price (not pre-positioning), the persistence filter captures a lagged signal on a move already in progress. Adverse selection risk: entering at peak of initial move.
8. **Hold horizon adverse selection** — On 30–60min holds, a second information event can occur mid-position. No exit trigger beyond |IR_clean| < 0.30 collapse — no news-event cancel-on-move implemented at intermediate or sophisticated tier.

### Implementation Gaps (7, inheriting 6 from intermediate + 1 new)

1. **Parent-order ID tracking** — CLOB WebSocket must track `order_id`, `resting_time_s = (now - created_at)`, `modification_count`; filter: `resting ≥ 5s AND modification_count ≤ 2`; aggregate to `V_bid_parent` and `V_ask_parent`. This replaces the 5s aggregate resting proxy. Critical: requires persistent order-state dict, not just current snapshot. (**BLOCKING** — without this, we have intermediate not sophisticated)
2. **λ_proxy computation** — `λ_proxy = price_impact_per_dollar = (price_after_last_$1k_trade - price_before) / 1000`. Pre-compute from recent trade history. Threshold: < 0.05 = mature (3 snapshots); ≥ 0.05 = thin (5 snapshots). Alternative proxy: `1 / min(depth_yes, depth_no)` normalized to depth range.
3. **Liquidity-tiered threshold** ✓ at intermediate — upgrade threshold: IR_clean > 0.70 (was 0.65) for mid-liquidity
4. **Market.category field** — fetch from Gamma API metadata on market init
5. **Category exclusion gate** ✓ at intermediate — sports/crypto excluded
6. **Category-specific hold horizon** ✓ at intermediate — 30–60min (geopolitics); 15–30min (politics)
7. **News-event cancel-on-move** — NEW sophisticated requirement: if price moves > 3% within 60s of entry signal, cancel position regardless of IR state (adverse selection guard)

### Evidence

- **Source:** paper + practitioner analysis (no own-data)
- **Certainty:** hypothesis (58% WR is single-source; cross-market IR threshold corroborated; latency-rank model is well-established in equity LOBs; prediction market application is extrapolated)
- **Scope:** geopolitics and politics/finance binary markets on Polymarket, $2k–$50k liquidity
- **Falsifiability:** testable — own-data 30-trade minimum for anti-prim A; category wash monitoring for anti-prim B
- **Limitations:** 8 documented failure modes above

### Anti-Prim Escape Hatches

**(A) Latency saturation**: own-data WR < 52% over 30 geopolitics trades with parent-order filtration and 3-snapshot persistence → co-located bots have consumed all persistent OBI signal at 10s latency. Mark anti-prim. Do not re-refine — this is a structural latency-rank problem, not a parameter problem.

**(B) Category wash contamination**: if Columbia or Paradigm update shows geopolitics wash rate ≥ 40% (converging to sports) → even parent-order filtration insufficient. Mark anti-prim for geopolitics category. Reassess politics/finance separately.

**(C) Platform-level taker delay removal**: Polymarket removed taker delay in Feb 2026 for crypto binary markets (Finance Magnates). If extended to geopolitics/politics categories → professional OBI bots arrive in force at <10ms; our latency rank drops to terminal. Mark anti-prim for all categories.

Any own-data outcome is load-bearing:
- WR ≥ 65% over 30 trades → validates signal, persistent-OBI targeting works; consider live deployment
- WR 58–64% → viable, deploy with minimum Kelly (α=0.10 floor)
- WR 52–58% → marginal; reduce to geopolitics-only, extend persistence to 5 snapshots
- WR < 52% → anti-prim (A)

### Sources (8)

- [arxiv 2507.22712 — Order-Flow Filtration and Directional Association with Short-Horizon Returns](https://arxiv.org/abs/2507.22712) — parent-order vs aggregate filtration, "systematically stronger" directional association from parent-order filtering
- [arxiv 2006.08682 — The Importance of Low Latency to Order Book Imbalance Trading Strategies (Byrd et al.)](https://arxiv.org/abs/2006.08682) — latency RANK (not absolute magnitude) drives OBI profit allocation; lowest-rank agents retain zero profit at limit
- [arxiv 2603.03152 — Political Shocks and Price Discovery in Prediction Markets](https://arxiv.org/abs/2603.03152) — OBI R²=0.65, VR(6)=1.84 persistent drift at political shocks (validates minutes-scale hold in prediction markets)
- [Columbia SSRN 5714122 — Network-Based Detection of Wash Trading (Sirolly et al., Nov 2025)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5714122) — sports 45% wash, elections/politics ~17%, total 25%
- [Paradigm — Polymarket Volume Is Being Double-Counted (Dec 2025)](https://www.paradigm.xyz/2025/12/polymarket-volume-is-being-double-counted) — systematic volume inflation; wash % estimates understated
- [arxiv 2603.03136 — The Anatomy of Polymarket: Evidence from the 2024 Presidential Election](https://arxiv.org/abs/2603.03136) — Kyle λ maturation gate (λ drops 50×; immature market single-agent distortion)
- [Navnoor Bawa — The Mathematical Execution Behind Prediction Market Alpha (Substack, Dec 2025)](https://navnoorbawa.substack.com/p/the-mathematical-execution-behind) — 58% WR claim at IR > 0.65 mid-liquidity (single source — hypothesis)
- [QuantVPS — How Latency Impacts Polymarket Bot Performance (2026)](https://www.quantvps.com/blog/how-latency-impacts-polymarket-trading-performance) — co-located bots 1–30ms; 75% orders match within ~1 hour; 50–100ms delay flips winning to losing trade
