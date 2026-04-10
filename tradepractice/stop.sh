#!/bin/bash
# TradePractice — Graceful Stop

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/queue.sh"

SESSION_NAME="tradepractice"

echo "Stopping tradepractice..."

if [ -f "$STATUS_FILE" ]; then
  stop_loop
  echo "  Status → stopped. Agents finishing current task."
else
  echo "  No status file. May not be running."
fi

sleep 10

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux kill-session -t "$SESSION_NAME"
  echo "  Session killed."
else
  echo "  No session found."
fi

echo ""

# Knowledge summary
for proj in freqtrade polymarket; do
  count="$(ls -1 "$KNOWLEDGE_DIR/$proj"/*.md 2>/dev/null | wc -l || echo 0)"
  echo "  $proj: $count research findings"
done

if [ -f "$STATE_DIR/session-summary.md" ]; then
  echo ""
  echo "Session summary:"
  cat "$STATE_DIR/session-summary.md"
fi
