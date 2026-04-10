#!/bin/bash
# Smart TradePractice Launcher
# Runs cycles adaptively until budget threshold reached
# Switches Opus/Sonnet based on remaining headroom
#
# Environment:
#   SESSION_BUDGET=220000    # Max tokens per 5-hour window (default Max 20x)
#   STOP_THRESHOLD=70        # Stop at this % of budget used

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/queue.sh"
source "$SCRIPT_DIR/lib/budget.sh"

SESSION_NAME="tradepractice"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

echo "╔══════════════════════════════════════════════╗"
echo "║     SMART TRADEPRACTICE                       ║"
echo "║     Budget-aware, adaptive cycles             ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Pre-flight
if [ "$DRY_RUN" = false ] && ! command -v tmux &>/dev/null; then
  echo "ERROR: tmux not installed"
  exit 1
fi

if ! command -v "$CLAUDE_BIN" &>/dev/null; then
  echo "ERROR: claude CLI not found"
  exit 1
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "Session already running. Use ./stop.sh first."
  exit 1
fi

init_budget

# Show current budget state
show_budget
echo ""

# Check if we're already over threshold
used_percent="$(get_budget_percent)"
if [ "$used_percent" -ge "$STOP_THRESHOLD" ]; then
  echo "Budget already at ${used_percent}% — above ${STOP_THRESHOLD}% threshold."
  echo "Window resets in: $(($(get_window_remaining) / 60)) min"
  echo "Skipping this run."
  exit 0
fi

echo "  Will run cycles until budget reaches ${STOP_THRESHOLD}%"
echo "  Current: ${used_percent}%"
echo "  Decision: $(decide_next_cycle)"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "[DRY RUN] Would launch smart conductor in tmux."
  exit 0
fi

# Init state (preserve budget file)
mkdir -p "$INBOX_DIR/conductor" "$INBOX_DIR/analyst" "$INBOX_DIR/implementer"
echo "running" > "$STATUS_FILE"
log_event "system" "launch-smart" "budget=$(get_budget_used_cents)c/${SESSION_BUDGET_USD}"

export CLAUDE_BIN SESSION_BUDGET_USD STOP_THRESHOLD

# Auto-cleanup: when conductor exits, kill the whole tmux session (no more zombies)
CONDUCTOR_CMD="bash \"$SCRIPT_DIR/agents/smart-conductor.sh\"; echo '--- CONDUCTOR EXITED ---'; sleep 5; tmux kill-session -t $SESSION_NAME"
ANALYST_CMD="bash \"$SCRIPT_DIR/agents/worker.sh\" analyst sonnet; echo '--- ANALYST EXITED ---'; sleep 2"
IMPLEMENTER_CMD="bash \"$SCRIPT_DIR/agents/worker.sh\" implementer sonnet; echo '--- IMPLEMENTER EXITED ---'; sleep 2"

tmux new-session -d -s "$SESSION_NAME" -n "trade" "$CONDUCTOR_CMD"
tmux split-window -t "$SESSION_NAME" -h "$ANALYST_CMD"
tmux split-window -t "$SESSION_NAME" -v "$IMPLEMENTER_CMD"
tmux select-layout -t "$SESSION_NAME" main-vertical

echo "╔══════════════════════════════════════════════╗"
echo "║  SMART LOOP LAUNCHED                         ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  View:    tmux attach -t $SESSION_NAME"
echo "  Stop:    ./stop.sh"
echo "  Budget:  cat $STATE_DIR/budget.json"
echo ""
