# Agent Instruction: Review & Logging Protocol

**Distributed by Tron — 2026-04-07**

All agents must follow this protocol immediately.

## 1. Log All Work

After completing any task, log it to `ai-core/logs/agent-events.jsonl` as a JSON line:

```json
{"timestamp": "ISO-8601", "agent": "agent-name", "action": "description", "project": "project-name", "files_changed": [], "code_related": true/false, "version": "vN"}
```

## 2. Submit for Review

If your work is significant (changed behaviour, affected features, fixed a bug, introduced risk, or altered code/config):

- Submit a review entry to `ai-core/logs/review-events.jsonl`
- Set `application_review_required: true` for all implementation work
- Set `director_review_required: true` for all coding-related work

## 3. Do NOT Mark Complete Until Reviews Pass

- Coding-related work requires BOTH Application Review AND Director Review
- Non-coding significant work requires at least Application Review
- Only after reviews pass can work be marked complete

## 4. Link to Prior Implementations

When logging, include:
- `previous_version` — prior version if applicable
- `related_task` — linked task/story
- `affected_feature` — what feature this touches

## 5. Non-Compliance Consequences

- Tron will flag unlogged work
- Tron will reject completion of unreviewed coding changes
- Repeated violations escalate to Behavioural Manager for scoring adjustments

## 6. Coding-Related Scope

The following are always coding-related: frontend changes, backend changes, scripts, config updates, infrastructure changes, data model changes, auth/session changes, automation logic, test logic, integration logic.
