require 'minitest/autorun'
require 'tmpdir'
require 'sqlite3'
require 'timeout'
require_relative '../support/cli_process'

class InputHandlingAcceptanceTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @cli = CLIProcess.new(@tmpdir)
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_should_send_with_a_misspelt_flag_and_say_how_it_was_read
    result = @cli.run('send', '--json', '--romo', 'general', '--author', 'Alice', stdin: 'hi')

    assert_equal [{ 'code' => 'interpreted_flag', 'message' => 'Read --romo as --room',
                    'given' => '--romo', 'interpreted_as' => '--room' }], result.json['warnings']
  end

  def test_should_report_interpretations_on_stderr_for_read_commands
    @cli.post('general', 'Alice', 'hi')

    result = @cli.run('recieve', '--json', '--room', 'general', '--consumer', 'Bob')

    assert_equal [{ 'warning' => { 'code' => 'interpreted_command', 'message' => 'Read recieve as receive',
                                   'given' => 'recieve', 'interpreted_as' => 'receive' } }], result.stderr_json_lines
  end

  def test_should_reject_a_flag_that_matches_nothing_with_exit_status_2
    result = @cli.run('receive', '--json', '--room', 'general', '--consumer', 'Bob', '--everything')

    assert_equal 2, result.exit_code
  end

  def test_should_name_the_unknown_flag_in_the_error
    result = @cli.run('receive', '--json', '--room', 'general', '--consumer', 'Bob', '--everything')

    assert_equal 'unknown_flag', result.json.dig('error', 'code')
  end

  def test_should_tell_a_reader_that_it_created_the_room
    result = @cli.run('receive', '--json', '--room', 'general', '--consumer', 'Bob')

    assert_equal [{ 'info' => { 'code' => 'room_created',
                                'message' => 'Room general did not exist; created it. You are the first here.' } }],
                 result.stderr_json_lines
  end

  def test_should_mention_an_existing_room_one_edit_away_from_a_new_one
    @cli.post('general', 'Alice', 'hi')

    result = @cli.run('receive', '--json', '--room', 'genral', '--consumer', 'Bob')

    assert_equal ['general'], result.stderr_json_lines[0].dig('info', 'similar_rooms')
  end

  def test_should_back_up_a_room_from_an_older_version_and_start_it_over
    old_room = File.join(@tmpdir, 'agent-chat', 'rooms', 'general', 'room.db')
    FileUtils.mkdir_p(File.dirname(old_room))
    SQLite3::Database.new(old_room).execute('CREATE TABLE messages (id INTEGER PRIMARY KEY, content TEXT)')

    result = @cli.run('receive', '--json', '--room', 'general', '--consumer', 'Bob')

    backup = result.stderr_json_lines[0].dig('warning', 'backup_path')
    assert_equal ['messages'], SQLite3::Database.new(File.join(backup, 'room.db'))
                                 .execute("SELECT name FROM sqlite_master WHERE type = 'table'").flatten
  end

  def test_should_show_id_and_replies_in_the_text_header
    first = @cli.post('general', 'Alice', 'one')
    second = @cli.post('general', 'Bob', 'two', '--reply-to', first)

    result = @cli.run('receive', '--room', 'general', '--consumer', 'Carol')

    assert_match(/^<<< Bob \| \d{4}-\d\d-\d\d \d\d:\d\d:\d\d \| #{second} \| re: #{first} >>>\ntwo$/, result.stdout)
  end

  def test_should_print_the_bare_id_when_sending_in_text_mode
    result = @cli.run('send', '--room', 'general', '--author', 'Alice', stdin: 'hi')

    assert_match(/\A[1-9A-HJ-NP-Za-km-z]{7}\n\z/, result.stdout)
  end

  def test_should_stream_messages_as_json_lines_as_they_arrive
    streaming('stream', '--json', '--room', 'general', '--consumer', 'Bob') do |stdout|
      id = @cli.post('general', 'Alice', 'live')

      line = Timeout.timeout(10) { stdout.gets }

      assert_equal id, JSON.parse(line)['id']
    end
  end

  private

  def streaming(*args)
    stdin, stdout, _stderr, wait = @cli.spawn(*args)
    yield stdout
  ensure
    Process.kill('INT', wait.pid)
    [stdin, stdout].each(&:close)
  end
end
