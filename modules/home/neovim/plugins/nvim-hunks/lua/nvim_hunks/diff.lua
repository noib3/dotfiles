local ffi = require("ffi")

local M = {}

--- The longest a diff can take before the library falls back to a coarser
--- one.
local max_computation_time_ms = 1000

ffi.cdef([[
  typedef struct {
    int start_line;
    int end_line;
  } LineRange;

  typedef struct {
    int start_line;
    int start_col;
    int end_line;
    int end_col;
  } CharRange;

  typedef struct {
    CharRange original;
    CharRange modified;
  } RangeMapping;

  typedef struct {
    LineRange original;
    LineRange modified;
    RangeMapping* inner_changes;
    int inner_change_count;
  } DetailedLineRangeMapping;

  typedef struct {
    DetailedLineRangeMapping* mappings;
    int count;
    int capacity;
  } DetailedLineRangeMappingArray;

  typedef struct {
    LineRange original;
    LineRange modified;
  } MovedText;

  typedef struct {
    MovedText* moves;
    int count;
    int capacity;
  } MovedTextArray;

  typedef struct {
    DetailedLineRangeMappingArray changes;
    MovedTextArray moves;
    bool hit_timeout;
  } LinesDiff;

  typedef struct {
    bool ignore_trim_whitespace;
    int max_computation_time_ms;
    bool compute_moves;
    bool extend_to_subwords;
  } DiffOptions;

  LinesDiff* compute_diff(
    const char** original_lines,
    int original_count,
    const char** modified_lines,
    int modified_count,
    const DiffOptions* options
  );

  void free_lines_diff(LinesDiff* diff);
]])

---@class nvim_hunks.Range
---@field line integer The 1-based line the range is on.
---@field start_col integer The 0-based byte column the range starts at.
---@field end_col integer The 0-based byte column the range ends before.

---@class nvim_hunks.Hunk
--- The 1-based first line of the hunk in the old text. When `old_count` is 0,
--- it's the line after which the new lines were added, or 0 if they were
--- added at the start.
---@field old_start integer
---@field old_count integer
--- The 1-based first line of the hunk in the new text. When `new_count` is 0,
--- it's the line after which the old lines were deleted, or 0 if they were
--- deleted from the start.
---@field new_start integer
---@field new_count integer
---@field old_changes nvim_hunks.Range[] The changed text in the old lines.
---@field new_changes nvim_hunks.Range[] The changed text in the new lines.

---@type ffi.namespace*?
local lib

---@param path string The path of libvscode-diff's shared library.
M.load = function(path) lib = ffi.load(path) end

---@return boolean
M.is_loaded = function() return lib ~= nil end

---@param lines string[]
---@return ffi.cdata*
local c_lines = function(lines)
  local array = ffi.new("const char*[?]", math.max(#lines, 1))
  for idx, line in ipairs(lines) do
    array[idx - 1] = line
  end
  return array
end

--- Converts a 1-based UTF-16 column into a 0-based byte column.
---@param text string
---@param col integer
---@return integer
local byte_col = function(text, col)
  return vim.str_byteindex(text, "utf-16", col - 1, false)
end

--- Splits a range spanning one or more lines into per-line byte ranges, and
--- appends the non-empty ones.
---@param ranges nvim_hunks.Range[]
---@param lines string[]
---@param range ffi.cdata*
local add_range = function(ranges, lines, range)
  for line = range.start_line, range.end_line do
    local text = lines[line]
    if text then
      local start_col = line == range.start_line
          and byte_col(text, range.start_col)
        or 0
      local end_col = line == range.end_line and byte_col(text, range.end_col)
        or #text
      if end_col > start_col then
        ranges[#ranges + 1] =
          { line = line, start_col = start_col, end_col = end_col }
      end
    end
  end
end

--- Returns the ranges that don't cover the whole non-whitespace text of their
--- line. A wholly changed line is already marked by its own highlight.
---@param ranges nvim_hunks.Range[]
---@param lines string[]
---@return nvim_hunks.Range[]
local drop_whole_lines = function(ranges, lines)
  ---@type table<integer, integer>
  local covered = {}
  for _, range in ipairs(ranges) do
    local text = lines[range.line]:sub(range.start_col + 1, range.end_col)
    covered[range.line] = (covered[range.line] or 0) + #text:gsub("%s", "")
  end

  return vim.tbl_filter(
    function(range)
      return covered[range.line] < #lines[range.line]:gsub("%s", "")
    end,
    ranges
  )
end

--- Returns the hunks turning the old lines into the new ones.
---@param old_lines string[]
---@param new_lines string[]
---@return nvim_hunks.Hunk[]
M.compute = function(old_lines, new_lines)
  local opts = ffi.new("DiffOptions", {
    ignore_trim_whitespace = false,
    max_computation_time_ms = max_computation_time_ms,
    compute_moves = false,
    extend_to_subwords = false,
  })

  local result = assert(lib).compute_diff(
    c_lines(old_lines),
    #old_lines,
    c_lines(new_lines),
    #new_lines,
    opts
  )
  if result == nil then error("libvscode-diff failed to compute the diff") end

  ---@type nvim_hunks.Hunk[]
  local hunks = {}
  for idx = 0, result.changes.count - 1 do
    local mapping = result.changes.mappings[idx]
    local old_count = mapping.original.end_line - mapping.original.start_line
    local new_count = mapping.modified.end_line - mapping.modified.start_line

    ---@type nvim_hunks.Hunk
    local hunk = {
      old_start = mapping.original.start_line - (old_count == 0 and 1 or 0),
      old_count = old_count,
      new_start = mapping.modified.start_line - (new_count == 0 and 1 or 0),
      new_count = new_count,
      old_changes = {},
      new_changes = {},
    }

    if old_count > 0 and new_count > 0 then
      for inner = 0, mapping.inner_change_count - 1 do
        local change = mapping.inner_changes[inner]
        add_range(hunk.old_changes, old_lines, change.original)
        add_range(hunk.new_changes, new_lines, change.modified)
      end
      hunk.old_changes = drop_whole_lines(hunk.old_changes, old_lines)
      hunk.new_changes = drop_whole_lines(hunk.new_changes, new_lines)
    end

    hunks[#hunks + 1] = hunk
  end

  lib.free_lines_diff(result)
  return hunks
end

return M
