ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'rack/lint'
require 'tmpdir'
require 'agent_chat/web/app'

class WebApiAcceptanceTest < Minitest::Test
  include Rack::Test::Methods

  def app = Rack::Lint.new(AgentChat::Web::App)

  def setup
    @tmpdir = Dir.mktmpdir
    AgentChat::Web::App.set :chat_root, @tmpdir
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_should_answer_an_accepted_post_with_201_and_the_assigned_id
    post_message(author: 'Alice', content: 'hi')

    assert_equal [201, %w[status assigned_id room_created]], [last_response.status, body.keys]
  end

  def test_should_answer_a_post_to_an_existing_room_with_only_status_and_id
    post_message(author: 'Alice', content: 'one')

    post_message(author: 'Bob', content: 'two')

    assert_equal %w[status assigned_id], body.keys
  end

  def test_should_name_existing_rooms_close_to_one_a_post_created
    post '/api/rooms/general/messages', { author: 'Alice', content: 'one' }.to_json, 'CONTENT_TYPE' => 'application/json'

    post '/api/rooms/genral/messages', { author: 'Bob', content: 'two' }.to_json, 'CONTENT_TYPE' => 'application/json'

    assert_equal %w[general], body['similar_rooms']
  end

  def test_should_return_messages_with_ids_and_replies
    first = post_message(author: 'Alice', content: 'one')['assigned_id']
    second = post_message(author: 'Bob', content: 'two', reply_to: [first])['assigned_id']

    get '/api/rooms/general/messages'

    assert_equal [{ 'id' => second, 'author' => 'Bob', 'timestamp' => body[1]['timestamp'], 'content' => 'two',
                    'reply_to' => [first] }], body.drop(1)
  end

  def test_should_answer_a_reply_to_an_unknown_id_with_422
    post_message(author: 'Alice', content: 'hi', reply_to: ['zzzzzzz'])

    assert_equal [422, 'unknown_reply_to'], [last_response.status, body.dig('error', 'code')]
  end

  def test_should_answer_a_body_that_is_not_json_with_400
    post '/api/rooms/general/messages', '{oops', 'CONTENT_TYPE' => 'application/json'

    assert_equal [400, 'invalid_json'], [last_response.status, body.dig('error', 'code')]
  end

  def test_should_answer_a_post_that_is_not_labelled_as_json_with_415
    post '/api/rooms/general/messages', { author: 'Alice', content: 'hi' }.to_json, 'CONTENT_TYPE' => 'text/plain'

    assert_equal [415, 'unsupported_media_type'], [last_response.status, body.dig('error', 'code')]
  end

  def test_should_give_a_consumer_only_messages_it_has_not_read
    post_message(author: 'Alice', content: 'one')
    get '/api/rooms/general/messages/new?consumer=Carol'
    post_message(author: 'Alice', content: 'two')

    get '/api/rooms/general/messages/new?consumer=Carol'

    assert_equal %w[two], body.map { |message| message['content'] }
  end

  def test_should_count_a_full_load_with_a_consumer_as_read
    post_message(author: 'Alice', content: 'one')
    get '/api/rooms/general/messages?consumer=web+user'

    get '/api/rooms/general/messages/new?consumer=web+user'

    assert_equal [], body
  end

  def test_should_answer_a_full_load_of_an_empty_room_with_a_consumer
    get '/api/rooms/general/messages?consumer=web+user'

    assert_equal [200, []], [last_response.status, body]
  end

  def test_should_answer_a_new_messages_request_without_a_consumer_with_400
    get '/api/rooms/general/messages/new'

    assert_equal [400, 'missing_parameter'], [last_response.status, body.dig('error', 'code')]
  end

  def test_should_answer_a_room_name_that_cannot_be_a_folder_with_400
    get '/api/rooms/a%09b/messages'

    assert_equal [400, 'invalid_room'], [last_response.status, body.dig('error', 'code')]
  end

  def test_should_list_the_rooms_in_name_order
    %w[beta alpha].each { |room| post "/api/rooms/#{room}/messages", { author: 'A', content: 'x' }.to_json, 'CONTENT_TYPE' => 'application/json' }

    get '/api/rooms'

    assert_equal %w[alpha beta], body
  end

  private

  def body = JSON.parse(last_response.body)

  def post_message(**fields)
    post '/api/rooms/general/messages', fields.to_json, 'CONTENT_TYPE' => 'application/json'
    body
  end
end
