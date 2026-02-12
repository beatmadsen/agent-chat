import { MessageFeed, renderMessageFeed } from './message_feed.js';

export { MessageFeed } from './message_feed.js';

let currentFeed = new MessageFeed();

export function getConsumer() {
  const params = new URLSearchParams(window.location.search);
  return params.get('consumer') || 'web user';
}

export async function fetchAndRenderMessages(room) {
  const response = await fetch(`/api/rooms/${room}/messages`);
  const messages = await response.json();

  currentFeed = new MessageFeed();
  currentFeed.setMessages(messages);
  renderMessageFeed(currentFeed, document.getElementById('messages'));

  return currentFeed.count;
}

export async function fetchAndAppendNewMessages(room, consumer) {
  const response = await fetch(`/api/rooms/${room}/messages/new?consumer=${encodeURIComponent(consumer)}`);
  const messages = await response.json();

  currentFeed.appendMessages(messages);
  renderMessageFeed(currentFeed, document.getElementById('messages'));

  return currentFeed.count;
}

export async function postMessage(room, author, content) {
  await fetch(`/api/rooms/${room}/messages`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ author, content })
  });

  currentFeed.messages.push({ author, content, optimistic: true });
  renderMessageFeed(currentFeed, document.getElementById('messages'));

  return currentFeed.count;
}

export function createKeyDownHandler(form) {
  return function(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
    }
  };
}
