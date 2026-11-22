require_relative '../problem'

module AgentChat
  module Room
    module Name
      FORBIDDEN = %r{[/\\\x00-\x1f]}

      def self.problems_with(text)
        return [] if acceptable?(text)

        [Problem.new(:invalid_room, "Room name #{text.inspect} cannot be used: it must be a plain folder name")]
      end

      def self.acceptable?(text)
        !text.strip.empty? && !FORBIDDEN.match?(text) && !%w[. ..].include?(text)
      end
    end
  end
end
