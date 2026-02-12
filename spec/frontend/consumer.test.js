/**
 * @jest-environment jsdom
 */

import { jest } from '@jest/globals';
import { fetchAndRenderMessages, fetchAndAppendNewMessages, getConsumer, postMessage } from '../../public/js/messages.js';

describe('consumer', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="messages"></div>';
  });

  test('should use consumer from URL parameter', async () => {
    delete window.location;
    window.location = { search: '?consumer=Alice' };

    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve([])
      })
    );

    await fetchAndRenderMessages('general');
    await fetchAndAppendNewMessages('general', getConsumer());

    expect(global.fetch).toHaveBeenCalledWith(
      '/api/rooms/general/messages/new?consumer=Alice'
    );
  });

  test('should default to "web user" when no consumer in URL', async () => {
    delete window.location;
    window.location = { search: '' };

    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve([])
      })
    );

    await fetchAndRenderMessages('general');
    await fetchAndAppendNewMessages('general', getConsumer());

    expect(global.fetch).toHaveBeenCalledWith(
      '/api/rooms/general/messages/new?consumer=web%20user'
    );
  });

  test('should POST message and add to feed optimistically', async () => {
    let callCount = 0;
    global.fetch = jest.fn(() => {
      callCount++;
      if (callCount === 1) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve([{ id: 1, author: 'Bob', content: 'Hi' }])
        });
      }
      return Promise.resolve({ ok: true, status: 201 });
    });

    await fetchAndRenderMessages('general');
    const count = await postMessage('general', 'Alice', 'Hello');

    expect(global.fetch).toHaveBeenCalledWith(
      '/api/rooms/general/messages',
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify({ author: 'Alice', content: 'Hello' })
      })
    );
    expect(count).toBe(2);
  });
});
