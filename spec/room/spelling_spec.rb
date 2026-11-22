require 'minitest/autorun'
require 'agent_chat/spelling'

class SpellingSpec < Minitest::Test
  def test_should_count_one_edit_for_a_missing_letter
    assert_equal 1, AgentChat::Spelling.distance('genral', 'general')
  end

  def test_should_count_one_edit_for_two_swapped_neighbours
    assert_equal 1, AgentChat::Spelling.distance('recieve', 'receive')
  end

  def test_should_count_one_edit_for_a_changed_letter
    assert_equal 1, AgentChat::Spelling.distance('--romm', '--room')
  end

  def test_should_count_every_edit_needed
    assert_equal 3, AgentChat::Spelling.distance('send', 'show')
  end
end
