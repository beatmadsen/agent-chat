module AgentChat
  module CLI
    Request = Data.define(:command, :room, :author, :consumer, :reply_to, :ids, :all, :json) do
      def self.special(command, json:)
        new(command:, room: nil, author: nil, consumer: nil, reply_to: [], ids: [], all: false, json:)
      end
    end
  end
end
