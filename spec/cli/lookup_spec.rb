require 'minitest/autorun'
require 'agent_chat/cli/lookup'

class LookupSpec < Minitest::Test
  def test_should_match_a_known_word_exactly
    assert_equal AgentChat::CLI::Lookup::Exact.new('send'), lookup('send')
  end

  def test_should_interpret_a_word_one_edit_from_a_single_known_word
    assert_equal AgentChat::CLI::Lookup::Interpreted.new('send'), lookup('sedn')
  end

  def test_should_refuse_to_guess_between_two_known_words_one_edit_away
    assert_equal AgentChat::CLI::Lookup::Unknown.new(%w[cat cut]), AgentChat::CLI::Lookup.find('cot', %w[cat cut dog])
  end

  def test_should_suggest_known_words_two_edits_away
    assert_equal AgentChat::CLI::Lookup::Unknown.new(%w[show]), lookup('shxx')
  end

  private

  def lookup(word) = AgentChat::CLI::Lookup.find(word, %w[send receive stream show])
end
