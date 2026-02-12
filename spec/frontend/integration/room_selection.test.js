/**
 * @jest-environment jsdom
 */
import { jest } from '@jest/globals';
import { fetchAndRenderRooms } from '../../../public/js/rooms.js';
import { fetchAndRenderMessages, fetchAndAppendNewMessages, getConsumer } from '../../../public/js/messages.js';
import { mockFetchForRoom, setupRoomSelectionDOM, selectRoom } from '../helpers/mock_fetch.js';

describe('room selection', () => {
  beforeEach(() => {
    setupRoomSelectionDOM();
  });

  test('should display message count in room header when room is selected', async () => {
    global.fetch = jest.fn((url) => {
      if (url === '/api/rooms') {
        return Promise.resolve({ ok: true, json: () => Promise.resolve(['general']) });
      }
      if (url === '/api/rooms/general/messages') {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve([
            { author: 'Alice', content: 'Hello' },
            { author: 'Bob', content: 'Hi' },
            { author: 'Alice', content: 'Bye' }
          ])
        });
      }
    });

    async function onRoomSelected(room) {
      document.getElementById('room-title').textContent = room;
      const count = await fetchAndRenderMessages(room);
      document.getElementById('room-title').textContent = `${room} (${count})`;
    }

    await fetchAndRenderRooms(onRoomSelected);
    await selectRoom();

    expect(document.getElementById('room-title').textContent).toBe('general (3)');
  });

  test('should append new messages when polling', async () => {
    delete window.location;
    window.location = { search: '' };

    global.fetch = mockFetchForRoom(
      [{ id: 1, author: 'Bob', content: 'Hello' }],
      [[{ id: 2, author: 'Carol', content: 'New message' }]]
    );

    async function onRoomSelected(room) {
      document.getElementById('room-title').textContent = room;
      const count = await fetchAndRenderMessages(room);
      document.getElementById('room-title').textContent = `${room} (${count})`;
    }

    await fetchAndRenderRooms(onRoomSelected);
    await selectRoom();

    expect(document.querySelectorAll('.message')).toHaveLength(1);

    await fetchAndAppendNewMessages('general', 'web user');

    const messages = document.querySelectorAll('.message');
    expect(messages).toHaveLength(2);
    expect(messages[0].querySelector('.message-content').textContent).toContain('Hello');
    expect(messages[1].querySelector('.message-content').textContent).toContain('New message');
  });

  test('should update message count when new messages arrive', async () => {
    delete window.location;
    window.location = { search: '' };

    global.fetch = mockFetchForRoom(
      [{ id: 1, author: 'Bob', content: 'Hello' }],
      [[{ id: 2, author: 'Carol', content: 'New message' }]]
    );

    async function onRoomSelected(room) {
      document.getElementById('room-title').textContent = room;
      const count = await fetchAndRenderMessages(room);
      document.getElementById('room-title').textContent = `${room} (${count})`;
    }

    await fetchAndRenderRooms(onRoomSelected);
    await selectRoom();

    expect(document.getElementById('room-title').textContent).toBe('general (1)');

    const count = await fetchAndAppendNewMessages('general', 'web user');
    document.getElementById('room-title').textContent = `general (${count})`;

    expect(document.getElementById('room-title').textContent).toBe('general (2)');
  });
});
