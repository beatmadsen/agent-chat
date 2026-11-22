import { marked } from 'marked';
import DOMPurify from 'dompurify';
import { replyLink } from './reply_link.js';

const TEMPLATE = `
  <div class="message-header">
    <span class="message-author"></span>
    <span class="message-id"></span>
    <button type="button" class="reply-button">Reply</button>
  </div>
  <div class="message-replies"></div>
  <div class="message-content"></div>`;

export function renderMessageFeed(feed, container) {
  const wasAtBottom = container.scrollTop + container.clientHeight >= container.scrollHeight - 50;
  container.replaceChildren(...feed.messages.map(message => messageElement(message, feed)));
  if (wasAtBottom) {
    container.scrollTop = container.scrollHeight;
  }
}

function messageElement(message, feed) {
  const element = document.createElement('div');
  element.className = 'message';
  element.dataset.id = message.id;
  element.innerHTML = TEMPLATE;
  fill(element, message, feed);
  return element;
}

function fill(element, message, feed) {
  element.querySelector('.message-author').textContent = message.author;
  element.querySelector('.message-id').textContent = message.id;
  element.querySelector('.message-replies').append(...message.reply_to.map(id => replyLink(id, feed)));
  element.querySelector('.message-content').innerHTML = DOMPurify.sanitize(marked.parse(message.content));
  element.querySelector('.reply-button').addEventListener('click', () => announceReply(element, message));
}

function announceReply(element, message) {
  element.dispatchEvent(new CustomEvent('reply', { detail: message, bubbles: true }));
}
