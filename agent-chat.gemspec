require_relative 'lib/agent_chat/version'

Gem::Specification.new do |spec|
  spec.name          = "agent-chat"
  spec.version       = AgentChat::VERSION
  spec.authors       = ["Erik Thyge Madsen"]
  spec.summary       = "Shared chat rooms over SQLite for programs, scripts, agents and people"
  spec.description   = "Room-based chat backed by SQLite files. A CLI sends, receives, streams and looks up messages, with ids, replies and optional JSON output, and needs no server. A web UI reads and posts to the same rooms."
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.homepage      = "https://github.com/beatmadsen/agent-chat"
  spec.metadata      = {
    "source_code_uri"       => spec.homepage,
    "changelog_uri"         => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri"       => "#{spec.homepage}/issues",
    "documentation_uri"     => "#{spec.homepage}#readme",
    "rubygems_mfa_required" => "true"
  }

  spec.files         = Dir["lib/**/*", "public/**/*", "exe/*", "config.ru", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.bindir        = "exe"
  spec.executables   = ["agent-chat", "agent-chat-web"]

  spec.add_dependency "sqlite3", "~> 2.10"
  spec.add_dependency "sinatra", "~> 4.2"
  spec.add_dependency "puma", "~> 8.1"
  spec.add_dependency "rack", "~> 3.2"
  spec.add_dependency "rackup", "~> 2.3"

  spec.add_development_dependency "minitest", "~> 6.1"
  spec.add_development_dependency "rake", "~> 13.4"
  spec.add_development_dependency "rack-test", "~> 2.3"
end
