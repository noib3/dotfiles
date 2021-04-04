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

-- If the current buffer is part of a git repository execute ripgrep from the
-- repository's root, else from the cwd.
vim.api.nvim_exec([[
function! Nicer_Rg(query, fullscreen)
  let command_fmt = 'rg -nS --no-heading --color=always -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {}
  let spec['options'] = ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]
  let spec['dir'] = system('git status') =~ '^fatal' ? expand('%:p:h') : systemlist('git rev-parse --show-toplevel')[0]
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction
]], false)

vim.cmd('command! -nargs=* -bang NicerRg call Nicer_Rg(<q-args>, <bang>0)')

map('', '<C-x><C-e>',
    '<Cmd>FZF --prompt=Edit>\\  --preview=bat\\ {} ~<CR>', {silent=true})
map('i', '<C-x><C-e>',
    '<C-o><Cmd>FZF --prompt=Edit>\\  --preview=bat\\ {} ~<CR>', {silent=true})

map('', '<C-x><C-r>', '<Cmd>NicerRg<CR>', {silent=true})
map('i', '<C-x><C-r>', '<C-o><Cmd>NicerRg<CR>', {silent=true})
