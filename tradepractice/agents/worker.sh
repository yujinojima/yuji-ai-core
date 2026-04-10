#!/bin/bash
# TradePractice Worker — tracks actual token usage via JSON output
# Usage: worker.sh <role> <model>

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.sh"
source "$SCRIPT_DIR/../lib/queue.sh"
source "$SCRIPT_DIR/../lib/budget.sh"

ROLE="${1:?Usage: worker.sh <role> <model>}"
MODEL="${2:-sonnet}"
PROMPT_FILE="$TRADE_DIR/prompts/${ROLE}.md"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: Prompt not found: $PROMPT_FILE"
  exit 1
fi

SYSTEM_PROMPT="$(cat "$PROMPT_FILE")"
SYSTEM_PROMPT="$SYSTEM_PROMPT

$TERSE_RULES"

echo "=== WORKER [$ROLE] starting (model: $MODEL) ==="
init_budget

while is_running; do
  if has_messages "$ROLE"; then
    task="$(consume "$ROLE")"
    [ -z "$task" ] && { sleep "$POLL_INTERVAL"; continue; }

    # Role can be overridden per-task via meta field (for dynamic model switching)
    task_model="$MODEL"
    if echo "$task" | grep -q "^override_model:"; then
      task_model="$(echo "$task" | grep "^override_model:" | head -1 | sed 's/override_model:\s*//')"
      task="$(echo "$task" | grep -v "^override_model:")"
    fi

    echo ""
    echo "[$ROLE] Task received $(date +%H:%M:%S) (model: $task_model)"
    log_event "$ROLE" "task_started" "model=$task_model"

    full_prompt="$SYSTEM_PROMPT

---
$task
---

Complete the task. Be thorough but terse. No filler."

    echo "[$ROLE] Running claude ($task_model)..."

    # Run with JSON output to capture usage
    json_output="$(echo "$full_prompt" | "$CLAUDE_BIN" --dangerously-skip-permissions --print --output-format json --model "$task_model" 2>/dev/null || echo '{"result":"ERROR: Claude call failed","usage":{"input_tokens":0,"output_tokens":0}}')"

    # Extract the text result
    result="$(echo "$json_output" | jq -r '.result // "ERROR: no result"' 2>/dev/null || echo "ERROR: parse failed")"

    # Extract and record actual USD cost
    cost_usd="$(extract_cost "$json_output")"
    tokens="$(echo "$json_output" | jq -r '.usage.input_tokens + .usage.output_tokens' 2>/dev/null || echo 0)"

    record_usage "$ROLE" "$task_model" "$cost_usd"

    printf "[%s] Done. %d chars, \$%s cost\n" "$ROLE" "${#result}" "$cost_usd"
    log_event "$ROLE" "task_completed" "cost=\$$cost_usd tokens=$tokens chars=${#result}"

    enqueue "conductor" "$ROLE" "${ROLE}-result" "$result"
  else
    sleep "$POLL_INTERVAL"
  fi
done

echo "=== WORKER [$ROLE] stopped ==="
