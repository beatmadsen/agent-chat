require 'minitest/autorun'
require 'tmpdir'
require 'agent_chat/room/directory'

class DirectorySpec < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @directory = AgentChat::Room::Directory.new(@tmpdir)
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_should_list_folders_that_hold_a_room_database_in_name_order
    %w[beta alpha].each { |name| create_room(name) }
    FileUtils.mkdir_p(File.join(@tmpdir, 'agent-chat', 'rooms', 'empty-folder'))

    assert_equal %w[alpha beta], @directory.names
  end

  def test_should_list_no_rooms_before_any_exist
    assert_equal [], @directory.names
  end

  def test_should_find_other_rooms_one_edit_away
    %w[general genre generals].each { |name| create_room(name) }

    assert_equal %w[generals], @directory.names_near('general')
  end

  private

  def create_room(name)
    location = @directory.location(name)
    FileUtils.mkdir_p(File.dirname(location.database))
    FileUtils.touch(location.database)
  end
end
