local Format = require("trouble.format")
local Item = require("trouble.item")
local hunks = require("nvim_hunks")

local M = {}

---@class nvim_hunks.trouble.Entry
---@field file nvim_hunks.File
---@field hunk? nvim_hunks.Hunk Unset on the row of the file itself.

--- Returns the `+added -deleted` segments of a set of hunks.
---@param hunk_list nvim_hunks.Hunk[]
---@return trouble.Format[]
local counts = function(hunk_list)
  local added, deleted = 0, 0
  for _, hunk in ipairs(hunk_list) do
    added = added + hunk.new_count
    deleted = deleted + hunk.old_count
  end

  local segments = {}
  if added > 0 then
    segments[#segments + 1] = { text = " +" .. added, hl = "HunksAddedCount" }
  end
  if deleted > 0 then
    segments[#segments + 1] =
      { text = " -" .. deleted, hl = "HunksDeletedCount" }
  end
  return segments
end

---@param file nvim_hunks.File
---@param path string
---@return string
local display_path = function(file, path)
  return vim.fn.fnamemodify(vim.fs.joinpath(file.root, path), ":~:.")
end

--- Returns the 1-based line a hunk starts at in the buffer, or the line its
--- deleted lines follow.
---@param hunk nvim_hunks.Hunk
---@return integer
local first_line = function(hunk) return math.max(hunk.new_start, 1) end

--- Returns the distinct files of a node's items.
---@param node trouble.Node
---@return nvim_hunks.File[]
local files_of = function(node)
  local files, seen = {}, {}
  for _, item in ipairs(node:flatten()) do
    local file = item.item.file
    if file and not seen[file] then
      seen[file] = true
      files[#files + 1] = file
    end
  end
  return files
end

--- The changes to files in the order they're summarized, with their letters
--- and the highlights of their numbers.
local statuses = {
  { "modified", "m", "HunksModifiedFiles" },
  { "added", "a", "HunksAddedFiles" },
  { "removed", "d", "HunksDeletedFiles" },
  { "renamed", "r", "HunksRenamedFiles" },
  { "copied", "c", "HunksRenamedFiles" },
}

--- Returns the segments summarizing a set of files, like `3m 1a 1d (+20 -4)`:
--- how many were modified, added, deleted, renamed and copied, and the lines
--- added and deleted.
---@param files nvim_hunks.File[]
---@return trouble.Format[]
local summary = function(files)
  ---@type table<string, integer?>
  local counts_by_status = {}
  local all = {}
  for _, file in ipairs(files) do
    counts_by_status[file.status] = (counts_by_status[file.status] or 0) + 1
    vim.list_extend(all, file.hunks)
  end

  local segments = {}
  for _, status in ipairs(statuses) do
    local count = counts_by_status[status[1]]
    if count then
      segments[#segments + 1] = { text = " " .. count, hl = status[3] }
      segments[#segments + 1] = { text = status[2] }
    end
  end

  local lines = counts(all)
  if #lines > 0 then
    -- The counts of lines start with a space.
    lines[1].text = lines[1].text:sub(2)
    segments[#segments + 1] = { text = " (" }
    vim.list_extend(segments, lines)
    segments[#segments + 1] = { text = ")" }
  end
  return segments
end

--- The files of the last listing.
---@type nvim_hunks.File[]
local listed = {}

--- The working-copy commit of the listed workspace, if only one is listed.
---@type nvim_hunks.Revision?
local working_copy

--- The floats showing the recap of each open list of hunks at its top-right
--- corner, keyed by the list's window.
---@type table<integer, integer>
local recaps = {}

local recap_namespace = vim.api.nvim_create_namespace("nvim-hunks-recap")

--- Returns the lines of the recap of the listed files, each as its segments:
--- the working-copy commit's IDs and bookmarks, the counts of changed files
--- and lines, and the commit's description, shortened to the given width.
---@param max_width integer
---@return trouble.Format[][]
local recap_lines = function(max_width)
  local lines = {}

  if working_copy then
    local change_id, commit_id = working_copy.change_id, working_copy.commit_id
    local ids = {
      { text = change_id.prefix, hl = "Special" },
      { text = change_id.rest, hl = "Comment" },
      { text = " " },
      { text = commit_id.prefix, hl = "Identifier" },
      { text = commit_id.rest, hl = "Comment" },
    }
    for _, bookmark in ipairs(working_copy.bookmarks) do
      ids[#ids + 1] = { text = " " .. bookmark, hl = "Function" }
    end
    lines[#lines + 1] = ids
  end

  if #listed > 0 then
    local summarized = summary(listed)
    -- The summary starts with a space.
    local first = summarized[1]
    if first then first.text = first.text:sub(2) end
    lines[#lines + 1] = summarized
  end

  if working_copy then
    local description = working_copy.description
    local has_description = description ~= ""
    if not has_description then description = "(no description set)" end
    if vim.api.nvim_strwidth(description) > max_width then
      description = vim.fn.strcharpart(description, 0, max_width - 1) .. "…"
    end
    lines[#lines + 1] = {
      { text = description, hl = not has_description and "Comment" or nil },
    }
  end

  return lines
end

--- Draws the recap of the listed files at the top-right corner of a list of
--- hunks, with each of its lines aligned to the right.
---@param list_win integer
local draw_recap = function(list_win)
  local list_width = vim.api.nvim_win_get_width(list_win)
  local lines = recap_lines(math.max(math.floor(list_width / 2), 10))
  local recap = recaps[list_win]
  if #lines == 0 then
    if recap and vim.api.nvim_win_is_valid(recap) then
      vim.api.nvim_win_close(recap, true)
    end
    recaps[list_win] = nil
    return
  end

  local widths, width = {}, 0
  for idx, segments in ipairs(lines) do
    widths[idx] = 0
    for _, segment in ipairs(segments) do
      widths[idx] = widths[idx] + vim.api.nvim_strwidth(segment.text)
    end
    width = math.max(width, widths[idx])
  end
  width = math.min(width, list_width)

  local buf = recap
      and vim.api.nvim_win_is_valid(recap)
      and vim.api.nvim_win_get_buf(recap)
    or vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"

  local texts, marks = {}, {}
  for idx, segments in ipairs(lines) do
    local text = (" "):rep(math.max(width - widths[idx], 0))
    for _, segment in ipairs(segments) do
      if segment.hl then
        marks[#marks + 1] =
          { idx - 1, #text, #text + #segment.text, segment.hl }
      end
      text = text .. segment.text
    end
    texts[idx] = text
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, texts)
  vim.api.nvim_buf_clear_namespace(buf, recap_namespace, 0, -1)
  for _, mark in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(buf, recap_namespace, mark[1], mark[2], {
      end_col = mark[3],
      hl_group = mark[4],
    })
  end

  ---@type vim.api.keyset.win_config
  local config = {
    relative = "win",
    win = list_win,
    anchor = "NE",
    row = 0,
    col = list_width,
    width = width,
    height = #lines,
    focusable = false,
    style = "minimal",
  }
  if recap and vim.api.nvim_win_is_valid(recap) then
    vim.api.nvim_win_set_config(recap, config)
  else
    config.noautocmd = true
    recap = vim.api.nvim_open_win(buf, false, config)
    vim.wo[recap].winhighlight =
      "Normal:TroubleNormal,NormalFloat:TroubleNormal"
    recaps[list_win] = recap
  end
end

--- Returns the window of a list of hunks, if it's open.
---@param view trouble.View
---@return integer?
local list_win = function(view)
  local win = view.win.win --[[@as integer?]]
  return win and vim.api.nvim_win_is_valid(win) and win or nil
end

--- Draws the recaps of the open lists of hunks.
local draw_recaps = function()
  for _, open in ipairs(require("trouble.view").get({ mode = "hunks" })) do
    local win = list_win(open.view)
    if win then draw_recap(win) end
  end
end

M.config = {
  formatters = {
    hunks_directory = function(ctx)
      local directory = ctx.item.directory
      local parent = ctx.node:parent_item()
      if parent and parent.directory then
        directory = directory:sub(#parent.directory + 1)
      end
      return { text = directory, hl = "TroubleDirectory" }
    end,
    hunks_directory_summary = function(ctx) return summary(files_of(ctx.node)) end,
    hunks_row = function(ctx)
      ---@type nvim_hunks.trouble.Entry
      local entry = ctx.item.item
      local file, hunk = entry.file, entry.hunk

      if hunk then
        local first = first_line(hunk)
        local last = first + hunk.new_count - 1
        local range = last > first and ("L%d-%d"):format(first, last)
          or ("L%d"):format(first)
        return vim.list_extend({ { text = range } }, counts({ hunk }))
      end

      local segments = { Format.formatters.file_icon(ctx), { text = " " } }
      if file.status == "renamed" then
        segments[#segments + 1] = {
          text = display_path(file, assert(file.old_path)) .. " → ",
        }
      end
      segments[#segments + 1] = {
        text = ctx.item.basename,
        hl = file.status == "added" and "HunksAddedCount"
          or file.status == "removed" and "HunksDeletedCount"
          or nil,
      }
      vim.list_extend(segments, counts(file.hunks))

      local tag = file.binary and "binary"
        or file.status == "added" and "new file"
        or file.status == "removed" and "deleted"
        or file.status == "copied" and "copied"
        or nil
      if tag then
        segments[#segments + 1] =
          { text = (" (%s)"):format(tag), hl = "Comment" }
      end
      return segments
    end,
  },
  modes = {
    hunks = {
      desc = "Hunks of the working-copy change",
      source = "hunks",
      events = {
        {
          event = "User",
          pattern = { "NvimHunksChanged", "NvimHunksFilesChanged" },
        },
      },
      groups = {
        {
          "directory",
          format = "{directory_icon} {hunks_directory}{hunks_directory_summary}",
        },
      },
      sort = {},
      format = "{hunks_row}",
      -- The list places its own cursor when it opens.
      follow = false,
    },
  },
}

--- Returns the row of a file, or of one of its hunks nested under the
--- file's row.
---@param file nvim_hunks.File
---@param hunk? nvim_hunks.Hunk
---@param parent? trouble.Item The row of the file.
---@return trouble.Item
local new_item = function(file, hunk, parent)
  local filename = vim.fs.joinpath(file.root, file.path)
  -- A file's row is at its first hunk, which its preview shows.
  local shown = hunk or file.hunks[1]
  local line = shown and first_line(shown) or 1
  local last = hunk and math.max(line + hunk.new_count - 1, line) or line

  local bufnr = file.status == "removed" and hunks.deleted_buffer(file)
    or vim.fn.bufnr(filename)
  local buf = bufnr > 0 and vim.api.nvim_buf_is_loaded(bufnr) and bufnr or nil

  return Item.new({
    id = hunk and ("%s:%d:%d"):format(filename, hunk.old_start, hunk.new_start)
      or filename,
    buf = buf,
    filename = filename,
    pos = { line, 0 },
    end_pos = { last, 0 },
    -- A file's row covers the whole file, and its hunks' rows come after it.
    range = not hunk and {
      pos = { 1, 0 },
      end_pos = { math.max(#file.lines, 1), 0 },
    } or nil,
    item = { file = file, hunk = hunk },
    parent = parent,
    source = "hunks",
  })
end

--- The roots of the jj workspaces listed while the list is open, taken from
--- the working directory it was opened in.
---@type string[]?
local roots

--- Returns the row of the hunk containing the cursor of a window, or else
--- the row of the window's file, if it's listed.
---@param items trouble.Item[]
---@param main trouble.Main
---@return trouble.Item?
local row_at = function(items, main)
  local line = main.cursor[1]
  ---@type trouble.Item?
  local found
  for _, item in ipairs(items) do
    local range = item.range
      or { pos = item.pos, end_pos = item.end_pos or item.pos }
    if
      item.buf == main.buf
      and line >= range.pos[1]
      and line <= range.end_pos[1]
    then
      found = item
    end
  end
  return found
end

--- The ids of the rows of the files listed since the list was opened.
---@type table<string, true>
local listed_files = {}

--- Calls back with the open list of hunks once it shows one of the given
--- items, and is focused if asked to.
---@param items table<trouble.Item, true>
---@param focused boolean
---@param on_shown fun(view: trouble.View)
local when_shown = function(items, focused, on_shown)
  local timer = assert(vim.uv.new_timer())
  local deadline = vim.uv.now() + 2000
  timer:start(
    10,
    10,
    vim.schedule_wrap(function()
      if timer:is_closing() then return end
      local done = vim.uv.now() > deadline
      for _, open in ipairs(require("trouble.view").get({ mode = "hunks" })) do
        local view = open.view
        local win = list_win(view)
        local is_ready = win
          and (not focused or win == vim.api.nvim_get_current_win())
        if is_ready and not done then
          for _, location in pairs(view.renderer._locations) do
            if location.item and items[location.item] then
              done = true
              on_shown(view)
              break
            end
          end
        end
      end
      if done then timer:close() end
    end)
  )
end

--- The time it takes the main loop to report a cursor movement.
local cursor_moved_ms = 50

--- Calls a function that moves the cursor of a list of hunks, without
--- previewing the item it moves to.
---@param view trouble.View
---@param move fun()
local without_preview = function(view, move)
  local auto_preview = view.opts.auto_preview
  view.opts.auto_preview = false
  move()
  vim.defer_fn(
    function() view.opts.auto_preview = auto_preview end,
    cursor_moved_ms
  )
end

--- Moves the cursor of a list of hunks to an item's row, or else to the first
--- row.
---@param view trouble.View
---@param target? trouble.Item
local move_cursor_to = function(view, target)
  local win = list_win(view)
  if not win then return end
  ---@type integer?
  local first
  for row, location in pairs(view.renderer._locations) do
    if target and location.item == target then
      return vim.api.nvim_win_set_cursor(win, { row, 0 })
    end
    if location.node and (not first or row < first) then first = row end
  end
  if first then vim.api.nvim_win_set_cursor(win, { first, 0 }) end
end

--- Collapses the rows of the files that are new to the list, or of all files
--- but the given one when the list is opening.
---@param view trouble.View
---@param new_files table<trouble.Item, true>
---@param is_opening boolean
---@param expanded? nvim_hunks.File
local collapse_files = function(view, new_files, is_opening, expanded)
  for _, location in pairs(view.renderer._locations) do
    local item, node = location.item, location.node
    local is_file = item and node and not item.item.hunk and not node:is_leaf()
    if item and node and is_file and (is_opening or new_files[item]) then
      local action = item.item.file == expanded and "open" or "close"
      view.renderer:fold(node, { action = action })
    end
  end
  require("trouble.view").render(view)
end

--- Returns the directory a file is listed under: its directory relative to
--- the root of its workspace, under the workspace's name if several are
--- listed. Files at the root of a single workspace aren't under any.
---@param file nvim_hunks.File
---@param in_several boolean
---@return string?
local listed_dir = function(file, in_several)
  local dir = vim.fs.dirname(file.path)
  if dir == "." then dir = "" end
  if in_several then
    local name = vim.fs.basename(file.root)
    dir = dir == "" and name or name .. "/" .. dir
  end
  return dir ~= "" and dir or nil
end

--- Lists every changed file, with the hunks of the modified and renamed ones
--- nested under it, collapsed. A list that's opening starts on the hunk or
--- file under the cursor of the window it's opened from, with only that file
--- expanded. The listed workspaces are the ones around the list's `cwd`
--- option, or else the current working directory when it opens.
---@param cb fun(items: trouble.Item[])
---@param ctx { main?: trouble.Main, opts: { cwd?: string } }
M.get = function(cb, ctx)
  local is_opening = roots == nil
  roots = roots or hunks.workspaces(ctx.opts.cwd)
  hunks.show_all(true)
  hunks.files(roots, function(files)
    if #roots == 1 then
      hunks.working_copy(roots[1], function(revision)
        working_copy = revision
        draw_recaps()
      end)
    else
      working_copy = nil
    end
    listed = files
    local in_several = #roots > 1
    local items = {}
    ---@type table<trouble.Item, true>
    local batch, new_files = {}, {}
    for _, file in ipairs(files) do
      local file_item = new_item(file)
      items[#items + 1] = file_item
      if not listed_files[file_item.id] then
        listed_files[file_item.id] = true
        new_files[file_item] = true
      end
      if file.status == "modified" or file.status == "renamed" then
        for _, hunk in ipairs(file.hunks) do
          items[#items + 1] = new_item(file, hunk, file_item)
        end
      end
    end
    for _, item in ipairs(items) do
      batch[item] = true
      -- The tree of directories starts at the workspaces' roots.
      item.dirname = listed_dir(item.item.file, in_several)
    end
    cb(items)

    local target = is_opening and ctx.main and row_at(items, ctx.main) or nil
    when_shown(batch, is_opening, function(view)
      local win = list_win(view)
      if win then draw_recap(win) end
      without_preview(view, function()
        collapse_files(view, new_files, is_opening, target and target.item.file)
        if is_opening then move_cursor_to(view, target) end
      end)
    end)
  end)
end

--- Draws the hunks on a preview, laid out for the preview's window, and
--- removes trouble's highlights of the item, which cover the hunk's colors.
---@param item trouble.Item
---@param ctx { win: integer, buf: integer }
M.preview = function(item, ctx)
  vim.wo[ctx.win].cursorline = false
  vim.api.nvim_buf_clear_namespace(
    ctx.buf,
    require("trouble.view.render").ns,
    0,
    -1
  )
  ---@type nvim_hunks.File?
  local file = item.item.file
  if file and file.status ~= "removed" and not hunks.is_shown(ctx.buf) then
    hunks.render_file(ctx.buf, file, ctx.win)
  else
    -- trouble shows the buffer without the autocommands redrawing it for
    -- the preview's window.
    hunks.redraw(ctx.buf, ctx.win)
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(ctx.win),
      once = true,
      desc = "Redraws the previewed buffer for the windows still showing it",
      callback = vim.schedule_wrap(function()
        if vim.api.nvim_buf_is_valid(ctx.buf) then hunks.redraw(ctx.buf) end
      end),
    })
  end
end

--- Moves the change under the cursor into another revision: the hunk, all of
--- the file's changes, or all the changes in the directory.
---@param ctx trouble.Action.ctx
---@param into string
M.move = function(ctx, into)
  local node = ctx.node
  if not node then return end

  if node:source() == "fs" then
    return hunks.move_files(files_of(node), into)
  end

  ---@type nvim_hunks.trouble.Entry?
  local entry = node.item and node.item.item --[[@as nvim_hunks.trouble.Entry?]]
  if not entry or not entry.file then return end
  if entry.hunk then
    hunks.move_hunk(entry.file, entry.hunk, into)
  else
    hunks.move_file(entry.file, into)
  end
end

local group =
  vim.api.nvim_create_augroup("nvim-hunks-trouble", { clear = true })

vim.api.nvim_create_autocmd("WinResized", {
  group = group,
  desc = "Keeps the recaps at the top-right corners of the lists of hunks",
  callback = function()
    for _, win in ipairs(vim.v.event.windows or {}) do
      if recaps[win] and vim.api.nvim_win_is_valid(win) then draw_recap(win) end
    end
  end,
})

vim.api.nvim_create_autocmd("WinClosed", {
  group = group,
  desc = "Stops showing all diffs once no list of hunks is open",
  -- The closed window is still valid while WinClosed runs, and trouble would
  -- refresh the list in it.
  callback = vim.schedule_wrap(function()
    for list_win, recap in pairs(recaps) do
      if not vim.api.nvim_win_is_valid(list_win) then
        if vim.api.nvim_win_is_valid(recap) then
          vim.api.nvim_win_close(recap, true)
        end
        recaps[list_win] = nil
      end
    end

    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local trouble = vim.w[win].trouble
      if trouble and trouble.mode == "hunks" then return end
    end
    roots = nil
    listed_files = {}
    listed = {}
    working_copy = nil
    if hunks.is_showing_all() then hunks.show_all(false) end
  end),
})

return M
