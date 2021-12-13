local vim_localopt = vim.opt_local

vim_localopt.spelllang = { 'en_us', 'it' }
vim_localopt.formatoptions:remove({'r', 'o'})

_G.localmap({
  modes = 'n',
  lhs = '<C-t>',
  rhs = '<Cmd>!context --purge ./%<CR>',
  opts = { silent = true },
})

_G.localmap({
  modes = 'n',
  lhs = '<LocalLeader>lv',
  rhs = '<Cmd>silent call v:lua.open_tex_pdf()<CR>',
  opts = { silent = true },
})

_G.augroup({
  name = 'TeX',
  autocmds = {
    {
      event = 'BufUnload',
      pattern = '*.tex',
      cmd = 'silent call v:lua.close_tex_pdf()',
    },
  }
})
