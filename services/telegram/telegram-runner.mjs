/**
 * Task runner that pipes commands into Claude Code via `claude -p`.
 * This bridges Telegram → Claude so Tron can actually process requests.
 */

import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);

const CLAUDE_BIN = process.env.CLAUDE_BIN || 'claude';
const PROJECT_DIR =
  process.env.TRON_PROJECT_DIR ||
  `${process.env.HOME}/Desktop/Yuji Project`;
const MAX_RESPONSE_LENGTH = 4000; // Telegram message limit ~4096

/**
 * Run a prompt through Claude Code and return the response.
 */
export async function runClaude(prompt) {
  const fullPrompt = `You are Tron, the workspace orchestrator. The user is messaging you via Telegram. Be concise — Telegram has a 4096 char limit. Respond directly.\n\nUser request: ${prompt}`;

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
    if (!response) return '(no response from Claude)';

    // Truncate for Telegram
    if (response.length > MAX_RESPONSE_LENGTH) {
      response = response.slice(0, MAX_RESPONSE_LENGTH - 20) + '\n\n…(truncated)';
    }

    return response;
  } catch (err) {
    if (err.killed) {
      throw new Error('Request timed out (5 min limit)');
    }
    throw new Error(`Claude error: ${err.message}`);
  }
}
