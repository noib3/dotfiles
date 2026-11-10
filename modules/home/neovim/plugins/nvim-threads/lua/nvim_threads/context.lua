local jj = require("nvim_threads.jj")

local M = {}

--- The words in the types of the treesitter nodes that make scopes, like
--- `function_definition` or `impl_item`.
local scope_words = {
  "class",
  "enum",
  "function",
  "impl",
  "interface",
  "method",
  "mod_item",
  "module",
  "namespace",
  "struct",
  "trait",
}

--- The words in the types of the nodes that never make scopes, like
--- `function_call`.
local non_scope_words =
  { "argument", "call", "identifier", "parameter", "type" }

--- The longest a scope's line is before it's cut off.
local scope_length = 80

---@class nvim_threads.Source
---@field root string The root of the file's jj workspace.
---@field path string The file's path relative to the root.
---@field lines string[] The file's current lines.
---@field filetype string
---@field bufnr? integer The file's buffer, if it's loaded.

---@param kind string
---@return boolean
local is_scope = function(kind)
  for _, word in ipairs(non_scope_words) do
    if kind:find(word, 1, true) then return false end
  end
  for _, word in ipairs(scope_words) do
    if kind:find(word, 1, true) then return true end
  end
  return false
end

--- Returns the first lines of the scopes enclosing an anchor, outermost
--- first, like `impl Foo` and `fn bar(&self)`.
---@param source nvim_threads.Source
---@param anchor nvim_threads.Anchor
---@return string[]
M.scopes = function(source, anchor)
  local lang = vim.treesitter.language.get_lang(source.filetype)
  if not lang then return {} end

  local ok, parser
  if source.bufnr and vim.api.nvim_buf_is_loaded(source.bufnr) then
    ok, parser = pcall(vim.treesitter.get_parser, source.bufnr, lang)
  else
    local text = table.concat(source.lines, "\n")
    ok, parser = pcall(vim.treesitter.get_string_parser, text, lang)
  end
  if not ok or not parser then return {} end

  local trees = parser:parse()
  local tree = trees and trees[1]
  if not tree then return {} end

  local node = tree:root():named_descendant_for_range(
    anchor.start_row,
    anchor.start_col,
    anchor.end_row,
    anchor.end_col
  )

  local scopes = {}
  while node do
    if is_scope(node:type()) then
      -- The whole line names a scope that's assigned, like a closure.
      local row = node:start()
      local line = source.lines[row + 1] or ""
      line = vim.trim((line:gsub("%s*{%s*$", "")))
      if #line > scope_length then line = line:sub(1, scope_length) .. "…" end
      table.insert(scopes, 1, line)
    end
    node = node:parent()
  end
  return scopes
end

--- Returns the 1-based first and last lines holding an anchor's text.
---@param anchor nvim_threads.Anchor
---@return integer first
---@return integer last
M.lines_of = function(anchor)
  local last = anchor.end_row + 1
  if anchor.end_col == 0 and anchor.end_row > anchor.start_row then
    last = last - 1
  end
  return anchor.start_row + 1, last
end

--- Returns the text of an anchor in a file's lines.
---@param lines string[]
---@param anchor nvim_threads.Anchor
---@return string
M.text_of = function(lines, anchor)
  local selected =
    vim.list_slice(lines, anchor.start_row + 1, anchor.end_row + 1)
  local last = selected[#selected]
  if not last then return "" end
  selected[#selected] = last:sub(1, anchor.end_col)
  selected[1] = assert(selected[1]):sub(anchor.start_col + 1)
  return table.concat(selected, "\n")
end

--- Returns the hunks of a git-style diff whose new lines overlap the given
--- 1-based lines, each with its `@@` header.
---@param diff string
---@param first integer
---@param last integer
---@return string[]
M.overlapping_hunks = function(diff, first, last)
  local hunks = {}
  ---@type { start: integer, count: integer, lines: string[] }?
  local current

  local finish = function()
    if not current then return end
    -- A hunk without new lines is at the line it follows.
    local hunk_first = current.start
    local hunk_last = current.count > 0 and current.start + current.count - 1
      or current.start
    if hunk_first <= last and hunk_last >= first then
      hunks[#hunks + 1] = table.concat(current.lines, "\n")
    end
    current = nil
  end

  for line in vim.gsplit(diff, "\n", { plain = true }) do
    local start, count = line:match("^@@ %-%d+,?%d* %+(%d+),?(%d*) @@")
    if start then
      finish()
      current = {
        start = tonumber(start) --[[@as integer]],
        count = count == "" and 1 or tonumber(count) --[[@as integer]],
        lines = { line },
      }
    elseif line:match("^diff ") then
      finish()
    elseif current and line:match("^[ +%-\\]") then
      table.insert(current.lines, line)
    end
  end
  finish()
  return hunks
end

---@param text string
---@return string
local fence_for = function(text)
  local longest = 2
  for ticks in text:gmatch("`+") do
    longest = math.max(longest, #ticks)
  end
  return ("`"):rep(longest + 1)
end

--- Calls back with the context of a thread for an agent: its selection,
--- the scopes around it, and the changes of the working-copy commit it
--- overlaps.
---@param source nvim_threads.Source
---@param anchor nvim_threads.Anchor
---@param on_done fun(context: string)
M.build = function(source, anchor, on_done)
  local first, last = M.lines_of(anchor)
  local text = M.text_of(source.lines, anchor)
  local abs_path = vim.fs.joinpath(source.root, source.path)
  local lang = vim.treesitter.language.get_lang(source.filetype)
    or source.filetype

  local fence = fence_for(text)
  local location = first == last and ("%s:%d"):format(abs_path, first)
    or ("%s:%d-%d"):format(abs_path, first, last)
  local parts = {
    "<context>",
    "The following items were attached by the user. They are up-to-date and don't need to be re-read.",
    "",
    "<selections>",
    ("%s%s %s"):format(fence, lang, location),
    text,
    fence,
    "</selections>",
  }

  local is_charwise = anchor.start_col > 0
    or anchor.end_col < #(source.lines[last] or "")
  if is_charwise then
    parts[#parts + 1] = ("The selection starts at column %d of line %d and ends at column %d of line %d."):format(
      anchor.start_col + 1,
      first,
      anchor.end_col,
      last
    )
  end

  local scopes = M.scopes(source, anchor)
  if #scopes > 0 then
    parts[#parts + 1] = ("The selection is in %s."):format(
      table.concat(
        vim.tbl_map(function(scope) return ("`%s`"):format(scope) end, scopes),
        " › "
      )
    )
  end

  jj.diff(source.root, source.path, function(err, diff)
    vim.schedule(function()
      local hunks = not err and diff and M.overlapping_hunks(diff, first, last)
        or {}
      if #hunks > 0 then
        local joined = table.concat(hunks, "\n")
        local diff_fence = fence_for(joined)
        vim.list_extend(parts, {
          "",
          "<hunks>",
          "The selection overlaps these changes of the working-copy commit:",
          diff_fence .. "diff",
          joined,
          diff_fence,
          "</hunks>",
        })
      end
      parts[#parts + 1] = "</context>"
      on_done(table.concat(parts, "\n"))
    end)
  end)
end

--- Returns the prompt of a thread's latest comment for an agent: the
--- thread's context, its earlier comments, then the latest one.
---@param context string
---@param thread nvim_threads.Thread
---@return string
M.prompt = function(context, thread)
  local parts = { context }
  local earlier = vim.list_slice(thread.comments, 1, #thread.comments - 1)
  if #earlier > 0 then
    parts[#parts + 1] = ""
    parts[#parts + 1] = "<thread>"
    for _, comment in ipairs(earlier) do
      parts[#parts + 1] = ("%s: %s"):format(comment.author, comment.body)
    end
    parts[#parts + 1] = "</thread>"
  end
  parts[#parts + 1] = ""
  parts[#parts + 1] = thread.comments[#thread.comments].body
  return table.concat(parts, "\n")
end

return M
