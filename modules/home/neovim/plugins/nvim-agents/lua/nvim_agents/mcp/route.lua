--- Finds the Neovim the MCP server's tool calls on a file run in, among the
--- ones running on the machine: the one with unsaved changes to the file,
--- or else one with the file loaded, or else the one at `$NVIM`, or else the
--- one whose directory is the closest one containing the file. Ties go to
--- the one at `$NVIM`, and then to the first address.
local peers = require("nvim_agents.peers")

local M = {}

--- The time a Neovim has to answer, after which it's skipped.
M.timeout_ms = 50

--- The code each Neovim runs to tell what it has of a file.
local probe = [[
local ok, mcp = pcall(require, "nvim_agents.mcp")
if not ok then return nil end
return { state = mcp.file_state(...), cwd = vim.fn.getcwd() }
]]

--- Returns the addresses of the running Neovims, the one at `$NVIM`
--- included.
---@return string[]
M.addresses = function()
  local addresses = peers.addresses()
  local nvim = vim.env.NVIM
  if nvim and nvim ~= "" and not vim.list_contains(addresses, nvim) then
    table.insert(addresses, 1, nvim)
  end
  return addresses
end

---@param dir any
---@param path string
---@return integer The length of the directory if it contains the path, or else -1.
local containing = function(dir, path)
  if type(dir) ~= "string" then return -1 end
  dir = dir:gsub("/$", "")
  return vim.startswith(path, dir .. "/") and #dir or -1
end

--- Returns whether a score is higher than another, comparing their numbers
--- in order.
---@param score integer[]
---@param other integer[]
---@return boolean
local beats = function(score, other)
  for index, number in ipairs(score) do
    if number ~= other[index] then return number > (other[index] or 0) end
  end
  return false
end

--- Calls back with the address of the Neovim to run a tool call on a file in,
--- and the file's state there, or with nothing if no Neovim answers.
---@param path string An absolute path.
---@param callback fun(address?: string, state?: "modified"|"loaded")
M.find = function(path, callback)
  local nvim = vim.env.NVIM
  local rank = { modified = 2, loaded = 1 }
  local addresses = M.addresses()
  peers.ask_all(addresses, probe, { path }, M.timeout_ms, function(answers)
    ---@type string?, integer[]?
    local best, best_score
    for _, address in ipairs(addresses) do
      local answer = answers[address]
      if type(answer) == "table" then
        local score = {
          rank[answer.state] or 0,
          address == nvim and 1 or 0,
          containing(answer.cwd, path),
        }
        if not best_score or beats(score, best_score) then
          best, best_score = address, score
        end
      end
    end
    local answer = best and answers[best]
    callback(best, answer and answer.state or nil)
  end)
end

--- Calls back with the tools' descriptions, from the Neovim at `$NVIM` or
--- else the first one answering, or with nothing if none does.
---@param callback fun(listed?: { instructions?: string, tools: table[] })
M.list = function(callback)
  local code = [[
local ok, mcp = pcall(require, "nvim_agents.mcp")
if not ok then return nil end
return mcp.list()
]]
  local addresses = M.addresses()
  peers.ask_all(addresses, code, {}, M.timeout_ms, function(answers)
    local nvim = vim.env.NVIM
    if nvim and type(answers[nvim]) == "table" then return callback(answers[nvim]) end
    for _, address in ipairs(addresses) do
      if type(answers[address]) == "table" then return callback(answers[address]) end
    end
    callback(nil)
  end)
end

return M
