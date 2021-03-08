local map = vim.api.nvim_set_keymap
local fn = vim.fn
local cmd = vim.cmd

vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- Save the file
map('n', '<C-s>', '<Cmd>w<CR>', {silent=true})

-- Quit if there's only one buffer open or if there are multiple windows open,
-- else delete the current buffer.
function q_if_one_buff_or_multpl_wins()
  if fn.len(fn.getbufinfo({buflisted=1})) == 1 or fn.winnr('$') > 1 then
    cmd('q')
  else
    cmd('bd')
  end
end

map('n', '<C-w>', '<Cmd>lua q_if_one_buff_or_multpl_wins()<CR>', {silent=true})

-- Jump to the first non whitespace character in the line
map('', '<C-a>', '^', {})
map('i', '<C-a>', '<C-o>I', {})

-- Jump to the end of the line
map('',  '<C-e>', '$', {})
map('i', '<C-e>', '<C-o>A', {})

-- Toggle folds
map('n', '<Space>', 'za', {})

-- Navigate split windows
map('n', '<S-Up>', '<C-w>k', {noremap=true})
map('n', '<S-Down>', '<C-w>j', {noremap=true})
map('n', '<S-Left>', '<C-w>h', {noremap=true})
map('n', '<S-Right>', '<C-w>l', {noremap=true})

-- Delete the previous word in insert mode
map('i', '<M-BS>', '<C-w>', {noremap=true})

-- Escape terminal mode
map('t', '<M-Esc>', '<C-\\><C-n>', {noremap=true})

-- Jump to the beginning of the line in command mode
map('c', '<C-a>', '<C-b>', {})

-- Substitute globally
map('n', 'ss', '<Cmd>%s//g<Left><Left>', {})
