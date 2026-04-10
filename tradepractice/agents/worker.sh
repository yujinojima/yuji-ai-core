#!/bin/bash
# TradePractice Worker — watches inbox, runs claude, sends results back
# Usage: worker.sh <role> <model>

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.sh"
source "$SCRIPT_DIR/../lib/queue.sh"

ROLE="${1:?Usage: worker.sh <role> <model>}"
MODEL="${2:-sonnet}"
PROMPT_FILE="$TRADE_DIR/prompts/${ROLE}.md"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: Prompt not found: $PROMPT_FILE"
  exit 1
fi

SYSTEM_PROMPT="$(cat "$PROMPT_FILE")"

# Inject terse rules
SYSTEM_PROMPT="$SYSTEM_PROMPT

$TERSE_RULES"

echo "=== WORKER [$ROLE] starting (model: $MODEL) ==="

while is_running; do
  if has_messages "$ROLE"; then
    task="$(consume "$ROLE")"
    [ -z "$task" ] && { sleep "$POLL_INTERVAL"; continue; }

    echo ""
    echo "[$ROLE] Task received $(date +%H:%M:%S)"
    echo "$task" | head -2 | sed 's/^/  /'
    log_event "$ROLE" "task_started" "processing"

    full_prompt="$SYSTEM_PROMPT

---
$task
---

Complete the task. Be thorough but terse. No filler."

    echo "[$ROLE] Running claude ($MODEL)..."
    result="$(echo "$full_prompt" | "$CLAUDE_BIN" --dangerously-skip-permissions --print --model "$MODEL" 2>/dev/null || echo "ERROR: Claude call failed for $ROLE")"

    echo "[$ROLE] Done. ${#result} chars"
    enqueue "conductor" "$ROLE" "${ROLE}-result" "$result"
    log_event "$ROLE" "task_completed" "${#result} chars"
  else
    sleep "$POLL_INTERVAL"
  fi
done

echo "=== WORKER [$ROLE] stopped ==="
