require 'minitest/autorun'
require 'agent_chat/message'

class MessageSpec < Minitest::Test
  def test_should_present_its_fields_in_the_published_order_with_a_utc_timestamp
    message = AgentChat::Message.new(id: 'abc1234', author: 'Alice', content: 'hi',
                                     timestamp: Time.new(2026, 11, 22, 14, 30, 5, '+01:00'), reply_to: ['xyz9876'])

    assert_equal '{"id":"abc1234","author":"Alice","timestamp":"2026-11-22T13:30:05Z","content":"hi","reply_to":["xyz9876"]}',
                 JSON.generate(message.as_json)
  end
end
