local format = string.format
local keymap = vim.api.nvim_set_keymap

require('bufferline').setup {
  options = {
    numbers = 'ordinal',
    -- number_style = '',
    -- close_icon = ' ',
    -- show_buffer_close_icons = false,
    -- separator_style = {' ', ' '},
    -- always_show_bufferline = false,
  }
}

for i = 1,9 do
  keymap(
    'n',
    format('<F%s>', i),
    format('<Cmd>lua require"bufferline".go_to_buffer(%s)<CR>', i),
    {silent=true}
  )
end
