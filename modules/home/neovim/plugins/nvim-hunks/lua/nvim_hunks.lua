local diff = require("nvim_hunks.diff")
local float = require("nvim_hunks.float")
local jj = require("nvim_hunks.jj")
local render = require("nvim_hunks.render")

local M = {}

local uv = vim.uv

local attach_event = "NvimHunksAttach"
local changed_event = "NvimHunksChanged"
local detach_event = "NvimHunksDetach"
local files_changed_event = "NvimHunksFilesChanged"

--- The delay between a change to a buffer and the diff it triggers.
local buffer_debounce_ms = 100

--- The delay between a jj operation and the reload of the bases it triggers.
local op_debounce_ms = 100

--- A file's base is its contents in the working-copy commit's parents,
--- merged like `jj diff` merges them.

---@class nvim_hunks.Config
---@field colors nvim_hunks.Colors The colors blended into the diff's backgrounds.
---@field library? string The path of libvscode-diff's shared library.

---@type nvim_hunks.Config
local config = {
  colors = {
    added = "#2ea043",
    deleted = "#f85149",
    modified = "#d29922",
    renamed = "#4493f8",
  },
  library = vim.env.LIBVSCODE_DIFF,
}

---@class nvim_hunks.Repo
---@field root string The root of the jj workspace.
---@field timer? uv.uv_timer_t
---@field watcher? uv.uv_fs_event_t

---@class nvim_hunks.Buffer
---@field base_lines? string[] The file's lines in the base, unset until they're loaded or when the file isn't tracked.
---@field base_eol? boolean Whether the file ends with a newline in the base.
---@field hunks nvim_hunks.Hunk[]
---@field old_path? string The file's path in the base if it was renamed since.
---@field path string The file's path relative to the repo's root.
---@field repo nvim_hunks.Repo
---@field request integer The number of base loads started for the buffer.
---@field syntax? nvim_hunks.Syntax The syntax of the base lines.
---@field syntax_filetype? string The filetype the syntax was computed for.
---@field top_deleted? integer The number of deleted lines above the buffer's first line.
---@field timer? uv.uv_timer_t

--- Whether the buffers of all files in jj workspaces show their diffs.
local showing_all = false

--- The buffers whose diffs were turned on individually.
---@type table<integer, true?>
local turned_on = {}

--- The buffers whose diffs were turned off individually while all diffs were
--- shown.
---@type table<integer, true?>
local turned_off = {}

---@type table<integer, nvim_hunks.Buffer?>
local buffers = {}

---@type table<string, nvim_hunks.Repo?>
local repos = {}

--- The roots of the repos whose changed files were listed while all diffs
--- are shown.
---@type table<string, true?>
local listed_roots = {}

---@class nvim_hunks.DeletedBuffer
---@field root string
---@field path string The deleted file's path relative to the root.

--- The bases of the changed files listed so far, keyed by workspace root
--- and then by path. A workspace's are dropped after each of its jj
--- operations.
---@type table<string, table<string, string?>?>
local base_texts = {}

--- The changed files listed so far, keyed by workspace root and then by
--- path. A workspace's are dropped after each of its jj operations.
---@type table<string, table<string, nvim_hunks.File?>?>
local listed_files = {}

--- The buffers displaying deleted files.
---@type table<integer, nvim_hunks.DeletedBuffer?>
local deleted_buffers = {}

---@param pattern string
---@param data? table
local fire = function(pattern, data)
  vim.api.nvim_exec_autocmds("User", {
    pattern = pattern,
    modeline = false,
    data = data,
  })
end

--- Returns whether a file's text ends with a newline, which its lines leave
--- out. An empty file counts as ending with one.
---@param text string
---@return boolean
local ends_with_newline = function(text)
  return text == "" or text:sub(-1) == "\n"
end

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

--- Returns the number of deleted lines drawn above a buffer's first line.
---@param hunks nvim_hunks.Hunk[]
---@param line_count integer
---@return integer
local top_deleted = function(hunks, line_count)
  for _, hunk in ipairs(hunks) do
    local row, above = render.deleted_anchor(hunk, line_count)
    if hunk.old_count > 0 and row == 0 and above then return hunk.old_count end
  end
  return 0
end

--- Shows the deleted lines above a buffer's first line in a window scrolled
--- to the top. Neovim keeps the virtual lines above a window's first line
--- hidden until its 'topfill' reveals them.
---@param win integer
local show_top_deleted = function(win)
  local state = buffers[vim.api.nvim_win_get_buf(win)]
  local count = state and state.top_deleted or 0
  if count == 0 then return end
  vim.api.nvim_win_call(win, function()
    local view = vim.fn.winsaveview()
    if view.topline == 1 and view.topfill == 0 then
      vim.fn.winrestview({ topfill = count })
    end
  end)
end

--- Draws the buffer's hunks laid out for a window showing it, without
--- computing them again.
---@param bufnr integer
---@param win? integer
local draw = function(bufnr, win)
  local state = buffers[bufnr]
  if not state or not vim.api.nvim_buf_is_valid(bufnr) then return end

  -- The floats cover the deleted lines of the hunks being replaced.
  for _, win in ipairs(float.of_buffer(bufnr)) do
    float.close(win)
  end

  if not state.base_lines or not state.hunks then return render.clear(bufnr) end

  local has_deletions = vim
    .iter(state.hunks)
    :any(function(hunk) return hunk.old_count > 0 end)
  local syntax = has_deletions and syntax_of(bufnr, state) or {}
  local lines = buffer_lines(bufnr)
  render.render(bufnr, state.hunks, state.base_lines, lines, syntax, win)

  local previous = state.top_deleted
  state.top_deleted = top_deleted(state.hunks, #lines)
  if state.top_deleted ~= previous then
    for _, shown in ipairs(vim.fn.win_findbuf(bufnr)) do
      show_top_deleted(shown)
    end
  end
end

---@param bufnr integer
local update = function(bufnr)
  local state = buffers[bufnr]
  if not state or not vim.api.nvim_buf_is_valid(bufnr) then return end

  state.hunks = state.base_lines
      and diff.compute(state.base_lines, buffer_lines(bufnr))
    or {}
  draw(bufnr)
  fire(changed_event, { buf = bufnr })
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
---@param base_eol? boolean
local set_base = function(bufnr, state, base_lines, base_eol)
  state.base_lines = base_lines
  state.base_eol = base_eol ~= false
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
  state.old_path = nil

  -- A listed file's base is already loaded.
  local listed = listed_files[root] and listed_files[root][state.path]
  if listed then
    state.old_path = listed.old_path
    return set_base(bufnr, state, listed.base_lines, listed.base_eol)
  end

  ---@param source string
  local load_renamed = function(source)
    jj.parent_file(root, source, function(err, text)
      vim.schedule(function()
        if not is_current() then return end
        if err or not text then return notify(err or "Missing " .. source) end
        state.old_path = source
        set_base(bufnr, state, split_lines(text), ends_with_newline(text))
      end)
    end)
  end

  jj.parent_file(root, state.path, function(err, text)
    vim.schedule(function()
      if not is_current() then return end

      if err then
        notify(err)
      elseif text then
        set_base(bufnr, state, split_lines(text), ends_with_newline(text))
      else
        -- A file missing from the base was either renamed, added or copied
        -- since, or isn't tracked at all.
        jj.changed_files(root, function(files_err, files)
          vim.schedule(function()
            if not is_current() then return end
            if files_err then return notify(files_err) end
            local file = vim.iter(assert(files)):find(
              function(file) return file.target == state.path end
            )
            if file and file.status == "renamed" then
              load_renamed(file.source)
            else
              set_base(bufnr, state, file and {} or nil)
            end
          end)
        end)
      end
    end)
  end)
end

---@param repo nvim_hunks.Repo
local reload_repo = function(repo)
  base_texts[repo.root] = nil
  listed_files[repo.root] = nil
  for bufnr, state in pairs(buffers) do
    if state.repo == repo then load_base(bufnr) end
  end
  if listed_roots[repo.root] then fire(files_changed_event) end
end

---@param root string
---@return nvim_hunks.Repo
local repo_for = function(root)
  local repo = repos[root]
  if repo then return repo end

  repo = { root = root }
  repos[root] = repo
  -- What was cached while the repo wasn't watched may predate its last jj
  -- operations.
  base_texts[root] = nil
  listed_files[root] = nil

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
  if listed_roots[repo.root] then return end
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

  fire(changed_event, { buf = bufnr })
  fire(detach_event, { buf = bufnr })
end

---@param bufnr integer
---@return boolean
local should_show = function(bufnr)
  if turned_off[bufnr] then return false end
  return showing_all or turned_on[bufnr] == true
end

---@param bufnr integer
local attach = function(bufnr)
  if
    not should_show(bufnr)
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

  fire(attach_event, { buf = bufnr, float = false })
  load_base(bufnr)
end

---@param message string
local notify_error = function(message)
  vim.notify(message, vim.log.levels.ERROR, { title = "nvim-hunks" })
end

---@return boolean
local is_library_loaded = function()
  if diff.is_loaded() then return true end
  notify_error("libvscode-diff isn't loaded, see `setup()`'s `library` option")
  return false
end

---@param bufnr? integer
---@return integer
local resolve_buf = function(bufnr)
  if not bufnr or bufnr == 0 then return vim.api.nvim_get_current_buf() end
  return bufnr
end

--- Shows the diff of a buffer if it's hidden, or hides it if it's shown.
---@param bufnr? integer Defaults to the current buffer.
M.toggle = function(bufnr)
  bufnr = resolve_buf(bufnr)

  if buffers[bufnr] then
    turned_on[bufnr] = nil
    if showing_all then turned_off[bufnr] = true end
    detach(bufnr)
    return
  end

  if not is_library_loaded() then return end
  turned_off[bufnr] = nil
  turned_on[bufnr] = true
  attach(bufnr)
  if not buffers[bufnr] then
    turned_on[bufnr] = nil
    notify_error("The buffer isn't a file in a jj workspace")
  end
end

--- Shows the diffs of the buffers of all files in jj workspaces, or stops
--- doing so. Afterwards, only the buffers whose diffs were turned on
--- individually keep showing them.
---@param show boolean
M.show_all = function(show)
  if show == showing_all then return end
  if show and not is_library_loaded() then return end

  showing_all = show
  turned_off = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if should_show(bufnr) then
      attach(bufnr)
    else
      detach(bufnr)
    end
  end

  if not show then
    local roots = vim.tbl_keys(listed_roots)
    listed_roots = {}
    base_texts = {}
    listed_files = {}
    for _, root in ipairs(roots) do
      if repos[root] then release_repo(repos[root]) end
    end
  end
end

---@param bufnr? integer Defaults to the current buffer.
---@return boolean
M.is_shown = function(bufnr) return buffers[resolve_buf(bufnr)] ~= nil end

--- Returns whether the buffers of all files in jj workspaces show their
--- diffs.
---@return boolean
M.is_showing_all = function() return showing_all end

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
  ---@type integer?
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
--- with the selected old lines deleted and the selected new lines added, and
--- whether the result ends with a newline: like the file its last line comes
--- from if it's that file's last line, and otherwise always.
---@param old_lines string[]
---@param new_lines string[]
---@param hunks nvim_hunks.Hunk[]
---@param selected_old table<integer, true?>
---@param selected_new table<integer, true?>
---@param old_eol boolean
---@param new_eol boolean
---@return string[] lines
---@return boolean eol
local apply = function(
  old_lines,
  new_lines,
  hunks,
  selected_old,
  selected_new,
  old_eol,
  new_eol
)
  local lines = {}
  local next_old = 1
  local eol = true

  ---@param line integer
  local add_old = function(line)
    lines[#lines + 1] = old_lines[line]
    eol = line < #old_lines or old_eol
  end
  ---@param line integer
  local add_new = function(line)
    lines[#lines + 1] = new_lines[line]
    eol = line < #new_lines or new_eol
  end

  for _, hunk in ipairs(hunks) do
    local first_old = hunk.old_count > 0 and hunk.old_start
      or hunk.old_start + 1
    for line = next_old, first_old - 1 do
      add_old(line)
    end
    for line = first_old, first_old + hunk.old_count - 1 do
      if not selected_old[line] then add_old(line) end
    end
    for line = hunk.new_start, hunk.new_start + hunk.new_count - 1 do
      if selected_new[line] then add_new(line) end
    end
    next_old = first_old + hunk.old_count
  end

  for line = next_old, #old_lines do
    add_old(line)
  end
  return lines, eol
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
--- buffer if it's loaded, whether the file is binary, and whether it ends
--- with a newline.
---@param path string
---@return string[]? lines
---@return boolean binary
---@return boolean eol
local read_lines = function(path)
  local bufnr = buffer_of(path)
  if bufnr then return buffer_lines(bufnr), false, vim.bo[bufnr].eol end

  local file = io.open(path, "rb")
  if not file then return nil, false, true end
  local text = file:read("*a")
  file:close()
  return split_lines(text),
    text:find("\0", 1, true) ~= nil,
    ends_with_newline(text)
end

--- Reloads the loaded buffers of the given files from disk.
---@param root string
---@param paths (string|false)[]
local reload_files = function(root, paths)
  for _, path in ipairs(paths) do
    local bufnr = path and buffer_of(vim.fs.joinpath(root, path))
    if bufnr then vim.cmd.checktime(bufnr) end
  end
end

--- Calls back with the change ID of the revision a revset resolves to,
--- picked with `vim.ui.select` when it resolves to several. A revset
--- resolving to none is an error.
---@param root string
---@param revset string
---@param on_picked fun(change_id: string)
local pick_revision = function(root, revset, on_picked)
  jj.resolve(root, revset, function(err, targets)
    vim.schedule(function()
      if err then return notify_error(err) end
      targets = assert(targets)
      if #targets == 0 then
        return notify_error(("`%s` doesn't resolve to any revision"):format(revset))
      end
      if #targets == 1 then return on_picked(targets[1].change_id) end
      vim.ui.select(targets, {
        prompt = ("Move into which of `%s`?"):format(revset),
        ---@param target nvim_hunks.Target
        format_item = function(target) return target.label end,
      }, function(target)
        if target then on_picked(target.change_id) end
      end)
    end)
  end)
end

---@class nvim_hunks.File
---@field root string The root of the file's jj workspace.
--- The file's path in the working-copy commit, or in the base if it
--- was deleted, relative to the root.
---@field path string
---@field old_path? string The file's path in the base if it was renamed.
---@field status nvim_hunks.Status
---@field base_lines string[]
---@field base_eol boolean Whether the file ends with a newline in the base.
---@field lines string[]
---@field eol boolean Whether the file ends with a newline in the working copy.
---@field hunks nvim_hunks.Hunk[]
---@field binary boolean

--- Reloads the bases of a workspace's buffers and refreshes the lists of its
--- changed files, without waiting for the watcher of its jj operations.
---@param root string
local reload_root = function(root)
  local repo = repos[root]
  if repo then return reload_repo(repo) end
  fire(files_changed_event)
end

--- Calls back if a file's base is still the one its hunks were computed
--- against. Otherwise, e.g. when a move right before hasn't been reloaded
--- yet, the moves built on the hunks would undo it, so it reports that and
--- reloads the diffs.
---@param file nvim_hunks.File
---@param on_current fun()
local check_base = function(file, on_current)
  jj.parent_file(
    file.root,
    file.old_path or file.path,
    function(err, text)
      vim.schedule(function()
        if err then return notify_error(err) end
        local base_lines = text and split_lines(text) or {}
        local base_eol = not text or ends_with_newline(text)
        if
          vim.deep_equal(base_lines, file.base_lines)
          and base_eol == file.base_eol
        then
          return on_current()
        end
        notify_error("The diff was out of date, try again")
        reload_root(file.root)
      end)
    end
  )
end

--- Moves the selected lines of a file's hunks into another revision. A
--- renamed file's rename is moved with them.
---@param file nvim_hunks.File
---@param selected_old table<integer, true?>
---@param selected_new table<integer, true?>
---@param into string
---@param on_moved? fun()
local move_lines = function(file, selected_old, selected_new, into, on_moved)
  local lines, eol = apply(
    file.base_lines,
    file.lines,
    file.hunks,
    selected_old,
    selected_new,
    file.base_eol,
    file.eol
  )
  if vim.deep_equal(lines, file.base_lines) and eol == file.base_eol then
    return notify_error("The selection doesn't contain any changes")
  end
  local text = #lines > 0 and table.concat(lines, "\n") .. (eol and "\n" or "")
    or ""
  local other_paths = file.old_path and { file.old_path } or {}

  pick_revision(file.root, into, function(target)
    check_base(file, function()
      jj.squash_file(
        file.root,
        target,
        file.path,
        text,
        other_paths,
        function(squash_err)
          vim.schedule(function()
            if squash_err then return notify_error(squash_err) end
            if on_moved then on_moved() end
            -- Moving changes into a descendant takes them out of the files
            -- on disk.
            reload_files(file.root, { file.path, file.old_path or false })
            reload_root(file.root)
          end)
        end
      )
    end)
  end)
end

--- Computes the files changed by a workspace's working-copy commit.
---@param root string
---@param on_done fun(files: nvim_hunks.File[])
local workspace_files = function(root, on_done)
  jj.changed_files(root, function(err, changed)
    if err then
      vim.schedule(function()
        notify_error(err)
        on_done({})
      end)
      return
    end

    changed = assert(changed)
    ---@type nvim_hunks.File[]
    local files = {}
    local pending = #changed
    if pending == 0 then
      vim.schedule(function() on_done({}) end)
      return
    end

    for idx, change in ipairs(changed) do
      local status = change.status
      ---@type nvim_hunks.File
      local file = {
        root = root,
        path = status == "removed" and change.source or change.target,
        old_path = status == "renamed" and change.source or nil,
        status = status,
        base_lines = {},
        base_eol = true,
        lines = {},
        eol = true,
        hunks = {},
        binary = false,
      }
      files[idx] = file

      ---@param base_text string
      local compute = vim.schedule_wrap(function(base_text)
        file.base_lines = split_lines(base_text)
        file.base_eol = ends_with_newline(base_text)
        file.binary = base_text:find("\0", 1, true) ~= nil
        if status ~= "removed" then
          local lines, binary, eol =
            read_lines(vim.fs.joinpath(root, file.path))
          file.lines = lines or {}
          file.eol = eol
          file.binary = file.binary or binary
        end
        if not file.binary then
          file.hunks = diff.compute(file.base_lines, file.lines)
        end
        if repos[root] then
          listed_files[root] = listed_files[root] or {}
          listed_files[root][file.path] = file
        end

        pending = pending - 1
        if pending == 0 then on_done(files) end
      end)

      -- The caches are only dropped after the jj operations of watched repos.
      local is_watched = repos[root] ~= nil
      local cached = is_watched
        and base_texts[root]
        and base_texts[root][change.source]
      if status == "added" or status == "copied" then
        compute("")
      elseif cached then
        compute(cached)
      else
        jj.parent_file(root, change.source, function(_, text)
          vim.schedule(function()
            if not repos[root] then return end
            base_texts[root] = base_texts[root] or {}
            base_texts[root][change.source] = text or ""
          end)
          compute(text or "")
        end)
      end
    end
  end)
end

--- Returns the roots of the jj workspaces around a directory: the one
--- containing it, or else the ones directly inside it.
---@param dir? string The directory, the current working directory by default.
---@return string[]
M.workspaces = function(dir)
  local cwd = dir or vim.fn.getcwd()
  local root = jj.root(cwd)
  if root then return { root } end

  local roots = {}
  for name, type in vim.fs.dir(cwd) do
    local dir = vim.fs.joinpath(cwd, name)
    if type == "directory" and uv.fs_stat(vim.fs.joinpath(dir, ".jj")) then
      roots[#roots + 1] = vim.fs.normalize(dir)
    end
  end
  table.sort(roots)
  return roots
end

--- Computes the files changed by the working-copy commits of the given jj
--- workspaces.
---@param roots string[]
---@param on_done fun(files: nvim_hunks.File[])
M.files = function(roots, on_done)
  ---@type nvim_hunks.File[]
  local all = {}
  local pending = #roots
  if pending == 0 then return on_done({}) end

  for _, root in ipairs(roots) do
    workspace_files(root, function(files)
      vim.list_extend(all, files)
      pending = pending - 1
      if pending > 0 then return end
      table.sort(
        all,
        function(a, b)
          return vim.fs.joinpath(a.root, a.path)
            < vim.fs.joinpath(b.root, b.path)
        end
      )
      on_done(all)

      -- The list of the workspaces' files is refreshed after their jj
      -- operations while all diffs are shown, which the callback may have
      -- just turned on.
      if showing_all then
        for _, listed_root in ipairs(roots) do
          listed_roots[listed_root] = true
          repo_for(listed_root)
        end
      end
    end)
  end
end

--- Describes the working-copy commit of a jj workspace.
---@param root string
---@param on_done fun(revision?: nvim_hunks.Revision)
M.working_copy = function(root, on_done)
  jj.describe(root, "@", function(err, revision)
    vim.schedule(function()
      if err then notify_error(err) end
      on_done(revision)
    end)
  end)
end

--- Moves all of a file's changes into another revision. For a renamed file,
--- only the rename is moved, without the changes to its contents.
---@param file nvim_hunks.File
---@param into string
M.move_file = function(file, into)
  for _, path in ipairs({ file.path, file.old_path }) do
    local bufnr = buffer_of(vim.fs.joinpath(file.root, path))
    if bufnr and vim.bo[bufnr].modified then
      return notify_error("Save the buffer first")
    end
  end

  ---@param err? string
  local on_moved = function(err)
    vim.schedule(function()
      if err then return notify_error(err) end
      reload_files(file.root, { file.path, file.old_path or false })
      reload_root(file.root)
    end)
  end

  pick_revision(file.root, into, function(target)
    if file.status == "renamed" and not file.binary then
      local text = #file.base_lines > 0
          and table.concat(file.base_lines, "\n") .. (file.base_eol and "\n" or "")
        or ""
      check_base(
        file,
        function()
          jj.squash_file(
            file.root,
            target,
            file.path,
            text,
            { file.old_path },
            on_moved
          )
        end
      )
    else
      local paths = { file.path, file.old_path }
      jj.squash_paths(file.root, target, paths, on_moved)
    end
  end)
end

--- Moves all the changes of a set of files, renames included, into another
--- revision.
---@param files nvim_hunks.File[]
---@param into string
M.move_files = function(files, into)
  ---@type table<string, string[]>
  local paths_by_root = {}
  for _, file in ipairs(files) do
    for _, path in ipairs({ file.path, file.old_path }) do
      local bufnr = buffer_of(vim.fs.joinpath(file.root, path))
      if bufnr and vim.bo[bufnr].modified then
        return notify_error("Save the buffers first")
      end
      paths_by_root[file.root] = paths_by_root[file.root] or {}
      table.insert(paths_by_root[file.root], path)
    end
  end

  for root, paths in pairs(paths_by_root) do
    pick_revision(root, into, function(target)
      jj.squash_paths(root, target, paths, function(squash_err)
        vim.schedule(function()
          if squash_err then return notify_error(squash_err) end
          reload_files(root, paths)
        end)
      end)
    end)
  end
end

--- Moves one of a file's hunks into another revision, together with the
--- file's rename if it was renamed.
---@param file nvim_hunks.File
---@param hunk nvim_hunks.Hunk
---@param into string
M.move_hunk = function(file, hunk, into)
  local path = vim.fs.joinpath(file.root, file.path)
  local bufnr = buffer_of(path)
  if bufnr and vim.bo[bufnr].modified then
    return notify_error("Save the buffer first")
  end

  local lines = file.status == "removed" and {} or read_lines(path) or {}
  if not vim.deep_equal(lines, file.lines) then
    notify_error("The file changed since its hunks were computed")
    return fire(files_changed_event)
  end

  ---@type table<integer, true?>, table<integer, true?>
  local selected_old, selected_new = {}, {}
  for line = hunk.old_start, hunk.old_start + hunk.old_count - 1 do
    selected_old[line] = true
  end
  for line = hunk.new_start, hunk.new_start + hunk.new_count - 1 do
    selected_new[line] = true
  end
  move_lines(file, selected_old, selected_new, into)
end

---@class nvim_hunks.HunkSelection
---@field file nvim_hunks.File
---@field hunks nvim_hunks.Hunk[]

--- Returns the lines of a file's hunks, in the base and in the working copy.
---@param hunk_list nvim_hunks.Hunk[]
---@return table<integer, true?> selected_old
---@return table<integer, true?> selected_new
local lines_of_hunks = function(hunk_list)
  ---@type table<integer, true?>, table<integer, true?>
  local selected_old, selected_new = {}, {}
  for _, hunk in ipairs(hunk_list) do
    for line = hunk.old_start, hunk.old_start + hunk.old_count - 1 do
      selected_old[line] = true
    end
    for line = hunk.new_start, hunk.new_start + hunk.new_count - 1 do
      selected_new[line] = true
    end
  end
  return selected_old, selected_new
end

--- Moves whole files and some of the hunks of others into another revision.
--- The revision is picked once per workspace. Each workspace's whole files
--- are moved together, and then each file's hunks together, with its rename
--- if it was renamed, one jj operation after the other.
---@param files nvim_hunks.File[] The files moved whole.
---@param selections nvim_hunks.HunkSelection[]
---@param into string
M.move_many = function(files, selections, into)
  ---@type string[], table<string, { paths: string[], selections: nvim_hunks.HunkSelection[] }>
  local roots, groups = {}, {}
  ---@param root string
  local group_of = function(root)
    local group = groups[root]
    if not group then
      group = { paths = {}, selections = {} }
      groups[root] = group
      roots[#roots + 1] = root
    end
    return group
  end

  for _, file in ipairs(files) do
    for _, path in ipairs({ file.path, file.old_path }) do
      local bufnr = buffer_of(vim.fs.joinpath(file.root, path))
      if bufnr and vim.bo[bufnr].modified then
        return notify_error("Save the buffers first")
      end
      table.insert(group_of(file.root).paths, path)
    end
  end

  for _, selection in ipairs(selections) do
    local file = selection.file
    local path = vim.fs.joinpath(file.root, file.path)
    local bufnr = buffer_of(path)
    if bufnr and vim.bo[bufnr].modified then
      return notify_error("Save the buffers first")
    end
    local lines = file.status == "removed" and {} or read_lines(path) or {}
    if not vim.deep_equal(lines, file.lines) then
      notify_error("A file changed since its hunks were computed")
      return fire(files_changed_event)
    end
    table.insert(group_of(file.root).selections, selection)
  end

  for _, root in ipairs(roots) do
    local group = groups[root]
    pick_revision(root, into, function(target)
      ---@type fun(on_done: fun())[]
      local steps = {}
      if #group.paths > 0 then
        steps[#steps + 1] = function(on_done)
          jj.squash_paths(root, target, group.paths, function(squash_err)
            vim.schedule(function()
              if squash_err then return notify_error(squash_err) end
              reload_files(root, group.paths)
              on_done()
            end)
          end)
        end
      end
      for _, selection in ipairs(group.selections) do
        steps[#steps + 1] = function(on_done)
          local selected_old, selected_new = lines_of_hunks(selection.hunks)
          move_lines(selection.file, selected_old, selected_new, target, on_done)
        end
      end

      local index = 0
      ---@type fun()
      local step
      step = function()
        index = index + 1
        local next_step = steps[index]
        if next_step then next_step(step) end
      end
      step()
    end)
  end
end

--- Draws the contents of a deleted file's buffer as deleted lines, laid out
--- for a window showing it.
---@param bufnr integer
---@param win? integer
local draw_deleted = function(bufnr, win)
  render.clear(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  render.render_lines(bufnr, 1, lines, render.layout(bufnr, win), "Delete")
end

--- Returns a buffer displaying a deleted file's contents in the base,
--- highlighted as deleted.
---@param file nvim_hunks.File
---@return integer
M.deleted_buffer = function(file)
  for bufnr, deleted in pairs(deleted_buffers) do
    if deleted.root == file.root and deleted.path == file.path then
      return bufnr
    end
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(
    bufnr,
    "nvim-hunks://" .. vim.fs.joinpath(file.root, file.path)
  )
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, file.base_lines)
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].modifiable = false

  local filetype = vim.filetype.match({ filename = file.path })
  local lang = filetype and vim.treesitter.language.get_lang(filetype)
  if lang then pcall(vim.treesitter.start, bufnr, lang) end

  deleted_buffers[bufnr] = { root = file.root, path = file.path }
  draw_deleted(bufnr)
  fire(attach_event, { buf = bufnr, float = false, deleted = true })
  return bufnr
end

--- Draws the hunks of a buffer showing its diff, or the contents of a deleted
--- file's buffer, laid out for a window showing it, by default the current
--- one or else any.
---@param bufnr integer
---@param win? integer
M.redraw = function(bufnr, win)
  if buffers[bufnr] then
    draw(bufnr, win)
  elseif deleted_buffers[bufnr] then
    draw_deleted(bufnr, win)
  end
end

--- Draws a changed file's hunks on a buffer holding the file's contents in
--- the working-copy commit, laid out for a window showing it.
---@param bufnr integer
---@param file nvim_hunks.File
---@param win? integer
M.render_file = function(bufnr, file, win)
  local has_deletions = vim
    .iter(file.hunks)
    :any(function(hunk) return hunk.old_count > 0 end)
  local filetype = vim.filetype.match({ filename = file.path })
  local syntax = has_deletions
      and filetype
      and render.syntax(table.concat(file.base_lines, "\n"), filetype)
    or {}
  render.render(bufnr, file.hunks, file.base_lines, file.lines, syntax, win)
end

--- Reloads the buffers of files changed on disk, and refreshes the lists of
--- changed files. Meant to be called after files are edited outside of
--- Neovim, e.g. by a coding agent.
M.refresh = function()
  vim.cmd.checktime()
  fire(files_changed_event)
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
---@param into string A revset, e.g. `@-`. When it resolves to several revisions, one is picked with `vim.ui.select`.
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

  local deleted = deleted_buffers[bufnr]
  if deleted then
    M.move_file({
      root = deleted.root,
      path = deleted.path,
      status = "removed",
      base_lines = {},
      base_eol = true,
      lines = {},
      eol = true,
      hunks = {},
      binary = false,
    }, into)
    return true
  end

  local state = buffers[bufnr]
  if not state or not state.base_lines then return false end

  ---@type table<integer, true?>, table<integer, true?>
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

  move_lines(
    {
      root = state.repo.root,
      path = state.path,
      old_path = state.old_path,
      status = state.old_path and "renamed" or "modified",
      base_lines = state.base_lines,
      base_eol = state.base_eol ~= false,
      lines = buffer_lines(bufnr),
      eol = vim.bo[bufnr].eol,
      hunks = state.hunks,
      binary = false,
    },
    selected_old,
    selected_new,
    into,
    function()
      if current_float then float.close(win) end
    end
  )

  return true
end

---@param opts? { colors?: nvim_hunks.Colors, library?: string }
M.setup = function(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  if config.library and not diff.is_loaded() then
    local ok, err = pcall(diff.load, config.library)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR, { title = "nvim-hunks" })
    end
  end

  render.set_highlights(config.colors)

  local group = vim.api.nvim_create_augroup("nvim-hunks", { clear = true })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    desc = "Redraws the diffs with the new color scheme's highlights",
    callback = function()
      render.set_highlights(config.colors)
      for bufnr in pairs(buffers) do
        update(bufnr)
      end
    end,
  })

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

  ---@param bufnr integer
  ---@param win? integer
  local redraw = function(bufnr, win)
    if buffers[bufnr] then
      draw(bufnr, win)
    elseif deleted_buffers[bufnr] then
      draw_deleted(bufnr, win)
    end
  end

  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    desc = "Redraws the diff to fit the buffer's window",
    callback = function(ev) redraw(ev.buf) end,
  })

  ---@type table<integer, { topline: integer, leftcol: integer }?>
  local views = {}
  vim.api.nvim_create_autocmd("WinScrolled", {
    group = group,
    desc = "Redraws the diffs of windows scrolled sideways, and shows the deleted lines above the first line of buffers scrolled to the top",
    callback = function()
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local view = vim.api.nvim_win_call(win, vim.fn.winsaveview)
        local previous = views[win]
        views[win] = { topline = view.topline, leftcol = view.leftcol }
        if (previous and previous.leftcol or 0) ~= view.leftcol then
          redraw(vim.api.nvim_win_get_buf(win), win)
        end
        if previous and previous.topline ~= 1 and view.topline == 1 then
          show_top_deleted(win)
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinResized", {
    group = group,
    desc = "Redraws the diffs to fit the resized windows",
    callback = function()
      for _, win in ipairs(vim.v.event.windows or {}) do
        if vim.api.nvim_win_is_valid(win) then
          redraw(vim.api.nvim_win_get_buf(win))
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("OptionSet", {
    group = group,
    pattern = {
      "colorcolumn",
      "foldcolumn",
      "number",
      "numberwidth",
      "relativenumber",
      "showbreak",
      "signcolumn",
      "statuscolumn",
      "tabstop",
      "textwidth",
      "wrap",
    },
    desc = "Redraws the diffs laid out with the changed option",
    callback = function()
      local wins = vim.v.option_type == "local"
          and { vim.api.nvim_get_current_win() }
        or vim.api.nvim_list_wins()
      for _, win in ipairs(wins) do
        redraw(vim.api.nvim_win_get_buf(win))
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    desc = "Forgets the diff of the buffer",
    callback = function(ev)
      detach(ev.buf)
      turned_on[ev.buf] = nil
      turned_off[ev.buf] = nil
      deleted_buffers[ev.buf] = nil
    end,
  })
end

return M
