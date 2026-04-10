#!/bin/bash
# TradePractice — Status Dashboard

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

SESSION_NAME="tradepractice"

echo "╔══════════════════════════════════════════════╗"
echo "║  TRADEPRACTICE STATUS                         ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Session
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "  Session:  RUNNING"
else
  echo "  Session:  NOT RUNNING"
fi

[ -f "$STATE_DIR/status.txt" ] && echo "  Status:   $(cat "$STATE_DIR/status.txt")"
[ -f "$STATE_DIR/cycle.txt" ] && echo "  Cycle:    $(cat "$STATE_DIR/cycle.txt") / $MAX_CYCLES"
echo ""

# Knowledge
echo "  Knowledge Base:"
for proj in freqtrade polymarket; do
  count="$(ls -1 "$KNOWLEDGE_DIR/$proj"/*.md 2>/dev/null | wc -l || echo 0)"
  echo "    $proj: $count findings"
  if [ "$count" -gt 0 ]; then
    ls -1t "$KNOWLEDGE_DIR/$proj"/*.md 2>/dev/null | head -3 | while read f; do
      echo "      - $(basename "$f")"
    done
  fi
done
echo ""

# Recent log
if [ -f "$STATE_DIR/log.jsonl" ]; then
  total="$(wc -l < "$STATE_DIR/log.jsonl")"
  echo "  Log entries: $total"
  echo "  Last 5:"
  tail -5 "$STATE_DIR/log.jsonl" | jq -r '  "    \(.ts | split("T")[1] | split("+")[0]) [\(.agent)] \(.action): \(.detail)"' 2>/dev/null || tail -5 "$STATE_DIR/log.jsonl"
fi
