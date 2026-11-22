/**
 * @jest-environment jsdom
 */

import { MessageFeed } from '../../../public/js/feed/message_feed.js';

const message = (id, author = 'Alice') => ({ id, author, content: `content of ${id}`, timestamp: '2026-11-22T12:00:00Z', reply_to: [] });

describe('MessageFeed', () => {
  test('should append messages it has not seen', () => {
    const feed = new MessageFeed();
    feed.setMessages([message('aaaaaaa')]);

    feed.appendMessages([message('bbbbbbb')]);

    expect(feed.messages.map(m => m.id)).toEqual(['aaaaaaa', 'bbbbbbb']);
  });

  test('should not append a message whose id is already in the feed', () => {
    const feed = new MessageFeed();
    feed.setMessages([message('aaaaaaa')]);

    feed.appendMessages([message('aaaaaaa'), message('bbbbbbb')]);

    expect(feed.messages.map(m => m.id)).toEqual(['aaaaaaa', 'bbbbbbb']);
  });

  test('should keep two different messages that share a timestamp', () => {
    const feed = new MessageFeed();
    feed.setMessages([message('aaaaaaa')]);

    feed.appendMessages([message('bbbbbbb')]);

    expect(feed.count).toBe(2);
  });

  test('should find a message by id', () => {
    const feed = new MessageFeed();
    feed.setMessages([message('aaaaaaa'), message('bbbbbbb', 'Bob')]);

    expect(feed.find('bbbbbbb').author).toBe('Bob');
  });

  test('should find nothing for an id that is not in the feed', () => {
    const feed = new MessageFeed();

    expect(feed.find('zzzzzzz')).toBeUndefined();
  });
});
