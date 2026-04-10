/**
 * Authorization — only respond to approved users/chats.
 */

export function createAuth({ allowedChatId, allowedUserId }) {
  const chatIds = parseIds(allowedChatId);
  const userIds = parseIds(allowedUserId);

  function isAuthorized(message) {
    if (!message?.from) return false;
    const userId = String(message.from.id);
    const chatId = String(message.chat.id);

    if (userIds.size > 0 && !userIds.has(userId)) return false;
    if (chatIds.size > 0 && !chatIds.has(chatId)) return false;
    // If neither is configured, deny all
    if (userIds.size === 0 && chatIds.size === 0) return false;

    return true;
  }

  return { isAuthorized };
}

function parseIds(value) {
  if (!value) return new Set();
  return new Set(
    String(value)
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean)
  );
}
