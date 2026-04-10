#!/bin/bash
# Overnight Multi-Agent Loop — Launcher
# Creates a tmux session with 5 panes: Conductor + 4 Workers
#
# Usage:
#   ./launch.sh                           # Default: ALLOK8R, 10 cycles
#   TARGET_PROJECT=TLE MAX_CYCLES=20 ./launch.sh
#   ./launch.sh --dry-run                 # Show what would happen without running

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/queue.sh"

SESSION_NAME="overnight-loop"
DRY_RUN=false

# Parse args
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

# ── Pre-flight checks ───────────────────────────────
echo "╔══════════════════════════════════════════════╗"
echo "║     OVERNIGHT MULTI-AGENT LOOP              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Check tmux (skip for dry-run)
if [ "$DRY_RUN" = false ] && ! command -v tmux &>/dev/null; then
  echo "ERROR: tmux is not installed."
  echo "Install it first:  sudo apt-get install tmux"
  exit 1
fi

# Check claude
if ! command -v "$CLAUDE_BIN" &>/dev/null; then
  echo "ERROR: claude CLI not found at: $CLAUDE_BIN"
  exit 1
fi

# Check project path
if [ -z "$PROJECT_PATH" ] || [ ! -d "$PROJECT_PATH" ]; then
  echo "ERROR: Project path not found: $PROJECT_PATH"
  echo "Set TARGET_PROJECT to a valid project key from projects.json"
  exit 1
fi

# Check for existing session
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "WARNING: Session '$SESSION_NAME' already exists."
  echo "Use ./stop.sh to stop it first, or:"
  echo "  tmux attach -t $SESSION_NAME   # to view it"
  echo "  tmux kill-session -t $SESSION_NAME  # to force kill"
  exit 1
fi

echo "Configuration:"
echo "  Project:      $TARGET_PROJECT"
echo "  Project path: $PROJECT_PATH"
echo "  Max cycles:   $MAX_CYCLES"
echo "  Session:      $SESSION_NAME"
echo "  Models:       conductor=$MODEL_CONDUCTOR ideator=$MODEL_IDEATOR"
echo "                researcher=$MODEL_RESEARCHER builder=$MODEL_BUILDER"
echo "                reviewer=$MODEL_REVIEWER"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "[DRY RUN] Would create tmux session with 5 panes."
  echo "  Pane 0: Conductor (Tron)"
  echo "  Pane 1: Ideator"
  echo "  Pane 2: Researcher"
  echo "  Pane 3: Builder"
  echo "  Pane 4: Reviewer"
  exit 0
fi

# ── Initialize state ────────────────────────────────
init_queue
log_event "system" "launch" "project=$TARGET_PROJECT cycles=$MAX_CYCLES"

echo "State initialized at: $STATE_DIR"
echo ""

# ── Create tmux session ─────────────────────────────
echo "Creating tmux session: $SESSION_NAME"

# Export env vars so child panes inherit them
export TARGET_PROJECT MAX_CYCLES CLAUDE_BIN
export MODEL_CONDUCTOR MODEL_IDEATOR MODEL_RESEARCHER MODEL_BUILDER MODEL_REVIEWER

# Create session with first pane (Conductor)
tmux new-session -d -s "$SESSION_NAME" -n "overnight" \
  "bash $SCRIPT_DIR/agents/conductor.sh; echo '--- CONDUCTOR EXITED ---'; read"

# Split into 4 more panes for workers
# Layout: tiled (roughly equal panes)
tmux split-window -t "$SESSION_NAME" \
  "bash $SCRIPT_DIR/agents/worker.sh ideator $MODEL_IDEATOR; echo '--- IDEATOR EXITED ---'; read"

tmux split-window -t "$SESSION_NAME" \
  "bash $SCRIPT_DIR/agents/worker.sh researcher $MODEL_RESEARCHER; echo '--- RESEARCHER EXITED ---'; read"

tmux split-window -t "$SESSION_NAME" \
  "bash $SCRIPT_DIR/agents/worker.sh builder $MODEL_BUILDER; echo '--- BUILDER EXITED ---'; read"

tmux split-window -t "$SESSION_NAME" \
  "bash $SCRIPT_DIR/agents/worker.sh reviewer $MODEL_REVIEWER; echo '--- REVIEWER EXITED ---'; read"

# Arrange panes in a tiled layout
tmux select-layout -t "$SESSION_NAME" tiled

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  OVERNIGHT LOOP LAUNCHED                     ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  View:    tmux attach -t $SESSION_NAME"
echo "  Stop:    ./stop.sh"
echo "  Logs:    tail -f $LOG_FILE"
echo "  Status:  cat $STATUS_FILE"
echo ""
echo "The loop is running in the background."
echo "You can safely close this terminal."
