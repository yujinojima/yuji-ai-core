#!/bin/bash
# Budget Tracker — Tracks USD cost per 5-hour window
# Uses actual cost_usd from claude JSON output (already discounted for caching)

# Expects $TRADE_DIR and $STATE_DIR to be set by config.sh

BUDGET_FILE="$STATE_DIR/budget.json"
COST_MODEL_FILE="$STATE_DIR/cost-model.json"

# 5-hour session window in seconds
WINDOW_SECONDS=$((5 * 3600))

# Session budget in USD (Max 20x: ~$8 per window is safe)
SESSION_BUDGET_USD="${SESSION_BUDGET_USD:-8.00}"

# Stop threshold: stop when we've used this much of the budget
STOP_THRESHOLD="${STOP_THRESHOLD:-70}"  # percent

# Get budget in cents (for integer math)
budget_cents() {
  # Convert $8.00 → 800
  awk -v b="$SESSION_BUDGET_USD" 'BEGIN{printf "%d", b*100}'
}

init_budget() {
  if [ ! -f "$BUDGET_FILE" ]; then
    echo '{"window_start":0,"cost_cents":0,"cycles_run":0,"last_reset":0}' > "$BUDGET_FILE"
  fi
  if [ ! -f "$COST_MODEL_FILE" ]; then
    cat > "$COST_MODEL_FILE" <<'EOF'
{
  "opus_analyst": {"samples":[], "avg_cents":350, "count":0},
  "sonnet_analyst": {"samples":[], "avg_cents":50, "count":0},
  "sonnet_implementer": {"samples":[], "avg_cents":45, "count":0}
}
EOF
  fi
}

# Check if current window has expired and reset if needed
check_window_reset() {
  local now
  now="$(date +%s)"
  local window_start
  window_start="$(jq -r '.window_start' "$BUDGET_FILE")"

  if [ "$window_start" -eq 0 ] || [ $((now - window_start)) -ge "$WINDOW_SECONDS" ]; then
    jq --arg now "$now" '.window_start = ($now|tonumber) | .cost_cents = 0 | .cycles_run = 0 | .last_reset = ($now|tonumber)' \
      "$BUDGET_FILE" > "$BUDGET_FILE.tmp" && mv "$BUDGET_FILE.tmp" "$BUDGET_FILE"
  fi
  return 0
}

# Get current window cost (in cents)
get_budget_used_cents() {
  check_window_reset
  jq -r '.cost_cents' "$BUDGET_FILE"
}

# Get percentage used
get_budget_percent() {
  local used budget_c
  used="$(get_budget_used_cents)"
  budget_c="$(budget_cents)"
  echo "$((used * 100 / budget_c))"
}

# Get seconds remaining in window
get_window_remaining() {
  local now
  now="$(date +%s)"
  local window_start
  window_start="$(jq -r '.window_start' "$BUDGET_FILE")"
  if [ "$window_start" -eq 0 ]; then
    echo "$WINDOW_SECONDS"
    return
  fi
  local elapsed=$((now - window_start))
  local remaining=$((WINDOW_SECONDS - elapsed))
  if [ "$remaining" -lt 0 ]; then
    echo 0
  else
    echo "$remaining"
  fi
}

# Record actual cost from claude JSON output
# Args: <role> <model> <cost_usd>
record_usage() {
  local role="$1"
  local model="$2"
  local cost_usd="$3"

  # Convert USD to cents (integer)
  local cost_cents
  cost_cents="$(awk -v c="$cost_usd" 'BEGIN{printf "%d", c*100}')"

  check_window_reset

  # Update budget file
  jq --argjson c "$cost_cents" '.cost_cents += $c | .cycles_run += 1' \
    "$BUDGET_FILE" > "$BUDGET_FILE.tmp" && mv "$BUDGET_FILE.tmp" "$BUDGET_FILE"

  # Update cost model — rolling average of last 10 samples
  local key="${model}_${role}"
  jq --arg k "$key" --argjson c "$cost_cents" '
    if .[$k] then
      .[$k].samples += [$c]
      | .[$k].samples = (.[$k].samples | if length > 10 then .[1:] else . end)
      | .[$k].count += 1
      | .[$k].avg_cents = ((.[$k].samples | add) / (.[$k].samples | length) | floor)
    else
      .[$k] = {"samples":[$c], "avg_cents":$c, "count":1}
    end
  ' "$COST_MODEL_FILE" > "$COST_MODEL_FILE.tmp" && mv "$COST_MODEL_FILE.tmp" "$COST_MODEL_FILE"
}

# Extract cost from claude JSON output
extract_cost() {
  local json="$1"
  echo "$json" | jq -r '.total_cost_usd // 0' 2>/dev/null || echo 0
}

# Get estimated cost for a cycle (analyst + implementer) in cents
estimate_cycle_cost() {
  local analyst_model="$1"
  local implementer_model="$2"

  local analyst_avg implementer_avg
  analyst_avg="$(jq -r ".${analyst_model}_analyst.avg_cents // 350" "$COST_MODEL_FILE")"
  implementer_avg="$(jq -r ".${implementer_model}_implementer.avg_cents // 45" "$COST_MODEL_FILE")"

  echo $((analyst_avg + implementer_avg))
}

# Decide: should we run another cycle?
decide_next_cycle() {
  local used_cents percent budget_c
  used_cents="$(get_budget_used_cents)"
  budget_c="$(budget_cents)"
  percent="$((used_cents * 100 / budget_c))"

  if [ "$percent" -ge "$STOP_THRESHOLD" ]; then
    echo "stop"
    return
  fi

  local stop_at=$((budget_c * STOP_THRESHOLD / 100))
  local headroom=$((stop_at - used_cents))

  # Estimate next cycle cost
  local opus_cost sonnet_cost
  opus_cost="$(estimate_cycle_cost opus sonnet)"
  sonnet_cost="$(estimate_cycle_cost sonnet sonnet)"

  # Prefer Opus if it fits, otherwise Sonnet, otherwise stop
  if [ "$opus_cost" -le "$headroom" ]; then
    echo "run opus"
  elif [ "$sonnet_cost" -le "$headroom" ]; then
    echo "run sonnet"
  else
    echo "stop"
  fi
}

# Print budget status
show_budget() {
  check_window_reset
  local used_cents percent remaining cycles
  used_cents="$(get_budget_used_cents)"
  percent="$(get_budget_percent)"
  remaining="$(get_window_remaining)"
  cycles="$(jq -r '.cycles_run' "$BUDGET_FILE")"

  printf "  Budget: \$%.2f / \$%s (%d%%)\n" "$(awk "BEGIN{print $used_cents/100}")" "$SESSION_BUDGET_USD" "$percent"
  echo "  Stop at: ${STOP_THRESHOLD}%"
  echo "  Cycles this window: $cycles"
  echo "  Window resets in: $((remaining / 60)) min"
  echo ""
  echo "  Cost model (from recent runs):"
  jq -r 'to_entries[] | "    \(.key): ~$\(.value.avg_cents / 100 | floor).\(.value.avg_cents % 100) (\(.value.count) samples)"' "$COST_MODEL_FILE"
}
