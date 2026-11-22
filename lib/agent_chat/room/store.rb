require 'json'
require 'set'
require 'time'
require_relative 'schema'
require_relative '../message'

module AgentChat
  module Room
    class IdTaken < StandardError; end

    class Store
      SELECT_MESSAGES = <<~SQL.freeze
        SELECT m.id, m.author, m.content, m.timestamp,
               (SELECT json_group_array(parent_id ORDER BY position) FROM replies WHERE message_seq = m.seq)
        FROM messages m
      SQL
      SEQ_OF_ID = 'COALESCE((SELECT seq FROM messages WHERE id = ?), 0)'.freeze
      IN_JSON_ARRAY = 'IN (SELECT value FROM json_each(?))'.freeze

      def initialize(db)
        @db = db
      end

      def insert(message)
        write(message)
      rescue SQLite3::ConstraintException => e
        raise IdTaken, message.id if e.message.include?('messages.id')

        raise
      end

      def messages_after(id)
        rows = @db.execute("#{SELECT_MESSAGES} WHERE m.seq > #{SEQ_OF_ID} ORDER BY m.seq", [id])
        rows.map { |row| to_message(row) }
      end

      def messages_with_ids(ids)
        rows = @db.execute("#{SELECT_MESSAGES} WHERE m.id #{IN_JSON_ARRAY} ORDER BY m.seq", [JSON.generate(ids)])
        rows.map { |row| to_message(row) }
      end

      def existing_ids(ids)
        rows = @db.execute("SELECT id FROM messages WHERE id #{IN_JSON_ARRAY}", [JSON.generate(ids)])
        rows.flatten.to_set
      end

      def read_position(consumer)
        @db.get_first_value(<<~SQL, [consumer])
          SELECT m.id FROM read_positions r JOIN messages m ON m.seq = r.last_seq WHERE r.consumer = ?
        SQL
      end

      def move_read_position(consumer, to:)
        @db.execute(<<~SQL, [consumer, to])
          INSERT INTO read_positions (consumer, last_seq) SELECT ?, seq FROM messages WHERE id = ?
          ON CONFLICT (consumer) DO UPDATE SET last_seq = excluded.last_seq
        SQL
      end

      private

      def write(message)
        @db.transaction do
          insert_message(message)
          insert_replies(@db.last_insert_row_id, message.reply_to)
        end
      end

      def insert_message(message)
        @db.execute('INSERT INTO messages (id, author, content, timestamp) VALUES (?, ?, ?, ?)',
                    [message.id, message.author, message.content, message.timestamp.getutc.iso8601])
      end

      def insert_replies(seq, parent_ids)
        parent_ids.each_with_index do |parent_id, position|
          @db.execute('INSERT INTO replies (message_seq, position, parent_id) VALUES (?, ?, ?)',
                      [seq, position, parent_id])
        end
      end

      def to_message(row)
        id, author, content, timestamp, reply_to = row
        Message.new(id:, author:, content:, timestamp: Time.iso8601(timestamp), reply_to: JSON.parse(reply_to))
      end
    end
  end
end
