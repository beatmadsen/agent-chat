module AgentChat
  class MessageFormatter
    def self.format(messages)
      messages.map { |message| format_single(message) }.join("\n\n\n\n")
    end

    def self.format_single(message)
      timestamp = message.timestamp.strftime('%Y-%m-%d %H:%M:%S')
      "<<< #{message.author} | #{timestamp} >>>\n#{message.content}"
    end

    private_class_method :format_single
  end
end
