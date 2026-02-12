require 'sqlite3'
require 'fileutils'

module AgentChat
  module Persistence
    class Database
      def initialize(file_resolver:)
        db_path = file_resolver.db_location
        FileUtils.mkdir_p(File.dirname(db_path))
        @db = SQLite3::Database.new(db_path)
        create_tables
      end

      def find_or_create_room(name)
        @db.execute("INSERT OR IGNORE INTO rooms (name) VALUES (?)", [name])
        @db.get_first_value("SELECT id FROM rooms WHERE name = ?", [name])
      end

      def find_or_create_consumer(nickname)
        @db.execute("INSERT OR IGNORE INTO consumers (nickname) VALUES (?)", [nickname])
        @db.get_first_value("SELECT id FROM consumers WHERE nickname = ?", [nickname])
      end

      def insert_message(room_id:, author:, content:, timestamp:)
        @db.execute(
          "INSERT INTO messages (room_id, author, content, timestamp) VALUES (?, ?, ?, ?)",
          [room_id, author, content, timestamp]
        )
      end

      def messages_since(room_id:, since_id:)
        @db.execute(<<~SQL, [room_id, since_id])
          SELECT id, author, content, timestamp
          FROM messages
          WHERE room_id = ? AND id > ?
          ORDER BY id
        SQL
      end

      def get_last_read_message_id(consumer_id:, room_id:)
        @db.get_first_value(
          "SELECT last_read_message_id FROM read_positions WHERE consumer_id = ? AND room_id = ?",
          [consumer_id, room_id]
        ) || 0
      end

      def update_last_read_message_id(consumer_id:, room_id:, message_id:)
        @db.execute(<<~SQL, [message_id, consumer_id, room_id])
          INSERT INTO read_positions (last_read_message_id, consumer_id, room_id)
          VALUES (?, ?, ?)
          ON CONFLICT(consumer_id, room_id) DO UPDATE SET last_read_message_id = excluded.last_read_message_id
        SQL
      end

      def all_rooms
        @db.execute("SELECT name FROM rooms ORDER BY name").map { |row| row[0] }
      end

      private

      def create_tables
        create_rooms_table
        create_consumers_table
        create_messages_table
        create_read_positions_table
      end

      def create_rooms_table
        @db.execute(<<~SQL)
          CREATE TABLE IF NOT EXISTS rooms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE
          )
        SQL
      end

      def create_consumers_table
        @db.execute(<<~SQL)
          CREATE TABLE IF NOT EXISTS consumers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nickname TEXT NOT NULL UNIQUE
          )
        SQL
      end

      def create_messages_table
        @db.execute(<<~SQL)
          CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL REFERENCES rooms(id),
            author TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp TEXT NOT NULL
          )
        SQL
      end

      def create_read_positions_table
        @db.execute(<<~SQL)
          CREATE TABLE IF NOT EXISTS read_positions (
            consumer_id INTEGER NOT NULL REFERENCES consumers(id),
            room_id INTEGER NOT NULL REFERENCES rooms(id),
            last_read_message_id INTEGER NOT NULL,
            PRIMARY KEY (consumer_id, room_id)
          )
        SQL
      end
    end
  end
end
