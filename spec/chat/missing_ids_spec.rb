require 'minitest/autorun'
require 'agent_chat/chat/missing_ids'

class MissingIdsSpec < Minitest::Test
  def test_should_name_the_one_missing_id_and_the_room
    assert_equal({ code: 'unknown_reply_to', message: 'No message with id zzzzzzz in room general', ids: %w[zzzzzzz] },
                 AgentChat::Chat::MissingIds.problem(:unknown_reply_to, %w[zzzzzzz], 'general').as_json)
  end

  def test_should_list_several_missing_ids_in_one_message
    assert_equal 'No messages with ids zzzzzzz, yyyyyyy in room general',
                 AgentChat::Chat::MissingIds.problem(:unknown_id, %w[zzzzzzz yyyyyyy], 'general').message
  end
end
