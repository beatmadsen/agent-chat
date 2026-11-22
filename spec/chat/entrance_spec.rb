require 'minitest/autorun'
require 'tmpdir'
require 'agent_chat/chat/entrance'

class EntranceSpec < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @entrance = AgentChat::Chat::Entrance.new(@tmpdir)
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_should_refuse_a_room_name_that_cannot_be_a_folder
    assert_equal :invalid_room, @entrance.enter('../x').problem.code
  end

  def test_should_name_existing_rooms_one_edit_away_from_a_room_it_created
    @entrance.enter('general')

    assert_equal %w[general], @entrance.enter('genral').value.similar_rooms
  end

  def test_should_name_no_similar_rooms_when_the_room_already_existed
    %w[general genral].each { |room| @entrance.enter(room) }

    assert_empty @entrance.enter('genral').value.similar_rooms
  end

  def test_should_hand_out_a_chat_that_posts_into_the_room
    @entrance.enter('general').value.chat.post(author: 'Alice', content: 'hi', reply_to: [])

    assert_equal %w[hi], @entrance.enter('general').value.chat.history.map(&:content)
  end
end
