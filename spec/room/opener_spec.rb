require 'minitest/autorun'
require 'tmpdir'
require 'agent_chat/room/opener'

class OpenerSpec < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @directory = AgentChat::Room::Directory.new(@tmpdir)
    @location = @directory.location('general')
  end

  def teardown
    @writer&.close
    FileUtils.remove_entry(@tmpdir)
  end

  def test_should_report_a_room_it_had_to_create
    _db, arrival = open_room

    assert_equal :created, arrival.kind
  end

  def test_should_report_a_room_that_already_existed
    open_room.first.close

    _db, arrival = open_room

    assert_equal :existing, arrival.kind
  end

  def test_should_give_a_new_room_the_current_schema
    db, = open_room

    assert_equal :current, AgentChat::Room::Schema.state(db)
  end

  def test_should_report_where_it_backed_up_an_outdated_room
    create_outdated_room

    _db, arrival = open_room

    assert_equal File.join(@tmpdir, 'agent-chat', 'backups', '20261122T120000Z', 'general'), arrival.backup_path
  end

  def test_should_start_an_outdated_room_over_with_the_current_schema
    create_outdated_room

    db, = open_room

    assert_equal 0, db.get_first_value('SELECT count(*) FROM messages')
  end

  def test_should_keep_writes_still_in_the_write_ahead_log_in_the_backup
    @writer = create_outdated_room(journal_mode: 'WAL')

    _db, arrival = open_room

    backup = SQLite3::Database.new(File.join(arrival.backup_path, 'room.db'))
    assert_equal [['from old version']], backup.execute('SELECT content FROM messages')
  end

  def test_should_keep_the_old_messages_in_the_backup_when_several_processes_open_an_outdated_room_at_once
    create_outdated_room.close
    start, go = IO.pipe

    pids = Array.new(8) { fork { go.close; start.read; open_room; exit!(0) } }
    [start, go].each(&:close)
    pids.each { |pid| Process.wait(pid) }

    backup = SQLite3::Database.new(File.join(@tmpdir, 'agent-chat', 'backups', '20261122T120000Z', 'general', 'room.db'))
    assert_equal [['from old version']], backup.execute('SELECT content FROM messages')
  end

  private

  def open_room
    clock = -> { Time.utc(2026, 11, 22, 12) }
    AgentChat::Room::Opener.new(@location, clock:).open
  end

  def create_outdated_room(journal_mode: 'DELETE')
    FileUtils.mkdir_p(File.dirname(@location.database))
    db = SQLite3::Database.new(@location.database)
    db.execute("PRAGMA journal_mode = #{journal_mode}")
    db.execute('PRAGMA wal_autocheckpoint = 0')
    db.execute('CREATE TABLE messages (id INTEGER PRIMARY KEY, content TEXT)')
    db.execute("INSERT INTO messages (content) VALUES ('from old version')")
    db
  end
end
