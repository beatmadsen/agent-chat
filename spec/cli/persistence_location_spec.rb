require 'minitest/autorun'
require 'agent_chat'

class PersistenceLocationSpec < Minitest::Test
  def test_should_return_db_path_in_room_subdirectory
    # Given a FileResolver with a room name
    resolver = AgentChat::Persistence::FileResolver.new(tmp_dir_root: 'mytmpdir', room: 'my-project-abc123')

    # When we ask for the db location
    result = resolver.db_location

    # Then it returns the path combining tmp_dir_root, rooms dir, room name, and room.db
    assert_equal 'mytmpdir/agent-chat/rooms/my-project-abc123/room.db', result
  end
end
