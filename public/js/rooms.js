export async function fetchAndRenderRooms(onRoomSelected) {
  const response = await fetch('/api/rooms');
  const rooms = await response.json();

  const list = document.getElementById('rooms-list');
  list.innerHTML = '';

  for (const room of rooms) {
    const li = document.createElement('li');
    li.textContent = room;
    li.addEventListener('click', () => onRoomSelected(room));
    list.appendChild(li);
  }
}
