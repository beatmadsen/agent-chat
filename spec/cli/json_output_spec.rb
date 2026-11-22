require 'minitest/autorun'
require 'stringio'
require 'agent_chat/cli/json_output'

class JsonOutputSpec < Minitest::Test
  include AgentChat

  def setup
    @stdout = StringIO.new
    @stderr = StringIO.new
    @output = CLI::JsonOutput.new(stdout: @stdout, stderr: @stderr)
  end

  def test_should_print_one_line_per_message
    @output.messages([chat_message('aaaaaaa'), chat_message('bbbbbbb')])

    assert_equal %w[aaaaaaa bbbbbbb], @stdout.string.lines.map { |line| JSON.parse(line)['id'] }
  end

  def test_should_print_nothing_for_no_messages
    @output.messages([])

    assert_equal '', @stdout.string
  end

  def test_should_print_each_notice_as_a_line_on_stderr_keyed_by_its_level
    @output.notices([CLI::Notice.new(:info, Problem.new(:room_created, 'made it'))])

    assert_equal %({"info":{"code":"room_created","message":"made it"}}\n), @stderr.string
  end

  def test_should_report_an_accepted_post_with_only_status_and_id
    @output.posted('aaaaaaa', [])

    assert_equal %({"status":"accepted","assigned_id":"aaaaaaa"}\n), @stdout.string
  end

  def test_should_report_that_a_post_created_the_room_and_which_rooms_are_close
    @output.posted('aaaaaaa', [CLI::Notice.new(:info, Problem.new(:room_created, 'made it', similar_rooms: %w[general]))])

    assert_equal({ 'room_created' => true, 'similar_rooms' => %w[general] }, JSON.parse(@stdout.string).slice('room_created', 'similar_rooms'))
  end

  def test_should_put_warnings_about_a_post_in_its_envelope
    @output.posted('aaaaaaa', [CLI::Notice.new(:warning, Problem.new(:interpreted_flag, 'read it'))])

    assert_equal [{ 'code' => 'interpreted_flag', 'message' => 'read it' }], JSON.parse(@stdout.string)['warnings']
  end

  def test_should_report_a_rejection_on_stdout_with_its_error_object
    @output.rejected(Problem.new(:unknown_flag, 'no such flag', flag: '--x'), [])

    assert_equal %({"status":"rejected","error":{"code":"unknown_flag","message":"no such flag","flag":"--x"}}\n), @stdout.string
  end

  def test_should_keep_stderr_empty_when_reporting_a_rejection
    @output.rejected(Problem.new(:unknown_flag, 'no such flag'), [CLI::Notice.new(:warning, Problem.new(:ignored_flag, 'x'))])

    assert_equal '', @stderr.string
  end

  private

  def chat_message(id) = Message.new(id:, author: 'Alice', content: 'hi', timestamp: Time.utc(2026), reply_to: [])
end
