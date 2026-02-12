ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'json'

require 'agent_chat'

class ApiMessagesSpec < Minitest::Test
  include Rack::Test::Methods

  def app
    AgentChat::Web::App
  end

  def test_should_return_messages_from_service_as_json
    # Given: a service factory that returns a service with messages
    messages = [
      stub_message(author: 'Alice', content: 'Hello'),
      stub_message(author: 'Bob', content: 'Hi')
    ]
    AgentChat::Web::App.set :service_factory, stub_service_factory(messages: messages)

    # When
    get '/api/rooms/general/messages', {}, { 'HTTP_HOST' => 'localhost' }

    # Then
    assert last_response.ok?
    result = JSON.parse(last_response.body)
    assert_equal 2, result.length
    assert_equal 'Alice', result[0]['author']
    assert_equal 'Hello', result[0]['content']
  end

  def test_should_return_new_messages_for_consumer
    # Given: a service factory that returns a service with new messages
    messages = [stub_message(author: 'Alice', content: 'Hello')]
    AgentChat::Web::App.set :service_factory, stub_service_factory(new_messages: messages)

    # When
    get '/api/rooms/general/messages/new?consumer=Bob', {}, { 'HTTP_HOST' => 'localhost' }

    # Then
    assert last_response.ok?
    result = JSON.parse(last_response.body)
    assert_equal 1, result.length
    assert_equal 'Alice', result[0]['author']
  end

  def test_should_post_message_to_service
    # Given: a service factory that returns a recording service
    service = RecordingService.new
    AgentChat::Web::App.set :service_factory, StubServiceFactory.new(service)

    # When
    post '/api/rooms/general/messages',
         { author: 'Alice', content: 'Hello' }.to_json,
         { 'HTTP_HOST' => 'localhost', 'CONTENT_TYPE' => 'application/json' }

    # Then
    assert last_response.created?
    assert_equal 'general', service.last_room
    assert_equal 'Alice', service.last_author
    assert_equal 'Hello', service.last_content
  end

  private

  class RecordingService
    attr_reader :last_room, :last_author, :last_content

    def send_message(room:, author:, content:)
      @last_room = room
      @last_author = author
      @last_content = content
    end
  end

  class StubServiceFactory
    def initialize(service)
      @service = service
    end

    def for_room(_room)
      @service
    end
  end

  def stub_service_factory(messages: [], new_messages: [])
    service = Object.new.tap do |stub|
      stub.define_singleton_method(:get_messages) { |room:| messages }
      stub.define_singleton_method(:get_new_messages) { |room:, consumer:| new_messages }
    end
    StubServiceFactory.new(service)
  end

  def stub_message(author:, content:)
    Object.new.tap do |msg|
      msg.define_singleton_method(:author) { author }
      msg.define_singleton_method(:content) { content }
      msg.define_singleton_method(:timestamp) { Time.now }
    end
  end
end
