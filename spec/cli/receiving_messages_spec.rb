require 'minitest/autorun'
require 'stringio'
require 'agent_chat'
require_relative 'test_doubles'

class ReceivingMessagesSpec < Minitest::Test
  include TestDoubles

  def test_should_return_messages_from_database
    db = stub_database(
      room_id: 1,
      messages: [
        [1, "Alice", "hello", "2025-01-01T10:00:00Z"],
        [2, "Bob", "world", "2025-01-01T10:01:00Z"]
      ]
    )
    service = AgentChat::Service::Main.new(database: db)

    messages = service.get_messages(room: "general")

    assert_equal 2, messages.length
    assert_equal "Alice", messages[0].author
    assert_equal "hello", messages[0].content
    assert_equal "Bob", messages[1].author
    assert_equal "world", messages[1].content
  end

  def test_should_get_new_messages_and_update_read_position
    db = RecordingNewMessagesDatabase.new
    service = AgentChat::Service::Main.new(database: db)

    messages = service.get_new_messages(room: "general", consumer: "Charlie")

    assert_equal "general", db.last_room_name
    assert_equal "Charlie", db.last_consumer_name
    assert_equal 5, db.last_updated_message_id
    assert_equal 1, messages.length
  end

  def test_should_format_received_messages_using_formatter
    args = ['receive', '--room', 'general', '--consumer', 'Bob']
    message = AgentChat::Message.new(author: 'Alice', content: 'Hello world')
    service = StubReceiveService.new([message])
    formatter = RecordingFormatter.new

    AgentChat::CLIAdapter.new(stdin: StringIO.new, stdout: StringIO.new, service: service, formatter: formatter).run(args)

    assert_equal [message], formatter.last_messages
  end

  def test_should_output_formatted_messages_to_stdout
    args = ['receive', '--room', 'general', '--consumer', 'Bob']
    service = StubReceiveService.new([])
    formatter = StubFormatter.new("formatted output")
    stdout = StringIO.new

    AgentChat::CLIAdapter.new(stdin: StringIO.new, stdout: stdout, service: service, formatter: formatter).run(args)

    assert_equal "formatted output\n", stdout.string
  end

  def test_should_pass_correct_args_to_service_for_receive
    args = ['receive', '--room', 'general', '--consumer', 'Alice']
    service = FakeReceiveService.new

    AgentChat::CLIAdapter.setup(StringIO.new, StringIO.new, args, service: service).run(args)

    assert service.receive_called, "Service should have received receive invocation"
    assert_equal 'general', service.last_room
    assert_equal 'Alice', service.last_consumer
  end
end
