#!/bin/bash
# TradePractice — Cron-safe launcher
# Skips if already running. Always launches otherwise.
# The session pool is separate per 5-hour window, so running alongside
# an interactive session is fine — they share the pool but don't conflict.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$SCRIPT_DIR/cron.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

# Skip if tradepractice tmux session already running
if tmux has-session -t tradepractice 2>/dev/null; then
  log "SKIP: tradepractice session already running"
  exit 0
fi

log "LAUNCH: starting tradepractice (window $(date +%H:%M))"
cd "$SCRIPT_DIR" && /bin/bash -l ./launch.sh >> "$LOG" 2>&1
