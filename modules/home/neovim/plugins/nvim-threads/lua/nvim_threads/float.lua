local render = require("nvim_threads.render")

local M = {}

--- The z-index of the floats, below the default one of other floats.
local zindex = 10

---@class nvim_threads.Float
---@field thread_id string
---@field source_buf integer The buffer whose thread the float displays.
---@field source_win integer The window displaying the buffer.
---@field row integer The 0-based row of the line the thread's virtual lines follow.
---@field offset integer The number of other threads' virtual lines before the thread's.
---@field source_scroll integer[] The source window's `topline`, `topfill` and `leftcol` when the float was placed.
--- The borders of the float's lines, drawn by its 'statuscolumn', each as
--- its text and highlight groups.
---@field borders nvim_threads.Chunk[]
---@field history integer The number of lines above the composer.

---@type table<integer, nvim_threads.Float?>
local floats = {}

local group =
  vim.api.nvim_create_augroup("nvim-threads-float", { clear = true })

--- Returns the float displayed in the window, if it's one.
---@param win integer
---@return nvim_threads.Float?
M.get = function(win) return floats[win] end

--- Returns the window of the float displaying a thread, if it's open.
---@param thread_id string
---@return integer?
M.of_thread = function(thread_id)
  for win, float in pairs(floats) do
    if float.thread_id == thread_id then return win end
  end
end

--- Returns the windows of the floats displaying a buffer's threads.
---@param buf integer
---@return integer[]
M.of_buffer = function(buf)
  -- `vim.iter()` would take the table of floats, keyed by window IDs, for an
  -- array.
  local wins = {}
  for win, float in pairs(floats) do
    if float.source_buf == buf then wins[#wins + 1] = win end
  end
  return wins
end

---@param win integer
---@return integer[]
local scroll_of = function(win)
  local view = vim.api.nvim_win_call(win, vim.fn.winsaveview)
  return { view.topline, view.topfill, view.leftcol }
end

--- Returns the screen rows of the virtual lines below a line that are
--- visible in the window, as the 1-based screen row of the first one, their
--- number, and the 1-based virtual line displayed first. Returns nothing if
--- none of them is visible.
---@param win integer
---@param row integer The 0-based row of the line the virtual lines follow.
---@param offset integer The number of virtual lines skipped before them.
---@param count integer The number of virtual lines.
---@return integer? first_row
---@return integer height
local visible_rows = function(win, row, offset, count)
  -- Brings the window's scroll position up to date with its cursor.
  vim.api.nvim_win_call(win, vim.fn.winline)

  local info = assert(vim.fn.getwininfo(win)[1])
  local bottom = info.winrow + info.height - 1
  local line_row = vim.fn.screenpos(win, row + 1, 1).row
  if line_row == 0 then return nil, 0 end

  -- The virtual lines follow all of the line's wrapped rows.
  local text =
    vim.api.nvim_win_text_height(win, { start_row = row, end_row = row })
  local first_row = line_row + text.all - text.fill + offset
  return first_row, math.max(math.min(count, bottom - first_row + 1), 0)
end

--- Scrolls the window to show the line the virtual lines follow and as many
--- of them as fit, if they aren't all visible already.
---@param win integer
---@param row integer The 0-based row of the line the virtual lines follow.
---@param offset integer
---@param count integer
M.reveal = function(win, row, offset, count)
  local first_row, visible = visible_rows(win, row, offset, count)
  if first_row and visible == count then return end
  local line = row + 1
  vim.api.nvim_win_call(
    win,
    function() vim.fn.winrestview({ lnum = line, topline = line, topfill = 0 }) end
  )
end

--- Opens a float displaying a buffer over the virtual lines of a thread,
--- without entering it. When only some of them are visible, the float only
--- covers those. Returns nothing if none of them is visible.
---@param buf integer The float's buffer.
---@param float nvim_threads.Float
---@param count integer The number of the thread's virtual lines.
---@return integer?
M.open = function(buf, float, count)
  local info = assert(vim.fn.getwininfo(float.source_win)[1])
  local width = info.width - info.textoff
  if width < 1 then return end

  local first_row, height =
    visible_rows(float.source_win, float.row, float.offset, count)
  if not first_row or height < 1 then return end

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "win",
    win = float.source_win,
    row = first_row - info.winrow,
    col = info.textoff,
    width = width,
    height = height,
    focusable = true,
    style = "minimal",
    zindex = zindex,
  })
  vim.wo[win].winhighlight = table.concat({
    "Normal:ThreadsNormal",
    "NormalFloat:ThreadsNormal",
    "EndOfBuffer:ThreadsNormal",
    "LineNr:ThreadsNormal",
    "CursorLineNr:ThreadsNormal",
  }, ",")
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].breakindent = false
  vim.wo[win].list = false
  vim.wo[win].statuscolumn =
    "%!v:lua.require'nvim_threads.float'.statuscolumn()"
  vim.wo[win].statusline = "%!v:lua.require'nvim_threads.float'.statusline()"

  float.source_scroll = scroll_of(float.source_win)
  floats[win] = float
  return win
end

--- Moves and resizes a float to cover the thread's virtual lines again,
--- after their number changed.
---@param win integer
---@param count integer
M.place = function(win, count)
  local float = floats[win]
  if not float or not vim.api.nvim_win_is_valid(float.source_win) then
    return
  end
  local first_row, height =
    visible_rows(float.source_win, float.row, float.offset, count)
  if not first_row or height < 1 then return M.close(win) end
  local info = assert(vim.fn.getwininfo(float.source_win)[1])
  vim.api.nvim_win_set_config(win, {
    relative = "win",
    win = float.source_win,
    row = first_row - info.winrow,
    col = info.textoff,
    width = info.width - info.textoff,
    height = height,
  })
  float.source_scroll = scroll_of(float.source_win)
end

---@param win integer
M.close = function(win)
  local float = floats[win]
  if not float then return end
  floats[win] = nil
  if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  vim.api.nvim_exec_autocmds("User", {
    pattern = "NvimThreadsFloatClosed",
    modeline = false,
    data = { thread_id = float.thread_id, source_buf = float.source_buf },
  })
end

--- Moves the cursor into a float, and closes the float when the cursor
--- leaves it.
---@param win integer
---@param position? { line: integer, virtcol: integer } The 1-based line and the screen column.
M.enter = function(win, position)
  if not floats[win] then return end

  -- Without autocommands, the source window stays the one other plugins
  -- consider focused.
  vim.cmd(("noautocmd call nvim_set_current_win(%d)"):format(win))
  if position then
    local line_count =
      vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win))
    vim.api.nvim_win_set_cursor(win, { math.min(position.line, line_count), 0 })
    vim.cmd(("normal! %d|"):format(position.virtcol))
  end

  vim.api.nvim_create_autocmd("WinLeave", {
    group = group,
    buffer = vim.api.nvim_win_get_buf(win),
    once = true,
    desc = "Closes the float of a thread",
    callback = vim.schedule_wrap(function() M.close(win) end),
  })
end

--- Returns the 'statuscolumn' of the current float: the border of the
--- line being drawn.
---@return string
M.statuscolumn = function()
  local float = floats[vim.g.statusline_winid]
  local border = float and float.borders[vim.v.lnum]
  if not border then return render.border end
  local hl = border[2]
  if type(hl) == "table" then hl = hl[#hl] end
  return ("%%#%s#%s%%*"):format(
    render.on_background(hl or "ThreadsNormal"),
    border[1]
  )
end

--- Returns the statusline of the source window of the current float, which
--- the global statusline displays while the float is the current window.
---@return string
M.statusline = function()
  local float = floats[vim.api.nvim_get_current_win()]
  if not float or not vim.api.nvim_win_is_valid(float.source_win) then
    return vim.go.statusline
  end
  return vim.wo[float.source_win].statusline
end

vim.api.nvim_create_autocmd("WinScrolled", {
  group = group,
  desc = "Closes the floats of threads whose window scrolled",
  callback = function()
    for win, float in pairs(floats) do
      local source = float.source_win
      local scrolled = not vim.api.nvim_win_is_valid(source)
        or not vim.deep_equal(scroll_of(source), float.source_scroll)
      if scrolled then M.close(win) end
    end
  end,
})

return M
