require_relative 'parse'
require_relative 'vocabulary'
require_relative 'wording'

module AgentChat
  module CLI
    class FlagValues
      LIST_FLAG = '--reply-to'.freeze

      def initialize(command, uses)
        @command = command
        @uses = uses
      end

      def collect
        given = @uses.group_by(&:flag).transform_values { |uses| uses.map(&:value) }
        conflicts = given.select { |flag, values| flag != LIST_FLAG && values.uniq.size > 1 }
        return Parse.rejected(conflicting(conflicts)) unless conflicts.empty?

        settle(given.to_h { |flag, values| [flag, merge(flag, values)] })
      end

      private

      def conflicting(conflicts)
        flag, values = conflicts.first
        Wording.conflicting_values(flag, values.uniq)
      end

      def merge(flag, values)
        flag == LIST_FLAG ? values.flat_map { |value| value.split(',') } : values.first
      end

      def settle(values)
        reading_all = values.key?('--all')
        notices = reading_all && values.key?('--consumer') ? [Wording.ignored('--consumer', 'is not used with --all')] : []
        kept = reading_all ? values.except('--consumer') : values
        missing = required(reading_all).reject { |flag| kept.key?(flag) }
        return Parse.rejected(Wording.missing_flag(@command, missing.first), notices) unless missing.empty?

        Parse.accepted(kept, notices)
      end

      def required(reading_all)
        reading_all ? Vocabulary.required(@command) - ['--consumer'] : Vocabulary.required(@command)
      end
    end
  end
end
