#!/bin/bash
# Lean Conductor — Multi-project round-robin orchestration
# Pipeline per project: Scout → Builder → Verify
# Rotates across projects so only 1 claude call runs at a time
# 2-3 claude calls per project per rotation

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.sh"
source "$SCRIPT_DIR/../lib/queue.sh"

# ── Parse projects from brief ──
readarray -t PROJECT_LINES < <(parse_brief_projects)

if [ "${#PROJECT_LINES[@]}" -eq 0 ] || [ -z "${PROJECT_LINES[0]}" ]; then
  # Fallback to single project from env
  echo "No projects in brief.md. Using TARGET_PROJECT=$TARGET_PROJECT"
  PROJECT_LINES=("${TARGET_PROJECT}|${PROJECT_PATH}|General improvements")
fi

# Parse into arrays
declare -a PROJECT_NAMES=()
declare -a PROJECT_PATHS=()
declare -a PROJECT_FOCUS=()
declare -A PROJECT_DONE=()

for line in "${PROJECT_LINES[@]}"; do
  IFS='|' read -r name path focus <<< "$line"
  PROJECT_NAMES+=("$name")
  PROJECT_PATHS+=("$path")
  PROJECT_FOCUS+=("$focus")
  PROJECT_DONE["$name"]=false
done

NUM_PROJECTS="${#PROJECT_NAMES[@]}"

# Load global brief sections (constraints, context, etc.)
GLOBAL_BRIEF="$(parse_brief_global)"

echo "╔══════════════════════════════════════════════╗"
echo "║  LEAN CONDUCTOR — Multi-Project              ║"
echo "║  Max cycles: $MAX_CYCLES (total, round-robin) ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Projects:"
for i in "${!PROJECT_NAMES[@]}"; do
  echo "    [$((i+1))] ${PROJECT_NAMES[$i]} → ${PROJECT_FOCUS[$i]}"
done
echo ""

# ── Helper: run one project cycle ──
run_project_cycle() {
  local proj_name="$1"
  local proj_path="$2"
  local proj_focus="$3"
  local cycle="$4"

  echo ""
  echo "  ┌─ $proj_name ─────────────────────────"

  # Load previous cycle results for this project
  local prev_results=""
  local summary_file="$STATE_DIR/cycle-summary-${proj_name}.md"
  if [ -f "$summary_file" ]; then
    prev_results="$(cat "$summary_file")"
  fi

  # ── SCOUT ──
  echo "  │ [1/3] Scout → finding work..."
  log_event "conductor" "scout" "$proj_name (cycle $cycle)"

  enqueue "scout" "conductor" "scout-${proj_name}-cycle-${cycle}" \
    "Target project: $proj_name
Project path: $proj_path
Workspace root: $WORKSPACE_DIR
Cycle: $cycle of $MAX_CYCLES

## Project Focus
$proj_focus

## Global Directives
$GLOBAL_BRIEF

## Previous Cycles for $proj_name
$prev_results

Read the project state and produce a build spec for the single most valuable next change.
Stay within the project focus above. Respect all constraints and Do NOT Touch rules.
If this project's goals are met, output <promise>COMPLETE</promise>."

  if ! wait_for_message "conductor" 600; then
    echo "  │ Scout timed out."
    log_event "conductor" "timeout" "scout $proj_name"
    echo "  └──────────────────────────────────"
    return 1
  fi

  local scout_result
  scout_result="$(consume "conductor")"

  # Check completion
  if echo "$scout_result" | grep -q "<promise>COMPLETE</promise>"; then
    echo "  │ Scout: $proj_name goals met. Done."
    log_event "conductor" "complete" "$proj_name done at cycle $cycle"
    PROJECT_DONE["$proj_name"]=true
    echo "  └──────────────────────────────────"
    return 0
  fi

  echo "  │ Scout delivered spec."
  echo "$scout_result" | grep -E "^### What|^### Why" | head -2 | sed 's/^/  │   /'

  # ── BUILD ──
  echo "  │ [2/3] Builder → implementing..."
  log_event "conductor" "build" "$proj_name (cycle $cycle)"

  enqueue "builder" "conductor" "build-${proj_name}-cycle-${cycle}" \
    "Project path: $proj_path

$scout_result"

  if ! wait_for_message "conductor" 900; then
    echo "  │ Builder timed out."
    log_event "conductor" "timeout" "builder $proj_name"
    echo "  └──────────────────────────────────"
    return 1
  fi

  local build_result
  build_result="$(consume "conductor")"
  echo "  │ Builder finished."

  if echo "$build_result" | grep -qi "BLOCKED"; then
    echo "  │ Builder BLOCKED. Skipping verify."
    log_event "conductor" "blocked" "builder $proj_name cycle $cycle"
    echo "  └──────────────────────────────────"
    return 1
  fi

  # ── VERIFY (bash only) ──
  echo "  │ [3/3] Verify..."
  log_event "conductor" "verify" "$proj_name (cycle $cycle)"

  local verify_pass=true

  # Check uncommitted changes
  if cd "$proj_path" 2>/dev/null; then
    local uncommitted
    uncommitted="$(git status --porcelain 2>/dev/null | wc -l || echo 0)"
    if [ "$uncommitted" -gt 0 ]; then
      echo "  │   WARN: $uncommitted uncommitted files — auto-committing"
      git add -A && git commit -m "chore: auto-commit from overnight cycle $cycle" 2>/dev/null || true
    fi
    echo "  │   Last commit: $(git log --oneline -1 2>/dev/null || echo 'none')"
  fi

  # Build check
  if [ -f "$proj_path/package.json" ]; then
    if cd "$proj_path" && npm run build --if-present >/dev/null 2>&1; then
      echo "  │   Build: PASS"
    else
      echo "  │   Build: FAIL"
      verify_pass=false
    fi
  fi

  # If verify failed, send fix to builder
  if [ "$verify_pass" = false ]; then
    echo "  │   Sending fix task to builder..."
    log_event "conductor" "verify_fail" "$proj_name cycle $cycle"

    enqueue "builder" "conductor" "fix-${proj_name}-cycle-${cycle}" \
      "Project path: $proj_path

The build failed after your changes. Read the error output and fix the issue.
Do not revert — fix forward. Commit the fix.

Original spec:
$scout_result"

    if wait_for_message "conductor" 600; then
      consume "conductor" > /dev/null
      echo "  │   Fix applied."
      log_event "conductor" "fix_applied" "$proj_name cycle $cycle"
    fi
  else
    log_event "conductor" "verify_pass" "$proj_name cycle $cycle"
  fi

  # Record cycle summary for this project
  {
    echo "### Cycle $cycle ($(date +%H:%M))"
    echo "$scout_result" | grep -E "^### What" -A 1 | head -2
    echo "$build_result" | grep -E "^### Verdict|^### Changes|^### Commit" -A 1 | head -6
    echo ""
  } >> "$summary_file"

  echo "  └──────────────────────────────────"
  log_event "conductor" "cycle_done" "$proj_name cycle $cycle"
  return 0
}

# ── Check if all projects are done ──
all_done() {
  for name in "${PROJECT_NAMES[@]}"; do
    if [ "${PROJECT_DONE[$name]}" = false ]; then
      return 1
    fi
  done
  return 0
}

# ── MAIN LOOP — Round-robin across projects ──
while is_running; do
  cycle="$(next_cycle)"

  if [ "$cycle" -gt "$MAX_CYCLES" ]; then
    echo ""
    echo "Max cycles ($MAX_CYCLES) reached."
    stop_loop
    break
  fi

  echo ""
  echo "═══════════════════════════════════════"
  echo "  ROTATION $cycle / $MAX_CYCLES — $(date +%H:%M:%S)"
  echo "═══════════════════════════════════════"

  # Rotate through all active projects
  for i in "${!PROJECT_NAMES[@]}"; do
    local_name="${PROJECT_NAMES[$i]}"
    local_path="${PROJECT_PATHS[$i]}"
    local_focus="${PROJECT_FOCUS[$i]}"

    # Skip completed projects
    if [ "${PROJECT_DONE[$local_name]}" = true ]; then
      echo "  [$local_name] — already complete, skipping"
      continue
    fi

    run_project_cycle "$local_name" "$local_path" "$local_focus" "$cycle"

    # Check if loop was stopped externally
    if ! is_running; then
      break
    fi

    # Small pause between projects (rate limit safety)
    sleep 3
  done

  # Check if all projects are done
  if all_done; then
    echo ""
    echo "All projects completed their goals!"
    stop_loop
    break
  fi

  sleep 2
done

# ── Final summary ──
echo ""
echo "═══════════════════════════════════════"
echo "  OVERNIGHT RUN COMPLETE"
echo "  Rotations: $(get_cycle)"
echo "═══════════════════════════════════════"
echo ""
echo "  Project Status:"
for i in "${!PROJECT_NAMES[@]}"; do
  local_name="${PROJECT_NAMES[$i]}"
  if [ "${PROJECT_DONE[$local_name]}" = true ]; then
    echo "    ✓ $local_name — COMPLETE"
  else
    echo "    ○ $local_name — in progress"
  fi
done
echo ""

# Per-project summaries
for i in "${!PROJECT_NAMES[@]}"; do
  local_name="${PROJECT_NAMES[$i]}"
  local summary_file="$STATE_DIR/cycle-summary-${local_name}.md"
  if [ -f "$summary_file" ]; then
    echo "  --- $local_name summary ---"
    cat "$summary_file" | head -30
    echo ""
  fi
done

log_event "conductor" "shutdown" "$(get_cycle) rotations, ${#PROJECT_NAMES[@]} projects"
