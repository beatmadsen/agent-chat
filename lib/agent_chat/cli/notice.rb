require_relative '../problem'

module AgentChat
  module CLI
    Notice = Data.define(:level, :problem) do
      def warning? = level == :warning
      def room_created? = problem.code == :room_created
    end
  end
end
