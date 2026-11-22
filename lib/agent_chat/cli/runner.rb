require 'tmpdir'
require_relative 'command_line'
require_relative 'arrival_notices'
require_relative 'commands'
require_relative 'help'
require_relative 'json_output'
require_relative 'stream'
require_relative 'text_output'
require_relative '../chat/entrance'
require_relative '../version'

module AgentChat
  module CLI
    Terminal = Data.define(:stdin, :stdout, :stderr)

    class Runner
      OK = 0
      REFUSED = 1
      UNREADABLE = 2

      def initialize(terminal, root: Dir.tmpdir, pause: -> { sleep 1 })
        @terminal = terminal
        @root = root
        @pause = pause
      end

      def run(args)
        command_line = CommandLine.new(args)
        output = output_for(command_line.json_requested?)
        respond(command_line.parse, output)
      rescue Interrupt, Errno::EPIPE
        OK
      end

      private

      def respond(parse, output)
        notices = parse.notices.map { |problem| Notice.new(:warning, problem) }
        return UNREADABLE.tap { output.rejected(parse.outcome.problem, notices) } if parse.outcome.is_a?(Rejected)

        dispatch(parse.outcome.value, notices, output)
      end

      def output_for(json)
        streams = { stdout: @terminal.stdout, stderr: @terminal.stderr }
        json ? JsonOutput.new(**streams) : TextOutput.new(**streams)
      end

      def dispatch(request, notices, output)
        case request.command
        when :help then OK.tap { @terminal.stdout.puts(HELP) }
        when :version then OK.tap { output.version(VERSION) }
        else enter(request, notices, output)
        end
      end

      def enter(request, notices, output)
        outcome = Chat::Entrance.new(@root).enter(request.room)
        return REFUSED.tap { output.rejected(outcome.problem, notices) } if outcome.is_a?(Rejected)

        visit = outcome.value
        command(request.command, visit.chat, output).run(request, notices + ArrivalNotices.for(visit, request.room))
      end

      def command(name, chat, output)
        case name
        when :send then Commands::Send.new(chat:, output:, stdin: @terminal.stdin)
        when :receive then Commands::Receive.new(chat:, output:)
        when :show then Commands::Show.new(chat:, output:)
        when :stream then Commands::Stream.new(chat:, output:, pause: @pause)
        end
      end
    end
  end
end
