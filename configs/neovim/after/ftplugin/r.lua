local bufmap = vim.api.nvim_buf_set_keymap

bufmap(0, 'n', '<C-t>', '<Cmd>!Rscript ./%<CR>', {silent = true})
