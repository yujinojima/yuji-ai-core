## Prim: llm-ensemble-probability-edge
**Level:** intermediate
**Project:** polymarket
**Parent:** naive (cycle 56)

### Rule

**Two-mode structure based on question type and knowledge-cutoff safety:**

**Mode A (base-rate-optimised):** Query ≥ 3 frontier LLM models at temperature=0.0 with the standardised CoT prompt (see Implementation). Take the performance-weighted ensemble estimate (or median fallback if no calibration data). If weighted estimate diverges ≥ 12% from Polymarket YES price → buy in ensemble direction. Requires: geopolitics category only; resolution horizon 14–60 days; knowledge-cutoff classifier score ≤ 0.2 (base-rate-dominated question — recurring event type with long historical precedent, answer not dependent on any development in the prior 30 days); ensemble inter-model spread < 20pp; all active models Brier ≤ 0.30 on calibration test set (20+ questions).

**Mode B (reference-class-guided):** Same query protocol. Weighted estimate diverges ≥ 18% from YES price → buy. Requires: geopolitics or politics-elections category; resolution horizon 14–45 days; knowledge-cutoff classifier score ≤ 0.4 (question references specific actors or outcomes but historical analogies are rich enough that LLM training covers the reference class); ensemble inter-model spread < 25pp; same model Brier gate.

**Both modes:** α = 0.10 Kelly floor (uncalibrated). N_eff Kelly adjustment for thematically correlated bets. Anti-anchoring prompt structure mandatory (do not expose models to YES price). Model calibration pre-screen required before live deployment (20 matched historical questions with known outcomes per mode).

---

### Mechanism

LLM frontier models encode two distinguishable types of probabilistic knowledge from training corpora:

**1. Base-rate statistics (Mode A mechanism):** Training data over decades of geopolitical and political outcomes provides implicit reference-class frequency tables — what fraction of incumbent leaders survive confidence votes, what fraction of peace negotiations produce ceasefires within 90 days, what fraction of disputed elections produce the initial front-runner's victory. For recurring event types, LLMs function as compressed historical databases queried via natural language. Critically, this knowledge is **anchoring-free** relative to Polymarket participants who start from the current contract price and adjust. When a crowd of independently-sampled LLM runs produces a consensus estimate on a base-rate-dominated question, the ensemble median reflects historical reference-class frequencies with partial idiosyncratic bias cancellation.

**2. Reference-class reasoning (Mode B mechanism):** For questions involving specific named actors, LLMs can draw on historical analogies to comparable actors/situations even when the exact current context is uncertain. A model can estimate "probability that incumbent president wins re-election" by drawing on its distributional training across hundreds of historical precedents, applying soft conditioning on the question's descriptive framing without requiring current poll data. This is weaker than Mode A (current information matters more) but still exploitable at higher divergence thresholds.

**Why divergence creates edge:** Polymarket participants anchor to the current contract price (Kahneman-Tversky anchoring; see no-event-time-decay-fade prim). For questions with long horizons and stable base rates, PM crowds may over-weight recent framing effects (news, social media sentiment) and under-weight historical base rates. LLM ensemble estimates, being drawn from parametric training data without exposure to current PM prices, systematically differ from PM crowds on questions where anchoring bias distorts crowd estimates most. The divergence threshold acts as a joint filter for: (a) cases where LLM base-rate estimation is informative, and (b) cases where PM crowd is biased enough to create exploitable mispricing.

**Mechanism limitations acknowledged at intermediate level:** The mechanism works only when the correct probability is primarily determined by information that existed before the model's training cutoff. The knowledge-cutoff classifier formalises this constraint: Mode A requires it to be near-certain (score ≤ 0.2), Mode B requires it to be plausible (score ≤ 0.4). The mechanism fails categorically — not statistically — when the answer depends on post-cutoff developments.

**Distinction from related prims maintained:**
- `superforecaster-consensus-lead`: Human experts (always current, slow supply, 24h update lag); LLM ensemble (always available, sub-minute, knowledge-cutoff bounded). Complementary, not substitutable.
- `ensemble-forecast-edge`: Physical-process NWP models (physics-based, domain-specific); LLM ensemble (parametric pattern matching, domain-general).
- `no-event-time-decay-fade`: Exploits anchoring bias at short horizons (≤ 21 days) via actuarial mis-pricing; LLM ensemble exploits base-rate mis-estimation at medium horizons (14–60 days) via reference-class divergence.

---

### Conditions

| Condition | Mode A | Mode B |
|-----------|--------|--------|
| Categories | Geopolitics only | Geopolitics + politics elections |
| Resolution horizon | 14–60 days | 14–45 days |
| Knowledge-cutoff score | ≤ 0.2 (base-rate-dominated) | ≤ 0.4 (reference-class plausible) |
| Divergence threshold | ≥ 12% from YES price | ≥ 18% from YES price |
| Models | ≥ 3 frontier (GPT-4o, Claude, Gemini minimum) | Same |
| Temperature | 0.0 (deterministic) | Same |
| Runs per model | ≥ 3 independent calls; take median | Same |
| Aggregation | Performance-weighted (if calibration data); fallback: equal-weight median | Same |
| Model gate | Brier ≤ 0.30 on ≥ 20 calibration questions | Same |
| Inter-model spread | < 20pp across model medians | < 25pp |
| PM liquidity | ≥ $5k YES + NO depth combined | ≥ $2k combined |
| Prompt structure | Standardised CoT + anti-anchoring + reference-class framing | Same |
| Kelly floor | α = 0.10 (uncalibrated) | α = 0.10 (uncalibrated) |
| N_eff adjustment | Apply correlated-bet adjustment for same-event clusters (ρ̄ ≈ 0.7) | Same |

**Knowledge-cutoff classifier (3-gate):**

| Gate | Method | Score contribution |
|------|--------|-------------------|
| Event-type taxonomy | Election/treaty/scheduled legislative ← LOW; conflict outcome/negotiation ← MEDIUM; crisis/appointment/sudden event ← HIGH | 0.1 / 0.3 / 0.7 base |
| Recency keyword scan | "latest", "current", "recent", "as of", "ongoing", "updated" → +0.3 per hit (cap 0.6) | 0.0–0.6 additive |
| Entity status check | Key named entity had major status change in prior 30 days? (yes: +0.3, uncertain: +0.1, no: +0.0) | 0.0–0.3 additive |

Combined score = base + keyword penalty + entity check (capped at 1.0). Mode A: ≤ 0.2. Mode B: ≤ 0.4.

---

### Evidence

- **PolySwarm (Schoenegger et al., 2026; arxiv 2604.03888):** 50-agent LLM ensemble achieves positive alpha on Polymarket, benchmarked at quarter-Kelly sizing. Directly tests the mechanism in the exact deployment context. **Primary anchor for PM-specific LLM ensemble trading.** Mode A mechanism most directly supported here (base-rate-dominated prediction markets).

- **Halawi et al. (2024; arxiv 2402.18563):** Zero-shot LLM forecasters approach superforecaster-level accuracy on Metaculus questions. GPT-4 Brier score within 0.05 of human superforecasters on long-horizon political questions. Chain-of-thought prompting improves calibration. Anchor for Mode B reference-class mechanism and for CoT prompt design.

- **Schoenegger & Schoenegger (2023; arxiv 2307.15313):** GPT-4 competitive with community median Brier on Metaculus questions with resolution horizon > 14 days. Underperforms on questions requiring recent information. **Direct empirical support for 14-day horizon floor** and for the knowledge-cutoff safety gate.

- **Atanasov et al. (2024):** Performance-weighted aggregation of human forecasters outperforms CDA (unweighted aggregate) when participants have known performance histories; unweighted aggregation ties CDA on average. Grounds the performance-weighted aggregation design: use calibration pre-screen Brier scores to weight model contributions where data available.

**Epistemic upgrade from naive:** Added 4th source (Atanasov 2024) anchoring the performance-weighted aggregation mechanism. Horizon floor formalised from Schoenegger 2023 evidence (not heuristic). Two-mode structure derived from Halawi 2024 CoT findings (Mode A benefits most from reference-class framing; Mode B requires higher threshold due to reduced mechanism confidence).

---

### Limitations

1. **Knowledge cutoff (categorical, not statistical):** LLMs cannot incorporate post-training developments. The knowledge-cutoff classifier reduces exposure but does not eliminate it. For Mode B, score 0.40 still permits ~40% of the question's probability mass to be cutoff-affected. Certainty ceiling: hypothesis until calibration pre-screen establishes mode-specific Brier benchmarks.

2. **Prompt sensitivity:** Probability estimates shift 5–15pp with minor rephrasing (naive finding). The standardised CoT prompt and divergence thresholds partially absorb this noise. Escape hatch (C) fires if mean absolute spread across 5 controlled variants > 15pp.

3. **Circular training data:** LLMs may have been trained on Polymarket contract data itself, creating implicit price anchoring. Magnitude unknown. Anti-anchoring prompt instruction mitigates but does not resolve this.

4. **Venue transfer uncertainty:** PolySwarm demonstrates positive alpha on PM; Halawi and Schoenegger measure on Metaculus. PM has different trader composition (financially incentivised), different contract types, and different friction (0–7.2% fees). Transfer of accuracy from Metaculus to PM is assumed, not validated.

5. **Performance weighting dependency:** Weighted aggregation requires 20+ calibration questions with known outcomes per mode. Before calibration data accumulates, equal-weight median (fallback) provides lower precision aggregation. Weight estimation adds another parameter to estimate — potential for overfitting if calibration set is small.

6. **Signal scarcity:** Estimated 20–80 qualified signals per year. Mode A more restrictive (geopolitics only, score ≤ 0.2) → ~10–30/year. Mode B broader but higher threshold → ~10–50/year. N=30 requires approximately 1–3 years for Mode A; 6–36 months for Mode B. Certainty upgrade to "evidence" requires own-data forward test.

7. **API cost and operational overhead:** 9 API calls per evaluation (minimum), ~$0.04 per signal, ~$3/year at 80 signals. Cost negligible but operational dependency on 3 API providers. Prompt-injection risk if question text contains adversarial framing (sanitise question input before passing to model).

---

### Implementation

**Files:**
```
src/strategies/llm_ensemble_edge.py
src/classifiers/knowledge_cutoff_guard.py
src/calibration/llm_calibration.py  (new at intermediate)
src/risk/kelly.py  (existing — N_eff extension needed)
```

**Standardised CoT Prompt:**
```python
SYSTEM_PROMPT = """You are a calibrated probability forecaster. Your task is to estimate the 
probability that a binary question resolves YES. Do NOT anchor to market prices or recent news. 
Apply reference-class reasoning from historical base rates only."""

USER_PROMPT_TEMPLATE = """Question: {question_text}
Resolution criteria: {resolution_criteria}
Resolution date: {resolution_date} ({days_remaining} days from today)

Step 1: Identify the most relevant historical reference class. What type of event is this?
Step 2: Estimate the base rate. What fraction of similar events historically resolved YES?
Step 3: Adjust for specific characteristics visible in the question framing only.
Step 4: State your final probability.

Respond in JSON: {{"reasoning": "...", "base_rate": 0.XX, "probability": 0.XX}}"""
```

**Core logic (pseudocode):**
```python
def evaluate_llm_ensemble(question_text, resolution_criteria, resolution_date, yes_price):
    # 1. Knowledge-cutoff gate
    cutoff_score = knowledge_cutoff_guard(question_text, resolution_criteria)
    mode = determine_mode(cutoff_score, days_remaining(resolution_date), category)
    if mode is None:
        return "NO_SIGNAL"  # cutoff score or horizon fails both modes
    
    # 2. Query each model
    models = get_active_models()  # filtered: Brier ≤ 0.30 on calibration set
    model_medians = {}
    for model_id in models:
        runs = [query_model(model_id, question_text, resolution_criteria,
                            resolution_date, temp=0.0) 
                for _ in range(3)]
        parsed = [extract_probability(r) for r in runs]
        model_medians[model_id] = median(parsed)
    
    # 3. Check inter-model spread
    spread_limit = 0.20 if mode == "A" else 0.25
    if max(model_medians.values()) - min(model_medians.values()) >= spread_limit:
        return "NO_SIGNAL"  # no consensus
    
    # 4. Performance-weighted aggregation
    weights = get_calibration_weights(models)  # 1/Brier normalised; fallback: equal
    ensemble_estimate = sum(w * model_medians[m] for m, w in weights.items())
    
    # 5. Divergence gate
    divergence = ensemble_estimate - yes_price
    threshold = 0.12 if mode == "A" else 0.18
    if abs(divergence) < threshold:
        return "NO_SIGNAL"
    
    # 6. N_eff Kelly adjustment
    n_active = count_open_positions_same_event(question_text)
    rho = 0.70  # intra-event correlation estimate
    n_eff = n_active / (1 + (n_active - 1) * rho) if n_active > 1 else 1.0
    kelly_fraction = kelly.compute(ensemble_estimate, yes_price, alpha=0.10)
    kelly_adj = kelly_fraction / n_eff
    
    return Signal(
        direction="BUY YES" if divergence > 0 else "BUY NO",
        ensemble=ensemble_estimate,
        divergence=divergence,
        mode=mode,
        kelly_fraction=kelly_adj
    )
```

**Model calibration pre-screen** (required before live deployment):
```python
# Collect 20+ matched historical questions per mode (known outcomes)
# For each model, compute Brier score = mean((prediction - outcome)^2)
# Reject models with Brier > 0.30
# Weight remaining models by (1/Brier_i) / sum(1/Brier_j)
# Re-run calibration monthly; if any model Brier > 0.30 rolling 20Q → Escape Hatch D
```

**Knowledge-cutoff guard (3-gate implementation):**
```python
def knowledge_cutoff_guard(question_text, resolution_criteria):
    score = 0.0
    
    # Gate 1: Event-type taxonomy
    text = (question_text + " " + resolution_criteria).lower()
    if any(k in text for k in ["election", "vote", "referendum scheduled", "treaty", "summit"]):
        score += 0.1  # LOW risk
    elif any(k in text for k in ["ceasefire", "negotiation", "talks", "appointed", "nominated"]):
        score += 0.3  # MEDIUM risk
    elif any(k in text for k in ["resign", "coup", "crisis", "emergency", "snap"]):
        score += 0.7  # HIGH risk — return immediately
    
    # Gate 2: Recency keyword scan
    recency_keywords = ["latest", "current", "recent", "as of", "ongoing", "updated", "now"]
    hits = sum(1 for k in recency_keywords if k in text)
    score += min(hits * 0.3, 0.6)
    
    # Gate 3: Entity recency (placeholder — requires external lookup)
    # entity_recent_change = lookup_entity_status_change(extract_entities(text), days=30)
    # score += entity_recent_change  # 0.0 / 0.1 / 0.3
    
    return min(score, 1.0)
```

**Anti-prim escape hatches (4, formalized):**

| Hatch | Trigger | Action |
|-------|---------|--------|
| **(A) Calibration failure** | Rolling RMSE > 0.20 on 50 scored questions (Mode A or B separately) | Halt that mode; recalibrate classifier thresholds |
| **(B) Win rate collapse** | Live WR < 52% over 30 closed trades (both modes combined) | Full halt; audit mechanism validity |
| **(C) Prompt sensitivity** | Mean absolute spread across 5 controlled prompt variants > 15pp on same question set | Halt; redesign prompt structure; raise divergence threshold by 3pp |
| **(D) Model Brier regression** | Any active model rolling Brier > 0.30 on 20 matched calibration questions | Remove that model; require replacement from next-tier frontier model list |

**Deployment gate:** Model calibration pre-screen (20 matched historical questions per mode, all models pass Brier ≤ 0.30) must complete before live deployment. BLOCKING.

---

### Conditions Log Entry

- **Works when (Mode A):** ≥ 3 frontier LLMs polled at temperature 0.0 with standardised CoT prompt; ≥ 3 runs per model; performance-weighted ensemble estimate diverges ≥ 12% from PM YES price; knowledge-cutoff classifier score ≤ 0.2 (base-rate-dominated, recurring event type); geopolitics category only; resolution 14–60 days; inter-model spread < 20pp; all models pass Brier ≤ 0.30 calibration gate; no same-event N_eff overextension (ρ̄ adjustment applied)
- **Works when (Mode B):** Same protocol; classifier score ≤ 0.4 (reference-class plausible); geopolitics or politics-elections; resolution 14–45 days; divergence ≥ 18%; inter-model spread < 25pp; same model gate
- **Fails when:** Knowledge-cutoff score > threshold for mode (cutoff blindspot — categorical failure, not statistical); inter-model spread ≥ limit (no LLM consensus, mechanism unclear); any model anchored to PM price (circular reference — anti-anchoring prompt required); horizon < 14 days (PM outperforms LLMs at short horizon, Schoenegger 2023); horizon > 60 days Mode A / 45 days Mode B (declining base-rate precision on distant events); category is crypto/sports/weather (base rates not well-represented in LLM training); prompt sensitivity spread > 15pp (noise floor violation → escape hatch C); ensemble spread ≥ 20pp Mode A / 25pp Mode B (conflicting model estimates — no signal); model Brier > 0.30 calibration gate failed
- **Best categories:** Geopolitics (Mode A primary — elections, conflicts, treaty events; LLMs have richest training); politics-elections (Mode B secondary)
- **Key numbers:** Mode A divergence 12%; Mode B divergence 18%; knowledge-cutoff score ≤ 0.2 (Mode A) / ≤ 0.4 (Mode B); horizon 14–60d (Mode A) / 14–45d (Mode B); model Brier gate ≤ 0.30; calibration pre-screen n ≥ 20/mode; inter-model spread limit 20pp / 25pp; API cost ~$0.04/evaluation; signal frequency ~20–80/year; α=0.10 Kelly floor; intra-event ρ̄ ≈ 0.70 for N_eff adjustment; certainty: hypothesis (PolySwarm positive alpha; zero own-data trades)
- **Evidence:** PolySwarm (arxiv 2604.03888 — 50-agent LLM ensemble positive alpha on PM); Halawi et al. (arxiv 2402.18563 — LLMs approach superforecaster accuracy, CoT improves calibration); Schoenegger (arxiv 2307.15313 — GPT-4 competitive at 14d+ horizon; underperforms short-horizon); Atanasov et al. (2024 — performance-weighted aggregation outperforms CDA for model ensemble weighting)
- **Anti-prim escape hatches:** (A) RMSE > 0.20 / 50 scored questions per mode → halt mode; (B) live WR < 52% / 30 closed trades → full halt; (C) prompt sensitivity spread > 15pp / 5 variants → halt, redesign; (D) model Brier > 0.30 rolling 20 calibration questions → remove model
- **Implementation gaps:** `knowledge_cutoff_guard.py` (Gate 3 entity-status lookup BLOCKING); model calibration pre-screen 20 matched historical questions per mode (BLOCKING deployment); `llm_calibration.py` (Brier weighting module); N_eff extension in `kelly.py`; prompt injection sanitisation in question pre-processing
- **Last validated:** cycle 57 intermediate elevation; naive superseded; zero own-data trades; certainty: hypothesis; Mode A calibration pre-screen BLOCKING live deployment
