require 'minitest/autorun'
require 'agent_chat/room/name'

class RoomNameSpec < Minitest::Test
  def test_should_accept_an_ordinary_room_name
    assert_empty AgentChat::Room::Name.problems_with('atdd-mob_2')
  end

  def test_should_reject_a_name_that_would_leave_the_rooms_folder
    assert_equal [:invalid_room], AgentChat::Room::Name.problems_with('../etc').map(&:code)
  end

  def test_should_reject_the_parent_folder_name
    assert_equal [:invalid_room], AgentChat::Room::Name.problems_with('..').map(&:code)
  end

  def test_should_reject_a_blank_name
    assert_equal [:invalid_room], AgentChat::Room::Name.problems_with('  ').map(&:code)
  end
end
