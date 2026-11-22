require 'minitest/autorun'
require 'agent_chat/global_id'

class GlobalIdSpec < Minitest::Test
  def test_should_generate_seven_characters_from_the_base58_alphabet
    id = AgentChat::GlobalId.generate(Random.new(42))

    assert_match(/\A[1-9A-HJ-NP-Za-km-z]{7}\z/, id)
  end

  def test_should_generate_different_ids_from_different_random_draws
    random = Random.new(42)

    refute_equal AgentChat::GlobalId.generate(random), AgentChat::GlobalId.generate(random)
  end
end
