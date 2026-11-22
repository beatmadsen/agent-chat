require 'sqlite3'

module AgentChat
  module Room
    module Schema
      VERSION = 1

      TABLES = [
        <<~SQL,
          CREATE TABLE IF NOT EXISTS messages (
            seq INTEGER PRIMARY KEY AUTOINCREMENT,
            id TEXT NOT NULL UNIQUE,
            author TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp TEXT NOT NULL
          )
        SQL
        <<~SQL,
          CREATE TABLE IF NOT EXISTS replies (
            message_seq INTEGER NOT NULL REFERENCES messages(seq),
            position INTEGER NOT NULL,
            parent_id TEXT NOT NULL,
            PRIMARY KEY (message_seq, position)
          )
        SQL
        <<~SQL
          CREATE TABLE IF NOT EXISTS read_positions (
            consumer TEXT PRIMARY KEY,
            last_seq INTEGER NOT NULL
          )
        SQL
      ].freeze

      def self.apply(db)
        db.transaction(:immediate) do
          TABLES.each { |sql| db.execute(sql) }
          db.execute("PRAGMA user_version = #{VERSION}")
        end
      end

      def self.state(db)
        tables = db.get_first_value("SELECT count(*) FROM sqlite_master WHERE type = 'table'")
        return :blank if tables.zero?

        version = db.get_first_value('PRAGMA user_version')
        version == VERSION ? :current : :outdated
      end
    end
  end
end
