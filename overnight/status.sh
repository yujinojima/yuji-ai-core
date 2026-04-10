#!/bin/bash
# Overnight Loop — Status Dashboard
# Shows current state without attaching to tmux.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

SESSION_NAME="overnight-loop"

echo "╔══════════════════════════════════════════════╗"
echo "║  OVERNIGHT LOOP STATUS                       ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Tmux session
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "  Session:  RUNNING"
  pane_count="$(tmux list-panes -t "$SESSION_NAME" 2>/dev/null | wc -l)"
  echo "  Panes:    $pane_count"
else
  echo "  Session:  NOT RUNNING"
fi

# State
if [ -f "$STATE_DIR/status.txt" ]; then
  echo "  Status:   $(cat "$STATE_DIR/status.txt")"
else
  echo "  Status:   (no state file)"
fi

if [ -f "$STATE_DIR/cycle.txt" ]; then
  echo "  Cycle:    $(cat "$STATE_DIR/cycle.txt") / $MAX_CYCLES"
fi

echo "  Project:  $TARGET_PROJECT"
echo ""

# Inbox counts
echo "  Inbox Depths:"
for agent in conductor ideator researcher builder reviewer; do
  count="$(ls -1 "$STATE_DIR/inbox/$agent"/*.md 2>/dev/null | wc -l || echo 0)"
  echo "    $agent: $count"
done
echo ""

# Recent log
if [ -f "$STATE_DIR/log.jsonl" ]; then
  total="$(wc -l < "$STATE_DIR/log.jsonl")"
  echo "  Log entries: $total"
  echo ""
  echo "  Last 5 events:"
  tail -5 "$STATE_DIR/log.jsonl" | jq -r '  "    \(.ts | split("T")[1] | split("+")[0]) [\(.agent)] \(.action): \(.detail)"' 2>/dev/null || tail -5 "$STATE_DIR/log.jsonl"
fi
