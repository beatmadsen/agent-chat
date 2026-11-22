require_relative 'tokenizer'
require_relative 'request_builder'

module AgentChat
  module CLI
    class CommandLine
      def initialize(args)
        @args = args
      end

      def parse
        return Parse.accepted(special(:help)) if @args.empty? || @args.intersect?(Vocabulary::HELP)
        return Parse.accepted(special(:version)) if @args.intersect?(Vocabulary::VERSION)

        Tokenizer.new(@args).tokenize.and_then do |tokens|
          resolve_command(tokens.positionals.first).and_then { |command| RequestBuilder.new(command, tokens).build }
        end
      end

      def json_requested? = @args.any? { |arg| Vocabulary.flag_name(arg.split('=').first) == '--json' }

      private

      def special(command) = Request.special(command, json: json_requested?)

      def resolve_command(given)
        return Parse.rejected(Wording.missing_command) if given.nil?

        match = Lookup.find(given.downcase, Vocabulary.command_names)
        return Parse.rejected(Wording.unknown_command(given, match.suggestions)) if match.is_a?(Lookup::Unknown)

        notices = given == match.word ? [] : [Wording.interpreted(:interpreted_command, given, match.word)]
        Parse.accepted(match.word, notices)
      end
    end
  end
end
