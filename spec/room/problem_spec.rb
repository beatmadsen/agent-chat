require 'minitest/autorun'
require 'agent_chat/problem'

class ProblemSpec < Minitest::Test
  def test_should_present_code_and_message_first_then_its_details
    problem = AgentChat::Problem.new(:unknown_reply_to, 'No message', ids: ['zzzzzzz'])

    assert_equal({ code: 'unknown_reply_to', message: 'No message', ids: ['zzzzzzz'] }, problem.as_json)
  end
end
