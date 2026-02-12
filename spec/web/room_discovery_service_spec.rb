require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'

require 'agent_chat'

class RoomDiscoveryServiceSpec < Minitest::Test
  def test_should_return_room_names_from_directories_containing_room_db
    Dir.mktmpdir do |tmpdir|
      # Given: room directories with room.db files
      FileUtils.mkdir_p("#{tmpdir}/agent-chat/rooms/alpha")
      FileUtils.touch("#{tmpdir}/agent-chat/rooms/alpha/room.db")
      FileUtils.mkdir_p("#{tmpdir}/agent-chat/rooms/beta")
      FileUtils.touch("#{tmpdir}/agent-chat/rooms/beta/room.db")

      service = AgentChat::Web::RoomDiscoveryService.new(tmpdir: tmpdir)

      # When
      rooms = service.list_rooms

      # Then
      assert_equal ['alpha', 'beta'], rooms.sort,
        "Should return room names from directories containing room.db"
    end
  end
end
