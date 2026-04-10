#!/bin/bash
# TradePractice — Smart Cron Launcher with zombie detection
# If a tmux session exists but isn't actively processing, kill and restart.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$SCRIPT_DIR/cron.log"
STATUS_FILE="$SCRIPT_DIR/state/status.txt"
LOG_FILE="$SCRIPT_DIR/state/log.jsonl"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

# Check for tmux session
if tmux has-session -t tradepractice 2>/dev/null; then
  # Zombie detection: if status is "stopped" OR last log entry > 10 min old, kill it
  should_kill=false

  if [ -f "$STATUS_FILE" ] && [ "$(cat "$STATUS_FILE")" = "stopped" ]; then
    should_kill=true
    log "ZOMBIE: status=stopped but tmux still exists"
  elif [ -f "$LOG_FILE" ]; then
    last_log_epoch="$(tail -1 "$LOG_FILE" | jq -r '.ts' 2>/dev/null | xargs -I{} date -d {} +%s 2>/dev/null || echo 0)"
    now_epoch="$(date +%s)"
    if [ "$last_log_epoch" -gt 0 ] && [ $((now_epoch - last_log_epoch)) -gt 600 ]; then
      should_kill=true
      log "ZOMBIE: no log activity for $(( (now_epoch - last_log_epoch) / 60 )) min"
    fi
  fi

  if [ "$should_kill" = true ]; then
    tmux kill-session -t tradepractice 2>/dev/null || true
    log "KILLED zombie session, proceeding with launch"
  else
    log "SKIP: tradepractice actively running"
    exit 0
  fi
fi

log "LAUNCH: starting smart tradepractice (window $(date +%H:%M))"
cd "$SCRIPT_DIR" && /bin/bash -l ./smart-launch.sh >> "$LOG" 2>&1
