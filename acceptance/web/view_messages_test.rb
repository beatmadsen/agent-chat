ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'json'
require 'tmpdir'

require 'agent_chat'

class ViewMessagesAcceptanceTest < Minitest::Test
  include Rack::Test::Methods

  def app
    AgentChat::Web::App
  end

  def test_should_return_messages_in_room
    Dir.mktmpdir do |tmpdir|
      # Given: messages exist in a room (created via agent-chat service)
      service = AgentChat::Service::Main.standard(tmpdir: tmpdir, room: 'general')
      service.send_message(room: 'general', author: 'Alice', content: 'Hello')
      service.send_message(room: 'general', author: 'Bob', content: 'Hi there')

      # Configure app with room discovery and service factory
      AgentChat::Web::App.set :room_discovery, AgentChat::Web::RoomDiscoveryService.new(tmpdir: tmpdir)
      AgentChat::Web::App.set :service_factory, AgentChat::Web::ServiceFactory.new(tmpdir: tmpdir)

      # When: user views messages in the room
      get '/api/rooms/general/messages', {}, { 'HTTP_HOST' => 'localhost' }

      # Then: they see messages from that room
      assert last_response.ok?, "Expected 200, got #{last_response.status}"
      messages = JSON.parse(last_response.body)
      assert_equal 2, messages.length
      assert_equal 'Alice', messages[0]['author']
      assert_equal 'Hello', messages[0]['content']
      assert_equal 'Bob', messages[1]['author']
      assert_equal 'Hi there', messages[1]['content']
    end
  end
end
