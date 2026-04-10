/**
 * Telegram Bot API client — thin HTTP wrapper.
 * Uses Node.js https module with IPv4 forced (undici fetch times out on some networks).
 */

import https from 'node:https';

const BASE_URL = 'https://api.telegram.org/bot';

function httpPost(url, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const parsed = new URL(url);
    const req = https.request(
      {
        hostname: parsed.hostname,
        path: parsed.pathname,
        method: 'POST',
        family: 4,
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(data),
        },
        timeout: 60_000,
      },
      (res) => {
        let chunks = '';
        res.on('data', (c) => (chunks += c));
        res.on('end', () => {
          try {
            resolve(JSON.parse(chunks));
          } catch {
            reject(new Error(`Invalid JSON from Telegram: ${chunks.slice(0, 200)}`));
          }
        });
      },
    );
    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timed out'));
    });
    req.write(data);
    req.end();
  });
}

export function createClient(token) {
  if (!token) throw new Error('TELEGRAM_BOT_TOKEN is required');

  const apiUrl = `${BASE_URL}${token}`;

  async function call(method, body = {}) {
    const data = await httpPost(`${apiUrl}/${method}`, body);
    if (!data.ok) {
      throw new Error(`Telegram API error [${method}]: ${data.description}`);
    }
    return data.result;
  }

  return {
    getMe: () => call('getMe'),

    getUpdates: (offset, timeout = 30) =>
      call('getUpdates', { offset, timeout, allowed_updates: ['message'] }),

    sendMessage: (chatId, text) =>
      call('sendMessage', { chat_id: chatId, text }),

    sendMarkdown: (chatId, text) =>
      call('sendMessage', {
        chat_id: chatId,
        text,
        parse_mode: 'MarkdownV2',
      }),
  };
}
