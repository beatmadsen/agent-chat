require_relative '../spelling'

module AgentChat
  module CLI
    module Lookup
      Exact = Data.define(:word)
      Interpreted = Data.define(:word)
      Unknown = Data.define(:suggestions)

      def self.find(word, known)
        return Exact.new(word) if known.include?(word)

        close = within(1, word, known)
        return Interpreted.new(close.first) if close.one?

        Unknown.new(close.empty? ? within(2, word, known) : close)
      end

      def self.within(edits, word, known)
        known.select { |candidate| Spelling.distance(word, candidate) <= edits }
      end
    end
  end
end
