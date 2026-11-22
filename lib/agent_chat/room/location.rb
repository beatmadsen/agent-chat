module AgentChat
  module Room
    class Location
      attr_reader :name

      def initialize(root:, name:)
        @root = root
        @name = name
      end

      def folder = File.join(@root, 'agent-chat', 'rooms', @name)
      def database = File.join(folder, 'room.db')
      def lock = File.join(folder, 'room.lock')
      def database_files = [database, "#{database}-wal", "#{database}-shm"]

      def backup_folder(at:)
        File.join(@root, 'agent-chat', 'backups', at.getutc.strftime('%Y%m%dT%H%M%SZ'), @name)
      end
    end
  end
end
