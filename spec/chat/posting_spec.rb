require 'minitest/autorun'
require 'agent_chat/chat'

class PostingSpec < Minitest::Test
  def setup
    @ids = %w[aaaaaaa bbbbbbb ccccccc ddddddd]
    @chat = AgentChat::Chat.new(store: in_memory_store, room: 'general',
                                clock: -> { Time.utc(2026, 11, 22, 12) }, id_source: -> { @ids.shift })
  end

  def test_should_accept_a_message_under_a_new_id
    assert_equal AgentChat::Accepted.new('aaaaaaa'), post('hello')
  end

  def test_should_draw_another_id_when_the_drawn_one_is_taken
    @ids = %w[aaaaaaa aaaaaaa bbbbbbb]
    post('first')

    assert_equal AgentChat::Accepted.new('bbbbbbb'), post('second')
  end

  def test_should_reject_a_message_without_an_author
    assert_equal :missing_author, post('hello', author: ' ').problem.code
  end

  def test_should_reject_a_message_without_content
    assert_equal :empty_content, post(" \n").problem.code
  end

  def test_should_reject_a_reply_to_an_unknown_id
    assert_equal :unknown_reply_to, post('reply', reply_to: %w[zzzzzzz]).problem.code
  end

  def test_should_list_every_unknown_reply_id_in_the_rejection
    post('known')

    assert_equal({ ids: %w[zzzzzzz yyyyyyy] }, post('reply', reply_to: %w[zzzzzzz aaaaaaa yyyyyyy]).problem.details)
  end

  def test_should_save_nothing_when_a_reply_id_is_unknown
    post('reply', reply_to: %w[zzzzzzz])

    assert_empty @chat.history
  end

  def test_should_drop_repeated_reply_ids_and_keep_the_first_order
    post('one')
    post('two')
    post('three', reply_to: %w[bbbbbbb aaaaaaa bbbbbbb])

    assert_equal %w[bbbbbbb aaaaaaa], @chat.history.last.reply_to
  end

  def test_should_save_the_time_of_posting
    post('hello')

    assert_equal Time.utc(2026, 11, 22, 12), @chat.history.first.timestamp
  end

  private

  def post(content, author: 'Alice', reply_to: [])
    @chat.post(author:, content:, reply_to:)
  end

  def in_memory_store
    db = SQLite3::Database.new(':memory:')
    AgentChat::Room::Schema.apply(db)
    AgentChat::Room::Store.new(db)
  end
end
