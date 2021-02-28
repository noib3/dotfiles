local g   = vim.g
local map = vim.api.nvim_set_keymap
local fn  = vim.fn
local cmd = vim.cmd

g.floaterm_title     = ''
g.floaterm_width     = 0.8
g.floaterm_height    = 0.8
g.floaterm_autoclose = 2

map('n', 'll', ':lua open_lf_select_current_file()<CR>', { silent = true })
map('n', 'lg', ':FloatermNew lazygit<CR>',               { silent = true })

-- https://github.com/voldikss/vim-floaterm/issues/209#issuecomment-734656183

-- function! s:select(filename, ...) abort
--   silent execute printf('!lf -remote "send select %s"', a:filename)
-- endfunction

function open_lf_select_current_file()
  -- local filename = fn(expand('%'))
  -- cmd('!echo ' .. filename .. ' >> /Users/noibe/ciaones')
  cmd('FloatermNew lf')
end

-- function! s:open_lf_select_current_file()
--   let filename = expand('%')
--   execute 'FloatermNew lf'
--   if filename != ''
--     call timer_start(100, function('s:select', [filename]), {'repeat': 3})
--   endif
-- endfunction
