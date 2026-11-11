local M = {}

local uv = vim.uv

---@class nvim_threads.Edit
---@field path string The edited file's path relative to the workspace's root.
---@field old_text string The text replaced, which occurs exactly once in the file.
---@field new_text string
---@field resolution? "applied"|"rejected" Whether the edit was applied or rejected.

---@class nvim_threads.Comment
---@field author string `me`, or a participant's name.
---@field body string
---@field time integer The Unix time the comment was made at.
---@field edits? nvim_threads.Edit[] The edits the comment suggests.
---@field applied? table<string, true> The paths whose suggested edits were all applied, in comments saved before the edits had resolutions.
---@field error? boolean Whether the body is a participant's error.

--- A range in a file's lines, with 0-based rows and byte columns, whose end
--- is exclusive.
---@class nvim_threads.Anchor
---@field start_row integer
---@field start_col integer
---@field end_row integer
---@field end_col integer

---@class nvim_threads.Thread
---@field id string
---@field anchor nvim_threads.Anchor
---@field title? string
---@field comments nvim_threads.Comment[]
---@field participants string[] The names of the participants mentioned so far.
---@field outdated? boolean Whether the anchored text was replaced entirely.

--- A file's threads in a change.
---@class nvim_threads.Entry
---@field snapshot string[] The file's lines the anchors are ranges in.
---@field threads nvim_threads.Thread[]

--- A change's threads, keyed by the paths of their files relative to the
--- workspace's root.
---@class nvim_threads.Change
---@field files table<string, nvim_threads.Entry?>

--- The changes loaded so far, keyed by their repo's directory and then by
--- their change IDs.
---@type table<string, table<string, nvim_threads.Change?>?>
local changes = {}

---@param repo_dir string
---@param change_id string
---@return string
local file_of = function(repo_dir, change_id)
  return vim.fs.joinpath(repo_dir, "nvim-threads", change_id .. ".json")
end

--- Returns a change's threads, read from disk the first time.
---@param repo_dir string The `.jj/repo` directory of the change's repo.
---@param change_id string
---@return nvim_threads.Change
M.load = function(repo_dir, change_id)
  changes[repo_dir] = changes[repo_dir] or {}
  local change = changes[repo_dir][change_id]
  if change then return change end

  change = { files = {} }
  local file = io.open(file_of(repo_dir, change_id), "r")
  if file then
    local text = file:read("*a") or ""
    file:close()
    local ok, decoded = pcall(function() return vim.json.decode(text) end)
    if ok and type(decoded) == "table" and type(decoded.files) == "table" then
      change = decoded --[[@as nvim_threads.Change]]
    else
      vim.notify(
        ("Couldn't read the threads of %s"):format(change_id),
        vim.log.levels.WARN,
        { title = "nvim-threads" }
      )
    end
  end

  changes[repo_dir][change_id] = change
  return change
end

--- Returns a file's threads in a change, creating its entry if it has none.
---@param repo_dir string
---@param change_id string
---@param path string
---@param lines string[] The file's lines, which a new entry's anchors are ranges in.
---@return nvim_threads.Entry
M.entry = function(repo_dir, change_id, path, lines)
  local change = M.load(repo_dir, change_id)
  local entry = change.files[path]
  if not entry then
    entry = { snapshot = lines, threads = {} }
    change.files[path] = entry
  end
  return entry
end

--- Writes a change's threads to disk, or deletes its file once it has none.
--- Threads without comments yet are left out.
---@param repo_dir string
---@param change_id string
M.save = function(repo_dir, change_id)
  local change = M.load(repo_dir, change_id)
  ---@type nvim_threads.Change
  local saved = { files = {} }
  for path, entry in pairs(change.files) do
    local threads = vim.tbl_filter(
      function(thread) return #thread.comments > 0 end,
      entry.threads
    )
    if #threads > 0 then
      saved.files[path] = { snapshot = entry.snapshot, threads = threads }
    elseif #entry.threads == 0 then
      change.files[path] = nil
    end
  end

  local path = file_of(repo_dir, change_id)
  if next(saved.files) == nil then
    uv.fs_unlink(path)
    return
  end

  vim.fn.mkdir(vim.fs.dirname(path), "p")
  -- Renaming a complete file over the old one never leaves a partial one.
  local tmp = path .. ".tmp"
  local file = assert(io.open(tmp, "w"))
  file:write(vim.json.encode(saved))
  file:close()
  assert(uv.fs_rename(tmp, path))
end

--- A hunk of a line diff, as the 1-based first old line, the number of old
--- lines, the first new line and the number of new lines. A side without
--- lines starts after the line it names.
---@alias nvim_threads.DiffHunk [integer, integer, integer, integer]

--- Returns the hunks turning some lines into others.
---@param a string[]
---@param b string[]
---@return nvim_threads.DiffHunk[]
M.diff = function(a, b)
  if #a == 0 and #b == 0 then return {} end
  ---@diagnostic disable-next-line: deprecated
  local diff = vim.text.diff or vim.diff
  local result = diff(
    table.concat(a, "\n") .. "\n",
    table.concat(b, "\n") .. "\n",
    { result_type = "indices", algorithm = "histogram" }
  )
  return result --[[@as nvim_threads.DiffHunk[] ]]
end

--- Returns the 1-based line of the new lines a line of the old ones became,
--- and the hunk replacing it if it was changed, in which case the line is
--- the first one of its replacement.
---@param hunks nvim_threads.DiffHunk[]
---@param line integer
---@return integer
---@return nvim_threads.DiffHunk? hunk
local map_line = function(hunks, line)
  local delta = 0
  for _, hunk in ipairs(hunks) do
    -- A hunk without lines on a side starts after the line it names there.
    local old_first = hunk[2] > 0 and hunk[1] or hunk[1] + 1
    local new_first = hunk[4] > 0 and hunk[3] or hunk[3] + 1
    if line < old_first then break end
    if line < old_first + hunk[2] then return new_first, hunk end
    delta = (new_first + hunk[4]) - (old_first + hunk[2])
  end
  return line + delta
end

--- Returns an anchor moved from the old lines to the new ones, and whether
--- its text was replaced entirely.
---@param anchor nvim_threads.Anchor
---@param hunks nvim_threads.DiffHunk[]
---@param lines string[] The new lines.
---@return nvim_threads.Anchor
---@return boolean outdated
M.map_anchor = function(anchor, hunks, lines)
  local start_line, start_hunk = map_line(hunks, anchor.start_row + 1)
  local end_line, end_hunk = map_line(hunks, anchor.end_row + 1)

  local start_row, start_col = start_line - 1, anchor.start_col
  local end_row, end_col = end_line - 1, anchor.end_col
  if start_hunk then start_col = 0 end
  if end_hunk then
    -- The anchor ends with the lines replacing its last one, or before the
    -- lines that follow deleted ones.
    end_row = end_line + end_hunk[4] - 2
    end_col = #(lines[end_row + 1] or "")
  end

  local outdated = start_hunk ~= nil and start_hunk == end_hunk
  if outdated and end_row < start_row then
    -- Without any lines replacing them, the anchor shrinks to the start of
    -- the line after them.
    end_row, end_col = start_row, 0
  end

  local last_row = math.max(#lines - 1, 0)
  ---@param row integer
  ---@param col integer
  ---@return integer, integer
  local clamp = function(row, col)
    if row > last_row then return last_row, #(lines[last_row + 1] or "") end
    row = math.max(row, 0) --[[@as integer]]
    return row, math.min(col, #(lines[row + 1] or "")) --[[@as integer]]
  end
  start_row, start_col = clamp(start_row, start_col)
  end_row, end_col = clamp(end_row, end_col)
  if end_row < start_row or (end_row == start_row and end_col < start_col) then
    end_row, end_col = start_row, start_col
  end

  return {
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
  },
    outdated
end

--- Moves an entry's anchors from its snapshot to the given lines, which
--- become its snapshot.
---@param entry nvim_threads.Entry
---@param lines string[]
M.remap = function(entry, lines)
  if vim.deep_equal(entry.snapshot, lines) then return end
  local hunks = M.diff(entry.snapshot, lines)
  for _, thread in ipairs(entry.threads) do
    local anchor, outdated = M.map_anchor(thread.anchor, hunks, lines)
    thread.anchor = anchor
    if outdated then thread.outdated = true end
  end
  entry.snapshot = lines
end

return M
