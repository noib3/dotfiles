local github = require("nvim_jj.github")
local jj = require("nvim_jj.jj")

local M = {}

local uv = vim.uv

--- The delay between a jj operation and the redraw of the logs it triggers.
local op_debounce_ms = 100

--- The prefix of the names of the log buffers, which is followed by the root
--- of their workspace.
local scheme = "jj://"

local filetype = "jjlog"

local namespace = vim.api.nvim_create_namespace("nvim-jj")

--- The namespace of the ephemeral extmarks highlighting code in subjects.
local code_namespace = vim.api.nvim_create_namespace("nvim-jj-code")

---@class nvim_jj.Config
---@field gh string The GitHub CLI's executable.
---@field height integer The height of the log's window.
---@field lookahead integer The number of changes loaded past the last one in view.
---@field remote string The git remote that changes are pushed to.
---@field revset string The revisions in the log.

---@type nvim_jj.Config
local config = {
  gh = "gh",
  height = 14,
  lookahead = 200,
  remote = "origin",
  revset = "::(@ | trunk() | mutable())",
}

---@class nvim_jj.Row
---@field change nvim_jj.Change
---@field graph string The graph drawn on the change's line, including its node.
---@field below nvim_jj.LogLine[] The lines between the change and the next one: its details, then the graph.
---@field marks? { left: integer, right: integer } The IDs of the extmarks drawn on the change's line.

---@class nvim_jj.Load
---@field stream nvim_jj.LogStream
---@field rows nvim_jj.Row[] The rows read but not drawn yet.
---@field replace boolean Whether the read rows are yet to replace the drawn ones.
---@field minimum integer The number of rows read before they replace the drawn ones.
---@field done boolean Whether jj has exited.

---@class nvim_jj.Log
---@field root string The root of the jj workspace.
---@field rows nvim_jj.Row[] The rows drawn in the buffer, one per line.
---@field cut table<string, true?> The IDs of the cut changes.
---@field copied table<string, true?> The IDs of the copied changes.
---@field unpadded? integer The line whose pad was emptied for insert mode.
---@field load? nvim_jj.Load The read of jj's log in progress.
---@field on_drawn fun()[] The callbacks waiting for the next redraw.
---@field timer? uv.uv_timer_t
---@field watcher? uv.uv_fs_event_t

---@type table<integer, nvim_jj.Log?>
local logs = {}

--- The log buffer in insert mode, if any.
---@type integer?
local inserting

--- The text of the line of a change without a subject. Neovim draws the
--- cursor of an empty line in the window's first column, before the line's
--- inline virtual text, and the cursor of any other line after it.
local pad = " "

--- Returns the text of the line of a change.
---@param change nvim_jj.Change
---@return string
local line_text = function(change)
  return change.subject ~= "" and change.subject or pad
end

---@param message string
---@param level? integer
local notify = function(message, level)
  vim.notify(message, level or vim.log.levels.ERROR, { title = "nvim-jj" })
end

--- Returns a change's short ID followed by its subject, for messages.
---@param change nvim_jj.Change
---@return string
local label = function(change)
  local subject = change.subject ~= "" and change.subject
    or "(no description set)"
  return ("%s%s %s"):format(change.prefix, change.rest, subject)
end

--- Returns the highlight of the line of a change that's cut or copied.
---@param bufnr integer
---@param id string
---@return string?
local held_hl = function(bufnr, id)
  local log = logs[bufnr]
  if not log then return end
  if log.cut[id] then return "JjCut" end
  if log.copied[id] then return "JjCopy" end
end

--- Returns the error of rewriting an immutable change.
---@param change nvim_jj.Change
---@return string
local immutable = function(change)
  return ("%s is immutable: jj doesn't rewrite the trunk, tags, untracked remote bookmarks, or what's below them"):format(
    label(change)
  )
end

--- Returns the virtual lines drawn below a row. The details of a cut or
--- copied change are highlighted like its line, across the screen.
---@param row nvim_jj.Row
---@param held? string The highlight of the row's line.
---@return [string, string|string[]][][]
local lines_below = function(row, held)
  return vim.tbl_map(function(line)
    local detail = line.detail
    if not detail then return { { line.graph, "JjGraph" } } end
    local hl = detail.kind == "authors" and "JjAuthor" or "JjTimestamp"
    if not held then return { { line.graph, "JjGraph" }, { detail.text, hl } } end
    local width = vim.api.nvim_strwidth(line.graph .. detail.text)
    return {
      { line.graph, { "JjGraph", held } },
      { detail.text, { hl, held } },
      { (" "):rep(math.max(vim.o.columns - width, 0)), held },
    }
  end, row.below)
end

--- Draws a row's graph and change ID, the lines below it, and the
--- highlight of its line if its change is cut or copied. A row drawn before
--- stays where its line moved to since.
---@param bufnr integer
---@param row nvim_jj.Row
---@param line integer The row's 0-based line when it's drawn for the first time.
local draw_left = function(bufnr, row, line)
  local change = row.change
  local graph_hl = change.working_copy and "JjWorkingCopy" or "JjGraph"
  local held = held_hl(bufnr, change.id)

  local marks = assert(row.marks)
  if marks.left ~= 0 then
    line = vim.api.nvim_buf_get_extmark_by_id(bufnr, namespace, marks.left, {})[1]
      or line
  end
  marks.left = vim.api.nvim_buf_set_extmark(bufnr, namespace, line, 0, {
    id = marks.left ~= 0 and marks.left or nil,
    virt_text = {
      { row.graph, graph_hl },
      { change.prefix, "JjChangeId" },
      { change.rest .. " ", "JjChangeIdRest" },
    },
    virt_text_pos = "inline",
    hl_mode = "combine",
    virt_lines = #row.below > 0 and lines_below(row, held) or nil,
    line_hl_group = held,
    right_gravity = false,
    invalidate = true,
  })
end

--- Returns whether an empty subject on a line of a log buffer shows the
--- placeholder, which it doesn't while it's edited in insert mode.
---@param bufnr integer
---@param line integer The 0-based line.
---@param text string The line's subject.
---@return boolean
local shows_placeholder = function(bufnr, line, text)
  if vim.trim(text) ~= "" then return false end
  return inserting ~= bufnr
    or vim.api.nvim_get_current_buf() ~= bufnr
    or vim.fn.line(".") ~= line + 1
end

--- Draws what follows a row's subject: the change's bookmarks and markers.
--- An empty subject shows a placeholder before them, drawn over the line so
--- that the cursor rests on its first character.
---@param bufnr integer
---@param row nvim_jj.Row
---@param line integer The row's 0-based line.
---@param text string The row's subject in the buffer.
local draw_right = function(bufnr, row, line, text)
  local change = row.change
  local placeholder = shows_placeholder(bufnr, line, text)
  ---@type [string, string][]
  local chunks = {}
  if placeholder then
    chunks[#chunks + 1] = { "(no description set) ", "JjPlaceholder" }
  end
  for _, bookmark in ipairs(change.bookmarks) do
    local hl = vim.endswith(bookmark, "??") and "JjConflict" or "JjBookmark"
    chunks[#chunks + 1] = { bookmark .. " ", hl }
  end
  if change.divergent then
    chunks[#chunks + 1] = { "(divergent) ", "JjDivergent" }
  end
  if change.conflict then
    chunks[#chunks + 1] = { "(conflict) ", "JjConflict" }
  end

  local marks = assert(row.marks)
  marks.right = vim.api.nvim_buf_set_extmark(bufnr, namespace, line, 0, {
    id = marks.right ~= 0 and marks.right or nil,
    virt_text = #chunks > 0 and chunks or { { "" } },
    virt_text_pos = placeholder and "overlay" or "eol",
    hl_mode = "combine",
    invalidate = true,
  })
end

--- Draws the decorations of the rows from a line on, which must match the
--- buffer's lines.
---@param bufnr integer
---@param log nvim_jj.Log
---@param first integer The first row, 1-based.
local draw_rows = function(bufnr, log, first)
  local texts = vim.api.nvim_buf_get_lines(bufnr, first - 1, #log.rows, false)
  for index = first, #log.rows do
    local row, line = log.rows[index], index - 1
    row.marks = { left = 0, right = 0 }
    draw_left(bufnr, row, line)
    draw_right(bufnr, row, line, texts[index - first + 1] or "")
  end
end

---@class nvim_jj.Mark
---@field line integer The 0-based line.
---@field invalid boolean Whether the mark is hidden because its line was deleted or replaced.
---@field placeholder boolean Whether the mark starts with the placeholder of an empty subject.

--- Returns a log buffer's extmarks, keyed by ID.
---@param bufnr integer
---@return table<integer, nvim_jj.Mark?>
local marks_of = function(bufnr)
  local marks = {}
  local items =
    vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, { details = true })
  for _, item in ipairs(items) do
    local details = item[4] or {}
    local first = (details.virt_text or {})[1]
    marks[item[1]] = {
      line = item[2],
      invalid = details.invalid == true,
      placeholder = first ~= nil and first[2] == "JjPlaceholder",
    }
  end
  return marks
end

--- Returns whether each of a log buffer's lines is still the one its row was
--- drawn on, i.e. no line was added, removed or moved since. A line replaced
--- in place, e.g. by pasting over it, still counts as its row's.
---@param bufnr integer
---@param log nvim_jj.Log
---@return boolean
local is_intact = function(bufnr, log)
  if vim.api.nvim_buf_line_count(bufnr) ~= #log.rows then return false end
  local marks = marks_of(bufnr)
  for index, row in ipairs(log.rows) do
    local mark = row.marks and marks[row.marks.left]
    if not mark or mark.line ~= index - 1 then return false end
  end
  return true
end

--- Redraws the decorations of the rows whose lines were edited: the
--- placeholders of the subjects emptied, filled in or edited in insert mode,
--- and the decorations hidden by replacing a line in place.
---@param bufnr integer
---@param log nvim_jj.Log
local redraw_edited = function(bufnr, log)
  if vim.api.nvim_buf_line_count(bufnr) ~= #log.rows then return end
  local texts = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local marks = marks_of(bufnr)
  for index, row in ipairs(log.rows) do
    local text, line = texts[index] or "", index - 1
    local left = row.marks and marks[row.marks.left]
    local right = row.marks and marks[row.marks.right]
    if left and left.line == line then
      if left.invalid then
        draw_left(bufnr, row, line)
        draw_right(bufnr, row, line, text)
      elseif
        right and right.placeholder ~= shows_placeholder(bufnr, line, text)
      then
        draw_right(bufnr, row, line, text)
      end
    end
  end
end

--- Returns the row of a change.
---@param log nvim_jj.Log
---@param id string
---@return integer?
local row_of = function(log, id)
  for index, row in ipairs(log.rows) do
    if row.change.id == id then return index end
  end
end

--- Returns the row of the working-copy commit.
---@param log nvim_jj.Log
---@return integer?
local working_copy_row = function(log)
  for index, row in ipairs(log.rows) do
    if row.change.working_copy then return index end
  end
end

--- Moves the cursor of each window showing a buffer to a line.
---@param bufnr integer
---@param line integer
local set_cursors = function(bufnr, line)
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    vim.api.nvim_win_set_cursor(win, { line, 0 })
  end
end

--- Returns the number of rows that fill the windows showing a log buffer,
--- down to the bottom of the view of the last one.
---@param bufnr integer
---@return integer
local rows_in_view = function(bufnr)
  local rows = 0
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    -- The top line lags behind the cursor until the next redraw.
    local top = math.max(
      vim.fn.line("w0", win),
      vim.api.nvim_win_get_cursor(win)[1]
    )
    rows = math.max(rows, top + vim.api.nvim_win_get_height(win))
  end
  return rows
end

--- Replaces a log buffer's lines with the subjects of the given rows,
--- keeping each window's cursor on the change and column it was on.
---@param bufnr integer
---@param log nvim_jj.Log
---@param rows nvim_jj.Row[]
local replace_rows = function(bufnr, log, rows)
  ---@type table<integer, { id: string, col: integer, offset: integer }>
  local views = {}
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    local line, col = unpack(vim.api.nvim_win_get_cursor(win))
    local row = log.rows[line]
    if row then
      views[win] = {
        id = row.change.id,
        col = col,
        offset = line - vim.fn.line("w0", win),
      }
    end
  end

  log.rows = rows

  -- Undoing past a redraw would bring back the subjects jj had before it.
  local undolevels = vim.bo[bufnr].undolevels
  vim.bo[bufnr].undolevels = -1
  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  vim.api.nvim_buf_set_lines(
    bufnr,
    0,
    -1,
    false,
    vim.tbl_map(function(row) return line_text(row.change) end, rows)
  )
  vim.bo[bufnr].undolevels = undolevels
  vim.bo[bufnr].modified = false
  draw_rows(bufnr, log, 1)

  for win, view in pairs(views) do
    local line = row_of(log, view.id)
    if line then
      vim.api.nvim_win_call(win, function()
        vim.fn.winrestview({
          lnum = line,
          col = view.col,
          topline = math.max(1, line - view.offset),
        })
      end)
    end
  end
end

--- Appends rows to a log buffer.
---@param bufnr integer
---@param log nvim_jj.Log
---@param rows nvim_jj.Row[]
local append_rows = function(bufnr, log, rows)
  local first = #log.rows + 1
  vim.list_extend(log.rows, rows)

  -- Appending to an unmodified buffer would be its only undoable change.
  local undolevels = vim.bo[bufnr].undolevels
  vim.bo[bufnr].undolevels = -1
  vim.api.nvim_buf_set_lines(
    bufnr,
    first - 1,
    -1,
    false,
    vim.tbl_map(function(row) return line_text(row.change) end, rows)
  )
  vim.bo[bufnr].undolevels = undolevels
  vim.bo[bufnr].modified = false
  draw_rows(bufnr, log, first)
end

--- Draws what a log buffer's read of jj's log has read so far, and reads
--- more of it while the windows showing the buffer are close to its end.
--- The rows read replace the drawn ones once there are as many as before
--- and enough to fill the windows, or jj is done, and are then only
--- appended while the buffer is unmodified.
---@param bufnr integer
---@param log nvim_jj.Log
local flush = function(bufnr, log)
  local load = log.load
  if not load then return end

  if load.replace then
    -- The windows may have opened since the read started.
    local minimum = math.max(load.minimum, rows_in_view(bufnr), 1)
    if #load.rows < minimum and not load.done then return end
    load.replace = false
    local rows = load.rows
    load.rows = {}
    replace_rows(bufnr, log, rows)

    local callbacks = log.on_drawn
    log.on_drawn = {}
    for _, callback in ipairs(callbacks) do
      callback()
    end
  elseif
    #load.rows > 0
    and not vim.bo[bufnr].modified
    and vim.api.nvim_buf_line_count(bufnr) == #log.rows
  then
    local rows = load.rows
    load.rows = {}
    append_rows(bufnr, log, rows)
  end

  if load.done then
    log.load = nil
  elseif #log.rows + #load.rows >= rows_in_view(bufnr) + config.lookahead then
    load.stream.pause()
  else
    load.stream.resume()
  end
end

--- Redraws a log buffer from jj's log, discarding the edits to its text.
--- Each window showing it stays on the change it was on. The callback runs
--- after the first redraw that finishes, which may be a later one.
---@param bufnr integer
---@param snapshot boolean Whether to snapshot the working copy first.
---@param on_done? fun()
local render = function(bufnr, snapshot, on_done)
  local log = assert(logs[bufnr])
  if on_done then table.insert(log.on_drawn, on_done) end
  if log.load then log.load.stream.kill() end

  ---@type nvim_jj.Load
  local load
  ---@param lines nvim_jj.LogLine[]
  local on_lines = function(lines)
    if log.load ~= load then return end
    ---@type nvim_jj.Row?
    local last_drawn
    if not load.replace then last_drawn = log.rows[#log.rows] end
    for _, line in ipairs(lines) do
      if line.change then
        load.rows[#load.rows + 1] =
          { change = line.change, graph = line.graph, below = {} }
      else
        ---@type nvim_jj.Row?
        local last = load.rows[#load.rows] or last_drawn
        if last then
          table.insert(last.below, line)
          if last == last_drawn and last.marks then
            draw_left(bufnr, last, #log.rows - 1)
          end
        end
      end
    end
    flush(bufnr, log)
  end

  load = {
    rows = {},
    replace = true,
    minimum = math.max(#log.rows, rows_in_view(bufnr)),
    done = false,
    stream = jj.log(log.root, config.revset, snapshot, on_lines, function(err)
      if log.load ~= load then return end
      load.done = true
      if err then
        log.load = nil
        log.on_drawn = {}
        return notify(err)
      end
      flush(bufnr, log)
    end),
  }
  log.load = load
end

---@param bufnr integer
local release = function(bufnr)
  local log = logs[bufnr]
  if not log then return end
  if log.load then log.load.stream.kill() end
  if log.watcher then log.watcher:close() end
  if log.timer then log.timer:close() end
  logs[bufnr] = nil
end

--- Starts redrawing a log buffer after each of its repo's jj operations. A
--- modified buffer is left alone, to not lose its edits.
---@param bufnr integer
---@param log nvim_jj.Log
local watch = function(bufnr, log)
  local timer = assert(uv.new_timer())
  local watcher = assert(uv.new_fs_event())
  local ok = watcher:start(jj.op_heads_dir(log.root), {}, function()
    timer:start(
      op_debounce_ms,
      0,
      vim.schedule_wrap(function()
        if logs[bufnr] == log and not vim.bo[bufnr].modified then
          render(bufnr, false)
        end
      end)
    )
  end)

  log.timer = timer
  if ok then
    log.watcher = watcher
  else
    watcher:close()
  end
end

--- The commands of the code actions on the changes of the log buffers.
local commands = {
  open_pull_request = "nvim-jj.openPullRequest",
}

--- Returns the log buffer of a URI.
---@param uri string
---@return integer?
local buffer_of_uri = function(uri)
  for bufnr in pairs(logs) do
    if vim.uri.from_buf(bufnr) == uri then return bufnr end
  end
end

--- Returns the code actions on the change on a line of a log buffer.
---@param bufnr integer
---@param line integer The 1-based line.
---@return lsp.CodeAction[]
local code_actions = function(bufnr, line)
  local log = logs[bufnr]
  local row = log and log.rows[line]
  if not row then return {} end

  ---@type lsp.CodeAction[]
  local actions = {}
  if #row.change.local_bookmarks > 0 then
    local title = "Open a pull request"
    actions[#actions + 1] = {
      title = title,
      command = {
        title = title,
        command = commands.open_pull_request,
        arguments = { bufnr, line },
      },
    }
  end
  return actions
end

--- Returns the in-process language server of the log buffers, which serves
--- the code actions on their changes.
---@param dispatchers vim.lsp.rpc.Dispatchers
---@return vim.lsp.rpc.Client
local server = function(dispatchers)
  local closing, request_id = false, 0

  ---@param method string
  ---@param params table
  ---@return any result
  ---@return lsp.ResponseError? err
  local handle = function(method, params)
    if method == "initialize" then
      return {
        capabilities = {
          codeActionProvider = true,
          executeCommandProvider = { commands = vim.tbl_values(commands) },
          textDocumentSync = 0,
        },
        serverInfo = { name = "nvim-jj" },
      }
    elseif method == "shutdown" then
      return vim.NIL
    elseif method == "textDocument/codeAction" then
      local bufnr = buffer_of_uri(params.textDocument.uri)
      return bufnr and code_actions(bufnr, params.range.start.line + 1) or {}
    elseif method == "workspace/executeCommand" then
      local args = params.arguments or {}
      if params.command == commands.open_pull_request then
        M.open_pull_request(args[1], args[2])
      end
      return vim.NIL
    end
    return nil, { code = -32601, message = "Method not found: " .. method }
  end

  local client = {
    request = function(method, params, callback, notify_reply_callback)
      request_id = request_id + 1
      local id = request_id
      vim.schedule(function()
        local result, err = handle(method, params)
        callback(err, result)
        if notify_reply_callback then notify_reply_callback(id) end
      end)
      return true, id
    end,
    notify = function(method)
      if method == "exit" then
        closing = true
        dispatchers.on_exit(0, 0)
      end
      return true
    end,
    is_closing = function() return closing end,
    terminate = function() closing = true end,
  }
  -- The client's private fields are the ones of a process it talks to.
  return client --[[@as vim.lsp.rpc.Client]]
end

--- Draws the log of the workspace a buffer is named after, with the cursor
--- on the working-copy commit.
---@param bufnr integer
local load = function(bufnr)
  local log = logs[bufnr]
  if not log then
    log = {
      root = vim.api.nvim_buf_get_name(bufnr):sub(#scheme + 1),
      rows = {},
      cut = {},
      copied = {},
      on_drawn = {},
    }
    logs[bufnr] = log
    watch(bufnr, log)
  end

  vim.bo[bufnr].buftype = "acwrite"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = filetype
  vim.lsp.start(
    { name = "nvim-jj", cmd = server, root_dir = log.root },
    { bufnr = bufnr }
  )

  render(bufnr, true, function()
    local line = working_copy_row(log)
    if line then set_cursors(bufnr, line) end
  end)
end

--- The error of an action on a log buffer whose lines don't match its rows.
local not_intact =
  "Lines were added, removed or moved. Undo that, or reload with :edit!"

--- The error of a graph operation on a log buffer with unsaved edits, which
--- redrawing the buffer after the operation would discard.
local not_saved = "Save the edited subjects first, or discard them with :edit!"

---@class nvim_jj.Step
---@field label string The operation, e.g. "pasting 2 changes".
---@field undo fun(on_done: fun(err?: string))
---@field redo fun(on_done: fun(err?: string))

---@class nvim_jj.History
---@field undo nvim_jj.Step[]
---@field redo nvim_jj.Step[]
---@field aliases table<string, string> The IDs of the changes recreated since, keyed by their previous IDs.
---@field busy boolean Whether an undo or a redo is running.

--- The histories of the graph operations started from the logs, keyed by
--- workspace root.
---@type table<string, nvim_jj.History?>
local histories = {}

---@param root string
---@return nvim_jj.History
local history_of = function(root)
  local history = histories[root]
  if not history then
    history = { undo = {}, redo = {}, aliases = {}, busy = false }
    histories[root] = history
  end
  return history
end

--- Returns the current ID of a change, which differs from the given one if
--- the change was recreated since.
---@param history nvim_jj.History
---@param id string
---@return string
local current_id = function(history, id)
  while history.aliases[id] do
    id = history.aliases[id]
  end
  return id
end

---@param history nvim_jj.History
---@param ids string[]
---@return string[]
local current_ids = function(history, ids)
  return vim.tbl_map(function(id) return current_id(history, id) end, ids)
end

--- Returns the revset of a set of changes, by their current IDs.
---@param history nvim_jj.History
---@param ids string[]
---@return string
local revset_of = function(history, ids)
  if #ids == 0 then return "none()" end
  return ("(%s)"):format(table.concat(current_ids(history, ids), " | "))
end

--- Records an operation started from a log, which drops the operations
--- undone before it.
---@param root string
---@param step nvim_jj.Step
local record = function(root, step)
  local history = history_of(root)
  table.insert(history.undo, step)
  history.redo = {}
end

--- Returns a number of changes, for messages.
---@param count integer
---@return string
local count_changes = function(count)
  return count == 1 and "1 change" or ("%d changes"):format(count)
end

--- Runs asynchronous functions one after the other, stopping at the first
--- error.
---@param fns fun(on_done: fun(err?: string))[]
---@param on_done fun(err?: string)
local in_sequence = function(fns, on_done)
  local index = 0
  ---@type fun(err?: string)
  local step
  step = function(err)
    if err then return on_done(err) end
    index = index + 1
    local fn = fns[index]
    if not fn then return on_done() end
    fn(step)
  end
  step()
end

--- Returns the full IDs of the changes with the given ID prefixes, keyed by
--- prefix.
---@param root string
---@param prefixes string[]
---@param on_done fun(err?: string, ids?: table<string, string>)
local full_ids = function(root, prefixes, on_done)
  if #prefixes == 0 then return on_done(nil, {}) end
  jj.changes(root, table.concat(prefixes, " | "), function(err, changes)
    if err or not changes then return on_done(err) end
    local ids = {}
    for _, prefix in ipairs(prefixes) do
      for _, change in ipairs(changes) do
        if vim.startswith(change.id, prefix) then ids[prefix] = change.id end
      end
    end
    on_done(nil, ids)
  end)
end

---@class nvim_jj.Group
---@field ids string[] The changes, connected by the edges between them.
---@field parents string[] The parents of the changes outside of the group.
---@field children string[] The children of the changes outside of the group.

--- Splits a set of changes into the groups the edges between them connect,
--- each with its parents and children outside of it.
---@param root string
---@param ids string[]
---@param on_done fun(err?: string, groups?: nvim_jj.Group[])
local groups_of = function(root, ids, on_done)
  local set = ("(%s)"):format(table.concat(ids, " | "))
  jj.parents(root, ("%s | %s+"):format(set, set), function(err, parents)
    if err or not parents then return on_done(err) end

    ---@type table<string, string?>
    local leaders = {}
    for _, id in ipairs(ids) do
      leaders[id] = id
    end
    ---@param id string
    ---@return string
    local leader_of = function(id)
      local leader = leaders[id]
      while leader and leader ~= id do
        id, leader = leader, leaders[leader]
      end
      return id
    end
    for _, id in ipairs(ids) do
      for _, parent in ipairs(parents[id] or {}) do
        if leaders[parent] then leaders[leader_of(id)] = leader_of(parent) end
      end
    end

    ---@type nvim_jj.Group[], table<string, nvim_jj.Group>
    local groups, by_leader = {}, {}
    ---@param id string
    ---@return nvim_jj.Group
    local group_of = function(id)
      local leader = leader_of(id)
      local group = by_leader[leader]
      if not group then
        group = { ids = {}, parents = {}, children = {} }
        by_leader[leader] = group
        groups[#groups + 1] = group
      end
      return group
    end
    ---@param list string[]
    ---@param id string
    local add = function(list, id)
      if not vim.list_contains(list, id) then list[#list + 1] = id end
    end

    for _, id in ipairs(ids) do
      local group = group_of(id)
      add(group.ids, id)
      for _, parent in ipairs(parents[id] or {}) do
        if not leaders[parent] then add(group.parents, parent) end
      end
    end
    for child, child_parents in pairs(parents) do
      if not leaders[child] then
        for _, parent in ipairs(child_parents) do
          if leaders[parent] then add(group_of(parent).children, child) end
        end
      end
    end
    on_done(nil, groups)
  end)
end

--- Returns the place of a group of changes, between its parents and children.
---@param history nvim_jj.History
---@param group nvim_jj.Group
---@return nvim_jj.Place
local place_of = function(history, group)
  local parents = revset_of(history, group.parents)
  if #group.children == 0 then return { onto = parents } end
  return { after = parents, before = revset_of(history, group.children) }
end

--- Moves changes to a place, which is computed each time the move is done or
--- redone. The undo puts each group of the changes back between its parents
--- and children.
---@param root string
---@param ids string[]
---@param place fun(): nvim_jj.Place
---@param what string
---@param on_done fun(err?: string)
local move_changes = function(root, ids, place, what, on_done)
  local history = history_of(root)
  ---@type nvim_jj.Group[]
  local groups = {}

  ---@param done fun(err?: string)
  local move = function(done)
    local revs = current_ids(history, ids)
    groups_of(root, revs, function(err, found)
      if err or not found then return done(err) end
      groups = found
      jj.rebase(root, revs, place(), done)
    end)
  end

  move(function(err)
    if err then return on_done(err) end
    record(root, {
      label = what,
      redo = move,
      undo = function(done)
        in_sequence(
          vim.tbl_map(function(group)
            return function(moved)
              local revs = current_ids(history, group.ids)
              jj.rebase(root, revs, place_of(history, group), moved)
            end
          end, groups),
          done
        )
      end,
    })
    on_done()
  end)
end

--- Abandons changes. The undo recreates them from their commits, under new
--- IDs, and checks out the recreated working-copy commit if it was abandoned.
---@param root string
---@param ids string[]
---@param what string
---@param on_done fun(err?: string)
local abandon_changes = function(root, ids, what, on_done)
  local history = history_of(root)
  ---@type nvim_jj.Group[], table<string, string>, string?
  local groups, commits, working_copy = {}, {}, nil

  ---@param done fun(err?: string)
  local abandon = function(done)
    local revs = current_ids(history, ids)
    jj.changes(root, table.concat(revs, " | "), function(err, changes)
      if err or not changes then return done(err) end
      commits, working_copy = {}, nil
      for _, change in ipairs(changes) do
        commits[change.id] = change.commit_id
        if change.working_copy then working_copy = change.id end
      end
      groups_of(root, revs, function(groups_err, found)
        if groups_err or not found then return done(groups_err) end
        groups = found
        jj.abandon(root, revs, done)
      end)
    end)
  end

  ---@param group nvim_jj.Group
  ---@return fun(done: fun(err?: string))
  local recreate = function(group)
    return function(done)
      local sources = vim.tbl_map(function(id) return commits[id] end, group.ids)
      jj.duplicate(root, sources, place_of(history, group), function(err, copies)
        if err or not copies then
          done(err)
          return
        end
        local prefixes = vim.tbl_map(function(copy) return copy.change end, copies)
        full_ids(root, prefixes, function(ids_err, new_ids)
          if ids_err or not new_ids then
            done(ids_err)
            return
          end
          for _, copy in ipairs(copies) do
            for _, id in ipairs(group.ids) do
              if vim.startswith(commits[id], copy.source) then
                history.aliases[id] = new_ids[copy.change]
              end
            end
          end
          if working_copy and vim.list_contains(group.ids, working_copy) then
            jj.edit(root, current_id(history, working_copy), done)
          else
            done()
          end
        end)
      end)
    end
  end

  abandon(function(err)
    if err then return on_done(err) end
    record(root, {
      label = what,
      redo = abandon,
      undo = function(done) in_sequence(vim.tbl_map(recreate, groups), done) end,
    })
    on_done()
  end)
end

--- Creates an empty change in a place, which is computed each time the change
--- is created or recreated. The undo abandons the change, unless it isn't
--- empty anymore.
---@param root string
---@param place fun(): nvim_jj.Place
---@param what string
---@param on_done fun(err?: string, id?: string)
local create_change = function(root, place, what, on_done)
  local history = history_of(root)
  ---@type string?
  local created

  ---@param done fun(err?: string)
  local create = function(done)
    jj.new(root, place(), false, function(err, prefix)
      if err or not prefix then return done(err or "jj didn't name the new change") end
      full_ids(root, { prefix }, function(ids_err, ids)
        if ids_err or not ids then return done(ids_err) end
        local id = ids[prefix]
        if created then history.aliases[created] = id end
        created = id
        done()
      end)
    end)
  end

  create(function(err)
    if err then return on_done(err) end
    record(root, {
      label = what,
      redo = create,
      undo = function(done)
        local id = current_id(history, assert(created))
        jj.changes(root, id, function(changes_err, changes)
          if changes_err or not changes then return done(changes_err) end
          local change = changes[1]
          if change and not change.empty then
            return done(("%s isn't empty anymore"):format(label(change)))
          end
          jj.abandon(root, { id }, done)
        end)
      end,
    })
    on_done(nil, created)
  end)
end

--- Copies changes to a place, which is computed each time they're copied or
--- copied again. The undo abandons the copies.
---@param root string
---@param ids string[]
---@param place fun(): nvim_jj.Place
---@param what string
---@param on_done fun(err?: string, copies?: string[])
local copy_changes = function(root, ids, place, what, on_done)
  local history = history_of(root)
  --- The IDs of the copies, keyed by the copied changes' IDs.
  ---@type table<string, string?>
  local copies = {}

  ---@param done fun(err?: string)
  local copy = function(done)
    local revs = current_ids(history, ids)
    ---@type table<string, string>
    local originals = {}
    for index, id in ipairs(ids) do
      originals[revs[index]] = id
    end
    jj.changes(root, table.concat(revs, " | "), function(err, changes)
      if err or not changes then return done(err) end
      jj.duplicate(root, revs, place(), function(dup_err, made)
        if dup_err or not made then return done(dup_err) end
        local prefixes = vim.tbl_map(function(made_copy) return made_copy.change end, made)
        full_ids(root, prefixes, function(ids_err, new_ids)
          if ids_err or not new_ids then return done(ids_err) end
          for _, made_copy in ipairs(made) do
            for _, change in ipairs(changes) do
              if vim.startswith(change.commit_id, made_copy.source) then
                local source = originals[change.id] or change.id
                local new_id = new_ids[made_copy.change]
                if copies[source] then history.aliases[copies[source]] = new_id end
                copies[source] = new_id
              end
            end
          end
          done()
        end)
      end)
    end)
  end

  copy(function(err)
    if err then return on_done(err) end
    record(root, {
      label = what,
      redo = copy,
      undo = function(done)
        jj.abandon(root, current_ids(history, vim.tbl_values(copies)), done)
      end,
    })
    on_done(nil, vim.tbl_values(copies))
  end)
end

---@class nvim_jj.Edit
---@field change nvim_jj.Change
---@field subject string

--- Returns the subjects edited in a log buffer, or an error if lines were
--- added, removed or moved.
---@param bufnr integer
---@param log nvim_jj.Log
---@return string? err
---@return nvim_jj.Edit[]? edits
local edits_of = function(bufnr, log)
  if not is_intact(bufnr, log) then return not_intact end

  local texts = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  ---@type nvim_jj.Edit[]
  local edits = {}
  for index, row in ipairs(log.rows) do
    local text = vim.trim(texts[index] or "")
    local change = row.change
    if text ~= vim.trim(change.subject) then
      if change.immutable then
        return immutable(change)
      end
      edits[#edits + 1] = { change = change, subject = text }
    end
  end
  return nil, edits
end

--- Returns a description with its first line replaced by a subject. An empty
--- subject empties the whole description, which the log then shows as having
--- none.
---@param description string
---@param subject string
---@return string
local with_subject = function(description, subject)
  if subject == "" then return "" end
  local lines = vim.split(description, "\n", { plain = true })
  lines[1] = subject
  return vim.trim(table.concat(lines, "\n"))
end

--- Describes the changes whose subjects were edited in a log buffer, keeping
--- the rest of their descriptions, and then abandons the cut changes. If jj
--- fails, the buffer keeps its edits.
---@param bufnr integer
---@param on_done? fun(err?: string)
local save = function(bufnr, on_done)
  local log = logs[bufnr]
  if not log then return end

  ---@param err? string
  local finish = function(err)
    if err then notify(err) end
    if on_done then on_done(err) end
  end

  local err, edits = edits_of(bufnr, log)
  if err or not edits then return finish(err) end

  local index = 0
  ---@type fun(err?: string)
  local step
  step = function(step_err)
    if step_err then return finish(step_err) end

    index = index + 1
    local edit = edits[index]
    if not edit then
      local cut = vim.tbl_keys(log.cut)
      if #cut == 0 then return render(bufnr, false, finish) end
      local what = "abandoning " .. count_changes(#cut)
      return abandon_changes(log.root, cut, what, function(abandon_err)
        if abandon_err then return finish(abandon_err) end
        log.cut = {}
        render(bufnr, false, finish)
      end)
    end

    jj.description(log.root, edit.change.id, function(desc_err, description)
      if desc_err or not description then
        step(desc_err)
        return
      end
      local text = with_subject(description, edit.subject)
      jj.describe(log.root, edit.change.id, text, step)
    end)
  end
  step()
end

--- Returns the changes on the given lines of a log buffer, or an error if
--- lines were added, removed or moved since its last redraw.
---@param bufnr integer
---@param log nvim_jj.Log
---@param first integer The first line, 1-based.
---@param last integer The last line, inclusive.
---@return string? err
---@return nvim_jj.Change[]? changes
local changes_between = function(bufnr, log, first, last)
  if not is_intact(bufnr, log) then return not_intact end

  local changes = {}
  for index = math.min(first, last), math.max(first, last) do
    local row = log.rows[index]
    if row then changes[#changes + 1] = row.change end
  end
  if #changes == 0 then return "No change on the selected lines" end
  return nil, changes
end

--- Returns the root of the jj workspace containing the given path, or else
--- the current file's, or else the working directory's.
---@param path? string
---@return string?
local root_of = function(path)
  if path then return jj.root(path) end
  local name = vim.api.nvim_buf_get_name(0)
  if vim.startswith(name, scheme) then return name:sub(#scheme + 1) end
  if vim.bo.buftype == "" and name ~= "" then return jj.root(name) end
  return jj.root(vim.fn.getcwd())
end

--- Runs a function with all autocommands ignored.
---@param fn fun()
local without_autocmds = function(fn)
  local eventignore = vim.o.eventignore
  vim.o.eventignore = "all"
  local ok, err = pcall(fn)
  vim.o.eventignore = eventignore
  if not ok then error(err, 0) end
end

--- Returns the buffer of the log of a workspace, drawing it if it's new.
---@param root string
---@return integer
local log_buffer = function(root)
  local name = scheme .. root
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(bufnr) == name and logs[bufnr] then
      render(bufnr, true)
      return bufnr
    end
  end

  ---@type integer
  local bufnr
  -- Naming a buffer would make other plugins look at it as a file.
  without_autocmds(function()
    bufnr = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_name(bufnr, name)
  end)
  load(bufnr)
  return bufnr
end

--- Closes the windows of the current tab page showing the log of a jj
--- workspace, or else opens one in a split below the current window. The
--- window opens with all autocommands ignored.
---@param path? string A path in the workspace, by default the current file or the working directory.
---@return integer? win The window opened.
M.toggle = function(path)
  local root = root_of(path)
  if not root then return notify("Not in a jj workspace") end

  local name = scheme .. root
  local open = vim.tbl_filter(
    function(win)
      return vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)) == name
    end,
    vim.api.nvim_tabpage_list_wins(0)
  )
  if #open > 0 then
    for _, win in ipairs(open) do
      local ok, err = pcall(vim.api.nvim_win_close, win, false)
      if not ok then notify(tostring(err)) end
    end
    return
  end

  local bufnr = log_buffer(root)
  ---@type integer
  local win
  without_autocmds(function()
    vim.cmd(("belowright %dsplit"):format(config.height))
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, bufnr)
    vim.wo[win].winfixheight = true
  end)
  return win
end

--- Returns the line of a log buffer's topmost change among the given ones.
---@param log nvim_jj.Log
---@param ids string[]
---@return integer?
local topmost_row = function(log, ids)
  for index, row in ipairs(log.rows) do
    if vim.list_contains(ids, row.change.id) then return index end
  end
end

--- Inserts an empty change next to the changes on the given lines of a log
--- buffer, without checking it out. Above them, it's their child, and their
--- children become its children. Below them, it's their parent, and their
--- parents become its parents. On a branch, it takes no children, which
--- makes it a new branch on top of them above them, and their sibling below
--- them.
---@param bufnr integer
---@param position "above"|"below"
---@param branch boolean
---@param first integer The first line, 1-based.
---@param last integer The last line, inclusive.
---@param on_done? fun(line: integer) Called with the new change's line once the buffer is redrawn.
M.insert_change = function(bufnr, position, branch, first, last, on_done)
  local log = logs[bufnr]
  if not log then return end
  if vim.bo[bufnr].modified then return notify(not_saved) end

  local err, changes = changes_between(bufnr, log, first, last)
  if err or not changes then return notify(err or "") end

  local history = history_of(log.root)
  local ids = vim.tbl_map(function(change) return change.id end, changes)
  local place = function()
    local revs = revset_of(history, ids)
    if branch then
      return { onto = position == "above" and revs or revs .. "-" }
    end
    return position == "above" and { after = revs } or { before = revs }
  end

  create_change(log.root, place, "inserting a change", function(create_err, id)
    if create_err or not id then return notify(create_err or "") end
    render(bufnr, false, function()
      local line = topmost_row(log, { id })
      if line and on_done then on_done(line) end
    end)
  end)
end

---@alias nvim_jj.Hold "cut"|"copied"

--- Cuts or copies changes of a log buffer, or uncuts or uncopies them if
--- they all are already. Cutting drops the copied changes, and copying drops
--- the cut ones.
---@param bufnr integer
---@param log nvim_jj.Log
---@param hold nvim_jj.Hold
---@param changes nvim_jj.Change[]
local toggle_held = function(bufnr, log, hold, changes)
  local release = true
  for _, change in ipairs(changes) do
    if not log[hold][change.id] then release = false end
  end
  if hold == "cut" and not release then
    for _, change in ipairs(changes) do
      if change.immutable then
        return notify(immutable(change))
      end
    end
  end

  ---@type table<string, true?>
  local redraw = {}
  for id in pairs(log.cut) do
    redraw[id] = true
  end
  for id in pairs(log.copied) do
    redraw[id] = true
  end

  if not release then log[hold == "cut" and "copied" or "cut"] = {} end
  for _, change in ipairs(changes) do
    log[hold][change.id] = not release or nil
    redraw[change.id] = true
  end
  for index, row in ipairs(log.rows) do
    if redraw[row.change.id] and row.marks then
      draw_left(bufnr, row, index - 1)
    end
  end
end

---@param bufnr integer
---@param hold nvim_jj.Hold
---@param first integer
---@param last integer
local hold_lines = function(bufnr, hold, first, last)
  local log = logs[bufnr]
  if not log then return end
  local err, changes = changes_between(bufnr, log, first, last)
  if err or not changes then return notify(err or "") end
  toggle_held(bufnr, log, hold, changes)
end

---@param bufnr integer
---@param hold nvim_jj.Hold
---@param line integer
---@param with_change boolean
---@param on_done? fun()
local hold_descendants = function(bufnr, hold, line, with_change, on_done)
  local log = logs[bufnr]
  if not log then return end
  local err, changes = changes_between(bufnr, log, line, line)
  if err or not changes then return notify(err or "") end
  local change = assert(changes[1])

  local revset = change.id .. (with_change and "::" or "+::")
  jj.changes(log.root, revset, function(changes_err, descendants)
    if changes_err or not descendants then return notify(changes_err or "") end
    if #descendants == 0 then
      return notify(("%s has no descendants"):format(label(change)))
    end
    toggle_held(bufnr, log, hold, descendants)
    if on_done then on_done() end
  end)
end

--- Cuts the changes on the given lines of a log buffer, or uncuts them if
--- they're all cut already.
---@param bufnr integer
---@param first integer The first line, 1-based.
---@param last integer The last line, inclusive.
M.cut = function(bufnr, first, last) hold_lines(bufnr, "cut", first, last) end

--- Copies the changes on the given lines of a log buffer, or uncopies them
--- if they're all copied already.
---@param bufnr integer
---@param first integer The first line, 1-based.
---@param last integer The last line, inclusive.
M.copy = function(bufnr, first, last) hold_lines(bufnr, "copied", first, last) end

--- Cuts the descendants of the change on a line of a log buffer, or uncuts
--- them if they're all cut already.
---@param bufnr integer
---@param line integer The 1-based line.
---@param with_change boolean Whether the change itself is cut too.
---@param on_done? fun()
M.cut_descendants = function(bufnr, line, with_change, on_done)
  hold_descendants(bufnr, "cut", line, with_change, on_done)
end

--- Copies the descendants of the change on a line of a log buffer, or
--- uncopies them if they're all copied already.
---@param bufnr integer
---@param line integer The 1-based line.
---@param with_change boolean Whether the change itself is copied too.
---@param on_done? fun()
M.copy_descendants = function(bufnr, line, with_change, on_done)
  hold_descendants(bufnr, "copied", line, with_change, on_done)
end

--- Returns whether a log buffer has cut or copied changes.
---@param bufnr integer
---@return boolean
M.has_held = function(bufnr)
  local log = logs[bufnr]
  return log ~= nil and (next(log.cut) ~= nil or next(log.copied) ~= nil)
end

--- Moves the cut changes of a log buffer next to the change on a line, or
--- else copies the copied ones there. Below the change, they take its
--- parents and it becomes their child. Above it, it becomes their parent and
--- its children become theirs. On a branch, they take no children, which
--- makes them its siblings below it and a new branch of it above it. The
--- copied changes stay copied.
---@param bufnr integer
---@param line integer The 1-based line.
---@param position "above"|"below"
---@param branch boolean
---@param on_done? fun(line: integer) Called with the line of the topmost pasted change once the buffer is redrawn.
M.paste = function(bufnr, line, position, branch, on_done)
  local log = logs[bufnr]
  if not log then return end
  if vim.bo[bufnr].modified then return notify(not_saved) end

  local cut, copied = vim.tbl_keys(log.cut), vim.tbl_keys(log.copied)
  if #cut == 0 and #copied == 0 then return notify("Nothing is cut or copied") end

  local err, changes = changes_between(bufnr, log, line, line)
  if err or not changes then return notify(err or "") end
  local target = assert(changes[1])
  if log.cut[target.id] then
    return notify("The change to paste next to is cut")
  end

  local history = history_of(log.root)
  local place = function()
    local rev = current_id(history, target.id)
    if branch then return { onto = position == "above" and rev or rev .. "-" } end
    return position == "above" and { after = rev } or { before = rev }
  end

  ---@param pasted string[]
  local redraw = function(pasted)
    render(bufnr, false, function()
      local pasted_line = topmost_row(log, pasted)
      if pasted_line and on_done then on_done(pasted_line) end
    end)
  end

  if #cut > 0 then
    local what = "pasting " .. count_changes(#cut)
    return move_changes(log.root, cut, place, what, function(move_err)
      if move_err then return notify(move_err) end
      log.cut = {}
      redraw(cut)
    end)
  end

  local what = "pasting copies of " .. count_changes(#copied)
  copy_changes(log.root, copied, place, what, function(copy_err, copies)
    if copy_err or not copies then return notify(copy_err or "") end
    redraw(copies)
  end)
end

--- Prompts for the name of the bookmark of the change on a line of a log
--- buffer. A new name creates the bookmark, or renames the change's one, and
--- an empty name deletes it. With several bookmarks, the one to edit is
--- picked first.
---@param bufnr integer
---@param line integer The 1-based line.
---@param on_done? fun(err?: string)
M.edit_bookmark = function(bufnr, line, on_done)
  local log = logs[bufnr]
  if not log then return end

  ---@param err? string
  local finish = function(err)
    if err then notify(err) end
    if on_done then on_done(err) end
  end

  local err, changes = changes_between(bufnr, log, line, line)
  if err or not changes then return finish(err) end
  local change = assert(changes[1])

  ---@param old? string
  local edit = function(old)
    vim.ui.input(
      { prompt = "Bookmark: ", default = old or "" },
      function(input)
        if input == nil then return finish() end
        local new = vim.trim(input)
        if new == (old or "") then return finish() end
        local root, history = log.root, history_of(log.root)
        ---@param name string
        local create = function(name)
          return function(done)
            jj.create_bookmark(root, name, current_id(history, change.id), done)
          end
        end
        ---@param name string
        local delete = function(name)
          return function(done) jj.delete_bookmark(root, name, done) end
        end
        ---@param from string
        ---@param to string
        local rename = function(from, to)
          return function(done) jj.rename_bookmark(root, from, to, done) end
        end

        ---@type nvim_jj.Step
        local step
        if not old then
          step = { label = "creating " .. new, redo = create(new), undo = delete(new) }
        elseif new == "" then
          step = { label = "deleting " .. old, redo = delete(old), undo = create(old) }
        else
          step = {
            label = ("renaming %s to %s"):format(old, new),
            redo = rename(old, new),
            undo = rename(new, old),
          }
        end
        step.redo(function(edit_err)
          if not edit_err then record(root, step) end
          finish(edit_err)
        end)
      end
    )
  end

  local bookmarks = change.local_bookmarks
  if #bookmarks <= 1 then return edit(bookmarks[1]) end
  vim.ui.select(bookmarks, { prompt = "Bookmark to edit" }, function(old)
    if old then
      edit(old)
    else
      finish()
    end
  end)
end

--- Pushes the changes on the given lines of a log buffer. The topmost one's
--- bookmark is pushed if it has one, or else the remote bookmark the changes
--- are on top of is moved to it. On a new branch, or without a remote
--- bookmark below them, the bookmark is prompted for, by default the `push-`
--- one jj would name after the change, and an existing bookmark is only moved
--- once confirmed. The changes that are already pushed are skipped with a
--- warning, and each of their ancestors that isn't selected has to be pushed
--- already.
---@param bufnr integer
---@param first integer The first line, 1-based.
---@param last integer The last line, inclusive.
---@param branch boolean Whether to push the changes on a new branch.
---@param on_done? fun(err?: string)
M.push = function(bufnr, first, last, branch, on_done)
  local log = logs[bufnr]
  if not log then return end
  local root, remote = log.root, config.remote

  ---@param err? string
  local finish = function(err)
    if err then notify(err) end
    if on_done then on_done(err) end
  end

  local err, selected = changes_between(bufnr, log, first, last)
  if err or not selected then return finish(err) end

  local pushed =
    ("::remote_bookmarks(remote=exact:%s)"):format(jj.quote(remote))
  local selection = ("(%s)"):format(table.concat(
    vim.tbl_map(function(change) return change.id end, selected),
    " | "
  ))
  local unpushed = ("(%s ~ %s)"):format(selection, pushed)

  ---@param name string
  ---@param head nvim_jj.Change
  local push_bookmark = function(name, head)
    notify(
      ("Pushing %s to %s@%s"):format(label(head), name, remote),
      vim.log.levels.INFO
    )
    jj.push(root, name, remote, function(push_err)
      if push_err then return finish(push_err) end
      notify(
        ("Pushed %s to %s@%s"):format(label(head), name, remote),
        vim.log.levels.INFO
      )
      finish()
    end)
  end

  ---@param name string
  ---@param head nvim_jj.Change
  ---@param backwards? boolean Whether the bookmark can move off its descendants.
  local push = function(name, head, backwards)
    jj.set_bookmark(root, name, head.id, backwards == true, function(set_err)
      if set_err then return finish(set_err) end
      push_bookmark(name, head)
    end)
  end

  ---@param bookmark nvim_jj.RemoteBookmark
  ---@param head nvim_jj.Change
  ---@param backwards? boolean
  local track_and_push = function(bookmark, head, backwards)
    if bookmark.tracked then return push(bookmark.name, head, backwards) end
    jj.track(root, bookmark.name, remote, function(track_err)
      if track_err then return finish(track_err) end
      push(bookmark.name, head, backwards)
    end)
  end

  --- Moves an existing bookmark to a change and pushes it, once confirmed.
  ---@param name string
  ---@param head nvim_jj.Change
  ---@param holders nvim_jj.Change[] The changes the bookmark is on, locally or on the remote.
  local confirm_move = function(name, head, holders)
    local move = "Move it"
    vim.ui.select({ move, "Cancel" }, {
      prompt = ("%s is already on %s"):format(
        name,
        table.concat(vim.tbl_map(label, holders), ", ")
      ),
    }, function(choice)
      if choice ~= move then return finish() end
      local remote_rev = ("remote_bookmarks(exact:%s, remote=exact:%s)"):format(
        jj.quote(name),
        jj.quote(remote)
      )
      jj.remote_bookmarks(root, remote_rev, remote, function(err, remotes)
        if err or not remotes then return finish(err) end
        local tracked = not remotes[1] or remotes[1].tracked
        track_and_push({ name = name, tracked = tracked }, head, true)
      end)
    end)
  end

  --- Prompts for the bookmark of a change, by default the `push-` one jj
  --- would name after it, and pushes it as a new branch. An existing bookmark
  --- is only moved once confirmed.
  ---@param head nvim_jj.Change
  local prompt = function(head)
    vim.ui.input({
      prompt = "Bookmark: ",
      default = "push-" .. head.id:sub(1, 12),
    }, function(input)
      local name = vim.trim(input or "")
      if name == "" then return finish() end

      local quoted = jj.quote(name)
      local existing = ("bookmarks(exact:%s) | remote_bookmarks(exact:%s, remote=exact:%s)"):format(
        quoted,
        quoted,
        jj.quote(remote)
      )
      jj.changes(root, existing, function(err, holders)
        if err or not holders then return finish(err) end
        if #holders == 0 then
          return jj.create_bookmark(root, name, head.id, function(create_err)
            if create_err then return finish(create_err) end
            push_bookmark(name, head)
          end)
        end
        if #holders == 1 and holders[1].id == head.id then
          return push_bookmark(name, head)
        end
        confirm_move(name, head, holders)
      end)
    end)
  end

  ---@param head nvim_jj.Change
  local push_head = function(head)
    local own = head.local_bookmarks
    if not branch and #own == 1 then return push_bookmark(own[1], head) end
    if not branch and #own > 1 then
      return vim.ui.select(own, { prompt = "Bookmark to push" }, function(name)
        if name then
          push_bookmark(name, head)
        else
          finish()
        end
      end)
    end

    local base = ("heads(::%s & %s)"):format(head.id, pushed)
    jj.remote_bookmarks(root, base, remote, function(base_err, bookmarks)
      if base_err or not bookmarks then return finish(base_err) end
      if branch or #bookmarks == 0 then return prompt(head) end
      if #bookmarks == 1 then return track_and_push(bookmarks[1], head) end
      vim.ui.select(bookmarks, {
        prompt = "Bookmark to push to",
        format_item = function(bookmark) return bookmark.name end,
      }, function(bookmark)
        if bookmark then
          track_and_push(bookmark, head)
        else
          finish()
        end
      end)
    end)
  end

  jj.changes(root, selection .. " & " .. pushed, function(pushed_err, already)
    if pushed_err or not already then return finish(pushed_err) end
    for _, change in ipairs(already) do
      notify(
        ("%s is already pushed"):format(label(change)),
        vim.log.levels.WARN
      )
    end
    if #already == #selected then return finish() end

    local missing =
      ("::%s ~ %s ~ %s ~ root()"):format(unpushed, pushed, selection)
    jj.changes(root, missing, function(missing_err, ancestors)
      if missing_err or not ancestors then return finish(missing_err) end
      if #ancestors > 0 then
        return finish(
          "These ancestors aren't pushed:\n"
            .. table.concat(vim.tbl_map(label, ancestors), "\n")
        )
      end

      local heads = ("heads(%s)"):format(unpushed)
      jj.changes(root, heads, function(heads_err, changes)
        if heads_err or not changes then return finish(heads_err) end
        if #changes ~= 1 then
          return finish("The selected changes aren't a single stack")
        end
        push_head(changes[1])
      end)
    end)
  end)
end

---@param bufnr integer
---@param direction "undo"|"redo"
---@param on_done? fun(err?: string)
local step_history = function(bufnr, direction, on_done)
  local log = logs[bufnr]
  if not log then return end

  ---@param err? string
  local finish = function(err)
    if err then notify(err) end
    if on_done then on_done(err) end
  end

  if vim.bo[bufnr].modified then return finish(not_saved) end
  local history = history_of(log.root)
  if history.busy then return finish("An undo or redo is still running") end
  local from = history[direction]
  local to = history[direction == "undo" and "redo" or "undo"]
  local step = from[#from]
  if not step then
    return finish(direction == "undo" and "Nothing to undo" or "Nothing to redo")
  end

  history.busy = true
  step[direction](function(err)
    history.busy = false
    if err then
      render(bufnr, false)
      return finish(err)
    end
    table.remove(from)
    table.insert(to, step)
    local done = direction == "undo" and "Undid" or "Redid"
    notify(("%s %s"):format(done, step.label), vim.log.levels.INFO)
    render(bufnr, false, finish)
  end)
end

--- Undoes the last graph operation started from a log of the buffer's
--- workspace.
---@param bufnr integer
---@param on_done? fun(err?: string)
M.undo = function(bufnr, on_done) step_history(bufnr, "undo", on_done) end

--- Redoes the last graph operation undone from a log of the buffer's
--- workspace.
---@param bufnr integer
---@param on_done? fun(err?: string)
M.redo = function(bufnr, on_done) step_history(bufnr, "redo", on_done) end

--- Checks out the change on a line of a log buffer. The undo checks out the
--- previous working-copy commit, or recreates it on its parents if it was
--- empty and abandoned when it was left.
---@param bufnr integer
---@param line integer The 1-based line.
---@param on_done? fun(err?: string)
M.check_out = function(bufnr, line, on_done)
  local log = logs[bufnr]
  if not log then return end
  local root, history = log.root, history_of(log.root)

  ---@param err? string
  local finish = function(err)
    if err then notify(err) end
    if on_done then on_done(err) end
  end

  if vim.bo[bufnr].modified then return finish(not_saved) end
  local err, changes = changes_between(bufnr, log, line, line)
  if err or not changes then return finish(err) end
  local target = assert(changes[1])
  if target.working_copy then return finish() end

  jj.parents(root, "@", function(parents_err, parents)
    if parents_err or not parents then return finish(parents_err) end
    local previous, previous_parents = next(parents)
    if not previous then return finish("There's no working-copy commit") end

    ---@param done fun(err?: string)
    local edit = function(done) jj.edit(root, current_id(history, target.id), done) end
    ---@param done fun(err?: string)
    local undo = function(done)
      local id = current_id(history, previous)
      jj.changes(root, ("present(%s)"):format(id), function(present_err, present)
        if present_err or not present then return done(present_err) end
        if #present > 0 then return jj.edit(root, id, done) end
        local place = { onto = revset_of(history, previous_parents or {}) }
        jj.new(root, place, true, function(new_err, prefix)
          if new_err or not prefix then return done(new_err) end
          full_ids(root, { prefix }, function(ids_err, ids)
            if ids_err or not ids then return done(ids_err) end
            history.aliases[id] = ids[prefix]
            done()
          end)
        end)
      end)
    end

    edit(function(edit_err)
      if edit_err then return finish(edit_err) end
      record(root, { label = "checking out " .. label(target), redo = edit, undo = undo })
      render(bufnr, false, finish)
    end)
  end)
end

--- Fetches the remote's bookmarks into the log buffer's workspace. If the
--- trunk moved, the changes between it and the working-copy commit that
--- aren't on top of it yet, with their descendants, can be moved onto it.
---@param bufnr integer
---@param on_done? fun(err?: string)
M.fetch = function(bufnr, on_done)
  local log = logs[bufnr]
  if not log then return end
  local root, remote = log.root, config.remote

  ---@param err? string
  local finish = function(err)
    if err then notify(err) end
    if on_done then on_done(err) end
  end

  if vim.bo[bufnr].modified then return finish(not_saved) end

  jj.changes(root, "trunk()", function(err, before)
    if err or not before then return finish(err) end
    notify(("Fetching %s"):format(remote), vim.log.levels.INFO)
    jj.fetch(root, remote, function(fetch_err)
      if fetch_err then return finish(fetch_err) end
      notify(("Fetched %s"):format(remote), vim.log.levels.INFO)
      jj.changes(root, "trunk()", function(after_err, after)
        if after_err or not after then return finish(after_err) end
        local trunk = after[1]
        if not trunk or (before[1] and before[1].commit_id == trunk.commit_id) then
          return render(bufnr, false, finish)
        end

        local behind = "(trunk()..@ ~ trunk()::)::"
        jj.changes(root, behind, function(behind_err, changes)
          if behind_err or not changes then return finish(behind_err) end
          if #changes == 0 then return render(bufnr, false, finish) end

          local name = trunk.bookmarks[1] or "trunk()"
          local move = ("Move them onto %s"):format(name)
          vim.ui.select({ move, "Leave them" }, {
            prompt = ("%s moved, and %s aren't on top of it"):format(
              name,
              count_changes(#changes)
            ),
          }, function(choice)
            if choice ~= move then return render(bufnr, false, finish) end
            local ids = vim.tbl_map(function(change) return change.id end, changes)
            local what = ("moving %s onto %s"):format(count_changes(#ids), name)
            local place = function() return { onto = "trunk()" } end
            move_changes(root, ids, place, what, function(move_err)
              if move_err then return finish(move_err) end
              render(bufnr, false, finish)
            end)
          end)
        end)
      end)
    end)
  end)
end

--- Opens a pull request of the bookmark of the change on a line of a log
--- buffer, into the remote bookmark the change is on top of. The bookmark
--- has to be pushed already, and the pull request's title is the change's
--- subject.
---@param bufnr integer
---@param line integer The 1-based line.
---@param on_done? fun(err?: string, url?: string)
M.open_pull_request = function(bufnr, line, on_done)
  local log = logs[bufnr]
  if not log then return end
  local root, remote = log.root, config.remote

  ---@param err? string
  ---@param url? string
  local finish = function(err, url)
    if err then notify(err) end
    if url then notify(("Opened %s"):format(url), vim.log.levels.INFO) end
    if on_done then on_done(err, url) end
  end

  local err, changes = changes_between(bufnr, log, line, line)
  if err or not changes then return finish(err) end
  local change = assert(changes[1])

  ---@param head string
  ---@param base string
  local create = function(head, base)
    jj.remote_url(root, remote, function(url_err, url)
      if url_err or not url then return finish(url_err) end
      local repo = github.repo_of(url)
      if not repo then
        return finish(("%s isn't a GitHub repo"):format(remote))
      end
      notify(("Opening a pull request of %s into %s"):format(head, base), vim.log.levels.INFO)
      github.create_pull_request(root, config.gh, repo, head, base, change.subject, finish)
    end)
  end

  ---@param head string
  local open = function(head)
    local pushed = ("%s & remote_bookmarks(exact:%s, remote=exact:%s)"):format(
      change.id,
      jj.quote(head),
      jj.quote(remote)
    )
    jj.changes(root, pushed, function(pushed_err, up_to_date)
      if pushed_err or not up_to_date then return finish(pushed_err) end
      if #up_to_date == 0 then
        return finish(("Push %s to %s first"):format(head, remote))
      end

      local base = ("heads(::%s- & ::remote_bookmarks(remote=exact:%s))"):format(
        change.id,
        jj.quote(remote)
      )
      jj.remote_bookmarks(root, base, remote, function(base_err, bookmarks)
        if base_err or not bookmarks then return finish(base_err) end
        if #bookmarks == 0 then
          return finish(("%s isn't on top of a bookmark of %s"):format(label(change), remote))
        end
        if #bookmarks == 1 then return create(head, bookmarks[1].name) end
        vim.ui.select(bookmarks, {
          prompt = "Bookmark to pull into",
          format_item = function(bookmark) return bookmark.name end,
        }, function(bookmark)
          if bookmark then
            create(head, bookmark.name)
          else
            finish()
          end
        end)
      end)
    end)
  end

  local own = change.local_bookmarks
  if #own == 0 then
    return finish(("%s has no bookmark to open a pull request of"):format(label(change)))
  end
  if #own == 1 then return open(own[1]) end
  vim.ui.select(own, { prompt = "Bookmark to open a pull request of" }, function(name)
    if name then
      open(name)
    else
      finish()
    end
  end)
end

--- Replaces a log buffer's line without making it undoable, and keeps the
--- buffer's modified state.
---@param bufnr integer
---@param line integer The 1-based line.
---@param old string
---@param new string
local set_quietly = function(bufnr, line, old, new)
  local undolevels, modified = vim.bo[bufnr].undolevels, vim.bo[bufnr].modified
  vim.bo[bufnr].undolevels = -1
  vim.api.nvim_buf_set_text(bufnr, line - 1, 0, line - 1, #old, { new })
  vim.bo[bufnr].undolevels = undolevels
  vim.bo[bufnr].modified = modified
end

--- Empties the pad of the cursor's line of a log buffer entering insert mode,
--- where Neovim draws the cursor of an empty line after its inline virtual
--- text.
---@param bufnr integer
---@param log nvim_jj.Log
local unpad = function(bufnr, log)
  local line = vim.fn.line(".")
  local text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1]
  if text ~= pad then return end
  set_quietly(bufnr, line, pad, "")
  log.unpadded = line
end

--- Pads the line emptied when a log buffer entered insert mode, if it's
--- still empty.
---@param bufnr integer
---@param log nvim_jj.Log
local repad = function(bufnr, log)
  local line = log.unpadded
  log.unpadded = nil
  if not line then return end
  local text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1]
  if text == "" then set_quietly(bufnr, line, "", pad) end
end

--- Returns a highlight group's foreground, following its links.
---@param name string
---@return integer?
local foreground = function(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false }).fg
end

--- Sets the default colors of the log buffers. The details and the IDs use
--- the colors of comments and identifiers without their other attributes.
local set_highlights = function()
  local comment = foreground("Comment")

  ---@type table<string, vim.api.keyset.highlight>
  local highlights = {
    JjAuthor = { fg = comment },
    JjBookmark = { link = "Constant" },
    JjChangeId = { fg = foreground("Identifier"), bold = true },
    JjChangeIdRest = { fg = comment },
    JjCode = { link = "String" },
    JjCodeDelimiter = { fg = comment },
    JjConflict = { link = "DiagnosticError" },
    JjCopy = { link = "DiffAdd" },
    JjCut = { link = "DiffDelete" },
    JjDivergent = { link = "DiagnosticWarn" },
    JjGraph = { link = "NonText" },
    JjPlaceholder = { link = "Comment" },
    JjTimestamp = { fg = comment },
    JjWorkingCopy = { link = "Title" },
  }
  for name, highlight in pairs(highlights) do
    highlight.default = true
    vim.api.nvim_set_hl(0, name, highlight)
  end
end

--- Returns the spans of a subject in backticks, as the 0-based columns of
--- their opening and closing backticks.
---@param text string
---@return [integer, integer][]
local code_spans = function(text)
  local spans = {}
  for open, close in text:gmatch("()`[^`]*()`") do
    spans[#spans + 1] = { open - 1, close - 1 }
  end
  return spans
end

--- Returns the index of the code span a window's cursor is in, if any. The
--- span's backticks count as in it.
---@param win integer
---@param bufnr integer
---@return integer? row The cursor's 0-based line.
---@return integer? index
local cursor_span = function(win, bufnr)
  local row, col = unpack(vim.api.nvim_win_get_cursor(win))
  local text = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
  for index, span in ipairs(code_spans(text)) do
    if col >= span[1] and col <= span[2] then return row - 1, index end
  end
  return row - 1, nil
end

--- Highlights the code in a line of a log buffer drawn in a window, and
--- conceals its backticks, except the ones around the window's cursor.
---@param win integer
---@param bufnr integer
---@param row integer The 0-based line.
local draw_code = function(win, bufnr, row)
  local text = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  local cursor_row, cursor_index = cursor_span(win, bufnr)
  for index, span in ipairs(code_spans(text)) do
    local open, close = span[1], span[2]
    vim.api.nvim_buf_set_extmark(bufnr, code_namespace, row, open + 1, {
      end_col = close,
      hl_group = "JjCode",
      ephemeral = true,
    })
    local revealed = row == cursor_row and index == cursor_index
    for _, col in ipairs({ open, close }) do
      vim.api.nvim_buf_set_extmark(bufnr, code_namespace, row, col, {
        end_col = col + 1,
        hl_group = "JjCodeDelimiter",
        conceal = not revealed and "" or nil,
        ephemeral = true,
      })
    end
  end
end

--- The code span each window's cursor was last in, as its 0-based line and
--- index, keyed by window.
---@type table<integer, [integer, integer?]?>
local cursor_spans = {}

--- Redraws the lines of a window whose code spans revealed by the cursor
--- changed since the cursor last moved.
---@param win integer
---@param bufnr integer
local redraw_cursor_spans = function(win, bufnr)
  local row, index = cursor_span(win, bufnr)
  local previous = cursor_spans[win]
  cursor_spans[win] = { assert(row), index }
  if previous and previous[1] == row and previous[2] == index then return end
  ---@param line integer
  local redraw = function(line)
    vim.api.nvim__redraw({ win = win, range = { line, line + 1 }, flush = false })
  end
  local previous_row = previous and previous[1]
  if previous_row then redraw(previous_row) end
  if index then redraw(assert(row)) end
end

---@param opts? { gh?: string, height?: integer, lookahead?: integer, remote?: string, revset?: string }
M.setup = function(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
  set_highlights()

  local group = vim.api.nvim_create_augroup("nvim-jj", { clear = true })
  local pattern = scheme .. "*"

  vim.api.nvim_set_decoration_provider(code_namespace, {
    on_win = function(_, _, bufnr) return logs[bufnr] ~= nil end,
    on_line = function(_, win, bufnr, row) draw_code(win, bufnr, row) end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    desc = "Sets the default colors of the jj logs",
    callback = set_highlights,
  })

  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = group,
    pattern = pattern,
    desc = "Draws the jj log",
    callback = function(ev) load(ev.buf) end,
  })

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    group = group,
    pattern = pattern,
    desc = "Describes the changes whose subjects were edited",
    callback = function(ev) save(ev.buf) end,
  })

  vim.api.nvim_create_autocmd(
    { "TextChanged", "TextChangedI", "CursorMovedI", "InsertEnter", "InsertLeave" },
    {
      group = group,
      pattern = pattern,
      desc = "Redraws the decorations of the jj log's edited lines",
      callback = function(ev)
        local log = logs[ev.buf]
        if ev.event == "InsertEnter" then
          inserting = ev.buf
          if log then unpad(ev.buf, log) end
        elseif ev.event == "InsertLeave" then
          inserting = nil
          if log then repad(ev.buf, log) end
        end
        if log then redraw_edited(ev.buf, log) end
      end,
    }
  )

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = group,
    pattern = pattern,
    desc = "Reveals the backticks of the code the cursor is in",
    callback = function(ev)
      redraw_cursor_spans(vim.api.nvim_get_current_win(), ev.buf)
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    desc = "Forgets the code span the closed window's cursor was in",
    callback = function(ev) cursor_spans[tonumber(ev.match) or -1] = nil end,
  })

  vim.api.nvim_create_autocmd("WinScrolled", {
    group = group,
    desc = "Reads more of the jj logs scrolled close to their end",
    callback = function()
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local bufnr = vim.api.nvim_win_get_buf(win)
        local log = logs[bufnr]
        if log then flush(bufnr, log) end
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    pattern = pattern,
    desc = "Redraws the jj log after snapshotting the working copy",
    callback = function(ev)
      if logs[ev.buf] and not vim.bo[ev.buf].modified then
        render(ev.buf, true)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    pattern = pattern,
    desc = "Stops watching the jj log's repo",
    callback = function(ev) release(ev.buf) end,
  })
end

return M
