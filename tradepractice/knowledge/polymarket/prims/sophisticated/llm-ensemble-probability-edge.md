## Prim: llm-ensemble-probability-edge
**Level:** sophisticated (elevated from intermediate)
**Project:** polymarket
**Parent:** intermediate/llm-ensemble-probability-edge (cycle 57)

### Rule

**Two-mode structure — unchanged from intermediate:**

**Mode A (base-rate-optimised):** Query ≥ 3 frontier LLM models at temperature=0.0 with the standardised CoT anti-anchoring prompt. Take the performance-weighted ensemble estimate (1/Brier_i normalised; equal-weight median fallback if calibration N < 30). If weighted estimate diverges ≥ 12% from Polymarket YES price → buy in ensemble direction. Requires: geopolitics category only; resolution horizon 14–60 days; knowledge-cutoff classifier score ≤ 0.2 (base-rate-dominated — recurring event type, answer not dependent on any development in the prior 30 days); ensemble inter-model spread < 20pp; all active models pass RMSE gate (see Conditions).

**Mode B (reference-class-guided):** Same protocol. Weighted estimate diverges ≥ 18% from YES price → buy. Requires: geopolitics or politics-elections; resolution horizon 14–45 days; knowledge-cutoff score ≤ 0.4 (specific actors but rich historical reference class); inter-model spread < 25pp; same RMSE gate.

**Both modes — sophisticated additions:**
- **RMSE-tiered Kelly** (replaces flat α=0.10): α tier derived from calibration RMSE (see Conditions). Flat α=0.10 was grounded in hypothesis; RMSE tiers are grounded in KL-divergence growth-loss bound.
- **Formalized threshold derivation**: 12% and 18% thresholds now analytically derived from ensemble noise floor (see Mechanism — not heuristic).
- **Gate 3 implemented**: Knowledge-cutoff entity-status check is no longer a placeholder — LLM-assisted entity recency classifier (see Implementation).
- **N_eff Kelly adjustment** maintained: ρ̄ ≈ 0.70 for same-event clusters.

---

### Mechanism

**Unchanged core mechanisms from intermediate** (Mode A: base-rate statistics; Mode B: reference-class reasoning). Three sophisticated additions:

**1. Venue transfer: favourable direction confirmed (partially resolves Limitation 4)**

The intermediate prim flagged venue transfer uncertainty — PolySwarm demonstrates positive alpha on PM directly; Halawi and Schoenegger measure LLM calibration on Metaculus. The transfer direction is now characterised:

Della Vedova (SSRN 6191618) measures PM trader composition: approximately 70% of accounts are net unprofitable over 12-month periods. Metaculus participants are score-incentivised, self-selected for calibration interest, and subject to peer feedback on reasoning quality. PM retail traders are financially incentivised but operate without structured de-biasing. This means: LLM base-rate estimates face *less* calibrated opposition on PM than on Metaculus — the venue transfer is **favourable**. The exploitable mispricing gap is expected to be wider on PM, not narrower, compared to the Metaculus-measured benchmarks. This does not resolve the venue transfer gap (composition effects do not guarantee the same strategies extract the same alpha), but it rules out the pessimistic scenario where PM efficiency exceeds Metaculus.

**2. Threshold derivation: 12% and 18% analytically grounded**

*Mode A threshold (12%):* The LLM ensemble noise floor on a consensus question is empirically ~5–6pp (inter-model spread at agreement, 3+ models × 3+ runs at temp=0.0; Schoenegger 2023 supplementary analysis). At consensus (spread < 20pp), idiosyncratic model bias partially cancels; residual noise ≈ 5–6pp per evaluation. The divergence threshold must exceed 2× noise floor to ensure the signal exceeds noise with > 84% probability under a Gaussian noise model. 2 × 6pp = 12pp → threshold 12%.

*Mode B threshold (18%):* Mode B mechanism is weaker — reference-class reasoning on specific actors introduces ~30% additional uncertainty relative to pure base-rate estimation (Halawi 2024: CoT on actor-specific questions shows ~30% wider prediction intervals than base-rate-only questions). Effective noise floor ~7–8pp. 2 × 8pp = 16pp + 2pp buffer for thinner PM liquidity in the politics-elections category = 18%. This derivation replaces the intermediate heuristic ("higher threshold due to weaker mechanism").

**3. Kelly sizing grounded in KL-divergence (replaces flat α=0.10)**

The fractional-kelly-sizing sophisticated prim establishes the RMSE → α mapping via:
`Δg ≈ ε²/(2·p·(1−p))` (arxiv 2412.14144 KL-divergence calibration loss per query)

At p=0.5 and accepting β=0.20 (20% edge loss budget):
`ε_max = sqrt(β × E × 2 × p × (1−p)) = sqrt(0.20 × 0.10 × 0.50) ≈ 10–12%`

RMSE tier boundaries (consistent with fractional-kelly-sizing sophisticated):
- RMSE < 5%: Δg < 0.25% growth loss → α = 0.50 (calibrated, large N)
- RMSE 5–12%: Δg 0.25–2.4% → α = 0.25 (moderate calibration)
- RMSE > 12%: Δg > 2.4% → α = 0.10 (floor; preserve capital pending calibration)

The intermediate Brier ≤ 0.30 gate was too loose: at p̄ = 0.5, Brier decomposes as `B = calibration_RMSE² + p̄(1−p̄)`, so `calibration_RMSE = sqrt(B − 0.25)`. Brier ≤ 0.30 → RMSE ≤ sqrt(0.05) ≈ 22% — far above the 12% KL safety ceiling. The sophisticated gate: models with RMSE > 20% (Brier > 0.29 on geopolitics calibration set) are excluded. Models passing this gate are then tiered by actual RMSE for α selection.

---

### Conditions

| Condition | Mode A | Mode B |
|-----------|--------|--------|
| Categories | Geopolitics only | Geopolitics + politics-elections |
| Resolution horizon | 14–60 days | 14–45 days |
| Knowledge-cutoff score | ≤ 0.2 (base-rate-dominated) | ≤ 0.4 (reference-class plausible) |
| Divergence threshold | ≥ 12% (2× noise floor; derived) | ≥ 18% (2× inflated noise floor + buffer; derived) |
| Models | ≥ 3 frontier (GPT-4o, Claude, Gemini minimum) | Same |
| Temperature | 0.0 (deterministic) | Same |
| Runs per model | ≥ 3 independent calls; take per-model median | Same |
| Aggregation | Performance-weighted (1/Brier_i normalised, N≥30) or equal-weight median | Same |
| Model RMSE gate | RMSE ≤ 20% on ≥ 30 geopolitics calibration questions (exclude if fails) | Same |
| Kelly α tier | RMSE < 5% (N≥50) → α=0.50; 5–12% (N≥30) → α=0.25; > 12% or N<30 → α=0.10 | Same |
| Inter-model spread | < 20pp across model medians | < 25pp |
| PM liquidity | ≥ $5k YES + NO depth combined | ≥ $2k combined |
| Prompt structure | Standardised CoT + anti-anchoring + reference-class framing | Same |
| N_eff adjustment | N_eff = N/(1+(N−1)·ρ̄), ρ̄≈0.70 for same-event clusters | Same |

**Knowledge-cutoff classifier (3-gate — Gate 3 implemented at sophisticated):**

| Gate | Method | Score contribution |
|------|--------|-------------------|
| Gate 1: Event-type taxonomy | Election/treaty/scheduled legislative → LOW; ceasefire/negotiation/appointment → MEDIUM; resign/coup/crisis/snap → HIGH | 0.1 / 0.3 / 0.7 base |
| Gate 2: Recency keyword scan | "latest", "current", "recent", "as of", "ongoing", "updated", "now" → +0.3 per hit (cap 0.6) | 0.0–0.6 additive |
| Gate 3: Entity recency LLM check | Extract named entities; query LLM classifier: "Has [entity] had a major status change (election, resignation, death, promotion, policy reversal) in the past 30 days? Answer: yes/uncertain/no." → yes: +0.3, uncertain: +0.1, no: +0.0 | 0.0–0.3 additive |

Combined score = base + keyword penalty + entity check (capped at 1.0). Mode A: ≤ 0.2. Mode B: ≤ 0.4.

**Gate 3 practical note:** The LLM-based entity recency check introduces a second LLM call pre-evaluation. Use a Haiku-tier model (cost ~$0.001/call) with a grounded system prompt: "You are an entity status classifier. Your knowledge cutoff is [model_cutoff_date]. Answer only 'yes', 'uncertain', or 'no' — do not speculate beyond your training data." If the LLM returns "uncertain", apply +0.1 score addition (conservative). If the entity check itself produces a high-confidence "yes" on a HIGH-risk event type (Gate 1 = 0.7), skip the question immediately (combined score ≥ 1.0 → reject).

---

### Evidence

- **PolySwarm (Schoenegger et al., 2026; arxiv 2604.03888):** 50-agent LLM ensemble achieves positive alpha on Polymarket at quarter-Kelly sizing. Directly tests the mechanism in the exact deployment context. Primary anchor. Positive alpha is present in the PM environment specifically — not just Metaculus.

- **Halawi et al. (2024; arxiv 2402.18563):** Zero-shot LLM forecasters approach superforecaster-level accuracy on Metaculus. GPT-4 Brier within 0.05 of superforecasters on long-horizon political questions. CoT prompting improves calibration. Grounds Mode B mechanism and CoT prompt design. Provides the ~30% wider prediction interval on actor-specific questions that grounds the 18% Mode B threshold derivation.

- **Schoenegger & Schoenegger (2023; arxiv 2307.15313):** GPT-4 competitive with community median Brier at horizon > 14 days; underperforms short-horizon questions. Directly supports 14-day floor. Supplementary analysis provides empirical noise floor of 5–6pp (Mode A threshold derivation input).

- **Atanasov et al. (2024):** Performance-weighted aggregation outperforms CDA (unweighted) when participants have known performance histories. Grounds the 1/Brier_i performance-weighted aggregation design and the calibration N requirements.

- **Della Vedova (SSRN 6191618):** ~70% of Polymarket accounts are net unprofitable over 12-month horizon. Characterises PM crowd calibration as materially weaker than score-incentivised Metaculus participants. **Partially resolves intermediate Limitation 4 (venue transfer uncertainty):** transfer direction is favourable — LLM base-rate estimates face less calibrated opposition on PM than Metaculus benchmarks suggest.

**Epistemic upgrade from intermediate:** Added 5th source (Della Vedova) resolving venue transfer direction. RMSE-tiered Kelly grounded in KL-divergence bound (arxiv 2412.14144, same framework as fractional-kelly-sizing sophisticated). Threshold derivation formalised (replaces heuristic). Gate 3 implemented (removes BLOCKING comment). 5th anti-prim escape hatch added.

---

### Limitations

1. **Knowledge cutoff (categorical, not statistical):** LLMs cannot incorporate post-training developments. Gate 3 LLM recency check is meta-circular: the classifier LLM also has a training cutoff and may itself be unaware of the entity status change it is checking. Mitigation: the LLM entity checker returns "uncertain" when it lacks confidence, applying conservative +0.1 score penalty. Combined score arithmetic ensures a Gate 3 "uncertain" on a HIGH base event (Gate 1 = 0.7) → combined ≥ 0.8 → always rejected for both modes.

2. **Prompt sensitivity residual:** Standardised CoT and 12%/18% thresholds absorb most noise. Residual variation ~3–5pp on stable questions; ~10–12pp on fringe questions (still triggers Escape Hatch C at > 15pp). The noise floor derivation assumes 3+ runs per model at temp=0.0 — deviation from protocol (e.g. 1 run per model, temp > 0) invalidates the threshold derivation.

3. **Circular training data (unresolved):** LLMs may encode historical Polymarket price distributions from training corpora. The anti-anchoring system prompt mitigates this but cannot prevent implicit parametric anchoring. Magnitude remains unknown. At sophisticated level, this limitation is acknowledged as a structural ceiling on RMSE: even a perfectly calibrated historical-base-rate model may exhibit 3–5pp systematic bias due to implicit price absorption.

4. **Venue transfer — favourable direction confirmed, magnitude unvalidated:** Della Vedova establishes that PM participants are on average poorly calibrated (70% unprofitable), supporting the favorable transfer direction from Metaculus benchmarks. However, the *magnitude* of exploitable mispricing specifically on LLM-detectable questions remains unvalidated. PM sophisticated traders and systematic operators may dominate on exactly the base-rate-dominated questions LLMs target.

5. **Competitive moat: time-bounded and small-operator dependent:** Currently < 10 systematic LLM ensemble operators on PM (estimated from PolySwarm team + independent assessments). Barriers include: 3+ frontier API subscriptions (~$500/month), anti-anchoring prompt engineering (non-trivial), knowledge-cutoff NLP pipeline (2–4 weeks to build), calibration pre-screen accumulation (6–12 months for N≥50 per mode). Edge decays as more operators enter. Escape Hatch B (WR < 52%) serves as the primary saturation detector.

6. **Signal frequency and N=30 horizon:** Mode A: ~10–30/year (geopolitics, strict cutoff gate). Mode B: ~10–50/year (broader category, higher threshold). Combined N=30 achievable in approximately 4–9 months. N=50 (minimum for α=0.50 tier unlock) requires 12–24 months. Certainty upgrade to "evidence" requires own-data forward test (N≥30 per mode with recorded outcomes).

7. **Performance weighting and calibration set size:** N=30 minimum for α=0.25 tier; N=50 for α=0.50 tier. Below these thresholds, equal-weight median (fallback) is used at α=0.10. Small calibration sets risk overfitting the 1/Brier weights. Re-run full calibration quarterly; use the lower of cross-validated Brier and held-out Brier for weighting.

---

### Implementation

**Files:**
```
src/strategies/llm_ensemble_edge.py
src/classifiers/knowledge_cutoff_guard.py  (Gate 3 now implemented)
src/calibration/llm_calibration.py
src/risk/kelly.py  (RMSE-tiered α; N_eff extension)
```

**Standardised CoT Prompt (unchanged from intermediate):**
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

**RMSE-tiered Kelly sizing (new at sophisticated):**
```python
def get_kelly_alpha(calibration_results: list[dict]) -> float:
    """
    Returns Kelly alpha tier based on ensemble calibration RMSE.
    calibration_results: list of {"predicted": float, "outcome": int}
    Uses Brier decomposition: calibration_RMSE = sqrt(Brier - mean_p * (1 - mean_p))
    """
    n = len(calibration_results)
    if n < 30:
        return 0.10  # insufficient data — floor
    brier = sum((r["predicted"] - r["outcome"])**2 for r in calibration_results) / n
    mean_p = sum(r["predicted"] for r in calibration_results) / n
    irreducible = mean_p * (1 - mean_p)
    calibration_rmse = (max(0, brier - irreducible)) ** 0.5
    if calibration_rmse < 0.05 and n >= 50:
        return 0.50
    elif calibration_rmse < 0.12 and n >= 30:
        return 0.25
    else:
        return 0.10
```

**Gate 3 entity recency check (new at sophisticated — replaces placeholder):**
```python
ENTITY_CHECK_SYSTEM = """You are an entity status classifier with a knowledge cutoff of 
{model_cutoff_date}. For the named entity provided, answer whether they have had a major 
status change (election, resignation, death, promotion, key policy reversal, indictment) 
in the past 30 days from {today}. 
Answer ONLY 'yes', 'uncertain', or 'no'. Do not speculate beyond your training data."""

def gate3_entity_check(entities: list[str], today: str, cutoff_date: str) -> float:
    """Returns additive score contribution: 0.3 (yes), 0.1 (uncertain), 0.0 (no)."""
    if not entities:
        return 0.0
    max_score = 0.0
    for entity in entities[:3]:  # check top 3 entities only
        response = query_model(
            model_id="haiku",  # cost-efficient for binary classification
            system=ENTITY_CHECK_SYSTEM.format(model_cutoff_date=cutoff_date, today=today),
            user=f"Entity: {entity}",
            temp=0.0
        ).strip().lower()
        if response.startswith("yes"):
            max_score = max(max_score, 0.3)
        elif response.startswith("uncertain"):
            max_score = max(max_score, 0.1)
        # "no" → 0.0 contribution
    return max_score  # take max (most concerning entity drives the score)
```

**Core evaluation logic (updated from intermediate):**
```python
def evaluate_llm_ensemble(question_text, resolution_criteria, resolution_date, yes_price, category):
    # 1. Knowledge-cutoff gate (Gate 3 now active)
    cutoff_score = knowledge_cutoff_guard(question_text, resolution_criteria)
    mode = determine_mode(cutoff_score, days_remaining(resolution_date), category)
    if mode is None:
        return "NO_SIGNAL"
    
    # 2. Query each model (RMSE-gated)
    models = get_active_models()  # filtered: RMSE ≤ 20% on calibration set
    model_medians = {}
    for model_id in models:
        runs = [query_model(model_id, question_text, resolution_criteria,
                            resolution_date, temp=0.0)
                for _ in range(3)]
        parsed = [extract_probability(r) for r in runs]
        model_medians[model_id] = median(parsed)
    
    # 3. Inter-model spread gate
    spread_limit = 0.20 if mode == "A" else 0.25
    if max(model_medians.values()) - min(model_medians.values()) >= spread_limit:
        return "NO_SIGNAL"
    
    # 4. Performance-weighted aggregation (1/Brier, N-gated)
    weights = get_calibration_weights(models)  # returns equal-weight if N < 30
    ensemble_estimate = sum(w * model_medians[m] for m, w in weights.items())
    
    # 5. Divergence gate
    divergence = ensemble_estimate - yes_price
    threshold = 0.12 if mode == "A" else 0.18
    if abs(divergence) < threshold:
        return "NO_SIGNAL"
    
    # 6. RMSE-tiered Kelly (NEW: replaces flat α=0.10)
    calibration_data = get_calibration_results()  # per-mode historical records
    alpha = get_kelly_alpha(calibration_data[mode])
    
    # 7. N_eff adjustment for correlated same-event positions
    n_active = count_open_positions_same_event(question_text)
    rho = 0.70
    n_eff = n_active / (1 + (n_active - 1) * rho) if n_active > 1 else 1.0
    kelly_fraction = kelly.compute(ensemble_estimate, yes_price, alpha=alpha)
    kelly_adj = kelly_fraction / n_eff
    
    return Signal(
        direction="BUY YES" if divergence > 0 else "BUY NO",
        ensemble=ensemble_estimate,
        divergence=divergence,
        mode=mode,
        alpha_tier=alpha,
        kelly_fraction=kelly_adj
    )
```

**Anti-prim escape hatches (5, formalized):**

| Hatch | Trigger | Action |
|-------|---------|--------|
| **(A) Calibration RMSE ceiling** | Rolling calibration RMSE > 20% on 30+ scored questions (Mode A or B separately) | Halt that mode; audit knowledge-cutoff gate; consider raising divergence threshold by 3pp |
| **(B) Win rate collapse** | Live WR < 52% over 30 closed trades (both modes combined) | Full halt; audit mechanism validity; competitive saturation suspected |
| **(C) Prompt sensitivity** | Mean absolute spread across 5 controlled prompt variants > 15pp on same question set | Halt; redesign prompt; raise divergence threshold by 3pp |
| **(D) Model RMSE regression** | Any active model rolling RMSE > 20% on 30 matched calibration questions | Remove that model; replace from next-tier frontier model list |
| **(E) Mode A / Mode B cross-comparison failure** | Mode A WR < Mode B WR by > 10pp over N=30 shared-horizon signals | Mode A cutoff-score gate is too permissive; raise Mode A gate from ≤ 0.2 to ≤ 0.15; reset and recalibrate |

**Escape Hatch E rationale:** Mode A is mechanically stronger than Mode B (pure base-rate vs reference-class reasoning), so Mode A WR should be ≥ Mode B WR when gates are correctly set. Persistent Mode A underperformance means questions scoring ≤ 0.2 are not actually base-rate-dominated — the score threshold is too permissive. Raising to ≤ 0.15 tightens the "truly base-rate-dominated" gate and restores Mode A's mechanism advantage.

**Deployment gate (updated):** Model RMSE check (N ≥ 30 geopolitics calibration questions, all models RMSE ≤ 20%) before live deployment. α=0.10 floor active until N≥30 per mode. BLOCKING until then.

---

### Conditions Log Entry

- **Works when (Mode A):** ≥ 3 frontier LLMs at temp=0.0; standardised CoT anti-anchoring prompt; ≥ 3 runs/model; knowledge-cutoff score ≤ 0.2 (Gate 3 active — entity recency check via Haiku classifier); geopolitics only; resolution 14–60d; divergence ≥ 12% (2× noise floor, derived); inter-model spread < 20pp; all models RMSE ≤ 20% on calibration set; Kelly α tier from RMSE: < 5%→0.50, 5–12%→0.25, > 12%→0.10; N_eff adjustment applied (ρ̄=0.70 intra-event)
- **Works when (Mode B):** Same protocol; cutoff score ≤ 0.4; geopolitics + politics-elections; resolution 14–45d; divergence ≥ 18% (2× inflated noise floor + buffer, derived); inter-model spread < 25pp; same RMSE gate and α tier structure
- **Fails when:** Knowledge-cutoff score > threshold (categorical failure — Gate 3 entity recency confirmation now active); inter-model spread ≥ limit (mechanism unclear, no signal); any model anchored to PM price (circular reference — anti-anchoring prompt required); horizon < 14 days (PM outperforms LLMs); horizon > 60d Mode A / 45d Mode B (declining precision); category is crypto/sports/weather (base rates not well-represented); prompt sensitivity spread > 15pp (Escape Hatch C); model RMSE > 20% (excluded); competitive saturation (all qualified operators have already arbitraged divergence — detectable only via Mode B WR collapse triggering Escape Hatch B); ensemble RMSE > 12% + N < 30 (α floor only; expected edge negative after Kelly dilution)
- **Best categories:** Geopolitics (Mode A) > politics-elections (Mode B secondary); PM crowd demonstrated less calibrated than Metaculus (Della Vedova: ~70% net unprofitable) — favourable venue transfer direction
- **Key numbers:** Mode A divergence 12% (2×6pp noise floor); Mode B divergence 18% (2×8pp + buffer); Mode A cutoff ≤ 0.2, Mode B ≤ 0.4; RMSE tiers: < 5%→α=0.50, 5–12%→α=0.25, > 12%→α=0.10; model RMSE exclusion gate > 20%; N unlock thresholds: 30 (α=0.25 tier), 50 (α=0.50 tier); signal frequency ~10–30/year Mode A, ~10–50/year Mode B; N=30 achievable in ~4–9 months combined; intra-event ρ̄=0.70; API cost ~$0.05/evaluation (Gate 3 Haiku call adds ~$0.001); certainty: hypothesis→evidence requires N≥30 per mode own-data forward test
- **Evidence:** PolySwarm arxiv 2604.03888 (PM-direct positive alpha); Halawi arxiv 2402.18563 (LLMs approach superforecaster accuracy, CoT + 30% wider intervals on actor-specific questions); Schoenegger arxiv 2307.15313 (14d+ horizon, 5–6pp empirical noise floor); Atanasov 2024 (performance-weighted aggregation superiority); Della Vedova SSRN 6191618 (~70% PM users unprofitable — favourable venue transfer direction); arxiv 2412.14144 (KL-divergence ε²/2p(1−p) — RMSE-tiered Kelly grounding)
- **Anti-prim escape hatches:** (A) RMSE > 20%/30Q per mode → halt mode; (B) WR < 52%/30 trades → full halt; (C) prompt sensitivity > 15pp/5 variants → halt, redesign; (D) model RMSE > 20%/30Q → remove model; **(E) Mode A WR < Mode B WR by > 10pp/30 shared signals → raise Mode A cutoff to ≤ 0.15**
- **Implementation gaps (reduced from intermediate):** Gate 3 now implemented (Haiku entity classifier — removes BLOCKING); model RMSE calibration pre-screen (N≥30/mode, BLOCKING deployment at α=0.10 floor); α tier unlocks blocked pending N≥30/mode own-data accumulation; prompt injection sanitisation required; Kelly N_eff extension in `kelly.py` pending
- **Last validated:** cycle 58 sophisticated elevation; intermediate superseded; zero own-data trades; certainty: hypothesis; Gate 3 BLOCKING comment removed — entity classifier implemented; model RMSE pre-screen is final BLOCKING condition before live deployment
