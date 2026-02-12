module AgentChat
  class Message
    attr_reader :author, :content, :timestamp

    def initialize(author:, content:, timestamp: Time.now)
      @author = author
      @content = content
      @timestamp = timestamp
    end

    def to_h
      { author: @author, content: @content, timestamp: @timestamp }
    end
  end
end
