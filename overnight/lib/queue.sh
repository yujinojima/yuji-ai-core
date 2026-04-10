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

# Read and remove the oldest message
consume() {
  local agent="$1"
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
# Usage: wait_for_message <agent> [timeout_seconds]
wait_for_message() {
  local agent="$1"
  local timeout="${2:-300}"
  local elapsed=0

  while ! has_messages "$agent" && is_running; do
    sleep "$POLL_INTERVAL"
    elapsed=$((elapsed + POLL_INTERVAL))
    if [ "$elapsed" -ge "$timeout" ]; then
      log_event "$agent" "timeout" "No message received in ${timeout}s"
      return 1
    fi
  done

  is_running
}
