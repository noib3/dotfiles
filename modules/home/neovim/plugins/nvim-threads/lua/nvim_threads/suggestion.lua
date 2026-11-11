local store = require("nvim_threads.store")

local M = {}

local suggestion_event = "NvimThreadsSuggestion"

---@param message string
local notify_error = function(message)
  vim.notify(message, vim.log.levels.ERROR, { title = "nvim-threads" })
end

--- Returns the loaded buffer of the file at the given absolute path.
---@param path string
---@return integer?
local buffer_of = function(path)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_loaded(bufnr)
      and vim.api.nvim_buf_get_name(bufnr) == path
    then
      return bufnr
    end
  end
end

--- Returns the lines of the file at the given absolute path, taken from its
--- buffer if it's loaded.
---@param path string
---@return string[]?
M.read_lines = function(path)
  local bufnr = buffer_of(path)
  if bufnr then return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false) end
  local file = io.open(path, "rb")
  if not file then return end
  local text = file:read("*a")
  file:close()
  local lines = vim.split(text, "\n", { plain = true })
  if lines[#lines] == "" and #lines > 1 then lines[#lines] = nil end
  return lines
end

--- Returns the lines with the edits applied one after the other, or why one
--- of them can't be.
---@param lines string[]
---@param edits nvim_threads.Edit[]
---@return string[]? lines
---@return string? err
M.apply_edits = function(lines, edits)
  local text = table.concat(lines, "\n")
  for _, edit in ipairs(edits) do
    local count, from, at = 0, 1, nil
    while true do
      local found = text:find(edit.old_text, from, true)
      if not found then break end
      count = count + 1
      at = at or found
      from = found + math.max(#edit.old_text, 1)
    end
    if count == 0 then
      return nil,
        ("The text an edit replaces isn't in %s anymore"):format(edit.path)
    elseif count > 1 then
      return nil,
        ("The text an edit replaces occurs %d times in %s"):format(
          count,
          edit.path
        )
    end
    ---@cast at integer
    text = text:sub(1, at - 1) .. edit.new_text .. text:sub(at + #edit.old_text)
  end
  return vim.split(text, "\n", { plain = true })
end

--- The diffs of nvim-hunks, when it's installed. Without it, the edits are
--- listed without their diffs.
local ok_view, view = pcall(require, "nvim_hunks.view")

--- The diff of one of the edits a comment suggests.
---@class nvim_threads.EditDiff
---@field index integer The edit's index in the comment's edits.
--- Whether the edit is still to apply, was applied or rejected, or matches
--- neither the file nor the file with it applied, in which case its lines
--- aren't numbered.
---@field state "pending"|"applied"|"rejected"|"outdated"
---@field line? integer The 1-based line of the file the edit starts at.
---@field hunks nvim_hunks.view.Line[][] The changed lines with their context, if nvim-hunks is installed.
---@field old_lines? string[] The file's lines without the edit, which the diff's highlights are those of.
---@field new_lines? string[] The file's lines with the edit.

---@class nvim_threads.FileDiff
---@field path string The file's path relative to the workspace's root.
---@field edits nvim_threads.EditDiff[]

--- Returns lines with their tabs expanded.
---@param lines string[]
---@return string[]
local expand_tabs = function(lines)
  return vim.tbl_map(function(line) return (line:gsub("\t", "    ")) end, lines)
end

--- Returns the 1-based line a text starts at in lines, if it's in them.
---@param lines string[]
---@param text string
---@return integer?
local line_of_text = function(lines, text)
  local at = table.concat(lines, "\n"):find(text, 1, true)
  if not at then return end
  local _, newlines = table.concat(lines, "\n"):sub(1, at - 1):gsub("\n", "")
  return newlines + 1
end

--- Returns the diff of an edit against a file's lines, which have it applied
--- if it was.
---@param path string
---@param lines string[]
---@param edit nvim_threads.Edit
---@param index integer
---@param resolution? "applied"|"rejected"
---@return nvim_threads.EditDiff
local edit_diff = function(path, lines, edit, index, resolution)
  ---@type string[]?, string[]?
  local old, new
  if resolution == "applied" then
    old = M.apply_edits(lines, {
      { path = path, old_text = edit.new_text, new_text = edit.old_text },
    })
    new = old and lines
  else
    new = M.apply_edits(lines, { edit })
    old = new and lines
  end
  local line = line_of_text(
    lines,
    resolution == "applied" and edit.new_text or edit.old_text
  )

  if not old or not new then
    -- The edit alone, without the file's lines or numbers.
    local hunks = {}
    if ok_view then
      local all = {}
      for _, hunk in
        ipairs(
          view.hunks(
            expand_tabs(vim.split(edit.old_text, "\n", { plain = true })),
            expand_tabs(vim.split(edit.new_text, "\n", { plain = true }))
          )
        )
      do
        for _, diff_line in ipairs(hunk) do
          diff_line.old, diff_line.new = nil, nil
          all[#all + 1] = diff_line
        end
      end
      hunks = { all }
    end
    return {
      index = index,
      state = resolution or "outdated",
      line = line,
      hunks = hunks,
    }
  end

  old, new = expand_tabs(old), expand_tabs(new)
  return {
    index = index,
    state = resolution or "pending",
    line = line,
    hunks = ok_view and view.hunks(old, new) or {},
    old_lines = old,
    new_lines = new,
  }
end

--- Returns a string that changes whenever the file at an absolute path does.
---@param path string
---@return string
local version_of = function(path)
  local bufnr = buffer_of(path)
  if bufnr then return "b" .. vim.api.nvim_buf_get_changedtick(bufnr) end
  local stat = vim.uv.fs_stat(path)
  if not stat then return "-" end
  return ("f%d.%d.%d"):format(stat.mtime.sec, stat.mtime.nsec, stat.size)
end

--- The diffs computed so far, by comment, with the versions of their files
--- and the edits' resolutions.
---@type table<nvim_threads.Comment, { key: string, diffs: nvim_threads.FileDiff[] }?>
local diffs_cache = setmetatable({}, { __mode = "k" })

--- Returns a comment's suggested edits grouped by file, in the order of the
--- files' first edits, with their indices.
---@param edits nvim_threads.Edit[]
---@return string[] paths
---@return table<string, integer[]> by_path
local by_file = function(edits)
  local paths, by_path = {}, {}
  for index, edit in ipairs(edits) do
    if not by_path[edit.path] then
      by_path[edit.path] = {}
      paths[#paths + 1] = edit.path
    end
    table.insert(by_path[edit.path], index)
  end
  return paths, by_path
end

--- Returns whether an edit a comment suggests was applied or rejected.
---@param comment nvim_threads.Comment
---@param edit nvim_threads.Edit
---@return "applied"|"rejected"|nil
M.resolution = function(comment, edit)
  if edit.resolution then return edit.resolution end
  -- Comments saved before the edits had resolutions record the applied
  -- files.
  if comment.applied and comment.applied[edit.path] then return "applied" end
end

--- Returns the diffs of the edits a comment suggests, one per file.
---@param root string The root of the workspace.
---@param comment nvim_threads.Comment
---@return nvim_threads.FileDiff[]
M.diffs = function(root, comment)
  local edits = comment.edits or {}
  local paths, by_path = by_file(edits)
  local keys = {}
  for _, path in ipairs(paths) do
    keys[#keys + 1] = path .. ":" .. version_of(vim.fs.joinpath(root, path))
  end
  for _, edit in ipairs(edits) do
    keys[#keys + 1] = M.resolution(comment, edit) or "-"
  end
  local key = table.concat(keys, "\0")
  local cached = diffs_cache[comment]
  if cached and cached.key == key then return cached.diffs end

  local diffs = {}
  for _, path in ipairs(paths) do
    local lines = M.read_lines(vim.fs.joinpath(root, path)) or {}
    local file = { path = path, edits = {} }
    for _, index in ipairs(by_path[path]) do
      local edit = assert(edits[index])
      table.insert(
        file.edits,
        edit_diff(path, lines, edit, index, M.resolution(comment, edit))
      )
    end
    diffs[#diffs + 1] = file
  end
  diffs_cache[comment] = { key = key, diffs = diffs }
  return diffs
end

--- Returns the 0-based row and byte column of a byte offset into lines
--- joined by newlines.
---@param lines string[]
---@param offset integer The 0-based offset.
---@return integer row
---@return integer col
local position_of = function(lines, offset)
  for index, line in ipairs(lines) do
    if offset <= #line then return index - 1, offset end
    offset = offset - #line - 1
  end
  return math.max(#lines - 1, 0), #(lines[#lines] or "")
end

--- Replaces a buffer's lines with new ones, one hunk at a time, and only the
--- text between the hunk's common start and end, so that the marks outside
--- of what changed stay where they are.
---@param bufnr integer
---@param lines string[]
local replace_lines = function(bufnr, lines)
  local old = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local hunks = store.diff(old, lines)
  for index = #hunks, 1, -1 do
    local hunk = hunks[index]
    local new_lines = vim.list_slice(lines, hunk[3], hunk[3] + hunk[4] - 1)
    if hunk[2] == 0 or hunk[4] == 0 then
      -- A hunk without old lines inserts after the line it names.
      local start = hunk[2] > 0 and hunk[1] - 1 or hunk[1]
      vim.api.nvim_buf_set_lines(
        bufnr,
        start,
        start + hunk[2],
        false,
        new_lines
      )
    else
      local old_lines = vim.list_slice(old, hunk[1], hunk[1] + hunk[2] - 1)
      local old_text = table.concat(old_lines, "\n")
      local new_text = table.concat(new_lines, "\n")
      local prefix = 0
      local shortest = math.min(#old_text, #new_text)
      while
        prefix < shortest
        and old_text:byte(prefix + 1) == new_text:byte(prefix + 1)
      do
        prefix = prefix + 1
      end
      local suffix = 0
      while
        suffix < shortest - prefix
        and old_text:byte(#old_text - suffix)
          == new_text:byte(#new_text - suffix)
      do
        suffix = suffix + 1
      end
      local start_row, start_col = position_of(old_lines, prefix)
      local end_row, end_col = position_of(old_lines, #old_text - suffix)
      local replacement = new_text:sub(prefix + 1, #new_text - suffix)
      vim.api.nvim_buf_set_text(
        bufnr,
        hunk[1] - 1 + start_row,
        start_col,
        hunk[1] - 1 + end_row,
        end_col,
        vim.split(replacement, "\n", { plain = true })
      )
    end
  end
end

--- Replaces the lines of the buffer of the file at an absolute path, loading
--- it if it isn't, and saves it if it had no unsaved changes. Returns the
--- buffer and its first changed line.
---@param path string
---@param lines string[]
---@return integer bufnr
---@return integer? first_changed
M.write = function(path, lines)
  local target = vim.fn.bufadd(path)
  vim.fn.bufload(target)
  vim.bo[target].buflisted = true
  local was_modified = vim.bo[target].modified

  ---@type integer?
  local first_changed
  local old = vim.api.nvim_buf_get_lines(target, 0, -1, false)
  for index = 1, math.max(#old, #lines) do
    if old[index] ~= lines[index] then
      first_changed = index
      break
    end
  end

  replace_lines(target, lines)
  if not was_modified then
    vim.api.nvim_buf_call(target, function() vim.cmd("silent write") end)
  end
  return target, first_changed
end

--- Returns the lines of a file with some of the edits a comment suggests
--- applied, in order, or why they can't be.
---@param root string
---@param comment nvim_threads.Comment
---@param indices integer[] The edits' indices.
---@return string[]? lines
---@return string? err
M.edited_lines = function(root, comment, indices)
  local all = comment.edits or {}
  ---@type nvim_threads.Edit[]
  local edits = vim.tbl_map(
    function(index) return assert(all[index]) end,
    indices
  )
  local path = assert(edits[1]).path
  local lines = M.read_lines(vim.fs.joinpath(root, path)) or {}
  return M.apply_edits(lines, edits)
end

---@class nvim_threads.Review
---@field root string
---@field thread_id string
---@field comment integer The index of the comment suggesting the edits.
---@field edits nvim_threads.Edit[]
---@field on_applied fun(path: string)

--- Applies a suggestion buffer's lines to its file's buffer, which is saved
--- if it didn't have unsaved changes, then shows that buffer in the
--- suggestion's windows.
---@param buf integer
---@param abs_path string
---@param on_applied fun()
local apply = function(buf, abs_path, on_applied)
  local target, first_changed =
    M.write(abs_path, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  vim.bo[buf].modified = false
  on_applied()

  -- Hiding the suggestion's buffer wipes it, which can't happen while it's
  -- being written.
  vim.schedule(function()
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      vim.api.nvim_win_set_buf(win, target)
      if first_changed then
        local line =
          math.min(first_changed, vim.api.nvim_buf_line_count(target))
        vim.api.nvim_win_set_cursor(win, { line, 0 })
      end
    end
  end)
end

--- Opens a buffer for each file a comment suggests edits to, holding the
--- file's lines with the edits applied. Writing one applies its lines to the
--- file. The first one is shown in the current window, and the others in
--- splits below it.
---@param review nvim_threads.Review
M.open = function(review)
  local paths, by_path = {}, {}
  for _, edit in ipairs(review.edits) do
    if not by_path[edit.path] then
      by_path[edit.path] = {}
      paths[#paths + 1] = edit.path
    end
    table.insert(by_path[edit.path], edit)
  end

  local shown = 0
  for _, path in ipairs(paths) do
    local abs_path = vim.fs.joinpath(review.root, path)
    local base = M.read_lines(abs_path) or {}
    local lines, err = M.apply_edits(base, by_path[path])
    if not lines then
      notify_error(assert(err))
    else
      local name = ("nvim-threads://%s/%d/%s"):format(
        review.thread_id,
        review.comment,
        path
      )
      local existing = vim.fn.bufnr(name)
      local buf = existing ~= -1 and existing
        or vim.api.nvim_create_buf(true, false)
      if existing == -1 then vim.api.nvim_buf_set_name(buf, name) end
      vim.bo[buf].buftype = "acwrite"
      vim.bo[buf].bufhidden = "wipe"
      vim.bo[buf].swapfile = false
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].modified = false
      vim.bo[buf].filetype = vim.filetype.match({ filename = path }) or ""

      vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        desc = "Applies the suggested edits to the file",
        callback = function()
          apply(buf, abs_path, function() review.on_applied(path) end)
        end,
      })

      if shown == 0 then
        vim.api.nvim_win_set_buf(0, buf)
      else
        vim.cmd.sbuffer(buf)
      end
      shown = shown + 1

      vim.api.nvim_exec_autocmds("User", {
        pattern = suggestion_event,
        modeline = false,
        data = { buf = buf, base = base, root = review.root, path = path },
      })
    end
  end
end

return M
