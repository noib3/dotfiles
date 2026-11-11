--- A connection to an agent over ACP, the Agent Client Protocol: JSON-RPC
--- messages, one per line, on the agent's stdin and stdout.

local M = {}

--- The version of ACP that the client speaks.
M.protocol_version = 1

---@class nvim_agents.acp.Error
---@field code integer
---@field message string
---@field data? any

---@class nvim_agents.acp.Handlers
--- Handles a notification from the agent.
---@field notification fun(method: string, params: table)
--- Handles a request from the agent, which `respond` answers.
---@field request fun(method: string, params: table, respond: fun(result?: any, err?: nvim_agents.acp.Error))
--- Handles the agent's exit, with the reason.
---@field exit fun(reason: string)

---@class nvim_agents.acp.Connection
---@field process vim.SystemObj
---@field handlers nvim_agents.acp.Handlers
---@field next_id integer
---@field pending table<integer, fun(err?: nvim_agents.acp.Error, result?: any)?>
---@field partial string The output read after its last newline.
---@field stderr string[] The agent's last lines on stderr.
---@field closed? string The reason the connection closed, once it has.
local Connection = {}
Connection.__index = Connection

--- The number of lines of the agent's stderr kept to explain its exit.
local stderr_lines = 20

---@param text string
---@return table?
local decode = function(text)
  local ok, message =
    pcall(vim.json.decode, text, { luanil = { object = true, array = true } })
  if ok and type(message) == "table" then return message end
end

--- Starts an agent and connects to it.
---@param cmd string[]
---@param opts { env?: table<string, string>, cwd?: string }
---@param handlers nvim_agents.acp.Handlers
---@return nvim_agents.acp.Connection
M.connect = function(cmd, opts, handlers)
  local self = setmetatable({
    handlers = handlers,
    next_id = 0,
    pending = {},
    partial = "",
    stderr = {},
  }, Connection)

  local ok, process = pcall(vim.system, cmd, {
    stdin = true,
    text = true,
    env = opts.env,
    cwd = opts.cwd,
    stdout = function(_, data)
      if data then vim.schedule(function() self:read(data) end) end
    end,
    stderr = function(_, data)
      if not data then return end
      vim.schedule(function()
        for line in data:gmatch("[^\n]+") do
          table.insert(self.stderr, line)
          if #self.stderr > stderr_lines then table.remove(self.stderr, 1) end
        end
      end)
    end,
  }, function(result)
    vim.schedule(function()
      local reason = ("%s exited with code %d"):format(cmd[1], result.code)
      if #self.stderr > 0 then
        reason = reason .. ":\n" .. table.concat(self.stderr, "\n")
      end
      self:close(reason)
    end)
  end)
  if not ok then
    self.closed = tostring(process)
    vim.schedule(function() handlers.exit(self.closed) end)
    return self
  end
  self.process = process
  return self
end

---@private
---@param message table
function Connection:send(message)
  if self.closed then return end
  message.jsonrpc = "2.0"
  self.process:write(vim.json.encode(message) .. "\n")
end

---@param data string
function Connection:read(data)
  local text = self.partial .. data
  local last = 1
  for line, next_start in text:gmatch("([^\n]*)\n()") do
    last = next_start --[[@as integer]]
    local message = line ~= "" and decode(line)
    if message then self:dispatch(message) end
  end
  self.partial = text:sub(last)
end

---@private
---@param message table
function Connection:dispatch(message)
  if message.method and message.id ~= nil then
    local id = message.id
    self.handlers.request(
      message.method,
      message.params or {},
      function(result, err)
        if err then
          self:send({ id = id, error = err })
        else
          self:send({ id = id, result = result == nil and vim.NIL or result })
        end
      end
    )
  elseif message.method then
    self.handlers.notification(message.method, message.params or {})
  elseif message.id ~= nil then
    local callback = self.pending[message.id]
    self.pending[message.id] = nil
    if callback then callback(message.error, message.result) end
  end
end

--- Sends a request, whose response `callback` gets.
---@param method string
---@param params table
---@param callback fun(err?: nvim_agents.acp.Error, result?: any)
function Connection:request(method, params, callback)
  if self.closed then
    return callback({ code = -32000, message = self.closed })
  end
  self.next_id = self.next_id + 1
  self.pending[self.next_id] = callback
  self:send({ id = self.next_id, method = method, params = params })
end

---@param method string
---@param params table
function Connection:notify(method, params)
  self:send({ method = method, params = params })
end

--- Closes the connection, failing the requests waiting for a response, and
--- stops the agent.
---@param reason string
function Connection:close(reason)
  if self.closed then return end
  self.closed = reason
  local pending = self.pending
  self.pending = {}
  for _, callback in pairs(pending) do
    callback({ code = -32000, message = reason })
  end
  if self.process and not self.process:is_closing() then
    pcall(self.process.kill, self.process, "sigterm")
  end
  self.handlers.exit(reason)
end

return M
