require_relative '../problem'

module AgentChat
  module CLI
    module Wording
      COMMAND_LIST = 'Commands: send, receive, stream, show.'.freeze
      HELP_HINT = 'Run agent-chat --help for usage.'.freeze

      def self.interpreted(code, given, interpreted_as)
        Problem.new(code, "Read #{given} as #{interpreted_as}", given:, interpreted_as:)
      end

      def self.unknown_flag(flag, suggestions)
        Problem.new(:unknown_flag, "Unknown flag #{flag}.#{did_you_mean(suggestions)} #{HELP_HINT}", flag:, **listed(suggestions))
      end

      def self.unknown_command(command, suggestions)
        Problem.new(:unknown_command, "Unknown command #{command}.#{did_you_mean(suggestions)} #{COMMAND_LIST}",
                    command:, **listed(suggestions))
      end

      def self.missing_command = Problem.new(:missing_command, "No command given. #{COMMAND_LIST}")
      def self.missing_value(flag) = Problem.new(:missing_value, "#{flag} needs a value", flag:)
      def self.unexpected_value(flag) = Problem.new(:unexpected_value, "#{flag} takes no value", flag:)
      def self.missing_flag(command, flag) = Problem.new(:missing_flag, "#{command} needs #{flag}", flag:)
      def self.missing_ids = Problem.new(:missing_argument, 'show needs at least one message id')
      def self.ignored(flag, reason) = Problem.new(:ignored_flag, "#{flag} #{reason}; ignored it", flag:)

      def self.unexpected_argument(command, argument)
        extra = command == 'send' ? '; the message content is read from standard input' : ''
        Problem.new(:unexpected_argument, "#{command} takes no argument #{argument}#{extra}", argument:)
      end

      def self.conflicting_values(flag, values)
        Problem.new(:conflicting_values, "#{flag} was given different values: #{values.join(', ')}", flag:, values:)
      end

      def self.did_you_mean(suggestions) = suggestions.empty? ? '' : " Did you mean #{suggestions.join(' or ')}?"
      def self.listed(suggestions) = suggestions.empty? ? {} : { suggestions: }
    end
  end
end
