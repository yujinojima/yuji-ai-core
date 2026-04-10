# Tron Telegram Bot

Lightweight Telegram integration for Tron — receive commands and send status notifications.

## Setup

### 1. Create the bot

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot`
3. Choose a name (e.g. "Tron Assistant") and username (e.g. `tron_yuji_bot`)
4. BotFather gives you a token like `123456:ABC-DEF...` — copy it

### 2. Get your user/chat ID

1. Message [@userinfobot](https://t.me/userinfobot) on Telegram
2. It replies with your user ID (a number like `123456789`)
3. For private chats, chat ID = user ID

### 3. Configure environment

```bash
cp .env.example .env
```

Fill in:
```
TELEGRAM_BOT_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
TELEGRAM_ALLOWED_USER_ID=123456789
TELEGRAM_ALLOWED_CHAT_ID=123456789
```

### 4. Run

```bash
# From this directory
source .env && node telegram-bot.mjs

# Or export vars and run from anywhere
export TELEGRAM_BOT_TOKEN=...
export TELEGRAM_ALLOWED_USER_ID=...
export TELEGRAM_ALLOWED_CHAT_ID=...
node ai-core/services/telegram/telegram-bot.mjs
```

The bot sends "Tron is online ✅" on startup.

## Commands

| Command | Description |
|---------|-------------|
| `/start` | Activate the bot |
| `/help` | List available commands |
| `/status` | Show uptime, active task, last error |
| `/ping` | Connectivity check (replies "pong") |
| `/run <task>` | Run a task through Tron |
| `/note <message>` | Save a note to `ai-core/logs/telegram-notes.log` |

## Architecture

```
telegram/
├── telegram-bot.mjs       # Entry point — polling loop, lifecycle
├── telegram-client.mjs    # Raw Telegram Bot API HTTP calls
├── telegram-auth.mjs      # User/chat authorization
├── telegram-commands.mjs  # Command parsing and handlers
├── .env.example           # Environment variable template
├── .last-update-id        # Auto-generated — tracks processed updates
└── README.md
```

## Integration

The bot exports two functions for use by other modules:

```js
import { notify, setTaskRunner } from './telegram-bot.mjs';

// Send a notification
await notify('Task completed ✅');

// Hook up a task runner for /run commands
setTaskRunner(async (taskDescription) => {
  // your logic here
  return 'done';
});
```

## Security

- Only responds to messages from authorized user/chat IDs
- Unauthorized messages are silently ignored (logged locally)
- Bot token loaded from environment only — never hardcoded
- State file (`.last-update-id`) is gitignored
