local M = {}

local initial_buf = vim.api.nvim_get_current_buf()
local base_buf

---Records the terminal created from Neovim's initial buffer as the session's
---base terminal.
---@param buf number
M.register_base = function(buf)
  if base_buf or buf ~= initial_buf then return end
  if not vim.api.nvim_buf_is_valid(buf) then return end
  if vim.bo[buf].buftype ~= "terminal" then return end
  base_buf = buf
end

---Returns the session's base terminal if it still exists.
---@return number?
M.get_base = function()
  if
    type(base_buf) ~= "number"
    or not vim.api.nvim_buf_is_valid(base_buf)
    or vim.bo[base_buf].buftype ~= "terminal"
  then
    return nil
  end

  return base_buf
end

local term = vim.env.TERM

if not term or term == "" then return M end

local ex_cmd = require("vim._core.ex_cmd")
local ex_terminal = ex_cmd.ex_terminal

---Forward the outer TUI's terminal identity to jobs spawned by `:terminal`.
---@diagnostic disable-next-line: duplicate-set-field
ex_cmd.ex_terminal = function(...)
  local orig_jobstart = vim.fn.jobstart

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.fn.jobstart = function(cmd, opts)
    if type(opts) == "table" and opts.term then
      opts = vim.tbl_extend("force", opts, {
        env = vim.tbl_extend("force", opts.env or {}, { TERM = term }),
      })
    end
    return orig_jobstart(cmd, opts)
  end

  local ok, err = pcall(ex_terminal, ...)
  vim.fn.jobstart = orig_jobstart
  if not ok then error(err, 0) end
end

return M
