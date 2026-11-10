local jj = require("nvim_jj.jj")

local M = {}

local uv = vim.uv

--- The prefix of the names of the buffers showing changes, which is followed
--- by the workspace root and the change ID.
M.scheme = "jj-change://"

local namespace = vim.api.nvim_create_namespace("nvim-jj-change")

local syntax_namespace = vim.api.nvim_create_namespace("nvim-jj-change-syntax")

--- The delay between a jj operation and the redraw of the views it triggers.
local op_debounce_ms = 100

---@alias nvim_jj.FileStatus "added"|"deleted"|"modified"|"renamed"|"copied"

---@class nvim_jj.DiffLine
---@field kind " "|"-"|"+"
---@field text string
---@field old? integer The line's number in the parents.
---@field new? integer The line's number in the change.

---@class nvim_jj.Hunk
---@field old_start integer
---@field old_count integer
---@field lines nvim_jj.DiffLine[]

---@class nvim_jj.FileDiff
---@field path string The file's path in the change, or in the parents if it was deleted.
---@field old_path? string The file's path in the parents if it was renamed or copied.
---@field status nvim_jj.FileStatus
---@field binary boolean
---@field added integer The number of added lines.
---@field deleted integer The number of deleted lines.
---@field hunks nvim_jj.Hunk[]

--- Parses a diff in git's format.
---@param text string
---@return nvim_jj.FileDiff[]
M.parse_diff = function(text)
  ---@type nvim_jj.FileDiff[]
  local files = {}
  ---@type nvim_jj.FileDiff?
  local file
  ---@type nvim_jj.Hunk?
  local hunk
  local old, new = 0, 0

  for line in vim.gsplit(text, "\n", { plain = true }) do
    local from, to = line:match("^diff %-%-git a/(.-) b/(.*)$")
    if from and to then
      file = {
        path = to,
        old_path = from ~= to and from or nil,
        status = "modified",
        binary = false,
        added = 0,
        deleted = 0,
        hunks = {},
      }
      files[#files + 1] = file
      hunk = nil
    elseif file and not hunk then
      if line:match("^new file mode") then
        file.status = "added"
      elseif line:match("^deleted file mode") then
        file.status = "deleted"
      elseif line:match("^rename from ") then
        file.status = "renamed"
      elseif line:match("^copy from ") then
        file.status = "copied"
      elseif line:match("^Binary files ") then
        file.binary = true
      end
    end

    local old_start, old_count, new_start =
      line:match("^@@ %-(%d+),?(%d*) %+(%d+),?%d* @@")
    if file and old_start then
      hunk = {
        old_start = tonumber(old_start) --[[@as integer]],
        old_count = old_count == "" and 1 or tonumber(old_count) --[[@as integer]],
        lines = {},
      }
      table.insert(file.hunks, hunk)
      old, new = hunk.old_start, tonumber(new_start) --[[@as integer]]
    elseif file and hunk and not from then
      local kind, rest = line:sub(1, 1), line:sub(2)
      if kind == " " then
        table.insert(
          hunk.lines,
          { kind = " ", text = rest, old = old, new = new }
        )
        old, new = old + 1, new + 1
      elseif kind == "-" then
        table.insert(hunk.lines, { kind = "-", text = rest, old = old })
        old = old + 1
        file.deleted = file.deleted + 1
      elseif kind == "+" then
        table.insert(hunk.lines, { kind = "+", text = rest, new = new })
        new = new + 1
        file.added = file.added + 1
      end
    end
  end
  return files
end

---@alias nvim_jj.Chunk [string, string?] A text and its highlight.

--- The letters of the statuses of files, and their highlights.
---@type table<nvim_jj.FileStatus, [string, string]>
local statuses = {
  added = { "A", "JjAddedFiles" },
  deleted = { "D", "JjDeletedFiles" },
  modified = { "M", "JjModifiedFiles" },
  renamed = { "R", "JjRenamedFiles" },
  copied = { "C", "JjRenamedFiles" },
}

--- The order the statuses are summarized in.
---@type nvim_jj.FileStatus[]
local status_order = { "added", "deleted", "modified", "renamed", "copied" }

--- Returns the chunks of numbers of added and deleted lines, like `+3 -1`,
--- leaving out the zeros.
---@param added integer
---@param deleted integer
---@return nvim_jj.Chunk[]
local line_counts = function(added, deleted)
  ---@type nvim_jj.Chunk[]
  local chunks = {}
  if added > 0 then chunks[#chunks + 1] = { "+" .. added, "JjAddedCount" } end
  if deleted > 0 then
    if #chunks > 0 then chunks[#chunks + 1] = { " " } end
    chunks[#chunks + 1] = { "-" .. deleted, "JjDeletedCount" }
  end
  return chunks
end

--- Returns the chunks summarizing the files a change changed, like `3 files
--- changed: 1 added, 2 modified`, with each count in the highlight of its
--- status, and the chunks of its total of added and deleted lines.
---@param files nvim_jj.FileDiff[]
---@return nvim_jj.Chunk[] summary
---@return nvim_jj.Chunk[] totals
M.summarize = function(files)
  if #files == 0 then return { { "No files changed" } }, {} end
  ---@type table<nvim_jj.FileStatus, integer?>
  local counts = {}
  local added, deleted = 0, 0
  for _, file in ipairs(files) do
    counts[file.status] = (counts[file.status] or 0) + 1
    added, deleted = added + file.added, deleted + file.deleted
  end

  ---@type nvim_jj.Chunk[]
  local summary = {
    {
      (#files == 1 and "1 file changed" or ("%d files changed"):format(#files))
        .. ": ",
    },
  }
  for _, status in ipairs(status_order) do
    local count = counts[status]
    if count then
      if #summary > 1 then summary[#summary + 1] = { ", " } end
      summary[#summary + 1] =
        { ("%d %s"):format(count, status), statuses[status][2] }
    end
  end
  return summary, line_counts(added, deleted)
end

--- Returns the text of a file's row: its path, or its old and new paths if it
--- was renamed or copied.
---@param file nvim_jj.FileDiff
---@return string
local file_text = function(file)
  if not file.old_path then return file.path end
  return ("%s → %s"):format(file.old_path, file.path)
end

--- Returns the chunks of a file's numbers of added and deleted lines.
---@param file nvim_jj.FileDiff
---@return nvim_jj.Chunk[]
local file_stats = function(file)
  if file.binary then return { { "binary", "JjPlaceholder" } } end
  return line_counts(file.added, file.deleted)
end

--- Returns the lines of a change's details: its IDs and bookmarks, its date,
--- and its author, in the order of the log.
---@param details nvim_jj.Details
---@return nvim_jj.Chunk[][]
local details_lines = function(details)
  ---@type nvim_jj.Chunk[]
  local ids = {
    { details.prefix, "JjChangeId" },
    { details.rest .. " ", "JjChangeIdRest" },
    { details.commit_id, "JjChangeIdRest" },
  }
  for _, bookmark in ipairs(details.bookmarks) do
    ids[#ids + 1] = { " " }
    ids[#ids + 1] = { bookmark, "JjBookmark" }
  end
  return {
    ids,
    { { details.timestamp, "JjTimestamp" } },
    { { details.author, "JjAuthor" } },
  }
end

--- Returns the text of chunks.
---@param chunks nvim_jj.Chunk[]
---@return string
local text_of = function(chunks)
  return table.concat(vim.tbl_map(function(chunk) return chunk[1] end, chunks))
end

--- Returns the spans of a subject in backticks, as the 0-based columns of
--- their opening and closing backticks.
---@param text string
---@return [integer, integer][]
M.code_spans = function(text)
  local spans = {}
  for open, close in text:gmatch("()`[^`]*()`") do
    spans[#spans + 1] = { open - 1, close - 1 }
  end
  return spans
end

---@class nvim_jj.ViewRow
---@field file nvim_jj.FileDiff
---@field hunk? nvim_jj.Hunk The hunk the row is a line of, if any.
---@field first? boolean Whether the row is its hunk's first line.

---@class nvim_jj.View
---@field root string The root of the jj workspace.
---@field id string The change ID.
---@field details? nvim_jj.Details
---@field files nvim_jj.FileDiff[]
---@field expanded table<string, true?> The paths of the files whose hunks are shown.
---@field rows table<integer, nvim_jj.ViewRow?> The rows of the files and of their hunks' lines, keyed by their 0-based offset from the summary's row.
---@field summary integer The ID of the extmark on the summary's row, which follows the description.
---@field timer? uv.uv_timer_t
---@field watcher? uv.uv_fs_event_t

---@type table<integer, nvim_jj.View?>
local views = {}

--- Returns the 0-based row of a view's summary, which follows the
--- description.
---@param bufnr integer
---@param view nvim_jj.View
---@return integer
local summary_row = function(bufnr, view)
  local mark =
    vim.api.nvim_buf_get_extmark_by_id(bufnr, namespace, view.summary, {})
  return mark[1] or 0
end

--- Draws the placeholder of an empty subject.
---@param bufnr integer
local draw_placeholder = function(bufnr)
  local placeholder_namespace =
    vim.api.nvim_create_namespace("nvim-jj-change-placeholder")
  vim.api.nvim_buf_clear_namespace(bufnr, placeholder_namespace, 0, -1)
  if (vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or "") ~= "" then
    return
  end
  vim.api.nvim_buf_set_extmark(bufnr, placeholder_namespace, 0, 0, {
    virt_text = { { "(no description set)", "JjPlaceholder" } },
    virt_text_pos = "eol",
  })
end

--- Highlights rows of a buffer with the treesitter highlights of a text made
--- of their lines, in the language of a file.
---@param bufnr integer
---@param path string The file's path.
---@param lines string[]
---@param rows (integer|false)[] The 0-based row of each line, or `false` for a line left alone.
local highlight_syntax = function(bufnr, path, lines, rows)
  local filetype = vim.filetype.match({ filename = path })
  local lang = filetype and vim.treesitter.language.get_lang(filetype)
  if not lang then return end
  local text = table.concat(lines, "\n")
  local ok, parser = pcall(vim.treesitter.get_string_parser, text, lang)
  if not ok or not parser then return end
  parser:parse(true)

  parser:for_each_tree(function(tree, language_tree)
    local tree_lang = language_tree:lang()
    local query = vim.treesitter.query.get(tree_lang, "highlights")
    if not query then return end
    for id, node, metadata in query:iter_captures(tree:root(), text) do
      local name = query.captures[id]
      if
        name
        and not vim.startswith(name, "_")
        and name ~= "spell"
        and name ~= "nospell"
      then
        local priority = tonumber(
          metadata.priority or (metadata[id] and metadata[id].priority)
        ) or vim.hl.priorities.treesitter
        local start_row, start_col, end_row, end_col = node:range()
        for line = start_row, end_row do
          local row = rows[line + 1]
          local length = #(lines[line + 1] or "")
          local from = line == start_row and start_col or 0
          local to = line == end_row and math.min(end_col, length) or length
          if row and from < to then
            vim.api.nvim_buf_set_extmark(bufnr, syntax_namespace, row, from, {
              end_col = to,
              hl_group = ("@%s.%s"):format(name, tree_lang),
              priority = math.floor(priority),
            })
          end
        end
      end
    end
  end)
end

--- The word-level diff of nvim-hunks, when it's installed.
local ok_word_diff, word_diff = pcall(require, "nvim_hunks.diff")

--- Returns the ranges of the text that changed between old and new lines,
--- or none if nvim-hunks' diff isn't loaded.
---@param old_lines string[]
---@param new_lines string[]
---@return { old: { line: integer, start_col: integer, end_col: integer }[], new: { line: integer, start_col: integer, end_col: integer }[] }
local changed_words = function(old_lines, new_lines)
  local ranges = { old = {}, new = {} }
  if not ok_word_diff or not word_diff.is_loaded() then return ranges end
  for _, hunk in ipairs(word_diff.compute(old_lines, new_lines)) do
    vim.list_extend(ranges.old, hunk.old_changes)
    vim.list_extend(ranges.new, hunk.new_changes)
  end
  return ranges
end

--- Returns the extmark options drawing chunks as a line's highlights, from a
--- column on.
---@param chunks nvim_jj.Chunk[]
---@param col integer
---@return { col: integer, end_col: integer, hl_group: string }[]
local chunk_highlights = function(chunks, col)
  local highlights = {}
  for _, chunk in ipairs(chunks) do
    if chunk[2] then
      highlights[#highlights + 1] =
        { col = col, end_col = col + #chunk[1], hl_group = chunk[2] }
    end
    col = col + #chunk[1]
  end
  return highlights
end

--- Draws the part of a view that follows its description: a separator, the
--- change's details, the summary of its files, and their rows, with the hunks
--- of the expanded ones.
---@param bufnr integer
---@param view nvim_jj.View
local draw_files = function(bufnr, view)
  local first = summary_row(bufnr, view)
  local summary, totals = M.summarize(view.files)

  ---@type string[]
  local lines = { text_of(summary) }
  ---@type { row: integer, col?: integer, end_row?: integer, opts: vim.api.keyset.set_extmark }[]
  local marks = {}
  ---@type table<integer, nvim_jj.ViewRow?>
  local rows = {}
  ---@type { path: string, lines: string[], rows: (integer|false)[] }[]
  local syntax = {}

  ---@type nvim_jj.Chunk[][]
  local header = { { { ("─"):rep(vim.o.columns), "JjSeparator" } } }
  if view.details then vim.list_extend(header, details_lines(view.details)) end
  header[#header + 1] = {}
  marks[#marks + 1] = {
    row = 0,
    opts = {
      virt_lines = header,
      virt_lines_above = true,
      virt_text = #totals > 0 and totals or nil,
      virt_text_pos = "eol",
    },
  }
  for _, highlight in ipairs(chunk_highlights(summary, 0)) do
    marks[#marks + 1] = {
      row = 0,
      col = highlight.col,
      opts = { end_col = highlight.end_col, hl_group = highlight.hl_group },
    }
  end

  for _, file in ipairs(view.files) do
    local row = #lines
    lines[#lines + 1] = file_text(file)
    rows[row] = { file = file }
    local expandable = #file.hunks > 0
    local expanded = expandable and view.expanded[file.path]
    local status = statuses[file.status]
    marks[#marks + 1] = {
      row = row,
      opts = {
        virt_text = {
          {
            (expanded and "▾" or expandable and "▸" or " ") .. " ",
            "JjChevron",
          },
          { status[1] .. " ", status[2] },
        },
        virt_text_pos = "inline",
        right_gravity = false,
      },
    }
    local stats = file_stats(file)
    marks[#marks + 1] = {
      row = row,
      opts = {
        virt_text = #stats > 0 and stats or { { "" } },
        virt_text_pos = "eol",
      },
    }

    if expanded then
      local width = 1
      for _, hunk in ipairs(file.hunks) do
        for _, line in ipairs(hunk.lines) do
          width =
            math.max(width, #tostring(line.old or 0), #tostring(line.new or 0))
        end
      end
      local blank = (" "):rep(width)
      local gutter_width = 2 * width + 3
      local new_lines, new_rows, old_lines, old_rows = {}, {}, {}, {}

      ---@type integer?
      local next_old
      for _, hunk in ipairs(file.hunks) do
        local hidden = hunk.old_start - (next_old or 1)
        next_old = hunk.old_start + hunk.old_count
        local hunk_old, hunk_new, hunk_old_rows, hunk_new_rows = {}, {}, {}, {}

        for index, line in ipairs(hunk.lines) do
          local line_row = #lines
          lines[#lines + 1] = line.text
          rows[line_row] = { file = file, hunk = hunk, first = index == 1 }
          local old = line.old and ("%" .. width .. "d"):format(line.old)
            or blank
          local new = line.new and ("%" .. width .. "d"):format(line.new)
            or blank
          local number_hl = line.kind == "+" and "JjDiffAddNr"
            or line.kind == "-" and "JjDiffDeleteNr"
            or "JjDiffContextNr"
          local line_hl = line.kind == "+" and "JjDiffAdd"
            or line.kind == "-" and "JjDiffDelete"
            or nil
          ---@type vim.api.keyset.set_extmark
          local opts = {
            -- The indent aligning the gutter with the file's name is on the
            -- text's background, not the line's.
            virt_text = {
              { "  ", "JjDiffIndent" },
              { (" %s %s "):format(old, new), number_hl },
              { (" %s "):format(line.kind), line_hl },
            },
            virt_text_pos = "inline",
            hl_mode = "combine",
            right_gravity = false,
          }
          -- A `line_hl_group` would be drawn over the changed words'
          -- highlights, so the line's background is a range ending past the
          -- end of the line.
          if line_hl then
            marks[#marks + 1] = {
              row = line_row,
              end_row = line_row + 1,
              opts = {
                end_col = 0,
                hl_group = line_hl,
                hl_eol = true,
                -- The buffer's last line has no next row to end on.
                strict = false,
              },
            }
          end
          if index == 1 and hidden > 0 then
            local text = (" %d unchanged line%s"):format(
              hidden,
              hidden == 1 and "" or "s"
            )
            opts.virt_lines = {
              {
                { "  " },
                { (" "):rep(gutter_width), "JjDiffGapNr" },
                {
                  text
                    .. (" "):rep(
                      math.max(vim.o.columns - gutter_width - 2 - #text, 0)
                    ),
                  "JjDiffGap",
                },
              },
            }
            opts.virt_lines_above = true
          end
          marks[#marks + 1] = { row = line_row, opts = opts }

          if line.kind ~= "-" then
            new_lines[#new_lines + 1] = line.text
            new_rows[#new_rows + 1] = line_row
            hunk_new[#hunk_new + 1] = line.text
            hunk_new_rows[#hunk_new_rows + 1] = line_row
          end
          if line.kind ~= "+" then
            old_lines[#old_lines + 1] = line.text
            old_rows[#old_rows + 1] = line.kind == "-" and line_row or false
            hunk_old[#hunk_old + 1] = line.text
            hunk_old_rows[#hunk_old_rows + 1] = line_row
          end
        end

        local words = changed_words(hunk_old, hunk_new)
        for side, hl_group in pairs({
          old = "JjDiffDeleteText",
          new = "JjDiffAddText",
        }) do
          local side_rows = side == "old" and hunk_old_rows or hunk_new_rows
          for _, range in ipairs(words[side]) do
            local row_of_range = side_rows[range.line]
            if row_of_range then
              marks[#marks + 1] = {
                row = row_of_range,
                col = range.start_col,
                opts = {
                  end_col = range.end_col,
                  hl_group = hl_group,
                  priority = 4200,
                },
              }
            end
          end
        end
      end
      syntax[#syntax + 1] =
        { path = file.path, lines = new_lines, rows = new_rows }
      syntax[#syntax + 1] =
        { path = file.path, lines = old_lines, rows = old_rows }
    end
  end

  -- Redrawing isn't an edit of the description.
  local modified = vim.bo[bufnr].modified
  local undolevels = vim.bo[bufnr].undolevels
  vim.bo[bufnr].undolevels = -1
  vim.api.nvim_buf_set_lines(bufnr, first, -1, false, lines)
  vim.bo[bufnr].undolevels = undolevels
  vim.bo[bufnr].modified = modified

  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  vim.api.nvim_buf_clear_namespace(bufnr, syntax_namespace, 0, -1)
  view.summary = vim.api.nvim_buf_set_extmark(bufnr, namespace, first, 0, {})
  for _, mark in ipairs(marks) do
    if mark.end_row then mark.opts.end_row = first + mark.end_row end
    vim.api.nvim_buf_set_extmark(
      bufnr,
      namespace,
      first + mark.row,
      mark.col or 0,
      mark.opts
    )
  end
  for _, file in ipairs(syntax) do
    ---@type (integer|false)[]
    local shifted = {}
    for index, row in ipairs(file.rows) do
      shifted[index] = row and first + row
    end
    highlight_syntax(bufnr, file.path, file.lines, shifted)
  end
  view.rows = rows
end

--- Draws a view from scratch, with the description jj has.
---@param bufnr integer
---@param view nvim_jj.View
local draw = function(bufnr, view)
  local description = vim.trim(view.details and view.details.description or "")
  local lines = vim.split(description, "\n", { plain = true })

  -- Drawing the change's description isn't an edit of it.
  local undolevels = vim.bo[bufnr].undolevels
  vim.bo[bufnr].undolevels = -1
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_lines(bufnr, #lines, #lines, false, { "" })
  vim.bo[bufnr].undolevels = undolevels

  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  view.summary = vim.api.nvim_buf_set_extmark(bufnr, namespace, #lines, 0, {})
  draw_files(bufnr, view)
  draw_placeholder(bufnr)
  vim.bo[bufnr].modified = false
end

--- Reads a view's change and draws it, keeping each window's cursor on the
--- same row.
---@param bufnr integer
---@param on_done? fun()
local load = function(bufnr, on_done)
  local view = views[bufnr]
  if not view then return end
  jj.details(view.root, view.id, function(err, details)
    if err or not details then
      return vim.notify(err or "", vim.log.levels.ERROR, { title = "nvim-jj" })
    end
    jj.diff(view.root, view.id, function(diff_err, diff)
      if diff_err or not diff then
        return vim.notify(
          diff_err or "",
          vim.log.levels.ERROR,
          { title = "nvim-jj" }
        )
      end
      if views[bufnr] ~= view or not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      view.details = details
      view.files = M.parse_diff(diff)

      local cursors = {}
      for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
        cursors[win] = vim.api.nvim_win_get_cursor(win)
      end
      draw(bufnr, view)
      local count = vim.api.nvim_buf_line_count(bufnr)
      for win, cursor in pairs(cursors) do
        pcall(
          vim.api.nvim_win_set_cursor,
          win,
          { math.min(cursor[1], count), cursor[2] }
        )
      end
      if on_done then on_done() end
    end)
  end)
end

--- Returns what's on a row of a view, if it's a file's or a line of its
--- hunks.
---@param bufnr integer
---@param view nvim_jj.View
---@param line integer The 1-based line.
---@return nvim_jj.ViewRow?
local row_at = function(bufnr, view, line)
  return view.rows[line - 1 - summary_row(bufnr, view)]
end

--- Shows or hides the hunks of the file on a line of a view, or of the file
--- whose hunks the line is in, and moves the cursor to the file's row.
---@param bufnr integer
---@param line integer The 1-based line.
M.toggle_file = function(bufnr, line)
  local view = views[bufnr]
  if not view then return end
  local row = row_at(bufnr, view, line)
  if not row or #row.file.hunks == 0 then return end
  local path = row.file.path
  view.expanded[path] = not view.expanded[path] or nil
  draw_files(bufnr, view)
  for offset, other in pairs(view.rows) do
    if other.file == row.file and not other.hunk then
      vim.api.nvim_win_set_cursor(
        0,
        { summary_row(bufnr, view) + offset + 1, 0 }
      )
      return
    end
  end
end

--- Moves the cursor to the first line of the next or previous hunk of the
--- expanded files of a view, if there's one.
---@param bufnr integer
---@param direction 1|-1
M.jump_to_hunk = function(bufnr, direction)
  local view = views[bufnr]
  if not view then return end
  local first = summary_row(bufnr, view)
  local cursor = vim.api.nvim_win_get_cursor(0)[1] - 1 - first
  ---@type integer?
  local target
  for offset, row in pairs(view.rows) do
    if row.first then
      local ahead = direction > 0 and offset > cursor
      local behind = direction < 0 and offset < cursor
      if ahead and (not target or offset < target) then target = offset end
      if behind and (not target or offset > target) then target = offset end
    end
  end
  if target then vim.api.nvim_win_set_cursor(0, { first + target + 1, 0 }) end
end

--- Returns the description edited in a view: its lines before the summary,
--- without the trailing empty ones.
---@param bufnr integer
---@param view nvim_jj.View
---@return string
local edited_description = function(bufnr, view)
  local lines =
    vim.api.nvim_buf_get_lines(bufnr, 0, summary_row(bufnr, view), false)
  return vim.trim(table.concat(lines, "\n"))
end

---@param bufnr integer
local release = function(bufnr)
  local view = views[bufnr]
  if not view then return end
  if view.watcher then view.watcher:close() end
  if view.timer then view.timer:close() end
  views[bufnr] = nil
end

--- Returns a buffer showing a change of a jj workspace, creating it if there's
--- none. Its first lines are the change's description, which writing the
--- buffer saves. They're followed by the change's details, the summary of the
--- files it changed, and their rows, where `<CR>` shows or hides a file's
--- hunks and `]]` and `[[` move between them. The buffer is redrawn after
--- each jj operation, unless the description has unsaved edits.
---@param root string
---@param id string
---@return integer bufnr
M.buffer = function(root, id)
  local name = ("%s%s/%s"):format(M.scheme, root, id)
  for bufnr, view in pairs(views) do
    if
      view.root == root
      and view.id == id
      and vim.api.nvim_buf_is_valid(bufnr)
    then
      return bufnr
    end
  end

  local bufnr = vim.api.nvim_create_buf(false, false)
  local eventignore = vim.o.eventignore
  vim.o.eventignore = "all"
  pcall(vim.api.nvim_buf_set_name, bufnr, name)
  vim.o.eventignore = eventignore

  vim.bo[bufnr].buftype = "acwrite"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].textwidth = 0
  vim.bo[bufnr].filetype = "jjchange"

  ---@type nvim_jj.View
  local view =
    { root = root, id = id, files = {}, expanded = {}, rows = {}, summary = 0 }
  views[bufnr] = view
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "" })
  view.summary = vim.api.nvim_buf_set_extmark(bufnr, namespace, 0, 0, {})

  local group =
    vim.api.nvim_create_augroup("nvim-jj-change-" .. bufnr, { clear = true })
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    group = group,
    buffer = bufnr,
    callback = function()
      local details = view.details
      if details and details.immutable then
        local subject = vim.split(details.description, "\n")[1] or ""
        if subject == "" then subject = "(no description set)" end
        local label = ("%s%s %s"):format(details.prefix, details.rest, subject)
        return vim.notify(
          jj.immutable_error(label),
          vim.log.levels.ERROR,
          { title = "nvim-jj" }
        )
      end
      -- The buffer counts as written right away, so `:wq` quits it. It's
      -- modified again if jj fails.
      vim.bo[bufnr].modified = false
      jj.describe(root, id, edited_description(bufnr, view), function(err)
        local valid = vim.api.nvim_buf_is_valid(bufnr)
        if err then
          if valid then vim.bo[bufnr].modified = true end
          return vim.notify(err, vim.log.levels.ERROR, { title = "nvim-jj" })
        end
        if valid then load(bufnr) end
      end)
    end,
  })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    buffer = bufnr,
    callback = function() draw_placeholder(bufnr) end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = bufnr,
    callback = function()
      release(bufnr)
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })

  local timer = assert(uv.new_timer())
  local watcher = assert(uv.new_fs_event())
  local ok = watcher:start(jj.op_heads_dir(root), {}, function()
    timer:start(
      op_debounce_ms,
      0,
      vim.schedule_wrap(function()
        if views[bufnr] == view and not vim.bo[bufnr].modified then
          load(bufnr)
        end
      end)
    )
  end)
  view.timer = timer
  if ok then
    view.watcher = watcher
  else
    watcher:close()
  end

  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
  end
  map(
    "<CR>",
    function() M.toggle_file(bufnr, vim.fn.line(".")) end,
    "Show or hide the file's hunks"
  )
  map("]]", function() M.jump_to_hunk(bufnr, 1) end, "Go to the next hunk")
  map("[[", function() M.jump_to_hunk(bufnr, -1) end, "Go to the previous hunk")
  map("q", function() vim.cmd.quit() end, "Close the change")

  load(bufnr)
  return bufnr
end

--- Sets the options of a window showing a change. The backticks of the
--- subject's code are concealed, except around the cursor.
---@param win integer
M.set_window_options = function(win)
  local wo = vim.wo[win][0]
  wo.number = false
  wo.relativenumber = false
  wo.wrap = false
  wo.list = false
  wo.signcolumn = "no"
  wo.foldcolumn = "0"
  wo.conceallevel = 2
  wo.concealcursor = "ni"
end

--- Returns whether a buffer shows a change.
---@param bufnr integer
---@return boolean
M.is_view = function(bufnr) return views[bufnr] ~= nil end

---@class nvim_jj.Recap
---@field lines string[]
---@field highlights { row: integer, col: integer, end_col: integer, hl_group: string }[]

--- Returns the recap of a change shown on hover, laid out like the top of its
--- view: its description, a separator, its details, the summary of its
--- files, and their rows.
---@param root string
---@param id string
---@param on_done fun(err?: string, recap?: nvim_jj.Recap)
M.recap = function(root, id, on_done)
  jj.details(root, id, function(err, details)
    if err or not details then return on_done(err) end
    jj.diff(root, id, function(diff_err, diff)
      if diff_err or not diff then return on_done(diff_err) end
      local files = M.parse_diff(diff)

      ---@type nvim_jj.Chunk[][]
      local chunk_lines = {}
      local description = vim.trim(details.description)
      if description == "" then
        chunk_lines[1] = { { "(no description set)", "JjPlaceholder" } }
      else
        for _, line in ipairs(vim.split(description, "\n", { plain = true })) do
          chunk_lines[#chunk_lines + 1] = { { line } }
        end
      end
      local separator = #chunk_lines + 1
      chunk_lines[separator] = {}
      vim.list_extend(chunk_lines, details_lines(details))
      chunk_lines[#chunk_lines + 1] = {}
      local summary, totals = M.summarize(files)
      if #totals > 0 then
        vim.list_extend(summary, vim.list_extend({ { " " } }, totals))
      end
      chunk_lines[#chunk_lines + 1] = summary
      for _, file in ipairs(files) do
        local status = statuses[file.status]
        local row = { { status[1], status[2] }, { " " .. file_text(file) } }
        local stats = file_stats(file)
        if #stats > 0 then
          vim.list_extend(row, vim.list_extend({ { " " } }, stats))
        end
        chunk_lines[#chunk_lines + 1] = row
      end

      local width = 0
      for _, chunks in ipairs(chunk_lines) do
        width = math.max(width, vim.api.nvim_strwidth(text_of(chunks)))
      end
      chunk_lines[separator] = { { ("─"):rep(width), "JjSeparator" } }

      ---@type nvim_jj.Recap
      local recap = { lines = {}, highlights = {} }
      for row, chunks in ipairs(chunk_lines) do
        recap.lines[row] = text_of(chunks)
        for _, highlight in ipairs(chunk_highlights(chunks, 0)) do
          recap.highlights[#recap.highlights + 1] = {
            row = row - 1,
            col = highlight.col,
            end_col = highlight.end_col,
            hl_group = highlight.hl_group,
          }
        end
      end
      on_done(nil, recap)
    end)
  end)
end

--- Draws a recap's highlights in a buffer showing its lines, and conceals the
--- backticks of the subject's code like the view does. The window gets a
--- column of padding on each side.
---@param bufnr integer
---@param win integer
---@param recap nvim_jj.Recap
M.decorate = function(bufnr, win, recap)
  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  for _, highlight in ipairs(recap.highlights) do
    vim.api.nvim_buf_set_extmark(
      bufnr,
      namespace,
      highlight.row,
      highlight.col,
      {
        end_col = highlight.end_col,
        hl_group = highlight.hl_group,
      }
    )
  end
  for _, span in ipairs(M.code_spans(recap.lines[1] or "")) do
    local open, close = span[1], span[2]
    vim.api.nvim_buf_set_extmark(bufnr, namespace, 0, open + 1, {
      end_col = close,
      hl_group = "JjCode",
    })
    for _, col in ipairs({ open, close }) do
      vim.api.nvim_buf_set_extmark(bufnr, namespace, 0, col, {
        end_col = col + 1,
        hl_group = "JjCodeDelimiter",
        conceal = "",
      })
    end
  end
  vim.wo[win].conceallevel = 2
  vim.wo[win].concealcursor = "n"
  vim.api.nvim_win_set_config(
    win,
    { border = { "", "", "", " ", "", "", "", " " } }
  )
end

--- Returns the color of a highlight group's attribute, following its links.
---@param name string
---@param attr "fg"|"bg"
---@return integer?
local color_of = function(name, attr)
  return vim.api.nvim_get_hl(0, { name = name, link = false })[attr]
end

--- Returns a color blended into another one by some amount.
---@param color integer
---@param base integer
---@param alpha number The amount of the color, from 0 to 1.
---@return integer
local blend = function(color, base, alpha)
  local mixed = 0
  for _, shift in ipairs({ 16, 8, 0 }) do
    local channel = bit.band(bit.rshift(color, shift), 0xff)
    local base_channel = bit.band(bit.rshift(base, shift), 0xff)
    mixed = mixed
      + bit.lshift(
        math.floor(channel * alpha + base_channel * (1 - alpha) + 0.5),
        shift
      )
  end
  return mixed
end

--- Sets the default colors of the views. The context lines' numbers are on
--- a background a shade lighter than the text's, and the rows between hunks
--- on a tint of the information color, like GitHub's.
M.set_highlights = function()
  local background = color_of("Normal", "bg")
    or (vim.o.background == "dark" and 0x000000 or 0xffffff)
  local foreground = color_of("Normal", "fg")
    or (vim.o.background == "dark" and 0xffffff or 0x000000)
  local info = color_of("DiagnosticInfo", "fg") or foreground

  ---@type table<string, vim.api.keyset.highlight>
  local highlights = {
    JjAddedCount = { link = "Added" },
    JjAddedFiles = { link = "Added" },
    JjChevron = { link = "NonText" },
    JjDeletedCount = { link = "Removed" },
    JjDeletedFiles = { link = "Removed" },
    JjDiffAdd = { link = "DiffAdd" },
    JjDiffAddNr = { link = "DiffAdd" },
    JjDiffAddText = { link = "DiffText" },
    JjDiffContextNr = {
      bg = blend(foreground, background, 0.06),
      fg = color_of("LineNr", "fg"),
    },
    JjDiffDelete = { link = "DiffDelete" },
    JjDiffDeleteNr = { link = "DiffDelete" },
    JjDiffDeleteText = { link = "DiffText" },
    JjDiffGap = {
      bg = blend(info, background, 0.12),
      fg = color_of("Comment", "fg"),
    },
    JjDiffGapNr = { bg = blend(info, background, 0.25) },
    JjDiffIndent = { link = "Normal" },
    JjModifiedFiles = { link = "Changed" },
    JjRenamedFiles = { link = "Special" },
    JjSeparator = { link = "NonText" },
  }
  for name, highlight in pairs(highlights) do
    highlight.default = true
    vim.api.nvim_set_hl(0, name, highlight)
  end
end

return M
