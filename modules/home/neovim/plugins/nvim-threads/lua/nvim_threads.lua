local context = require("nvim_threads.context")
local float = require("nvim_threads.float")
local jj = require("nvim_threads.jj")
local render = require("nvim_threads.render")
local server = require("nvim_threads.server")
local store = require("nvim_threads.store")
local suggestion = require("nvim_threads.suggestion")

local M = {}

local uv = vim.uv

local attach_event = "NvimThreadsAttach"
local changed_event = "NvimThreadsChanged"
local detach_event = "NvimThreadsDetach"

--- The delay between a change to a buffer and the update of its anchors.
local sync_debounce_ms = 150

--- The delay between a change to a change's threads and their write.
local save_debounce_ms = 300

--- The delay between a jj operation and the reload of the working copy it
--- triggers.
local op_debounce_ms = 100

local anchor_namespace = vim.api.nvim_create_namespace("nvim-threads-anchors")
local highlight_namespace =
  vim.api.nvim_create_namespace("nvim-threads-highlights")
local float_namespace = vim.api.nvim_create_namespace("nvim-threads-float")

---@class nvim_threads.Request
---@field thread nvim_threads.Thread A copy of the thread, whose last comment is the one to reply to.
---@field root string The root of the thread's jj workspace.
---@field path string The thread's file, relative to the root.
---@field context string The thread's selection and its surroundings.
---@field prompt string The context, the earlier comments and the last one.

---@class nvim_threads.Result
---@field body? string The reply, if it's not the text streamed in.
---@field title? string
---@field edits? nvim_threads.Edit[]

---@class nvim_threads.Reply
---@field chunk fun(text: string) Adds text to the reply streamed in so far.
---@field done fun(result?: nvim_threads.Result)
---@field error fun(message: string)

---@class nvim_threads.Participant
---@field name string
--- Whether the participant takes part in a buffer's threads. Without it, it
--- takes part in all of them.
---@field attaches? fun(bufnr: integer): boolean
--- Starts replying to a request, and returns a function cancelling the reply
--- if it can be.
---@field send fun(request: nvim_threads.Request, reply: nvim_threads.Reply): (fun()?)

---@class nvim_threads.Config
--- Names a thread whose first comment mentions no participants.
---@field titler? fun(request: nvim_threads.Request, on_title: fun(title: string))
---@field spinner { frames: string[], interval: integer }

---@type nvim_threads.Config
local config = {
  spinner = {
    frames = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
    interval = 100,
  },
}

---@class nvim_threads.Repo
---@field root string The root of the jj workspace.
---@field repo_dir string
---@field change_id? string The change ID of the working-copy commit, unset until it's resolved.
---@field waiting fun()[] The callbacks waiting for the change ID.
---@field timer? uv.uv_timer_t
---@field watcher? uv.uv_fs_event_t

---@class nvim_threads.Mark
---@field anchor integer The extmark of the thread's anchor.
---@field display? integer The extmark of the thread's virtual lines.
---@field display_row? integer The 0-based row the virtual lines follow.

---@class nvim_threads.Buffer
---@field repo nvim_threads.Repo
---@field path string The file's path relative to the repo's root.
---@field change_id? string The change whose threads the buffer shows.
---@field marks table<string, nvim_threads.Mark?>
---@field timer? uv.uv_timer_t

---@class nvim_threads.Location
---@field thread nvim_threads.Thread
---@field repo nvim_threads.Repo
---@field change_id string
---@field path string

---@type table<string, nvim_threads.Participant?>
local participants = {}

---@type table<string, nvim_threads.Repo?>
local repos = {}

---@type table<integer, nvim_threads.Buffer?>
local buffers = {}

--- The views of the threads displayed so far, by thread ID.
---@type table<string, nvim_threads.View?>
local views = {}

--- The rows of each thread as last drawn, by thread ID.
---@type table<string, nvim_threads.Row[]?>
local drawn_rows = {}

--- Where the threads loaded so far are stored, by thread ID.
---@type table<string, nvim_threads.Location?>
local locations = {}

--- The functions cancelling the replies in progress, by thread ID and then
--- by participant.
---@type table<string, table<string, fun()?>?>
local cancels = {}

--- The spinner's current frame and the timer advancing it while replies are
--- in progress.
---@type { frame: integer, timer?: uv.uv_timer_t }
local spinner = { frame = 1 }

--- The timers of the pending writes, by repo directory and change ID.
---@type table<string, { timer: uv.uv_timer_t, repo_dir: string, change_id: string }?>
local saves = {}

--- The floats' buffers whose lines are being set by the plugin.
---@type table<integer, true?>
local filling = {}

---@param pattern string
---@param data? table
local fire = function(pattern, data)
  vim.api.nvim_exec_autocmds("User", {
    pattern = pattern,
    modeline = false,
    data = data,
  })
end

---@param message string
local notify_error = function(message)
  vim.notify(message, vim.log.levels.ERROR, { title = "nvim-threads" })
end

---@param message string
local notify_warn = function(message)
  vim.notify(message, vim.log.levels.WARN, { title = "nvim-threads" })
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

---@return string
local new_id = function()
  return ("%x%06x"):format(os.time(), math.random(0, 0xffffff))
end

---@param id string
---@return nvim_threads.View
local view_of = function(id)
  local view = views[id]
  if not view then
    view = {
      expanded = false,
      pending = {},
      frame = config.spinner.frames[spinner.frame] or "",
    }
    views[id] = view
  end
  return view
end

---@param repo_dir string
---@param change_id string
local save_now = function(repo_dir, change_id)
  local key = repo_dir .. "\0" .. change_id
  local pending = saves[key]
  if pending then
    pending.timer:close()
    saves[key] = nil
  end
  store.save(repo_dir, change_id)
end

---@param repo_dir string
---@param change_id string
local schedule_save = function(repo_dir, change_id)
  local key = repo_dir .. "\0" .. change_id
  local pending = saves[key]
  if not pending then
    pending = {
      timer = assert(uv.new_timer()),
      repo_dir = repo_dir,
      change_id = change_id,
    }
    saves[key] = pending
  end
  pending.timer:start(
    save_debounce_ms,
    0,
    vim.schedule_wrap(function()
      if saves[key] == pending then save_now(repo_dir, change_id) end
    end)
  )
end

local flush_saves = function()
  for _, pending in pairs(saves) do
    save_now(pending.repo_dir, pending.change_id)
  end
end

--- Records that a thread changed, to be written and listed again.
---@param thread nvim_threads.Thread
local persist = function(thread)
  local location = locations[thread.id]
  if not location then return end
  schedule_save(location.repo.repo_dir, location.change_id)
  fire(changed_event)
end

--- Returns the 0-based row of the last line holding an anchor's text, which
--- its thread's virtual lines follow.
---@param anchor nvim_threads.Anchor
---@return integer
local display_row = function(anchor)
  local _, last = context.lines_of(anchor)
  return last - 1
end

--- Returns the window showing the buffer, preferably the current one.
---@param bufnr integer
---@return integer?
local window_of = function(bufnr)
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(win) == bufnr then return win end
  return vim.fn.win_findbuf(bufnr)[1]
end

--- Returns the width of the text area of a window showing the buffer, and
--- the width of the columns to its left.
---@param bufnr integer
---@return integer text_width
---@return integer gutter
local layout_of = function(bufnr)
  local win = window_of(bufnr)
  local info = win and vim.fn.getwininfo(win)[1]
  if not info then return math.max(vim.o.columns - 4, 20), 0 end
  return math.max(info.width - info.textoff, 20), info.textoff
end

---@param state nvim_threads.Buffer
---@param lines? string[] The file's lines, which create its entry if it has none.
---@return nvim_threads.Entry?
local entry_of = function(state, lines)
  if not state.change_id then return end
  if lines then
    return store.entry(state.repo.repo_dir, state.change_id, state.path, lines)
  end
  return store.load(state.repo.repo_dir, state.change_id).files[state.path]
end

---@param bufnr integer
---@param id string
---@return nvim_threads.Thread?
local thread_of = function(bufnr, id)
  local state = buffers[bufnr]
  local entry = state and entry_of(state)
  if not entry then return end
  return vim
    .iter(entry.threads)
    :find(function(thread) return thread.id == id end)
end

--- Returns the buffers displaying a thread.
---@param thread nvim_threads.Thread
---@return integer[]
local buffers_of = function(thread)
  local location = locations[thread.id]
  if not location then return {} end
  local result = {}
  for bufnr, state in pairs(buffers) do
    if
      state.repo == location.repo
      and state.change_id == location.change_id
      and state.path == location.path
      and state.marks[thread.id]
    then
      result[#result + 1] = bufnr
    end
  end
  return result
end

--- Returns the names of the participants taking part in a buffer's threads.
---@param bufnr integer
---@return string[]
local participants_of = function(bufnr)
  local names = {}
  for name, participant in pairs(participants) do
    if not participant.attaches or participant.attaches(bufnr) then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  return names
end

--- Returns the float's buffer's rows above the composer, and those of the
--- composer.
---@param rows nvim_threads.Row[]
---@return nvim_threads.Row[] history
---@return nvim_threads.Row[] composer
local split_rows = function(rows)
  local history, composer = {}, {}
  for _, row in ipairs(rows) do
    table.insert(row.kind == "composer" and composer or history, row)
  end
  return history, composer
end

--- Makes a float's buffer modifiable only while its cursor is in the
--- composer.
---@param win integer
local update_modifiable = function(win)
  local current = float.get(win)
  if not current or not vim.api.nvim_win_is_valid(win) then return end
  local buf = vim.api.nvim_win_get_buf(win)
  local line = vim.api.nvim_win_get_cursor(win)[1]
  vim.bo[buf].modifiable = line > current.history
end

--- Sets the lines of a float's buffer to a thread's rows, and highlights
--- them. Unless it's full, the composer's lines are left as they are.
---@param win integer
---@param rows nvim_threads.Row[]
---@param full boolean
local fill = function(win, rows, full)
  local current = float.get(win)
  if not current then return end
  local buf = vim.api.nvim_win_get_buf(win)
  local history, composer = split_rows(rows)
  local texts = vim.tbl_map(render.text, history)

  filling[buf] = true
  vim.bo[buf].modifiable = true
  if full then
    local view = view_of(current.thread_id)
    vim.api.nvim_buf_set_lines(
      buf,
      0,
      -1,
      false,
      vim.list_extend(texts, vim.deepcopy(view.draft or {}))
    )
  else
    vim.api.nvim_buf_set_lines(buf, 0, current.history, false, texts)
  end
  filling[buf] = nil
  current.history = #history

  vim.api.nvim_buf_clear_namespace(buf, float_namespace, 0, -1)
  current.borders = {}
  for index, row in ipairs(history) do
    current.borders[index] = row.prefix[1] or { render.border }
    local col = 0
    for _, chunk in ipairs(row.chunks) do
      local hl = chunk[2]
      if hl then
        local groups = type(hl) == "table" and hl or { hl }
        for priority, group in ipairs(groups) do
          vim.api.nvim_buf_set_extmark(buf, float_namespace, index - 1, col, {
            end_col = col + #chunk[1],
            hl_group = group,
            priority = vim.hl.priorities.user + priority,
          })
        end
      end
      col = col + #chunk[1]
    end
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  for line = current.history + 1, line_count do
    current.borders[line] = { render.border, "ThreadsAuthorMe" }
  end
  local placeholder = composer[1] and composer[1].placeholder
  if placeholder and line_count == current.history + 1 then
    local text = vim.api.nvim_buf_get_lines(buf, -2, -1, false)[1]
    if text == "" then
      vim.api.nvim_buf_set_extmark(buf, float_namespace, current.history, 0, {
        virt_text = { { placeholder, "ThreadsPlaceholder" } },
        virt_text_pos = "overlay",
      })
    end
  end

  update_modifiable(win)
end

--- Draws a thread's virtual lines in a buffer, and its float if it's open.
---@param bufnr integer
---@param thread nvim_threads.Thread
---@param full_float? boolean Whether the float's composer is filled again too.
local draw = function(bufnr, thread, full_float)
  local state = buffers[bufnr]
  local mark = state and state.marks[thread.id]
  if not mark or not vim.api.nvim_buf_is_valid(bufnr) then return end

  local view = view_of(thread.id)
  local width, gutter = layout_of(bufnr)
  local rows = render.rows(thread, view, width)
  drawn_rows[thread.id] = rows

  -- The virtual lines cover the columns left of the text, which would
  -- otherwise take the number highlight of the line they follow, like a
  -- hunk's.
  local virt_lines = vim.tbl_map(function(row)
    local chunks = render.virt_line(row, width)
    table.insert(chunks, 1, { (" "):rep(gutter), "ThreadsGutter" })
    return chunks
  end, rows)

  local row = display_row(thread.anchor)
  local ok, id =
    pcall(vim.api.nvim_buf_set_extmark, bufnr, render.namespace, row, 0, {
      id = mark.display,
      virt_lines = virt_lines,
      virt_lines_leftcol = true,
      strict = false,
    })
  if ok then
    mark.display = id
    mark.display_row = row
  end

  local win = float.of_thread(thread.id)
  if win and vim.api.nvim_win_is_valid(win) then
    fill(win, rows, full_float == true)
    float.place(win, #rows)
  end
end

--- Redraws a thread wherever it's displayed.
---@param thread nvim_threads.Thread
local redraw = function(thread)
  for _, bufnr in ipairs(buffers_of(thread)) do
    draw(bufnr, thread)
  end
end

--- Starts animating the spinners of the replies in progress, or stops it
--- once there are none.
local update_spinner = function()
  local any = false
  for _, view in pairs(views) do
    if next(view.pending) then any = true end
  end
  if not any then
    if spinner.timer then
      spinner.timer:close()
      spinner.timer = nil
    end
    return
  end
  if spinner.timer then return end

  spinner.timer = assert(uv.new_timer())
  spinner.timer:start(
    config.spinner.interval,
    config.spinner.interval,
    vim.schedule_wrap(function()
      spinner.frame = spinner.frame % #config.spinner.frames + 1
      for id, view in pairs(views) do
        view.frame = config.spinner.frames[spinner.frame]
        local location = locations[id]
        if next(view.pending) and location then redraw(location.thread) end
      end
    end)
  )
end

--- Sets the extmark of a thread's anchor in a buffer.
---@param bufnr integer
---@param state nvim_threads.Buffer
---@param thread nvim_threads.Thread
local place = function(bufnr, state, thread)
  local anchor = thread.anchor
  local id = vim.api.nvim_buf_set_extmark(
    bufnr,
    anchor_namespace,
    anchor.start_row,
    anchor.start_col,
    {
      end_row = anchor.end_row,
      end_col = anchor.end_col,
      invalidate = true,
      strict = false,
    }
  )
  state.marks[thread.id] = { anchor = id }
  locations[thread.id] = {
    thread = thread,
    repo = state.repo,
    change_id = assert(state.change_id),
    path = state.path,
  }
end

--- Returns the anchor of an extmark, and whether its text was deleted.
---@param bufnr integer
---@param id integer
---@return nvim_threads.Anchor?
---@return boolean invalid
local read_anchor = function(bufnr, id)
  local mark = vim.api.nvim_buf_get_extmark_by_id(
    bufnr,
    anchor_namespace,
    id,
    { details = true }
  )
  if not mark[1] then return nil, false end
  local details = mark[3] or {}
  return {
    start_row = mark[1],
    start_col = mark[2],
    end_row = details.end_row or mark[1],
    end_col = details.end_col or mark[2],
  },
    details.invalid == true
end

--- Updates the anchors of a buffer's threads from their extmarks, and the
--- snapshot of its file from its lines.
---@param bufnr integer
local sync = function(bufnr)
  local state = buffers[bufnr]
  local entry = state and entry_of(state)
  if not state or not entry or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  for _, thread in ipairs(entry.threads) do
    local mark = state.marks[thread.id]
    local anchor, invalid = nil, false
    if mark then
      anchor, invalid = read_anchor(bufnr, mark.anchor)
    end
    if mark and anchor then
      if invalid then
        thread.outdated = true
        anchor.end_row, anchor.end_col = anchor.start_row, anchor.start_col
      end
      thread.anchor = anchor
      if display_row(anchor) ~= mark.display_row then draw(bufnr, thread) end
    end
  end

  entry.snapshot = buffer_lines(bufnr)
  schedule_save(state.repo.repo_dir, assert(state.change_id))
end

--- Displays the threads of the buffer's file in the working-copy commit.
---@param bufnr integer
local load = function(bufnr)
  local state = buffers[bufnr]
  if not state or not state.repo.change_id then return end
  if not vim.api.nvim_buf_is_loaded(bufnr) then return end

  state.change_id = state.repo.change_id
  local entry = entry_of(state)
  if not entry then return end

  store.remap(entry, buffer_lines(bufnr))
  for _, thread in ipairs(entry.threads) do
    place(bufnr, state, thread)
    draw(bufnr, thread)
  end
  fire(changed_event)
end

--- Stops displaying a buffer's threads, after saving their anchors.
---@param bufnr integer
local unload = function(bufnr)
  local state = buffers[bufnr]
  if not state then return end

  sync(bufnr)
  for _, win in ipairs(float.of_buffer(bufnr)) do
    float.close(win)
  end
  if vim.api.nvim_buf_is_valid(bufnr) then
    for _, namespace in ipairs({
      anchor_namespace,
      render.namespace,
      highlight_namespace,
    }) do
      vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
    end
  end
  state.marks = {}
  if state.change_id then save_now(state.repo.repo_dir, state.change_id) end
end

--- Displays a buffer's threads again after it was reloaded, which replaces
--- all of its lines.
---@param bufnr integer
local reload = function(bufnr)
  local state = buffers[bufnr]
  local entry = state and entry_of(state)
  if not state or not entry then return end
  for _, namespace in ipairs({ anchor_namespace, render.namespace }) do
    vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  end
  state.marks = {}
  store.remap(entry, buffer_lines(bufnr))
  for _, thread in ipairs(entry.threads) do
    place(bufnr, state, thread)
    draw(bufnr, thread)
  end
  schedule_save(state.repo.repo_dir, assert(state.change_id))
end

---@param repo nvim_threads.Repo
local refresh_working_copy = function(repo)
  jj.working_copy(repo.root, function(err, change_id)
    vim.schedule(function()
      if repos[repo.root] ~= repo then return end
      if err then return notify_warn(err) end
      local previous = repo.change_id
      repo.change_id = change_id

      local waiting = repo.waiting
      repo.waiting = {}
      for _, callback in ipairs(waiting) do
        callback()
      end

      if previous and previous ~= change_id then
        for bufnr, state in pairs(buffers) do
          if state.repo == repo then
            unload(bufnr)
            load(bufnr)
          end
        end
        fire(changed_event)
      end
    end)
  end)
end

---@param root string
---@return nvim_threads.Repo
local repo_for = function(root)
  local repo = repos[root]
  if repo then return repo end

  repo = { root = root, repo_dir = jj.repo_dir(root), waiting = {} }
  repos[root] = repo
  refresh_working_copy(repo)

  local timer = assert(uv.new_timer())
  local watcher = assert(uv.new_fs_event())
  local ok = watcher:start(jj.op_heads_dir(root), {}, function()
    timer:start(
      op_debounce_ms,
      0,
      vim.schedule_wrap(function()
        if repos[root] == repo then refresh_working_copy(repo) end
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

--- Calls back once the change ID of the repo's working-copy commit is
--- resolved.
---@param repo nvim_threads.Repo
---@param callback fun()
local with_change = function(repo, callback)
  if repo.change_id then return callback() end
  table.insert(repo.waiting, callback)
end

---@param bufnr integer
local detach = function(bufnr)
  local state = buffers[bufnr]
  if not state then return end
  unload(bufnr)
  buffers[bufnr] = nil
  if state.timer then state.timer:close() end
  fire(detach_event, { buf = bufnr })
end

---@param bufnr integer
local attach = function(bufnr)
  if
    buffers[bufnr]
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
  root = uv.fs_realpath(root) or root

  ---@type nvim_threads.Buffer
  local state = {
    repo = repo_for(root),
    path = assert(vim.fs.relpath(root, path)),
    marks = {},
  }
  buffers[bufnr] = state

  local on_change = function()
    if buffers[bufnr] ~= state then return true end
    state.timer = state.timer or assert(uv.new_timer())
    state.timer:start(
      sync_debounce_ms,
      0,
      vim.schedule_wrap(function()
        if buffers[bufnr] == state then sync(bufnr) end
      end)
    )
  end

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = on_change,
    on_reload = function()
      vim.schedule(function()
        if buffers[bufnr] == state then reload(bufnr) end
      end)
    end,
    on_detach = function()
      vim.schedule(function()
        if buffers[bufnr] == state then detach(bufnr) end
      end)
    end,
  })

  fire(attach_event, { buf = bufnr, float = false })
  with_change(state.repo, function() load(bufnr) end)
end

--- Returns the threads whose virtual lines follow the given row, in the
--- order they're drawn in.
---@param bufnr integer
---@param row integer
---@return nvim_threads.Thread[]
local threads_after = function(bufnr, row)
  local state = buffers[bufnr]
  local entry = state and entry_of(state)
  if not state or not entry then return {} end
  local found = vim.tbl_filter(function(thread)
    local mark = state.marks[thread.id]
    return mark ~= nil and mark.display_row == row
  end, entry.threads)
  ---@param thread nvim_threads.Thread
  ---@return integer
  local display_id = function(thread)
    local mark = state.marks[thread.id]
    return mark and mark.display or 0
  end
  table.sort(found, function(a, b) return display_id(a) < display_id(b) end)
  return found
end

--- Returns the number of virtual lines of the threads drawn before a thread
--- after the same row.
---@param bufnr integer
---@param thread nvim_threads.Thread
---@return integer
local offset_of = function(bufnr, thread)
  local state = assert(buffers[bufnr])
  local row = assert(state.marks[thread.id]).display_row or 0
  local offset = 0
  for _, other in ipairs(threads_after(bufnr, row)) do
    if other.id == thread.id then break end
    offset = offset + #(drawn_rows[other.id] or {})
  end
  return offset
end

---@param bufnr integer
---@param thread nvim_threads.Thread
local highlight_anchor = function(bufnr, thread)
  vim.api.nvim_buf_clear_namespace(bufnr, highlight_namespace, 0, -1)
  local anchor = thread.anchor
  vim.api.nvim_buf_set_extmark(
    bufnr,
    highlight_namespace,
    anchor.start_row,
    anchor.start_col,
    {
      end_row = anchor.end_row,
      end_col = anchor.end_col,
      hl_group = "ThreadsAnchor",
      strict = false,
    }
  )
end

--- Updates a thread's draft from its float's composer, and redraws it.
---@param buf integer The float's buffer.
local composer_changed = function(buf)
  local win = vim.fn.win_findbuf(buf)[1]
  local current = win and float.get(win)
  if not current then return end
  local thread = thread_of(current.source_buf, current.thread_id)
  if not thread then return end

  local lines = vim.api.nvim_buf_get_lines(buf, current.history, -1, false)
  if #lines == 0 then
    -- The composer always keeps a line to type in.
    filling[buf] = true
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "" })
    filling[buf] = nil
    lines = { "" }
  end
  view_of(thread.id).draft = lines
  draw(current.source_buf, thread)
end

---@alias nvim_threads.FloatLine "first"|"last"|"composer"

--- Opens the float of a thread displayed in a buffer, and moves the cursor
--- into it.
---@param bufnr integer
---@param thread nvim_threads.Thread
---@param opts { line: nvim_threads.FloatLine, virtcol?: integer, insert?: boolean, source_win?: integer }
local open_float = function(bufnr, thread, opts)
  local source_win = opts.source_win or window_of(bufnr)
  if not source_win then return end

  for _, win in ipairs(float.of_buffer(bufnr)) do
    float.close(win)
  end

  local view = view_of(thread.id)
  if view.expanded and not view.draft then view.draft = { "" } end
  draw(bufnr, thread)
  local rows = drawn_rows[thread.id] or {}
  local state = assert(buffers[bufnr])
  local mark = assert(state.marks[thread.id])
  local row = mark.display_row or display_row(thread.anchor)
  local offset = offset_of(bufnr, thread)
  float.reveal(source_win, row, offset, #rows)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "nvim-threads"
  pcall(vim.api.nvim_buf_set_name, buf, "nvim-threads://" .. thread.id)

  ---@type nvim_threads.Float
  local current = {
    thread_id = thread.id,
    source_buf = bufnr,
    source_win = source_win,
    row = row,
    offset = offset,
    source_scroll = {},
    borders = {},
    history = 0,
  }
  local win = float.open(buf, current, #rows)
  if not win then
    vim.api.nvim_buf_delete(buf, { force = true })
    return
  end
  fill(win, rows, true)

  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      if filling[buf] then return end
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then composer_changed(buf) end
      end)
    end,
  })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    buffer = buf,
    desc = "Lets only the composer be edited",
    callback = function() update_modifiable(vim.api.nvim_get_current_win()) end,
  })
  -- Deleting past the composer's edges would join its lines with the ones
  -- around it, so it does nothing there.
  ---@param keys string
  ---@param at_edge fun(row: integer, col: integer, text: string, rows: integer): boolean The cursor's 1-based row in the composer, its column, its line, and the composer's number of lines.
  local stop_at_edge = function(keys, at_edge)
    vim.keymap.set("i", keys, function()
      local win = vim.api.nvim_get_current_win()
      local shown = float.get(win)
      if shown then
        local cursor = vim.api.nvim_win_get_cursor(win)
        local rows = vim.api.nvim_buf_line_count(buf) - shown.history
        local text = vim.api.nvim_get_current_line()
        if at_edge(cursor[1] - shown.history, cursor[2], text, rows) then
          return ""
        end
      end
      -- The mapping replaces the keycodes in what it returns.
      return keys
    end, {
      buffer = buf,
      expr = true,
      desc = "Delete, except past the composer's edges",
    })
  end
  for _, keys in ipairs({ "<BS>", "<C-h>", "<C-w>", "<C-u>" }) do
    stop_at_edge(keys, function(row, col) return row <= 1 and col == 0 end)
  end
  stop_at_edge(
    "<Del>",
    function(row, col, text, rows) return row >= rows and col >= #text end
  )

  vim.api.nvim_create_autocmd("InsertLeave", {
    buffer = buf,
    desc = "Records where insert mode was left in the composer",
    callback = function()
      local shown = float.get(vim.api.nvim_get_current_win())
      if not shown then return end
      local mark = vim.api.nvim_buf_get_mark(buf, "^")
      if mark[1] > shown.history then
        view.insert_at = { mark[1] - shown.history - 1, mark[2] }
      end
    end,
  })

  vim.lsp.start({
    name = "nvim-threads",
    cmd = server.server(function(float_buf)
      local float_win = vim.fn.win_findbuf(float_buf)[1]
      local shown = float_win and float.get(float_win)
      return shown and participants_of(shown.source_buf) or {}
    end),
    root_dir = state.repo.root,
  }, { bufnr = buf })

  highlight_anchor(bufnr, thread)
  fire(attach_event, { buf = buf, float = true })

  local line_count = vim.api.nvim_buf_line_count(buf)
  local line = opts.line == "first" and 1
    or opts.line == "last" and line_count
    or line_count
  float.enter(win, { line = line, virtcol = opts.virtcol or 1 })
  update_modifiable(win)
  if opts.insert then vim.cmd("startinsert!") end
end

--- Forgets a thread whose float closed if it never got a comment, and
--- otherwise collapses it, keeping its draft if it has one.
---@param thread_id string
---@param source_buf integer
local on_float_closed = function(thread_id, source_buf)
  if vim.api.nvim_buf_is_valid(source_buf) then
    vim.api.nvim_buf_clear_namespace(source_buf, highlight_namespace, 0, -1)
  end
  local thread = thread_of(source_buf, thread_id)
  if not thread then return end

  local view = view_of(thread_id)
  local is_empty = not view.draft
    or vim.trim(table.concat(view.draft, "\n")) == ""
  if is_empty then view.draft = nil end

  if #thread.comments == 0 and is_empty then
    M.delete_thread(thread)
    return
  end
  view.expanded = false
  draw(source_buf, thread)
end

--- Returns the current float's thread, the float and its window.
---@return nvim_threads.Thread?
---@return nvim_threads.Float?
---@return integer win
local current_thread = function()
  local win = vim.api.nvim_get_current_win()
  local current = float.get(win)
  if not current then return nil, nil, win end
  return thread_of(current.source_buf, current.thread_id), current, win
end

--- Moves the cursor from a float to its source window, on the line before
--- or after the thread's virtual lines.
---@param win integer
---@param current nvim_threads.Float
---@param line integer
local leave_float = function(win, current, line)
  if not vim.api.nvim_win_is_valid(current.source_win) then
    return float.close(win)
  end
  local virtcol = vim.fn.winsaveview().curswant + 1
  vim.cmd(
    ("noautocmd call nvim_set_current_win(%d)"):format(current.source_win)
  )
  local line_count = vim.api.nvim_buf_line_count(current.source_buf)
  vim.api.nvim_win_set_cursor(
    current.source_win,
    { math.max(math.min(line, line_count), 1), 0 }
  )
  vim.cmd(("normal! %d|"):format(virtcol))
  float.close(win)
end

--- Returns the names mentioned in a comment, and those that aren't
--- participants of the buffer.
---@param body string
---@param bufnr integer
---@return string[] known
---@return string[] unknown
local mentions = function(body, bufnr)
  local available = {}
  for _, name in ipairs(participants_of(bufnr)) do
    available[name] = true
  end
  local known, unknown, seen = {}, {}, {}
  for name in body:gmatch("@([%w_.-]+)") do
    name = name:gsub("[.-]+$", "")
    if name ~= "" and not seen[name] then
      seen[name] = true
      table.insert(available[name] and known or unknown, name)
    end
  end
  return known, unknown
end

--- Returns the file of a thread, as the source of its context.
---@param thread nvim_threads.Thread
---@return nvim_threads.Source?
local source_of = function(thread)
  local location = locations[thread.id]
  if not location then return end
  local root = location.repo.root
  local abs_path = vim.fs.joinpath(root, location.path)
  local bufnr = buffers_of(thread)[1]
  local lines = bufnr and vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    or suggestion.read_lines(abs_path)
    or {}
  return {
    root = root,
    path = location.path,
    lines = lines,
    filetype = bufnr and vim.bo[bufnr].filetype or vim.filetype.match({
      filename = abs_path,
    }) or "",
    bufnr = bufnr,
  }
end

--- Asks a participant to reply to a thread's last comment, streaming its
--- reply into the thread.
---@param thread nvim_threads.Thread
---@param name string
---@param request nvim_threads.Request
local start_reply = function(thread, name, request)
  local participant = participants[name]
  local id = thread.id
  -- A thread deleted while its context was built doesn't have a view.
  local view = views[id]
  if not participant or not view then return end

  -- A newer comment supersedes the one being replied to.
  local previous = cancels[id] and cancels[id][name]
  if previous then pcall(previous) end

  ---@type { finished: boolean }
  local reply_state = { finished = false }
  view.pending[name] = ""
  cancels[id] = cancels[id] or {}

  ---@param comment nvim_threads.Comment
  local finish = function(comment)
    if reply_state.finished or views[id] ~= view then return end
    reply_state.finished = true
    view.pending[name] = nil
    cancels[id][name] = nil
    table.insert(thread.comments, comment)
    persist(thread)
    redraw(thread)
    update_spinner()
  end

  ---@type nvim_threads.Reply
  local reply = {
    chunk = function(text)
      vim.schedule(function()
        if reply_state.finished or views[id] ~= view then return end
        view.pending[name] = (view.pending[name] or "") .. text
        redraw(thread)
      end)
    end,
    done = function(result)
      vim.schedule(function()
        result = result or {}
        local body = result.body or view.pending[name] or ""
        if result.title and vim.trim(result.title) ~= "" then
          thread.title = vim.trim(result.title)
        end
        finish({
          author = name,
          body = vim.trim(body),
          time = os.time(),
          edits = result.edits and #result.edits > 0 and result.edits or nil,
        })
      end)
    end,
    error = function(message)
      vim.schedule(
        function()
          finish({
            author = name,
            body = message,
            time = os.time(),
            error = true,
          })
        end
      )
    end,
  }

  redraw(thread)
  update_spinner()
  local ok, cancel = pcall(participant.send, request, reply)
  if not ok then
    reply.error(tostring(cancel))
  elseif type(cancel) == "function" and not reply_state.finished then
    cancels[id][name] = cancel
  end
end

--- Sends a thread's last comment to its participants, or names the thread
--- with the titler when its first comment mentions none.
---@param thread nvim_threads.Thread
local request_replies = function(thread)
  local names = vim.tbl_filter(
    function(name) return participants[name] ~= nil end,
    thread.participants
  )
  local wants_title = #names == 0
    and #thread.comments == 1
    and not thread.title
    and config.titler ~= nil
  if #names == 0 and not wants_title then return end

  local source = source_of(thread)
  local location = locations[thread.id]
  if not source or not location then return end
  -- The requests show the thread as it was when it was sent.
  local snapshot = vim.deepcopy(thread)

  -- The thread waits on the participants while its context is built.
  local view = view_of(thread.id)
  for _, name in ipairs(names) do
    view.pending[name] = ""
  end
  if #names > 0 then
    redraw(thread)
    update_spinner()
  end

  context.build(source, snapshot.anchor, function(built)
    ---@type nvim_threads.Request
    local request = {
      thread = snapshot,
      root = source.root,
      path = source.path,
      context = built,
      prompt = context.prompt(built, snapshot),
    }
    if wants_title then
      local titler = assert(config.titler)
      titler(request, function(title)
        vim.schedule(function()
          if not locations[thread.id] or vim.trim(title) == "" then return end
          thread.title = vim.trim(title)
          persist(thread)
          redraw(thread)
        end)
      end)
    end
    for _, name in ipairs(names) do
      start_reply(thread, name, request)
    end
  end)
end

--- Moves threads of a file from one change into another. Their anchors are
--- ranges in the file's current lines.
---@param repo nvim_threads.Repo
---@param path string
---@param threads nvim_threads.Thread[]
---@param from string
---@param into string
---@param lines string[]
local transfer = function(repo, path, threads, from, into, lines)
  if #threads == 0 or from == into then return end
  local from_entry = store.load(repo.repo_dir, from).files[path]
  if not from_entry then return end
  local into_entry = store.entry(repo.repo_dir, into, path, lines)
  store.remap(into_entry, lines)

  local moving = {}
  for _, thread in ipairs(threads) do
    moving[thread.id] = true
  end
  from_entry.threads = vim.tbl_filter(
    function(thread) return not moving[thread.id] end,
    from_entry.threads
  )
  vim.list_extend(into_entry.threads, threads)

  for bufnr, state in pairs(buffers) do
    if state.repo == repo and state.path == path then
      for _, thread in ipairs(threads) do
        local mark = state.marks[thread.id]
        if mark then
          vim.api.nvim_buf_del_extmark(bufnr, anchor_namespace, mark.anchor)
          if mark.display then
            vim.api.nvim_buf_del_extmark(bufnr, render.namespace, mark.display)
          end
          state.marks[thread.id] = nil
        end
        local win = float.of_thread(thread.id)
        if win then float.close(win) end
      end
    end
  end
  for _, thread in ipairs(threads) do
    local location = locations[thread.id]
    if location then location.change_id = into end
  end

  save_now(repo.repo_dir, from)
  save_now(repo.repo_dir, into)
  fire(changed_event)
end

--- Returns the loaded buffer displaying a file's threads.
---@param repo nvim_threads.Repo
---@param path string
---@return integer?
local buffer_of_file = function(repo, path)
  for bufnr, state in pairs(buffers) do
    if state.repo == repo and state.path == path then return bufnr end
  end
end

--- Returns a file's current lines, from its buffer if it's loaded.
---@param repo nvim_threads.Repo
---@param path string
---@return string[]
local file_lines = function(repo, path)
  local bufnr = buffer_of_file(repo, path)
  if bufnr then return buffer_lines(bufnr) end
  local lines = suggestion.read_lines(vim.fs.joinpath(repo.root, path)) or {}
  if #lines == 1 and lines[1] == "" then return {} end
  return lines
end

--- Returns whether a buffer displays the threads of its file.
---@param bufnr integer 0 for the current buffer.
---@return boolean
M.is_attached = function(bufnr)
  if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
  return buffers[bufnr] ~= nil
end

--- Returns whether a thread is waiting on a participant's reply or on me.
---@param thread nvim_threads.Thread
---@return "waiting on agent"|"waiting on me"
M.status = function(thread)
  local view = views[thread.id]
  if view and next(view.pending) then return "waiting on agent" end
  return "waiting on me"
end

--- Registers a participant that comments mention by its name, replacing the
--- one of the same name.
---@param participant nvim_threads.Participant
M.register = function(participant)
  vim.validate("name", participant.name, "string")
  vim.validate("send", participant.send, "function")
  participants[participant.name] = participant
end

---@param name string
M.unregister = function(name) participants[name] = nil end

--- Opens a new thread on the visual selection, or on the cursor's line,
--- with its composer focused. Returns false without doing anything outside
--- of a buffer of a jj workspace.
---@return boolean
M.create = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local state = buffers[bufnr]
  if not state or not state.change_id then return false end

  local mode = vim.fn.mode()
  local is_visual = mode == "v" or mode == "V" or mode == "\22"

  ---@type nvim_threads.Anchor
  local anchor
  if is_visual then
    local start, finish = vim.fn.getpos("v"), vim.fn.getpos(".")
    if
      start[2] > finish[2] or (start[2] == finish[2] and start[3] > finish[3])
    then
      start, finish = finish, start
    end
    local last_line = vim.api.nvim_buf_get_lines(
      bufnr,
      finish[2] - 1,
      finish[2],
      false
    )[1] or ""
    local end_col = #last_line
    if mode == "v" and #last_line > 0 then
      local col = math.min(finish[3], #last_line)
      end_col = col + vim.str_utf_end(last_line, col)
    end
    anchor = {
      start_row = start[2] - 1,
      start_col = mode == "v" and start[3] - 1 or 0,
      end_row = finish[2] - 1,
      end_col = end_col,
    }
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  else
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1]
    anchor = {
      start_row = line - 1,
      start_col = 0,
      end_row = line - 1,
      end_col = #(text or ""),
    }
  end

  sync(bufnr)
  local lines = buffer_lines(bufnr)
  local entry = assert(entry_of(state, lines))
  store.remap(entry, lines)

  ---@type nvim_threads.Thread
  local thread = {
    id = new_id(),
    anchor = anchor,
    comments = {},
    participants = {},
  }
  table.insert(entry.threads, thread)
  local view = view_of(thread.id)
  view.expanded = true
  view.draft = { "" }
  place(bufnr, state, thread)
  draw(bufnr, thread)
  open_float(bufnr, thread, { line = "composer", insert = true })
  return true
end

--- Adds the current float's composer to its thread as a comment, sends it to
--- the thread's participants, and empties the composer, where the cursor
--- stays. Returns false outside of a float.
---@return boolean
M.submit = function()
  local thread, current, win = current_thread()
  if not thread or not current then return false end

  local buf = vim.api.nvim_win_get_buf(win)
  local lines = vim.api.nvim_buf_get_lines(buf, current.history, -1, false)
  local body = vim.trim(table.concat(lines, "\n"))
  if body == "" then return true end

  vim.cmd.stopinsert()
  local known, unknown = mentions(body, current.source_buf)
  if #unknown > 0 then
    notify_warn(("No participant named %s"):format(table.concat(unknown, ", ")))
  end
  for _, name in ipairs(known) do
    if not vim.tbl_contains(thread.participants, name) then
      table.insert(thread.participants, name)
    end
  end
  table.insert(
    thread.comments,
    { author = "me", body = body, time = os.time() }
  )

  local view = view_of(thread.id)
  view.draft = { "" }
  view.insert_at = nil
  draw(current.source_buf, thread, true)
  vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
  persist(thread)
  request_replies(thread)
  return true
end

--- Starts insert mode in the current float's composer when the cursor is
--- above it, where insert mode was last left there or else at its end.
--- Returns false without doing anything outside of floats, in a collapsed
--- thread, or when the cursor is in the composer.
---@return boolean
M.insert_in_composer = function()
  local thread, current, win = current_thread()
  if not thread or not current then return false end
  local buf = vim.api.nvim_win_get_buf(win)
  local line_count = vim.api.nvim_buf_line_count(buf)
  local line = vim.api.nvim_win_get_cursor(win)[1]
  if line > current.history or line_count == current.history then
    return false
  end

  local view = view_of(thread.id)
  local row, col = line_count, nil
  if view.insert_at then
    row = math.min(current.history + view.insert_at[1] + 1, line_count)
    col = view.insert_at[2]
  end
  local text = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
  vim.bo[buf].modifiable = true
  if not col or col >= #text then
    vim.api.nvim_win_set_cursor(win, { row, #text })
    vim.cmd("startinsert!")
  else
    vim.api.nvim_win_set_cursor(win, { row, col })
    vim.cmd.startinsert()
  end
  return true
end

--- Expands or collapses the current float's thread. Returns false outside of
--- a float.
---@return boolean
M.toggle = function()
  local thread, current = current_thread()
  if not thread or not current then return false end
  local view = view_of(thread.id)
  view.expanded = not view.expanded
  if view.expanded then
    view.draft = view.draft or { "" }
  elseif view.draft and vim.trim(table.concat(view.draft, "\n")) == "" then
    view.draft = nil
  end
  draw(current.source_buf, thread, true)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  return true
end

--- Acts on the row under the cursor in a float: it expands or collapses the
--- thread on its header, reviews the suggested edits on a suggestion, and
--- sends the comment in the composer. Returns false elsewhere.
---@return boolean
M.activate = function()
  local thread, current = current_thread()
  if not thread or not current then return false end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  if line > current.history then return M.submit() end
  local history = split_rows(drawn_rows[thread.id] or {})
  local row = history[line]
  if not row then return false end
  if row.kind == "header" then return M.toggle() end
  if row.kind == "suggestion" and row.comment then
    M.review(thread, row.comment)
    return true
  end
  return false
end

--- Deletes a thread, cancelling the replies in progress.
---@param thread nvim_threads.Thread
M.delete_thread = function(thread)
  local location = locations[thread.id]
  for _, cancel in pairs(cancels[thread.id] or {}) do
    pcall(cancel)
  end
  cancels[thread.id] = nil

  for _, bufnr in ipairs(buffers_of(thread)) do
    local state = assert(buffers[bufnr])
    local mark = state.marks[thread.id]
    if mark then
      vim.api.nvim_buf_del_extmark(bufnr, anchor_namespace, mark.anchor)
      if mark.display then
        vim.api.nvim_buf_del_extmark(bufnr, render.namespace, mark.display)
      end
      state.marks[thread.id] = nil
    end
  end
  local win = float.of_thread(thread.id)
  if win then float.close(win) end

  views[thread.id] = nil
  drawn_rows[thread.id] = nil
  locations[thread.id] = nil
  update_spinner()

  if not location then return end
  local entry =
    store.load(location.repo.repo_dir, location.change_id).files[location.path]
  if entry then
    entry.threads = vim.tbl_filter(
      function(other) return other.id ~= thread.id end,
      entry.threads
    )
  end
  save_now(location.repo.repo_dir, location.change_id)
  fire(changed_event)
end

--- Deletes the current float's thread when the cursor is on its header.
--- Returns false elsewhere.
---@return boolean
M.delete = function()
  local thread, current, win = current_thread()
  if not thread or not current then return false end
  if vim.api.nvim_win_get_cursor(win)[1] ~= 1 then return false end
  leave_float(win, current, current.row + 1)
  M.delete_thread(thread)
  return true
end

--- Moves the current float's thread into another change when the cursor is
--- on its header. When the revset resolves to several changes, one is
--- picked with `vim.ui.select`. Returns false elsewhere.
---@param into string A revset, e.g. `@-`.
---@return boolean
M.move_thread = function(into)
  local thread, current, win = current_thread()
  if not thread or not current then return false end
  if vim.api.nvim_win_get_cursor(win)[1] ~= 1 then return false end
  local location = locations[thread.id]
  if not location then return false end

  local repo, path, from = location.repo, location.path, location.change_id
  local bufnr = current.source_buf
  jj.resolve(repo.root, into, function(err, targets)
    vim.schedule(function()
      if err then return notify_error(err) end
      targets = assert(targets)
      if #targets == 0 then
        return notify_error(("`%s` doesn't resolve to any change"):format(into))
      end
      ---@param change_id string
      local move = function(change_id)
        sync(bufnr)
        transfer(
          repo,
          path,
          { thread },
          from,
          change_id,
          file_lines(repo, path)
        )
      end
      if #targets == 1 then return move(targets[1].change_id) end
      vim.ui.select(targets, {
        prompt = ("Move the thread into which of `%s`?"):format(into),
        format_item = function(target) return target.label end,
      }, function(target)
        if target then move(target.change_id) end
      end)
    end)
  end)
  return true
end

--- Moves the threads of a file in the working-copy commit that overlap the
--- given lines into another change, like the lines moved there.
---@param root string The root of the file's jj workspace.
---@param path string The file's path relative to the root.
---@param lines? integer[] The 1-based lines, or all of the file's threads if unset.
---@param into string The change ID of the change the lines moved into.
M.move = function(root, path, lines, into)
  local repo = repo_for(uv.fs_realpath(root) or root)
  with_change(repo, function()
    local from = assert(repo.change_id)
    if from == into then return end
    local bufnr = buffer_of_file(repo, path)
    if bufnr then sync(bufnr) end
    local entry = store.load(repo.repo_dir, from).files[path]
    if not entry then return end
    local current_lines = file_lines(repo, path)
    store.remap(entry, current_lines)

    local selected = {}
    for _, line in ipairs(lines or {}) do
      selected[line] = true
    end
    local moved = vim.tbl_filter(function(thread)
      if not lines then return true end
      local first, last = context.lines_of(thread.anchor)
      for line = first, last do
        if selected[line] then return true end
      end
      return false
    end, entry.threads)
    transfer(repo, path, moved, from, into, current_lines)
  end)
end

--- Opens the edits a thread's comment suggests for review, in buffers that
--- apply them to their files when written.
---@param thread nvim_threads.Thread
---@param index integer The comment's index.
M.review = function(thread, index)
  local comment = thread.comments[index]
  local location = locations[thread.id]
  if not comment or not comment.edits or not location then return end

  local current_win = vim.api.nvim_get_current_win()
  local current = float.get(current_win)
  if current then leave_float(current_win, current, current.row + 1) end

  suggestion.open({
    root = location.repo.root,
    thread_id = thread.id,
    comment = index,
    edits = comment.edits,
    on_applied = function(path)
      comment.applied = comment.applied or {}
      comment.applied[path] = true
      persist(thread)
      redraw(thread)
    end,
  })
end

--- Moves the cursor by `v:count1` lines by running the given keys, stepping
--- into the float of the thread it would otherwise skip over, or out of the
--- current float when moving past its edge. Only single-line moves step
--- into or out of floats. Returns false without moving outside of floats
--- when there's no thread to step into.
---@param direction 1|-1
---@param keys string The keys moving the cursor by one line, e.g. `j`.
---@return boolean
M.step = function(direction, keys)
  local count = vim.v.count1
  local win = vim.api.nvim_get_current_win()
  local motion = count
    .. vim.api.nvim_replace_termcodes(keys, true, false, true)
  local run = function() vim.cmd.normal({ args = { motion }, bang = true }) end

  local current = float.get(win)
  if current then
    local line = vim.api.nvim_win_get_cursor(win)[1]
    local buf = vim.api.nvim_win_get_buf(win)
    local at_edge = direction > 0 and line == vim.api.nvim_buf_line_count(buf)
      or direction < 0 and line == 1
    if count > 1 or not at_edge then
      run()
      return true
    end

    local virtcol = vim.fn.winsaveview().curswant + 1
    local siblings = threads_after(current.source_buf, current.row)
    for index, thread in ipairs(siblings) do
      local next_thread = thread.id == current.thread_id
        and siblings[index + direction]
      if next_thread then
        open_float(current.source_buf, next_thread, {
          line = direction > 0 and "first" or "last",
          virtcol = virtcol,
          source_win = current.source_win,
        })
        return true
      end
    end
    leave_float(
      win,
      current,
      direction > 0 and current.row + 2 or current.row + 1
    )
    return true
  end

  local bufnr = vim.api.nvim_get_current_buf()
  if count > 1 or not buffers[bufnr] then return false end
  local line = vim.api.nvim_win_get_cursor(win)[1]
  local blocks = threads_after(bufnr, direction > 0 and line - 1 or line - 2)
  local thread = direction > 0 and blocks[1] or blocks[#blocks]
  if not thread then return false end

  open_float(bufnr, thread, {
    line = direction > 0 and "first" or "last",
    virtcol = vim.fn.winsaveview().curswant + 1,
    source_win = win,
  })
  return true
end

--- Moves the cursor to the start of the `count`th thread after it, or
--- before it if the count is negative.
---@param count integer
M.goto_thread = function(count)
  local bufnr = vim.api.nvim_get_current_buf()
  local state = buffers[bufnr]
  if not state or count == 0 then return end

  local rows, seen = {}, {}
  for _, mark in pairs(state.marks) do
    local anchor = read_anchor(bufnr, mark.anchor)
    if anchor and not seen[anchor.start_row] then
      seen[anchor.start_row] = true
      rows[#rows + 1] = anchor.start_row
    end
  end
  table.sort(rows)

  local cursor = vim.api.nvim_win_get_cursor(0)[1] - 1
  local target
  if count > 0 then
    local after = vim.tbl_filter(function(row) return row > cursor end, rows)
    target = after[math.min(count, #after)]
  else
    local before = vim.tbl_filter(function(row) return row < cursor end, rows)
    target = before[math.max(#before + count + 1, 1)]
  end
  if target then vim.api.nvim_win_set_cursor(0, { target + 1, 0 }) end
end

---@class nvim_threads.Listed
---@field root string
---@field path string
---@field thread nvim_threads.Thread
---@field status "waiting on agent"|"waiting on me"

--- Calls back with the threads of the working-copy commit of the workspace
--- containing a directory, with their current anchors.
---@param dir string
---@param on_done fun(threads: nvim_threads.Listed[])
M.list = function(dir, on_done)
  local root = jj.root(dir)
  if not root then return on_done({}) end
  local repo = repo_for(uv.fs_realpath(root) or root)
  with_change(repo, function()
    local change_id = assert(repo.change_id)
    local change = store.load(repo.repo_dir, change_id)
    local listed = {}
    for path, entry in pairs(change.files) do
      local bufnr = buffer_of_file(repo, path)
      if bufnr then
        sync(bufnr)
      else
        store.remap(entry, file_lines(repo, path))
      end
      for _, thread in ipairs(entry.threads) do
        if #thread.comments > 0 then
          locations[thread.id] = locations[thread.id]
            or {
              thread = thread,
              repo = repo,
              change_id = change_id,
              path = path,
            }
          listed[#listed + 1] = {
            root = repo.root,
            path = path,
            thread = thread,
            status = M.status(thread),
          }
        end
      end
    end
    on_done(listed)
  end)
end

--- Returns the title of a thread, or the start of its first comment.
---@param thread nvim_threads.Thread
---@return string
M.title = function(thread) return (render.title(thread)) end

---@param opts? { titler?: fun(request: nvim_threads.Request, on_title: fun(title: string)), spinner?: { frames?: string[], interval?: integer } }
M.setup = function(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
  render.set_highlights()

  local group = vim.api.nvim_create_augroup("nvim-threads", { clear = true })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    desc = "Sets the default highlight groups of threads",
    callback = function() render.set_highlights() end,
  })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = group,
    desc = "Displays the threads of the buffer's file",
    callback = function(ev) attach(ev.buf) end,
  })

  vim.api.nvim_create_autocmd("BufFilePost", {
    group = group,
    desc = "Displays the threads of the buffer's new file",
    callback = function(ev)
      detach(ev.buf)
      attach(ev.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    desc = "Saves the anchors of the buffer's threads",
    callback = function(ev)
      local state = buffers[ev.buf]
      if not state or not state.change_id then return end
      sync(ev.buf)
      save_now(state.repo.repo_dir, state.change_id)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = group,
    desc = "Saves and stops displaying the buffer's threads",
    callback = function(ev) detach(ev.buf) end,
  })

  ---@param bufnr integer
  local redraw_buffer = function(bufnr)
    local state = buffers[bufnr]
    local entry = state and entry_of(state)
    if not entry then return end
    for _, thread in ipairs(entry.threads) do
      draw(bufnr, thread)
    end
  end

  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    desc = "Redraws the threads to fit the buffer's window",
    callback = function(ev) redraw_buffer(ev.buf) end,
  })

  vim.api.nvim_create_autocmd("OptionSet", {
    group = group,
    pattern = {
      "foldcolumn",
      "number",
      "numberwidth",
      "relativenumber",
      "signcolumn",
      "statuscolumn",
    },
    desc = "Redraws the threads over the resized columns left of the text",
    callback = function()
      local wins = vim.v.option_type == "local"
          and { vim.api.nvim_get_current_win() }
        or vim.api.nvim_list_wins()
      for _, win in ipairs(wins) do
        if not float.get(win) then
          redraw_buffer(vim.api.nvim_win_get_buf(win))
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinResized", {
    group = group,
    desc = "Redraws the threads to fit the resized windows",
    callback = function()
      for _, win in ipairs(vim.v.event.windows or {}) do
        if vim.api.nvim_win_is_valid(win) and not float.get(win) then
          redraw_buffer(vim.api.nvim_win_get_buf(win))
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "NvimThreadsFloatClosed",
    desc = "Hides the composer of the thread whose float closed",
    callback = function(ev)
      on_float_closed(ev.data.thread_id, ev.data.source_buf)
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    desc = "Writes the threads",
    callback = function()
      for bufnr in pairs(buffers) do
        sync(bufnr)
      end
      flush_saves()
    end,
  })

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    attach(bufnr)
  end
end

return M
