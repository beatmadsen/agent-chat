require 'minitest/autorun'
require 'tmpdir'
require 'sqlite3'
require 'agent_chat'

class SqlitePersistenceSpec < Minitest::Test
  def test_should_persist_message_to_sqlite
    Dir.mktmpdir do |tmpdir|
      # Given a service
      service = AgentChat::Service::Main.standard(tmpdir:, room: "test-room")

      # When we send a message
      service.send_message(room: 'general', author: 'Alice', content: 'hello')

      # Then the room exists in SQLite
      file_resolver = AgentChat::Persistence::FileResolver.new(tmp_dir_root: tmpdir, room: "test-room")
      db = SQLite3::Database.new(file_resolver.db_location)
      rooms = db.execute("SELECT id, name FROM rooms")
      assert_equal 1, rooms.length
      assert_equal 'general', rooms.first[1]
      room_id = rooms.first[0]

      # And the message exists with correct room_id
      messages = db.execute("SELECT author, content, room_id FROM messages")
      assert_equal 1, messages.length
      assert_equal 'Alice', messages.first[0]
      assert_equal 'hello', messages.first[1]
      assert_equal room_id, messages.first[2]
    end
  end

  def test_should_track_read_position_in_sqlite
    Dir.mktmpdir do |tmpdir|
      # Given a service with one message
      service = AgentChat::Service::Main.standard(tmpdir:, room: "test-room")
      service.send_message(room: 'general', author: 'Alice', content: 'hello')

      # When a consumer reads for the first time
      messages = service.get_new_messages(room: 'general', consumer: 'Bob')

      # Then they get the message
      assert_equal 1, messages.length
      assert_equal 'hello', messages.first.content

      # When they read again (no new messages)
      messages = service.get_new_messages(room: 'general', consumer: 'Bob')

      # Then they get empty (read position was tracked)
      assert_equal 0, messages.length

      # When a new message is sent
      service.send_message(room: 'general', author: 'Alice', content: 'world')

      # And consumer reads again
      messages = service.get_new_messages(room: 'general', consumer: 'Bob')

      # Then they get only the new message
      assert_equal 1, messages.length
      assert_equal 'world', messages.first.content
    end
  end
end
