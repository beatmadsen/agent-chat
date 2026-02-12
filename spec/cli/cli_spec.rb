require 'minitest/autorun'
require 'stringio'
require 'timeout'
require 'agent_chat'

class CLISpec < Minitest::Test
  # Help behaviors

  def test_should_display_help_text_when_help_flag_provided
    # Given
    args = ['--help']
    stdout = StringIO.new

    # When
    AgentChat::CLIAdapter.new(stdin: StringIO.new, stdout: stdout, service: nil).run(args)

    # Then
    assert_includes stdout.string, "agent-chat"
    assert_includes stdout.string, "Usage:"
    assert_includes stdout.string, "send"
    assert_includes stdout.string, "receive"
    assert_includes stdout.string, "--room"
  end

  def test_should_display_help_when_no_arguments
    # Given
    args = []
    stdout = StringIO.new

    # When
    AgentChat::CLIAdapter.new(stdin: StringIO.new, stdout: stdout, service: nil).run(args)

    # Then
    assert_includes stdout.string, "Usage:"
  end

  # Argument parsing behaviors

  def test_should_parse_send_command_with_room_and_author
    # Given
    args = ['send', '--room', 'general', '--author', 'Alice']

    # When
    result = AgentChat::ArgumentParser.parse(args)

    # Then
    assert_equal :send, result[:action], "Should identify send action"
    assert_equal 'general', result[:room], "Should extract room name"
    assert_equal 'Alice', result[:author], "Should extract author"
  end

  def test_should_parse_poll_command_with_room_and_consumer
    # Given
    args = ['poll', '--room', 'general', '--consumer', 'Bob']

    # When
    result = AgentChat::ArgumentParser.parse(args)

    # Then
    assert_equal :poll, result[:action], "Should identify poll action"
    assert_equal 'general', result[:room], "Should extract room name"
    assert_equal 'Bob', result[:consumer], "Should extract consumer nickname"
  end

  def test_should_return_help_action_for_help_flag
    assert_equal :help, AgentChat::ArgumentParser.parse(['--help'])[:action]
    assert_equal :help, AgentChat::ArgumentParser.parse(['-h'])[:action]
  end

  def test_should_return_help_action_when_no_arguments
    assert_equal :help, AgentChat::ArgumentParser.parse([])[:action]
  end

  def test_should_return_help_action_when_help_flag_appears_anywhere
    assert_equal :help, AgentChat::ArgumentParser.parse(['send', '--room', 'general', '--help'])[:action]
  end

  # Stream behaviors

  def test_should_output_formatted_messages_when_streaming
    # Given: service returns messages
    messages = [AgentChat::Message.new(author: "Alice", content: "Hello", timestamp: Time.new(2025, 1, 1, 12, 0, 0))]
    service = FakeServiceWithMessages.new(messages)
    stdout = StringIO.new
    adapter = AgentChat::CLIAdapter.new(stdin: StringIO.new, stdout:, service:, formatter: AgentChat::MessageFormatter)

    # When: stream runs briefly
    thread = Thread.new { adapter.run(['stream', '--room', 'general', '--consumer', 'Agent1']) }
    Timeout.timeout(5) { Thread.pass until stdout.string.include?("Hello") }
    thread.kill

    # Then: formatted message appears
    assert_match(/<<< Alice \|.*>>>/, stdout.string, "Should output message header")
    assert_includes stdout.string, "Hello", "Should output message content"
  end

  class FakeServiceWithMessages
    def initialize(messages)
      @messages = messages
    end

    def get_new_messages(room:, consumer:)
      @messages
    end
  end
end
