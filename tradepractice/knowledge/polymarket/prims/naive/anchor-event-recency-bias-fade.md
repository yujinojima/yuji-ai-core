---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T08:35:25+10:00
cycle: 75
---

---

**Cycle 75 — RESEARCH — Complete**

---

## Prim: anchor-event-recency-bias-fade
**Level:** naive | **Project:** polymarket | **Cycle:** 75 | **Class:** 16th

---

### What was created

A new signal class not represented in any of the 15 existing sophisticated prims: **cross-event availability bias fade**.

**Rule (naive):**
After a surprising major event resolves in category C (GDELT articles > 1,000/48h; resolved against prior PM consensus ≥ 55%), similar-category markets reprice upward within 7 days. The upward reprice is a cognitive artefact — not new information. **BUY NO** on target markets (YES ∈ [0.15, 0.55], entity_sim < 0.70 to anchor, resolution > 14 days). Exit at 14-day max or when GDELT anchor velocity drops below 0.5× peak. Kelly α = 0.10 uncalibrated floor.

**Why this is the right cycle 75 call:**

All 15 polymarket prims were already sophisticated. The conductor asked for "new angles." The five signal axes already covered are: microstructure (CLOB arb/MM/OBI), information quality (superforecasters/LLM/news velocity), cross-venue arb (Kalshi/financial instruments), static behavioral biases (FLB/time decay), and correlated contracts. This is the first prim in a **sixth axis: dynamic cross-event behavioral triggers**.

**Academic grounding:**
1. Tversky & Kahneman (1974 Science) — availability heuristic; judged probability inflated by ease of recall
2. Kahneman & Tversky (1979 Econometrica) — Prospect Theory probability weighting; recent experience over-sampled
3. Barber & Odean (2008 RFS) — attention-driven retail buying; reversion documented after attention spikes
4. Greenwood & Shleifer (2014 RFS) — extrapolation of recent dramatic events → systematic overestimation

**Primary challenge identified (Limitation #1):** The information vs bias confound. An anchor earthquake may legitimately update seismological base rates. The path to intermediate requires finding historical cases where anchor-triggered YES spikes subsequently resolved NO — confirming the price spike was bias, not information. If < 50% of historical cases resolve NO, this prim becomes an anti-prim.

**Shared infrastructure:** Anchor event detection (GDELT article count by entity) reuses the same pipeline as `news-velocity-informed-directional`. Joint development reduces blocker cost.

**Next cycle:** Intermediate elevation — resolve information vs bias confound via historical PM resolution database scan (GDELT archive 2022–2026 + Polymarket resolution API).
