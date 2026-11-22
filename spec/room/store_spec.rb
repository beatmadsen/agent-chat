require 'minitest/autorun'
require 'agent_chat/room/store'

class StoreSpec < Minitest::Test
  NOON = Time.utc(2026, 11, 22, 12)

  def setup
    db = SQLite3::Database.new(':memory:')
    AgentChat::Room::Schema.apply(db)
    @store = AgentChat::Room::Store.new(db)
  end

  def test_should_return_a_saved_message_with_its_fields
    @store.insert(saved_message('aaaaaaa', reply_to: ['bbbbbbb']))

    assert_equal [saved_message('aaaaaaa', reply_to: ['bbbbbbb'])], @store.messages_after(nil)
  end

  def test_should_keep_replies_in_the_order_they_were_given
    @store.insert(saved_message('aaaaaaa', reply_to: %w[ccccccc bbbbbbb ddddddd]))

    assert_equal %w[ccccccc bbbbbbb ddddddd], @store.messages_after(nil).first.reply_to
  end

  def test_should_refuse_an_id_that_is_already_taken
    @store.insert(saved_message('aaaaaaa'))

    assert_raises(AgentChat::Room::IdTaken) { @store.insert(saved_message('aaaaaaa')) }
  end

  def test_should_return_only_messages_saved_after_the_given_id
    %w[aaaaaaa bbbbbbb ccccccc].each { |id| @store.insert(saved_message(id)) }

    assert_equal %w[ccccccc], @store.messages_after('bbbbbbb').map(&:id)
  end

  def test_should_find_messages_by_id
    %w[aaaaaaa bbbbbbb ccccccc].each { |id| @store.insert(saved_message(id)) }

    assert_equal %w[aaaaaaa ccccccc], @store.messages_with_ids(%w[ccccccc aaaaaaa]).map(&:id)
  end

  def test_should_tell_which_of_the_given_ids_exist
    @store.insert(saved_message('aaaaaaa'))

    assert_equal Set['aaaaaaa'], @store.existing_ids(%w[aaaaaaa zzzzzzz])
  end

  def test_should_have_no_read_position_for_a_new_consumer
    assert_nil @store.read_position('Bob')
  end

  def test_should_remember_how_far_a_consumer_has_read
    %w[aaaaaaa bbbbbbb].each { |id| @store.insert(saved_message(id)) }
    @store.move_read_position('Bob', to: 'aaaaaaa')
    @store.move_read_position('Bob', to: 'bbbbbbb')

    assert_equal 'bbbbbbb', @store.read_position('Bob')
  end

  private

  def saved_message(id, reply_to: [])
    AgentChat::Message.new(id:, author: 'Alice', content: "content of #{id}", timestamp: NOON, reply_to:)
  end
end
