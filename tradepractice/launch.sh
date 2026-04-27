#!/bin/bash
# TradePractice — Launch trading strategy optimisation session
# 3 panes: Conductor (bash) + Analyst (Opus) + Implementer (Sonnet)
# Alternates between freqtrade and polymarket each cycle
# Knowledge persists across windows in knowledge/ dir
#
# Usage:
#   ./launch.sh                    # Default: 6 cycles
#   MAX_CYCLES=10 ./launch.sh      # More cycles
#   ./launch.sh --dry-run          # Preview

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/queue.sh"

SESSION_NAME="${SESSION_NAME_OVERRIDE:-tradepractice}"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

echo "╔══════════════════════════════════════════════╗"
echo "║     TRADEPRACTICE                             ║"
echo "║     Trading Strategy Optimisation Loop        ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Pre-flight
if [ "$DRY_RUN" = false ] && ! command -v tmux &>/dev/null; then
  echo "ERROR: tmux not installed. Run: sudo apt-get install tmux"
  exit 1
fi

if ! command -v "$CLAUDE_BIN" &>/dev/null; then
  echo "ERROR: claude CLI not found"
  exit 1
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "Session '$SESSION_NAME' already running."
  echo "  tmux attach -t $SESSION_NAME"
  echo "  ./stop.sh"
  exit 1
fi

# Check projects exist
for dir in "$FREQTRADE_DIR" "$POLYMARKET_DIR"; do
  if [ ! -d "$dir" ]; then
    echo "WARNING: $dir not found"
  fi
done

# Knowledge stats
ft_knowledge="$(find "$KNOWLEDGE_DIR/freqtrade" -name '*.md' 2>/dev/null | wc -l)"
pm_knowledge="$(find "$KNOWLEDGE_DIR/polymarket" -name '*.md' 2>/dev/null | wc -l)"

echo "  Freqtrade:   $FREQTRADE_DIR"
echo "    Knowledge: $ft_knowledge findings accumulated"
echo "  Polymarket:  $POLYMARKET_DIR"
echo "    Knowledge: $pm_knowledge findings accumulated"
echo ""
echo "  Cycles:      $MAX_CYCLES (alternating freqtrade/polymarket)"
echo "  Analyst:     $MODEL_ANALYST (deep research)"
echo "  Implementer: $MODEL_IMPLEMENTER (code changes)"
echo "  Session:     $SESSION_NAME"
echo "  Terse mode:  ON (token-saving output)"
echo ""
echo "  Pipeline:    Assess → Research → Implement → Backtest → Record"
echo "  Est. calls:  ~$((MAX_CYCLES * 2)) claude calls"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "[DRY RUN] Would create tmux session with 3 panes."
  echo "  Pane 0: Conductor (bash orchestration)"
  echo "  Pane 1: Analyst (research + assessment)"
  echo "  Pane 2: Implementer (code + backtest)"
  echo ""
  echo "  Cycle rotation:"
  for i in $(seq 1 "$MAX_CYCLES"); do
    proj_idx=$(( (i - 1) % 2 ))
    [ "$proj_idx" -eq 0 ] && echo "    Cycle $i: freqtrade" || echo "    Cycle $i: polymarket"
  done
  exit 0
fi

# Init state
init_queue
mkdir -p "$INBOX_DIR/analyst" "$INBOX_DIR/implementer"
log_event "system" "launch" "tradepractice cycles=$MAX_CYCLES"

export MAX_CYCLES CLAUDE_BIN MODEL_ANALYST MODEL_IMPLEMENTER

# Create tmux session
# Quote paths for spaces in "Yuji Project"
# 2026-04-26: kill the session when the conductor exits so worker panes don't
# keep polling and burn tokens on stale queue items (post-conductor orphan bug).
# Mirrors smart-launch.sh. Workers exit naturally when their tmux panes die.
CONDUCTOR_CMD="bash \"$SCRIPT_DIR/agents/conductor.sh\"; echo '--- CONDUCTOR EXITED ---'; sleep 8; tmux kill-session -t \"$SESSION_NAME\""
ANALYST_CMD="bash \"$SCRIPT_DIR/agents/worker.sh\" analyst $MODEL_ANALYST; echo '--- ANALYST EXITED ---'; read"
IMPLEMENTER_CMD="bash \"$SCRIPT_DIR/agents/worker.sh\" implementer $MODEL_IMPLEMENTER; echo '--- IMPLEMENTER EXITED ---'; read"

tmux new-session -d -s "$SESSION_NAME" -n "trade" "$CONDUCTOR_CMD"
tmux split-window -t "$SESSION_NAME" -h "$ANALYST_CMD"
tmux split-window -t "$SESSION_NAME" -v "$IMPLEMENTER_CMD"
tmux select-layout -t "$SESSION_NAME" main-vertical

echo "╔══════════════════════════════════════════════╗"
echo "║  TRADEPRACTICE LAUNCHED                      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  View:      tmux attach -t $SESSION_NAME"
echo "  Stop:      ./stop.sh"
echo "  Knowledge: ls knowledge/freqtrade/ knowledge/polymarket/"
echo "  Logs:      tail -f $STATE_DIR/log.jsonl"
echo ""
echo "Running in background. Knowledge accumulates in knowledge/ dir."
