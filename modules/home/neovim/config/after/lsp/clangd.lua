-- Custom clangd configuration that provides workspace-wide diagnostics.
--
-- By default, clangd only provides diagnostics for the currently-opened files.
-- This config works around that by sending `textDocument/didOpen` on startup
-- for every source file listed in the project's `compile_commands.json`, making
-- clangd treat them as "open" and producing diagnostics for the entire project.
--
-- We intercept Neovim's `didOpen` and `didClose` notifications to prevent the
-- normal buffer lifecycle from interfering with our "all files open" state, and
-- we watch `compile_commands.json` to keep the file set in sync.

local methods = vim.lsp.protocol.Methods

---@param config vim.lsp.ClientConfig
---@return boolean
local workspace_diagnostics_enabled = function(config)
  local enabled = vim.tbl_get(
    config.settings or {},
    "clangd",
    "noib3",
    "workspaceDiagnostics"
  )

  return enabled ~= false
end

--- Returns whether the active clang-format config disables formatting.
---@param root_dir string?
---@return boolean
local clang_format_is_disabled = function(root_dir)
  if not root_dir then return false end

  local clang_format = vim.fs.find(".clang-format", {
    upward = true,
    path = root_dir,
  })[1]
  if not clang_format then return false end

  for _, line in ipairs(vim.fn.readfile(clang_format)) do
    local value = line:match("^%s*DisableFormat%s*:%s*([^#]+)")
    if value then return vim.trim(value):lower() == "true" end
  end

  return false
end

--- Parses a compile_commands.json and returns the set of source file paths.
---@param path string
---@return table<string, true>
local parse_compile_commands = function(path)
  local f = io.open(path, "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()

  local ok, entries = pcall(vim.json.decode, content)
  if not ok or type(entries) ~= "table" then return {} end

  local files = {}
  for _, entry in ipairs(entries) do
    if entry.file then
      local file = entry.file
      if not file:match("^/") and entry.directory then
        file = entry.directory .. "/" .. file
      end
      files[vim.fs.normalize(file)] = true
    end
  end
  return files
end

--- Reads a file from disk.
---@param path string
---@return string?
local read_file = function(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

--- Finds the first compile_commands.json under `root_dir`, searching
--- immediate subdirectories and the root itself.
---@param root_dir string
---@return string?
local find_compile_commands = function(root_dir)
  local candidates = {}
  local handle = vim.uv.fs_scandir(root_dir)
  if handle then
    while true do
      local name, typ = vim.uv.fs_scandir_next(handle)
      if not name then break end
      if typ == "directory" then
        local cc = root_dir .. "/" .. name .. "/compile_commands.json"
        if vim.uv.fs_stat(cc) then candidates[#candidates + 1] = cc end
      end
    end
  end
  local root_cc = root_dir .. "/compile_commands.json"
  if vim.uv.fs_stat(root_cc) then candidates[#candidates + 1] = root_cc end
  table.sort(candidates)
  return candidates[1]
end

--- Returns the LSP language ID for a file path.
---@param path string
---@return string
local get_language_id = function(path)
  local ext = vim.fn.fnamemodify(path, ":e")
  local map = {
    c = "c",
    h = "c",
    cc = "cpp",
    cpp = "cpp",
    cxx = "cpp",
    hh = "cpp",
    hpp = "cpp",
    hxx = "cpp",
    m = "objective-c",
    mm = "objective-cpp",
  }
  return map[ext] or "cpp"
end

local notify_handlers = {}

--- When the user opens a file already in our workspace set, we suppress the
--- `didOpen` (which would be a protocol violation) and send `didChange` instead
--- to sync clangd with the buffer contents. We also restore any cached
--- diagnostics since clangd won't re-send them if the content matches.
notify_handlers[methods.textDocument_didOpen] = function(state, client, params)
  local path = vim.uri_to_fname(params.textDocument.uri)
  if not state.workspace_files[path] then return end

  state.workspace_files[path] = state.workspace_files[path] + 1
  state.original_notify(client, methods.textDocument_didChange, {
    textDocument = {
      uri = params.textDocument.uri,
      version = state.workspace_files[path],
    },
    contentChanges = { { text = params.textDocument.text } },
  })

  local cached = state.diagnostics_cache[path]
  if cached then
    local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
    local ns = vim.lsp.diagnostic.get_namespace(client.id)
    vim.schedule(function() vim.diagnostic.set(ns, bufnr, cached) end)
  end

  return true
end

--- When the user closes a buffer, we suppress the `didClose` so the file stays
--- "open" in clangd. If the buffer had unsaved changes we send `didChange` with
--- the on-disk contents to revert clangd's view. We also cache and restore
--- diagnostics since Neovim's `_on_detach` clears them.
notify_handlers[methods.textDocument_didClose] = function(state, client, params)
  local path = vim.uri_to_fname(params.textDocument.uri)
  if not state.workspace_files[path] then return end

  local bufnr = vim.fn.bufnr(path)

  -- Revert clangd to on-disk contents if the buffer was dirty.
  if bufnr ~= -1 and vim.bo[bufnr].modified then
    local text = read_file(path)
    if text then
      state.workspace_files[path] = state.workspace_files[path] + 1
      state.original_notify(client, methods.textDocument_didChange, {
        textDocument = {
          uri = params.textDocument.uri,
          version = state.workspace_files[path],
        },
        contentChanges = { { text = text } },
      })
    end
  end

  -- Cache diagnostics and restore them after _on_detach's reset.
  if bufnr ~= -1 then
    local ns = vim.lsp.diagnostic.get_namespace(client.id)
    local diags = vim.diagnostic.get(bufnr, { namespace = ns })
    state.diagnostics_cache[path] = diags
    vim.schedule(function() vim.diagnostic.set(ns, bufnr, diags) end)
  end

  return true
end

--- Installs a per-client `publishDiagnostics` handler that tracks workspace
--- open progress by counting responses from clangd.
---@param client vim.lsp.Client
---@param state table
local install_progress_handler = function(client, state)
  local default_handler =
    vim.lsp.handlers[methods.textDocument_publishDiagnostics]

  client.handlers[methods.textDocument_publishDiagnostics] = function(
    err,
    result,
    ctx,
    config
  )
    default_handler(err, result, ctx, config)

    if not state.tracking_progress then return end

    local uri = result and result.uri
    if not uri then return end
    local path = vim.uri_to_fname(uri)
    if not state.workspace_files[path] then return end

    state.diagnostics_received = state.diagnostics_received + 1
    if state.diagnostics_received >= state.diagnostics_expected then
      state.report_progress(
        "end",
        string.format(
          "%d/%d",
          state.diagnostics_received,
          state.diagnostics_expected
        )
      )
      state.tracking_progress = false
    else
      local pct = math.floor(
        state.diagnostics_received / state.diagnostics_expected * 100
      )
      state.report_progress(
        "report",
        string.format(
          "%d/%d",
          state.diagnostics_received,
          state.diagnostics_expected
        ),
        pct
      )
    end
  end
end

--- Returns a progress reporting function for the given client, using the same
--- LspProgress mechanism as clangd's own progress updates.
---@param client vim.lsp.Client
---@return function
local new_progress_reporter = function(client)
  local token = "clangd-workspace"

  return function(kind, message, percentage)
    local value = { kind = kind, message = message, percentage = percentage }
    if kind == "begin" then
      value.title = "Opening workspace files"
      client.progress.pending[token] = value.title
    else
      value.title = client.progress.pending[token]
      if kind == "end" then client.progress.pending[token] = nil end
    end
    client.progress:push({ token = token, value = value })
    vim.api.nvim_exec_autocmds("LspProgress", {
      pattern = kind,
      modeline = false,
      data = {
        client_id = client.id,
        params = { token = token, value = value },
      },
    })
  end
end

--- Parses compile_commands.json and sends `didOpen`/`didClose` to bring
--- clangd's set of open files in sync. Reports progress for new files.
---@param client vim.lsp.Client
---@param state table
---@param cc_path string
local sync_workspace_files = function(client, state, cc_path)
  local new_files = parse_compile_commands(cc_path)
  local original_notify = state.original_notify

  -- Close files no longer in the compilation database.
  for path in pairs(state.workspace_files) do
    if not new_files[path] then
      original_notify(client, methods.textDocument_didClose, {
        textDocument = { uri = vim.uri_from_fname(path) },
      })
      state.workspace_files[path] = nil
    end
  end

  -- Open new files.
  local opened = 0
  for path in pairs(new_files) do
    if not state.workspace_files[path] then
      local text = read_file(path)
      if text then
        state.workspace_files[path] = 0
        original_notify(client, methods.textDocument_didOpen, {
          textDocument = {
            uri = vim.uri_from_fname(path),
            languageId = get_language_id(path),
            version = 0,
            text = text,
          },
        })
        opened = opened + 1
      end
    end
  end

  if opened > 0 then
    state.diagnostics_expected = opened
    state.diagnostics_received = 0
    state.tracking_progress = true
    state.report_progress("begin", string.format("0/%d", opened), 0)
  end
end

--- Watches compile_commands.json and re-syncs the workspace files when it
--- changes.
---@param client vim.lsp.Client
---@param state table
---@param cc_path string
local watch_compile_commands = function(client, state, cc_path)
  local watcher = vim.uv.new_fs_event()
  if not watcher then return end

  local debounce = vim.uv.new_timer()
  if not debounce then
    watcher:close()
    return
  end

  watcher:start(cc_path, {}, function(err)
    if err then return end
    debounce:stop()
    debounce:start(
      1000,
      0,
      vim.schedule_wrap(
        function() sync_workspace_files(client, state, cc_path) end
      )
    )
  end)
end

--- Wraps `client.notify` to intercept outgoing `didOpen`/`didClose`
--- notifications for workspace files.
---@param client vim.lsp.Client
---@param state table
local install_notify_interceptor = function(client, state)
  local original_notify = state.original_notify

  client.notify = function(self, method, params)
    local handler = notify_handlers[method]
    if handler and handler(state, self, params) then return true end
    return original_notify(self, method, params)
  end
end

---@type vim.lsp.Config
return {
  settings = {
    clangd = {
      noib3 = {
        workspaceDiagnostics = false,
      },
    },
  },

  cmd = function(dispatchers, config)
    local cmd = { "clangd" }

    if workspace_diagnostics_enabled(config) then
      -- Raise the file descriptor limit: workspace-wide diagnostics open all
      -- project files in clangd simultaneously, which can exceed the OS default.
      cmd = { "sh", "-c", "ulimit -n 10240; exec clangd --background-index" }
    end

    return vim.lsp.rpc.start(cmd, dispatchers)
  end,

  on_init = function(client, init_result)
    -- Replicate nvim-lspconfig's default on_init for clangd, which handles
    -- clangd's custom `offsetEncoding` extension.
    ---@diagnostic disable-next-line: undefined-field
    if init_result.offsetEncoding then
      ---@diagnostic disable-next-line: undefined-field
      client.offset_encoding = init_result.offsetEncoding
    end

    if clang_format_is_disabled(client.root_dir) then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end

    if not workspace_diagnostics_enabled(client.config) then return end

    local root_dir = client.root_dir
    if not root_dir then return end

    local cc_path = find_compile_commands(root_dir)
    if not cc_path then return end

    local state = {
      diagnostics_cache = {}, -- path -> diagnostics list (populated on didClose)
      diagnostics_expected = 0,
      diagnostics_received = 0,
      original_notify = client.notify,
      report_progress = new_progress_reporter(client),
      tracking_progress = false,
      workspace_files = {}, -- path -> version number
    }

    install_progress_handler(client, state)
    install_notify_interceptor(client, state)
    watch_compile_commands(client, state, cc_path)
    sync_workspace_files(client, state, cc_path)
  end,
}
