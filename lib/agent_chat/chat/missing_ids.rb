require_relative '../problem'

module AgentChat
  class Chat
    module MissingIds
      def self.problem(code, ids, room)
        noun = ids.one? ? 'message with id' : 'messages with ids'
        Problem.new(code, "No #{noun} #{ids.join(', ')} in room #{room}", ids:)
      end
    end
  end
end
