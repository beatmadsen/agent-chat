require 'time'

require_relative 'persistence/file_resolver'
require_relative 'persistence/database'
require_relative 'message'

module AgentChat
  module Persistence
    def self.rows_to_messages(rows)
      rows.map do |row|
        AgentChat::Message.new(
          author: row[1],
          content: row[2],
          timestamp: Time.parse(row[3])
        )
      end
    end
  end
end
