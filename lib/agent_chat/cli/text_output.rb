require_relative 'notice'
require_relative '../message'

module AgentChat
  module CLI
    class TextOutput
      LABELS = { info: 'note', warning: 'warning' }.freeze

      def initialize(stdout:, stderr:)
        @stdout = stdout
        @stderr = stderr
      end

      def messages(messages)
        return if messages.empty?

        @stdout.puts(messages.map { |message| block(message) }.join("\n\n\n\n"))
        @stdout.flush
      end

      def notices(notices)
        notices.each { |notice| @stderr.puts("#{LABELS.fetch(notice.level)}: #{notice.problem.message}") }
      end

      def posted(id, notices)
        notices(notices)
        @stdout.puts(id)
      end

      def rejected(problem, notices)
        notices(notices)
        @stderr.puts("error: #{problem.message}")
      end

      def version(number)
        @stdout.puts("agent-chat #{number}")
      end

      private

      def block(message)
        time = message.timestamp.localtime.strftime('%Y-%m-%d %H:%M:%S')
        replies = message.reply_to.empty? ? '' : " | re: #{message.reply_to.join(', ')}"
        "<<< #{message.author} | #{time} | #{message.id}#{replies} >>>\n#{message.content}"
      end
    end
  end
end
