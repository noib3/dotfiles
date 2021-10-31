local g = vim.g
local cmd = vim.cmd
local keymap = vim.api.nvim_set_keymap

g.mapleader = ','
g.maplocalleader = ','

-- Save the file
keymap('n', '<C-s>', '<Cmd>w<CR>', {silent = true})

-- Quit if there's only one buffer open, else delete the current buffer
-- (without destroying the window it's in if there are multiple windows open).
keymap(
  'n', '<C-w>',
  "'<Cmd>' . (len(getbufinfo({'buflisted': 1})) == 1 ? 'q' : winnr('$') > 1 ? 'BD' : 'bd') . '<CR>'",
  {expr = true, silent = true})

-- Move between displayed lines instead of physical lines
keymap('n', '<Up>', 'g<Up>', {noremap = true, silent = true})
keymap('v', '<Up>', 'g<Up>', {noremap = true, silent = true})
keymap(
  'i', '<Up>', [[pumvisible() ? '<C-p>' : '<C-o>g<Up>']],
  {expr = true, noremap = true, silent = true}
)

keymap('n', '<Down>', 'g<Down>', {noremap = true, silent = true})
keymap('v', '<Down>', 'g<Down>', {noremap = true, silent = true})
keymap(
  'i', '<Down>', [[pumvisible() ? '<C-n>' : '<C-o>g<Down>']],
  {expr = true, noremap = true, silent = true}
)

-- Jump to the first non whitespace character in the displayed line
keymap('n', '<C-a>', 'g^', {})
keymap('v', '<C-a>', 'g^', {})
keymap('i', '<C-a>', '<C-o>g^', {})

-- Jump to the end of the displayed line
keymap('n',  '<C-e>', 'g$', {})
keymap('v',  '<C-e>', 'g$', {})
keymap('i', '<C-e>', '<C-o>g$', {})

-- Move the screen up or down without moving the cursor
keymap('n', 'J', '1<C-d>', {noremap = true})
keymap('n', 'K', '1<C-u>', {noremap = true})

-- Toggle folds
keymap('n', '<Space>', 'za', {})

-- Disable 's' in normal mode
keymap('n', 's', '', {})

-- Navigate split windows
keymap('n', '<S-Up>', '<C-w>k', {noremap = true})
keymap('n', '<S-Down>', '<C-w>j', {noremap = true})
keymap('n', '<S-Left>', '<C-w>h', {noremap = true})
keymap('n', '<S-Right>', '<C-w>l', {noremap = true})

-- Delete the previous word in insert mode
keymap('i', '<M-BS>', '<C-w>', {noremap = true})

-- Escape terminal mode
keymap('t', '<M-Esc>', '<C-\\><C-n>', {noremap = true})

-- Jump to the beginning of the line in command mode
keymap('c', '<C-a>', '<C-b>', {})

-- Substitute globally
keymap('n', 'ss', ':%s//g<Left><Left>', {})

-- Insert accented characters and words
cmd('iabbr ee è')
cmd('iabbr EE È')
cmd('iabbr perche perché')
