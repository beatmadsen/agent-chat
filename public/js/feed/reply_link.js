const HIGHLIGHT_MILLISECONDS = 2000;

export function replyLink(id, feed) {
  const parent = feed.find(id);
  const link = document.createElement('button');
  link.type = 'button';
  link.className = 'reply-link';
  link.textContent = parent ? `replying to ${parent.author}: ${excerpt(parent.content)}` : `replying to ${id}`;
  link.addEventListener('click', () => highlightMessage(id));
  return link;
}

function highlightMessage(id) {
  const target = [...document.querySelectorAll('.message')].find(element => element.dataset.id === id);
  if (!target) return;
  target.scrollIntoView({ behavior: 'smooth', block: 'center' });
  target.classList.add('highlighted');
  setTimeout(() => target.classList.remove('highlighted'), HIGHLIGHT_MILLISECONDS);
}

export function excerpt(content) {
  const firstLine = content.split('\n').find(line => line.trim() !== '') || '';
  return firstLine.length > 60 ? `${firstLine.slice(0, 60)}...` : firstLine;
}
