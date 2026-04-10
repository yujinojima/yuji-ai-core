# Logging, Review & Escalation Protocol

**Effective:** 2026-04-07
**Owner:** Tron (Orchestrator)
**Monitor:** Behaviour Manager

## Core Rule

No significant work is considered complete unless it has been:
1. Logged to `ai-core/logs/`
2. Reviewed (Application Review)
3. If coding-related: reviewed by both Application Review AND Director Review

## Review Chain

```
Agent Work → Log → Application Review → Director Review (if code) → Complete
                                    ↓
                          Behaviour Manager monitors,
                          links to prior implementations,
                          assigns score deltas
```

## Log Files

| File | Purpose |
|------|---------|
| `agent-events.jsonl` | Task lifecycle events (assigned, started, completed, blocked) |
| `review-events.jsonl` | Review submissions, passes, failures |
| `score-adjustments.jsonl` | Continuous improvement scoring |
| `regressions.jsonl` | Regression tracking and links |
| `decisions.jsonl` | Architecture, design, scope decisions |
| `projects/<name>.jsonl` | Per-project event streams |

## JSONL Format

Required fields per event:
- `timestamp`, `agent`, `role`, `project`, `task_id`, `feature_id`
- `related_feature_id`, `action_type`, `summary`, `details`
- `code_related`, `review_status`
- `application_review_required`, `director_review_required`
- `previous_version`, `current_version`, `score_delta`, `status`

## Coding-Related Escalation

Any work marked `code_related: true` automatically requires:
- `application_review_required: true`
- `director_review_required: true`

This includes: frontend, backend, scripts, config, infrastructure, data model, auth, automation, test, and integration changes.

## Score Deltas

| Event | Delta |
|-------|-------|
| Failed implementation review | -5 |
| Regression introduced | -10 |
| Fix resolves prior regression | +8 |
| Repeated same mistake | -12 |
| Strong improvement, stable outcome | +10 |

## Agent Compliance

All agents must:
- Log significant actions, decisions, changes, errors, completions
- Submit work for review before marking complete
- Include traceability to previous versions where applicable
- Never mark coding-related work complete with only self-review

## Enforcement

Tron enforces:
- Flag unlogged completions
- Reject coding work without dual review
- Escalate repeat non-compliance to Behaviour Manager
- Require traceability corrections
- Reject vague or incomplete logs
