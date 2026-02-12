/**
 * @jest-environment jsdom
 */

import { jest } from '@jest/globals';
import { fetchAndRenderMessages, fetchAndAppendNewMessages, getConsumer, postMessage } from '../../public/js/messages.js';

describe('messages', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="messages"></div>';
  });

  test('should render messages from API', async () => {
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve([
          { author: 'Alice', content: 'Hello', timestamp: '2025-01-01T10:00:00Z' },
          { author: 'Bob', content: 'Hi there', timestamp: '2025-01-01T10:01:00Z' }
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
          { author: 'Alice', content: '**bold** and *italic*', timestamp: '2025-01-01T10:00:00Z' }
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
          { author: 'Alice', content: 'Hello' },
          { author: 'Bob', content: 'Hi' }
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
          json: () => Promise.resolve([{ id: 1, author: 'Bob', content: 'Hello' }])
        });
      }
      return Promise.resolve({
        ok: true,
        json: () => Promise.resolve([{ id: 2, author: 'Carol', content: 'New' }])
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
          json: () => Promise.resolve([{ id: 1, author: 'Bob', content: 'Hello' }])
        });
      }
      return Promise.resolve({
        ok: true,
        json: () => Promise.resolve([{ id: 2, author: 'Carol', content: 'New' }])
      });
    });

    await fetchAndRenderMessages('general');
    const count = await fetchAndAppendNewMessages('general', 'web user');

    expect(count).toBe(2);
  });
});
