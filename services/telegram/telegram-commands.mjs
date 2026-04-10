/**
 * Command parser and handler registry.
 */

import { appendFileSync } from 'node:fs';
import { join } from 'node:path';

const NOTES_FILE = join(
  process.env.HOME || '.',
  'Desktop/Yuji Project/ai-core/logs/telegram-notes.log'
);

const startTime = Date.now();
let lastError = null;
let activeTask = null;

// External hook — set by the bot to route /run commands
let taskRunner = null;

export function setTaskRunner(fn) {
  taskRunner = fn;
}

export function setActiveTask(task) {
  activeTask = task;
}

export function setLastError(err) {
  lastError = err;
}

/**
 * Parse a message into { command, args } or null.
 */
export function parseCommand(text) {
  if (!text || !text.startsWith('/')) return null;
  const [rawCmd, ...rest] = text.split(' ');
  const command = rawCmd.replace(/@\w+$/, '').toLowerCase(); // strip @botname
  return { command, args: rest.join(' ').trim() };
}

/**
 * Handle a parsed command. Returns reply text.
 */
export async function handleCommand({ command, args }) {
  switch (command) {
    case '/start':
      return '👋 Tron Telegram interface active. Type /help for commands.';

    case '/help':
      return [
        '*Available commands:*',
        '/start — Activate bot',
        '/help — Show this message',
        '/status — Current state',
        '/ping — Connectivity check',
        '/run <task> — Run a task',
        '/note <message> — Save a note',
      ].join('\n');

    case '/ping':
      return 'pong';

    case '/status': {
      const uptime = Math.floor((Date.now() - startTime) / 1000);
      const hrs = Math.floor(uptime / 3600);
      const mins = Math.floor((uptime % 3600) / 60);
      const secs = uptime % 60;
      return [
        `*Status:* Online`,
        `*Uptime:* ${hrs}h ${mins}m ${secs}s`,
        `*Active task:* ${activeTask || 'None'}`,
        `*Last error:* ${lastError || 'None'}`,
      ].join('\n');
    }

    case '/run': {
      if (!args) return '⚠️ Usage: /run <task description>';
      if (taskRunner) {
        try {
          setActiveTask(args);
          const result = await taskRunner(args);
          setActiveTask(null);
          return `✅ Task completed: ${result || args}`;
        } catch (err) {
          setLastError(String(err.message || err));
          setActiveTask(null);
          return `❌ Task failed: ${err.message || err}`;
        }
      }
      return `📋 Task queued (no runner attached): ${args}`;
    }

    case '/note': {
      if (!args) return '⚠️ Usage: /note <message>';
      const entry = `[${new Date().toISOString()}] ${args}\n`;
      try {
        appendFileSync(NOTES_FILE, entry, 'utf8');
        return `📝 Note saved.`;
      } catch (err) {
        return `⚠️ Could not save note: ${err.message}`;
      }
    }

    default:
      return `Unknown command: ${command}. Type /help for available commands.`;
  }
}
