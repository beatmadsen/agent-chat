module AgentChat
  module Web
    class RoomDiscoveryService
      def initialize(tmpdir:)
        @tmpdir = tmpdir
      end

      def list_rooms
        rooms_path = "#{@tmpdir}/agent-chat/rooms"
        return [] unless Dir.exist?(rooms_path)

        Dir.children(rooms_path).select do |name|
          File.exist?("#{rooms_path}/#{name}/room.db")
        end
      end
    end
  end
end
