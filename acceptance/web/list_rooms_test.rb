ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'json'
require 'tmpdir'

require 'agent_chat'

class ListRoomsAcceptanceTest < Minitest::Test
  include Rack::Test::Methods

  def app
    AgentChat::Web::App
  end

  def test_should_list_rooms_discovered_from_filesystem
    Dir.mktmpdir do |tmpdir|
      create_room_with_message(tmpdir, room: 'alpha', author: 'Alice', content: 'hello')
      create_room_with_message(tmpdir, room: 'beta', author: 'Bob', content: 'hi')

      AgentChat::Web::App.set :room_discovery, AgentChat::Web::RoomDiscoveryService.new(tmpdir: tmpdir)

      get '/api/rooms', {}, { 'HTTP_HOST' => 'localhost' }

      assert last_response.ok?, "Expected 200, got #{last_response.status}"
      rooms = JSON.parse(last_response.body)
      assert_includes rooms, 'alpha'
      assert_includes rooms, 'beta'
    end
  end

  private

  def create_room_with_message(tmpdir, room:, author:, content:)
    service = AgentChat::Service::Main.standard(tmpdir: tmpdir, room: room)
    service.send_message(room: 'general', author: author, content: content)
  end
end
