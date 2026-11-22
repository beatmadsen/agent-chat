require_relative '../chat'
require_relative '../global_id'
require_relative '../room/name'
require_relative '../room/opener'

module AgentChat
  class Chat
    Visit = Data.define(:chat, :arrival, :similar_rooms)

    class Entrance
      def initialize(root, clock: -> { Time.now })
        @directory = Room::Directory.new(root)
        @clock = clock
      end

      def enter(room)
        problems = Room::Name.problems_with(room)
        return Rejected.new(problems.first) unless problems.empty?

        db, arrival = Room::Opener.new(@directory.location(room), clock: @clock).open
        chat = Chat.new(store: Room::Store.new(db), room:, clock: @clock, id_source: -> { GlobalId.generate })
        Accepted.new(Visit.new(chat:, arrival:, similar_rooms: similar_rooms(room, arrival)))
      end

      private

      def similar_rooms(room, arrival)
        return [] unless arrival.kind == :created

        @directory.names_near(room)
      end
    end
  end
end
