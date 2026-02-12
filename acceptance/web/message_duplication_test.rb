ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'json'
require 'tmpdir'

require 'agent_chat'

class MessageDuplicationAcceptanceTest < Minitest::Test
  include Rack::Test::Methods

  def app
    AgentChat::Web::App
  end

  def test_should_not_duplicate_messages_when_polling_after_initial_load
    Dir.mktmpdir do |tmpdir|
      # Given: messages exist in a room
      service = AgentChat::Service::Main.standard(tmpdir: tmpdir, room: 'general')
      service.send_message(room: 'general', author: 'Alice', content: 'Hello')
      service.send_message(room: 'general', author: 'Bob', content: 'Hi there')

      AgentChat::Web::App.set :room_discovery, AgentChat::Web::RoomDiscoveryService.new(tmpdir: tmpdir)
      AgentChat::Web::App.set :service_factory, AgentChat::Web::ServiceFactory.new(tmpdir: tmpdir)

      # When: consumer loads all messages (initial page load)
      get '/api/rooms/general/messages?consumer=web+user', {}, { 'HTTP_HOST' => 'localhost' }
      assert last_response.ok?
      initial_messages = JSON.parse(last_response.body)
      assert_equal 2, initial_messages.length, "Initial load should return all messages"

      # And: consumer immediately polls for new messages
      get '/api/rooms/general/messages/new?consumer=web+user', {}, { 'HTTP_HOST' => 'localhost' }
      assert last_response.ok?
      new_messages = JSON.parse(last_response.body)

      # Then: the poll should return no messages (nothing new since initial load)
      assert_equal 0, new_messages.length,
        "Poll after initial load should return 0 messages, but got #{new_messages.length} " \
        "(messages were duplicated)"
    end
  end
end
