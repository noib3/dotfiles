vim.bo.errorformat = [[%*\sFile "%f"\, line %l\, %m,]]
vim.opt_local.formatoptions:remove({ "r" })
vim.bo.makeprg = "python3 %"

vim.keymap.set(
  "n",
  "<C-t>",
  "<Cmd>make!<Bar>silent cc<CR>",
  { silent = true, buffer = true }
)
