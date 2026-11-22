require 'fileutils'
require 'sqlite3'
require_relative 'arrival'
require_relative 'directory'
require_relative 'schema'

module AgentChat
  module Room
    class Opener
      def initialize(location, clock: -> { Time.now })
        @location = location
        @clock = clock
      end

      def open
        FileUtils.mkdir_p(@location.folder)
        File.open(@location.lock, File::RDWR | File::CREAT) do |lock|
          lock.flock(File::LOCK_EX)
          open_while_locked
        end
      end

      private

      def open_while_locked
        arrival = arrive
        db = connect
        Schema.apply(db)
        [db, arrival]
      end

      def arrive
        return Arrival.created unless File.exist?(@location.database)

        state = inspect_schema
        return Arrival.reset(back_up) if state == :outdated

        state == :blank ? Arrival.created : Arrival.existing
      end

      def inspect_schema
        db = SQLite3::Database.new(@location.database)
        Schema.state(db)
      ensure
        db&.close
      end

      def back_up
        folder = @location.backup_folder(at: @clock.call)
        FileUtils.mkdir_p(folder)
        @location.database_files.select { |file| File.exist?(file) }.each { |file| File.rename(file, File.join(folder, File.basename(file))) }
        folder
      end

      def connect
        db = SQLite3::Database.new(@location.database)
        db.busy_timeout = 5000
        db.execute('PRAGMA journal_mode = WAL')
        db
      end
    end
  end
end
