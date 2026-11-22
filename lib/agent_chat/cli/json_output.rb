require 'json'
require_relative 'notice'
require_relative '../message'

module AgentChat
  module CLI
    class JsonOutput
      def initialize(stdout:, stderr:)
        @stdout = stdout
        @stderr = stderr
      end

      def messages(messages)
        messages.each { |message| @stdout.puts(JSON.generate(message.as_json)) }
        @stdout.flush
      end

      def notices(notices)
        notices.each { |notice| @stderr.puts(JSON.generate({ notice.level => notice.problem.as_json })) }
      end

      def posted(id, notices)
        created = notices.find(&:room_created?)
        envelope = { status: 'accepted', assigned_id: id, **room_fields(created), **warnings(notices) }
        @stdout.puts(JSON.generate(envelope))
      end

      def rejected(problem, notices)
        @stdout.puts(JSON.generate({ status: 'rejected', error: problem.as_json, **warnings(notices) }))
      end

      def version(number)
        @stdout.puts(JSON.generate({ version: number }))
      end

      private

      def room_fields(created)
        return {} if created.nil?

        { room_created: true, **created.problem.details }
      end

      def warnings(notices)
        warnings = notices.select(&:warning?)
        warnings.empty? ? {} : { warnings: warnings.map { |notice| notice.problem.as_json } }
      end
    end
  end
end
