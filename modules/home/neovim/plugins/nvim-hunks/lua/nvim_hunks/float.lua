local render = require("nvim_hunks.render")

local M = {}

local attach_event = "NvimHunksAttach"

--- The z-index of the floats, below the default one of other floats.
local zindex = 10

---@class nvim_hunks.Float
---@field buf integer The buffer whose deleted lines the float displays.
---@field hunk nvim_hunks.Hunk
---@field row integer The 0-based row the deleted lines are attached to.
---@field above boolean Whether the deleted lines are above the row.
---@field source_win integer The window displaying the buffer.
---@field source_scroll integer[] The source window's `topline`, `topfill` and `leftcol` when the float was opened.

---@type table<integer, nvim_hunks.Float>
local floats = {}

local group = vim.api.nvim_create_augroup("nvim-hunks-float", { clear = true })

--- Returns the float displayed in the window, if it's one.
---@param win integer
---@return nvim_hunks.Float?
M.get = function(win) return floats[win] end

--- Returns the windows of the floats displaying the buffer's deleted lines.
---@param buf integer
---@return integer[]
M.of_buffer = function(buf)
  -- `vim.iter()` would take the table of floats, keyed by window IDs, for an
  -- array.
  local wins = {}
  for win, float in pairs(floats) do
    if float.buf == buf then wins[#wins + 1] = win end
  end
  return wins
end

---@param win integer
M.close = function(win)
  if not floats[win] then return end
  floats[win] = nil
  if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
end

--- Highlights the float's lines like the virtual lines it covers, with the
--- syntax computed from the whole old text. The deleted lines alone often
--- aren't enough for treesitter to parse.
---@param buf integer The float's buffer.
---@param hunk nvim_hunks.Hunk
---@param lines string[]
---@param syntax nvim_hunks.Syntax The syntax of the old lines.
---@param layout nvim_hunks.Layout The layout of the lines, which don't wrap.
local highlight = function(buf, hunk, lines, syntax, layout)
  for idx, text in ipairs(lines) do
    local captures = syntax[hunk.old_start + idx - 1]
    for _, segment in ipairs(render.syntax_segments(text, captures)) do
      vim.api.nvim_buf_set_extmark(buf, render.namespace, idx - 1, segment[1], {
        end_col = segment[2],
        hl_group = segment[3],
        priority = vim.hl.priorities.treesitter,
      })
    end
    render.render_lines(buf, idx, { text }, layout, "Delete")
  end

  for _, change in ipairs(hunk.old_changes) do
    vim.api.nvim_buf_set_extmark(
      buf,
      render.namespace,
      change.line - hunk.old_start,
      change.start_col,
      {
        end_col = change.end_col,
        hl_group = "HunksDeleteText",
        priority = render.text_priority,
      }
    )
  end
end

---@param win integer
---@return integer[]
local scroll_of = function(win)
  local view = vim.api.nvim_win_call(win, vim.fn.winsaveview)
  return { view.topline, view.topfill, view.leftcol }
end

--- Returns the screen rows of the virtual lines displaying a hunk's deleted
--- lines that are visible in the window, as the 1-based screen row of the
--- first one, their number, and the 1-based deleted line displayed first.
--- Returns nothing if none of them is visible.
---@param win integer
---@param row integer The 0-based row the deleted lines are attached to.
---@param above boolean Whether the deleted lines are above the row.
---@param count integer The number of deleted lines.
---@return integer? first_row
---@return integer height
---@return integer first_line
local visible_rows = function(win, row, above, count)
  -- Brings the window's scroll position up to date with its cursor.
  vim.api.nvim_win_call(win, vim.fn.winline)

  local info = assert(vim.fn.getwininfo(win)[1])
  local top, bottom = info.winrow, info.winrow + info.height - 1
  local anchor_row = vim.fn.screenpos(win, row + 1, 1).row
  if above and anchor_row > 0 then
    local first_row = math.max(anchor_row - count, top)
    local height = anchor_row - first_row
    return first_row, height, count - height + 1
  end

  -- Without a visible line below them, the virtual lines are located from
  -- the line they follow, after all of its wrapped rows.
  local before = above and row or row + 1
  if before < 1 then return nil, 0, 0 end
  local before_row = vim.fn.screenpos(win, before, 1).row
  if before_row == 0 then return nil, 0, 0 end
  local text = vim.api.nvim_win_text_height(
    win,
    { start_row = before - 1, end_row = before - 1 }
  )
  local first_row = before_row + text.all - text.fill
  return first_row, math.min(count, bottom - first_row + 1), 1
end

--- Scrolls the window to show the virtual lines displaying a hunk's deleted
--- lines and the line they're attached to. If they don't fit, it shows as
--- many of the deleted lines as fit, starting from the first one when
--- entering them from above, or from the last one when entering them from
--- below. Moves the window's cursor to a line that stays visible.
---@param win integer
---@param hunk nvim_hunks.Hunk
---@param line_count integer The number of lines in the buffer.
---@param from_above boolean
M.reveal = function(win, hunk, line_count, from_above)
  local row, above = render.deleted_anchor(hunk, line_count)
  local anchor = row + 1
  local count = hunk.old_count
  local height = vim.api.nvim_win_get_height(win)

  local view
  if count + 1 <= height then
    local first_row, visible = visible_rows(win, row, above, count)
    if first_row and visible == count then
      local anchor_row = vim.fn.screenpos(win, anchor, 1).row
      if anchor_row > 0 then return end
    end
    view = { lnum = anchor, topline = anchor, topfill = above and count or 0 }
  elseif above and from_above and anchor > 1 then
    view = { lnum = anchor - 1, topline = anchor - 1, topfill = 0 }
  elseif above then
    view = { lnum = anchor, topline = anchor, topfill = height - 1 }
  else
    view = { lnum = anchor, topline = anchor, topfill = 0 }
  end

  vim.api.nvim_win_call(win, function() vim.fn.winrestview(view) end)
end

--- Opens a float over the virtual lines displaying a hunk's deleted lines,
--- without entering it. When only some of them are visible, the float only
--- covers those. Returns nothing if none of them is visible.
---@param source_win integer A window displaying the buffer.
---@param buf integer
---@param hunk nvim_hunks.Hunk
---@param old_lines string[]
---@param syntax nvim_hunks.Syntax The syntax of the old lines.
---@param line_count integer The number of lines in the buffer.
---@return integer?
M.open = function(source_win, buf, hunk, old_lines, syntax, line_count)
  local info = assert(vim.fn.getwininfo(source_win)[1])
  local width = info.width - info.textoff
  if width < 1 or hunk.old_count == 0 then return end

  local lines = vim.list_slice(
    old_lines,
    hunk.old_start,
    hunk.old_start + hunk.old_count - 1
  )
  local row, above = render.deleted_anchor(hunk, line_count)
  local first_row, height, first_line =
    visible_rows(source_win, row, above, #lines)
  if not first_row or height < 1 then return end

  local float_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, lines)
  vim.bo[float_buf].bufhidden = "wipe"
  vim.bo[float_buf].modifiable = false
  vim.bo[float_buf].tabstop = vim.bo[buf].tabstop

  local layout = render.layout(buf, source_win)
  layout.wrap_width = nil
  highlight(float_buf, hunk, lines, syntax, layout)

  -- The float is placed at the screen rows of the virtual lines, which don't
  -- move unless the source window scrolls, and that closes the float.
  local win = vim.api.nvim_open_win(float_buf, false, {
    relative = "win",
    win = source_win,
    row = first_row - info.winrow,
    col = info.textoff,
    width = width,
    height = height,
    focusable = true,
    style = "minimal",
    zindex = zindex,
  })
  vim.wo[win].winhighlight = "NormalFloat:Normal"
  vim.wo[win].wrap = false
  vim.wo[win].list = false
  vim.wo[win].statusline = "%!v:lua.require'nvim_hunks.float'.statusline()"
  vim.api.nvim_win_call(
    win,
    function() vim.fn.winrestview({ topline = first_line, lnum = first_line }) end
  )

  floats[win] = {
    buf = buf,
    hunk = hunk,
    row = row,
    above = above,
    source_win = source_win,
    source_scroll = scroll_of(source_win),
  }

  vim.api.nvim_exec_autocmds("User", {
    pattern = attach_event,
    modeline = false,
    data = { buf = float_buf, float = true },
  })

  return win
end

--- Moves the cursor into a float, and closes the float when the cursor leaves
--- it. Without a position, a cursor already in the float stays where it is.
---@param win integer
---@param position? { line: integer, virtcol: integer } The 1-based line and the screen column.
M.enter = function(win, position)
  if not floats[win] then return end

  -- Without autocommands, the source window stays the one other plugins
  -- consider focused.
  vim.cmd(("noautocmd call nvim_set_current_win(%d)"):format(win))
  if position then
    vim.api.nvim_win_set_cursor(win, { position.line, 0 })
    vim.cmd(("normal! %d|"):format(position.virtcol))
  end

  vim.api.nvim_create_autocmd("WinLeave", {
    group = group,
    buffer = vim.api.nvim_win_get_buf(win),
    once = true,
    desc = "Closes the float of deleted lines",
    callback = vim.schedule_wrap(function() M.close(win) end),
  })
end

--- Closes the current float and moves the cursor to the buffer line before
--- or after the deleted lines it displays, keeping the desired column. Does
--- nothing if there's no such line.
---@param win integer
---@param direction 1|-1
---@return boolean exited
M.exit = function(win, direction)
  local float = floats[win]
  if not float or not vim.api.nvim_win_is_valid(float.source_win) then
    return false
  end

  local line_count = vim.api.nvim_buf_line_count(float.buf)
  -- The 1-based buffer lines around the deleted lines.
  local before = float.above and float.row or float.row + 1
  local after = before + 1
  local target = direction > 0 and after or before
  if target < 1 or target > line_count then return false end

  local virtcol = vim.fn.winsaveview().curswant + 1
  vim.cmd(("noautocmd call nvim_set_current_win(%d)"):format(float.source_win))
  vim.api.nvim_win_set_cursor(float.source_win, { target, 0 })
  vim.cmd(("normal! %d|"):format(virtcol))
  M.close(win)
  return true
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
  desc = "Closes the floats of deleted lines whose window scrolled",
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
