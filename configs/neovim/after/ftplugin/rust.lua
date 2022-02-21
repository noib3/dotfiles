vim.opt_local.textwidth = 79

if not vim.fn.exists("current_compiler") then
  vim.cmd("compiler cargo")
end

_G.localmap({
  modes = "n",
  lhs = "<C-t>",
  rhs = "<Cmd>make!<Bar>silent cc<CR>",
  opts = { silent = true },
})

-- I thought this was cool but it's actually kinda useless.
_G.autocmd({
  event = "BufWritePost",
  pattern = "<buffer>",
  cmd = 'lua require("lsp_extensions.inlay_hints").request({aligned = true, prefix = " » "})',
})
