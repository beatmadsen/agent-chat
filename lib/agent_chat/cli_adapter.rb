require_relative 'argument_parser'
require_relative 'version'
require_relative 'service/main'
require_relative 'message_formatter'

module AgentChat
  class CLIAdapter
    HELP_TEXT = <<~HELP
      agent-chat - A simple chat messaging tool for inter-agent communication

      Usage:
        agent-chat <command> [options]

      Commands:
        send      Send a message to a chat room (reads content from stdin)
        receive   Receive messages from a chat room (one-shot)
        stream    Stream messages from a chat room (continuous, Ctrl-C to stop)

      Options:
        --room <name>       Chat room name (required)
        --author <name>     Author name for sending messages
        --consumer <name>   Consumer name for tracking read position
        -h, --help          Show this help message

      Examples:
        echo 'Hello!' | agent-chat send --room general --author Alice
        agent-chat receive --room general --consumer Bob
        agent-chat stream --room general --consumer Bob
    HELP

    def self.setup(stdin, stdout, args, service: nil, formatter: AgentChat::MessageFormatter)
      parsed = AgentChat::ArgumentParser.parse(args)
      return new(stdin:, stdout:, service: nil, formatter: nil) if [:help, :version].include?(parsed[:action])

      service ||= AgentChat::Service::Main.standard(room: parsed[:room])
      new(stdin:, stdout:, service:, formatter:)
    end

    def initialize(stdin:, stdout:, service:, formatter: nil)
      @stdin = stdin
      @stdout = stdout
      @service = service
      @formatter = formatter
    end

    def run(args)
      parsed = AgentChat::ArgumentParser.parse(args)
      dispatch(parsed)
    rescue Interrupt
      # exit gracefully
    end

    private

    def dispatch(parsed)
      case parsed[:action]
      when :help    then @stdout.puts HELP_TEXT
      when :version then @stdout.puts "agent-chat #{AgentChat::VERSION}"
      when :send    then send_message(parsed)
      when :receive then receive_messages(parsed)
      when :stream  then stream_messages(parsed)
      end
    end

    def send_message(parsed)
      @service.send_message(room: parsed[:room], author: parsed[:author], content: @stdin.read)
    end

    def receive_messages(parsed)
      messages = @service.get_new_messages(room: parsed[:room], consumer: parsed[:consumer])
      @stdout.puts @formatter.format(messages)
    end

    def stream_messages(parsed)
      loop do
        messages = @service.get_new_messages(room: parsed[:room], consumer: parsed[:consumer])
        @stdout.puts @formatter.format(messages) if messages.any?
        sleep 1
      end
    end
  end
end
