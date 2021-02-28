local map = vim.api.nvim_set_keymap

vim.g.mapleader = ','

-- Save the file
map('n', '<C-s>', ':w<CR>', { silent = true })

-- Quit neovim if there's only one buffer open, else delete the current one
map('n', '<C-w>',
    '(len(getbufinfo({"buflisted":1})) == 1 ? ":q" : ":bd") . "\\<CR>"',
    { expr = true, silent = true })

-- Jump to the first non whitespace character in the line
map('',  '<C-a>', '^',      {})
map('i', '<C-a>', '<C-o>I', {})

-- Jump to the end of the line
map('',  '<C-e>', '$',      {})
map('i', '<C-e>', '<C-o>A', {})

-- Toggle folds
map('n', '<Space>', 'za', {})

-- Navigate split windows
map('n', '<S-Up>',    '<C-w>k', { noremap = true })
map('n', '<S-Down>',  '<C-w>j', { noremap = true })
map('n', '<S-Left>',  '<C-w>h', { noremap = true })
map('n', '<S-Right>', '<C-w>l', { noremap = true })

-- Delete the previous word in insert mode
map('i', '<M-BS>', '<C-w>', { noremap = true })

-- Escape terminal mode
map('t', '<M-Esc>', '<C-\\><C-n>', { noremap = true })

-- Jump to the beginning of the line in command mode
map('c', '<C-a>', '<C-b>', {})

-- Substitute globally
map('n', 'ss', ':%s//g<Left><Left>', {})
