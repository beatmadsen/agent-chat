require 'minitest/autorun'
require 'stringio'
require 'timeout'
require 'tmpdir'
require 'agent_chat/cli/runner'

class RunnerSpec < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @stdout = StringIO.new
    @stderr = StringIO.new
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_should_recommend_json_output_in_the_help_text
    run_cli('--help')

    assert_includes @stdout.string, '--json'
  end

  def test_should_report_the_version_as_json_when_asked
    run_cli('--version', '--json')

    assert_equal({ 'version' => AgentChat::VERSION }, JSON.parse(@stdout.string))
  end

  def test_should_refuse_a_lookup_of_an_unknown_id_with_status_1
    assert_equal 1, run_cli('show', '--json', '--room', 'general', 'zzzzzzz')
  end

  def test_should_refuse_a_room_name_that_cannot_be_a_folder
    run_cli('receive', '--json', '--room', '..', '--consumer', 'Bob')

    assert_equal 'invalid_room', JSON.parse(@stdout.string).dig('error', 'code')
  end

  def test_should_reject_a_malformed_line_with_status_2
    assert_equal 2, run_cli('receive', '--room')
  end

  def test_should_note_on_stderr_that_a_text_mode_send_created_the_room
    run_cli('send', '--room', 'general', '--author', 'Alice', stdin: 'hi')

    assert_equal "note: Room general did not exist; created it. You are the first here.\n", @stderr.string
  end

  def test_should_strip_the_newline_echo_adds_to_the_content
    run_cli('send', '--room', 'general', '--author', 'Alice', stdin: "Hello\n")
    run_cli('receive', '--json', '--room', 'general', '--all', stdout: @stdout = StringIO.new)

    assert_equal 'Hello', JSON.parse(@stdout.string)['content']
  end

  def test_should_refuse_a_reply_to_an_unknown_id_with_status_1
    assert_equal 1, run_cli('send', '--json', '--room', 'general', '--author', 'Bob', '--reply-to', 'zzzzzzz', stdin: 'two')
  end

  def test_should_print_the_whole_history_on_every_read_with_all
    run_cli('send', '--room', 'general', '--author', 'Alice', stdin: 'one')
    run_cli('receive', '--json', '--room', 'general', '--all')

    run_cli('receive', '--json', '--room', 'general', '--all', stdout: @stdout = StringIO.new)

    assert_equal 'one', JSON.parse(@stdout.string)['content']
  end

  def test_should_put_how_it_read_a_misspelt_flag_in_the_reply_to_a_send
    run_cli('send', '--json', '--romo', 'general', '--author', 'Alice', stdin: 'hi')

    assert_equal ['Read --romo as --room'], JSON.parse(@stdout.string)['warnings'].map { |warning| warning['message'] }
  end

  def test_should_report_how_it_read_a_misspelt_command_on_stderr_when_reading
    run_cli('send', '--room', 'general', '--author', 'Alice', stdin: 'hi')
    @stderr = StringIO.new

    run_cli('recieve', '--json', '--room', 'general', '--consumer', 'Bob')

    assert_equal %({"warning":{"code":"interpreted_command","message":"Read recieve as receive","given":"recieve","interpreted_as":"receive"}}\n),
                 @stderr.string
  end

  def test_should_stream_the_history_and_then_new_messages_when_following_everything
    run_cli('send', '--room', 'general', '--author', 'Alice', stdin: 'old')
    pauses = [-> { run_cli('send', '--room', 'general', '--author', 'Bob', stdin: 'new', stdout: StringIO.new) },
              -> { raise Interrupt }]

    run_cli('stream', '--json', '--room', 'general', '--all', stdout: @stdout = StringIO.new, pause: -> { pauses.shift.call })

    assert_equal %w[old new], @stdout.string.lines.map { |line| JSON.parse(line)['content'] }
  end

  def test_should_stop_quietly_when_the_reader_closes_the_pipe
    closed = Object.new.tap { |pipe| pipe.define_singleton_method(:puts) { |_| raise Errno::EPIPE } }
    run_cli('send', '--room', 'general', '--author', 'Alice', stdin: 'hi')

    assert_equal 0, run_cli('receive', '--room', 'general', '--all', stdout: closed)
  end

  def test_should_let_ctrl_c_stop_a_send_that_is_waiting_for_input
    reader, writer = IO.pipe
    waiting = Thread::Queue.new
    stdin = Object.new.tap { |input| input.define_singleton_method(:read) { waiting << :reading; reader.read } }
    terminal = AgentChat::CLI::Terminal.new(stdin:, stdout: @stdout, stderr: @stderr)
    # An Interrupt escaping into Minitest would abort the run and still exit 0.
    sender = Thread.new do
      AgentChat::CLI::Runner.new(terminal, root: @tmpdir).run(%w[send --room general --author Alice])
    rescue Interrupt
      'Interrupt escaped the runner'
    end
    waiting.pop

    sender.raise(Interrupt)

    assert_equal 0, Timeout.timeout(5) { sender.value }
  ensure
    [reader, writer].each(&:close)
  end

  private

  def run_cli(*args, stdin: '', stdout: @stdout, pause: -> { raise Interrupt })
    terminal = AgentChat::CLI::Terminal.new(stdin: StringIO.new(stdin), stdout:, stderr: @stderr)
    AgentChat::CLI::Runner.new(terminal, root: @tmpdir, pause:).run(args)
  end
end
