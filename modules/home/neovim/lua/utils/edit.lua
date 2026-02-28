local M = {}

--- Opens the given file in the current window. If the current buffer is a
--- terminal, sets up a one-shot autocmd to re-enter insert mode when the
--- terminal buffer is re-focused (e.g. after closing the opened file).
---
---@param filepath string
M.open = function(filepath)
  local buf = vim.api.nvim_get_current_buf()
  local was_terminal = vim.bo[buf].buftype == "terminal"

  vim.cmd.edit(filepath)

  if was_terminal then
    vim.api.nvim_create_autocmd("BufEnter", {
      buffer = buf,
      once = true,
      callback = function() vim.cmd.startinsert() end,
    })
  end
end

return M
