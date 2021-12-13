local b = vim.b
local opt = vim.opt_local

opt.commentstring = '<!-- %s -->'
opt.foldcolumn = '0'
opt.foldenable = false
opt.spell = false
opt.spelllang = 'en_us,it'
opt.textwidth = 79

b.delimitMate_quotes = "\" ' ` *"

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
