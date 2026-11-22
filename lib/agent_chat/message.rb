require 'json'
require 'time'

module AgentChat
  Message = Data.define(:id, :author, :content, :timestamp, :reply_to) do
    def as_json
      { id:, author:, timestamp: timestamp.getutc.iso8601, content:, reply_to: }
    end
  end
end
