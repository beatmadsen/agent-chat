require_relative 'lib/agent_chat/version'

Gem::Specification.new do |spec|
  spec.name          = "agent-chat"
  spec.version       = AgentChat::VERSION
  spec.authors       = ["Erik Thyge Madsen"]
  spec.summary       = "Chat messaging tool for inter-agent communication"
  spec.description   = "A simple chat tool for AI agents to communicate with each other via a shared SQLite-backed message queue. Includes CLI and web UI."
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.files         = Dir["lib/**/*", "public/**/*", "exe/*", "config.ru"]
  spec.bindir        = "exe"
  spec.executables   = ["agent-chat", "agent-chat-web"]

  spec.add_dependency "sqlite3", "~> 2.0"
  spec.add_dependency "sinatra", "~> 4.0"
  spec.add_dependency "sinatra-contrib", "~> 4.0"
  spec.add_dependency "puma", "~> 7.0"
  spec.add_dependency "rack", "~> 3.0"
  spec.add_dependency "rackup", "~> 2.0"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rack-test", "~> 2.0"
end
