#!/bin/bash
# TradePractice — Smart Cron Launcher
# Skips if already running. Uses smart launcher which auto-stops at budget threshold.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$SCRIPT_DIR/cron.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

if tmux has-session -t tradepractice 2>/dev/null; then
  log "SKIP: tradepractice session already running"
  exit 0
fi

log "LAUNCH: starting smart tradepractice (window $(date +%H:%M))"
cd "$SCRIPT_DIR" && /bin/bash -l ./smart-launch.sh >> "$LOG" 2>&1
