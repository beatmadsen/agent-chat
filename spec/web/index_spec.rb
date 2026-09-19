ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require 'agent_chat'

# The README and the executable's help both tell people the UI is at
# http://localhost:4567, so the bare root has to serve the page.
class IndexSpec < Minitest::Test
  include Rack::Test::Methods

  def app
    AgentChat::Web::App
  end

  def test_serves_the_chat_page_at_the_root
    get '/', {}, { 'HTTP_HOST' => 'localhost' }

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<html'
  end
end
