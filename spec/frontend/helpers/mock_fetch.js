import { jest } from '@jest/globals';

export function mockFetchForRoom(roomMessages, newMessagesByPoll = []) {
  let pollCount = 0;
  return jest.fn((url) => {
    if (url === '/api/rooms') {
      return Promise.resolve({
        ok: true,
        json: () => Promise.resolve(['general'])
      });
    }
    if (url === '/api/rooms/general/messages') {
      return Promise.resolve({
        ok: true,
        json: () => Promise.resolve(roomMessages)
      });
    }
    if (url.includes('/messages/new?consumer=')) {
      const messages = pollCount < newMessagesByPoll.length ? newMessagesByPoll[pollCount] : [];
      pollCount++;
      return Promise.resolve({ ok: true, json: () => Promise.resolve(messages) });
    }
  });
}

export function setupRoomSelectionDOM() {
  document.body.innerHTML = `
    <ul id="rooms-list"></ul>
    <h2 id="room-title">Select a room</h2>
    <div id="messages"></div>
  `;
}

export async function selectRoom(onRoomSelected) {
  document.querySelector('#rooms-list li').click();
  await new Promise(resolve => setTimeout(resolve, 0));
}
