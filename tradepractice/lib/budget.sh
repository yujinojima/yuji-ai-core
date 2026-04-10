#!/bin/bash
# Budget Tracker — Records actual token usage per cycle
# Tracks 5-hour rolling windows, predicts next cycle cost, decides model

# Expects $TRADE_DIR and $STATE_DIR to be set by config.sh

BUDGET_FILE="$STATE_DIR/budget.json"
COST_MODEL_FILE="$STATE_DIR/cost-model.json"

# 5-hour session window in seconds
WINDOW_SECONDS=$((5 * 3600))

# Max 20x plan estimate: ~220k tokens per 5-hour session
SESSION_BUDGET="${SESSION_BUDGET:-220000}"

# Stop threshold: stop when we've used this much of the budget
STOP_THRESHOLD="${STOP_THRESHOLD:-70}"  # percent

init_budget() {
  if [ ! -f "$BUDGET_FILE" ]; then
    echo '{"window_start":0,"tokens_used":0,"cycles_run":0,"last_reset":0}' > "$BUDGET_FILE"
  fi
  if [ ! -f "$COST_MODEL_FILE" ]; then
    cat > "$COST_MODEL_FILE" <<'EOF'
{
  "opus_analyst": {"samples":[], "avg_tokens":40000, "count":0},
  "sonnet_analyst": {"samples":[], "avg_tokens":22000, "count":0},
  "opus_implementer": {"samples":[], "avg_tokens":30000, "count":0},
  "sonnet_implementer": {"samples":[], "avg_tokens":18000, "count":0}
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
    # Reset window
    jq --arg now "$now" '.window_start = ($now|tonumber) | .tokens_used = 0 | .cycles_run = 0 | .last_reset = ($now|tonumber)' \
      "$BUDGET_FILE" > "$BUDGET_FILE.tmp" && mv "$BUDGET_FILE.tmp" "$BUDGET_FILE"
  fi
  return 0
}

# Get current window usage
get_budget_used() {
  check_window_reset > /dev/null
  jq -r '.tokens_used' "$BUDGET_FILE"
}

# Get percentage used
get_budget_percent() {
  local used
  used="$(get_budget_used)"
  echo "$((used * 100 / SESSION_BUDGET))"
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

# Record actual token usage from claude JSON output
# Args: <role> <model> <tokens_used>
record_usage() {
  local role="$1"
  local model="$2"
  local tokens="$3"

  check_window_reset > /dev/null

  # Update budget file
  jq --argjson t "$tokens" '.tokens_used += $t | .cycles_run += 1' \
    "$BUDGET_FILE" > "$BUDGET_FILE.tmp" && mv "$BUDGET_FILE.tmp" "$BUDGET_FILE"

  # Update cost model — exponential moving average
  local key="${model}_${role}"
  jq --arg k "$key" --argjson t "$tokens" '
    if .[$k] then
      .[$k].samples += [$t]
      | .[$k].samples = (.[$k].samples | if length > 10 then .[1:] else . end)
      | .[$k].count += 1
      | .[$k].avg_tokens = ((.[$k].samples | add) / (.[$k].samples | length) | floor)
    else . end
  ' "$COST_MODEL_FILE" > "$COST_MODEL_FILE.tmp" && mv "$COST_MODEL_FILE.tmp" "$COST_MODEL_FILE"
}

# Extract token count from claude JSON output
# Reads from stdin, outputs total tokens (input + output + cache_creation)
extract_tokens() {
  local json="$1"
  # Parse last line (claude -p --output-format json outputs single JSON)
  local input_tokens cache_creation cache_read output_tokens
  input_tokens="$(echo "$json" | jq -r '.usage.input_tokens // 0' 2>/dev/null || echo 0)"
  cache_creation="$(echo "$json" | jq -r '.usage.cache_creation_input_tokens // 0' 2>/dev/null || echo 0)"
  cache_read="$(echo "$json" | jq -r '.usage.cache_read_input_tokens // 0' 2>/dev/null || echo 0)"
  output_tokens="$(echo "$json" | jq -r '.usage.output_tokens // 0' 2>/dev/null || echo 0)"

  # Total billable tokens (cache_read is discounted but counts)
  echo $((input_tokens + cache_creation + cache_read + output_tokens))
}

# Get estimated cost for a cycle (analyst + implementer)
estimate_cycle_cost() {
  local analyst_model="$1"
  local implementer_model="$2"

  local analyst_avg implementer_avg
  analyst_avg="$(jq -r ".${analyst_model}_analyst.avg_tokens" "$COST_MODEL_FILE")"
  implementer_avg="$(jq -r ".${implementer_model}_implementer.avg_tokens" "$COST_MODEL_FILE")"

  echo $((analyst_avg + implementer_avg))
}

# Decide: should we run another cycle?
# Returns: "run opus|run sonnet|stop"
decide_next_cycle() {
  local used percent remaining
  used="$(get_budget_used)"
  percent="$((used * 100 / SESSION_BUDGET))"

  # Already above stop threshold?
  if [ "$percent" -ge "$STOP_THRESHOLD" ]; then
    echo "stop"
    return
  fi

  remaining=$((SESSION_BUDGET - used))
  local stop_at=$((SESSION_BUDGET * STOP_THRESHOLD / 100))
  local headroom=$((stop_at - used))

  # Estimate next cycle cost for each model
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
  check_window_reset > /dev/null
  local used percent remaining cycles
  used="$(get_budget_used)"
  percent="$((used * 100 / SESSION_BUDGET))"
  remaining="$(get_window_remaining)"
  cycles="$(jq -r '.cycles_run' "$BUDGET_FILE")"

  echo "  Budget: $used / $SESSION_BUDGET tokens ($percent%)"
  echo "  Stop at: ${STOP_THRESHOLD}%"
  echo "  Cycles this window: $cycles"
  echo "  Window resets in: $((remaining / 60)) min"
  echo ""
  echo "  Cost model (from recent runs):"
  jq -r 'to_entries[] | "    \(.key): ~\(.value.avg_tokens) tokens (\(.value.count) samples)"' "$COST_MODEL_FILE"
}
