local map = vim.api.nvim_set_keymap

vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- Save the file
map('n', '<C-s>', '<Cmd>w<CR>', {silent = true})

-- Quit if there's only one buffer open or if there are multiple windows open,
-- else delete the current buffer.
-- map('n', '<C-w>',
--     '"<Cmd>".(len(getbufinfo({"buflisted": 1})) == 1 || winnr("$") > 1 ? "q" : "bd")."<CR>"',
--     {silent=true, expr=true})

-- Quit if there's only one buffer open, else delete the current buffer.
map(
  'n',
  '<C-w>',
  '"<Cmd>" . (len(getbufinfo({"buflisted": 1})) == 1 ? "q" : "bd") . "<CR>"',
  {expr = true, silent = true}
)

-- Move between displayed lines instead of physical lines
map('n', '<Up>', 'g<Up>', {noremap = true, silent = true})
map('v', '<Up>', 'g<Up>', {noremap = true, silent = true})
map('i', '<Up>', '<C-o>g<Up>', {noremap = true, silent = true})

map('n', '<Down>', 'g<Down>', {noremap = true, silent = true})
map('v', '<Down>', 'g<Down>', {noremap = true, silent = true})
map('i', '<Down>', '<C-o>g<Down>', {noremap = true, silent = true})

-- Jump to the first non whitespace character in the displayed line
map('n', '<C-a>', 'g^', {})
map('v', '<C-a>', 'g^', {})
map('i', '<C-a>', '<C-o>g^', {})

-- Jump to the end of the displayed line
map('n',  '<C-e>', 'g$', {})
map('v',  '<C-e>', 'g$', {})
map('i', '<C-e>', '<C-o>g$', {})

-- Toggle folds
map('n', '<Space>', 'za', {})

-- Disable 's' in normal mode
map('n', 's', '', {})

-- Navigate split windows
map('n', '<S-Up>', '<C-w>k', {noremap = true})
map('n', '<S-Down>', '<C-w>j', {noremap = true})
map('n', '<S-Left>', '<C-w>h', {noremap = true})
map('n', '<S-Right>', '<C-w>l', {noremap = true})

-- Delete the previous word in insert mode
map('i', '<M-BS>', '<C-w>', {noremap = true})

-- Escape terminal mode
map('t', '<M-Esc>', '<C-\\><C-n>', {noremap = true})

-- Jump to the beginning of the line in command mode
map('c', '<C-a>', '<C-b>', {})

-- Substitute globally
map('n', 'ss', ':%s//g<Left><Left>', {})
