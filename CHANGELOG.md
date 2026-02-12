# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
