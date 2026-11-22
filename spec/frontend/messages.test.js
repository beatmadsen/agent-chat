/**
 * @jest-environment jsdom
 */

import { jest } from '@jest/globals';
import { fetchAndRenderMessages, fetchAndAppendNewMessages, postMessage } from '../../public/js/messages.js';
import { getConsumer } from '../../public/js/page.js';

describe('messages', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="messages"></div>';
  });

  test('should render messages from API', async () => {
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve([
          { id: 'msg0001', author: 'Alice', content: 'Hello', timestamp: '2025-01-01T10:00:00Z', reply_to: [] },
          { id: 'msg0002', author: 'Bob', content: 'Hi there', timestamp: '2025-01-01T10:01:00Z', reply_to: [] }
        ])
      })
    );

    await fetchAndRenderMessages('general');

    const messages = document.querySelectorAll('.message');
    expect(messages).toHaveLength(2);
    expect(messages[0].querySelector('.message-author').textContent).toBe('Alice');
    expect(messages[0].querySelector('.message-content').textContent).toContain('Hello');
    expect(messages[1].querySelector('.message-author').textContent).toBe('Bob');
  });

  test('should render markdown in message content', async () => {
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve([
          { id: 'msg0003', author: 'Alice', content: '**bold** and *italic*', timestamp: '2025-01-01T10:00:00Z', reply_to: [] }
        ])
      })
    );

    await fetchAndRenderMessages('general');

    const container = document.getElementById('messages');
    expect(container.innerHTML).toContain('<strong>bold</strong>');
    expect(container.innerHTML).toContain('<em>italic</em>');
  });

  test('should return message count after rendering', async () => {
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve([
          { id: 'msg0004', author: 'Alice', content: 'Hello', reply_to: [] },
          { id: 'msg0005', author: 'Bob', content: 'Hi', reply_to: [] }
        ])
      })
    );

    const count = await fetchAndRenderMessages('general');

    expect(count).toBe(2);
  });

  test('should fetch new messages and append to container', async () => {
    let callCount = 0;
    global.fetch = jest.fn(() => {
      callCount++;
      if (callCount === 1) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve([{ id: 'msg0001', author: 'Bob', content: 'Hello', reply_to: [] }])
        });
      }
      return Promise.resolve({
        ok: true,
        json: () => Promise.resolve([{ id: 'msg0002', author: 'Carol', content: 'New', reply_to: [] }])
      });
    });

    await fetchAndRenderMessages('general');
    await fetchAndAppendNewMessages('general', 'web user');

    const messages = document.querySelectorAll('.message');
    expect(messages).toHaveLength(2);
  });

  test('should return updated message count after appending', async () => {
    let callCount = 0;
    global.fetch = jest.fn(() => {
      callCount++;
      if (callCount === 1) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve([{ id: 'msg0001', author: 'Bob', content: 'Hello', reply_to: [] }])
        });
      }
      return Promise.resolve({
        ok: true,
        json: () => Promise.resolve([{ id: 'msg0002', author: 'Carol', content: 'New', reply_to: [] }])
      });
    });

    await fetchAndRenderMessages('general');
    const count = await fetchAndAppendNewMessages('general', 'web user');

    expect(count).toBe(2);
  });

  test('should leave the rendered feed untouched when a poll brings nothing new', async () => {
    global.fetch = jest.fn((url) => Promise.resolve({
      ok: true,
      json: () => Promise.resolve(url.includes('/new?') ? [] : [{ id: 'aaaaaaa', author: 'Bob', content: 'Hi', reply_to: [] }])
    }));
    await fetchAndRenderMessages('general');
    const rendered = document.querySelector('.message');

    await fetchAndAppendNewMessages('general', 'web user');

    expect(document.querySelector('.message')).toBe(rendered);
  });

  test('should clear the feed when the next room has no messages', async () => {
    global.fetch = jest.fn((url) => Promise.resolve({
      ok: true,
      json: () => Promise.resolve(url.includes('/busy/') ? [{ id: 'aaaaaaa', author: 'Bob', content: 'Hi', reply_to: [] }] : [])
    }));
    await fetchAndRenderMessages('busy');

    await fetchAndRenderMessages('quiet');

    expect(document.querySelectorAll('.message')).toHaveLength(0);
  });

  describe('posting', () => {
    function serverAnswering(postAnswer) {
      return jest.fn((url, options) => {
        if (options?.method === 'POST') return Promise.resolve({ ok: true, json: () => Promise.resolve(postAnswer) });
        return Promise.resolve({ ok: true, json: () => Promise.resolve([{ id: 'aaaaaaa', author: 'Bob', content: 'Hi', reply_to: [] }]) });
      });
    }

    test('should send the ids the message replies to', async () => {
      global.fetch = serverAnswering({ status: 'accepted', assigned_id: 'bbbbbbb' });
      await fetchAndRenderMessages('general');

      await postMessage('general', 'Alice', 'Agreed', ['aaaaaaa']);

      expect(JSON.parse(global.fetch.mock.calls[1][1].body)).toEqual({ author: 'Alice', content: 'Agreed', reply_to: ['aaaaaaa'] });
    });

    test('should show the posted message under the id the server assigned', async () => {
      global.fetch = serverAnswering({ status: 'accepted', assigned_id: 'bbbbbbb' });
      await fetchAndRenderMessages('general');

      await postMessage('general', 'Alice', 'Agreed', ['aaaaaaa']);

      expect([...document.querySelectorAll('.message-id')].map(e => e.textContent)).toEqual(['aaaaaaa', 'bbbbbbb']);
    });

    test('should hand back the reason when the server refuses the message', async () => {
      global.fetch = serverAnswering({ status: 'rejected', error: { code: 'unknown_reply_to', message: 'No message with id zzzzzzz in room general' } });
      await fetchAndRenderMessages('general');

      const result = await postMessage('general', 'Alice', 'Agreed', ['zzzzzzz']);

      expect(result).toEqual({ count: 1, error: 'No message with id zzzzzzz in room general' });
    });

    test('should hand back a reason when the server fails without a JSON answer', async () => {
      global.fetch = jest.fn((url, options) => {
        if (options?.method === 'POST') return Promise.resolve({ ok: false, status: 500, json: () => Promise.reject(new SyntaxError('Unexpected token <')) });
        return Promise.resolve({ ok: true, json: () => Promise.resolve([]) });
      });
      await fetchAndRenderMessages('general');

      const result = await postMessage('general', 'Alice', 'Agreed');

      expect(result).toEqual({ count: 0, error: 'The server could not take the message (HTTP 500)' });
    });
  });
});
