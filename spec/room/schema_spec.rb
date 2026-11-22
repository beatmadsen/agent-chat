require 'minitest/autorun'
require 'agent_chat/room/schema'

class SchemaSpec < Minitest::Test
  def setup
    @db = SQLite3::Database.new(':memory:')
  end

  def test_should_see_an_empty_database_as_blank
    assert_equal :blank, AgentChat::Room::Schema.state(@db)
  end

  def test_should_see_its_own_schema_as_current
    AgentChat::Room::Schema.apply(@db)

    assert_equal :current, AgentChat::Room::Schema.state(@db)
  end

  def test_should_see_tables_from_another_version_as_outdated
    @db.execute('CREATE TABLE messages (id INTEGER PRIMARY KEY)')

    assert_equal :outdated, AgentChat::Room::Schema.state(@db)
  end

  def test_should_leave_an_applied_schema_unchanged_when_applied_again
    AgentChat::Room::Schema.apply(@db)

    AgentChat::Room::Schema.apply(@db)

    assert_equal :current, AgentChat::Room::Schema.state(@db)
  end
end
