local M = {}

M.namespace = vim.api.nvim_create_namespace("nvim-threads")

---@alias nvim_threads.Chunk [string, (string|string[])?]

---@alias nvim_threads.RowKind "header"|"author"|"body"|"blank"|"separator"|"suggestion"|"edit"|"diff"|"composer"

--- A screen row of a thread. Its prefix is the border, which the float
--- draws in its 'statuscolumn'.
---@class nvim_threads.Row
---@field kind nvim_threads.RowKind
---@field prefix nvim_threads.Chunk[]
---@field chunks nvim_threads.Chunk[]
---@field comment? integer The index of the comment the row belongs to.
---@field path? string The file of the suggested edits the row shows.
---@field edit? integer The index of the suggested edit the row shows.
---@field fill? string The group of the row's background past its text.
---@field expanded? boolean Whether the suggested edit the row shows is expanded.
---@field conceals? nvim_threads.Conceal[] The text the row hides, sorted.
---@field elements? nvim_threads.Element[] The elements with hidden parts the row covers part of.
---@field placeholder? string The text drawn over an empty composer.

--- A part of a Markdown element that's hidden unless the cursor is in the
--- element, like the backticks of a code span.
---@class nvim_threads.Conceal
---@field from integer The 0-based byte column of the text hidden in its row.
---@field to integer The exclusive end column.
---@field text string What's shown instead.
---@field element nvim_threads.Element

--- A Markdown element with hidden parts, as the rows and byte ranges it
--- covers.
---@class nvim_threads.Element
---@field parts { row: nvim_threads.Row, from: integer, to: integer }[]
---@field range [integer, integer, integer, integer] Its 0-based range in its text.

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
--- Whether the suggested edits are expanded, keyed by the indices of their
--- comment and of the edit, like `1:2`. Without a key, the edits still to
--- apply are expanded, and the others collapsed.
---@field expanded_edits table<string, boolean?>
--- The files whose suggested edits are collapsed, keyed by the index of
--- their comment and the file's path, like `1:f.txt`.
---@field collapsed_files table<string, true?>

--- The number of agents' colors, which participants cycle through in the
--- order they joined the thread.
local author_colors = 4

--- The border of a thread's rows, which is as wide as the float's
--- 'statuscolumn'.
local border = "▎ "

M.border = border

--- The border on the right of the rows of messages, mirroring the one on
--- their left.
local right_border = " 🮇"

--- Returns the border on the right of a row, if it's a message's, with its
--- left border's group.
---@param row nvim_threads.Row
---@return nvim_threads.Chunk?
M.right_border = function(row)
  if row.kind == "header" or row.kind == "separator" then return end
  local left = row.prefix[1]
  return { right_border, left and left[2] }
end

--- Returns whether a row is drawn on the threads' background, which only
--- the title and the composer are. The other rows are on the window's.
---@param row nvim_threads.Row
---@return boolean
M.is_shaded = function(row)
  return row.kind == "header" or row.kind == "composer"
end

--- The icon of a thread waiting on me, from Nerd Fonts. It's drawn two cells
--- wide, which is one more than Neovim counts, so it covers the space after
--- it, which follows the spinner's frames.
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
    ThreadsMention = "Special",
    ThreadsSeparator = "WinSeparator",
    ThreadsAuthorMe = "Directory",
    ThreadsAuthor1 = "DiagnosticHint",
    ThreadsAuthor2 = "DiagnosticOk",
    ThreadsAuthor3 = "Constant",
    ThreadsAuthor4 = "Identifier",
    ThreadsAnchor = "Visual",
  }
  for name, link in pairs(links) do
    vim.api.nvim_set_hl(0, name, { link = link, default = true })
  end
  -- The rows naming the files of suggested edits take the text's color.
  vim.api.nvim_set_hl(0, "ThreadsSuggestion", { bold = true, default = true })
end

--- Returns the name of a participant's own highlight group, like
--- `ThreadsAuthorClaude` for `claude`.
---@param name string
---@return string
M.author_group = function(name)
  local pascal = name:gsub("^%l", string.upper):gsub("[^%w]", "")
  return "ThreadsAuthor" .. pascal
end

--- Returns the highlight group of an author's name and border.
---@param thread nvim_threads.Thread
---@param author string
---@return string
local author_hl = function(thread, author)
  if author == "me" then return "ThreadsAuthorMe" end
  local own = M.author_group(author)
  if vim.fn.hlexists(own) == 1 then return own end
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

--- Returns the number of seconds until the duration since a Unix time, as
--- `ago()` shows it, changes.
---@param time integer
---@return integer
M.age_changes_in = function(time)
  local seconds = os.time() - time
  if seconds < 60 then return 60 - seconds end
  if seconds < 3600 then return 60 - seconds % 60 end
  if seconds < 86400 then return 3600 - seconds % 3600 end
  return 86400 - seconds % 86400
end

---@type fun(text: string, lang: string): table<integer, [integer, integer, string][]>, nvim_threads.HiddenText[]
local parse

--- Returns the treesitter highlights of a text in a language, including
--- those of the languages injected in it, by 1-based line.
---@param text string
---@param lang string
---@return table<integer, [integer, integer, string][]>
M.syntax = function(text, lang) return (parse(text, lang)) end

--- The types of the Markdown nodes whose hidden parts are revealed
--- together, when the cursor is in one of them.
local elements = {
  code_span = true,
  emphasis = true,
  strong_emphasis = true,
  strikethrough = true,
  inline_link = true,
  full_reference_link = true,
  collapsed_reference_link = true,
  shortcut_link = true,
  image = true,
  fenced_code_block = true,
}

--- Returns the 0-based range of the element a hidden node is part of: its
--- closest ancestor that's an element, or the node itself.
---@param node TSNode
---@return integer start_row
---@return integer start_col
---@return integer end_row
---@return integer end_col
local element_range = function(node)
  local current = node:parent()
  while current do
    if elements[current:type()] then return current:range() end
    current = current:parent()
  end
  return node:range()
end

---@class nvim_threads.HiddenText
---@field line integer The 1-based line.
---@field from integer The 0-based byte column.
---@field to integer The exclusive end column.
---@field text string What's shown instead.
---@field element string The range of its element, as a key.
---@field range [integer, integer, integer, integer] The element's 0-based range.

--- Returns the treesitter highlights of a text in a language by 1-based
--- line, and the text its queries conceal.
---@param text string
---@param lang string
---@return table<integer, [integer, integer, string][]> highlights
---@return nvim_threads.HiddenText[] hidden
parse = function(text, lang)
  local syntax_by_line, hidden = {}, {}
  -- A closing code fence is only one when a newline follows it.
  text = text .. "\n"
  local ok, parser = pcall(vim.treesitter.get_string_parser, text, lang)
  if not ok or not parser then return syntax_by_line, hidden end
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
      local replacement = metadata.conceal
        or (metadata[id] and metadata[id].conceal)
      if replacement then
        local range = vim.treesitter.get_range(node, text, metadata[id])
        local start_row, start_col, _, end_row, end_col = unpack(range)
        local element = { element_range(node) }
        for row = start_row, end_row do
          local from = row == start_row and start_col or 0
          local to = row == end_row and end_col or math.huge
          if to > from then
            hidden[#hidden + 1] = {
              line = row + 1,
              from = from,
              to = to,
              text = row == start_row and replacement or "",
              element = table.concat(element, ":"),
              range = element,
            }
          end
        end
      end
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
  return syntax_by_line, hidden
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

--- Returns the 0-based byte ranges of the mentions of participants in a
--- line, like `@claude`, the end being exclusive.
---@param line string
---@return [integer, integer][]
M.mentions = function(line)
  local ranges = {}
  for start, stop in line:gmatch("()@[%w_.-]+()") do
    local from = start --[[@as integer]]
    local to = stop --[[@as integer]]
    local before = from > 1 and line:sub(from - 1, from - 1) or ""
    if not before:match("[%w_.-]") then
      ranges[#ranges + 1] = { from - 1, to - 1 }
    end
  end
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
  local captures, hidden = parse(text, "markdown")
  ---@type table<string, nvim_threads.Element?>
  local elements_by_key = {}
  ---@param key string
  ---@param range [integer, integer, integer, integer]
  ---@return nvim_threads.Element
  local element_of = function(key, range)
    local element = elements_by_key[key]
    if element then return element end
    element = { parts = {}, range = range }
    elements_by_key[key] = element
    return element
  end
  for line_index, line in ipairs(vim.split(text, "\n", { plain = true })) do
    local groups = groups_of(line, captures[line_index])
    for _, mention in ipairs(M.mentions(line)) do
      for col = mention[1] + 1, mention[2] do
        groups[col] = "ThreadsMention"
      end
    end
    for _, range in ipairs(M.wrap(line, width)) do
      ---@type nvim_threads.Row
      local row = {
        kind = kind,
        prefix = prefix,
        chunks = chunks_of(line, groups, range[1], range[2], hl),
        comment = comment,
      }
      rows[#rows + 1] = row

      for _, part in ipairs(hidden) do
        if
          part.line == line_index
          and part.to > range[1]
          and part.from < range[2]
        then
          row.conceals = row.conceals or {}
          table.insert(row.conceals, {
            from = math.max(part.from, range[1]) - range[1],
            to = math.min(part.to, range[2]) - range[1],
            text = part.from >= range[1] and part.text or "",
            element = element_of(part.element, part.range),
          })
        end
      end
      -- The row's part of each element covering it.
      for _, element in pairs(elements_by_key) do
        local first_row, first_col, last_row, last_col = unpack(element.range)
        local row_index = line_index - 1
        if row_index >= first_row and row_index <= last_row then
          local from = row_index == first_row and first_col or 0
          local to = row_index == last_row and last_col or #line
          from, to = math.max(from, range[1]), math.min(to, range[2])
          if to >= from and (to > from or range[1] == range[2]) then
            table.insert(
              element.parts,
              { row = row, from = from - range[1], to = to - range[1] }
            )
            row.elements = row.elements or {}
            table.insert(row.elements, element)
          end
        end
      end
      if row.conceals then
        table.sort(row.conceals, function(a, b) return a.from < b.from end)
      end
    end
  end
  return rows
end

--- The diffs of nvim-hunks, when it's installed.
local ok_view, view = pcall(require, "nvim_hunks.view")

--- The rows of the diffs drawn so far, by edit, with the width they were
--- laid out in.
---@type table<nvim_threads.EditDiff, { width: integer, rows: nvim_hunks.view.Row[] }?>
local diff_cache = setmetatable({}, { __mode = "k" })

--- Returns the rows of an edit's diff laid out within a width.
---@param edit nvim_threads.EditDiff
---@param path string
---@param width integer
---@return nvim_hunks.view.Row[]
local diff_view_rows = function(edit, path, width)
  if not ok_view then return {} end
  local cached = diff_cache[edit]
  if cached and cached.width == width then return cached.rows end
  local rows = view.rows(edit.hunks, {
    path = path,
    old_lines = edit.old_lines,
    new_lines = edit.new_lines,
    width = width,
  })
  diff_cache[edit] = { width = width, rows = rows }
  return rows
end

--- Returns the key of a comment's edit in a view's `expanded_edits`.
---@param comment integer
---@param edit integer
---@return string
M.edit_key = function(comment, edit) return comment .. ":" .. edit end

--- Returns the key of a comment's file in a view's `collapsed_files`.
---@param comment integer
---@param path string
---@return string
M.file_key = function(comment, path) return comment .. ":" .. path end

--- Returns the rows of the edits a comment suggests to a file: a row naming
--- the file, then each edit's diff, wrapped within a width, with the lines'
--- numbers and the number of unchanged lines between its hunks. The applied
--- and rejected edits are a row each, unless they're expanded.
---@param diff nvim_threads.FileDiff
---@param view nvim_threads.View
---@param width integer
---@param prefix nvim_threads.Chunk[]
---@param comment integer
---@return nvim_threads.Row[]
local diff_rows = function(diff, view, width, prefix, comment)
  ---@type table<string, integer>
  local counts = { applied = 0, rejected = 0 }
  for _, edit in ipairs(diff.edits) do
    if edit.state == "applied" or edit.state == "rejected" then
      counts[edit.state] = (counts[edit.state] or 0) + 1
    end
  end
  local collapsed = view.collapsed_files[M.file_key(comment, diff.path)] == true
  ---@type nvim_threads.Chunk[]
  local header = {
    { collapsed and "▸ " or "▾ ", "ThreadsChevron" },
    { ("✎ Suggested edits to %s"):format(diff.path), "ThreadsSuggestion" },
  }
  for _, state in ipairs({ "applied", "rejected" }) do
    local count = counts[state] or 0
    if count > 0 then
      local text = count == #diff.edits and state
        or ("%d %s"):format(count, state)
      header[#header + 1] = { " · " .. text, "ThreadsMeta" }
    end
  end
  ---@type nvim_threads.Row[]
  local rows = {
    {
      kind = "suggestion",
      prefix = prefix,
      chunks = header,
      comment = comment,
      path = diff.path,
    },
  }
  if collapsed then return rows end

  ---@param chunks nvim_threads.Chunk[]
  ---@param edit integer
  ---@param expanded boolean
  ---@param fill? string
  ---@param kind? nvim_threads.RowKind
  local add = function(chunks, edit, expanded, fill, kind)
    rows[#rows + 1] = {
      kind = kind or "diff",
      prefix = prefix,
      chunks = chunks,
      comment = comment,
      path = diff.path,
      edit = edit,
      expanded = expanded,
      fill = fill,
    }
  end

  for _, edit in ipairs(diff.edits) do
    local resolved = edit.state == "applied" or edit.state == "rejected"
    local expanded = view.expanded_edits[M.edit_key(comment, edit.index)]
    if expanded == nil then expanded = not resolved end
    do
      ---@type table<string, string>
      local texts = {
        pending = "Edit",
        applied = "Applied edit",
        rejected = "Rejected edit",
        outdated = "Outdated edit",
      }
      local text = texts[edit.state] or "Edit"
      if edit.line then text = text .. (" at line %d"):format(edit.line) end
      if edit.state == "outdated" then
        text = text .. ", whose text isn't in the file anymore"
      end
      add({
        { expanded and "▾ " or "▸ ", "ThreadsChevron" },
        { text, "ThreadsMeta" },
      }, edit.index, expanded, nil, "edit")
    end

    if expanded then
      for _, row in ipairs(diff_view_rows(edit, diff.path, width)) do
        add(
          vim.list_extend(vim.list_extend({}, row.gutter), row.chunks),
          edit.index,
          expanded,
          row.fill
        )
      end
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
      waiting and { view.frame .. " ", "ThreadsWaitingOnAgent" }
        or { waiting_on_me_icon .. " ", "ThreadsWaitingOnMe" },
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
---@param diffs fun(comment: integer): nvim_threads.FileDiff[] Returns the diffs of the edits a comment suggests.
---@return nvim_threads.Row[]
M.rows = function(thread, view, width, diffs)
  local rows = { header(thread, view) }
  if not view.expanded then return rows end

  local body_width = width
    - vim.api.nvim_strwidth(border)
    - vim.api.nvim_strwidth(right_border)

  -- A thin line separates each message from the previous one, from a cell
  -- after the edge of the window to a cell before the other.
  local separate = function()
    if #rows == 1 then return end
    local line = ("─"):rep(math.max(width - 2, 0))
    local prefix_width = vim.api.nvim_strwidth(border)
    rows[#rows + 1] = {
      kind = "separator",
      prefix = {
        {
          " " .. vim.fn.strcharpart(line, 0, prefix_width - 1),
          "ThreadsSeparator",
        },
      },
      chunks = {
        { vim.fn.strcharpart(line, prefix_width - 1), "ThreadsSeparator" },
        { " " },
      },
    }
  end

  ---@param author string
  ---@param time? integer
  ---@param comment? integer
  local add_author = function(author, time, comment)
    separate()
    local hl = author_hl(thread, author)
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
      for _, diff in ipairs(diffs(index)) do
        rows[#rows + 1] =
          { kind = "blank", prefix = prefix, chunks = {}, comment = index }
        vim.list_extend(rows, diff_rows(diff, view, body_width, prefix, index))
      end
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
    separate()
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

--- Returns a row's chunks without the text it hides, which is replaced by
--- what's shown instead.
---@param row nvim_threads.Row
---@return nvim_threads.Chunk[]
local concealed_chunks = function(row)
  if not row.conceals then return row.chunks end
  local result, col = {}, 0
  for _, chunk in ipairs(row.chunks) do
    local text, hl = chunk[1], chunk[2]
    local start, stop = col, col + #text
    local kept = start
    for _, conceal in ipairs(row.conceals) do
      if conceal.to > start and conceal.from < stop then
        local cut_from = math.max(conceal.from, start)
        if cut_from > kept then
          result[#result + 1] =
            { text:sub(kept - start + 1, cut_from - start), hl }
        end
        if conceal.from >= start and conceal.text ~= "" then
          result[#result + 1] = { conceal.text, hl }
        end
        kept = math.max(kept, math.min(conceal.to, stop))
      end
    end
    if kept < stop then
      result[#result + 1] = { text:sub(kept - start + 1), hl }
    end
    col = stop
  end
  return result
end

--- Returns the chunks of a row drawn as a virtual line, padded to the width
--- of the text area and followed by its right border, if any. The row's
--- hidden text is hidden, and the title and the composer are on the
--- threads' background.
---@param row nvim_threads.Row
---@param width integer
---@return nvim_threads.Chunk[]
M.virt_line = function(row, width)
  local chunks = vim.list_extend(
    vim.deepcopy(row.prefix),
    vim.deepcopy(concealed_chunks(row))
  )
  if row.placeholder then
    chunks[#chunks + 1] = { row.placeholder, "ThreadsPlaceholder" }
  end
  local right = M.right_border(row)

  local used = 0
  for _, chunk in ipairs(chunks) do
    used = used + vim.api.nvim_strwidth(chunk[1])
  end
  local room = width - (right and vim.api.nvim_strwidth(right[1]) or 0)
  if used < room then
    chunks[#chunks + 1] = { (" "):rep(room - used), row.fill }
  end
  if right then chunks[#chunks + 1] = vim.deepcopy(right) end

  if M.is_shaded(row) then
    for _, chunk in ipairs(chunks) do
      local hl = chunk[2]
      chunk[2] = vim.list_extend(
        { "ThreadsNormal" },
        type(hl) == "table" and hl or { hl }
      )
    end
  end
  return chunks
end

return M
