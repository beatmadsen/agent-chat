/**
 * @jest-environment jsdom
 */
import { jest } from '@jest/globals';
import { fetchAndRenderRooms } from '../../../public/js/rooms.js';
import { fetchAndRenderMessages, getConsumer, postMessage } from '../../../public/js/messages.js';
import { selectRoom } from '../helpers/mock_fetch.js';

describe('message posting', () => {
  test('should post message and add to feed when form submitted', async () => {
    delete window.location;
    window.location = { search: '?consumer=Alice' };

    global.fetch = jest.fn((url, options) => {
      if (url === '/api/rooms') {
        return Promise.resolve({ ok: true, json: () => Promise.resolve(['general']) });
      }
      if (url === '/api/rooms/general/messages' && !options) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve([{ id: 1, author: 'Bob', content: 'Hello' }])
        });
      }
      if (url === '/api/rooms/general/messages' && options?.method === 'POST') {
        return Promise.resolve({ ok: true, status: 201, json: () => Promise.resolve({}) });
      }
    });

    document.body.innerHTML = `
      <ul id="rooms-list"></ul>
      <h2 id="room-title">Select a room</h2>
      <div id="messages"></div>
      <form id="message-form">
        <input id="message-author" type="text" />
        <input id="message-content" type="text" />
        <button type="submit">Send</button>
      </form>
    `;

    async function onRoomSelected(room) {
      document.getElementById('room-title').textContent = room;
      const count = await fetchAndRenderMessages(room);
      document.getElementById('room-title').textContent = `${room} (${count})`;
      document.getElementById('message-author').value = getConsumer();
    }

    await fetchAndRenderRooms(onRoomSelected);
    await selectRoom();

    expect(document.getElementById('message-author').value).toBe('Alice');
    expect(document.querySelectorAll('.message')).toHaveLength(1);

    document.getElementById('message-content').value = 'Hello world';
    const count = await postMessage('general', 'Alice', 'Hello world');
    document.getElementById('room-title').textContent = `general (${count})`;

    expect(global.fetch).toHaveBeenCalledWith(
      '/api/rooms/general/messages',
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify({ author: 'Alice', content: 'Hello world' })
      })
    );

    const messages = document.querySelectorAll('.message');
    expect(messages).toHaveLength(2);
    expect(messages[1].querySelector('.message-author').textContent).toBe('Alice');
    expect(messages[1].querySelector('.message-content').textContent).toContain('Hello world');
    expect(document.getElementById('room-title').textContent).toBe('general (2)');
  });
});
