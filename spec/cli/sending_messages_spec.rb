require 'minitest/autorun'
require 'stringio'
require 'agent_chat'
require_relative 'test_doubles'

class SendingMessagesSpec < Minitest::Test
  include TestDoubles

  def test_should_send_message_to_database
    db = RecordingDatabase.new(room_id: 1)
    service = AgentChat::Service::Main.new(database: db)

    service.send_message(room: "general", author: "Alice", content: "hello")

    assert_equal "general", db.last_room_name
    assert_equal 1, db.last_message[:room_id]
    assert_equal "Alice", db.last_message[:author]
    assert_equal "hello", db.last_message[:content]
  end

  def test_should_send_message_to_service_with_content_from_stdin
    args = ['send', '--room', 'general', '--author', 'Alice']
    stdin = StringIO.new("Hello world")
    service = FakeSendService.new

    AgentChat::CLIAdapter.new(stdin: stdin, stdout: nil, service: service).run(args)

    assert service.send_called
    assert_equal 'general', service.last_room
    assert_equal 'Alice', service.last_author
    assert_equal 'Hello world', service.last_content
  end

  def test_should_pass_correct_args_to_service_for_send
    args = ['send', '--room', 'general', '--author', 'Alice']
    stdin = StringIO.new("Hello world")
    service = FakeSendService.new

    AgentChat::CLIAdapter.setup(stdin, StringIO.new, args, service: service).run(args)

    assert service.send_called, "Service should have received send invocation"
    assert_equal 'general', service.last_room
    assert_equal 'Alice', service.last_author
    assert_equal 'Hello world', service.last_content
  end
end
