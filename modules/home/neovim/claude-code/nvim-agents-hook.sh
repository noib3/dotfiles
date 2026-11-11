input=$(cat)
event=$(jq -r .hook_event_name <<<"$input")
tool=$(jq -r '.tool_name // ""' <<<"$input")
session=$(jq -r .session_id <<<"$input")
state="${XDG_STATE_HOME:-$HOME/.local/state}/nvim/nvim-agents"

# Appends an event to the session's file of the registry.
record() {
  local dir="$state/sessions/claude"
  mkdir -p "$dir"
  printf '%s\n' "$1" >>"$dir/$session.jsonl"
}

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
}

# The session's title, which Claude Code writes to its transcript after its
# first prompts, is recorded whenever it changes.
case "$event" in
Stop | UserPromptSubmit | SessionEnd)
  transcript=$(jq -r '.transcript_path // ""' <<<"$input")
  if [ -z "${NVIM_AGENTS_SUGGEST:-}" ] && [ -f "$transcript" ]; then
    title=$(grep -a '"type":"ai-title"' "$transcript" | tail -1 | jq -r '.aiTitle // empty' || true)
    last=$(grep -a '"event":"title"' "$state/sessions/claude/$session.jsonl" 2>/dev/null |
      tail -1 | jq -r '.title // empty' || true)
    if [ -n "$title" ] && [ "$title" != "$last" ]; then
      record "$(jq -cn --arg title "$title" '{ event: "title", title: $title, time: (now | floor) }')"
    fi
  fi
  ;;
esac

# Prints whether a file has unsaved changes, `modified`, or is loaded,
# `loaded`, in the Neovim the nvim MCP server's tool calls on it run in.
file_state() {
  @state@ "$1" 2>/dev/null || true
}

if [ "$event" = PreToolUse ] && [ "$tool" = Read ]; then
  path=$(jq -r '.tool_input.file_path // ""' <<<"$input")
  [ -n "$path" ] || exit 0
  if [ "$(file_state "$path")" = modified ]; then
    deny "The file has unsaved changes in the user's Neovim, so it differs from the file on disk. Read it with the read tool of the nvim MCP server, which sees them."
  fi
  exit 0
fi

if [ "$event" = UserPromptSubmit ]; then
  texts=()
  for file in "$state/inbox/claude/$session"/*.md; do
    [ -e "$file" ] || continue
    texts+=("$(cat "$file")")
    rm -f "$file"
  done
  [ ${#texts[@]} -gt 0 ] || exit 0
  printf '%s\n\n' "${texts[@]}" | jq -Rs '{
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: rtrimstr("\n\n")
    }
  }'
  exit 0
fi

if [ -n "${NVIM_AGENTS_SUGGEST:-}" ]; then
  if [ "$event" = PreToolUse ]; then
    deny "This session only suggests edits: the edit was recorded as a suggestion for the user to review, and wasn't applied. Don't retry it."
  fi
  exit 0
fi

if [ "$event" = PreToolUse ]; then
  if [ "$tool" = Edit ] || [ "$tool" = MultiEdit ]; then
    path=$(jq -r '.tool_input.file_path // ""' <<<"$input")
    if [ -n "${NVIM:-}" ] || [ -n "$(file_state "$path")" ]; then
      deny "The user edits this file in Neovim: edit it with the edit tool of the nvim MCP server instead, which keeps the user's unsaved changes."
    fi
  fi
  exit 0
fi

line=$(jq -c --arg nvim "${NVIM:-}" '
  (.tool_input.file_path // .tool_input.notebook_path // .tool_input.path) as $path
  | if .hook_event_name == "SessionStart" then
      { event: "start", cwd: .cwd } + (if $nvim != "" then { nvim: $nvim } else {} end)
    elif .hook_event_name == "SessionEnd" then
      { event: "end" }
    elif .hook_event_name == "PostToolUse" and ($path | type) == "string" then
      {
        event: (if .tool_name == "Read" or (.tool_name | test("__read$")) then "read" else "edit" end),
        path: (if ($path | startswith("/")) then $path else .cwd + "/" + $path end)
      }
    else empty end
  | . + { time: (now | floor) }
' <<<"$input")
[ -n "$line" ] || exit 0
record "$line"
