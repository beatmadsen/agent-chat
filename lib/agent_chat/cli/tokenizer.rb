require_relative 'lookup'
require_relative 'parse'
require_relative 'vocabulary'
require_relative 'wording'

module AgentChat
  module CLI
    FlagUse = Data.define(:flag, :value)
    Tokens = Data.define(:flags, :positionals)

    class Tokenizer
      def initialize(args)
        @remaining = args.dup
        @flags = []
        @positionals = []
        @notices = []
      end

      def tokenize
        until @remaining.empty?
          problems = take(@remaining.shift)
          return Parse.rejected(problems.first, @notices) unless problems.empty?
        end
        Parse.accepted(Tokens.new(flags: @flags, positionals: @positionals), @notices)
      end

      private

      def take(token)
        return take_flag(*token.split('=', 2)) if token.start_with?('-')

        @positionals << token
        []
      end

      def take_flag(given, joined_value = nil)
        match = Lookup.find(Vocabulary.flag_name(given), Vocabulary::FLAGS)
        return [Wording.unknown_flag(given, match.suggestions)] if match.is_a?(Lookup::Unknown)

        @notices << Wording.interpreted(:interpreted_flag, given, match.word) unless given == match.word
        Vocabulary.takes_value?(match.word) ? take_value(match.word, joined_value) : take_switch(match.word, joined_value)
      end

      def take_value(flag, joined_value)
        value = joined_value || next_value
        return [Wording.missing_value(flag)] if value.nil?

        @flags << FlagUse.new(flag:, value:)
        []
      end

      def next_value
        return nil if @remaining.empty? || @remaining.first.start_with?('-')

        @remaining.shift
      end

      def take_switch(flag, joined_value)
        return [Wording.unexpected_value(flag)] unless joined_value.nil?

        @flags << FlagUse.new(flag:, value: true)
        []
      end
    end
  end
end
