--- Draws diffs as rows of chunks, which other plugins show as the lines of
--- a buffer or as virtual lines.
local diff = require("nvim_hunks.diff")
local render = require("nvim_hunks.render")

local M = {}

--- The number of unchanged lines around the changes of the hunks `hunks()`
--- returns.
local context = 3

---@alias nvim_hunks.Chunk [string, (string|string[])?]

---@class nvim_hunks.view.Line
---@field kind " "|"+"|"-"
---@field old? integer The line's 1-based number in the old lines.
---@field new? integer The line's 1-based number in the new lines.
---@field text string

--- A screen row of a diff.
---@class nvim_hunks.view.Row
---@field kind " "|"+"|"-"|"gap" The kind of the row's line, or `gap` for the row counting the unchanged lines before a hunk.
---@field hunk integer The index of the row's hunk.
---@field first boolean Whether the row is the first one of its hunk's lines.
---@field gutter nvim_hunks.Chunk[] The line's numbers and sign, which are blank on the rows its text wraps into.
---@field chunks nvim_hunks.Chunk[] The row's text, over the line's background, with its syntax and changed text highlighted.
---@field fill? string The group of the row's background past its text.

---@class nvim_hunks.view.Opts
---@field path string The diffed file's path, whose type sets the highlights' language.
---@field old_lines? string[] All the old lines, whose highlights are those of the whole text. Without them, a hunk's lines are highlighted on their own.
---@field new_lines? string[] All the new lines.
---@field width? integer The width the text wraps within. Without it, it doesn't wrap.

---@class nvim_hunks.view.LineHunk
---@field old_start integer
---@field old_count integer
---@field new_start integer
---@field new_count integer

--- Returns the hunks turning old lines into new ones, as their line numbers
--- and counts. A side without lines starts after the line it names.
---@param old string[]
---@param new string[]
---@return nvim_hunks.view.LineHunk[]
local line_hunks = function(old, new)
  if diff.is_loaded() then
    return diff.compute(old, new) --[[@as nvim_hunks.view.LineHunk[] ]]
  end
  if #old == 0 and #new == 0 then return {} end
  ---@diagnostic disable-next-line: deprecated
  local text_diff = vim.text.diff or vim.diff
  local indices = text_diff(
    table.concat(old, "\n") .. "\n",
    table.concat(new, "\n") .. "\n",
    { result_type = "indices", algorithm = "histogram" }
  ) --[[@as integer[][] ]]
  return vim.tbl_map(
    function(hunk)
      return {
        old_start = hunk[1],
        old_count = hunk[2],
        new_start = hunk[3],
        new_count = hunk[4],
      }
    end,
    indices
  ) --[[@as nvim_hunks.view.LineHunk[] ]]
end

--- Returns the hunks turning old lines into new ones, as their lines with
--- up to `context` unchanged lines around their changes.
---@param old_lines string[]
---@param new_lines string[]
---@return nvim_hunks.view.Line[][]
M.hunks = function(old_lines, new_lines)
  ---@type nvim_hunks.view.Line[]
  local lines = {}
  local old, new = 1, 1
  ---@param kind " "|"+"|"-"
  local add = function(kind)
    lines[#lines + 1] = {
      kind = kind,
      old = kind ~= "+" and old or nil,
      new = kind ~= "-" and new or nil,
      text = (kind == "+" and new_lines[new] or old_lines[old]) or "",
    }
    if kind ~= "+" then old = old + 1 end
    if kind ~= "-" then new = new + 1 end
  end
  for _, hunk in ipairs(line_hunks(old_lines, new_lines)) do
    local first = hunk.old_count > 0 and hunk.old_start or hunk.old_start + 1
    while old < first do
      add(" ")
    end
    for _ = 1, hunk.old_count do
      add("-")
    end
    for _ = 1, hunk.new_count do
      add("+")
    end
  end
  while old <= #old_lines do
    add(" ")
  end

  local near = {}
  for index, line in ipairs(lines) do
    if line.kind ~= " " then
      for other = math.max(index - context, 1), math.min(index + context, #lines) do
        near[other] = true
      end
    end
  end
  local hunks, hunk = {}, nil
  for index, line in ipairs(lines) do
    if near[index] then
      if not hunk then
        hunk = {}
        hunks[#hunks + 1] = hunk
      end
      hunk[#hunk + 1] = line
    else
      hunk = nil
    end
  end
  return hunks
end

--- Returns the treesitter highlights of the lines of hunks by line: those
--- of the old and new lines if they're given, or else those of the hunks'
--- lines parsed on their own, the old ones apart from the others.
---@param hunks nvim_hunks.view.Line[][]
---@param opts nvim_hunks.view.Opts
---@return table<nvim_hunks.view.Line, [integer, integer, string][]>
local syntax_of = function(hunks, opts)
  local syntax = {}
  local filetype = vim.filetype.match({ filename = opts.path })
  if not filetype then return syntax end

  if opts.old_lines and opts.new_lines then
    local old = render.syntax(table.concat(opts.old_lines, "\n"), filetype)
    local new = render.syntax(table.concat(opts.new_lines, "\n"), filetype)
    for _, hunk in ipairs(hunks) do
      for _, line in ipairs(hunk) do
        syntax[line] = line.new and new[line.new] or line.old and old[line.old]
      end
    end
    return syntax
  end

  -- The unchanged lines take the new lines' highlights.
  ---@type (" "|"+"|"-")[]
  local sides = { "-", "+" }
  for _, side in ipairs(sides) do
    ---@type nvim_hunks.view.Line[]
    local lines = {}
    for _, hunk in ipairs(hunks) do
      for _, line in ipairs(hunk) do
        if line.kind == " " or line.kind == side then
          lines[#lines + 1] = line
        end
      end
    end
    local text = table.concat(
      vim.tbl_map(function(line) return line.text end, lines),
      "\n"
    )
    for index, captures in pairs(render.syntax(text, filetype)) do
      local line = lines[index]
      if line and (line.kind == side or side == "+") then
        syntax[line] = captures
      end
    end
  end
  return syntax
end

--- Returns the 0-based byte ranges of the text that changed in the lines of
--- a hunk, by line, or none if the diff's library isn't loaded.
---@param hunk nvim_hunks.view.Line[]
---@return table<nvim_hunks.view.Line, [integer, integer][]>
local changes_of = function(hunk)
  local changes = {}
  if not diff.is_loaded() then return changes end
  local old, new = {}, {}
  for _, line in ipairs(hunk) do
    if line.kind ~= "+" then old[#old + 1] = line end
    if line.kind ~= "-" then new[#new + 1] = line end
  end
  local text = function(line) return line.text end
  for _, changed in
    ipairs(diff.compute(vim.tbl_map(text, old), vim.tbl_map(text, new)))
  do
    for side, ranges in pairs({
      [old] = changed.old_changes,
      [new] = changed.new_changes,
    }) do
      for _, range in ipairs(ranges) do
        local line = side[range.line]
        if line and line.kind ~= " " then
          changes[line] = changes[line] or {}
          table.insert(changes[line], { range.start_col, range.end_col })
        end
      end
    end
  end
  return changes
end

--- Returns the 0-based byte ranges of the rows a line wraps into within a
--- width, breaking after spaces where possible.
---@param text string
---@param width? integer
---@return [integer, integer][]
local wrap = function(text, width)
  if not width or text == "" then return { { 0, #text } } end
  width = math.max(width, 1)
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

--- Returns the chunks of the bytes of a line between two 0-based columns,
--- the end being exclusive, over the line's background.
---@param text string
---@param from integer
---@param to integer
---@param captures? [integer, integer, string][]
---@param changes? [integer, integer][]
---@param line_hl? string
---@param changed_hl? string
---@return nvim_hunks.Chunk[]
local text_chunks = function(
  text,
  from,
  to,
  captures,
  changes,
  line_hl,
  changed_hl
)
  ---@type table<integer, string?>
  local groups = {}
  for _, segment in ipairs(render.syntax_segments(text, captures)) do
    for col = segment[1] + 1, segment[2] do
      groups[col] = segment[3]
    end
  end
  ---@type table<integer, true?>
  local changed = {}
  for _, range in ipairs(changes or {}) do
    for col = range[1] + 1, math.min(range[2], #text) do
      changed[col] = true
    end
  end

  local chunks = {}
  local col = from + 1
  while col <= to do
    local group, is_changed = groups[col], changed[col]
    local last = col
    while
      last < to
      and groups[last + 1] == group
      and changed[last + 1] == is_changed
    do
      last = last + 1
    end
    local hl = {}
    if line_hl then hl[#hl + 1] = line_hl end
    if group then hl[#hl + 1] = group end
    if is_changed and changed_hl then hl[#hl + 1] = changed_hl end
    chunks[#chunks + 1] = { text:sub(col, last), #hl > 0 and hl or nil }
    col = last + 1
  end
  return chunks
end

--- Returns the rows of hunks: their lines, with the lines' numbers and signs
--- in a gutter, and a row counting the unchanged lines before each hunk that
--- doesn't start the file.
---@param hunks nvim_hunks.view.Line[][]
---@param opts nvim_hunks.view.Opts
---@return nvim_hunks.view.Row[]
M.rows = function(hunks, opts)
  local syntax = syntax_of(hunks, opts)
  local digits = 1
  for _, hunk in ipairs(hunks) do
    for _, line in ipairs(hunk) do
      digits =
        math.max(digits, #tostring(line.old or ""), #tostring(line.new or ""))
    end
  end
  local blank = (" "):rep(digits)
  local numbers_width = 2 * digits + 3
  local text_width = opts.width and math.max(opts.width - numbers_width - 3, 1)

  ---@type nvim_hunks.view.Row[]
  local rows = {}
  ---@type integer
  local previous_old = 0
  for hunk_index, hunk in ipairs(hunks) do
    ---@type nvim_hunks.view.Line?
    local first_old = vim
      .iter(hunk)
      :find(function(line) return line.old ~= nil end)
    local first_number = first_old and first_old.old
    local hidden = first_number and first_number - previous_old - 1 or 0
    if hidden > 0 then
      rows[#rows + 1] = {
        kind = "gap",
        hunk = hunk_index,
        first = false,
        gutter = { { (" "):rep(numbers_width), "HunksGapNr" } },
        chunks = {
          {
            (" %d unchanged line%s"):format(hidden, hidden == 1 and "" or "s"),
            "HunksGap",
          },
        },
        fill = "HunksGap",
      }
    end
    for _, line in ipairs(hunk) do
      if line.old then previous_old = line.old end
    end

    local changes = changes_of(hunk)
    for line_index, line in ipairs(hunk) do
      local line_hl = line.kind == "+" and "HunksAdd"
        or line.kind == "-" and "HunksDelete"
        or nil
      local changed_hl = line.kind == "+" and "HunksAddText"
        or line.kind == "-" and "HunksDeleteText"
        or nil
      local number_hl = line.kind == "+" and "HunksAddNr"
        or line.kind == "-" and "HunksDeleteNr"
        or "HunksContextNr"
      local numbers = (" %s %s "):format(
        line.old and ("%" .. digits .. "d"):format(line.old) or blank,
        line.new and ("%" .. digits .. "d"):format(line.new) or blank
      )
      for range_index, range in ipairs(wrap(line.text, text_width)) do
        local first_row = range_index == 1
        rows[#rows + 1] = {
          kind = line.kind,
          hunk = hunk_index,
          first = first_row and line_index == 1,
          gutter = {
            { first_row and numbers or (" "):rep(numbers_width), number_hl },
            { first_row and (" %s "):format(line.kind) or "   ", line_hl },
          },
          chunks = text_chunks(
            line.text,
            range[1],
            range[2],
            syntax[line],
            changes[line],
            line_hl,
            changed_hl
          ),
          fill = line_hl,
        }
      end
    end
  end
  return rows
end

return M
