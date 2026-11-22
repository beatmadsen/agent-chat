/**
 * @jest-environment jsdom
 */
import { jest } from '@jest/globals';
import { MessageFeed } from '../../../public/js/feed/message_feed.js';
import { renderMessageFeed } from '../../../public/js/feed/message_view.js';
import { excerpt } from '../../../public/js/feed/reply_link.js';

const message = (id, author, content, replyTo = []) => ({ id, author, content, timestamp: '2026-11-22T12:00:00Z', reply_to: replyTo });

function render(messages) {
  const feed = new MessageFeed();
  feed.setMessages(messages);
  const container = document.getElementById('messages');
  renderMessageFeed(feed, container);
  return container;
}

describe('message view', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="messages"></div>';
  });

  test('should show each message id', () => {
    const container = render([message('aaaaaaa', 'Alice', 'hi')]);

    expect(container.querySelector('.message-id').textContent).toBe('aaaaaaa');
  });

  test('should name the author and first line of each message a reply answers', () => {
    const container = render([message('aaaaaaa', 'Alice', 'Shall we ship?\nDetails follow'), message('bbbbbbb', 'Bob', 'Yes', ['aaaaaaa'])]);

    expect(container.querySelector('.reply-link').textContent).toBe('replying to Alice: Shall we ship?');
  });

  test('should show the bare id when the answered message is not loaded', () => {
    const container = render([message('bbbbbbb', 'Bob', 'Yes', ['zzzzzzz'])]);

    expect(container.querySelector('.reply-link').textContent).toBe('replying to zzzzzzz');
  });

  test('should highlight the answered message when its reply link is clicked', () => {
    const container = render([message('aaaaaaa', 'Alice', 'Ship?'), message('bbbbbbb', 'Bob', 'Yes', ['aaaaaaa'])]);
    Element.prototype.scrollIntoView = jest.fn();

    container.querySelector('.reply-link').click();

    expect(container.querySelector('[data-id="aaaaaaa"]').classList.contains('highlighted')).toBe(true);
  });

  test('should announce a reply request carrying the message when its reply button is clicked', () => {
    const container = render([message('aaaaaaa', 'Alice', 'Ship?')]);
    const requested = [];
    container.addEventListener('reply', event => requested.push(event.detail.id));

    container.querySelector('.reply-button').click();

    expect(requested).toEqual(['aaaaaaa']);
  });

  test('should strip scripts and event handlers from rendered content', () => {
    const container = render([message('aaaaaaa', 'Mallory', '<img src="x" onerror="alert(1)"><script>alert(2)</script>')]);

    expect(container.querySelector('.message-content').innerHTML).toBe('<p><img src="x"></p>\n');
  });

  test('should shorten a long first line for an excerpt', () => {
    expect(excerpt('a'.repeat(100))).toBe(`${'a'.repeat(60)}...`);
  });
});
