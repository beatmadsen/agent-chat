# agent-chat

A chat messaging tool for inter-agent communication, backed by SQLite. Designed for AI agents (or humans) that need a simple shared message queue with room-based conversations.

Includes a CLI (`agent-chat`) and a web UI (`agent-chat-web`).

## Installation

```
gem install agent-chat
```

Or add to your Gemfile:

```ruby
gem "agent-chat"
```

Requires Ruby >= 3.0.

## CLI Usage

```
agent-chat <command> [options]
```

### Commands

**send** -- Send a message (reads content from stdin):

```bash
echo "Hello!" | agent-chat send --room general --author Alice
```

**receive** -- Receive new messages (one-shot):

```bash
agent-chat receive --room general --consumer Bob
```

**stream** -- Stream messages continuously (Ctrl-C to stop):

```bash
agent-chat stream --room general --consumer Bob
```

### Options

| Option | Description |
|--------|-------------|
| `--room <name>` | Chat room name (required) |
| `--author <name>` | Author name for sending messages |
| `--consumer <name>` | Consumer name for tracking read position |
| `-h, --help` | Show help |

### Message Format

Received messages are formatted as:

```
<<< Alice | 2025-01-15 14:30:00 >>>
Hello!
```

## Web UI

Launch the web interface:

```bash
agent-chat-web
```

This starts a Sinatra server on `http://localhost:4567` and opens it in your browser. The web UI provides a dark-themed chat interface with a room sidebar for browsing conversations.

### API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/rooms` | List all rooms |
| GET | `/api/rooms/:room/messages` | Get all messages in a room |
| GET | `/api/rooms/:room/messages/new?consumer=NAME` | Get new messages for a consumer |
| POST | `/api/rooms/:room/messages` | Send a message (JSON body: `author`, `content`) |

## How It Works

Each room gets its own SQLite database stored in your system's temp directory:

```
$TMPDIR/agent-chat/rooms/<room-name>/room.db
```

Key concepts:

- **Rooms** are independent chat channels, each with its own database file.
- **Consumers** track read positions independently. When a consumer calls `receive`, they only get messages they haven't seen before.
- **No server required** for CLI usage. Multiple processes can read and write to the same SQLite database concurrently.
- Messages persist across restarts. The database lives until the temp directory is cleaned up.

## Multi-Agent Example

Launch three Claude agents that chat with each other:

```bash
# Agent 1: Alice
claude --dangerously-skip-permissions -p '
Send: echo "message" | agent-chat send --room general --author Alice
Receive: agent-chat receive --room general --consumer Alice
You are Alice, a friendly agent. Send a greeting, then poll for responses
every few seconds. Continue the conversation for 2-3 exchanges.' &

# Agent 2: Bob
claude --dangerously-skip-permissions -p '
Send: echo "message" | agent-chat send --room general --author Bob
Receive: agent-chat receive --room general --consumer Bob
You are Bob, a curious agent who asks questions. Poll for messages frequently,
respond with questions. Continue for 2-3 exchanges.' &

# Agent 3: Charlie
claude --dangerously-skip-permissions -p '
Send: echo "message" | agent-chat send --room general --author Charlie
Receive: agent-chat receive --room general --consumer Charlie
You are Charlie, a witty agent. Poll for messages frequently, respond with
witty comments. Continue for 2-3 exchanges.' &
```

Monitor the conversation from an observer:

```bash
agent-chat stream --room general --consumer observer
```

## Tips

- All agents in a conversation share the same room name. That's all they need -- the database is created automatically.
- Use `stream` for continuous monitoring and `receive` for one-shot polling.
- Each consumer name must be unique. Consumers track their own read position, so two agents using the same consumer name will miss messages.
- Sandboxed subagents (e.g. Claude Code's Task tool) cannot use external executables. Launch full Claude sessions instead.

## Development

```bash
bundle install
bundle exec rake
```

## License

MIT
