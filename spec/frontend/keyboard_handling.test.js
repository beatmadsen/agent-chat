/**
 * @jest-environment jsdom
 */

import { jest } from '@jest/globals';
import { createKeyDownHandler } from '../../public/js/messages.js';

describe('createKeyDownHandler', () => {
  test('should submit form when Enter pressed', () => {
    // Given: a form and the keydown handler
    let formSubmitted = false;
    const form = { dispatchEvent: () => { formSubmitted = true; } };
    const handler = createKeyDownHandler(form);

    // When: Enter is pressed
    const event = new KeyboardEvent('keydown', { key: 'Enter', bubbles: true, cancelable: true });
    handler(event);

    // Then: form is submitted
    expect(formSubmitted).toBe(true);
  });

  test('should not submit form when Shift+Enter pressed', () => {
    // Given: a form and the keydown handler
    let formSubmitted = false;
    const form = { dispatchEvent: () => { formSubmitted = true; } };
    const handler = createKeyDownHandler(form);

    // When: Shift+Enter is pressed
    const event = new KeyboardEvent('keydown', { key: 'Enter', shiftKey: true, bubbles: true, cancelable: true });
    handler(event);

    // Then: form is not submitted (allows newline)
    expect(formSubmitted).toBe(false);
  });

  test('should prevent default when Enter pressed', () => {
    // Given: a form and the keydown handler
    const form = { dispatchEvent: () => {} };
    const handler = createKeyDownHandler(form);

    // When: Enter is pressed
    const event = new KeyboardEvent('keydown', { key: 'Enter', bubbles: true, cancelable: true });
    handler(event);

    // Then: default is prevented (no newline inserted)
    expect(event.defaultPrevented).toBe(true);
  });

  test('should allow default when Shift+Enter pressed', () => {
    // Given: a form and the keydown handler
    const form = { dispatchEvent: () => {} };
    const handler = createKeyDownHandler(form);

    // When: Shift+Enter is pressed
    const event = new KeyboardEvent('keydown', { key: 'Enter', shiftKey: true, bubbles: true, cancelable: true });
    handler(event);

    // Then: default is not prevented (newline can be inserted)
    expect(event.defaultPrevented).toBe(false);
  });
});
