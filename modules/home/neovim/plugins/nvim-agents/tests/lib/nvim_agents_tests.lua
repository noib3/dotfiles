local M = {}

---@param actual any
---@param expected any
---@param message? string
M.eq = function(actual, expected, message)
  if vim.deep_equal(actual, expected) then return end
  local show = function(value)
    return type(value) == "string" and value or vim.inspect(value)
  end
  error(
    ("%s\n--- expected\n%s\n--- actual\n%s"):format(
      message or "values differ",
      show(expected),
      show(actual)
    ),
    2
  )
end

--- Waits until the condition holds, failing if it doesn't within the time.
---@param condition fun(): boolean?
---@param message string
---@param timeout_ms? integer
M.wait = function(condition, message, timeout_ms)
  if not vim.wait(timeout_ms or 5000, condition, 10) then
    error("timed out waiting until " .. message, 2)
  end
end

---@param path string
---@param text string
M.write = function(path, text)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local file = assert(io.open(path, "wb"))
  file:write(text)
  file:close()
end

---@param path string
---@param text string
M.append = function(path, text)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local file = assert(io.open(path, "ab"))
  file:write(text)
  file:close()
end

---@param path string
---@return string?
M.read = function(path)
  local file = io.open(path, "rb")
  if not file then return end
  local text = file:read("*a")
  file:close()
  return text
end

--- Returns a new empty directory, with its symlinks resolved.
---@return string
M.tmpdir = function()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  return (assert(vim.uv.fs_realpath(dir)))
end

--- Returns the path of a file in the `lib` directory.
---@param name string
---@return string
M.lib = function(name)
  local source = assert(debug.getinfo(1, "S")).source:sub(2)
  return vim.fs.joinpath(vim.fs.dirname(source), name)
end

--- Returns the command running the fake ACP agent, which logs the messages
--- it gets to a file.
---@param log string
---@return string[]
M.fake_agent = function(log)
  return {
    vim.v.progpath,
    "--clean",
    "-l",
    M.lib("fake_agent.lua"),
    log,
  }
end

--- Returns the messages the fake agent got, in order.
---@param log string
---@return { method: string, params: table }[]
M.agent_log = function(log)
  local messages = {}
  for line in (M.read(log) or ""):gmatch("[^\n]+") do
    messages[#messages + 1] = vim.json.decode(line)
  end
  return messages
end

--- Returns the methods the fake agent got, in order.
---@param log string
---@return string[]
M.agent_methods = function(log)
  return vim.tbl_map(
    function(message) return message.method end,
    M.agent_log(log)
  )
end

return M
