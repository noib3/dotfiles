local format = string.format

local keymap = vim.api.nvim_set_keymap
local g = vim.g

g.floaterm_title = ''
g.floaterm_width = 0.8
g.floaterm_height = 0.8
g.floaterm_opener = 'edit'
g.floaterm_autoclose = 2

-- https://github.com/voldikss/vim-floaterm/issues/259
vim.cmd([[
function! LfOpener(path)
  let filedir = expand('%:p:h')
  let tailingPart = substitute(a:path, filedir, '', '')
  if tailingPart != a:path
    exec 'normal i.' . tailingPart
  else
    let pathItems = split(a:path, '/')
    let filedirItems = split(filedir, '/')
    while len(pathItems) && pathItems[0] == filedirItems[0]
      call remove(pathItems, 0)
      call remove(filedirItems, 0)
    endwhile
    exec 'normal i' . join(map(copy(filedirItems), string('..')) + pathItems, '/')
  endif
endfunction

command! -nargs=1 LfOpener call LfOpener(<q-args>)]])

function open_lf_select_current()
  local filename = vim.api.nvim_buf_get_name(0)
  -- print(filename)
  local cmd = 'FloatermNew lf'
  -- local cmd = 'FloatermNew --opener=LfOpener lf'
  if filename ~= '' then
    -- filename = filename:gsub('%%', '\\%%')
    -- filename = filename:gsub('#', '\\#')
    cmd = format([[%s -command 'select "%s"']], cmd, filename)
  end
  vim.cmd(cmd)
end

keymap('n', 'll', '<Cmd>lua open_lf_select_current()<CR>', {silent = true})
keymap('n', 'lg', '<Cmd>FloatermNew lazygit<CR>', {silent = true})
