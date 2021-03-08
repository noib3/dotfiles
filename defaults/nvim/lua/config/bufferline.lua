local map = vim.api.nvim_set_keymap

require('bufferline').setup{
  options = {
    numbers = 'ordinal',
    number_style = '',
    close_icon = ' ',
    show_buffer_close_icons = false,
    separator_style = {' ', ' '},
    always_show_bufferline = false,
  }
}

for i = 1,9 do
  map('n', '<F'..i..'>', ':lua require"bufferline".go_to_buffer('..i..')<CR>',
      { silent = true })
end
