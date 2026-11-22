/**
 * @jest-environment jsdom
 */
import { ReplySelection } from '../../public/js/reply_selection.js';
import { renderReplySelection } from '../../public/js/reply_chips.js';

const message = (id, author = 'Alice') => ({ id, author, content: `about ${id}`, timestamp: '2026-11-22T12:00:00Z', reply_to: [] });

describe('ReplySelection', () => {
  test('should collect the ids of chosen messages in the order chosen', () => {
    const selection = new ReplySelection();

    selection.add(message('bbbbbbb'));
    selection.add(message('aaaaaaa'));

    expect(selection.ids).toEqual(['bbbbbbb', 'aaaaaaa']);
  });

  test('should hold a message only once', () => {
    const selection = new ReplySelection();

    selection.add(message('aaaaaaa'));
    selection.add(message('aaaaaaa'));

    expect(selection.ids).toEqual(['aaaaaaa']);
  });

  test('should forget a removed message', () => {
    const selection = new ReplySelection();
    selection.add(message('aaaaaaa'));
    selection.add(message('bbbbbbb'));

    selection.remove('aaaaaaa');

    expect(selection.ids).toEqual(['bbbbbbb']);
  });

  test('should be empty after clearing', () => {
    const selection = new ReplySelection();
    selection.add(message('aaaaaaa'));

    selection.clear();

    expect(selection.ids).toEqual([]);
  });
});

describe('renderReplySelection', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="reply-selection"></div>';
  });

  test('should show a chip naming each chosen message', () => {
    const selection = new ReplySelection();
    selection.add(message('aaaaaaa', 'Alice'));
    const container = document.getElementById('reply-selection');

    renderReplySelection(selection, container);

    expect(container.querySelector('.reply-chip-label').textContent).toBe('replying to Alice: about aaaaaaa');
  });

  test('should drop a message from the selection when its chip is removed', () => {
    const selection = new ReplySelection();
    selection.add(message('aaaaaaa'));
    const container = document.getElementById('reply-selection');
    renderReplySelection(selection, container);

    container.querySelector('.reply-chip-remove').click();

    expect([selection.ids, container.querySelectorAll('.reply-chip').length]).toEqual([[], 0]);
  });
});
