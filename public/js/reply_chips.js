import { excerpt } from './feed/reply_link.js';

const CHIP = '<span class="reply-chip-label"></span><button type="button" class="reply-chip-remove" aria-label="Remove">x</button>';

export function renderReplySelection(selection, container) {
  container.replaceChildren(...selection.messages.map(message => chip(message, selection, container)));
}

function chip(message, selection, container) {
  const element = document.createElement('span');
  element.className = 'reply-chip';
  element.innerHTML = CHIP;
  element.querySelector('.reply-chip-label').textContent = `replying to ${message.author}: ${excerpt(message.content)}`;
  element.querySelector('.reply-chip-remove').addEventListener('click', () => unselect(message.id, selection, container));
  return element;
}

function unselect(id, selection, container) {
  selection.remove(id);
  renderReplySelection(selection, container);
}
