#!/bin/bash
# File-based message queue for inter-agent communication

# Ensure state directories exist
init_queue() {
  mkdir -p "$INBOX_DIR"/{conductor,ideator,researcher,builder,reviewer}
  echo "running" > "$STATUS_FILE"
  echo "0" > "$CYCLE_FILE"
}

# Check if loop should keep running
is_running() {
  [ -f "$STATUS_FILE" ] && [ "$(cat "$STATUS_FILE" 2>/dev/null)" = "running" ]
}

# Send a message to an agent's inbox
# Usage: enqueue <recipient> <sender> <subject> <body>
enqueue() {
  local recipient="$1"
  local sender="$2"
  local subject="$3"
  local body="$4"
  local timestamp
  timestamp="$(date +%s%N)"
  local filename="${timestamp}-${sender}-${subject}.md"
  local filepath="$INBOX_DIR/$recipient/$filename"

  cat > "$filepath" <<MSGEOF
---
from: $sender
subject: $subject
timestamp: $(date -Iseconds)
cycle: $(cat "$CYCLE_FILE" 2>/dev/null || echo 0)
---

$body
MSGEOF

  log_event "$sender" "enqueued" "→ $recipient: $subject"
  echo "$filepath"
}

# Read the oldest message from an agent's inbox (FIFO)
# Returns the file path, or empty if no messages
dequeue() {
  local agent="$1"
  local inbox="$INBOX_DIR/$agent"
  local oldest
  oldest="$(ls -1t "$inbox"/*.md 2>/dev/null | tail -1)"
  echo "$oldest"
}

# Read and remove the oldest message.
# Optional 2nd arg: expected_sender — when set, drains any messages from other
# senders (logged as "drain") and returns the oldest matching one. Without it,
# behaviour is unchanged (FIFO across all senders).
# Added 2026-04-26 to fix queue cross-contamination in tradepractice/conductor.sh.
consume() {
  local agent="$1"
  local expected_sender="${2:-}"

  if [ -n "$expected_sender" ]; then
    local msg wrong_sender
    for msg in $(ls -1tr "$INBOX_DIR/$agent"/*.md 2>/dev/null); do
      if grep -q "^from: $expected_sender\$" "$msg" 2>/dev/null; then
        cat "$msg"
        rm -f "$msg"
        return 0
      fi
      # Wrong sender — drain it so it can't poison the next cycle.
      wrong_sender="$(grep '^from:' "$msg" 2>/dev/null | head -1 | awk '{print $2}')"
      log_event "$agent" "drain" "discarded stale msg from ${wrong_sender:-unknown} (expected $expected_sender)"
      rm -f "$msg"
    done
    return 1
  fi

  # Original behaviour (no source filter).
  local msg
  msg="$(dequeue "$agent")"
  if [ -n "$msg" ] && [ -f "$msg" ]; then
    cat "$msg"
    rm "$msg"
  fi
}

# Check if an agent has pending messages
has_messages() {
  local agent="$1"
  local count
  count="$(ls -1 "$INBOX_DIR/$agent"/*.md 2>/dev/null | wc -l)"
  [ "$count" -gt 0 ]
}

# Count messages in an agent's inbox
message_count() {
  local agent="$1"
  ls -1 "$INBOX_DIR/$agent"/*.md 2>/dev/null | wc -l
}

# Get current cycle
get_cycle() {
  cat "$CYCLE_FILE" 2>/dev/null || echo 0
}

# Increment cycle
next_cycle() {
  local current
  current="$(get_cycle)"
  echo $((current + 1)) > "$CYCLE_FILE"
  get_cycle
}

# Log an event to the overnight log
log_event() {
  local agent="$1"
  local action="$2"
  local detail="$3"
  local ts
  ts="$(date -Iseconds)"
  local cycle
  cycle="$(get_cycle)"

  echo "{\"ts\":\"$ts\",\"cycle\":$cycle,\"agent\":\"$agent\",\"action\":\"$action\",\"detail\":\"$detail\"}" >> "$LOG_FILE"
}

# Signal graceful stop
stop_loop() {
  echo "stopped" > "$STATUS_FILE"
  log_event "system" "stop" "Graceful shutdown requested"
}

# Wait for a message in an agent's inbox (blocking with timeout)
# Usage: wait_for_message <agent> [timeout_seconds] [expected_sender]
# Added 2026-04-26: when expected_sender is set, only counts messages from that
# sender as "arrived" (matches the new consume() filter). Without it, original
# any-sender behaviour. Backward-compatible with overnight.
wait_for_message() {
  local agent="$1"
  local timeout="${2:-300}"
  local expected_sender="${3:-}"
  local elapsed=0

  while is_running; do
    if [ -n "$expected_sender" ]; then
      # Check if there's a message from the expected sender specifically.
      local msg
      for msg in $(ls -1tr "$INBOX_DIR/$agent"/*.md 2>/dev/null); do
        if grep -q "^from: $expected_sender\$" "$msg" 2>/dev/null; then
          return 0
        fi
      done
    elif has_messages "$agent"; then
      return 0
    fi
    sleep "$POLL_INTERVAL"
    elapsed=$((elapsed + POLL_INTERVAL))
    if [ "$elapsed" -ge "$timeout" ]; then
      log_event "$agent" "timeout" "No message received in ${timeout}s${expected_sender:+ (from $expected_sender)}"
      return 1
    fi
  done

  is_running
}
