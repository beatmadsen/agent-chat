require 'json'
require 'sinatra/base'
require 'tmpdir'
require_relative 'post_body'
require_relative '../chat/entrance'

module AgentChat
  module Web
    class App < Sinatra::Base
      UNPROCESSABLE = %i[unknown_reply_to unknown_id].freeze

      set :public_folder, File.expand_path('../../../public', __dir__)
      set :chat_root, Dir.tmpdir

      # Sinatra serves the public folder but does not map / to its index, and
      # the README and the executable's help both point people at the bare URL.
      get '/' do
        send_file File.join(settings.public_folder, 'index.html')
      end

      get '/api/rooms' do
        respond(200, Room::Directory.new(settings.chat_root).names)
      end

      get '/api/rooms/:room/messages' do
        with_visit do |visit|
          messages = visit.chat.history
          visit.chat.mark_read(params[:consumer], through: messages.last.id) if params[:consumer] && !messages.empty?
          respond(200, messages.map(&:as_json))
        end
      end

      get '/api/rooms/:room/messages/new' do
        return refuse(Problem.new(:missing_parameter, 'consumer is required', parameter: 'consumer')) if params[:consumer].to_s.empty?

        with_visit { |visit| respond(200, visit.chat.unread(params[:consumer]).map(&:as_json)) }
      end

      post '/api/rooms/:room/messages' do
        request.body.rewind
        body = PostBody.parse(request.body.read)
        return refuse(body.problem) if body.is_a?(Rejected)

        with_visit { |visit| posted(visit, visit.chat.post(**body.value)) }
      end

      helpers do
        def with_visit
          outcome = Chat::Entrance.new(settings.chat_root).enter(params[:room])
          outcome.is_a?(Rejected) ? refuse(outcome.problem) : yield(outcome.value)
        end

        def posted(visit, outcome)
          return refuse(outcome.problem) if outcome.is_a?(Rejected)

          created = visit.arrival.kind == :created ? { room_created: true } : {}
          similar = visit.similar_rooms.empty? ? {} : { similar_rooms: visit.similar_rooms }
          respond(201, { status: 'accepted', assigned_id: outcome.value, **created, **similar })
        end

        def respond(code, data)
          status code
          content_type :json
          JSON.generate(data)
        end

        def refuse(problem)
          respond(UNPROCESSABLE.include?(problem.code) ? 422 : 400, { status: 'rejected', error: problem.as_json })
        end
      end
    end
  end
end
