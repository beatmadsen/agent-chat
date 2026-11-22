export class ReplySelection {
  constructor() {
    this.messages = [];
  }

  add(message) {
    if (!this.ids.includes(message.id)) {
      this.messages = [...this.messages, message];
    }
  }

  remove(id) {
    this.messages = this.messages.filter(m => m.id !== id);
  }

  clear() {
    this.messages = [];
  }

  get ids() {
    return this.messages.map(m => m.id);
  }
}
