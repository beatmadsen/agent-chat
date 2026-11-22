require 'minitest/autorun'
require 'tmpdir'
require_relative '../support/cli_process'

class JsonMessagingAcceptanceTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @cli = CLIProcess.new(@tmpdir)
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_should_report_the_assigned_id_when_a_message_is_accepted
    result = @cli.run('send', '--json', '--room', 'general', '--author', 'Alice', stdin: "Hello\n")

    assert_match(/\A\{"status":"accepted","assigned_id":"[1-9A-HJ-NP-Za-km-z]{7}","room_created":true\}\n\z/, result.stdout)
  end

  def test_should_leave_out_room_created_when_the_room_already_existed
    @cli.post('general', 'Alice', 'first')

    result = @cli.run('send', '--json', '--room', 'general', '--author', 'Bob', stdin: 'second')

    assert_equal %w[status assigned_id], result.json.keys
  end

  def test_should_receive_each_message_as_one_json_line
    id = @cli.post('general', 'Alice', "Hello\n")

    result = @cli.run('receive', '--json', '--room', 'general', '--consumer', 'Bob')

    assert_equal [{ 'id' => id, 'author' => 'Alice', 'timestamp' => result.json_lines[0]['timestamp'],
                    'content' => 'Hello', 'reply_to' => [] }], result.json_lines
  end

  def test_should_give_timestamps_in_utc_with_a_z_suffix
    @cli.post('general', 'Alice', 'Hello')

    result = @cli.run('receive', '--json', '--room', 'general', '--consumer', 'Bob')

    assert_match(/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/, result.json_lines[0]['timestamp'])
  end

  def test_should_print_nothing_when_there_are_no_new_messages
    @cli.post('general', 'Alice', 'Hello')
    @cli.run('receive', '--json', '--room', 'general', '--consumer', 'Bob')

    result = @cli.run('receive', '--json', '--room', 'general', '--consumer', 'Bob')

    assert_equal '', result.stdout
  end

  def test_should_link_a_reply_to_every_message_it_answers_in_the_order_given
    first = @cli.post('general', 'Alice', 'one')
    second = @cli.post('general', 'Bob', 'two')
    @cli.post('general', 'Carol', 'both', '--reply-to', second, '--reply-to', "#{first},#{second}")

    result = @cli.run('receive', '--json', '--room', 'general', '--consumer', 'Dave')

    assert_equal [second, first], result.json_lines.last['reply_to']
  end

  def test_should_reject_a_reply_to_an_unknown_id_without_saving_the_message
    @cli.post('general', 'Alice', 'one')

    result = @cli.run('send', '--json', '--room', 'general', '--author', 'Bob', '--reply-to', 'zzzzzzz', stdin: 'two')

    assert_equal({ 'status' => 'rejected',
                   'error' => { 'code' => 'unknown_reply_to', 'message' => 'No message with id zzzzzzz in room general',
                                'ids' => ['zzzzzzz'] } }, result.json)
  end

  def test_should_exit_with_status_1_when_a_request_is_rejected
    result = @cli.run('send', '--json', '--room', 'general', '--author', 'Bob', '--reply-to', 'zzzzzzz', stdin: 'two')

    assert_equal 1, result.exit_code
  end

  def test_should_not_save_a_rejected_message
    @cli.run('send', '--json', '--room', 'general', '--author', 'Bob', '--reply-to', 'zzzzzzz', stdin: 'two')

    result = @cli.run('receive', '--json', '--room', 'general', '--all')

    assert_equal '', result.stdout
  end

  def test_should_show_the_requested_messages_in_the_order_given
    first = @cli.post('general', 'Alice', 'one')
    second = @cli.post('general', 'Bob', 'two')

    result = @cli.run('show', '--json', '--room', 'general', second, first)

    assert_equal %w[two one], result.json_lines.map { |line| line['content'] }
  end

  def test_should_receive_the_whole_history_with_all_without_moving_the_read_position
    @cli.post('general', 'Alice', 'one')
    @cli.run('receive', '--json', '--room', 'general', '--all')

    result = @cli.run('receive', '--json', '--room', 'general', '--consumer', 'Bob')

    assert_equal ['one'], result.json_lines.map { |line| line['content'] }
  end
end
