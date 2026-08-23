local trouble = require("trouble")

local M = {}

---@class locations.Location
---@field argument_filename string
---@field filename string
---@field lnum? integer
---@field col? integer

--- Parses the `path:line:column` convention used by ripgrep and other tools.
--- An existing literal filename takes precedence over interpreting its suffix.
---@param argument string
---@return locations.Location
local parse_cli_file = function(argument)
  local literal_filename = vim.fs.abspath(argument)
  if vim.uv.fs_stat(literal_filename) then
    return {
      argument_filename = literal_filename,
      filename = literal_filename,
    }
  end

  local path, line, col = argument:match("^(.*):(%d+):(%d+)$")
  local filename = path and vim.fs.abspath(path) or nil

  if not filename or not vim.uv.fs_stat(filename) then
    return {
      argument_filename = literal_filename,
      filename = literal_filename,
    }
  end

  return {
    argument_filename = literal_filename,
    filename = filename,
    lnum = tonumber(line),
    col = tonumber(col),
  }
end

--- Replaces location references in the startup argument list with their
--- resolved filenames and removes the placeholder buffers Neovim created for
--- those references.
---@param locations locations.Location[]
local resolve_arglist = function(locations)
  local has_references = vim.iter(locations):any(
    function(location) return location.argument_filename ~= location.filename end
  )
  if not has_references then return end

  local filenames = vim.tbl_map(
    function(location) return location.filename end,
    locations
  )
  vim.cmd.args({ args = filenames })

  for _, location in ipairs(locations) do
    if location.argument_filename ~= location.filename then
      local bufnr = vim.fn.bufnr(location.argument_filename)
      if
        bufnr >= 0
        and vim.api.nvim_buf_is_valid(bufnr)
        and not vim.bo[bufnr].modified
      then
        vim.api.nvim_buf_delete(bufnr, {})
      end
    end
  end
end

--- Resolves CLI arguments to the literal filepaths Neovim should load.
---@param paths string[]
---@return string[]
M.resolve_cli_filepaths = function(paths)
  return vim
    .iter(paths)
    :map(function(path) return parse_cli_file(path).filename end)
    :totable()
end

--- Opens trouble.nvim with the given entries in quickfix format
--- (`:h setqflist`).
---@param qf_entries table[]
M.open_trouble_qf = function(qf_entries)
  if #qf_entries == 0 then return end

  qf_entries = vim.tbl_map(function(entry)
    if (not entry.lnum or entry.lnum == 0) and not entry.pattern then
      return vim.tbl_extend("keep", entry, { lnum = 1, col = 1 })
    end
    return entry
  end, qf_entries)

  local win = vim.api.nvim_get_current_win()
  vim.fn.setqflist(qf_entries, "r")
  trouble.open({
    mode = "quickfix",
    new = false,
    refresh = true,
  })
  vim.api.nvim_set_current_win(win)
end

--- Opens the first CLI file at its requested location and, when multiple
--- locations were provided, adds all of them to Trouble. `path:line:column`
--- locations use 1-based byte columns.
---@param paths string[]
---@param resolve_startup_arglist? boolean
M.open_cli_files = function(paths, resolve_startup_arglist)
  if #paths == 0 then return end

  local locations = vim.tbl_map(parse_cli_file, paths)
  if resolve_startup_arglist then resolve_arglist(locations) end
  local first = locations[1]

  if first.lnum and first.col then
    if vim.api.nvim_buf_get_name(0) ~= first.filename then
      vim.cmd.edit({ args = { first.filename } })
    end

    local line = math.min(first.lnum, vim.api.nvim_buf_line_count(0))
    local contents = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1]
      or ""
    local col = math.min(first.col - 1, #contents)
    vim.api.nvim_win_set_cursor(0, { line, col })
  end

  if #locations > 1 then M.open_trouble_qf(locations) end
end

return M
