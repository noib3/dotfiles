local b = vim.b
local opt = vim.opt_local
local bufmap = vim.api.nvim_buf_set_keymap

opt.commentstring = '<!-- %s -->'
opt.foldcolumn = '0'
opt.foldenable = false
opt.spell = false
opt.spelllang = 'en_us,it'
opt.textwidth = 79

b.delimitMate_quotes = "\" ' ` *"

bufmap(0, 'n', '<LocalLeader>p', '<Cmd>MarkdownPreview<CR>', {silent = true})
bufmap(0, 'n', '<LocalLeader>k', '<Cmd>MarkdownPreviewStop<CR>', {silent = true})
