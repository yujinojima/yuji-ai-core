#!/bin/bash
# Overnight Loop — Graceful Stop
# Signals agents to stop after their current task, then kills tmux session.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/queue.sh"

# Check both session names
SESSION_NAME=""
if tmux has-session -t "overnight-lean" 2>/dev/null; then
  SESSION_NAME="overnight-lean"
elif tmux has-session -t "overnight-loop" 2>/dev/null; then
  SESSION_NAME="overnight-loop"
fi

echo "Stopping overnight loop..."

# Signal graceful stop
if [ -f "$STATUS_FILE" ]; then
  stop_loop
  echo "  Status set to 'stopped'. Agents will finish current task and exit."
else
  echo "  No status file found. Loop may not be running."
fi

# Wait a moment for agents to notice
echo "  Waiting 10s for agents to wrap up..."
sleep 10

# Kill tmux session
if [ -n "$SESSION_NAME" ]; then
  tmux kill-session -t "$SESSION_NAME"
  echo "  Tmux session '$SESSION_NAME' killed."
else
  echo "  No overnight tmux session found."
fi

# Summary
echo ""
echo "Overnight loop stopped."
if [ -f "$LOG_FILE" ]; then
  echo ""
  echo "Last 10 log entries:"
  tail -10 "$LOG_FILE" | jq -r '"\(.ts) [\(.agent)] \(.action): \(.detail)"' 2>/dev/null || tail -10 "$LOG_FILE"
fi

if [ -f "$CYCLE_FILE" ]; then
  echo ""
  echo "Completed cycles: $(cat "$CYCLE_FILE")"
fi
