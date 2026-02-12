module TestDoubles
  class RecordingDatabase
    attr_reader :last_room_name, :last_message

    def initialize(room_id:)
      @room_id = room_id
    end

    def find_or_create_room(name)
      @last_room_name = name
      @room_id
    end

    def insert_message(room_id:, author:, content:, timestamp:)
      @last_message = { room_id:, author:, content:, timestamp: }
    end
  end

  class RecordingNewMessagesDatabase
    attr_reader :last_room_name, :last_consumer_name, :last_updated_message_id

    def find_or_create_room(name)
      @last_room_name = name
      1
    end

    def find_or_create_consumer(name)
      @last_consumer_name = name
      2
    end

    def get_last_read_message_id(consumer_id:, room_id:)
      0
    end

    def messages_since(room_id:, since_id:)
      [[5, "Alice", "hello", "2025-01-01T10:00:00Z"]]
    end

    def update_last_read_message_id(consumer_id:, room_id:, message_id:)
      @last_updated_message_id = message_id
    end
  end

  class RecordingFormatter
    attr_reader :last_messages

    def format(messages)
      @last_messages = messages
      ""
    end
  end

  class StubFormatter
    def initialize(output)
      @output = output
    end

    def format(_messages)
      @output
    end
  end

  class StubReceiveService
    def initialize(messages)
      @messages = messages
    end

    def get_new_messages(room:, consumer:)
      @messages
    end
  end

  class FakeSendService
    attr_reader :send_called, :last_room, :last_author, :last_content

    def send_message(room:, author:, content:)
      @send_called = true
      @last_room = room
      @last_author = author
      @last_content = content
    end
  end

  class FakeReceiveService
    attr_reader :receive_called, :last_room, :last_consumer

    def get_new_messages(room:, consumer:)
      @receive_called = true
      @last_room = room
      @last_consumer = consumer
      [AgentChat::Message.new(author: 'Bob', content: 'Hi there')]
    end
  end

  def stub_database(room_id: nil, messages: [])
    Object.new.tap do |stub|
      stub.define_singleton_method(:find_or_create_room) { |_| room_id }
      stub.define_singleton_method(:messages_since) { |room_id:, since_id:| messages }
    end
  end
end
