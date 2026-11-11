-- The process of the MCP server, run with `nvim --clean -l`. It speaks MCP,
-- JSON-RPC messages one per line, on its stdin and stdout, and runs each tool
-- call with `nvim_agents.mcp` in the Neovim `nvim_agents.mcp.route` finds for
-- the call's file. Without a Neovim to connect to, it lists no tools.

local uv = vim.uv

-- The modules are next to this script.
local source = assert(debug.getinfo(1, "S")).source:sub(2)
local lua_dir = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(source)))
package.path = ("%s/?.lua;%s/?/init.lua;%s"):format(lua_dir, lua_dir, package.path)

local route = require("nvim_agents.mcp.route")

--- The MCP version answered to a client that doesn't ask for one.
local default_protocol_version = "2025-06-18"

--- The RPC channels to the Neovims connected to, and this process's channel
--- ID in each, by address.
---@type table<string, { channel: integer, id: integer }?>
local hosts = {}

--- The tool calls waiting for their result, by the ID they're sent with.
---@type table<integer, any>
local pending = {}

local next_call = 0

local done = false

---@param message table
local write = function(message)
  message.jsonrpc = "2.0"
  io.stdout:write(vim.json.encode(message), "\n")
  io.stdout:flush()
end

--- Returns the connection to the Neovim at an address, connecting to it
--- the first time.
---@param address string
---@return { channel: integer, id: integer }?
local connect = function(address)
  local host = hosts[address]
  if host then return host end
  local mode = address:match("^[%w.-]*:%d+$") and "tcp" or "pipe"
  local ok, channel = pcall(
    function() return vim.fn.sockconnect(mode, address, { rpc = true }) end
  )
  if not ok or channel == 0 then return end
  ---@cast channel integer
  local info_ok, info = pcall(
    function() return vim.rpcrequest(channel, "nvim_get_api_info") end
  )
  if not info_ok or type(info) ~= "table" then return end
  host = { channel = channel, id = info[1] }
  hosts[address] = host
  return host
end

--- Delivers the result of a tool call, which the Neovim at `$NVIM` calls on
--- this process.
---@param call integer
---@param result { text: string, is_error?: boolean }
_G.nvim_agents_mcp_deliver = function(call, result)
  local id = pending[call]
  pending[call] = nil
  if id == nil then return end
  write({
    id = id,
    result = {
      content = { { type = "text", text = result.text } },
      isError = result.is_error == true,
    },
  })
end

---@param id any
---@param text string
local tool_error = function(id, text)
  write({
    id = id,
    result = { content = { { type = "text", text = text } }, isError = true },
  })
end

---@param message table
local handle = function(message)
  local id, method, params = message.id, message.method, message.params or {}
  if id == nil or not method then return end
  if method == "initialize" then
    route.list(function(listed)
      write({
        id = id,
        result = {
          protocolVersion = params.protocolVersion or default_protocol_version,
          capabilities = { tools = vim.empty_dict() },
          serverInfo = { name = "nvim", version = "0.1.0" },
          instructions = listed and listed.instructions or nil,
        },
      })
    end)
  elseif method == "ping" then
    write({ id = id, result = vim.empty_dict() })
  elseif method == "tools/list" then
    route.list(function(listed)
      write({ id = id, result = { tools = listed and listed.tools or {} } })
    end)
  elseif method == "tools/call" then
    local args = params.arguments or vim.empty_dict()
    local path = type(args.path) == "string" and args.path or ""
    if path ~= "" and not vim.startswith(path, "/") then
      path = vim.fs.joinpath(assert(uv.cwd()), path)
    end
    route.find(vim.fs.normalize(path), function(address)
      local host = address and connect(address)
      if not host then return tool_error(id, "No Neovim is running") end
      next_call = next_call + 1
      pending[next_call] = id
      local ok, err = pcall(function()
        return vim.rpcrequest(
          host.channel,
          "nvim_exec_lua",
          "return require('nvim_agents.mcp').call(...)",
          { host.id, next_call, params.name, args, uv.cwd() }
        )
      end)
      if not ok then
        pending[next_call] = nil
        -- The next call connects again.
        hosts[assert(address)] = nil
        tool_error(id, tostring(err))
      end
    end)
  else
    write({
      id = id,
      error = { code = -32601, message = "Method not found: " .. method },
    })
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
      local ok, message = pcall(
        vim.json.decode,
        line,
        { luanil = { object = true, array = true } }
      )
      if ok and type(message) == "table" then handle(message) end
    end
    partial = text:sub(last)
  end)
end)

while not done do
  vim.wait(60000, function() return done end)
end
