#!/bin/bash
# ralph-cron.sh — 3-hourly cron entrypoint for tradepractice research loop.
#
# Each invocation:
#   1. If a session is still active → SKIP (no overlap). Zombies get killed.
#   2. If the previous run ended and we haven't summarised it → print summary.
#   3. Launch a fresh tmux session with MAX_CYCLES=5 using the new charter.
#
# Constraints (user directive 2026-04-25):
#   - tradepractice only (NOT millionaire)
#   - fixed MAX_CYCLES=5 per run (no adaptive loops)
#   - no parallel sessions
#   - no dynamic escalation
#
# Crontab (every 3h, user):
#   0 */3 * * * /home/yuji/Desktop/Yuji\ Project/ai-core/tradepractice/ralph-cron.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Cron has a minimal PATH — restore what the tradepractice stack needs.
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

LOG="$SCRIPT_DIR/cron-ralph.log"
LAST_START="$SCRIPT_DIR/state/last_run_start.txt"
LAST_END="$SCRIPT_DIR/state/last_run_end.txt"
LAST_SUMMARY_MARK="$SCRIPT_DIR/state/last_run_summary.marker"
STATUS_FILE="$SCRIPT_DIR/state/status.txt"
ACTIVITY_LOG="$SCRIPT_DIR/state/log.jsonl"
SESSION_NAME="tradepractice"
MAX_CYCLES=5   # Rolled back 2026-04-26 from 7→5. Reinstate 7 only after 2 clean runs.
ZOMBIE_IDLE_SECS=900   # 15 min of no activity = zombie

# Phase 5 token-budget guard: 400k tokens / 5h window puts current ~280k load at
# 70% utilization, with soft warn (75% = 300k) and hard cap (85% = 340k) tight
# enough to bind. Override per-environment via cron line if needed.
export TOKEN_BUDGET_PER_WINDOW="${TOKEN_BUDGET_PER_WINDOW:-400000}"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG" >&2
}

# ── Phase 1: summarise the previous run if it has ended since our last summary ──
maybe_summarise_previous() {
  [ -f "$LAST_START" ] || return 0
  [ -f "$LAST_END" ] || return 0
  if [ -f "$LAST_SUMMARY_MARK" ] && [ "$LAST_SUMMARY_MARK" -nt "$LAST_END" ]; then
    return 0
  fi
  local since until
  since="$(cat "$LAST_START")"
  until="$(cat "$LAST_END")"
  log "SUMMARY: generating report for window $since .. $until"
  bash "$SCRIPT_DIR/run-summary.sh" "$since" "$until" >> "$LOG" 2>&1 || {
    log "SUMMARY: run-summary.sh failed (exit $?)"
    return 0
  }
  touch "$LAST_SUMMARY_MARK"
}

# If a tmux session exists AND the conductor has exited, mark the end time.
record_end_if_session_done() {
  if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    # Session vanished; if we have a start without an end, record now.
    if [ -f "$LAST_START" ] && [ ! -f "$LAST_END" ]; then
      date -u +%Y-%m-%dT%H:%M:%SZ > "$LAST_END"
      log "END: recorded session-end timestamp"
    fi
    return 0
  fi
  # Session exists — check if status file says stopped (conductor finished).
  if [ -f "$STATUS_FILE" ] && [ "$(cat "$STATUS_FILE")" = "stopped" ]; then
    if [ -f "$LAST_START" ] && [ ! -f "$LAST_END" ]; then
      date -u +%Y-%m-%dT%H:%M:%SZ > "$LAST_END"
      log "END: conductor reported stopped"
    fi
  fi
}

# ── Phase 2: overlap / zombie check ──
session_is_active() {
  tmux has-session -t "$SESSION_NAME" 2>/dev/null
}

is_zombie() {
  # Zombie if status=stopped OR no activity in ZOMBIE_IDLE_SECS.
  if [ -f "$STATUS_FILE" ] && [ "$(cat "$STATUS_FILE")" = "stopped" ]; then
    return 0
  fi
  if [ -f "$ACTIVITY_LOG" ]; then
    local last_epoch now_epoch
    last_epoch="$(tail -1 "$ACTIVITY_LOG" | jq -r '.ts' 2>/dev/null | xargs -I{} date -d {} +%s 2>/dev/null || echo 0)"
    now_epoch="$(date +%s)"
    if [ "$last_epoch" -gt 0 ] && [ $((now_epoch - last_epoch)) -gt "$ZOMBIE_IDLE_SECS" ]; then
      return 0
    fi
  fi
  return 1
}

# ── Phase 2.5: refresh the score-driven control data ──
refresh_scores() {
  log "SCORES: regenerating primitive_scores.csv"
  /usr/bin/python3 \
    "/home/yuji/Desktop/Yuji Project/scripts/build_primitive_scores.py" \
    >> "$LOG" 2>&1 || log "SCORES: regeneration failed (non-fatal)"
}

# ── Phase 5 token-budget guard ──
# Returns 0 = proceed (sonnet), 1 = proceed (haiku downgrade), 2 = skip tick.
# Exposes ANALYST_MODEL_FOR_RUN as a side-effect so launch_fresh_run picks it up.
ANALYST_MODEL_FOR_RUN="sonnet"
check_token_budget() {
  local report rc
  report=$(/usr/bin/python3 \
    "/home/yuji/Desktop/Yuji Project/scripts/token_tracker.py" 2>&1)
  rc=$?
  log "TOKEN: $report"
  case $rc in
    2)
      log "TOKEN: HARD_CAP (≥85%) — skipping this tick"
      return 2
      ;;
    1)
      log "TOKEN: SOFT_WARN (≥75%) — analyst downgraded to haiku for this run"
      ANALYST_MODEL_FOR_RUN="haiku"
      return 0
      ;;
    *)
      ANALYST_MODEL_FOR_RUN="sonnet"
      return 0
      ;;
  esac
}

# ── Phase 3: launch a fresh 5-cycle run ──
launch_fresh_run() {
  refresh_scores
  log "LAUNCH: MAX_CYCLES=$MAX_CYCLES analyst=$ANALYST_MODEL_FOR_RUN (tradepractice only, new charter)"
  # Reset end/summary markers; record start.
  rm -f "$LAST_END" "$LAST_SUMMARY_MARK"
  date -u +%Y-%m-%dT%H:%M:%SZ > "$LAST_START"
  cd "$SCRIPT_DIR"
  # launch.sh backgrounds the tmux session; it returns quickly.
  MAX_CYCLES=$MAX_CYCLES \
    MODEL_ANALYST="$ANALYST_MODEL_FOR_RUN" \
    MODEL_IMPLEMENTER=sonnet \
    bash ./launch.sh >> "$LOG" 2>&1 || {
    log "LAUNCH FAILED (exit $?)"
    return 1
  }
  log "LAUNCH OK"
}

# ── Main ──
log "TICK"

record_end_if_session_done
maybe_summarise_previous

if session_is_active; then
  if is_zombie; then
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
    log "KILLED zombie session"
    # Record end for zombie so next tick summarises it.
    [ -f "$LAST_START" ] && [ ! -f "$LAST_END" ] && date -u +%Y-%m-%dT%H:%M:%SZ > "$LAST_END"
  else
    log "SKIP: active session in progress — not starting a new run"
    exit 0
  fi
fi

# Phase 5 — token-budget guard. Hard-cap exits before launch; soft-warn falls
# through with $ANALYST_MODEL_FOR_RUN already downgraded.
if ! check_token_budget; then
  exit 0
fi

launch_fresh_run
