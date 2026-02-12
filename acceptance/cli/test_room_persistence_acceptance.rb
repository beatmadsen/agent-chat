require 'minitest/autorun'
require 'tmpdir'
require 'sqlite3'
require 'agent_chat'

class TestRoomPersistenceAcceptance < Minitest::Test
  def test_should_persist_messages_to_room_based_database_path
    Dir.mktmpdir do |tmpdir|
      # Given: a service configured with a specific room
      service = AgentChat::Service::Main.standard(tmpdir:, room: "test-room")

      # When: I send a message
      service.send_message(room: "general", author: "Alice", content: "hello")

      # Then: database exists at room-based path (not pwd-based hash)
      expected_path = "#{tmpdir}/agent-chat/rooms/test-room/room.db"
      assert File.exist?(expected_path), "Database should be at #{expected_path}"

      # And: the message is in that database
      db = SQLite3::Database.new(expected_path)
      messages = db.execute("SELECT content FROM messages")
      assert_equal [["hello"]], messages
    end
  end

  def test_should_share_database_across_service_instances_with_same_room
    Dir.mktmpdir do |tmpdir|
      # The key test: room name determines database, not working directory
      # This simulates agents that cd into subdirectories but use same room

      # Given: first service sends a message
      service1 = AgentChat::Service::Main.standard(tmpdir:, room: "shared-room")
      service1.send_message(room: "general", author: "Alice", content: "from-root")

      # When: second service instance (simulates agent after cd) sends a message
      service2 = AgentChat::Service::Main.standard(tmpdir:, room: "shared-room")
      service2.send_message(room: "general", author: "Bob", content: "from-subdir")

      # Then: both messages are in the same database
      messages = service1.get_messages(room: "general")
      assert_equal 2, messages.length, "Both messages should be in same database"
      assert_equal ["from-root", "from-subdir"], messages.map(&:content)

      # And: only one database file exists
      db_path = "#{tmpdir}/agent-chat/rooms/shared-room/room.db"
      assert File.exist?(db_path), "Database should exist at room path"
    end
  end

  def test_should_isolate_messages_between_different_rooms
    Dir.mktmpdir do |tmpdir|
      # Given: messages sent to different rooms
      service_a = AgentChat::Service::Main.standard(tmpdir:, room: "room-a")
      service_b = AgentChat::Service::Main.standard(tmpdir:, room: "room-b")

      service_a.send_message(room: "general", author: "Alice", content: "in room A")
      service_b.send_message(room: "general", author: "Bob", content: "in room B")

      # Then: each room has its own database
      assert File.exist?("#{tmpdir}/agent-chat/rooms/room-a/room.db")
      assert File.exist?("#{tmpdir}/agent-chat/rooms/room-b/room.db")

      # And: messages are isolated to their respective databases
      messages_a = service_a.get_messages(room: "general")
      messages_b = service_b.get_messages(room: "general")

      assert_equal 1, messages_a.length
      assert_equal "in room A", messages_a.first.content

      assert_equal 1, messages_b.length
      assert_equal "in room B", messages_b.first.content
    end
  end
end
