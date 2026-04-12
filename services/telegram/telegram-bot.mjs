/**
 * Tron Telegram Bot — main entry point.
 *
 * Usage:
 *   TELEGRAM_BOT_TOKEN=xxx TELEGRAM_ALLOWED_CHAT_ID=123 node telegram-bot.mjs
 *
 * Or source a .env file first.
 */

import { createClient } from './telegram-client.mjs';
import { createAuth } from './telegram-auth.mjs';
import {
  parseCommand,
  handleCommand,
  setTaskRunner,
  setLastError,
} from './telegram-commands.mjs';
import { runClaude } from './telegram-runner.mjs';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const STATE_FILE = join(__dirname, '.last-update-id');

// ── Config ──────────────────────────────────────────────
const TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const ALLOWED_CHAT_ID = process.env.TELEGRAM_ALLOWED_CHAT_ID;
const ALLOWED_USER_ID = process.env.TELEGRAM_ALLOWED_USER_ID;
const POLL_TIMEOUT = 30; // seconds (Telegram long-poll)

if (!TOKEN) {
  console.error('❌ TELEGRAM_BOT_TOKEN not set. Exiting.');
  process.exit(1);
}

// ── Init ────────────────────────────────────────────────
const client = createClient(TOKEN);
const auth = createAuth({
  allowedChatId: ALLOWED_CHAT_ID,
  allowedUserId: ALLOWED_USER_ID,
});

let lastUpdateId = loadLastUpdateId();
let running = true;

// ── Public API for integration ──────────────────────────

/** Send a plain-text notification to the authorized chat. */
export async function notify(text) {
  if (!ALLOWED_CHAT_ID) {
    console.warn('[telegram] No ALLOWED_CHAT_ID — cannot send notification');
    return;
  }
  const chatId = ALLOWED_CHAT_ID.split(',')[0].trim();
  await client.sendMessage(chatId, text);
  console.log(`[telegram] → sent: ${text.slice(0, 80)}`);
}

export { setTaskRunner };

// ── Polling loop ────────────────────────────────────────

async function poll() {
  while (running) {
    try {
      const updates = await client.getUpdates(lastUpdateId + 1, POLL_TIMEOUT);

      for (const update of updates) {
        // Duplicate / old update guard
        if (update.update_id <= lastUpdateId) continue;
        lastUpdateId = update.update_id;
        saveLastUpdateId(lastUpdateId);

        const msg = update.message;
        if (!msg) continue;

        // Auth check
        if (!auth.isAuthorized(msg)) {
          console.log(
            `[telegram] ✗ unauthorized: user=${msg.from?.id} chat=${msg.chat?.id}`
          );
          continue;
        }

        console.log(
          `[telegram] ← ${msg.from?.username || msg.from?.id}: ${msg.text || '(non-text)'}`
        );

        // Command handling
        const parsed = parseCommand(msg.text);
        if (parsed) {
          const reply = await handleCommand(parsed);
          await client.sendMessage(msg.chat.id, reply);
          console.log(`[telegram] → reply: ${reply.slice(0, 80)}`);
        } else if (msg.text) {
          // Plain text → route through Claude as a Tron request
          await client.sendMessage(msg.chat.id, '⏳ Thinking…');
          try {
            const reply = await runClaude(msg.text);
            await client.sendMessage(msg.chat.id, reply);
            console.log(`[telegram] → claude reply: ${reply.slice(0, 80)}`);
          } catch (err) {
            setLastError(String(err.message || err));
            await client.sendMessage(msg.chat.id, `❌ ${err.message}`);
            console.error(`[telegram] claude error: ${err.message}`);
          }
        }
      }
    } catch (err) {
      setLastError(String(err.message || err));
      console.error(`[telegram] poll error: ${err.message}`);
      // Back off on error
      await sleep(5000);
    }
  }
}

// ── Lifecycle ───────────────────────────────────────────

async function start() {
  try {
    const me = await client.getMe();
    console.log(`[telegram] Bot online: @${me.username} (${me.id})`);
  } catch (err) {
    console.error(`[telegram] Failed to connect: ${err.message}`);
    process.exit(1);
  }

  // Connect /run to Claude
  setTaskRunner(runClaude);

  // Startup notification (may fail if user hasn't messaged the bot yet)
  try {
    await notify('Tron is online ✅');
  } catch (err) {
    console.warn(
      `[telegram] Could not send startup message: ${err.message}`
    );
    console.warn(
      '[telegram] Tip: message the bot first in Telegram, then restart.'
    );
  }

  // Start polling
  poll();
}

function shutdown() {
  console.log('[telegram] Shutting down…');
  running = false;
  notify('Tron is going offline 🔴').catch(() => {});
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

// ── Helpers ─────────────────────────────────────────────

function loadLastUpdateId() {
  try {
    if (existsSync(STATE_FILE)) {
      return parseInt(readFileSync(STATE_FILE, 'utf8').trim(), 10) || 0;
    }
  } catch {}
  return 0;
}

function saveLastUpdateId(id) {
  try {
    writeFileSync(STATE_FILE, String(id), 'utf8');
  } catch {}
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

// ── Hourly Paper Trade Checkpoints ──────────────────────

const CHECKPOINT_INTERVAL_MS = 60 * 60 * 1000; // 1 hour
let checkpointTimer = null;

async function runCheckpoint() {
  console.log('[telegram] ⏰ Running hourly paper trade checkpoint…');
  try {
    const prompt =
      'Hourly paper trade checkpoint. Check:\n' +
      '1. Freqtrade live dry-run — open positions, recent trades, P&L, any errors\n' +
      '2. Polymarket bot dry-run — markets scanned, simulated trades, any errors\n' +
      'Send a compact status summary. Flag anything needing attention.';
    const reply = await runClaude(prompt);
    await notify(`⏰ Hourly Trade Checkpoint\n\n${reply}`);
    console.log('[telegram] ✅ Checkpoint sent');
  } catch (err) {
    console.error(`[telegram] ❌ Checkpoint failed: ${err.message}`);
    try {
      await notify(`⏰ Checkpoint failed: ${err.message}`);
    } catch {}
  }
}

function startCheckpoints() {
  // First checkpoint 17 minutes after startup, then every hour
  const now = new Date();
  const minutesPastHour = now.getMinutes();
  const targetMinute = 17;
  let delayMs;
  if (minutesPastHour < targetMinute) {
    delayMs = (targetMinute - minutesPastHour) * 60 * 1000 - now.getSeconds() * 1000;
  } else {
    delayMs = (60 - minutesPastHour + targetMinute) * 60 * 1000 - now.getSeconds() * 1000;
  }

  console.log(`[telegram] ⏰ First checkpoint in ${Math.round(delayMs / 60000)} min (at :${targetMinute})`);

  setTimeout(() => {
    runCheckpoint();
    checkpointTimer = setInterval(runCheckpoint, CHECKPOINT_INTERVAL_MS);
  }, delayMs);
}

// ── Run ─────────────────────────────────────────────────
start();
startCheckpoints();
