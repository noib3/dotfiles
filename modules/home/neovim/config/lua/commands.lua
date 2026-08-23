local bufdelete = require("bufdelete")
local terminal = require("terminal")
local trouble = require("trouble")

vim.api.nvim_create_user_command("Qall", function()
  local base_terminal = terminal.get_base()
  if not base_terminal or vim.api.nvim_get_current_buf() == base_terminal then
    vim.cmd.qall()
    return
  end

  while trouble.close() do
  end

  local buffers = vim
    .iter(vim.fn.getbufinfo({ buflisted = 1 }))
    :map(function(info) return info.bufnr end)
    :filter(function(buffer) return buffer ~= base_terminal end)
    :totable()

  if #buffers == 0 then return end

  bufdelete.bufdelete(buffers, true, { base_terminal })
end, { desc = "Discards all buffers and returns to the base terminal" })

vim.cmd([[
  cnoreabbrev <expr> qa getcmdtype() ==# ':' && getcmdline() ==# 'qa' && v:char ==# "\r" ? 'Qall' : 'qa'
]])
