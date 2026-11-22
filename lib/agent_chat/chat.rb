require_relative 'outcome'
require_relative 'room/store'
require_relative 'chat/draft'
require_relative 'chat/missing_ids'

module AgentChat
  class Chat
    def initialize(store:, room:, clock:, id_source:)
      @store = store
      @room = room
      @clock = clock
      @id_source = id_source
    end

    def post(author:, content:, reply_to:)
      draft = Draft.of(author:, content:, reply_to:)
      existing = @store.existing_ids(draft.reply_to)
      problems = draft.problems(existing, @room)
      return Rejected.new(problems.first) unless problems.empty?

      Accepted.new(save(draft))
    end

    def unread(consumer)
      messages = @store.messages_after(@store.read_position(consumer))
      mark_read(consumer, through: messages.last.id) unless messages.empty?
      messages
    end

    def mark_read(consumer, through:)
      @store.move_read_position(consumer, to: through)
    end

    def history = @store.messages_after(nil)
    def history_after(id) = @store.messages_after(id)

    def find(ids)
      wanted = ids.uniq
      found = @store.messages_with_ids(wanted).to_h { |message| [message.id, message] }
      unknown = wanted.reject { |id| found.key?(id) }
      return Rejected.new(MissingIds.problem(:unknown_id, unknown, @room)) unless unknown.empty?

      Accepted.new(found.values_at(*wanted))
    end

    private

    def save(draft)
      message = draft.to_message(id: @id_source.call, timestamp: @clock.call)
      @store.insert(message)
      message.id
    rescue Room::IdTaken
      retry
    end
  end
end
