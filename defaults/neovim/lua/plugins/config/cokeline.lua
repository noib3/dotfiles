local map = vim.api.nvim_set_keymap
local format = string.format

require('cokeline').setup({
  hide_when_one_buffer = true,
  -- title_format = '{devicon}{index}: {filename}{flags}',
})

map('n', '<Leader>p', '<Plug>(cokeline-focus-prev)', {silent = true})
map('n', '<Leader>n', '<Plug>(cokeline-focus-next)', {silent = true})

for i = 1,9 do
  map(
    'n',
    format('<F%s>', i),
    format('<Plug>(cokeline-focus-%s)', i),
    {silent = true}
  )
end
