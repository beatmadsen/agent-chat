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

  test('should not duplicate messages already in the feed', () => {
    const feed = new MessageFeed();
    feed.setMessages([
      { author: 'Bob', content: 'Hello', timestamp: '2025-01-01T10:00:00Z' }
    ]);

    feed.appendMessages([
      { author: 'Bob', content: 'Hello', timestamp: '2025-01-01T10:00:00Z' }
    ]);

    expect(feed.messages).toHaveLength(1);
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

  test('should append only novel messages when batch contains a mix of new and duplicate', () => {
    // Given: feed has two existing messages with timestamps
    const feed = new MessageFeed();
    feed.setMessages([
      { author: 'Alice', content: 'First', timestamp: '2025-01-01T10:00:00Z' },
      { author: 'Bob', content: 'Second', timestamp: '2025-01-01T10:01:00Z' }
    ]);

    // When: appending a batch where one message is a duplicate and one is new
    feed.appendMessages([
      { author: 'Alice', content: 'First', timestamp: '2025-01-01T10:00:00Z' },
      { author: 'Carol', content: 'Third', timestamp: '2025-01-01T10:02:00Z' }
    ]);

    // Then: only the novel message is added
    expect(feed.messages).toHaveLength(3);
    expect(feed.messages[2].author).toBe('Carol');
  });

  test('should always append messages without timestamps', () => {
    // Given: feed already has a message without a timestamp
    const feed = new MessageFeed();
    feed.setMessages([
      { author: 'Alice', content: 'Hello' }
    ]);

    // When: appending another message without a timestamp
    feed.appendMessages([
      { author: 'Bob', content: 'World' }
    ]);

    // Then: both messages are kept (undefined timestamps are not treated as duplicates)
    expect(feed.messages).toHaveLength(2);
    expect(feed.messages[0].author).toBe('Alice');
    expect(feed.messages[1].author).toBe('Bob');
  });

  test('should replace optimistic message with server-confirmed version in same append', () => {
    // Given: feed has a real message and an optimistic message
    const feed = new MessageFeed();
    feed.setMessages([
      { author: 'Alice', content: 'Hi', timestamp: '2025-01-01T10:00:00Z' },
      { author: 'Bob', content: 'Sending...', optimistic: true }
    ]);

    // When: server returns the confirmed version of Bob's message
    feed.appendMessages([
      { author: 'Bob', content: 'Sending...', timestamp: '2025-01-01T10:01:00Z' }
    ]);

    // Then: optimistic message is gone, server version is present
    expect(feed.messages).toHaveLength(2);
    expect(feed.messages[0].author).toBe('Alice');
    expect(feed.messages[1].author).toBe('Bob');
    expect(feed.messages[1].optimistic).toBeUndefined();
  });

  test('should deduplicate correctly across multiple successive appends', () => {
    // Given: feed starts with one message
    const feed = new MessageFeed();
    feed.setMessages([
      { author: 'Alice', content: 'First', timestamp: '2025-01-01T10:00:00Z' }
    ]);

    // When: two successive appends, second includes messages from both previous rounds
    feed.appendMessages([
      { author: 'Bob', content: 'Second', timestamp: '2025-01-01T10:01:00Z' }
    ]);
    feed.appendMessages([
      { author: 'Alice', content: 'First', timestamp: '2025-01-01T10:00:00Z' },
      { author: 'Bob', content: 'Second', timestamp: '2025-01-01T10:01:00Z' },
      { author: 'Carol', content: 'Third', timestamp: '2025-01-01T10:02:00Z' }
    ]);

    // Then: no duplicates, only three unique messages
    expect(feed.messages).toHaveLength(3);
    expect(feed.messages[0].author).toBe('Alice');
    expect(feed.messages[1].author).toBe('Bob');
    expect(feed.messages[2].author).toBe('Carol');
  });
});
