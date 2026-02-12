/**
 * @jest-environment jsdom
 */

import { MessageFeed } from '../../public/js/messages.js';

describe('MessageFeed', () => {
  test('should append new messages from server', () => {
    const feed = new MessageFeed();
    feed.setMessages([{ author: 'Bob', content: 'Hello' }]);

    feed.appendMessages([{ author: 'Carol', content: 'New' }]);

    expect(feed.messages).toHaveLength(2);
    expect(feed.messages[1].author).toBe('Carol');
  });

  test('should remove optimistic messages when appending', () => {
    const feed = new MessageFeed();
    feed.setMessages([
      { author: 'Bob', content: 'Hi' },
      { author: 'Alice', content: 'Hello', optimistic: true }
    ]);

    feed.appendMessages([]);

    expect(feed.messages).toHaveLength(1);
    expect(feed.messages[0].author).toBe('Bob');
  });
});
