/**
 * @jest-environment jsdom
 */

import { jest } from '@jest/globals';
import { fetchAndRenderRooms } from '../../public/js/rooms.js';

describe('rooms', () => {
  let onRoomSelected;

  beforeEach(() => {
    document.body.innerHTML = '<ul id="rooms-list"></ul>';
    onRoomSelected = jest.fn();
  });

  test('should render rooms from API', async () => {
    // Given: API returns rooms
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve(['general', 'random'])
      })
    );

    // When: we fetch and render rooms
    await fetchAndRenderRooms(onRoomSelected);

    // Then: rooms appear in the list
    const items = document.querySelectorAll('#rooms-list li');
    expect(items).toHaveLength(2);
    expect(items[0].textContent).toBe('general');
    expect(items[1].textContent).toBe('random');
  });

  test('should call onRoomSelected when room is clicked', async () => {
    // Given: rooms are rendered
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve(['general', 'random'])
      })
    );
    await fetchAndRenderRooms(onRoomSelected);

    // When: user clicks a room
    const items = document.querySelectorAll('#rooms-list li');
    items[0].click();

    // Then: callback is invoked with room name
    expect(onRoomSelected).toHaveBeenCalledWith('general');
  });
});
