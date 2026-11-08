local diff = require("nvim_hunks.diff")
local float = require("nvim_hunks.float")
local jj = require("nvim_hunks.jj")
local render = require("nvim_hunks.render")

local M = {}

local uv = vim.uv

local attach_event = "NvimHunksAttach"
local changed_event = "NvimHunksChanged"
local detach_event = "NvimHunksDetach"

--- The delay between a change to a buffer and the diff it triggers.
local buffer_debounce_ms = 100

--- The delay between a jj operation and the reload of the bases it triggers.
local op_debounce_ms = 100

---@class nvim_hunks.Config
---@field base string The revision the buffers are diffed against.
---@field colors nvim_hunks.Colors The colors blended into the diff's backgrounds.
---@field library? string The path of libvscode-diff's shared library.

---@type nvim_hunks.Config
local config = {
  base = "@-",
  colors = { added = "#2ea043", deleted = "#f85149" },
  library = vim.env.LIBVSCODE_DIFF,
}

---@class nvim_hunks.Repo
---@field root string The root of the jj workspace.
---@field timer? uv.uv_timer_t
---@field watcher? uv.uv_fs_event_t

---@class nvim_hunks.Buffer
---@field base_lines? string[] The file's lines at the base revision, unset until they're loaded or when the file isn't tracked.
---@field hunks nvim_hunks.Hunk[]
---@field path string The file's path relative to the repo's root.
---@field repo nvim_hunks.Repo
---@field request integer The number of base loads started for the buffer.
---@field syntax? nvim_hunks.Syntax The syntax of the base lines.
---@field syntax_filetype? string The filetype the syntax was computed for.
---@field timer? uv.uv_timer_t

local enabled = false

---@type table<integer, nvim_hunks.Buffer>
local buffers = {}

---@type table<string, nvim_hunks.Repo>
local repos = {}

local enabled_group = "nvim-hunks-enabled"

---@param text string
---@return string[]
local split_lines = function(text)
  local lines = vim.split(text, "\n", { plain = true })
  if lines[#lines] == "" then lines[#lines] = nil end
  return lines
end

--- Returns the buffer's lines, with the single empty line of an empty buffer
--- counting as no lines.
---@param bufnr integer
---@return string[]
local buffer_lines = function(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if #lines == 1 and lines[1] == "" then return {} end
  return lines
end

---@param bufnr integer
---@param state nvim_hunks.Buffer
---@return nvim_hunks.Syntax
local syntax_of = function(bufnr, state)
  local filetype = vim.bo[bufnr].filetype
  if not state.syntax or state.syntax_filetype ~= filetype then
    state.syntax =
      render.syntax(table.concat(assert(state.base_lines), "\n"), filetype)
    state.syntax_filetype = filetype
  end
  return state.syntax
end

---@param bufnr integer
local update = function(bufnr)
  local state = buffers[bufnr]
  if not state or not vim.api.nvim_buf_is_valid(bufnr) then return end

  -- The floats cover the deleted lines of the hunks being replaced.
  for _, win in ipairs(float.of_buffer(bufnr)) do
    float.close(win)
  end

  if not state.base_lines then
    state.hunks = {}
    render.clear(bufnr)
  else
    local lines = buffer_lines(bufnr)
    state.hunks = diff.compute(state.base_lines, lines)

    local has_deletions = vim
      .iter(state.hunks)
      :any(function(hunk) return hunk.old_count > 0 end)
    local syntax = has_deletions and syntax_of(bufnr, state) or {}

    render.render(bufnr, state.hunks, state.base_lines, lines, syntax)
  end

  vim.api.nvim_exec_autocmds("User", {
    pattern = changed_event,
    modeline = false,
    data = { buf = bufnr },
  })
end

---@param bufnr integer
---@param state nvim_hunks.Buffer
local schedule_update = function(bufnr, state)
  state.timer = state.timer or assert(uv.new_timer())
  state.timer:start(
    buffer_debounce_ms,
    0,
    vim.schedule_wrap(function()
      if buffers[bufnr] == state then update(bufnr) end
    end)
  )
end

---@param bufnr integer
---@param state nvim_hunks.Buffer
---@param base_lines? string[]
local set_base = function(bufnr, state, base_lines)
  state.base_lines = base_lines
  state.syntax = nil
  update(bufnr)
end

---@param bufnr integer
local load_base = function(bufnr)
  local state = buffers[bufnr]
  if not state then return end

  state.request = state.request + 1
  local request = state.request

  ---@return boolean
  local is_current = function()
    return buffers[bufnr] == state and state.request == request
  end

  ---@param err string
  local notify = function(err)
    vim.notify(err, vim.log.levels.WARN, { title = "nvim-hunks" })
  end

  local root = state.repo.root

  jj.file_at(root, config.base, state.path, function(err, text)
    vim.schedule(function()
      if not is_current() then return end

      if err then
        notify(err)
      elseif text then
        set_base(bufnr, state, split_lines(text))
      else
        -- A file missing from the base was either added since, or isn't
        -- tracked at all.
        jj.is_tracked(root, state.path, function(tracked_err, tracked)
          vim.schedule(function()
            if not is_current() then return end
            if tracked_err then
              notify(tracked_err)
            else
              set_base(bufnr, state, tracked and {} or nil)
            end
          end)
        end)
      end
    end)
  end)
end

---@param repo nvim_hunks.Repo
local reload_repo = function(repo)
  for bufnr, state in pairs(buffers) do
    if state.repo == repo then load_base(bufnr) end
  end
end

---@param root string
---@return nvim_hunks.Repo
local repo_for = function(root)
  local repo = repos[root]
  if repo then return repo end

  repo = { root = root }
  repos[root] = repo

  local timer = assert(uv.new_timer())
  local watcher = assert(uv.new_fs_event())
  local ok = watcher:start(jj.op_heads_dir(root), {}, function()
    timer:start(
      op_debounce_ms,
      0,
      vim.schedule_wrap(function()
        if repos[root] == repo then reload_repo(repo) end
      end)
    )
  end)

  repo.timer = timer
  if ok then
    repo.watcher = watcher
  else
    watcher:close()
  end

  return repo
end

---@param repo nvim_hunks.Repo
local release_repo = function(repo)
  for _, state in pairs(buffers) do
    if state.repo == repo then return end
  end

  if repo.watcher then repo.watcher:close() end
  if repo.timer then repo.timer:close() end
  repos[repo.root] = nil
end

---@param bufnr integer
local detach = function(bufnr)
  local state = buffers[bufnr]
  if not state then return end

  buffers[bufnr] = nil
  if state.timer then state.timer:close() end
  release_repo(state.repo)
  for _, win in ipairs(float.of_buffer(bufnr)) do
    float.close(win)
  end
  if vim.api.nvim_buf_is_valid(bufnr) then render.clear(bufnr) end

  vim.api.nvim_exec_autocmds("User", {
    pattern = changed_event,
    modeline = false,
    data = { buf = bufnr },
  })
  vim.api.nvim_exec_autocmds("User", {
    pattern = detach_event,
    modeline = false,
    data = { buf = bufnr },
  })
end

---@param bufnr integer
local attach = function(bufnr)
  if
    not enabled
    or buffers[bufnr]
    or not vim.api.nvim_buf_is_loaded(bufnr)
    or vim.bo[bufnr].buftype ~= ""
  then
    return
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" or name:match("^%a[%w+.-]*://") then return end

  local path = uv.fs_realpath(name) or vim.fs.abspath(name)
  local root = jj.root(path)
  if not root then return end

  ---@type nvim_hunks.Buffer
  local state = {
    hunks = {},
    path = assert(vim.fs.relpath(root, path)),
    repo = repo_for(root),
    request = 0,
  }
  buffers[bufnr] = state

  local on_change = function()
    if buffers[bufnr] ~= state then return true end
    schedule_update(bufnr, state)
  end

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = on_change,
    on_reload = on_change,
    on_detach = function()
      vim.schedule(function()
        if buffers[bufnr] == state then detach(bufnr) end
      end)
    end,
  })

  vim.api.nvim_exec_autocmds("User", {
    pattern = attach_event,
    modeline = false,
    data = { buf = bufnr, float = false },
  })

  load_base(bufnr)
end

--- Starts showing the diffs of all the buffers of files in jj workspaces.
M.enable = function()
  if enabled then return end

  if not diff.is_loaded() then
    vim.notify(
      "libvscode-diff isn't loaded, see `setup()`'s `library` option",
      vim.log.levels.ERROR,
      { title = "nvim-hunks" }
    )
    return
  end
  enabled = true

  local group = vim.api.nvim_create_augroup(enabled_group, { clear = true })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = group,
    desc = "Shows the diff of the buffer",
    callback = function(ev) attach(ev.buf) end,
  })

  vim.api.nvim_create_autocmd("BufFilePost", {
    group = group,
    desc = "Shows the diff of the buffer's new file",
    callback = function(ev)
      detach(ev.buf)
      attach(ev.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    desc = "Redraws the diff to fit the gutter of the buffer's window",
    callback = function(ev)
      if buffers[ev.buf] then update(ev.buf) end
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    desc = "Forgets the diff of the buffer",
    callback = function(ev) detach(ev.buf) end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    desc = "Redraws the diffs with the new highlights",
    callback = function()
      for bufnr in pairs(buffers) do
        update(bufnr)
      end
    end,
  })

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    attach(bufnr)
  end
end

--- Stops showing the diffs.
M.disable = function()
  if not enabled then return end
  enabled = false

  vim.api.nvim_del_augroup_by_name(enabled_group)

  for bufnr in pairs(buffers) do
    detach(bufnr)
  end
end

M.toggle = function()
  if enabled then
    M.disable()
  else
    M.enable()
  end
end

---@return boolean
M.is_enabled = function() return enabled end

--- Returns the hunks of a buffer, or nothing if its diff isn't shown. The
--- returned hunks must not be modified.
---@param bufnr? integer Defaults to the current buffer.
---@return nvim_hunks.Hunk[]?
M.hunks = function(bufnr)
  if not bufnr or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
  local state = buffers[bufnr]
  return state and state.base_lines and state.hunks
end

--- Returns the number of lines added and deleted in a buffer, or nothing if
--- its diff isn't shown.
---@param bufnr? integer Defaults to the current buffer.
---@return { added: integer, deleted: integer }?
M.line_stats = function(bufnr)
  local hunks = M.hunks(bufnr)
  if not hunks then return nil end

  local stats = { added = 0, deleted = 0 }
  for _, hunk in ipairs(hunks) do
    stats.added = stats.added + hunk.new_count
    stats.deleted = stats.deleted + hunk.old_count
  end
  return stats
end

--- Moves the cursor to the start of the next hunk in the current buffer, or
--- of the previous one if the count is negative.
---@param count integer
M.goto_hunk = function(count)
  local hunks = M.hunks() or {}
  local targets = vim
    .iter(hunks)
    :map(function(hunk) return math.max(hunk.new_start, 1) end)
    :totable()
  if count < 0 then targets = vim.iter(targets):rev():totable() end

  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local target
  local remaining = math.abs(count)
  for _, line in ipairs(targets) do
    if count > 0 and line > cursor or count < 0 and line < cursor then
      target = line
      remaining = remaining - 1
      if remaining == 0 then break end
    end
  end

  if target then vim.api.nvim_win_set_cursor(0, { target, 0 }) end
end

---@param message string
local notify_error = function(message)
  vim.notify(message, vim.log.levels.ERROR, { title = "nvim-hunks" })
end

--- Returns the hunk whose deleted lines are displayed right after the given
--- 1-based buffer line, or right before the first line if it's 0.
---@param bufnr integer
---@param line integer
---@return nvim_hunks.Hunk?
local hunk_deleted_after = function(bufnr, line)
  local line_count = #buffer_lines(bufnr)
  for _, hunk in ipairs(M.hunks(bufnr) or {}) do
    if hunk.old_count > 0 then
      local row, above = render.deleted_anchor(hunk, line_count)
      if (above and row or row + 1) == line then return hunk end
    end
  end
end

---@param win integer
---@param bufnr integer
---@param hunk nvim_hunks.Hunk
---@return integer?
local open_float = function(win, bufnr, hunk)
  local state = assert(buffers[bufnr])
  return float.open(
    win,
    bufnr,
    hunk,
    assert(state.base_lines),
    syntax_of(bufnr, state),
    #buffer_lines(bufnr)
  )
end

--- Returns the old lines with the selected lines of the hunks applied, i.e.
--- with the selected old lines deleted and the selected new lines added.
---@param old_lines string[]
---@param new_lines string[]
---@param hunks nvim_hunks.Hunk[]
---@param selected_old table<integer, true>
---@param selected_new table<integer, true>
---@return string[]
local apply = function(old_lines, new_lines, hunks, selected_old, selected_new)
  local lines = {}
  local next_old = 1

  for _, hunk in ipairs(hunks) do
    local first_old = hunk.old_count > 0 and hunk.old_start
      or hunk.old_start + 1
    for line = next_old, first_old - 1 do
      lines[#lines + 1] = old_lines[line]
    end
    for line = first_old, first_old + hunk.old_count - 1 do
      if not selected_old[line] then lines[#lines + 1] = old_lines[line] end
    end
    for line = hunk.new_start, hunk.new_start + hunk.new_count - 1 do
      if selected_new[line] then lines[#lines + 1] = new_lines[line] end
    end
    next_old = first_old + hunk.old_count
  end

  for line = next_old, #old_lines do
    lines[#lines + 1] = old_lines[line]
  end
  return lines
end

--- Opens a float over each block of deleted lines displayed in the window,
--- without entering them, and returns their windows.
---@param win? integer Defaults to the current window.
---@return integer[]
M.open_floats = function(win)
  win = win or vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(win)
  local first = vim.fn.line("w0", win)
  local last = vim.fn.line("w$", win)
  local line_count = #buffer_lines(bufnr)

  local wins = {}
  for _, hunk in ipairs(M.hunks(bufnr) or {}) do
    if hunk.old_count > 0 then
      local row = render.deleted_anchor(hunk, line_count)
      if row + 1 >= first and row + 1 <= last then
        wins[#wins + 1] = open_float(win, bufnr, hunk)
      end
    end
  end
  return wins
end

--- Makes a float the current window, closing it once the cursor leaves it.
---@param win integer
M.enter_float = function(win) float.enter(win) end

---@param win integer
M.close_float = function(win) float.close(win) end

--- Moves the cursor by `v:count1` lines by running the given keys, stepping
--- into the float of the deleted lines it would otherwise skip over, or out
--- of the current float when moving past its edge. Only single-line moves
--- step into or out of floats.
---@param direction 1|-1
---@param keys string The keys moving the cursor by one line, e.g. `j`.
M.step = function(direction, keys)
  local count = vim.v.count1
  local win = vim.api.nvim_get_current_win()
  local motion = count
    .. vim.api.nvim_replace_termcodes(keys, true, false, true)
  local run = function() vim.cmd.normal({ args = { motion }, bang = true }) end

  if float.get(win) then
    local line = vim.api.nvim_win_get_cursor(win)[1]
    local at_edge = direction > 0 and line == vim.api.nvim_buf_line_count(0)
      or direction < 0 and line == 1
    if count == 1 and at_edge and float.exit(win, direction) then return end
    return run()
  end

  local bufnr = vim.api.nvim_get_current_buf()
  if count > 1 or not M.hunks(bufnr) then return run() end

  local view = vim.fn.winsaveview()
  run()
  -- The motion can move past the next line when `scrolloff` can't be honored
  -- around tall deleted lines, so only whether it left the line counts.
  local line = vim.api.nvim_win_get_cursor(win)[1]
  if (line - view.lnum) * direction <= 0 then return end

  local after = direction > 0 and view.lnum or view.lnum - 1
  local hunk = hunk_deleted_after(bufnr, after)
  if not hunk then return end

  if direction < 0 then vim.fn.winrestview(view) end
  float.reveal(win, hunk, #buffer_lines(bufnr), direction > 0)
  local float_win = open_float(win, bufnr, hunk)
  if not float_win then
    if direction < 0 then run() end
    return
  end

  float.enter(float_win, {
    line = direction > 0 and 1 or hunk.old_count,
    virtcol = view.curswant + 1,
  })
end

--- Moves changes from the working-copy commit into another revision: the
--- lines selected in visual mode, or else the whole hunk under the cursor.
--- In a float, the selected lines are deleted ones. Returns false without
--- doing anything if the buffer's diff isn't shown or, outside of visual mode
--- and floats, if the cursor isn't on a hunk.
---@param into string A revset resolving to a single revision, e.g. `@-`.
---@return boolean
M.move = function(into)
  local mode = vim.fn.mode()
  local range
  if mode == "v" or mode == "V" or mode == "\22" then
    local first, last = vim.fn.line("v"), vim.fn.line(".")
    range = { math.min(first, last), math.max(first, last) }
    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    vim.api.nvim_feedkeys(esc, "nx", false)
  end

  local win = vim.api.nvim_get_current_win()
  local current_float = float.get(win)
  local bufnr = current_float and current_float.buf
    or vim.api.nvim_get_current_buf()
  local state = buffers[bufnr]
  if not state or not state.base_lines then return false end

  ---@type table<integer, true>, table<integer, true>
  local selected_old, selected_new = {}, {}
  ---@param hunk nvim_hunks.Hunk
  local select_hunk = function(hunk)
    for line = hunk.old_start, hunk.old_start + hunk.old_count - 1 do
      selected_old[line] = true
    end
    for line = hunk.new_start, hunk.new_start + hunk.new_count - 1 do
      selected_new[line] = true
    end
  end

  if current_float and range then
    for line = range[1], range[2] do
      selected_old[current_float.hunk.old_start + line - 1] = true
    end
  elseif current_float then
    select_hunk(current_float.hunk)
  elseif range then
    for line = range[1], range[2] do
      selected_new[line] = true
    end
  else
    local line = vim.api.nvim_win_get_cursor(win)[1]
    local hunk = vim.iter(state.hunks):find(
      function(hunk)
        return line >= hunk.new_start and line < hunk.new_start + hunk.new_count
      end
    )
    if not hunk then return false end
    select_hunk(hunk)
  end

  if vim.bo[bufnr].modified then
    notify_error("Save the buffer first")
    return true
  end

  local base_lines = state.base_lines
  local lines = apply(
    base_lines,
    buffer_lines(bufnr),
    state.hunks,
    selected_old,
    selected_new
  )
  if vim.deep_equal(lines, base_lines) then
    notify_error("The selection doesn't contain any changes")
    return true
  end
  local text = #lines > 0 and table.concat(lines, "\n") .. "\n" or ""

  local root, path = state.repo.root, state.path
  jj.resolve(root, into, function(resolve_err, change_ids)
    vim.schedule(function()
      if resolve_err then return notify_error(resolve_err) end
      local count = #assert(change_ids)
      if count ~= 1 then
        return notify_error(
          count == 0 and ("`%s` doesn't resolve to any revision"):format(into)
            or ("`%s` resolves to %d revisions"):format(into, count)
        )
      end

      jj.squash_file(root, into, path, text, function(squash_err)
        vim.schedule(function()
          if squash_err then return notify_error(squash_err) end
          if current_float then float.close(win) end
          -- Moving changes into a descendant takes them out of the files on
          -- disk.
          if vim.api.nvim_buf_is_valid(bufnr) then vim.cmd.checktime(bufnr) end
        end)
      end)
    end)
  end)

  return true
end

---@param opts? { base?: string, colors?: nvim_hunks.Colors, library?: string }
M.setup = function(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  if config.library and not diff.is_loaded() then
    local ok, err = pcall(diff.load, config.library)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR, { title = "nvim-hunks" })
    end
  end

  render.set_highlights(config.colors)

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("nvim-hunks", { clear = true }),
    desc = "Defines the default diff highlights for the new color scheme",
    callback = function() render.set_highlights(config.colors) end,
  })
end

return M
