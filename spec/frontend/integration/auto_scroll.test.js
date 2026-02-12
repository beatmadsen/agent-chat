/**
 * @jest-environment jsdom
 */
import { jest } from '@jest/globals';
import { fetchAndRenderRooms } from '../../../public/js/rooms.js';
import { fetchAndRenderMessages, fetchAndAppendNewMessages } from '../../../public/js/messages.js';
import { mockFetchForRoom, setupRoomSelectionDOM, selectRoom } from '../helpers/mock_fetch.js';

function setupScrollTest() {
  delete window.location;
  window.location = { search: '' };

  global.fetch = mockFetchForRoom(
    [{ id: 1, author: 'Bob', content: 'Hello' }],
    [[{ id: 2, author: 'Carol', content: 'New message' }]]
  );
}

async function renderRoomAndSelect() {
  async function onRoomSelected(room) {
    document.getElementById('room-title').textContent = room;
    const count = await fetchAndRenderMessages(room);
    document.getElementById('room-title').textContent = `${room} (${count})`;
  }

  await fetchAndRenderRooms(onRoomSelected);
  await selectRoom();
}

describe('auto-scroll', () => {
  beforeEach(() => {
    setupRoomSelectionDOM();
  });

  test('should auto-scroll to new messages when at bottom', async () => {
    setupScrollTest();
    await renderRoomAndSelect();

    const messagesContainer = document.getElementById('messages');
    Object.defineProperty(messagesContainer, 'scrollHeight', { value: 500, configurable: true });
    Object.defineProperty(messagesContainer, 'clientHeight', { value: 400, configurable: true });
    Object.defineProperty(messagesContainer, 'scrollTop', { value: 100, writable: true, configurable: true });

    await fetchAndAppendNewMessages('general', 'web user');

    expect(messagesContainer.scrollTop).toBe(messagesContainer.scrollHeight);
  });

  test('should not auto-scroll when user has scrolled up', async () => {
    setupScrollTest();
    await renderRoomAndSelect();

    const messagesContainer = document.getElementById('messages');
    Object.defineProperty(messagesContainer, 'scrollHeight', { value: 500, configurable: true });
    Object.defineProperty(messagesContainer, 'clientHeight', { value: 400, configurable: true });
    Object.defineProperty(messagesContainer, 'scrollTop', { value: 0, writable: true, configurable: true });

    const originalScrollTop = messagesContainer.scrollTop;

    await fetchAndAppendNewMessages('general', 'web user');

    expect(messagesContainer.scrollTop).toBe(originalScrollTop);
  });
});
