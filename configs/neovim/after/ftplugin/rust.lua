vim.opt_local.formatoptions:remove({ "r", "o" })
vim.bo.textwidth = 79

if not vim.fn.exists("current_compiler") then
  vim.cmd("compiler cargo")
end

vim.keymap.set(
  "n",
  "<C-t>",
  "<Cmd>make!<Bar>silent cc<CR>",
  { silent = true, buffer = true }
)
