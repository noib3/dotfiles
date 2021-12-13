local vim_localopt = vim.opt_local

vim_localopt.errorformat = [[%*\sFile "%f"\, line %l\, %m,]]
vim_localopt.formatoptions:remove({'r'})
vim_localopt.makeprg = 'python3 %'

_G.localmap({
  modes = 'n',
  lhs = '<C-t>',
  rhs = '<Cmd>make!<Bar>silent cc<CR>',
  opts = { silent = true },
})
