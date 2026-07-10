local M = {}

local launch_event = "NvimFlattenLaunch"
local will_swallow_event = "NvimFlattenWillSwallow"
local did_swallow_event = "NvimFlattenDidSwallow"
local will_show_event = "NvimFlattenWillShow"
local did_show_event = "NvimFlattenDidShow"

local plugin_root =
  vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
local bin_dir = plugin_root .. "/bin"

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
  local on_done = data.on_done or function() end

  local orig_buf = ev.buf
  local file_buf

  if #filepaths == 0 then
    vim.cmd.enew()
    file_buf = vim.api.nvim_get_current_buf()
  else
    for _, filepath in ipairs(filepaths) do
      local buf = get_or_add_buffer(filepath)
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

vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("nvim-session-flatten", {
    clear = true,
  }),
  pattern = launch_event,
  nested = true,
  callback = handle_launch,
})
