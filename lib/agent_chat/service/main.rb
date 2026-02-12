require_relative '../persistence'
require 'tmpdir'

module AgentChat
  module Service
    class Main
      def self.standard(tmpdir: Dir.tmpdir, room:)
        raise ArgumentError, "room is required" if room.nil? || room.to_s.strip.empty?

        file_resolver = AgentChat::Persistence::FileResolver.new(tmp_dir_root: tmpdir, room:)
        database = AgentChat::Persistence::Database.new(file_resolver:)
        new(database:)
      end

      def initialize(database:)
        @database = database
      end

      def send_message(room:, author:, content:)
        room_id = @database.find_or_create_room(room)
        @database.insert_message(
          room_id: room_id,
          author: author,
          content: content,
          timestamp: Time.now.iso8601
        )
      end

      def list_rooms
        @database.all_rooms
      end

      def get_messages(room:)
        room_id = @database.find_or_create_room(room)
        rows = @database.messages_since(room_id: room_id, since_id: 0)
        AgentChat::Persistence.rows_to_messages(rows)
      end

      def get_new_messages(room:, consumer:)
        room_id = @database.find_or_create_room(room)
        consumer_id = @database.find_or_create_consumer(consumer)
        last_read_id = @database.get_last_read_message_id(consumer_id: consumer_id, room_id: room_id)

        rows = @database.messages_since(room_id: room_id, since_id: last_read_id)

        if rows.any?
          @database.update_last_read_message_id(
            consumer_id: consumer_id,
            room_id: room_id,
            message_id: rows.last[0]
          )
        end

        AgentChat::Persistence.rows_to_messages(rows)
      end
    end
  end
end
