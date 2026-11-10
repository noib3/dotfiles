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

--- Replaces a buffer's lines with new ones, one hunk at a time, so that the
--- marks on unchanged lines stay where they are.
---@param bufnr integer
---@param lines string[]
local replace_lines = function(bufnr, lines)
  local old = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local hunks = store.diff(old, lines)
  for index = #hunks, 1, -1 do
    local hunk = hunks[index]
    -- A hunk without old lines inserts after the line it names.
    local start = hunk[2] > 0 and hunk[1] - 1 or hunk[1]
    vim.api.nvim_buf_set_lines(
      bufnr,
      start,
      start + hunk[2],
      false,
      vim.list_slice(lines, hunk[3], hunk[3] + hunk[4] - 1)
    )
  end
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
  local target = vim.fn.bufadd(abs_path)
  vim.fn.bufload(target)
  vim.bo[target].buflisted = true
  local was_modified = vim.bo[target].modified
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

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
  ---@type string[], table<string, nvim_threads.Edit[]>
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
