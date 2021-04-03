local map = vim.api.nvim_set_keymap

vim.g.fzf_layout = {
  window = {
    width  = 1,
    height = 9,
    yoffset = 0,
    highlight = 'FzfBorder',
    border = 'bottom'
  }
}

map('', '<C-x><C-e>', '<Cmd>FZF --prompt=Edit>\\  ~<CR>', {silent=true})
map('i', '<C-x><C-e>', '<C-o><Cmd>FZF --prompt=Edit>\\  ~<CR>', {silent=true})

map('', '<C-x><C-r>', '<Cmd>NicerRg<CR>', {silent=true})
map('i', '<C-x><C-r>', '<C-o><Cmd>NicerRg<CR>', {silent=true})

-- If the current buffer is part of a git repository execute ripgrep from the
-- repository's root, else from the cwd.
vim.api.nvim_exec([[
command! -bang -nargs=* NicerRg call fzf#vim#grep('rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>), 1, fzf#vim#with_preview({'dir': (system('git status') =~ '^fatal' ? expand('%:p:h') : systemlist('git rev-parse --show-toplevel')[0])}), <bang>0)

" command! -bang -nargs=* NicerRg
"   \ call fzf#vim#grep(
"   \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>),
"   \   1,
"   \   fzf#vim#with_preview({'dir': (system('git status') =~ '^fatal' ? expand('%:p:h') : systemlist('git rev-parse --show-toplevel')[0])}),
"   \   <bang>0)
]], false)
