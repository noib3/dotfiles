local M = {}

local launch_event = "NvimFlattenLaunch"
local will_swallow_event = "NvimFlattenWillSwallow"

local plugin_root =
  vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
local bin_dir = plugin_root .. "/bin"

local buffers_owned_by_flatten = {}
local transform_filepaths = function(filepaths) return filepaths end

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
--- @return number, boolean
local get_or_add_buffer = function(filepath)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_valid(bufnr)
      and vim.api.nvim_buf_get_name(bufnr) == filepath
    then
      return bufnr, buffers_owned_by_flatten[bufnr] == true
    end
  end

  local bufnr = vim.fn.bufadd(filepath)
  buffers_owned_by_flatten[bufnr] = true
  return bufnr, true
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
  local filepaths = transform_filepaths(vim.deepcopy(data.filepaths or {}))
  local commands = data.commands or {}
  local on_done = data.on_done or function() end

  local orig_buf = ev.buf
  local orig_buflisted = vim.bo[orig_buf].buflisted
  local file_buf
  local file_buf_owned = false

  if #filepaths == 0 then
    emit_for_buffer(orig_buf, will_swallow_event)
    vim.cmd.enew()
    file_buf = vim.api.nvim_get_current_buf()
    file_buf_owned = true
    buffers_owned_by_flatten[file_buf] = true

    local launch_cwd = normalize(data.cwd)
    local launch_cwd_stat = launch_cwd and vim.uv.fs_stat(launch_cwd)
    if launch_cwd_stat and launch_cwd_stat.type == "directory" then
      vim.cmd.bcd({ args = { launch_cwd } })
    end
  else
    for _, filepath in ipairs(filepaths) do
      local buf, owned = get_or_add_buffer(filepath)
      prepare_buffer(buf, filepath)
      if not file_buf then
        file_buf = buf
        file_buf_owned = owned
      end
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

  local deleting_file_buf = false

  local window_autocmd = vim.api.nvim_create_autocmd(
    { "BufWinEnter", "BufWinLeave" },
    {
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
    }
  )

  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = file_buf,
    once = true,
    callback = function()
      deleting_file_buf = true
      local should_restore = vim.api.nvim_buf_is_valid(orig_buf)
        and vim.b[orig_buf].nvim_flatten_restore ~= false
      if should_restore then vim.bo[orig_buf].buflisted = orig_buflisted end

      vim.schedule(function()
        pcall(vim.api.nvim_del_autocmd, window_autocmd)

        local restored_win

        if should_restore and vim.api.nvim_buf_is_valid(orig_buf) then
          for _, win in ipairs(file_wins) do
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_set_buf(win, orig_buf)
              restored_win = restored_win or win
            end
          end
        end

        if file_buf_owned and vim.api.nvim_buf_is_valid(file_buf) then
          local ok, err = pcall(vim.api.nvim_buf_delete, file_buf, {
            force = true,
          })
          if not ok then
            vim.notify(
              ("nvim-flatten: failed to wipe owned buffer: %s"):format(err),
              vim.log.levels.ERROR
            )
          end
        end

        on_done()

        if
          not should_restore
          or not restored_win
          or not vim.api.nvim_buf_is_valid(orig_buf)
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

vim.api.nvim_create_autocmd("BufWipeout", {
  group = group,
  callback = function(ev) buffers_owned_by_flatten[ev.buf] = nil end,
})

---@param data table
M.launch = function(data)
  local orig_buf = vim.api.nvim_get_current_buf()

  vim.api.nvim_exec_autocmds("User", {
    pattern = launch_event,
    modeline = false,
    data = data,
  })

  handle_launch({ buf = orig_buf, data = data })
end

---@class nvim_flatten.Config
---@field transform_filepaths? fun(filepaths: string[]): string[]

---@param config? nvim_flatten.Config
M.setup = function(config)
  config = config or {}
  transform_filepaths = config.transform_filepaths
    or function(filepaths) return filepaths end
end

return M
