require 'minitest/autorun'
require 'agent_chat'
require_relative 'test_doubles'

class GetMessagesWithConsumerSpec < Minitest::Test
  include TestDoubles

  def test_should_register_read_position_when_consumer_provided
    db = RecordingReadPositionDatabase.new(
      room_id: 1,
      messages: [[5, "Alice", "hello", "2025-01-01T10:00:00Z"]]
    )
    service = AgentChat::Service::Main.new(database: db)

    service.get_messages(room: "general", consumer: "web user")

    assert_equal "web user", db.last_consumer_name
    assert_equal 5, db.last_updated_message_id
  end

  def test_should_not_register_read_position_when_no_consumer
    db = stub_database(
      room_id: 1,
      messages: [[1, "Alice", "hello", "2025-01-01T10:00:00Z"]]
    )
    service = AgentChat::Service::Main.new(database: db)

    messages = service.get_messages(room: "general")

    assert_equal 1, messages.length
  end
end
