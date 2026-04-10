#!/bin/bash
# Generic worker agent loop
# Usage: worker.sh <role> <model>
# Each worker watches its inbox, processes tasks via claude -p, and sends results back.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.sh"
source "$SCRIPT_DIR/../lib/queue.sh"

ROLE="${1:?Usage: worker.sh <role> <model>}"
MODEL="${2:-$MODEL_CONDUCTOR}"

# Resolve prompt file — lean mode uses different prompts for some roles
if [ "$ROLE" = "builder" ] && [ -f "$OVERNIGHT_DIR/prompts/builder-lean.md" ] && [ -n "${MODEL_BUILDER_LEAN:-}" ]; then
  PROMPT_FILE="$OVERNIGHT_DIR/prompts/builder-lean.md"
else
  PROMPT_FILE="$OVERNIGHT_DIR/prompts/${ROLE}.md"
fi

if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: Prompt file not found: $PROMPT_FILE"
  exit 1
fi

SYSTEM_PROMPT="$(cat "$PROMPT_FILE")"

echo "=== WORKER [$ROLE] starting (model: $MODEL) ==="
echo "Watching inbox: $INBOX_DIR/$ROLE/"
echo ""

while is_running; do
  if has_messages "$ROLE"; then
    task="$(consume "$ROLE")"

    if [ -z "$task" ]; then
      sleep "$POLL_INTERVAL"
      continue
    fi

    echo ""
    echo "──────────────────────────────────"
    echo "[$ROLE] Got task at $(date +%H:%M:%S)"
    echo "$task" | head -3
    echo "..."
    echo ""

    log_event "$ROLE" "task_started" "processing"

    # Build full prompt: system prompt + task
    full_prompt="$SYSTEM_PROMPT

---

## Incoming Task

$task

---

## Instructions

Complete the task above. Be thorough but concise.
When done, output your results clearly.
Do NOT output meta-commentary about what you're doing — just do it and show results."

    # Run claude
    echo "[$ROLE] Running claude (model: $MODEL)..."
    result="$( echo "$full_prompt" | "$CLAUDE_BIN" --dangerously-skip-permissions --print --model "$MODEL" 2>/dev/null || echo "ERROR: Claude invocation failed for $ROLE" )"

    echo "[$ROLE] Done. Result length: ${#result} chars"
    echo "$result" | head -5

    # Send result back to conductor
    enqueue "conductor" "$ROLE" "${ROLE}-result" "$result"

    log_event "$ROLE" "task_completed" "${#result} chars output"
  else
    sleep "$POLL_INTERVAL"
  fi
done

echo "=== WORKER [$ROLE] stopped ==="
