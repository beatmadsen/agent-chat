require 'agent_chat'
require 'tmpdir'

tmpdir = Dir.tmpdir
AgentChat::Web::App.set :room_discovery, AgentChat::Web::RoomDiscoveryService.new(tmpdir: tmpdir)
AgentChat::Web::App.set :service_factory, AgentChat::Web::ServiceFactory.new(tmpdir: tmpdir)

run AgentChat::Web::App
