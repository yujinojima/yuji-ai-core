#!/bin/bash
# Conductor (Tron) — Orchestrates the overnight pipeline
# Runs in tmux pane 0. Manages cycle progression and agent routing.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.sh"
source "$SCRIPT_DIR/../lib/queue.sh"

PROMPT_FILE="$OVERNIGHT_DIR/prompts/conductor.md"

echo "=== CONDUCTOR (Tron) starting ==="
echo "Project: $TARGET_PROJECT ($PROJECT_PATH)"
echo "Max cycles: $MAX_CYCLES"
echo ""

run_claude() {
  local prompt="$1"
  local model="${2:-$MODEL_CONDUCTOR}"
  echo "$prompt" | "$CLAUDE_BIN" --dangerously-skip-permissions --print --model "$model" 2>/dev/null || true
}

# Read project state for context
read_project_state() {
  local state=""

  # Git status
  if [ -d "$PROJECT_PATH/.git" ]; then
    state+="## Git Status\n"
    state+="$(cd "$PROJECT_PATH" && git log --oneline -5 2>/dev/null || echo 'No recent commits')\n\n"
  fi

  # PRD if exists
  if [ -f "$PROJECT_PATH/prd.json" ]; then
    state+="## PRD (Current Stories)\n"
    state+="$(cat "$PROJECT_PATH/prd.json" | jq -r '.stories[]? | "- [\(.status)] \(.title)"' 2>/dev/null || echo 'No stories')\n\n"
  fi

  # Progress if exists
  if [ -f "$PROJECT_PATH/progress.txt" ]; then
    state+="## Recent Progress\n"
    state+="$(tail -20 "$PROJECT_PATH/progress.txt" 2>/dev/null || echo 'No progress file')\n\n"
  fi

  # CLAUDE.md for project context
  if [ -f "$PROJECT_PATH/CLAUDE.md" ]; then
    state+="## Project CLAUDE.md (first 50 lines)\n"
    state+="$(head -50 "$PROJECT_PATH/CLAUDE.md" 2>/dev/null)\n\n"
  fi

  echo -e "$state"
}

# === MAIN LOOP ===
while is_running; do
  cycle="$(next_cycle)"

  if [ "$cycle" -gt "$MAX_CYCLES" ]; then
    echo ""
    echo "=== Max cycles ($MAX_CYCLES) reached. Stopping. ==="
    stop_loop
    break
  fi

  echo ""
  echo "╔══════════════════════════════════════════╗"
  echo "║  CYCLE $cycle of $MAX_CYCLES"
  echo "╚══════════════════════════════════════════╝"

  project_state="$(read_project_state)"

  # ── PHASE 1: IDEATION ──────────────────────────────
  echo ""
  echo "── Phase 1: Ideation ──"
  log_event "conductor" "phase_start" "ideation (cycle $cycle)"

  conductor_prompt="$(cat "$PROMPT_FILE")

## Current Project State
$project_state

## Your Task (Cycle $cycle)
Analyse the current project state. Generate a brief for the Ideator agent.
Focus on: what improvements, features, or fixes would be most valuable right now?
Consider the PRD stories, recent progress, and any gaps you see.

Output ONLY the ideation brief — no preamble. Start with '## Ideation Brief'."

  brief="$(run_claude "$conductor_prompt")"
  echo "$brief" | head -5
  enqueue "ideator" "conductor" "ideate-cycle-$cycle" "$brief"

  # Wait for Ideator result
  echo "  Waiting for Ideator..."
  if ! wait_for_message "conductor" 600; then
    echo "  Ideator timed out. Skipping to next cycle."
    log_event "conductor" "timeout" "ideator did not respond"
    continue
  fi
  ideas="$(consume "conductor")"
  echo "  Got ideas from Ideator."

  # ── PHASE 2: RESEARCH ──────────────────────────────
  echo ""
  echo "── Phase 2: Research ──"
  log_event "conductor" "phase_start" "research (cycle $cycle)"

  # Conductor picks best ideas and creates research tasks
  pick_prompt="$(cat "$PROMPT_FILE")

## Ideas from Ideator
$ideas

## Your Task
Pick the top 1-2 ideas that are most actionable and valuable.
Create a research brief for the Researcher to validate feasibility and approach.

Output ONLY the research brief — no preamble. Start with '## Research Brief'."

  research_brief="$(run_claude "$pick_prompt")"
  echo "$research_brief" | head -5
  enqueue "researcher" "conductor" "research-cycle-$cycle" "$research_brief"

  # Wait for Researcher result
  echo "  Waiting for Researcher..."
  if ! wait_for_message "conductor" 600; then
    echo "  Researcher timed out. Proceeding with ideas as-is."
    log_event "conductor" "timeout" "researcher did not respond"
    research_result="(Research skipped due to timeout)"
  else
    research_result="$(consume "conductor")"
    echo "  Got research from Researcher."
  fi

  # ── PHASE 3: BUILD ─────────────────────────────────
  echo ""
  echo "── Phase 3: Build ──"
  log_event "conductor" "phase_start" "build (cycle $cycle)"

  # Conductor creates implementation tasks
  build_prompt="$(cat "$PROMPT_FILE")

## Selected Ideas
$ideas

## Research Findings
$research_result

## Project State
$project_state

## Your Task
Create a detailed implementation brief for the Builder agent.
Include: what to build, which files to modify, acceptance criteria.
The Builder works in: $PROJECT_PATH
Keep the scope small — one meaningful change per cycle.

Output ONLY the build brief — no preamble. Start with '## Build Brief'."

  build_brief="$(run_claude "$build_prompt")"
  echo "$build_brief" | head -5
  enqueue "builder" "conductor" "build-cycle-$cycle" "$build_brief"

  # Wait for Builder result
  echo "  Waiting for Builder..."
  if ! wait_for_message "conductor" 900; then
    echo "  Builder timed out."
    log_event "conductor" "timeout" "builder did not respond"
    continue
  fi
  build_result="$(consume "conductor")"
  echo "  Builder finished."

  # ── PHASE 4: REVIEW ────────────────────────────────
  echo ""
  echo "── Phase 4: Review ──"
  log_event "conductor" "phase_start" "review (cycle $cycle)"

  review_brief="## Review Brief

### What was built
$build_brief

### Builder's output
$build_result

### Project path
$PROJECT_PATH

Review the changes. Check for:
1. Code quality and correctness
2. Security issues
3. Missing error handling
4. Test coverage
5. Whether the implementation matches the brief

Output a review report with PASS, WARN, or FAIL verdict."

  enqueue "reviewer" "conductor" "review-cycle-$cycle" "$review_brief"

  # Wait for Reviewer result
  echo "  Waiting for Reviewer..."
  if ! wait_for_message "conductor" 600; then
    echo "  Reviewer timed out."
    log_event "conductor" "timeout" "reviewer did not respond"
  else
    review_result="$(consume "conductor")"
    echo "  Review complete."

    # Check if review failed — send fixes back to builder
    if echo "$review_result" | grep -qi "FAIL"; then
      echo "  Review FAILED. Sending fixes to Builder..."
      log_event "conductor" "review_fail" "cycle $cycle"

      fix_brief="## Fix Brief

### Original build brief
$build_brief

### Review feedback (FAILED)
$review_result

Fix the issues identified in the review. Work in: $PROJECT_PATH
Commit the fixes with a clear message."

      enqueue "builder" "conductor" "fix-cycle-$cycle" "$fix_brief"

      if wait_for_message "conductor" 600; then
        consume "conductor" > /dev/null
        echo "  Fixes applied."
        log_event "conductor" "fix_applied" "cycle $cycle"
      fi
    else
      echo "  Review PASSED."
      log_event "conductor" "review_pass" "cycle $cycle"
    fi
  fi

  # ── CYCLE COMPLETE ─────────────────────────────────
  echo ""
  echo "=== Cycle $cycle complete ==="
  log_event "conductor" "cycle_complete" "cycle $cycle"

  sleep 2
done

echo ""
echo "=== CONDUCTOR stopped ==="
echo "Completed $(get_cycle) cycles."
log_event "conductor" "shutdown" "$(get_cycle) cycles completed"
