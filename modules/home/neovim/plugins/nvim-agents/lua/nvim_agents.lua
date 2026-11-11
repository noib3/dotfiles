local acp = require("nvim_agents.acp")
local registry = require("nvim_agents.registry")

local M = {}

---@class nvim_agents.AgentConfig
---@field cmd string[] The command starting the agent's ACP adapter.
---@field env? table<string, string>

---@class nvim_agents.Config
---@field agents table<string, nvim_agents.AgentConfig?>
---@field state_dir string
---@field max_age integer The age in seconds past which a session isn't matched anymore.

---@type nvim_agents.Config
local config = {
  agents = {},
  state_dir = vim.fs.joinpath(
    vim.fn.stdpath("state") --[[@as string]],
    "nvim-agents"
  ),
  max_age = 30 * 24 * 60 * 60,
}

--- The kinds of tool calls whose permission requests are allowed.
local allowed_kinds = { read = true, search = true, fetch = true, think = true }

---@class nvim_agents.Edit
---@field path string The edited file's absolute path.
---@field old_text string The text replaced.
---@field new_text string

---@class nvim_agents.Result
---@field text string The reply's text.
---@field edits nvim_agents.Edit[] The edits the agent made but didn't apply.
---@field stop_reason string

---@class nvim_agents.Handlers
---@field chunk? fun(text: string)
---@field done fun(result: nvim_agents.Result)
---@field error fun(message: string)

---@class nvim_agents.ToolCall
---@field kind? string
---@field status? string
---@field content? table[]
---@field raw_input? table

---@class nvim_agents.Turn
---@field text string
---@field handlers nvim_agents.Handlers
---@field tool_calls table<string, nvim_agents.ToolCall?>
---@field order string[] The tool calls' IDs, in the order they started.
---@field separate boolean Whether the next text starts a new paragraph.
---@field cancelled boolean

---@class nvim_agents.Client
---@field connection nvim_agents.acp.Connection
---@field ready boolean
---@field waiting fun(err?: string)[] The callbacks waiting for the initialization.
---@field conversations table<string, nvim_agents.Conversation?> The open conversations, by session ID.

--- The clients of the agents started so far, by agent.
---@type table<string, nvim_agents.Client?>
local clients = {}

---@class nvim_agents.Conversation
---@field agent string
---@field cwd string
---@field id? string The session ID, once the agent has it.
---@field private state "opening"|"open"|"closed"
---@field private open_session fun(client: nvim_agents.Client, callback: fun(err?: string))
---@field private queue { text: string, handlers: nvim_agents.Handlers, cancelled: boolean }[]
---@field private turn? nvim_agents.Turn
local Conversation = {}
Conversation.__index = Conversation

---@param err nvim_agents.acp.Error|string
---@return string
local message_of = function(err)
  if type(err) == "string" then return err end
  local message = err.message or "unknown error"
  if type(err.data) == "string" then
    message = message .. ": " .. err.data
  elseif type(err.data) == "table" and type(err.data.details) == "string" then
    message = message .. ": " .. err.data.details
  end
  return message
end

---@param path string
---@return string?
local read_file = function(path)
  local file = io.open(path, "rb")
  if not file then return end
  local text = file:read("*a")
  file:close()
  return text
end

--- Returns the edits of a tool call: its diffs, or else its raw input's text
--- replacement.
---@param call nvim_agents.ToolCall
---@return nvim_agents.Edit[]
local edits_of = function(call)
  local edits = {}
  for _, item in ipairs(call.content or {}) do
    if item.type == "diff" and type(item.path) == "string" then
      local old_text = item.oldText or read_file(item.path)
      if old_text and type(item.newText) == "string" then
        edits[#edits + 1] = {
          path = item.path,
          old_text = old_text,
          new_text = item.newText,
        }
      end
    end
  end
  local input = call.raw_input or {}
  local path = input.path or input.file_path
  local old_text = input.old_text or input.old_string
  local new_text = input.new_text or input.new_string
  if
    #edits == 0
    and type(path) == "string"
    and type(old_text) == "string"
    and type(new_text) == "string"
  then
    edits[1] = { path = path, old_text = old_text, new_text = new_text }
  end
  return edits
end

--- Returns the edits of a turn's tool calls that weren't applied.
---@param turn nvim_agents.Turn
---@return nvim_agents.Edit[]
local unapplied_edits = function(turn)
  local edits = {}
  for _, id in ipairs(turn.order) do
    local call = assert(turn.tool_calls[id])
    if call.kind == "edit" and call.status ~= "completed" then
      vim.list_extend(edits, edits_of(call))
    end
  end
  return edits
end

---@param turn nvim_agents.Turn
---@param id string
---@param fields table
local update_tool_call = function(turn, id, fields)
  local call = turn.tool_calls[id]
  if not call then
    call = {}
    turn.tool_calls[id] = call
    turn.order[#turn.order + 1] = id
    if turn.text ~= "" then turn.separate = true end
  end
  call.kind = fields.kind or call.kind
  call.status = fields.status or call.status
  call.content = fields.content or call.content
  call.raw_input = fields.rawInput or call.raw_input
end

---@param update table
function Conversation:update(update)
  local turn = self.turn
  if not turn or turn.cancelled then return end
  local kind = update.sessionUpdate
  if kind == "agent_message_chunk" then
    local content = update.content or {}
    if content.type ~= "text" or type(content.text) ~= "string" then return end
    local text = content.text
    if turn.separate and text ~= "" then
      text = "\n\n" .. text:gsub("^%s+", "")
      turn.separate = false
    end
    turn.text = turn.text .. text
    if turn.handlers.chunk then turn.handlers.chunk(text) end
  elseif kind == "tool_call" or kind == "tool_call_update" then
    if type(update.toolCallId) == "string" then
      update_tool_call(turn, update.toolCallId, update)
    end
  end
end

--- Answers a permission request: reads and searches are allowed, everything
--- else rejected.
---@param params table
---@param respond fun(result?: any, err?: nvim_agents.acp.Error)
function Conversation:request_permission(params, respond)
  local call = params.toolCall or {}
  if self.turn and type(call.toolCallId) == "string" then
    update_tool_call(self.turn, call.toolCallId, call)
  end
  local recorded = self.turn and self.turn.tool_calls[call.toolCallId]
  local kind = call.kind or (recorded and recorded.kind)
  local wanted = allowed_kinds[kind] and "allow_once" or "reject_once"
  for _, option in ipairs(params.options or {}) do
    if option.kind == wanted then
      return respond({
        outcome = { outcome = "selected", optionId = option.optionId },
      })
    end
  end
  respond({ outcome = { outcome = "cancelled" } })
end

---@param agent string
---@param client nvim_agents.Client
---@param method string
---@param params table
---@param respond fun(result?: any, err?: nvim_agents.acp.Error)
local handle_request = function(agent, client, method, params, respond)
  local conversation = client.conversations[params.sessionId]
  if method == "session/request_permission" and conversation then
    return conversation:request_permission(params, respond)
  end
  respond(nil, {
    code = -32601,
    message = ("%s isn't supported by nvim-agents' client of %s"):format(
      method,
      agent
    ),
  })
end

--- Calls back once the agent's client is initialized, starting it if it
--- isn't running.
---@param agent string
---@param callback fun(err?: string, client?: nvim_agents.Client)
local with_client = function(agent, callback)
  local existing = clients[agent]
  if existing and not existing.connection.closed then
    if existing.ready then return callback(nil, existing) end
    existing.waiting[#existing.waiting + 1] = function(err)
      callback(err, not err and existing or nil)
    end
    return
  end

  local agent_config = config.agents[agent]
  if not agent_config then
    return callback(("No agent named %s"):format(agent))
  end

  ---@type nvim_agents.Client
  local client
  client = {
    ready = false,
    waiting = {
      function(err) callback(err, not err and client or nil) end,
    },
    conversations = {},
    connection = acp.connect(agent_config.cmd, {
      env = vim.tbl_extend(
        "force",
        agent_config.env or {},
        { NVIM_AGENTS_SUGGEST = "1" }
      ),
    }, {
      notification = function(method, params)
        local conversation = client.conversations[params.sessionId]
        if method == "session/update" and conversation then
          conversation:update(params.update or {})
        end
      end,
      request = function(method, params, respond)
        handle_request(agent, client, method, params, respond)
      end,
      exit = function(reason)
        if clients[agent] == client then clients[agent] = nil end
        local waiting = client.waiting
        client.waiting = {}
        for _, wait in ipairs(waiting) do
          wait(reason)
        end
        for _, conversation in pairs(client.conversations) do
          conversation:fail(reason)
        end
        client.conversations = {}
      end,
    }),
  }
  clients[agent] = client

  client.connection:request("initialize", {
    protocolVersion = acp.protocol_version,
    clientCapabilities = {
      fs = { readTextFile = false, writeTextFile = false },
      terminal = false,
    },
    clientInfo = { name = "nvim-agents", version = "0.1.0" },
  }, function(err)
    local waiting = client.waiting
    client.waiting = {}
    client.ready = not err
    if err then client.connection:close(message_of(err)) end
    for _, wait in ipairs(waiting) do
      wait(err and message_of(err) or nil)
    end
  end)
end

---@param agent string
---@param cwd string
---@param open_session fun(client: nvim_agents.Client, callback: fun(err?: string))
---@return nvim_agents.Conversation
local new_conversation = function(agent, cwd, open_session)
  return setmetatable({
    agent = agent,
    cwd = cwd,
    state = "closed",
    open_session = open_session,
    queue = {},
  }, Conversation)
end

--- Opens the conversation's session, then sends the prompts queued so far.
---@private
function Conversation:open()
  self.state = "opening"
  with_client(self.agent, function(err, client)
    if err or not client then return self:fail(err or "no client") end
    self.open_session(client, function(open_err)
      if open_err then return self:fail(open_err) end
      client.conversations[assert(self.id)] = self
      self.state = "open"
      self:next()
    end)
  end)
end

--- Fails the turn in progress and the queued prompts.
---@param reason string
function Conversation:fail(reason)
  self.state = "closed"
  local turn, queue = self.turn, self.queue
  self.turn, self.queue = nil, {}
  if turn and not turn.cancelled then turn.handlers.error(reason) end
  for _, queued in ipairs(queue) do
    if not queued.cancelled then queued.handlers.error(reason) end
  end
end

--- Closes the conversation's session in the agent, which stops the process
--- running it there until the next prompt resumes it.
---@private
function Conversation:close()
  self.state = "closed"
  local client = clients[self.agent]
  if not client or not self.id then return end
  client.conversations[self.id] = nil
  client.connection:request(
    "session/close",
    { sessionId = self.id },
    function() end
  )
end

--- Sends the next queued prompt, if no turn is in progress, or else closes
--- the session.
---@private
function Conversation:next()
  if self.turn or self.state ~= "open" then return end
  local queued = table.remove(self.queue, 1)
  while queued and queued.cancelled do
    queued = table.remove(self.queue, 1)
  end
  if not queued then return self:close() end

  ---@type nvim_agents.Turn
  local turn = {
    text = "",
    handlers = queued.handlers,
    tool_calls = {},
    order = {},
    separate = false,
    cancelled = false,
  }
  self.turn = turn
  local client = assert(clients[self.agent])
  client.connection:request("session/prompt", {
    sessionId = self.id,
    prompt = { { type = "text", text = queued.text } },
  }, function(err, result)
    if self.turn ~= turn then return end
    self.turn = nil
    if not turn.cancelled then
      if err then
        turn.handlers.error(message_of(err))
      else
        turn.handlers.done({
          text = turn.text,
          edits = unapplied_edits(turn),
          stop_reason = (result or {}).stopReason or "end_turn",
        })
      end
    end
    self:next()
  end)
end

--- Sends a prompt once the turns before it are done, and returns a function
--- cancelling it.
---@param text string
---@param handlers nvim_agents.Handlers
---@return fun() cancel
function Conversation:prompt(text, handlers)
  local queued = { text = text, handlers = handlers, cancelled = false }
  self.queue[#self.queue + 1] = queued
  if self.state == "closed" then
    self:open()
  else
    self:next()
  end
  return function()
    queued.cancelled = true
    local turn = self.turn
    if turn and turn.handlers == handlers and not turn.cancelled then
      turn.cancelled = true
      local client = clients[self.agent]
      if client then
        client.connection:notify("session/cancel", { sessionId = self.id })
      end
    end
  end
end

--- Returns the sessions matching the paths, best first.
---@param opts { paths: string[], agent?: string }
---@return nvim_agents.Match[]
M.sessions = function(opts)
  local dir = vim.fs.joinpath(config.state_dir, "sessions")
  local sessions = vim.tbl_filter(
    function(session) return not opts.agent or session.agent == opts.agent end,
    registry.load(dir, config.max_age)
  )
  local paths = vim.tbl_map(registry.canonical, opts.paths)
  return registry.rank(sessions, paths)
end

--- Returns a conversation in a fork of a session, which is created when it's
--- first prompted.
---@param session { agent: string, id: string, cwd: string }
---@return nvim_agents.Conversation
M.fork = function(session)
  ---@type nvim_agents.Conversation
  local conversation
  conversation = new_conversation(
    session.agent,
    session.cwd,
    function(client, callback)
      local resume = function()
        client.connection:request("session/resume", {
          sessionId = conversation.id,
          cwd = conversation.cwd,
          mcpServers = {},
        }, function(err) callback(err and message_of(err) or nil) end)
      end
      if conversation.id then return resume() end
      -- A fork is a copy of the session that isn't open yet, which the
      -- conversation resumes like on its later turns.
      client.connection:request("session/fork", {
        sessionId = session.id,
        cwd = session.cwd,
        mcpServers = {},
      }, function(err, result)
        if err then return callback(message_of(err)) end
        conversation.id = result.sessionId
        resume()
      end)
    end
  )
  return conversation
end

--- Returns a conversation in a new session, which is created when it's first
--- prompted.
---@param agent string
---@param cwd string
---@return nvim_agents.Conversation
M.start = function(agent, cwd)
  ---@type nvim_agents.Conversation
  local conversation
  conversation = new_conversation(agent, cwd, function(client, callback)
    if conversation.id then
      return client.connection:request("session/resume", {
        sessionId = conversation.id,
        cwd = cwd,
        mcpServers = {},
      }, function(err) callback(err and message_of(err) or nil) end)
    end
    client.connection:request("session/new", {
      cwd = cwd,
      mcpServers = {},
    }, function(err, result)
      if err then return callback(message_of(err)) end
      conversation.id = result.sessionId
      callback()
    end)
  end)
  return conversation
end

--- Returns a conversation in an existing session, which is resumed when it's
--- first prompted.
---@param agent string
---@param id string
---@param cwd string
---@return nvim_agents.Conversation
M.resume = function(agent, id, cwd)
  local conversation = M.start(agent, cwd)
  conversation.id = id
  return conversation
end

--- Writes a text to a session's inbox, as a file of its own, and returns
--- the error if it can't.
---@param session { agent: string, id: string }
---@param text string
---@return string? err
M.queue = function(session, text)
  local dir =
    vim.fs.joinpath(config.state_dir, "inbox", session.agent, session.id)
  vim.fn.mkdir(dir, "p")
  local name = ("%d-%019d.md"):format(os.time(), vim.uv.hrtime())
  -- The text appears in the inbox once it's whole.
  local partial = vim.fs.joinpath(dir, "." .. name)
  local file, open_err = io.open(partial, "w")
  if not file then return open_err end
  file:write(text)
  file:close()
  local ok, rename_err = vim.uv.fs_rename(partial, vim.fs.joinpath(dir, name))
  if not ok then return rename_err end
end

--- Stops the agents' adapters.
M.stop = function()
  for _, client in pairs(clients) do
    client.connection:close("stopped")
  end
end

---@param opts? { agents?: table<string, nvim_agents.AgentConfig>, state_dir?: string, max_age?: integer }
M.setup = function(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("nvim-agents", { clear = true }),
    desc = "Stops the agents' adapters",
    callback = M.stop,
  })
end

return M
