local vim_cmd = vim.cmd
local vim_fn = vim.fn
local vim_g = vim.g

vim_g.floaterm_autoclose = 2
vim_g.floaterm_height = 0.8
vim_g.floaterm_opener = 'edit'
vim_g.floaterm_title = ''
vim_g.floaterm_width = 0.8

LfOpener = function(path)
  local filetype =
    vim_fn.system(('file -Lb --mime-type "%s"'):format(path)):gsub('\n', '')

  local is_textfile =
    (filetype):find('text')
      or filetype == 'application/json'
      or filetype == 'inode/x-empty'

  vim_cmd(
    is_textfile
    and ('%s %s'):format(vim_g.floaterm_opener, path)
     or ('silent execute "!open %s"'):format(vim_fn.shellescape(path))
  )
end

local lf_select_current_buffer = function()
  local filename = vim.api.nvim_buf_get_name(0)
  vim_cmd(('FloatermNew --opener=LfOpener lf '):format(
    filename ~= '' and vim_fn.shellescape(filename) or ''
  ))
end

vim_cmd('command! -nargs=* LfOpener call luaeval("LfOpener(_A)", <q-args>)')

_G.map({
  modes = 'n',
  lhs = 'll',
  rhs = '<Cmd>lua require"plug-config/floaterm".lf_select_current_buffer()<CR>',
  opts = { silent = true },
})

_G.map({
  modes = 'n',
  lhs = 'lg',
  rhs = '<Cmd>FloatermNew lazygit<CR>',
  opts = { silent = true },
})

return {
  lf_select_current_buffer = lf_select_current_buffer,
}
