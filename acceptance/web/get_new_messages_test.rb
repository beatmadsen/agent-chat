ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'json'
require 'tmpdir'

require 'agent_chat'

class GetNewMessagesAcceptanceTest < Minitest::Test
  include Rack::Test::Methods

  def app
    AgentChat::Web::App
  end

  def test_should_return_only_unread_messages
    Dir.mktmpdir do |tmpdir|
      # Given: messages exist in a room
      service = AgentChat::Service::Main.standard(tmpdir: tmpdir, room: 'general')
      service.send_message(room: 'general', author: 'Alice', content: 'First')
      service.send_message(room: 'general', author: 'Bob', content: 'Second')

      AgentChat::Web::App.set :room_discovery, AgentChat::Web::RoomDiscoveryService.new(tmpdir: tmpdir)
      AgentChat::Web::App.set :service_factory, AgentChat::Web::ServiceFactory.new(tmpdir: tmpdir)

      # When: consumer fetches new messages for the first time
      get '/api/rooms/general/messages/new?consumer=Charlie', {}, { 'HTTP_HOST' => 'localhost' }

      # Then: they get all messages
      assert last_response.ok?
      messages = JSON.parse(last_response.body)
      assert_equal 2, messages.length

      # When: consumer fetches again (no new messages)
      get '/api/rooms/general/messages/new?consumer=Charlie', {}, { 'HTTP_HOST' => 'localhost' }

      # Then: they get empty
      messages = JSON.parse(last_response.body)
      assert_equal 0, messages.length

      # When: a new message arrives
      service.send_message(room: 'general', author: 'Alice', content: 'Third')

      # And: consumer fetches again
      get '/api/rooms/general/messages/new?consumer=Charlie', {}, { 'HTTP_HOST' => 'localhost' }

      # Then: they get only the new message
      messages = JSON.parse(last_response.body)
      assert_equal 1, messages.length
      assert_equal 'Third', messages[0]['content']
    end
  end
end
