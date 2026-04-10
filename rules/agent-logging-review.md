# Agent Logging & Review Enforcement

> Config: `ai-core/configs/logging-review-directive.json`
> Log target: `ai-core/logs/agent-events.jsonl`

## Core Rule

No significant work is considered complete unless it has been:
1. **Logged** — event written to `ai-core/logs/agent-events.jsonl`
2. **Reviewed** — submitted for appropriate review
3. **If code-related** — passed both Application Review and Director Review

## Review Chain

| Work type | Review chain |
|-----------|-------------|
| Non-code (research, content, docs) | Agent log → Behaviour Manager review |
| Code (features, fixes, refactors) | Agent log → Application Review → Director Review → Behaviour Manager review |

### Application Review
- Checks: UX flow, logic alignment, integration, product behaviour match
- Performed by: code-reviewer or tdd-guide (context-dependent)

### Director Review
- Checks: architectural fit, strategic alignment, code quality, maintainability
- Performed by: Director agent
- Decision: accept, revise, or rollback

### Behaviour Manager Review
- Checks: compliance, performance scoring, links to prior implementations, regression patterns
- Performed by: Behaviour Manager agent
- Owns long-term workflow optimisation

## What Must Be Logged

**Task events:** assigned, started, paused, completed, blocked, abandoned

**Decisions:** implementation, architecture, design tradeoff, dependency choice, scope adjustment

**Changes:** feature created/updated, bug fix, refactor, rollback, config change

**Errors:** bug discovered, test failure, integration issue, regression, missing dependency, unclear requirement, environment failure

**Review events:** submitted for review, review passed/failed, sent back for revision

**Improvement links:** linked to previous implementation, score adjusted, regression/improvement linked

## Log Format

One JSONL event per line in `ai-core/logs/agent-events.jsonl`.

**Required fields:**
- `timestamp` (ISO 8601 with timezone)
- `agent` (agent name)
- `role` (agent role)
- `project` (project key from projects.json)
- `action_type` (from event types above)
- `summary` (one-line description)
- `status` (current status)

**Optional fields:**
- `task_id`, `feature_id`, `related_feature_id`
- `details` (extended description)
- `code_related` (boolean)
- `review_status` (pending/passed/failed)
- `application_review_required`, `director_review_required` (boolean)
- `previous_version`, `current_version`
- `score_delta` (number, set by Behaviour Manager)

**Example:**
```json
{"timestamp":"2026-04-07T11:10:00+10:00","agent":"frontend-builder","role":"builder","project":"allok8r","task_id":"TASK-104","feature_id":"AUTH-LOGIN","action_type":"feature_updated","summary":"Updated login form validation to match design spec","code_related":true,"review_status":"pending","application_review_required":true,"director_review_required":true,"status":"in_review"}
```

## Enforcement

### Tron (Orchestrator)
- Ensures all agents log before marking work complete
- Routes code work through the full review chain
- Tracks compliance; reports repeated failures to Behaviour Manager

### Behaviour Manager (Optimiser)
- Monitors logs for compliance gaps
- Scores agent performance on logging discipline
- Links new changes to prior implementations for continuous improvement
- Detects repeat failure patterns and recommends process refinements

### All Agents
- Log significant actions before marking complete
- Submit work for review per the review chain
- Include traceability to previous versions where applicable
