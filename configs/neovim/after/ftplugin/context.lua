local vim_localopt = vim.opt_local

vim_localopt.formatoptions:remove({'r', 'o'})
vim_localopt.spelllang = { 'en_us', 'it' }

_G.localmap({
  modes = 'n',
  lhs = '<C-t>',
  rhs = '<Cmd>!context --purge ./%<CR>',
  opts = { silent = true },
})

_G.localmap({
  modes = 'n',
  lhs = '<Leader>lv',
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
