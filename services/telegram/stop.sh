#!/usr/bin/env bash
# Stop Tron Telegram bot

DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$DIR/.bot.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "No PID file found — bot may not be running."
  exit 0
fi

PID=$(cat "$PID_FILE")

if kill -0 "$PID" 2>/dev/null; then
  kill "$PID"
  echo "✅ Bot stopped (PID $PID)"
else
  echo "⚠️  Process $PID not found — already stopped."
fi

rm -f "$PID_FILE"
