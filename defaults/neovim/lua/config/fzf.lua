local g = vim.g
local map = vim.api.nvim_set_keymap

g.fzf_layout = {
  window = {
    width  = 1,
    height = 9,
    yoffset = 0,
    highlight = 'FzfBorder',
    border = 'bottom'
  }
}

map('', '<C-x><C-e>', ':FZF --prompt=Edit>\\  ~<CR>', {silent=true})
map('i', '<C-x><C-e>', '<C-o>:FZF --prompt=Edit>\\  ~<CR>', {silent=true})
