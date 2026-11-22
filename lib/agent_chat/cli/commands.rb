module AgentChat
  module CLI
    module Commands
      class Send
        def initialize(chat:, output:, stdin:)
          @chat = chat
          @output = output
          @stdin = stdin
        end

        def run(request, notices)
          content = @stdin.read.chomp
          outcome = @chat.post(author: request.author, content:, reply_to: request.reply_to)
          return Runner::REFUSED.tap { @output.rejected(outcome.problem, notices) } if outcome.is_a?(Rejected)

          @output.posted(outcome.value, notices)
          Runner::OK
        end
      end

      class Receive
        def initialize(chat:, output:)
          @chat = chat
          @output = output
        end

        def run(request, notices)
          @output.notices(notices)
          @output.messages(request.all ? @chat.history : @chat.unread(request.consumer))
          Runner::OK
        end
      end

      class Show
        def initialize(chat:, output:)
          @chat = chat
          @output = output
        end

        def run(request, notices)
          @output.notices(notices)
          outcome = @chat.find(request.ids)
          return Runner::REFUSED.tap { @output.rejected(outcome.problem, []) } if outcome.is_a?(Rejected)

          @output.messages(outcome.value)
          Runner::OK
        end
      end
    end
  end
end
