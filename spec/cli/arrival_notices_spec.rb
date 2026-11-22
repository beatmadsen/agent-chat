require 'minitest/autorun'
require 'agent_chat/chat/entrance'
require 'agent_chat/cli/arrival_notices'

class ArrivalNoticesSpec < Minitest::Test
  include AgentChat

  def test_should_say_nothing_when_the_room_already_existed
    assert_empty notices(Room::Arrival.existing)
  end

  def test_should_tell_the_first_visitor_that_it_created_the_room
    assert_equal [{ info: { code: 'room_created',
                            message: 'Room general did not exist; created it. You are the first here.' } }],
                 notices(Room::Arrival.created)
  end

  def test_should_name_existing_rooms_close_to_one_it_created
    assert_equal({ code: 'room_created', similar_rooms: %w[genral generals],
                   message: 'Room general did not exist; created it. You are the first here. ' \
                            'Note that a room named genral and a room named generals exist.' },
                 notices(Room::Arrival.created, similar_rooms: %w[genral generals]).first[:info])
  end

  def test_should_name_a_single_close_room_in_the_singular
    assert_equal 'Room general did not exist; created it. You are the first here. Note that a room named genral exists.',
                 notices(Room::Arrival.created, similar_rooms: %w[genral]).first.dig(:info, :message)
  end

  def test_should_warn_where_it_backed_up_a_room_from_an_older_version
    assert_equal [{ warning: { code: 'room_reset', backup_path: '/backups/general',
                               message: 'Room general was made by an older version of agent-chat. ' \
                                        'Moved it to /backups/general and started the room over.' } }],
                 notices(Room::Arrival.reset('/backups/general'))
  end

  private

  def notices(arrival, similar_rooms: [])
    visit = Chat::Visit.new(chat: nil, arrival:, similar_rooms:)
    CLI::ArrivalNotices.for(visit, 'general').map { |notice| { notice.level => notice.problem.as_json } }
  end
end
