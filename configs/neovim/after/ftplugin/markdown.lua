local vim_localopt = vim.opt_local

vim_localopt.commentstring = '<!-- %s -->'
vim_localopt.foldcolumn = '0'
vim_localopt.foldenable = false
vim_localopt.spell = false
vim_localopt.spelllang = 'en_us,it'
vim_localopt.textwidth = 79

_G.localmap({
  modes = 'n',
  lhs = '<LocalLeader>p',
  rhs = '<Cmd>MarkdownPreview<CR>',
  opts = { silent = true },
})

_G.localmap({
  modes = 'n',
  lhs = '<LocalLeader>k',
  rhs = '<Cmd>MarkdownPreviewStop<CR>',
  opts = { silent = true },
})
