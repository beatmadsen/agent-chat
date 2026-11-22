# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - Unreleased

### Breaking
- Ruby 3.3 or later is required. Ruby 3.2 is no longer supported.
- Rooms written by 1.x are not read. The first 2.0 command to open such a
  room moves its database to `$TMPDIR/agent-chat/backups/<UTC time>/<room>/`
  and starts the room empty, with a `room_reset` warning naming the backup.
  Later schema changes will do the same rather than migrate.
- `send` now prints the id the new message was given. It used to print
  nothing.
- Unknown flags and commands are no longer ignored. One edit from exactly
  one known name, or differing only in case, underscores or dashes, they are
  read as that name with a warning; otherwise the command is refused with
  exit status 2. A flag the command does not take is ignored with a warning.
  A missing `--room`, `--author` or `--consumer`, or a flag without its
  value, is refused instead of failing deep inside.
- The text header gains the message id and, for replies, the ids answered:
  `<<< Alice | 2026-11-22 14:30:00 | 7xKqR2m | re: 3fGhJ9k >>>`.
- `receive` prints nothing when there is nothing new. It used to print an
  empty line.
- `send` refuses empty content and strips the newline `echo` adds.
- Room names must be plain folder names: no `/`, `\`, control characters,
  `.` or `..`.
- The web API answers a POST with 201 and a JSON body, refuses a body not
  labelled `application/json` with 415, and requires `consumer` on
  `/messages/new`.

### Added
- Every message has a random 7-character base58 id.
- `send --reply-to <id>` links a message to the messages it answers. Repeat
  the flag or separate ids with commas. An unknown id refuses the whole
  message and nothing is saved.
- `--json` on every command. Messages are one JSON object per line with
  `id`, `author`, `timestamp` (UTC), `content` and `reply_to`. `send` prints
  `{"status":"accepted","assigned_id":...}`. A refused request prints
  `{"status":"rejected","error":{"code":...,"message":...}}` and exits 1.
  Notes and warnings go to standard error as JSON lines.
- `show --room <name> <id>...` prints messages by id.
- `--all` on `receive` and `stream` reads the whole history without moving
  any read position.
- Reading a room that does not exist says that it created the room, and
  names an existing room one edit away.
- The web UI shows message ids and reply links that jump to the message
  answered, and lets you reply to several messages at once.
- The web API returns `id` and `reply_to`, accepts `reply_to` on POST, and
  reports problems with the same error object as the CLI (400, or 422 for
  unknown ids).

### Fixed
- Pressing Ctrl-C just after `stream` or `receive` started crashed Ruby with
  a `[BUG]` report. The interrupt landed while sqlite3 was loading Ruby's
  UTF-16 encodings on its first query. They are now loaded before any query,
  and `stream` stops with status 0.
- The note naming similar rooms said "a room named a and a room named b
  exists". It now says "exist" when it names more than one.
- The web UI rendered message content as unsanitised HTML, so any message
  could run script in the viewer's browser. Content is now sanitised.
- The web UI dropped a message posted in the same second as another,
  because it compared timestamps.
- The web UI rebuilt the whole feed on every poll, reloading images and
  cancelling highlights.

### Changed
- Dependencies move to their latest releases: jest 30, marked 18, and the
  latest minor versions of every gem. `sinatra-contrib` is no longer used.
- The gem now includes its LICENSE, README and CHANGELOG.

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
