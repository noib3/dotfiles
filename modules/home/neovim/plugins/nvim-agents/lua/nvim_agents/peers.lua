--- Asks the other Neovims running on the machine to run Lua code, over
--- msgpack-RPC on their sockets, each within a timeout so that a Neovim busy
--- or waiting at a prompt holds no one up.
local M = {}

local uv = vim.uv

--- The time a Neovim that didn't answer is skipped for.
local skip_ms = 30000

--- The times until which the Neovims that didn't answer are skipped, by
--- address.
---@type table<string, integer?>
local skipped = {}

--- Returns the addresses of the other Neovims' servers in the runtime
--- directory, where Neovim listens by default. A socket left behind by a
--- Neovim that quit refuses connections right away, so they're kept.
---@return string[]
M.addresses = function()
  local run = vim.fn.stdpath("run") --[[@as string]]
  local own = {}
  for _, address in ipairs(vim.fn.serverlist()) do
    own[address] = true
  end
  local addresses = {}
  for name in vim.fs.dir(run) do
    local address = vim.fs.joinpath(run, name)
    if name:match("^nvim%.%d+%.%d+$") and not own[address] then
      addresses[#addresses + 1] = address
    end
  end
  table.sort(addresses)
  return addresses
end

--- Runs Lua code in a Neovim with arguments, and calls back with its result,
--- or with nothing if it doesn't answer within a timeout.
---@param address string
---@param code string
---@param args any[]
---@param timeout_ms integer
---@param callback fun(ok: boolean, result?: any, timed_out?: boolean)
local ask = function(address, code, args, timeout_ms, callback)
  local finished = false
  local pipe = assert(uv.new_pipe(false))
  local timer = assert(uv.new_timer())
  ---@param ok boolean
  ---@param result? any
  ---@param timed_out? boolean
  local finish = function(ok, result, timed_out)
    if finished then return end
    finished = true
    if not timer:is_closing() then timer:close() end
    if not pipe:is_closing() then pipe:close() end
    callback(ok, result, timed_out)
  end
  timer:start(timeout_ms, 0, function() finish(false, nil, true) end)

  pipe:connect(address, function(connect_err)
    if connect_err then return finish(false) end
    -- A request is [0, its ID, the method, the arguments], and the response
    -- [1, the ID, an error, the result].
    local request = vim.mpack.encode({ 0, 1, "nvim_exec_lua", { code, args } })
    pipe:write(request)
    local unpack = vim.mpack.Unpacker()
    local buffer = ""
    pipe:read_start(function(read_err, data)
      if read_err or not data then return finish(false) end
      buffer = buffer .. data
      local ok, response, position = pcall(unpack, buffer)
      if not ok or response == nil then return end
      buffer = buffer:sub(position or #buffer + 1)
      if type(response) == "table" and response[1] == 1 and response[2] == 1 then
        finish(response[3] == nil or response[3] == vim.NIL, response[4])
      end
    end)
  end)
end

--- Runs Lua code with arguments in each of the Neovims at some addresses at
--- once, and calls back with the results of those that ran it within a
--- timeout, by address. A Neovim that didn't answer in time is skipped for
--- a while.
---@param addresses string[]
---@param code string
---@param args any[]
---@param timeout_ms integer
---@param callback fun(results: table<string, any>)
M.ask_all = function(addresses, code, args, timeout_ms, callback)
  local now = uv.now()
  addresses = vim.tbl_filter(
    function(address) return (skipped[address] or 0) <= now end,
    addresses
  )
  local results, left = {}, #addresses
  if left == 0 then return callback(results) end
  for _, address in ipairs(addresses) do
    ask(address, code, args, timeout_ms, function(ok, result, timed_out)
      if ok then results[address] = result end
      if timed_out then skipped[address] = uv.now() + skip_ms end
      left = left - 1
      if left == 0 then vim.schedule(function() callback(results) end) end
    end)
  end
end

return M
