module AgentChat
  module Web
    class ServiceFactory
      def initialize(tmpdir:)
        @tmpdir = tmpdir
      end

      def for_room(room)
        AgentChat::Service::Main.standard(tmpdir: @tmpdir, room: room)
      end
    end
  end
end
