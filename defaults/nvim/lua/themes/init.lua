vim.api.nvim_exec([[
augroup themes
  autocmd!
  autocmd ColorScheme * hi Normal     guibg=NONE
  autocmd ColorScheme * hi Comment    gui=italic
  autocmd ColorScheme * hi texComment gui=italic
  autocmd ColorScheme * hi goType     gui=italic

  autocmd ColorScheme afterglow lua require"themes.afterglow".patch_colors()
  autocmd ColorScheme gruvbox   lua require"themes.gruvbox".patch_colors()
  autocmd ColorScheme onedark   lua require"themes.onedark".patch_colors()
augroup END
]], false)

vim.cmd('colorscheme ' .. vim.env.THEME)
