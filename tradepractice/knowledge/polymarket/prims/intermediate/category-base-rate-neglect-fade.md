---
name: category-base-rate-neglect-fade
level: intermediate
project: polymarket
parent_prim: naive/category-base-rate-neglect-fade
created: 2026-04-12
last_validated: never
reaction_validated: no
status: SUPERSEDED by sophisticated (cycle 112)
---

## Prim: category-base-rate-neglect-fade
**Level:** intermediate (refined from naive)
**Project:** polymarket
**Parent:** naive/category-base-rate-neglect-fade

### Rule

**Mode A — Narrative-Salient Categories:** `category ∈ {elections_US, elections_foreign, geopolitical_conflict, judicial}` AND YES deviates ≥ 15 pp from cell base rate AND cell qualifies (≥ 30 resolved markets; ρ_window ≥ 0.80) AND GDELT velocity ≤ 4× baseline → BUY NO (YES > base_rate + 0.15) or BUY YES (YES < base_rate − 0.15). If GDELT velocity > 2× and ≤ 4× baseline → apply 0.5× position scalar (information-confound discount). Liquidity ≥ $5k; bid-ask ≤ $0.05; resolution 14–90 days; YES ∈ [0.20, 0.80]. α=0.10 Kelly floor. Exit: gap < 8 pp, resolution ≤ 5 days, or 60-day max hold.

**Mode B — Structural-Constraint Categories:** `category ∈ {legislation, executive_action, crypto_regulation}` AND YES deviates ≥ 12 pp from cell base rate AND cell qualifies (≥ 30 resolved markets; ρ_window ≥ 0.80) AND GDELT velocity ≤ 3× baseline → BUY NO (YES > base_rate + 0.12) or BUY YES (YES < base_rate − 0.12). If GDELT velocity > 1.5× and ≤ 3× baseline → apply 0.5× position scalar. Liquidity ≥ $5k; bid-ask ≤ $0.05; resolution 14–90 days; YES ∈ [0.20, 0.80]. α=0.10 Kelly floor. Same exit rules as Mode A.

**Both modes:** FLB exclusion zone applies — if YES < 0.10 or > 0.90, defer to FLB prim unconditionally (no base-rate signal). Cell-level IS backtest must have passed Mann-Whitney U p < 0.10 (or cell is treated as ineligible) before any live signal from that cell.

### Mechanism Precision

**Why Mode A and Mode B diverge on threshold:**

| Category group | Base-rate neglect mechanism | Information-updating risk | Threshold |
|---|---|---|---|
| Elections, geopolitics, judicial | Inside-view narrative maximally documented (Kahneman & Lovallo 1993: named candidate / vivid scenario dominates reference class reasoning). Tetlock (2005): hedgehog forecasters most biased on high-narrative political cases | High — genuine intelligence leaks, candidate withdrawals, court rulings frequently move markets legitimately | 15 pp (high bar: must overcome information noise) |
| Legislation, executive action, crypto regulation | Base rates more constrained by institutional arithmetic (vote counts, procedural requirements, agency dockets) — narrative bias still present but variance lower. Flyvbjerg (2006): structural constraints anchor base rates more stably in procedural domains | Moderate — information updating occurs but is rarer; most price deviations are narrative framing, not genuine news | 12 pp (lower bar: tighter base rates allow a smaller signal gap to be meaningful) |

**Why the GDELT confound gate is asymmetric between modes:**

Mode A operates in high-information-flow categories where breaking news is more frequent and more likely to represent genuine updating. A 2× velocity trigger is warranted before applying the discount. Mode B operates in categories where a 1.5× velocity already signals potential genuine information updating (procedural categories typically have lower news background rates — any elevation is more informative about genuine developments).

**Structural persistence mechanism (why edge survives at intermediate):**

At intermediate tier, the key question is whether base-rate neglect remains exploitable despite the presence of sophisticated PM participants. Two structural supports:

1. **Low-volume cell persistence** — for most non-election categories (legislation, judicial, geopolitics excluding US elections), PM market liquidity remains $5k–$50k range, dominated by retail. Institutional capital concentrates in high-liquidity political markets where edge may already be compressed. Mode A/B target the $5k–$50k range specifically.
2. **Category base-rate opacity** — unlike favourite-longshot bias (which is visible in the price itself), base-rate neglect requires knowing the empirical category resolution frequency, which no PM participant can easily compute without the database. The edge is protected by data infrastructure asymmetry, not just cognitive bias. A participant must independently scrape and classify 200+ resolved markets to detect the signal. Very few participants have done this.

### Category-Resolution Database Specification (Intermediate Infrastructure)

**Purpose:** Compute `base_rate[category][cell]` = empirical probability that a qualifying PM binary market resolves YES, grouped by NLP-classified category, estimated from all Polymarket resolved markets 2022–present.

**Step 1 — Gamma API scrape:**
```
GET https://gamma-api.polymarket.com/markets
  ?active=false&closed=true&limit=500&offset={n}
  → paginate until no more results
Fields required per market: id, question, description, category (native PM tag),
  endDate, resolutionTime, outcomePrices, volume, liquidity
Filter: volume > 0 AND resolutionTime IS NOT NULL (resolved, not cancelled)
Target: all resolved binary markets 2022–present; expected N ≈ 5,000–15,000
```

**Step 2 — NLP category tagger:**
- Input: market `question` + `description` text (concatenated)
- Classifier: `text-classification` model (e.g., fine-tuned distilBERT or zero-shot NLI on MNLI backbone)
- Output: one of 8 categories: `{elections_US, elections_foreign, executive_action, judicial, legislation, geopolitical_conflict, crypto_regulation, other}`
- Precision gate: validate on manual spot-check N=50 across all 8 categories → require precision ≥ 0.85 per category before using any cell. `other` category is never used for base-rate signal.
- Category definitions (examples for classifier fine-tuning):
  - `elections_US`: "Will [candidate] win the [US electoral office]?" — US federal/state elections
  - `elections_foreign`: "Will [non-US party/leader] win [non-US election]?"
  - `executive_action`: "Will [US/foreign executive] [sign/issue/veto/appoint] [X] by [date]?"
  - `judicial`: "Will [court] rule [for/against] in [case]? Will [X] be convicted/acquitted?"
  - `legislation`: "Will [Congress/Parliament/referendum] pass [legislation] by [date]?"
  - `geopolitical_conflict`: "Will [country A] [invade/sanction/withdraw from/attack] [country B] by [date]?"
  - `crypto_regulation`: "Will [SEC/CFTC/EU/Congress] [approve/ban/regulate] [crypto product] by [date]?"

**Step 3 — Resolution frequency aggregation:**
```python
# src/data/category_base_rates.py

def compute_base_rate(resolved_markets: list[dict], category: str,
                      window_months: int = 24) -> dict:
    """
    Compute empirical YES resolution frequency for a category cell.
    Returns: {'base_rate': float, 'n': int, 'window_start': date, 'eligible': bool}
    """
    cutoff = datetime.now() - timedelta(days=30 * window_months)
    cell = [m for m in resolved_markets
            if m['category'] == category
            and m['resolutionTime'] >= cutoff]
    n = len(cell)
    if n < 30:
        return {'base_rate': None, 'n': n, 'eligible': False,  # anti-prim A gate
                'reason': f'insufficient_sample: n={n} < 30'}
    yes_count = sum(1 for m in cell if m['resolved_yes'])
    return {'base_rate': yes_count / n, 'n': n,
            'window_start': cutoff, 'eligible': True}
```

**Step 4 — Minimum database threshold before any live use:**
- ≥ 8 qualifying cells (≥ 30 resolved markets each after tagger filtering)
- ≥ 3 of the 8 cells must have passed IS backtest (Mann-Whitney U p < 0.10)
- Database is treated as BLOCKING until these criteria are met

### Rolling Window Calibration Protocol

**Purpose:** Guard against structural regime change in PM participant composition (2021 crypto-native vs 2025+ retail/institutional mix). Base rates from stale participant cohorts produce spurious signals.

**Protocol:**
```python
def check_window_stability(resolved_markets, category, windows=(12, 24)):
    """
    Compare base rates across window lengths.
    If correlation < 0.80 across windows for a category → ineligible.
    """
    rates = {}
    for w in windows:
        result = compute_base_rate(resolved_markets, category, window_months=w)
        if not result['eligible']:
            return {'stable': False, 'reason': f'insufficient_n at {w}m window'}
        rates[w] = result['base_rate']
    
    # Point comparison (n=1 correlation proxy at intermediate tier)
    # At sophisticated tier: compute across sub-cells for true correlation
    delta = abs(rates[24] - rates[12])
    stable = delta < 0.08  # proxy for ρ >= 0.80 at intermediate (< 8pp drift)
    return {'stable': stable, 'rates': rates, 'delta': delta,
            'eligible': stable}
```

**Rationale for δ < 0.08 proxy:** At intermediate tier, we lack enough cells per category to compute a true Pearson correlation across cell pairs. The 8 pp drift threshold is derived from: if base_rate ≈ 0.50 (expected for most binary political markets), a ρ = 0.80 stability requirement approximately corresponds to a standard deviation of 0.10 across sub-cells; a single 12m vs 24m comparison within 8 pp of the overall rate implies stability sufficient for an intermediate gate. At sophisticated tier, replace with true cross-cell Pearson ρ ≥ 0.80.

**Annual recalibration:** run the stability check quarterly. Categories that were stable can become unstable after structural events (e.g., a new PM participant category entering the market). Mark unstable categories as ineligible immediately; they can re-enter after 6 months of new data.

### Information vs. Bias Gate (GDELT Confound Control)

**Purpose:** Distinguish between (a) base-rate neglect bias (narrative-anchored mispricing exploitable by fading) and (b) genuine information updating (the market is correct to deviate from base rate because new information justifies the case-specific assessment). This is the central identification challenge for this prim.

**GDELT velocity computation:**
```python
# GDELT free API — no key required
# https://api.gdeltproject.org/api/v2/doc/doc?query=...&mode=artlist&format=json

def get_gdelt_velocity(entity: str, lookback_hours: int = 24,
                       baseline_days: int = 30) -> dict:
    """
    entity: primary named entity extracted from market title (NER)
    Returns: {velocity_24h: int, baseline_daily: float, ratio: float}
    """
    # 24h count
    now = datetime.utcnow()
    window_start = now - timedelta(hours=lookback_hours)
    # GDELT date format: YYYYMMDDHHMMSS
    params_24h = {
        'query': entity,
        'mode': 'artlist',
        'startdatetime': window_start.strftime('%Y%m%d%H%M%S'),
        'enddatetime': now.strftime('%Y%m%d%H%M%S'),
        'maxrecords': 250,
        'format': 'json'
    }
    count_24h = len(fetch_gdelt(params_24h)['articles'])
    
    # 30-day baseline (daily average)
    baseline_start = now - timedelta(days=baseline_days)
    params_30d = {
        'query': entity,
        'mode': 'artlist',
        'startdatetime': baseline_start.strftime('%Y%m%d%H%M%S'),
        'enddatetime': now.strftime('%Y%m%d%H%M%S'),
        'maxrecords': 250,  # capped — use as proxy; at sophisticated tier, use artcount mode
        'format': 'json'
    }
    count_30d = len(fetch_gdelt(params_30d)['articles'])
    baseline_daily = count_30d / baseline_days
    ratio = count_24h / baseline_daily if baseline_daily > 0 else 0
    return {'velocity_24h': count_24h, 'baseline_daily': baseline_daily, 'ratio': ratio}
```

**Gate application:**
| GDELT velocity ratio | Mode A action | Mode B action |
|---|---|---|
| ≤ 2.0× | Full position (no discount) | — |
| > 2.0× and ≤ 4.0× | 0.5× position scalar (information confound possible) | — |
| > 4.0× | Skip entirely (genuine information shock likely) | — |
| ≤ 1.5× | — | Full position (no discount) |
| > 1.5× and ≤ 3.0× | — | 0.5× position scalar |
| > 3.0× | — | Skip entirely |

**NER for entity extraction:** use spaCy `en_core_web_sm` NER on market question text; extract PERSON and GPE entities; use the longest single entity string as the GDELT query term. Fallback: use the first 4 words of the question as keyword query if NER returns no entities.

**Limitation (tracked):** GDELT free API caps at 250 articles per request; high-velocity events (elections, major conflicts) may hit the ceiling, making the 30-day baseline undercount. At sophisticated tier, use GDELT artcount mode (returns exact counts) and GKG for entity-level baseline.

### IS Backtest Specification

**Purpose:** Validate that base-rate fade signals have statistically significant win rates on Polymarket's own historical data before any live deployment.

**Protocol per category cell:**
1. Filter historical resolved markets for cell (category + window ≥ 12m + resolved)
2. For each resolved market: compute base_rate_at_entry (rolling 24m up to market creation date) and YES price at entry (use 7-day post-opening price as proxy for "signal observation time"; avoid creation-day noise)
3. Flag as signal: |YES_price − base_rate| ≥ threshold (15 pp Mode A; 12 pp Mode B)
4. Outcome: `resolved_in_fade_direction` = 1 if (YES > base_rate + threshold AND market resolves NO) OR (YES < base_rate − threshold AND market resolves YES)
5. Compute WR = fraction of signals with `resolved_in_fade_direction = 1`
6. **Mann-Whitney U test**: WR vs null WR 0.50, one-tailed, Wilcoxon signed-rank (binary outcomes → binomial test equivalent), p < 0.10 significance threshold
7. **Minimum n per cell for backtest:** ≥ 15 signal events per cell (at ≥ 15 pp threshold, roughly 15–20% of resolved markets will qualify; need ≥ 75–100 resolved markets per cell for this)
8. **Deflation adjustment:** at intermediate tier, test only one threshold per cell (15 pp or 12 pp, not a grid). At sophisticated tier, apply DSR/CPCV across threshold grid to prevent multiple-testing inflation.

**Bank-level pass criterion:**
- ≥ 3 of all tested cells pass p < 0.10 → signal is real; eligible cells go live
- 1–2 cells pass → signal active but restricted to passing cells only
- 0 cells pass → **anti-prim B** triggered; retire signal pending re-investigation

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Rule structure | Single threshold (15 pp uniform) | **Two-mode: Mode A (narrative-salient, ≥ 15 pp) vs Mode B (structural-constraint, ≥ 12 pp)** — threshold differentiated by category base-rate variance and information-updating risk |
| Category taxonomy | Informal 8-category list | **Formal 2-mode assignment with precision ≥ 0.85 NLP tagger gate; `other` excluded; mode determines threshold, confound gate, and sizing** |
| Base-rate computation | Specified existence (Gamma API) | **Step-by-step database methodology: Gamma API pagination fields, NLP classifier spec, resolution frequency aggregator code, minimum cell eligibility criteria (≥ 30 resolved/cell, ≥ 8 cells total)** |
| Rolling window | Mentioned as requirement | **Formalised: rolling 24m window; 12m vs 24m stability check; δ < 0.08 proxy for ρ ≥ 0.80; quarterly recalibration; unstable → ineligible** |
| Information vs bias | "Primary identification problem" | **GDELT velocity gate formalised: NER entity extraction, 30-day baseline, asymmetric thresholds by mode (2×/4× Mode A; 1.5×/3× Mode B), 0.5× position scalar at intermediate zone** |
| IS backtest | Mentioned Mann-Whitney requirement | **Step-by-step IS backtest protocol: entry date proxy, outcome definition, Wilcoxon binomial test, p < 0.10, minimum n=15 per cell, bank-level pass criterion (≥ 3 cells)** |
| Anti-prim escape hatches | None formalised | **3 formal anti-prims: (A) database too sparse, (B) IS backtest fails all cells, (C) confound rate > 60%** |
| Certainty | hypothesis | **hypothesis (maintained — no own-data backtest completed; infrastructure specified but not built)** |

### Evidence — 10 Sources

| Source | Finding |
|---|---|
| **Kahneman & Lovallo (1993, Management Science)** | Inside view / outside view divergence formalized; corporate planners consistently ignore reference class base rates; effect measured across experimental and field settings; mechanism independent of expertise level |
| **Kahneman & Tversky (1973, Psychological Review)** | Representativeness heuristic; base-rate neglect demonstrated in probability estimation tasks; participants anchor on case description and ignore prior probabilities even when explicitly provided |
| **Flyvbjerg (2006, Management Science)** | Reference class forecasting applied to infrastructure projects: systematic 40–200% cost overruns across 258 projects; inside-view dominates even in high-stakes expert domains; **supports Mode B rationale**: structural categories (budget approvals, legislative votes) that follow institutional patterns are more amenable to reference-class adjustment |
| **Tetlock (2005, "Expert Political Judgment")** | Expert political forecasters underperform base-rate models; inside-view anchoring strongest for high-certainty hedgehog forecasters; **directly grounds Mode A**: elections and geopolitics most narratively loaded |
| **Wolfers & Zitzewitz (2004, JEP)** | PM well-calibrated on average (p ≈ 0.30–0.70); well-calibrated aggregate compatible with systematic sub-category bias; does not rule out base-rate neglect as within-category phenomenon |
| **Manski (2006, JFE)** | Documents multiple PM calibration anomalies including category-level deviations; aggregate calibration masks systematic within-category departures; **provides theoretical warrant for category-cell disaggregation** |
| **Tetlock & Gardner (2015, "Superforecasting")** | Superforecasters outperform prediction markets by anchoring on reference classes first, then adjusting for case-specific detail (outside-in method). This inversion of the inside-view pattern is the direct operationalisation of the base-rate approach this signal automates |
| **Della Vedova (SSRN 6191618, 2025)** | 222M Polymarket trades; 94% overall accuracy; per-category accuracy not reported; confirms high-accuracy baseline without disaggregating by narrative-intensity — **does not contradict signal; aggregate calibration hides within-category biases** |
| **Flyvbjerg, Holm & Buhl (2002, JAPA)** | Underestimation bias in project forecasting across 20 nations; effect larger for political/social projects than technical ones; **reference class forecasting (base-rate approach) reduces bias by 40–90% in these domains; analogy supports higher exploitation potential for narrative-salient categories (Mode A)** |
| **Bailey, Borwein & Lopez de Prado (2014, Journal of Portfolio Management)** | Deflated Sharpe Ratio + CPCV; **invoked at IS backtest specification stage**: intermediate tier uses single-threshold IS test (no overfitting risk); sophisticated tier requires DSR correction when testing threshold grid |

### Key Numbers

| Metric | Value |
|---|---|
| Mode A threshold | ≥ **15 pp** gap from category base rate |
| Mode B threshold | ≥ **12 pp** gap from category base rate |
| Minimum category cell size | ≥ **30 resolved markets** in rolling 24m window |
| Minimum cells for live use | ≥ **8 qualifying cells** (database); ≥ **3 IS-passing cells** (live eligibility) |
| Window stability proxy threshold | δ < **8 pp** (12m vs 24m base-rate drift) |
| GDELT confound — Mode A thresholds | Full: ≤ 2×; Discount: 2–4× (0.5× scalar); Skip: > 4× |
| GDELT confound — Mode B thresholds | Full: ≤ 1.5×; Discount: 1.5–3× (0.5× scalar); Skip: > 3× |
| IS backtest significance | Mann-Whitney U (Wilcoxon binomial), **p < 0.10**, one-tailed |
| IS backtest minimum n per cell | ≥ **15 signal events** per cell (requires ≥ 75–100 resolved markets/cell) |
| Bank-level pass criterion | ≥ **3 cells** passing at p < 0.10 |
| Anti-prim C trigger | > **60%** of triggered signals coincide with GDELT ratio > mode threshold |
| Kelly sizing | α = **0.10** fractional floor (no calibration history) |
| FLB exclusion zone | YES < **0.10** or > **0.90** — defer to FLB prim |
| NLP classifier precision gate | ≥ **0.85** per-category precision on N=50 spot-check sample |

### 8 Documented Limitations

1. **Category-resolution database not yet built (#1 blocker, partially resolved at intermediate)** — the Gamma API scraping methodology is now specified in full, but the database itself has not been built. All live-use gates remain blocked until: (a) scrape complete, (b) NLP tagger validated at ≥ 0.85 precision, (c) ≥ 8 qualifying cells available. Intermediate elevation specifies the HOW; building the database is a blocking engineering task.
2. **NLP tagger precision gate may be hard to achieve for ambiguous categories** — `executive_action` and `legislation` categories frequently overlap (an executive action can be triggered by legislative authorisation). Ambiguous markets may receive incorrect category labels, polluting the base rate computation. Tagger spot-check N=50 may miss systematic confusion patterns at higher N. Mitigation: add a confidence threshold to the tagger (discard markets where P(top_class) < 0.75).
3. **GDELT coverage is entity-dependent** — high-profile US political entities receive strong GDELT coverage; obscure foreign elections or niche regulatory proceedings have low article counts, making the 30-day baseline unreliable. In low-coverage markets, GDELT velocity ratio may fire false-positives on even modest news events. Mitigation at sophisticated tier: add coverage-quality gate (if baseline_daily < 2 articles/day → skip GDELT gate; rely on category cell quality instead).
4. **Rolling window reduces cell sample size** — the 24-month rolling window is correct structurally but halves the available resolved markets for a 4-year history. For newer categories (crypto_regulation from 2022), a 24m window may yield < 30 resolved markets, rendering those cells permanently ineligible until further resolutions accumulate. This creates cold-start problem for recently-emerged categories.
5. **IS backtest uses proxy entry price (7-day post-opening)** — no historical tick-level YES price at exact signal observation time is available from Gamma API (only creation price and resolution price). The 7-day post-opening proxy introduces noise: markets that moved sharply in the first 7 days will show inflated or deflated gaps. At sophisticated tier, replace with volume-weighted average price in days 3–10.
6. **FLB interaction at mid-range prices** — if a narrative-driven market pushes YES from 0.55 to 0.75, and the category base rate is 0.50, this signal (Mode A: 25 pp gap) fires. But if the market also exhibits a structural momentum from a secondary catalyst, entering the fade while momentum continues causes drawdown. No momentum veto is specified at intermediate tier.
7. **Information vs bias confound is irreducible at the signal level** — GDELT velocity captures news publication rate, not information content. A leaked document is one article; a 100-article analysis of a stable situation is 100 articles. The ratio can be low during genuine information events (if news is concentrated in one source) or high during pure sentiment storms (if many outlets repeat the same narrative). The gate reduces confound probability but does not eliminate it.
8. **Edge may already be zero in well-covered categories** — US presidential election markets (elections_US) are the highest-liquidity, highest-attention political PM markets. If sophisticated participants already apply reference-class reasoning in those markets, the edge in that cell may be below fee floor before the database is even built. The 15 pp threshold was set conservatively; the IS backtest will reveal whether elections_US produces any signal edge or whether Mode A is limited to elections_foreign and geopolitical_conflict.

### Implementation

```python
# src/strategies/base_rate_neglect_fade.py (intermediate skeleton)
# BLOCKED: category-resolution database (src/data/category_base_rates.py) must exist first

from src.data.category_base_rates import CategoryBaseRateDB
from src.data.gdelt import get_gdelt_velocity
from src.nlp.category_tagger import classify_market  # precision-gated NLP tagger

MODE_A_CATEGORIES = {"elections_US", "elections_foreign", "geopolitical_conflict", "judicial"}
MODE_B_CATEGORIES = {"legislation", "executive_action", "crypto_regulation"}

THRESHOLDS = {
    "MODE_A": 0.15,
    "MODE_B": 0.12,
}

GDELT_GATES = {
    "MODE_A": {"discount_ratio": 2.0, "skip_ratio": 4.0, "discount_scalar": 0.5},
    "MODE_B": {"discount_ratio": 1.5, "skip_ratio": 3.0, "discount_scalar": 0.5},
}

FILTERS = {
    "min_liquidity": 5000,
    "max_bid_ask": 0.05,
    "min_resolution_days": 14,
    "max_resolution_days": 90,
    "yes_range": (0.10, 0.90),         # FLB exclusion zone outer boundary
    "signal_range": (0.20, 0.80),       # active signal zone (inside FLB exclusion)
}


def compute_signal(market: dict, base_rate_db: CategoryBaseRateDB) -> dict | None:
    yes = market["yes_price"]
    
    # FLB exclusion zone
    if yes < FILTERS["yes_range"][0] or yes > FILTERS["yes_range"][1]:
        return None  # defer to FLB prim
    
    # Market microstructure filters
    if (market["liquidity"] < FILTERS["min_liquidity"] or
            market["bid_ask_spread"] > FILTERS["max_bid_ask"] or
            not (FILTERS["min_resolution_days"]
                 <= market["resolution_days"]
                 <= FILTERS["max_resolution_days"])):
        return None
    
    # Classify market category
    category, conf = classify_market(market["title"] + " " + market.get("description", ""))
    if conf < 0.75:
        return None  # ambiguous classification
    
    # Determine mode
    if category in MODE_A_CATEGORIES:
        mode = "MODE_A"
    elif category in MODE_B_CATEGORIES:
        mode = "MODE_B"
    else:
        return None  # 'other' category — no signal
    
    threshold = THRESHOLDS[mode]
    
    # Retrieve base rate
    cell = base_rate_db.get_rate(category)
    if cell is None or not cell["eligible"]:
        return None  # anti-prim A: insufficient sample or unstable window
    
    if not cell.get("backtest_passed", False):
        return None  # anti-prim B: IS backtest not passed for this cell
    
    base_rate = cell["base_rate"]
    gap = yes - base_rate
    
    if abs(gap) < threshold:
        return None  # gap below threshold
    
    # GDELT confound check
    entity = extract_primary_entity(market["title"])  # spaCy NER
    gdelt = get_gdelt_velocity(entity)
    gate = GDELT_GATES[mode]
    
    if gdelt["ratio"] > gate["skip_ratio"]:
        return None  # genuine information shock — skip
    
    position_scalar = 1.0
    if gdelt["ratio"] > gate["discount_ratio"]:
        position_scalar = gate["discount_scalar"]  # 0.5× information-confound discount
    
    direction = "NO" if gap > 0 else "YES"
    return {
        "direction": direction,
        "gap": abs(gap),
        "base_rate": base_rate,
        "cell_n": cell["n"],
        "mode": mode,
        "category": category,
        "gdelt_ratio": gdelt["ratio"],
        "position_scalar": position_scalar,
        "mechanism": "category_base_rate_neglect",
    }


def extract_primary_entity(title: str) -> str:
    """Extract primary PERSON or GPE entity from market title for GDELT lookup."""
    import spacy
    nlp = spacy.load("en_core_web_sm")
    doc = nlp(title)
    entities = [ent.text for ent in doc.ents if ent.label_ in ("PERSON", "GPE", "ORG")]
    if entities:
        return max(entities, key=len)  # longest entity is usually most specific
    return " ".join(title.split()[:4])  # fallback: first 4 words
```

**Required infrastructure (blocking):**
- `src/data/category_base_rates.py` — Gamma API scraper + NLP tagger wrapper + resolution frequency aggregator + window stability checker + IS backtest runner
- `src/nlp/category_tagger.py` — fine-tuned or zero-shot NLI classifier with precision gate
- `src/data/gdelt.py` — GDELT API client with baseline caching (30-day rolling baseline should be cached, not re-fetched per signal)

### Anti-Prim Escape Hatches (3 Formal)

- **(A) Database Sparse**: after Gamma API scrape, < 8 category cells achieve ≥ 30 resolved markets in 24m rolling window → database too sparse for any live use; hold signal inactive until additional resolved markets accumulate (recheck quarterly)
- **(B) IS Backtest Fails**: after per-cell IS backtest, 0 cells pass Mann-Whitney U p < 0.10 → inside-view bias hypothesis not confirmed on PM own-data for any category → retire signal; investigation required (mechanism may be priced-in, cell sizes too small, confound dominates across all categories)
- **(C) Confound Rate Dominant**: rolling 90-day audit — if > 60% of all triggered signals coincide with GDELT velocity > mode-threshold at trigger time → signal is detecting information events more than bias events → reduce to 0.25× Kelly across all cells pending re-investigation; requires structural fix (threshold calibration or GDELT gate tightening) before full reinstatement

### Conditions Log Entry

- **Works when:** YES deviates ≥ 15 pp (Mode A) or ≥ 12 pp (Mode B) from category empirical base rate; cell eligible (≥ 30 resolved markets in 24m rolling window; 12m vs 24m drift < 8 pp; IS backtest passed p < 0.10); liquidity ≥ $5k; bid-ask ≤ $0.05; resolution 14–90 days; YES ∈ [0.20, 0.80] (outside FLB zone); GDELT velocity ≤ skip threshold for mode; NLP category tagger confidence ≥ 0.75; ≥ 3 cells in database have passed IS backtest
- **Fails when:** Category-resolution database not built (BLOCKING for any live use); category cell has < 30 resolved markets or fails 12m/24m stability check; genuine information shock (GDELT skip threshold exceeded); FLB zone (YES < 0.10 or > 0.90 — defer to FLB prim); thin-liquidity adversarial selection (< $5k); market within 5 days of resolution; NLP tagger confidence < 0.75 (ambiguous category); IS backtest fails all cells (anti-prim B)
- **Anti-prim A (database sparse):** < 8 qualifying cells → inactive; **Anti-prim B (IS fails):** 0 cells pass p < 0.10 → retire; **Anti-prim C (confound dominates):** > 60% GDELT confound rate → reduce to 0.25× Kelly pending investigation
- **Last validated:** never (RESEARCH elevation — cycle 110; two-mode rule formalised; category-resolution database methodology specified; rolling window calibration protocol; GDELT confound gate; IS backtest specification; 3 anti-prim escape hatches; NOT yet empirically backtested; database not yet built)

## Refinement History

- 2026-04-12 (cycle 104): Created as naive prim. 20th polymarket prim class. Inside-view / outside-view mechanism grounded in Kahneman & Lovallo (1993) and Kahneman & Tversky (1973). Distinct from all 19 prior classes: uses PM's own historical category resolution frequencies as the reference signal. Primary blocker: category-resolution database does not yet exist. 7 limitations. Zero own-data. 8-source academic basis.
- 2026-04-12 (cycle 110): Refined to intermediate. Two-mode rule (Mode A: narrative-salient categories ≥ 15 pp; Mode B: structural-constraint categories ≥ 12 pp). Category-resolution database methodology fully specified (Gamma API pagination, NLP tagger precision ≥ 0.85, rolling 24m window, stability check, minimum cell criteria). GDELT confound gate formalised with asymmetric thresholds by mode. IS backtest specification (Mann-Whitney U p < 0.10, ≥ 3 cells required). 3 formal anti-prim escape hatches. Implementation skeleton written. Certainty remains hypothesis — database not yet built. 10-source basis.

## Next Refinement Path (Sophisticated)

5 upgrades required for sophisticated elevation:

1. **Build and validate the database (BLOCKING)**: execute the Gamma API scrape; validate NLP tagger on N=50 spot-check per category (reject if precision < 0.85 for any Mode A/B category); compute rolling 24m base rates for all qualifying cells; run stability check; identify which cells are eligible. Target: ≥ 8 qualifying cells across Mode A + Mode B.
2. **Run IS backtest for each qualifying cell**: per-cell Mann-Whitney U p < 0.10; if ≥ 3 cells pass → database active; measure raw WR per cell; report effect sizes (Cohen d); identify which categories produce strongest signal vs. weakest. If 0 cells pass → anti-prim B → do not proceed to sophisticated.
3. **Calibrate GDELT thresholds empirically**: in the IS backtest sample, retroactively compute GDELT velocity ratios for each signal event; measure the fraction of profitable fade signals vs. confound signals at each velocity ratio level; recalibrate the 2× (Mode A) and 1.5× (Mode B) thresholds to maximise signal purity; upgrade from GDELT free API (article count cap) to GDELT artcount mode for exact counts.
4. **Threshold plateau grid with DSR+CPCV**: test Mode A threshold ∈ [0.12, 0.15, 0.18, 0.20] × Mode B threshold ∈ [0.10, 0.12, 0.15] per qualifying cell; verify profit factor stable within ±20% across grid (plateau condition); apply Deflated Sharpe Ratio + CPCV to prevent overfitting on 12-cell grid; reject parameters that only work at one threshold.
5. **Entry price proxy upgrade**: replace 7-day post-opening proxy with Gamma API volume-weighted average price in days 3–10; validate that entry price proxy correlates > 0.85 with market prices at realistic entry observation times; reduces noise in IS backtest outcomes.
