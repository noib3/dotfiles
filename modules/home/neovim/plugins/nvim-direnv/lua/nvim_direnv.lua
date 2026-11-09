local M = {}

local uv = vim.uv

local changed_event = "NvimDirenvChanged"

--- The delay between a change to a watched file and the reload it triggers.
local debounce_ms = 100

--- The longest a spawn waits for its directory's first export to finish.
local first_load_timeout_ms = 1000

local original_system = vim.system

---@class nvim_direnv.Watcher
---@field handle uv.uv_fs_event_t
---@field names table<string, true>

---@class nvim_direnv.State
---@field dir string The directory containing the `.envrc`.
---@field env? table<string, string> The environment from the last export.
---@field fallback_env? table<string, string> The environment given to spawns that couldn't wait for the first export.
---@field job? vim.SystemObj The export in flight.
---@field last_error? string
---@field rerun boolean Whether to export again once the current job exits.
---@field timer? uv.uv_timer_t
---@field watchers table<string, nvim_direnv.Watcher?> The watched directories, keyed by path.

---@type table<string, nvim_direnv.State?>
local states = {}

---@type fun(state: nvim_direnv.State)
local load

---@param key string
---@return boolean
local is_bookkeeping = function(key) return vim.startswith(key, "DIRENV_") end

--- Returns whether two environments differ in any variable other than
--- direnv's own bookkeeping.
---@param a table<string, string>
---@param b table<string, string>
---@return boolean
local envs_differ = function(a, b)
  for key, value in pairs(a) do
    if not is_bookkeeping(key) and b[key] ~= value then return true end
  end
  for key in pairs(b) do
    if not is_bookkeeping(key) and a[key] == nil then return true end
  end
  return false
end

---@param env table<string, string>
---@param diff table<string, string|vim.NIL>
---@return table<string, string>
local apply_diff = function(env, diff)
  local result = vim.deepcopy(env)
  for key, value in pairs(diff) do
    if value == vim.NIL then
      result[key] = nil
    else
      result[key] = tostring(value)
    end
  end
  return result
end

---@param path string
---@return string?
local envrc_dir = function(path)
  local root = vim.fs.root(path, ".envrc")
  return root and vim.fs.normalize(root)
end

---@param state nvim_direnv.State
local schedule_load = function(state)
  state.timer = state.timer or assert(uv.new_timer())
  state.timer:start(
    debounce_ms,
    0,
    vim.schedule_wrap(function() load(state) end)
  )
end

--- Makes the state's fs watchers cover exactly the parent directories of the
--- given paths. Watching parents instead of the files themselves also catches
--- files that are created later or replaced by an atomic rename.
---@param state nvim_direnv.State
---@param paths string[]
local watch = function(state, paths)
  ---@type table<string, table<string, true>>
  local names_by_dir = {}
  for _, path in ipairs(paths) do
    local dir = vim.fs.dirname(path)
    names_by_dir[dir] = names_by_dir[dir] or {}
    names_by_dir[dir][vim.fs.basename(path)] = true
  end

  for dir, watcher in pairs(state.watchers) do
    if not names_by_dir[dir] then
      watcher.handle:close()
      state.watchers[dir] = nil
    end
  end

  for dir, names in pairs(names_by_dir) do
    local watcher = state.watchers[dir]
    if watcher then
      watcher.names = names
    else
      local handle = assert(uv.new_fs_event())
      watcher = { handle = handle, names = names }
      local ok = handle:start(dir, {}, function(err, filename)
        if
          not err
          and filename
          and not watcher.names[vim.fs.basename(filename)]
        then
          return
        end
        schedule_load(state)
      end)
      if ok then
        state.watchers[dir] = watcher
      else
        handle:close()
      end
    end
  end
end

--- Decodes a `DIRENV_WATCHES` dump and watches the files it lists.
---@param state nvim_direnv.State
---@param dump string
local watch_dump = function(state, dump)
  original_system(
    { "direnv", "show_dump", dump },
    { text = true },
    vim.schedule_wrap(function(result)
      -- A newer export has replaced this dump.
      if not state.env or state.env.DIRENV_WATCHES ~= dump then return end

      local ok, watches = pcall(vim.json.decode, result.stdout)
      if not ok or type(watches) ~= "table" then return end

      watch(
        state,
        vim.iter(watches):map(function(entry) return entry.path end):totable()
      )
    end)
  )
end

---@param state nvim_direnv.State
---@param base table<string, string>
---@param result vim.SystemCompleted
local on_exported = function(state, base, result)
  state.job = nil

  local diff = {}
  if result.stdout and result.stdout ~= "" then
    local ok, decoded = pcall(vim.json.decode, result.stdout)
    if ok and type(decoded) == "table" then diff = decoded end
  end

  if result.code ~= 0 then
    local message = vim.trim((result.stderr or ""):gsub("\27%[[%d;]*m", ""))
    if message ~= state.last_error then
      vim.notify(message, vim.log.levels.WARN, { title = "direnv" })
    end
    state.last_error = message
  else
    state.last_error = nil
  end

  local previous = state.env or state.fallback_env
  state.env = apply_diff(base, diff)
  state.fallback_env = nil

  if type(diff.DIRENV_WATCHES) == "string" then
    watch_dump(state, diff.DIRENV_WATCHES)
  end

  if previous and envs_differ(previous, state.env) then
    vim.api.nvim_exec_autocmds("User", {
      pattern = changed_event,
      modeline = false,
      data = { dir = state.dir, env = vim.deepcopy(state.env) },
    })
  end

  if state.rerun then
    state.rerun = false
    load(state)
  end
end

--- Runs `direnv export json` in the state's directory, on top of the last
--- exported environment. Direnv prints nothing when that environment is still
--- up to date, and otherwise reverts the old diff before applying the new one.
---@param state nvim_direnv.State
load = function(state)
  if state.job then
    state.rerun = true
    return
  end

  local base = state.env or uv.os_environ()
  local export_env = vim.tbl_extend("force", base, {
    DIRENV_LOG_FORMAT = "",
    TERM = "dumb",
  })

  state.job = original_system(
    { "direnv", "export", "json" },
    { cwd = state.dir, env = export_env, clear_env = true, text = true },
    vim.schedule_wrap(function(result) on_exported(state, base, result) end)
  )
end

--- Returns the state of the `.envrc` that applies to the given path, starting
--- its first export if needed.
---@param path string
---@return nvim_direnv.State?
local state_for_path = function(path)
  local dir = envrc_dir(path)
  if not dir then return nil end

  local state = states[dir]
  if state then return state end

  state = { dir = dir, rerun = false, watchers = {} }
  states[dir] = state
  load(state)
  return state
end

---@param cmd string[]
---@param opts? vim.SystemOpts
---@param on_exit? fun(out: vim.SystemCompleted)
---@return vim.SystemObj
local system = function(cmd, opts, on_exit)
  if
    type(opts) ~= "table"
    or type(opts.cwd) ~= "string"
    or opts.cwd == ""
    or opts.clear_env
  then
    return original_system(cmd, opts, on_exit)
  end

  local state = state_for_path(vim.fs.abspath(opts.cwd))
  if not state then return original_system(cmd, opts, on_exit) end

  if not state.env and not vim.in_fast_event() then
    vim.wait(first_load_timeout_ms, function() return state.env ~= nil end, 10)
  end

  if not state.env then
    state.fallback_env = state.fallback_env or uv.os_environ()
    return original_system(cmd, opts, on_exit)
  end

  local system_opts = vim.tbl_extend("force", {}, opts)
  system_opts.env = vim.tbl_extend("force", state.env, opts.env or {})
  system_opts.clear_env = true
  return original_system(cmd, system_opts, on_exit)
end

--- Returns the directory of the `.envrc` that applies to the given path.
---@param path string
---@return string?
M.dir_for_path = function(path) return envrc_dir(vim.fs.abspath(path)) end

M.setup = function()
  if vim.fn.executable("direnv") ~= 1 then return end

  vim.system = system

  vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("nvim-direnv", { clear = true }),
    desc = "Starts loading the direnv environment of the buffer's directory",
    callback = function(ev)
      if ev.file == "" or ev.file:match("^%a[%w+.-]*://") then return end
      state_for_path(vim.fs.abspath(ev.file))
    end,
  })
end

return M
