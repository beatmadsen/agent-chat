module AgentChat
  module Spelling
    def self.distance(given, known)
      EditTable.new(given, known).distance
    end

    def self.one_edit_apart?(given, known)
      distance(given, known) == 1
    end

    class EditTable
      def initialize(given, known)
        @given = given
        @known = known
        @cells = Array.new(given.length + 1) { |row| Array.new(known.length + 1) { |column| edge(row, column) } }
      end

      def distance
        (1..@given.length).each do |row|
          (1..@known.length).each { |column| fill(row, column) }
        end
        @cells[@given.length][@known.length]
      end

      private

      def edge(row, column)
        [row, column].min.zero? ? row + column : nil
      end

      def fill(row, column)
        changed = @given[row - 1] == @known[column - 1] ? 0 : 1
        best = [@cells[row - 1][column] + 1, @cells[row][column - 1] + 1, @cells[row - 1][column - 1] + changed].min
        best = [best, @cells[row - 2][column - 2] + 1].min if swapped?(row, column)
        @cells[row][column] = best
      end

      def swapped?(row, column)
        row > 1 && column > 1 && @given[row - 1] == @known[column - 2] && @given[row - 2] == @known[column - 1]
      end
    end
  end
end
