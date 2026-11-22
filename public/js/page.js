export function getConsumer() {
  const params = new URLSearchParams(window.location.search);
  return params.get('consumer') || 'web user';
}

export function createKeyDownHandler(form) {
  return function(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
    }
  };
}
