#!/bin/bash
# Lean Overnight Loop — Multi-Project Launcher
# 3 panes: Conductor (bash) + Scout + Builder
# Round-robin across projects, 1 active claude call at a time
#
# Usage:
#   ./launch-lean.sh                    # Read projects from brief.md
#   MAX_CYCLES=20 ./launch-lean.sh      # Override max cycles
#   ./launch-lean.sh --dry-run          # Preview without running

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/queue.sh"

SESSION_NAME="overnight-lean"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
  esac
done

echo "╔══════════════════════════════════════════════╗"
echo "║     LEAN OVERNIGHT LOOP                      ║"
echo "║     Scout → Build → Verify (round-robin)     ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── Pre-flight ──
if [ "$DRY_RUN" = false ] && ! command -v tmux &>/dev/null; then
  echo "ERROR: tmux not installed. Run: sudo apt-get install tmux"
  exit 1
fi

if ! command -v "$CLAUDE_BIN" &>/dev/null; then
  echo "ERROR: claude CLI not found at: $CLAUDE_BIN"
  exit 1
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "WARNING: Session '$SESSION_NAME' already exists."
  echo "  tmux attach -t $SESSION_NAME   # to view"
  echo "  ./stop.sh                      # to stop"
  exit 1
fi

# ── Parse projects from brief ──
readarray -t PROJECT_LINES < <(parse_brief_projects)
num_projects="${#PROJECT_LINES[@]}"

if [ "$num_projects" -eq 0 ] || [ -z "${PROJECT_LINES[0]}" ]; then
  # Fallback to TARGET_PROJECT env var
  if [ -n "$PROJECT_PATH" ] && [ -d "$PROJECT_PATH" ]; then
    echo "  No projects in brief.md — using TARGET_PROJECT=$TARGET_PROJECT"
    PROJECT_LINES=("${TARGET_PROJECT}|${PROJECT_PATH}|General improvements")
    num_projects=1
  else
    echo "ERROR: No projects configured."
    echo "Either:"
    echo "  1. Add projects to brief.md under ## Projects"
    echo "  2. Set TARGET_PROJECT=ALLOK8R"
    exit 1
  fi
fi

# ── Brief check ──
brief_directives=0
if [ -f "$BRIEF_FILE" ]; then
  brief_directives="$(grep -v '^$\|^#\|^<!--\|^-->' "$BRIEF_FILE" 2>/dev/null | grep -c '[a-zA-Z]' || echo 0)"
fi

if [ "$brief_directives" -eq 0 ]; then
  echo "WARNING: brief.md has no directives beyond project list."
  echo "Edit ai-core/overnight/brief.md to set constraints and goals."
  echo ""
  if [ "$DRY_RUN" = false ] && [ -t 0 ]; then
    read -p "Continue without directives? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Aborted. Edit brief.md first."
      exit 0
    fi
  fi
  # Non-interactive (cron): proceed without prompt
fi

# ── Display config ──
MODEL_SCOUT="${MODEL_SCOUT:-opus}"
MODEL_BUILDER_LEAN="${MODEL_BUILDER_LEAN:-sonnet}"

echo "  Projects ($num_projects):"
for line in "${PROJECT_LINES[@]}"; do
  IFS='|' read -r name path focus <<< "$line"
  echo "    - $name: \"$focus\""
done
echo ""
echo "  Cycles:     $MAX_CYCLES (total rotations across all projects)"
echo "  Scout:      $MODEL_SCOUT"
echo "  Builder:    $MODEL_BUILDER_LEAN"
echo "  Session:    $SESSION_NAME"
echo "  Panes:      3 (conductor + scout + builder)"
echo "  Scheduling: round-robin (1 active claude call at a time)"
echo ""
echo "  Est. API calls: ~$((num_projects * 2))-$((num_projects * 3)) per rotation"
echo "  Est. total:     ~$((MAX_CYCLES * num_projects * 2))-$((MAX_CYCLES * num_projects * 3)) calls"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "[DRY RUN] Would create tmux session with 3 panes."
  echo "  Pane 0: Conductor (bash — round-robin orchestration)"
  echo "  Pane 1: Scout (finds work, one project at a time)"
  echo "  Pane 2: Builder (implements, one project at a time)"
  exit 0
fi

# ── Init state ──
mkdir -p "$STATE_DIR/inbox/scout"
init_queue
log_event "system" "launch-lean" "projects=$num_projects cycles=$MAX_CYCLES"

export TARGET_PROJECT MAX_CYCLES CLAUDE_BIN MODEL_SCOUT MODEL_BUILDER_LEAN

# ── Create tmux session: 3 panes (quote paths for spaces) ──
CONDUCTOR_CMD="bash \"$SCRIPT_DIR/agents/conductor-lean.sh\"; echo '--- CONDUCTOR EXITED ---'; read"
SCOUT_CMD="bash \"$SCRIPT_DIR/agents/worker.sh\" scout $MODEL_SCOUT; echo '--- SCOUT EXITED ---'; read"
BUILDER_CMD="bash \"$SCRIPT_DIR/agents/worker.sh\" builder $MODEL_BUILDER_LEAN; echo '--- BUILDER EXITED ---'; read"

tmux new-session -d -s "$SESSION_NAME" -n "overnight" "$CONDUCTOR_CMD"
tmux split-window -t "$SESSION_NAME" -h "$SCOUT_CMD"
tmux split-window -t "$SESSION_NAME" -v "$BUILDER_CMD"
tmux select-layout -t "$SESSION_NAME" main-vertical

echo "╔══════════════════════════════════════════════╗"
echo "║  LEAN LOOP LAUNCHED                          ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  View:    tmux attach -t $SESSION_NAME"
echo "  Stop:    ./stop.sh"
echo "  Status:  ./status.sh"
echo "  Logs:    tail -f $STATE_DIR/log.jsonl"
echo ""
echo "Running in background. Safe to close terminal."
