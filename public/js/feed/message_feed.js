export class MessageFeed {
  constructor() {
    this.messages = [];
  }

  setMessages(messages) {
    this.messages = messages;
  }

  appendMessages(messages) {
    const known = new Set(this.messages.map(m => m.id));
    const added = messages.filter(m => !known.has(m.id));
    this.messages = [...this.messages, ...added];
    return added;
  }

  find(id) {
    return this.messages.find(m => m.id === id);
  }

  get count() {
    return this.messages.length;
  }
}
