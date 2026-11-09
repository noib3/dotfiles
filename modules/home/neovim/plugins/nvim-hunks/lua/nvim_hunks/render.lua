local M = {}

M.namespace = vim.api.nvim_create_namespace("nvim-hunks")

--- The priority of the extmarks highlighting added lines. It's above the
--- priorities of treesitter and of LSP semantic tokens, whose foregrounds
--- still show through since the diff highlights only set a background.
local line_priority = 150

--- The priority of the extmarks highlighting changed text in added lines.
local text_priority = 151

--- The priority of the extmarks drawing the colorcolumn over the diff.
M.column_priority = text_priority + 1

M.line_priority = line_priority
M.text_priority = text_priority

--- The opacity of the diff colors over the background of changed lines.
local line_alpha = 0.15

--- The opacity of the diff colors over the background of changed text.
local text_alpha = 0.4

--- The opacity of the diff colors over the background of the line numbers of
--- changed lines.
local number_alpha = 0.3

---@class nvim_hunks.Colors
---@field added string The color of added text, as a `#rrggbb` hex string.
---@field deleted string The color of deleted text, as a `#rrggbb` hex string.
---@field modified string The color of modified files, as a `#rrggbb` hex string.
---@field renamed string The color of renamed and copied files, as a `#rrggbb` hex string.

--- The treesitter highlight groups of a text, keyed by 1-based line. Each
--- line's `{ start_col, end_col, group }` ranges are sorted from lowest to
--- highest priority.
---@alias nvim_hunks.Syntax table<integer, [integer, integer, string][]>

---@param name string
---@param key "fg"|"bg"
---@return integer?
local color_of = function(name, key)
  return vim.api.nvim_get_hl(0, { name = name, link = false })[key]
end

---@param fg integer
---@param bg integer
---@param alpha number
---@return integer
local blend = function(fg, bg, alpha)
  local result = 0
  for _, shift in ipairs({ 65536, 256, 1 }) do
    local fg_channel = math.floor(fg / shift) % 256
    local bg_channel = math.floor(bg / shift) % 256
    local channel =
      math.floor(fg_channel * alpha + bg_channel * (1 - alpha) + 0.5)
    result = result + channel * shift
  end
  return result
end

--- Returns the hue, saturation and lightness of a color, each between 0 and 1.
---@param color integer
---@return number hue
---@return number saturation
---@return number lightness
local to_hsl = function(color)
  local r = math.floor(color / 65536) % 256 / 255
  local g = math.floor(color / 256) % 256 / 255
  local b = color % 256 / 255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local lightness = (max + min) / 2
  if max == min then return 0, 0, lightness end

  local delta = max - min
  local saturation = lightness > 0.5 and delta / (2 - max - min)
    or delta / (max + min)
  local hue
  if max == r then
    hue = (g - b) / delta + (g < b and 6 or 0)
  elseif max == g then
    hue = (b - r) / delta + 2
  else
    hue = (r - g) / delta + 4
  end
  return hue / 6, saturation, lightness
end

---@param hue number
---@param saturation number
---@param lightness number
---@return integer
local from_hsl = function(hue, saturation, lightness)
  local channel = function(offset)
    local k = (offset + hue * 12) % 12
    local a = saturation * math.min(lightness, 1 - lightness)
    local value = lightness - a * math.max(-1, math.min(k - 3, 9 - k, 1))
    return math.floor(value * 255 + 0.5)
  end
  return channel(0) * 65536 + channel(8) * 256 + channel(4)
end

--- The change in lightness and saturation from the colors of line counts to
--- the colors of file counts, which keep their hue. Lightness moves toward
--- the background.
local file_lightness = 0.05
local file_saturation = 0.15

--- Returns a color with the hue of the given one, and its lightness and
--- saturation shifted.
---@param color integer
---@param lightness number
---@param saturation number
---@return integer
local shifted = function(color, lightness, saturation)
  local h, s, l = to_hsl(color)
  local clamp = function(value) return math.max(0, math.min(1, value)) end
  return from_hsl(h, clamp(s + saturation), clamp(l + lightness))
end

--- Defines the default diff highlight groups by blending the given colors
--- into the background of `Normal`.
---@param colors nvim_hunks.Colors
M.set_highlights = function(colors)
  local background = color_of("Normal", "bg")
    or (vim.o.background == "dark" and 0x000000 or 0xffffff)
  local green = assert(tonumber(colors.added:sub(2), 16))
  local red = assert(tonumber(colors.deleted:sub(2), 16))

  local set = function(name, color, alpha)
    vim.api.nvim_set_hl(0, name, {
      bg = blend(color, background, alpha),
      default = true,
    })
  end

  set("HunksAdd", green, line_alpha)
  set("HunksAddText", green, text_alpha)
  set("HunksDelete", red, line_alpha)
  set("HunksDeleteText", red, text_alpha)
  vim.api.nvim_set_hl(0, "HunksAddNr", {
    bg = blend(green, background, number_alpha),
    default = true,
    fg = color_of("LineNr", "fg"),
  })
  vim.api.nvim_set_hl(0, "HunksAddedCount", { default = true, fg = green })
  vim.api.nvim_set_hl(0, "HunksDeletedCount", { default = true, fg = red })
  vim.api.nvim_set_hl(0, "HunksModifiedCount", {
    default = true,
    fg = tonumber(colors.modified:sub(2), 16),
  })
  vim.api.nvim_set_hl(0, "HunksRenamedCount", {
    default = true,
    fg = tonumber(colors.renamed:sub(2), 16),
  })

  -- The numbers of files take the hues of the numbers of lines.
  local lightness = vim.o.background == "dark" and -file_lightness
    or file_lightness
  for _, kind in ipairs({ "Added", "Deleted", "Modified", "Renamed" }) do
    local color = color_of(("Hunks%sCount"):format(kind), "fg")
    if color then
      vim.api.nvim_set_hl(0, ("Hunks%sFiles"):format(kind), {
        default = true,
        fg = shifted(color, lightness, file_saturation),
      })
    end
  end
  vim.api.nvim_set_hl(0, "HunksDeleteNr", {
    bg = blend(red, background, number_alpha),
    default = true,
    fg = color_of("LineNr", "fg"),
  })
end

---@class nvim_hunks.Layout
---@field win? integer The window the lines are laid out in.
---@field gutter integer The width of the columns to the left of the text.
---@field text_width integer The width of the text area.
--- The width of the text area, if lines wrap in it.
---@field wrap_width? integer
---@field showbreak string The text shown at the start of wrapped rows.
---@field showbreak_width integer
---@field eol? string The 'listchars' character shown at the end of lines.
--- The 1-based screen columns of the text area highlighted by 'colorcolumn'.
---@field columns table<integer, true>
---@field tabstop integer

--- Returns the layout of a buffer's lines in a window showing it, the given
--- one or else preferably the current one.
---@param bufnr integer
---@param win? integer
---@return nvim_hunks.Layout
M.layout = function(bufnr, win)
  ---@type nvim_hunks.Layout
  local layout = {
    gutter = 0,
    text_width = 0,
    showbreak = "",
    showbreak_width = 0,
    columns = {},
    tabstop = vim.bo[bufnr].tabstop,
  }

  if not win then
    win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_buf(win) ~= bufnr then
      win = vim.fn.win_findbuf(bufnr)[1]
    end
  end
  local info = win and vim.fn.getwininfo(win)[1]
  if not info then return layout end

  layout.win = win
  layout.gutter = info.textoff
  layout.text_width = info.width - info.textoff
  if vim.wo[win].wrap then
    layout.wrap_width = layout.text_width
    local showbreak = vim.api.nvim_get_option_value("showbreak", { win = win })
    if showbreak ~= "NONE" then
      layout.showbreak = showbreak
      layout.showbreak_width = vim.api.nvim_strwidth(showbreak)
    end
  end

  if vim.wo[win].list then
    local listchars = vim.api.nvim_get_option_value("listchars", { win = win })
    layout.eol = listchars:match("eol:([^,]+)")
  end

  local textwidth = vim.bo[bufnr].textwidth
  for _, entry in ipairs(vim.split(vim.wo[win].colorcolumn, ",")) do
    local column = tonumber(entry)
    -- Columns relative to 'textwidth' only exist when it's set.
    if column and entry:match("^[+-]") then
      column = textwidth > 0 and textwidth + column or nil
    end
    if column and column > 0 then layout.columns[column] = true end
  end

  return layout
end

--- Returns the treesitter highlights of a text, including those of its
--- injected languages.
---@param text string
---@param filetype string
---@return nvim_hunks.Syntax
M.syntax = function(text, filetype)
  ---@type nvim_hunks.Syntax
  local syntax = {}

  local lang = vim.treesitter.language.get_lang(filetype)
  if not lang then return syntax end

  local ok, parser = pcall(vim.treesitter.get_string_parser, text, lang)
  if not ok or not parser then return syntax end
  parser:parse(true)

  ---@type table<integer, { [1]: integer, [2]: integer, [3]: string, priority: integer, seq: integer }[]>
  local captures_by_line = {}
  local seq = 0

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
        and name ~= "conceal"
      then
        local priority = tonumber(
          metadata.priority or (metadata[id] and metadata[id].priority)
        ) or vim.hl.priorities.treesitter
        local group = ("@%s.%s"):format(name, tree_lang)
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
    syntax[line] = vim
      .iter(captures)
      :map(function(capture) return { capture[1], capture[2], capture[3] } end)
      :totable()
  end

  return syntax
end

--- Returns the non-overlapping `{ start_col, end_col, group }` ranges of a
--- line's syntax highlights, where a later capture takes precedence over an
--- earlier one.
---@param text string
---@param captures? [integer, integer, string][]
---@return [integer, integer, string][]
M.syntax_segments = function(text, captures)
  ---@type table<integer, string?>
  local groups = {}
  for _, capture in ipairs(captures or {}) do
    for col = capture[1] + 1, math.min(capture[2], #text) do
      groups[col] = capture[3]
    end
  end

  local segments = {}
  local col = 1
  while col <= #text do
    local group = groups[col]
    local last = col
    while last < #text and groups[last + 1] == group do
      last = last + 1
    end
    if group then segments[#segments + 1] = { col - 1, last, group } end
    col = last + 1
  end
  return segments
end

--- Replaces the tabs in a text with the spaces they'd be displayed as.
---@param text string
---@param width integer The display width of what precedes the text on its line.
---@param tabstop integer
---@return string expanded
---@return integer width The display width up to the end of the text.
local expand_tabs = function(text, width, tabstop)
  local parts = {}
  local start = 1

  while true do
    local tab = text:find("\t", start, true)
    local segment = text:sub(start, tab and tab - 1 or #text)
    parts[#parts + 1] = segment
    width = width + vim.api.nvim_strwidth(segment)
    if not tab then break end
    local spaces = tabstop - width % tabstop
    parts[#parts + 1] = (" "):rep(spaces)
    width = width + spaces
    start = tab + 1
  end

  return table.concat(parts), width
end

--- Returns the display width of a line, with its tabs expanded.
---@param text string
---@param tabstop integer
---@return integer
local line_width = function(text, tabstop)
  local _, width = expand_tabs(text, 0, tabstop)
  return width
end

--- Returns the number of screen rows a line of the given display width takes
--- up, and the display width of its last row, including the 'showbreak' of
--- wrapped rows.
---@param width integer
---@param layout nvim_hunks.Layout
---@return integer rows
---@return integer last_width
local rows_of = function(width, layout)
  local wrap_width = layout.wrap_width
  if not wrap_width or width <= wrap_width then return 1, width end
  local continued = wrap_width - layout.showbreak_width
  if continued <= 0 then return 1, width end
  local rows = 1 + math.ceil((width - wrap_width) / continued) --[[@as integer]]
  local last = width - wrap_width - (rows - 2) * continued
  return rows, layout.showbreak_width + last
end

--- Returns the virtual column displayed at a screen column of a line's row,
--- or nothing if the 'showbreak' of a wrapped row is displayed there.
---@param row integer The 1-based row.
---@param column integer The 1-based screen column of the text area.
---@param layout nvim_hunks.Layout
---@return integer?
local virtcol_at = function(row, column, layout)
  if row == 1 then return column end
  if column <= layout.showbreak_width then return end
  local wrap_width = assert(layout.wrap_width)
  local continued = wrap_width - layout.showbreak_width
  return wrap_width + (row - 2) * continued + column - layout.showbreak_width
end

--- Returns the 0-based byte range of the character displayed at a 1-based
--- virtual column of a line, if the line reaches it.
---@param text string
---@param virtcol integer
---@param tabstop integer
---@return integer? start
---@return integer? end_
local char_at = function(text, virtcol, tabstop)
  local width = 0
  for _, start in ipairs(vim.str_utf_pos(text)) do
    local end_ = start + vim.str_utf_end(text, start)
    local char = text:sub(start, end_)
    local char_width = char == "\t" and tabstop - width % tabstop
      or vim.api.nvim_strwidth(char)
    width = width + char_width
    if width >= virtcol then return start - 1, end_ end
  end
end

--- Returns the chunks of the cells between the end of a line's row and a
--- screen column, with the colorcolumn over the diff's background. The first
--- one shows the 'listchars' end of line, which they cover.
---@param from integer The 1-based screen column of the first cell.
---@param to integer The 1-based screen column of the last cell.
---@param hl_group string
---@param colored table<integer, boolean> The row's screen columns under a colorcolumn.
---@param eol? string
---@return [string, string|string[]][]
local blank_chunks = function(from, to, hl_group, colored, eol)
  ---@type [string, string|string[]][]
  local chunks = {}
  local start = from
  if eol and from <= to then
    chunks[1] = {
      eol,
      colored[from] and { "NonText", hl_group, "ColorColumn" }
        or { "NonText", hl_group },
    }
    from = from + vim.api.nvim_strwidth(eol)
    start = from
  end
  for column = from, to do
    local is_last = column == to
    local is_colored = colored[column]
    if is_colored or is_last or colored[column + 1] then
      chunks[#chunks + 1] = {
        (" "):rep(column - start + 1),
        is_colored and { hl_group, "ColorColumn" } or hl_group,
      }
      start = column + 1
    end
  end
  return chunks
end

--- Returns where a 'colorcolumn' is displayed on a line: the 1-based row, and
--- the 1-based screen column of the text area. On wrapped lines it counts the
--- cells of all rows, 'showbreak' included.
---@param column integer
---@param layout nvim_hunks.Layout
---@return integer row
---@return integer screen_column
local column_position = function(column, layout)
  local width = layout.wrap_width
  if not width then return 1, column end
  return math.floor((column - 1) / width) + 1, (column - 1) % width + 1
end

--- Returns the screen columns under a colorcolumn on a row of a line.
---@param row integer The 1-based row.
---@param layout nvim_hunks.Layout
---@return table<integer, boolean>
local colored_columns = function(row, layout)
  local columns = {}
  for column in pairs(layout.columns) do
    local column_row, screen_column = column_position(column, layout)
    if column_row == row then columns[screen_column] = true end
  end
  return columns
end

--- Returns the 0-based byte ranges of the characters of a line under its
--- colorcolumns.
---@param text string
---@param layout nvim_hunks.Layout
---@return [integer, integer][]
M.colored_chars = function(text, layout)
  local ranges = {}
  local rows = rows_of(line_width(text, layout.tabstop), layout)
  for column in pairs(layout.columns) do
    local row, screen_column = column_position(column, layout)
    local virtcol = row <= rows and virtcol_at(row, screen_column, layout)
    local start, end_ = nil, nil
    if virtcol then
      start, end_ = char_at(text, virtcol, layout.tabstop)
    end
    if start then ranges[#ranges + 1] = { start, end_ } end
  end
  return ranges
end

--- Returns the chunks of the virtual line displaying a deleted line, each
--- combining its syntax highlight with the diff's background.
---@param text string
---@param captures? [integer, integer, string][]
---@param changes nvim_hunks.Range[]
---@param layout nvim_hunks.Layout
---@return [string, string|string[]][]
local deleted_line = function(text, captures, changes, layout)
  local tabstop = layout.tabstop
  local text_width = line_width(text, tabstop)

  ---@type table<integer, string?>
  local groups = {}
  for _, segment in ipairs(M.syntax_segments(text, captures)) do
    for col = segment[1] + 1, segment[2] do
      groups[col] = segment[3]
    end
  end

  ---@type table<integer, boolean>
  local changed = {}
  for _, change in ipairs(changes) do
    for col = change.start_col + 1, change.end_col do
      changed[col] = true
    end
  end

  -- Virtual lines don't wrap, so they only have the colorcolumn of first rows.
  ---@type table<integer, boolean>
  local colored = {}
  for column in pairs(colored_columns(1, layout)) do
    local start, end_ = char_at(text, column, tabstop)
    if start then
      for col = start + 1, end_ do
        colored[col] = true
      end
    end
  end

  local chunks = {}
  local start = 1
  local line_end = 0

  for col = 1, #text do
    local next_col = col + 1
    if
      next_col > #text
      or groups[next_col] ~= groups[col]
      or changed[next_col] ~= changed[col]
      or colored[next_col] ~= colored[col]
    then
      -- The later groups take precedence.
      local hl_group = { changed[col] and "HunksDeleteText" or "HunksDelete" }
      if groups[col] then table.insert(hl_group, 1, groups[col]) end
      if colored[col] then hl_group[#hl_group + 1] = "ColorColumn" end
      local segment
      segment, line_end = expand_tabs(text:sub(start, col), line_end, tabstop)
      chunks[#chunks + 1] = { segment, hl_group }
      start = next_col
    end
  end

  -- The virtual line spans the text area like the lines' highlights do.
  if text_width < layout.text_width then
    vim.list_extend(
      chunks,
      blank_chunks(
        text_width + 1,
        layout.text_width,
        "HunksDelete",
        colored_columns(1, layout),
        layout.eol
      )
    )
  end
  return chunks
end

---@param bufnr integer
---@param row integer
---@param col integer
---@param opts vim.api.keyset.set_extmark
local set_extmark = function(bufnr, row, col, opts)
  opts.strict = false
  vim.api.nvim_buf_set_extmark(bufnr, M.namespace, row, col, opts)
end

--- Returns the 0-based row the virtual lines displaying a hunk's deleted lines
--- are attached to, and whether they go above it. They go above the first
--- line replacing them, or above the line following them, unless they were
--- deleted from the end of the text.
---@param hunk nvim_hunks.Hunk
---@param line_count integer The number of lines in the new text.
---@return integer row
---@return boolean above
M.deleted_anchor = function(hunk, line_count)
  if hunk.new_count > 0 then return hunk.new_start - 1, true end
  if hunk.new_start < line_count then return hunk.new_start, true end
  return math.max(hunk.new_start - 1, 0), hunk.new_start == 0
end

--- Draws the 'showbreak' of a wrapped line's rows over the diff's background,
--- which doesn't reach it.
---@param bufnr integer
---@param row integer The line's 0-based row.
---@param text string
---@param layout nvim_hunks.Layout
---@param hl_group string The diff's background.
local render_showbreaks = function(bufnr, row, text, layout, hl_group)
  if layout.showbreak_width == 0 then return end
  local rows = rows_of(line_width(text, layout.tabstop), layout)
  if rows == 1 then return end

  for wrapped = 2, rows do
    local colored = colored_columns(wrapped, layout)
    local chunks = {}
    local column = 1
    for _, char in ipairs(vim.fn.split(layout.showbreak, "\\zs")) do
      local is_colored = colored[column]
      chunks[#chunks + 1] = {
        char,
        is_colored and { "NonText", hl_group, "ColorColumn" }
          or { "NonText", hl_group },
      }
      column = column + vim.api.nvim_strwidth(char)
    end

    local start = char_at(
      text,
      assert(virtcol_at(wrapped, layout.showbreak_width + 1, layout)),
      layout.tabstop
    )
    if start then
      set_extmark(bufnr, row, start, {
        priority = line_priority,
        virt_text = chunks,
        virt_text_pos = "overlay",
        virt_text_win_col = 0,
      })
    end
  end
end

--- Draws consecutive lines of a buffer as added or deleted, highlighted across
--- the text area. The colorcolumn is drawn over them.
---@param bufnr integer
---@param first integer The 1-based line of the first one.
---@param lines string[]
---@param layout nvim_hunks.Layout
---@param kind "Add"|"Delete"
M.render_lines = function(bufnr, first, lines, layout, kind)
  local hl_group = "Hunks" .. kind
  for idx, text in ipairs(lines) do
    local row = first + idx - 2
    set_extmark(bufnr, row, 0, {
      end_col = #text,
      hl_group = text ~= "" and hl_group or nil,
      number_hl_group = hl_group .. "Nr",
      priority = line_priority,
    })

    local rows, last_width = rows_of(line_width(text, layout.tabstop), layout)
    if last_width < layout.text_width then
      set_extmark(bufnr, row, #text, {
        priority = line_priority,
        virt_text = blank_chunks(
          last_width + 1,
          layout.text_width,
          hl_group,
          colored_columns(rows, layout),
          layout.eol
        ),
        virt_text_pos = "overlay",
      })
    end

    render_showbreaks(bufnr, row, text, layout, hl_group)
    for _, range in ipairs(M.colored_chars(text, layout)) do
      set_extmark(bufnr, row, range[1], {
        end_col = range[2],
        hl_group = "ColorColumn",
        priority = M.column_priority,
      })
    end
  end
end

---@param bufnr integer
---@param hunk nvim_hunks.Hunk
---@param new_lines string[]
---@param layout nvim_hunks.Layout
local render_added = function(bufnr, hunk, new_lines, layout)
  local lines = vim.list_slice(
    new_lines,
    hunk.new_start,
    hunk.new_start + hunk.new_count - 1
  )
  M.render_lines(bufnr, hunk.new_start, lines, layout, "Add")

  for _, change in ipairs(hunk.new_changes) do
    set_extmark(bufnr, change.line - 1, change.start_col, {
      end_col = change.end_col,
      hl_group = "HunksAddText",
      priority = text_priority,
    })
  end
end

---@param bufnr integer
---@param hunk nvim_hunks.Hunk
---@param old_lines string[]
---@param syntax nvim_hunks.Syntax
---@param line_count integer The number of lines in the buffer.
---@param layout nvim_hunks.Layout
local render_deleted = function(
  bufnr,
  hunk,
  old_lines,
  syntax,
  line_count,
  layout
)
  if hunk.old_count == 0 then return end

  ---@type table<integer, nvim_hunks.Range[]>
  local changes_by_line = {}
  for _, change in ipairs(hunk.old_changes) do
    changes_by_line[change.line] = changes_by_line[change.line] or {}
    table.insert(changes_by_line[change.line], change)
  end

  local virt_lines = {}
  for line = hunk.old_start, hunk.old_start + hunk.old_count - 1 do
    local chunks = deleted_line(
      assert(old_lines[line]),
      syntax[line],
      changes_by_line[line] or {},
      layout
    )
    -- The virtual lines start at the window's left edge, so they draw their
    -- own gutter instead of the anchor line's.
    if layout.gutter > 0 then
      table.insert(chunks, 1, { (" "):rep(layout.gutter), "HunksDeleteNr" })
    end
    virt_lines[#virt_lines + 1] = chunks
  end

  local row, above = M.deleted_anchor(hunk, line_count)
  set_extmark(bufnr, row, 0, {
    virt_lines = virt_lines,
    virt_lines_above = above,
    virt_lines_leftcol = true,
    virt_lines_overflow = "scroll",
  })
end

--- Draws the hunks on the buffer, replacing the previously drawn ones.
---@param bufnr integer
---@param hunks nvim_hunks.Hunk[]
---@param old_lines string[]
---@param new_lines string[] The buffer's current lines.
---@param syntax nvim_hunks.Syntax The syntax of the old lines.
---@param win? integer The window the hunks are laid out for.
M.render = function(bufnr, hunks, old_lines, new_lines, syntax, win)
  M.clear(bufnr)
  local layout = M.layout(bufnr, win)
  for _, hunk in ipairs(hunks) do
    render_added(bufnr, hunk, new_lines, layout)
    render_deleted(bufnr, hunk, old_lines, syntax, #new_lines, layout)
  end
end

---@param bufnr integer
M.clear = function(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
end

return M
