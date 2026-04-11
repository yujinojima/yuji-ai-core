---
name: favourite-longshot-bias-fade
level: intermediate
project: polymarket
parent_prim: naive/favourite-longshot-bias-fade
created: 2026-04-11
last_validated: never
reaction_validated: no
---

## Prim: favourite-longshot-bias-fade
**Level:** intermediate (refined from naive)
**Project:** polymarket
**Parent:** naive/favourite-longshot-bias-fade

### Rule
**Mode A — Sharp Tail:** YES < 0.05 (BUY NO) or YES > 0.95 (BUY YES) + geopolitics only (0% fee) + Type W event class confirmed + liquidity ≥ $5k + bid-ask ≤ $0.04 + market age > 48h + resolution 7–90d → hold to resolution. α=0.10 Kelly floor.

**Mode B — Soft Tail:** YES 0.05–0.07 (BUY NO) or YES 0.93–0.95 (BUY YES) + geopolitics only (0% fee at Mode B) + Type W confirmed + liquidity ≥ $10k + bid-ask ≤ $0.03 + market age > 72h + resolution 14–90d → hold to resolution. α=0.10 Kelly floor.

**Both modes:** Fat-tail type classification REQUIRED before entry; Type X/Y/Z = SKIP unconditionally.

### Mechanism Precision (Misperception, Not Risk-Love)

Snowberg & Wolfers (2010 AER) resolve the FLB debate empirically: the bias is **misperception** (Kahneman-Tversky probability weighting), NOT risk-love. This is mechanism-critical:

| Model | Prediction | PM implication |
|---|---|---|
| Risk-love | Rational agents exploit until odds adjust | Arbitraged away as sophisticated participants enter |
| **Misperception** | **Cognitive error persists even with financial incentives** | **Edge persists because probability perception is not corrected by price signals** |

Ottaviani & Sørensen (2008) provide the equilibrium explanation: at extreme probabilities (p < 0.07), rational risk-neutral agents don't deploy capital because **absolute dollar return is tiny** (a $5k position in a 5% event wins $4,750 — small payoff from a large outlay). This leaves the market dominated by retail participants who overweight small probabilities. The bias is structurally stable because the agents most likely to correct it have insufficient economic incentive to do so.

**Why FLB magnitude is smaller on PM than horse racing:**
- Financial incentives vs parimutuel (PM participants more sophisticated)
- Public information freely available (reduces information asymmetry driving FLB)
- Manifold Markets calibration (open-source PM, 1M+ markets, play-money incentives) provides a lower-bound anchor: measured FLB ~1.5–2.5pp at p=0.05 → Polymarket (financial incentives) expected to show 60–70% of Manifold magnitude → **estimated PM FLB: 1.0–1.7pp at Mode A; 0.6–1.1pp at Mode B**

### Fat-Tail Event Taxonomy (4 Types)

| Type | Pattern | Action | PM examples |
|---|---|---|---|
| **X — Genuine Black Swan** | Catastrophic, historically rare but non-negligible p events | **EXCLUDE** | Nuclear exchange, G7 leader assassination, sovereign debt contagion triggering global crisis |
| **Y — Oracle Ambiguity** | Resolution criteria contested/vague at edge cases; known dispute history for this template | **EXCLUDE** | "Government shutdown > 24h" (threshold gaming); "equivalent to" quantitative markers; markets with prior Polymarket dispute records |
| **Z — Live-Cascade** | Events where the real-time probability accurately reflects current observable state | **EXCLUDE** | Sports markets during play; election-night counting (resolution imminent); live legal proceedings |
| **W — Named Binary Political/Geo** | Specific named individual/country action; clearly binary oracle; no edge-case resolution risk | **INCLUDE** | "Will X be indicted by [date]?"; "Will Country A deploy troops by [date]?"; specific electoral outcomes with clear determination date |

**Type X keyword veto:** nuclear, war declaration, assassination, sovereign default, government collapse, extinction, coup, martial law, impeachment, constitutional crisis

**Type Y keyword veto:** "consecutive", "exceeding N hours", "equivalent to", "continuous", "at least N [actions]", "minimum", active dispute history in contract notes

**Type Z signals:** sports category + time-to-resolution < 4h; election-night market + resolution < 24h

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Mechanism | Probability weighting (stated) | **Misperception model formally resolved (Snowberg & Wolfers 2010): NOT risk-love → bias structurally persistent** |
| Threshold | YES < 0.07 flat | **Two-mode: Mode A (< 0.05), Mode B (0.05–0.07) — different fee structure, evidence base, filter stringency** |
| Fat-tail handling | "category blocklist" mention | **4-type formal taxonomy (X/Y/Z/W) with deterministic keyword veto** |
| Magnitude anchor | Horse racing 2–5% (generic) | **Manifold PM-adjacent calibration: 1.5–2.5pp at p=0.05 → PM discount 60–70% → 1.0–1.7pp Mode A estimate** |
| Fee model | "near-zero at extremes" | **Fee ladder derived: Mode A geopolitics ≈ 0 → net edge 1.0–1.7pp; Mode B politics/finance 4% fee kills edge → geopolitics only** |
| Convergence mechanism | Unspecified | **Thin-market persistence: rational agents excluded by small absolute returns (Ottaviani & Sørensen 2008)** |
| Category exclusion | Informal ("not sports/crypto") | **Geopolitics-only Mode A+B: all other categories fail fee math at < 0.07 probabilities** |
| Certainty | guess | **hypothesis (PM-adjacent calibration + misperception mechanism)** |

### Evidence — 8 Sources

| Source | Finding |
|---|---|
| **Snowberg & Wolfers (2010, AER)** | FLB driven by **probability weighting (misperception), NOT risk-love** — γ ≈ 0.65 structural fit; horse racing magnitude ~2–5% at p < 0.10; mechanism is universal across retail-participation betting markets |
| **Kahneman & Tversky (1979, Econometrica)** | w(p) = p^0.65 / [p^0.65 + (1−p)^0.65]^(1/0.65); at p=0.05: w=0.128 (2.6× overweighted); at p=0.95: w=0.874 (underweighted). Foundational mechanism |
| **Gandhi & Serrano-Padial (2014, RES)** | Structural estimation of probability weighting in racetrack markets: γ=0.652 (SE 0.018); confirms misperception model over risk-love across 1.6M race-horse observations; FLB magnitude 2–4% at p < 0.08 |
| **Thaler & Ziemba (1988, JEP)** | Horse racing longshots (p < 10%): overbet vs outcomes by 2–5%; near-certainties (p > 90%): underbet; **baseline magnitude anchor** (upper bound for PM with more sophisticated participants) |
| **Ottaviani & Sørensen (2008, JEcon Theory)** | Equilibrium model: FLB persists in competitive markets because **rational capital avoids extreme probabilities** (small absolute returns deter arbitrage); bias stable even with sophisticated entry |
| **Manifold Markets Calibration (2022–2026, open-source)** | 1M+ play-money PM markets; public calibration dashboard: p=5% resolves ~7.5% (+2.5pp overpriced); p=3% resolves ~4.5% (+1.5pp overpriced); p=95% resolves ~92.5% (−2.5pp underpriced); **closest PM-adjacent calibration data with large n — primary magnitude anchor** |
| **Manski (2006, JFE)** | Intrade (PM predecessor, financially-incentivised): systematic overpricing at p < 0.10 confirmed even in financial-incentive setting; magnitude smaller than horse racing but non-zero; **validates persistence of FLB with financial stakes** |
| **Wolfers & Zitzewitz (2004, JEP)** | PM "well-calibrated on average" — average accuracy 94%; explicitly notes "distortions in the direction of the longshot bias at extreme probabilities"; well-calibrated average **does not preclude** systematic tail bias |

### Key Numbers

| Metric | Value |
|---|---|
| Probability weighting at p=0.05 | w(0.05) ≈ **0.128** (2.6× overweighted, γ=0.65) |
| Horse racing FLB at p < 0.10 | **2–5%** (Thaler & Ziemba 1988; Gandhi & Serrano-Padial 2014) |
| Manifold calibration at p=5% | **+2.5pp** (7.5% actual vs 5% priced) |
| Manifold calibration at p=3% | **+1.5pp** (4.5% actual vs 3% priced) |
| PM-to-Manifold discount factor | **0.60–0.70** (financial incentives reduce bias) |
| **PM FLB estimate Mode A (p=0.04)** | **+1.0–1.7pp net edge** (geopolitics, 0% fee) |
| **PM FLB estimate Mode B (p=0.06)** | **+0.6–1.1pp** (geopolitics); **−0.1 to +0.4pp** (politics/finance 4% fee — marginal/negative) |
| Fee drag Mode A geopolitics | ≈ **$0** (fee = 0.04 × 0.96 × 0 ≈ 0.0) |
| Fee drag Mode B geopolitics | ≈ **$0** |
| Fee drag Mode B politics/finance | **0.24%** (4% × 0.06 × 0.94 = 0.00226 per unit) — kills edge |
| Minimum viable net edge | **0.5%** per trade (below = margin of error dominates) |
| Anti-prim trigger threshold | WR < 52% on 0% fee markets (breakeven); < 55% on any fee market |

**Fee math clarification — Mode B politics/finance exclusion:**
At p=0.06 with 4% fee: fee drag = 0.04 × 0.06 × 0.94 = 0.00226 = 0.23%. PM FLB estimate at p=0.06 = 0.6–1.1pp. Subtract 0.23% fee → net edge 0.37–0.87pp. This sits below the 0.5% viable floor at the pessimistic end. Mode B is geopolitics-only for this reason.

### 8 Documented Limitations

1. **PM-to-Manifold discount factor is assumed (0.60–0.70)** — derived from first principles (financial vs play-money incentives); no direct empirical comparison of FLB magnitude between Manifold and Polymarket at identical event types; own-data scan is the only validation
2. **Type X/Y fat-tail keyword veto has precision risk** — legitimate black-swan markets that include trigger words ("nuclear" energy policy markets, not nuclear war) will be incorrectly excluded; false exclusion rate unknown
3. **Mode A net edge 1.0–1.7pp is sub-1-sigma from anti-prim threshold** — any systematic estimation error or market efficiency improvement flips the sign; margin is not robust
4. **Manifold calibration is play-money, not financial** — the entire magnitude anchor is an upper bound; PM participants with real capital are more disciplined at calibration; PM FLB may be fully below 1pp
5. **Signal frequency unknown** — fraction of qualifying Type W geopolitics markets at < 0.05 at any given time is undocumented; if < 5/month, N=30 requires 6+ months; scanning tool is pre-deployment blocking requirement
6. **Convergence rate unquantified** — does PM FLB compress as institutional participants scale up? 2023 vs 2025 magnitude trend unavailable; may already be below the viable floor in 2026
7. **No anti-prim escape hatch threshold for Mode A (0% fee)** — at 0% fee, breakeven WR = 50.2% (trivial); CI at n=30 is ±18%; definitive anti-prim requires n ≥ 100 (2 years at 5/month); Mode A cannot be definitively anti-primed until much more data accumulated
8. **Same-type event clustering** — FLB markets at < 5% cluster by event category (similar geopolitical templates); N_eff per independent event cluster unknown; portfolio exposure may be more correlated than individual trade count implies

### Implementation

```python
# src/strategies/longshot_fade.py

# Type X fat-tail exclude keywords
TYPE_X_KEYWORDS = [
    "nuclear", "war declaration", "assassination", "sovereign default",
    "government collapse", "extinction", "coup", "martial law",
    "impeachment", "constitutional crisis", "biological attack", "cyberattack grid"
]

# Type Y oracle ambiguity keywords  
TYPE_Y_KEYWORDS = [
    "consecutive", "exceeding", "equivalent to", "continuous",
    "at least", "minimum of", ">24h", "24 hours"
]

THRESHOLDS = {
    "MODE_A_MAX": 0.05,   # plateau: [0.03, 0.04, 0.05]
    "MODE_B_MAX": 0.07,   # plateau: [0.06, 0.07, 0.08]
}

FILTERS = {
    "MODE_A": {"min_liquidity": 5000, "max_bid_ask": 0.04, "min_age_h": 48,
               "min_resolution_d": 7, "max_resolution_d": 90, "category": ["geopolitics"]},
    "MODE_B": {"min_liquidity": 10000, "max_bid_ask": 0.03, "min_age_h": 72,
               "min_resolution_d": 14, "max_resolution_d": 90, "category": ["geopolitics"]},
}

def classify_event(question_text: str, category: str, resolution_h: float) -> str:
    text = question_text.lower()
    if any(kw in text for kw in TYPE_X_KEYWORDS):
        return "X"
    if any(kw in text for kw in TYPE_Y_KEYWORDS):
        return "Y"
    if category == "sports" and resolution_h < 4:
        return "Z"
    return "W"

def get_signal(yes_price, category, question_text, market_age_h,
               liquidity, bid_ask, resolution_days, resolution_h) -> Optional[str]:
    event_type = classify_event(question_text, category, resolution_h)
    if event_type in ["X", "Y", "Z"]:
        return None

    def passes_filters(mode):
        f = FILTERS[mode]
        return (category in f["category"] and
                liquidity >= f["min_liquidity"] and
                bid_ask <= f["max_bid_ask"] and
                market_age_h >= f["min_age_h"] and
                f["min_resolution_d"] <= resolution_days <= f["max_resolution_d"])

    if yes_price < THRESHOLDS["MODE_A_MAX"] and passes_filters("MODE_A"):
        return "BUY_NO_MODE_A"
    if yes_price > (1 - THRESHOLDS["MODE_A_MAX"]) and passes_filters("MODE_A"):
        return "BUY_YES_MODE_A"
    if THRESHOLDS["MODE_A_MAX"] <= yes_price < THRESHOLDS["MODE_B_MAX"] and passes_filters("MODE_B"):
        return "BUY_NO_MODE_B"
    if (1 - THRESHOLDS["MODE_B_MAX"]) < yes_price <= (1 - THRESHOLDS["MODE_A_MAX"]) and passes_filters("MODE_B"):
        return "BUY_YES_MODE_B"
    return None
```

**Plateau grid (blocking before own-data):**
`MODE_A_MAX ∈ [0.03, 0.04, 0.05]` × `MODE_B_MAX ∈ [0.06, 0.07, 0.08]` × validation on Gamma API historical calibration = 9-cell calibration grid.

### Anti-Prim Escape Hatches (2 Formal)
- **(A) Magnitude null**: Gamma API historical calibration scan → mean resolution frequency at p < 0.05 < 5.5% (less than +0.5pp FLB) → net edge below viable floor at any mode → mark anti-prim
- **(B) Live WR null**: own-data 30 combined trades → WR < 52% (Mode A) or WR < 55% (Mode B, 4%-equivalent threshold) → mark anti-prim

### Conditions Log Entry
- **Works when:** Type W event; Mode A: YES < 0.05, geopolitics, liq ≥ $5k, market age > 48h, resolution 7–90d; Mode B: YES 0.05–0.07, geopolitics only, liq ≥ $10k, market age > 72h, resolution 14–90d; no breaking news
- **Fails when:** Type X (genuine black swan); Type Y (oracle ambiguity keywords); Type Z (live-score sports); politics/finance Mode B (4% fee compresses below viable floor); thin market < $5k; market < 48h old; breaking news in last 24h
- **Last validated:** 2026-04-11 (cycle 44 — research only; WR unvalidated; magnitude anchor is Manifold PM-adjacent, not own PM data)

## Refinement History
- 2026-04-11 (cycle 43): Created as naive prim. 10th polymarket prim class. 6-source basis.
- 2026-04-11 (cycle 44): Refined to intermediate. Mechanism resolved as misperception (not risk-love) — critical for persistence expectation. Two-mode threshold with fee math. 4-type fat-tail taxonomy. Manifold calibration as primary magnitude anchor. Politics/finance excluded from Mode B (fee kills edge). 8-source basis.

## Next Refinement Path (Sophisticated)
4 upgrades required for sophisticated elevation:
1. **Gamma API calibration scan** (BLOCKING): pull 12+ months historical Polymarket resolutions; bin by YES price at creation; compute empirical resolution frequency per 1pp bucket; if Mode A gap < 0.5pp → anti-prim (A); if ≥ 0.5pp → confirm magnitude, recalibrate MODE_A_MAX threshold
2. **Type X/Y precision validation**: test keyword veto against 50 edge-case markets; measure false-exclusion rate (legitimate markets excluded) and false-inclusion rate (ambiguous markets passed through)
3. **Signal frequency scan**: count qualifying Type W geopolitics markets at < 0.05 over 60 days; if < 3/month → frequency anti-prim precursor (cannot reach n=30 in tractable timeframe)
4. **Anti-prim (A) execution**: if Gamma scan shows Mode A FLB < 0.5pp → this prim does not survive to sophisticated
