-- A fake ACP agent, run with `nvim --clean -l fake_agent.lua <log>`. It logs
-- every request and notification it gets to `<log>`, one JSON object per
-- line, and replies to a prompt according to its text:
-- - `edit`: an edit asking for permission, then a reply saying whether it was
--   allowed;
-- - `read`: the same with a read;
-- - `slow`: a chunk, then nothing until it's cancelled;
-- - `crash`: an exit with an error;
-- - anything else: a chunk, a completed read, then another chunk.

local uv = vim.uv

local log_path = assert(arg[1], "the log's path is missing")

local done = false
local next_session, next_request = 0, 0

--- The callbacks of the requests sent to the client, by ID.
---@type table<integer, fun(result: any)?>
local pending = {}

--- The prompt requests waiting for a cancellation, by session ID.
---@type table<string, any>
local cancellable = {}

---@param message table
local write = function(message)
  message.jsonrpc = "2.0"
  io.stdout:write(vim.json.encode(message), "\n")
  io.stdout:flush()
end

---@param message table
local log = function(message)
  local file = assert(io.open(log_path, "ab"))
  file:write(
    vim.json.encode({ method = message.method, params = message.params or {} }),
    "\n"
  )
  file:close()
end

---@param session string
---@param update table
local update = function(session, update)
  write({
    method = "session/update",
    params = { sessionId = session, update = update },
  })
end

---@param session string
---@param text string
local chunk = function(session, text)
  update(session, {
    sessionUpdate = "agent_message_chunk",
    content = { type = "text", text = text },
  })
end

---@param method string
---@param params table
---@param callback fun(result: any)
local request = function(method, params, callback)
  next_request = next_request + 1
  pending[next_request] = callback
  write({ id = next_request, method = method, params = params })
end

--- Asks for the permission of a tool call, then reports whether it ran.
---@param session string
---@param id any The prompt request's ID.
---@param call table
local ask = function(session, id, call)
  update(
    session,
    vim.tbl_extend("force", call, { sessionUpdate = "tool_call" })
  )
  request("session/request_permission", {
    sessionId = session,
    toolCall = { toolCallId = call.toolCallId },
    options = {
      { optionId = "yes", name = "Allow", kind = "allow_once" },
      { optionId = "no", name = "Reject", kind = "reject_once" },
    },
  }, function(result)
    local allowed = result.outcome.optionId == "yes"
    update(session, {
      sessionUpdate = "tool_call_update",
      toolCallId = call.toolCallId,
      status = allowed and "completed" or "failed",
    })
    chunk(session, allowed and "allowed" or "rejected")
    write({ id = id, result = { stopReason = "end_turn" } })
  end)
end

---@param id any
---@param session string
---@param text string
local prompt = function(id, session, text)
  if text == "edit" then
    ask(session, id, {
      toolCallId = "edit-1",
      title = "Edit a.txt",
      kind = "edit",
      status = "pending",
      content = {
        {
          type = "diff",
          path = "/repo/a.txt",
          oldText = "old",
          newText = "new",
        },
      },
    })
  elseif text == "read" then
    ask(session, id, {
      toolCallId = "read-1",
      title = "Read a.txt",
      kind = "read",
      status = "pending",
    })
  elseif text == "slow" then
    chunk(session, "thinking")
    cancellable[session] = id
  elseif text == "crash" then
    io.stderr:write("crashed on purpose\n")
    os.exit(3)
  else
    chunk(session, "Hello")
    chunk(session, " world.")
    update(session, {
      sessionUpdate = "tool_call",
      toolCallId = "read-1",
      title = "Read a.txt",
      kind = "read",
      status = "completed",
    })
    chunk(session, " Bye.")
    write({ id = id, result = { stopReason = "end_turn" } })
  end
end

--- The sessions open in the agent.
---@type table<string, true?>
local live = {}

---@param message table
local handle = function(message)
  if message.method == nil then
    local callback = pending[message.id]
    pending[message.id] = nil
    if callback then callback(message.result) end
    return
  end
  log(message)
  local id, method, params = message.id, message.method, message.params or {}
  if method == "initialize" then
    write({ id = id, result = { protocolVersion = 1, agentCapabilities = {} } })
  elseif method == "session/new" or method == "session/fork" then
    next_session = next_session + 1
    local prefix = method == "session/new" and "new" or "fork"
    local session = ("%s-%d"):format(prefix, next_session)
    -- Like claude-agent-acp, a fork copies the session without opening it.
    if method == "session/new" then live[session] = true end
    write({ id = id, result = { sessionId = session } })
  elseif method == "session/resume" then
    live[params.sessionId] = true
    write({ id = id, result = vim.empty_dict() })
  elseif method == "session/close" then
    live[params.sessionId] = nil
    write({ id = id, result = vim.empty_dict() })
  elseif method == "session/prompt" then
    if not live[params.sessionId] then
      return write({
        id = id,
        error = { code = -32603, message = "Session not found" },
      })
    end
    prompt(id, params.sessionId, params.prompt[1].text)
  elseif method == "session/cancel" then
    local waiting = cancellable[params.sessionId]
    cancellable[params.sessionId] = nil
    if waiting then
      write({ id = waiting, result = { stopReason = "cancelled" } })
    end
  elseif id ~= nil then
    write({ id = id, error = { code = -32601, message = "unknown " .. method } })
  end
end

local stdin = assert(uv.new_pipe(false))
stdin:open(0)
local partial = ""
stdin:read_start(function(err, data)
  if err or not data then
    done = true
    return
  end
  vim.schedule(function()
    local text = partial .. data
    local last = 1
    for line, next_start in text:gmatch("([^\n]*)\n()") do
      last = next_start --[[@as integer]]
      if line ~= "" then handle(vim.json.decode(line)) end
    end
    partial = text:sub(last)
  end)
end)

while not done do
  vim.wait(60000, function() return done end)
end
