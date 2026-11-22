require_relative 'location'
require_relative '../spelling'

module AgentChat
  module Room
    class Directory
      def initialize(root)
        @root = root
      end

      def location(name)
        Location.new(root: @root, name:)
      end

      def names
        rooms = File.join(@root, 'agent-chat', 'rooms')
        return [] unless Dir.exist?(rooms)

        Dir.children(rooms).select { |name| File.exist?(location(name).database) }.sort
      end

      def names_near(name)
        names.select { |other| Spelling.one_edit_apart?(name, other) }
      end
    end
  end
end
