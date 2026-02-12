import { marked } from 'marked';

export class MessageFeed {
  constructor() {
    this.messages = [];
  }

  setMessages(messages) {
    this.messages = messages;
  }

  appendMessages(messages) {
    this.messages = this.messages.filter(m => !m.optimistic);
    const existing = new Set(this.messages.map(m => m.timestamp));
    const novel = messages.filter(m => !m.timestamp || !existing.has(m.timestamp));
    this.messages = [...this.messages, ...novel];
  }

  get count() {
    return this.messages.length;
  }
}

export function renderMessageFeed(feed, container) {
  const wasAtBottom = container.scrollTop + container.clientHeight >= container.scrollHeight - 50;

  container.innerHTML = '';
  for (const msg of feed.messages) {
    const div = document.createElement('div');
    div.className = 'message';

    const author = document.createElement('div');
    author.className = 'message-author';
    author.textContent = msg.author;

    const content = document.createElement('div');
    content.className = 'message-content';
    content.innerHTML = marked.parse(msg.content);

    div.appendChild(author);
    div.appendChild(content);
    container.appendChild(div);
  }

  if (wasAtBottom) {
    container.scrollTop = container.scrollHeight;
  }
}
