---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T00:00:00+10:00
cycle: 54
---

---

## Prim: resolution-confirmation-arbitrage
**Level:** intermediate
**Project:** polymarket
**Class:** 12th polymarket prim — post-confirmation oracle convergence, intermediate elevation

**Supersedes:** `knowledge/polymarket/prims/naive/resolution-confirmation-arbitrage.md`

---

### Three Upgrades from Naive

1. **Two-mode entry timing** — naive used a single undifferentiated 0–60 min window and a single $0.90 price gate. Intermediate splits into Mode A (second-wave information-processing lag, T+5–60 min, price < $0.88) and Mode B (oracle mechanics window, T+60 min to dispute window end, price < $0.94). Price gates and dispute risk thresholds differ between modes because the competitive landscape and residual edge sources differ.

2. **Oracle dispute probability model** — naive used a binary no_active_uma_dispute flag only. Intermediate adds a pre-entry dispute risk score by event category using empirically grounded base rates, reflecting that structural ambiguity varies systematically across event types. Crypto (6%) and sports (8%) are excluded entirely; named political events are Mode A-only; major elections have the lowest base rate (0.5%).

3. **Fee-adjusted net return floor** — naive checked price < $0.90 without verifying the net return exceeded the taker fee. Intermediate uses the exact Polymarket fee formula `fee = fee_rate × p × (1−p)` to enforce a minimum net return floor per mode, ensuring each entry has a positive expected return after fees.

---

### Rules

**Mode A — Second-Wave (T+5 to T+60 min post wire confirmation)**

```
wire_confirms_outcome(market_id) == True
AND confirmed_side_price < 0.88
AND T+5 to T+60 min since wire confirmation
AND no_active_uma_dispute(market_id)
AND semantic_class(market_id) == "W"
AND dispute_risk_score(market_id) < 0.03
AND net_return(confirmed_side_price, category) >= 0.05
→ BUY confirmed side. α=0.10 Kelly.
```

**Mode B — Oracle Window (T+60 min to dispute window end)**

```
wire_confirms_outcome(market_id) == True
AND confirmed_side_price < 0.94
AND oracle_dispute_window_active(market_id)
AND no_active_uma_dispute(market_id)
AND semantic_class(market_id) == "W"
AND dispute_risk_score(market_id) < 0.02
AND net_return(confirmed_side_price, category) >= 0.03
→ BUY confirmed side. α=0.10 Kelly.
```

**Skip if:** entry price ≥ $0.94 (Mode B) or ≥ $0.88 (Mode A); any active UMA dispute at entry; semantic_class ≠ "W"; dispute_risk_score exceeds mode threshold; net_return < floor; crypto or sports category; neg_risk multi-market bundle.

---

### Mechanism

**Why prices have not converged at T+5 min (Mode A window):**

Tier 1 bots (sub-100ms) consume the largest gaps immediately after wire confirmation. But large-gap closures (price $0.50 → $0.88) require significant capital, and the bot population is bandwidth-limited — they execute best-priced opportunities first. By T+5 min, the price typically sits in the $0.88–$0.93 range: too small for Tier 1 economics, accessible to semi-automated second-wave actors with direct wire feed access.

**Why prices have not converged at T+60 min (Mode B window):**

After the first-mover and second-wave population exhausts their position limits, the market enters the oracle window phase. Rational holders in the $0.93–$0.97 range face a choice: sell into thin liquidity, or hold to oracle settlement at $1.00. Many choose to hold, creating persistent ask-side thinness. This is a structural feature of the UMA challenge window — convergence is guaranteed, but timing is the 24–48h oracle delay, not trader urgency.

---

### Tier Competition Model

| Tier | Actor | Window | Typical price range |
|------|-------|--------|---------------------|
| 1 | Sub-100ms bots with direct wire | T+0 to T+5 min | $0.50 → $0.88 |
| 2 | Semi-automated (Mode A) | T+5 to T+60 min | $0.88 → $0.93 |
| 3 | Oracle-window aware (Mode B) | T+60 min to oracle close | $0.93 → $0.97 |

Tier 1 bots are not a target: their advantage is sub-second latency and wire-feed colocation. Tier 2 is the primary target: human-speed wire monitoring with rapid execution. Tier 3 is the secondary target: capital still available after Mode A fill, or Mode A trigger did not fire (price already above $0.88 at T+5 min).

---

### Semantic Risk Classification (Single-Venue)

Adapted from cross-venue-semantic-arb sophisticated (Type A/B/C/D/E) for single-venue resolution confirmation:

| Class | Description | Resolution confirmation certainty | Viable? |
|-------|-------------|----------------------------------|---------|
| W | Unambiguous binary: wire report maps directly to PM resolution criteria with no scope conditions | Near-certain (Type W) | YES — both modes |
| X | Outcome-conditional: wire confirms an event but PM resolution criteria require a further condition (e.g. "effective date" or "signed into law") | Depends on secondary condition; wire confirmation ≠ oracle confirmation | NO — skip |
| Y | Oracle-dependent scope: resolution relies on UMA oracle interpretation of scope or definitions, not factual binary outcome | Dispute probability elevated; oracle may resolve opposite to wire report | NO — skip |

**All entries require semantic_class = "W" via `src/classifiers/semantic_risk.py`.** Types X and Y are primary loss modes: a wire confirmation of an election result does not guarantee PM resolves YES if the contract uses specific certification or electoral vote language that the reported outcome does not directly address.

---

### Oracle Dispute Probability Model

```python
dispute_risk_score(market_id) = base_rate[event_class] * complexity_multiplier[semantic_class]
```

**Base rates by event class:**

| Event class | Base rate | Mode A viable (< 0.03) | Mode B viable (< 0.02) |
|-------------|-----------|------------------------|------------------------|
| Major elections (AP/Reuters race call) | 0.005 | Yes | Yes |
| Legislative votes (passage/rejection) | 0.010–0.012 | Yes | Yes |
| Named political events (arrest/resignation) | 0.020–0.030 | Yes (≤ 0.030) | No |
| Crypto on-chain events | 0.060 | SKIP | SKIP |
| Sports outcomes | 0.080 | SKIP | SKIP |

**Complexity multiplier:**

| Semantic class | Multiplier |
|----------------|------------|
| W | 1.0× |
| X | 3.0× (excluded by semantic filter before this step) |
| Y | 5.0× (excluded by semantic filter before this step) |

**Rationale for base rates:** Major elections use structured race-call protocols (AP and Reuters have explicit "called" designations) that map cleanly to PM binary criteria; dispute rate is near-zero in practice. Legislative votes require only official vote count, which is unambiguous. Named events (arrests, resignations) have higher ambiguity because PM contracts often include scope qualifiers (e.g. "formally charged" vs "arrested"). Crypto events have elevated dispute rates due to block reorganisation ambiguity and contract scope disputes. Sports have an official-standings / appeals process that introduces post-confirmation uncertainty.

---

### Fee-Adjusted Net Return Formula

```python
net_return(p, category) = (1 - p) - fee_rate[category] * p * (1 - p)
```

| category | fee_rate |
|----------|----------|
| geopolitics | 0.00 |
| politics | 0.04 |
| sports | 0.07 (excluded) |
| crypto | 0.072 (excluded) |

**Net return table (reference):**

| Entry price (p) | Geopolitics (0%) | Politics (4%) |
|-----------------|-----------------|---------------|
| 0.85 | 15.0% | 14.4% |
| 0.88 | 12.0% | 11.6% |
| 0.90 | 10.0% | 9.6% |
| 0.92 | 8.0% | 7.7% |
| 0.94 | 6.0% | 5.8% |
| 0.96 | 4.0% | 3.8% |

**Key property:** Polymarket's `p×(1−p)` fee structure makes fees approach zero as price approaches 1.00. At p=0.94, geopolitics is fee-free; politics fee is only 0.2pp (0.04 × 0.94 × 0.06 = 0.22%). This means the fee concern is concentrated in the Mode A window ($0.85–$0.88) for politics, not in Mode B.

**Mode A floor: 5% net return** — enforces a minimum economic reason to enter (not just theoretically positive). At p=0.88, politics: 11.6% >> 5% floor. At p=0.88, geopolitics: 12.0% >> 5% floor. Mode A entries with price between $0.88–$0.90 are acceptable only if net_return ≥ 5% confirmed by formula.

**Mode B floor: 3% net return** — lower floor reflects higher certainty (oracle window active, no dispute, Tier 3 entry). At p=0.94, politics: 5.8% > 3% floor.

---

### Limitations

1. **Semantic classifier dependency:** All edge depends on semantic_risk.py correctly identifying Type W contracts. False negatives (X/Y misclassified as W) convert near-certain entries to directional bets. Classifier confidence ≥ 0.90 required; 10% false-negative rate eliminates the edge entirely.

2. **Dispute base rates are estimated, not own-data:** Category base rates are derived from UMA oracle documentation and PM community dispute history, not systematic own-data collection. A single cluster of disputes in one category (e.g. 3 disputes in elections during a contested cycle) would substantially change the base rate.

3. **Mode A window compressing:** Tier 1 bot sophistication is increasing. If Tier 1 bots expand their capital deployment to cover $0.88–$0.93 ranges, the Mode A window will shrink or disappear. Anti-prim (C) monitors this.

4. **Oracle window duration varies:** Some PM markets use shorter challenge windows (24h vs 48h). The T+60 min → dispute window end calculation must use the actual window for each market, not a default.

5. **Post-entry dispute risk not zero:** Entry with no active dispute does not prevent a dispute being filed after entry. Real-time dispute monitoring via `src/utils/uma_oracle_monitor.py` is required post-entry.

6. **Single-leg only:** neg_risk multi-market bundles settle differently (all legs must resolve for payout). A wire confirmation of one leg's outcome does not guarantee oracle settlement of the bundle. neg_risk=False gate is mandatory.

---

### Anti-Prim Escape Hatches

**(A) Semantic classifier leak:** WR < 85% over first 20 Type W trades → semantic_risk.py is leaking Type X/Y contracts into the Type W category → halt all entries, audit classifier on failed trades, recalibrate confidence threshold.

**(B) Category dispute cluster:** Dispute rate > 10% in any category over 20 trades → that category's resolution criteria are structurally more ambiguous than base rates predict → exclude category from both modes.

**(C) Mode A window saturation:** Median confirmed-side price at T+5 min > $0.95 over 20 consecutive events → Tier 2 competition has compressed the window before Mode A can execute → Mode B only; reassess Mode A architecture (requires wire-feed colocation to compete at T+0–T+5).

---

### Implementation Gaps

1. `src/strategies/resolution_arb.py` — two-mode logic (Mode A: T+5–60 min gate, price < $0.88, dispute_risk < 0.03, net_return ≥ 0.05; Mode B: oracle window active gate, price < $0.94, dispute_risk < 0.02, net_return ≥ 0.03); Kelly sizing via `src/risk/kelly.py` α=0.10; hold-to-settlement logic with real-time dispute monitor exit [BLOCKING: requires items 2–5]
2. `src/utils/uma_oracle_monitor.py` — real-time UMA dispute status via GraphQL API or event websocket; post-entry dispute detection [BLOCKING pre-deployment]
3. `src/feeds/news_wire_monitor.py` — Reuters/AP/Bloomberg structured wire feed integration; machine-readable event confirmation extractor; T+0 timestamp for Mode A/B window calculation
4. `src/classifiers/wire_to_contract_matcher.py` — map wire confirmation to PM question resolution criteria; confidence ≥ 0.90 [BLOCKING — primary loss-mode risk]; reuse `src/classifiers/semantic_risk.py` (Type W/X/Y gate)
5. `src/risk/dispute_risk_scorer.py` — dispute_risk_score(market_id) using category base rates × complexity multiplier; event_class detection from market metadata
6. Reuse `src/risk/kelly.py` (fractional-kelly-sizing sophisticated — α=0.10 floor); reuse `src/classifiers/semantic_risk.py` (Type W/X/Y classifier)

---

### Conditions Log Entry

- **Works when:** Wire service (Reuters/AP/Bloomberg) confirms binary outcome AND semantic_class = "W" AND no active UMA dispute pre-entry; **Mode A**: confirmed-side price < $0.88, T+5–60 min post-wire, dispute_risk < 0.03, net_return ≥ 5% (geopolitics or politics only); **Mode B**: confirmed-side price < $0.94, oracle dispute window active, T+60 min+ post-wire, dispute_risk < 0.02, net_return ≥ 3%; contract is single-leg binary (neg_risk=False); liquidity ≥ $5k; bid-ask ≤ $0.06
- **Fails when:** semantic_class = "X" or "Y" (wire confirmation ≠ oracle resolution criteria); UMA dispute active at entry or filed post-entry; crypto or sports category (dispute base rate 6–8%, above both mode thresholds); neg_risk multi-market bundle; price above mode threshold at time of entry (Mode A: ≥ $0.88; Mode B: ≥ $0.94); net_return below mode floor after fee adjustment
- **Best pair(s):** Geopolitics (0% fee, lowest dispute base rate class — major elections 0.5%); Politics elections (AP/Reuters race call); Politics appointments and legislative votes (1.0–1.2% dispute base rate)
- **Best timeframe:** Mode A: T+5–60 min post-wire (second-wave information-processing window, Tier 2 actors); Mode B: T+60 min to oracle close (oracle mechanics window, Tier 3); hold to oracle settlement ($1.00); exit trigger: oracle settlement OR UMA dispute filed post-entry (switch to position management)
- **Key numbers:** Mode A price gate $0.88; Mode B price gate $0.94; Mode A dispute threshold 3%; Mode B dispute threshold 2%; Mode A net return floor 5%; Mode B net return floor 3%; fee formula: fee_rate × p × (1−p) (approaches 0 near $1.00); major election base rate 0.5%; legislative vote 1.0–1.2%; named political events 2.0–3.0% (Mode A only); crypto/sports excluded; α=0.10 Kelly; BLOCKING: wire-to-contract semantic matcher confidence ≥ 0.90
- **Evidence:** Rodríguez et al. (2025, arxiv 2508.03474 — 75% of PM arb executes within 1h post-resolution, $40M extracted; tier competition model); Della Vedova (2025, SSRN 6191618 — 2.52c/contract bot advantage, T+0 Tier 1 window characterisation); UMA Protocol (2024 oracle docs — 24–48h optimistic oracle challenge period); Gürkaynak, Sack & Swanson (2005, AER — measurable implementation delay, second-wave mechanism); financial-market-lead-lag sophisticated (Mode A/B architecture precedent); cross-venue-semantic-arb sophisticated (Type W/X/Y semantic classification precedent); no own-data trades
- **Last validated:** cycle 54 intermediate elevation; three upgrades over naive: (1) two-mode entry structure (Mode A T+5–60 min, Mode B oracle window, separate price/dispute/return thresholds); (2) oracle dispute probability model (category base rates + complexity multiplier; crypto/sports excluded); (3) fee-adjusted net return floor (exact `p×(1−p)` formula; floors 5%/3% per mode); tier competition model formalised; semantic W/X/Y classification explicit; 3 anti-prim escape hatches added; BLOCKING: wire-to-contract semantic matcher + UMA oracle monitor
