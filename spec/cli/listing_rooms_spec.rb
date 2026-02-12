require 'minitest/autorun'
require 'tmpdir'
require 'agent_chat'

class ListingRoomsSpec < Minitest::Test
  # Service layer behavior

  def test_should_return_rooms_from_database
    # Given: a database stub that returns rooms
    db = stub_database(all_rooms: ["alpha", "beta"])
    service = AgentChat::Service::Main.new(database: db)

    # When
    rooms = service.list_rooms

    # Then
    assert_equal ["alpha", "beta"], rooms,
      "Should return rooms from database"
  end

  # Database layer behavior

  def test_should_return_all_room_names_alphabetically
    Dir.mktmpdir do |tmpdir|
      file_resolver = AgentChat::Persistence::FileResolver.new(tmp_dir_root: tmpdir, room: "test-room")
      db = AgentChat::Persistence::Database.new(file_resolver:)

      # Given: database with rooms created out of alphabetical order
      db.find_or_create_room("zebra")
      db.find_or_create_room("alpha")
      db.find_or_create_room("middle")

      # When
      rooms = db.all_rooms

      # Then
      assert_equal ["alpha", "middle", "zebra"], rooms,
        "Should return room names in alphabetical order"
    end
  end

  private

  def stub_database(all_rooms: [])
    Object.new.tap do |stub|
      stub.define_singleton_method(:all_rooms) { all_rooms }
    end
  end
end
