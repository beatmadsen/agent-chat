# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2026-09-20

### Fixed
- The web UI returned 404 at `http://localhost:4567`, the address the README
  and `agent-chat-web --help` both give. Sinatra serves the public folder but
  does not map `/` to its index, so only `/index.html` worked.

### Changed
- `puma` moves from 7.x to 8.x.
- `required_ruby_version` is now `>= 3.2`. The stated floor of 3.0 was never
  reachable, because sqlite3 requires 3.2.
- Publishing requires multi-factor auth, and the gemspec carries the homepage,
  bug tracker and documentation links it was missing.

## [1.0.2] - 2026-02-20

### Fixed
- SQLite3::BusyException when multiple agents access the same room concurrently
- Enable WAL journal mode and busy timeout for reliable multi-process database access

## [1.0.1] - 2026-02-12

### Added
- `--version` / `-v` flag for both `agent-chat` and `agent-chat-web`
- `--help` / `-h` flag for `agent-chat-web`
- GitHub metadata in gemspec
- Bundler gem_tasks for `rake release`

### Fixed
- Message duplication in web UI when loading rooms
- Message duplication in web UI when polling returns already-loaded messages
- Bash history expansion issue in help text example (`echo "Hello!"` → `echo 'Hello!'`)
- Graceful handling of missing `xdg-open` on Linux when opening browser

## [1.0.0] - 2026-02-12

### Added
- CLI tool (`agent-chat`) with send, receive, and stream commands for inter-agent messaging
- Web UI (`agent-chat-web`) with dark-themed chat interface for browsing and posting messages
- Room-based SQLite persistence with each room maintaining its own database
- Consumer read position tracking to show only new messages for each consumer
- Markdown rendering support in web UI messages
- Optimistic message posting in web UI with instant feedback
- Auto-scroll functionality with scroll position preservation
- Keyboard shortcuts: Enter to send messages, Shift+Enter for newlines
- Room discovery from filesystem with automatic listing
- Cross-platform browser opening support (macOS, Linux, Windows)
- Comprehensive test suite: 34 unit tests, 13 acceptance tests, 22 frontend tests
