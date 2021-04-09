vim.g.fzf_layout = {
  window = {
    width = 1,
    height = 9,
    yoffset = 0,
    highlight = 'FzfBorder',
    border = 'bottom'
  }
}

-- For some reason the Lua equivalents of the functions defined in the
-- following init.vim don't work (I get errors about funcrefs).
vim.cmd('source ~/.config/nvim/lua/plugins/config/fzf/init.vim')
