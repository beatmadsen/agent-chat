require 'minitest/autorun'
require 'tmpdir'
require 'agent_chat'

class TestServiceAcceptance < Minitest::Test
  def test_should_list_all_rooms
    Dir.mktmpdir do |tmpdir|
      service = AgentChat::Service::Main.standard(tmpdir:, room: "test-room")

      # Given: rooms created via sending messages
      service.send_message(room: "beta", author: "Alice", content: "hello")
      service.send_message(room: "alpha", author: "Bob", content: "hi")

      # When
      rooms = service.list_rooms

      # Then
      assert_equal ["alpha", "beta"], rooms,
        "Should return all rooms in alphabetical order"
    end
  end

  def test_should_get_all_messages_in_room
    Dir.mktmpdir do |tmpdir|
      service = AgentChat::Service::Main.standard(tmpdir:, room: "test-room")

      # Given: messages in a room
      service.send_message(room: "general", author: "Alice", content: "hello")
      service.send_message(room: "general", author: "Bob", content: "world")
      service.send_message(room: "other", author: "Eve", content: "ignore me")

      # When
      messages = service.get_messages(room: "general")

      # Then
      assert_equal 2, messages.length, "Should return only messages from the room"
      assert_equal "Alice", messages[0].author
      assert_equal "hello", messages[0].content
      assert_equal "Bob", messages[1].author
      assert_equal "world", messages[1].content
    end
  end

  def test_should_subscribe_to_new_messages
    Dir.mktmpdir do |tmpdir|
      service = AgentChat::Service::Main.standard(tmpdir:, room: "test-room")

      # Given: existing messages
      service.send_message(room: "general", author: "Alice", content: "hello")
      service.send_message(room: "general", author: "Bob", content: "world")

      # When: Charlie subscribes for the first time
      messages = service.get_new_messages(room: "general", consumer: "Charlie")

      # Then: he gets all messages
      assert_equal 2, messages.length, "First read should return all messages"

      # When: Charlie reads again (no new messages)
      messages = service.get_new_messages(room: "general", consumer: "Charlie")

      # Then: he gets nothing
      assert_equal 0, messages.length, "Second read should return no messages"

      # When: a new message arrives
      service.send_message(room: "general", author: "Alice", content: "new message")

      # And: Charlie reads again
      messages = service.get_new_messages(room: "general", consumer: "Charlie")

      # Then: he gets only the new message
      assert_equal 1, messages.length, "Should return only new messages"
      assert_equal "new message", messages[0].content
    end
  end
end
