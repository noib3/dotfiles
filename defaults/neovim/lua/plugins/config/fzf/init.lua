vim.g.fzf_layout = {
  window = {
    width = 1,
    height = 9,
    yoffset = 0,
    highlight = 'FzfBorder',
    border = 'bottom'
  }
}

-- For some reason the Lua equivalent of the function above doesn't work.
vim.cmd('source ~/.config/nvim/lua/plugins/config/fzf/init.vim')
