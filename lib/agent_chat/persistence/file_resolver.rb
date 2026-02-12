module AgentChat
  module Persistence
    class FileResolver
      def initialize(tmp_dir_root:, room:)
        @tmp_dir_root = tmp_dir_root
        @room = room
      end

      def db_location
        "#{@tmp_dir_root}/agent-chat/rooms/#{@room}/room.db"
      end
    end
  end
end
