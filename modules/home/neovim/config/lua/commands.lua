local bufdelete = require("bufdelete")
local terminal = require("terminal")
local trouble = require("trouble")

vim.api.nvim_create_user_command("Qall", function()
  local base_terminal = terminal.get_base()
  if not base_terminal or vim.api.nvim_get_current_buf() == base_terminal then
    vim.cmd.qall()
    return
  end

  -- trouble's module is a metatable that forwards to `trouble.api`, which
  -- EmmyLua can't see through.
  ---@diagnostic disable-next-line: undefined-field
  while trouble.close() do
  end

  if vim.fn.win_gettype() ~= "" then
    local window = vim
      .iter(vim.api.nvim_tabpage_list_wins(0))
      :find(function(win) return vim.fn.win_gettype(win) == "" end)
    if window then vim.api.nvim_set_current_win(window) end
  end

  vim.cmd.only({ bang = true })

  local buffers = vim
    .iter(vim.fn.getbufinfo({ buflisted = 1 }))
    :map(function(info) return info.bufnr end)
    :filter(function(buffer) return buffer ~= base_terminal end)
    :totable()

  if #buffers == 0 then return end

  bufdelete.bufdelete(buffers, true, { base_terminal })
end, {
  desc = "Closes all other windows, discards all buffers and returns to the base terminal",
})

vim.cmd([[
  cnoreabbrev <expr> qa getcmdtype() ==# ':' && getcmdline() ==# 'qa' && v:char ==# "\r" ? 'Qall' : 'qa'
]])
