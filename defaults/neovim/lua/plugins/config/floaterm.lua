local find = string.find
local gsub = string.gsub
local format = string.format

local keymap = vim.api.nvim_set_keymap
local cmd = vim.cmd
local fn = vim.fn
local g = vim.g

g.floaterm_title = ''
g.floaterm_width = 0.8
g.floaterm_height = 0.8
g.floaterm_opener = 'edit'
g.floaterm_autoclose = 2

function LfOpener(path)
  local is_textfile = function(type)
    return (
      find(type, 'text')
      or type == 'application/json'
      or type == 'inode/x-empty'
    )
  end
  local filetype = fn.system(format('file -Lb --mime-type "%s"', path))
  filetype = gsub(filetype, '\n', '')
  if is_textfile(filetype) then
    cmd(format('%s %s', g.floaterm_opener, path))
  else
    cmd(format('silent execute "!open %s"', path))
  end
end
cmd('command! -nargs=* LfOpener call luaeval("LfOpener(_A)", <q-args>)')


function Open_Lf_Select_Current()
  local filename = vim.api.nvim_buf_get_name(0)
  local command = 'FloatermNew --opener=LfOpener lf '
  if filename ~= '' then
    command = command .. fn.shellescape(filename)
  end
  cmd(command)
end

keymap('n', 'll', '<Cmd>lua Open_Lf_Select_Current()<CR>', {silent = true})
keymap('n', 'lg', '<Cmd>FloatermNew lazygit<CR>', {silent = true})
