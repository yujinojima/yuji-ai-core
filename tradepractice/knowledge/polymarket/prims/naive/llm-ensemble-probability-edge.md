## Prim: llm-ensemble-probability-edge
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule

Query ≥ 3 frontier LLM models (e.g., GPT-4o, Claude 3.5/4, Gemini 1.5/2) at temperature=0.0 for a probability estimate on a Polymarket YES/NO question. Take the median of ≥ 3 independent runs per model, then take the ensemble median across all models. If ensemble median diverges from Polymarket YES price by ≥ 12%, buy in the direction of the ensemble consensus. Restrict to: geopolitics/politics categories, resolution horizon 7–60 days, questions whose answer does not depend on information from the prior 30 days (knowledge-cutoff-safe domains). α=0.10 Kelly floor.

### Mechanism

LLM frontier models encode implicit base-rate statistics from training corpora covering decades of historical outcomes across political, geopolitical, and economic domains. Unlike Polymarket participants who anchor to the current contract price and adjust from it, LLMs produce fresh probability estimates from parametric knowledge — a form of reference-class forecasting without price anchoring. When a crowd of independently-sampled LLM runs produces a consensus estimate, individual model hallucination and idiosyncratic biases partially cancel. The resulting ensemble median may identify systematic mispricings where the PM crowd has over- or under-reacted to recent framing effects.

This mechanism is meaningfully distinct from `superforecaster-consensus-lead` (calibrated human experts, Metaculus/GJP — slower, bounded supply, more current-event aware) and from `ensemble-forecast-edge` (NWP physical-process weather models). LLMs are always available, sub-minute, and scale cheaply but are fundamentally limited by knowledge cutoff and prompt sensitivity.

### Conditions

| Condition | Requirement |
|-----------|-------------|
| Models | ≥ 3 frontier models (GPT-4o, Claude, Gemini minimum) |
| Temperature | 0.0 (deterministic output) |
| Runs per model | ≥ 3 independent calls; take median |
| Ensemble signal | Median of all per-model medians |
| Divergence threshold | ≥ 12% from YES price |
| Category | Geopolitics, politics only |
| Resolution horizon | 7–60 days |
| Knowledge safety | Question answer cannot depend on last-30-day events |
| Sizing | α=0.10 Kelly floor (uncalibrated) |

### Evidence

- **PolySwarm (Schoenegger et al., 2026; arxiv 2604.03888)**: 50-agent LLM ensemble achieves positive alpha on Polymarket, benchmarked at quarter-Kelly sizing. Primary citation for PM-specific LLM ensemble trading. Paper directly tests the mechanism in the exact deployment context.
- **Halawi et al. (2024; "Approaching Human-Level Forecasting", arxiv 2402.18563)**: Zero-shot LLM forecasters approach superforecaster-level accuracy on Metaculus questions; GPT-4 Brier score within 0.05 of human superforecasters on long-horizon political questions.
- **Schoenegger & Schoenegger (2023; arxiv 2307.15313)**: LLMs as forecasters on Metaculus; GPT-4 competitive with community median Brier score on questions with resolution horizon > 14 days. Underperforms on questions requiring recent information.

### Limitations

1. **Knowledge cutoff**: LLMs have a training cutoff and cannot incorporate recent developments. For any question where the answer has changed in the prior 30 days, the ensemble estimate will be systematically wrong in the direction of the pre-cutoff state. This is the single largest failure mode — not a statistical effect but a categorical error.
2. **Prompt sensitivity**: Probability estimates shift 5–15 percentage points with minor rephrasing. The 12% divergence threshold partially absorbs this noise but does not eliminate it.
3. **Circular training data risk**: LLMs may have been trained on Polymarket data itself, creating implicit price anchoring. Magnitude unknown.
4. **No own-data**: Zero own trades. Certainty level is hypothesis. The 12% threshold is heuristic, not derived from own calibration.
5. **API cost and latency**: 3 models × 3 runs = minimum 9 API calls per signal evaluation. Not suitable for real-time or high-frequency use.
6. **Calibration unknown on PM**: PolySwarm positive alpha (2604.03888) is the only PM-direct evidence. Halawi and Schoenegger papers measure on Metaculus, not Polymarket — venue transfer applies but is unvalidated.

### Implementation

```
src/strategies/llm_ensemble_edge.py
```

Pseudocode:
```python
def evaluate_llm_ensemble(question_text, yes_price):
    estimates = []
    for model in ["gpt-4o", "claude-3-5-sonnet", "gemini-1.5-pro"]:
        runs = [query_model(model, question_text, temp=0.0) for _ in range(3)]
        estimates.append(median(runs))
    ensemble_median = median(estimates)
    divergence = ensemble_median - yes_price
    if abs(divergence) >= 0.12:
        return "BUY YES" if divergence > 0 else "BUY NO"
    return "NO_SIGNAL"
```

Dependencies: OpenAI, Anthropic, Google Generative AI SDKs; `src/risk/kelly.py` (α=0.10 floor).

### Conditions Log Entry

- **Works when:** ≥ 3 frontier LLMs polled at temperature 0.0; ≥ 3 runs per model; ensemble median diverges ≥ 12% from PM YES price; question is knowledge-cutoff-safe (answer did not change in prior 30 days); geopolitics or politics category; resolution 7–60 days
- **Fails when:** Question answer depends on last-30-day events (cutoff blindspot — largest failure mode); prompt phrasing shifts ensemble estimate > 5pp (noise floor violation); models trained on PM data anchor to PM price (circular reference); ensemble spread > 20pp across models (no consensus); category is crypto/sports/weather (base rates poorly represented in training)
- **Key numbers:** Divergence threshold 12% (heuristic); models minimum 3; runs minimum 3 per model; resolution 7–60 days; α=0.10 Kelly floor; certainty: hypothesis (PolySwarm positive alpha primary anchor; zero own trades)
- **Evidence:** PolySwarm (arxiv 2604.03888, 2026 — 50-agent LLM ensemble positive alpha on PM); Halawi et al. (arxiv 2402.18563, 2024 — LLMs approaching superforecaster accuracy); Schoenegger (arxiv 2307.15313, 2023 — GPT-4 competitive with community median Brier on 14d+ horizon questions)
- **Last validated:** cycle 56 new prim creation; zero own-data trades; naive level only; knowledge-cutoff gate is mandatory pre-condition before any signal is evaluated
