local vim_b = vim.b
local vim_localopt = vim.opt_local

vim_localopt.errorformat = [[%f:%l: %m]]
vim_localopt.iskeyword:remove({':'})
vim_localopt.makeprg = [[pdflatex -halt-on-error -file-line-error %]]
vim_localopt.spelllang = { 'en_us', 'it' }

vim_b.delimitMate_matchpairs = "(:),[:],{:},`:'"
vim_b.delimitMate_quotes = '$'

vim_b[('surround_%s'):format(vim.fn.char2nr('c'))] = '\\\1command: \1{\r}'
vim_b[('surround_%s'):format(vim.fn.char2nr('e'))] =
  '\\begin{\1environment: \1}\n\t\r\n\\end{\1\1}'

_G.localmap({
  modes = 'n',
  lhs = '<C-t>',
  rhs = '<Cmd>make!<Bar>silent cc<CR>',
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
      event = 'BufRead',
      pattern = '*.tex',
      cmd = 'silent call v:lua.open_tex_pdf()',
    },
    {
      event = 'BufUnload',
      pattern = '*.tex',
      cmd = 'silent call v:lua.close_tex_pdf()',
    },
  }
})
