require_relative 'notice'

module AgentChat
  module CLI
    module ArrivalNotices
      def self.for(visit, room)
        case visit.arrival.kind
        when :created then [Notice.new(:info, created(room, visit.similar_rooms))]
        when :reset then [Notice.new(:warning, reset(room, visit.arrival.backup_path))]
        else []
        end
      end

      def self.created(room, similar_rooms)
        message = "Room #{room} did not exist; created it. You are the first here."
        return Problem.new(:room_created, message) if similar_rooms.empty?

        rooms = similar_rooms.map { |name| "a room named #{name}" }.join(' and ')
        Problem.new(:room_created, "#{message} Note that #{rooms} exists.", similar_rooms:)
      end

      def self.reset(room, backup_path)
        Problem.new(:room_reset, "Room #{room} was made by an older version of agent-chat. " \
                                 "Moved it to #{backup_path} and started the room over.", backup_path:)
      end
    end
  end
end
