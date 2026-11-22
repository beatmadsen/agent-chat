import { MessageFeed } from './feed/message_feed.js';
import { renderMessageFeed } from './feed/message_view.js';

let currentFeed = new MessageFeed();

export async function fetchAndRenderMessages(room, consumer) {
  const url = consumer
    ? `/api/rooms/${room}/messages?consumer=${encodeURIComponent(consumer)}`
    : `/api/rooms/${room}/messages`;
  const response = await fetch(url);
  currentFeed = new MessageFeed();
  show(await response.json());
  return currentFeed.count;
}

export async function fetchAndAppendNewMessages(room, consumer) {
  const response = await fetch(`/api/rooms/${room}/messages/new?consumer=${encodeURIComponent(consumer)}`);
  show(await response.json());
  return currentFeed.count;
}

export async function postMessage(room, author, content, replyTo = []) {
  const answer = await sendJson(`/api/rooms/${room}/messages`, { author, content, reply_to: replyTo });
  if (answer.status !== 'accepted') return { count: currentFeed.count, error: answer.error.message };

  show([{ id: answer.assigned_id, author, content, timestamp: new Date().toISOString(), reply_to: replyTo }]);
  return { count: currentFeed.count, error: null };
}

function show(messages) {
  const added = currentFeed.appendMessages(messages);
  if (added.length > 0 || currentFeed.count === 0) {
    renderMessageFeed(currentFeed, document.getElementById('messages'));
  }
}

async function sendJson(url, body) {
  const response = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  const failed = { status: 'failed', error: { message: `The server could not take the message (HTTP ${response.status})` } };
  return response.json().catch(() => failed);
}
