module AgentChat
  module CLI
    module Vocabulary
      VALUE_FLAGS = %w[--room --author --consumer --reply-to].freeze
      SWITCHES = %w[--all --json].freeze
      FLAGS = (VALUE_FLAGS + SWITCHES).freeze
      HELP = %w[-h --help].freeze
      VERSION = %w[-v --version].freeze

      READING = { flags: %w[--room --consumer --all --json], required: %w[--room --consumer] }.freeze
      COMMANDS = {
        'send' => { flags: %w[--room --author --reply-to --json], required: %w[--room --author] },
        'receive' => READING,
        'stream' => READING,
        'show' => { flags: %w[--room --json], required: %w[--room] }
      }.freeze

      def self.takes_value?(flag) = VALUE_FLAGS.include?(flag)
      def self.applies?(command, flag) = COMMANDS.fetch(command)[:flags].include?(flag)
      def self.required(command) = COMMANDS.fetch(command)[:required]
      def self.flag_name(given) = "--#{given.sub(/\A-+/, '').downcase.tr('_', '-')}"
      def self.command_names = COMMANDS.keys
    end
  end
end
