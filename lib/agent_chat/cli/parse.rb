require_relative '../outcome'

module AgentChat
  module CLI
    Parse = Data.define(:outcome, :notices) do
      def self.accepted(value, notices = []) = new(Accepted.new(value), notices)
      def self.rejected(problem, notices = []) = new(Rejected.new(problem), notices)

      def and_then
        return self if outcome.is_a?(Rejected)

        following = yield outcome.value
        Parse.new(following.outcome, notices + following.notices)
      end
    end
  end
end
