# Review Workflow Protocol v1

## Review Workflow

### Step 1 — Agent performs work.
### Step 2 — Agent logs the work to `ai-core/logs/`.
### Step 3 — If the work is significant (changed behaviour, affected features, fixed a bug, introduced a risk, or altered code/config), it must be submitted for review.
### Step 4 — Application Review must review all implementation work affecting functionality, behaviour, UX flow, data handling, or system integration.
### Step 5 — If the work is coding-related, after Application Review it must also go through Director Review.
### Step 6 — Only after required reviews pass can the work be marked complete.
### Step 7 — Behavioural Manager links the change to prior implementations and adjusts score/history.

## Coding-Related Escalation Rule

Any work marked `code_related=true` must automatically require:
- `application_review_required = true`
- `director_review_required = true`

Coding-related work includes: frontend changes, backend changes, scripts, config updates, infrastructure changes, data model changes, auth/session changes, automation logic, test logic, integration logic.

No coding-related task may be marked complete after only self-review.

## Continuous Improvement + Scoring

The Behavioural Manager tracks changes against prior implementations.

When a new change is logged, link it to: previous version, related task, affected feature, known issue or regression source.

### Score Adjustments
- Failed implementation review: -5
- Regression introduced: -10
- Fix successfully resolves prior regression: +8
- Repeated same mistake after prior warning: -12
- Strong improvement with stable outcome: +10

## Enforcement Rules (Tron)

- If an agent completes work without logging it → flag non-compliance
- If coding-related work submitted without both reviews → reject completion
- If agent repeatedly fails to log or follow review protocol → escalate to Behavioural Manager
- If task lacks traceability to prior implementations → request correction
- If logs are inconsistent, incomplete, or too vague → require rewrite
- No silent changes
- No unreviewed coding changes marked done
- No major cross-project decision without a log entry

## Log Files

| File | Purpose |
|------|---------|
| `ai-core/logs/agent-events.jsonl` | All agent work events |
| `ai-core/logs/review-events.jsonl` | Review submissions and outcomes |
| `ai-core/logs/score-adjustments.jsonl` | Behavioural scoring changes |
| `ai-core/logs/regressions.jsonl` | Tracked regressions |
| `ai-core/logs/decisions.jsonl` | Cross-project decisions |
| `ai-core/logs/projects/<name>.jsonl` | Per-project logs (optional) |
