require 'minitest/autorun'
require 'agent_chat/cli/command_line'

class ParsingProblemsSpec < Minitest::Test
  def test_should_reject_a_flag_that_is_not_close_to_any_known_flag
    assert_equal({ code: 'unknown_flag', flag: '--everything' }, problem('receive', '--room', 'g', '--everything').slice(:code, :flag))
  end

  def test_should_suggest_flags_two_edits_away_from_an_unknown_flag
    assert_equal %w[--room], problem('receive', '--rxxm', 'g', '--consumer', 'Bob')[:suggestions]
  end

  def test_should_reject_a_flag_missing_its_value_at_the_end
    assert_equal({ code: 'missing_value', flag: '--room' }, problem('receive', '--consumer', 'Bob', '--room').slice(:code, :flag))
  end

  def test_should_reject_a_flag_followed_by_another_flag_instead_of_a_value
    assert_equal 'missing_value', problem('receive', '--room', '--json', '--consumer', 'Bob')[:code]
  end

  def test_should_reject_a_value_given_to_a_flag_that_takes_none
    assert_equal({ code: 'unexpected_value', flag: '--json' }, problem('receive', '--json=yes').slice(:code, :flag))
  end

  def test_should_reject_a_command_that_is_not_close_to_any_known_command
    assert_equal({ code: 'unknown_command', command: 'publish' }, problem('publish', '--room', 'g').slice(:code, :command))
  end

  def test_should_reject_a_line_with_flags_but_no_command
    assert_equal 'missing_command', problem('--room', 'g')[:code]
  end

  def test_should_reject_an_argument_the_command_does_not_take
    assert_equal({ code: 'unexpected_argument', argument: 'hello' }, problem('send', 'hello', '--room', 'g', '--author', 'A').slice(:code, :argument))
  end

  def test_should_reject_different_values_for_the_same_flag
    assert_equal({ code: 'conflicting_values', flag: '--room', values: %w[a b] },
                 problem('receive', '--room', 'a', '--room', 'b', '--consumer', 'Bob').slice(:code, :flag, :values))
  end

  def test_should_reject_a_request_without_a_room
    assert_equal({ code: 'missing_flag', flag: '--room' }, problem('receive', '--consumer', 'Bob').slice(:code, :flag))
  end

  def test_should_reject_a_send_without_an_author
    assert_equal({ code: 'missing_flag', flag: '--author' }, problem('send', '--room', 'g').slice(:code, :flag))
  end

  def test_should_reject_a_receive_without_a_consumer
    assert_equal({ code: 'missing_flag', flag: '--consumer' }, problem('stream', '--room', 'g').slice(:code, :flag))
  end

  def test_should_reject_a_show_without_ids
    assert_equal 'missing_argument', problem('show', '--room', 'g')[:code]
  end

  private

  def problem(*args) = AgentChat::CLI::CommandLine.new(args).parse.outcome.problem.as_json
end
