local format = string.format
local keymap = vim.api.nvim_set_keymap

require('cokeline').setup({
  hide_when_one_buffer = true,
})

keymap('n', '<Leader>p', '<Plug>(cokeline-switch-prev)', {silent = true})
keymap('n', '<Leader>n', '<Plug>(cokeline-switch-next)', {silent = true})

for i = 1,9 do
  keymap(
    'n',
    format('<F%s>', i),
    format('<Plug>(cokeline-focus-%s)', i),
    {silent = true}
  )
end
