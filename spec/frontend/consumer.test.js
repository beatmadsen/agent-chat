/**
 * @jest-environment jsdom
 */

import { jest } from '@jest/globals';
import { fetchAndRenderMessages, fetchAndAppendNewMessages, postMessage } from '../../public/js/messages.js';
import { getConsumer } from '../../public/js/page.js';

describe('consumer', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="messages"></div>';
  });

  test('should pass consumer to initial messages fetch', async () => {
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve([])
      })
    );

    await fetchAndRenderMessages('general', 'Alice');

    expect(global.fetch).toHaveBeenCalledWith(
      '/api/rooms/general/messages?consumer=Alice'
    );
  });

  test('should use consumer from URL parameter', async () => {
    window.history.replaceState({}, '', '/?consumer=Alice');

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
    window.history.replaceState({}, '', '/');

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
});
