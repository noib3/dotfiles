local b = vim.b
local fn = vim.fn
local cmd = vim.cmd
local opt = vim.opt_local
local bufmap = vim.api.nvim_buf_set_keymap

if not fn.exists('current_compiler') then
  cmd('compiler python3')
end

opt.formatoptions:remove({'r'})

b['surround_{char2nr("f")}'] = "\1function: \1(\r)"

bufmap(0, 'n', '<C-t>', '<Cmd>make!<CR>', {silent = true})
