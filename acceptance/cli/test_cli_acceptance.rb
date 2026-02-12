require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require 'timeout'
require 'agent_chat'

class TestCLIAcceptance < Minitest::Test
  def test_should_send_and_receive_messages
    Dir.mktmpdir do |tmpdir|
      client = CLITestClient.new(tmpdir: tmpdir)

      # Given: messages sent from different authors
      client.send_message(room: "general", author: "Alice", content: "Hello world")
      client.send_message(room: "general", author: "Bob", content: "Hi there")

      # When: consumer receives messages
      output = client.receive_messages(room: "general", consumer: "Charlie")

      # Then: output contains formatted messages
      assert_match(/^<<< Alice \| .* >>>$/, output, "Missing or malformed header for Alice")
      assert_match(/^<<< Bob \| .* >>>$/, output, "Missing or malformed header for Bob")
      assert_includes output, "Hello world", "Missing Alice's message content"
      assert_includes output, "Hi there", "Missing Bob's message content"
      assert_includes output, "\n\n\n\n", "Missing 3 blank lines between messages"
    end
  end

  def test_should_terminate_stream_gracefully_on_interrupt
    Dir.mktmpdir do |tmpdir|
      # Given: stream command is running with a message to output
      service = AgentChat::Service::Main.standard(tmpdir:, room: "test-room")
      service.send_message(room: "general", author: "Test", content: "test message")

      stdout = StringIO.new
      adapter = AgentChat::CLIAdapter.new(stdin: StringIO.new, stdout:, service:, formatter: AgentChat::MessageFormatter)

      thread = Thread.new { adapter.run(['stream', '--room', 'general', '--consumer', 'Agent1']) }

      # Wait for streaming to start
      Timeout.timeout(5) { Thread.pass until !stdout.string.empty? }

      # When: simulate Ctrl-C
      thread.raise(Interrupt)

      # Then: thread exits cleanly
      result = thread.join(1)
      refute_nil result, "Thread should exit within timeout"
    end
  end

  def test_should_stream_new_messages_as_they_arrive
    Dir.mktmpdir do |tmpdir|
      client = CLITestClient.new(tmpdir:)
      stdout = StringIO.new

      # Given: stream is running
      thread = client.start_stream(room: "general", consumer: "Agent1", stdout:)

      # When: message is sent
      client.send_message(room: "general", author: "Alice", content: "Hello world")

      # Then: message appears in stream output
      Timeout.timeout(5) { Thread.pass until stdout.string.include?("Hello world") }

      thread.raise(Interrupt)
      thread.join(1)

      assert_match(/<<< Alice \|.*>>>/, stdout.string, "Should output message header")
    end
  end
end

class CLITestClient
  def initialize(tmpdir:, room: "test-room")
    @service = AgentChat::Service::Main.standard(tmpdir:, room:)
  end

  def send_message(room:, author:, content:)
    args = ["send", "--room", room, "--author", author]
    run_cli(args, stdin_content: content)
  end

  def receive_messages(room:, consumer:)
    args = ["receive", "--room", room, "--consumer", consumer]
    run_cli(args)
    @output.string
  end

  def start_stream(room:, consumer:, stdout:)
    adapter = AgentChat::CLIAdapter.new(stdin: StringIO.new, stdout:, service: @service, formatter: AgentChat::MessageFormatter)
    Thread.new { adapter.run(['stream', '--room', room, '--consumer', consumer]) }
  end

  private

  def run_cli(args, stdin_content: "")
    @output = StringIO.new
    stdin = StringIO.new(stdin_content)
    adapter = AgentChat::CLIAdapter.setup(stdin, @output, args, service: @service)
    adapter.run(args)
  end
end
