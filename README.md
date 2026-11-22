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

Requires Ruby >= 3.3.

## CLI Usage

```
agent-chat <command> [options]
```

### Commands

**send** reads the message from stdin and prints the id it was given:

```bash
echo "Hello!" | agent-chat send --room general --author Alice
# 7xKqR2m
```

Answer one or more earlier messages with `--reply-to`:

```bash
echo "Agreed" | agent-chat send --room general --author Bob --reply-to 7xKqR2m,3fGhJ9k
```

**receive** prints the messages this consumer has not seen yet, then exits:

```bash
agent-chat receive --room general --consumer Bob
```

**stream** does the same and keeps printing new messages until Ctrl-C:

```bash
agent-chat stream --room general --consumer Bob
```

**show** prints messages by id, for example the ones a reply answers:

```bash
agent-chat show --room general 7xKqR2m 3fGhJ9k
```

### Options

| Option | Description |
|--------|-------------|
| `--room <name>` | Chat room name (every command) |
| `--author <name>` | Who the message is from (`send`) |
| `--consumer <name>` | Reader name with its own read position (`receive`, `stream`) |
| `--reply-to <id,...>` | Ids this message answers (`send`); repeat or comma-separate |
| `--all` | Whole history instead of unread messages; moves no read position (`receive`, `stream`) |
| `--json` | Structured output, one JSON object per line |
| `-h, --help` | Show help |
| `-v, --version` | Show the version |

A misspelt flag or command one edit away from exactly one known name is read as that name, with a warning. Anything less certain is refused.

### Text output

```
<<< Alice | 2026-11-22 14:30:00 | 7xKqR2m >>>
Shall we ship?



<<< Bob | 2026-11-22 14:31:12 | 3fGhJ9k | re: 7xKqR2m >>>
Yes
```

Times are local. Notes, warnings and errors go to stderr.

### JSON output

With `--json`, `receive`, `stream` and `show` print one line per message:

```json
{"id":"3fGhJ9k","author":"Bob","timestamp":"2026-11-22T13:31:12Z","content":"Yes","reply_to":["7xKqR2m"]}
```

`receive` prints nothing when there is nothing new. `send` prints only what the sender does not already know:

```json
{"status":"accepted","assigned_id":"3fGhJ9k"}
```

It adds `"room_created":true` when the message created the room. A refused request prints an error object on stdout:

```json
{"status":"rejected","error":{"code":"unknown_reply_to","message":"No message with id zzzzzzz in room general","ids":["zzzzzzz"]}}
```

Notes and warnings from `receive`, `stream` and `show` go to stderr as `{"info":{...}}` or `{"warning":{...}}` lines, so stdout stays a clean stream of messages. For `send` and for refused requests they appear in a `"warnings"` list.

Exit status is 0 on success, 1 when a request is refused and 2 when the command line cannot be read.

## Web UI

Launch the web interface:

```bash
agent-chat-web
```

This starts a Sinatra server on `http://localhost:4567` and opens it in your browser. Each message shows its id and links to the messages it answers; click a link to jump to that message. Reply collects one or more messages to answer with your next post. Add `?consumer=<name>` to the address to read and post under a name.

### API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/rooms` | List all rooms |
| GET | `/api/rooms/:room/messages` | All messages in a room; with `?consumer=NAME` also marks them read |
| GET | `/api/rooms/:room/messages/new?consumer=NAME` | Messages the consumer has not read |
| POST | `/api/rooms/:room/messages` | Send a message: `application/json` body with `author`, `content` and optional `reply_to` |

Messages have the same fields as the CLI's JSON lines. A POST answers 201 with `{"status":"accepted","assigned_id":...}`. Problems come back as the same error object as the CLI, with status 400, 415 for a body that is not JSON, or 422 for an unknown message id.

## How It Works

Each room is a SQLite database in your system's temp directory:

```
$TMPDIR/agent-chat/rooms/<room-name>/room.db
```

- **Rooms** are independent chat channels, each with its own database file. Reading or sending to a room that does not exist creates it, and the command says so.
- **Consumers** track read positions independently. `receive` only returns messages the consumer has not seen before.
- **No server required** for CLI usage. Several processes can read and write the same room at once.
- Messages persist across restarts until the temp directory is cleaned up.
- A room created by a different version of agent-chat is moved to `$TMPDIR/agent-chat/backups/<UTC time>/<room>/` and started over, with a warning that names the backup.

## Multi-Agent Example

Launch three Claude agents that chat with each other:

```bash
USAGE='Send: echo "message" | agent-chat send --json --room general --author NAME [--reply-to ID,...]
Receive: agent-chat receive --json --room general --consumer NAME
Look up a message you were answered about: agent-chat show --json --room general ID'

claude --dangerously-skip-permissions -p "$USAGE
You are Alice, a friendly agent. Send a greeting, then poll for responses
every few seconds and reply to specific messages. Continue for 2-3 exchanges." &

claude --dangerously-skip-permissions -p "$USAGE
You are Bob, a curious agent who asks questions. Poll for messages frequently
and reply to the messages you are answering. Continue for 2-3 exchanges." &

claude --dangerously-skip-permissions -p "$USAGE
You are Charlie, a witty agent. Poll for messages frequently and reply with
witty comments. Continue for 2-3 exchanges." &
```

Watch the conversation:

```bash
agent-chat stream --room general --all
```

## Tips

- All participants share the same room name. That is all they need.
- Use `--json` from scripts and agents. Text output is for people.
- Use `stream` for continuous monitoring and `receive` for one-shot polling.
- Each consumer name must be unique. Two readers sharing a consumer name split the messages between them.
- Sandboxed subagents (e.g. Claude Code's Task tool) cannot use external executables. Launch full Claude sessions instead.

## Development

The frontend tests need Node.js.

```bash
bundle install
npm install
bundle exec rake
```

## License

MIT
