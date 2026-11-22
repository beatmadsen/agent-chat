require 'minitest/autorun'
require 'agent_chat/cli/command_line'

class ParsingSpec < Minitest::Test
  def test_should_read_a_send_request
    assert_equal({ command: :send, room: 'general', author: 'Alice' },
                 request('send', '--room', 'general', '--author', 'Alice').to_h.slice(:command, :room, :author))
  end

  def test_should_collect_reply_ids_from_repeated_and_comma_separated_flags
    assert_equal %w[a b c], request('send', '--room', 'g', '--author', 'A', '--reply-to', 'a,b', '--reply-to', 'c').reply_to
  end

  def test_should_read_a_value_joined_to_its_flag_with_an_equals_sign
    assert_equal 'general', request('receive', '--room=general', '--consumer', 'Bob').room
  end

  def test_should_accept_flags_before_the_command
    assert_equal :receive, request('--json', 'receive', '--room', 'g', '--consumer', 'Bob').command
  end

  def test_should_switch_on_json_output_with_the_json_flag
    assert request('receive', '--room', 'g', '--consumer', 'Bob', '--json').json
  end

  def test_should_not_need_a_consumer_when_reading_the_whole_history
    assert request('receive', '--room', 'g', '--all').all
  end

  def test_should_take_message_ids_for_show_from_separate_and_comma_separated_arguments
    assert_equal %w[a b c], request('show', '--room', 'g', 'a,b', 'c').ids
  end

  def test_should_show_help_when_given_no_arguments
    assert_equal :help, request.command
  end

  def test_should_show_help_when_asked_anywhere_on_the_line
    assert_equal :help, request('send', '--room', 'g', '-h').command
  end

  def test_should_show_the_version_when_asked
    assert_equal :version, request('--version').command
  end

  def test_should_read_a_flag_written_with_underscores_and_capitals
    assert_equal %w[a], request('send', '--room', 'g', '--author', 'A', '--Reply_To', 'a').reply_to
  end

  def test_should_say_how_it_read_a_flag_written_differently
    assert_equal [{ code: 'interpreted_flag', message: 'Read -room as --room', given: '-room', interpreted_as: '--room' }],
                 notices('receive', '-room', 'g', '--consumer', 'Bob')
  end

  def test_should_read_a_flag_one_edit_from_a_known_flag
    assert_equal 'g', request('receive', '--romo', 'g', '--consumer', 'Bob').room
  end

  def test_should_read_a_command_one_edit_from_a_known_command
    assert_equal :receive, request('recieve', '--room', 'g', '--consumer', 'Bob').command
  end

  def test_should_say_how_it_read_a_misspelt_command
    assert_equal ['Read recieve as receive'], notices('recieve', '--room', 'g', '--consumer', 'Bob').map { |n| n[:message] }
  end

  def test_should_ignore_a_flag_the_command_does_not_take_and_say_so
    assert_equal [{ code: 'ignored_flag', message: '--author does not apply to receive; ignored it', flag: '--author' }],
                 notices('receive', '--room', 'g', '--consumer', 'Bob', '--author', 'A')
  end

  def test_should_ignore_the_consumer_when_reading_the_whole_history_and_say_so
    assert_equal ['--consumer is not used with --all; ignored it'],
                 notices('receive', '--room', 'g', '--all', '--consumer', 'Bob').map { |n| n[:message] }
  end

  def test_should_drop_the_consumer_when_reading_the_whole_history
    assert_nil request('receive', '--room', 'g', '--all', '--consumer', 'Bob').consumer
  end

  def test_should_read_a_command_written_in_capitals
    assert_equal :receive, request('RECEIVE', '--room', 'g', '--consumer', 'Bob').command
  end

  def test_should_accept_the_same_value_given_twice
    assert_equal 'g', request('receive', '--room', 'g', '--room', 'g', '--consumer', 'Bob').room
  end

  private

  def parse(*args) = AgentChat::CLI::CommandLine.new(args).parse
  def request(*args) = parse(*args).outcome.value
  def notices(*args) = parse(*args).notices.map(&:as_json)
end
