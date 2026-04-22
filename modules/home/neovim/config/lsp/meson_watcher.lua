-- An in-process language server that keeps compile_commands.json up to date for
-- Meson projects.
--
-- This server doesn't expose any capabilities. Its only job is to watch the
-- meson files in the project and run `meson setup build --reconfigure` whenever
-- any of them change, so that compile_commands.json stays in sync with the
-- build description.
--
-- We implement this as a language server (rather than a plain plugin or
-- autocommand) because it lets us reuse Neovim's LSP client logic for spawning
-- one instance per project root and tearing it down when all buffers in that
-- project are closed.

local methods = vim.lsp.protocol.Methods

--- Returns whether the given directory contains a `meson.build` whose first
--- non-comment, non-empty line starts with `project(`.
---@param dir_path string
---@return boolean
local has_meson_project = function(dir_path)
  local meson_build = dir_path .. "/meson.build"
  if vim.fn.filereadable(meson_build) ~= 1 then return false end
  for line in io.lines(meson_build) do
    local is_comment = line:match("^%s*#")
    if not is_comment then
      local stripped = line:gsub("%s+", "")
      if stripped ~= "" then return stripped:match("^project%(") ~= nil end
    end
  end
  return false
end

--- Finds the outermost Meson project root above `bufnr`'s file. Meson
--- subprojects also have a `project()` call in their meson.build, so we can't
--- just stop at the first match -- we need to walk all the way up and return
--- the last (outermost) one.
---@param bufnr integer
---@return string|nil
local find_meson_root = function(bufnr)
  local outermost = nil
  local path = vim.api.nvim_buf_get_name(bufnr)
  while true do
    local match = vim.fs.root(
      path,
      function(_, dir) return has_meson_project(dir) end
    )
    if not match then break end
    outermost = match
    -- Continue searching from the parent of the match.
    local parent = vim.fn.fnamemodify(match, ":h")
    if parent == match then break end -- reached filesystem root
    path = parent
  end
  return outermost
end

--- Starts a recursive filesystem watcher on `root_dir` that runs `meson setup
--- build --reconfigure` whenever a meson.build or meson.options file in its
--- subtree changes. Returns a cleanup function that stops the watcher.
---@param root_dir string
---@return fun() stop
local start_watcher = function(root_dir)
  local fs_event, err = vim.uv.new_fs_event()
  if not fs_event then
    vim.notify(
      "[meson_watcher] failed to create fs watcher: " .. (err or "unknown"),
      vim.log.levels.ERROR
    )
    return function() end
  end

  local reconfigure_in_flight = false
  local reconfigure_queued = false

  local reconfigure
  reconfigure = function()
    if reconfigure_in_flight then
      reconfigure_queued = true
      return
    end

    reconfigure_in_flight = true

    -- Find all build directories by looking for immediate subdirectories
    -- that contain `meson-private/` (which Meson always creates).
    local build_dirs = {}
    local handle = vim.uv.fs_scandir(root_dir)
    if handle then
      while true do
        local name, typ = vim.uv.fs_scandir_next(handle)
        if not name then break end
        if typ == "directory" then
          local meson_private = root_dir .. "/" .. name .. "/meson-private"
          if vim.uv.fs_stat(meson_private) then
            build_dirs[#build_dirs + 1] = name
          end
        end
      end
    end

    if #build_dirs == 0 then
      reconfigure_in_flight = false
      return
    end

    local remaining = #build_dirs

    for _, build_dir in ipairs(build_dirs) do
      vim.system(
        { "meson", "setup", build_dir, "--reconfigure" },
        { cwd = root_dir, text = true },
        vim.schedule_wrap(function(result)
          if result.code ~= 0 then
            local stdout = result.stdout or ""
            local is_syntax_error = stdout:match("ERROR:") ~= nil
            -- We only notify the user about FS-related errors. Syntax errors in
            -- the meson sources should be handled by a separate LSP.
            if is_syntax_error then return end
            vim.notify(
              string.format(
                "[meson_watcher] reconfigure of %s/ failed (exit %d): %s",
                build_dir,
                result.code,
                (result.stderr ~= "" and result.stderr)
                  or (stdout ~= "" and stdout)
                  or "unknown error"
              ),
              vim.log.levels.ERROR
            )
          end

          remaining = remaining - 1
          if remaining == 0 then
            reconfigure_in_flight = false
            if reconfigure_queued then
              reconfigure_queued = false
              reconfigure()
            end
          end
        end)
      )
    end
  end

  local debounce_timer, err = vim.uv.new_timer()
  if not debounce_timer then
    vim.notify(
      "[meson_watcher] failed to create debounce timer: " .. (err or "unknown"),
      vim.log.levels.ERROR
    )
    return function() end
  end

  fs_event:start(root_dir, { recursive = true }, function(watch_err, filename)
    if watch_err then return end
    if not filename then return end

    local basename = vim.fn.fnamemodify(filename, ":t")
    if basename == "meson.build" or basename == "meson.options" then
      -- Some FS events can cause this callback to be called multiple times, so
      -- we debounce the reconfigure step.
      debounce_timer:stop()
      debounce_timer:start(500, 0, vim.schedule_wrap(reconfigure))
    end
  end)

  return function()
    debounce_timer:stop()
    if not debounce_timer:is_closing() then debounce_timer:close() end
    fs_event:stop()
    if not fs_event:is_closing() then fs_event:close() end
  end
end

---@type vim.lsp.Config
return {
  filetypes = { "c", "cpp" },

  root_dir = function(bufnr, on_dir)
    local root = find_meson_root(bufnr)
    if root then on_dir(root) end
  end,

  ---@param dispatchers vim.lsp.rpc.Dispatchers
  ---@param config vim.lsp.ClientConfig
  cmd = function(dispatchers, config)
    local root_dir = assert(config.root_dir)
    local stop_watcher = start_watcher(root_dir)
    local closing = false
    local next_request_id = 0

    local handlers = {}

    handlers[methods.initialize] = function(_, callback)
      callback(nil, { capabilities = {} })
    end

    handlers[methods.shutdown] = function(_, callback)
      stop_watcher()
      callback(nil, nil)
    end

    return {
      request = function(method, params, callback, notify_reply_callback)
        local request_id = next_request_id
        next_request_id = next_request_id + 1
        local handler = handlers[method]
        if handler then handler(params, callback) end
        if notify_reply_callback then notify_reply_callback(request_id) end
        return true, request_id
      end,
      notify = function(method)
        if method == "exit" then
          closing = true
          dispatchers.on_exit(0, 0)
        end
        return true
      end,
      is_closing = function() return closing end,
      terminate = function()
        if closing then return end
        closing = true
        stop_watcher()
        dispatchers.on_exit(0, 0)
      end,
    }
  end,
}
