module AgentChat
  module CLI
    module Commands
      class Stream
        def initialize(chat:, output:, pause:)
          @chat = chat
          @output = output
          @pause = pause
        end

        def run(request, notices)
          @output.notices(notices)
          request.all ? follow_everything : follow_unread(request.consumer)
        end

        private

        def follow_unread(consumer)
          loop do
            @output.messages(@chat.unread(consumer))
            @pause.call
          end
        end

        def follow_everything
          last_id = nil
          loop do
            batch = @chat.history_after(last_id)
            @output.messages(batch)
            last_id = batch.last.id unless batch.empty?
            @pause.call
          end
        end
      end
    end
  end
end
