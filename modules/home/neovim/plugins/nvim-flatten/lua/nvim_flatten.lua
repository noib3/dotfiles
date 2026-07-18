local M = {}

local launch_event = "NvimFlattenLaunch"
local will_swallow_event = "NvimFlattenWillSwallow"
local did_swallow_event = "NvimFlattenDidSwallow"
local will_show_event = "NvimFlattenWillShow"
local did_show_event = "NvimFlattenDidShow"

local project_markers = {
  ".envrc",
  ".git",
  ".hg",
  ".svn",
  "flake.nix",
  "Cargo.toml",
  "go.mod",
  "pyproject.toml",
  "package.json",
  "deno.json",
  "deno.jsonc",
  "Gemfile",
  "composer.json",
  "mix.exs",
  "build.zig",
  "meson.build",
  "CMakeLists.txt",
  "Makefile",
}

local plugin_root =
  vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
local bin_dir = plugin_root .. "/bin"

local contexts_by_buffer = {}
local contexts_by_root = {}
local roots_by_buffer = {}
local original_lsp_start

local prepend_path = function(dir)
  for path in vim.gsplit(vim.env.PATH or "", ":") do
    if path == dir then return end
  end

  vim.env.PATH = dir .. ":" .. (vim.env.PATH or "")
end

vim.env.NVIM_FLATTEN_REAL_NVIM = vim.fn.exepath(vim.v.progpath)
if vim.env.NVIM_FLATTEN_REAL_NVIM == "" then
  vim.env.NVIM_FLATTEN_REAL_NVIM = vim.v.progpath
end
prepend_path(bin_dir)

local normalize = function(path)
  if type(path) ~= "string" or path == "" then return nil end
  return vim.fs.normalize(path)
end

local environment_id = function(environment)
  local keys = vim.tbl_keys(environment)
  table.sort(keys)

  local serialized = {}
  for _, key in ipairs(keys) do
    local value = tostring(environment[key])
    serialized[#serialized + 1] = #key .. ":" .. key
    serialized[#serialized + 1] = #value .. ":" .. value
  end

  return vim.fn.sha256(table.concat(serialized))
end

local new_context = function(environment)
  local normalized = {}
  for key, value in pairs(environment or {}) do
    normalized[tostring(key)] = tostring(value)
  end

  return {
    environment = normalized,
    id = environment_id(normalized),
  }
end

local path_for_buffer = function(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name ~= "" then return name end

  local context = contexts_by_buffer[bufnr]
  if context then return context.environment.PWD end
  return nil
end

local detect_project_root = function(path)
  path = normalize(path)
  if not path then return nil end
  return normalize(vim.fs.root(path, { project_markers }))
end

local path_is_within = function(path, root)
  path = normalize(path)
  root = normalize(root)
  if not path or not root then return false end
  return path == root or vim.startswith(path, root .. "/")
end

local context_for_path = function(path)
  local best_root
  local best_context

  for root, context in pairs(contexts_by_root) do
    if path_is_within(path, root) and (not best_root or #root > #best_root) then
      best_root = root
      best_context = context
    end
  end

  return best_context
end

local context_for_buffer = function(bufnr)
  if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

  local context = contexts_by_buffer[bufnr]
  if context then return context end

  local path = path_for_buffer(bufnr)
  if not path then return nil end

  context = context_for_path(path)
  if context then contexts_by_buffer[bufnr] = context end
  return context
end

local register_buffer = function(bufnr, context, path)
  contexts_by_buffer[bufnr] = context

  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    local lsp_root = normalize(client.root_dir)
    if lsp_root then contexts_by_root[lsp_root] = context end
  end

  local root = detect_project_root(path)
    or detect_project_root(context.environment.PWD)
    or normalize(context.environment.PWD)
  if not root then return end

  roots_by_buffer[bufnr] = root
  contexts_by_root[root] = context
end

local uri_to_path = function(uri)
  if type(uri) ~= "string" or uri == "" then return nil end
  local ok, path = pcall(vim.uri_to_fname, uri)
  if ok then return normalize(path) end
  return nil
end

local root_for_lsp = function(config, opts)
  local root = normalize(config.root_dir)
  if root then return root end

  local folder = config.workspace_folders and config.workspace_folders[1]
  local workspace_root = folder and uri_to_path(folder.uri)
  if workspace_root then return workspace_root end

  if opts and opts._root_markers then
    local bufnr = opts.bufnr or 0
    if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
    return normalize(vim.fs.root(bufnr, opts._root_markers))
  end

  return nil
end

local merge_environment = function(environment, overrides)
  local result = vim.deepcopy(environment or {})
  for key, value in pairs(overrides or {}) do
    if value == vim.NIL or value == nil then
      result[key] = nil
    else
      result[key] = tostring(value)
    end
  end
  return result
end

local wrap_rpc_start = function(environment, command)
  return function(dispatchers, config)
    local rpc_start = vim.lsp.rpc.start

    vim.lsp.rpc.start = function(cmd, dispatchers_, spawn_params)
      spawn_params = vim.deepcopy(spawn_params or {})
      spawn_params.env = merge_environment(environment, spawn_params.env)
      return rpc_start(cmd, dispatchers_, spawn_params)
    end

    local ok, result = pcall(command, dispatchers, config)
    vim.lsp.rpc.start = rpc_start
    if not ok then error(result) end
    return result
  end
end

local default_reuse_client = function(client, config)
  return client.name == config.name and client.root_dir == config.root_dir
end

local with_lsp_environment = function(config, opts)
  local bufnr = opts and opts.bufnr or 0
  if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

  local root = root_for_lsp(config, opts)
  local context = context_for_buffer(bufnr)
    or (root and contexts_by_root[root])
    or (root and context_for_path(root))

  if not context then return config, opts end
  if root then contexts_by_root[root] = context end

  local result = vim.deepcopy(config)
  local base_cmd_env = result._nvim_flatten_base_cmd_env
    or vim.deepcopy(result.cmd_env or {})
  local original_cmd = result._nvim_flatten_original_cmd or result.cmd

  result.root_dir = root or result.root_dir
  result._nvim_flatten_base_cmd_env = base_cmd_env
  result._nvim_flatten_env_id = context.id
  result.cmd_env = merge_environment(context.environment, base_cmd_env)

  if type(original_cmd) == "function" then
    result._nvim_flatten_original_cmd = original_cmd
    result.cmd = wrap_rpc_start(result.cmd_env, original_cmd)
  end

  local start_opts = vim.tbl_extend("force", {}, opts or {})
  local reuse_client = start_opts.reuse_client or default_reuse_client
  start_opts.reuse_client = function(client, config_)
    return client.config._nvim_flatten_env_id == config_._nvim_flatten_env_id
      and reuse_client(client, config_)
  end

  return result, start_opts
end

original_lsp_start = vim.lsp.start
vim.lsp.start = function(config, opts)
  local config_, opts_ = with_lsp_environment(config, opts)
  return original_lsp_start(config_, opts_)
end

--- Returns an iterator over the windows currently displaying the given buffer.
--- @param buf number
local buf_get_wins = function(buf)
  return vim
    .iter(vim.api.nvim_list_wins())
    :filter(function(win) return vim.api.nvim_win_get_buf(win) == buf end)
end

--- @param buf number
--- @param pattern string
local emit_for_buffer = function(buf, pattern)
  if not vim.api.nvim_buf_is_valid(buf) then return end

  vim.api.nvim_buf_call(
    buf,
    function()
      vim.api.nvim_exec_autocmds("User", {
        pattern = pattern,
        modeline = false,
      })
    end
  )
end

--- @param filepath string
--- @return number
local get_or_add_buffer = function(filepath)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_valid(bufnr)
      and vim.api.nvim_buf_get_name(bufnr) == filepath
    then
      return bufnr
    end
  end

  return vim.fn.bufadd(filepath)
end

--- @param buf number
--- @param filepath string
local prepare_buffer = function(buf, filepath)
  vim.api.nvim_set_option_value("buflisted", true, { buf = buf })
  vim.fn.bufload(buf)

  if vim.bo[buf].filetype ~= "" then return end

  local ft = vim.filetype.match({ buf = buf, filename = filepath })
  if ft and ft ~= "" then
    vim.api.nvim_buf_call(buf, function() vim.cmd("setfiletype " .. ft) end)
  end
end

--- @param buf number
--- @param commands string[]
local run_post_commands = function(buf, commands)
  if #commands == 0 then return end

  local wins = buf_get_wins(buf):totable()

  local run = function()
    for _, command in ipairs(commands) do
      local ok, err = pcall(vim.cmd, command)
      if not ok then
        vim.notify(
          ("nvim-flatten: failed to run command %q: %s"):format(command, err),
          vim.log.levels.ERROR
        )
      end
    end
  end

  if #wins > 0 and vim.api.nvim_win_is_valid(wins[1]) then
    vim.api.nvim_win_call(wins[1], run)
  else
    vim.api.nvim_buf_call(buf, run)
  end
end

--- @param ev table
local handle_launch = function(ev)
  local data = ev.data or {}
  local filepaths = data.filepaths or {}
  local commands = data.commands or {}
  local context = new_context(data.environment)
  local on_done = data.on_done or function() end

  local orig_buf = ev.buf
  local file_buf

  if #filepaths == 0 then
    vim.cmd.enew()
    file_buf = vim.api.nvim_get_current_buf()
    register_buffer(file_buf, context)
  else
    for _, filepath in ipairs(filepaths) do
      local buf = get_or_add_buffer(filepath)
      register_buffer(buf, context, filepath)
      prepare_buffer(buf, filepath)
      if not file_buf then file_buf = buf end
    end

    if #filepaths == 1 and file_buf == orig_buf then
      vim.schedule(on_done)
      return
    end

    emit_for_buffer(orig_buf, will_swallow_event)

    if orig_buf == vim.api.nvim_get_current_buf() then
      vim.api.nvim_win_set_buf(0, file_buf)
    else
      for win in buf_get_wins(orig_buf) do
        vim.api.nvim_win_set_buf(win, file_buf)
      end
    end
  end

  local file_wins = buf_get_wins(file_buf):totable()
  emit_for_buffer(file_buf, did_swallow_event)

  local deleting_file_buf = false

  vim.api.nvim_create_autocmd({ "BufWinEnter", "BufWinLeave" }, {
    buffer = file_buf,
    callback = function()
      -- Update after the window transition completes. Buffer-deletion plugins
      -- also move windows before deleting their buffers; in that case
      -- `deleting_file_buf` is set before this scheduled update can discard the
      -- last user-selected restore targets.
      vim.schedule(function()
        if deleting_file_buf or not vim.api.nvim_buf_is_valid(file_buf) then
          return
        end
        file_wins = buf_get_wins(file_buf):totable()
      end)
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = file_buf,
    once = true,
    callback = function()
      deleting_file_buf = true
      emit_for_buffer(file_buf, will_show_event)

      vim.schedule(function()
        local restored_win

        if vim.api.nvim_buf_is_valid(orig_buf) then
          for _, win in ipairs(file_wins) do
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_set_buf(win, orig_buf)
              restored_win = restored_win or win
            end
          end
        end

        emit_for_buffer(orig_buf, did_show_event)
        on_done()

        if
          not vim.api.nvim_buf_is_valid(orig_buf)
          or vim.bo[orig_buf].buftype ~= "terminal"
        then
          return
        end

        local win = restored_win
        local current_win = vim.api.nvim_get_current_win()
        if vim.api.nvim_win_get_buf(current_win) == orig_buf then
          win = current_win
        end

        -- Buffer-deletion plugins may move windows before BufDelete runs. If
        -- orig_buf is already visible, still return to Terminal-mode there.
        if not win then win = buf_get_wins(orig_buf):next() end

        if win then vim.api.nvim_win_call(win, vim.cmd.startinsert) end
      end)
    end,
  })

  run_post_commands(file_buf, commands)
end

local group = vim.api.nvim_create_augroup("nvim-session-flatten", {
  clear = true,
})

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = launch_event,
  nested = true,
  callback = handle_launch,
})

vim.api.nvim_create_autocmd("BufWipeout", {
  group = group,
  callback = function(ev)
    contexts_by_buffer[ev.buf] = nil
    roots_by_buffer[ev.buf] = nil
  end,
})

M.environment_for_buffer = function(bufnr)
  local context = context_for_buffer(bufnr or 0)
  return context and vim.deepcopy(context.environment) or nil
end

M.environment_for_root = function(root)
  root = normalize(root)
  local context = root and (contexts_by_root[root] or context_for_path(root))
  return context and vim.deepcopy(context.environment) or nil
end

M.project_root = function(bufnr)
  if not bufnr or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
  return roots_by_buffer[bufnr] or detect_project_root(path_for_buffer(bufnr))
end

return M
