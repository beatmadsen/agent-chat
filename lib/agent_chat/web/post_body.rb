require 'json'
require_relative '../outcome'
require_relative '../problem'

module AgentChat
  module Web
    module PostBody
      def self.parse(text)
        data = JSON.parse(text)
        return Rejected.new(Problem.new(:invalid_json, 'The body must be a JSON object')) unless data.is_a?(Hash)

        fields(data)
      rescue JSON::ParserError => e
        Rejected.new(Problem.new(:invalid_json, "The body is not valid JSON: #{e.message}"))
      end

      def self.fields(data)
        reply_to = data.fetch('reply_to', [])
        return Rejected.new(invalid_reply_to) unless reply_to.is_a?(Array) && reply_to.all?(String)

        Accepted.new({ author: data['author'].to_s, content: data['content'].to_s, reply_to: })
      end

      def self.unsupported(media_type)
        Problem.new(:unsupported_media_type, "Send the body as application/json, not #{media_type || 'without a Content-Type'}")
      end

      def self.invalid_reply_to
        Problem.new(:invalid_field, 'reply_to must be a list of message ids', field: 'reply_to')
      end
    end
  end
end
