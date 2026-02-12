ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'json'

require 'agent_chat'

class ApiRoomsSpec < Minitest::Test
  include Rack::Test::Methods

  def app
    AgentChat::Web::App
  end

  def test_should_return_rooms_from_room_discovery_as_json
    # Given: a room discovery service that returns rooms
    AgentChat::Web::App.set :room_discovery, stub_room_discovery(rooms: ['alpha', 'beta'])

    # When
    get '/api/rooms', {}, { 'HTTP_HOST' => 'localhost' }

    # Then
    assert last_response.ok?
    assert_equal ['alpha', 'beta'], JSON.parse(last_response.body)
  end

  private

  def stub_room_discovery(rooms: [])
    Object.new.tap do |stub|
      stub.define_singleton_method(:list_rooms) { rooms }
    end
  end
end
