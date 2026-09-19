require 'sinatra/base'
require 'sinatra/json'

module AgentChat
  module Web
    class App < Sinatra::Base
      helpers Sinatra::JSON

      set :public_folder, File.expand_path('../../../../public', __FILE__)

      # Sinatra serves the public folder but does not map / to its index, and
      # the README and the executable's help both point people at the bare URL.
      get '/' do
        send_file File.join(settings.public_folder, 'index.html')
      end

      get '/api/rooms' do
        json settings.room_discovery.list_rooms
      end

      get '/api/rooms/:room/messages' do
        service = settings.service_factory.for_room(params[:room])
        messages = service.get_messages(room: params[:room], consumer: params[:consumer])
        json messages.map { |m| { author: m.author, content: m.content, timestamp: m.timestamp } }
      end

      get '/api/rooms/:room/messages/new' do
        service = settings.service_factory.for_room(params[:room])
        messages = service.get_new_messages(room: params[:room], consumer: params[:consumer])
        json messages.map { |m| { author: m.author, content: m.content, timestamp: m.timestamp } }
      end

      post '/api/rooms/:room/messages' do
        service = settings.service_factory.for_room(params[:room])
        data = JSON.parse(request.body.read)
        service.send_message(
          room: params[:room],
          author: data['author'],
          content: data['content']
        )
        status 201
      end
    end
  end
end
