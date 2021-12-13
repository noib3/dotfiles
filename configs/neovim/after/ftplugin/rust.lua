vim.opt_local.textwidth = 79

if not vim.fn.exists('current_compiler') then
  vim.cmd('compiler cargo')
end

_G.localmap({
  modes = 'n',
  lhs = '<C-t>',
  rhs = '<Cmd>make!<Bar>silent cc<CR>',
  opts = { silent = true },
})
