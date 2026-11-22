require 'minitest/autorun'
require 'agent_chat/chat'

class ReadingSpec < Minitest::Test
  def setup
    ids = %w[aaaaaaa bbbbbbb ccccccc]
    db = SQLite3::Database.new(':memory:')
    AgentChat::Room::Schema.apply(db)
    @chat = AgentChat::Chat.new(store: AgentChat::Room::Store.new(db), room: 'general',
                                clock: -> { Time.now }, id_source: -> { ids.shift })
    %w[one two three].each { |content| @chat.post(author: 'Alice', content:, reply_to: []) }
  end

  def test_should_give_a_new_consumer_every_message
    assert_equal %w[one two three], @chat.unread('Bob').map(&:content)
  end

  def test_should_give_a_consumer_nothing_it_has_already_read
    @chat.unread('Bob')

    assert_empty @chat.unread('Bob')
  end

  def test_should_give_a_consumer_only_messages_after_the_one_it_marked_read
    @chat.mark_read('Bob', through: 'bbbbbbb')

    assert_equal %w[three], @chat.unread('Bob').map(&:content)
  end

  def test_should_give_the_history_after_a_message
    assert_equal %w[two three], @chat.history_after('aaaaaaa').map(&:content)
  end

  def test_should_find_messages_in_the_order_asked_for
    assert_equal %w[three one], @chat.find(%w[ccccccc aaaaaaa]).value.map(&:content)
  end

  def test_should_reject_a_lookup_that_names_an_unknown_id
    assert_equal({ ids: %w[zzzzzzz] }, @chat.find(%w[aaaaaaa zzzzzzz]).problem.details)
  end
end
