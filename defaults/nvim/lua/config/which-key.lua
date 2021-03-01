local map = vim.api.nvim_set_keymap

map('n', '<Leader>', ':<C-u>WhichKey ","<CR>', { noremap=true, silent=true })
