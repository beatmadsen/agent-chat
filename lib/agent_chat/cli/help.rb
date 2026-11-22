module AgentChat
  module CLI
    HELP = <<~HELP.freeze
      agent-chat sends and reads messages in shared chat rooms, for programs,
      scripts, agents and people.

      Usage:
        agent-chat <command> [options]

      Commands:
        send      Send a message. The content is read from standard input.
                  Prints the id the new message was given.
        receive   Print the messages this consumer has not seen yet, then exit.
        stream    Like receive, but keeps running and prints new messages as
                  they arrive. Stop it with Ctrl-C.
        show      Print the messages with the given ids, in the order given:
                  agent-chat show --room <name> <id> [<id>...]

      Options:
        --room <name>        Chat room name. Every command needs it.
        --author <name>      Who the message is from (send).
        --consumer <name>    Reader name. Each consumer keeps its own read
                             position (receive, stream).
        --reply-to <id,...>  Ids of the messages this one answers (send).
                             Repeat the flag or separate ids with commas.
        --all                Print the whole history instead of unread
                             messages, without moving any read position
                             (receive, stream).
        --json               Structured output, one JSON object per line.
                             Recommended for scripts and agents.
        -h, --help           Show this help.
        -v, --version        Show the version.

      JSON output (--json)
        Every message is one line, the same for receive, stream and show:
          {"id":"7xKqR2m","author":"Alice","timestamp":"2026-11-22T13:30:00Z",
           "content":"Hello","reply_to":["3fGhJ9k"]}
        receive prints nothing when there is nothing new.
        send prints {"status":"accepted","assigned_id":"7xKqR2m"} and adds
        "room_created":true when the message created the room.
        A refused request prints {"status":"rejected","error":{"code":"...",
        "message":"..."}} on standard output.
        Notes and warnings from receive, stream and show go to standard error
        as {"info":{...}} or {"warning":{...}} lines. For send and for refused
        requests they appear in a "warnings" list instead.

      A misspelt flag or command one edit away from exactly one known name is
      read as that name, with a warning saying so. Anything less certain is
      refused.

      Exit status is 0 on success, 1 when a request is refused (an unknown
      message id, for example) and 2 when the command line cannot be read.

      Examples:
        echo 'Hello!' | agent-chat send --room general --author Alice
        echo 'Agreed' | agent-chat send --json --room general --author Bob --reply-to 7xKqR2m
        agent-chat receive --json --room general --consumer Bob
        agent-chat stream --json --room general --consumer Bob
        agent-chat show --json --room general 7xKqR2m
    HELP
  end
end
