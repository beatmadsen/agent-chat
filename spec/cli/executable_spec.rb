require 'minitest/autorun'
require 'open3'
require 'rbconfig'
require 'timeout'
require 'tmpdir'
require 'agent_chat/chat/entrance'

# Runs exe/agent-chat as a real process. Everything the runner decides is
# specified in process by runner_spec; these tests cover only what the
# executable wires up: arguments, standard streams, TMPDIR, the exit status
# and Ctrl-C.
class ExecutableSpec < Minitest::Test
  LIB = File.expand_path('../../lib', __dir__)
  EXE = File.expand_path('../../exe/agent-chat', __dir__)

  def setup
    @tmpdir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_should_print_the_id_of_a_message_read_from_standard_input
    out, = run_exe('send', '--room', 'general', '--author', 'Alice', stdin: 'hi')

    assert_match(/\A[1-9A-HJ-NP-Za-km-z]{7}\n\z/, out)
  end

  def test_should_keep_rooms_under_tmpdir_where_the_chat_finds_them
    run_exe('send', '--room', 'general', '--author', 'Alice', stdin: 'sent by the executable')

    assert_equal ['sent by the executable'], AgentChat::Chat::Entrance.new(@tmpdir).enter('general').value.chat.history.map(&:content)
  end

  def test_should_print_notes_on_standard_error
    _, err, = run_exe('send', '--room', 'general', '--author', 'Alice', stdin: 'hi')

    assert_equal "note: Room general did not exist; created it. You are the first here.\n", err
  end

  def test_should_exit_with_the_status_the_runner_returns
    _, _, status = run_exe('show', '--room', 'general', 'zzzzzzz')

    assert_equal 1, status.exitstatus
  end

  def test_should_stream_a_message_another_process_sends
    streaming do |stdout, _stderr|
      run_exe('send', '--room', 'general', '--author', 'Alice', stdin: 'live')

      assert_equal 'live', JSON.parse(Timeout.timeout(10) { stdout.gets })['content']
    end
  end

  def test_should_stop_streaming_with_status_0_on_ctrl_c
    streaming do |_stdout, stderr, wait|
      Timeout.timeout(10) { stderr.gets }

      Process.kill('INT', wait.pid)

      assert_equal 0, Timeout.timeout(10) { wait.value }.exitstatus
    end
  end

  # Whether the process ends with status 0 or by the signal depends on whether
  # Ctrl-C lands before or after the command finishes; either is fine.
  def test_should_not_crash_ruby_when_ctrl_c_arrives_while_reading
    stdin, stdout, stderr, wait = popen('receive', '--json', '--room', 'general', '--consumer', 'Bob')
    Timeout.timeout(10) { stderr.gets }

    Process.kill('INT', wait.pid)

    refute_includes Timeout.timeout(10) { stderr.read }, '[BUG]'
  ensure
    [stdin, stdout, stderr].each(&:close)
  end

  private

  def env = { 'TMPDIR' => @tmpdir }

  def popen(*args) = Open3.popen3(env, RbConfig.ruby, "-I#{LIB}", EXE, *args)

  def run_exe(*args, stdin: '')
    Open3.capture3(env, RbConfig.ruby, "-I#{LIB}", EXE, *args, stdin_data: stdin)
  end

  # Yields once the stream has entered the room: its first line on standard
  # error is the note that it created the room.
  def streaming
    stdin, stdout, stderr, wait = popen('stream', '--json', '--room', 'general', '--consumer', 'Bob')
    yield stdout, stderr, wait
  ensure
    Process.kill('KILL', wait.pid) if wait.alive?
    [stdin, stdout, stderr].each(&:close)
  end
end
