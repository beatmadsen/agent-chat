require 'minitest/autorun'
require 'agent_chat/web/post_body'

class PostBodySpec < Minitest::Test
  include AgentChat

  def test_should_read_author_content_and_reply_ids
    assert_equal Accepted.new({ author: 'Alice', content: 'hi', reply_to: %w[aaaaaaa] }),
                 Web::PostBody.parse('{"author":"Alice","content":"hi","reply_to":["aaaaaaa"]}')
  end

  def test_should_read_a_body_without_reply_ids_as_answering_nothing
    assert_equal [], Web::PostBody.parse('{"author":"Alice","content":"hi"}').value[:reply_to]
  end

  def test_should_leave_missing_author_and_content_for_the_chat_to_refuse
    assert_equal({ author: '', content: '' }, Web::PostBody.parse('{}').value.slice(:author, :content))
  end

  def test_should_refuse_text_that_is_not_json
    assert_equal :invalid_json, Web::PostBody.parse('{oops').problem.code
  end

  def test_should_refuse_json_that_is_not_an_object
    assert_equal({ code: 'invalid_json', message: 'The body must be a JSON object' },
                 Web::PostBody.parse('["Alice","hi"]').problem.as_json)
  end

  def test_should_refuse_reply_ids_that_are_not_a_list
    assert_equal({ code: 'invalid_field', message: 'reply_to must be a list of message ids', field: 'reply_to' },
                 Web::PostBody.parse('{"author":"Alice","content":"hi","reply_to":"aaaaaaa"}').problem.as_json)
  end

  def test_should_refuse_reply_ids_that_are_not_all_strings
    assert_equal :invalid_field, Web::PostBody.parse('{"author":"Alice","content":"hi","reply_to":["aaaaaaa",7]}').problem.code
  end

  def test_should_name_the_media_type_it_will_not_take
    assert_equal 'Send the body as application/json, not text/plain', Web::PostBody.unsupported('text/plain').message
  end

  def test_should_say_when_a_body_came_without_a_media_type
    assert_equal 'Send the body as application/json, not without a Content-Type', Web::PostBody.unsupported(nil).message
  end
end
