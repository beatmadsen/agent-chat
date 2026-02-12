require 'minitest/autorun'
require 'agent_chat'

class MessageFormattingSpec < Minitest::Test
  # Message structure behaviors

  def test_should_have_timestamp_when_created
    # Given/When a message is created
    message = AgentChat::Message.new(author: 'Alice', content: 'hello')

    # Then it should have a timestamp
    assert_instance_of Time, message.timestamp
  end

  def test_should_convert_to_hash_with_all_fields
    # Given a message
    message = AgentChat::Message.new(author: 'Alice', content: 'hello')

    # When converted to hash
    result = message.to_h

    # Then it contains all fields
    assert_equal 'Alice', result[:author]
    assert_equal 'hello', result[:content]
    assert_equal message.timestamp, result[:timestamp]
  end

  def test_should_use_provided_timestamp_when_given
    # Given a specific timestamp
    specific_time = Time.new(2024, 1, 15, 10, 30, 0)

    # When a message is created with that timestamp
    message = AgentChat::Message.new(author: 'Alice', content: 'hello', timestamp: specific_time)

    # Then it uses the provided timestamp
    assert_equal specific_time, message.timestamp
  end

  # Formatting behaviors

  def test_should_format_message_with_header_and_content
    # Given a message
    timestamp = Time.new(2025, 12, 7, 14, 30, 15)
    message = AgentChat::Message.new(author: 'Alice', content: 'Hello world', timestamp:)

    # When formatting
    output = AgentChat::MessageFormatter.format([message])

    # Then output contains content after header
    assert_includes output, "<<< Alice | 2025-12-07 14:30:15 >>>\nHello world"
  end

  def test_should_separate_multiple_messages_with_three_blank_lines
    # Given two messages
    timestamp1 = Time.new(2025, 12, 7, 14, 30, 15)
    timestamp2 = Time.new(2025, 12, 7, 14, 30, 22)
    messages = [
      AgentChat::Message.new(author: 'Alice', content: 'Hello world', timestamp: timestamp1),
      AgentChat::Message.new(author: 'Bob', content: 'Hi there', timestamp: timestamp2)
    ]

    # When formatting
    output = AgentChat::MessageFormatter.format(messages)

    # Then messages are separated by 3 blank lines
    assert_includes output, "Hello world\n\n\n\n<<< Bob |"
  end
end
