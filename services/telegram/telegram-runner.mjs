/**
 * Task runner that pipes commands into Claude Code via `claude -p`.
 * This bridges Telegram → Claude so Tron can actually process requests.
 */

import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const execFileAsync = promisify(execFile);

const CLAUDE_BIN = process.env.CLAUDE_BIN || 'claude';
const PROJECT_DIR =
  process.env.TRON_PROJECT_DIR ||
  `${process.env.HOME}/Desktop/Yuji Project`;
const MAX_RESPONSE_LENGTH = 4000; // Telegram message limit ~4096
const HISTORY_FILE = join(__dirname, 'message-history.json');
const MAX_HISTORY = 20; // keep last 20 exchanges for context

// ── Message History ─────────────────────────────────────

function loadHistory() {
  try {
    if (existsSync(HISTORY_FILE)) {
      return JSON.parse(readFileSync(HISTORY_FILE, 'utf8'));
    }
  } catch {}
  return [];
}

function saveHistory(history) {
  try {
    writeFileSync(HISTORY_FILE, JSON.stringify(history, null, 2), 'utf8');
  } catch (err) {
    console.error(`[runner] Failed to save history: ${err.message}`);
  }
}

function appendToHistory(userMsg, claudeReply) {
  const history = loadHistory();
  history.push({
    timestamp: new Date().toISOString(),
    user: userMsg,
    reply: claudeReply.slice(0, 500), // keep summaries compact
  });
  // Trim to last N entries
  while (history.length > MAX_HISTORY) history.shift();
  saveHistory(history);
}

function formatRecentHistory() {
  const history = loadHistory();
  if (history.length === 0) return '';
  const recent = history.slice(-5); // inject last 5 exchanges
  const lines = recent.map(
    (h) =>
      `[${h.timestamp}] User: ${h.user}\nTron: ${h.reply}`
  );
  return `\n\nRecent conversation history (for context continuity):\n---\n${lines.join('\n---\n')}\n---\n`;
}

/**
 * Run a prompt through Claude Code and return the response.
 */
export async function runClaude(prompt) {
  const history = formatRecentHistory();
  const fullPrompt = `You are Tron, the workspace orchestrator. The user is messaging you via Telegram. Be concise — Telegram has a 4096 char limit. Respond directly.${history}\nUser request: ${prompt}`;

  try {
    const { stdout, stderr } = await execFileAsync(
      CLAUDE_BIN,
      ['-p', '--output-format', 'text', fullPrompt],
      {
        cwd: PROJECT_DIR,
        timeout: 300_000, // 5 min max
        maxBuffer: 1024 * 1024,
        env: { ...process.env, FORCE_COLOR: '0' },
      }
    );

    if (stderr && !stderr.includes('no stdin data received')) {
      console.log(`[runner] stderr: ${stderr.slice(0, 200)}`);
    }

    let response = (stdout || '').trim();
    if (!response) response = '(no response from Claude)';

    // Truncate for Telegram
    if (response.length > MAX_RESPONSE_LENGTH) {
      response = response.slice(0, MAX_RESPONSE_LENGTH - 20) + '\n\n…(truncated)';
    }

    // Log exchange to history
    appendToHistory(prompt, response);

    return response;
  } catch (err) {
    if (err.killed) {
      throw new Error('Request timed out (5 min limit)');
    }
    throw new Error(`Claude error: ${err.message}`);
  }
}
