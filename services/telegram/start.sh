#!/usr/bin/env bash
# Start Tron Telegram bot as a background process

DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$DIR/.env"
LOG_FILE="$DIR/bot.log"
PID_FILE="$DIR/.bot.pid"

# Check for existing process
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "⚠️  Bot is already running (PID $(cat "$PID_FILE"))"
  echo "   Run ./stop.sh first to restart."
  exit 1
fi

# Load env
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ No .env file found. Copy .env.example and fill in your values."
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
  echo "❌ TELEGRAM_BOT_TOKEN not set in .env"
  exit 1
fi

# Start
nohup node "$DIR/telegram-bot.mjs" >> "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"

echo "✅ Tron Telegram bot started (PID $!)"
echo "   Logs: $LOG_FILE"
echo "   Stop: ./stop.sh"
