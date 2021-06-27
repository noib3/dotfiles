require('diffview').setup()

local find = string.find
local gsub = string.gsub
local format = string.format

local keymap = vim.api.nvim_set_keymap
local cmd = vim.cmd
local fn = vim.fn

function DiffviewOpenCurrent()
  local git_status = fn.system('git status')
  if find(git_status, 'fatal') then
    cmd('echoerr "Not inside a git repo"')
    return
  end
  local git_root = fn.systemlist('git rev-parse --show-toplevel')[1]
  local filepath = fn.expand('%:p')
  local git_path = gsub(filepath, git_root .. '/', '')
  cmd(format('execute "DiffviewOpen -- %s" | execute "DiffviewToggleFiles"', git_path))
end

keymap('n', '<Leader>doa', '<Cmd>DiffviewOpen<CR>', {silent = true})
keymap('n', '<Leader>doc', '<Cmd>lua DiffviewOpenCurrent()<CR>', {silent = true})
keymap('n', '<Leader>dc', '<Cmd>DiffviewClose<CR>', {silent = true})
