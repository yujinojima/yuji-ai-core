#!/bin/bash
# Smart Conductor — Budget-aware, adaptive, auto-stopping
# Runs cycles until budget threshold reached
# Switches between Opus and Sonnet based on remaining headroom

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.sh"
source "$SCRIPT_DIR/../lib/queue.sh"
source "$SCRIPT_DIR/../lib/budget.sh"

# Load brief
brief_content=""
if [ -f "$BRIEF_FILE" ]; then
  brief_content="$(cat "$BRIEF_FILE")"
fi

init_budget

# Helper functions (same as original conductor)
load_knowledge() {
  local project="$1"
  local knowledge=""
  for level in naive intermediate sophisticated; do
    local pdir="$KNOWLEDGE_DIR/$project/prims/$level"
    if [ -d "$pdir" ] && [ "$(ls -A "$pdir" 2>/dev/null)" ]; then
      knowledge+="## Existing $level prims\n"
      for f in "$pdir"/*.md; do
        [ -f "$f" ] || continue
        knowledge+="$(cat "$f")\n\n"
      done
    fi
  done
  if [ -f "$KNOWLEDGE_DIR/conditions-log.md" ]; then
    knowledge+="\n## Conditions Log\n$(cat "$KNOWLEDGE_DIR/conditions-log.md")\n"
  fi
  echo -e "$knowledge"
}

save_prim() {
  local project="$1" title="$2" level="$3" content="$4"
  local pdir="$KNOWLEDGE_DIR/$project/prims/$level"
  local filename="$(echo "$title" | tr ' ' '-' | tr -cd 'a-zA-Z0-9-' | head -c 50).md"
  mkdir -p "$pdir"
  echo "$content" > "$pdir/$filename"
  log_event "conductor" "prim_saved" "$project/$level: $filename"
}

extract_prim_level() {
  echo "$1" | grep -oP '\*\*Level:\*\*\s*\K(naive|intermediate|sophisticated)' | head -1 || echo "naive"
}

extract_prim_name() {
  echo "$1" | grep -oP '## Prim: \K.*' | head -1 || echo "unnamed-prim"
}

echo "╔══════════════════════════════════════════════╗"
echo "║  SMART TRADEPRACTICE CONDUCTOR               ║"
echo "║  Budget-aware, adaptive model selection      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
show_budget
echo ""

PROJECTS=("freqtrade" "polymarket")
PROJECT_DIRS=("$FREQTRADE_DIR" "$POLYMARKET_DIR")
cycle=0

# ── MAIN LOOP — run until budget threshold ──
while is_running; do
  # Decide what to do next
  decision="$(decide_next_cycle)"

  case "$decision" in
    stop)
      echo ""
      echo "═══════════════════════════════════════"
      echo "  BUDGET THRESHOLD REACHED"
      show_budget
      echo "═══════════════════════════════════════"
      stop_loop
      break
      ;;
    "run opus")
      next_model="opus"
      ;;
    "run sonnet")
      next_model="sonnet"
      ;;
  esac

  cycle=$((cycle + 1))
  next_cycle > /dev/null

  # Alternate projects
  proj_idx=$(( (cycle - 1) % ${#PROJECTS[@]} ))
  project="${PROJECTS[$proj_idx]}"
  project_dir="${PROJECT_DIRS[$proj_idx]}"

  echo ""
  echo "═══════════════════════════════════════"
  echo "  CYCLE $cycle — $project — $(date +%H:%M:%S)"
  echo "  Analyst model: $next_model (budget-selected)"
  echo "  Budget used: $(get_budget_used) tokens ($(get_budget_percent)%)"
  echo "═══════════════════════════════════════"

  knowledge="$(load_knowledge "$project")"

  # Count prims to decide mode
  naive_count="$(find "$KNOWLEDGE_DIR/$project/prims/naive" -name '*.md' 2>/dev/null | wc -l)"
  intermediate_count="$(find "$KNOWLEDGE_DIR/$project/prims/intermediate" -name '*.md' 2>/dev/null | wc -l)"
  sophisticated_count="$(find "$KNOWLEDGE_DIR/$project/prims/sophisticated" -name '*.md' 2>/dev/null | wc -l)"
  total_prims=$((naive_count + intermediate_count + sophisticated_count))

  if [ "$total_prims" -lt 3 ]; then
    analyst_task="Mode: ASSESS

Read the current $project strategies and extract naive trading primitives.
Project path: $project_dir
Prim template: $KNOWLEDGE_DIR/prim-template.md

$knowledge

## Brief
$brief_content

Read strategy files. Create ONE naive prim from a key entry/exit rule."
  elif [ "$naive_count" -gt "$intermediate_count" ]; then
    analyst_task="Mode: RESEARCH

$naive_count naive, $intermediate_count intermediate, $sophisticated_count sophisticated prims.
PRIORITY: Refine a naive prim to intermediate.
Project path: $project_dir

$knowledge

## Brief
$brief_content

Output one INTERMEDIATE prim refining a naive one with documented conditions."
  else
    analyst_task="Mode: RESEARCH

$naive_count naive, $intermediate_count intermediate, $sophisticated_count sophisticated prims.
PRIORITY: Refine intermediate → sophisticated, or explore new angles.
Project path: $project_dir

$knowledge

## Brief
$brief_content

Output one prim at appropriate level."
  fi

  # Enqueue with model override
  enqueue "analyst" "conductor" "analyst-${project}-cycle-${cycle}" \
    "override_model: $next_model
$analyst_task"

  if ! wait_for_message "conductor" 900; then
    echo "  Analyst timed out."
    continue
  fi

  analyst_result="$(consume "conductor")"

  prim_name="$(extract_prim_name "$analyst_result")"
  prim_level="$(extract_prim_level "$analyst_result")"

  if [ "$prim_name" != "unnamed-prim" ]; then
    save_prim "$project" "$prim_name" "$prim_level" "$analyst_result"
    echo "  Prim saved: $prim_level/$prim_name"
  fi

  # Implementer always uses sonnet (code changes don't need deep reasoning)
  enqueue "implementer" "conductor" "implement-${project}-cycle-${cycle}" \
    "Project: $project
Project path: $project_dir

$analyst_result

Apply the finding. Minimal change. Commit. If research-only, output SKIP."

  if ! wait_for_message "conductor" 900; then
    echo "  Implementer timed out."
    continue
  fi

  impl_result="$(consume "conductor")"

  if echo "$impl_result" | grep -qi "SKIP"; then
    echo "  Implementer: SKIP (research-only)"
  else
    echo "  Implementer done."
    # Verify
    if cd "$project_dir" 2>/dev/null; then
      uncommitted="$(git status --porcelain 2>/dev/null | wc -l || echo 0)"
      if [ "$uncommitted" -gt 0 ]; then
        git add -A && git commit -m "chore: tradepractice cycle $cycle ($project)" 2>/dev/null || true
      fi
    fi
  fi

  echo "  Cycle $cycle complete. Budget: $(get_budget_percent)% used."
  log_event "conductor" "cycle_complete" "$project cycle $cycle"

  sleep 3
done

echo ""
echo "═══════════════════════════════════════"
echo "  SMART SESSION COMPLETE"
echo "═══════════════════════════════════════"
show_budget
echo ""
echo "  Cycles run: $cycle"
