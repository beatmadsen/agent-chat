ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'json'
require 'tmpdir'

require 'agent_chat'

class PostMessageAcceptanceTest < Minitest::Test
  include Rack::Test::Methods

  def app
    AgentChat::Web::App
  end

  def test_should_post_message_and_see_it_in_room
    Dir.mktmpdir do |tmpdir|
      # Given: app configured with room discovery and service factory
      AgentChat::Web::App.set :room_discovery, AgentChat::Web::RoomDiscoveryService.new(tmpdir: tmpdir)
      AgentChat::Web::App.set :service_factory, AgentChat::Web::ServiceFactory.new(tmpdir: tmpdir)

      # When: user posts a message
      post '/api/rooms/general/messages',
           { author: 'Alice', content: 'Hello world' }.to_json,
           { 'HTTP_HOST' => 'localhost', 'CONTENT_TYPE' => 'application/json' }

      # Then: request succeeds
      assert last_response.created?, "Expected 201, got #{last_response.status}"

      # And: message appears in the room
      get '/api/rooms/general/messages', {}, { 'HTTP_HOST' => 'localhost' }
      messages = JSON.parse(last_response.body)
      assert_equal 1, messages.length
      assert_equal 'Alice', messages[0]['author']
      assert_equal 'Hello world', messages[0]['content']
    end
  end
end
