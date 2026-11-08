local M = {}

M.namespace = vim.api.nvim_create_namespace("nvim-hunks")

--- The priority of the extmarks highlighting added lines. It's above the
--- priorities of treesitter and of LSP semantic tokens, whose foregrounds
--- still show through since the diff highlights only set a background.
local line_priority = 150

--- The priority of the extmarks highlighting changed text in added lines.
local text_priority = 151

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

--- Defines the default diff highlight groups by blending the given colors
--- into the background of `Normal`.
---@param colors nvim_hunks.Colors
M.set_highlights = function(colors)
  local background = color_of("Normal", "bg")
    or (vim.o.background == "dark" and 0x000000 or 0xffffff)
  local green = tonumber(colors.added:sub(2), 16)
  local red = tonumber(colors.deleted:sub(2), 16)

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
  vim.api.nvim_set_hl(0, "HunksDeleteNr", {
    bg = blend(red, background, number_alpha),
    default = true,
    fg = color_of("LineNr", "fg"),
  })
end

--- Returns the width of the columns to the left of the text in a window
--- showing the buffer, preferring the current window.
---@param bufnr integer
---@return integer
local gutter_width = function(bufnr)
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(win) ~= bufnr then
    win = vim.fn.win_findbuf(bufnr)[1]
  end
  if not win then return 0 end
  local info = vim.fn.getwininfo(win)[1]
  return info and info.textoff or 0
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
        not vim.startswith(name, "_")
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
  ---@type table<integer, string>
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

--- Returns the chunks of the virtual line displaying a deleted line, each
--- combining its syntax highlight with the diff's background.
---@param text string
---@param captures? [integer, integer, string][]
---@param changes nvim_hunks.Range[]
---@param tabstop integer
---@return [string, string|string[]][]
local deleted_line = function(text, captures, changes, tabstop)
  if text == "" then return { { " ", "HunksDelete" } } end

  ---@type table<integer, string>
  local groups = {}
  for _, segment in ipairs(M.syntax_segments(text, captures)) do
    for col = segment[1] + 1, segment[2] do
      groups[col] = segment[3]
    end
  end

  ---@type table<integer, true>
  local changed = {}
  for _, change in ipairs(changes) do
    for col = change.start_col + 1, change.end_col do
      changed[col] = true
    end
  end

  local chunks = {}
  local start = 1
  local width = 0

  for col = 1, #text do
    local next_col = col + 1
    if
      next_col > #text
      or groups[next_col] ~= groups[col]
      or changed[next_col] ~= changed[col]
    then
      local diff_group = changed[col] and "HunksDeleteText" or "HunksDelete"
      local segment
      segment, width = expand_tabs(text:sub(start, col), width, tabstop)
      chunks[#chunks + 1] =
        { segment, groups[col] and { groups[col], diff_group } or diff_group }
      start = next_col
    end
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

---@param bufnr integer
---@param hunk nvim_hunks.Hunk
---@param new_lines string[]
local render_added = function(bufnr, hunk, new_lines)
  for line = hunk.new_start, hunk.new_start + hunk.new_count - 1 do
    local text = new_lines[line]
    if text == "" then
      set_extmark(bufnr, line - 1, 0, {
        number_hl_group = "HunksAddNr",
        priority = line_priority,
        virt_text = { { " ", "HunksAdd" } },
        virt_text_pos = "overlay",
      })
    else
      set_extmark(bufnr, line - 1, 0, {
        end_col = #text,
        hl_group = "HunksAdd",
        number_hl_group = "HunksAddNr",
        priority = line_priority,
      })
    end
  end

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
---@param gutter integer The width of the gutter the virtual lines start in.
---@param line_count integer The number of lines in the buffer.
local render_deleted = function(
  bufnr,
  hunk,
  old_lines,
  syntax,
  gutter,
  line_count
)
  if hunk.old_count == 0 then return end

  ---@type table<integer, nvim_hunks.Range[]>
  local changes_by_line = {}
  for _, change in ipairs(hunk.old_changes) do
    changes_by_line[change.line] = changes_by_line[change.line] or {}
    table.insert(changes_by_line[change.line], change)
  end

  local tabstop = vim.bo[bufnr].tabstop
  local virt_lines = {}
  for line = hunk.old_start, hunk.old_start + hunk.old_count - 1 do
    local chunks = deleted_line(
      old_lines[line],
      syntax[line],
      changes_by_line[line] or {},
      tabstop
    )
    -- The virtual lines start at the window's left edge, so they draw their
    -- own gutter instead of the anchor line's.
    if gutter > 0 then
      table.insert(chunks, 1, { (" "):rep(gutter), "HunksDeleteNr" })
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
M.render = function(bufnr, hunks, old_lines, new_lines, syntax)
  M.clear(bufnr)
  local gutter = gutter_width(bufnr)
  for _, hunk in ipairs(hunks) do
    render_added(bufnr, hunk, new_lines)
    render_deleted(bufnr, hunk, old_lines, syntax, gutter, #new_lines)
  end
end

---@param bufnr integer
M.clear = function(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
end

return M
