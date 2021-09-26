local fn = vim.fn
local cmd = vim.cmd
local bufmap = vim.api.nvim_buf_set_keymap

if not fn.exists('current_compiler') then
  cmd('compiler cargo')
end

bufmap(0, 'n', '<C-t>', '<Cmd>make!<Bar>silent cc<CR>', {silent = true})
