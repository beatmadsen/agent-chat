require 'minitest/autorun'
require 'stringio'
require 'agent_chat/cli/text_output'

class TextOutputSpec < Minitest::Test
  include AgentChat

  def setup
    @stdout = StringIO.new
    @stderr = StringIO.new
    @output = CLI::TextOutput.new(stdout: @stdout, stderr: @stderr)
  end

  def test_should_head_a_message_with_author_local_time_and_id
    @output.messages([chat_message('aaaaaaa', [])])

    assert_equal "<<< Alice | #{Time.utc(2026, 1, 2, 3, 4, 5).localtime.strftime('%Y-%m-%d %H:%M:%S')} | aaaaaaa >>>\nhi\n", @stdout.string
  end

  def test_should_name_the_messages_a_message_replies_to_in_its_header
    @output.messages([chat_message('ccccccc', %w[aaaaaaa bbbbbbb])])

    assert_includes @stdout.string, '| ccccccc | re: aaaaaaa, bbbbbbb >>>'
  end

  def test_should_separate_messages_with_three_blank_lines
    @output.messages([chat_message('aaaaaaa', []), chat_message('bbbbbbb', [])])

    assert_includes @stdout.string, "hi\n\n\n\n<<< Alice"
  end

  def test_should_print_nothing_for_no_messages
    @output.messages([])

    assert_equal '', @stdout.string
  end

  def test_should_print_the_bare_id_of_an_accepted_post
    @output.posted('aaaaaaa', [])

    assert_equal "aaaaaaa\n", @stdout.string
  end

  def test_should_print_notes_and_warnings_about_a_post_on_stderr
    @output.posted('aaaaaaa', [CLI::Notice.new(:info, Problem.new(:room_created, 'Made it')),
                               CLI::Notice.new(:warning, Problem.new(:ignored_flag, 'Ignored it'))])

    assert_equal "note: Made it\nwarning: Ignored it\n", @stderr.string
  end

  def test_should_print_a_rejection_on_stderr
    @output.rejected(Problem.new(:unknown_flag, 'Unknown flag --x'), [])

    assert_equal "error: Unknown flag --x\n", @stderr.string
  end

  private

  def chat_message(id, reply_to) = Message.new(id:, author: 'Alice', content: 'hi', timestamp: Time.utc(2026, 1, 2, 3, 4, 5), reply_to:)
end
