require_relative 'flag_values'
require_relative 'request'

module AgentChat
  module CLI
    class RequestBuilder
      def initialize(command, tokens)
        @command = command
        @tokens = tokens
      end

      def build
        applicable, ignored = @tokens.flags.partition { |use| Vocabulary.applies?(@command, use.flag) }
        notices = ignored.map(&:flag).uniq.map { |flag| Wording.ignored(flag, "does not apply to #{@command}") }
        parse = FlagValues.new(@command, applicable).collect.and_then { |values| finish(values) }
        Parse.new(parse.outcome, notices + parse.notices)
      end

      private

      def finish(values)
        arguments = @tokens.positionals.drop(1)
        return ids(arguments).and_then { |ids| Parse.accepted(request(values, ids)) } if @command == 'show'
        return Parse.rejected(Wording.unexpected_argument(@command, arguments.first)) unless arguments.empty?

        Parse.accepted(request(values, []))
      end

      def ids(arguments)
        ids = arguments.flat_map { |argument| argument.split(',') }
        ids.empty? ? Parse.rejected(Wording.missing_ids) : Parse.accepted(ids)
      end

      def request(values, ids)
        Request.new(command: @command.to_sym, room: values['--room'], author: values['--author'],
                    consumer: values['--consumer'], reply_to: values.fetch('--reply-to', []), ids:,
                    all: values.fetch('--all', false), json: values.fetch('--json', false))
      end
    end
  end
end
