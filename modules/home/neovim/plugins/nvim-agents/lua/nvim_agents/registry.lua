--- The agents' sessions, read from the files their hooks append to: one per
--- session, at `<dir>/<agent>/<session ID>.jsonl`, with a JSON object per
--- line.
---
--- Each object has an `event` and the `time` it happened, in seconds since the
--- epoch:
--- - `start`, with the session's `cwd` and the `nvim` address of the Neovim
---   whose terminal runs it, if any;
--- - `end`;
--- - `read` and `edit`, with the absolute `path` of the file;
--- - `title`, with the session's `title`.

local M = {}

local uv = vim.uv

---@class nvim_agents.Session
---@field agent string
---@field id string
---@field cwd? string
---@field nvim? string The address of the Neovim whose terminal runs the session.
---@field title? string The session's latest title.
---@field running boolean
---@field time integer The time of the session's last event.
---@field edited table<string, integer?> The time of the last edit of each file.
---@field read table<string, integer?> The time of the last read of each file.

---@class nvim_agents.Match
---@field session nvim_agents.Session
---@field edited integer The number of the paths the session edited.
---@field read integer The number of the paths the session read.
---@field contains boolean Whether the session's `cwd` contains all the paths.

---@class nvim_agents.registry.File
---@field size integer The number of bytes folded into the session.
---@field partial string The bytes after the last newline folded so far.
---@field session nvim_agents.Session

--- The sessions read so far, by file.
---@type table<string, nvim_agents.registry.File?>
local files = {}

--- Returns a path with its symlinks resolved, if it exists.
---@param path string
---@return string
M.canonical = function(path)
  return vim.fs.normalize(uv.fs_realpath(path) or path)
end

---@param session nvim_agents.Session
---@param line string
local fold = function(session, line)
  local ok, event =
    pcall(vim.json.decode, line, { luanil = { object = true, array = true } })
  if not ok or type(event) ~= "table" then return end
  local time = math.floor(tonumber(event.time) or 0)
  session.time = math.max(session.time, time)
  if event.event == "start" then
    session.cwd = event.cwd and M.canonical(event.cwd) or session.cwd
    session.nvim = event.nvim
    session.running = true
  elseif event.event == "end" then
    session.running = false
  elseif event.event == "title" and type(event.title) == "string" then
    session.title = event.title
  elseif
    (event.event == "edit" or event.event == "read")
    and type(event.path) == "string"
  then
    local times = event.event == "edit" and session.edited or session.read
    local path = M.canonical(event.path)
    if time > (times[path] or 0) then times[path] = time end
  end
end

--- Reads the bytes of a file appended since it was last read.
---@param path string
---@param from integer
---@return string?
local read_from = function(path, from)
  local fd = uv.fs_open(path, "r", 438)
  if not fd then return end
  local stat = uv.fs_fstat(fd)
  local data = stat
    and stat.size > from
    and uv.fs_read(fd, stat.size - from, from)
  uv.fs_close(fd)
  return data or ""
end

---@param path string
---@param agent string
---@param id string
---@return nvim_agents.Session?
local load_file = function(path, agent, id)
  local stat = uv.fs_stat(path)
  if not stat then
    files[path] = nil
    return
  end
  local file = files[path]
  if not file or stat.size < file.size then
    file = {
      size = 0,
      partial = "",
      session = {
        agent = agent,
        id = id,
        running = false,
        time = 0,
        edited = {},
        read = {},
      },
    }
    files[path] = file
  end
  if stat.size > file.size then
    local data = read_from(path, file.size) or ""
    file.size = file.size + #data
    local text = file.partial .. data
    local last = 1
    for line, next_start in text:gmatch("([^\n]*)\n()") do
      last = next_start --[[@as integer]]
      fold(file.session, line)
    end
    file.partial = text:sub(last)
  end
  return file.session
end

--- Returns the sessions whose last event is at most `max_age` seconds old.
---@param dir string
---@param max_age number
---@return nvim_agents.Session[]
M.load = function(dir, max_age)
  local sessions = {}
  local oldest = os.time() - max_age
  for agent, kind in vim.fs.dir(dir) do
    if kind == "directory" then
      local agent_dir = vim.fs.joinpath(dir, agent)
      for name in vim.fs.dir(agent_dir) do
        local id = name:match("^(.+)%.jsonl$")
        local session = id
          and load_file(vim.fs.joinpath(agent_dir, name), agent, id)
        if session and session.time >= oldest then
          sessions[#sessions + 1] = session
        end
      end
    end
  end
  return sessions
end

---@param dir string
---@param path string
---@return boolean
local contains = function(dir, path)
  return path == dir or vim.startswith(path, dir:gsub("/$", "") .. "/")
end

--- Returns the sessions that edited or read any of the paths, or whose `cwd`
--- contains all of them, best first: the ones that edited the most of them,
--- then read the most of them, then contain them, then were active last.
---@param sessions nvim_agents.Session[]
---@param paths string[] Absolute paths.
---@return nvim_agents.Match[]
M.rank = function(sessions, paths)
  local matches = {}
  for _, session in ipairs(sessions) do
    ---@type nvim_agents.Match
    local match =
      { session = session, edited = 0, read = 0, contains = #paths > 0 }
    for _, path in ipairs(paths) do
      if session.edited[path] then match.edited = match.edited + 1 end
      if session.read[path] then match.read = match.read + 1 end
      if not session.cwd or not contains(session.cwd, path) then
        match.contains = false
      end
    end
    if match.edited > 0 or match.read > 0 or match.contains then
      matches[#matches + 1] = match
    end
  end
  table.sort(matches, function(a, b)
    if a.edited ~= b.edited then return a.edited > b.edited end
    if a.read ~= b.read then return a.read > b.read end
    if a.contains ~= b.contains then return a.contains end
    if a.session.time ~= b.session.time then
      return a.session.time > b.session.time
    end
    return a.session.id < b.session.id
  end)
  return matches
end

return M
