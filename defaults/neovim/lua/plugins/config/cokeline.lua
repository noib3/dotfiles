local map = vim.api.nvim_set_keymap
local fmt = string.format

require('cokeline').setup({
  hide_when_one_buffer = true,
})

map('n', '<Leader>p', '<Plug>(cokeline-switch-prev)', {silent = true})
map('n', '<Leader>n', '<Plug>(cokeline-switch-next)', {silent = true})

for i = 1,9 do
  map('n', fmt('<F%s>', i), fmt('<Plug>(cokeline-focus-%s)', i), {silent = true})
end
