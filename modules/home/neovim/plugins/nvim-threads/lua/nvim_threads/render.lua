local M = {}

M.namespace = vim.api.nvim_create_namespace("nvim-threads")

---@alias nvim_threads.Chunk [string, (string|string[])?]

---@alias nvim_threads.RowKind "header"|"author"|"body"|"blank"|"suggestion"|"composer"

--- A screen row of a thread. Its prefix is the border, which the float
--- draws in its 'statuscolumn'.
---@class nvim_threads.Row
---@field kind nvim_threads.RowKind
---@field prefix nvim_threads.Chunk[]
---@field chunks nvim_threads.Chunk[]
---@field comment? integer The index of the comment the row belongs to.
---@field placeholder? string The text drawn over an empty composer.

--- The state of a thread's display, which isn't saved.
---@class nvim_threads.View
---@field expanded boolean
--- The replies being streamed in, keyed by the names of their participants.
---@field pending table<string, string>
---@field draft? string[] The composer's lines, while it's shown.
--- Where insert mode was last left in the composer, as the 0-based row from
--- the composer's first line and the byte column.
---@field insert_at? [integer, integer]
---@field frame string The spinner's current frame.

--- The number of agents' colors, which participants cycle through in the
--- order they joined the thread.
local author_colors = 4

--- The border of a thread's rows, which is as wide as the float's
--- 'statuscolumn'.
local border = "▎  "

M.border = border

--- The icon of a thread waiting on me, from Nerd Fonts. It's drawn two cells
--- wide, which is one more than Neovim counts, so the space after it is
--- one cell narrower than after the spinner's frames.
local waiting_on_me_icon = "\u{f075}"

M.waiting_on_me_icon = waiting_on_me_icon

--- The groups combining a group's attributes with the threads' background,
--- created so far.
---@type table<string, true?>
local on_background = {}

--- Defines the default highlight groups of threads. They're drawn over the
--- background of `ThreadsNormal`, so the defaults only link to groups
--- setting the foreground.
M.set_highlights = function()
  on_background = {}
  vim.api.nvim_set_hl(
    0,
    "ThreadsNormal",
    { link = "NormalFloat", default = true }
  )
  -- The title and the bodies take the foreground of `ThreadsNormal`.
  vim.api.nvim_set_hl(0, "ThreadsTitle", { default = true })
  local links = {
    ThreadsChevron = "Special",
    ThreadsGutter = "LineNr",
    ThreadsPlaceholder = "Comment",
    ThreadsMeta = "Comment",
    ThreadsWaitingOnAgent = "DiagnosticWarn",
    ThreadsWaitingOnMe = "DiagnosticInfo",
    ThreadsOutdated = "DiagnosticWarn",
    ThreadsError = "DiagnosticError",
    ThreadsSuggestion = "Added",
    ThreadsAuthorMe = "Special",
    ThreadsAuthor1 = "DiagnosticHint",
    ThreadsAuthor2 = "DiagnosticOk",
    ThreadsAuthor3 = "Constant",
    ThreadsAuthor4 = "Identifier",
    ThreadsAnchor = "Visual",
  }
  for name, link in pairs(links) do
    vim.api.nvim_set_hl(0, name, { link = link, default = true })
  end
end

--- Returns the highlight group of an author's name and border.
---@param thread nvim_threads.Thread
---@param author string
---@return string
local author_hl = function(thread, author)
  if author == "me" then return "ThreadsAuthorMe" end
  local index = 1
  for i, name in ipairs(thread.participants) do
    if name == author then index = i end
  end
  return ("ThreadsAuthor%d"):format((index - 1) % author_colors + 1)
end

--- Returns a duration since a Unix time, like `now`, `5m` or `2d`.
---@param time integer
---@return string
local ago = function(time)
  local seconds = os.time() - time
  if seconds < 60 then return "now" end
  if seconds < 3600 then return ("%dm"):format(math.floor(seconds / 60)) end
  if seconds < 86400 then return ("%dh"):format(math.floor(seconds / 3600)) end
  return ("%dd"):format(math.floor(seconds / 86400))
end

--- Returns the treesitter highlights of a markdown text, including those of
--- its inline elements and code blocks, by 1-based line.
---@param text string
---@return table<integer, [integer, integer, string][]>
local syntax = function(text)
  local syntax_by_line = {}
  local ok, parser = pcall(vim.treesitter.get_string_parser, text, "markdown")
  if not ok or not parser then return syntax_by_line end
  parser:parse(true)

  local seq = 0
  ---@type table<integer, { [1]: integer, [2]: integer, [3]: string, priority: integer, seq: integer }[]>
  local captures_by_line = {}
  parser:for_each_tree(function(tree, language_tree)
    local lang = language_tree:lang()
    local query = vim.treesitter.query.get(lang, "highlights")
    if not query then return end
    for id, node, metadata in query:iter_captures(tree:root(), text) do
      local name = query.captures[id]
      if
        name
        and not vim.startswith(name, "_")
        and name ~= "spell"
        and name ~= "nospell"
        and name ~= "conceal"
      then
        local priority = tonumber(
          metadata.priority or (metadata[id] and metadata[id].priority)
        ) or vim.hl.priorities.treesitter
        local group = ("@%s.%s"):format(name, lang)
        local start_row, start_col, end_row, end_col = node:range()
        for row = start_row, end_row do
          seq = seq + 1
          local line = row + 1
          captures_by_line[line] = captures_by_line[line] or {}
          table.insert(captures_by_line[line], {
            row == start_row and start_col or 0,
            row == end_row and end_col or math.huge,
            group,
            priority = priority,
            seq = seq,
          })
        end
      end
    end
  end)

  for line, captures in pairs(captures_by_line) do
    table.sort(captures, function(a, b)
      if a.priority ~= b.priority then return a.priority < b.priority end
      return a.seq < b.seq
    end)
    syntax_by_line[line] = vim
      .iter(captures)
      :map(function(capture) return { capture[1], capture[2], capture[3] } end)
      :totable()
  end
  return syntax_by_line
end

--- Returns the highlight group of each byte of a line, where a later capture
--- takes precedence over an earlier one.
---@param text string
---@param captures? [integer, integer, string][]
---@return table<integer, string?>
local groups_of = function(text, captures)
  local groups = {}
  for _, capture in ipairs(captures or {}) do
    for col = capture[1] + 1, math.min(capture[2], #text) do
      groups[col] = capture[3]
    end
  end
  return groups
end

--- Returns the chunks of the bytes of a line between two 0-based columns,
--- the end being exclusive, each with its highlight group.
---@param text string
---@param groups table<integer, string?>
---@param from integer
---@param to integer
---@param hl? string The group under the syntax's groups.
---@return nvim_threads.Chunk[]
local chunks_of = function(text, groups, from, to, hl)
  local chunks = {}
  local col = from + 1
  while col <= to do
    local group = groups[col]
    local last = col
    while last < to and groups[last + 1] == group do
      last = last + 1
    end
    local hl_group = group and hl and { hl, group } or group or hl
    chunks[#chunks + 1] = { text:sub(col, last), hl_group }
    col = last + 1
  end
  return chunks
end

--- Returns the 0-based byte ranges of the rows a line wraps into within a
--- width, breaking after spaces where possible.
---@param text string
---@param width integer
---@return [integer, integer][]
M.wrap = function(text, width)
  width = math.max(width, 1)
  if text == "" then return { { 0, 0 } } end

  local ranges = {}
  local start, used = 0, 0
  -- The byte after the last space of the current row, where it can break.
  local break_at
  local col = 0
  while col < #text do
    local char_end = col + vim.str_utf_end(text, col + 1) + 1
    local char = text:sub(col + 1, char_end)
    local char_width = vim.api.nvim_strwidth(char)
    if used + char_width > width and col > start then
      local stop = break_at and break_at > start and break_at or col
      ranges[#ranges + 1] = { start, stop }
      start = stop
      used = vim.api.nvim_strwidth(text:sub(start + 1, col))
      break_at = nil
    end
    used = used + char_width
    col = char_end
    if char == " " then break_at = col end
  end
  ranges[#ranges + 1] = { start, #text }
  return ranges
end

--- Returns the rows of a markdown text wrapped within a width.
---@param text string
---@param width integer
---@param prefix nvim_threads.Chunk[]
---@param kind nvim_threads.RowKind
---@param comment? integer
---@param hl? string The group under the syntax's groups.
---@return nvim_threads.Row[]
local text_rows = function(text, width, prefix, kind, comment, hl)
  text = text:gsub("\t", "    ")
  local rows = {}
  local captures = syntax(text)
  for line_index, line in ipairs(vim.split(text, "\n", { plain = true })) do
    local groups = groups_of(line, captures[line_index])
    for _, range in ipairs(M.wrap(line, width)) do
      rows[#rows + 1] = {
        kind = kind,
        prefix = prefix,
        chunks = chunks_of(line, groups, range[1], range[2], hl),
        comment = comment,
      }
    end
  end
  return rows
end

--- Returns the title of a thread, or the start of its first comment if it
--- doesn't have one yet.
---@param thread nvim_threads.Thread
---@return string title
---@return boolean is_placeholder
M.title = function(thread)
  if thread.title then return thread.title, false end
  local first = thread.comments[1]
  if not first then return "New thread", true end
  local line = vim.trim(vim.split(first.body, "\n", { plain = true })[1] or "")
  return line, true
end

---@param thread nvim_threads.Thread
---@param view nvim_threads.View
---@return nvim_threads.Row
local header = function(thread, view)
  local waiting = next(view.pending) ~= nil
  local title, is_placeholder = M.title(thread)
  ---@type nvim_threads.Chunk[]
  local chunks = {
    { view.expanded and "▾ " or "▸ ", "ThreadsChevron" },
    {
      title,
      is_placeholder and #thread.comments == 0 and "ThreadsPlaceholder"
        or "ThreadsTitle",
    },
  }

  local count = #thread.comments
  local details = {}
  if count > 0 then
    details[#details + 1] = ("%d message%s"):format(
      count,
      count == 1 and "" or "s"
    )
  end
  if not view.expanded and view.draft then details[#details + 1] = "draft" end
  if thread.outdated then details[#details + 1] = "outdated" end
  if #details > 0 then
    chunks[#chunks + 1] =
      { (" (%s)"):format(table.concat(details, ", ")), "ThreadsMeta" }
  end

  -- The status takes the place of the border, so the float draws it in its
  -- 'statuscolumn' too.
  return {
    kind = "header",
    prefix = {
      waiting and { view.frame .. "  ", "ThreadsWaitingOnAgent" }
        or { waiting_on_me_icon .. "  ", "ThreadsWaitingOnMe" },
    },
    chunks = chunks,
  }
end

--- Returns the rows of a thread laid out within a width, which are its
--- header if it's collapsed. An expanded thread's rows also include its
--- comments, the replies streamed in so far, and the composer while it's
--- shown.
---@param thread nvim_threads.Thread
---@param view nvim_threads.View
---@param width integer The width of the window's text area.
---@return nvim_threads.Row[]
M.rows = function(thread, view, width)
  local rows = { header(thread, view) }
  if not view.expanded then return rows end

  local body_width = width - vim.api.nvim_strwidth(border)

  ---@param author string
  ---@param time? integer
  ---@param comment? integer
  local add_author = function(author, time, comment)
    local hl = author_hl(thread, author)
    rows[#rows + 1] = {
      kind = "blank",
      prefix = { { border, hl } },
      chunks = {},
      comment = comment,
    }
    rows[#rows + 1] = {
      kind = "author",
      prefix = { { border, hl } },
      chunks = {
        { author, hl },
        time and { "  " .. ago(time), "ThreadsMeta" } or {
          "  " .. view.frame,
          "ThreadsWaitingOnAgent",
        },
      },
      comment = comment,
    }
  end

  for index, comment in ipairs(thread.comments) do
    add_author(comment.author, comment.time, index)
    local prefix = { { border, author_hl(thread, comment.author) } }
    vim.list_extend(
      rows,
      text_rows(
        comment.body,
        body_width,
        prefix,
        "body",
        index,
        comment.error and "ThreadsError" or nil
      )
    )
    if comment.edits and #comment.edits > 0 then
      local paths, seen = {}, {}
      for _, edit in ipairs(comment.edits) do
        if not seen[edit.path] then
          seen[edit.path] = true
          paths[#paths + 1] = edit.path
        end
      end
      local applied = comment.applied ~= nil
      for _, path in ipairs(paths) do
        if not (comment.applied and comment.applied[path]) then
          applied = false
        end
      end
      rows[#rows + 1] = {
        kind = "suggestion",
        prefix = prefix,
        chunks = {
          {
            ("✎ Suggested edits to %s"):format(table.concat(paths, ", ")),
            "ThreadsSuggestion",
          },
          applied and { " · applied", "ThreadsMeta" } or nil,
        },
        comment = index,
      }
    end
  end

  local pending_names = vim.tbl_keys(view.pending)
  table.sort(pending_names)
  for _, name in ipairs(pending_names) do
    add_author(name)
    local text = view.pending[name]
    if text ~= "" then
      local prefix = { { border, author_hl(thread, name) } }
      vim.list_extend(rows, text_rows(text, body_width, prefix, "body"))
    end
  end

  if view.draft then
    rows[#rows + 1] = {
      kind = "blank",
      prefix = { { border, "ThreadsAuthorMe" } },
      chunks = {},
    }
    local prefix = { { border, "ThreadsAuthorMe" } }
    local is_empty = #view.draft == 1 and view.draft[1] == ""
    for _, line in ipairs(view.draft) do
      rows[#rows + 1] = {
        kind = "composer",
        prefix = prefix,
        chunks = { { line } },
        placeholder = is_empty
            and (#thread.comments == 0 and "Write a remark, @ mentions a participant" or "Reply")
          or nil,
      }
    end
  end

  return rows
end

--- Returns a row's text, without its prefix.
---@param row nvim_threads.Row
---@return string
M.text = function(row)
  return table.concat(
    vim.tbl_map(function(chunk) return chunk[1] end, row.chunks)
  )
end

--- Returns the name of a group with a group's attributes over the threads'
--- background, which the float's 'statuscolumn' draws its borders with.
---@param group string
---@return string
M.on_background = function(group)
  local name = "ThreadsOn" .. group:gsub("[^%w]", "")
  if not on_background[name] then
    local background =
      vim.api.nvim_get_hl(0, { name = "ThreadsNormal", link = false })
    local attrs = vim.api.nvim_get_hl(0, { name = group, link = false })
    attrs.bg = background.bg
    attrs.ctermbg = background.ctermbg
    vim.api.nvim_set_hl(0, name, attrs --[[@as vim.api.keyset.highlight]])
    on_background[name] = true
  end
  return name
end

--- Returns the chunks of a row drawn as a virtual line over the threads'
--- background, padded to the width of the text area.
---@param row nvim_threads.Row
---@param width integer
---@return nvim_threads.Chunk[]
M.virt_line = function(row, width)
  local chunks = vim.list_extend(vim.deepcopy(row.prefix), row.chunks)
  if row.placeholder then
    chunks[#chunks + 1] = { row.placeholder, "ThreadsPlaceholder" }
  end

  local used = 0
  for _, chunk in ipairs(chunks) do
    used = used + vim.api.nvim_strwidth(chunk[1])
    local hl = chunk[2]
    if type(hl) == "table" then
      chunk[2] = vim.list_extend({ "ThreadsNormal" }, hl)
    else
      chunk[2] = hl and { "ThreadsNormal", hl } or "ThreadsNormal"
    end
  end
  if used < width then
    chunks[#chunks + 1] = { (" "):rep(width - used), "ThreadsNormal" }
  end
  return chunks
end

return M
