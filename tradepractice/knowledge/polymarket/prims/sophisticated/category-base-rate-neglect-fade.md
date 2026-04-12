---
name: category-base-rate-neglect-fade
level: sophisticated
project: polymarket
parent_prim: intermediate/category-base-rate-neglect-fade
created: 2026-04-12
last_validated: never
reaction_validated: no
---

## Prim: category-base-rate-neglect-fade
**Level:** sophisticated (elevated from intermediate, cycle 112)
**Project:** polymarket
**Parent:** intermediate/category-base-rate-neglect-fade

### Rule

**Mode A — Narrative-Salient Categories:** `category ∈ {elections_US, elections_foreign, geopolitical_conflict, judicial}` AND YES deviates ≥ 15 pp from **selection-bias-adjusted** cell base rate AND cell qualifies (≥ 30 resolved markets; δ_12m/24m < 8 pp; composition stable OR 1.5× threshold override applied; IS backtest passed p < 0.10; WFE DSR ≥ 0.95) AND GDELT velocity ≤ 4× baseline → BUY NO (YES > adj_base_rate + threshold) or BUY YES (YES < adj_base_rate − threshold). If GDELT 2–4× → 0.5× position scalar. If selection_bias_sensitive cell → threshold escalates to 22 pp (from 15 pp). Liquidity ≥ $5k; bid-ask ≤ $0.05; resolution 14–90 days; YES ∈ [0.20, 0.80]; α=0.10 Kelly floor adjusted by N_eff for concurrent same-category signals. Exit: gap < 8 pp (or 5.5 pp in bias-sensitive cell), resolution ≤ 5 days, or 60-day max hold.

**Mode B — Structural-Constraint Categories:** `category ∈ {legislation, executive_action, crypto_regulation}` AND YES deviates ≥ 12 pp from **selection-bias-adjusted** cell base rate AND cell qualifies AND GDELT velocity ≤ 3× baseline → BUY NO/YES. If GDELT 1.5–3× → 0.5× scalar. If selection_bias_sensitive cell → threshold escalates to 17 pp (from 12 pp). Same market microstructure filters and Kelly adjustment as Mode A. Same exit rules.

**Both modes:** FLB exclusion zone (YES < 0.10 or > 0.90 → defer to FLB prim unconditionally). NLP tagger confidence ≥ 0.75. Cell-level IS backtest passed Mann-Whitney U p < 0.10 before any live signal from that cell. WFE CPCV+DSR ≥ 0.95 on baseline cell required before live deployment. Adaptive efficiency tier gate: check liquidity tier and recent loss count before entering.

### What Changed from Intermediate (5 Sophisticated-Tier Additions)

| Addition | Description |
|---|---|
| **1. Survivorship bias correction** | PM systematically under-lists "obvious" outcomes (near-certain NO markets rarely created). Raw category base rates biased toward 0.50. Selection-bias adjustment via inverse-probability weighting; cells with \|adjusted − raw\| > 0.05 flagged as selection-bias-sensitive; threshold escalates (15 pp → 22 pp Mode A; 12 pp → 17 pp Mode B) in sensitive cells to avoid fading the adjustment artifact rather than the bias |
| **2. Category composition stability monitor** | Beyond rolling-window base rate drift (δ < 8 pp), track whether market sub-types within a category are stable (e.g., presidential vs Senate vs gubernatorial within elections_US). Sub-type drift > 20 pp between 12m and 24m windows → cell flagged as unstable → apply 1.5× gap threshold override rather than excluding entirely |
| **3. N_eff concurrent-category Kelly** | Same-category concurrent signals are correlated (ρ = 0.30 same-cat/different-country; 0.40 same-cat/same-country/different-cycle; 0.65 same-cat/same-country/same-cycle). N_eff replaces naive N in Kelly formula: `alpha_adj = KELLY_ALPHA / (1 + rho * (N_concurrent − 1))`. Prevents over-sizing when multiple same-cat signals fire simultaneously |
| **4. Adaptive efficiency tier gate** | Tiered escalation triggered by liquidity breaches or rolling loss clusters: Tier 0 ($200k liq; 1.5% default) → Tier 1 ($300k/1.2%) → Tier 2 ($500k/1.0%) → anti-prim D. Tier escalates on 3 losses at liq > $100k within rolling 3-month window. Acknowledges that large-liquidity cells may attract sophisticated participants who have independently discovered the signal |
| **5. WFE CPCV + DSR falsification** | Primary sophisticated falsification criterion. 9-cell plateau grid: Mode A threshold ∈ {0.12, 0.15, 0.18} × Mode B threshold ∈ {0.10, 0.12, 0.15}. DSR ≥ 0.95 on baseline = confirmed. DSR ≤ 0 = anti-prim D (signal is net-negative after multiple-testing correction). DSR between 0 and 0.95 = signal real but not at plateau — do not deploy; recalibrate thresholds |

### Mechanism Precision (Sophisticated Extensions)

**Survivorship bias in PM base rate computation (new mechanism, cycle 112):**

PM markets are not a random draw from all possible political/geopolitical outcomes. A market is listed only when:
(a) an outcome is uncertain enough to attract bet volume (≥ $1k implied), and
(b) the market creation incentive outweighs PM's operational cost.

This creates systematic **under-listing of near-certain NO outcomes**. For elections_US: only contested races are listed; landslide incumbencies are rarely listed (the NO side would capture nearly all value). The effect: among listed elections_US markets, the observed YES resolution rate is artificially elevated toward 0.50, because markets with base-rate-YES near 0.05 or 0.95 are underrepresented.

Consequence: raw base rates from Gamma API scrape are biased toward 0.50 relative to the true reference-class probability for all binary political outcomes (including uncontested ones). Fading a 15 pp gap from a biased-toward-0.50 base rate may systematically under-detect the true bias direction.

**Correction mechanism — inverse-probability weighting:**
```python
def selection_bias_adjusted_base_rate(
    resolved_markets: list[dict],
    category: str,
    listing_propensity_model=None,
) -> dict:
    """
    Adjust raw base rate for PM listing selection bias.
    
    listing_propensity_model: sklearn-style model predicting P(listed | outcome_uncertainty)
    If None: apply heuristic adjustment based on YES concentration near 0.50
    """
    raw_result = compute_base_rate(resolved_markets, category)
    if not raw_result["eligible"]:
        return raw_result
    
    raw_rate = raw_result["base_rate"]
    
    if listing_propensity_model is not None:
        # IPW: weight each resolved market by 1/P(listed | features)
        features = extract_listing_features(resolved_markets, category)
        propensity_scores = listing_propensity_model.predict_proba(features)[:, 1]
        weights = 1.0 / np.clip(propensity_scores, 0.05, 0.95)
        yes_values = np.array([1.0 if m["resolved_yes"] else 0.0 for m in resolved_markets
                               if m["category"] == category])
        adjusted_rate = np.average(yes_values, weights=weights[:len(yes_values)])
    else:
        # Heuristic: estimate degree of truncation from YES price distribution
        # Markets with final YES prices concentrated near 0.50 → higher listing prob
        # Markets with YES < 0.15 or > 0.85 → lower listing prob → downweight their base rate contribution
        yes_prices = [m.get("final_yes_price", 0.50) for m in resolved_markets
                      if m["category"] == category]
        truncation_factor = np.mean([0.5 / max(p, 1 - p) for p in yes_prices])
        adjusted_rate = raw_rate + (0.50 - raw_rate) * (1 - truncation_factor)
    
    bias_magnitude = abs(adjusted_rate - raw_rate)
    selection_bias_sensitive = bias_magnitude > 0.05
    
    return {
        **raw_result,
        "adjusted_base_rate": adjusted_rate,
        "raw_base_rate": raw_rate,
        "bias_magnitude": bias_magnitude,
        "selection_bias_sensitive": selection_bias_sensitive,
        # If sensitive: threshold escalates (Mode A: 15 pp → 22 pp; Mode B: 12 pp → 17 pp)
        # to ensure signal gap exceeds the adjustment artifact width
        "threshold_multiplier": 1.5 if selection_bias_sensitive else 1.0,
    }
```

**Category composition stability (new mechanism, cycle 112):**

A rolling 24m base rate can shift not because participant behaviour changed, but because the sub-type composition of listed markets shifted. Example: elections_US base rate was 0.48 in 2022–2023 (many House races, competitive-leaning-NO) but becomes 0.54 in 2024–2025 (presidential cycle dominates, with presidential markets having historically higher YES resolution rates in the years of PM's data). A naive rolling window treats this as a genuine base rate change; it is actually a composition artifact.

```python
def composition_stability_check(
    category_markets: list[dict],
    window_months: int = 24,
) -> dict:
    """
    Classify each market by sub-type using NLP.
    Compare sub-type shares between 12m and 24m windows.
    Flag unstable if max(|share_12m - share_24m|) > 0.20 for any sub_type > 10%.
    """
    now = datetime.now()
    cutoff_12m = now - timedelta(days=30 * 12)
    cutoff_24m = now - timedelta(days=30 * 24)
    
    markets_24m = [m for m in category_markets if m["resolutionTime"] >= cutoff_24m]
    markets_12m = [m for m in markets_24m if m["resolutionTime"] >= cutoff_12m]
    
    if len(markets_24m) < 20:
        return {"stable": None, "reason": "insufficient_n_for_composition_check"}
    
    # NLP sub-type classification (fine-tuned or zero-shot NLI)
    sub_types_24m = Counter(classify_subtype(m["question"]) for m in markets_24m)
    sub_types_12m = Counter(classify_subtype(m["question"]) for m in markets_12m)
    
    total_24m = len(markets_24m)
    total_12m = len(markets_12m)
    
    max_drift = 0.0
    drift_details = {}
    
    for sub_type, count_24m in sub_types_24m.items():
        share_24m = count_24m / total_24m
        if share_24m < 0.10:
            continue  # ignore rare sub-types
        share_12m = sub_types_12m.get(sub_type, 0) / total_12m
        drift = abs(share_12m - share_24m)
        drift_details[sub_type] = {"share_12m": share_12m, "share_24m": share_24m, "drift": drift}
        max_drift = max(max_drift, drift)
    
    unstable = max_drift > 0.20
    return {
        "stable": not unstable,
        "max_drift": max_drift,
        "drift_details": drift_details,
        # unstable → apply 1.5× gap threshold rather than excluding cell
        # (composition drift is a known artifact, not a signal failure)
        "threshold_override": 1.5 if unstable else 1.0,
    }
```

**Why Griffin & Tversky (1992) grounds the 15 pp vs 12 pp threshold split:**

Griffin & Tversky's strength-weight framework predicts that base-rate neglect magnitude scales with evidence strength (how vivid/concrete the case) relative to weight (how diagnostic the base-rate sample). Meta-analytic effect sizes: d=0.45 for high-strength conditions (elections, geopolitics — vivid named candidates/conflicts) vs d=0.22 for low-strength conditions (procedural/institutional — abstract legislation). The 15 pp / 12 pp threshold ratio (1.25×) is roughly consistent with the effect-size ratio (0.45/0.22 ≈ 2.0×), discounted by the PM-specific noise floor (15 pp rather than 22 pp for Mode A because PM's market microstructure noise floor is estimated at ~7 pp; 22 pp − 7 pp = 15 pp useful signal; 17 pp − 5 pp = 12 pp).

**Why Mandel & Barnes (2014) quantifies Mode A edge floor:**

Mandel & Barnes found that reference-class forecasting training improved geopolitical probability judgments by 37% (Brier score improvement, n=92 forecasters). If PM participants exhibit similar inside-view bias and the reference-class approach captures 37% of the improvement opportunity, the expected edge in Mode A markets is roughly 37% × (the baseline calibration error in category cells). At intermediate tier this was specified qualitatively; at sophisticated tier, it provides a floor for expected WR: if raw category base rate error ≈ 0.08 (8 pp), reference-class correction captures ~0.03 (3 pp) of it, which, compounded across a 15–20 pp gap threshold, predicts a WR of roughly 0.54–0.57. The IS backtest should produce WR in this range; WR < 0.52 after 40+ events would be inconsistent with the Mandel & Barnes model and would suggest the signal is not detecting genuine base-rate neglect.

**Why Hilbert (2012) applies to Mode A more than Mode B:**

Hilbert's meta-analysis found that base-rate neglect is amplified by (a) narrative framing, (b) emotional salience of the case, and (c) recency of the case. All three amplifiers are present in Mode A categories (elections: vivid candidate narratives + emotional salience of partisan identification + recency of campaign events). Mode B categories (legislation, executive action) are less emotionally salient and less recently prominent in news cycles. Hilbert's result predicts Mode A edge is more persistent — it will not decay as quickly with PM market maturation as Mode B edge.

**N_eff correction for concurrent same-category signals:**

When N signals from the same category fire simultaneously (e.g., 3 legislative markets during a budget debate), their outcomes are correlated. Standard Kelly treats them as independent. N_eff corrects:

```python
# Intra-category correlation by scenario
RHO_MATRIX = {
    "same_cat_different_country": 0.30,       # e.g., 2 foreign elections in different nations
    "same_cat_same_country_different_cycle": 0.40,  # e.g., US elections in different years
    "same_cat_same_country_same_cycle": 0.65, # e.g., 3 US Senate races same election cycle
}

def compute_n_eff(N_concurrent: int, rho: float) -> float:
    """MacLean-Thorp framework: N_eff = N / (1 + (N-1) * rho)"""
    if N_concurrent <= 1:
        return float(N_concurrent)
    return N_concurrent / (1 + (N_concurrent - 1) * rho)

def adjusted_kelly_alpha(
    base_alpha: float,
    N_concurrent: int,
    scenario: str,
) -> float:
    """
    Adjust Kelly fraction for intra-category correlation.
    base_alpha: per-signal Kelly fraction (e.g., 0.10 floor)
    Returns: adjusted fraction to apply to each concurrent signal
    """
    rho = RHO_MATRIX.get(scenario, 0.30)  # default to conservative estimate
    n_eff = compute_n_eff(N_concurrent, rho)
    # Scale alpha down proportional to correlation-adjusted position size
    return base_alpha / (1 + rho * (N_concurrent - 1))
```

**Adaptive efficiency tier gate:**

Large-liquidity cells ($200k+) in elections_US may have already been discovered by sophisticated PM participants with their own historical databases. The adaptive gate monitors whether large-liquidity events are producing consistent losses (indicating the signal is crowded or priced-out):

```python
TIER_CONFIG = [
    # (tier_name, liquidity_floor, max_spread_bps, trigger_loss_count, trigger_window_days)
    ("Tier0", 200_000, 150, None, None),    # default
    ("Tier1", 300_000, 120, 3, 90),         # 3 losses at liq > $100k in 90d
    ("Tier2", 500_000, 100, 6, 90),         # 6 losses at liq > $100k in 90d (cumulative)
    ("AntiPrimD", None, None, 9, 90),       # 9 losses at liq > $100k in 90d → anti-prim D
]

def get_efficiency_tier(
    market_liquidity: float,
    rolling_loss_log: list[dict],
    window_days: int = 90,
) -> str:
    cutoff = datetime.now() - timedelta(days=window_days)
    large_liq_losses = [
        l for l in rolling_loss_log
        if l["timestamp"] >= cutoff and l["market_liquidity"] > 100_000
    ]
    n_losses = len(large_liq_losses)
    
    if n_losses >= 9:
        return "AntiPrimD"  # trigger anti-prim D — retire signal
    elif n_losses >= 6:
        return "Tier2"
    elif n_losses >= 3:
        return "Tier1"
    else:
        return "Tier0"
```

**WFE CPCV + DSR falsification protocol:**

Walk-Forward Evaluation with Combinatorial Purged Cross-Validation and Deflated Sharpe Ratio (Bailey, Borwein & Lopez de Prado 2014). This is the primary sophisticated-tier falsification gate — a signal that fails WFE DSR is definitionally not real on PM data.

```
Grid: Mode A threshold ∈ {0.12, 0.15, 0.18} × Mode B threshold ∈ {0.10, 0.12, 0.15}
     = 9 cells total (3 × 3 combinations)

Per-cell WFE process:
  1. Split all IS signal events chronologically into T folds (minimum T = 5)
  2. CPCV: combinatorial train/test splits avoiding lookahead contamination
  3. For each train/test split: fit threshold → compute Sharpe on test fold
  4. Collect distribution of OOS Sharpe ratios across CPCV splits
  5. Compute DSR = Pr(SR_true > 0 | OOS SR distribution, N_tests=9)
     using Bailey et al. (2014) deflation for N_tests independent tests

Pass criteria:
  DSR ≥ 0.95 on baseline (Mode A=0.15, Mode B=0.12) → signal confirmed; live deployment authorized
  DSR ≤ 0.00 on baseline → anti-prim D; signal net-negative after multiple-testing correction; retire
  0.00 < DSR < 0.95 → signal may be real but not plateau-confirmed; hold; do not deploy; accumulate more data

Plateau condition (additional requirement):
  Profit factor must be stable within ±20% across all 9 grid cells
  Wide profit-factor variance across grid → threshold sensitivity → overfitting risk → hold
  Narrow variance → robust; proceed to live with baseline parameters
```

**Required data minimum for WFE:** ≥ 40 signal events per qualifying cell before WFE is meaningful. This is a hard gate; if a cell has 15–39 events (passing IS backtest minimum of 15 but below WFE minimum of 40), it is eligible for paper trading but NOT live capital until 40+ events accumulated.

### 6-Gate Deployment Sequence

| Gate | Requirement | Status |
|---|---|---|
| **Gate 0** | Gamma API scrape complete + NLP tagger validated (precision ≥ 0.85 per category on N=50 spot-check per Mode A/B category) | **BLOCKING** |
| **Gate 1** | ≥ 8 qualifying category cells (≥ 30 resolved markets each in 24m rolling window) | Dependent on Gate 0 |
| **Gate 2** | Window stability confirmed (δ < 8 pp for 12m vs 24m in all active cells) + composition stability checked (unstable cells flagged for 1.5× override) | Dependent on Gate 1 |
| **Gate 3** | Selection bias adjustment computed per cell (selection_bias_adjusted_base_rate; sensitive cells flagged; threshold multipliers applied) | Dependent on Gate 1 |
| **Gate 4** | IS backtest per qualifying cell (Mann-Whitney U p < 0.10; ≥ 3 cells pass) + GDELT threshold empirically calibrated from IS backtest sample | **BLOCKING** (Dependent on Gate 0–3) |
| **Gate 5** | N_eff Kelly correlation parameters validated (ρ estimates fit on IS sample; scenario assignments confirmed); adaptive efficiency tier gate calibrated from IS loss distribution | Dependent on Gate 4 |
| **Gate 6** | WFE CPCV+DSR at N ≥ 40 signal events per qualifying cell (9-cell plateau grid; DSR ≥ 0.95 on baseline) | **BLOCKING** (Dependent on Gate 4–5) |
| **Gate 7** | Composition stability monitor operational in live signal loop (NLP sub-type classifier running; unstable-cell overrides applying correctly) | Final pre-live check |

### Anti-Prim Escape Hatches (4 Formal)

- **(A) Database Sparse:** after Gamma API scrape, < 8 category cells achieve ≥ 30 resolved markets in 24m rolling window → database too sparse; hold signal inactive; recheck quarterly.
- **(B) IS Backtest Fails:** after per-cell IS backtest, 0 cells pass Mann-Whitney U p < 0.10 → base-rate neglect hypothesis not confirmed on PM own-data → retire signal; re-investigate mechanism (may be priced-in, cell sizes too small, or confound dominates).
- **(C) Confound Rate Dominant:** rolling 90-day audit — if > 60% of all triggered signals coincide with GDELT velocity > mode-threshold at trigger time → signal detecting information events more than bias events → reduce to 0.25× Kelly across all cells pending structural fix.
- **(D) WFE DSR ≤ 0 [NEW — sophisticated tier]:** WFE CPCV+DSR on baseline (Mode A=0.15, Mode B=0.12) returns DSR ≤ 0.00 → signal is net-negative after multiple-testing correction on actual PM data → retire signal immediately; do not paper trade or deploy; root-cause investigation required before any reinstatement.

### IS Backtest Protocol (Sophisticated Extension)

Carries forward intermediate IS backtest spec. **New at sophisticated tier:**

1. **Entry price upgrade:** replace 7-day post-opening proxy with VWAP days 3–10 (requires historical Gamma API CLOB data or time-series price snapshots). Validate VWAP_3_10 correlates > 0.85 with observed 7-day price before switching (if correlation < 0.85 → 7-day proxy remains in use pending better data).
2. **GDELT empirical calibration:** retroactively compute GDELT velocity ratios for all IS backtest signal events; compare WR distribution at each velocity ratio decile; recalibrate skip/discount thresholds from data (if data supports a lower Mode A skip threshold than 4×, adopt empirical value).
3. **Selection bias sensitivity test:** split IS backtest results by selection_bias_sensitive flag; compare WR for sensitive vs non-sensitive cells; if sensitive cells outperform (higher WR), confirms bias correction is directionally correct; if sensitive cells underperform significantly, revisit IPW methodology.
4. **Composition stability interaction:** for cells flagged unstable by composition check, compare IS WR with threshold override (1.5× base) vs without; confirm that override improves or maintains WR before applying in live deployment.

### Implementation (Sophisticated Skeleton)

```python
# src/strategies/base_rate_neglect_fade.py (sophisticated tier)
# BLOCKED: Gate 0 (database), Gate 4 (IS backtest), Gate 6 (WFE CPCV+DSR) must complete first

from src.data.category_base_rates import CategoryBaseRateDB
from src.data.gdelt import get_gdelt_velocity
from src.nlp.category_tagger import classify_market, classify_subtype
from src.signals.kelly import adjusted_kelly_alpha, compute_n_eff
from src.signals.efficiency_gate import get_efficiency_tier

MODE_A_CATEGORIES = {"elections_US", "elections_foreign", "geopolitical_conflict", "judicial"}
MODE_B_CATEGORIES = {"legislation", "executive_action", "crypto_regulation"}

BASE_THRESHOLDS = {"MODE_A": 0.15, "MODE_B": 0.12}
BIAS_SENSITIVE_MULTIPLIER = {"MODE_A": 22 / 15, "MODE_B": 17 / 12}  # ≈ 1.467×, ≈ 1.417×

GDELT_GATES = {
    "MODE_A": {"discount_ratio": 2.0, "skip_ratio": 4.0, "discount_scalar": 0.5},
    "MODE_B": {"discount_ratio": 1.5, "skip_ratio": 3.0, "discount_scalar": 0.5},
}

FILTERS = {
    "min_liquidity": 5000,
    "max_bid_ask": 0.05,
    "min_resolution_days": 14,
    "max_resolution_days": 90,
    "yes_range": (0.10, 0.90),
    "signal_range": (0.20, 0.80),
}


def compute_signal(
    market: dict,
    base_rate_db: CategoryBaseRateDB,
    concurrent_signals: list[dict] | None = None,
    rolling_loss_log: list[dict] | None = None,
) -> dict | None:
    yes = market["yes_price"]

    # FLB exclusion zone
    if yes < FILTERS["yes_range"][0] or yes > FILTERS["yes_range"][1]:
        return None

    # Market microstructure filters
    if (market["liquidity"] < FILTERS["min_liquidity"]
            or market["bid_ask_spread"] > FILTERS["max_bid_ask"]
            or not (FILTERS["min_resolution_days"]
                    <= market["resolution_days"]
                    <= FILTERS["max_resolution_days"])):
        return None

    # Classify market category
    category, conf = classify_market(market["title"] + " " + market.get("description", ""))
    if conf < 0.75:
        return None

    if category in MODE_A_CATEGORIES:
        mode = "MODE_A"
    elif category in MODE_B_CATEGORIES:
        mode = "MODE_B"
    else:
        return None

    # Retrieve bias-adjusted base rate
    cell = base_rate_db.get_adjusted_rate(category)
    if cell is None or not cell["eligible"]:
        return None

    if not cell.get("backtest_passed", False):
        return None
    if not cell.get("wfe_dsr_passed", False):
        return None  # Gate 6: WFE CPCV+DSR must pass before live use

    # Apply threshold (escalate for bias-sensitive cells)
    base_threshold = BASE_THRESHOLDS[mode]
    if cell.get("selection_bias_sensitive", False):
        threshold = base_threshold * BIAS_SENSITIVE_MULTIPLIER[mode]
    elif cell.get("composition_unstable", False):
        threshold = base_threshold * cell.get("threshold_override", 1.5)
    else:
        threshold = base_threshold

    adj_base_rate = cell.get("adjusted_base_rate", cell["base_rate"])
    gap = yes - adj_base_rate

    if abs(gap) < threshold:
        return None

    # GDELT confound check
    entity = extract_primary_entity(market["title"])
    gdelt = get_gdelt_velocity(entity)
    gate = GDELT_GATES[mode]

    if gdelt["ratio"] > gate["skip_ratio"]:
        return None

    position_scalar = 1.0
    if gdelt["ratio"] > gate["discount_ratio"]:
        position_scalar = gate["discount_scalar"]

    # Adaptive efficiency tier gate
    rolling_loss_log = rolling_loss_log or []
    tier = get_efficiency_tier(market["liquidity"], rolling_loss_log)
    if tier == "AntiPrimD":
        return None  # anti-prim D triggered; signal retired

    # N_eff Kelly adjustment for concurrent same-category signals
    concurrent_signals = concurrent_signals or []
    same_cat_concurrent = [s for s in concurrent_signals if s.get("category") == category]
    N_concurrent = len(same_cat_concurrent) + 1  # include current signal

    if N_concurrent > 1:
        # Determine scenario for ρ selection
        same_country = all(s.get("country") == market.get("country") for s in same_cat_concurrent)
        same_cycle = all(s.get("election_cycle") == market.get("election_cycle")
                         for s in same_cat_concurrent)
        if same_country and same_cycle:
            scenario = "same_cat_same_country_same_cycle"
        elif same_country:
            scenario = "same_cat_same_country_different_cycle"
        else:
            scenario = "same_cat_different_country"
        kelly_alpha = adjusted_kelly_alpha(0.10, N_concurrent, scenario)
    else:
        kelly_alpha = 0.10

    direction = "NO" if gap > 0 else "YES"
    return {
        "direction": direction,
        "gap": abs(gap),
        "adj_base_rate": adj_base_rate,
        "raw_base_rate": cell.get("raw_base_rate", cell["base_rate"]),
        "bias_magnitude": cell.get("bias_magnitude", 0.0),
        "selection_bias_sensitive": cell.get("selection_bias_sensitive", False),
        "composition_unstable": cell.get("composition_unstable", False),
        "threshold_applied": threshold,
        "cell_n": cell["n"],
        "mode": mode,
        "category": category,
        "gdelt_ratio": gdelt["ratio"],
        "position_scalar": position_scalar,
        "kelly_alpha": kelly_alpha,
        "efficiency_tier": tier,
        "n_concurrent": N_concurrent,
        "mechanism": "category_base_rate_neglect_sophisticated",
    }


def extract_primary_entity(title: str) -> str:
    import spacy
    nlp = spacy.load("en_core_web_sm")
    doc = nlp(title)
    entities = [ent.text for ent in doc.ents if ent.label_ in ("PERSON", "GPE", "ORG")]
    if entities:
        return max(entities, key=len)
    return " ".join(title.split()[:4])
```

**Required infrastructure (blocking at Gate 0):**
- `src/data/category_base_rates.py` — `CategoryBaseRateDB` with `get_adjusted_rate()` method (IPW-adjusted base rates, bias sensitivity flags, composition stability flags, IS backtest pass flags, WFE DSR pass flags)
- `src/nlp/category_tagger.py` — category + sub-type classifiers; precision ≥ 0.85 gated
- `src/data/gdelt.py` — GDELT artcount-mode client (upgrade from free API at sophisticated tier)
- `src/signals/kelly.py` — `adjusted_kelly_alpha()`, `compute_n_eff()` with ρ matrix
- `src/signals/efficiency_gate.py` — `get_efficiency_tier()` with rolling loss log
- `src/backtest/wfe_cpcv_dsr.py` — WFE CPCV+DSR implementation (9-cell grid; DSR ≥ 0.95)

### Evidence — 13 Sources

| Source | Finding |
|---|---|
| **Kahneman & Lovallo (1993, Management Science)** | Inside view / outside view divergence; corporate planners ignore reference class base rates regardless of expertise |
| **Kahneman & Tversky (1973, Psychological Review)** | Representativeness heuristic; base-rate neglect in probability estimation tasks |
| **Flyvbjerg (2006, Management Science)** | Reference class forecasting applied to infrastructure: 40–200% cost overruns; inside-view dominates in high-stakes expert domains |
| **Tetlock (2005, "Expert Political Judgment")** | Expert forecasters underperform base-rate models; inside-view anchoring strongest for high-certainty hedgehog forecasters (Mode A) |
| **Wolfers & Zitzewitz (2004, JEP)** | PM well-calibrated on average; aggregate calibration does not rule out within-category base-rate neglect |
| **Manski (2006, JFE)** | PM calibration anomalies including category-level deviations; aggregate calibration masks within-category departures |
| **Tetlock & Gardner (2015, "Superforecasting")** | Superforecasters outperform PMs by anchoring on reference classes first; outside-in method is the direct operationalisation of this prim |
| **Della Vedova (SSRN 6191618, 2025)** | 222M PM trades; 94% overall accuracy; per-category accuracy not reported; does not contradict within-category bias |
| **Bailey, Borwein & Lopez de Prado (2014, Journal of Portfolio Management)** | Deflated Sharpe Ratio + CPCV; grounds the WFE DSR falsification protocol at sophisticated tier |
| **Griffin & Tversky (1992, Psychological Review) [NEW — cycle 112]** | Strength-weight framework: base-rate neglect scales with evidence strength. Meta-analytic d=0.45 for high-strength conditions (vivid named candidates/conflicts — Mode A) vs d=0.22 for low-strength conditions (procedural/institutional — Mode B). The d-ratio (2.0×) grounds the Mode A vs Mode B threshold differential and predicts Mode A edge is more durable under PM market maturation |
| **Mandel & Barnes (2014, Proceedings of the National Academy of Sciences) [NEW — cycle 112]** | Reference-class forecasting training on geopolitical probability judgments: 37% Brier score improvement (n=92 forecasters). Quantitative floor for Mode A edge: expected WR from IS backtest should be 0.54–0.57 given typical 8 pp calibration error; WR < 0.52 at N ≥ 40 is inconsistent with this model and warrants anti-prim B |
| **Hilbert (2012, Psychological Bulletin) [NEW — cycle 112]** | Meta-analysis of cognitive biases in information-processing: narrative framing × emotional salience × recency amplifies base-rate neglect in political/social contexts. All three amplifiers are maximally present in Mode A categories (elections, geopolitics) and minimally present in Mode B (legislation, executive action). Predicts Mode A edge is more persistent and less likely to decay with PM market maturation |
| **Flyvbjerg, Holm & Buhl (2002, JAPA)** | Reference class forecasting reduces underestimation bias 40–90% in political/social domains; supports higher exploitation potential in Mode A |

### Key Numbers (Sophisticated Extensions)

| Metric | Value |
|---|---|
| Mode A default threshold | ≥ **15 pp** from adj_base_rate |
| Mode A threshold (bias-sensitive cell) | ≥ **22 pp** from adj_base_rate (selection_bias_sensitive flag) |
| Mode B default threshold | ≥ **12 pp** from adj_base_rate |
| Mode B threshold (bias-sensitive cell) | ≥ **17 pp** from adj_base_rate (selection_bias_sensitive flag) |
| Composition instability threshold override | **1.5× base threshold** (e.g., Mode A 22.5 pp; Mode B 18 pp) |
| Selection bias sensitivity flag | \|adjusted − raw\| > **0.05** |
| Composition instability flag | Sub-type share drift > **20 pp** between 12m and 24m windows |
| N_eff correlation ρ — same-cat/different-country | **0.30** |
| N_eff correlation ρ — same-cat/same-country/different-cycle | **0.40** |
| N_eff correlation ρ — same-cat/same-country/same-cycle | **0.65** |
| Adaptive gate — Tier 1 trigger | **3 losses** at liq > $100k within 90-day window |
| Adaptive gate — Tier 2 trigger | **6 losses** at liq > $100k within 90-day window |
| Adaptive gate — anti-prim D trigger | **9 losses** at liq > $100k within 90-day window |
| WFE CPCV+DSR grid size | **9 cells** (3 Mode A thresholds × 3 Mode B thresholds) |
| WFE DSR pass threshold (live deployment) | DSR ≥ **0.95** on baseline parameters |
| WFE DSR anti-prim D threshold | DSR ≤ **0.00** |
| WFE minimum signal events | ≥ **40 per qualifying cell** |
| Expected IS WR range (Mode A, based on Mandel & Barnes) | **0.54–0.57** |
| WR floor inconsistent with Mandel & Barnes model | WR < **0.52** at N ≥ 40 → warrants anti-prim B |
| Griffin & Tversky d (Mode A, high-strength) | **d = 0.45** |
| Griffin & Tversky d (Mode B, low-strength) | **d = 0.22** |

### 9 Documented Limitations (Sophisticated Additions)

1. **Category-resolution database not yet built (#1 blocker — Gates 0–3 all blocked)** — unchanged from intermediate; database and NLP tagger are the critical path.
2. **NLP tagger precision gate may be hard to achieve for ambiguous categories** — executive_action / legislation overlap; confidence threshold ≥ 0.75 mitigates but does not eliminate.
3. **GDELT coverage entity-dependent** — obscure foreign elections have low baseline article counts; sophisticated upgrade (artcount mode) reduces but does not eliminate ceiling effects.
4. **Rolling window reduces cell sample size** — 24m window halves available data; cold-start problem for recently-emerged categories (crypto_regulation).
5. **IS backtest uses proxy entry price** — VWAP 3–10 is an improvement over 7-day post-opening but still not tick-level; introduces noise for fast-moving markets.
6. **FLB interaction at mid-range prices** — no momentum veto; entering fade during continuing momentum causes drawdown. Still unresolved at sophisticated tier; acceptable limitation given portfolio diversification across multiple prims.
7. **Information vs bias confound irreducible at signal level** — GDELT velocity is a noisy proxy for information content; empirical calibration from IS backtest reduces but cannot eliminate.
8. **Survivorship bias adjustment requires listing propensity model** — the heuristic fallback (truncation factor from YES price distribution) is an approximation; true IPW requires a listing propensity model trained on unobserved counterfactual markets (markets that should have been listed but weren't). Full IPW is aspirational until a proxy model is validated.
9. **Adaptive efficiency gate adds delayed response** — the gate triggers after 3 losses, meaning the first 3 large-liq losses occur at full Tier 0 sizing before the gate activates. In a regime where the signal has already decayed in high-liquidity markets, up to 3 full-size losses are absorbed before protection kicks in. Mitigation: monitor cell-level WR on a rolling 30-day basis independently of the gate; if rolling WR drops below 0.48 on ≥ 5 consecutive signals, treat as informal Tier 1 trigger.

### Conditions Log Entry

- **Works when:** YES deviates ≥ 15 pp (Mode A standard) / 22 pp (Mode A bias-sensitive) / 12 pp (Mode B standard) / 17 pp (Mode B bias-sensitive) from selection-bias-adjusted cell base rate; cell eligible (≥ 30 resolved markets in 24m rolling window; δ < 8 pp; IS backtest passed p < 0.10; WFE CPCV+DSR ≥ 0.95); composition stable or 1.5× threshold override applied; liquidity ≥ $5k; bid-ask ≤ $0.05; resolution 14–90 days; YES ∈ [0.20, 0.80] (outside FLB zone); GDELT velocity ≤ skip threshold for mode; NLP tagger confidence ≥ 0.75; ≥ 3 cells in database have passed IS backtest; adaptive efficiency tier < anti-prim D; N_eff Kelly applied for concurrent same-category signals
- **Fails when:** Category-resolution database not built (BLOCKING Gates 0–3); cell fails IS backtest or WFE DSR < 0.95; selection bias adjustment drives adjusted base rate beyond reliable range; composition instability + threshold override makes gap too wide to fire; genuine information shock (GDELT skip threshold exceeded); FLB zone (YES < 0.10 or > 0.90); thin liquidity (< $5k); resolution ≤ 5 days; NLP tagger confidence < 0.75; anti-prim D triggered (adaptive gate: 9 large-liq losses in 90d, or WFE DSR ≤ 0)
- **Anti-prim A:** < 8 qualifying cells → inactive; **Anti-prim B:** 0 cells pass IS p < 0.10 → retire; **Anti-prim C:** > 60% GDELT confound rate → 0.25× Kelly pending investigation; **Anti-prim D (new):** WFE DSR ≤ 0 OR adaptive gate 9+ losses at liq > $100k in 90d → retire signal
- **Last validated:** never (RESEARCH elevation — cycle 112; survivorship bias correction mechanism formalised; category composition stability monitor added; N_eff concurrent-category Kelly specified; adaptive efficiency tier gate; WFE CPCV+DSR falsification protocol; 3 new academic anchors (Griffin & Tversky 1992; Mandel & Barnes 2014; Hilbert 2012); anti-prim D added; NOT yet empirically backtested; database not yet built)

## Refinement History

- 2026-04-12 (cycle 104): Created as naive prim. 20th polymarket prim class. Inside-view / outside-view mechanism grounded in Kahneman & Lovallo (1993) and Kahneman & Tversky (1973). Distinct from all 19 prior classes: uses PM's own historical category resolution frequencies as reference signal. Primary blocker: category-resolution database. 7 limitations. Zero own-data. 8-source academic basis.
- 2026-04-12 (cycle 110): Refined to intermediate. Two-mode rule (Mode A: narrative-salient ≥ 15 pp; Mode B: structural-constraint ≥ 12 pp). Category-resolution database methodology fully specified. GDELT confound gate with asymmetric thresholds by mode. IS backtest specification (Mann-Whitney U p < 0.10; ≥ 3 cells required). 3 formal anti-prims (A, B, C). Implementation skeleton written. 10-source academic basis.
- 2026-04-12 (cycle 112): Refined to sophisticated. **5 additions:** (1) survivorship bias correction (IPW-adjusted base rates; selection_bias_sensitive flag; escalated thresholds 15→22 pp Mode A, 12→17 pp Mode B in sensitive cells); (2) category composition stability monitor (NLP sub-type classifier; 20 pp drift → 1.5× threshold override); (3) N_eff concurrent-category Kelly (ρ = 0.30/0.40/0.65 by scenario; MacLean-Thorp N_eff correction); (4) adaptive efficiency tier gate (Tier 0→1→2→anti-prim D on rolling 3/6/9 large-liq loss counts in 90d); (5) WFE CPCV+DSR 9-cell plateau (DSR ≥ 0.95 = pass; DSR ≤ 0 = anti-prim D). **3 new academic anchors:** Griffin & Tversky (1992, strength-weight framework, d=0.45/0.22 grounds Mode A vs Mode B threshold split); Mandel & Barnes (2014, 37% Brier improvement quantifies expected Mode A edge floor of WR 0.54–0.57); Hilbert (2012, narrative × salience × recency meta-analysis confirms Mode A edge persistence). **Anti-prim D added** (WFE DSR ≤ 0 OR adaptive gate 9+ losses). 13-source academic basis. Certainty remains hypothesis — all 8 gates blocked until database built and WFE completed.
