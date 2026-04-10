#!/bin/bash
# TradePractice Conductor
# Alternates: Assess → Research → Implement → Backtest → Record
# Each cycle targets one project (alternating freqtrade / polymarket)
# Knowledge accumulates across windows

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.sh"
source "$SCRIPT_DIR/../lib/queue.sh"

# ── Load brief ──
brief_content=""
if [ -f "$BRIEF_FILE" ]; then
  brief_content="$(cat "$BRIEF_FILE")"
fi

# ── Load accumulated knowledge ──
load_knowledge() {
  local project="$1"
  local knowledge=""

  # Load existing prims (structured knowledge)
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

  # Load conditions log
  if [ -f "$KNOWLEDGE_DIR/conditions-log.md" ]; then
    knowledge+="\n## Conditions Log\n"
    knowledge+="$(cat "$KNOWLEDGE_DIR/conditions-log.md")\n"
  fi

  # Load raw research findings
  local kdir="$KNOWLEDGE_DIR/$project"
  for f in "$kdir"/*.md; do
    [ -f "$f" ] || continue
    knowledge+="\n## Research: $(basename "$f" .md)\n"
    knowledge+="$(cat "$f")\n"
  done

  echo -e "$knowledge"
}

# ── Save prim ──
save_prim() {
  local project="$1"
  local title="$2"
  local level="$3"
  local content="$4"
  local pdir="$KNOWLEDGE_DIR/$project/prims/$level"
  local filename="$(echo "$title" | tr ' ' '-' | tr -cd 'a-zA-Z0-9-' | head -c 50).md"

  mkdir -p "$pdir"
  echo "$content" > "$pdir/$filename"
  log_event "conductor" "prim_saved" "$project/$level: $filename"
}

# ── Save raw research finding ──
save_knowledge() {
  local project="$1"
  local title="$2"
  local content="$3"
  local kdir="$KNOWLEDGE_DIR/$project"
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M)"
  local filename="${timestamp}-$(echo "$title" | tr ' ' '-' | tr -cd 'a-zA-Z0-9-' | head -c 50).md"

  mkdir -p "$kdir"
  echo "$content" > "$kdir/$filename"
  log_event "conductor" "knowledge_saved" "$project: $filename"
}

# ── Extract prim level from analyst output ──
extract_prim_level() {
  local content="$1"
  local level
  level="$(echo "$content" | grep -oP '\*\*Level:\*\*\s*\K(naive|intermediate|sophisticated)' | head -1)"
  echo "${level:-naive}"
}

# ── Extract prim name from analyst output ──
extract_prim_name() {
  local content="$1"
  local name
  name="$(echo "$content" | grep -oP '## Prim: \K.*' | head -1)"
  echo "${name:-unnamed-prim}"
}

echo "╔══════════════════════════════════════════════╗"
echo "║  TRADEPRACTICE — Strategy Optimisation        ║"
echo "║  Max cycles: $MAX_CYCLES                      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Projects alternate each cycle
PROJECTS=("freqtrade" "polymarket")
PROJECT_DIRS=("$FREQTRADE_DIR" "$POLYMARKET_DIR")

# ── MAIN LOOP ──
while is_running; do
  cycle="$(next_cycle)"

  if [ "$cycle" -gt "$MAX_CYCLES" ]; then
    echo "Max cycles reached."
    stop_loop
    break
  fi

  # Alternate projects
  proj_idx=$(( (cycle - 1) % ${#PROJECTS[@]} ))
  project="${PROJECTS[$proj_idx]}"
  project_dir="${PROJECT_DIRS[$proj_idx]}"

  echo ""
  echo "═══════════════════════════════════════"
  echo "  CYCLE $cycle / $MAX_CYCLES — $project — $(date +%H:%M:%S)"
  echo "═══════════════════════════════════════"

  knowledge="$(load_knowledge "$project")"

  # ── PHASE 1: ASSESS + RESEARCH (single analyst call) ──
  echo ""
  echo "  [1/3] Analyst → assessing + researching $project..."
  log_event "conductor" "analyst" "$project (cycle $cycle)"

  # Build analyst task based on epistemic maturity
  naive_count="$(find "$KNOWLEDGE_DIR/$project/prims/naive" -name '*.md' 2>/dev/null | wc -l)"
  intermediate_count="$(find "$KNOWLEDGE_DIR/$project/prims/intermediate" -name '*.md' 2>/dev/null | wc -l)"
  sophisticated_count="$(find "$KNOWLEDGE_DIR/$project/prims/sophisticated" -name '*.md' 2>/dev/null | wc -l)"
  total_prims=$((naive_count + intermediate_count + sophisticated_count))
  research_count="$(find "$KNOWLEDGE_DIR/$project" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l)"

  if [ "$total_prims" -lt 3 ]; then
    # Early stage — build naive prims from current strategies
    analyst_mode="ASSESS"
    analyst_task="Mode: ASSESS

Read the current $project strategies and extract naive trading primitives (p-prims).
Project path: $project_dir
Prim template: $KNOWLEDGE_DIR/prim-template.md

Current knowledge ($total_prims prims, $research_count raw findings):
$knowledge

## Brief
$brief_content

Read the strategy files. For each key entry/exit rule, create a NAIVE prim.
Start simple — one rule per prim. Document what you know and what you DON'T know.
Output ONE prim in the format from the analyst prompt."
  elif [ "$naive_count" -gt "$intermediate_count" ]; then
    # Have naive prims — refine them with research
    analyst_mode="RESEARCH"
    analyst_task="Mode: RESEARCH

You have $naive_count naive, $intermediate_count intermediate, $sophisticated_count sophisticated prims.
PRIORITY: Refine a naive prim to intermediate by finding its activation conditions.
Project path: $project_dir

$knowledge

## Brief
$brief_content

Pick the naive prim with the least documented conditions.
Search for evidence: when does it work? When does it fail?
Output an INTERMEDIATE prim that refines it. Set parent_prim to the naive one."
  else
    # Have intermediate prims — refine to sophisticated or find new angles
    analyst_mode="RESEARCH"
    analyst_task="Mode: RESEARCH

You have $naive_count naive, $intermediate_count intermediate, $sophisticated_count sophisticated prims.
PRIORITY: Either refine an intermediate prim to sophisticated, or find a new angle entirely.
Project path: $project_dir

$knowledge

## Brief
$brief_content

For refinement: add regime awareness, multi-timeframe confirmation, documented failure modes.
For new angles: search papers, GitHub, forums for approaches not yet in the prim bank.
Output ONE prim at the appropriate level."
  fi

  enqueue "analyst" "conductor" "analyst-${project}-cycle-${cycle}" "$analyst_task"

  if ! wait_for_message "conductor" 600; then
    echo "  Analyst timed out."
    log_event "conductor" "timeout" "analyst $project"
    continue
  fi

  analyst_result="$(consume "conductor")"
  echo "  Analyst delivered finding."
  echo "$analyst_result" | grep -E "^## Prim:|^## Finding:|^### Rule|^### Key Insight" | head -2 | sed 's/^/    /' || true

  # Save output — route prim vs raw research
  prim_name="$(extract_prim_name "$analyst_result")"
  prim_level="$(extract_prim_level "$analyst_result")"

  if [ "$prim_name" != "unnamed-prim" ]; then
    # Structured prim — save to prims/level/
    save_prim "$project" "$prim_name" "$prim_level" "$analyst_result"
    echo "    Prim saved: $prim_level/$prim_name"

    # Append to conditions log if conditions section exists
    if echo "$analyst_result" | grep -q "### Conditions Log Entry"; then
      {
        echo ""
        echo "## $prim_name ($prim_level) — $(date +%Y-%m-%d)"
        echo "$analyst_result" | sed -n '/### Conditions Log Entry/,/^###/p' | grep -v "^### Conditions Log Entry" | grep -v "^###" || true
      } >> "$KNOWLEDGE_DIR/conditions-log.md"
      echo "    Conditions log updated."
    fi
  else
    # Raw research finding
    finding_title="$(echo "$analyst_result" | grep -oP '## Finding: \K.*' | head -1 | tr ' ' '-' | tr -cd 'a-zA-Z0-9-' | head -c 50)"
    [ -z "$finding_title" ] && finding_title="finding-cycle-$cycle"
    save_knowledge "$project" "$finding_title" "$analyst_result"
    echo "    Research finding saved."
  fi

  # ── PHASE 2: IMPLEMENT ──
  echo ""
  echo "  [2/3] Implementer → applying to $project..."
  log_event "conductor" "implementer" "$project (cycle $cycle)"

  implement_task="Project: $project
Project path: $project_dir

## Analyst Finding to Implement
$analyst_result

## Instructions
Apply this finding to the strategy code. Make the minimum change needed.
If the finding suggests a parameter change, update the parameter with a comment citing the source.
If it suggests a new indicator, add it following existing patterns.

After implementing:
- For freqtrade: run a backtest if possible
- For polymarket: run the scanner tool to verify no errors
- Commit with a descriptive message

If the finding is purely research (no code change needed), output SKIP."

  enqueue "implementer" "conductor" "implement-${project}-cycle-${cycle}" "$implement_task"

  if ! wait_for_message "conductor" 900; then
    echo "  Implementer timed out."
    log_event "conductor" "timeout" "implementer $project"
    continue
  fi

  impl_result="$(consume "conductor")"

  if echo "$impl_result" | grep -qi "SKIP"; then
    echo "  Implementer: research-only finding, no code change."
    log_event "conductor" "skip" "no code change for $project cycle $cycle"
  else
    echo "  Implementer finished."
    echo "$impl_result" | grep -E "^### Changes|^### Backtest|^### Commit" | head -3 | sed 's/^/    /' || true

    # ── PHASE 3: VERIFY (bash) ──
    echo ""
    echo "  [3/3] Verify..."

    if [ "$project" = "freqtrade" ]; then
      # Check strategy files parse correctly
      if cd "$project_dir" 2>/dev/null; then
        uncommitted="$(git status --porcelain 2>/dev/null | wc -l || echo 0)"
        if [ "$uncommitted" -gt 0 ]; then
          git add -A && git commit -m "chore: auto-commit tradepractice cycle $cycle ($project)" 2>/dev/null || true
        fi
        echo "    Last commit: $(git log --oneline -1 2>/dev/null)"
      fi
    elif [ "$project" = "polymarket" ]; then
      if cd "$project_dir" 2>/dev/null; then
        # Quick syntax check
        python3 -m py_compile src/strategies/arb.py 2>/dev/null && echo "    arb.py: OK" || echo "    arb.py: SYNTAX ERROR"
        python3 -m py_compile src/strategies/spread.py 2>/dev/null && echo "    spread.py: OK" || echo "    spread.py: SYNTAX ERROR"

        uncommitted="$(git status --porcelain 2>/dev/null | wc -l || echo 0)"
        if [ "$uncommitted" -gt 0 ]; then
          git add -A && git commit -m "chore: auto-commit tradepractice cycle $cycle ($project)" 2>/dev/null || true
        fi
        echo "    Last commit: $(git log --oneline -1 2>/dev/null)"
      fi
    fi

    log_event "conductor" "verify" "$project cycle $cycle"
  fi

  # ── Record cycle summary ──
  {
    echo "### Cycle $cycle — $project ($(date +%H:%M))"
    echo "Mode: $analyst_mode"
    echo "$analyst_result" | grep -E "^## Prim:|^## Finding|^### Rule|^### Key Insight|^### Confidence" | head -3 || true
    echo "$impl_result" | grep -E "^### Changes|^### Backtest Results" -A 3 | head -6 || true
    echo ""
  } >> "$STATE_DIR/session-summary.md"

  echo ""
  echo "  Cycle $cycle complete ($project)."
  log_event "conductor" "cycle_complete" "$project cycle $cycle"

  sleep 3
done

# ── Final Report ──
echo ""
echo "═══════════════════════════════════════"
echo "  TRADEPRACTICE SESSION COMPLETE"
echo "  Cycles: $(get_cycle)"
echo "═══════════════════════════════════════"
echo ""

# Show knowledge stats
for proj in "${PROJECTS[@]}"; do
  count="$(ls -1 "$KNOWLEDGE_DIR/$proj"/*.md 2>/dev/null | wc -l || echo 0)"
  echo "  $proj: $count research findings accumulated"
done

echo ""
if [ -f "$STATE_DIR/session-summary.md" ]; then
  echo "  Session summary:"
  cat "$STATE_DIR/session-summary.md"
fi

log_event "conductor" "shutdown" "$(get_cycle) cycles completed"
