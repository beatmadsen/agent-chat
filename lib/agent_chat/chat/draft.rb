require_relative 'missing_ids'
require_relative '../message'

module AgentChat
  class Chat
    Draft = Data.define(:author, :content, :reply_to) do
      def self.of(author:, content:, reply_to:)
        new(author:, content:, reply_to: reply_to.uniq)
      end

      def problems(existing_ids, room)
        return [Problem.new(:missing_author, 'A message needs an author')] if author.to_s.strip.empty?
        return [Problem.new(:empty_content, 'A message needs content')] if content.to_s.strip.empty?

        unknown = reply_to.reject { |id| existing_ids.include?(id) }
        unknown.empty? ? [] : [MissingIds.problem(:unknown_reply_to, unknown, room)]
      end

      def to_message(id:, timestamp:)
        Message.new(id:, author:, content:, timestamp:, reply_to:)
      end
    end
  end
end
