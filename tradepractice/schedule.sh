#!/bin/bash
# TradePractice — Scheduled Launcher
# Waits until a specified time, then launches tradepractice
#
# Usage:
#   ./schedule.sh                     # Launch after next session reset (~5hr window)
#   ./schedule.sh 02:00               # Launch at 2:00 AM local time
#   ./schedule.sh +90m                # Launch in 90 minutes
#   ./schedule.sh now                 # Launch immediately

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults
LAUNCH_ARGS="${LAUNCH_EXTRA_ARGS:-}"
MODEL_ANALYST="${MODEL_ANALYST:-sonnet}"
MAX_CYCLES="${MAX_CYCLES:-6}"

parse_time() {
  local input="$1"

  case "$input" in
    now)
      echo 0
      ;;
    +*m)
      # +90m → 90 minutes
      local mins="${input#+}"
      mins="${mins%m}"
      echo "$((mins * 60))"
      ;;
    +*h)
      # +2h → 2 hours
      local hrs="${input#+}"
      hrs="${hrs%h}"
      echo "$((hrs * 3600))"
      ;;
    *)
      # HH:MM → seconds until that time
      local target_epoch
      target_epoch="$(date -d "today $input" +%s 2>/dev/null || date -d "tomorrow $input" +%s)"
      local now_epoch
      now_epoch="$(date +%s)"
      local diff=$((target_epoch - now_epoch))
      if [ "$diff" -lt 0 ]; then
        # Time already passed today, schedule for tomorrow
        diff=$((diff + 86400))
      fi
      echo "$diff"
      ;;
  esac
}

WHEN="${1:-+90m}"
WAIT_SECONDS="$(parse_time "$WHEN")"

if [ "$WAIT_SECONDS" -le 0 ]; then
  echo "Launching immediately..."
  export MODEL_ANALYST MAX_CYCLES
  exec "$SCRIPT_DIR/launch.sh"
fi

WAIT_MINS=$((WAIT_SECONDS / 60))
LAUNCH_TIME="$(date -d "+${WAIT_SECONDS} seconds" +%H:%M 2>/dev/null || date -v+${WAIT_SECONDS}S +%H:%M)"

echo "╔══════════════════════════════════════════════╗"
echo "║  TRADEPRACTICE — SCHEDULED                    ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Launch at:    $LAUNCH_TIME (in ${WAIT_MINS} minutes)"
echo "  Analyst:      $MODEL_ANALYST"
echo "  Cycles:       $MAX_CYCLES"
echo ""
echo "  Waiting... (Ctrl+C to cancel)"
echo ""

# Countdown with periodic status
elapsed=0
while [ "$elapsed" -lt "$WAIT_SECONDS" ]; do
  remaining=$(( (WAIT_SECONDS - elapsed) / 60 ))
  printf "\r  ⏳ %d min remaining...  " "$remaining"
  sleep 30
  elapsed=$((elapsed + 30))
done

echo ""
echo ""
echo "Window open. Launching tradepractice..."
echo ""

export MODEL_ANALYST MAX_CYCLES
exec "$SCRIPT_DIR/launch.sh"
