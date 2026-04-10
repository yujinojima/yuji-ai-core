#!/bin/bash
# Reset the budget tracker — use when you see the Claude UI session has refreshed
# but our internal tracker hasn't caught up

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

if [ ! -f "$STATE_DIR/budget.json" ]; then
  echo "No budget file to reset."
  exit 0
fi

OLD_USED="$(jq -r '.cost_cents' "$STATE_DIR/budget.json")"
OLD_CYCLES="$(jq -r '.cycles_run' "$STATE_DIR/budget.json")"

NOW="$(date +%s)"
jq --arg now "$NOW" '.window_start = ($now|tonumber) | .cost_cents = 0 | .cycles_run = 0 | .last_reset = ($now|tonumber)' \
  "$STATE_DIR/budget.json" > "$STATE_DIR/budget.json.tmp" && mv "$STATE_DIR/budget.json.tmp" "$STATE_DIR/budget.json"

echo "Budget reset."
echo "  Previous window: \$$(awk "BEGIN{print $OLD_USED/100}") used, $OLD_CYCLES cycles"
echo "  New window starts: $(date)"
